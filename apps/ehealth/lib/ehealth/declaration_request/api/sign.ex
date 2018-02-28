defmodule EHealth.DeclarationRequest.API.Sign do
  @moduledoc false

  import EHealth.Utils.Connection

  alias EHealth.API.{MPI, OPS, MediaStorage}
  alias EHealth.DeclarationRequest
  alias EHealth.DeclarationRequest.API
  alias EHealth.{Parties, Employees}
  alias EHealth.Employees.Employee
  alias HTTPoison.Response

  require Logger

  @auth_na DeclarationRequest.authentication_method(:na)
  @auth_otp DeclarationRequest.authentication_method(:otp)
  @auth_offline DeclarationRequest.authentication_method(:offline)

  @status_approved DeclarationRequest.status(:approved)

  def check_status(input) do
    db_data =
      input
      |> Map.fetch!("id")
      |> API.get_declaration_request_by_id!()

    case Map.get(db_data, :status) do
      @status_approved -> {:ok, db_data}
      _ -> {:error, [{%{description: "incorrect status", params: [], rule: :invalid}, "$.status"}]}
    end
  end

  def check_patient_signed("") do
    {:error, [{%{description: "Can not be empty", params: [], rule: :invalid}, "$.declaration_request"}]}
  end

  def check_patient_signed(content) do
    case get_in(content, ["person", "patient_signed"]) do
      true ->
        :ok

      _ ->
        {:error,
         [{%{description: "Patient must sign declaration form", params: [], rule: :invalid}, "$.person.patient_signed"}]}
    end
  end

  def compare_with_db(content, declaration_request) do
    db_content =
      declaration_request
      |> Map.get(:data)
      |> put_in(["person", "patient_signed"], true)
      |> Map.put("id", Map.get(declaration_request, :id))
      |> Map.put("status", Map.get(declaration_request, :status))
      |> Map.put("content", Map.get(declaration_request, :printout_content))
      |> Map.put("seed", current_hash())

    case db_content == content do
      true ->
        :ok

      _ ->
        mismatches = do_compare_with_db(db_content, content)

        Logger.info(fn ->
          Poison.encode!(%{
            "log_type" => "debug",
            "process" => "declaration_request_sign",
            "details" => %{
              "mismatches" => mismatches
            },
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

        {:error,
         [
           {%{description: "Signed content does not match the previously created content", params: [], rule: :invalid},
            "$.content"}
         ]}
    end
  end

  def check_drfo(signer, headers) do
    drfo = signer |> Map.get("drfo") |> String.replace(" ", "")
    tax_id = headers |> get_consumer_id() |> Parties.get_tax_id_by_user_id()

    Logger.info(fn ->
      Poison.encode!(%{
        "log_type" => "debug",
        "process" => "declaration_request_sign",
        "details" => %{
          "drfo" => drfo,
          "tax_id" => tax_id
        },
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    case tax_id == drfo do
      true ->
        :ok

      _ ->
        {:error,
         [
           {%{description: "Does not match the signer drfo", params: [], rule: :invalid}, "$.token.consumer_id"}
         ]}
    end
  end

  def check_employee_id(content, headers) do
    with %Employee{legal_entity_id: legal_entity_id} <- content |> get_in(["employee", "id"]) |> Employees.get_by_id(),
         true <- legal_entity_id == get_client_id(headers) do
      :ok
    else
      _ -> {:error, :forbidden}
    end
  end

  def store_signed_content(db_data, input, headers) do
    Logger.info(fn ->
      """
      db_data: #{inspect(db_data)}
      """
    end)

    input
    |> Map.fetch!("signed_declaration_request")
    |> MediaStorage.store_signed_content(:declaration_bucket, Map.fetch!(db_data, :declaration_id), headers)
    |> case do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def create_or_update_person(declaration_request, content, headers) do
    content
    |> Map.fetch!("person")
    |> Map.put("patient_signed", true)
    |> Map.put("id", declaration_request.id)
    |> MPI.create_or_update_person(headers)
    |> case do
      {:ok, %Response{status_code: 409}} -> {:conflict, "person is not active"}
      {:ok, %Response{status_code: 404}} -> {:conflict, "person is not found"}
      {:ok, %Response{body: person, status_code: 200}} -> Poison.decode(person)
      {:ok, %Response{body: person, status_code: 201}} -> Poison.decode(person)
      err -> err
    end
  end

  def create_declaration_with_termination_logic(
        %{"data" => %{"id" => person_id}},
        %DeclarationRequest{
          id: id,
          data: data,
          authentication_method_current: authentication_method_current,
          declaration_id: declaration_id
        },
        headers
      ) do
    client_id = get_client_id(headers)

    data
    |> Map.take(["start_date", "end_date", "scope", "seed"])
    |> Map.merge(%{
      "id" => declaration_id,
      "employee_id" => get_in(data, ["employee", "id"]),
      "division_id" => get_in(data, ["division", "id"]),
      "legal_entity_id" => get_in(data, ["legal_entity", "id"]),
      "person_id" => person_id,
      "status" => get_status(authentication_method_current),
      "is_active" => true,
      "created_by" => client_id,
      "updated_by" => client_id,
      "signed_at" => Timex.now(),
      "declaration_request_id" => id
    })
    |> OPS.create_declaration_with_termination_logic(headers)
  end

  def update_declaration_request_status(ops_declaration_response, input) do
    update_result =
      input
      |> Map.fetch!("id")
      |> API.update_status("SIGNED")

    declaration_data =
      ops_declaration_response
      |> Map.get("data")
      |> Map.drop(["updated_by", "updated_at", "created_by"])

    case update_result do
      {:ok, _data} -> {:ok, declaration_data}
      err -> err
    end
  end

  defp get_status(%{"type" => @auth_offline}), do: "pending_verification"
  defp get_status(%{"type" => @auth_otp}), do: "active"
  defp get_status(%{"type" => @auth_na}), do: "active"

  defp get_status(_) do
    Logger.error(fn ->
      Poison.encode!(%{
        "log_type" => "error",
        "message" => "Unknown authentication_method_current.type",
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    ""
  end

  defp do_compare_with_db(db_content, content) do
    Enum.reduce(Map.keys(db_content), [], fn key, acc ->
      v1 = Map.get(db_content, key)
      v2 = Map.get(content, key)

      if v1 != v2 do
        [%{"db_content.#{key}" => v1, "data.#{key}" => v2} | acc]
      else
        acc
      end
    end)
  end

  defp current_hash do
    {:ok, %{"data" => %{"hash" => hash}}} = OPS.get_latest_block()
    hash
  end
end

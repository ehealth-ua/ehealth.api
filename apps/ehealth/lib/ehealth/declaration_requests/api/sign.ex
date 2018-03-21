defmodule EHealth.DeclarationRequests.API.Sign do
  @moduledoc false

  import Ecto.Changeset
  import EHealth.Utils.Connection
  alias EHealth.API.MPI
  alias EHealth.API.MediaStorage
  alias EHealth.API.OPS
  alias EHealth.API.Signature
  alias EHealth.DeclarationRequests
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias EHealth.DeclarationRequests.SignRequest
  alias EHealth.Parties
  alias EHealth.Employees
  alias EHealth.Employees.Employee
  alias HTTPoison.Response
  alias EHealth.Repo
  require Logger

  @auth_na DeclarationRequest.authentication_method(:na)
  @auth_otp DeclarationRequest.authentication_method(:otp)
  @auth_offline DeclarationRequest.authentication_method(:offline)

  @status_approved DeclarationRequest.status(:approved)

  def sign(params, headers) do
    with {:ok, %{"data" => %{"content" => content, "signer" => signer}}} <- decode_and_validate(params, headers),
         %DeclarationRequest{} = declaration_request <- params |> Map.fetch!("id") |> DeclarationRequests.get_by_id!(),
         :ok <- check_status(declaration_request),
         :ok <- check_patient_signed(content),
         :ok <- compare_with_db(content, declaration_request),
         :ok <- check_employee_id(content, headers),
         :ok <- check_drfo(signer, headers),
         :ok <- store_signed_content(declaration_request, params, headers),
         {:ok, person} <- create_or_update_person(declaration_request, content, headers),
         {:ok, declaration} <- create_declaration_with_termination_logic(person, declaration_request, headers),
         {:ok, signed_declaration} <- update_declaration_request_status(declaration_request, declaration) do
      {:ok, signed_declaration}
    end
  end

  def decode_and_validate(params, headers) do
    params
    |> validate_sign_request()
    |> validate_signature(headers)
    |> normalize_signature_error()
    |> check_is_valid()
  end

  def validate_sign_request(params) do
    fields = ~W(
      signed_declaration_request
      signed_content_encoding
    )a

    %SignRequest{}
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:signed_content_encoding, ["base64"])
  end

  def validate_signature(%Ecto.Changeset{valid?: true, changes: changes}, headers) do
    changes
    |> Map.get(:signed_declaration_request)
    |> Signature.decode_and_validate(Map.get(changes, :signed_content_encoding), headers)
  end

  def validate_signature(err, _headers), do: err

  def normalize_signature_error({:error, %{"meta" => %{"description" => error}}}) do
    %SignRequest{}
    |> cast(%{}, [:signed_legal_entity_request])
    |> add_error(:signed_legal_entity_request, error)
  end

  def normalize_signature_error(ok_resp), do: ok_resp

  def check_is_valid({:ok, %{"data" => %{"is_valid" => false, "validation_error_message" => error}}}) do
    {:error, {:bad_request, error}}
  end

  def check_is_valid({:ok, %{"data" => %{"is_valid" => true}} = result}) do
    {_empty_message, result} = pop_in(result, ["data", "validation_error_message"])
    {:ok, result}
  end

  def check_is_valid(err), do: err

  def check_status(%DeclarationRequest{status: status}) do
    case status do
      @status_approved -> :ok
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

  def compare_with_db(content, %DeclarationRequest{} = declaration_request) do
    db_content =
      declaration_request
      |> Map.get(:data)
      |> put_in(["person", "patient_signed"], true)
      |> Map.put("id", Map.get(declaration_request, :id))
      |> Map.put("status", Map.get(declaration_request, :status))
      |> Map.put("content", Map.get(declaration_request, :printout_content))
      |> Map.put("declaration_number", Map.get(declaration_request, :declaration_number))
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
    employee_id = get_in(content, ["employee", "id"])

    with %Employee{legal_entity_id: legal_entity_id} <- Employees.get_by_id(employee_id),
         true <- legal_entity_id == get_client_id(headers) do
      :ok
    else
      _ -> {:error, :forbidden}
    end
  end

  def store_signed_content(%DeclarationRequest{} = declaration_request, input, headers) do
    Logger.info(fn ->
      """
      db_data: #{inspect(declaration_request)}
      """
    end)

    input
    |> Map.fetch!("signed_declaration_request")
    |> MediaStorage.store_signed_content(:declaration_bucket, Map.fetch!(declaration_request, :declaration_id), headers)
    |> case do
      {:ok, _} -> :ok
      err -> err
    end
  end

  def create_or_update_person(%DeclarationRequest{} = declaration_request, content, headers) do
    content
    |> Map.fetch!("person")
    |> Map.put("patient_signed", true)
    |> Map.put("id", declaration_request.mpi_id)
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
          declaration_id: declaration_id,
          declaration_number: declaration_number,
          overlimit: overlimit
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
      "declaration_request_id" => id,
      "overlimit" => overlimit,
      "declaration_number" => declaration_number
    })
    |> OPS.create_declaration_with_termination_logic(headers)
  end

  def update_declaration_request_status(%DeclarationRequest{} = declaration_request, declaration) do
    declaration_request =
      declaration_request
      |> DeclarationRequests.changeset(%{status: "SIGNED"})
      |> Repo.update()

    declaration_data =
      declaration
      |> Map.get("data")
      |> Map.drop(["updated_by", "updated_at", "created_by"])

    case declaration_request do
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

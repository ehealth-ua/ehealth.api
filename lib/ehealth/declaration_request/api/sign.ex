defmodule EHealth.DeclarationRequest.API.Sign do
  @moduledoc false

  import EHealth.Utils.Connection

  alias EHealth.API.MediaStorage
  alias EHealth.API.MPI
  alias EHealth.API.OPS
  alias EHealth.DeclarationRequest
  alias EHealth.DeclarationRequest.API
  alias EHealth.PRM.Employees
  alias EHealth.PRM.PartyUsers

  require Logger

  def check_status({:ok, pipe_data}, input) do
    db_data =
      input
      |> Map.fetch!("id")
      |> API.get_declaration_request_by_id!()

    case Map.get(db_data, :status) do
      "APPROVED" -> {:ok, pipe_data, db_data}
      _ -> {:error, [{%{description: "incorrect status", params: [], rule: :invalid}, "$.status"}]}
    end
  end
  def check_status(err, _input), do: err

  def check_patient_signed({:ok, %{"data" => %{"content" => ""}}, _declaration_request}) do
    {:error, [{%{description: "Can not be empty", params: [], rule: :invalid}, "$.declaration_request"}]}
  end

  def check_patient_signed({:ok, %{"data" => %{"content" => content}}, _declaration_request} = pipe_data) do
    case get_in(content, ["person", "patient_signed"]) do
      true -> pipe_data
      _ -> {:error, [{%{description: "Patient must sign declaration form", params: [], rule: :invalid},
        "$.person.patient_signed"}]}
    end
  end

  def check_patient_signed(err), do: err

  def compare_with_db({:ok, %{"data" => %{"content" => content}}, declaration_request} = pipe_data) do
    db_content =
      declaration_request
      |> Map.get(:data)
      |> put_in(["person", "patient_signed"], true)
      |> Map.put("id", Map.get(declaration_request, :id))
      |> Map.put("status", Map.get(declaration_request, :status))
      |> Map.put("content", Map.get(declaration_request, :printout_content))
      |> Map.delete("seed")

    data = Map.delete(content, "seed")
    Logger.info(fn -> """
      db_content: #{inspect db_content}
      data: #{inspect data}
      """ end)

    case db_content == data do
      true -> pipe_data
      _ -> {:error, [{%{description: "Signed content does not match the previously created content",
        params: [], rule: :invalid}, "$.content"}]}
    end
  end
  def compare_with_db(err), do: err

  def check_drfo({:ok, %{"data" => %{"content" => content, "signer" => signer}}, db_data}) do
    tax_id = get_in(content, ["employee", "party", "tax_id"])
    drfo = Map.get(signer, "drfo")

    Logger.info(fn -> """
      tax_id: #{tax_id}
      drfo: #{drfo}
      """ end)

    case tax_id == drfo do
      true -> {:ok, {content, db_data}}
      _ -> {:error, [{%{description: "Does not match the signer drfo",
        params: [], rule: :invalid}, "$.content.employee.party.tax_id"}]}
    end
  end
  def check_drfo(err), do: err

  defp find_employee(employees, employee_id) do
    Enum.find(employees, fn(employee) -> employee_id == employee.id end)
  end

  defp match_employees(results, employee_id) do
    find_result = Enum.find(results, fn(data) -> find_employee(data, employee_id) != nil end)

    case find_result do
      nil -> {:error, :forbidden}
      _ -> :ok
    end
  end

  defp check_employees(party_users, employee_id) do
    party_users
    |> Enum.map(fn(party_user) ->
      %{party_id: party_user.party_id, is_active: true}
      |> Employees.get_employees()
      |> Tuple.to_list
      |> List.first
    end)
    |> match_employees(employee_id)
  end

  def check_employee_id({:ok, {content, db_data}}, headers) do
    employee_id = get_in(content, ["employee", "id"])
    with consumer_id <- get_consumer_id(headers),
         {:ok, party_users} <- PartyUsers.get_party_users_by_user_id(consumer_id),
         :ok <- check_employees(party_users, employee_id)
   do
     {:ok, {content, db_data}}
   end
  end
  def check_employee_id(err, _headers), do: err

  def store_signed_content({:ok, {_, db_data} = data}, input, headers) do
    input
    |> Map.fetch!("signed_declaration_request")
    |> MediaStorage.store_signed_content(:declaration_bucket, Map.fetch!(db_data, :declaration_id), headers)
    |> validate_api_response(data)
  end
  def store_signed_content(err, _input, _headers), do: err

  def create_or_update_person({:ok, {content, db_data}}, headers) do
    result =
      content
      |> Map.fetch!("person")
      |> Map.put("patient_signed", true)
      |> MPI.create_or_update_person(headers)

    case result do
      {:ok, data} -> {:ok, data, db_data}
      err -> err
    end
  end
  def create_or_update_person(err, _headers), do: err

  def create_declaration_with_termination_logic({:ok, %{"data" => %{"id" => person_id}},
    %DeclarationRequest{
      id: id, data: data,
      authentication_method_current: authentication_method_current,
      declaration_id: declaration_id}}, headers) do
    client_id = get_client_id(headers)
    data
    |> Map.take(["start_date", "end_date", "scope", "seed"])
    |> Map.put("id", declaration_id)
    |> Map.put("employee_id", get_in(data, ["employee", "id"]))
    |> Map.put("division_id", get_in(data, ["division", "id"]))
    |> Map.put("legal_entity_id", get_in(data, ["legal_entity", "id"]))
    |> Map.put("person_id", person_id)
    |> Map.put("status", get_status(authentication_method_current))
    |> Map.put("is_active", true)
    |> Map.put("created_by", client_id)
    |> Map.put("updated_by", client_id)
    |> Map.put("signed_at", Timex.now())
    |> Map.put("declaration_request_id", id)
    |> OPS.create_declaration_with_termination_logic(headers)
  end
  def create_declaration_with_termination_logic(err, _headers), do: err

  def update_declaration_request_status({:ok, declaration_response}, input) do
    update_result =
      input
      |> Map.fetch!("id")
      |> API.update_status("SIGNED")

    declaration_data =
      declaration_response
      |> Map.get("data")
      |> Map.drop(["updated_by", "updated_at", "created_by"])

    case update_result do
      {:ok, _data} -> {:ok, declaration_data}
      err -> err
    end
  end
  def update_declaration_request_status(err, _input), do: err

  defp get_status(%{"type" => "OFFLINE"}), do: "pending_verification"
  defp get_status(%{"type" => "OTP"}), do: "active"
  defp get_status(%{"type" => "NA"}), do: "active"
  defp get_status(_) do
    Logger.error(fn -> "Unknown authentication_method_current.type" end)
    ""
  end

  defp validate_api_response({:ok, _}, db_data), do: {:ok, db_data}
  defp validate_api_response(error, _db_data), do: error
end

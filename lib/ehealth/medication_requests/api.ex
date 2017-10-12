defmodule EHealth.MedicationRequests.API do
  @moduledoc false

  alias EHealth.API.OPS
  alias EHealth.PRM.PartyUsers
  alias EHealth.PRM.Employees
  alias EHealth.PRM.Divisions.Schema, as: Division
  alias EHealth.PRM.PartyUsers.Schema, as: PartyUser
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias EHealth.PRM.MedicalPrograms.Schema, as: MedicalProgram
  alias EHealth.PRM.Medications.Medication.Schema, as: Medication
  alias EHealth.PRM.Medications.API, as: MedicationsAPI
  alias EHealth.PRM.Divisions
  alias EHealth.PRM.Employees
  alias EHealth.PRM.MedicalPrograms
  alias EHealth.API.MPI
  alias EHealth.MedicationRequests.Search
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]
  import Ecto.Changeset
  require Logger

  @fields_optional ~w(employee_id person_id status page_size page)a

  def list(params, headers) do
    user_id = get_consumer_id(headers)
    with %Ecto.Changeset{valid?: true, changes: changes} = changeset <- changeset(params),
         %PartyUser{party: party} <- get_party_user(user_id),
         employee_ids <- get_employees(party.id, get_change(changeset, :legal_entity_id)),
         :ok <- validate_employee_id(get_change(changeset, :employee_id), employee_ids),
         search_params <- get_search_params(employee_ids, changes),
         {:ok, %{"data" => data, "paging" => paging}} <- OPS.get_doctor_medication_requests(search_params, headers)
    do
      medication_requests = Enum.reduce_while(data, [], fn medication_request, acc ->
        with {:ok, medication_request} <- get_references(medication_request) do
          {:cont, acc ++ [medication_request]}
        else
          _ ->
            message = "Could not load remote reference for medication_request #{Map.get(medication_request, "id")}"
            {:halt, {:error, {:internal_error, message}}}
        end
      end)

      with {:error, error} <- medication_requests do
        {:error, error}
      else
        _ -> {:ok, medication_requests, paging}
      end
    end
  end

  def show(params, headers) do
    with {:ok, medication_request} <- get_medication_request(params, headers) do
      with {:ok, medication_request} <- get_references(medication_request) do
           {:ok, medication_request}
      else
        _ ->
          message = "Could not load remote reference for medication_request #{Map.get(medication_request, "id")}"
          {:error, {:internal_error, message}}
      end
    end
  end

  def get_medication_request(%{"id" => id} = params, headers) do
    user_id = get_consumer_id(headers)
    with %PartyUser{party: party} <- get_party_user(user_id),
         employee_ids <- get_employees(party.id, Map.get(params, "legal_entity_id")),
           search_params <- %{"employee_id" => Enum.join(employee_ids, ","), "id" => id},
         {:ok, %{"data" => [medication_request]}} <- OPS.get_doctor_medication_requests(search_params, headers)
    do
      {:ok, medication_request}
    else
      {:ok, %{"data" => []}} -> nil
      error -> error
    end
  end

  defp validate_employee_id(nil, _), do: :ok
  defp validate_employee_id(employee_id, employee_ids) do
    if Enum.member?(employee_ids, employee_id), do: :ok, else: {:error, :forbidden}
  end

  defp get_search_params(employee_ids, %{person_id: person_id} = params) do
    Map.put(do_get_search_params(employee_ids, params), :person_id, person_id)
  end
  defp get_search_params(employee_ids, params), do: do_get_search_params(employee_ids, params)

  defp do_get_search_params(employee_ids, params) do
    params
    |> Map.take(~w(page page_size)a)
    |> Map.put(:employee_id, Enum.join(employee_ids, ","))
  end

  defp get_employees(party_id, nil) do
    do_get_employees([party_id: party_id])
  end
  defp get_employees(party_id, legal_entity_id) do
    do_get_employees([
      party_id: party_id,
      legal_entity_id: legal_entity_id
    ])
  end

  defp do_get_employees(params) do
    params
    |> Employees.list()
    |> Enum.map(&(Map.get(&1, :id)))
  end

  defp get_party_user(user_id) do
    with %PartyUser{} = party_user <- PartyUsers.get_party_users_by_user_id(user_id) do
      party_user
    else
      _ ->
        Logger.error("No party user for user_id: \"#{user_id}\"")
        {:error, %{"type" => "internal_error"}}
    end
  end

  def get_references(medication_request) do
    with %Division{} = division <- Divisions.get_division_by_id(medication_request["division_id"]),
         %Employee{} = employee <- Employees.get_employee_by_id(medication_request["employee_id"]),
         %MedicalProgram{} = medical_program <- MedicalPrograms.get_by_id(medication_request["medical_program_id"]),
         %Medication{} = medication <- MedicationsAPI.get_medication_by_id(medication_request["medication_id"]),
         {:ok, %{"data" => person}} <- MPI.person(medication_request["person_id"])
    do
      {
        :ok,
        medication_request
        |> Map.put("division", division)
        |> Map.put("employee", employee)
        |> Map.put("legal_entity", employee.legal_entity)
        |> Map.put("medical_program", medical_program)
        |> Map.put("medication", medication)
        |> Map.put("person", person)
      }
    else
      _ ->
        {:error, [{
          %{description: "Medication request is not valid",
            params: [],
            rule: :required
          }, "$.medication_request_id"}]}
    end
  end

  defp changeset(params) do
    cast(%Search{}, params, @fields_optional)
  end
end

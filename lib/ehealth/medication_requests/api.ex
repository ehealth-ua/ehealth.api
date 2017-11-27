defmodule EHealth.MedicationRequests.API do
  @moduledoc false

  alias EHealth.API.OPS
  alias EHealth.PartyUsers
  alias EHealth.Employees
  alias EHealth.Divisions.Division
  alias EHealth.PartyUsers.PartyUser
  alias EHealth.Employees.Employee
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.MedicalPrograms.MedicalProgram
  alias EHealth.Medications.INNMDosage
  alias EHealth.Medications.Program, as: ProgramMedication
  alias EHealth.Medications
  alias EHealth.Medications.Medication.Ingredient
  alias EHealth.Medications.INNMDosage.Ingredient, as: INNMDosageIngredient
  alias EHealth.LegalEntities
  alias EHealth.Divisions
  alias EHealth.MedicalPrograms
  alias EHealth.API.MPI
  alias EHealth.Validators.JsonSchema
  alias EHealth.MedicationRequests.Search
  alias EHealth.PRMRepo
  alias EHealth.MedicationRequests.SMSSender
  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  @legal_entity_msp LegalEntity.type(:msp)
  @legal_entity_pharmacy LegalEntity.type(:pharmacy)

  def list(params, client_type, headers) do
    with %Ecto.Changeset{valid?: true, changes: changes} <- changeset(params),
         {:ok, %{"data" => data, "paging" => paging}} <- get_medication_requests(changes, client_type, headers)
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

  def show(params, client_type, headers) do
    with {:ok, medication_request} <- get_medication_request(params, client_type, headers) do
      with {:ok, medication_request} <- get_references(medication_request) do
           {:ok, medication_request}
      else
        _ ->
          message = "Could not load remote reference for medication_request #{Map.get(medication_request, "id")}"
          {:error, {:internal_error, message}}
      end
    end
  end

  def reject(params, client_type, headers) do
    update_params = %{"medication_request": %{status: "REJECTED",
                      updated_by: get_client_id(headers),
                      updated_at: NaiveDateTime.utc_now(),
                      reject_reason: params["reject_reason"]}}
    with {:ok, %{"status" => "ACTIVE"} = medication_request} <- show(%{"id" => params["id"]}, client_type, headers),
         {:ok, %{"data" => mr}} <- OPS.update_medication_request(medication_request["id"], update_params)
    do
      SMSSender.maybe_send_sms(%{request_number: medication_request["request_number"],
                                 created_at: medication_request["created_at"]},
                                medication_request["person"],
                                &SMSSender.reject_template/1)
      {:ok, Map.merge(medication_request, mr)}
    else
      {:ok, _} -> {:error, {:conflict, "Invalid status Request for Medication request for reject transition!"}}
      err -> err
    end
  end

  def resend(params, client_type, headers) do
    with {:ok, %{"status" => "ACTIVE"} = medication_request} <- show(%{"id" => params["id"]}, client_type, headers),
         false <- is_nil(medication_request["verification_code"])
    do
      SMSSender.maybe_send_sms(%{request_number: medication_request["request_number"],
                                 verification_code: medication_request["verification_code"]},
                                medication_request["person"],
                                &SMSSender.sign_template/1)
      {:ok, Map.merge(medication_request, medication_request)}
    else
      {:ok, _} -> {:error, {:conflict, "Invalid status Medication request for resend action!"}}
      true -> {:error, {:forbidden, "Can't resend Medication request without verification code!"}}
      err -> err
    end
  end

  @doc """
  Currently supports the only program "доступні ліки"
  """
  def qualify(id, client_type, params, headers) do
    with params <- Map.drop(params, ~w(legal_entity_id is_active)),
         {:ok, medication_request} <- get_medication_request(%{"id" => id}, client_type, headers),
         :ok <- validate_medication_request_status(medication_request),
         :ok <- JsonSchema.validate(:medication_request_qualify, params),
         {:ok, medical_programs} <- get_medical_programs(params),
         validations <- validate_programs(medical_programs, medication_request)
    do
      {:ok, medical_programs, validations}
    end
  end

  def get_medication_requests(changes, client_type, headers) do
    do_get_medication_requests(get_consumer_id(headers), client_type, changes, headers)
  end

  defp do_get_medication_requests(_, "NHS ADMIN", changes, headers) do
    employee_id = Map.get(changes, :employee_id)
    search_params = get_search_params([], changes)
    search_params = if is_nil(employee_id), do: Map.delete(search_params, :employee_id), else: search_params
    OPS.get_doctor_medication_requests(search_params, headers)
  end
  defp do_get_medication_requests(user_id, _, changes, headers) do
    with %PartyUser{party: party} <- get_party_user(user_id),
         employee_ids <- get_employees(party.id, Map.get(changes, :legal_entity_id)),
         :ok <- validate_employee_id(Map.get(changes, :employee_id), employee_ids),
         search_params <- get_search_params(employee_ids, changes)
    do
      OPS.get_doctor_medication_requests(search_params, headers)
    end
  end

  def get_medication_request(%{"id" => id}, client_type, headers) do
    do_get_medication_request(get_client_id(headers), get_consumer_id(headers), client_type, id, headers)
  end

  defp do_get_medication_request(_, _, "NHS ADMIN", id, headers) do
    with search_params <- get_show_search_params(id),
         {:ok, %{"data" => [medication_request]}} <- OPS.get_doctor_medication_requests(search_params, headers)
    do
      {:ok, medication_request}
    else
      {:ok, %{"data" => []}} -> nil
      error -> error
    end
  end
  defp do_get_medication_request(legal_entity_id, user_id, _, id, headers) do
    with %PartyUser{party: party} <- get_party_user(user_id),
         %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(legal_entity_id),
         search_params <- get_show_search_params(party.id, legal_entity, id),
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

  defp get_show_search_params(party_id, %LegalEntity{id: legal_entity_id, type: @legal_entity_msp}, id) do
    employee_ids = get_employees(party_id, legal_entity_id)
    %{"employee_id" => Enum.join(employee_ids, ","), "id" => id}
  end
  defp get_show_search_params(_, %LegalEntity{type: @legal_entity_pharmacy}, id), do: get_show_search_params(id)
  defp get_show_search_params(id), do: %{"id" => id}

  defp get_search_params(employee_ids, %{person_id: person_id} = params) do
    Map.put(do_get_search_params(employee_ids, params), :person_id, person_id)
  end
  defp get_search_params(employee_ids, params), do: do_get_search_params(employee_ids, params)

  defp do_get_search_params(_employee_ids, %{employee_id: _employee_id} = params), do: params
  defp do_get_search_params(employee_ids, params) do
    Map.put(params, :employee_id, Enum.join(employee_ids, ","))
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
    |> Employees.list!()
    |> Enum.map(&(Map.get(&1, :id)))
  end

  defp get_party_user(user_id) do
    with [party_user] <- PartyUsers.list!(%{user_id: user_id}) do
      party_user
    else
      _ ->
        Logger.error("No party user for user_id: \"#{user_id}\"")
        {:error, %{"type" => "internal_error"}}
    end
  end

  def get_references(medication_request) do
    with %Division{} = division <- Divisions.get_by_id(medication_request["division_id"]),
         %Employee{} = employee <- Employees.get_by_id(medication_request["employee_id"]),
         %MedicalProgram{} = medical_program <- MedicalPrograms.get_by_id(medication_request["medical_program_id"]),
         %INNMDosage{} = medication <- Medications.get_innm_dosage_by_id(medication_request["medication_id"]),
         %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(medication_request["legal_entity_id"]),
         {:ok, %{"data" => person}} <- MPI.person(medication_request["person_id"])
    do
      {
        :ok,
        medication_request
        |> Map.put("division", division)
        |> Map.put("employee", employee)
        |> Map.put("legal_entity", legal_entity)
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
    cast(%Search{}, params, Search.__schema__(:fields))
  end

  defp validate_innm(program, medication_request) do
    ids = Enum.reduce(program.program_medications, [], fn program_medication, acc ->
      [program_medication.medication.id] ++ acc
    end)
    ingredients =
      Ingredient
      |> join(:left, [i], m in assoc(i, :medication))
      |> where([i], i.parent_id in ^ids and i.is_primary)
      |> where([i], i.medication_child_id == ^medication_request["medication_id"])
      |> where([i, m], m.is_active)
      |> select([i, m], count(m.id))
      |> PRMRepo.one
    if ingredients > 0 do
      :ok
    else
      {:error, "Innm not on the list of approved innms for program 'DOSTUPNI LIKI' !"}
    end
  end

  def get_check_innm_id(medication_request) do
    medication_id = medication_request["medication_id"]
    with %INNMDosage{} = medication <- Medications.get_innm_dosage_by_id(medication_id),
         ingredient <- Enum.find(medication.ingredients, &(Map.get(&1, :is_primary)))
    do
      {:ok, ingredient.innm_child_id}
    else
      _ -> {:error, [{
              %{description: "Medication request is not valid",
                params: [],
                rule: :required
              }, "$.medication_request_id"}]}
    end
  end

  defp validate_programs(medical_programs, medication_request) do
    # Currently supports the only program "доступні ліки"
    Enum.reduce(medical_programs, %{}, fn program, acc ->
      with :ok <- validate_innm(program, medication_request),
           {:ok, check_innm_id} <- get_check_innm_id(medication_request),
           {:ok, %{"data" => medication_ids}} <- get_qualify_requests(medication_request),
           :ok <- validate_ingredients(medication_ids, check_innm_id)
      do
        Map.put(acc, program.id, :ok)
      else
        error -> Map.put(acc, program.id, error)
      end
    end)
  end

  defp get_qualify_requests(%{} = medication_request) do
    medication_request
    |> Map.take(~w(person_id started_at ended_at))
    |> OPS.get_qualify_medication_requests()
  end

  defp validate_ingredients(medication_ids, check_innm_id) do
    ingredients =
      INNMDosageIngredient
      |> where([idi], idi.parent_id in ^medication_ids)
      |> where([idi], idi.is_primary and idi.innm_child_id == ^check_innm_id)
      |> PRMRepo.all
    if Enum.empty?(ingredients) do
      :ok
    else
      {:error, "For the patient at the same term there can be only" <>
        " 1 dispensed medication request per one and the same innm!"}
    end
  end

  defp get_medical_programs(%{"programs" => programs}) do
    medical_programs = Enum.map(programs, fn %{"id" => id} ->
      MedicalProgram
      |> where([mp], mp.is_active)
      |> join(:left, [mp], pm in ProgramMedication, pm.medical_program_id == mp.id and pm.is_active)
      |> join(:left, [mp, pm], m in assoc(pm, :medication))
      |> preload([mp, pm, m], [program_medications: {pm, medication: m}])
      |> PRMRepo.get(id)
    end)
    errors =
      medical_programs
      |> Enum.with_index()
      |> Enum.filter(fn
      {medical_program, _} -> is_nil(medical_program)
    end)

    if Enum.empty?(errors) do
      {:ok, medical_programs}
    else
      {:error, Enum.map(errors, fn {nil, i} ->
          {%{description: "Medical program not found",
             params: [],
             rule: :required
            }, "$.programs[#{i}].id"}
        end)}
    end
  end

  defp validate_medication_request_status(%{"status" => "ACTIVE"}), do: :ok
  defp validate_medication_request_status(_) do
    {:conflict, "Invalid status Medication request for qualify action!"}
  end
end

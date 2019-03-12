defmodule Core.MedicationRequests.API do
  @moduledoc false

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import Ecto.Changeset
  import Ecto.Query

  alias Core.Divisions
  alias Core.Divisions.Division
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.MedicalPrograms
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.MedicationRequests.MedicationRequest
  alias Core.MedicationRequests.Renderer, as: MedicationRequestsRenderer
  alias Core.MedicationRequests.Search
  alias Core.MedicationRequests.SMSSender
  alias Core.Medications
  alias Core.Medications.INNMDosage
  alias Core.Medications.INNMDosage.Ingredient, as: INNMDosageIngredient
  alias Core.Medications.Medication
  alias Core.Medications.Medication.Ingredient
  alias Core.Medications.Program, as: ProgramMedication
  alias Core.PartyUsers
  alias Core.PartyUsers.PartyUser
  alias Core.Utils.NumberGenerator
  alias Core.ValidationError
  alias Core.Validators.Content, as: ContentValidator
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Core.Validators.Signature, as: SignatureValidator

  require Logger

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @ops_api Application.get_env(:core, :api_resolvers)[:ops]
  @mpi_api Application.get_env(:core, :api_resolvers)[:mpi]
  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]

  @legal_entity_msp LegalEntity.type(:msp)
  @legal_entity_pharmacy LegalEntity.type(:pharmacy)
  @legal_entity_msp_pharmacy LegalEntity.type(:msp_pharmacy)

  @intent_order MedicationRequest.intent(:order)

  def list(params, client_type, headers) do
    with %Ecto.Changeset{valid?: true, changes: changes} <- changeset(params),
         {:ok, %{"data" => data, "paging" => paging}} <- get_medication_requests(changes, client_type, headers) do
      medication_requests =
        Enum.reduce_while(data, [], fn medication_request, acc ->
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
    user_id = get_consumer_id(headers)
    update_datetime = DateTime.utc_now()

    with :ok <- JsonSchema.validate(:medication_request_reject, params),
         {:ok, %{"content" => content, "signers" => [signer]}} <- decode_signed_content(params, headers),
         :ok <- SignatureValidator.check_drfo(signer, user_id, "medication_request_reject"),
         {:ok, %{"status" => "ACTIVE"} = medication_request} <- show(%{"id" => params["id"]}, client_type, headers),
         :ok <- check_medication_dispenses(medication_request, headers),
         :ok <- JsonSchema.validate(:medication_request_request_create_generic, content),
         schema <- String.to_atom("medication_request_reject_content_" <> content["intent"]),
         :ok <- JsonSchema.validate(schema, content),
         :ok <- compare_with_db(content, medication_request),
         :ok <- save_signed_content(params["id"], params, headers),
         update_params <-
           content
           |> Map.take(~w(reject_reason))
           |> Map.merge(%{
             "status" => "REJECTED",
             "updated_by" => get_client_id(headers),
             "updated_at" => update_datetime,
             "rejected_by" => get_client_id(headers),
             "rejected_at" => update_datetime
           }),
         {:ok, %{"data" => mr}} <-
           @ops_api.update_medication_request(
             medication_request["id"],
             %{"medication_request" => update_params},
             headers
           ) do
      SMSSender.maybe_send_sms(
        %{request_number: medication_request["request_number"], created_at: medication_request["created_at"]},
        medication_request["person"],
        &SMSSender.reject_template/1
      )

      {:ok, Map.merge(medication_request, mr)}
    else
      {:ok, _} -> {:error, {:conflict, "Invalid status Request for Medication request for reject transition!"}}
      err -> err
    end
  end

  def resend(params, client_type, headers) do
    with {:ok, %{"status" => "ACTIVE"} = medication_request} <- show(%{"id" => params["id"]}, client_type, headers),
         {:intent, @intent_order} <- {:intent, medication_request["intent"]},
         false <- is_nil(medication_request["verification_code"]) do
      SMSSender.maybe_send_sms(
        %{
          request_number: medication_request["request_number"],
          verification_code: medication_request["verification_code"]
        },
        medication_request["person"],
        &SMSSender.sign_template/1
      )

      {:ok, Map.merge(medication_request, medication_request)}
    else
      {:ok, _} -> {:error, {:conflict, "Invalid status Medication request for resend action!"}}
      {:intent, _} -> {:error, {:conflict, "For medication request plan information cannot be resent"}}
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
         {:intent, @intent_order} <- {:intent, medication_request["intent"]},
         :ok <- JsonSchema.validate(:medication_request_qualify, params),
         {:ok, medical_programs} <- get_medical_programs(params),
         medical_programs <- filter_medical_programs_data(medical_programs, medication_request),
         validations <- validate_programs(medical_programs, medication_request) do
      {:ok, medical_programs, validations}
    else
      {:intent, _} -> {:error, {:conflict, "Medication request with type (intent) PLAN cannot be qualified"}}
      err -> err
    end
  end

  def get_medication_requests(changes, client_type, headers) do
    do_get_medication_requests(get_consumer_id(headers), client_type, changes, headers)
  end

  defp do_get_medication_requests(_, "NHS", changes, headers) do
    employee_id = Map.get(changes, :employee_id)
    search_params = get_search_params([], changes)
    search_params = if is_nil(employee_id), do: Map.delete(search_params, :employee_id), else: search_params
    @ops_api.get_doctor_medication_requests(search_params, headers)
  end

  defp do_get_medication_requests(user_id, _, changes, headers) do
    with %PartyUser{party: party} <- get_party_user(user_id),
         employee_ids <- get_employees(party.id, Map.get(changes, :legal_entity_id)),
         :ok <- validate_employee_id(Map.get(changes, :employee_id), employee_ids),
         search_params <- get_search_params(employee_ids, changes) do
      @ops_api.get_doctor_medication_requests(search_params, headers)
    end
  end

  def get_medication_request(%{"id" => id}, client_type, headers) do
    do_get_medication_request(get_client_id(headers), get_consumer_id(headers), client_type, id, headers)
  end

  defp do_get_medication_request(_, _, "NHS", id, headers) do
    with {:ok, search_params} <- add_id_search_params(%{}, id),
         {:ok, %{"data" => [medication_request]}} <- @ops_api.get_doctor_medication_requests(search_params, headers) do
      {:ok, medication_request}
    else
      {:ok, %{"data" => []}} -> nil
      error -> error
    end
  end

  defp do_get_medication_request(legal_entity_id, user_id, _, id, headers) do
    with %PartyUser{party: party} <- get_party_user(user_id),
         %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(legal_entity_id),
         {:ok, search_params} <- get_show_search_params(party.id, legal_entity.id, legal_entity.type, id),
         {:ok, %{"data" => [medication_request]}} <- @ops_api.get_doctor_medication_requests(search_params, headers) do
      {:ok, medication_request}
    else
      {:ok, %{"data" => []}} -> nil
      :validation_error -> nil
      error -> error
    end
  end

  defp validate_employee_id(nil, _), do: :ok

  defp validate_employee_id(employee_id, employee_ids) do
    if Enum.member?(employee_ids, employee_id), do: :ok, else: {:error, :forbidden}
  end

  defp get_show_search_params(party_id, legal_entity_id, @legal_entity_msp_pharmacy, id) do
    get_show_search_params(party_id, legal_entity_id, @legal_entity_pharmacy, id)
  end

  defp get_show_search_params(party_id, legal_entity_id, @legal_entity_msp, id) do
    with employee_ids <- get_employees(party_id, legal_entity_id),
         {:ok, search_params} <- add_id_search_params(%{"employee_id" => Enum.join(employee_ids, ",")}, id) do
      {:ok, search_params}
    end
  end

  defp get_show_search_params(_, _, @legal_entity_pharmacy, id), do: add_id_search_params(%{}, id)

  defp add_id_search_params(search_params, id) do
    symbols = NumberGenerator.get_number_symbols()

    cond do
      Regex.match?(~r/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i, id) ->
        {:ok, Map.put(search_params, "id", id)}

      Regex.match?(~r/^[0]{4}-[#{symbols}]{4}-[#{symbols}]{4}-[#{symbols}]{4}/, id) ->
        {:ok, Map.put(search_params, "request_number", id)}

      true ->
        :validation_error
    end
  end

  defp get_search_params(employee_ids, %{person_id: person_id} = params) do
    Map.put(do_get_search_params(employee_ids, params), :person_id, person_id)
  end

  defp get_search_params(employee_ids, params), do: do_get_search_params(employee_ids, params)

  defp do_get_search_params(_employee_ids, %{employee_id: _employee_id} = params), do: params

  defp do_get_search_params(employee_ids, params) do
    Map.put(params, :employee_id, Enum.join(employee_ids, ","))
  end

  defp get_employees(party_id, nil) do
    do_get_employees(party_id: party_id)
  end

  defp get_employees(party_id, legal_entity_id) do
    do_get_employees(
      party_id: party_id,
      legal_entity_id: legal_entity_id
    )
  end

  defp do_get_employees(params) do
    params
    |> Employees.list!()
    |> Enum.map(&Map.get(&1, :id))
  end

  defp get_party_user(user_id) do
    with [party_user] <- PartyUsers.list!(%{user_id: user_id}) do
      party_user
    else
      _ ->
        Logger.error(fn ->
          Jason.encode!(%{
            "log_type" => "error",
            "message" => "No party user for user_id: \"#{user_id}\"",
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

        {:error, %{"type" => "internal_error"}}
    end
  end

  def get_references(medication_request) do
    with %Division{} = division <- Divisions.get_by_id(medication_request["division_id"]),
         %Employee{} = employee <- Employees.get_by_id(medication_request["employee_id"]),
         %INNMDosage{} = medication <- Medications.get_innm_dosage_by_id(medication_request["medication_id"]),
         %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(medication_request["legal_entity_id"]),
         {:ok, %{"data" => person}} <- @mpi_api.person(medication_request["person_id"], []) do
      result =
        medication_request
        |> Map.put("division", division)
        |> Map.put("employee", employee)
        |> Map.put("legal_entity", legal_entity)
        |> Map.put("medication", medication)
        |> Map.put("person", person)

      with false <- is_nil(medication_request["medical_program_id"]),
           %MedicalProgram{} = medical_program <- MedicalPrograms.get_by_id(medication_request["medical_program_id"]) do
        {:ok, Map.put(result, "medical_program", medical_program)}
      else
        true ->
          {:ok, result}

        _ ->
          Error.dump(%ValidationError{
            description: "Medication request is not valid",
            path: "$.medication_request_id",
            rule: :required
          })
      end
    else
      _ ->
        Error.dump(%ValidationError{
          description: "Medication request is not valid",
          path: "$.medication_request_id",
          rule: :required
        })
    end
  end

  defp changeset(params) do
    cast(%Search{}, params, Search.__schema__(:fields))
  end

  defp validate_innm(program, medication_request) do
    ids =
      Enum.reduce(program.program_medications, [], fn program_medication, acc ->
        [program_medication.medication.id] ++ acc
      end)

    ingredients =
      Ingredient
      |> join(:left, [i], m in assoc(i, :medication))
      |> where([i], i.parent_id in ^ids and i.is_primary)
      |> where([i], i.medication_child_id == ^medication_request["medication_id"])
      |> where([i, m], m.is_active)
      |> select([i, m], count(m.id))
      |> @read_prm_repo.one()

    if ingredients > 0 do
      :ok
    else
      {:error, "Innm not on the list of approved innms for program 'DOSTUPNI LIKI' !"}
    end
  end

  def get_check_innm_id(medication_request) do
    medication_id = medication_request["medication_id"]

    with %INNMDosage{} = medication <- Medications.get_innm_dosage_by_id(medication_id),
         ingredient <- Enum.find(medication.ingredients, &Map.get(&1, :is_primary)) do
      {:ok, ingredient.innm_child_id}
    else
      _ ->
        {:error,
         [{%{description: "Medication request is not valid", params: [], rule: :required}, "$.medication_request_id"}]}
    end
  end

  defp validate_programs(medical_programs, medication_request) do
    # Currently supports the only program "доступні ліки"
    Enum.reduce(medical_programs, %{}, fn program, acc ->
      with :ok <- validate_innm(program, medication_request),
           {:ok, check_innm_id} <- get_check_innm_id(medication_request),
           {:ok, %{"data" => medication_ids}} <- get_qualify_requests(medication_request),
           :ok <- validate_ingredients(medication_ids, check_innm_id) do
        Map.put(acc, program.id, :ok)
      else
        error -> Map.put(acc, program.id, error)
      end
    end)
  end

  defp get_qualify_requests(%{} = medication_request) do
    medication_request
    |> Map.take(~w(person_id started_at ended_at))
    |> @ops_api.get_qualify_medication_requests([])
  end

  defp validate_ingredients(medication_ids, check_innm_id) do
    ingredients =
      INNMDosageIngredient
      |> where([idi], idi.parent_id in ^medication_ids)
      |> where([idi], idi.is_primary and idi.innm_child_id == ^check_innm_id)
      |> @read_prm_repo.all()

    if Enum.empty?(ingredients) do
      :ok
    else
      {:error,
       "For the patient at the same term there can be only" <>
         " 1 dispensed medication request per one and the same innm!"}
    end
  end

  defp get_medical_programs(%{"programs" => programs}) do
    medical_programs =
      Enum.map(programs, fn %{"id" => id} ->
        MedicalProgram
        |> where([mp], mp.is_active)
        |> @read_prm_repo.get(id)
      end)

    errors =
      medical_programs
      |> Enum.with_index()
      |> Enum.filter(fn {medical_program, _} -> is_nil(medical_program) end)

    if Enum.empty?(errors) do
      {:ok, medical_programs}
    else
      {:error,
       Enum.map(errors, fn {nil, i} ->
         {%{description: "Medical program not found", params: [], rule: :required}, "$.programs[#{i}].id"}
       end)}
    end
  end

  defp filter_medical_programs_data(programs, %{"medication_id" => medication_id}) do
    Enum.map(programs, fn %{id: id} ->
      with {program_medications_ids, medications_ids} <- get_medical_programs_data_ids(id, medication_id) do
        MedicalProgram
        |> where([mp], mp.is_active)
        |> join(
          :left,
          [mp],
          pm in ProgramMedication,
          pm.medical_program_id == mp.id and pm.is_active and pm.id in ^program_medications_ids
        )
        |> join(:left, [mp, pm], m in assoc(pm, :medication), m.id in ^medications_ids)
        |> preload([mp, pm, m], program_medications: {pm, medication: m})
        |> @read_prm_repo.get(id)
      end
    end)
  end

  defp get_medical_programs_data_ids(medical_program_id, medication_id) do
    ids =
      Ingredient
      |> join(
        :inner,
        [ing],
        m in Medication,
        ing.parent_id == m.id and ing.medication_child_id == ^medication_id and ing.is_primary == true
      )
      |> join(
        :inner,
        [ing, m],
        pm in ProgramMedication,
        ing.parent_id == pm.medication_id and pm.medical_program_id == ^medical_program_id and pm.is_active == true
      )
      |> select([ing, m, pm], {pm.id, m.id})
      |> @read_prm_repo.all()

    program_medications_ids = Enum.map(ids, fn {program_medications_ids, _} -> program_medications_ids end)
    medications_ids = Enum.map(ids, fn {_, medications_id} -> medications_id end)

    {program_medications_ids, medications_ids}
  end

  defp validate_medication_request_status(%{"status" => "ACTIVE"}), do: :ok

  defp validate_medication_request_status(_) do
    {:conflict, "Invalid status Medication request for qualify action!"}
  end

  defp decode_signed_content(
         %{"signed_medication_reject" => signed_content, "signed_content_encoding" => encoding},
         headers
       ) do
    SignatureValidator.validate(signed_content, encoding, headers)
  end

  defp check_medication_dispenses(%{"id" => medication_request_id}, headers) do
    params = %{"status" => "NEW,PROCESSED", "medication_request_id" => medication_request_id}

    with {:ok, %{"data" => []}} <- @ops_api.get_medication_dispenses(params, headers) do
      :ok
    else
      _ -> {:error, {:conflict, "Medication request with connected processed medication dispenses can not be rejected"}}
    end
  end

  defp compare_with_db(content, medication_request) do
    db_content =
      "show.json"
      |> MedicationRequestsRenderer.render(medication_request)
      |> Jason.encode!()
      |> Jason.decode!()

    content = Map.delete(content, "reject_reason")
    ContentValidator.compare_with_db(content, db_content, "medication_request_reject")
  end

  defp save_signed_content(id, %{"signed_medication_reject" => signed_content}, headers) do
    signed_content
    |> @media_storage_api.store_signed_content(
      :medication_request_bucket,
      id,
      "medication_request_reject",
      headers
    )
    |> case do
      {:ok, _} -> :ok
      _error -> {:error, {:bad_gateway, "Failed to save signed content"}}
    end
  end
end

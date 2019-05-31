defmodule Core.MedicationRequestRequests do
  @moduledoc """
  The MedicationRequestRequests context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset
  import Core.API.Helpers.Connection

  use Confex, otp_app: :core

  alias Core.Employees
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.MedicalPrograms
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.MedicationRequestRequest
  alias Core.MedicationRequestRequest.CreateDataOperation
  alias Core.MedicationRequestRequest.Operation
  alias Core.MedicationRequestRequest.PreloadFkOperation
  alias Core.MedicationRequestRequest.RejectOperation
  alias Core.MedicationRequestRequest.Search
  alias Core.MedicationRequestRequest.SignOperation
  alias Core.MedicationRequestRequest.Validations
  alias Core.MedicationRequests.SMSSender
  alias Core.Medications
  alias Core.Medications.INNMDosage
  alias Core.Medications.INNMDosage.Ingredient, as: INNMDosageIngredient
  alias Core.Medications.Medication
  alias Core.Medications.Medication.Ingredient
  alias Core.Medications.Program, as: ProgramMedication
  alias Core.Repo
  alias Core.Utils.NumberGenerator
  alias Core.Utils.Phone
  alias Core.ValidationError
  alias Core.Validators.Error

  @status_new MedicationRequestRequest.status(:new)
  @status_signed MedicationRequestRequest.status(:signed)
  @status_expired MedicationRequestRequest.status(:expired)
  @status_rejected MedicationRequestRequest.status(:rejected)

  @ops_api Application.get_env(:core, :api_resolvers)[:ops]
  @read_repo Application.get_env(:core, :repos)[:read_repo]
  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @doc """
  Returns the list of medication_request_requests.

  ## Examples

      iex> list_medication_request_requests()
      [%MedicationRequestRequest{}, ...]

  """
  def list_medication_request_requests do
    @read_repo.all(MedicationRequestRequest)
  end

  def list_medication_request_requests(params, headers) do
    with %Ecto.Changeset{valid?: true, changes: changes} <- changeset(params) do
      MedicationRequestRequest
      |> filter_by_employee_id(changes, headers)
      |> filter_by_person_id(changes)
      |> filter_by_status(changes)
      |> filter_by_intent(changes)
      |> order_by(desc: :inserted_at)
      |> @read_repo.paginate(params)
      |> preload_fk()
    end
  end

  defp changeset(params) do
    cast(%Search{}, params, Search.__schema__(:fields))
  end

  defp filter_by_employee_id(query, %{employee_id: employee_id}, _) do
    where(query, [r], r.data_employee_id == ^employee_id)
  end

  defp filter_by_employee_id(query, _, headers) do
    employee_ids = get_employee_ids_from_headers(headers)
    where(query, [r], r.data_employee_id in ^employee_ids)
  end

  defp preload_fk(page) do
    entries =
      Enum.map(page.entries, fn e ->
        operation = PreloadFkOperation.preload(e)
        Map.merge(operation.data, %{medication_request_request: e})
      end)

    Map.put(page, :entries, entries)
  end

  defp get_employee_ids_from_headers(headers) do
    headers
    |> get_consumer_id()
    |> Employees.get_by_user_id()
    |> Enum.filter(fn e -> e.legal_entity_id == get_client_id(headers) end)
    |> Enum.map(fn e -> e.id end)
  end

  defp filter_by_status(query, %{status: status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end

  defp filter_by_status(query, _), do: query

  defp filter_by_person_id(query, %{person_id: person_id}) when is_binary(person_id) do
    where(query, [r], r.data_person_id == ^person_id)
  end

  defp filter_by_person_id(query, _), do: query

  defp filter_by_intent(query, %{intent: intent}) when is_binary(intent) do
    where(query, [r], r.data_intent == ^intent)
  end

  defp filter_by_intent(query, _), do: query

  def show(id) do
    with %MedicationRequestRequest{} = mrr <- get_medication_request_request(id) do
      operation = PreloadFkOperation.preload(mrr)
      {:ok, Map.merge(operation.data, %{medication_request_request: mrr})}
    end
  end

  def get_medication_request_request(id), do: @read_repo.get(MedicationRequestRequest, id)
  def get_medication_request_request!(id), do: @read_repo.get!(MedicationRequestRequest, id)
  def get_medication_request_request_by_query(clauses), do: @read_repo.get_by(MedicationRequestRequest, clauses)

  @doc """
  Creates a medication_request_request.

  ## Examples

      iex> create(%{field: value})
      {:ok, %MedicationRequestRequest{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs, user_id, client_id) do
    with :ok <- Validations.validate_create_schema(:generic, attrs),
         intent <-
           attrs
           |> Map.get("intent")
           |> String.to_atom(),
         :ok <- Validations.validate_create_schema(intent, attrs),
         :ok <- validate_legal_entity(client_id) do
      create_operation = CreateDataOperation.create(attrs, client_id)

      case create_operation
           |> create_changeset(attrs, user_id, client_id)
           |> Repo.insert() do
        {:ok, inserted_entity} ->
          urgent_data = prepare_urgent_data(create_operation.data.person)
          {:ok, Map.merge(create_operation.data, %{medication_request_request: inserted_entity}), urgent_data}

        {:error, %Ecto.Changeset{errors: [request_number: {"has already been taken", []}]}} ->
          create(attrs, user_id, client_id)

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      err -> err
    end
  end

  defp validate_legal_entity(id) do
    allowed_types = Confex.fetch_env!(:core, :medication_request_request_legal_entity_types)

    with %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(id),
         {_, true} <- {:status, legal_entity.is_active && legal_entity.status == LegalEntity.status(:active)},
         {_, true} <- {:nhs_verified, legal_entity.nhs_verified},
         {_, true} <- {:type, legal_entity.type in allowed_types} do
      :ok
    else
      {:status, _} ->
        {:error, {:conflict, "Legal entity is not active"}}

      {:nhs_verified, _} ->
        {:error, {:conflict, "Legal entity is not verified"}}

      {:type, _} ->
        {:error, {:conflict, "Invalid legal entity type"}}

      _ ->
        {:error, %{"type" => "internal_error"}}
    end
  end

  def prequalify(attrs, user_id, client_id) do
    with :ok <- Validations.validate_prequalify_schema(attrs),
         %{"medication_request_request" => mrr, "programs" => programs} <- attrs,
         :ok <- check_intent(mrr),
         create_operation <- CreateDataOperation.create(mrr, client_id),
         %Ecto.Changeset{valid?: true} <- create_changeset(create_operation, mrr, user_id, client_id),
         :ok <- validate_medical_programs(attrs),
         :ok <- validate_existing_medication_requests(attrs) do
      {:ok, prequalify_programs(mrr, programs)}
    else
      err -> err
    end
  end

  @doc false
  def create_changeset(create_operation, attrs, user_id, _client_id) do
    %MedicationRequestRequest{}
    |> cast(attrs, [:request_number, :status, :inserted_by, :updated_by])
    |> put_embed(:data, create_operation.changeset)
    |> put_change(:status, @status_new)
    |> put_change(:request_number, NumberGenerator.generate(0))
    |> put_change(:verification_code, put_verification_code(create_operation))
    |> put_change(:inserted_by, user_id)
    |> put_change(:updated_by, user_id)
    |> put_change(:medication_request_id, Ecto.UUID.generate())
    |> validate_required([:data, :request_number, :status, :inserted_by, :updated_by])
    |> unique_constraint(:request_number, name: :medication_request_requests_number_index)
  end

  defp put_verification_code(%Operation{valid?: true} = operation) do
    otp = Enum.find(operation.data.person.authentication_methods, nil, fn method -> method.type == "OTP" end)
    if otp, do: NumberGenerator.generate_otp_verification_code(), else: nil
  end

  defp put_verification_code(_), do: nil

  defp prequalify_programs(mrr, programs) do
    programs
    |> Enum.map(fn %{"id" => program_id} ->
      %{
        id: program_id,
        data: Validations.validate_medication_id(mrr["medication_id"], mrr["medication_qty"], program_id),
        mrr: mrr
      }
    end)
    |> Enum.map(fn validated_result -> show_program_status(validated_result) end)
  end

  def get_check_innm_id(medication_id) do
    with %INNMDosage{} = medication <- Medications.get_innm_dosage_by_id(medication_id),
         ingredient <- Enum.find(medication.ingredients, &Map.get(&1, :is_primary)) do
      {:ok, ingredient.innm_child_id}
    end
  end

  defp get_prequalify_requests(%{} = medication_request) do
    medication_request
    |> Map.take(~w(person_id started_at ended_at))
    |> @ops_api.get_prequalify_medication_requests([])
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
      :error
    end
  end

  defp show_program_status(%{id: _id, data: {:ok, result}, mrr: mrr}) do
    mp = Enum.at(result, 0)

    with {program_medications_ids, medications_ids} <-
           get_medical_programs_data_ids(mp.medical_program_id, mrr["medication_id"]),
         medical_program <-
           get_medical_program_with_participants(mp.medical_program_id, program_medications_ids, medications_ids),
         participants <- build_participants(medical_program.program_medications),
         {:ok, check_innm_id} <- get_check_innm_id(mrr["medication_id"]),
         {:ok, %{"data" => medication_ids}} <- get_prequalify_requests(mrr),
         :ok <- validate_ingredients(medication_ids, check_innm_id) do
      %{id: mp.medical_program_id, name: mp.medical_program_name, status: "VALID", participants: participants}
    else
      _ ->
        %{
          id: mp.medical_program_id,
          name: mp.medical_program_name,
          status: "INVALID",
          rejection_reason:
            "It can be only 1 active/ completed medication request request or " <>
              "medication request per one innm for the same patient at the same period of time!"
        }
    end
  end

  defp show_program_status(%{id: id, data: _err, mrr: _}) do
    mp = MedicalPrograms.get_by_id(id)

    mp
    |> Map.put(:status, "INVALID")
    |> Map.put(:rejection_reason, "Innm not on the list of approved innms for program \"#{mp.name}\"")
  end

  defp build_participants(program_medications) do
    Enum.map(program_medications, fn program_medication ->
      program_medication.medication
      |> Map.take(~w(id name form manufacturer)a)
      |> Map.put("reimbursement_amount", program_medication.reimbursement.reimbursement_amount)
    end)
  end

  defp get_medical_program_with_participants(id, program_medications_ids, medications_ids) do
    MedicalProgram
    |> where([mp], mp.is_active)
    |> join(
      :left,
      [mp],
      pm in ProgramMedication,
      on: pm.medical_program_id == mp.id and pm.is_active and pm.id in ^program_medications_ids
    )
    |> join(:left, [mp, pm], m in assoc(pm, :medication), on: m.id in ^medications_ids)
    |> preload([mp, pm, m], program_medications: {pm, medication: m})
    |> @read_prm_repo.get(id)
  end

  defp get_medical_programs_data_ids(medical_program_id, medication_id) do
    ids =
      Ingredient
      |> join(
        :inner,
        [ing],
        m in Medication,
        on: ing.parent_id == m.id and ing.medication_child_id == ^medication_id and ing.is_primary == true
      )
      |> join(
        :inner,
        [ing, m],
        pm in ProgramMedication,
        on: ing.parent_id == pm.medication_id and pm.medical_program_id == ^medical_program_id and pm.is_active == true
      )
      |> select([ing, m, pm], {pm.id, m.id})
      |> @read_prm_repo.all()

    program_medications_ids = Enum.map(ids, fn {program_medications_ids, _} -> program_medications_ids end)
    medications_ids = Enum.map(ids, fn {_, medications_id} -> medications_id end)

    {program_medications_ids, medications_ids}
  end

  def reject(id, user_id, client_id) do
    with %MedicationRequestRequest{} = mrr <- get_medication_request_request(id),
         %Ecto.Changeset{} = changeset <- reject_changeset(mrr, user_id),
         {:ok, mrr} <- Repo.update(changeset),
         operation <- RejectOperation.reject(changeset, mrr, client_id) do
      {:ok, Map.merge(operation.data, %{medication_request_request: mrr})}
    end
  end

  def reject_changeset(%MedicationRequestRequest{status: @status_new} = record, user_id) do
    record
    |> change
    |> put_change(:status, @status_rejected)
    |> put_change(:updated_by, user_id)
  end

  def reject_changeset(%MedicationRequestRequest{}, _),
    do: {:error, {:conflict, "Invalid status Request for Medication request for reject transition!"}}

  def reject_changeset(nil, _), do: {:error, :not_found}

  def autoterminate do
    Repo.update_all(
      termination_query(),
      set: [
        status: @status_expired,
        updated_at: Timex.now(),
        updated_by: Confex.fetch_env!(:core, :system_user)
      ]
    )
  end

  defp termination_query do
    minutes = Confex.fetch_env!(:core, :medication_request_request)[:expire_in_minutes]
    termination_time = Timex.shift(Timex.now(), minutes: -minutes)

    MedicationRequestRequest
    |> where([mrr], mrr.status == ^@status_new)
    |> where([mrr], mrr.inserted_at < ^termination_time)
  end

  def sign(params, headers) do
    {id, params} = Map.pop(params, "id")

    with :ok <- Validations.validate_sign_schema(params),
         %MedicationRequestRequest{status: "NEW"} = mrr <- get_medication_request_request_by_query(id: id),
         employee_ids <- get_employee_ids_from_headers(headers),
         :ok <- doctor_authorized_to_sign?(employee_ids, mrr),
         {operation, {:ok, mrr}} <- SignOperation.sign(mrr, params, headers) do
      mrr
      |> sign_changeset
      |> Repo.update()

      SMSSender.maybe_send_sms(mrr, operation.data.person, &SMSSender.sign_template/1)

      {:ok,
       operation.data.medication_request
       |> Map.put("legal_entity", operation.data.legal_entity)
       |> Map.put("division", operation.data.division)
       |> Map.put("person", operation.data.person)
       |> Map.put("employee", operation.data.employee)
       |> Map.put("medical_program", operation.data.medical_program)
       |> Map.put("legal_entity", operation.data.legal_entity)
       |> Map.put("medication", operation.data.medication)}
    else
      %MedicationRequestRequest{status: _} ->
        {:error, {:conflict, "Invalid status Medication request Request for sign transition!"}}

      err ->
        err
    end
  end

  defp doctor_authorized_to_sign?(employee_ids, mrr) do
    if mrr.data.employee_id in employee_ids do
      :ok
    else
      {:error, {:forbidden, "Only doctor that in Medication request Request can sign it"}}
    end
  end

  def sign_changeset(mrr) do
    mrr
    |> change
    |> put_change(:status, @status_signed)
  end

  defp validate_medical_programs(%{"programs" => programs}) do
    errors =
      programs
      |> Enum.map(fn %{"id" => id} -> @read_prm_repo.get(MedicalProgram, id) end)
      |> Enum.with_index()
      |> Enum.reduce([], fn {medical_program, i}, acc ->
        case medical_program do
          nil ->
            acc ++
              [
                %ValidationError{
                  description: "Medical program not found",
                  rule: :required,
                  path: "$.programs.[#{i}].id"
                }
              ]

          %MedicalProgram{is_active: false} ->
            acc ++
              [
                %ValidationError{
                  description: "Medical program is not active",
                  path: "$.programs.[#{i}].id"
                }
              ]

          _ ->
            acc
        end
      end)

    if Enum.empty?(errors) do
      :ok
    else
      Error.dump(errors)
    end
  end

  defp validate_existing_medication_requests(%{"medication_request_request" => data, "programs" => programs}) do
    errors =
      programs
      |> Enum.map(fn %{"id" => id} -> Validations.validate_existing_medication_requests(data, id) end)
      |> Enum.with_index()
      |> Enum.reduce([], fn {validation_result, i}, acc ->
        case validation_result do
          {:invalid_existing_medication_requests, nil} ->
            acc ++
              [
                %ValidationError{
                  description:
                    "It's to early to create new medication request for such innm_dosage and medical_program_id",
                  path: "$.programs.[#{i}].id"
                }
              ]

          _ ->
            acc
        end
      end)

    if Enum.empty?(errors) do
      :ok
    else
      Error.dump(errors)
    end
  end

  defp check_intent(%{"intent" => "plan"}), do: {:error, {:conflict, "Plan can't be qualified"}}
  defp check_intent(%{"intent" => _}), do: :ok

  def prepare_urgent_data(%{authentication_methods: authentication_methods}) do
    filtered_authentication_method_current =
      authentication_methods
      |> List.first()
      |> filter_authentication_method()
      |> Map.take(~w(type phone_number)a)

    %{
      authentication_method_current: filtered_authentication_method_current
    }
  end

  defp filter_authentication_method(nil), do: %{}
  defp filter_authentication_method(%{phone_number: nil} = method), do: method

  defp filter_authentication_method(%{phone_number: number} = method) do
    Map.put(method, :phone_number, Phone.hide_number(number))
  end

  defp filter_authentication_method(method), do: method
end

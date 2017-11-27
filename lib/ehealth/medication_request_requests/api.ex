defmodule EHealth.MedicationRequestRequests do
  @moduledoc """
  The MedicationRequestRequests context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset
  import EHealth.Utils.Connection

  use Confex, otp_app: :ehealth

  alias EHealth.Repo
  alias EHealth.PRMRepo
  alias EHealth.API.OPS
  alias EHealth.Employees
  alias EHealth.MedicalPrograms
  alias EHealth.MedicationRequestRequest
  alias EHealth.MedicationRequests.SMSSender
  alias EHealth.MedicationRequestRequest.Operation
  alias EHealth.MedicationRequestRequest.Validations
  alias EHealth.MedicationRequestRequest.SignOperation
  alias EHealth.Medications
  alias EHealth.MedicationRequestRequest.RejectOperation
  alias EHealth.MedicationRequestRequest.PreloadFkOperation
  alias EHealth.MedicationRequestRequest.CreateDataOperation
  alias EHealth.MedicalPrograms.MedicalProgram
  alias EHealth.Medications.INNMDosage
  alias EHealth.Medications.Program, as: ProgramMedication
  alias EHealth.Medications.INNMDosage.Ingredient, as: INNMDosageIngredient
  alias EHealth.MedicationRequestRequest.HumanReadableNumberGenerator, as: HRNGenerator

  @status_new EHealth.MedicationRequestRequest.status(:new)
  @status_signed EHealth.MedicationRequestRequest.status(:signed)
  @status_expired EHealth.MedicationRequestRequest.status(:expired)
  @status_rejected EHealth.MedicationRequestRequest.status(:rejected)

  @doc """
  Returns the list of medication_request_requests.

  ## Examples

      iex> list_medication_request_requests()
      [%MedicationRequestRequest{}, ...]

  """
  def list_medication_request_requests do
    Repo.all(MedicationRequestRequest)
  end

  def list_medication_request_requests(params, headers) do
    query = from dr in MedicationRequestRequest,
    order_by: [desc: :inserted_at]

    query
    |> filter_by_employee_id(params, headers)
    |> filter_by_person_id(params)
    |> filter_by_status(params)
    |> Repo.paginate(params)
    |> preload_fk()
  end

  defp filter_by_employee_id(query, %{"employee_id" => employee_id}, _) do
    where(query, [r], fragment("?->'employee_id' = ?", r.data, ^employee_id))
  end
  defp filter_by_employee_id(query, _, headers) do
    employee_ids = get_employee_ids_from_headers(headers)
    Enum.reduce(employee_ids, query, fn(id, query) ->
      or_where(query, [r], fragment("?->'employee_id' = ?", r.data, ^id))
    end)
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

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end
  defp filter_by_status(query, _), do: query

  defp filter_by_person_id(query, %{"person_id" => person_id}) when is_binary(person_id) do
    where(query, [r], fragment("?->'person_id' = ?", r.data, ^person_id))
  end
  defp filter_by_person_id(query, _), do: query

  def show(id) do
    mrr = get_medication_request_request(id)
    operation = PreloadFkOperation.preload(mrr)
    Map.merge(operation.data, %{medication_request_request: mrr})
  end

  def get_medication_request_request(id), do: Repo.get(MedicationRequestRequest, id)
  def get_medication_request_request!(id), do: Repo.get!(MedicationRequestRequest, id)
  def get_medication_request_request_by_query(clauses), do: Repo.get_by(MedicationRequestRequest, clauses)
  @doc """
  Creates a medication_request_request.

  ## Examples

      iex> create(%{field: value})
      {:ok, %MedicationRequestRequest{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs, user_id, client_id) do
    with :ok <- Validations.validate_create_schema(attrs)
    do
      create_operation = CreateDataOperation.create(attrs, client_id)
      case create_operation
           |> create_changeset(attrs, user_id, client_id)
           |> Repo.insert() do
        {:ok, inserted_entity} ->
          {:ok, Map.merge(create_operation.data, %{medication_request_request: inserted_entity})}
        {:error, %Ecto.Changeset{errors: [request_number: {"has already been taken", []}]}} ->
          create(attrs, user_id, client_id)
        {:error, changeset} -> {:error, changeset}
      end
    else
      err -> err
    end
  end

  def prequalify(attrs, user_id, client_id) do
    with :ok <- Validations.validate_prequalify_schema(attrs),
        %{"medication_request_request" => mrr, "programs" => programs} <- attrs,
        create_operation <- CreateDataOperation.create(mrr, client_id),
        %Ecto.Changeset{valid?: true} <- create_changeset(create_operation, mrr, user_id, client_id)
    do
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
    |> put_change(:request_number, HRNGenerator.generate(1))
    |> put_change(:verification_code, put_verification_code(create_operation))
    |> put_change(:inserted_by, user_id)
    |> put_change(:updated_by, user_id)
    |> put_change(:medication_request_id, Ecto.UUID.generate())
    |> validate_required([:data, :request_number, :status, :inserted_by, :updated_by])
    |> unique_constraint(:request_number, name: :medication_request_requests_number_index)
  end

  defp put_verification_code(%Operation{valid?: true} = operation) do
    otp = Enum.find(operation.data.person["authentication_methods"], nil, fn method -> method["type"] == "OTP" end)
    if otp do
      HRNGenerator.generate_otp_verification_code()
    else
      nil
    end
  end
  defp put_verification_code(_), do: nil

  def changeset(%MedicationRequestRequest{} = medication_request_request, attrs) do
    medication_request_request
    |> cast(attrs, [:data, :request_number, :status, :inserted_by, :updated_by])
    |> validate_required([:data, :request_number, :status, :inserted_by, :updated_by])
  end

  defp prequalify_programs(mrr, programs) do
    programs
    |> Enum.map(fn %{"id" => program_id} ->
      %{id: program_id,
        data: Validations.validate_medication_id(mrr["medication_id"], mrr["medication_qty"], program_id),
        mrr: mrr}
    end)
    |> Enum.map(fn validated_result -> show_program_status(validated_result) end)
  end

  def get_check_innm_id(medication_id) do
    with %INNMDosage{} = medication <- Medications.get_innm_dosage_by_id(medication_id),
         ingredient <- Enum.find(medication.ingredients, &(Map.get(&1, :is_primary)))
    do
      {:ok, ingredient.innm_child_id}
    end
  end

  defp get_prequalify_requests(%{} = medication_request) do
    medication_request
    |> Map.take(~w(person_id started_at ended_at))
    |> OPS.get_prequalify_medication_requests()
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
      :error
    end
  end

  defp show_program_status(%{id: _id, data: {:ok, result}, mrr: mrr}) do
    mp = Enum.at(result, 0)
    with medical_program <- get_medical_program_with_participants(mp.medical_program_id),
         participants <- build_participants(medical_program.program_medications),
         {:ok, check_innm_id} <- get_check_innm_id(mrr["medication_id"]),
         {:ok, %{"data" => medication_ids}} <- get_prequalify_requests(mrr),
         :ok <- validate_ingredients(medication_ids, check_innm_id)
    do
        %{id: mp.medical_program_id, name: mp.medical_program_name, status: "VALID", participants: participants}
    else
        _ ->  %{id: mp.medical_program_id, name: mp.medical_program_name, status: "INVALID",
                rejection_reason: "It can be only 1 active/ completed medication request request or " <>
                "medication request per one innm for the same patient at the same period of time!"}
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
      |> Map.put("reimbursement_amount", program_medication.reimbursement["reimbursement_amount"])
    end)
  end

  defp get_medical_program_with_participants(id) do
    MedicalProgram
    |> where([mp], mp.is_active)
    |> join(:left, [mp], pm in ProgramMedication, pm.medical_program_id == mp.id and pm.is_active)
    |> join(:left, [mp, pm], m in assoc(pm, :medication))
    |> preload([mp, pm, m], [program_medications: {pm, medication: m}])
    |> PRMRepo.get(id)
  end

  def reject(id, user_id, client_id) do
    with %MedicationRequestRequest{} = mrr <- get_medication_request_request(id),
         %Ecto.Changeset{} = changeset <- reject_changeset(mrr, user_id),
         {:ok, mrr} <- Repo.update(changeset),
         operation <- RejectOperation.reject(changeset, mrr, client_id)
    do
      {:ok, Map.merge(operation.data, %{medication_request_request: mrr})}
    end
  end

  def reject_changeset(%MedicationRequestRequest{status: @status_new} = record, user_id) do
    record
    |> change
    |> put_change(:status, @status_rejected)
    |> put_change(:updated_by, user_id)
  end
  def reject_changeset(%MedicationRequestRequest{}, _), do:
    {:error, {:conflict, "Invalid status Request for Medication request for reject transition!"}}
  def reject_changeset(nil, _), do: {:error, :not_found}

  def autoterminate do
    Repo.update_all(termination_query(), set: [
        status: @status_expired,
        updated_at: Timex.now,
        updated_by: Confex.fetch_env!(:ehealth, :system_user)
        ])
  end

  defp termination_query do
    minutes = Confex.fetch_env!(:ehealth, :medication_request_request)[:expire_in_minutes]
    termination_time = Timex.shift(Timex.now, minutes: -minutes)

    MedicationRequestRequest
    |> where([mrr], mrr.status == ^@status_new)
    |> where([mrr], mrr.inserted_at < ^termination_time)
  end

  def sign(params, headers) do
    {id, params} = Map.pop(params, "id")
    with :ok <- Validations.validate_sign_schema(params),
         %MedicationRequestRequest{status: "NEW"} = mrr <- get_medication_request_request_by_query([id: id]),
         employee_ids <- get_employee_ids_from_headers(headers),
         :ok <- doctor_authorized_to_sign?(employee_ids, mrr),
         {operation, {:ok, mrr}} <- SignOperation.sign(mrr, params, headers)
    do
      mrr
      |> sign_changeset
      |> Repo.update

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
      err -> err
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
end

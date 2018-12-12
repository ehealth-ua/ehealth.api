defmodule Core.MedicationRequestRequest.Validations do
  @moduledoc false

  alias Core.Declarations.API, as: DeclarationsAPI
  alias Core.Dictionaries
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.MedicationRequestRequest.Renderer, as: MedicationRequestRequestRenderer
  alias Core.Medications
  alias Core.Validators.Content, as: ContentValidator
  alias Core.Validators.JsonSchema
  alias Core.Validators.Signature, as: SignatureValidator

  @rpc_worker Application.get_env(:core, :rpc_worker)

  def validate_create_schema(:generic, params) do
    JsonSchema.validate(:medication_request_request_create_generic, params)
  end

  def validate_create_schema(:order, params) do
    JsonSchema.validate(:medication_request_request_create_order, params)
  end

  def validate_create_schema(:plan, params) do
    JsonSchema.validate(:medication_request_request_create_plan, params)
  end

  def validate_prequalify_schema(params) do
    JsonSchema.validate(:medication_request_request_prequalify, params)
  end

  def validate_sign_schema(params) do
    JsonSchema.validate(:medication_request_request_sign, params)
  end

  def validate_doctor(doctor, legal_entity) do
    with true <- doctor.employee_type == "DOCTOR",
         true <- doctor.status == "APPROVED",
         true <- doctor.legal_entity.id == legal_entity.id do
      {:ok, doctor}
    else
      _ -> {:invalid_employee, doctor}
    end
  end

  def validate_person(person) do
    with true <- person["is_active"] do
      {:ok, person}
    else
      _ -> {:invalid_person, person}
    end
  end

  def validate_declaration_existance(employee, person) do
    with {:ok, %{declarations: declarations}} <-
           DeclarationsAPI.get_declarations(
             %{"employee_id" => employee.id, "person_id" => person["id"], "status" => "active"},
             []
           ),
         true <- length(declarations) > 0 do
      {:ok, declarations}
    else
      _ -> {:invalid_declarations_count, nil}
    end
  end

  def validate_divison(division, legal_entity_id) do
    with true <- division.is_active && division.status == "ACTIVE" && division.legal_entity_id == legal_entity_id do
      {:ok, division}
    else
      _ -> {:invalid_division, division}
    end
  end

  def validate_medication_id(medication_id, medication_qty, medical_program_id) do
    with medications <- Medications.get_medication_for_medication_request_request(medication_id, medical_program_id),
         {true, :medication} <- {length(medications) > 0, :medication},
         {true, :medication_qty} <- validate_medication_qty(medications, medication_qty) do
      {:ok, medications}
    else
      {false, :medication} -> {:invalid_medication, nil}
      {false, :medication_qty} -> {:invalid_medication_qty, nil}
    end
  end

  defp validate_medication_qty(medications, medication_qty) do
    {0 in Enum.map(medications, fn med -> rem(medication_qty, med.package_min_qty) end), :medication_qty}
  end

  def validate_medical_event_entity(nil, _), do: {:ok, nil}

  def validate_medical_event_entity(context, patient_id) do
    type =
      context
      |> get_in(~w(identifier type coding))
      |> hd()
      |> Map.get("code")
      |> String.to_atom()

    entity_id = get_in(context, ~w(identifier value))

    do_validate_medical_event_entity(type, patient_id, entity_id)
  end

  defp do_validate_medical_event_entity(:encounter, patient_id, entity_id) do
    case @rpc_worker.run("me", Core.Rpc, :encounter_status_by_id, [patient_id, entity_id]) do
      {:ok, "entered_in_error"} ->
        {:invalid_encounter, nil}

      {:ok, _} ->
        {:ok, nil}

      _ ->
        {:not_found_encounter, nil}
    end
  end

  def validate_dosage_instruction(nil), do: {:ok, nil}

  def validate_dosage_instruction(dosage_instruction) do
    with :ok <- validate_sequences(dosage_instruction),
         :ok <- validate_codeable(dosage_instruction) do
      {:ok, nil}
    end
  end

  defp validate_sequences(dosage_instruction) do
    sequences = Enum.map(dosage_instruction, &Map.get(&1, "sequence"))

    if Enum.uniq(sequences) == sequences do
      :ok
    else
      {:sequence_error, nil}
    end
  end

  defp validate_codeable(dosage_instruction) do
    dosage_instruction
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {instruction, instruction_index}, acc ->
      with :ok <-
             do_validate_codeable(instruction["additional_instruction"], "additional instruction", fn i ->
               "$.dosage_instruction[#{Enum.at(i, 0)}].additional_instruction[#{Enum.at(i, 1)}].coding[#{Enum.at(i, 2)}].code"
             end),
           :ok <-
             do_validate_codeable(instruction["site"], "site", fn i ->
               "$.dosage_instruction[#{Enum.at(i, 0)}].site.coding[#{Enum.at(i, 1)}].code"
             end),
           :ok <-
             do_validate_codeable(instruction["route"], "route", fn i ->
               "$.dosage_instruction[#{Enum.at(i, 0)}].route.coding[#{Enum.at(i, 1)}].code"
             end),
           :ok <-
             do_validate_codeable(instruction["method"], "method", fn i ->
               "$.dosage_instruction[#{Enum.at(i, 0)}].method.coding[#{Enum.at(i, 1)}].code"
             end),
           :ok <-
             do_validate_codeable(instruction["dose_and_rate"]["type"], "dose and rate type", fn i ->
               "$.dosage_instruction[#{Enum.at(i, 0)}].dose_and_rate.type.coding[#{Enum.at(i, 1)}].code"
             end) do
        {:cont, acc}
      else
        {:error,
         %{
           description: description,
           indexes: indexes,
           path: path_fun
         }} ->
          indexes = [instruction_index | Enum.reject(indexes, &is_nil/1)]
          {:halt, {:invalid_dosage_instruction, %{description: description, path: path_fun.(indexes)}}}
      end
    end)
  end

  defp do_validate_codeable(codeable, description, path_fun) when is_list(codeable) do
    codeable
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {codeable_item, codeable_index}, acc ->
      case do_validate_codeable(codeable_item, description, path_fun) do
        :ok ->
          {:cont, acc}

        {:error,
         %{
           description: description,
           indexes: [nil, coding_index],
           path: path_fun
         }} ->
          {:halt,
           {:error,
            %{
              description: description,
              indexes: [codeable_index, coding_index],
              path: path_fun
            }}}
      end
    end)
  end

  defp do_validate_codeable(codeable, description, path_fun) do
    codeable
    |> Map.get("coding")
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {%{
                                    "system" => system,
                                    "code" => code
                                  }, coding_index},
                                 acc ->
      {:ok, [dictionary]} = Dictionaries.list_dictionaries(%{name: system, is_active: true})

      if Map.has_key?(dictionary.values, code) do
        {:cont, acc}
      else
        {:halt,
         {:error,
          %{
            description: description,
            indexes: [nil, coding_index],
            path: path_fun
          }}}
      end
    end)
  end

  def decode_sign_content(content, headers) do
    SignatureValidator.validate(
      content["signed_medication_request_request"],
      content["signed_content_encoding"],
      headers
    )
  end

  def validate_sign_content(mrr, operation) do
    with false <- is_nil(Map.get(operation.data, :decoded_content)),
         %{"content" => content, "signers" => [signer]} = operation.data.decoded_content,
         %Employee{} = employee <- Employees.get_by_id(mrr.data.employee_id),
         doctor_tax_id <- employee |> Map.get(:party) |> Map.get(:tax_id),
         true <- doctor_tax_id == signer["drfo"],
         :ok <- compare_with_db(content, mrr, operation) do
      {:ok, mrr}
    else
      _ -> {:error, {:"422", "Signed content does not match the previously created content!"}}
    end
  end

  defp compare_with_db(content, medication_request_request, operation) do
    mrr_data =
      operation.data
      |> Map.delete(:decoded_content)
      |> Map.merge(%{medication_request_request: medication_request_request})

    db_content =
      "medication_request_request_detail.json"
      |> MedicationRequestRequestRenderer.render(mrr_data)
      |> Jason.encode!()
      |> Jason.decode!()

    ContentValidator.compare_with_db(content, db_content, "medication_request_request_sign")
  end

  def validate_dates(attrs) do
    cond do
      attrs["ended_at"] < attrs["started_at"] ->
        {:invalid_state, {:ended_at, "Ended date must be >= Started date!"}}

      attrs["started_at"] < attrs["created_at"] ->
        {:invalid_state, {:started_at, "Started date must be >= Created date!"}}

      attrs["started_at"] < to_string(Timex.today()) ->
        {:invalid_state, {:started_at, "Started date must be >= Current date!"}}

      attrs["dispense_valid_from"] < attrs["started_at"] ->
        {:invalid_state, {:dispense_valid_from, "Dispense valid from date must be >= Started date!"}}

      attrs["dispense_valid_to"] < attrs["dispense_valid_from"] ->
        {:invalid_state, {:dispense_valid_from, "Dispense valid to date must be >= Dispense valid from date!"}}

      true ->
        {:ok, nil}
    end
  end
end

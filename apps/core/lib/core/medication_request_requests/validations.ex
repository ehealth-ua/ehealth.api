defmodule Core.MedicationRequestRequest.Validations do
  @moduledoc false

  import Ecto.Changeset
  require Logger

  alias Core.Declarations.API, as: DeclarationsAPI
  alias Core.Dictionaries
  alias Core.GlobalParameters
  alias Core.MedicationRequestRequest.EmbeddedData
  alias Core.MedicationRequestRequest.Renderer, as: MedicationRequestRequestRenderer
  alias Core.MedicationRequests.MedicationRequest
  alias Core.Medications
  alias Core.Rpc.Error, as: RpcError
  alias Core.Validators.Content, as: ContentValidator
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Core.Validators.Signature, as: SignatureValidator

  @rpc_worker Application.get_env(:core, :rpc_worker)
  @intent_order EmbeddedData.intent(:order)

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
    case @rpc_worker.run("medical_events_api", Api.Rpc, :encounter_status_by_id, [patient_id, entity_id]) do
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

  defp do_validate_codeable(nil, _, _), do: :ok

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

  def validate_dispense_valid_from(operation, %{"intent" => @intent_order} = attrs) do
    {:ok,
     Map.put(
       operation,
       :changeset,
       put_change(operation.changeset, :dispense_valid_from, Date.from_iso8601!(attrs["created_at"]))
     )}
  end

  def validate_dispense_valid_from(operation, _attrs), do: {:ok, operation}

  def validate_dispense_valid_to(operation, %{"intent" => @intent_order}) do
    medication_dispense_period =
      GlobalParameters.get_values()
      |> Map.get("medication_dispense_period")
      |> String.to_integer()

    {:ok,
     Map.put(
       operation,
       :changeset,
       put_change(
         operation.changeset,
         :dispense_valid_to,
         Date.add(operation.changeset.changes.dispense_valid_from, medication_dispense_period)
       )
     )}
  end

  def validate_dispense_valid_to(operation, _attrs), do: {:ok, operation}

  def validate_treatment_period(
        %{
          changeset: %{
            changes: %{
              started_at: started_at,
              ended_at: ended_at,
              dispense_valid_from: dispense_valid_from,
              dispense_valid_to: dispense_valid_to
            }
          }
        },
        %{"intent" => @intent_order}
      ) do
    treatment_period = Timex.diff(ended_at, started_at, :days)
    medication_dispense_period = Timex.diff(dispense_valid_to, dispense_valid_from, :days)

    if treatment_period < medication_dispense_period do
      {:invalid_period, nil}
    else
      {:ok, nil}
    end
  end

  def validate_treatment_period(_operation, _attrs), do: {:ok, nil}

  def validate_existing_medication_requests(_data, nil), do: {:ok, nil}

  def validate_existing_medication_requests(%{"intent" => @intent_order} = data, medical_program_id) do
    search_params = %{
      "person_id" => data["person_id"],
      "medication_id" => data["medication_id"],
      "medical_program_id" => medical_program_id,
      "status" => Enum.join([MedicationRequest.status(:active), MedicationRequest.status(:completed)], ",")
    }

    case @rpc_worker.run("ops", Core.Rpc, :last_medication_request_dates, [search_params]) do
      {:ok, nil} ->
        {:ok, nil}

      {:ok, %{"ended_at" => last_mr_ended_at} = medication_request_dates} ->
        with :ok <- validate_started_at(Date.from_iso8601!(data["started_at"]), last_mr_ended_at) do
          do_validate_existing_medication_requests(medication_request_dates, Date.from_iso8601!(data["created_at"]))
        end

      {:error, error} ->
        Logger.error(
          "RPC fail: Core.Rpc.last_medication_request_dates: #{inspect(search_params)} with error #{inspect(error)}"
        )

        raise(RpcError, message: "Cannot fetch persons medication requests")
    end
  end

  def validate_existing_medication_requests(_data, _medical_program_id), do: {:ok, nil}

  defp do_validate_existing_medication_requests(
         %{"started_at" => last_mr_started_at, "ended_at" => last_mr_ended_at},
         created_at
       ) do
    config = Confex.fetch_env!(:core, :medication_request_request)
    mrr_standard_duration = config[:standard_duration]
    min_mrr_renew_days = config[:min_renew_days]
    max_mrr_renew_days = config[:max_renew_days]

    comparison_period = Date.diff(last_mr_ended_at, last_mr_started_at)

    with {:greater_than_today, true} <-
           {:greater_than_today, Date.compare(last_mr_ended_at, Date.utc_today()) in [:gt, :eq]},
         {:greater_than_mrr_standard_duration, true} <-
           {:greater_than_mrr_standard_duration, comparison_period >= mrr_standard_duration} do
      if Date.compare(created_at, Date.add(last_mr_ended_at, -max_mrr_renew_days)) in [:gt, :eq] and
           Date.compare(Date.add(last_mr_ended_at, -max_mrr_renew_days), Date.utc_today()) in [:gt, :eq] do
        {:ok, nil}
      else
        {:invalid_existing_medication_requests, nil}
      end
    else
      {:greater_than_today, false} ->
        {:ok, nil}

      {:greater_than_mrr_standard_duration, false} ->
        if Date.compare(created_at, Date.add(last_mr_ended_at, -min_mrr_renew_days)) in [:gt, :eq] and
             Date.compare(Date.add(last_mr_ended_at, -min_mrr_renew_days), Date.utc_today()) in [:gt, :eq] do
          {:ok, nil}
        else
          {:invalid_existing_medication_requests, nil}
        end
    end
  end

  def validate_started_at(started_at, last_mr_ended_at) do
    if Date.compare(started_at, last_mr_ended_at) == :gt do
      :ok
    else
      {:invalid_started_at, nil}
    end
  end

  def decode_sign_content(content, headers) do
    with {:ok, result} <-
           SignatureValidator.validate(
             content["signed_medication_request_request"],
             content["signed_content_encoding"],
             headers
           ) do
      {:ok, result}
    else
      {:error, {:bad_request, reason}} ->
        {:invalid_signature, reason}

      error ->
        error
    end
  end

  def validate_sign_content(mrr, %{data: %{decoded_content: decoded_content}} = operation) do
    with %{"content" => content, "signers" => [signer]} <- decoded_content,
         :ok <-
           SignatureValidator.check_drfo(
             signer,
             mrr.data.employee_id,
             "$.employee_id.drfo",
             "medication_dispense_process"
           ),
         {:comparison, :ok} <- {:comparison, compare_with_db(content, mrr, operation)} do
      {:ok, mrr}
    else
      {:comparison, _} -> Error.dump("Signed content does not match the previously created content!")
      error -> error
    end
  end

  def validate_sign_content(_, _) do
    Error.dump("Signed content does not match the previously created content!")
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
    medication_request_request_delay_input = Confex.fetch_env!(:core, :medication_request_request)[:delay_input]

    boundary_date =
      Date.utc_today()
      |> Date.add(-medication_request_request_delay_input)
      |> Date.to_string()

    cond do
      compare_dates(attrs["ended_at"], attrs["started_at"]) == :lt ->
        {:invalid_state, {:ended_at, "Ended date must be >= Started date!"}}

      compare_dates(attrs["started_at"], attrs["created_at"]) == :lt ->
        {:invalid_state, {:started_at, "Started date must be >= Created date!"}}

      compare_dates(attrs["started_at"], to_string(Date.utc_today())) == :lt ->
        {:invalid_state, {:started_at, "Started date must be >= Current date!"}}

      compare_dates(attrs["created_at"], boundary_date) == :lt ->
        {:invalid_state, {:created_at, "Create date must be >= Current date - MRR delay input!"}}

      true ->
        {:ok, nil}
    end
  end

  defp compare_dates(date1, date2) when is_binary(date1) and is_binary(date2) do
    Date.compare(Date.from_iso8601!(date1), Date.from_iso8601!(date2))
  end
end

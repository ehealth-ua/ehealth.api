defmodule EHealth.Medications do
  @moduledoc """
  The Medications context.
  """

  use EHealth.Search, EHealth.PRMRepo

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.PRMRepo
  alias EHealth.Medications.INNM
  alias EHealth.Medications.INNM.Search, as: INNMSearch
  alias EHealth.Medications.INNMDosage
  alias EHealth.Medications.INNMDosage.Search, as: INNMDosageSearch
  alias EHealth.Medications.Medication.Ingredient, as: MedicationIngredient
  alias EHealth.Medications.Medication
  alias EHealth.Medications.Medication.Search, as: MedicationSearch
  alias EHealth.Medications.Program, as: ProgramMedication
  alias EHealth.Medications.Program.Search, as: ProgramMedicationSearch
  alias EHealth.MedicalPrograms.MedicalProgram
  alias EHealth.Medications.DrugsSearch
  alias EHealth.Validators.JsonSchema
  alias EHealth.Medications.Validator

  @type_innm_dosage INNMDosage.type()
  @type_medication Medication.type()

  @fields_innm_required [:name, :name_original, :inserted_by, :updated_by]
  @fields_innm_optional [:sctid, :is_active]

  @fields_medication_required [:name, :type, :form, :inserted_by, :updated_by]
  @fields_medication_optional [
    :manufacturer,
    :code_atc,
    :is_active,
    :container,
    :package_qty,
    :package_min_qty,
    :certificate,
    :certificate_expired_at,
  ]
  @fields_innm_dosage_optional [:is_active]

  @fields_program_medication_required [:reimbursement, :medication_id, :medical_program_id, :inserted_by, :updated_by]
  @fields_program_medication_optional [:medication_request_allowed, :is_active]

  # List

  def get_by_ids(ids) do
    Medication
    |> where([e], e.id in ^ids)
    |> PRMRepo.all()
  end

  def get_drugs(params) do
    %DrugsSearch{}
    |> cast(params, DrugsSearch.__schema__(:fields))
    |> search_drugs(params)
  end

  defp search_drugs(%{valid?: true, changes: attrs}, params) do
    INNMDosage
    |> distinct(true)
    # get primary INNMDosage ingredients
    |> join(:inner, [id], ii in assoc(id, :ingredients))
    |> where([_, ii], ii.is_primary)
    # get active INNM
    |> join(:inner, [_, ii], i in assoc(ii, :innm))
    # get primary Medication ingredients related to INNMDosage
    |> join(:inner, [id], idi in assoc(id, :ingredients_medication))
    |> where([..., idi], idi.is_primary)
    # get active Medication
    |> join(:inner, [..., idi], m in assoc(idi, :medication))
    |> where_drugs_attrs(attrs)
    # group by primary keys
    |> group_by([innm], innm.id)
    |> group_by([_, innm_ingrdient], innm_ingrdient.id)
    |> group_by([_, _, innm_dosage], innm_dosage.id)
    |> select(
         [innm_dosage, innm_ingredient, innm, _, medication],
         %{
           innm_id: innm.id,
           innm_name: innm.name,
           innm_name_original: innm.name_original,
           innm_sctid: innm.sctid,
           innm_dosage_id: innm_dosage.id,
           innm_dosage_name: innm_dosage.name,
           innm_dosage_form: innm_dosage.form,
           innm_dosage_dosage: innm_ingredient.dosage,
           packages:
             fragment("array_agg((?, ?, ?))", medication.container, medication.package_qty, medication.package_min_qty),
         }
       )
    |> PRMRepo.paginate(params)
  end
  defp search_drugs(changeset, _params) do
    changeset
  end

  defp where_drugs_attrs(query, attrs) do
    attrs
    |> Enum.reduce(
         query,
         fn {field, value}, query ->
           case field do
             :innm_id -> where(query, [_, _, innm], innm.id == ^value)
             :innm_name -> where(query, [_, _, innm], ilike(innm.name, ^("%" <> value <> "%")))
             :innm_sctid -> where(query, [_, _, innm], innm.sctid == ^value)
             :innm_dosage_id -> where(query, [innm_dosage], innm_dosage.id == ^value)
             :innm_dosage_name -> where(query, [innm_dosage], ilike(innm_dosage.name, ^("%" <> value <> "%")))
             :innm_dosage_form -> where(query, [innm_dosage], innm_dosage.form == ^value)
             :medication_code_atc -> where(query, [..., med], med.code_atc == ^value)
             _ -> query
           end
         end
       )
    |> where([innm_dosage, ...], innm_dosage.is_active)
    |> where([_, _, innm], innm.is_active)
    |> where([..., med], med.is_active)
  end

  def list_medications(params) do
    params = Map.put(params, "type", @type_medication)

    %MedicationSearch{}
    |> cast(params, MedicationSearch.__schema__(:fields))
    |> search(params, Medication)
  end

  def list_innm_dosages(params) do
    params = Map.put(params, "type", @type_innm_dosage)

    %INNMDosageSearch{}
    |> cast(params, INNMDosageSearch.__schema__(:fields))
    |> search(params, INNMDosage)
  end

  def get_search_query(Medication, changes) do
    params =
      changes
      |> Map.take([:id, :form, :type, :is_active])
      |> Enum.into([])

    Medication
    |> where(^params)
    |> join(:inner, [m], i in assoc(m, :ingredients))
    |> join(:inner, [..., i], id in assoc(i, :innm_dosage))
    |> where_innm_dosage_attrs(changes)
    |> where_medication_name(changes)
    |> where([_, i, _], i.is_primary)
    |> preload([ingredients: [innm_dosage: []]])
  end

  def get_search_query(INNMDosage, changes) do
    INNMDosage
    |> super(changes)
    |> preload(ingredients: [innm: []])
  end

  def get_search_query(entity, changes) do
    super(entity, changes)
  end

  defp where_medication_name(query, %{name: name}) do
    where(query, [m], ilike(m.name, ^("%" <> name <> "%")))
  end
  defp where_medication_name(query, _changes) do
    query
  end

  defp where_innm_dosage_attrs(query, attrs) do
    Enum.reduce(attrs, query, fn {field, value}, query ->
      case field do
        :innm_dosage_id -> where(query, [..., id], id.id == ^value)
        :innm_dosage_name -> where(query, [..., id], ilike(id.name, ^("%" <> value <> "%")))
        _ -> query
      end
    end)
  end

  # Get by id

  def get_innm_dosage_by_id(id), do: get_medication_entity_by_id(INNMDosage, id)

  def get_medication_by_id(id), do: get_medication_entity_by_id(Medication, id)

  defp get_medication_entity_by_id(entity, id) do
    entity
    |> join(:left, [e], i in assoc(e, :ingredients))
    |> join(:left, [e, i], id in assoc(i, :innm_dosage))
    |> join(:left, [e, i, id], idi in assoc(id, :ingredients))
    |> join(:left, [e, i, id, idi], innm in assoc(idi, :innm))
    |> preload([e, i, id, idi, innm], [ingredients: {i, innm_dosage: {id, ingredients: {idi, innm: innm}}}])
    |> PRMRepo.get_by([id: id, type: entity.type()])
  end

  def get_innm_dosage_by_id!(id), do: get_medication_entity_by_id!(INNMDosage, id)

  def get_medication_by_id!(id), do: get_medication_entity_by_id!(Medication, id)

  defp get_medication_entity_by_id!(entity, id) do
    entity
    |> PRMRepo.get_by!([id: id, type: entity.type()])
    |> preload_references()
  end

  def get_active_innm_dosage_by_id!(id), do: get_active_medication_entity_by_id!(INNMDosage, id)

  def get_active_medication_by_id!(id), do: get_active_medication_entity_by_id!(Medication, id)

  defp get_active_medication_entity_by_id!(entity, id) do
    entity
    |> PRMRepo.get_by!([id: id, type: entity.type(), is_active: true])
    |> preload_references()
  end

  def get_medication_for_medication_request_request(innm_dosage_id, program_id) do
    innm_dosage_id
    |> get_medication_for_medication_request_request_query()
    |> maybe_validate_medication_program_for_medication_request_request(innm_dosage_id, program_id)
    |> PRMRepo.all()
  end

  def maybe_validate_medication_program_for_medication_request_request(query, _, nil), do: query
  def maybe_validate_medication_program_for_medication_request_request(query, innm_dosage_id, program_id) do
    from q in query,
    inner_join: ing in MedicationIngredient, on: ing.medication_child_id == ^innm_dosage_id,
    inner_join: med in Medication, on: ing.parent_id == med.id,
    inner_join: mp in MedicalProgram, on: mp.id == ^program_id,
    inner_join: pm in ProgramMedication, on: mp.id == pm.medical_program_id and pm.medication_id == med.id,
    where: pm.is_active,
    where: pm.medication_request_allowed,
    select_merge: %{medical_program_id: mp.id, medical_program_name: mp.name}
  end

  def get_medication_for_medication_request_request_query(innm_dosage_id) do
    from innm_dosage in INNMDosage,
      inner_join: ing in MedicationIngredient, on: ing.medication_child_id == ^innm_dosage_id,
      inner_join: med in Medication, on: ing.parent_id == med.id,
      where: ing.is_primary,
      where: innm_dosage.id == ^innm_dosage_id,
      where: innm_dosage.type == ^INNMDosage.type(),
      where: innm_dosage.is_active,
      where: med.is_active,
      select: %{id: innm_dosage.id, medication_id: med.id,
                package_qty: med.package_qty, package_min_qty: med.package_min_qty}
  end

  # Create

  def create_innm_dosage(attrs, headers), do: create_medication_entity(INNMDosage, attrs, headers)

  def create_medication(attrs, headers), do: create_medication_entity(Medication, attrs, headers)

  defp create_medication_entity(entity, attrs, headers) do
    schema_type =
      case entity.type() do
        @type_innm_dosage -> :innm_dosage
        @type_medication -> :medication
      end

    case JsonSchema.validate(schema_type, attrs) do
      :ok ->
        consumer_id = get_consumer_id(headers)
        attrs = Map.merge(
          attrs,
          %{
            "type" => entity.type(),
            "inserted_by" => consumer_id,
            "updated_by" => consumer_id
          }
        )

        entity
        |> struct()
        |> changeset(attrs)
        |> PRMRepo.insert_and_log(consumer_id)
        |> preload_references()

      err -> err
    end
  end

  # Update

  @doc "Deactivate INNM dosage when it has no active medication"
  def deactivate_innm_dosage(%INNMDosage{} = entity, headers) do
    INNMDosage
    |> where([i], i.id == ^entity.id)
    |> join(:inner, [id], i in assoc(id, :ingredients_medication))
    |> where([..., i], i.is_primary)
    |> join(:inner, [..., i], m in assoc(i, :medication))
    |> where([..., m], m.is_active)
    |> select([..., m], count(m.id))
    |> PRMRepo.one()
    |> case do
         0 -> deactivate_medication_entity(entity, headers)
         _ -> {:error, {:conflict, "INNM Dosage has active Medications"}}
       end
  end

  def deactivate_medication(%Medication{id: id} = entity, headers) do
    case count_active_program_medications_by(medication_id: id) do
      0 -> deactivate_medication_entity(entity, headers)
      _ -> {:error, {:conflict, "Medication is participant of an active Medical Program"}}
    end
  end

  @doc false
  defp deactivate_medication_entity(entity, headers) do
    consumer_id = get_consumer_id(headers)

    attrs = %{
      is_active: false,
      updated_by: consumer_id
    }

    entity
    |> changeset(attrs)
    |> PRMRepo.update_and_log(consumer_id)
    |> preload_references()
  end

  # Changeset

  def changeset(%Medication{} = medication, attrs) do
    medication
    |> cast(attrs, @fields_medication_required ++ @fields_medication_optional)
    |> cast_assoc(:ingredients)
    |> validate_required(@fields_medication_required)
    |> Validator.validate_package_quantity()
    |> Validator.validate_ingredients()
  end

  def changeset(%INNMDosage{} = medication, attrs) do
    medication
    |> cast(attrs, @fields_medication_required ++ @fields_innm_dosage_optional)
    |> cast_assoc(:ingredients)
    |> validate_required(@fields_medication_required)
    |> foreign_key_constraint(:ingredients_innm_id)
    |> Validator.validate_ingredients()
  end

  def changeset(%INNM{} = innm, attrs) do
    innm
    |> cast(attrs, @fields_innm_required ++ @fields_innm_optional)
    |> unique_constraint(:sctid)
    |> validate_required(@fields_innm_required)
  end

  def changeset(%ProgramMedication{} = innm, attrs) do
    opts = [
      name: :program_medications_medication_id_medical_program_id_index,
      message: "Medication brand is already a participant of the program"
    ]

    innm
    |> cast(attrs, @fields_program_medication_required ++ @fields_program_medication_optional)
    |> validate_required(@fields_program_medication_required)
    |> foreign_key_constraint(:medication_id)
    |> foreign_key_constraint(:medical_program_id)
    |> unique_constraint(:medication_id, opts)
    |> Validator.validate_program_medication_is_active()
    |> Validator.validate_program_medication_requests_allowed()
    |> Validator.validate_medication_is_active()
    |> Validator.validate_medical_program_is_active()
  end

  # INNMs

  @doc false
  def list_innms(params) do
    %INNMSearch{}
    |> cast(params, INNMSearch.__schema__(:fields))
    |> search(params, INNM)
  end

  @doc false
  def get_innm!(id), do: PRMRepo.get!(INNM, id)

  @doc false
  def create_innm(attrs, headers) do
    case JsonSchema.validate(:innm, attrs) do
      :ok ->
        consumer_id = get_consumer_id(headers)

        %INNM{}
        |> changeset(put_consumer_id(attrs, headers))
        |> PRMRepo.insert_and_log(consumer_id)

      err -> err
    end
  end

  # Program Medication

  def list_program_medications(attrs) do
    %ProgramMedicationSearch{}
    |> cast(attrs, ProgramMedicationSearch.__schema__(:fields))
    |> search_program_medications(attrs)
  end

  defp search_program_medications(%{valid?: true, changes: attrs}, params) do
    ProgramMedication
    |> join(:inner, [pm], m in assoc(pm, :medication))
    |> join(:inner, [pm], mp in assoc(pm, :medical_program))
    |> join(:inner, [_, m], i in assoc(m, :ingredients))
    |> join(:inner, [..., i], id in assoc(i, :innm_dosage))
    |> where_innm_dosage_attrs(attrs)
    |> where_program_medications_attrs(attrs)
    |> where([..., i, _id], i.is_primary)
    |> preload([_, m, mp, i, id], [medication: {m, ingredients: {i, innm_dosage: id}}, medical_program: mp])
    |> select([program_medication], program_medication)
    |> PRMRepo.paginate(params)
  end
  defp search_program_medications(changeset, _params) do
    changeset
  end

  defp where_program_medications_attrs(query, attrs) do
    attrs
    |> Enum.reduce(
         query,
         fn {field, value}, query ->
           case field do
             :id -> where(query, [program_medication], program_medication.id == ^value)
             :is_active -> where(query, [program_medication], program_medication.is_active)
             :medication_id -> where(query, [_, med], med.id == ^value)
             :medication_name -> where(query, [_, med], ilike(med.name, ^("%" <> value <> "%")))
             :medical_program_id -> where(query, [_, _, mp], mp.id == ^value)
             :medical_program_name -> where(query, [_, _, mp], ilike(mp.name, ^("%" <> value <> "%")))
             _ -> query
           end
         end
       )
    |> where([_, medication], medication.is_active)
  end

  def get_program_medication!(id), do: PRMRepo.get!(ProgramMedication, id)

  def get_program_medication!(id, :preload) do
    ProgramMedication
    |> PRMRepo.get!(id)
    |> preload_references()
  end

  def count_active_program_medications_by(params) when is_list(params) do
    params = [is_active: true] ++ params

    ProgramMedication
    |> where(^params)
    |> select([pm], count(pm.id))
    |> PRMRepo.one()
  end

  def create_program_medication(attrs, headers) do
    case JsonSchema.validate(:program_medication, attrs) do
      :ok ->
        consumer_id = get_consumer_id(headers)

        %ProgramMedication{}
        |> changeset(put_consumer_id(attrs, headers))
        |> PRMRepo.insert_and_log(consumer_id)
        |> preload_references()

      err -> err
    end
  end

  def update_program_medication(%ProgramMedication{} = program_medication, attrs, headers) do
    case JsonSchema.validate(:program_medication_update, attrs) do
      :ok ->
        consumer_id = get_consumer_id(headers)

        program_medication
        |> changeset(put_consumer_id(attrs, headers))
        |> PRMRepo.update_and_log(consumer_id)
        |> preload_references()

      err -> err
    end
  end

  defp preload_references({:ok, entity}) do
    {:ok, preload_references(entity)}
  end
  defp preload_references(%ProgramMedication{} = program) do
    PRMRepo.preload(program, [medication: [ingredients: [innm_dosage: []]], medical_program: []])
  end
  defp preload_references(%Medication{} = medication) do
    PRMRepo.preload(medication, ingredients: [innm_dosage: []])
  end
  defp preload_references(%INNMDosage{} = innm_dosage) do
    PRMRepo.preload(innm_dosage, ingredients: [innm: []])
  end
  defp preload_references(entity) do
    entity
  end

  # helpers

  defp put_consumer_id(attrs, headers) do
    consumer_id = get_consumer_id(headers)
    Map.merge(attrs, %{"inserted_by" => consumer_id, "updated_by" => consumer_id})
  end
end

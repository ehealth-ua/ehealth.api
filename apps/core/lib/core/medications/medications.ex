defmodule Core.Medications do
  @moduledoc """
  The Medications context.
  """

  use Core.Search, Application.get_env(:core, :repos)[:read_prm_repo]

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Medications.DrugsSearch
  alias Core.Medications.INNM
  alias Core.Medications.INNM.Search, as: INNMSearch
  alias Core.Medications.INNMDosage
  alias Core.Medications.INNMDosage.Search, as: INNMDosageSearch
  alias Core.Medications.Medication
  alias Core.Medications.Medication.Ingredient, as: MedicationIngredient
  alias Core.Medications.Medication.Search, as: MedicationSearch
  alias Core.Medications.Program, as: ProgramMedication
  alias Core.Medications.Program.Reimbursement
  alias Core.Medications.Program.Search, as: ProgramMedicationSearch
  alias Core.Medications.Validator
  alias Core.PRMRepo
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Scrivener.Page

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

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
    :daily_dosage
  ]
  @fields_innm_dosage_optional [:is_active]

  @fields_program_medication_required [:medication_id, :medical_program_id, :inserted_by, :updated_by]
  @fields_program_medication_optional [
    :medication_request_allowed,
    :is_active,
    :wholesale_price,
    :consumer_price,
    :reimbursement_daily_dosage,
    :estimated_payment_amount
  ]

  # List

  def get_by_ids(ids) do
    Medication
    |> where([e], e.id in ^ids)
    |> @read_prm_repo.all()
  end

  def get_drugs(params) do
    %DrugsSearch{}
    |> cast(params, DrugsSearch.__schema__(:fields))
    |> search_drugs(params)
  end

  defp search_drugs(%{valid?: true, changes: attrs}, params) do
    page_number = 1

    page_number =
      case Integer.parse(Map.get(params, "page", "")) do
        {int, _} -> max(int, page_number)
        :error -> page_number
      end

    page_size = 50

    page_size =
      case Integer.parse(Map.get(params, "page_size", "")) do
        {int, _} -> if int > 0, do: int, else: page_size
        :error -> page_size
      end

    offset = page_size * (page_number - 1)

    # get primary INNMDosage ingredients
    # get active INNM
    # get primary Medication ingredients related to INNMDosage
    # get active Medication
    # group by primary keys
    query =
      INNMDosage
      |> distinct(true)
      |> join(:inner, [id], ii in assoc(id, :ingredients))
      |> where([_, ii], ii.is_primary)
      |> join(:inner, [_, ii], i in assoc(ii, :innm))
      |> join(:inner, [id], idi in assoc(id, :ingredients_medication))
      |> where([..., idi], idi.is_primary)
      |> join(:inner, [..., idi], m in assoc(idi, :medication))
      |> join_program_medications(attrs)
      |> where_drugs_attrs(attrs)
      |> do_select(attrs)
      |> subquery()
      |> group_by([a], a.innm_id)
      |> group_by([a], a.innm_name)
      |> group_by([a], a.innm_name_original)
      |> group_by([a], a.innm_sctid)
      |> group_by([a], a.innm_dosage_id)
      |> group_by([a], a.innm_dosage_name)
      |> group_by([a], a.innm_dosage_form)
      |> group_by([a], a.innm_dosage_dosage)
      |> select([a], %{
        innm_id: a.innm_id,
        innm_name: a.innm_name,
        innm_name_original: a.innm_name_original,
        innm_sctid: a.innm_sctid,
        innm_dosage_id: a.innm_dosage_id,
        innm_dosage_name: a.innm_dosage_name,
        innm_dosage_form: a.innm_dosage_form,
        innm_dosage_dosage: a.innm_dosage_dosage,
        packages:
          fragment(
            "array_agg((?, ?, ?))",
            a.medication_container,
            a.medication_package_qty,
            a.medication_package_min_qty
          )
      })

    dataset =
      query
      |> limit([a], ^page_size)
      |> offset([], ^offset)
      |> @read_prm_repo.all()

    total_entries =
      query
      |> @read_prm_repo.all()
      |> length()

    total_pages =
      if page_size != 0 do
        trunced = trunc(total_entries / page_size)
        if trunced < total_entries / page_size, do: trunced + 1, else: trunced
      else
        1
      end

    %Page{
      entries: dataset,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    }
  end

  defp search_drugs(changeset, _params) do
    changeset
  end

  defp join_program_medications(query, %{medical_program_id: _}) do
    join(query, :inner, [..., m], pm in ProgramMedication, pm.medication_id == m.id)
  end

  defp join_program_medications(query, _), do: query

  defp where_drugs_attrs(query, attrs) do
    query
    |> do_where_drugs_attrs(attrs)
    |> where([innm_dosage, ...], innm_dosage.is_active)
    |> where([_, _, innm], innm.is_active)
    |> do_where_medication_conditions(attrs)
  end

  defp do_where_drugs_attrs(query, attrs) do
    Enum.reduce(attrs, query, fn
      {:innm_id, value}, query ->
        where(query, [_, _, innm], innm.id == ^value)

      {:innm_name, value}, query ->
        where(query, [_, _, innm], ilike(innm.name, ^("%" <> value <> "%")))

      {:innm_sctid, value}, query ->
        where(query, [_, _, innm], innm.sctid == ^value)

      {:innm_dosage_id, value}, query ->
        where(query, [innm_dosage], innm_dosage.id == ^value)

      {:innm_dosage_name, value}, query ->
        where(query, [innm_dosage], ilike(innm_dosage.name, ^("%" <> value <> "%")))

      {:innm_dosage_form, value}, query ->
        where(query, [innm_dosage], innm_dosage.form == ^value)

      {:medication_code_atc, value}, query ->
        if Map.has_key?(attrs, :medical_program_id) do
          where(query, [..., med, _], fragment("? @> ?", med.code_atc, ^value))
        else
          where(query, [..., med], fragment("? @> ?", med.code_atc, ^value))
        end

      {:medical_program_id, value}, query ->
        where(query, [..., pm], pm.medical_program_id == ^value and pm.is_active and pm.medication_request_allowed)

      _, query ->
        query
    end)
  end

  defp do_where_medication_conditions(query, %{medical_program_id: _}) do
    where(query, [..., med, _], med.is_active)
  end

  defp do_where_medication_conditions(query, _) do
    where(query, [..., med], med.is_active)
  end

  defp do_select(query, %{medical_program_id: _}) do
    select(query, [innm_dosage, innm_ingredient, innm, _, medication, program_medications], %{
      innm_id: innm.id,
      innm_name: innm.name,
      innm_name_original: innm.name_original,
      innm_sctid: innm.sctid,
      innm_dosage_id: innm_dosage.id,
      innm_dosage_name: innm_dosage.name,
      innm_dosage_form: innm_dosage.form,
      innm_dosage_dosage: innm_ingredient.dosage,
      medication_container: medication.container,
      medication_package_qty: medication.package_qty,
      medication_package_min_qty: medication.package_min_qty,
      medical_program_id: program_medications.medical_program_id
    })
  end

  defp do_select(query, _) do
    select(query, [innm_dosage, innm_ingredient, innm, _, medication], %{
      innm_id: innm.id,
      innm_name: innm.name,
      innm_name_original: innm.name_original,
      innm_sctid: innm.sctid,
      innm_dosage_id: innm_dosage.id,
      innm_dosage_name: innm_dosage.name,
      innm_dosage_form: innm_dosage.form,
      innm_dosage_dosage: innm_ingredient.dosage,
      medication_container: medication.container,
      medication_package_qty: medication.package_qty,
      medication_package_min_qty: medication.package_min_qty
    })
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
    |> preload(ingredients: [innm_dosage: []])
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

  def fetch_innm_dosage_by_id(id), do: fetch_medication_entity_by_id(INNMDosage, id)

  def fetch_medication_by_id(id), do: fetch_medication_entity_by_id(Medication, id)

  defp get_medication_entity_by_id(entity, id) do
    entity
    |> join(:left, [e], i in assoc(e, :ingredients))
    |> join(:left, [e, i], id in assoc(i, :innm_dosage))
    |> join(:left, [e, i, id], idi in assoc(id, :ingredients))
    |> join(:left, [e, i, id, idi], innm in assoc(idi, :innm))
    |> preload([e, i, id, idi, innm], ingredients: {i, innm_dosage: {id, ingredients: {idi, innm: innm}}})
    |> @read_prm_repo.get_by(id: id, type: entity.type())
  end

  def fetch_medication_entity_by_id(entity, id) do
    case get_medication_entity_by_id(entity, id) do
      %{__struct__: ^entity} = item -> {:ok, item}
      _ -> {:error, {:not_found, "Medication entity not found"}}
    end
  end

  def get_innm_dosage_by_id!(id), do: get_medication_entity_by_id!(INNMDosage, id)

  def get_medication_by_id!(id), do: get_medication_entity_by_id!(Medication, id)

  defp get_medication_entity_by_id!(entity, id) do
    entity
    |> @read_prm_repo.get_by!(id: id, type: entity.type())
    |> preload_references()
  end

  def get_active_innm_dosage_by_id!(id), do: get_active_medication_entity_by_id!(INNMDosage, id)

  def get_active_medication_by_id!(id), do: get_active_medication_entity_by_id!(Medication, id)

  defp get_active_medication_entity_by_id!(entity, id) do
    entity
    |> @read_prm_repo.get_by!(id: id, type: entity.type(), is_active: true)
    |> preload_references()
  end

  def get_medication_for_medication_request_request(innm_dosage_id, program_id) do
    innm_dosage_id
    |> get_medication_for_medication_request_request_query()
    |> maybe_validate_medication_program_for_medication_request_request(program_id)
    |> @read_prm_repo.all()
  end

  def maybe_validate_medication_program_for_medication_request_request(query, nil), do: query

  def maybe_validate_medication_program_for_medication_request_request(query, program_id) do
    query
    |> join(:inner, [...], mp in MedicalProgram, mp.id == ^program_id)
    |> join(
      :inner,
      [innm_dosage, ing, med, mp],
      pm in ProgramMedication,
      mp.id == pm.medical_program_id and pm.medication_id == med.id
    )
    |> where([..., pm], pm.is_active == true)
    |> where([..., pm], pm.medication_request_allowed == true)
    |> select_merge([innm_dosage, ing, med, mp, pm], %{medical_program_id: mp.id, medical_program_name: mp.name})
  end

  def get_medication_for_medication_request_request_query(innm_dosage_id) do
    INNMDosage
    |> join(:inner, [innm_dosage], ing in MedicationIngredient, ing.medication_child_id == ^innm_dosage_id)
    |> join(:inner, [innm_dosage, ing], med in Medication, ing.parent_id == med.id)
    |> where([innm_dosage, ing, med], ing.is_primary == true)
    |> where([innm_dosage], innm_dosage.id == ^innm_dosage_id)
    |> where([innm_dosage], innm_dosage.type == ^INNMDosage.type())
    |> where([innm_dosage], innm_dosage.is_active == true)
    |> where([..., med], med.is_active == true)
    |> select([innm_dosage, ing, med], %{
      id: innm_dosage.id,
      medication_id: med.id,
      package_qty: med.package_qty,
      package_min_qty: med.package_min_qty
    })
  end

  # Create

  def create_innm_dosage(attrs, actor_id), do: create_medication_entity(INNMDosage, attrs, actor_id)

  def create_medication(attrs, actor_id) do
    code_atc = Map.get(attrs, "code_atc")

    case check_duplicates_in_list(code_atc, "code_atc", "atc codes are duplicated") do
      :ok ->
        create_medication_entity(Medication, attrs, actor_id)

      err ->
        err
    end
  end

  defp check_duplicates_in_list(attr, attr_name, error_description) when is_list(attr) do
    if attr == Enum.uniq(attr) do
      :ok
    else
      Error.dump(%ValidationError{description: error_description, path: "$." <> attr_name})
    end
  end

  defp check_duplicates_in_list(_, _, _), do: :ok

  defp create_medication_entity(entity, attrs, actor_id) do
    schema_type =
      case entity.type() do
        @type_innm_dosage -> :innm_dosage
        @type_medication -> :medication
      end

    case JsonSchema.validate(schema_type, attrs) do
      :ok ->
        attrs =
          Map.merge(attrs, %{
            "type" => entity.type(),
            "inserted_by" => actor_id,
            "updated_by" => actor_id
          })

        entity
        |> struct()
        |> changeset(attrs)
        |> PRMRepo.insert_and_log(actor_id)
        |> preload_references()

      err ->
        err
    end
  end

  # Update

  @doc "Deactivate INNM dosage when it has no active medication"
  def deactivate_innm_dosage(%INNMDosage{} = entity, actor_id) do
    INNMDosage
    |> where([i], i.id == ^entity.id)
    |> join(:inner, [id], i in assoc(id, :ingredients_medication))
    |> where([..., i], i.is_primary)
    |> join(:inner, [..., i], m in assoc(i, :medication))
    |> where([..., m], m.is_active)
    |> select([..., m], count(m.id))
    |> @read_prm_repo.one()
    |> case do
      0 -> deactivate_medication_entity(entity, actor_id)
      _ -> {:error, {:conflict, "INNM Dosage has active Medications"}}
    end
  end

  def deactivate_medication(%Medication{id: id} = entity, actor_id) do
    case count_active_program_medications_by(medication_id: id) do
      0 -> deactivate_medication_entity(entity, actor_id)
      _ -> {:error, {:conflict, "Medication is participant of an active Medical Program"}}
    end
  end

  @doc false
  defp deactivate_medication_entity(entity, actor_id) do
    attrs = %{
      is_active: false,
      updated_by: actor_id
    }

    entity
    |> changeset(attrs)
    |> PRMRepo.update_and_log(actor_id)
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

  def changeset(%ProgramMedication{} = program_medication, attrs) do
    opts = [
      name: :program_medications_medication_id_medical_program_id_index,
      message: "Medication brand is already a participant of the program"
    ]

    program_medication
    |> cast(attrs, @fields_program_medication_required ++ @fields_program_medication_optional)
    |> validate_required(@fields_program_medication_required)
    |> cast_embed(:reimbursement, with: &Reimbursement.changeset/2, required: true)
    |> foreign_key_constraint(:medication_id)
    |> foreign_key_constraint(:medical_program_id)
    |> unique_constraint(:medication_id, opts)
    # TODO: these validations should go outside of changeset and fail with CONFLICT errors
    |> Validator.validate_program_medication_is_active()
    |> Validator.validate_program_medication_requests_allowed()
    |> Validator.validate_program_medication_reimbursement()
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
  def get_innm!(id), do: @read_prm_repo.get!(INNM, id)

  @doc false
  def create_innm(attrs, actor_id) do
    case JsonSchema.validate(:innm, attrs) do
      :ok ->
        %INNM{}
        |> changeset(Map.merge(attrs, %{"inserted_by" => actor_id, "updated_by" => actor_id}))
        |> PRMRepo.insert_and_log(actor_id)

      err ->
        err
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
    |> preload([_, m, mp, i, id], medication: {m, ingredients: {i, innm_dosage: id}}, medical_program: mp)
    |> select([program_medication], program_medication)
    |> @read_prm_repo.paginate(params)
  end

  defp search_program_medications(changeset, _params) do
    changeset
  end

  defp where_program_medications_attrs(query, attrs) do
    attrs
    |> Enum.reduce(query, fn {field, value}, query ->
      case field do
        :id -> where(query, [program_medication], program_medication.id == ^value)
        :is_active -> where(query, [program_medication], program_medication.is_active)
        :medication_id -> where(query, [_, med], med.id == ^value)
        :medication_name -> where(query, [_, med], ilike(med.name, ^("%" <> value <> "%")))
        :medical_program_id -> where(query, [_, _, mp], mp.id == ^value)
        :medical_program_name -> where(query, [_, _, mp], ilike(mp.name, ^("%" <> value <> "%")))
        _ -> query
      end
    end)
    |> where([_, medication], medication.is_active)
  end

  def fetch_program_medication(params) do
    case @read_prm_repo.get_by(ProgramMedication, params) do
      nil -> {:error, {:not_found, "ProgramMedication not found"}}
      entity -> {:ok, entity}
    end
  end

  def fetch_program_medication(params, :preload) do
    params
    |> fetch_program_medication()
    |> preload_references()
  end

  def count_active_program_medications_by(params) when is_list(params) do
    params = [is_active: true] ++ params

    ProgramMedication
    |> where(^params)
    |> select([pm], count(pm.id))
    |> @read_prm_repo.one()
  end

  def create_program_medication(%{} = params, actor_id) when is_binary(actor_id) do
    with :ok <- JsonSchema.validate(:program_medication, params) do
      %ProgramMedication{}
      |> changeset(Map.merge(params, %{"inserted_by" => actor_id, "updated_by" => actor_id}))
      |> PRMRepo.insert_and_log(actor_id)
    end
  end

  def update_program_medication(%ProgramMedication{} = program_medication, %{} = attrs, actor_id)
      when is_binary(actor_id) do
    case JsonSchema.validate(:program_medication_update, attrs) do
      :ok ->
        attrs = Map.put(attrs, "updated_by", actor_id)

        program_medication
        |> changeset(attrs)
        |> PRMRepo.update_and_log(actor_id)
        |> preload_references()

      err ->
        err
    end
  end

  def preload_references({:ok, entity}) do
    {:ok, preload_references(entity)}
  end

  def preload_references(%ProgramMedication{} = program) do
    @read_prm_repo.preload(program, medication: [ingredients: [innm_dosage: []]], medical_program: [])
  end

  def preload_references(%Medication{} = medication) do
    @read_prm_repo.preload(medication, ingredients: [innm_dosage: []])
  end

  def preload_references(%INNMDosage{} = innm_dosage) do
    @read_prm_repo.preload(innm_dosage, ingredients: [innm: []])
  end

  def preload_references(entity) do
    entity
  end
end

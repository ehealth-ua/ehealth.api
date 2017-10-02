defmodule EHealth.PRM.Medications.API do
  @moduledoc """
  The Medications context.
  """

  use EHealth.PRM.Search

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.PRMRepo
  alias EHealth.PRM.Medications.INNM.Schema, as: INNM
  alias EHealth.PRM.Medications.INNM.Search, as: INNMSearch
  alias EHealth.PRM.Medications.INNMDosage.Schema, as: INNMDosage
  alias EHealth.PRM.Medications.INNMDosage.Search, as: INNMSearch
  alias EHealth.PRM.Medications.Medication.Schema, as: Medication
  alias EHealth.PRM.Medications.Medication.Search, as: MedicationSearch
  alias EHealth.PRM.Medications.DrugsSearch
  alias EHealth.Validators.JsonSchema
  alias EHealth.PRM.Medications.Validator

  @page_size 50

  @type_innm_dosage INNMDosage.type()
  @type_medication Medication.type()

  @fields_innm_required [:sctid, :name, :name_original, :inserted_by, :updated_by]
  @fields_innm_optional [:is_active]

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

  # List

  def get_drugs(params) do
    %DrugsSearch{}
    |> cast(params, DrugsSearch.__schema__(:fields))
    |> search_drugs()
  end

  defp search_drugs(%{valid?: true, changes: params}) do
    INNM
    |> distinct(true)
    |> where_innm(params)
    # get primary INNMDosage ingredients related to INNM
    |> join(:inner, [i], ii in assoc(i, :ingredients))
    |> where([_, ii], ii.is_primary)
    # get active INNMDosage
    |> join(:inner, [_, ii], id in assoc(ii, :innm_dosage))
    |> where([..., id], id.is_active)
    |> where_innm_dosage(params)
    # get primary Medication ingredients related to INNMDosage
    |> join(:inner, [..., id], idi in assoc(id, :ingredients_medication))
    |> where([..., idi], idi.is_primary)
    # get active Medication
    |> join(:inner, [..., idi], m in assoc(idi, :medication))
    |> where_medication(params)
    # group by primary keys
    |> group_by([innm], innm.id)
    |> group_by([_, innm_ingrdient], innm_ingrdient.id)
    |> group_by([_, _, innm_dosage], innm_dosage.id)
    |> select(
         [innm, innm_ingrdient, innm_dosage, _, medication],
         %{
           innm_id: innm.id,
           innm_name: innm.name,
           innm_name_original: innm.name_original,
           innm_sctid: innm.sctid,
           innm_dosage_id: innm_dosage.id,
           innm_dosage_name: innm_dosage.name,
           innm_dosage_form: innm_dosage.form,
           innm_dosage_dosage: innm_ingrdient.dosage,
           packages:
             fragment("array_agg((?, ?, ?))", medication.container, medication.package_qty, medication.package_min_qty),
         }
       )
    |> PRMRepo.paginate()
  end
  defp search_drugs(changeset) do
    changeset
  end

  defp where_innm(query, attrs) do
    params =
      attrs
      |> Map.take(~W(innm_id innm_sctid)a)
      |> Enum.into([])
      |> Kernel.++([is_active: true])

    query = where(query, ^params)

    case Map.has_key?(attrs, :innm_name) do
      true -> where(query, [i], ilike(i.name, ^("%" <> attrs.innm_name <> "%")))
      false -> query
    end
  end

  defp where_innm_dosage(query, attrs) do
    params =
      attrs
      |> Map.take(~W(innm_dosage_id, innm_dosage_form)a)
      |> Enum.into([])
      |> Kernel.++([is_active: true])

    query = where(query, ^params)
    case Map.has_key?(attrs, :innm_dosage_name) do
      true -> where(query, [..., id], ilike(id.name, ^("%" <> attrs.innm_dosage_name <> "%")))
      false -> query
    end
  end

  def where_medication(query, attrs) do
    query = where(query, [..., m], m.is_active)
    case Map.has_key?(attrs, :medication_code_atc) do
      true -> where(query, [..., m], m.code_atc == ^attrs.medication_code_atc)
      false -> query
    end
  end

  def list_medications(params) do
    params = Map.put(params, "type", @type_medication)

    %MedicationSearch{}
    |> cast(params, MedicationSearch.__schema__(:fields))
    |> search(params, Medication, @page_size)
  end

  def list_innm_dosages(params) do
    params = Map.put(params, "type", @type_innm_dosage)

    %INNMSearch{}
    |> cast(params, INNMSearch.__schema__(:fields))
    |> search(params, INNMDosage, @page_size)
  end

  def get_search_query(Medication, changes) do
    params =
      changes
      |> Map.take([:id, :form, :type, :is_active])
      |> Enum.into([])

    Medication
    |> where(^params)
    |> join(:inner, [m], i in assoc(m, :ingredients))
    |> where([_, i], i.is_primary)
    |> where_name(changes)
    |> join_innm_dosage(changes)
    |> preload(:ingredients)
  end

  def get_search_query(INNMDosage, changes) do
    INNMDosage
    |> super(changes)
    |> preload(:ingredients)
  end

  def get_search_query(entity, changes) do
    super(entity, changes)
  end

  defp where_name(query, %{name: {name, _}}) do
    where(query, [m], ilike(m.name, ^("%" <> name <> "%")))
  end

  defp where_name(query, _changes) do
    query
  end

  defp join_innm_dosage(query, %{innm_dosage_id: innm_dosage_id, innm_dosage_name: {innm_dosage_name, _}}) do
    query
    |> join(:inner, [..., i], inn in assoc(i, :innm_dosage))
    |> where([..., inn], inn.id == ^innm_dosage_id)
    |> where([..., inn], ilike(inn.name, ^("%" <> innm_dosage_name <> "%")))
  end

  defp join_innm_dosage(query, %{innm_dosage_name: {innm_dosage_name, _}}) do
    query
    |> join(:inner, [..., i], inn in assoc(i, :innm_dosage))
    |> where([..., inn], ilike(inn.name, ^("%" <> innm_dosage_name <> "%")))
  end

  defp join_innm_dosage(query, %{innm_dosage_id: innm_dosage_id}) do
    query
    |> join(:inner, [..., i], inn in assoc(i, :innm_dosage))
    |> where([..., inn], inn.id == ^innm_dosage_id)
  end

  defp join_innm_dosage(query, _) do
    query
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
    |> PRMRepo.preload(:ingredients)
  end

  def get_active_innm_dosage_by_id!(id), do: get_active_medication_entity_by_id(INNMDosage, id)

  def get_active_medication_by_id!(id), do: get_active_medication_entity_by_id(Medication, id)

  defp get_active_medication_entity_by_id(entity, id) do
    entity
    |> PRMRepo.get_by!([id: id, type: entity.type(), is_active: true])
    |> PRMRepo.preload(:ingredients)
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
        |> PRMRepo.insert()

      err -> err
    end
  end

  # Update

  @doc false
  def deactivate_medication(entity, headers) do
    attrs = %{
      is_active: false,
      updated_by: get_consumer_id(headers)
    }

    entity
    |> changeset(attrs)
    |> PRMRepo.update()
  end

  # Changeset

  def changeset(%Medication{} = medication, attrs) do
    medication
    |> cast(attrs, @fields_medication_required ++ @fields_medication_optional)
    |> cast_assoc(:ingredients)
    |> validate_required(@fields_medication_required)
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

  # INNMs

  @doc false
  def list_innms(params) do
    %INNMSearch{}
    |> cast(params, INNMSearch.__schema__(:fields))
    |> search(params, INNM, @page_size)
  end

  @doc false
  def get_innm!(id), do: PRMRepo.get!(INNM, id)

  @doc false
  def create_innm(attrs, headers) do
    case JsonSchema.validate(:innm, attrs) do
      :ok ->
        consumer_id = get_consumer_id(headers)
        attrs = Map.merge(attrs, %{"inserted_by" => consumer_id, "updated_by" => consumer_id})

        %INNM{}
        |> changeset(attrs)
        |> PRMRepo.insert()

      err -> err
    end
  end
end

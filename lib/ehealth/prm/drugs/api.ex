defmodule EHealth.PRM.Drugs.API do
  @moduledoc """
  The Drugs context.
  """

  use EHealth.PRM.Search

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.PRMRepo
  alias EHealth.PRM.Drugs.INNM.Schema, as: INNM
  alias EHealth.PRM.Drugs.Substance.Schema, as: Substance
  alias EHealth.PRM.Drugs.Medication.Schema, as: Medication
  alias EHealth.PRM.Drugs.INNM.Search, as: INNMSearch
  alias EHealth.PRM.Drugs.Substance.Search, as: SubstanceSearch
  alias EHealth.PRM.Drugs.Medication.Search, as: MedicationSearch
  alias EHealth.Validators.JsonSchema
  alias EHealth.PRM.Drugs.Validator

  @page_size 50

  @type_innm INNM.type()
  @type_medication Medication.type()

  @fields_substance_required [:sctid, :name, :name_original, :inserted_by, :updated_by]
  @fields_substance_optional [:is_active]

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
  @fields_innm_optional [:is_active]

  # List

  def list_medications(params) do
    params = Map.put(params, "type", @type_medication)

    %MedicationSearch{}
    |> cast(params, MedicationSearch.__schema__(:fields))
    |> search(params, Medication, @page_size)
  end

  def list_innms(params) do
    params = Map.put(params, "type", @type_innm)

    %INNMSearch{}
    |> cast(params, INNMSearch.__schema__(:fields))
    |> search(params, INNM, @page_size)
  end

  def get_search_query(Medication, changes) do
    params = changes |> Map.take([:id, :form, :type, :is_active]) |> Enum.into([])

    Medication
    |> where(^params)
    |> join(:inner, [m], i in assoc(m, :ingredients))
    |> where([_, i], i.is_active_substance)
    |> where_name(changes)
    |> join_innm(changes)
    |> preload(:ingredients)
  end

  def get_search_query(INNM, changes) do
    INNM
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

  defp join_innm(query, %{innm_id: innm_id, innm_name: {innm_name, _}}) do
    query
    |> join(:inner, [..., i], inn in assoc(i, :innm))
    |> where([..., inn], inn.id == ^innm_id)
    |> where([..., inn], ilike(inn.name, ^("%" <> innm_name <> "%")))
  end

  defp join_innm(query, %{innm_name: {innm_name, _}}) do
    query
    |> join(:inner, [..., i], inn in assoc(i, :innm))
    |> where([..., inn], ilike(inn.name, ^("%" <> innm_name <> "%")))
  end

  defp join_innm(query, %{innm_id: innm_id}) do
    query
    |> join(:inner, [..., i], inn in assoc(i, :innm))
    |> where([..., inn], inn.id == ^innm_id)
  end

  defp join_innm(query, _) do
    query
  end

  # Get by id

  def get_innm_by_id(id), do: get_medication_entity_by_id(INNM, id)

  def get_medication_by_id(id), do: get_medication_entity_by_id(Medication, id)

  defp get_medication_entity_by_id(entity, id) do
    entity
    |> PRMRepo.get_by([id: id, type: entity.type()])
    |> PRMRepo.preload(:ingredients)
  end

  def get_innm_by_id!(id), do: get_medication_entity_by_id!(INNM, id)

  def get_medication_by_id!(id), do: get_medication_entity_by_id!(Medication, id)

  defp get_medication_entity_by_id!(entity, id) do
    entity
    |> PRMRepo.get_by!([id: id, type: entity.type()])
    |> PRMRepo.preload(:ingredients)
  end

  def get_active_innm_by_id!(id), do: get_active_medication_entity_by_id(INNM, id)

  def get_active_medication_by_id!(id), do: get_active_medication_entity_by_id(Medication, id)

  defp get_active_medication_entity_by_id(entity, id) do
    entity
    |> PRMRepo.get_by!([id: id, type: entity.type(), is_active: true])
    |> PRMRepo.preload(:ingredients)
  end

  # Create

  def create_innm(attrs, headers), do: create_medication_entity(INNM, attrs, headers)

  def create_medication(attrs, headers), do: create_medication_entity(Medication, attrs, headers)

  defp create_medication_entity(entity, attrs, headers) do
    schema_type =
      case entity.type() do
        @type_innm -> :innm
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

  def changeset(%INNM{} = medication, attrs) do
    medication
    |> cast(attrs, @fields_medication_required ++ @fields_innm_optional)
    |> cast_assoc(:ingredients)
    |> validate_required(@fields_medication_required)
    |> foreign_key_constraint(:ingredients_substance_id)
    |> Validator.validate_ingredients()
  end

  def changeset(%Substance{} = substance, attrs) do
    substance
    |> cast(attrs, @fields_substance_required ++ @fields_substance_optional)
    |> unique_constraint(:sctid)
    |> validate_required(@fields_substance_required)
  end

  # Substances

  @doc false
  def list_substances(params) do
    %SubstanceSearch{}
    |> cast(params, SubstanceSearch.__schema__(:fields))
    |> search(params, Substance, @page_size)
  end

  @doc false
  def get_substance!(id), do: PRMRepo.get!(Substance, id)

  @doc false
  def create_substance(attrs, headers) do
    case JsonSchema.validate(:substance, attrs) do
      :ok ->
        consumer_id = get_consumer_id(headers)
        attrs = Map.merge(attrs, %{"inserted_by" => consumer_id, "updated_by" => consumer_id})

        %Substance{}
        |> changeset(attrs)
        |> PRMRepo.insert()

      err -> err
    end
  end
end

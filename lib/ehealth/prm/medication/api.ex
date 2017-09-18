defmodule EHealth.PRM.Medication.API do
  @moduledoc """
  The Medication context.
  """

  use JValid

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.PRMRepo
  alias EHealth.PRM.Medication
  alias EHealth.PRM.Medication.Substance
  alias EHealth.Validators.SchemaMapper

  use_schema :substance, "specs/json_schemas/new_substance_schema.json"
  use_schema :medication, "specs/json_schemas/new_medication_type_medication_schema.json"
  use_schema :innm, "specs/json_schemas/new_medication_type_innm_schema.json"

  @type_innm Medication.type(:innm)
  @type_medication Medication.type(:medication)

  @fields_substance_required [:sctid, :name, :name_original, :inserted_by, :updated_by]
  @fields_substance_optional [:is_active]

  @fields_medication_required [:name, :type, :form, :ingredients, :inserted_by, :updated_by]
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

  @doc false
  def list_medications(type) do
    query = from(m in Medication, where: m.type == ^type)
    PRMRepo.all(query)
  end

  @doc false
  def get_medication!(id), do: PRMRepo.get_by!(Medication, [id: id, is_active: true])

  def get_medication_by_id_and_type!(id, type), do: PRMRepo.get_by!(Medication, [id: id, type: type, is_active: true])

  @doc false
  def create_medication(attrs, type, headers) do
    case validate_medication_schema(attrs, type) do
      {:ok, _} ->
        consumer_id = get_consumer_id(headers)
        attrs = Map.merge(
          attrs,
          %{
            "type" => Medication.type(type),
            "inserted_by" => consumer_id,
            "updated_by" => consumer_id
          }
        )

        %Medication{}
        |> changeset(attrs)
        |> PRMRepo.insert()

      err -> err
    end
  end

  @doc false
  def deactivate_medication(%Medication{} = medication, headers) do
    attrs = %{
      is_active: false,
      updated_by: get_consumer_id(headers)
    }

    medication
    |> changeset(attrs)
    |> PRMRepo.update()
  end

  @doc false
  def validate_medication_schema(data, schema_name) do
    schema =
      @schemas
      |> Keyword.get(schema_name)
      |> SchemaMapper.prepare_medication_schema(schema_name)

    case validate_schema(schema, data) do
      :ok -> {:ok, data}
      err -> err
    end
  end

  @doc false
  def changeset(%Medication{} = medication, attrs) do
    medication
    |> cast(attrs, @fields_medication_optional ++ @fields_medication_required)
    |> validate_required(@fields_medication_required)
    |> validate_ingredients_fk()
  end

  @doc false
  def changeset(%Substance{} = substance, attrs) do
    substance
    |> cast(attrs, @fields_substance_required ++ @fields_substance_optional)
    |> validate_required(@fields_substance_required)
  end

  @doc false
  def validate_ingredients_fk(changeset) do
    validate_change changeset, :ingredients, fn :ingredients, ingredients ->
      ingredients
      |> Enum.map(&(Map.get(&1, "id")))
      |> Enum.uniq()
      |> validate_fk(get_field(changeset, :type))
    end
  end

  @doc false
  def validate_fk(ids, type) do
    case length(ids) == count_by_ids(ids, type) do
      true -> []
      false -> [ingredients: "Invalid foreign keys"]
    end
  end

  # Substance

  @doc false
  def list_substances do
    PRMRepo.all(Substance)
  end

  @doc false
  def get_substance!(id), do: PRMRepo.get!(Substance, id)

  @doc false
  def create_substance(attrs, headers) do
    case validate_medication_schema(attrs, :substance) do
      {:ok, _} ->
        consumer_id = get_consumer_id(headers)
        attrs = Map.merge(attrs, %{"inserted_by" => consumer_id, "updated_by" => consumer_id})

        %Substance{}
        |> changeset(attrs)
        |> PRMRepo.insert()

      err -> err
    end
  end

  # counters

  def count_by_ids(ids, @type_medication) do
    PRMRepo.one(from m in Medication, select: count("*"), where: m.id in ^ids)
  end

  def count_by_ids(ids, @type_innm) do
    PRMRepo.one(from s in Substance, select: count("*"), where: s.id in ^ids)
  end

end

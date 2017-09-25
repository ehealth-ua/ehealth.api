defmodule EHealth.PRM.Medication.API do
  @moduledoc """
  The Medication context.
  """

  use EHealth.PRM.Search

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.PRMRepo
  alias EHealth.PRM.Medication
  alias EHealth.PRM.Medication.Substance
  alias EHealth.Ecto.StringLike
  alias EHealth.Validators.JsonSchema

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
  def list_medications(params, type) do
    params = Map.put(params, "type", type)
    data = %{}
    types = %{id: Ecto.UUID, name: StringLike, form: :string, type: :string, is_active: :boolean}

    {data, types}
    |> cast(params, Map.keys(types))
    |> build_search_query(Medication)
    |> PRMRepo.paginate(params)
  end

  @doc false
  def get_medication!(id), do: PRMRepo.get!(Medication, id)

  def get_by_id(id), do: PRMRepo.get(Medication, id)

  def get_medication_by_id_and_type!(id, type), do: PRMRepo.get_by!(Medication, [id: id, type: type])

  def get_active_medication_by_id_and_type!(id, type) do
    PRMRepo.get_by!(Medication, [id: id, type: type, is_active: true])
  end

  @doc false
  def create_medication(attrs, type, headers) do
    case JsonSchema.validate(type, attrs) do
      :ok ->
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
  def changeset(%Medication{} = medication, attrs) do
    medication
    |> cast(attrs, @fields_medication_optional ++ @fields_medication_required)
    |> validate_required(@fields_medication_required)
    |> validate_ingredients_fk()
    |> validate_ingredients_id_uniqueness()
    |> validate_ingedients_active_substance_uniqueness()
  end

  @doc false
  def changeset(%Substance{} = substance, attrs) do
    substance
    |> cast(attrs, @fields_substance_required ++ @fields_substance_optional)
    |> unique_constraint(:sctid)
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
  def validate_ingredients_id_uniqueness(changeset) do
    validate_change changeset, :ingredients, fn :ingredients, ingredients ->
      ingredients
      |> Enum.reduce_while({[], []}, &id_unique/2)
      |> elem(1)
    end
  end

  defp id_unique(%{"id" => id}, {collected_ids, _msg}) do
    case Enum.member?(collected_ids, id) do
      true -> {:halt, {false, [ingredients: "Ingredient id duplicated"]}}
      false -> {:cont, {collected_ids ++ [id], []}}
    end
  end

  defp validate_ingedients_active_substance_uniqueness(changeset) do
    validate_change changeset, :ingredients, fn :ingredients, ingredients ->
      ingredients
      |> Enum.reduce_while({false, []}, &active_substance_unique/2)
      |> case do
           {false, _} -> [ingredients: "One and only one ingredient must be active"]
           {true, msg} -> msg
         end
    end
  end

  defp active_substance_unique(%{"is_active_substance" => false}, acc), do: {:cont, acc}
  defp active_substance_unique(%{"is_active_substance" => true}, {false, _msg}), do: {:cont, {true, []}}
  defp active_substance_unique(%{"is_active_substance" => true}, {true, _msg}), do:
    {:halt, {true, [ingredients: "One and only one ingredient must be active"]}}

  @doc false
  def validate_fk(ids, type) do
    case length(ids) == count_by_ids(ids, type) do
      true -> []
      false -> [ingredients: "Invalid foreign keys"]
    end
  end

  # Substance

  @doc false
  def list_substances(params) do
    data = %{}
    types = %{id: Ecto.UUID, name: StringLike, name_original: StringLike, sctid: :string, is_active: :boolean}

    {data, types}
    |> cast(params, Map.keys(types))
    |> build_search_query(Substance)
    |> PRMRepo.paginate(params)
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

  # counters

  defp count_by_ids(ids, @type_medication) do
    Medication
    |> where([m], m.id in ^ids)
    |> where([m], m.type == @type_innm)
    |> where([m], m.is_active)
    |> select(count("*"))
    |> PRMRepo.one()
  end

  defp count_by_ids(ids, @type_innm) do
    Substance
    |> where([s], s.id in ^ids)
    |> where([s], s.is_active)
    |> select(count("*"))
    |> PRMRepo.one()
  end
end

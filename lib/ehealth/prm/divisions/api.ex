defmodule EHealth.PRM.Divisions do
  @moduledoc false

  use EHealth.PRM.Search

  alias EHealth.PRMRepo
  alias EHealth.PRM.Divisions.Search
  alias EHealth.PRM.Divisions.Schema, as: Division

  @search_fields ~w(
    ids
    name
    legal_entity_id
    type
    status
  )a

  @fields_optional ~w(
    external_id
    mountain_group
    is_active
    location
  )a

  @fields_required ~w(
    legal_entity_id
    name
    type
    addresses
    phones
    status
    email
  )a

  def get_division_by_id!(id) do
    PRMRepo.get!(Division, id)
  end

  def get_division_by_id(id) do
    PRMRepo.get(Division, id)
  end

  def get_divisions(params) do
    %Search{}
    |> changeset(params)
    |> search(params, Division)
  end

  def get_by_ids(ids) when is_list(ids) do
    Division
    |> where([d], d.id in ^ids)
    |> PRMRepo.all()
  end

  def create_division(attrs, author_id) do
    %Division{}
    |> changeset(attrs)
    |> PRMRepo.insert_and_log(author_id)
  end

  def update_division(%Division{} = division, attrs, author_id) do
    division
    |> changeset(attrs)
    |> PRMRepo.update_and_log(author_id)
  end

  def update_divisions_mountain_group(attrs) do
    attrs
    |> mountain_group_changeset()
    |> do_update_divisions_mountain_group()
  end

  def get_search_query(Division = entity, %{ids: _} = changes) do
    super(entity, convert_comma_params_to_where_in_clause(changes, :ids, :id))
  end

  def get_search_query(Division = division, changes) do
    params =
      changes
      |> Map.drop([:name])
      |> Map.to_list()

    division
    |> select([d], d)
    |> query_name(Map.get(changes, :name))
    |> where(^params)
  end

  def query_name(query, nil), do: query
  def query_name(query, name) do
    query |> where([d], ilike(d.name, ^"%#{name}%"))
  end

  defp convert_comma_params_to_where_in_clause(changes, param_name, db_field) do
    changes
    |> Map.put(db_field, {String.split(changes[param_name], ","), :in})
    |> Map.delete(param_name)
  end

  defp changeset(%Division{} = division, %{"location" => %{"longitude" => lng, "latitude" => lat}} = attrs) do
    changeset(division, Map.put(attrs, "location", %Geo.Point{coordinates: {lng, lat}}))
  end
  defp changeset(%Division{} = division, attrs) do
    division
    |> cast(attrs, @fields_optional ++ @fields_required)
    |> validate_required(@fields_required)
    |> foreign_key_constraint(:legal_entity_id)
  end
  defp changeset(%Search{} = division, attrs) do
    cast(division, attrs, @search_fields)
  end

  defp mountain_group_changeset(attrs) do
    data  = %{}
    types = %{mountain_group: :boolean, settlement_id: Ecto.UUID}

    {data, types}
    |> cast(attrs, Map.keys(types))
    |> validate_required(Map.keys(types))
  end

  defp do_update_divisions_mountain_group(%Ecto.Changeset{valid?: true} = changeset) do
    settlement_id = get_change(changeset, :settlement_id)
    mountain_group = get_change(changeset, :mountain_group)
    addresses = [%{settlement_id: settlement_id}]

    query =
      from d in Division,
      where: d.mountain_group != ^mountain_group,
      where: fragment("? @> ?", d.addresses, ^addresses)

    PRMRepo.update_all(query, set: [mountain_group: mountain_group])
  end
  defp do_update_divisions_mountain_group(changeset), do: changeset
end

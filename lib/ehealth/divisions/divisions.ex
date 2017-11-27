defmodule EHealth.Divisions do
  @moduledoc """
  The boundary for the Divisions system.
  """

  import Ecto.Changeset, warn: false
  import EHealth.Utils.Connection, only: [get_client_id: 1, get_consumer_id: 1]

  use EHealth.Search, EHealth.PRMRepo

  alias EHealth.PRMRepo
  alias EHealth.Divisions.Search
  alias EHealth.API.UAddress
  alias EHealth.Validators.Addresses
  alias EHealth.Divisions.Division
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.LegalEntities
  alias EHealth.Validators.JsonSchema
  alias EHealth.Validators.JsonObjects
  alias EHealth.Dictionaries
  alias Ecto.Multi
  alias EctoTrail.Changelog

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

  @mountain_group_required_types %{mountain_group: :boolean, settlement_id: Ecto.UUID}
  @status_active Division.status(:active)
  @default_mountain_group "0"
  @validation_dictionaries ["ADDRESS_TYPE", "PHONE_TYPE"]

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, Division)
  end

  def get_by_id!(id) do
    PRMRepo.get!(Division, id)
  end

  def get_by_id(id) do
    PRMRepo.get(Division, id)
  end

  def get_by_ids(ids) when is_list(ids) do
    Division
    |> where([d], d.id in ^ids)
    |> PRMRepo.all()
  end

  def search(legal_entity_id, params \\ %{}) do
    params
    |> Map.put("legal_entity_id", legal_entity_id)
    |> list()
  end

  def create(params, headers) do
    with {:ok, attrs} <- prepare_division_data(params, get_client_id(headers)),
         attrs <- Map.merge(attrs, %{"status" => @status_active, "is_active" => true})
    do
      %Division{}
      |> changeset(attrs)
      |> PRMRepo.insert_and_log(get_consumer_id(headers))
    end
  end

  def update(id, params, headers) do
    legal_entity_id = get_client_id(headers)
    with {:ok, attrs} <- prepare_division_data(params, legal_entity_id),
         %Division{} = division <- get_by_id(id),
         :ok <- validate_legal_entity(division, legal_entity_id)
    do
      division
      |> changeset(attrs)
      |> PRMRepo.update_and_log(get_consumer_id(headers))
    end
  end

  def prepare_division_data(params, legal_entity_id) do
    with %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(legal_entity_id),
         :ok <- validate_division_type(legal_entity, params),
         params <- params
                   |> Map.delete("id")
                   |> Map.put("legal_entity_id", legal_entity_id),
         :ok <- JsonSchema.validate(:division, params),
         :ok <- validate_json_objects(params),
         :ok <- validate_addresses(params)
    do
      put_mountain_group(params)
    else
      nil ->
        {:error, [{%{
                      "rule": :invalid,
                      "params": [],
                      "description": "invalid legal entity"
                   }, "$.legal_entity_id"}]}
      err -> err
    end
  end

  def update_status(id, status, headers) do
    with %Division{} = division <- get_by_id(id),
         :ok <- validate_legal_entity(division, get_client_id(headers)),
         attrs <- %{"status" => status, "is_active" => status == @status_active}
    do
      division
      |> changeset(attrs)
      |> PRMRepo.update_and_log(get_consumer_id(headers))
    end
  end

  def update_mountain_group(attrs, consumer_id) do
    case mountain_group_changeset(attrs) do
      %Ecto.Changeset{valid?: true} -> do_update_divisions_mountain_group(attrs, consumer_id)
      err_changeset                 -> err_changeset
    end
  end

  def validate_json_objects(data) do
    dict_keys = Dictionaries.get_dictionaries_keys(@validation_dictionaries)

    with %{"ADDRESS_TYPE" => address_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(data, ["addresses"], "type", address_types),
         %{"PHONE_TYPE" => phone_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(data, ["phones"], "type", phone_types),
    do:  :ok
  end

  def validate_addresses(data) do
    data
    |> Map.get("addresses")
    |> Addresses.validate("RESIDENCE")
    |> case do
         {:ok, _} -> :ok
         err -> err
       end
  end

  defp validate_division_type(%LegalEntity{type: legal_entity_type}, params) do
    config = Confex.fetch_env!(:ehealth, :legal_entity_division_types)
    legal_entity_type =
      legal_entity_type
      |> String.downcase()
      |> String.to_atom

    allowed_types = Keyword.get(config, legal_entity_type)
    type = Map.get(params, "type")
    if !type || Enum.member?(allowed_types, type) do
      :ok
    else
      {:error, [{%{
        "rule": "inclusion",
        "params": allowed_types,
        "description": "value is not allowed in enum"
      }, "$.type"}]}
    end
  end

  def put_mountain_group(%{"addresses" => addresses} = division) do
    settlement_id =
      addresses
      |> List.first()
      |> Map.fetch!("settlement_id")

    settlement_id
    |> UAddress.get_settlement_by_id()
    |> put_mountain_group(division)
  end
  def put_mountain_group(err), do: err

  def put_mountain_group({:ok, %{"data" => address}}, division) do
    mountain_group = Map.get(address, "mountain_group", @default_mountain_group)
    {:ok, Map.put(division, "mountain_group", mountain_group)}
  end
  def put_mountain_group(err, _division), do: err

  def validate_legal_entity(%Division{} = division, legal_entity_id) do
    case legal_entity_id == division.legal_entity_id do
      true -> :ok
      false -> {:error, :forbidden}
    end
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
    required_params = Map.keys(@mountain_group_required_types)

    {%{}, @mountain_group_required_types}
    |> cast(attrs, required_params)
    |> validate_required(required_params)
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

  defp do_update_divisions_mountain_group(attrs, consumer_id) do
    %{settlement_id: settlement_id, mountain_group: mountain_group} = attrs
    addresses = [%{settlement_id: settlement_id}]

    query =
      from d in Division,
      where: d.mountain_group != ^mountain_group and
             fragment("? @> ?::jsonb", d.addresses, ^addresses)

    Multi.new()
    |> Multi.update_all(
        :update_divisions_mountain_group,
        query,
        [set: [mountain_group: mountain_group, updated_at: NaiveDateTime.utc_now()]],
        returning: [:id, :mountain_group])
    |> Multi.run(:log_updates, &log_changes(&1, consumer_id))
    |> PRMRepo.transaction()
  end

  defp log_changes(%{update_divisions_mountain_group: {_, updated_divisions}}, consumer_id) do
    changes =
      updated_divisions
      |> Enum.map(fn ud ->
        %{
          actor_id: consumer_id,
          resource: "divisions",
          resource_id: ud.id,
          changeset: %{mountain_group: ud.mountain_group},
        }
      end)
      |> Enum.map(&Map.put(&1, :inserted_at, NaiveDateTime.utc_now))

    {_, changelog} = PRMRepo.insert_all(Changelog, changes, returning: true)
    {:ok, changelog}
  end
end

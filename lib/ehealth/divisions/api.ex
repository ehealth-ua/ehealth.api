defmodule EHealth.Divisions.API do
  @moduledoc """
  The boundary for the Divisions system.
  """

  import Ecto.Changeset, warn: false
  import EHealth.Utils.Connection, only: [get_client_id: 1, get_consumer_id: 1]

  alias EHealth.API.UAddress
  alias EHealth.Validators.Addresses
  alias EHealth.PRM.Divisions
  alias EHealth.PRM.Divisions.Schema, as: Division
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.LegalEntities
  alias EHealth.Validators.JsonSchema
  alias EHealth.Validators.JsonObjects
  alias EHealth.Dictionaries

  @status_active Division.status(:active)
  @default_mountain_group "0"
  @validation_dictionaries ["ADDRESS_TYPE", "PHONE_TYPE"]

  def search(legal_entity_id, params \\ %{}) do
    params
    |> Map.put("legal_entity_id", legal_entity_id)
    |> Divisions.get_divisions()
  end

  def get_by_id(legal_entity_id, id) do
    with division <- Divisions.get_division_by_id!(id) do
      validate_legal_entity(division, legal_entity_id)
    end
  end

  def create(params, headers) do
    params
    |> prepare_division_data(get_client_id(headers))
    |> create_division(get_consumer_id(headers))
  end

  def update(id, params, headers) do
    legal_entity_id = get_client_id(headers)
    with {:ok, data} <- prepare_division_data(params, legal_entity_id),
         {:ok, division} <- get_by_id(legal_entity_id, id)
    do
      update_division(division, data, get_consumer_id(headers))
    end
  end

  def prepare_division_data(params, legal_entity_id) do
    with %LegalEntity{} = legal_entity <- LegalEntities.get_legal_entity_by_id(legal_entity_id),
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
    with {:ok, division} <- get_by_id(get_client_id(headers), id),
         params <- %{"status" => status, "is_active" => status == @status_active}
    do
      update_division(division, params, get_consumer_id(headers))
    end
  end

  def create_division({:ok, data}, author_id) do
    data
    |> Map.merge(%{"status" => @status_active, "is_active" => true})
    |> Divisions.create_division(author_id)
  end
  def create_division(err, _), do: err

  def update_division(%Division{} = division, data, author_id) do
    Divisions.update_division(division, data, author_id)
  end

  def validate_json_objects(data) do
    dict_keys = Dictionaries.get_dictionaries_keys(@validation_dictionaries)

    with %{"ADDRESS_TYPE" => address_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(data, ["addresses"], "type", address_types),
         :ok <- JsonObjects.array_contains_item(data, ["addresses"], "type", "RESIDENCE"),
         %{"PHONE_TYPE" => phone_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(data, ["phones"], "type", phone_types),
    do:  :ok
  end

  def validate_addresses(data) do
    data
    |> Map.get("addresses")
    |> Addresses.validate()
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
      true -> {:ok, division}
      false -> {:error, :forbidden}
    end
  end
  def validate_legal_entity(err, _legal_entity_id), do: err
end

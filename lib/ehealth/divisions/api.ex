defmodule EHealth.Divisions.API do
  @moduledoc """
  The boundary for the Divisions system.
  """
  use JValid

  import Ecto.Changeset, warn: false
  import EHealth.Utils.Connection, only: [get_client_id: 1, get_consumer_id: 1]

  alias EHealth.API.UAddress
  alias EHealth.Validators.SchemaMapper
  alias EHealth.Validators.Addresses
  alias EHealth.PRM.Divisions
  alias EHealth.PRM.Divisions.Schema, as: Division

  use_schema :division, "specs/json_schemas/division_schema.json"

  @status_active "ACTIVE"
  @default_mountain_group "0"

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
    params
    |> Map.delete("id")
    |> Map.put("legal_entity_id", legal_entity_id)
    |> validate_division()
    |> validate_addresses()
    |> put_mountain_group()
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
    |> Map.merge(%{"status" => "ACTIVE", "is_active" => true})
    |> Divisions.create_division(author_id)
  end
  def create_division(err, _), do: err

  def update_division(%Division{} = division, data, author_id) do
    Divisions.update_division(division, data, author_id)
  end

  def validate_division(data) do
    schema =
      @schemas
      |> Keyword.get(:division)
      |> SchemaMapper.prepare_divisions_schema()

    case validate_schema(schema, data) do
      :ok -> {:ok, data}
      err -> err
    end
  end

  def validate_addresses({:ok, data} = return) do
    data
    |> Map.get("addresses")
    |> Addresses.validate()
    |> case do
         {:ok, _} -> return
         err -> err
       end
  end
  def validate_addresses(err), do: err

  def put_mountain_group({:ok, %{"addresses" => addresses} = division}) do
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

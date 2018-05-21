defmodule EHealth.API.UAddressesBehaviour do
  @moduledoc false

  @callback search_settlements(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_settlement_by_id(id :: binary, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback update_settlement(id :: binary, data :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_region_by_id(id :: binary, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_district_by_id(id :: binary, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback validate_addresses(addresses :: list, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}
end

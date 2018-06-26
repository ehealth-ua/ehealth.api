defmodule EHealth.API.ReportBehaviour do
  @moduledoc false

  @callback get_capitation_list(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_declaration_count(ids :: list, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}
end

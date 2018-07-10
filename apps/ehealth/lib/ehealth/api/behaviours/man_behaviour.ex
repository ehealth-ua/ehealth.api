defmodule EHealth.API.ManBehaviour do
  @moduledoc false

  @callback render_template(id :: binary, data :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}
end

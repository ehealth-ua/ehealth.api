defmodule EHealth.Validators.CacheBehaviour do
  @moduledoc false

  @callback get_json_schema(key :: binary) :: {:ok, any()}

  @callback set_json_schema(key :: binary, schema :: map) :: :ok
end

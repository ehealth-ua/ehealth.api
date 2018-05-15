defmodule EHealth.Validators.CacheTest do
  @moduledoc false

  @behaviour EHealth.Validators.CacheBehaviour

  def get_json_schema(_key), do: {:ok, nil}

  def set_json_schema(_key, _schema), do: :ok
end

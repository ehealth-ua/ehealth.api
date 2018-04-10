defmodule EHealth.API.PostmarkClientBehaviour do
  @moduledoc false

  @callback activate_email(binary) :: {:ok, binary} | {:error, binary}
end

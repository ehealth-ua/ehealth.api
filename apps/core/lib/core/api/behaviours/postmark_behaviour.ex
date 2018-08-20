defmodule Core.API.PostmarkBehaviour do
  @moduledoc false

  @callback get_bounces(binary) :: {:ok, %{}} | {:error, %{}}
  @callback activate_bounce(binary) :: {:ok, %{}} | {:error, %{}}
end

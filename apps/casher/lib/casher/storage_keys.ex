defmodule Casher.StorageKeys do
  @moduledoc false

  @spec person_data(binary, binary) :: binary
  def person_data(user_id, client_id), do: "person_data:#{user_id}:#{client_id}"
end

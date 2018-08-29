defmodule Casher.StorageKeys do
  @moduledoc false

  @prefix "casher"

  @spec person_data(binary, binary) :: binary
  def person_data(user_id, client_id), do: "#{@prefix}:person_data:#{user_id}:#{client_id}"
end

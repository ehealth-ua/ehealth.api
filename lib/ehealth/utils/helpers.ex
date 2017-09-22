defmodule EHealth.Utils.Helpers do
  @moduledoc """
  Plug.Conn helpers
  """
  def get_assoc_by_func(assoc_id, fun) do
    case fun.() do
      nil -> {:assoc_error, assoc_id}
      assoc -> {:ok, assoc}
    end
  end

  def from_filed_to_name(id_string) do
    id_string
    |> String.replace("_id", "")
    |> String.capitalize
  end
end

defmodule EHealth.Paging do
  @moduledoc false

  def get_paging(search_params, default_limit) do
    limit =
        search_params
        |> Map.get("limit", default_limit)
        |> to_integer()

    cursors = %Ecto.Paging.Cursors{
        starting_after: Map.get(search_params, "starting_after"),
        ending_before: Map.get(search_params, "ending_before")
    }
    %Ecto.Paging{limit: limit, cursors: cursors}
  end

  defp to_integer(value) when is_binary(value), do: String.to_integer(value)
  defp to_integer(value), do: value
end

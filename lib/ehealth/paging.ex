defmodule EHealth.Paging do
  @moduledoc false

  import EHealth.Utils.TypesConverter, only: [string_to_integer: 1]

  def get_paging(search_params, default_limit) do
    limit =
        search_params
        |> Map.get("limit", default_limit)
        |> string_to_integer()

    cursors = %Ecto.Paging.Cursors{
        starting_after: Map.get(search_params, "starting_after"),
        ending_before: Map.get(search_params, "ending_before")
    }
    %Ecto.Paging{limit: limit, cursors: cursors}
  end
end

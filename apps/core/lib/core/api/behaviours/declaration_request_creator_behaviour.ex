defmodule Core.DeclarationRequests.API.CreatorBehaviour do
  @moduledoc false

  @callback sql_get_sequence_number() ::
              {:ok, %Postgrex.Result{rows: [[sequence :: integer]]}} | {:error, reason :: term}
end

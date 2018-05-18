defmodule MicroservicesHelper do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use Plug.Router

      plug(Plug.Head)

      plug(:match)

      plug(
        Plug.Parsers,
        parsers: [:json],
        pass: ["application/json"],
        json_decoder: Jason
      )

      plug(:dispatch)
    end
  end
end

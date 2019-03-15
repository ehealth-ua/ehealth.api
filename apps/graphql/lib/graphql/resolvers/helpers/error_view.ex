defmodule GraphQL.Resolvers.Helpers.ErrorView do
  @moduledoc false

  require Logger

  @internal_error_templates ["500.json", "501.json", "503.json", "505.json"]

  def render(template, %{reason: error}) when template in @internal_error_templates do
    Logger.error("An exception was raised: #{inspect(error)}")

    %{
      message: "Something went wrong",
      extensions: %{code: "INTERNAL_SERVER_ERROR"}
    }
  end
end

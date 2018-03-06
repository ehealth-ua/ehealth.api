defmodule EHealth.API.Helpers.HeadersProcessor do
  @moduledoc """
  Proxy headers preprocessor
  """

  defmacro __using__(_) do
    quote do
      @filter_headers ["content-length", "Content-Length"]

      def process_request_headers(headers) do
        headers
        |> Keyword.drop(@filter_headers)
        |> Kernel.++([{"Content-Type", "application/json"}])
      end
    end
  end
end

defmodule EHealth.API.Helpers.MicroserviceBase do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      require Logger
      alias EHealth.API.ResponseDecoder

      def process_url(url), do: config()[:endpoint] <> url

      def process_request_options(options), do: Keyword.merge(config()[:hackney_options], options)

      def request!(method, url, body \\ "", headers \\ [], options \\ []) do
        ResponseDecoder.check_response(super(method, url, body, headers, options))
      end

      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        params = Keyword.get(options, :params, [])
        query_string = if Enum.empty?(params), do: "", else: "?#{URI.encode_query(params)}"
        Logger.info(fn ->
          "Calling #{method} on #{process_url(url)}#{query_string}. Body: #{inspect body}. Headers: #{inspect headers}"
        end)

        super(method, url, body, headers, options)
      end
    end
  end
end

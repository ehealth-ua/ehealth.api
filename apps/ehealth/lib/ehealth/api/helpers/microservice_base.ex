defmodule EHealth.API.Helpers.MicroserviceBase do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use Confex, otp_app: :ehealth
      use HTTPoison.Base
      require Logger
      alias EHealth.API.ResponseDecoder

      def process_url(url), do: config()[:endpoint] <> url

      def process_request_options(options), do: Keyword.merge(config()[:hackney_options], options)

      @filter_headers ["content-length", "Content-Length", "api-key", "authorization"]

      def process_request_headers(headers) do
        headers
        |> Keyword.drop(@filter_headers)
        |> Kernel.++([{"Content-Type", "application/json"}])
      end

      def request!(method, url, body \\ "", headers \\ [], options \\ []) do
        response = super(method, url, body, headers, options)

        if response.status_code >= 300 do
          Logger.error(fn ->
            Jason.encode!(%{
              "log_type" => "microservice_response",
              "microservice" => config()[:endpoint],
              "response" => body,
              "request_id" => Logger.metadata()[:request_id]
            })
          end)
        end

        ResponseDecoder.check_response(response)
      end

      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        params = Keyword.get(options, :params, [])
        query_string = if Enum.empty?(params), do: "", else: "?#{URI.encode_query(params)}"

        Logger.info(fn ->
          Jason.encode!(%{
            "log_type" => "microservice_request",
            "microservice" => config()[:endpoint],
            "action" => method,
            "path" => Enum.join([process_url(url), query_string]),
            "request_id" => Logger.metadata()[:request_id],
            "body" => body,
            "headers" =>
              Enum.reduce(process_request_headers(headers), %{}, fn {k, v}, map ->
                Map.put_new(map, k, v)
              end)
          })
        end)

        super(method, url, body, headers, options)
      end
    end
  end
end

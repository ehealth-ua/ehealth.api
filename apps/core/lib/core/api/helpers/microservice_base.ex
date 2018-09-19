defmodule Core.API.Helpers.MicroserviceBase do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use Confex, otp_app: :core
      use HTTPoison.Base
      alias Core.API.Helpers.ResponseDecoder
      require Logger

      def process_url(url), do: config()[:endpoint] <> url

      def process_request_options(options), do: Keyword.merge(config()[:hackney_options], options)

      @filter_request_headers ["content-length", "Content-Length", "authorization"]
      @filter_log_headers ["api-key", "authorization"]

      def process_request_headers(headers) do
        headers
        |> Keyword.drop(@filter_request_headers)
        |> Kernel.++([{"Content-Type", "application/json"}])
      end

      def process_log_headers(headers) do
        headers
        |> Keyword.drop(@filter_log_headers)
        |> Enum.reduce(%{}, fn {k, v}, map ->
          Map.put_new(map, k, v)
        end)
      end

      def request!(method, url, body \\ "", headers \\ [], options \\ []) do
        with {:ok, _} <- check_params(options) do
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
      end

      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        with {:ok, params} <- check_params(options) do
          query_string = if Enum.empty?(params), do: "", else: "?#{URI.encode_query(params)}"

          Logger.info(fn ->
            Jason.encode!(%{
              "log_type" => "microservice_request",
              "microservice" => config()[:endpoint],
              "action" => method,
              "path" => Enum.join([process_url(url), query_string]),
              "request_id" => Logger.metadata()[:request_id],
              "body" => body,
              "headers" => process_log_headers(headers)
            })
          end)

          super(method, url, body, headers, options)
        end
      end

      defp check_params(options) do
        params = Keyword.get(options, :params, [])

        errors =
          Enum.reduce(params, [], fn
            {k, v}, errors_list when is_list(v) ->
              errors_list ++ error_description(k)

            {k, v}, errors_list ->
              try do
                to_string(v)
                errors_list
              rescue
                error ->
                  errors_list ++ error_description(k)
              end
          end)

        if length(errors) > 0, do: {:error, errors}, else: {:ok, params}
      end

      defp error_description(value_name) do
        [
          {
            %{
              description: "Request parameter #{value_name} is not valid",
              params: [],
              rule: :invalid
            },
            "$.#{value_name}"
          }
        ]
      end
    end
  end
end

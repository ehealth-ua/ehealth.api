defmodule Core.API.Helpers.MicroserviceBase do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use Confex, otp_app: :core
      use HTTPoison.Base

      alias Core.API.Helpers.ResponseDecoder
      require Logger

      def process_request_url(url), do: config()[:endpoint] <> url

      def process_request_options(options), do: Keyword.merge(config()[:hackney_options], options)

      @filter_request_headers ["content-length", "Content-Length", "authorization"]
      @filter_log_headers ["api-key", "authorization"]

      def process_request_headers(headers) do
        headers
        |> Keyword.drop(@filter_request_headers)
        |> Enum.concat([{"Content-Type", "application/json"}])
      end

      defp process_log_headers(headers) do
        headers
        |> Keyword.drop(@filter_log_headers)
        |> Enum.into(%{})
      end

      def request!(method, url, body \\ "", headers \\ [], options \\ []) do
        with {:ok, _} <- check_params(options) do
          method
          |> super(url, body, headers, options)
          |> log_response()
          |> ResponseDecoder.check_response()
        end
      end

      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        with {:ok, params} <- check_params(options) do
          query_string = if Enum.empty?(params), do: "", else: "?#{URI.encode_query(params)}"

          Logger.info(
            "Microservice #{method} request to #{config()[:endpoint]} on #{process_request_url(url)}#{query_string}.
            Body: #{body} and headers: #{inspect(process_log_headers(headers))}"
          )

          method
          |> super(url, body, headers, options)
          |> log_response()
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

      defp log_response(%{request: request, status_code: code, body: body} = response) when code >= 300 do
        Logger.warn(
          "Failed microservice #{request.method} request to #{config()[:endpoint]} with response: #{inspect(body)}"
        )

        response
      end

      defp log_response(response), do: response

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

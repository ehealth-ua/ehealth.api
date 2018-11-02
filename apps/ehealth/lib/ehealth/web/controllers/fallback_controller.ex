defmodule EHealth.Web.FallbackController do
  @moduledoc """
  This controller should be used as `action_fallback` in rest of controllers to remove duplicated error handling.
  """
  use EHealth.Web, :controller

  alias Core.ValidationError, as: CoreValidationError
  alias Core.Validators.Error, as: EHealthError
  alias EView.Views.{Error, PhoenixError, ValidationError}

  require Logger

  def call(conn, %CoreValidationError{} = error), do: call(conn, EHealthError.dump(error))

  def call(conn, {:error, %{"paging" => %{"total_pages" => pages}}}) when pages > 1 do
    forbidden_message =
      "This API method returns only exact match results, please retry with more specific search parameters"

    conn
    |> put_status(:forbidden)
    |> put_view(PhoenixError)
    |> render(:"403", %{message: forbidden_message})
  end

  def call(conn, {:error, json_schema_errors}) when is_list(json_schema_errors) do
    conn
    |> put_status(422)
    |> put_view(ValidationError)
    |> render("422.json", %{schema: json_schema_errors})
  end

  def call(conn, {:error, errors, :query_parameter}) when is_list(errors) do
    conn
    |> put_status(422)
    |> put_view(ValidationError)
    |> render("422.query.json", %{schema: errors})
  end

  def call(conn, {:error, {:"422", error}}) do
    conn
    |> put_status(422)
    |> put_view(Error)
    |> render(:"400", %{message: error})
  end

  def call(conn, %Ecto.Changeset{valid?: false} = changeset) do
    call(conn, {:error, changeset})
  end

  def call(conn, {:error, %Ecto.Changeset{valid?: false} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ValidationError)
    |> render(:"422", changeset)
  end

  @doc """
  Proxy response from APIs
  """
  def call(conn, {_, %{"meta" => %{}} = proxy_resp}) do
    proxy(conn, proxy_resp)
  end

  def call(conn, {:error, _ecto_multi_key, %Ecto.Changeset{valid?: false} = changeset, _}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ValidationError)
    |> render(:"422", changeset)
  end

  def call(conn, {:error, _ecto_multi_key, reason, _}) do
    proxy(conn, reason)
  end

  def call(conn, {:error, {:bad_request, reason}}) when is_binary(reason) do
    conn
    |> put_status(:bad_request)
    |> put_view(Error)
    |> render(:"400", %{message: reason})
  end

  def call(conn, {:error, :access_denied}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(Error)
    |> render(:"401")
  end

  def call(conn, {:error, {:access_denied, reason}}) when is_map(reason) do
    conn
    |> put_status(:unauthorized)
    |> put_view(Error)
    |> render(:"401", reason)
  end

  def call(conn, {:error, {:access_denied, reason}}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(Error)
    |> render(:"401", %{message: reason})
  end

  def call(conn, {:error, :invalid_role}) do
    conn
    |> put_status(:bad_request)
    |> put_view(Error)
    |> render(:"400", %{message: "User OAuth role does not exists"})
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> put_view(Error)
    |> render(:"404")
  end

  def call(conn, {:error, %{"type" => "not_found"}}) do
    call(conn, {:error, :not_found})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(Error)
    |> render(:"404")
  end

  def call(conn, {:error, {:not_found, reason}}) do
    conn
    |> put_status(:not_found)
    |> put_view(Error)
    |> render(:"404", %{message: reason})
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(Error)
    |> render(:"403")
  end

  def call(conn, {:error, {:forbidden, reason}}) do
    conn
    |> put_status(:forbidden)
    |> put_view(Error)
    |> render(:"403", %{message: reason})
  end

  def call(conn, {:error, %{"type" => "internal_error"}}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(Error)
    |> render(:"500", %{type: "proxied error", message: "remote server internal error"})
  end

  def call(conn, {:error, {:internal_error, message}}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(Error)
    |> render(:"500", %{message: message})
  end

  def call(conn, {:error, {:bad_gateway, message}}) do
    conn
    |> put_status(:bad_gateway)
    |> put_resp_content_type("application/json")
    |> send_resp(502, Jason.encode!(%{message: message}))
  end

  def call(conn, {:error, {:service_unavailable, message}}) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(Error)
    |> render(:"503", %{message: message})
  end

  def call(conn, {:error, {:conflict, reason}}) do
    call(conn, {:conflict, reason})
  end

  def call(conn, {:conflict, reason}) when is_binary(reason) do
    call(conn, {:conflict, %{message: reason}})
  end

  def call(conn, {:conflict, reason}) when is_map(reason) do
    conn
    |> put_status(:conflict)
    |> put_view(Error)
    |> render(:"409", reason)
  end

  def call(conn, {:error, {:empty_body, code}}) do
    Logger.error(fn ->
      Jason.encode!(%{
        "log_type" => "error",
        "message" => "Proxied response with empty body. Status code: #{code}",
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    conn
    |> put_status(code)
    |> put_view(Error)
    |> render(:"400", %{message: "Proxied response with empty body"})
  end

  def call(conn, {:error, {:response_json_decoder, reason}}) do
    Logger.error(fn ->
      Jason.encode!(%{
        "log_type" => "error",
        "message" => "Cannot decode HTTP JSON response: #{inspect(reason)}",
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    conn
    |> put_status(:failed_dependency)
    |> put_view(Error)
    |> render(:"424", %{message: "Cannot decode HTTP JSON response"})
  end

  def call(conn, params) do
    Logger.error(fn ->
      Jason.encode!(%{
        "log_type" => "error",
        "message" => "No function clause matching in EHealth.Web.FallbackController.call/2: #{inspect(params)}",
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    conn
    |> put_status(:not_implemented)
    |> put_view(Error)
    |> render(:"501")
  end

  def auth_error(conn, {:invalid_token, :token_expired}, _opts) do
    call(conn, {:error, {:access_denied, %{message: "JWT expired", type: :jwt_expired}}})
  end

  def auth_error(conn, _, _opts) do
    call(conn, {:error, :access_denied})
  end
end

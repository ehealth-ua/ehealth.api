defmodule EHealth.Web.FallbackController do
  @moduledoc """
  This controller should be used as `action_fallback` in rest of controllers to remove duplicated error handling.
  """
  use EHealth.Web, :controller

  require Logger

  def call(conn, {:error, json_schema_errors}) when is_list(json_schema_errors) do
    conn
    |> put_status(422)
    |> render(EView.Views.ValidationError, "422.json", %{schema: json_schema_errors})
  end

  def call(conn, {:error, errors, :query_parameter}) when is_list(errors) do
    conn
    |> put_status(422)
    |> render(EView.Views.ValidationError, "422.query.json", %{schema: errors})
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
    |> render(EView.Views.ValidationError, :"422", changeset)
  end

  def call(conn, {:error, _ecto_multi_key, reason, _}) do
    proxy(conn, reason)
  end

  def call(conn, %Ecto.Changeset{valid?: false} = changeset) do
    call(conn, {:error, changeset})
  end

  def call(conn, {:error, %Ecto.Changeset{valid?: false} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(EView.Views.ValidationError, :"422", changeset)
  end

  def call(conn, {:error, {:bad_request, reason}}) when is_binary(reason) do
    conn
    |> put_status(:bad_request)
    |> render(EView.Views.Error, :"400", %{message: reason})
  end

  def call(conn, {:error, :access_denied}) do
    conn
    |> put_status(:unauthorized)
    |> render(EView.Views.Error, :"401")
  end

  def call(conn, {:error, {:access_denied, reason}}) do
    conn
    |> put_status(:unauthorized)
    |> render(EView.Views.Error, :"401", %{reason: reason})
  end

  def call(conn, {:error, :invalid_role}) do
    conn
    |> put_status(:bad_request)
    |> render(EView.Views.Error, :"400", %{message: "User OAuth role does not exists"})
  end

  def call(conn, {:error, %{"type" => "not_found"}}) do
    call(conn, {:error, :not_found})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(EView.Views.Error, :"404")
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> render(EView.Views.Error, :"403")
  end

  def call(conn, {:error, {:forbidden, reason}}) do
    conn
    |> put_status(:forbidden)
    |> render(EView.Views.Error, :"403", %{message: reason})
  end

  def call(conn, {:error, %{"type" => "internal_error"}}) do
    conn
    |> put_status(:internal_server_error)
    |> render(EView.Views.Error, :"500", %{type: "proxied error", message: "remote server internal error"})
  end

  def call(conn, {:error, {:internal_error, message}}) do
    conn
    |> put_status(:internal_server_error)
    |> render(EView.Views.Error, :"500", %{message: message})
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> render(EView.Views.Error, :"404")
  end

  def call(conn, {:error, {:conflict, reason}}) do
    call(conn, {:conflict, reason})
  end

  def call(conn, {:conflict, reason}) do
    conn
    |> put_status(:conflict)
    |> render(EView.Views.Error, :"409", %{message: reason})
  end

  def call(conn, {:error, {:response_json_decoder, reason}}) do
    Logger.error("Cannot decode HTTP JSON response: #{inspect reason}")
    conn
    |> put_status(:failed_dependency)
    |> render(EView.Views.Error, :"424", %{message: "Cannot decode HTTP JSON response"})
  end

  def call(conn, params) do
    Logger.error("No function clause matching in EHealth.Web.FallbackController.call/2: #{inspect params}")
    conn
    |> put_status(:not_implemented)
    |> render(EView.Views.Error, :"501")
  end
end

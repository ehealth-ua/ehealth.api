defmodule EHealth.Web.FallbackController do
  @moduledoc """
  This controller should be used as `action_fallback` in rest of controllers to remove duplicated error handling.
  """
  use EHealth.Web, :controller

  def call(conn, {:error, json_schema_errors}) when is_list(json_schema_errors) do
    conn
    |> put_status(422)
    |> render(EView.Views.ValidationError, "422.json", %{schema: json_schema_errors})
  end

  @doc """
  Proxy response from APIs
  """
  def call(conn, {_, %{"meta" => %{}} = proxy_resp}) do
    proxy(conn, proxy_resp)
  end

  def call(conn, %Ecto.Changeset{valid?: false} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(EView.Views.ValidationError, :"422", changeset)
  end

  def call(conn, {:error, :access_denied}) do
    conn
    |> put_status(:unauthorized)
    |> render(EView.Views.Error, :"401")
  end

  def call(conn, {:error, %{"type" => "not_found"}}) do
    call(conn, {:error, :not_found})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(EView.Views.Error, :"404")
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> render(EView.Views.Error, :"404")
  end

  def call(conn, {:conflict, reason}) do
    conn
    |> put_status(:conflict)
    |> render(EView.Views.Error, :"409", %{message: reason})
  end
end

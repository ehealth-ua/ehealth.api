defmodule Casher.Web.FallbackController do
  @moduledoc """
  This controller should be used as `action_fallback` in rest of controllers to remove duplicated error handling.
  """
  use Casher.Web, :controller

  alias EView.Views.Error

  def call(conn, {:error, {:"422", error}}) do
    conn
    |> put_status(422)
    |> put_view(Error)
    |> render(:"400", %{message: error})
  end

  def call(conn, {:error, {:not_found, reason}}) do
    conn
    |> put_status(:not_found)
    |> put_view(Error)
    |> render(:"404", %{message: reason})
  end

  def call(conn, nil), do: call(conn, {:error, :not_found})

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(Error)
    |> render(:"404")
  end

  def call(conn, {:error, {:internal_error, message}}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(Error)
    |> render(:"500", %{message: message})
  end

  def call(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(Error)
    |> render(:"404")
  end
end

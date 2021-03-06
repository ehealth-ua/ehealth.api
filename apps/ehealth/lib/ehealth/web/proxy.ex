defmodule EHealth.Proxy do
  @moduledoc """
  Proxy response from CRUD APIs
  """

  import Plug.Conn
  import Core.Utils.TypesConverter

  alias Scrivener.Page

  def proxy(conn, %{"meta" => %{"code" => status}} = response) do
    resp =
      response
      |> get_proxy_resp_data()
      |> Jason.encode!()

    paging =
      response
      |> Map.get("paging", %{})
      |> strings_to_keys()

    conn
    |> resp(string_to_integer(status), resp)
    |> assign(:paging, paging)
    |> put_resp_content_type("application/json")
  end

  def get_proxy_resp_data(%{"error" => error}), do: error
  def get_proxy_resp_data(%{"data" => data}), do: data

  def create_page(paging) do
    struct(Page, Enum.into(paging, %{}, fn {k, v} -> {String.to_atom(k), v} end))
  end
end

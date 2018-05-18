defmodule EHealth.Proxy do
  @moduledoc """
  Proxy response from CRUD APIs
  """

  import Plug.Conn
  import EHealth.Utils.TypesConverter

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
end

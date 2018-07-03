defmodule EHealth.MockServer do
  @moduledoc false

  def render(resource, conn, status) do
    conn = Plug.Conn.put_status(conn, status)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, get_resp_body(resource, conn))
  end

  def render_with_paging(resource, conn, paging \\ nil) do
    conn = Plug.Conn.put_status(conn, 200)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(
      200,
      resource
      |> wrap_response_with_paging(paging)
      |> Jason.encode!()
    )
  end

  def get_resp_body(resource, conn), do: resource |> EView.wrap_body(conn) |> Jason.encode!()

  def wrap_response(data, code \\ 200) do
    %{
      "meta" => %{
        "code" => code,
        "type" => "list"
      },
      "data" => data
    }
  end

  def wrap_object_response(data \\ %{}, code \\ 200) do
    %{
      "meta" => %{
        "code" => code
      },
      "data" => data
    }
  end

  def wrap_response_with_paging(data), do: wrap_response_with_paging(data, nil)

  def wrap_response_with_paging(data, nil) do
    wrap_response_with_paging(data, %{
      "page_number" => 1,
      "total_pages" => 1,
      "page_size" => 10,
      "total_entries" => Enum.count(data)
    })
  end

  def wrap_response_with_paging(data, paging) do
    data
    |> wrap_response()
    |> Map.put("paging", paging)
  end
end

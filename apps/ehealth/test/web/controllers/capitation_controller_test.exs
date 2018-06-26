defmodule EHealth.Web.CapitationControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Ecto.UUID

  describe "List capitation reports" do
    test "get capitation report list success", %{conn: conn} do
      report_id = UUID.generate()

      expect(ReportMock, :get_capitation_list, fn _params, _headers ->
        {:ok,
         %{
           "data" => [
             %{
               "billing_date" => "2018-06-01",
               "id" => report_id,
               "inserted_at" => "2018-06-25T15:47:09.351803"
             }
           ],
           "meta" => %{"code" => 200},
           "paging" => %{
             "page_number" => 2,
             "page_size" => 1,
             "total_entries" => 2,
             "total_pages" => 2
           }
         }}
      end)

      response =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(capitation_path(conn, :index, %{page_size: 1, page: 2}))
        |> json_response(200)

      assert %{"data" => [%{"id" => ^report_id}], "paging" => %{"page_number" => 2, "page_size" => 1}} = response
    end
  end
end

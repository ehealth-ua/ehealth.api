defmodule EHealth.Integration.CorruptChainNotificationTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false
  use Bamboo.Test

  import Mox

  describe "Sending mangled chain notification" do
    test "it sends an email to specified recepient" do
      expect(RPCWorkerMock, :run, fn "man_api", Man.Rpc, :render_template, [_id, data] ->
        assert %{
                 failure_details: %{
                   "data" => [
                     %{"a" => 1},
                     %{"b" => 2}
                   ]
                 },
                 format: "text/html",
                 locale: "uk_UA"
               } = data

        {:ok, "<html><body>some_rendered_content</body></html>"}
      end)

      details = %{
        "data" => [
          %{"a" => 1},
          %{"b" => 2}
        ]
      }

      conn = build_conn()

      conn
      |> put_req_header("content-type", "application/json")
      |> post(hash_chain_path(conn, :verification_failed), details)

      assert_delivered_with(html_body: "<html><body>some_rendered_content</body></html>")
    end
  end
end

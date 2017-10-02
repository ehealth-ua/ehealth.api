defmodule EHealth.Integraiton.CorruptChainNotificationTest do
  @moduledoc false

  alias EHealth.Bamboo.Emails.HashChainVeriricationNotification

  use EHealth.Web.ConnCase, async: false
  use Bamboo.Test

  describe "Sending mangled chain notification" do
    defmodule Man do
      @moduledoc false

      use MicroservicesHelper

      Plug.Router.post "/templates/32167/actions/render" do
        %{
          "failure_details" => %{
            "data" => [
              %{"a" => 1},
              %{"b" => 2}
            ]
          },
          "format" => "text/html",
          "locale" => "uk_UA"
        } = conn.params

        template = "<html><body>some_rendered_content</body></html>"

        Plug.Conn.send_resp(conn, 200, template)
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(Man)

      System.put_env("MAN_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MAN_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{conn: conn}}
    end

    test "it sends an email to specified recepient" do
      details = %{
        "data" => [
          %{ "a" => 1 },
          %{ "b" => 2 }
        ]
      }

      conn = build_conn()

      conn
      |> put_req_header("content-type", "application/json")
      |> post(hash_chain_path(conn, :verification_failed), details)

      assert_delivered_email HashChainVeriricationNotification.new("<html><body>some_rendered_content</body></html>")
    end
  end
end

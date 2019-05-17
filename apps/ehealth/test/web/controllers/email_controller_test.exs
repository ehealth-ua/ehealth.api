defmodule EHealth.Web.EmailsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Mox

  # For Mox lib. Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  @man_id Ecto.UUID.generate()

  @valid_params %{
    subject: "some subject",
    from: "from@example.com",
    to: "to@example.com",
    data: %{
      verification_code: 1234
    }
  }

  describe "send email" do
    test "success", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn "man_api", Man.Rpc, :render_template, [@man_id, data] ->
        assert Map.has_key?(data, "locale")
        assert Map.has_key?(data, "format")
        {:ok, "<html>#{inspect(data)}</html>"}
      end)

      assert "Email was successfully sent." =
               conn
               |> post(email_path(conn, :send, @man_id), @valid_params)
               |> json_response(200)
               |> get_in(~w(data message))
    end

    test "invalid Man template id", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn "man_api", Man.Rpc, :render_template, ["123", _data] ->
        nil
      end)

      assert "Cannot render email template" <> _ =
               conn
               |> post(email_path(conn, :send, "123"), @valid_params)
               |> json_response(400)
               |> get_in(~w(error message))
    end

    test "invalid email format", %{conn: conn} do
      assert [err] =
               conn
               |> post(email_path(conn, :send, @man_id), Map.put(@valid_params, :from, "not-so-good.com"))
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.from" == err["entry"]

      assert [err] =
               conn
               |> post(email_path(conn, :send, @man_id), Map.put(@valid_params, :to, "not-so-good.com"))
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.to[0].receiver" == err["entry"]

      assert [err] =
               conn
               |> post(email_path(conn, :send, @man_id), Map.put(@valid_params, :to, "to@smtp.com, not-so-good.com"))
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.to[1].receiver" == err["entry"]
    end

    test "no params", %{conn: conn} do
      assert errors =
               conn
               |> post(email_path(conn, :send, @man_id), %{})
               |> json_response(422)
               |> get_in(~w(error invalid))

      entries =
        errors
        |> Enum.reduce([], fn error, acc ->
          assert %{
                   "entry_type" => "json_data_property",
                   "rules" => [%{"rule" => "required"}]
                 } = error

          [error["entry"] | acc]
        end)
        |> MapSet.new()

      assert MapSet.new(~w($.from $.to)) == entries
    end

    test "no from parameter", %{conn: conn} do
      assert [err] =
               conn
               |> post(email_path(conn, :send, @man_id), Map.delete(@valid_params, :from))
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert %{
               "entry" => "$.from",
               "entry_type" => "json_data_property",
               "rules" => [
                 %{
                   "description" => "required property from was not present",
                   "rule" => "required"
                 }
               ]
             } = err
    end

    test "param from and param to are identical", %{conn: conn} do
      data = Map.put(@valid_params, :to, "from@example.com")

      assert [err] =
               conn
               |> post(email_path(conn, :send, @man_id), data)
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.from" == err["entry"]
    end
  end
end

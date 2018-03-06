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
      expect(ManMock, :render_template, fn @man_id, data ->
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
      expect(ManMock, :render_template, fn "123", _data ->
        {:error, %{"error" => "invalid Man id"}}
      end)

      assert "Cannot render email template with: " <> _ =
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

      assert "$.to" == err["entry"]
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

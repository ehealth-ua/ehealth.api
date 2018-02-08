defmodule EHealth.Web.RegisterControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.Registers.Register

  @status_new Register.status(:new)
  @status_processed Register.status(:processed)
  @status_processing Register.status(:processing)

  describe "list registers" do
    setup %{conn: conn} do
      insert(:il, :register, status: @status_new)
      insert(:il, :register, status: @status_processed)
      insert(:il, :register, status: @status_processing)

      %{conn: conn}
    end

    test "success list", %{conn: conn} do
      assert 3 =
               conn
               |> get(register_path(conn, :index))
               |> json_response(200)
               |> Map.get("data")
               |> length()
    end

    test "search by status", %{conn: conn} do
      data =
        conn
        |> get(register_path(conn, :index), status: @status_processed)
        |> json_response(200)
        |> Map.get("data")

      assert 1 == length(data)
      assert @status_processed == hd(data)["status"]
    end

    test "search by inserted_at range", %{conn: conn} do
      insert(:il, :register, status: @status_processing, inserted_at: ~N[2017-12-12 12:10:12])
      %{id: id} = insert(:il, :register, status: @status_processing, inserted_at: ~N[2017-12-13 02:10:12])
      insert(:il, :register, status: @status_processing, inserted_at: ~N[2017-12-14 14:10:12])

      params = %{
        status: @status_processing,
        inserted_at_from: "2017-12-13",
        inserted_at_to: "2017-12-14"
      }

      assert [register] =
               conn
               |> get(register_path(conn, :index), params)
               |> json_response(200)
               |> Map.get("data")

      assert id == register["id"]
      assert @status_processing == register["status"]
    end
  end

  describe "create register" do
    defmodule Termination do
      use MicroservicesHelper

      Plug.Router.get "/persons_internal" do
        {code, data} =
          case conn.query_params do
            x when x in [%{"passport" => "passport_primary"}, %{"tax_id" => "tax_id_primary"}] ->
              {200, [%{id: Ecto.UUID.generate()}]}

            %{"temporary_certificate" => "processing"} ->
              {500, %{error: "system unavailable"}}

            _ ->
              {200, []}
          end

        send_resp(conn, code, Poison.encode!(%{meta: %{code: code}, data: data}))
      end

      Plug.Router.patch "/persons/:id/declarations/actions/terminate" do
        send_resp(conn, 200, Poison.encode!(%{meta: %{code: 200}, data: %{}}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(Termination)

      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      %{conn: conn}
    end

    test "success with status PROCESSED", %{conn: conn} do
      attrs = %{
        file: get_csv_file("valid"),
        file_name: "persons",
        type: "death"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 0,
               "not_found" => 0,
               "processing" => 0,
               "total" => 3
             } == data["qty"]

      assert "PROCESSED" = data["status"]
    end

    test "success with status PROCESSING", %{conn: conn} do
      attrs = %{
        file: get_csv_file("diverse"),
        file_name: "persons",
        type: "death"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 2,
               "not_found" => 1,
               "processing" => 1,
               "total" => 6
             } == data["qty"]

      assert "PROCESSING" = data["status"]
    end

    test "invalid CSV file", %{conn: conn} do
      attrs = %{
        file: get_csv_file("invalid"),
        file_name: "persons",
        type: "death"
      }

      conn
      |> post(register_path(conn, :create), attrs)
      |> json_response(422)
    end
  end

  describe "create register with param reason_description and user_id" do
    defmodule TerminationWithRequiredParams do
      use MicroservicesHelper

      Plug.Router.get "/persons_internal" do
        send_resp(conn, 200, Poison.encode!(%{meta: %{code: 200}, data: [%{id: Ecto.UUID.generate()}]}))
      end

      Plug.Router.patch "/persons/:id/declarations/actions/terminate" do
        case is_binary(conn.body_params["reason_description"]) do
          true -> send_resp(conn, 200, Poison.encode!(%{meta: %{code: 200}, data: %{}}))
          _ -> send_resp(conn, 404, Poison.encode!(%{meta: %{code: 404}, data: %{}}))
        end
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(TerminationWithRequiredParams)

      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      %{conn: conn}
    end

    test "both params passed", %{conn: conn} do
      attrs = %{
        file: get_csv_file("valid"),
        file_name: "persons",
        type: "death",
        reason_description: "Згідно реєстру померлих"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 0,
               "not_found" => 0,
               "processing" => 0,
               "total" => 3
             } == data["qty"]

      assert "PROCESSED" = data["status"]
    end

    test "param reason_description not passed", %{conn: conn} do
      attrs = %{
        file: get_csv_file("valid"),
        file_name: "persons",
        type: "death"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 0,
               "not_found" => 0,
               "processing" => 3,
               "total" => 3
             } == data["qty"]

      assert "PROCESSING" = data["status"]
    end

    test "header consumer_id not set", %{conn: conn} do
      conn = delete_consumer_id_header(conn)

      attrs = %{
        file: get_csv_file("valid"),
        file_name: "persons",
        type: "death",
        reason_description: "Згідно реєстру померлих"
      }

      message =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(401)
        |> get_in(~w(error message))

      assert "Missing header x-consumer-id" == message
    end
  end

  defp get_csv_file(name) do
    "test/data/register/#{name}.csv"
    |> File.read!()
    |> Base.encode64()
  end
end

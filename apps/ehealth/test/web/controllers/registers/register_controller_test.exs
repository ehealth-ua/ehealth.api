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
            %{"number" => "primary"} ->
              {200, [%{id: Ecto.UUID.generate()}]}

            %{"number" => "processing"} ->
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
      insert(:il, :dictionary_document_type)

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

      # check register_entry
      register_entries =
        conn
        |> get(register_entry_path(conn, :index), register_id: data["id"])
        |> json_response(200)
        |> Map.get("data")

      assert 3 = length(register_entries)
      entry = hd(register_entries)

      assert data["id"] == entry["register_id"]
      assert data["inserted_by"] == entry["updated_by"]
      assert data["updated_by"] == entry["inserted_by"]
    end

    test "success with status PROCESSING", %{conn: conn} do
      %{values: values} = insert(:il, :dictionary_document_type)
      dict_values = Map.keys(values) |> Enum.join(", ")

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
               "errors" => 5,
               "not_found" => 1,
               "processing" => 1,
               "total" => 9
             } == data["qty"]

      assert "PROCESSING" = data["status"]

      assert [
               "Row has length 4 - expected length 2 on line 4",
               "Invalid type - expected one of #{dict_values} on line 6",
               "Row has length 1 - expected length 2 on line 7",
               "Invalid number - expected non empty string on line 8",
               "Row has length 1 - expected length 2 on line 10"
             ] == data["errors"]
    end

    test "invalid CSV file format", %{conn: conn} do
      attrs = %{
        "file" => "invalid base64 string",
        "file_name" => "death",
        "type" => "death"
      }

      assert [invalid] =
               conn
               |> post(register_path(conn, :create), attrs)
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "$.file" == invalid["entry"]
    end

    test "invalid CSV headers", %{conn: conn} do
      csv =
        "test/data/register/invalid_headers.csv"
        |> File.read!()
        |> Base.encode64()

      attrs = %{
        "file" => csv,
        "file_name" => "death",
        "type" => "death"
      }

      assert "Invalid CSV headers" =
               conn
               |> post(register_path(conn, :create), attrs)
               |> json_response(422)
               |> get_in(~w(error message))
    end

    test "invalid CSV body", %{conn: conn} do
      %{values: values} = insert(:il, :dictionary_document_type)
      dict_values = Map.keys(values) |> Enum.join(", ")

      csv =
        "test/data/register/invalid_body.csv"
        |> File.read!()
        |> Base.encode64()

      attrs = %{
        "file" => csv,
        "file_name" => "death",
        "type" => "death"
      }

      data =
        conn
        |> post(register_path(conn, :create), attrs)
        |> json_response(201)
        |> Map.get("data")

      assert %{
               "errors" => 2,
               "not_found" => 0,
               "processing" => 0,
               "total" => 2
             } == data["qty"]

      assert "PROCESSED" = data["status"]

      assert [
               "Invalid number - expected non empty string on line 2",
               "Invalid type - expected one of #{dict_values} on line 3"
             ] == data["errors"]
    end

    test "invalid CSV type field because of empty dictionary values by DOCUMENT_TYPE", %{conn: conn} do
      csv =
        "test/data/register/valid.csv"
        |> File.read!()
        |> Base.encode64()

      attrs = %{
        "file" => csv,
        "file_name" => "death",
        "type" => "death"
      }

      assert "Type not allowed" =
               conn
               |> post(register_path(conn, :create), attrs)
               |> json_response(422)
               |> get_in(~w(error message))
    end
  end

  describe "create register with param reason_description and user_id" do
    defmodule TerminationWithRequiredParams do
      use MicroservicesHelper

      Plug.Router.get "/persons_internal" do
        case is_binary(conn.query_params["type"]) do
          true -> send_resp(conn, 200, Poison.encode!(%{meta: %{code: 200}, data: [%{id: Ecto.UUID.generate()}]}))
          _ -> send_resp(conn, 404, Poison.encode!(%{meta: %{code: 422}, data: %{}}))
        end
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

      insert(:il, :dictionary_document_type)
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

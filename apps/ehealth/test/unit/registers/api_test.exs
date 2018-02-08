defmodule EHealth.Registers.APITest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  alias Ecto.UUID
  alias Ecto.Changeset
  alias EHealth.Registers.Register
  alias EHealth.Registers.API, as: APIRegisters

  describe "process register CSV" do
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

        send_resp(conn, 200, Poison.encode!(%{meta: %{code: code}, data: data}))
      end

      Plug.Router.patch "/persons/:id/declarations/actions/terminate" do
        send_resp(conn, 200, Poison.encode!(%{meta: %{code: 200}, data: %{}}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(Termination)

      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      csv =
        "test/data/register/diverse.csv"
        |> File.read!()
        |> Base.encode64()

      attrs = %{
        "file" => csv,
        "file_name" => "death",
        "type" => "death",
        "reason_description" => "Згідно реєстру померлих"
      }

      %{attrs: attrs}
    end

    test "success processing", %{attrs: attrs} do
      author_id = UUID.generate()

      assert {:ok, %Register{} = register} = APIRegisters.process_register_file(attrs, author_id)
      assert "PROCESSING" = register.status
      assert %Register.Qty{total: 6, errors: 2, not_found: 1, processing: 1} = register.qty
      assert ["Row has length 4 - expected length 5 on line 5", "Row has length 1 - expected length 5 on line 7"]
    end

    test "invalid CSV file format" do
      author_id = UUID.generate()

      attrs = %{
        "file" => "invalid base64 string",
        "file_name" => "death",
        "type" => "death"
      }

      assert %Changeset{valid?: false, errors: [file: _]} = APIRegisters.process_register_file(attrs, author_id)
    end

    test "invalid CSV fields" do
      author_id = UUID.generate()

      csv =
        "test/data/register/invalid.csv"
        |> File.read!()
        |> Base.encode64()

      attrs = %{
        "file" => csv,
        "file_name" => "death",
        "type" => "death"
      }

      assert {:error, {:"422", "Invalid CSV headers"}} = APIRegisters.process_register_file(attrs, author_id)
    end
  end
end

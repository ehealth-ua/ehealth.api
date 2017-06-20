defmodule EHealth.Integraiton.DeclarationRequest.API.CreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Create
  alias EHealth.DeclarationRequest

  import Ecto.Changeset, only: [get_change: 2]

  describe "generate_upload_urls/1" do
    test "generates links & updates declaration request" do
      changeset =
        %DeclarationRequest{id: "98e0a42f-20fe-472c-a614-0ea99426a3fb"}
        |> Ecto.Changeset.change()
        |> generate_upload_urls()

      expected_documents = [
        %{
          "type" => "Passport",
          "url" => "http://some_resource.com/98e0a42f-20fe-472c-a614-0ea99426a3fb/declaration_request_Passport.jpeg"
        },
        %{
          "type" => "SSN",
          "url" => "http://some_resource.com/98e0a42f-20fe-472c-a614-0ea99426a3fb/declaration_request_SSN.jpeg"
        }
      ]

      assert get_change(changeset, :documents) == expected_documents
    end

    @tag pending: true
    test "returns error on documents field" do
    end
  end

  describe "generate_printout_form/1" do
    test "updates declaration request with printout form" do
      changeset =
        %DeclarationRequest{id: 123}
        |> Ecto.Changeset.change()
        |> generate_printout_form()

      expected_content = "<html><body>Printout form for declaration request #123</body></hrml>"

      assert get_change(changeset, :printout_content) == expected_content
    end

    @tag pending: true
    test "returns error on printout_content field" do
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI record exists" do
    defmodule MpiExists do
      use MicroservicesHelper

      Plug.Router.get "/persons" do
        confirm_params =
          conn
          |> Plug.Conn.fetch_query_params(conn)
          |> Map.get(:params)

        %{
          "first_name" => "Олена",
          "last_name" => "Пчілка",
          "phone_number" => "+380508887700",
          "birth_date" => "2010-08-19 00:00:00",
          "tax_id" => "3126509816"
        } = confirm_params

        search_result = [
          %{id: "b5350f79-f2ca-408f-b15d-1ae0a8cc861c"}
        ]

        send_resp(conn, 200, Poison.encode!(%{data: search_result}))
      end

      Plug.Router.get "/persons/b5350f79-f2ca-408f-b15d-1ae0a8cc861c" do
        person = %{
          "authentication_methods": [
            %{"type": "OTP", "number": "+380508887700"}
          ]
        }

        send_resp(conn, 200, Poison.encode!(%{data: person}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(MpiExists)

      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "auth method's type is set to OTP password" do
      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "first_name" => "Олена",
            "last_name" => "Пчілка",
            "birth_date" => "2010-08-19",
            "tax_id" => "3126509816",
            "phones" => [%{
              "number" => "+380508887700"
            }],
            "authentication_methods" => [%{
              "number" => "+380508887700"
            }]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> determine_auth_method_for_mpi()

      assert get_change(changeset, :authentication_method_current) ==
        %{"number" => "+380508887700", "type" => "OTP"}
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI record does not exist" do
    defmodule NoMpi do
      use MicroservicesHelper

      Plug.Router.get "/persons" do
        send_resp(conn, 200, Poison.encode!(%{data: []}))
      end

      Plug.Router.post "/api/v1/tables/58f62b96e79e8521f51b5754/decisions" do
        decision = %{
          "final_decision": "OFFLINE"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: decision}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(NoMpi)

      System.put_env("GNDF_ENDPOINT", "http://localhost:#{port}")
      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        System.put_env("GNDF_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "MPI record does not exist, e.g. Gandalf makes a decision" do
      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "first_name" => "Олександр",
            "last_name" => "Олесь",
            "birth_date" => "1988-08-19 00:00:00",
            "tax_id" => "3126509817",
            "phones" => [%{
              "number" => "+380508887701"
            }],
            "authentication_methods" => [%{
              "number" => "+380508887701"
            }]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> determine_auth_method_for_mpi()

      assert get_change(changeset, :authentication_method_current) ==
        %{"number" => "+380508887701", "type" => "OFFLINE"}
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI returns an error" do
    defmodule MpiError do
      use MicroservicesHelper

      Plug.Router.get "/persons" do
        send_resp(conn, 404, Poison.encode!(%{something: "terrible"}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(MpiError)

      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "MPI returns an error" do
      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "phones" => [%{
              "number" => "+380508887701"
            }]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> determine_auth_method_for_mpi()

      assert ~s(Error during MPI interaction. Result from MPI: {:error, %{"something" => "terrible"}}) ==
        elem(changeset.errors[:authentication_method_current], 0)
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI record does not exist (2)" do
    defmodule GandalfError do
      use MicroservicesHelper

      Plug.Router.get "/persons" do
        send_resp(conn, 200, Poison.encode!(%{data: []}))
      end

      Plug.Router.post "/api/v1/tables/58f62b96e79e8521f51b5754/decisions" do
        decision = %{
          "final_decision": "OFFLINE"
        }

        Plug.Conn.send_resp(conn, 404, Poison.encode!(%{something: "terrible"}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(GandalfError)

      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      System.put_env("GNDF_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        System.put_env("GNDF_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "Gandalf returns an error" do
      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "phones" => [%{
              "number" => "+380508887701"
            }],
            "authentication_methods" => [%{
              "number" => "+380508887701"
            }]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> determine_auth_method_for_mpi()

      assert ~s(Error during Gandalf interaction. Result from Gandalf: {:error, %{"something" => "terrible"}}) ==
        elem(changeset.errors[:authentication_method_current], 0)
    end
  end
end

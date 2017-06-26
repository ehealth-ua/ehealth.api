defmodule EHealth.Integraiton.DeclarationRequest.API.CreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Create
  alias EHealth.DeclarationRequest

  import Ecto.Changeset, only: [get_change: 2]

  describe "generate_upload_urls/1" do
    defmodule UploadingFiles do
      use MicroservicesHelper

      Plug.Router.post "/media_content_storage_secrets" do
        params = conn.body_params["secret"]

        case params["resource_id"] do
          "98e0a42f-20fe-472c-a614-0ea99426a3fb" ->
            upload = %{
              secret_url: "http://a.link.for/#{params["resource_id"]}/#{params["resource_name"]}"
            }

            Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: upload}))
          "98e0a42f-0000-9999-5555-0ea99426a3fb" ->
            Plug.Conn.send_resp(conn, 500, Poison.encode!(%{something: "went wrong with #{params["resource_name"]}"}))
        end
      end
    end

    setup %{conn: _conn} do
      {:ok, port, ref} = start_microservices(UploadingFiles)

      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "generates links & updates declaration request" do
      changeset =
        %DeclarationRequest{id: "98e0a42f-20fe-472c-a614-0ea99426a3fb"}
        |> Ecto.Changeset.change()
        |> generate_upload_urls()

      expected_documents = [
        %{
          "type" => "Passport",
          "url" => "http://a.link.for/98e0a42f-20fe-472c-a614-0ea99426a3fb/declaration_request_Passport.jpeg"
        },
        %{
          "type" => "SSN",
          "url" => "http://a.link.for/98e0a42f-20fe-472c-a614-0ea99426a3fb/declaration_request_SSN.jpeg"
        }
      ]

      assert get_change(changeset, :documents) == expected_documents
    end

    test "returns error on documents field" do
      changeset =
        %DeclarationRequest{id: "98e0a42f-0000-9999-5555-0ea99426a3fb"}
        |> Ecto.Changeset.change()
        |> generate_upload_urls()

      error_message = ~s(Error during MediaStorage interaction. Result from MediaStorage: \
%{"something" => "went wrong with declaration_request_Passport.jpeg"}; Error during \
MediaStorage interaction. Result from MediaStorage: %{"something" => "went wrong with \
declaration_request_SSN.jpeg"})

      assert error_message == elem(changeset.errors[:documents], 0)
    end
  end

  describe "generate_printout_form/1" do
    defmodule PrintoutForm do
      use MicroservicesHelper

      Plug.Router.post "/templates/4/actions/render" do
        printout_form = "Template id=#4 and declaration request ##{conn.body_params["declaration_request_id"]}"

        Plug.Conn.send_resp(conn, 200, printout_form)
      end

      Plug.Router.post "/templates/999/actions/render" do
        Plug.Conn.send_resp(conn, 404, "oops, I did it again")
      end
    end

    setup %{conn: _conn} do
      {:ok, port, ref} = start_microservices(PrintoutForm)

      System.put_env("MAN_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MAN_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "updates declaration request with printout form" do
      printout_form_id = Confex.get_map(:ehealth, EHealth.Man.Templates.DeclarationRequestPrintoutForm)[:id]

      changeset =
        %DeclarationRequest{id: 321}
        |> Ecto.Changeset.change()
        |> generate_printout_form()

      expected_content = "Template id=##{printout_form_id} and declaration request #321"

      assert get_change(changeset, :printout_content) == expected_content
    end

    test "returns error on printout_content field" do
      System.put_env("DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", "999")

      changeset =
        %DeclarationRequest{id: 321}
        |> Ecto.Changeset.change()
        |> generate_printout_form()

      assert ~s(Error during MAN interaction. Result from MAN: "oops, I did it again") ==
        elem(changeset.errors[:printout_content], 0)

      System.put_env("DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", "4")
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

      Plug.Router.post "/api/v1/tables/some_gndf_table_id/decisions" do
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

      assert ~s(Error during MPI interaction. Result from MPI: %{"something" => "terrible"}) ==
        elem(changeset.errors[:authentication_method_current], 0)
    end
  end

  describe "determine_auth_method_for_mpi/1, MPI record does not exist (2)" do
    defmodule GandalfError do
      use MicroservicesHelper

      Plug.Router.get "/persons" do
        send_resp(conn, 200, Poison.encode!(%{data: []}))
      end

      Plug.Router.post "/api/v1/tables/some_gndf_table_id/decisions" do
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

      assert ~s(Error during Gandalf interaction. Result from Gandalf: %{"something" => "terrible"}) ==
        elem(changeset.errors[:authentication_method_current], 0)
    end
  end

  describe "send_verification_code/1" do
    defmodule SendingVerificationCode do
      use MicroservicesHelper

      Plug.Router.post "/verifications/+380991234567" do
        send_resp(conn, 200, Poison.encode!(%{data: ["response_we_don't_care_about"]}))
      end

      Plug.Router.post "/verifications/+380508887700" do
        send_resp(conn, 404, Poison.encode!(%{}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(SendingVerificationCode)

      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "code was successfully sent" do
      multi = %{
        declaration_request: %{
          authentication_method_current: %{
            "number" => "+380991234567"
          }
        }
      }

      assert {:ok, _} = send_verification_code(multi)
    end

    test "code was not sent" do
      multi = %{
        declaration_request: %{
          authentication_method_current: %{
            "number" => "+380508887700"
          }
        }
      }

      assert {:error, _} = send_verification_code(multi)
    end
  end
end

defmodule EHealth.Integraiton.DeclarationRequest.API.CreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Create
  alias EHealth.DeclarationRequest
  alias EHealth.Dictionaries

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
      result = generate_upload_urls("98e0a42f-20fe-472c-a614-0ea99426a3fb", ["Passport", "SSN"])

      expected_documents = [
        %{
          "type" => "SSN",
          "verb" => "PUT",
          "url" => "http://a.link.for/98e0a42f-20fe-472c-a614-0ea99426a3fb/declaration_request_SSN.jpeg"
        },
        %{
          "type" => "Passport",
          "verb" => "PUT",
          "url" => "http://a.link.for/98e0a42f-20fe-472c-a614-0ea99426a3fb/declaration_request_Passport.jpeg"
        }
      ]

      assert {:ok, expected_documents} == result
    end

    test "returns error on documents field" do
      result = generate_upload_urls("98e0a42f-0000-9999-5555-0ea99426a3fb", ["Passport"])

      error_message = ~s(Error during MediaStorage interaction. Result from MediaStorage: \
%{"something" => "went wrong with declaration_request_Passport.jpeg"})

      assert {:error, error_message} == result
    end
  end

  describe "generate_printout_form/1" do
    defmodule PrintoutForm do
      use MicroservicesHelper

      Plug.Router.post "/templates/4/actions/render" do
        printout_form =
          conn.body_params
          |> Map.drop(["locale", "format"])
          |> Poison.encode!()

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

      Dictionaries.create_dictionary(%{
        name: "SETTLEMENT_TYPE",
        labels: [],
        values: %{"CITY": "місто"}
      })

      Dictionaries.create_dictionary(%{
        name: "STREET_TYPE",
        labels: [],
        values: %{"STREET": "вулиця"}
      })

      :ok
    end

    test "updates declaration request with expected printout form when data is valid" do
      data =
        "test/data/sign_declaration_request.json"
        |> File.read!()
        |> Poison.decode!

      printout_content =
        %DeclarationRequest{id: 321, data: data}
        |> Ecto.Changeset.change()
        |> generate_printout_form()
        |> get_change(:printout_content)

      expected_content = %{
        person: %{
          full_name: "Петро Миколайович Іванов",
          gender: %{
            male: true,
            female: false
          },
          birth_date: "1991-08-19",
          document: %{
            type: "PASSPORT",
            number: "120518"
          },
          birth_settlement: "Вінниця",
          birth_country: "Україна",
          tax_id: "3126509816",
          addresses: %{
            registration: %{
              full_address: "Житомирська область, Бердичівський район, місто Київ, вулиця Ніжинська 15, квартира 23, \
02090"
            },
            residence: %{
              full_address: "Житомирська область, Бердичівський район, місто Київ, вулиця Ніжинська 16, квартира 41, \
02090"
            }
          },
          phones: %{
            number: "+380503410870"
          },
          email: "email@example.com",
          secret: "secret",
          emergency_contact: %{
            full_name: "Петро Миколайович Іванов",
            phones: %{
              number: "+380503410870"
            }
          },
          confidant_person: %{
            primary: %{
              full_name: "Петро Миколайович Іванов",
              phones: %{
                number: "+380503410870"
              },
              birth_date: "1991-08-19",
              gender: %{
                male: true,
                female: false
              },
              birth_settlement: "Вінниця",
              birth_country: "Україна",
              documents_person: %{
                type: "PASSPORT",
                number: "120518"
              },
              tax_id: "3126509816",
              documents_relationship: %{
                type: "PASSPORT",
                number: "120519"
              }
            },
            secondary: %{
              full_name: "Іван Миколайович Петров",
              phones: %{
                number: "+380503410871"
              },
              birth_date: "1991-08-20",
              gender: %{
                male: true,
                female: false
              },
              birth_settlement: "Вінниця",
              birth_country: "Україна",
              documents_person: %{
                type: "PASSPORT",
                number: "120520"
              },
              tax_id: "3126509817",
              documents_relationship: %{
                type: "PASSPORT",
                number: "120521"
              }
            }
          }
        },
        employee: %{
          full_name: "Петро Миколайович Іванов",
          phones: %{
            number: "+380503410870"
          },
          email: "email@example.com"
        },
        division: %{
          addresses: %{
            registration: %{
              full_street: "вулиця Ніжинська 15",
              settlement: "місто Київ"
            }
          }
        },
        legal_entity: %{
          full_name: "ЦПМСД №1",
          addresses: %{
            registration: %{
              full_address: "Житомирська область, Бердичівський район, місто Київ, вулиця Ніжинська 15, квартира 23, \
02090"
            }
          },
          edrpou: "5432345432",
          full_license: "",
          phones: %{
            number: "+380503410870"
          },
          email: "email@example.com"
        },
        confidant_persons: %{
          exist: true,
          secondary: true
        },
        authentication_method_current: %{
          otp: true,
          offline: false
        }
      }

      assert printout_content == Poison.encode!(expected_content)
    end

    test "updates declaration request with printout form that has empty fields when data is empty" do
      printout_content =
        %DeclarationRequest{id: 321, data: %{}}
        |> Ecto.Changeset.change()
        |> generate_printout_form()
        |> get_change(:printout_content)

      expected_content = %{
        person: %{
          full_name: "",
          gender: %{
            male: false,
            female: false
          },
          birth_date: nil,
          document: nil,
          birth_settlement: nil,
          birth_country: nil,
          tax_id: nil,
          addresses: %{
            registration: %{
              full_address: nil
            },
            residence: %{
              full_address: nil
            }
          },
          phones: nil,
          email: nil,
          secret: nil,
          emergency_contact: %{
            full_name: "",
            phones: nil
          },
          confidant_person: %{
            primary: nil,
            secondary: nil
          }
        },
        employee: %{
          full_name: "",
          phones: nil,
          email: nil
        },
        division: %{
          addresses: %{
            registration: %{
              full_street: nil,
              settlement: nil
            }
          }
        },
        legal_entity: %{
          full_name: nil,
          addresses: %{
            registration: %{
              full_address: nil
            }
          },
          edrpou: nil,
          full_license: "",
          phones: nil,
          email: nil
        },
        confidant_persons: %{
          exist: false,
          secondary: false
        },
        authentication_method_current: %{
          otp: false,
          offline: false
        }
      }

      assert printout_content == Poison.encode!(expected_content)
    end

    test "returns error on printout_content field" do
      System.put_env("DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", "999")

      changeset =
        %DeclarationRequest{id: 321, data: %{}}
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
          "second_name" => "XXX",
          "birth_date" => "2010-08-19",
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
            %{"type": "OTP", "phone_number": "+380508887700"}
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
            "second_name" => "XXX",
            "last_name" => "Пчілка",
            "birth_date" => "2010-08-19",
            "tax_id" => "3126509816",
            "authentication_methods" => [%{
              "phone_number" => "+380508887700"
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
            "birth_date" => "1988-08-19",
            "tax_id" => "3126509817",
            "authentication_methods" => [%{
              "phone_number" => "+380508887701"
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
              "phone_number" => "+380508887701"
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

      Plug.Router.post "/verifications" do
        code =
          case conn.body_params["phone_number"] do
            "+380991234567" -> 200
            "+380508887700" -> 404
          end

        send_resp(conn, code, Poison.encode!(%{data: ["response_we_don't_care_about"]}))
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
      assert {:ok, _} = send_verification_code("+380991234567")
    end

    test "code was not sent" do
      assert {:error, _} = send_verification_code("+380508887700")
    end
  end
end

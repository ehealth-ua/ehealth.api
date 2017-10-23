defmodule EHealth.Integraiton.DeclarationRequest.API.CreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Create
  alias EHealth.DeclarationRequest
  alias EHealth.Dictionaries

  import Ecto.Changeset, only: [get_change: 2, put_change: 3]

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

      Dictionaries.create_dictionary(%{
        name: "DOCUMENT_TYPE",
        labels: [],
        values: %{"PASSPORT": "Паспорт"}
      })

      :ok
    end

    test "updates declaration request with expected printout form when data is valid" do
      data =
        "test/data/sign_declaration_request.json"
        |> File.read!()
        |> Poison.decode!

      authentication_method_current = %{
        "type" => "OTP"
      }

      printout_content =
        %DeclarationRequest{id: 321, data: data}
        |> Ecto.Changeset.change()
        |> put_change(:authentication_method_current, authentication_method_current)
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
            type: "Паспорт",
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
                type: "Паспорт",
                number: "120518"
              },
              tax_id: "3126509816",
              documents_relationship: %{
                type: "Паспорт",
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
                type: "Паспорт",
                number: "120520"
              },
              tax_id: "3126509817",
              documents_relationship: %{
                type: "Паспорт",
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
        },
        declaration_id: ""
      }

      assert printout_content == Poison.encode!(expected_content)
    end

    test "updates declaration request with printout form that has empty fields when data is empty" do
      printout_content =
        %DeclarationRequest{id: 321, data: %{}}
        |> Ecto.Changeset.change()
        |> put_change(:authentication_method_current, %{})
        |> generate_printout_form()
        |> get_change(:printout_content)

      expected_content = %{
        person: %{
          full_name: "",
          gender: %{
            male: false,
            female: false
          },
          birth_date: "",
          document: %{
            type: "",
            number: ""
          },
          birth_settlement: "",
          birth_country: "",
          tax_id: "",
          addresses: %{
            registration: %{
              full_address: ""
            },
            residence: %{
              full_address: ""
            }
          },
          phones: %{
            number: ""
          },
          email: "",
          secret: "",
          emergency_contact: %{
            full_name: "",
            phones: %{
              number: ""
            }
          },
          confidant_person: %{
            primary: %{},
            secondary: %{}
          }
        },
        employee: %{
          full_name: "",
          phones: %{
            number: ""
          },
          email: ""
        },
        division: %{
          addresses: %{
            registration: %{
              full_street: "",
              settlement: ""
            }
          }
        },
        legal_entity: %{
          full_name: "",
          addresses: %{
            registration: %{
              full_address: ""
            }
          },
          edrpou: "",
          full_license: "",
          phones: %{
            number: ""
          },
          email: ""
        },
        confidant_persons: %{
          exist: false,
          secondary: false
        },
        authentication_method_current: %{
          otp: false,
          offline: false
        },
        declaration_id: ""
      }

      assert printout_content == Poison.encode!(expected_content)
    end

    test "returns error on printout_content field" do
      System.put_env("DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", "999")

      changeset =
        %DeclarationRequest{id: 321, data: %{}}
        |> Ecto.Changeset.change()
        |> put_change(:authentication_method_current, %{})
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

      Plug.Router.post "/api/v1/tables/not_available/decisions" do
        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: %{final_decision: "NA"}}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(NoMpi)

      System.put_env("GNDF_ENDPOINT", "http://localhost:#{port}")
      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        System.put_env("GNDF_ENDPOINT", "http://localhost:4040")
        System.put_env("GNDF_TABLE_ID", "some_gndf_table_id")
        stop_microservices(ref)
      end

      :ok
    end

    test "MPI record does not exist" do
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

      assert get_change(changeset, :authentication_method_current) == %{"type" => "NA"}
    end

    test "Gandalf makes a NA decision" do
      System.put_env("GNDF_TABLE_ID", "not_available")
      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "first_name" => "Олександр",
            "last_name" => "Олесь",
            "birth_date" => "1988-08-19",
            "tax_id" => "3126509817",
            "authentication_methods" => [%{
              "type" => "OTP",
              "phone_number" => "+380508887702"
            }]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> determine_auth_method_for_mpi()

      assert get_change(changeset, :authentication_method_current) == %{"type" => "NA"}
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

    test "authentication_methods OTP converts to NA" do
      declaration_request = %DeclarationRequest{
        data: %{
          "person" => %{
            "phones" => [%{
              "number" => "+380508887701"
            }],
            "authentication_methods" => [%{
              "type" => "OTP",
              "phone_number" => "+380508887701"
            }]
          }
        }
      }

      changeset =
        declaration_request
        |> Ecto.Changeset.change()
        |> determine_auth_method_for_mpi()

      assert get_change(changeset, :authentication_method_current) == %{"type" => "NA"}
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

  describe "put_party_email/1" do
    defmodule PRMMithrilMock do
      use MicroservicesHelper

      @invalid_party_id "6b4127ea-99ad-4493-b5ce-6f0769fa9fab"
      @invalid_user_id "79d70fe0-00dd-4dc3-b302-c8f3a6f6ad38"
      @user_id "53c63398-7033-47f6-9602-be250e35049e"
      @role_id Ecto.UUID.generate()

      def user_id, do: @user_id

      # PRM API
      Plug.Router.get "/party_users" do
        party_id = Map.get(conn.query_params, "party_id")
        user_id = case party_id do
          @invalid_party_id -> @invalid_user_id
          _ -> @user_id
        end
        party_users = [%{
          "user_id": user_id
        }]

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: party_users}))
      end

      # Mithril API
      Plug.Router.get "/admin/roles" do
        roles = [%{
          "id" => @role_id
        }]

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: roles}))
      end

      Plug.Router.get "/admin/users/#{@invalid_user_id}/roles" do
        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: []}))
      end

      Plug.Router.get "/admin/users/#{@user_id}/roles" do
        roles = [%{
          "user_id" => @user_id,
          "role_id" => @role_id
        }]

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: roles}))
      end

      Plug.Router.get "/admin/users/#{@user_id}" do
        user = %{
          "email" => "user@email.com"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: user}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(PRMMithrilMock)

      System.put_env("PRM_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OAUTH_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("PRM_ENDPOINT", "http://localhost:4040")
        System.put_env("OAUTH_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "user is not doctor" do
      types = %{"data" => :map}
      data = %{"employee" => %{"party" => %{"id" => "6b4127ea-99ad-4493-b5ce-6f0769fa9fab"}}}
      changes = %{data: data}
      errors = [email: {"Current user is not a doctor", []}]
      expected_result =
        %Ecto.Changeset{action: nil, changes: changes, errors: errors, data: data, types: types, valid?: false}
      result = put_party_email(%Ecto.Changeset{data: data, changes: changes, types: types, valid?: true})
      assert expected_result == result
    end

    test "everything is ok" do
      types = %{"data" => :map}
      party_user = insert(:prm, :party_user, user_id: PRMMithrilMock.user_id())
      data = %{"employee" => %{"party" => %{"id" => party_user.party_id}}}
      expected_changes = %{data: put_in(data, ["employee", "party", "email"], "user@email.com")}
      changes = %{data: data}
      expected_result =
        %Ecto.Changeset{action: nil, changes: expected_changes, errors: [], data: data, types: types, valid?: true}
      result = put_party_email(%Ecto.Changeset{data: data, changes: changes, types: types, valid?: true})
      assert expected_result == result
    end
  end
end

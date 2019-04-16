defmodule EHealth.Web.Cabinet.DeclarationRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  import Core.Expectations.Man
  alias Ecto.UUID
  alias Core.Repo
  alias Core.DeclarationRequests.DeclarationRequest

  @person_non_create_params ~w(
    version
    national_id
    death_date
    invalid_tax_id
    is_active
    status
    inserted_by
    updated_by
    master_persons
    merged_persons
    id
  )

  setup :verify_on_exit!

  setup do
    insert(:prm, :global_parameter, %{parameter: "adult_age", value: "18"})
    insert(:prm, :global_parameter, %{parameter: "declaration_term", value: "40"})
    insert(:prm, :global_parameter, %{parameter: "declaration_term_unit", value: "YEARS"})
    insert_dictionaries()
    :ok
  end

  def gen_sequence_number do
    expect(DeclarationRequestsCreatorMock, :sql_get_sequence_number, fn ->
      {:ok, %Postgrex.Result{rows: [[Enum.random(1_000_000..2_000_000)]]}}
    end)
  end

  describe "create declaration request online" do
    test "success create declaration request online for underage person for PEDIATRICIAN", %{conn: conn} do
      cabinet()

      person_id = UUID.generate()
      gen_sequence_number()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "2222222225"
           }
         }}
      end)

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 10)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok,
         build(:person,
           id: id,
           birth_date: birth_date,
           unzr: unzr(birth_date),
           documents: get_person_documents(),
           tax_id: "2222222225",
           no_tax_id: false,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact(),
           confidant_person: get_person_confidant_person()
         )}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "PEDIATRICIAN")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)
      template()

      resp =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })
        |> json_response(200)

      assert Kernel.trunc(Date.diff(Date.from_iso8601!(resp["data"]["end_date"]), Date.from_iso8601!(birth_date)) / 365) ==
               Core.GlobalParameters.get_values()["adult_age"]
               |> String.to_integer()

      assert %{
               "data" => %{
                 "seed" => "some_current_hash",
                 "employee" => %{
                   "speciality" => "PEDIATRICIAN"
                 }
               }
             } = resp

      for key <- Map.keys(resp["data"]["person"]) do
        refute key in @person_non_create_params
      end

      assert get_person_documents() == resp["data"]["person"]["documents"]

      declaration_request = Repo.get(DeclarationRequest, get_in(resp, ~w(data id)))
      assert declaration_request.mpi_id == person_id
    end

    test "create declaration request online for person refused tax_id", %{conn: conn} do
      cabinet()

      person_id = UUID.generate()
      gen_sequence_number()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id
           }
         }}
      end)

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 10)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok,
         build(:person,
           id: id,
           birth_date: birth_date,
           unzr: unzr(birth_date),
           documents: get_person_documents(),
           no_tax_id: true,
           tax_id: nil,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact(),
           confidant_person: get_person_confidant_person()
         )}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "PEDIATRICIAN")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)
      template()

      resp =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })
        |> json_response(200)

      assert Kernel.trunc(Date.diff(Date.from_iso8601!(resp["data"]["end_date"]), Date.from_iso8601!(birth_date)) / 365) ==
               Core.GlobalParameters.get_values()["adult_age"]
               |> String.to_integer()

      assert %{
               "data" => %{
                 "seed" => "some_current_hash",
                 "employee" => %{
                   "speciality" => "PEDIATRICIAN"
                 }
               }
             } = resp

      for key <- Map.keys(resp["data"]["person"]) do
        refute key in @person_non_create_params
      end

      declaration_request = Repo.get(DeclarationRequest, get_in(resp, ~w(data id)))
      assert declaration_request.mpi_id == person_id
    end

    test "create declaration request online fails for person refused tax_id but has tax_id", %{conn: conn} do
      cabinet()

      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "0123456789"
           }
         }}
      end)

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 10)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok,
         build(:person,
           id: id,
           birth_date: birth_date,
           unzr: unzr(birth_date),
           documents: get_person_documents(),
           no_tax_id: true,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact(),
           confidant_person: get_person_confidant_person()
         )}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "PEDIATRICIAN")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)

      resp =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "rules" => [
                     %{
                       "rule" => "invalid",
                       "params" => ["no_tax_id"],
                       "description" => "Persons who refused the tax_id should be without tax_id"
                     }
                   ],
                   "entry" => "$.person.person.tax_id"
                 }
               ]
             } = resp["error"]
    end

    test "create declaration request online fails for adult that has no tax_id but has did not refuse tax_id (no_tax_id = false)",
         %{conn: conn} do
      cabinet()

      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id
           }
         }}
      end)

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 16)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok,
         build(:person,
           id: id,
           birth_date: birth_date,
           unzr: unzr(birth_date),
           documents: get_person_documents(),
           tax_id: nil,
           no_tax_id: false,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact(),
           confidant_person: get_person_confidant_person()
         )}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "PEDIATRICIAN")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)

      resp =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.person.person.tax_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Only persons who refused the tax_id could be without tax_id",
                       "params" => ["tax_id"],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ],
               "type" => "validation_failed"
             } = resp["error"]
    end

    test "create declaration request online does not fail for children that has no tax_id but has did not refuse tax_id (no_tax_id = false)",
         %{conn: conn} do
      cabinet()

      person_id = UUID.generate()
      gen_sequence_number()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id
           }
         }}
      end)

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 13)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok,
         build(:person,
           id: person_id,
           birth_date: birth_date,
           unzr: unzr(birth_date),
           documents: get_person_documents(),
           tax_id: nil,
           no_tax_id: false,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact(),
           confidant_person: get_person_confidant_person()
         )}
      end)

      role_id = UUID.generate()
      expect(MithrilMock, :get_user_by_id, fn _, _ -> {:ok, %{"data" => %{"email" => "user@email.com"}}} end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "PEDIATRICIAN")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)
      template()

      conn
      |> put_req_header("edrpou", "2222222220")
      |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
      |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
      |> post(cabinet_declaration_requests_path(conn, :create), %{
        person_id: person_id,
        employee_id: employee.id,
        division_id: employee.division.id
      })
      |> json_response(200)
    end

    test "invalid doctor speciality", %{conn: conn} do
      cabinet()
      person_id = UUID.generate()
      gen_sequence_number()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "2222222225",
             "no_tax_id" => false
           }
         }}
      end)

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 20)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok,
         build(:person,
           id: person_id,
           birth_date: birth_date,
           unzr: unzr(birth_date),
           documents: get_person_documents(),
           tax_id: "2222222225",
           no_tax_id: false,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact()
         )}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "PEDIATRICIAN")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)

      resp =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.data",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "Doctor speciality doesn't match patient's age",
                     "params" => [],
                     "rule" => "invalid_age"
                   }
                 ]
               }
             ] == resp["error"]["invalid"]
    end

    test "success create declaration request online for underage person for FAMILY_DOCTOR without unzr", %{conn: conn} do
      cabinet()

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 10)
        |> to_string()

      person_id = UUID.generate()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        person =
          build(:person,
            id: person_id,
            birth_date: birth_date,
            documents: get_person_documents(),
            tax_id: "2222222225",
            no_tax_id: false,
            authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
            addresses: get_person_addresses(),
            emergency_contact: get_person_emergency_contact(),
            confidant_person: get_person_confidant_person()
          )

        {:ok, Map.delete(person, :unzr)}
      end)

      gen_sequence_number()
      role_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, 2, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "2222222225",
             "no_tax_id" => false,
             "email" => "user@email.com"
           }
         }}
      end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "FAMILY_DOCTOR")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)
      template()

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })

      resp = json_response(conn, 200)

      assert Kernel.trunc(Date.diff(Date.from_iso8601!(resp["data"]["end_date"]), Date.utc_today()) / 365) ==
               Core.GlobalParameters.get_values()["declaration_term"]
               |> String.to_integer()

      assert %{
               "data" => %{
                 "seed" => "some_current_hash",
                 "employee" => %{
                   "speciality" => "FAMILY_DOCTOR"
                 }
               }
             } = resp

      for key <- Map.keys(resp["data"]["person"]) do
        refute key in @person_non_create_params
      end

      declaration_request = Repo.get(DeclarationRequest, get_in(resp, ~w(data id)))
      assert declaration_request.mpi_id == person_id
    end

    test "create declaration request online fails unzr does not match birthdate", %{conn: conn} do
      cabinet()
      person_id = UUID.generate()

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 10)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok,
         build(:person,
           id: person_id,
           birth_date: birth_date,
           unzr: "20180831-23459",
           documents: get_person_documents(),
           tax_id: "2222222225",
           no_tax_id: false,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact(),
           confidant_person: get_person_confidant_person()
         )}
      end)

      expect(MithrilMock, :get_user_by_id, 1, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "2222222225",
             "email" => "user@email.com"
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "FAMILY_DOCTOR")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })

      resp = json_response(conn, 422)

      assert [
               %{
                 "entry" => "$.person.person.unzr",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "Birthdate or unzr is not correct",
                     "params" => ["unzr"],
                     "rule" => "invalid"
                   }
                 ]
               }
             ] == resp["error"]["invalid"]
    end

    test "successful declaration request online creation with undefined unzr", %{conn: conn} do
      cabinet()
      person_id = UUID.generate()

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 10)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        person =
          build(:person,
            id: person_id,
            birth_date: birth_date,
            unzr: nil,
            documents: get_person_documents(),
            tax_id: "2222222225",
            no_tax_id: false,
            authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
            addresses: get_person_addresses(),
            emergency_contact: get_person_emergency_contact(),
            confidant_person: get_person_confidant_person()
          )

        {:ok, Map.delete(person, :unzr)}
      end)

      gen_sequence_number()
      role_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, 2, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "2222222225",
             "no_tax_id" => false,
             "email" => "user@email.com"
           }
         }}
      end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "FAMILY_DOCTOR")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)
      template()

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })

      assert json_response(conn, 200)
    end

    test "success create declaration request online for underage person for FAMILY_DOCTOR with unzr", %{conn: conn} do
      cabinet()
      person_id = UUID.generate()

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 10)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok,
         build(:person,
           id: person_id,
           birth_date: birth_date,
           unzr: unzr(birth_date),
           documents: get_person_documents(),
           tax_id: "2222222225",
           no_tax_id: false,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact(),
           confidant_person: get_person_confidant_person()
         )}
      end)

      gen_sequence_number()
      role_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, 2, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "2222222225",
             "email" => "user@email.com"
           }
         }}
      end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "FAMILY_DOCTOR")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)
      template()

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })

      resp = json_response(conn, 200)

      assert Kernel.trunc(Date.diff(Date.from_iso8601!(resp["data"]["end_date"]), Date.utc_today()) / 365) ==
               Core.GlobalParameters.get_values()["declaration_term"]
               |> String.to_integer()

      assert %{
               "data" => %{
                 "seed" => "some_current_hash",
                 "employee" => %{
                   "speciality" => "FAMILY_DOCTOR"
                 }
               }
             } = resp

      for key <- Map.keys(resp["data"]["person"]) do
        refute key in @person_non_create_params
      end

      declaration_request = Repo.get(DeclarationRequest, get_in(resp, ~w(data id)))
      assert declaration_request.mpi_id == person_id
    end

    test "success create declaration request online for adult person for THERAPIST", %{conn: conn} do
      cabinet()
      person_id = UUID.generate()
      role_id = UUID.generate()
      gen_sequence_number()

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 30)
        |> to_string()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok,
         build(:person,
           id: person_id,
           birth_date: birth_date,
           unzr: unzr(birth_date),
           documents: get_person_documents(),
           tax_id: "2222222225",
           no_tax_id: false,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact()
         )}
      end)

      expect(MithrilMock, :get_user_by_id, 2, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "2222222225",
             "email" => "user@email.com"
           }
         }}
      end)

      expect(MithrilMock, :get_roles_by_name, fn "DOCTOR", _headers ->
        {:ok, %{"data" => [%{"id" => role_id}]}}
      end)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => UUID.generate()
             }
           ]
         }}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "THERAPIST")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)
      template()

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })

      resp = json_response(conn, 200)

      assert Kernel.trunc(Date.diff(Date.from_iso8601!(resp["data"]["end_date"]), Date.utc_today()) / 365) ==
               Core.GlobalParameters.get_values()["declaration_term"]
               |> String.to_integer()

      assert %{
               "data" => %{
                 "seed" => "some_current_hash",
                 "employee" => %{
                   "speciality" => "THERAPIST"
                 }
               }
             } = resp

      for key <- Map.keys(resp["data"]["person"]) do
        refute key in @person_non_create_params
      end

      declaration_request = Repo.get(DeclarationRequest, get_in(resp, ~w(data id)))
      assert declaration_request.mpi_id == person_id
    end

    test "declaration request without required confidant person for child", %{conn: conn} do
      cabinet()

      age = 13
      birth_date = Timex.shift(Timex.today(), years: -age) |> to_string()
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "2222222225",
             "no_tax_id" => false,
             "email" => "user@email.com",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok,
         build(:person,
           id: person_id,
           birth_date: birth_date,
           unzr: unzr(birth_date),
           documents: get_person_documents(),
           tax_id: "2222222225",
           no_tax_id: false,
           authentication_methods: [%{"type" => "OTP", "phone_number" => "+380508887700"}],
           addresses: get_person_addresses(),
           emergency_contact: get_person_emergency_contact()
         )}
      end)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id
        )

      request_params = %{
        person_id: person_id,
        employee_id: employee.id,
        division_id: employee.division.id
      }

      resp =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declaration_requests_path(conn, :create), request_params)
        |> json_response(422)

      assert [error] = resp["error"]["invalid"]
      assert "Confidant person is mandatory for children" == error["rules"] |> List.first() |> Map.get("description")
    end
  end

  @user_id "4d593e84-34dc-48d3-9e33-0628a8446956"
  @person_id "0c65d15b-32b4-4e82-b53d-0572416d890e"

  describe "declaration requests list via cabinet" do
    test "declaration requests list is successfully showed", %{conn: conn} do
      cabinet()
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => person_id,
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok, build(:person, id: person_id, tax_id: "12341234")}
      end)

      declaration_request_in =
        insert(:il, :declaration_request, prepare_params(%{mpi_id: person_id, data: fixture_params()}))

      declaration_request_out = insert(:il, :declaration_request, prepare_params(%{data: fixture_params()}))

      resp =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index))
        |> json_response(200)

      declaration_request_ids = Enum.map(resp["data"], & &1["id"])
      assert declaration_request_in.id in declaration_request_ids
      refute declaration_request_out.id in declaration_request_ids

      schema =
        "../core/specs/json_schemas/cabinet/declaration_requests_list.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "declaration requests list with search params", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id, tax_id: "12341234")}
      end)

      search_status = DeclarationRequest.status(:approved)
      search_start_year = "2018"

      declaration_request_in =
        insert(
          :il,
          :declaration_request,
          prepare_params(%{
            mpi_id: @person_id,
            status: search_status,
            data: fixture_params(%{"start_date" => "2018-03-02"})
          })
        )

      declaration_request_out =
        insert(:il, :declaration_request, prepare_params(%{mpi_id: @person_id, data: fixture_params()}))

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index), %{status: search_status, start_year: search_start_year})

      resp = json_response(conn, 200)

      declaration_request_ids = Enum.map(resp["data"], fn item -> Map.get(item, "id") end)
      assert declaration_request_in.id in declaration_request_ids
      refute declaration_request_out.id in declaration_request_ids

      schema =
        "../core/specs/json_schemas/cabinet/declaration_requests_list.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "declaration requests list ignore invalid search params", %{conn: conn} do
      cabinet()
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => person_id,
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok, build(:person, id: person_id, tax_id: "12341234")}
      end)

      for _ <- 1..2,
          do: insert(:il, :declaration_request, prepare_params(%{mpi_id: person_id, data: fixture_params()}))

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index), %{test: UUID.generate()})

      resp = json_response(conn, 200)
      assert length(resp["data"]) == 2

      schema =
        "../core/specs/json_schemas/cabinet/declaration_requests_list.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "failed when person is not valid", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id, tax_id: "11111111")}
      end)

      resp =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index))
        |> json_response(401)

      assert %{"type" => "access_denied", "message" => "Person not found"} == resp["error"]
    end

    test "failed when user is blocked", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => true
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id, tax_id: "12341234")}
      end)

      resp =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index))
        |> json_response(401)

      assert %{"type" => "access_denied"} == resp["error"]
    end

    test "declaration requests list - expired status is not shown", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id, tax_id: "12341234")}
      end)

      declaration_request_in =
        insert(:il, :declaration_request, prepare_params(%{mpi_id: @person_id, data: fixture_params()}))

      declaration_request_out =
        insert(
          :il,
          :declaration_request,
          prepare_params(%{
            mpi_id: @person_id,
            status: DeclarationRequest.status(:expired),
            data: fixture_params()
          })
        )

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index))

      resp = json_response(conn, 200)

      declaration_request_ids = Enum.map(resp["data"], fn item -> Map.get(item, "id") end)
      assert declaration_request_in.id in declaration_request_ids
      refute declaration_request_out.id in declaration_request_ids

      schema =
        "../core/specs/json_schemas/cabinet/declaration_requests_list.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "declaration requests list with status search param - expired status means empty list", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id, tax_id: "12341234")}
      end)

      search_status = DeclarationRequest.status(:expired)
      search_start_year = "2018"

      insert(
        :il,
        :declaration_request,
        prepare_params(%{
          mpi_id: @person_id,
          status: search_status,
          data: fixture_params(%{"start_date" => "2018-03-02"})
        })
      )

      insert(:il, :declaration_request, prepare_params(%{mpi_id: @person_id, data: fixture_params()}))

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :index), %{status: search_status, start_year: search_start_year})

      resp = json_response(conn, 200)
      assert resp["data"] == []
    end
  end

  describe "declaration request details via cabinet" do
    test "declaration request details is successfully showed", %{conn: conn} do
      cabinet()
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => person_id,
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok, build(:person, id: person_id, tax_id: "12341234")}
      end)

      expect(OPSMock, :get_latest_block, fn _params ->
        {:ok, %{"data" => %{"hash" => "some_current_hash"}}}
      end)

      speciality = %{
        "speciality" => "PEDIATRICIAN",
        "speciality_officio" => true,
        "level" => "Перша категорія",
        "qualification_type" => "Підтвердження",
        "attestation_name" => "random string",
        "attestation_date" => ~D[1987-04-17],
        "valid_to_date" => ~D[1987-04-17],
        "certificate_number" => "random string"
      }

      %{id: employee_id} = insert(:prm, :employee, id: UUID.generate(), speciality: speciality)
      data = put_in(fixture_params(), ["employee", "id"], employee_id)
      %{id: declaration_request_id} = insert(:il, :declaration_request, mpi_id: person_id, data: data)

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, declaration_request_id))

      assert %{
               "data" => %{
                 "seed" => "some_current_hash",
                 "employee" => %{
                   "speciality" => "PEDIATRICIAN"
                 }
               }
             } = json_response(conn, 200)
    end

    test "declaration request is not found", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id, tax_id: "12341234")}
      end)

      conn =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, UUID.generate()))

      resp = json_response(conn, 404)
      assert %{"error" => %{"type" => "not_found"}} = resp
    end

    test "failed when declaration request is not belong to person", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id, tax_id: "12341234")}
      end)

      %{id: declaration_request_id} = insert(:il, :declaration_request, data: fixture_params())

      resp =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, declaration_request_id))
        |> json_response(403)

      assert %{"error" => %{"type" => "forbidden"}} = resp
    end

    test "failed when person is not valid", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id, tax_id: "11111111")}
      end)

      resp =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, UUID.generate()))
        |> json_response(401)

      assert %{"type" => "access_denied", "message" => "Person not found"} == resp["error"]
    end

    test "failed when user is blocked", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn user_id, _headers ->
        {:ok,
         %{
           "data" => %{
             "id" => user_id,
             "person_id" => "0c65d15b-32b4-4e82-b53d-0572416d890e",
             "tax_id" => "12341234",
             "is_blocked" => true
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id, tax_id: "12341234")}
      end)

      resp =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> get(cabinet_declaration_requests_path(conn, :show, UUID.generate()))
        |> json_response(401)

      assert %{"type" => "access_denied"} == resp["error"]
    end
  end

  describe "approve declaration_request" do
    test "success approve", %{conn: conn} do
      cabinet()
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => "12341234"
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok, build(:person, id: person_id, tax_id: "12341234")}
      end)

      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 1}}}
      end)

      declaration_request =
        insert(
          :il,
          :declaration_request,
          channel: DeclarationRequest.channel(:cabinet),
          mpi_id: person_id
        )

      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :employee, id: "d290f1ee-6c54-4b01-90e6-d701748f0851", legal_entity_id: legal_entity.id)

      resp =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> patch(cabinet_declaration_requests_path(conn, :approve, declaration_request.id))
        |> json_response(200)

      assert DeclarationRequest.status(:approved) == resp["data"]["status"]
    end

    test "wrong channel", %{conn: conn} do
      cabinet()

      declaration_request =
        insert(
          :il,
          :declaration_request,
          channel: DeclarationRequest.channel(:mis)
        )

      resp =
        conn
        |> put_consumer_id_header(@user_id)
        |> put_client_id_header(@user_id)
        |> patch(cabinet_declaration_requests_path(conn, :approve, declaration_request.id))
        |> json_response(403)

      assert "Declaration request should be approved by Doctor" == resp["error"]["message"]
    end
  end

  defp fixture_params(params \\ %{}) do
    %{
      "scope" => "family_doctor",
      "person" => %{
        "id" => UUID.generate(),
        "email" => nil,
        "gender" => "MALE",
        "secret" => "тЕСТдоК",
        "tax_id" => "3173108921",
        "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
        "addresses" => [
          %{
            "zip" => "21236",
            "area" => "АВТОНОМНА РЕСПУБЛІКА КРИМ",
            "type" => "RESIDENCE",
            "street" => "Тест",
            "country" => "UA",
            "building" => "1",
            "apartment" => "2",
            "settlement" => "ВОЛОШИНЕ",
            "street_type" => "STREET",
            "settlement_id" => UUID.generate(),
            "settlement_type" => "VILLAGE"
          },
          %{
            "zip" => "21236",
            "area" => "АВТОНОМНА РЕСПУБЛІКА КРИМ",
            "type" => "REGISTRATION",
            "street" => "Тест",
            "country" => "UA",
            "building" => "1",
            "apartment" => "2",
            "settlement" => "ВОЛОШИНЕ",
            "street_type" => "STREET",
            "settlement_id" => UUID.generate(),
            "settlement_type" => "VILLAGE"
          }
        ],
        "documents" => [
          %{
            "issued_at" => "2014-02-12",
            "issued_by" => "Збухівський РО ГО МЖД",
            "number" => "120518",
            "type" => "PASSPORT",
            "expiration_date" => "2024-02-12"
          },
          %{"number" => "1234567", "type" => "BIRTH_CERTIFICATE", "issued_at" => "2010-01-01"}
        ],
        "last_name" => "Петров",
        "birth_date" => "1991-08-20",
        "first_name" => "Іван",
        "second_name" => "Миколайович",
        "birth_country" => "Україна",
        "patient_signed" => false,
        "birth_settlement" => "Киев",
        "confidant_person" => [
          %{
            "gender" => "MALE",
            "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
            "secret" => "secret",
            "tax_id" => "3378115538",
            "last_name" => "Іванов",
            "birth_date" => "1991-08-19",
            "first_name" => "Петро",
            "second_name" => "Миколайович",
            "birth_country" => "Україна",
            "relation_type" => "PRIMARY",
            "birth_settlement" => "Вінниця",
            "documents_person" => [%{"type" => "PASSPORT", "number" => "120518"}],
            "documents_relationship" => [
              %{"type" => "COURT_DECISION", "number" => "120518"}
            ]
          },
          %{
            "gender" => "MALE",
            "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
            "secret" => "secret",
            "tax_id" => "3378115538",
            "last_name" => "Іванов",
            "birth_date" => "1991-08-19",
            "first_name" => "Петро",
            "second_name" => "Миколайович",
            "birth_country" => "Україна",
            "relation_type" => "SECONDARY",
            "birth_settlement" => "Вінниця",
            "documents_person" => [%{"type" => "PASSPORT", "number" => "120518"}],
            "documents_relationship" => [
              %{"type" => "COURT_DECISION", "number" => "120518"}
            ]
          }
        ],
        "emergency_contact" => %{
          "phones" => [%{"type" => "MOBILE", "number" => "+380686521488"}],
          "last_name" => "ТестДит",
          "first_name" => "ТестДит",
          "second_name" => "ТестДит"
        },
        "authentication_methods" => [%{"type" => "OFFLINE"}],
        "process_disclosure_data_consent" => true
      },
      "channel" => "MIS",
      "division" => %{
        "id" => UUID.generate(),
        "name" => "Бориспільське відділення Клініки Борис",
        "type" => "CLINIC",
        "status" => "ACTIVE",
        "email" => "example@gmail.com",
        "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
        "addresses" => [
          %{
            "zip" => "43000",
            "area" => "М.КИЇВ",
            "type" => "RESIDENCE",
            "street" => "Шевченка",
            "country" => "UA",
            "building" => "2",
            "apartment" => "23",
            "settlement" => "КИЇВ",
            "street_type" => "STREET",
            "settlement_id" => UUID.generate(),
            "settlement_type" => "CITY"
          }
        ],
        "external_id" => "3213213",
        "legal_entity_id" => UUID.generate()
      },
      "employee" => %{
        "id" => UUID.generate(),
        "party" => %{
          "id" => UUID.generate(),
          "email" => "example309@gmail.com",
          "phones" => [%{"type" => "MOBILE", "number" => "+380503410870"}],
          "tax_id" => "3033413670",
          "last_name" => "Іванов",
          "first_name" => "Петро",
          "second_name" => "Миколайович"
        },
        "position" => "P2",
        "status" => "APPROVED",
        "start_date" => "2017-03-02T10:45:16.000Z",
        "legal_entity_id" => UUID.generate()
      },
      "end_date" => "2068-06-12",
      "start_date" => "2018-06-12",
      "legal_entity" => %{
        "id" => UUID.generate(),
        "name" => "Клініка Лимич Медікал",
        "email" => "lymychcl@gmail.com",
        "edrpou" => "3160405192",
        "phones" => [%{"type" => "MOBILE", "number" => "+380979134223"}],
        "licenses" => [
          %{
            "order_no" => "К-123",
            "issued_by" => "Кваліфікацйна комісія",
            "expiry_date" => "1991-08-19",
            "issued_date" => "1991-08-19",
            "what_licensed" => "реалізація наркотичних засобів",
            "license_number" => "fd123443",
            "active_from_date" => "1991-08-19"
          }
        ],
        "addresses" => [
          %{
            "zip" => "02090",
            "area" => "ХАРКІВСЬКА",
            "type" => "REGISTRATION",
            "street" => "вул. Ніжинська",
            "country" => "UA",
            "building" => "15",
            "apartment" => "23",
            "settlement" => "ЧУГУЇВ",
            "street_type" => "STREET",
            "settlement_id" => UUID.generate(),
            "settlement_type" => "CITY"
          }
        ],
        "legal_form" => "140",
        "short_name" => "Лимич Медікал",
        "public_name" => "Лимич Медікал",
        "status" => "ACTIVE",
        "accreditation" => %{
          "category" => "FIRST",
          "order_no" => "fd123443",
          "order_date" => "1991-08-19",
          "expiry_date" => "1991-08-19",
          "issued_date" => "1991-08-19"
        }
      }
    }
    |> Map.merge(params)
  end

  defp get_person_emergency_contact do
    fixture_params() |> get_in(["person", "emergency_contact"])
  end

  defp get_person_documents do
    fixture_params() |> get_in(["person", "documents"])
  end

  defp get_person_confidant_person do
    fixture_params() |> get_in(["person", "confidant_person"])
  end

  defp get_person_addresses do
    [
      build(:address, %{"type" => "REGISTRATION"}),
      build(:address, %{"type" => "RESIDENCE"})
    ]
  end

  defp insert_dictionaries do
    insert(:il, :dictionary_phone_type)
    insert(:il, :dictionary_document_type)
    insert(:il, :dictionary_authentication_method)
    insert(:il, :dictionary_document_relationship_type)
  end

  defp unzr(birthdate) do
    "#{String.replace(birthdate, "-", "")}-#{Enum.random(10000..99999)}"
  end

  defp prepare_params(params) when is_map(params) do
    data = Map.get(params, :data)

    start_date_year =
      data
      |> Map.get("start_date")
      |> case do
        start_date when is_binary(start_date) ->
          start_date
          |> Date.from_iso8601!()
          |> Map.get(:year)

        _ ->
          nil
      end

    person_birth_date =
      data
      |> get_in(~w(person birth_date))
      |> case do
        birth_date when is_binary(birth_date) -> Date.from_iso8601!(birth_date)
        _ -> nil
      end

    Map.merge(params, %{
      data_legal_entity_id: get_in(data, ~w(legal_entity id)),
      data_employee_id: get_in(data, ~w(employee id)),
      data_start_date_year: start_date_year,
      data_person_tax_id: get_in(data, ~w(person tax_id)),
      data_person_first_name: get_in(data, ~w(person first_name)),
      data_person_last_name: get_in(data, ~w(person last_name)),
      data_person_birth_date: person_birth_date
    })
  end
end

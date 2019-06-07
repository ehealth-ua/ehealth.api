defmodule EHealth.Rpc do
  @moduledoc """
  This module contains functions that are called from other pods via RPC.
  """

  alias Core.Dictionaries
  alias Core.Divisions
  alias Core.Divisions.Division
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.Parties
  alias Core.Parties.Party
  alias Core.Services.Service
  alias Core.Services.ServiceGroup
  alias Core.Services.ServiceInclusion
  alias EHealth.Web.DictionaryView
  alias EHealth.Web.DivisionView
  alias EHealth.Web.EmployeeView
  alias EHealth.Web.LegalEntityView
  alias EHealth.Web.ServiceView
  import Ecto.Query

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @type service() :: %{
          category: binary(),
          code: binary(),
          id: binary(),
          inserted_at: DateTime,
          inserted_by: binary(),
          is_active: boolean(),
          is_composition: boolean(),
          name: binary(),
          parent_id: binary(),
          request_allowed: boolean(),
          updated_at: DateTime,
          updated_by: binary()
        }

  @type service_group() :: %{
          code: binary(),
          id: binary(),
          inserted_at: DateTime,
          inserted_by: binary(),
          is_active: boolean(),
          name: binary(),
          request_allowed: boolean(),
          updated_at: DateTime,
          updated_by: binary()
        }

  @type dictionary() :: %{
          is_active: boolean(),
          labels: list(binary()),
          name: binary(),
          values: map()
        }

  @type document() :: %{
          issued_at: Date,
          issued_by: binary(),
          number: binary(),
          type: binary()
        }

  @type phone() :: %{
          number: binary(),
          type: binary()
        }

  @type party() :: %{
          about_myself: binary(),
          birth_date: Date,
          declaration_count: integer(),
          declaration_limit: integer(),
          documents: list(document()),
          first_name: binary(),
          gender: binary(),
          id: binary(),
          last_name: binary(),
          no_tax_id: boolean(),
          phones: list(phone()),
          second_name: binary(),
          tax_id: binary(),
          working_experience: integer()
        }

  @type employee() :: %{
          doctor: map(),
          employee_type: binary(),
          end_date: Date,
          id: binary(),
          party: party(),
          position: binary(),
          start_date: Date,
          status: binary()
        }

  @type user() :: %{
          user_id: binary()
        }

  @type party_short() :: %{
          id: binary(),
          tax_id: binary(),
          users: list(user())
        }

  @type employee_users_short() :: %{
          id: binary(),
          party: party_short(),
          legal_entity_id: binary()
        }

  @type legal_entity() :: %{
          addresses: list(map()),
          archive: list(map()),
          beneficiary: binary(),
          edr_verified: boolean(),
          edrpou: binary(),
          email: binary(),
          id: binary(),
          inserted_at: DateTime,
          inserted_by: binary(),
          is_active: boolean(),
          kveds: list(map()),
          legal_form: binary(),
          medical_service_provider: map(),
          name: binary(),
          nhs_comment: binary(),
          nhs_reviewed: boolean(),
          nhs_verified: boolean(),
          owner_property_type: binary(),
          phones: list(map()),
          public_name: binary(),
          receiver_funds_code: binary(),
          short_name: binary(),
          status: binary(),
          type: binary(),
          updated_at: DateTime,
          updated_by: binary(),
          website: binary()
        }

  @type division() :: %{
          addresses: list(map()),
          dls_id: binary(),
          dls_verified: boolean(),
          email: binary(),
          external_id: binary(),
          id: binary(),
          legal_entity_id: binary(),
          location: map(),
          mountain_group: boolean(),
          name: binary(),
          phones: list(map()),
          status: binary(),
          type: binary(),
          working_hours: map()
        }

  @doc """
  Get service by service_id

  ## Examples

      iex> EHealth.Rpc.service_by_id("cdfade57-5d1c-4bac-8155-a26e88795d9f")
      {:ok,
        %{
          category: "service_category",
          code: "service_code",
          id: "cdfade57-5d1c-4bac-8155-a26e88795d9f",
          inserted_at: #DateTime<2019-04-15 18:32:34.982672Z>,
          inserted_by: "da333fb4-f397-46b1-90e3-3bc1d3b3d658",
          is_active: true,
          is_composition: false,
          name: "service_name",
          parent_id: "99630d0e-880c-4f70-a62b-cf65895ee196",
          request_allowed: true,
          updated_at: #DateTime<2019-04-15 18:32:34.982672Z>,
          updated_by: "da333fb4-f397-46b1-90e3-3bc1d3b3d658"
        }
      }
  """

  @spec service_by_id(service_id :: binary()) :: nil | {:ok, service()}
  def service_by_id(service_id) do
    with %Service{} = service <- @read_prm_repo.get(Service, service_id) do
      {:ok, ServiceView.render("service.json", %{service: service})}
    end
  end

  @doc """
  Get service group by service_group_id

  ## Examples

      iex> EHealth.Rpc.service_group_by_id("71a01a1b-c60a-41c0-8ee6-73fc10abf1ea")
      {:ok,
        %{
          code: "service_group_code",
          id: "71a01a1b-c60a-41c0-8ee6-73fc10abf1ea",
          inserted_at: #DateTime<2019-04-16 12:01:24.978769Z>,
          inserted_by: "da333fb4-f397-46b1-90e3-3bc1d3b3d658",
          is_active: true,
          name: "service_group_name",
          request_allowed: true,
          updated_at: #DateTime<2019-04-16 12:01:24.978769Z>,
          updated_by: "da333fb4-f397-46b1-90e3-3bc1d3b3d658"
        }
      }
  """

  @spec service_group_by_id(service_group_id :: binary()) :: nil | {:ok, service_group()}
  def service_group_by_id(service_group_id) do
    with %ServiceGroup{} = service_group <- @read_prm_repo.get(ServiceGroup, service_group_id) do
      {:ok, ServiceView.render("group.json", %{group: %{node: service_group}})}
    end
  end

  @doc """
  Check if service belongs to group

  ## Examples

      iex> EHealth.Rpc.service_belongs_to_group?("cdfade57-5d1c-4bac-8155-a26e88795d9f", "71a01a1b-c60a-41c0-8ee6-73fc10abf1ea")
      true
  """

  @spec service_belongs_to_group?(service_id :: binary(), service_group_id :: binary()) :: boolean()
  def service_belongs_to_group?(service_id, service_group_id) do
    ServiceInclusion
    |> where([sg], sg.service_id == ^service_id and sg.service_group_id == ^service_group_id)
    |> @read_prm_repo.one()
    |> Kernel.is_nil()
    |> Kernel.not()
  end

  @doc """
  Get employee ids by user id

  ## Examples

      iex> EHealth.Rpc.employees_by_user_id_client_id(
        "26e673e1-1d68-413e-b96c-407b45d9f572",
        "d221d7f1-81cb-44d3-b6d4-8d7e42f97ff9"
      )
      {:ok, ["1241d1f9-ae81-4fe5-b614-f4f780a5acf0"]}
  """
  @spec employees_by_user_id_client_id(user_id :: binary(), client_id :: binary()) :: nil | {:ok, list()}
  def employees_by_user_id_client_id(user_id, client_id) do
    with %Party{id: party_id} <- Parties.get_by_user_id(user_id) do
      {:ok, employees_by_party_id_client_id(party_id, client_id)}
    else
      _ -> nil
    end
  end

  def employees_by_party_id_client_id(party_id, client_id) do
    Employee
    |> select([e], e.id)
    |> where([e], e.party_id == ^party_id)
    |> where([e], e.legal_entity_id == ^client_id)
    |> where([e], e.status == ^Employee.status(:approved))
    |> @read_prm_repo.all()
  end

  def tax_id_by_employee_id(employee_id) do
    Party
    |> select([p], p.tax_id)
    |> join(:left, [p], e in Employee, on: p.id == e.party_id)
    |> where([p, e], e.id == ^employee_id)
    |> @read_prm_repo.one()
  end

  @doc """
  Get employee by id

  ## Examples

      iex> EHealth.Rpc.employee_by_id("b8edf2c1-adaf-44e1-89db-a3e68f8f72fb")
      {:ok,
      %{
        doctor: %{
          "educations" => [
            %{
              "city" => "Kyiv",
              "country" => "UA",
              "degree" => "Бакалавр",
              "diploma_number" => "random string",
              "institution_name" => "random string",
              "issued_date" => "1987-04-17",
              "speciality" => "random string"
            }
          ],
          "qualifications" => [
            %{
              "certificate_number" => "random string",
              "institution_name" => "random string",
              "issued_date" => "1987-04-17",
              "speciality" => "PEDIATRICIAN",
              "type" => "Інтернатура"
            }
          ],
          "science_degree" => %{
            "city" => "Kyiv",
            "country" => "UA",
            "degree" => "Доктор філософії",
            "diploma_number" => "random string",
            "institution_name" => "random string",
            "issued_date" => "1987-04-17",
            "speciality" => "random string"
          },
          "specialities" => [
            %{
              "attestation_date" => "1987-04-17",
              "attestation_name" => "random string",
              "certificate_number" => "random string",
              "level" => "Перша категорія",
              "qualification_type" => "Підтвердження",
              "speciality" => "PEDIATRICIAN",
              "speciality_officio" => true,
              "valid_to_date" => "1987-04-17"
            }
          ]
        },
        employee_type: "DOCTOR",
        end_date: ~D[2012-04-17],
        id: "b8edf2c1-adaf-44e1-89db-a3e68f8f72fb",
        legal_entity_id: "91fa575b-1cf3-4645-a7fc-22513b8cde7f",
        party: %{
          about_myself: nil,
          birth_date: ~D[1991-08-19],
          declaration_count: 0,
          declaration_limit: 0,
          documents: [
            %{
              issued_at: ~D[2017-06-11],
              issued_by: "Прикордонна служба",
              number: "AA000000",
              type: "NATIONAL_ID"
            }
          ],
          first_name: "Петро",
          gender: "MALE",
          id: "3cb7264c-90e5-47a1-af44-49eea04ada98",
          last_name: "В'язовська",
          no_tax_id: false,
          phones: [
            %Core.Parties.Phone{
              __meta__: #Ecto.Schema.Metadata<:loaded, "phones">,
              number: "+380972526080",
              type: "MOBILE"
            }
          ],
          second_name: "Миколайович",
          tax_id: "100000000",
          working_experience: nil
        },
        position: "P1",
        start_date: ~D[2017-08-07],
        status: "APPROVED"
      }}
  """
  @spec employee_by_id(id :: binary()) :: nil | {:ok, employee()}
  def employee_by_id(id) do
    employee =
      Employee
      |> where([e], e.id == ^id)
      |> preload([e], :party)
      |> @read_prm_repo.one()

    case employee do
      %Employee{} ->
        {:ok,
         "employee.json"
         |> EmployeeView.render(%{employee: employee})
         |> Map.put(:legal_entity_id, employee.legal_entity_id)}

      _ ->
        nil
    end
  end

  @doc """
  Get employee short with users by id

  ## Examples

      iex> EHealth.Rpc.employee_by_id_users_short("e62760ef-455c-4547-8d01-7fcbbd48e02c")
      {:ok,
      %{
        id: "e62760ef-455c-4547-8d01-7fcbbd48e02c",
        legal_entity_id: "0f4b5978-ba01-4704-9649-96f340e8d099",
        party: %{
          id: "fe5b8d40-ff95-44bb-92e4-97f250e97615",
          tax_id: "100000000",
          users: [%{user_id: "549a9ae6-73ed-4ba2-b2e9-4dfd873d9c44"}]
        }
      }}
  """
  @spec employee_by_id_users_short(id :: binary()) :: nil | {:ok, employee_users_short()}
  def employee_by_id_users_short(id) do
    with {:ok, employee} <- Employees.get_by_id_with_users(id) do
      {:ok, EmployeeView.render("employee_users_short.json", %{employee: employee})}
    end
  end

  @doc """
  Get legal entity by id

  ## Examples

      iex> EHealth.Rpc.legal_entity_by_id("4d156509-3583-4737-b667-aa8fc814789d")
      {:ok,
      %{
        addresses: [
          %{
            "apartment" => "23",
            "area" => "Житомирська",
            "building" => "15-В",
            "country" => "UA",
            "region" => "Бердичівський",
            "settlement" => "Київ",
            "settlement_id" => "d54ce701-5762-4dda-885d-7b24ae97b3ed",
            "settlement_type" => "CITY",
            "street" => "вул. Ніжинська",
            "street_type" => "STREET",
            "type" => "REGISTRATION",
            "zip" => "02090"
          }
        ],
        archive: [
          %{
            "date" => "2012-12-29",
            "place" => "Житомир вул. Малярів, буд. 211, корп. 2, оф. 1"
          }
        ],
        beneficiary: "Марко Вовчок",
        edr_verified: nil,
        edrpou: "3356478194",
        email: "some email",
        id: "4d156509-3583-4737-b667-aa8fc814789d",
        inserted_at: #DateTime<2019-06-06 16:04:45.911201Z>,
        inserted_by: "d584177b-5554-4de2-a728-5d8c04660ea6",
        is_active: true,
        kveds: [],
        legal_form: "240",
        medical_service_provider: %{
          accreditation: %{
            "category" => "some",
            "expiry_date" => "some",
            "issued_date" => "some",
            "order_date" => "some",
            "order_no" => "some"
          },
          licenses: [
            %{
              active_from_date: ~D[2019-06-06],
              expiry_date: ~D[2020-06-05],
              id: "9f9e8882-8a32-4020-8062-62a415db1cbc",
              inserted_at: #DateTime<2019-06-06 16:04:45Z>,
              inserted_by: "282c657c-a752-4f6d-bdcb-5a3b829f2b10",
              is_active: true,
              issued_by: "foo",
              issued_date: ~D[2019-06-06],
              issuer_status: "valid",
              license_number: "1234567",
              order_no: nil,
              type: "MSP",
              updated_at: #DateTime<2019-06-06 16:04:45Z>,
              updated_by: "282c657c-a752-4f6d-bdcb-5a3b829f2b10",
              what_licensed: nil
            }
          ]
        },
        name: "Клініка Борис",
        nhs_comment: "",
        nhs_reviewed: true,
        nhs_verified: true,
        owner_property_type: "STATE",
        phones: [],
        public_name: "some public_name",
        receiver_funds_code: "088912",
        short_name: "some short_name",
        status: "ACTIVE",
        type: "MSP",
        updated_at: #DateTime<2019-06-06 16:04:45.911201Z>,
        updated_by: "be4e3169-e7d8-4b3e-8d61-d85739c6046a",
        website: "http://example.com"
      }}
  """
  @spec legal_entity_by_id(id :: binary()) :: nil | {:ok, legal_entity()}
  def legal_entity_by_id(id) do
    with %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(id) do
      {:ok, LegalEntityView.render("show.json", %{legal_entity: legal_entity})}
    end
  end

  @doc """
  Get division by id

  ## Examples

      iex> EHealth.Rpc.division_by_id("bdf63ecd-8b9d-4a3c-9dc7-0ba841b9724a")
      {:ok,
      %{
        addresses: [
          %{
            apartment: "23",
            area: "ЛЬВІВСЬКА",
            building: "15",
            country: "UA",
            region: "ПУСТОМИТІВСЬКИЙ",
            settlement: "СОРОКИ-ЛЬВІВСЬКІ",
            settlement_id: "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
            settlement_type: "CITY",
            street: "вул. Ніжинська",
            street_type: "STREET",
            type: "REGISTRATION",
            zip: "02090"
          },
          %{
            apartment: "23",
            area: "ЛЬВІВСЬКА",
            building: "15",
            country: "UA",
            region: "ПУСТОМИТІВСЬКИЙ",
            settlement: "СОРОКИ-ЛЬВІВСЬКІ",
            settlement_id: "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
            settlement_type: "CITY",
            street: "вул. Ніжинська",
            street_type: "STREET",
            type: "RESIDENCE",
            zip: "02090"
          }
        ],
        dls_id: nil,
        dls_verified: true,
        email: "some@local.com",
        external_id: "7ae4bbd6-a9e7-4ce0-992b-6a1b18a262dc",
        id: "bdf63ecd-8b9d-4a3c-9dc7-0ba841b9724a",
        legal_entity_id: "c309e62b-29c5-4624-b033-f3de713aa74f",
        location: %{latitude: 20.0, longitude: 50.0},
        mountain_group: false,
        name: "some",
        phones: [],
        status: "ACTIVE",
        type: "CLINIC",
        working_hours: %{"fri" => [["08.00", "12.00"], ["14.00", "16.00"]]}
      }}
  """
  @spec division_by_id(id :: binary()) :: nil | {:ok, division()}
  def division_by_id(id) do
    with %Division{} = division <- Divisions.get_by_id(id) do
      {:ok, DivisionView.render("show.json", %{division: division})}
    end
  end

  @doc """
  Get dictionaries

  ## Examples

      iex> EHealth.Rpc.get_dictionaries(%{})
      {:ok,
        [
          %{
            is_active: true,
            labels: ["SYSTEM"],
            name: "KVEDS_ALLOWED_PHARMACY",
            values: %{
              "47.73" => "Роздрібна торгівля фармацевтичними товарами в спеціалізованих магазинах"
            }
          }
        ]
      }
  """
  @spec get_dictionaries(params :: map()) :: {:ok, list(dictionary())}
  def get_dictionaries(params \\ %{}) do
    with {:ok, dictionaries} <- Dictionaries.list_dictionaries(params) do
      {:ok, DictionaryView.render("index.json", %{dictionaries: dictionaries})}
    end
  end
end

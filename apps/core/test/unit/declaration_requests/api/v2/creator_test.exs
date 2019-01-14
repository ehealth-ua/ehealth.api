defmodule Core.DeclarationRequests.API.V2.CreatorTest do
  @moduledoc false

  use Core.ConnCase, async: true

  alias Ecto.UUID
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.DeclarationRequests.API.V2.Creator
  alias Core.Repo
  alias Core.Utils.NumberGenerator

  describe "pending_declaration_requests/2" do
    test "returns pending requests" do
      employee_id = UUID.generate()
      legal_entity_id = UUID.generate()

      existing_declaration_request_data = %{
        "person" => %{
          "tax_id" => "111"
        },
        "employee" => %{
          "id" => employee_id
        },
        "legal_entity" => %{
          "id" => legal_entity_id
        }
      }

      pending_declaration_req_1 = copy_declaration_request(existing_declaration_request_data, "NEW")
      pending_declaration_req_2 = copy_declaration_request(existing_declaration_request_data, "APPROVED")

      query = Creator.pending_declaration_requests(%{"tax_id" => "111"}, employee_id, legal_entity_id)
      requests = Repo.all(query)
      assert pending_declaration_req_1 in requests
      assert pending_declaration_req_2 in requests
    end

    test "returns pending requests without tax_id" do
      employee_id = UUID.generate()
      legal_entity_id = UUID.generate()

      existing_declaration_request_data = %{
        "person" => %{
          "first_name" => "Василь",
          "last_name" => "Шамрило",
          "birth_date" => "2000-12-14"
        },
        "employee" => %{
          "id" => employee_id
        },
        "legal_entity" => %{
          "id" => legal_entity_id
        }
      }

      pending_declaration_req_1 = copy_declaration_request(existing_declaration_request_data, "NEW")
      pending_declaration_req_2 = copy_declaration_request(existing_declaration_request_data, "APPROVED")

      query =
        Creator.pending_declaration_requests(existing_declaration_request_data["person"], employee_id, legal_entity_id)

      declarations = Repo.all(query)
      assert pending_declaration_req_1 in declarations
      assert pending_declaration_req_2 in declarations
    end
  end

  describe "mpi child search" do
    test "tax_id - found" do
      expect_persons_search_result([%{id: 1}, %{id: 2}])

      assert {:ok, %{id: 1}} =
               Creator.mpi_search(%{
                 "birth_date" => "2016-08-28",
                 "tax_id" => "0123456789",
                 "last_name" => "Рюрікович",
                 "documents" => [
                   %{
                     "type" => "BIRTH_CERTIFICATE",
                     "number" => "Стеблівським РОУ МВУ в Черкаській обл. НОМЕР 2511 в 5/11"
                   }
                 ]
               })
    end

    test "tax_id - not found" do
      expect_persons_search_result([])

      expect_persons_search_result([%{id: 1}, %{id: 2}])

      assert {:ok, %{id: 1}} =
               Creator.mpi_search(%{
                 "birth_date" => "2016-08-28",
                 "tax_id" => "0123456789",
                 "last_name" => "Рюрікович",
                 "documents" => [
                   %{
                     "type" => "BIRTH_CERTIFICATE",
                     "number" => "Стеблівським РОУ МВУ в Черкаській обл. НОМЕР 2511 в 5/11"
                   }
                 ]
               })
    end
  end

  describe "mpi adult search" do
    test "tax_id - found" do
      expect_persons_search_result([%{id: 1}, %{id: 2}])

      assert {:ok, %{id: 1}} =
               Creator.mpi_search(%{
                 "birth_date" => "1838-11-25",
                 "tax_id" => "0123456789",
                 "last_name" => "Рюрікович"
               })
    end

    test "no tax_id" do
      expect_persons_search_result([%{id: 1}, %{id: 2}])

      assert {:ok, %{id: 1}} =
               Creator.mpi_search(%{
                 "birth_date" => "1838-11-25",
                 "last_name" => "Рюрікович",
                 "documents" => [
                   %{
                     "type" => "BIRTH_CERTIFICATE",
                     "number" => "Стеблівським РОУ МВУ в Черкаській обл. НОМЕР 2511 в 5/11"
                   },
                   %{
                     "type" => "PASSPORT",
                     "number" => "18381125-01234"
                   }
                 ]
               })
    end
  end

  describe "mpi persons search" do
    test "few mpi persons" do
      expect_persons_search_result([%{id: 1}, %{id: 2}])

      assert {:ok, %{id: 1}} =
               Creator.mpi_search(%{
                 "unzr" => "20160828-12345",
                 "birth_date" => "2016-08-28",
                 "tax_id" => "0123456789",
                 "last_name" => "Рюрікович",
                 "documents" => [
                   %{
                     "type" => "BIRTH_CERTIFICATE",
                     "number" => "Стеблівським РОУ МВУ в Черкаській обл. НОМЕР 2511 в 5/11"
                   }
                 ]
               })
    end

    test "one mpi persons" do
      expect_persons_search_result([%{id: 1}])

      person = %{
        "unzr" => "20160303-12345",
        "birth_date" => "2016-03-03",
        "tax_id" => "0123456789",
        "last_name" => "Рюрікович",
        "documents" => [
          %{
            "type" => "BIRTH_CERTIFICATE",
            "number" => "Стеблівським РОУ МВУ в Черкаській обл. НОМЕР 2511 в 5/11"
          }
        ]
      }

      assert {:ok, %{id: 1}} = Creator.mpi_search(person)
    end

    test "no mpi persons" do
      expect_persons_search_result([], 2)

      assert {:ok, nil} =
               Creator.mpi_search(%{
                 "unzr" => "20190101-12345",
                 "birth_date" => "2019-01-01",
                 "tax_id" => "1234567890",
                 "last_name" => "Рюрікович",
                 "documents" => [
                   %{
                     "type" => "BIRTH_CERTIFICATE",
                     "number" => "Стеблівським РОУ МВУ в Черкаській обл. НОМЕР 2511 в 5/11"
                   }
                 ]
               })
    end
  end

  defp copy_declaration_request(template, status) do
    attrs =
      %{
        "status" => status,
        "data" => %{
          "person" => template["person"],
          "employee" => %{
            "id" => get_in(template, ["employee", "id"])
          },
          "legal_entity" => %{
            "id" => get_in(template, ["legal_entity", "id"])
          }
        },
        "authentication_method_current" => %{
          "number" => "+380508887700",
          "type" => "OTP"
        },
        "documents" => [],
        "printout_content" => "Some fake content",
        "inserted_by" => UUID.generate(),
        "updated_by" => UUID.generate(),
        "declaration_id" => UUID.generate(),
        "channel" => DeclarationRequest.channel(:mis),
        "declaration_number" => NumberGenerator.generate(1, 2)
      }
      |> prepare_params()
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> Enum.into(%{})

    insert(:il, :declaration_request, attrs)
  end

  defp prepare_params(params) when is_map(params) do
    data = Map.get(params, "data")

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
      "data_legal_entity_id" => get_in(data, ~w(legal_entity id)),
      "data_employee_id" => get_in(data, ~w(employee id)),
      "data_start_date_year" => start_date_year,
      "data_person_tax_id" => get_in(data, ~w(person tax_id)),
      "data_person_first_name" => get_in(data, ~w(person first_name)),
      "data_person_last_name" => get_in(data, ~w(person last_name)),
      "data_person_birth_date" => person_birth_date
    })
  end
end

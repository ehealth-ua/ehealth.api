defmodule Core.DeclarationRequests.API.V2.CreatorTest do
  @moduledoc false

  use Core.ConnCase, async: true

  import Mox

  alias Ecto.UUID
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.DeclarationRequests.API.V2.Creator
  alias Core.Repo
  alias Core.Utils.NumberGenerator

  describe "pending_declaration_requests/2" do
    test "returns pending requests" do
      existing_declaration_request_data = %{
        "person" => %{
          "tax_id" => "111"
        },
        "employee" => %{
          "id" => "222"
        },
        "legal_entity" => %{
          "id" => "333"
        }
      }

      {:ok, pending_declaration_req_1} = copy_declaration_request(existing_declaration_request_data, "NEW")
      {:ok, pending_declaration_req_2} = copy_declaration_request(existing_declaration_request_data, "APPROVED")

      query = Creator.pending_declaration_requests(%{"tax_id" => "111"}, "222", "333")
      requests = Repo.all(query)
      assert pending_declaration_req_1 in requests
      assert pending_declaration_req_2 in requests
    end

    test "returns pending requests without tax_id" do
      existing_declaration_request_data = %{
        "person" => %{
          "first_name" => "Василь",
          "last_name" => "Шамрило",
          "birth_data" => "2000-12-14"
        },
        "employee" => %{
          "id" => "222"
        },
        "legal_entity" => %{
          "id" => "333"
        }
      }

      {:ok, pending_declaration_req_1} = copy_declaration_request(existing_declaration_request_data, "NEW")
      {:ok, pending_declaration_req_2} = copy_declaration_request(existing_declaration_request_data, "APPROVED")

      query = Creator.pending_declaration_requests(%{}, "222", "333")
      declarations = Repo.all(query)
      assert pending_declaration_req_1 in declarations
      assert pending_declaration_req_2 in declarations
    end
  end

  describe "mpi persons search" do
    test "few mpi persons" do
      expect(MPIMock, :search, fn _, _ ->
        {:ok,
         %{
           "data" => [%{id: 1}, %{id: 2}]
         }}
      end)

      assert {:ok, %{id: 1}} =
               Creator.mpi_search(%{"unzr" => "20160828-12345", "birth_date" => "2016-08-28", "tax_id" => "0123456789"})
    end

    test "one mpi persons" do
      expect(MPIMock, :search, fn _, _ ->
        {:ok,
         %{
           "data" => [%{id: 1}]
         }}
      end)

      person = %{"unzr" => "20160303-12345", "birth_date" => "2016-03-03", "tax_id" => "0123456789"}

      assert {:ok, %{id: 1}} = Creator.mpi_search(person)
    end

    test "no mpi persons" do
      expect(MPIMock, :search, fn _, _ ->
        {:ok,
         %{
           "data" => []
         }}
      end)

      assert {:ok, nil} =
               Creator.mpi_search(%{"unzr" => "20190101-12345", "birth_date" => "2019-01-01", "tax_id" => "1234567890"})
    end
  end

  defp copy_declaration_request(template, status) do
    attrs = %{
      "status" => status,
      "data" => %{
        "person" => %{
          "tax_id" => get_in(template, ["person", "tax_id"])
        },
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

    allowed =
      attrs
      |> Map.keys()
      |> Enum.map(&String.to_atom(&1))

    %DeclarationRequest{}
    |> Ecto.Changeset.cast(attrs, allowed)
    |> Repo.insert()
  end
end

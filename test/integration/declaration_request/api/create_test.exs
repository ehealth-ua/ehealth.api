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
        %{"upload_link" => "http://some_resource.com/declaration-98e0a42f-20fe-472c-a614-0ea99426a3fb/Passport.jpeg"},
        %{"upload_link" => "http://some_resource.com/declaration-98e0a42f-20fe-472c-a614-0ea99426a3fb/SSN.jpeg"}
      ]

      assert get_change(changeset, :documents) == expected_documents
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
  end

  describe "determine_auth_method_for_mpi/1" do
    test "MPI record exists" do
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

    test "MPI record does not exist, e.g. Gandalf makes decision" do
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

      # TODO: why this test works? there's no config that says to go on localhost?

      assert get_change(changeset, :authentication_method_current) ==
        %{"number" => "+380508887701", "type" => "OFFLINE"}
    end
  end
end

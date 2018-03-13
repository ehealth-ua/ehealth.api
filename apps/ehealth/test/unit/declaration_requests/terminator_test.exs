defmodule EHealth.DeclarationRequests.TerminatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias EHealth.Repo
  import EHealth.DeclarationRequests.Terminator

  test "terminate outdated declaration_requests" do
    simple_fixture(:declaration_request)
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :seconds)

    declaration_request1 =
      simple_fixture(:declaration_request)
      |> Ecto.Changeset.change(inserted_at: inserted_at)
      |> Repo.update!()

    declaration_request2 =
      simple_fixture(:declaration_request)
      |> Ecto.Changeset.change(inserted_at: inserted_at)
      |> Repo.update!()

    insert(:prm, :global_parameter, parameter: "declaration_request_term_unit", value: "DAYS")
    insert(:prm, :global_parameter, parameter: "declaration_request_expiration", value: "5")

    terminate_declaration_requests()
    assert 3 = DeclarationRequest |> Repo.all() |> Enum.count()

    expired = DeclarationRequest.status(:expired)
    updated_request = Repo.get(DeclarationRequest, declaration_request1.id)
    assert %{data: nil, documents: nil, printout_content: nil, status: ^expired} = updated_request

    updated_request = Repo.get(DeclarationRequest, declaration_request2.id)
    assert %{data: nil, documents: nil, printout_content: nil, status: ^expired} = updated_request
  end
end

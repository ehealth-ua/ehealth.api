defmodule EHealth.DeclarationRequests.TerminatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Repo
  import EHealth.DeclarationRequests.Terminator

  test "terminate outdated declaration_requests" do
    insert(:il, :declaration_request)
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :seconds)

    declaration_request1 =
      insert(
        :il,
        :declaration_request,
        status: DeclarationRequest.status(:cancelled),
        inserted_at: inserted_at
      )

    declaration_request2 =
      insert(
        :il,
        :declaration_request,
        status: DeclarationRequest.status(:signed),
        inserted_at: inserted_at
      )

    insert(:prm, :global_parameter, parameter: "declaration_request_term_unit", value: "DAYS")
    insert(:prm, :global_parameter, parameter: "declaration_request_expiration", value: "5")

    terminate_declaration_requests()
    assert_receive :terminated_signed
    assert_receive :terminated_expired

    assert 3 = DeclarationRequest |> Repo.all() |> Enum.count()

    expired = DeclarationRequest.status(:expired)
    updated_request = Repo.get(DeclarationRequest, declaration_request1.id)
    assert %{data: nil, documents: nil, printout_content: nil, status: ^expired} = updated_request

    signed = DeclarationRequest.status(:signed)
    updated_request = Repo.get(DeclarationRequest, declaration_request2.id)
    assert %{data: nil, documents: nil, printout_content: nil, status: ^signed} = updated_request
  end
end

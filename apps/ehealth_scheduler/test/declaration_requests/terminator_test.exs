defmodule EHealthScheduler.DeclarationRequests.TerminatorTest do
  @moduledoc false

  use Core.ConnCase, async: false
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Repo
  alias EHealthScheduler.DeclarationRequests.Terminator

  test "clean outdated declaration_requests" do
    insert(:il, :declaration_request)
    inserted_at = DateTime.add(DateTime.utc_now(), -86_400 * 10)

    declaration_request =
      insert(
        :il,
        :declaration_request,
        status: DeclarationRequest.status(:signed),
        inserted_at: inserted_at
      )

    insert(:prm, :global_parameter, parameter: "declaration_request_term_unit", value: "DAYS")
    insert(:prm, :global_parameter, parameter: "declaration_request_expiration", value: "5")

    Terminator.clean_declaration_requests()
    assert 2 = DeclarationRequest |> Repo.all() |> Enum.count()
    signed = DeclarationRequest.status(:signed)
    assert %{data: nil, printout_content: nil, status: ^signed} = Repo.get(DeclarationRequest, declaration_request.id)
  end

  test "terminate outdated declaration_requests" do
    insert(:il, :declaration_request)
    inserted_at = DateTime.add(DateTime.utc_now(), -86_400 * 10)

    declaration_request =
      insert(
        :il,
        :declaration_request,
        status: DeclarationRequest.status(:cancelled),
        inserted_at: inserted_at
      )

    insert(:prm, :global_parameter, parameter: "declaration_request_term_unit", value: "DAYS")
    insert(:prm, :global_parameter, parameter: "declaration_request_expiration", value: "5")

    Terminator.terminate_declaration_requests()
    assert 2 = DeclarationRequest |> Repo.all() |> Enum.count()
    expired = DeclarationRequest.status(:expired)
    assert %{data: nil, printout_content: nil, status: ^expired} = Repo.get(DeclarationRequest, declaration_request.id)
  end
end

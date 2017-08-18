defmodule EHealth.Integration.DeclarationRequest.TerminatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias EHealth.DeclarationRequest
  alias EHealth.DeclarationRequest.Terminator
  alias EHealth.Repo

  @tag :pending
  test "start init genserver" do
    declaration_request = simple_fixture(:declaration_request)
    simple_fixture(:declaration_request)
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :seconds)

    declaration_request
    |> Ecto.Changeset.change(inserted_at: inserted_at)
    |> Repo.update()

    insert(:prm, :global_parameter, parameter: "declaration_request_term_unit", value: "DAYS")
    insert(:prm, :global_parameter, parameter: "declaration_request_expiration", value: "5")
    assert 2 = DeclarationRequest |> Repo.all() |> Enum.count

    GenServer.cast(Terminator, {:terminate, 1})
    Process.sleep(100)

    assert 1 = DeclarationRequest |> Repo.all() |> Enum.count
  end
end

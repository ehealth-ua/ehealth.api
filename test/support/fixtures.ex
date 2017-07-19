defmodule EHealth.Test.Support.Fixtures do
  @moduledoc false

  alias EHealth.Repo
  alias EHealth.DeclarationRequest

  def simple_fixture(:declaration_request, status \\ "ACTIVE", authentication_method_current_type \\ "OTP") do
    data =
      "test/data/sign_declaration_request.json"
      |> File.read!()
      |> Poison.decode!

    Repo.insert!(%DeclarationRequest{
      data: data,
      status: status,
      inserted_by: Ecto.UUID.generate(),
      updated_by: Ecto.UUID.generate(),
      authentication_method_current: %{"type" => authentication_method_current_type},
      printout_content: ""
    })
  end
end

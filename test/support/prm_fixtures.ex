defmodule EHealth.Test.Support.PRMFixtures do
  @moduledoc false

  alias Ecto.UUID
  alias Ecto.Changeset

  alias EHealth.PRMRepo
  alias EHealth.PRM.GlobalParameters.Schema, as: GlobalParameter

  def global_parameter_attrs(custom_attrs \\ %{}) do
    Map.merge(%{
      parameter: Base.url_encode64(:crypto.strong_rand_bytes(10)),
      value: :rand.normal(),
      inserted_by: UUID.generate(),
      updated_by: UUID.generate()
    }, custom_attrs)
  end

  def insert_global_parameter(custom_attrs \\ %{}) do
    attributes = global_parameter_attrs(custom_attrs)

    %GlobalParameter{}
    |> Changeset.change(attributes)
    |> PRMRepo.insert!
  end
end

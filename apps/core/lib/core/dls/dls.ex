defmodule Core.DLS do
  @moduledoc false

  alias Core.Divisions
  alias Core.Divisions.Division
  alias Core.DLS.Registry
  alias Core.PRMRepo

  @division_types [Division.type(:drugstore), Division.type(:drugstore_point)]

  def validate_divisions do
    Registry
    |> PRMRepo.all()
    |> Enum.each(fn registry ->
      with %Division{} = division <- Divisions.get_by_id(registry.division_id),
           true <- division.type in @division_types do
        case String.downcase(registry.dls_status) do
          "active" ->
            division
            |> Divisions.changeset(%{"dls_id" => registry.dls_id, "dls_verified" => true})
            |> PRMRepo.update()

          "inactive" ->
            division
            |> Divisions.changeset(%{"dls_id" => registry.dls_id, "dls_verified" => false})
            |> PRMRepo.update()

          _ ->
            nil
        end
      end
    end)
  end
end

defmodule EHealth.PRMRepo.Migrations.CopyDivisionAddressesFromColumnToTable do
  use Ecto.Migration

  import Ecto.Query

  alias EHealth.Divisions.Division
  alias EHealth.Divisions.DivisionAddress
  alias EHealth.PRMRepo

  def change do
    divisions =
      Division
      |> select([d], {d.id, d.addresses})
      |> PRMRepo.all()

    for {division_id, addresses} <- divisions, address <- addresses do
      division_address = Map.merge(address, %{"division_id" => division_id})

      %DivisionAddress{}
      |> DivisionAddress.changeset(division_address)
      |> PRMRepo.insert()
    end
  end
end

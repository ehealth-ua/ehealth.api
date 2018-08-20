defmodule Core.PRMRepo.Migrations.FixDivisionsAddresses do
  use Ecto.Migration

  import Ecto.Changeset
  import Ecto.Query

  alias Core.Divisions.Division
  alias Core.PRMRepo

  def change do
    Division
    |> where([d], fragment("jsonb_array_length(?) = 1", d.addresses))
    |> where([d], fragment(~s(? @> '[{"type": "REGISTRATION"}]'::jsonb), d.addresses))
    |> PRMRepo.all()
    |> Enum.each(fn division ->
      registration = hd(division.addresses)
      addresses = [registration, Map.put(registration, "type", "RESIDENCE")]

      division
      |> cast(%{addresses: addresses}, ~w(addresses)a)
      |> PRMRepo.update!()
    end)
  end
end

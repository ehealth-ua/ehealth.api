defmodule Core.Unit.RelatedLegalEntityTest do
  @moduledoc false

  use Core.ConnCase, async: false

  import Mox

  alias Core.LegalEntities.RelatedLegalEntities, as: API
  alias Core.LegalEntities.RelatedLegalEntity
  alias Ecto.Changeset
  alias Ecto.UUID

  setup :verify_on_exit!

  describe "create related legal entity" do
    test "duplicated merged ids" do
      to = insert(:prm, :legal_entity)
      from = insert(:prm, :legal_entity)

      inserted_by = UUID.generate()

      data = %{
        reason: "test merge",
        merged_to_id: to.id,
        merged_from_id: from.id,
        inserted_by: inserted_by,
        is_active: true
      }

      assert {:ok, _} = API.create(%RelatedLegalEntity{}, data, inserted_by)
      assert {:error, %Changeset{errors: errors}} = API.create(%RelatedLegalEntity{}, data, inserted_by)

      assert {"related legal entity already created", [constraint: :unique, constraint_name: "merged_ids_index"]} ==
               errors[:merged_to]
    end
  end
end

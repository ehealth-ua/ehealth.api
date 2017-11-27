defmodule EHealth.Medication.APITest do

  use EHealth.Web.ConnCase, async: true
  alias EHealth.Medications, as: API
  alias EHealth.Medications.INNMDosage
  alias Ecto.UUID

  @ingredient %{
    "id" => UUID.generate(),
    "is_primary" => true,
    "dosage" => %{
      "numerator_unit" => "pill",
      "numerator_value" => 10,
      "denumerator_unit" => "g",
      "denumerator_value" => 1
    }
  }
  @create_innm_dosage_attrs %{
    "name" => "some name",
    "form" => "some form",
    "ingredients" => [@ingredient],
  }
  @invalid_attrs %{
    "name" => nil,
    "form" => nil,
  }

  @doc """
  Creates Medication with type MEDICATION
  """
  def medication_fixture do
    %{id: medication_id} = medication_innm_dosage_fixture()
    %{id: innm_dosage_id} = insert(:prm, :innm_dosage)
    ingredient = build(:ingredient_medication,
      parent_id: medication_id,
      medication_child_id: innm_dosage_id
    )
    insert(:prm, :medication, ingredients: [ingredient])
  end

  @doc """
  Creates Medication with type INNM
  """
  def medication_innm_dosage_fixture do
    %{id: innm_id} = insert(:prm, :innm)
    ingredient = build(:ingredient_innm_dosage, innm_child_id: innm_id)

    insert(:prm, :innm_dosage, ingredients: [ingredient])
  end

  test "get_medication!/1 returns the medication with given id" do
    medication = medication_fixture()
    assert API.get_medication_by_id!(medication.id).name == medication.name
  end

  describe "create_innm_dosage/1" do
    test "invalid foreign keys" do
      assert {:error, error} = API.create_innm_dosage(@create_innm_dosage_attrs, get_headers_with_consumer_id())
      assert [ingredients: {"Invalid foreign keys", []}], error.errors
    end

    test "with type INNMDosage and valid data creates a medication" do
      %{id: innm_id} = insert(:prm, :innm)
      ingredient = Map.put(@ingredient, "id", innm_id)
      attrs = Map.put(@create_innm_dosage_attrs, "ingredients", [ingredient])

      assert {:ok, %INNMDosage{} = innm_dosage} = API.create_innm_dosage(attrs, get_headers_with_consumer_id())

      assert innm_dosage.name == "some name"
      assert innm_dosage.form == "some form"
      assert innm_dosage.ingredients == innm_dosage.ingredients
      assert innm_dosage.type == "INNM_DOSAGE"
    end

    test "with invalid data returns error changeset" do
      assert {:error, _} = API.create_medication(@invalid_attrs, get_headers_with_consumer_id())
    end
  end
end

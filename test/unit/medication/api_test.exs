defmodule EHealth.Medication.APITest do

  use EHealth.Web.ConnCase, async: true
  alias EHealth.PRM.Drugs.API
  alias EHealth.PRM.Drugs.INNM.Schema, as: INNM
  alias Ecto.UUID

  @ingredient %{
    "id" => UUID.generate(),
    "is_active_substance" => true,
    "dosage" => %{
      "numerator_unit" => "mg",
      "numerator_value" => 10,
      "denumerator_unit" => "g",
      "denumerator_value" => 1
    }
  }
  @create_innm_attrs %{
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
    %{id: medication_id} = medication_innm_fixture()
    ingredient = build(:ingredient, id: medication_id)
    insert(:prm, :medication, ingredients: [ingredient])
  end

  @doc """
  Creates Medication with type Substance
  """
  def medication_innm_fixture do
    %{id: substance_id} = insert(:prm, :substance)
    ingredient = build(:ingredient, id: substance_id)

    insert(:prm, :innm, ingredients: [ingredient])
  end

  test "get_medication!/1 returns the medication with given id" do
    medication = medication_fixture()
    assert API.get_medication_by_id!(medication.id).name == medication.name
  end

  describe "create_innm/1" do
    test "invalid foreign keys" do
      assert {:error, error} = API.create_innm(@create_innm_attrs, get_headers_with_consumer_id())
      assert [ingredients: {"Invalid foreign keys", []}], error.errors
    end

    test "with type INNM and valid data creates a medication" do
      %{id: substance_id} = insert(:prm, :substance)
      ingredient = Map.put(@ingredient, "id", substance_id)
      attrs = Map.put(@create_innm_attrs, "ingredients", [ingredient])

      assert {:ok, %INNM{} = innm} = API.create_innm(attrs, get_headers_with_consumer_id())

      assert innm.name == "some name"
      assert innm.form == "some form"
      assert innm.ingredients == innm.ingredients
      assert innm.type == "INNM"
    end

    test "with invalid data returns error changeset" do
      assert {:error, _} = API.create_medication(@invalid_attrs, get_headers_with_consumer_id())
    end
  end
end

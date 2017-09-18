defmodule EHealth.Medication.APITest do

  use EHealth.Web.ConnCase, async: true
  alias EHealth.PRM.Medication.API
  alias EHealth.PRM.Medication
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
  @create_attrs %{
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

  test "list_medications/0 returns all medications" do
    medication_fixture()
    medication = medication_innm_fixture()
    [_, medication_from_list] = API.list_medications(Medication.type(:innm))
    assert medication.name == medication_from_list.name
  end

  test "get_medication!/1 returns the medication with given id" do
    medication = medication_fixture()
    assert API.get_medication!(medication.id).name == medication.name
  end

  describe "create_medication/1" do
    test "with type INNM and invalid foreign keys" do
      assert {:error, error} = API.create_medication(@create_attrs, :innm, get_headers_with_consumer_id())
      assert [ingredients: {"Invalid foreign keys", []}], error.errors
    end

    test "with type Substance and valid data creates a medication" do
      %{id: substance_id} = insert(:prm, :substance)
      ingredient = Map.put(@ingredient, "id", substance_id)
      attrs = Map.put(@create_attrs, "ingredients", [ingredient])

      assert {:ok, %Medication{} = medication} = API.create_medication(
               attrs,
               :innm,
               get_headers_with_consumer_id()
             )

      assert medication.name == "some name"
      assert medication.form == "some form"
      assert medication.ingredients == medication.ingredients
      assert medication.type == "INNM"
    end

    test "with invalid data returns error changeset" do
      assert {:error, _} = API.create_medication(@invalid_attrs, :innm, get_headers_with_consumer_id())
    end
  end
end

defmodule Core.Unit.Valiadators.SignatureTest do
  @moduledoc false

  use Core.ConnCase
  import Core.Validators.Signature

  describe "check_drfo/3" do
    test "returns error when drfo does not match the tax_id" do
      tax_id = "AA111"
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))
      signer = %{"drfo" => "222"}
      result = check_drfo(signer, user_id, "")
      assert {:error, {:"422", "Does not match the signer drfo"}} == result
    end

    test "returns expected result when drfo matches the tax_id" do
      tax_id = "AA111"
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))

      signer = %{"drfo" => "AA 111"}
      assert :ok == check_drfo(signer, user_id, "")
    end

    test "check drfo when it latin" do
      tax_id = "МЮ111"
      assert [1052, 1070, 49, 49, 49] == String.to_charlist(tax_id)
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))

      drfo = "MYU 111"
      assert 'MYU 111' == String.to_charlist(drfo)
      signer = %{"drfo" => drfo}
      assert :ok == check_drfo(signer, user_id, "")
    end

    test "returns expected result when drfo is null" do
      tax_id = "AA111"
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))
      signer = %{"drfo" => nil}
      result = check_drfo(signer, user_id, "")
      assert {:error, {:"422", "Invalid drfo"}} == result
    end
  end

  describe "check_drfo/4" do
    test "returns error when drfo does not match the tax_id" do
      tax_id = "AA111"
      party = insert(:prm, :party, tax_id: tax_id)
      employee = insert(:prm, :employee, party: party)
      insert(:prm, :party_user, party: party)
      signer = %{"drfo" => "222"}
      result = check_drfo(signer, employee.id, "$.nhs_signer_id", "")

      assert {:error,
              [{%{description: "Does not match the signer drfo", params: [], rule: :invalid}, "$.nhs_signer_id"}]} ==
               result
    end

    test "returns expected result when drfo matches the tax_id" do
      tax_id = "AA112"
      party = insert(:prm, :party, tax_id: tax_id)
      employee = insert(:prm, :employee, party: party)
      insert(:prm, :party_user, party: party)

      signer = %{"drfo" => "AA 112"}
      assert :ok == check_drfo(signer, employee.id, "$.nhs_signer_id", "")
    end

    test "check drfo when it latin" do
      tax_id = "МЮ111"
      assert [1052, 1070, 49, 49, 49] == String.to_charlist(tax_id)
      party = insert(:prm, :party, tax_id: tax_id)
      employee = insert(:prm, :employee, party: party)
      insert(:prm, :party_user, party: party)

      drfo = "MYU 111"
      assert 'MYU 111' == String.to_charlist(drfo)
      signer = %{"drfo" => drfo}
      assert :ok == check_drfo(signer, employee.id, "$.nhs_signer_id", "")
    end

    test "returns expected result when drfo is null" do
      tax_id = "AA113"
      party = insert(:prm, :party, tax_id: tax_id)
      employee = insert(:prm, :employee, party: party)
      insert(:prm, :party_user, party: party)
      signer = %{"drfo" => nil}
      result = check_drfo(signer, employee.id, "$.nhs_signer_id", "")
      assert {:error, [{%{description: "Invalid drfo", params: [], rule: :invalid}, "$.nhs_signer_id"}]} == result
    end
  end
end

defmodule EHealth.Unit.LegalEntity.APITest do
  @moduledoc """
  Legal entity api tests
  """

  use EHealth.Web.ConnCase, async: true
  # alias EHealth.LegalEntities

  # describe "check status" do
  #   test "check_status CLOSED" do
  #     legal_entity = build(:legal_entity, status: "CLOSED")
  #     assert {:error, {:conflict, _}} = LegalEntities.check_status(legal_entity)
  #   end

  #   test "OK" do
  #     legal_entity = build(:legal_entity)
  #     assert :ok == API.check_status(legal_entity)
  #   end
  # end

end

defmodule EHealth.Integraiton.DeclarationRequests.API.RejectTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias Ecto.UUID
  alias Core.DeclarationRequests
  alias Core.DeclarationRequests.DeclarationRequest

  describe "reject/2" do
    test "rejecting record in NEW status" do
      record =
        insert(
          :il,
          :declaration_request,
          status: DeclarationRequest.status(:new)
        )

      user_id = UUID.generate()

      assert DeclarationRequest.status(:new) == record.status

      {:ok, updated_record} = DeclarationRequests.reject(record.id, user_id)

      assert DeclarationRequest.status(:rejected) == updated_record.status
      assert ^user_id = updated_record.updated_by
    end

    test "rejecting record in APPROVED status" do
      record =
        insert(
          :il,
          :declaration_request,
          status: DeclarationRequest.status(:approved)
        )

      user_id = UUID.generate()

      assert DeclarationRequest.status(:approved) == record.status

      {:ok, updated_record} = DeclarationRequests.reject(record.id, user_id)

      assert DeclarationRequest.status(:rejected) == updated_record.status
      assert ^user_id = updated_record.updated_by
    end

    test "rejecting record in REJECTED status" do
      record =
        insert(
          :il,
          :declaration_request,
          status: DeclarationRequest.status(:rejected)
        )

      user_id = UUID.generate()

      assert {:error, {:conflict, "Invalid transition"}} == DeclarationRequests.reject(record.id, user_id)
    end

    test "rejecting record in SIGNED status" do
      record =
        insert(
          :il,
          :declaration_request,
          status: DeclarationRequest.status(:rejected)
        )

      user_id = UUID.generate()

      assert {:error, {:conflict, "Invalid transition"}} == DeclarationRequests.reject(record.id, user_id)
    end
  end
end

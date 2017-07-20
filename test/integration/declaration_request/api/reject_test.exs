defmodule EHealth.Integraiton.DeclarationRequest.API.RejectTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias EHealth.DeclarationRequest.API

  describe "reject/2" do
    test "rejecting record in NEW status" do
      record  = simple_fixture(:declaration_request, "NEW")
      user_id = "fe98c21e-ba2f-4d60-8598-b0df6ec471bf"

      assert "NEW" = record.status

      {:ok, updated_record} = API.reject(record.id, user_id)

      assert "REJECTED" = updated_record.status
      assert ^user_id = updated_record.updated_by
    end

    test "rejecting record in APPROVED status" do
      record  = simple_fixture(:declaration_request, "APPROVED")
      user_id = "fe98c21e-ba2f-4d60-8598-b0df6ec471bf"

      assert "APPROVED" = record.status

      {:ok, updated_record} = API.reject(record.id, user_id)

      assert "REJECTED" = updated_record.status
      assert ^user_id = updated_record.updated_by
    end

    test "rejecting record in REJECTED status" do
      record  = simple_fixture(:declaration_request, "REJECTED")
      user_id = "fe98c21e-ba2f-4d60-8598-b0df6ec471bf"

      {:error, %Ecto.Changeset{valid?: false} = changeset} = API.reject(record.id, user_id)

      assert {"Incorrect status transition.", []} = changeset.errors[:status]
    end

    test "rejecting record in SIGNED status" do
      record  = simple_fixture(:declaration_request, "SIGNED")
      user_id = "fe98c21e-ba2f-4d60-8598-b0df6ec471bf"

      {:error, %Ecto.Changeset{valid?: false} = changeset} = API.reject(record.id, user_id)

      assert {"Incorrect status transition.", []} = changeset.errors[:status]
    end
  end
end

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

      assert "CANCELLED" = updated_record.status
      assert ^user_id = updated_record.updated_by
    end

    test "rejecting record in APPROVED status" do
      record  = simple_fixture(:declaration_request, "APPROVED")
      user_id = "fe98c21e-ba2f-4d60-8598-b0df6ec471bf"

      assert "APPROVED" = record.status

      {:ok, updated_record} = API.reject(record.id, user_id)

      assert "CANCELLED" = updated_record.status
      assert ^user_id = updated_record.updated_by
    end

    test "rejecting record in CANCELLED status" do
      record  = simple_fixture(:declaration_request, "CANCELLED")
      user_id = "fe98c21e-ba2f-4d60-8598-b0df6ec471bf"

      nil = API.reject(record.id, user_id)
    end

    test "rejecting record in SIGNED status" do
      record  = simple_fixture(:declaration_request, "SIGNED")
      user_id = "fe98c21e-ba2f-4d60-8598-b0df6ec471bf"

      nil = API.reject(record.id, user_id)
    end
  end
end

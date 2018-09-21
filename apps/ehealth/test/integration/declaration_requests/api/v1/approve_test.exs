defmodule EHealth.Integraiton.DeclarationRequests.API.ApproveTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Core.DeclarationRequests.API.Approve
  import Mox

  setup :verify_on_exit!

  describe "verify/2 - via offline docs" do
    test "all documents were verified to be successfully uploaded" do
      expect(OPSMock, :get_declarations_count, fn _, _ ->
        {:ok, %{"data" => %{"count" => 1}}}
      end)

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      party = insert(:prm, :party)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity_id: legal_entity.id)

      declaration_request =
        build(
          :declaration_request,
          id: "2685788E-CE5E-4C0F-9857-BB070C5F2180",
          authentication_method_current: %{
            "type" => "OFFLINE"
          },
          data: %{"employee" => %{"id" => employee_id}},
          documents: [
            %{"verb" => "HEAD", "type" => "A"},
            %{"verb" => "HEAD", "type" => "B"}
          ]
        )

      assert {:ok, true} = verify(declaration_request, "doesn't matter", [])
    end

    test "there's a missing upload" do
      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn
        _, "declaration_request_A.jpeg" -> {:ok, %HTTPoison.Response{status_code: 200}}
        _, "declaration_request_C.jpeg" -> {:ok, %HTTPoison.Response{status_code: 404}}
      end)

      declaration_request = %{
        id: "2685788E-CE5E-4C0F-9857-BB070C5F2180",
        authentication_method_current: %{
          "type" => "OFFLINE"
        },
        documents: [
          %{"verb" => "HEAD", "type" => "A"},
          %{"verb" => "HEAD", "type" => "C"}
        ]
      }

      assert {:error, {:documents_not_uploaded, ["C"]}} == verify(declaration_request, "doesn't matter")
    end

    test "response error" do
      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://localhost/good_upload_1"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, fn _, _ ->
        {:error, "reason"}
      end)

      declaration_request = %{
        id: "2685788E-CE5E-4C0F-9857-BB070C5F2180",
        authentication_method_current: %{
          "type" => "OFFLINE"
        },
        documents: [
          %{"verb" => "HEAD", "type" => "A"}
        ]
      }

      assert {:error, {:ael_bad_response, "reason"}} == verify(declaration_request, "doesn't matter")
    end
  end

  describe "verify/2 - via code" do
    test "successfully completes phone verification" do
      otp_verification_expect()

      declaration_request = %{
        authentication_method_current: %{
          "type" => "OTP",
          "number" => "+380972805261"
        }
      }

      assert {:ok, %{"data" => %{"status" => "verified"}}} = verify_auth(declaration_request, "99911")
    end

    test "phone is not verified verification" do
      otp_verification_expect()

      declaration_request = %{
        authentication_method_current: %{
          "type" => "OTP",
          "number" => "+380972805261"
        }
      }

      assert {:error, %{"error" => %{}}} = verify_auth(declaration_request, "11999")
    end

    test "auth method NA is not required verification" do
      declaration_request = %{
        authentication_method_current: %{
          "type" => "NA",
          "number" => "+380972805261"
        }
      }

      assert {:ok, true} == verify_auth(declaration_request, nil)
    end
  end

  defp otp_verification_expect(count \\ 1) do
    expect(OTPVerificationMock, :complete, count, fn _number, params, _headers ->
      case params.code do
        "99911" ->
          {:ok, %{"meta" => %{"code" => 200}, "data" => %{"status" => "verified"}}}

        "11999" ->
          {:error,
           %{"meta" => %{"code" => 422}, "error" => %{"type" => "forbidden", "message" => "invalid verification code"}}}

        _ ->
          nil
      end
    end)
  end
end

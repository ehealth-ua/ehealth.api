defmodule Core.Unit.Email.PostmarkTest do
  @moduledoc false

  use Core.ConnCase

  alias Core.Email.Postmark

  describe "activate_email" do
    test "correclty activates email" do
      expected_bounce_id = "1240137184"

      Mox.expect(PostmarkMock, :get_bounces, fn _ ->
        {:ok,
         %HTTPoison.Response{
           body: ~s({"TotalCount": 1, "Bounces": [{"ID": #{expected_bounce_id}}] }),
           status_code: 200
         }}
      end)

      Mox.expect(PostmarkMock, :activate_bounce, fn _ ->
        {:ok,
         %HTTPoison.Response{
           body: ~s({"Message":"OK","Bounce":{"ID":#{expected_bounce_id}, "CanActivate":true}}),
           status_code: 200
         }}
      end)

      assert {:ok, expected_bounce_id} === Postmark.activate_email("valid@email.com")
    end

    test "show error on bounce not found" do
      Mox.expect(PostmarkMock, :get_bounces, fn _ ->
        {:ok,
         %HTTPoison.Response{
           body: ~s({"TotalCount": 0, "Bounces":[]}"),
           status_code: 200
         }}
      end)

      assert {:error, _} = Postmark.activate_email("valid@email.com")
    end

    test "show error on httpoison error" do
      Mox.expect(PostmarkMock, :get_bounces, fn _ ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      assert {:error, _} = Postmark.activate_email("valid@email.com")
    end

    test "show error on non 200 response status from postmark" do
      Mox.expect(PostmarkMock, :get_bounces, fn _ ->
        {:ok,
         %HTTPoison.Response{
           body: ~s({"would_not": "match"}),
           status_code: 422
         }}
      end)

      assert {:error, _} = Postmark.activate_email("valid@email.com")
    end

    test "show error on email that can't be activated" do
      Mox.expect(PostmarkMock, :get_bounces, fn _ ->
        {:ok,
         %HTTPoison.Response{
           body: ~s({"TotalCount": 1, "Bounces": [{"ID": 123}] }),
           status_code: 200
         }}
      end)

      Mox.expect(PostmarkMock, :activate_bounce, fn _ ->
        {:ok,
         %HTTPoison.Response{
           body: ~s({"Message":"OK","Bounce":{"ID":123, "CanActivate": false}}),
           status_code: 200
         }}
      end)

      assert {:error, _} = Postmark.activate_email("valid@email.com")
    end
  end
end

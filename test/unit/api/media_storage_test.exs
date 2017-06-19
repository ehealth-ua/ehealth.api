defmodule EHealth.Unit.API.MediaStorageTest do
  @moduledoc false

  import ExUnit.CaptureLog

  use EHealth.Web.ConnCase

  alias EHealth.API.MediaStorage

  describe "create_signed_url/2" do
    setup do
      original_level = Logger.level()
      Logger.configure(level: :info)

      on_exit fn ->
        Logger.configure(level: original_level)
      end

      :ok
    end

    test "writes to log" do
      fun = fn ->
        MediaStorage.create_signed_url("PUT", "some_bucket", "my_resource", "my_id", [some_header: "x"])
      end

      assert capture_log([level: :info], fun) =~ "Calling POST on http://localhost:4040/media_content_storage_secrets"
      assert capture_log([level: :info], fun) =~ "body=%{"
      assert capture_log([level: :info], fun) =~ ~s(headers=[some_header: "x"])
    end
  end
end

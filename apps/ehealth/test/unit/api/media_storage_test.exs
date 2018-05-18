defmodule EHealth.Unit.API.MediaStorageTest do
  @moduledoc false

  import ExUnit.CaptureLog

  use EHealth.Web.ConnCase

  alias EHealth.API.MediaStorage

  describe "create_signed_url/2" do
    setup do
      original_level = Logger.level()
      Logger.configure(level: :info)

      on_exit(fn ->
        Logger.configure(level: original_level)
      end)

      :ok
    end

    test "writes to log" do
      fun = fn ->
        MediaStorage.create_signed_url("PUT", "some_bucket", "my_resource", "my_id", some_header: "x")
      end

      message =
        ~s("action":"post","body":\"{\\\"secret\\\":{\\\"action\\\":\\\"PUT\\\",\\\"bucket\\\":\\\"some_bucket\\\",\\\"content_type\\\":\\\"application/octet-stream\\\",\\\"resource_id\\\":\\\"my_id\\\",\\\"resource_name\\\":\\\"my_resource\\\"}}\",\"headers\":{\"some_header\":\"x\",\"Content-Type\":\"application/json\"},\"log_type\":\"microservice_request\")

      assert capture_log([level: :info], fun) =~ message
    end
  end
end

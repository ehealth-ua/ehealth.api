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

      message =
        ~s("log_type":"microservice_request","headers":{"some_header":"x"},"body":{"secret":{") <>
        ~s(resource_name":"my_resource","resource_id":"my_id","content_type":"application/octe) <>
        ~s(t-stream","bucket":"some_bucket","action":"PUT"}},"action":"POST")
      assert capture_log([level: :info], fun) =~ message
    end
  end
end

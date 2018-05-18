defmodule EHealth.Unit.API.Helpers.MicroserviceBaseTest do
  @moduledoc false

  use ExUnit.Case, async: true

  use EHealth.API.Helpers.MicroserviceBase
  import ExUnit.CaptureLog

  def config, do: [endpoint: "http://google.com", hackney_options: []]

  setup do
    original_level = Logger.level()
    Logger.configure(level: :info)

    on_exit(fn ->
      Logger.configure(level: original_level)
    end)

    :ok
  end

  test "log/4" do
    headers = [{"some_header", "x"}, {"api-key", "y"}, {"authorization", "z"}]

    fun = fn ->
      get!("/test", headers, params: %{"param1" => "test"})
    end

    message =
      ~s({"action":"get","body":"","headers":{"Content-Type":"application/json","some_header":"x"},"log_type":"microservice_request","microservice":"http://google.com","path":"http://google.com/test?param1=test","request_id":null})

    assert capture_log([level: :info], fun) =~ message
  end

  test "log/5" do
    headers = [{"some_header", "x"}, {"api-key", "y"}, {"authorization", "z"}]

    fun = fn ->
      post!("/test", Jason.encode!(%{a: 1, b: 2}), headers)
    end

    message =
      ~s({"action":"post","body":"{\\\"a\\\":1,\\\"b\\\":2}","headers":{"Content-Type":"application/json","some_header":"x"},"log_type":"microservice_request","microservice":"http://google.com","path":"http://google.com/test","request_id":null})

    assert capture_log([level: :info], fun) =~ message
  end
end

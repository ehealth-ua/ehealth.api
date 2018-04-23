defmodule EHealth.Unit.API.Helpers.MicroserviceBaseTest do
  @moduledoc false

  use ExUnit.Case, async: true

  use HTTPoison.Base
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
      ~s({"request_id":null,"path":"http://google.com/test?param1=test","microservice":"http://google.com",) <>
        ~s("log_type":"microservice_request","headers":{"some_header":"x","Content-Type":"application/json"},"body":"","action":"get"})

    assert capture_log([level: :info], fun) =~ message
  end

  test "log/5" do
    headers = [{"some_header", "x"}, {"api-key", "y"}, {"authorization", "z"}]

    fun = fn ->
      post!("/test", Poison.encode!(%{a: 1, b: 2}), headers)
    end

    message =
      ~s({"request_id":null,"path":"http://google.com/test","microservice":"http://google.com","log_type":") <>
        ~s(microservice_request","headers":{"some_header":"x","Content-Type":"application/json"},"body":"{\\\"b\\\":2,\\\"a\\\":1}","action":"post"})

    assert capture_log([level: :info], fun) =~ message
  end
end

defmodule EHealth.Unit.API.Helpers.MicroserviceCallLogTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias EHealth.API.Helpers.MicroserviceCallLog

  import ExUnit.CaptureLog

  setup do
    original_level = Logger.level()
    Logger.configure(level: :info)

    on_exit fn ->
      Logger.configure(level: original_level)
    end

    :ok
  end

  test "log/4" do
    fun = fn ->
      MicroserviceCallLog.log("GET", "google.com", "/test", [some_header: "x"])
    end

    assert capture_log([level: :info], fun) =~ ~s(Calling GET on google.com/test with headers=[some_header: "x"].)
  end

  test "log/5" do
    fun = fn ->
      MicroserviceCallLog.log("POST", "google.com", "/test", %{a: 1, b: 2}, [some_header: "x"])
    end

    message = ~s(Calling POST on google.com/test with body=%{a: 1, b: 2} and headers=[some_header: "x"].)
    assert capture_log([level: :info], fun) =~ message
  end
end

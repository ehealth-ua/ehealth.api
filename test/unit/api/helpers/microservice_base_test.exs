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

    on_exit fn ->
      Logger.configure(level: original_level)
    end

    :ok
  end

  test "log/4" do
    fun = fn ->
      get!("/test", [some_header: "x"], params: %{"param1" => "test"})
    end

    message = ~s(Calling get on http://google.com/test?param1=test. Body: "". Headers: [some_header: "x"])
    assert capture_log([level: :info], fun) =~ message
  end

  test "log/5" do
    fun = fn ->
      post!("/test", Poison.encode!(%{a: 1, b: 2}), [some_header: "x"])
    end

    message = ~s(Calling post on http://google.com/test. Body: "{\\"b\\":2,\\"a\\":1}". Headers: [some_header: "x"])
    assert capture_log([level: :info], fun) =~ message
  end
end

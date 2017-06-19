defmodule EHealth.Unit.API.PrmTest do
  @moduledoc false

  import ExUnit.CaptureLog

  use EHealth.Web.ConnCase

  alias EHealth.API.PRM

  describe "get_global_parameters/1" do
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
        PRM.get_global_parameters([some_header: "x"])
      end

      assert capture_log([level: :info], fun) =~ "Calling GET on http://localhost:4040/global_parameters"
      assert capture_log([level: :info], fun) =~ ~s(headers=[some_header: "x"])
    end
  end

  describe "get_employee_by_id/1" do
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
        PRM.get_employee_by_id("66abd07e-62d5-43c5-a260-4b835ef81b6b", [some_header: "x"])
      end

      message = "Calling GET on http://localhost:4040/employees/66abd07e-62d5-43c5-a260-4b835ef81b6b"
      assert capture_log([level: :info], fun) =~ message
      assert capture_log([level: :info], fun) =~ ~s(headers=[some_header: "x"])
    end
  end
end

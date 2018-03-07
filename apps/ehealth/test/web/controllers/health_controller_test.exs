defmodule EHealth.Web.HealthControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "health status" do
    test "returns 200", %{conn: conn} do
      conn
      |> get(health_path(conn, :show))
      |> response(200)
    end
  end
end

defmodule EHealth.Web.DeduplicationsController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.DuplicatePersons.Signals

  action_fallback EHealth.Web.FallbackController

  def found_duplicates(conn, _params) do
    Signals.deactivate()

    text conn, "OK"
  end
end

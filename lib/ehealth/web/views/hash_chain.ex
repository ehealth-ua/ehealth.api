defmodule EHealth.Web.HashChainView do
  @moduledoc false

  use EHealth.Web, :view

  def render("notification_sent.json", _) do
    %{
      message: "The notification was successfully sent."
    }
  end
end

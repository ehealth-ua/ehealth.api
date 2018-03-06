defmodule EHealth.Web.EmailView do
  @moduledoc false

  use EHealth.Web, :view

  def render("email_sent.json", _) do
    %{
      message: "Email was successfully sent."
    }
  end
end

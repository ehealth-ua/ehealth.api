defmodule EHealth.Web.CapitationView do
  @moduledoc false
  use EHealth.Web, :view

  def render("index.json", %{reports: reports}) do
    render_many(reports, __MODULE__, "show.json", as: :report)
  end

  def render("show.json", %{report: report}) do
    Map.take(report, ~w(id billing_date inserted_at))
  end
end

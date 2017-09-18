defmodule EHealth.Web.SubstanceView do
  @moduledoc false
  use EHealth.Web, :view

  def render("index.json", %{substances: substances}) do
    render_many(substances, __MODULE__, "substance.json")
  end

  def render("show.json", %{substance: substance}) do
    render_one(substance, __MODULE__, "substance.json")
  end

  def render("substance.json", %{substance: substance}) do
    substance
  end
end

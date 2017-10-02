defmodule EHealth.Web.INNMView do
  @moduledoc false
  use EHealth.Web, :view

  def render("index.json", %{innms: innms}) do
    render_many(innms, __MODULE__, "innm.json")
  end

  def render("show.json", %{innm: innm}) do
    render_one(innm, __MODULE__, "innm.json")
  end

  def render("innm.json", %{innm: innm}) do
    innm
  end
end

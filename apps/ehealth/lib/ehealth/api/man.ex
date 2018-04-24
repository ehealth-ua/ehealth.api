defmodule EHealth.API.Man do
  @moduledoc """
  Man API client
  """

  use EHealth.API.Helpers.MicroserviceBase

  @behaviour EHealth.API.ManBehaviour

  def render_template(id, data, headers \\ []) do
    post!("/templates/#{id}/actions/render", Poison.encode!(data), headers)
  end
end

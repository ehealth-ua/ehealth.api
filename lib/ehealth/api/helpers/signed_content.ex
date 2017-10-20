defmodule EHealth.API.Helpers.SignedContent do
  @moduledoc """
  Save signed content by absolute url
  """

  use HTTPoison.Base
  use EHealth.API.HeadersProcessor

  def save(url, content, headers, options) do
    put!(url, content, headers, options)
  end
end

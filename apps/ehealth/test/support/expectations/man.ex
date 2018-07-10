defmodule EHealth.Expectations.Man do
  @moduledoc false

  import Mox

  def html_template(html, n \\ 1) when is_binary(html) do
    expect(ManMock, :render_template, n, fn _, _, _ ->
      {:ok, html}
    end)
  end

  def template(n \\ 1) do
    expect(ManMock, :render_template, n, fn _, _, _ ->
      {:ok, "<html></html>"}
    end)
  end
end

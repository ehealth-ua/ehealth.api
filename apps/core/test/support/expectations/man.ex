defmodule Core.Expectations.Man do
  @moduledoc false

  import Mox

  def html_template(html, n \\ 1) when is_binary(html) do
    expect(RPCWorkerMock, :run, n, fn "man_api", Man.Rpc, :render_template, _ ->
      {:ok, html}
    end)
  end

  def template(n \\ 1) do
    expect(RPCWorkerMock, :run, n, fn "man_api", Man.Rpc, :render_template, _ ->
      {:ok, "<html></html>"}
    end)
  end
end

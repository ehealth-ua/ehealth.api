defmodule EHealth.Capitation.Capitation do
  @moduledoc false

  alias Scrivener.Page
  @report_api Application.get_env(:ehealth, :api_resolvers)[:report]

  def list(params, headers) do
    with {:ok, %{"data" => data, "paging" => paging}} <- @report_api.get_capitation_list(params, headers) do
      %{create_page(paging) | entries: data}
    end
  end

  def details(params, headers) do
    with {:ok, %{"data" => data, "paging" => paging}} <- @report_api.get_capitation_details(params, headers) do
      %{create_page(paging) | entries: data}
    end
  end

  defp create_page(paging) do
    struct(Page, Enum.into(paging, %{}, fn {k, v} -> {String.to_atom(k), v} end))
  end
end

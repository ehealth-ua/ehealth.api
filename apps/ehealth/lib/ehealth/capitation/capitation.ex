defmodule EHealth.Capitation.Capitation do
  @moduledoc false

  alias Scrivener.Page
  import EHealth.Utils.Connection, only: [get_client_id: 1]

  @report_api Application.get_env(:ehealth, :api_resolvers)[:report]
  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]

  def list(params, headers) do
    with {:ok, %{"data" => data, "paging" => paging}} <- @report_api.get_capitation_list(params, headers) do
      paging
      |> create_page()
      |> Map.put(:entries, data)
    end
  end

  def details(params, headers) do
    client_id = get_client_id(headers)

    params =
      case @mithril_api.get_client_type_name(client_id, headers) do
        {:ok, "NHS"} -> params
        _ -> Map.put(params, "legal_entity_id", client_id)
      end

    with {:ok, %{"data" => data, "paging" => paging}} <- @report_api.get_capitation_details(params, headers) do
      paging
      |> create_page()
      |> Map.put(:entries, data)
    end
  end

  defp create_page(paging) do
    struct(Page, Enum.into(paging, %{}, fn {k, v} -> {String.to_atom(k), v} end))
  end
end

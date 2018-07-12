defmodule EHealth.Web.CapitationView do
  @moduledoc false
  use EHealth.Web, :view

  def render("index.json", %{reports: reports}) do
    render_many(reports, __MODULE__, "show.json", as: :report)
  end

  def render("show.json", %{report: report}) do
    Map.take(report, ~w(id billing_date inserted_at))
  end

  def render("details.json", %{details: details}) do
    render_many(details, __MODULE__, "detail.json", as: :detail)
  end

  def render("detail.json", %{detail: detail}) do
    detail
    |> Map.take(~w(billing_date capitation_contracts edrpou legal_entity_id legal_entity_name report_id))
    |> Map.put("id", detail["edrpou"] <> "-" <> detail["report_id"])
    |> Map.put(
      "capitation_contracts",
      render_many(detail["capitation_contracts"], __MODULE__, "contract.json", as: :contract)
    )
  end

  def render("contract.json", %{contract: contract}) do
    contract
    |> Map.take(~w(contract_id contract_number details total))
    |> Map.put(
      "contract_detail",
      render_many(contract["details"], __MODULE__, "contract_detail.json", as: :contract_detail)
    )
    |> Map.put("total", merge_attributes(contract["total"]))
  end

  def render("contract_detail.json", %{contract_detail: detail}) do
    detail
    |> Map.take(~w(mountain_group attributes))
    |> Map.put("attributes", merge_attributes(detail["attributes"]))
  end

  defp merge_attributes(attributes) do
    Enum.reduce(attributes, %{}, fn tm, acc ->
      Map.merge(acc, tm)
    end)
  end
end

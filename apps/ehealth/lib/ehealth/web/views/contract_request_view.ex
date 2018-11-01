defmodule EHealth.Web.ContractRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias Core.ContractRequests.Renderer, as: ContractRequestsRenderer

  def render("index.json", %{contract_requests: contract_requests}) do
    render_many(contract_requests, __MODULE__, "list_contract_request.json")
  end

  def render("list_contract_request.json", %{contract_request: contract_request}) do
    Map.take(contract_request, ~w(
      id
      contractor_legal_entity_id
      contractor_owner_id
      contractor_base
      status
      status_reason
      nhs_signer_id
      nhs_legal_entity_id
      nhs_signer_base
      issue_city
      nhs_contract_price
      contract_number
      contract_id
      start_date
      end_date
      parent_contract_id
    )a)
  end

  def render("draft.json", %{id: id, statute_url: statute_url, additional_document_url: additional_document_url}) do
    %{
      id: id,
      statute_url: statute_url,
      additional_document_url: additional_document_url
    }
  end

  def render("show.json", %{contract_request: contract_request, references: references}) do
    ContractRequestsRenderer.render(contract_request, references)
  end

  def render("partially_signed_content.json", %{url: url}), do: %{url: url}

  def render("printout_content.json", %{contract_request: contract_request, printout_content: printout_content}) do
    %{id: contract_request.id, printout_content: printout_content}
  end

  def render("contract_request_decline.json", %{contract_request: contract_request, references: references}) do
    contractor_legal_entity =
      references
      |> Map.get(:legal_entity)
      |> Map.get(contract_request.contractor_legal_entity_id)

    %{
      "id" => contract_request.id,
      "contractor_legal_entity" => Map.take(contractor_legal_entity, ~w(id name edrpou)a)
    }
  end

  def render("contract_request_approve.json", %{contract_request: contract_request, references: references}) do
    contractor_legal_entity =
      references
      |> Map.get(:legal_entity)
      |> Map.get(contract_request.contractor_legal_entity_id)

    %{
      "id" => contract_request.id,
      "contractor_legal_entity" => Map.take(contractor_legal_entity, ~w(id name edrpou)a)
    }
  end
end

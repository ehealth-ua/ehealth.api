defmodule EHealth.Web.ContractView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.Web.ContractRequestView

  def render("index.json", %{contracts: contracts, references: references}) do
    Enum.map(contracts, fn contract ->
      render_one(contract, __MODULE__, "contract.json", references: references)
    end)
  end

  def render("contract.json", %{contract: contract, references: references}) do
    contract
    |> Map.take(~w(
      id
      start_date
      end_date
      status
      contractor_legal_entity_id
      contractor_base
      external_contractor_flag
      nhs_legal_entity_id
      nhs_signer_id
      nhs_signer_base
      issue_city
      price
      contract_number
      is_suspended
      contract_request_id
    ))
    |> Map.put(
      "contractor_owner",
      ContractRequestView.render_association(:employee, references, contract["contractor_owner_id"])
    )
  end

  def render("show.json", %{contract: contract, references: references}) do
    contract_request = get_in(references, [:contract_request, contract["contract_request_id"]])

    contract
    |> Map.take(~w(
      id
      start_date
      end_date
      status
      contractor_base
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
      external_contractors
      nhs_payment_method
      nhs_signer_base
      nhs_payment_details
      issue_city
      price
      contract_number
      is_suspended
      contract_request_id
    ))
    |> Map.put("nhs_contract_price", contract_request.nhs_contract_price)
    |> Map.put(
      "contractor_legal_entity",
      ContractRequestView.render_association(:legal_entity, references, contract["contractor_legal_entity_id"])
    )
    |> Map.put(
      "nhs_legal_entity",
      ContractRequestView.render_association(:legal_entity, references, contract["nhs_legal_entity_id"])
    )
    |> Map.put(
      "contractor_owner",
      ContractRequestView.render_association(:employee, references, contract["contractor_owner_id"])
    )
    |> Map.put(
      "nhs_signer",
      ContractRequestView.render_association(:employee, references, contract["nhs_signer_id"])
    )
    |> Map.put(
      "contractor_employee_divisions",
      ContractRequestView.render_association(
        :employee_divisions,
        references,
        contract["contractor_employee_divisions"] || []
      )
    )
  end
end

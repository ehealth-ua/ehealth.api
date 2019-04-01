defmodule Core.Man.Templates.ReimbursementContractRequestPrintoutForm do
  @moduledoc false

  use Confex, otp_app: :core

  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]

  import Core.Man.Templates.CapitationContractRequestPrintoutForm,
    only: [
      format_price: 2,
      format_date: 2,
      prepare_employee: 2,
      prepare_employee: 3,
      prepare_contractor_legal_entity: 3
    ]

  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Dictionaries
  alias Core.Validators.Preload

  @man_api Application.get_env(:core, :api_resolvers)[:man]

  def render(%ReimbursementContractRequest{} = contract_request, headers) do
    template_data =
      contract_request
      |> atoms_to_strings()
      |> Map.merge(%{
        "format" => config()[:format],
        "locale" => config()[:locale]
      })

    template_id = config()[:id]

    @man_api.render_template(template_id, prepare_data(template_data), headers)
  end

  defp prepare_data(data) do
    {:ok, dictionaries} = Dictionaries.list_dictionaries()
    references = preload_references(data)

    nhs_signer = Map.get(references.employee, data["nhs_signer_id"]) || %{}
    contractor_owner = Map.get(references.employee, data["contractor_owner_id"]) || %{}
    contractor_legal_entity = Map.get(references.legal_entity, Map.get(data, "contractor_legal_entity_id")) || %{}

    data
    |> format_date(~w(start_date))
    |> format_date(~w(end_date))
    |> format_date(~w(nhs_signed_date))
    |> format_price("nhs_contract_price")
    |> Map.merge(%{
      "nhs_signer" => prepare_employee(nhs_signer, dictionaries),
      "contractor_owner" => prepare_employee(contractor_owner, dictionaries, contractor_legal_entity),
      "contractor_legal_entity" => prepare_contractor_legal_entity(data, references, dictionaries)
    })
  end

  defp preload_references(contract_request) do
    load_entities = [
      {"nhs_signer_id", :employee},
      {"contractor_legal_entity_id", :legal_entity},
      {"contractor_owner_id", :employee}
    ]

    Preload.preload_references(contract_request, load_entities)
  end
end

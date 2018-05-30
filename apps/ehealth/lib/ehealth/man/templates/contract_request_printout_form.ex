defmodule EHealth.Man.Templates.ContractRequestPrintoutForm do
  @moduledoc false

  use Confex, otp_app: :ehealth

  alias EHealth.Validators.Preload
  alias EHealth.ContractRequests.ContractRequest

  @man_api Application.get_env(:ehealth, :api_resolvers)[:man]

  def render(%ContractRequest{} = contract_request, headers) do
    template_data =
      contract_request
      |> Jason.encode!()
      |> Jason.decode!()
      |> Map.put("format", config()[:format])
      |> Map.put("locale", config()[:locale])

    template_id = config()[:id]
    @man_api.render_template(template_id, prepare_data(template_data), headers)
  end

  defp prepare_data(data) do
    references = preload_references(data)
    nhs_signer = Map.get(references.employee, Map.get(data, "nhs_signer_id")) || %{}

    contractor_owner = Map.get(references.employee, Map.get(data, "contractor_owner_id")) || %{}

    data
    |> Map.put("nhs_signer", nhs_signer)
    |> Map.put("contractor_legal_entity", prepare_contractor_legal_entity(data, references))
    |> Map.put("contractor_owner", contractor_owner)
    |> Map.put("contractor_divisions", prepare_contractor_divisions(data, references))
    |> Map.put("contractor_employee_divisions", prepare_contractor_employee_divisions(data, references))
    |> Map.put("external_contractors", prepare_external_contractors(data, references))
  end

  defp prepare_contractor_legal_entity(data, references) do
    contractor_legal_entity = Map.get(references.legal_entity, Map.get(data, "contractor_legal_entity_id")) || %{}

    address =
      contractor_legal_entity
      |> Map.get("addresses", [])
      |> Enum.find(fn address -> Map.get(address, "type") == "REGISTRATION" end)

    Map.put(contractor_legal_entity, "address", address)
  end

  defp prepare_contractor_divisions(data, references) do
    contractor_divisions = Map.get(data, "contractor_divisions") || []

    Enum.map(contractor_divisions, fn division_id ->
      division = Map.get(references.division, division_id) || %{}

      address =
        division
        |> Map.get("address", [])
        |> Enum.find(fn address -> Map.get(address, "type") == "REGISTRATION" end)

      phones = Map.get(division, "phones") || []
      phone = List.first(phones) || %{}

      division
      |> Map.put("address", address)
      |> Map.put("phone", phone)
    end)
  end

  defp prepare_contractor_employee_divisions(data, references) do
    contractor_employee_divisions = Map.get(data, "contractor_employee_divisions") || []

    Enum.map(contractor_employee_divisions, fn contractor_employee_division ->
      employee = Map.get(references.employee, contractor_employee_division["employee_id"]) || %{}
      Map.put(contractor_employee_division, "employee", employee)
    end)
  end

  defp prepare_external_contractors(data, references) do
    external_contractors = Map.get(data, "external_contractors") || []

    Enum.map(external_contractors, fn external_contractor ->
      legal_entity = Map.get(references.legal_entity, external_contractor["legal_entity_id"]) || %{}
      Map.put(external_contractor, "legal_entity", legal_entity)
    end)
  end

  defp preload_references(contract_request) do
    fields = [
      {"contractor_legal_entity_id", :legal_entity},
      {"contractor_owner_id", :employee},
      {"nhs_signer_id", :employee},
      {"contractor_divisions", :division}
    ]

    fields =
      if is_list(contract_request["contractor_employee_divisions"]) do
        fields ++
          [
            {["contractor_employee_divisions", "$", "employee_id"], :employee}
          ]
      else
        fields
      end

    fields =
      if is_list(contract_request["external_contractors"]) do
        fields ++
          [
            {["external_contractors", "$", "legal_entity_id"], :legal_entity}
          ]
      else
        fields
      end

    Preload.preload_references(contract_request, fields)
  end
end

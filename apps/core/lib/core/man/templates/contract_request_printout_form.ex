defmodule Core.Man.Templates.ContractRequestPrintoutForm do
  @moduledoc false

  use Confex, otp_app: :core

  import Ecto.Query

  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Contracts.CapitationContract
  alias Core.Dictionaries
  alias Core.Dictionaries.Dictionary
  alias Core.PRMRepo
  alias Core.Validators.Preload

  @man_api Application.get_env(:core, :api_resolvers)[:man]
  @working_hours [
    mon: "Пн.",
    tue: "Вт.",
    wed: "Ср.",
    thu: "Чт.",
    fri: "Пт.",
    sat: "Сб.",
    sun: "Нд."
  ]

  def render(
        %CapitationContractRequest{parent_contract_id: parent_contract_id, contract_number: contract_number} =
          contract_request,
        headers
      )
      when not is_nil(parent_contract_id) do
    parent_contract =
      CapitationContract
      |> where([c], c.contract_number == ^contract_number and is_nil(c.parent_contract_id))
      |> PRMRepo.one()

    template_data =
      contract_request
      |> Jason.encode!()
      |> Jason.decode!()
      |> Map.put("format", config()[:format])
      |> Map.put("locale", config()[:locale])
      |> prepare_data()
      |> Map.put("parent", %{"nhs_signed_date" => to_string(parent_contract.nhs_signed_date)})
      |> format_date(~w(parent nhs_signed_date))

    template_id = config()[:appendix_id]
    @man_api.render_template(template_id, template_data, headers)
  end

  def render(%CapitationContractRequest{} = contract_request, headers) do
    template_data =
      contract_request
      |> Jason.encode!()
      |> Jason.decode!()
      |> Map.put("format", config()[:format])
      |> Map.put("locale", config()[:locale])

    template_id = config()[:id]
    @man_api.render_template(template_id, prepare_data(template_data), headers)
  end

  # ToDo: form is not ready yet. Waiting for НСЗУ
  def render(%ReimbursementContractRequest{} = _contract_request, _headers) do
    {:ok, "<html>Reimbursement contract printout form</html>"}
  end

  defp prepare_data(data) do
    {:ok, dictionaries} = Dictionaries.list_dictionaries()
    references = preload_references(data)
    nhs_signer = Map.get(references.employee, Map.get(data, "nhs_signer_id")) || %{}

    contractor_owner = Map.get(references.employee, Map.get(data, "contractor_owner_id")) || %{}

    data
    |> format_date(~w(start_date))
    |> format_date(~w(end_date))
    |> format_date(~w(nhs_signed_date))
    |> format_price("nhs_contract_price")
    |> Map.put("nhs_signer", prepare_employee(nhs_signer))
    |> Map.put("contractor_legal_entity", prepare_contractor_legal_entity(data, references, dictionaries))
    |> Map.put("contractor_owner", prepare_employee(contractor_owner))
    |> Map.put("contractor_divisions", prepare_contractor_divisions(data, references, dictionaries))
    |> Map.put("contractor_employee_divisions", prepare_contractor_employee_divisions(data, references, dictionaries))
    |> Map.put("external_contractors", prepare_external_contractors(data, references, dictionaries))
  end

  defp format_price(data, field) do
    case Map.get(data, field) do
      value when is_integer(value) -> Map.put(data, field, :erlang.float_to_binary(value / 1, decimals: 2))
      value when is_float(value) -> Map.put(data, field, :erlang.float_to_binary(value, decimals: 2))
      _ -> data
    end
  end

  defp format_date(data, field) when is_list(field) do
    case get_in(data, field) do
      nil ->
        data

      date ->
        value =
          date
          |> Timex.parse!("%Y-%m-%d", :strftime)
          |> Timex.format!("%d.%m.%Y", :strftime)

        put_in(data, field, value)
    end
  end

  defp prepare_employee(employee) do
    party = Map.get(employee, :party) || %{}
    %{"party" => Map.take(party, ~w(first_name last_name second_name)a)}
  end

  defp prepare_contractor_legal_entity(data, references, dictionaries) do
    contractor_legal_entity = Map.get(references.legal_entity, Map.get(data, "contractor_legal_entity_id")) || %{}

    address =
      contractor_legal_entity
      |> Map.get(:addresses, [])
      |> Enum.find(fn address -> Map.get(address, "type") == "REGISTRATION" end)
      |> translate_address(dictionaries)

    contractor_legal_entity
    |> Map.take(~w(edrpou name)a)
    |> Map.put(:address, address)
  end

  defp prepare_contractor_divisions(data, references, dictionaries) do
    contractor_divisions = Map.get(data, "contractor_divisions") || []

    Enum.map(contractor_divisions, fn division_id ->
      division = Map.get(references.division, division_id) || %{}

      address =
        division
        |> Map.get(:addresses, [])
        |> Enum.find(fn address -> Map.get(address, :type) == "RESIDENCE" end)
        |> translate_address(dictionaries)

      phones = Map.get(division, :phones) || []
      phone = List.first(phones) || %{}

      division
      |> Map.take(~w(id name email mountain_group working_hours)a)
      |> translate_working_hours()
      |> Map.put(:address, address)
      |> Map.put(:phone, phone)
    end)
  end

  defp translate_working_hours(%{working_hours: working_hours} = division) when is_map(working_hours) do
    translations =
      Enum.reduce(@working_hours, [], fn {key, value}, acc ->
        case Map.get(working_hours, to_string(key)) do
          nil ->
            acc

          schedule ->
            acc ++ [%{name: value, schedule: schedule}]
        end
      end)

    %{division | working_hours: translations}
  end

  defp translate_working_hours(division), do: division

  defp translate_address(nil, _), do: nil

  defp translate_address(%{__struct__: _} = address, dictionaries) do
    address
    |> Jason.encode!()
    |> Jason.decode!()
    |> translate_address(dictionaries)
  end

  defp translate_address(address, dictionaries) do
    %Dictionary{values: values} = Enum.find(dictionaries, fn %Dictionary{name: name} -> name == "STREET_TYPE" end)
    street_type_key = Map.get(address, "street_type")
    street_type = values[street_type_key]

    %Dictionary{values: values} = Enum.find(dictionaries, fn %Dictionary{name: name} -> name == "SETTLEMENT_TYPE" end)
    settlement_type_key = Map.get(address, "settlement_type")
    settlement_type = values[settlement_type_key]

    address
    |> Map.merge(%{
      "street_type" => street_type,
      "settlement_type" => settlement_type
    })
  end

  defp prepare_contractor_employee_divisions(data, references, dictionaries) do
    contractor_employee_divisions = Map.get(data, "contractor_employee_divisions") || []

    Enum.map(contractor_employee_divisions, fn contractor_employee_division ->
      employee = Map.get(references.employee, contractor_employee_division["employee_id"]) || %{}
      party = Map.get(employee, :party) || %{}
      party = Map.take(party, ~w(first_name last_name second_name)a)

      employee =
        employee
        |> Map.take(~w(id speciality)a)
        |> translate_speciality(dictionaries)
        |> Map.put(:party, party)

      contractor_employee_division
      |> Map.take(~w(division_id staff_units declaration_limit))
      |> Map.put("employee", employee)
    end)
  end

  defp translate_speciality(%{speciality: speciality} = params, dictionaries) do
    %Dictionary{values: values} = Enum.find(dictionaries, fn %Dictionary{name: name} -> name == "SPECIALITY_TYPE" end)
    speciality_value = Map.get(speciality, "speciality")
    translated_speciality = Map.get(values, speciality_value)
    Map.put(params, :speciality, Map.put(speciality, "speciality", translated_speciality))
  end

  defp prepare_external_contractors(data, references, dictionaries) do
    external_contractors = Map.get(data, "external_contractors") || []

    Enum.map(external_contractors, fn external_contractor ->
      legal_entity = Map.get(references.legal_entity, external_contractor["legal_entity_id"]) || %{}
      legal_entity = Map.take(legal_entity, ~w(id name)a)
      divisions = Enum.map(external_contractor["divisions"], &translate_medical_service(&1, dictionaries))

      external_contractor
      |> Map.take(~w(contract))
      |> Map.put("divisions", divisions)
      |> format_date(~w(contract expires_at))
      |> format_date(~w(contract issued_at))
      |> Map.put("legal_entity", legal_entity)
    end)
  end

  defp translate_medical_service(%{"medical_service" => medical_service} = division, dictionaries) do
    %Dictionary{values: values} = Enum.find(dictionaries, fn %Dictionary{name: name} -> name == "MEDICAL_SERVICE" end)
    translated_medical_service = Map.get(values, medical_service)
    Map.put(division, "medical_service", translated_medical_service)
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

defmodule EHealth.Man.Templates.DeclarationRequestPrintoutForm do
  @moduledoc false

  alias EHealth.API.Man
  alias EHealth.Utils.AddressMerger
  alias EHealth.Dictionaries

  use Confex, otp_app: :ehealth

  def render(declaration_request, authentication_method_current) do
    template_data =
      declaration_request
      |> map_declaration_data(authentication_method_current)
      |> Map.put(:format, config()[:format])
      |> Map.put(:locale, config()[:locale])

    template_id = config()[:id]

    Man.render_template(template_id, template_data)
  end

  defp map_declaration_data(nil, _), do: %{}
  defp map_declaration_data(declaration_request, authentication_method_current) do
    %{
      person: get_person(declaration_request),
      employee: get_employee(declaration_request),
      division: get_division(declaration_request),
      legal_entity: get_legal_entity(declaration_request),
      confidant_persons: check_confidant_persons(declaration_request),
      authentication_method_current: get_authentication_method_current(authentication_method_current),
      declaration_id: Map.get(declaration_request, "declaration_id")
    }
  end

  defp get_person(declaration_request) do
    person = Map.get(declaration_request, "person", %{})

    %{
      full_name: get_full_name(person),
      gender: get_gender(person),
      birth_date: Map.get(person, "birth_date"),
      document: get_document(person, "documents"),
      birth_settlement: Map.get(person, "birth_settlement"),
      birth_country: Map.get(person, "birth_country"),
      tax_id: Map.get(person, "tax_id"),
      addresses: get_person_addresses(person),
      phones: get_phone(person),
      email: Map.get(person, "email"),
      secret: Map.get(person, "secret"),
      emergency_contact: get_emergency_contact(person),
      confidant_person: get_confidant_persons(person)
    }
  end

  defp get_full_name(data) do
    first_name =
      data
      |> Map.get("first_name")
      |> to_string()
      |> get_listed_value()

    second_name =
      data
      |> Map.get("second_name")
      |> to_string()
      |> get_listed_value()

    last_name =
      data
      |> Map.get("last_name")
      |> to_string()
      |> get_listed_value()

    []
    |> Kernel.++(first_name)
    |> Kernel.++(second_name)
    |> Kernel.++(last_name)
    |> Enum.join(" ")
  end

  defp get_gender(data) do
    gender = %{
      male: false,
      female: false
    }

    case Map.get(data, "gender") do
      "MALE" -> Map.put(gender, :male, true)
      "FEMALE" -> Map.put(gender, :female, true)
      _ -> gender
    end
  end

  defp get_document(data, key) do
    documents = Map.get(data, key)
    case is_list(documents) do
      true -> documents |> List.first() |> take_fields(["type", "number"]) |> update_document_type()
      _ -> nil
    end
  end

  defp update_document_type(document) do
    Map.update!(document, "type", fn(type) -> Dictionaries.get_dictionary_value(type, "DOCUMENT_TYPE") end)
  end

  defp get_person_addresses(person) do
    addresses = Map.get(person, "addresses", [])
    registration_address = Enum.find(addresses, fn(address) -> Map.get(address, "type") == "REGISTRATION" end)
    residence_address = Enum.find(addresses, fn(address) -> Map.get(address, "type") == "RESIDENCE" end)

    full_registration_address = case registration_address do
      nil -> nil
      address -> AddressMerger.merge_address(address)
    end

    full_residence_address = case residence_address do
      nil -> nil
      address -> AddressMerger.merge_address(address)
    end

    %{
      registration: %{
        full_address: full_registration_address
      },
      residence: %{
        full_address: full_residence_address
      }
    }
  end

  defp get_phone(data) do
    phones = Map.get(data, "phones")
    case is_list(phones) do
      true -> phones |> List.first() |> take_fields(["number"])
      _ -> nil
    end
  end

  defp take_fields(data, fields) when is_map(data), do: Map.take(data, fields)
  defp take_fields(_, _), do: nil

  defp get_emergency_contact(person) do
    emergency_contact = Map.get(person, "emergency_contact", %{})

    %{
      full_name: get_full_name(emergency_contact),
      phones: get_phone(emergency_contact)
    }
  end

  defp get_confidant_persons(person) do
    confidant_persons = Map.get(person, "confidant_person", [])
    primary_confidant_person = Enum.find(confidant_persons, fn(x) -> Map.get(x, "relation_type") == "PRIMARY" end)
    secondary_confidant_person = Enum.find(confidant_persons, fn(x) -> Map.get(x, "relation_type") == "SECONDARY" end)

    primary = case primary_confidant_person do
      nil -> nil
      confidant_person -> get_confidant_person(confidant_person)
    end

    secondary = case secondary_confidant_person do
      nil -> nil
      confidant_person -> get_confidant_person(confidant_person)
    end

    %{
      primary: primary,
      secondary: secondary
    }
  end

  defp get_confidant_person(confidant_person) do
    %{
      full_name: get_full_name(confidant_person),
      phones: get_phone(confidant_person),
      birth_date: Map.get(confidant_person, "birth_date"),
      gender: get_gender(confidant_person),
      birth_settlement: Map.get(confidant_person, "birth_settlement"),
      birth_country: Map.get(confidant_person, "birth_country"),
      documents_person: get_document(confidant_person, "documents_person"),
      tax_id: Map.get(confidant_person, "tax_id"),
      documents_relationship: get_document(confidant_person, "documents_relationship")
    }
  end

  defp get_employee(declaration_request) do
    employee = Map.get(declaration_request, "employee", %{})
    party = Map.get(employee, "party", %{})

    %{
      full_name: get_full_name(party),
      phones: get_phone(party),
      email: Map.get(party, "email")
    }
  end

  defp get_division(declaration_request) do
    division = Map.get(declaration_request, "division", %{})

    %{
      addresses: get_division_addresses(division)
    }
  end

  defp get_division_addresses(division) do
    addresses = Map.get(division, "addresses", [])
    registration_address = Enum.find(addresses, fn(address) -> Map.get(address, "type") == "REGISTRATION" end)

    full_street = case registration_address do
      nil -> nil
      address -> address |> AddressMerger.merge_street_part() |> List.first()
    end

    settlement = case registration_address do
      nil -> nil
      address -> address |> AddressMerger.merge_settlement_part(full_street) |> List.first()
    end

    %{
      registration: %{
        full_street: full_street,
        settlement: settlement
      }
    }
  end

  defp get_legal_entity(declaration_request) do
    legal_entity = Map.get(declaration_request, "legal_entity", %{})

    %{
      full_name: Map.get(legal_entity, "public_name"),
      addresses: get_legal_entity_addresses(legal_entity),
      edrpou: Map.get(legal_entity, "edrpou"),
      full_license: get_full_license(legal_entity),
      phones: get_phone(legal_entity),
      email: Map.get(legal_entity, "email")
    }
  end

  defp get_legal_entity_addresses(legal_entity) do
    addresses = Map.get(legal_entity, "addresses", [])
    registration_address = Enum.find(addresses, fn(address) -> Map.get(address, "type") == "REGISTRATION" end)

    full_address = case registration_address do
      nil -> nil
      address -> AddressMerger.merge_address(address)
    end

    %{
      registration: %{
        full_address: full_address
      }
    }
  end

  defp get_full_license(legal_entity) do
    license = case get_in(legal_entity, ["medical_service_provider", "licenses"]) do
      [] = licenses -> List.first(licenses)
      _ -> %{}
    end

    license_number =
      license
      |> Map.get("license_number")
      |> to_string()
      |> get_listed_value()

    issued_data =
      license
      |> Map.get("issued_data")
      |> to_string()
      |> get_listed_value()

    []
    |> Kernel.++(license_number)
    |> Kernel.++(issued_data)
    |> Enum.join(", ")
  end

  defp check_confidant_persons(declaration_request) do
    person = Map.get(declaration_request, "person", %{})
    confidant_persons = Map.get(person, "confidant_person", [])
    secondary_confidant_person = Enum.find(confidant_persons, fn(x) -> Map.get(x, "relation_type") == "SECONDARY" end)

    %{
      exist: length(confidant_persons) > 0,
      secondary: secondary_confidant_person != nil
    }
  end

  defp get_authentication_method_current(data) do
    authentication_method_current = %{
      otp: false,
      offline: false
    }

    case Map.get(data, "type") do
      "OTP" -> Map.put(authentication_method_current, :otp, true)
      "OFFLINE" -> Map.put(authentication_method_current, :offline, true)
      _ -> authentication_method_current
    end
  end

  defp get_listed_value(""), do: []
  defp get_listed_value(license_number), do: [license_number]
end

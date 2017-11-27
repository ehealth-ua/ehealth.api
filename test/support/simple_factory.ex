defmodule EHealth.SimpleFactory do
  @moduledoc false

  alias Ecto.UUID
  alias EHealth.Repo
  alias EHealth.PRMRepo
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.DeclarationRequest

  defmacro fixture(module) do
    quote do
      module = unquote module
      case module do
        Request -> Request |> struct(employee_request()) |> Repo.insert!
        DeclarationRequest -> declaration_request()
        LegalEntity -> legal_entity() |> PRMRepo.insert!
      end
    end
  end

  defmacro fixture(module, params) do
    quote do
      module = unquote module
      params = unquote params
      case module do
        Request ->
          params =
            params
            |> set_email(Map.get(params, :email))
            |> set_employee_type(Map.get(params, :employee_type))
            |> set_legal_entity_id(Map.get(params, :legal_entity_id))
            |> Map.drop(~w(email employee_type legal_entity_id)a)
          Request
          |> struct(params)
          |> Repo.insert!
        LegalEntity ->
          module
          |> struct(params)
          |> PRMRepo.insert!
        _ ->
          module
          |> struct(params)
          |> Repo.insert!
      end
    end
  end

  def employee_request do
    attrs =
      "test/data/employee_doctor_request.json"
      |> File.read!()
      |> Poison.decode!()
      |> put_in(["employee_request", "legal_entity_id"], "8b797c23-ba47-45f2-bc0f-521013e01074")

    data = Map.fetch!(attrs, "employee_request")
    %{data: Map.delete(data, "status"), status: Map.fetch!(data, "status")}
 end

  def declaration_request do
    uuid = UUID.generate
    %DeclarationRequest{
      data: %{},
      status: "",
      inserted_by: uuid,
      updated_by: uuid,
      authentication_method_current: %{},
      printout_content: "",
      declaration_id: UUID.generate,
    }
    |> Repo.insert!()
  end

  def set_employee_type(data, nil), do: data
  def set_employee_type(data, employee_type) do
    Map.put(data, "employee_type", employee_type)
  end

  def set_email(data, nil), do: data
  def set_email(data, email), do: put_in(data, [:data, "party", "email"], email)

  def set_legal_entity_id(data, nil), do: data
  def set_legal_entity_id(data, id), do: put_in(data, [:data, "legal_entity_id"], id)

  def legal_entity do
    %LegalEntity{
      "is_active": true,
      "addresses": [%{
        "settlement_id" => UUID.generate()
      }],
      "inserted_by": "026a8ea0-2114-11e7-8fae-685b35cd61c2",
      "edrpou": rand_edrpou(),
      "email": "some email",
      "kveds": [],
      "legal_form": "P14",
      "name": "some name",
      "owner_property_type": "STATE",
      "phones": [%{}],
      "public_name": "some public_name",
      "short_name": "some short_name",
      "status": "ACTIVE",
      "mis_verified": "VERIFIED",
      "type": "MSP",
      "nhs_verified": false,
      "updated_by": "1729f790-2114-11e7-97f0-685b35cd61c2",
      "created_by_mis_client_id": "1729f790-2114-11e7-97f0-685b35cd61c2",
    }
  end

  def rand_edrpou do
    9999999
    |> :rand.uniform()
    |> Kernel.+(10000000)
    |> to_string()
  end

  def address(type) when type in ["RESIDENCE", "REGISTRATION", "NOT_IN_DICTIONARY"] do
    %{
      "type" => type,
      "country" => "UA",
      "area" => "Житомирська",
      "region" => "Бердичівський",
      "settlement" => "Київ",
      "settlement_type" => "CITY",
      "settlement_id" => "dsdafdf",
      "street" => "вул. Ніжинська",
      "building" => "15-В",
      "apartment" => "23",
      "zip" => "02090"
    }
  end
end

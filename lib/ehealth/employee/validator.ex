defmodule EHealth.Employee.Validator do
  @moduledoc """
  Request and Tax ID validators
  """

  use JValid

  alias EHealth.Validators.SchemaMapper
  alias EHealth.Validators.TaxID
  alias EHealth.Validators.BirthDate
  alias EHealth.PRM.Employees.Schema, as: Employee

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)

  use_schema :employee_request, "specs/json_schemas/new_employee_request_schema.json"
  use_schema :employee_doctor, "specs/json_schemas/employee_doctor_schema.json"
  use_schema :employee_pharmacist, "specs/json_schemas/employee_pharmacist_schema.json"

  def validate(params) do
    with :ok <- validate_employee_request(params),
         :ok <- validate_additional_info(params),
         :ok <- validate_tax_id(params),
         :ok <- validate_birth_date(params), do: :ok
  end

  defp validate_employee_request(content) do
    @schemas
    |> Keyword.get(:employee_request)
    |> SchemaMapper.prepare_employee_request_schema()
    |> validate_schema(content)
  end

  defp validate_additional_info(%{"employee_request" => %{"employee_type" => @doctor, "doctor" => data}}) do
    @schemas
    |> Keyword.get(:employee_doctor)
    |> SchemaMapper.prepare_employee_additional_info_schema()
    |> validate_schema(data)
  end
  defp validate_additional_info(%{"employee_request" => %{"employee_type" => @pharmacist, "pharmacist" => data}}) do
    @schemas
    |> Keyword.get(:employee_pharmacist)
    |> SchemaMapper.prepare_employee_additional_info_schema()
    |> validate_schema(data)
  end
  defp validate_additional_info(%{"employee_request" => %{"employee_type" => @doctor}}) do
    {:error, [{%{
      description: "required property doctor was not present",
      params: [],
      rule: :required
    }, "$.employee_request.doctor"}]}
  end
  defp validate_additional_info(%{"employee_request" => %{"employee_type" => @pharmacist}}) do
    {:error, [{%{
      description: "required property pharmacist was not present",
      params: [],
      rule: :required
    }, "$.employee_request.pharmacist"}]}
  end
  defp validate_additional_info(%{"employee_request" => %{"employee_type" => _, "doctor" => _}}) do
    {:error, [{%{
      description: "field doctor is not allowed",
      params: [],
      rule: :invalid
    }, "$.employee_request.doctor"}]}
  end
  defp validate_additional_info(%{"employee_request" => %{"employee_type" => _, "pharmacist" => _}}) do
    {:error, [{%{
      description: "field pharmacist is not allowed",
      params: [],
      rule: :invalid
    }, "$.employee_request.pharmacist"}]}
  end
  defp validate_additional_info(_), do: :ok

  defp validate_tax_id(content) do
    content
    |> get_in(~w(employee_request party tax_id))
    |> TaxID.validate()
    |> case do
         true -> :ok
         _ ->
          {:error, [{%{
            description: "invalid tax_id value",
            params: [],
            rule: :invalid
          }, "$.employee_request.party.tax_id"}]}
       end
  end

  defp validate_birth_date(content) do
    content
    |> get_in(~w(employee_request party birth_date))
    |> BirthDate.validate()
    |> case do
         true -> :ok
         _ ->
          {:error, [{%{
            description: "invalid birth_date value",
            params: [],
            rule: :invalid
          }, "$.employee_request.party.birth_date"}]}
       end
  end
end

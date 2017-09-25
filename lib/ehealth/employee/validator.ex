defmodule EHealth.Employee.Validator do
  @moduledoc """
  Request and Tax ID validators
  """

  alias EHealth.Validators.TaxID
  alias EHealth.Validators.BirthDate
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias EHealth.Validators.JsonSchema

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)

  def validate(params) do
    with :ok <- JsonSchema.validate(:employee_request, params),
         :ok <- validate_additional_info(Map.get(params, "employee_request")),
         :ok <- validate_tax_id(params),
         :ok <- validate_birth_date(params), do: :ok
  end

  defp validate_additional_info(%{"employee_type" => @doctor, "doctor" => data}) do
    JsonSchema.validate(:employee_doctor, data)
  end
  defp validate_additional_info(%{"employee_type" => @pharmacist, "pharmacist" => data}) do
    JsonSchema.validate(:employee_pharmacist, data)
  end
  defp validate_additional_info(%{"employee_type" => @doctor}) do
    {:error, [{%{
      description: "required property doctor was not present",
      params: [],
      rule: :required
    }, "$.employee_request.doctor"}]}
  end
  defp validate_additional_info(%{"employee_type" => @pharmacist}) do
    {:error, [{%{
      description: "required property pharmacist was not present",
      params: [],
      rule: :required
    }, "$.employee_request.pharmacist"}]}
  end
  defp validate_additional_info(%{"employee_type" => _, "doctor" => _}) do
    {:error, [{%{
      description: "field doctor is not allowed",
      params: [],
      rule: :invalid
    }, "$.employee_request.doctor"}]}
  end
  defp validate_additional_info(%{"employee_type" => _, "pharmacist" => _}) do
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

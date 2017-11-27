defmodule EHealth.EmployeeRequests.Validator do
  @moduledoc """
  Request and Tax ID validators
  """

  alias EHealth.Validators.TaxID
  alias EHealth.Validators.BirthDate
  alias EHealth.Employees.Employee
  alias EHealth.Validators.JsonSchema
  alias EHealth.Validators.JsonObjects
  alias EHealth.Dictionaries

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)
  @validation_dictionaries ["DOCUMENT_TYPE", "PHONE_TYPE"]

  def validate(params) do
    with :ok <- JsonSchema.validate(:employee_request, params),
    :ok <- validate_additional_info(Map.get(params, "employee_request")),
    :ok <- validate_json_objects(params),
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

  defp validate_json_objects(params) do
    dict_keys = Dictionaries.get_dictionaries_keys(@validation_dictionaries)

    with %{"DOCUMENT_TYPE" => doc_types} = dict_keys,
         docs_path = ["employee_request", "party", "documents"],
         :ok <- validate_non_req_parameteter(params, docs_path, "type", doc_types),
         %{"PHONE_TYPE" => phone_types} = dict_keys,
         ph_path = ["employee_request", "party", "phones"],
         :ok <- validate_non_req_parameteter(params, ph_path, "type", phone_types),
    do:  :ok
  end

  defp validate_non_req_parameteter(params, path, key_name, valid_types) do
    elements = get_in(params, path)
    if elements != nil and elements != [] do
      JsonObjects.array_unique_by_key(params, path, key_name, valid_types)
    else
      :ok
    end
  end

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

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
         :ok <- validate_birth_date(params),
         do: :ok
  end

  defp validate_additional_info(%{"employee_type" => @doctor, "doctor" => data}) do
    validate_additional_info(data, String.downcase(@doctor))
  end

  defp validate_additional_info(%{"employee_type" => @pharmacist, "pharmacist" => data}) do
    validate_additional_info(data, String.downcase(@pharmacist))
  end

  defp validate_additional_info(%{"employee_type" => @doctor}) do
    cast_error("required property doctor was not present", "$.employee_request.doctor", :required)
  end

  defp validate_additional_info(%{"employee_type" => @pharmacist}) do
    cast_error("required property pharmacist was not present", "$.employee_request.pharmacist", :required)
  end

  defp validate_additional_info(%{"employee_type" => _, "doctor" => _}) do
    cast_error("field doctor is not allowed", "$.employee_request.doctor", :invalid)
  end

  defp validate_additional_info(%{"employee_type" => _, "pharmacist" => _}) do
    cast_error("field pharmacist is not allowed", "$.employee_request.pharmacist", :invalid)
  end

  defp validate_additional_info(_), do: :ok

  defp validate_additional_info(additional_info, employee_type) do
    json_schema = String.to_atom("employee_#{employee_type}")

    with :ok <- JsonSchema.validate(json_schema, additional_info),
         {:ok, speciality} <- validate_and_fetch_speciality_officio(additional_info["specialities"]),
         :ok <- validate_speciality(speciality, employee_type) do
      :ok
    else
      {:error, message} when is_binary(message) ->
        cast_error(message, "$.employee_request.#{employee_type}.specialities", :invalid)

      err ->
        err
    end
  end

  defp validate_and_fetch_speciality_officio(specialities) do
    case Enum.filter(specialities, fn speciality -> Map.get(speciality, "speciality_officio") end) do
      [speciality] -> {:ok, speciality}
      [] -> {:error, "employee doesn't have speciality with active speciality_officio"}
      _ -> {:error, "employee have more than one speciality with active speciality_officio"}
    end
  end

  defp validate_speciality(speciality, employee_type) do
    allowed_specialities = Confex.fetch_env!(:ehealth, :employee_specialities_types)[String.to_atom(employee_type)]

    case speciality["speciality"] in allowed_specialities do
      true -> :ok
      _ -> {:error, "speciality with active speciality_officio is not allowed for #{employee_type}"}
    end
  end

  defp validate_json_objects(params) do
    dict_keys = Dictionaries.get_dictionaries_keys(@validation_dictionaries)

    with %{"DOCUMENT_TYPE" => doc_types} = dict_keys,
         docs_path = ["employee_request", "party", "documents"],
         :ok <- validate_non_req_parameteter(params, docs_path, "type", doc_types),
         %{"PHONE_TYPE" => phone_types} = dict_keys,
         ph_path = ["employee_request", "party", "phones"],
         :ok <- validate_non_req_parameteter(params, ph_path, "type", phone_types),
         do: :ok
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
    no_tax_id = get_in(content, ~w(employee_request party no_tax_id))

    content
    |> get_in(~w(employee_request party tax_id))
    |> TaxID.validate(no_tax_id)
    |> case do
      true -> :ok
      _ -> cast_error("invalid tax_id value", "$.employee_request.party.tax_id", :invalid)
    end
  end

  defp validate_birth_date(content) do
    content
    |> get_in(~w(employee_request party birth_date))
    |> BirthDate.validate()
    |> case do
      true -> :ok
      _ -> cast_error("invalid birth_date value", "$.employee_request.party.birth_date", :invalid)
    end
  end

  defp cast_error(message, path, rule) do
    {:error,
     [
       {%{
          description: message,
          params: [],
          rule: rule
        }, path}
     ]}
  end
end

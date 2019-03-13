defmodule Core.EmployeeRequests.Validator do
  @moduledoc """
  Request and Tax ID validators
  """

  alias Core.Email.Sanitizer
  alias Core.Employees.Employee
  alias Core.ValidationError
  alias Core.Validators.BirthDate
  alias Core.Validators.Error
  alias Core.Validators.JsonObjects
  alias Core.Validators.JsonSchema
  alias Core.Validators.TaxID

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)

  def validate(params) do
    with :ok <- JsonSchema.validate(:employee_request, params),
         params <- lowercase_email(params),
         :ok <- validate_additional_info(Map.get(params, "employee_request")),
         :ok <- validate_json_objects(params),
         :ok <- validate_tax_id(params),
         :ok <- validate_birth_date(params),
         do: {:ok, params}
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
         {_, {:ok, speciality}} <-
           {:speciality, validate_and_fetch_speciality_officio(additional_info["specialities"])},
         {_, :ok} <- {:education, validate_education_degree(additional_info["educations"], employee_type)},
         {_, :ok} <- {:qualification, validate_qualification_type(additional_info["qualifications"], employee_type)},
         {_, :ok} <- {:speciality, validate_speciality_type(speciality, employee_type)},
         {_, :ok} <- {:speciality, validate_speciality_level(speciality, employee_type)} do
      :ok
    else
      {:speciality, {:error, message}} when is_binary(message) ->
        cast_error(message, "$.employee_request.#{employee_type}.specialities", :invalid)

      {:education, {:error, message}} when is_binary(message) ->
        cast_error(message, "$.employee_request.#{employee_type}.educations", :invalid)

      {:qualification, {:error, message}} when is_binary(message) ->
        cast_error(message, "$.employee_request.#{employee_type}.qualifications", :invalid)

      err ->
        err
    end
  end

  defp validate_education_degree(educations, employee_type) do
    allowed_degrees = Confex.fetch_env!(:core, :employee_education_degrees)[String.to_atom(employee_type)]

    Enum.reduce_while(educations, :ok, fn education, _ ->
      degree = education["degree"]

      case degree in allowed_degrees do
        true -> {:cont, :ok}
        _ -> {:halt, {:error, "education degree #{degree} is not allowed for #{employee_type}"}}
      end
    end)
  end

  defp validate_qualification_type(nil, _), do: :ok

  defp validate_qualification_type(qualifications, employee_type) do
    allowed_types = Confex.fetch_env!(:core, :employee_qualification_types)[String.to_atom(employee_type)]

    Enum.reduce_while(qualifications, :ok, fn qualification, _ ->
      type = qualification["type"]

      case type in allowed_types do
        true -> {:cont, :ok}
        _ -> {:halt, {:error, "qualification type #{type} is not allowed for #{employee_type}"}}
      end
    end)
  end

  defp validate_and_fetch_speciality_officio(specialities) do
    case Enum.filter(specialities, fn speciality -> Map.get(speciality, "speciality_officio") end) do
      [speciality] -> {:ok, speciality}
      [] -> {:error, "employee doesn't have speciality with active speciality_officio"}
      _ -> {:error, "employee have more than one speciality with active speciality_officio"}
    end
  end

  defp validate_speciality_type(%{"speciality" => speciality}, employee_type) do
    allowed_specialities = Confex.fetch_env!(:core, :employee_speciality_types)[String.to_atom(employee_type)]

    case speciality in allowed_specialities do
      true -> :ok
      _ -> {:error, "speciality #{speciality} with active speciality_officio is not allowed for #{employee_type}"}
    end
  end

  defp validate_speciality_level(%{"level" => level}, employee_type) do
    allowed_levels = Confex.fetch_env!(:core, :employee_speciality_levels)[String.to_atom(employee_type)]

    case level in allowed_levels do
      true -> :ok
      _ -> {:error, "speciality level #{level} with active speciality_officio is not allowed for #{employee_type}"}
    end
  end

  defp validate_json_objects(params) do
    with :ok <- validate_non_req_parameteter(params, ~w(employee_request party documents), "type"),
         :ok <- validate_non_req_parameteter(params, ~w(employee_request party phones), "type"),
         do: :ok
  end

  defp validate_non_req_parameteter(params, path, key_name) do
    elements = get_in(params, path)

    if elements != nil and elements != [] do
      JsonObjects.array_unique_by_key(params, path, key_name)
    else
      :ok
    end
  end

  defp validate_tax_id(content) do
    no_tax_id = get_in(content, ~w(employee_request party no_tax_id))

    content
    |> get_in(~w(employee_request party tax_id))
    |> TaxID.validate(no_tax_id, %ValidationError{
      description: "invalid tax_id value",
      path: "$.employee_request.party.tax_id"
    })
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
    Error.dump(%ValidationError{description: message, path: path, rule: rule})
  end

  defp lowercase_email(params) do
    path = ~w(employee_request party email)
    email = get_in(params, path)
    put_in(params, path, Sanitizer.sanitize(email))
  end
end

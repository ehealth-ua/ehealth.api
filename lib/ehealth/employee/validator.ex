defmodule EHealth.Employee.Validator do
  @moduledoc """
  Request and Tax ID validators
  """

  use JValid

  alias EHealth.Utils.ValidationSchemaMapper
  alias EHealth.Utils.TaxIDValidator

  use_schema :employee_request, "specs/json_schemas/new_employee_request_schema.json"

  def validate(params) do
    params
    |> validate_employee_request()
    |> validate_tax_id()
  end

  # Employee request validator

  def validate_employee_request(content) do
    schema =
      @schemas
      |> Keyword.get(:employee_request)
      |> ValidationSchemaMapper.prepare_employee_request_schema()

    case validate_schema(schema, content) do
      :ok -> {:ok, content}
      err -> err
    end
  end

  # Tax ID validator

  def validate_tax_id({:ok, content}) do
    content
    |> get_in(["employee_request", "party", "tax_id"])
    |> TaxIDValidator.validate()
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

  def validate_tax_id(err), do: err
end

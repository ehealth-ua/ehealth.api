defmodule EHealth.Employee.Validator do
  @moduledoc """
  Request and Tax ID validators
  """

  use JValid

  alias EHealth.Validators.SchemaMapper
  alias EHealth.Validators.TaxID

  use_schema :employee_request, "specs/json_schemas/new_employee_request_schema.json"

  def validate(params) do
    params
    |> validate_employee_request()
    |> validate_doctor_inclusion()
    |> validate_tax_id()
  end

  # Employee request validator

  def validate_employee_request(content) do
    schema =
      @schemas
      |> Keyword.get(:employee_request)
      |> SchemaMapper.prepare_employee_request_schema()

    case validate_schema(schema, content) do
      :ok -> {:ok, content}
      err -> err
    end
  end

  def validate_doctor_inclusion({:ok, %{"employee_request" => %{"employee_type" => employee_type, "doctor" => _}}})
    when employee_type != "DOCTOR" do
    {:error, [{%{
      description: "field doctor is not allowed",
      params: [],
      rule: :invalid
    }, "$.employee_request.doctor"}]}
  end
  def validate_doctor_inclusion(changeset), do: changeset

  # Tax ID validator

  def validate_tax_id({:ok, content}) do
    content
    |> get_in(["employee_request", "party", "tax_id"])
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

  def validate_tax_id(err), do: err
end

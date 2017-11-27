defmodule EHealth.Validators.Reference do
  @moduledoc """
  Validates reference existance
  """

  alias EHealth.API.OPS
  alias EHealth.Divisions
  alias EHealth.Divisions.Division
  alias EHealth.Employees
  alias EHealth.Employees.Employee
  alias EHealth.LegalEntities
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.MedicalPrograms
  alias EHealth.MedicalPrograms.MedicalProgram
  alias EHealth.Medications
  alias EHealth.Medications.Medication

  def validate(type, nil) do
    error(type)
  end
  def validate(:medication_request = type, id) do
    with {:ok, %{"data" => [medication_request]}} <- OPS.get_medication_requests(%{"id" => id}) do
      {:ok, medication_request}
    else
      _ -> error(type)
    end
  end
  def validate(:employee = type, id) do
    with %Employee{} = employee <- Employees.get_by_id(id) do
      {:ok, employee}
    else
      _ -> error(type)
    end
  end
  def validate(:division = type, id) do
    with %Division{} = division <- Divisions.get_by_id(id) do
      {:ok, division}
    else
      _ -> error(type)
    end
  end
  def validate(:medical_program = type, id) do
    with %MedicalProgram{} = medical_program <- MedicalPrograms.get_by_id(id) do
      {:ok, medical_program}
    else
      _ -> error(type)
    end
  end
  def validate(:legal_entity = type, id) do
    with %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(id) do
      {:ok, legal_entity}
    else
      _ -> error(type)
    end
  end
  def validate(:medication = type, id, path \\ nil) do
    with %Medication{} = medication <- Medications.get_medication_by_id(id) do
      {:ok, medication}
    else
      _ -> error(type, path)
    end
  end

  defp error(type, path \\ nil) when is_atom(type) do
    description =
      type
      |> to_string()
      |> String.capitalize
      |> String.replace("_", " ")
    path = path || "$.#{type}_id"
    {:error, [{%{
      description: "#{description} not found",
      params: [],
      rule: :invalid
    }, path}]}
  end
end

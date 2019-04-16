defmodule Core.Validators.Reference do
  @moduledoc """
  Validates reference existance
  """

  alias Core.CapitationContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Divisions
  alias Core.Divisions.Division
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.MedicalPrograms
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Medications
  alias Core.Medications.Medication
  alias Core.Persons
  alias Core.ReimbursementContractRequests
  alias Core.ValidationError
  alias Core.Validators.Error

  @ops_api Application.get_env(:core, :api_resolvers)[:ops]

  def validate(type, nil) do
    error(type)
  end

  def validate(type, id), do: validate(type, id, nil)

  def validate(:medication_request = type, id, path) do
    with {:ok, %{"data" => [medication_request]}} <- @ops_api.get_medication_requests(%{"id" => id}, []) do
      {:ok, medication_request}
    else
      _ -> error(type, path)
    end
  end

  def validate(:employee = type, id, path) do
    with %Employee{} = employee <- Employees.get_by_id(id) do
      {:ok, employee}
    else
      _ -> error(type, path)
    end
  end

  def validate(:division = type, id, path) do
    with %Division{} = division <- Divisions.get_by_id(id),
         {:status, true} <- {:status, division.status == Division.status(:active)} do
      {:ok, division}
    else
      {:status, _} -> error_status(type, path)
      _ -> error(type, path)
    end
  end

  def validate(:medical_program = type, id, path) do
    with %MedicalProgram{} = medical_program <- MedicalPrograms.get_by_id(id) do
      {:ok, medical_program}
    else
      _ -> error(type, path)
    end
  end

  def validate(:legal_entity = type, id, path) do
    with %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(id),
         {:status, true} <- {:status, legal_entity.status == LegalEntity.status(:active)} do
      {:ok, legal_entity}
    else
      {:status, _} -> error_status(type, path)
      _ -> error(type, path)
    end
  end

  def validate(:person = type, id, path) do
    with {:ok, person} <- Persons.get_by_id(id) do
      {:ok, person}
    else
      _ -> error(type, path)
    end
  end

  def validate(:medication = type, id, path) do
    with %Medication{} = medication <- Medications.get_medication_by_id(id) do
      {:ok, medication}
    else
      _ -> error(type, path)
    end
  end

  # TODO: rename everywhere
  def validate(:contract_request = type, id, path) do
    with %CapitationContractRequest{} = contract_request <- CapitationContractRequests.get_by_id(id) do
      {:ok, contract_request}
    else
      _ -> error(type, path)
    end
  end

  def validate(:reimbursement_contract_request = type, id, path) do
    with %ReimbursementContractRequest{} = contract_request <- ReimbursementContractRequests.get_by_id(id) do
      {:ok, contract_request}
    else
      _ -> error(type, path)
    end
  end

  defp error(type, path \\ nil) when is_atom(type) do
    description =
      type
      |> to_string()
      |> String.capitalize()
      |> String.replace("_", " ")

    path = path || "$.#{type}_id"
    Error.dump(%ValidationError{description: "#{description} not found", path: path})
  end

  defp error_status(type, path) when is_atom(type) do
    description =
      type
      |> to_string()
      |> String.capitalize()
      |> String.replace("_", " ")

    path = path || "$.#{type}_id"
    Error.dump(%ValidationError{description: "#{description} is not active", path: path})
  end
end

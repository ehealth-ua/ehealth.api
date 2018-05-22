defmodule EHealth.Validators.Reference do
  @moduledoc """
  Validates reference existance
  """

  alias EHealth.{Divisions, Employees, LegalEntities, Medications, MedicalPrograms, ContractRequests}
  alias EHealth.Divisions.Division
  alias EHealth.ContractRequests.ContractRequest
  alias EHealth.Employees.Employee
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Medications.Medication
  alias EHealth.MedicalPrograms.MedicalProgram

  @ops_api Application.get_env(:ehealth, :api_resolvers)[:ops]
  @mpi_api Application.get_env(:ehealth, :api_resolvers)[:mpi]

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
    with {:ok, %{"data" => person}} <- @mpi_api.person(id, []) do
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

  def validate(:contract_request = type, id, path) do
    with %ContractRequest{} = contract_request <- ContractRequests.get_by_id(id) do
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

    {:error,
     [
       {%{
          description: "#{description} not found",
          params: [],
          rule: :invalid
        }, path}
     ]}
  end

  defp error_status(type, path) when is_atom(type) do
    description =
      type
      |> to_string()
      |> String.capitalize()
      |> String.replace("_", " ")

    path = path || "$.#{type}_id"

    {:error,
     [
       {%{
          description: "#{description} is not active",
          params: [],
          rule: :invalid
        }, path}
     ]}
  end
end

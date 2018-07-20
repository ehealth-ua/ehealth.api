defmodule EHealth.MedicationRequestRequest.SignOperation do
  @moduledoc false
  import EHealth.MedicationRequestRequest.OperationHelpers

  alias EHealth.API.MediaStorage
  alias EHealth.MedicationRequestRequest.Operation
  alias EHealth.MedicationRequestRequest.Validations
  alias EHealth.Utils.Connection

  @ops_api Application.get_env(:ehealth, :api_resolvers)[:ops]

  def sign(mrr, params, headers) do
    mrr
    |> Ecto.Changeset.change()
    |> Operation.new()
    |> validate_foreign_key(Connection.get_client_id(headers), &get_legal_entity/1, &put_legal_entity/2)
    |> validate_foreign_key(mrr.data.employee_id, &get_employee/1, &validate_employee/2, key: :employee)
    |> validate_foreign_key(mrr.data.person_id, &get_person/1, &validate_person/2, key: :person)
    |> validate_foreign_key(mrr.data.division_id, &get_division/1, &validate_division/2, key: :division)
    |> validate_foreign_key(mrr.data.medication_id, &get_medication/1, fn _, e -> {:ok, e} end, key: :medication)
    |> validate_foreign_key(
      mrr.data.medical_program_id,
      &get_medical_program/1,
      fn _, e -> {:ok, e} end,
      key: :medical_program
    )
    |> validate_data({params, headers}, &decode_sign_content/2, key: :decoded_content)
    |> validate_sign_content(mrr)
    |> upload_sign_content(params, mrr)
    |> create_medication_request(headers)
    |> validate_ops_resp(mrr)
  end

  def decode_sign_content(_operation, {params, headers}), do: Validations.decode_sign_content(params, headers)

  def validate_sign_content(operation, mrr) do
    {operation, Validations.validate_sign_content(mrr, operation.data.decoded_content)}
  end

  def upload_sign_content({operation, {:error, error}}, _, _), do: {operation, {:error, error}}

  def upload_sign_content({operation, {:ok, _content}}, params, mrr) do
    params
    |> Map.fetch!("signed_medication_request_request")
    |> MediaStorage.store_signed_content(
      :medication_request_request_bucket,
      Map.fetch!(mrr, :medication_request_id),
      "signed_content",
      []
    )
    |> validate_api_response(operation, mrr)
  end

  defp validate_api_response({:ok, _}, operation, db_data), do: {operation, {:ok, db_data}}
  defp validate_api_response(error, _operation, _db_data), do: error

  def create_medication_request({_operation, {:error, error}}, _), do: {:error, error}

  def create_medication_request({operation, {:ok, mrr}}, headers) do
    params =
      mrr.data
      |> Map.drop(~w(__struct__ __meta__)a)
      |> Map.put(:id, mrr.medication_request_id)
      |> Map.put(:medication_request_requests_id, mrr.id)
      |> Map.put(:request_number, mrr.request_number)
      |> Map.put(:verification_code, mrr.verification_code)
      |> Map.put(:updated_by, Connection.get_client_id(headers))
      |> Map.put(:inserted_by, Connection.get_client_id(headers))

    {operation, @ops_api.create_medication_request(%{medication_request: params}, headers)}
  end

  def validate_ops_resp({:error, error}, _), do: {:error, error}

  def validate_ops_resp({operation, {:ok, %{"data" => ops_resp}}}, mrr) do
    if ops_resp["id"] == mrr.medication_request_id do
      {Operation.add_data(operation, :medication_request, ops_resp), {:ok, mrr}}
    else
      {:error, %{"type" => "internal_error"}}
    end
  end

  def validate_ops_resp(_), do: {:error, %{"type" => "internal_error"}}
end

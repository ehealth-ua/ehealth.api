defmodule EHealth.MedicationRequestRequests do
  @moduledoc """
  The MedicationRequestRequests context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias EHealth.Repo

  use Confex, otp_app: :ehealth

  alias EHealth.PRM.MedicalPrograms
  alias EHealth.MedicationRequestRequest
  alias EHealth.MedicationRequestRequest.Operation
  alias EHealth.MedicationRequestRequest.Validations
  alias EHealth.MedicationRequestRequest.CreateDataOperation
  alias EHealth.MedicationRequestRequest.HumanReadableNumberGenerator, as: HRNGenerator

  @doc """
  Returns the list of medication_request_requests.

  ## Examples

      iex> list_medication_request_requests()
      [%MedicationRequestRequest{}, ...]

  """
  def list_medication_request_requests do
    Repo.all(MedicationRequestRequest)
  end

  def list_medication_request_requests(params) do
    query = from dr in MedicationRequestRequest,
    order_by: [desc: :inserted_at]

    query
    |> filter_by_employee_id(params)
    |> filter_by_legal_entity_id(params)
    |> filter_by_status(params)
    |> Repo.paginate(params)
  end

  defp filter_by_legal_entity_id(query, %{"legal_entity_id" => legal_entity_id}) do
    where(query, [r], fragment("?->'legal_entity_id' = ?", r.data, ^legal_entity_id))
  end
  defp filter_by_legal_entity_id(query, _), do: query

  defp filter_by_employee_id(query, %{"employee_id" => employee_id}) do
    where(query, [r], fragment("?->'employee_id' = ?", r.data, ^employee_id))
  end
  defp filter_by_employee_id(query, _), do: query

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end
  defp filter_by_status(query, _), do: query

  @doc """
  Gets a single medication_request_request.

  Raises `Ecto.NoResultsError` if the Medication request request does not exist.

  ## Examples

      iex> get_medication_request_request!(123)
      %MedicationRequestRequest{}

      iex> get_medication_request_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_medication_request_request!(id), do: Repo.get!(MedicationRequestRequest, id)

  @doc """
  Creates a medication_request_request.

  ## Examples

      iex> create(%{field: value})
      {:ok, %MedicationRequestRequest{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs, user_id, client_id) do
    with :ok <- Validations.validate_create_schema(attrs)
    do
      case %MedicationRequestRequest{}
           |> create_changeset(attrs, user_id, client_id)
           |> Repo.insert() do
        {:ok, inserted_entity} -> {:ok, inserted_entity}
        {:error, %Ecto.Changeset{errors: [number: {"has already been taken", []}]}} -> create(attrs, user_id, client_id)
        {:error, changeset} -> {:error, changeset}
      end
    else
      err -> err
    end
  end

  def prequalify(%{"medication_request_request" => mrr, "programs" => programs} = attrs, user_id, client_id) do
    with :ok <- Validations.validate_prequalify_schema(attrs)
    do
      with %Ecto.Changeset{valid?: true} =
        %MedicationRequestRequest{}
        |> create_changeset(mrr, user_id, client_id)
      do
        prequalify_programs(mrr["medication_id"], mrr["medication_qty"], programs)
      end
    else
      err -> err
    end
  end

  @doc false
  def create_changeset(%MedicationRequestRequest{} = medication_request_request, attrs, user_id, client_id) do
    create_operation = CreateDataOperation.create(attrs, client_id)
    medication_request_request
    |> cast(attrs, [:number, :status, :inserted_by, :updated_by])
    |> put_embed(:data, create_operation.changeset)
    |> put_change(:status, "NEW")
    |> put_change(:number, HRNGenerator.generate(1))
    |> put_change(:verification_code, put_verification_code(create_operation))
    |> put_change(:inserted_by, user_id)
    |> put_change(:updated_by, user_id)
    |> validate_required([:data, :number, :status, :inserted_by, :updated_by])
    |> unique_constraint(:number, name: :medication_request_requests_number_index)
  end

  defp put_verification_code(%Operation{valid?: true} = operation) do
    is_otp = Enum.filter(operation.data.person["authentication_methods"], fn method -> method["type"] == "OTP" end)
    if length(is_otp) > 0 do
      HRNGenerator.generate_otp_verification_code()
    else
      nil
    end
  end
  defp put_verification_code(_), do: nil

  def changeset(%MedicationRequestRequest{} = medication_request_request, attrs) do
    medication_request_request
    |> cast(attrs, [:data, :number, :status, :inserted_by, :updated_by])
    |> validate_required([:data, :number, :status, :inserted_by, :updated_by])
  end

  defp prequalify_programs(medication_id, medication_qty, programs) do
    programs
    |> Enum.map(fn %{"id" => program_id} ->
      %{id: program_id, data: Validations.validate_medication_id(medication_id, medication_qty, program_id)}
    end)
    |> Enum.map(fn validated_result -> show_program_status(validated_result) end)
  end

  defp show_program_status(%{id: _id, data: {:ok, result}}) do
    result
    |> Enum.at(0)
    |> Map.put(:status, "VALID")
  end
  defp show_program_status(%{id: id, data: _err}) do
    mp = MedicalPrograms.get_by_id(id)
    %{medical_program_id: mp.id, medical_program_name: mp.name, status: "INVALID"}
  end
end

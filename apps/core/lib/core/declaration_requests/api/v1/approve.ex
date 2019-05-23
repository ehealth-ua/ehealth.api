defmodule Core.DeclarationRequests.API.Approve do
  @moduledoc false

  import Ecto.Query

  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.Parties.Party
  alias Core.Validators.Error
  require Logger

  @rpc_worker Application.get_env(:core, :rpc_worker)
  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]
  @ops_api Application.get_env(:core, :api_resolvers)[:ops]
  @auth_otp DeclarationRequest.authentication_method(:otp)
  @read_repo Application.get_env(:core, :repos)[:read_repo]

  def verify(declaration_request, code, headers) do
    with {:ok, _} <- verify_auth(declaration_request, code),
         {:ok, _} <- check_documents(declaration_request.documents, declaration_request.id, {:ok, true}),
         :ok <- validate_declaration_limit(declaration_request, headers) do
      {:ok, true}
    end
  end

  def verify(declaration_request, headers) do
    with {:ok, _} <- check_documents(declaration_request.documents, declaration_request.id, {:ok, true}),
         :ok <- validate_declaration_limit(declaration_request, headers) do
      {:ok, true}
    end
  end

  def verify_auth(%{authentication_method_current: %{"type" => @auth_otp, "number" => phone}}, code) do
    case @rpc_worker.run("otp_verification_api", OtpVerification.Rpc, :complete, [phone, code]) do
      {:ok, _verification} = result -> result
      nil -> {:error, {:not_found, "Verification not found"}}
      error -> error
    end
  end

  def verify_auth(_, _), do: {:ok, true}

  def check_documents([document | tail], declaration_request_id, acc) do
    case uploaded?(declaration_request_id, document) do
      # document is succesfully uploaded
      {:ok, true} ->
        check_documents(tail, declaration_request_id, acc)

      # document not found
      {:error, {:not_uploaded, document_type}} ->
        check_documents(tail, declaration_request_id, put_document_error(acc, document_type))

      # ael bad response
      {:error, {:ael_bad_response, _}} = err ->
        err
    end
  end

  def check_documents(_, _declaration_request_id, acc), do: acc

  def uploaded?(id, %{"type" => type}) do
    resource_name = "declaration_request_#{type}.jpeg"
    bucket = Confex.fetch_env!(:core, Core.API.MediaStorage)[:declaration_request_bucket]

    {:ok, %{secret_url: url} = result} = @media_storage_api.create_signed_url("HEAD", bucket, resource_name, id)

    Logger.info("Microservice ael response: #{inspect(result)}")

    case @media_storage_api.verify_uploaded_file(url, resource_name) do
      {:ok, resp} ->
        case resp do
          %HTTPoison.Response{status_code: 200} ->
            {:ok, true}

          _ ->
            {:error, {:not_uploaded, type}}
        end

      {:error, reason} ->
        Logger.info("Microservice ael response: #{reason}")
        {:error, {:ael_bad_response, reason}}
    end
  end

  def put_document_error({:ok, true}, doc_type) do
    {:error, {:documents_not_uploaded, [doc_type]}}
  end

  def put_document_error({:error, {:documents_not_uploaded, container}}, doc_type) do
    {:error, {:documents_not_uploaded, container ++ [doc_type]}}
  end

  defp validate_declaration_limit(%DeclarationRequest{overlimit: true}, _), do: :ok

  defp validate_declaration_limit(
         %DeclarationRequest{
           data: %{"employee" => %{"id" => employee_id}},
           mpi_id: person_id
         },
         headers
       ) do
    with %Employee{party: %Party{} = party} <- Employees.get_by_id(employee_id),
         employees <- Employees.get_active_by_party_id(party.id),
         employee_ids <- Enum.map(employees, &Map.get(&1, :id)),
         declarations_request_count <-
           get_declarations_requests_count(DeclarationRequest.status(:approved), employee_ids),
         {:ok, %{"data" => %{"count" => declarations_count}}} <-
           @ops_api.get_declarations_count(%{"ids" => employee_ids, "exclude_person_id" => person_id}, headers),
         declaration_limit <- get_declaration_limit(employees),
         {:limit, _, true} <-
           {:limit, declarations_count + declarations_request_count,
            declarations_count + declarations_request_count < declaration_limit} do
      :ok
    else
      {:limit, declaration_count, _} ->
        Error.dump("This doctor has #{declaration_count} declarations and could not sign more")

      _ ->
        {:error, {:conflict, "employee or party not found"}}
    end
  end

  def get_declarations_requests_count(status, employee_ids) do
    DeclarationRequest
    |> select([dr], count(dr.id))
    |> where(
      [dr],
      dr.status == ^status and dr.data_employee_id in ^employee_ids
    )
    |> @read_repo.one()
  end

  defp get_declaration_limit(employees) do
    config = Confex.fetch_env!(:core, :employee_speciality_limits)

    employees
    |> Enum.filter(fn employee -> employee.employee_type == Employee.type(:doctor) end)
    |> Enum.map(fn employee ->
      case employee.speciality["speciality"] do
        "THERAPIST" ->
          config[:therapist_declaration_limit]

        "PEDIATRICIAN" ->
          config[:pediatrician_declaration_limit]

        "FAMILY_DOCTOR" ->
          config[:family_doctor_declaration_limit]
      end
    end)
    |> Enum.min(fn -> 0 end)
  end
end

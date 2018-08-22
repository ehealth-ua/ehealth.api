defmodule Core.DeclarationRequests.API.Approve do
  @moduledoc false

  import Ecto.Query

  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.Parties.Party
  alias Core.Repo
  alias Core.Validators.Error
  require Logger

  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]
  @otp_verification_api Application.get_env(:core, :api_resolvers)[:otp_verification]
  @ops_api Application.get_env(:core, :api_resolvers)[:ops]
  @auth_otp DeclarationRequest.authentication_method(:otp)

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
    @otp_verification_api.complete(phone, %{code: code}, [])
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

    {:ok, %{"data" => %{"secret_url" => url}} = result} =
      @media_storage_api.create_signed_url("HEAD", bucket, resource_name, id, [])

    Logger.info(fn ->
      Jason.encode!(%{
        "log_type" => "microservice_response",
        "microservice" => "ael",
        "result" => result,
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    case @media_storage_api.verify_uploaded_file(url, resource_name) do
      {:ok, resp} ->
        case resp do
          %HTTPoison.Response{status_code: 200} ->
            {:ok, true}

          _ ->
            {:error, {:not_uploaded, type}}
        end

      {:error, reason} ->
        Logger.info(fn ->
          Jason.encode!(%{
            "log_type" => "microservice_response",
            "microservice" => "ael",
            "result" => reason,
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

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
           data: %{"employee" => %{"id" => employee_id}}
         },
         headers
       ) do
    with %Employee{party: %Party{} = party} <- Employees.get_by_id(employee_id),
         employees <- Employees.get_active_by_party_id(party.id),
         employee_ids <- Enum.map(employees, &Map.get(&1, :id)),
         declarations_request_count <-
           get_declarations_requests_count(DeclarationRequest.status(:approved), employee_ids),
         {:ok, %{"data" => %{"count" => declarations_count}}} <- @ops_api.get_declarations_count(employee_ids, headers),
         {:limit, true} <-
           {:limit,
            !party.declaration_limit || declarations_count + declarations_request_count < party.declaration_limit} do
      :ok
    else
      {:limit, false} -> Error.dump("This doctor reaches his limit and could not sign more declarations")
      _ -> {:error, {:conflict, "employee or party not found"}}
    end
  end

  def get_declarations_requests_count(status, employee_ids) do
    DeclarationRequest
    |> select([dr], count(dr.id))
    |> where(
      [dr],
      dr.status == ^status and fragment("?->'employee'->>'id'", dr.data) in ^employee_ids
    )
    |> Repo.one()
  end
end

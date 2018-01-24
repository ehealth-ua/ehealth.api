defmodule EHealth.DeclarationRequest.API.Approve do
  @moduledoc false

  alias EHealth.API.MediaStorage
  alias EHealth.API.OTPVerification
  alias EHealth.DeclarationRequest
  require Logger

  @auth_otp DeclarationRequest.authentication_method(:otp)
  @auth_offline DeclarationRequest.authentication_method(:offline)
  @declaration_doc [%{"type" => "person.DECLARATION_FORM"}]

  def verify(declaration_request, code) do
    with {:ok, _} <- verify_auth(declaration_request, code),
         docs <- prepare_documents_list(declaration_request),
         {:ok, _} <- check_documents(docs, declaration_request.id, {:ok, true}) do
      {:ok, true}
    end
  end

  def verify_auth(%{authentication_method_current: %{"type" => @auth_otp, "number" => phone}}, code) do
    OTPVerification.complete(phone, %{code: code})
  end

  def verify_auth(_, _), do: {:ok, true}

  defp prepare_documents_list(%{authentication_method_current: %{"type" => @auth_offline}} = declaration_request) do
    declaration_request.documents ++ @declaration_doc
  end

  defp prepare_documents_list(_), do: @declaration_doc

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

  def check_documents([], _declaration_request_id, acc) do
    acc
  end

  def uploaded?(id, %{"type" => type}) do
    resource_name = "declaration_request_#{type}.jpeg"
    bucket = Confex.fetch_env!(:ehealth, EHealth.API.MediaStorage)[:declaration_request_bucket]

    {:ok, %{"data" => %{"secret_url" => url}} = result} =
      MediaStorage.create_signed_url("HEAD", bucket, resource_name, id)

    Logger.info(fn ->
      Poison.encode!(%{
        "log_type" => "microservice_response",
        "microservice" => "ael",
        "result" => result,
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    case HTTPoison.head(url, "Content-Type": MIME.from_path(resource_name)) do
      {:ok, resp} ->
        case resp do
          %HTTPoison.Response{status_code: 200} ->
            {:ok, true}

          _ ->
            {:error, {:not_uploaded, type}}
        end

      {:error, reason} ->
        Logger.info(fn ->
          Poison.encode!(%{
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
end

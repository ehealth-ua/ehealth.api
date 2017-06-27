defmodule EHealth.API.MediaStorage do
  @moduledoc """
  Media Storage on Google Cloud Platform
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder
  alias EHealth.API.Helpers.MicroserviceCallLog, as: CallLog

  require Logger

  def options, do: config()[:hackney_options]

  def create_signed_url(action, bucket, resource_name, resource_id, headers \\ []) do
    data = %{"secret" => %{
      "action" => action,
      "bucket" => bucket,
      "resource_id" => resource_id,
      "resource_name" => resource_name,
    }}
    create_signed_url(data, headers)
  end

  def create_signed_url(data, headers) do
    CallLog.log("POST", config()[:endpoint], "/media_content_storage_secrets", data, headers)

    config()[:endpoint]
    |> Kernel.<>("/media_content_storage_secrets")
    |> post!(Poison.encode!(data), headers, options())
    |> ResponseDecoder.check_response()
  end

  def store_signed_content(signed_content, bucket, id, headers) do
    store_signed_content(config()[:enabled?], bucket, signed_content, id, headers)
  end

  def store_signed_content(true, bucket, signed_content, id, headers) do
    "PUT"
    |> create_signed_url(config()[bucket], "signed_content", id, headers)
    |> put_signed_content(signed_content)
  end

  def store_signed_content(false, _bucket, _signed_content, _id, _headers) do
    {:ok, "Media Storage is disabled in config"}
  end

  def put_signed_content({:ok, %{"data" => data}}, signed_content) do
    headers = [{"Content-Type", ""}]
    content = Base.decode64!(signed_content, [ignore: :whitespace, padding: false])

    data
    |> Map.fetch!("secret_url")
    |> put!(content, headers, options())
    |> check_gcs_response()
  end

  def put_signed_content(err, _signed_content) do
    Logger.error(fn -> "Cannot create signed url. Response: #{inspect err}" end)
    err
  end

  def check_gcs_response(%HTTPoison.Response{status_code: code, body: body}) when code in [200, 201] do
    {:ok, body}
  end
  def check_gcs_response(%HTTPoison.Response{body: body}) do
    {:error, body}
  end
end

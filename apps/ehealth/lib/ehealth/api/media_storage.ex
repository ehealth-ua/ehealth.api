defmodule EHealth.API.MediaStorage do
  @moduledoc """
  Media Storage on Google Cloud Platform
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.Helpers.MicroserviceBase
  alias EHealth.API.Helpers.SignedContent
  require Logger

  def create_signed_url(action, bucket, resource_name, resource_id, headers \\ []) do
    data = %{"secret" => generate_sign_url_data(action, bucket, resource_name, resource_id)}
    create_signed_url(data, headers)
  end

  defp generate_sign_url_data(action, bucket, resource_name, resource_id) do
    %{
      "action" => action,
      "bucket" => bucket,
      "resource_id" => resource_id,
      "resource_name" => resource_name
    }
    |> add_content_type(action, resource_name)
  end

  defp add_content_type(data, "GET", _resource_name), do: data

  defp add_content_type(data, _action, resource_name) do
    Map.put(data, "content_type", MIME.from_path(resource_name))
  end

  def create_signed_url(data, headers) do
    post!("/media_content_storage_secrets", Poison.encode!(data), headers)
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
    headers = [{"Content-Type", "application/octet-stream"}]
    content = Base.decode64!(signed_content, ignore: :whitespace, padding: false)

    data
    |> Map.fetch!("secret_url")
    |> SignedContent.save(content, headers, config()[:hackney_options])
    |> check_gcs_response()
  end

  def put_signed_content(err, _signed_content) do
    Logger.error(fn ->
      Poison.encode!(%{
        "log_type" => "microservice_response",
        "microservice" => config()[:endpoint],
        "response" => err,
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    err
  end

  def check_gcs_response(%HTTPoison.Response{status_code: code, body: body}) when code in [200, 201] do
    {:ok, body}
  end

  def check_gcs_response(%HTTPoison.Response{body: body}) do
    {:error, body}
  end
end

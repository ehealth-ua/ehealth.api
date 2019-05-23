defmodule Core.API.MediaStorage do
  @moduledoc """
  Media Storage on Google Cloud Platform
  """

  use Core.API.Helpers.MicroserviceBase
  require Logger

  @behaviour Core.API.MediaStorageBehaviour

  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]
  @rpc_worker Application.get_env(:core, :rpc_worker)

  def verify_uploaded_file(url, resource_name) do
    HTTPoison.head(url, "Content-Type": MIME.from_path(resource_name))
  end

  def create_signed_url(action, bucket, resource_name, resource_id) do
    action
    |> generate_sign_url_data(bucket, resource_name, resource_id)
    |> create_signed_url()
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

  def create_signed_url(%{} = sign_url_data) do
    with {:ok, secret} <- @rpc_worker.run("ael_api", Ael.Rpc, :signed_url, [sign_url_data]) do
      {:ok, secret}
    else
      error ->
        Logger.error("Failed to create signed url with error #{inspect(error)}")
        {:error, :internal_server_error}
    end
  end

  def store_signed_content(signed_content, bucket, id, resource_name) do
    store_signed_content(config()[:enabled?], bucket, signed_content, id, resource_name)
  end

  def store_signed_content(true, bucket, signed_content, id, resource_name) do
    with {:ok, %{secret_url: url}} <- @media_storage_api.create_signed_url("PUT", config()[bucket], resource_name, id) do
      headers = [{"Content-Type", "application/octet-stream"}]
      content = Base.decode64!(signed_content, ignore: :whitespace, padding: false)

      url
      |> @media_storage_api.put_signed_content(content, headers, config()[:hackney_options])
      |> check_gcs_response()
    end
  end

  def store_signed_content(false, _bucket, _signed_content, _id, _resource_name) do
    {:ok, "Media Storage is disabled in config"}
  end

  def check_gcs_response({:ok, %HTTPoison.Response{status_code: code} = response}) when code in [200, 201] do
    check_gcs_response(response)
  end

  def check_gcs_response({_, response}), do: check_gcs_response(response)

  def check_gcs_response(%HTTPoison.Response{status_code: code, body: body}) when code in [200, 201] do
    {:ok, body}
  end

  def check_gcs_response(%HTTPoison.Response{body: body}) do
    Logger.error("Failed to store signed_content, details: #{inspect(body)}")
    {:error, body}
  end

  def get_signed_content(secret_url) do
    case HTTPoison.get(secret_url) do
      {:ok, %{status_code: 200}} = result ->
        result

      {:ok, %{body: body}} ->
        Logger.warn("Failed to get signed_content, details: #{inspect(body)}")
        {:error, {:conflict, "Failed to get signed_content"}}

      error ->
        error
    end
  end

  def save_file(id, content, bucket, resource_name) do
    with {:ok, %{secret_url: url}} <- create_signed_url("PUT", bucket, resource_name, id) do
      url
      |> put_signed_content(content, [{"Content-Type", MIME.from_path(resource_name)}], config()[:hackney_options])
      |> check_gcs_response()
    end
  end

  def delete_file(url), do: HTTPoison.delete(url)
  def put_signed_content(url, content, headers, options), do: HTTPoison.put(url, content, headers, options)
end

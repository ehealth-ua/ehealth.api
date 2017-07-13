defmodule EHealth.API.Mithril do
  @moduledoc """
  Trump API client
  API documentation: http://docs.trump1.apiary.io
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  require Logger

  @client_type_name "MSP"
  @client_type_scopes "legal_entities:read,update"
  @client_type_data %{
    "name" => @client_type_name,
    "scope" => @client_type_scopes
  }

  def process_url(url), do: config()[:endpoint] <> url

  def options, do: config()[:hackney_options]

  # Clients

  def put_client(%{"id" => id} = client, headers \\ []) do
    "/admin/clients/"
    |> Kernel.<>(id)
    |> put!(prepare_client_data(client, headers), headers, options())
    |> ResponseDecoder.check_response()
  end

  def get_client(id, headers \\ []) do
    "/admin/clients/"
    |> Kernel.<>(id)
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def get_clients(params \\ [], headers \\ []) do
    "/admin/clients"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_client_by_name(name, headers \\ []) do
    get_clients([name: name], headers)
  end

  def get_client_details(id, headers \\ []) do
    "/admin/clients/#{id}/details"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def get_client_type_name(id, headers) do
    id
    |> get_client_details(headers)
    |> case do
         {:ok, %{"data" => %{"client_type_name" => client_type}}} -> client_type
         _ -> nil
       end
  end

  # Client types

  def create_client_type(client_type, headers \\ []) do
    "/admin/client_types"
    |> post!(Poison.encode!(%{"client_type" => client_type}), headers, options())
    |> ResponseDecoder.check_response()
  end

  def get_client_types(params \\ [], headers \\ []) do
    "/admin/client_types"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_client_type_by_name(name, headers \\ []) do
    get_client_types([name: name], headers)
  end

  # Users

  def get_user_by_id(id, headers \\ []) do
    "/admin/users/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def search_user(params, headers \\ []) do
    "/admin/users"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def create_user(params, headers \\ []) do
    "/admin/users"
    |> post!(Poison.encode!(%{"user" => params}), headers, options())
    |> ResponseDecoder.check_response()
  end

  # Roles

  def get_roles_by_name(name, headers \\ []) do
    "/admin/roles"
    |> get!(headers, params: [name: name])
    |> ResponseDecoder.check_response()
  end

  # User roles

  def get_user_roles(user_id, params, headers \\ []) when is_binary(user_id) do
    "/admin/users/#{user_id}/roles"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def create_user_role(user_id, role, headers \\ []) do
    "/admin/users/#{user_id}/roles"
    |> post!(Poison.encode!(%{"user_role" => role}), headers, options())
    |> ResponseDecoder.check_response()
  end

  def delete_user_role(user_id, role_id, headers) do
    "/admin/users/#{user_id}/roles/#{role_id}"
    |> delete!(headers, options())
    |> ResponseDecoder.check_response()
  end

  def delete_user_roles_by_user(user_id, headers) do
    "/admin/users/#{user_id}/roles"
    |> delete!(headers, options())
    |> ResponseDecoder.check_response()
  end

  # Apps

  def get_apps(params \\ [], headers \\ []) do
    "/admin/apps"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def delete_app(app_id, headers) do
    "/admin/apps/#{app_id}"
    |> delete!(headers, options())
    |> ResponseDecoder.check_response()
  end

  def delete_apps_by_user(user_id, headers) do
    "/admin/users/#{user_id}/apps"
    |> delete!(headers, options())
    |> ResponseDecoder.check_response()
  end

  # Tokens

  def get_tokens(params \\ [], headers \\ []) do
    "/admin/tokens"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def delete_token(token_id, headers) do
    "/admin/tokens/#{token_id}"
    |> delete!(headers, options())
    |> ResponseDecoder.check_response()
  end

  def delete_tokens_by_user(user_id, headers) do
    "/admin/users/#{user_id}/tokens"
    |> delete!(headers, options())
    |> ResponseDecoder.check_response()
  end

  # Helpers

  def prepare_client_data(client, headers \\ []) do
    Poison.encode!(%{"client" => put_client_type_id(client, headers)})
  end

  def put_client_type_id(client, headers \\ []) do
    Map.put(client, "client_type_id", get_client_type_id(headers))
  end

  def get_client_type_id(headers \\ []) do
    case get_client_type_by_name(@client_type_name, headers) do
      {:ok, %{"data" => [%{"id" => id}]}}
        -> id
      {:ok, %{"data" => [%{"id" => id} | _tail]}}
        -> id
      {:ok, _}
        -> @client_type_data
           |> create_client_type()
           |> elem(1)
           |> Map.fetch!("data")
           |> Map.fetch!("id")
      {:error, response}
        -> Logger.error(fn -> "Cannot get Client Type from Mithril API. Response: #{inspect response}" end)
        nil
    end
  end
end

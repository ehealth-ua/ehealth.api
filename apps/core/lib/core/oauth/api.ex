defmodule Core.OAuth.API do
  @moduledoc """
  OAuth service layer
  """

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1]

  alias Core.LegalEntities.LegalEntity

  require Logger

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  def upsert_client_with_connection(%LegalEntity{} = legal_entity, client_type_id, request_params, headers) do
    redirect_uri = get_in(request_params, ~w(security redirect_uri))

    client_attrs = %{
      "id" => legal_entity.id,
      "name" => legal_entity.name,
      "user_id" => get_consumer_id(headers),
      "client_type_id" => client_type_id
    }

    connection_attrs = %{"redirect_uri" => redirect_uri}

    with {:ok, %{"data" => client}} <- @mithril_api.put_client(client_attrs, headers),
         {:ok, %{"data" => connection}} <- create_or_update_connection(client["id"], connection_attrs, headers) do
      {:ok, client, connection}
    end
  end

  def create_or_update_connection(client_id, attrs, headers) do
    attrs = Map.put(attrs, "consumer_id", get_consumer_id(headers))
    @mithril_api.upsert_client_connection(client_id, attrs, headers)
  end

  @doc """
  Creates a new Mithril client for MSP after successfully created a new Legal Entity
  """
  def put_client(%LegalEntity{} = legal_entity, client_type_id, redirect_uri, headers) do
    @mithril_api.put_client(
      %{
        "id" => legal_entity.id,
        "name" => legal_entity.name,
        "redirect_uri" => redirect_uri,
        "user_id" => get_consumer_id(headers),
        "client_type_id" => client_type_id
      },
      headers
    )
  end

  def create_user(%Ecto.Changeset{valid?: true, changes: %{password: password}}, email, headers) do
    @mithril_api.create_user(%{"password" => password, "email" => email}, headers)
  end

  def create_user(err, _email, _headers), do: err

  def get_connection_credentials(client_id, headers) do
    attrs = %{"consumer_id" => get_consumer_id(headers)}

    with {:ok, %{"data" => connections}} <- @mithril_api.get_client_connections(client_id, attrs, headers) do
      {:ok, fetch_connection_credentials(connections, client_id)}
    end
  end

  defp fetch_connection_credentials([connection], client_id) do
    %{
      "client_id" => client_id,
      "client_secret" => Map.get(connection, "secret"),
      "redirect_uri" => Map.get(connection, "redirect_uri")
    }
  end

  defp fetch_connection_credentials(_, client_id) do
    Logger.error(fn ->
      Jason.encode!(%{
        "log_type" => "error",
        "message" => "Cannot create or find Mithril client for Legal Entity #{client_id}}",
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    %{}
  end
end

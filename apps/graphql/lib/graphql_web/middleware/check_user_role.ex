defmodule GraphQLWeb.Middleware.CheckUserRole do
  @moduledoc """
  Checks if user has provided role by `client_id`
  """

  @behaviour Absinthe.Middleware

  import Core.Users.Validator, only: [user_has_role: 3]

  alias Absinthe.Resolution
  alias Core.Log

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  def call(%{state: :unresolved, context: %{client_id: client_id, consumer_id: user_id}} = resolution, options) do
    role = Keyword.fetch!(options, :role)
    error_message = Keyword.get(options, :message, "User doesn't have required role")
    search_params = %{client_id: client_id, user_id: user_id}

    with {:ok, roles} <- get_user_roles(search_params),
         :ok <- user_has_role(roles, role, error_message) do
      resolution
    else
      error ->
        Resolution.put_result(resolution, error)
    end
  end

  def call(%{state: :unresolved}, _) do
    raise "`client_id` or `consumer_id` was not provided for #{__MODULE__}"
  end

  def call(resolution, _), do: resolution

  defp get_user_roles(search_params) do
    with {:ok, %{"data" => roles}} <- @mithril_api.search_user_roles(search_params, []) do
      {:ok, roles}
    else
      error ->
        Log.error("#{__MODULE__}: Fail to search_user_roles with error: #{inspect(error)}")
        {:error, :internal_server_error}
    end
  end
end

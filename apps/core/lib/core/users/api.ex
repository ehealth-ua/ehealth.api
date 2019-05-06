defmodule Core.Users.API do
  @moduledoc """
  API to work with platform users.
  """

  import Ecto.{Query, Changeset}, warn: false

  alias Core.Bamboo.Emails.Sender
  alias Core.Man.Templates.CredentialsRecoveryRequest, as: CredentialsRecoveryRequestTemplate
  alias Core.Repo
  alias Core.Users.CredentialsRecoveryRequest
  alias Core.Validators.JsonSchema
  alias Ecto.Changeset
  alias EView.Changeset.Validators.Email, as: EmailValidator

  require Logger

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]
  @read_repo Application.get_env(:core, :repos)[:read_repo]

  def create_credentials_recovery_request(attrs, opts \\ []) do
    upstream_headers = Keyword.get(opts, :upstream_headers, [])

    with {:ok, email} <- Map.fetch(attrs, "email"),
         :ok <- JsonSchema.validate(:credentials_recovery_request, attrs),
         {:ok, %{"data" => users}} <- @mithril_api.search_user(%{"email" => email}, upstream_headers),
         [%{"id" => user_id, "email" => user_email}] <- users,
         {:ok, request} <- insert_credentials_recovery_request(user_id),
         :ok <- send_email(user_email, request, Map.get(attrs, "client_id"), Map.get(attrs, "redirect_uri")) do
      {:ok, %{request | expires_at: get_expiration_date(request)}}
    else
      :error ->
        changeset =
          %CredentialsRecoveryRequest{}
          |> change(%{})
          |> add_error(:email, "is not set", validation: :required)
          |> EmailValidator.validate_email(:email)

        {:error, changeset}

      [] ->
        changeset =
          %CredentialsRecoveryRequest{}
          |> change(%{})
          |> add_error(:email, "does not exist", validation: :existence)
          |> EmailValidator.validate_email(:email)

        {:error, changeset}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp insert_credentials_recovery_request(user_id) do
    %CredentialsRecoveryRequest{user_id: user_id}
    |> credentials_recovery_request_changeset(%{"user_id" => user_id})
    |> Repo.insert()
  end

  defp fetch_credentials_recovery_request(request_id) do
    case @read_repo.get_by(CredentialsRecoveryRequest, id: request_id, is_active: true) do
      nil -> {:error, :not_found}
      %CredentialsRecoveryRequest{} = request -> {:ok, request}
    end
  end

  defp deactivate_credentials_recovery_request(request) do
    request
    |> credentials_recovery_request_changeset(%{"is_active" => false})
    |> Repo.update()
  end

  defp get_expiration_date(request) do
    ttl = Confex.fetch_env!(:core, :credentials_recovery_request_ttl)
    DateTime.add(request.inserted_at, ttl, :second)
  end

  defp request_expired?(request) do
    DateTime.compare(get_expiration_date(request), DateTime.utc_now()) == :lt
  end

  def reset_password(request_id, attrs, opts \\ []) do
    upstream_headers = Keyword.get(opts, :upstream_headers, [])

    with {:ok, %{user_id: user_id} = request} <- fetch_credentials_recovery_request(request_id),
         false <- request_expired?(request),
         %Changeset{valid?: true} <- reset_password_changeset(attrs),
         {:ok, %{"data" => user}} <- @mithril_api.change_user(user_id, attrs, upstream_headers),
         {:ok, _updated_request} <- deactivate_credentials_recovery_request(request) do
      {:ok, user}
    else
      true ->
        changeset =
          %CredentialsRecoveryRequest{}
          |> change(%{})
          |> add_error(:expires_at, "is expired", validation: :expiration)

        {:error, changeset}

      {:ok, %{"error" => error}} ->
        {:error, error}

      {:error, reason} ->
        {:error, reason}

      %Changeset{} = changeset ->
        {:error, changeset}
    end
  end

  defp credentials_recovery_request_changeset(%CredentialsRecoveryRequest{} = request, attrs) do
    request
    |> cast(attrs, [:user_id, :is_active])
    |> validate_required([:user_id, :is_active])
  end

  defp reset_password_changeset(attrs) do
    types = %{password: :string}
    keys = Map.keys(types)

    {attrs, types}
    |> cast(attrs, keys)
    |> validate_required(keys)
  end

  defp send_email(email, %CredentialsRecoveryRequest{} = request, client_id, redirect_uri) do
    email_config =
      :core
      |> Confex.fetch_env!(:emails)
      |> Keyword.get(:credentials_recovery_request)

    with {:ok, body} <- CredentialsRecoveryRequestTemplate.render(request, client_id, redirect_uri),
         {:ok, _} <- Sender.send_email_with_activation(email, body, email_config[:from], email_config[:subject]) do
      :ok
    end
  end
end

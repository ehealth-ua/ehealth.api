defmodule EHealth.Users.API do
  @moduledoc """
  API to work with platform users.
  """
  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset
  alias EHealth.Bamboo.Emails.Sender
  alias EHealth.Repo
  alias EHealth.Users.CredentialsRecoveryRequest
  alias EHealth.Validators.JsonSchema
  alias EView.Changeset.Validators.Email, as: EmailValidator
  require Logger

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

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
    case Repo.get_by(CredentialsRecoveryRequest, id: request_id, is_active: true) do
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
    ttl = Confex.fetch_env!(:ehealth, :credentials_recovery_request_ttl)
    NaiveDateTime.add(request.inserted_at, ttl)
  end

  defp request_expired?(request) do
    NaiveDateTime.compare(get_expiration_date(request), NaiveDateTime.utc_now()) == :lt
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
    case EHealth.Man.Templates.CredentialsRecoveryRequest.render(request, client_id, redirect_uri) do
      {:ok, body} ->
        try do
          email_config =
            :ehealth
            |> Confex.fetch_env!(:emails)
            |> Keyword.get(:credentials_recovery_request)

          Sender.send_email(email, body, email_config[:from], email_config[:subject])
          :ok
        rescue
          error in [Bamboo.PostmarkAdapter.ApiError] ->
            Logger.warn(Exception.message(error))
            :ok
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end

defmodule EHealth.Cabinet.API do
  @moduledoc false
  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.Guardian
  alias EHealth.Bamboo.Emails.Sender
  alias EHealth.Validators.JsonSchema
  alias EHealth.Cabinet.{RegistrationRequest, UserSearchRequest}
  alias EHealth.Man.Templates.EmailVerification

  require Logger

  @mpi_api Application.get_env(:ehealth, :api_resolvers)[:mpi]
  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]
  @signature_api Application.get_env(:ehealth, :api_resolvers)[:digital_signature]

  def create_patient(jwt, params, headers) do
    with {:ok, %{"email" => email}} <- Guardian.decode_and_verify(jwt),
         %Ecto.Changeset{valid?: true} <- validate_params(:patient, params),
         {:ok, %{"data" => %{"content" => content, "signer" => signer}}} <-
           @signature_api.decode_and_validate(params["signed_person_data"], params["signed_content_encoding"], headers),
         {:ok, tax_id} <- validate_tax_id(content, signer),
         :ok <- JsonSchema.validate(:person, content),
         {:ok, %{"data" => mpi_person}} <-
           @mpi_api.search(%{"tax_id" => tax_id, "birth_date" => content["birth_date"]}, headers),
         {:ok, %{"data" => person}} <- create_or_update_person(mpi_person, content, headers),
         {:ok, %{"data" => mithril_user}} <- @mithril_api.search_user(%{email: email}, headers),
         :ok <- check_user_by_tax_id(mithril_user),
         user_params <- prepare_user_params(tax_id, email, params),
         {:ok, %{"data" => user}} <- create_or_update_user(mithril_user, user_params, headers),
         conf <- Confex.fetch_env!(:ehealth, __MODULE__),
         role_params <- %{role_id: conf[:role_id], client_id: conf[:client_id]},
         {:ok, %{"data" => role}} <- @mithril_api.create_user_role(user["id"], role_params, headers),
         {:ok, %{"data" => token}} <- create_access_token(params["password"], email, role, conf[:client_id], headers) do
      {:ok, %{user: user, patient: person, access_token: token["value"]}}
    end
  end

  defp validate_tax_id(%{"tax_id" => tax_id}, %{"edrpou" => edrpou}) when edrpou == tax_id, do: {:ok, tax_id}
  defp validate_tax_id(_, _), do: {:error, {:conflict, "Registration person and person that sign should be the same"}}

  defp create_or_update_person([], params, headers), do: @mpi_api.create_or_update_person(params, headers)
  defp create_or_update_person(persons, params, headers), do: @mpi_api.update_person(hd(persons)["id"], params, headers)

  defp prepare_user_params(tax_id, email, params) do
    %{
      "otp" => params["otp"],
      "email" => email,
      "tax_id" => tax_id,
      "password" => params["password"]
    }
  end

  defp check_user_by_tax_id([%{"tax_id" => tax_id}]) when is_binary(tax_id) and byte_size(tax_id) > 0 do
    {:error, {:conflict, "User with this tax_id already exists"}}
  end

  defp check_user_by_tax_id(_), do: :ok

  defp create_or_update_user([%{"id" => id}], params, headers), do: @mithril_api.change_user(id, params, headers)
  defp create_or_update_user([], params, headers), do: @mithril_api.create_user(params, headers)

  defp create_access_token(password, email, %{"scope" => scope}, client_id, headers) do
    token = %{
      grant_type: "password",
      email: email,
      password: password,
      client_id: client_id,
      scope: scope
    }

    @mithril_api.create_access_token(token, headers)
  end

  def validate_email_jwt(jwt) do
    with {:ok, %{"email" => email}} <- Guardian.decode_and_verify(jwt),
         ttl <- Confex.fetch_env!(:ehealth, __MODULE__)[:jwt_ttl_registration],
         {:ok, jwt, _claims} <- generate_jwt(email, {ttl, :hours}) do
      {:ok, jwt}
    else
      _ -> {:error, {:access_denied, "invalid JWT"}}
    end
  end

  def send_email_verification(params, headers) do
    with %Ecto.Changeset{valid?: true, changes: %{email: email}} <- validate_params(:email, params),
         true <- email_available_for_registration?(email, headers),
         false <- email_sent?(email),
         ttl <- Confex.fetch_env!(:ehealth, __MODULE__)[:jwt_ttl_email],
         {:ok, jwt, _claims} <- generate_jwt(email, {ttl, :hours}),
         {:ok, template} <- EmailVerification.render(jwt) do
      email_config = Confex.fetch_env!(:ehealth, EmailVerification)
      send_email(email, template, email_config)
    end
  end

  defp validate_params(:email, params) do
    {%{}, %{email: :string}}
    |> cast(params, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[a-zA-Z0-9.!#$%&’*+\/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)
  end

  defp validate_params(:patient, params) do
    fields = RegistrationRequest.__schema__(:fields)

    %RegistrationRequest{}
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:signed_content_encoding, ["base64"])
  end

  defp validate_params(:user_search, params) do
    fields = UserSearchRequest.__schema__(:fields)

    %UserSearchRequest{}
    |> cast(params, fields)
    |> validate_required(fields)
  end

  def email_available_for_registration?(email, headers) do
    case @mithril_api.search_user(%{email: email}, headers) do
      {:ok, %{"data" => [%{"tax_id" => tax_id}]}} when is_binary(tax_id) and byte_size(tax_id) > 0 ->
        {:error, {:conflict, "User with this email already exists"}}

      {:ok, _} ->
        true

      _ ->
        {:error, {:internal_error, "Cannot fetch user"}}
    end
  end

  defp email_sent?(_email) do
    # ToDo: check sent email?
    false
  end

  defp generate_jwt(email, ttl) do
    Guardian.encode_and_sign(:email, %{email: email}, token_type: "access", ttl: ttl)
  end

  def send_email(email, body, email_config) do
    Sender.send_email(email, body, email_config[:from], email_config[:subject])
    :ok
  rescue
    e ->
      Logger.error(fn ->
        Poison.encode!(%{
          "log_type" => "error",
          "message" => e.message,
          "request_id" => Logger.metadata()[:request_id]
        })
      end)

      {:error, {:internal_error, "Cannot send email. Try later"}}
  end

  def check_user_absence(params, headers) do
    with %Ecto.Changeset{valid?: true} <- validate_params(:user_search, params) do
      case @mithril_api.search_user(%{tax_id: params["tax_id"]}, headers) do
        {:ok, %{"data" => data}} when length(data) > 0 ->
          {:error, {:conflict, "User with this tax_id already exists"}}

        {:ok, _} ->
          :ok

        _ ->
          {:error, {:internal_error, "Cannot fetch user"}}
      end
    end
  end
end

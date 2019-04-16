defmodule Core.Cabinet.API do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  import Core.API.Helpers.Connection, only: [get_consumer_id: 1]

  alias Core.Bamboo.Emails.Sender
  alias Core.Cabinet.Requests.Registration
  alias Core.Cabinet.Requests.UserSearch
  alias Core.DeclarationRequests.API.V2.MpiSearch
  alias Core.DeclarationRequests.API.V2.Persons
  alias Core.Guardian
  alias Core.Man.Templates.EmailVerification
  alias Core.Persons, as: CorePersons
  alias Core.Persons.V2.Validator, as: PersonsValidator
  alias Core.ValidationError
  alias Core.Validators.Addresses
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Core.Validators.Signature, as: SignatureValidator
  alias EView.Changeset.Validators.Email, as: EmailValidator

  require Logger

  @mpi_api Application.get_env(:core, :api_resolvers)[:mpi]
  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]
  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]
  @otp_verification_api Application.get_env(:core, :api_resolvers)[:otp_verification]

  @person_active "active"
  @authentication_otp "OTP"

  def create_patient(jwt, params, headers) do
    with {:ok, email} <- fetch_email_from_jwt(jwt),
         %Ecto.Changeset{valid?: true, changes: changes} <- validate_params(:patient, params),
         {:ok, %{"content" => content, "signers" => [signer]}} <-
           SignatureValidator.validate(params["signed_content"], params["signed_content_encoding"], headers),
         :ok <- verify_auth(content, changes, headers),
         :ok <- JsonSchema.validate(:person, content),
         :ok <- PersonsValidator.validate_unzr(content),
         :ok <- PersonsValidator.validate_national_id(content),
         :ok <- PersonsValidator.validate_person_passports(content),
         :ok <- PersonsValidator.validate_birth_date(content["birth_date"], "$.birth_date"),
         :ok <- Addresses.validate(content["addresses"], "RESIDENCE"),
         {:ok, tax_id} <- validate_tax_id(content, signer),
         :ok <- validate_first_name(content, signer),
         :ok <- validate_last_name(content, signer),
         :ok <- validate_email(content, email),
         {:ok, search_params} <- Persons.get_search_params(content),
         {:ok, mpi_response} <- MpiSearch.search(search_params),
         {:ok, %{"data" => user_data}} <- @mithril_api.search_user(%{email: email}, headers),
         mithril_user <- fetch_mithril_user(user_data),
         :ok <- check_user_blocked(mithril_user),
         :ok <- check_user_by_tax_id(mithril_user),
         person_params <- prepare_person_params(content),
         {:ok, %{"data" => person}} <- create_or_update_person(mpi_response, person_params, headers),
         :ok <- save_signed_content(person["id"], params, headers),
         user_params <- prepare_user_params(tax_id, person["id"], email, params, content),
         {:ok, %{"data" => user}} <- create_or_update_user(mithril_user, user_params, headers),
         conf <- Confex.fetch_env!(:core, __MODULE__),
         role_params <- %{role_id: conf[:role_id]},
         {:ok, %{"data" => _}} <- @mithril_api.create_global_user_role(user["id"], role_params, headers),
         {:ok, %{"data" => token}} <- create_access_token(user, conf[:client_id], headers) do
      {:ok, %{user: user, patient: person, access_token: token["value"]}}
    end
  end

  defp fetch_email_from_jwt(jwt) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, %{"email" => email}} -> {:ok, email}
      _ -> {:error, {:access_denied, "invalid JWT claim"}}
    end
  end

  defp validate_tax_id(%{"tax_id" => tax_id}, %{"drfo" => tax_id}), do: {:ok, tax_id}
  defp validate_tax_id(_, _), do: {:error, {:conflict, "Registration person and person that sign should be the same"}}

  defp validate_first_name(content, signer) do
    with given_name when is_binary(given_name) <- Map.get(signer, "given_name", :signer_empty_given_name),
         first_name when is_binary(first_name) <- Map.get(content, "first_name", :signed_content_empty_first_name),
         true <- String.downcase(given_name) =~ String.downcase(first_name) do
      :ok
    else
      :signer_empty_given_name ->
        conflict("Field given_name is empty in DS signer", :signer_empty_given_name)

      :signed_content_empty_first_name ->
        conflict("Field first_name is empty in signed content", :signed_content_empty_first_name)

      _ ->
        conflict("Input first_name doesn't match name from DS", :input_name_not_matched_with_ds)
    end
  end

  defp validate_last_name(%{"last_name" => last_name}, %{"surname" => last_name}), do: :ok
  defp validate_last_name(_, _), do: {:error, {:conflict, "Input last_name doesn't match name from DS"}}

  def validate_email(%{"email" => signed_content_email}, signed_content_email), do: :ok
  def validate_email(_, _), do: {:error, {:conflict, "Email in signed content is incorrect"}}

  defp prepare_person_params(content), do: Map.put(content, "patient_signed", true)

  defp create_or_update_person(nil, params, headers), do: @mpi_api.create_or_update_person!(params, headers)

  defp create_or_update_person(person, params, headers), do: @mpi_api.update_person(person.id, params, headers)

  defp prepare_user_params(tax_id, person_id, email, params, content) do
    [%{"phone_number" => phone_number}] = content["authentication_methods"]

    %{
      "factor" => phone_number,
      "otp" => params["otp"],
      "email" => email,
      "tax_id" => tax_id,
      "person_id" => person_id,
      "password" => params["password"]
    }
  end

  defp fetch_mithril_user([user | _]), do: user
  defp fetch_mithril_user(_), do: nil

  defp check_user_blocked(%{"is_blocked" => false}), do: :ok
  defp check_user_blocked(%{"is_blocked" => _}), do: {:error, {:access_denied, "User blocked"}}
  defp check_user_blocked(_), do: :ok

  defp check_user_by_tax_id(%{"tax_id" => tax_id}) when is_binary(tax_id) and byte_size(tax_id) > 0 do
    conflict("User with this tax_id already exists", :tax_id_exists)
  end

  defp check_user_by_tax_id(_), do: :ok

  defp create_or_update_user(%{"id" => id}, params, headers), do: @mithril_api.change_user(id, params, headers)
  defp create_or_update_user(nil, params, headers), do: @mithril_api.create_user(params, headers)

  defp create_access_token(%{"id" => user_id}, client_id, headers) do
    params = %{
      client_id: client_id,
      scope: "app:authorize"
    }

    @mithril_api.create_access_token(user_id, params, headers)
  end

  def validate_email_jwt(jwt, headers) do
    with {:ok, email} <- fetch_email_from_jwt(jwt),
         true <- email_available_for_registration?(email, headers),
         ttl <- Confex.fetch_env!(:core, __MODULE__)[:jwt_ttl_registration],
         {:ok, jwt, _claims} <- generate_jwt(Guardian.get_aud(:registration), email, {ttl, :minutes}) do
      {:ok, jwt}
    end
  end

  def send_email_verification(params, headers) do
    with %Ecto.Changeset{valid?: true, changes: %{email: email}} <- validate_params(:email, params),
         true <- email_available_for_registration?(email, headers),
         false <- email_sent?(email),
         ttl <- Confex.fetch_env!(:core, __MODULE__)[:jwt_ttl_email],
         {:ok, jwt, _claims} <- generate_jwt(Guardian.get_aud(:email_verification), email, {ttl, :hours}),
         {:ok, template} <- EmailVerification.render(jwt),
         email_config <- Confex.fetch_env!(:core, EmailVerification),
         :ok <- send_email(email, template, email_config) do
      {:ok, jwt}
    end
  end

  defp validate_params(:email, params) do
    {%{}, %{email: :string}}
    |> cast(params, [:email])
    |> validate_required([:email])
    |> EmailValidator.validate_email(:email)
  end

  defp validate_params(:patient, params) do
    fields = Registration.__schema__(:fields)

    %Registration{}
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:signed_content_encoding, ["base64"])
  end

  defp validate_params(:user_search, params) do
    fields = UserSearch.__schema__(:fields)

    %UserSearch{}
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:signed_content_encoding, ["base64"])
  end

  def email_available_for_registration?(email, headers) do
    case @mithril_api.search_user(%{email: email}, headers) do
      {:ok, %{"data" => [%{"tax_id" => tax_id}]}} when is_binary(tax_id) and byte_size(tax_id) > 0 ->
        Error.dump(%ValidationError{description: "invalid", rule: "email_exists", path: "$.email"})

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

  defp generate_jwt(type, email, ttl) do
    Guardian.encode_and_sign(type, %{email: email}, token_type: "access", ttl: ttl)
  end

  defp send_email(email, body, email_config) do
    Sender.send_email(email, body, email_config[:from], email_config[:subject])
    :ok
  rescue
    e ->
      Logger.error(e.message)
      {:error, {:internal_error, "Cannot send email. Try later"}}
  end

  def check_user_absence(jwt, params, headers) do
    with %Ecto.Changeset{valid?: true} <- validate_params(:user_search, params),
         {:ok, %{"email" => email}} <- Guardian.decode_and_verify(jwt),
         true <- email_available_for_registration?(email, headers),
         {:ok, %{"signers" => [signer]}} <-
           SignatureValidator.validate(params["signed_content"], params["signed_content_encoding"], headers),
         {:ok, tax_id} <- fetch_drfo(signer) do
      %{tax_id: tax_id}
      |> @mithril_api.search_user(headers)
      |> check_mithril_user_absence()
    end
  end

  defp fetch_drfo(%{"drfo" => drfo}) when is_binary(drfo) and byte_size(drfo) > 0, do: {:ok, drfo}
  defp fetch_drfo(_signer), do: conflict("DRFO in DS not present", :drfo_not_present)

  defp check_mithril_user_absence({:ok, %{"data" => data}}) when length(data) > 0 do
    conflict("User with this tax_id already exists", :tax_id_exists)
  end

  defp check_mithril_user_absence({:ok, _}), do: :ok
  defp check_mithril_user_absence(_), do: {:error, {:internal_error, "Cannot fetch user"}}

  defp conflict(message, type), do: {:error, {:conflict, %{message: message, type: type}}}

  defp save_signed_content(id, %{"signed_content" => signed_content}, headers, resource_name \\ "signed_content") do
    signed_content
    |> @media_storage_api.store_signed_content(:person_bucket, id, resource_name, headers)
    |> case do
      {:ok, _} -> :ok
      _error -> {:error, {:bad_gateway, "Failed to save signed content"}}
    end
  end

  def verify_auth(%{"authentication_methods" => authentication_methods}, %{otp: code}, headers) do
    case Enum.find(authentication_methods, &otp_params?(&1)) do
      nil ->
        {:error, :access_denied}

      %{"phone_number" => phone_number} ->
        case @otp_verification_api.complete(phone_number, %{code: code}, headers) do
          {:ok, _} -> :ok
          _error -> Error.dump(%ValidationError{description: "Invalid verification code", path: "$.otp"})
        end
    end
  end

  def verify_auth(_, _, _), do: {:error, :access_denied}

  defp otp_params?(%{"phone_number" => _, "type" => @authentication_otp}), do: true
  defp otp_params?(_), do: false

  def get_user_authentication_factor(headers) do
    user_id = get_consumer_id(headers)

    with {:ok, %{"data" => user}} <- @mithril_api.get_user_by_id(user_id, headers),
         {:ok, person} <- CorePersons.get_by_id(user["person_id"]),
         :ok <- check_user_blocked(user),
         :ok <- check_person_status(person),
         {:ok, paging} <- @mithril_api.get_authentication_factors(user_id, %{}, headers) do
      {:ok, paging}
    end
  end

  defp check_person_status(%{is_active: true, status: @person_active}), do: :ok
  defp check_person_status(_), do: {:error, {:conflict, "Person is not active"}}
end

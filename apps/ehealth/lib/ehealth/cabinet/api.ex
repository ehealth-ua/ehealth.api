defmodule EHealth.Cabinet.API do
  @moduledoc false
  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.Guardian
  alias EHealth.Bamboo.Emails.Sender
  alias EHealth.Validators.Addresses
  alias EHealth.Validators.JsonSchema
  alias EHealth.Cabinet.Requests.{Registration, UserSearch}
  alias EHealth.Man.Templates.EmailVerification
  alias EHealth.Persons.Validator, as: PersonValidator

  require Logger

  @mpi_api Application.get_env(:ehealth, :api_resolvers)[:mpi]
  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]
  @signature_api Application.get_env(:ehealth, :api_resolvers)[:digital_signature]

  @person_active "active"
  @addresses_types ~w(REGISTRATION RESIDENCE)

  def create_patient(jwt, params, headers) do
    with {:ok, email} <- fetch_email_from_jwt(jwt),
         %Ecto.Changeset{valid?: true} <- validate_params(:patient, params),
         {:ok, %{"data" => %{"content" => content, "signer" => signer}}} <-
           @signature_api.decode_and_validate(params["signed_content"], params["signed_content_encoding"], headers),
         :ok <- JsonSchema.validate(:person, content),
         :ok <- PersonValidator.validate_birth_date(content["birth_date"], "$.birth_date"),
         :ok <- PersonValidator.validate_addresses_types(content["addresses"], @addresses_types),
         {:ok, _} <- Addresses.validate(content["addresses"]),
         {:ok, tax_id} <- validate_tax_id(content, signer),
         :ok <- validate_first_name(content, signer),
         :ok <- validate_last_name(content, signer),
         :ok <- validate_email(content, email),
         {:ok, %{"data" => mpi_person}} <-
           @mpi_api.search(
             %{"tax_id" => tax_id, "birth_date" => content["birth_date"], "status" => @person_active},
             headers
           ),
         {:ok, %{"data" => user_data}} <- @mithril_api.search_user(%{email: email}, headers),
         mithril_user <- fetch_mithril_user(user_data),
         :ok <- check_user_blocked(mithril_user),
         :ok <- check_user_by_tax_id(mithril_user),
         person_params <- prepare_person_params(content),
         {:ok, %{"data" => person}} <- create_or_update_person(mpi_person, person_params, headers),
         user_params <- prepare_user_params(tax_id, person["id"], email, params, content),
         {:ok, %{"data" => user}} <- create_or_update_user(mithril_user, user_params, headers),
         conf <- Confex.fetch_env!(:ehealth, __MODULE__),
         role_params <- %{role_id: conf[:role_id], client_id: conf[:client_id]},
         {:ok, %{"data" => _}} <- @mithril_api.create_user_role(user["id"], role_params, headers),
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

  defp validate_tax_id(%{"tax_id" => tax_id}, %{"drfo" => drfo}) when drfo == tax_id, do: {:ok, tax_id}
  defp validate_tax_id(_, _), do: {:error, {:conflict, "Registration person and person that sign should be the same"}}

  defp validate_first_name(content, signer) do
    case Map.get(signer, "given_name", "") =~ content["first_name"] do
      true -> :ok
      _ -> {:error, {:conflict, "Input first_name doesn't match name from DS"}}
    end
  end

  defp validate_last_name(%{"last_name" => last_name}, %{"surname" => surname}) when last_name == surname, do: :ok
  defp validate_last_name(_, _), do: {:error, {:conflict, "Input last_name doesn't match name from DS"}}

  def validate_email(%{"email" => signed_content_email}, jwt_email) when signed_content_email == jwt_email, do: :ok
  def validate_email(_, _), do: {:error, {:conflict, "Email in signed content is incorrect"}}

  defp prepare_person_params(content), do: Map.put(content, "patient_signed", true)

  defp create_or_update_person([], params, headers), do: @mpi_api.create_or_update_person!(params, headers)

  defp create_or_update_person(persons, _, _) when length(persons) > 1,
    do:
      {:error,
       {:conflict,
        %{
          message: "Person duplicated",
          type: :person_duplicated
        }}}

  defp create_or_update_person(persons, params, headers), do: @mpi_api.update_person(hd(persons)["id"], params, headers)

  defp prepare_user_params(tax_id, person_id, email, params, content) do
    [%{"phone_number" => phone_number}] = content["authentication_methods"]

    %{
      "2fa_enable" => true,
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
    {:error, {:conflict, %{message: "User with this tax_id already exists", type: :tax_id_exists}}}
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
         ttl <- Confex.fetch_env!(:ehealth, __MODULE__)[:jwt_ttl_registration],
         {:ok, jwt, _claims} <- generate_jwt(Guardian.get_aud(:registration), email, {ttl, :minutes}) do
      {:ok, jwt}
    end
  end

  def send_email_verification(params, headers) do
    with %Ecto.Changeset{valid?: true, changes: %{email: email}} <- validate_params(:email, params),
         true <- email_available_for_registration?(email, headers),
         false <- email_sent?(email),
         ttl <- Confex.fetch_env!(:ehealth, __MODULE__)[:jwt_ttl_email],
         {:ok, jwt, _claims} <- generate_jwt(Guardian.get_aud(:email_verification), email, {ttl, :hours}),
         {:ok, template} <- EmailVerification.render(jwt),
         email_config <- Confex.fetch_env!(:ehealth, EmailVerification),
         :ok <- send_email(email, template, email_config) do
      {:ok, jwt}
    end
  end

  defp validate_params(:email, params) do
    {%{}, %{email: :string}}
    |> cast(params, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[a-zA-Z0-9.!#$%&’*+\/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)
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
        {:error, {:conflict, %{message: "User with this email already exists", type: "email_exists"}}}

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
      Logger.error(fn ->
        Poison.encode!(%{
          "log_type" => "error",
          "message" => e.message,
          "request_id" => Logger.metadata()[:request_id]
        })
      end)

      {:error, {:internal_error, "Cannot send email. Try later"}}
  end

  def check_user_absence(jwt, params, headers) do
    with %Ecto.Changeset{valid?: true} <- validate_params(:user_search, params),
         {:ok, %{"email" => email}} <- Guardian.decode_and_verify(jwt),
         true <- email_available_for_registration?(email, headers),
         {:ok, %{"data" => %{"signer" => signer}}} <-
           @signature_api.decode_and_validate(params["signed_content"], params["signed_content_encoding"], headers),
         {:ok, tax_id} <- fetch_drfo(signer) do
      %{tax_id: tax_id}
      |> @mithril_api.search_user(headers)
      |> check_mithril_user_absence()
    end
  end

  defp fetch_drfo(%{"drfo" => drfo}), do: {:ok, drfo}
  defp fetch_drfo(_signer), do: {:error, {:conflict, %{message: "DRFO in DS not present", type: :drfo_not_present}}}

  defp check_mithril_user_absence({:ok, %{"data" => data}}) when length(data) > 0 do
    {:error, {:conflict, %{message: "User with this tax_id already exists", type: :tax_id_exists}}}
  end

  defp check_mithril_user_absence({:ok, _}), do: :ok
  defp check_mithril_user_absence(_), do: {:error, {:internal_error, "Cannot fetch user"}}
end

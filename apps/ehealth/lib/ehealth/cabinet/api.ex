defmodule EHealth.Cabinet.API do
  @moduledoc false
  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.Bamboo.Emails.Sender
  alias EHealth.Man.Templates.EmailVerification

  require Logger

  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]

  def send_email_verification(params) do
    with %Ecto.Changeset{valid?: true, changes: %{email: email}} <- validate_params(params),
         true <- email_available_for_registration?(email),
         false <- email_sent?(email),
         {:ok, jwt, _claims} <- generate_jwt(email),
         {:ok, template} <- EmailVerification.render(jwt) do
      email_config = Confex.fetch_env!(:ehealth, EmailVerification)
      send_email(email, template, email_config)
    end
  end

  defp validate_params(params) do
    {%{}, %{email: :string}}
    |> cast(params, [:email])
    |> validate_format(:email, ~r/^[a-zA-Z0-9.!#$%&’*+\/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)
  end

  def email_available_for_registration?(email) do
    case @mithril_api.search_user(%{email: email}) do
      {:ok, %{"data" => [%{"tax_id" => tax_id}]}} when is_binary(tax_id) and byte_size(tax_id) > 0 ->
        {:error, {:conflict, "User with this email already exists"}}

      {:ok, _} ->
        true

      _ ->
        {:error, {:service_unavailable, "Cannot fetch user"}}
    end
  end

  defp email_sent?(_email) do
    # ToDo: check sent email?
    false
  end

  defp generate_jwt(email) do
    ttl = Confex.fetch_env!(:ehealth, __MODULE__)[:jwt_ttl]
    EHealth.Guardian.encode_and_sign(:email, %{email: email}, token_type: "access", ttl: {ttl, :hours})
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

      {:error, {:service_unavailable, "Cannot send email. Try later"}}
  end
end

defmodule EHealth.Users.CredentialsRecoveryRequest do
  @moduledoc """
  This schema stores password reset requests.
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Jason.Encoder, except: [:__meta__]}
  schema "credentials_recovery_requests" do
    field(:user_id, :binary_id)
    field(:is_active, :boolean, default: true)
    field(:expires_at, :utc_datetime, virtual: true)
    field(:email, :string, virtual: true)

    timestamps()
  end
end

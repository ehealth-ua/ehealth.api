defmodule EHealth.Cabinet.RegistrationRequest do
  @moduledoc false

  use Ecto.Schema

  alias EHealth.Ecto.Base64

  @primary_key false
  schema "registration_request" do
    field(:otp, :integer)
    field(:password, :string)
    field(:signed_person_data, Base64)
    field(:signed_content_encoding, :string)
  end
end

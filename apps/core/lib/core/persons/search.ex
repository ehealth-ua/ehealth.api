defmodule Core.Persons.Search do
  @moduledoc false

  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  alias EView.Changeset.Validators.PhoneNumber

  @fields_required ~w(first_name last_name birth_date)a
  @fields_optional ~w(second_name tax_id unzr phone_number birth_certificate)a

  schema "persons" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:second_name, :string)
    field(:birth_date, :date)
    field(:tax_id, :string)
    field(:unzr, :string)
    field(:phone_number, :string)
    field(:birth_certificate, :string)
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
    |> PhoneNumber.validate_phone_number(:phone_number)
  end
end

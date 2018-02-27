defmodule EHealth.Persons.Search do
  @moduledoc false

  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  alias EView.Changeset.Validators.PhoneNumber

  schema "persons" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:second_name, :string)
    field(:birth_date, :date)
    field(:tax_id, :string)
    field(:phone_number, :string)
    field(:birth_certificate, :string)
  end

  def changeset(params) do
    birth_date_changeset =
      %__MODULE__{}
      |> cast(params, ~w(birth_date phone_number)a)
      |> validate_required(~w(birth_date)a)
      |> PhoneNumber.validate_phone_number(:phone_number)

    case birth_date_changeset do
      %Ecto.Changeset{valid?: true, changes: changes} ->
        age = Timex.diff(Timex.now(), Map.get(changes, :birth_date), :years)

        %__MODULE__{}
        |> cast(params, required_fields(age) ++ optional_fields(age))
        |> validate_required(required_fields(age))

      changeset ->
        changeset
    end
  end

  defp required_fields(age) when age < 16, do: ~w(birth_date birth_certificate)a

  defp required_fields(_), do: ~w(first_name last_name birth_date)a

  defp optional_fields(age) when age < 16, do: ~w(first_name last_name second_name)a

  defp optional_fields(_), do: ~w(second_name tax_id phone_number)a
end

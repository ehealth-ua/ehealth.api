defmodule EHealth.PRM.Parties do
  @moduledoc false

  use EHealth.PRM.Search

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.PRMRepo
  alias EHealth.PRM.Meta.Phone
  alias EHealth.PRM.Meta.Document
  alias EHealth.PRM.Parties.Schema, as: Party
  alias EHealth.PRM.Parties.PartyUser

  @party_users_fields ~W(
    first_name
    second_name
    last_name
    birth_date
    gender
    tax_id
    inserted_by
    updated_by
  )

  @party_users_fields_required ~W(
    first_name
    last_name
    birth_date
    gender
    tax_id
    inserted_by
    updated_by
  )a

  def get_party_user_by_id(id), do: PRMRepo.get(PartyUser, id)

  def get_party_users_by_user_id(user_id), do: get_party_users(%{user_id: user_id})

  def get_party_users_by_party_id(party_id), do: get_party_users(%{party_id: party_id})

  def get_party_users(params) do
    case party_users_changeset(params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        PartyUser
        |> get_search_query(changeset.changes)
        |> PRMRepo.all()

      changeset ->
        {:error, changeset}
    end
  end

  defp party_users_changeset(attrs) do
    search_params = %{
      user_id: Ecto.UUID,
      party_id: Ecto.UUID,
    }

    cast({%{}, search_params}, attrs, Map.keys(search_params))
  end

  defp party_changeset(attrs) do
    search_params = %{
      tax_id: :string,
      first_name: :string,
      second_name: :string,
      last_name: :string,
      birth_date: :date,
      phone_number: :string,
    }

    cast({%{}, search_params}, attrs, Map.keys(search_params))
  end

  defp party_changeset(%Party{} = party, attrs) do
    party
    |> cast(attrs, @party_users_fields)
    |> cast_embed(:phones, with: &Phone.changeset/2)
    |> cast_embed(:documents, with: &Document.changeset/2)
    |> validate_required(@party_users_fields_required)
  end

  def get_search_query(Party = entity, %{phone_number: number} = changes) do
    params =
      changes
      |> Map.delete(:phone_number)
      |> Map.to_list()

    phone_number = [%{"number" => number}]

    from e in entity,
      where: ^params,
      where: fragment("? @> ?", e.phones, ^phone_number)
  end

  def get_search_query(entity, changes), do: super(entity, changes)
end

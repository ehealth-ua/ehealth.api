defmodule EHealth.PRM.PartyUsers do
  @moduledoc false

  @moduledoc false

  use EHealth.PRM.Search

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.PRMRepo
  alias EHealth.PRM.PartyUsers.Search
  alias EHealth.PRM.PartyUsers.Schema, as: PartyUser

  @fields_required ~w(
    user_id
    party_id
  )a

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, PartyUser)
  end

  def get_search_query(entity, changes) do
    entity
    |> where(^Map.to_list(changes))
    |> join(:left, [pu], p in assoc(pu, :party))
    |> preload([pu, p], [party: p])
  end

  def get_party_user_by_id(id), do: PRMRepo.get(PartyUser, id)

  def get_party_users_by_user_id(user_id) do
    PartyUser
    |> preload(:party)
    |> PRMRepo.get_by(user_id: user_id)
  end

  def get_party_users_by_party_id(party_id), do: get_party_users(%{party_id: party_id})

  def get_party_users(params) do
    case party_users_changeset(params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        party_users =
          PartyUser
          |> where([pu], ^Map.to_list(changeset.changes))
          |> preload(:party)
          |> PRMRepo.all
        {:ok, party_users}

      changeset ->
        {:error, changeset}
    end
  end

  def create_party_user(party_id, user_id) do
    %PartyUser{}
    |> changeset(%{user_id: user_id, party_id: party_id})
    |> PRMRepo.insert_and_log(user_id)
  end

  defp party_users_changeset(attrs) do
    search_params = %{
      user_id: Ecto.UUID,
      party_id: Ecto.UUID,
    }

    cast({%{}, search_params}, attrs, Map.keys(search_params))
  end

  defp changeset(%PartyUser{} = party_user, attrs) do
    party_user
    |> cast(attrs, @fields_required)
    |> validate_required(@fields_required)
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:party_id)
  end
  defp changeset(%Search{} = search, attrs) do
    cast(search, attrs, Search.__schema__(:fields))
  end
end

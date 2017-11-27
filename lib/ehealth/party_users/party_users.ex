defmodule EHealth.PartyUsers do
  @moduledoc false

  use EHealth.Search, EHealth.PRMRepo

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.PRMRepo
  alias EHealth.PartyUsers.Search
  alias EHealth.PartyUsers.PartyUser

  @fields_required ~w(
    user_id
    party_id
  )a

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, PartyUser)
  end

  @doc """
  List all entries without pagination
  """
  def list!(params) do
    with %Ecto.Changeset{valid?: true, changes: changes} <- changeset(%Search{}, params) do
      PartyUser
      |> get_search_query(changes)
      |> PRMRepo.all()
    end
  end

  def get_search_query(entity, changes) do
    entity
    |> where(^Map.to_list(changes))
    |> join(:left, [pu], p in assoc(pu, :party))
    |> preload([pu, p], [party: p])
  end

  def create(party_id, user_id) do
    %PartyUser{}
    |> changeset(%{user_id: user_id, party_id: party_id})
    |> PRMRepo.insert_and_log(user_id)
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

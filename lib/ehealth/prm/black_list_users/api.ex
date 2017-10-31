defmodule EHealth.PRM.BlackListUsers do
  @moduledoc false

  use EHealth.PRM.Search

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.PRMRepo
  alias EHealth.PRM.Parties
  alias EHealth.API.Mithril
  alias EHealth.PRM.BlackListUsers.Search
  alias EHealth.PRM.BlackListUsers.Schema, as: BlackListUser

  @fields_required [:tax_id]
  @fields_optional [:is_active]

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, BlackListUser)
  end

  def get_search_query(entity, changes) do
    entity
    |> super(changes)
    |> load_references()
  end

  def get_by_id!(id), do: PRMRepo.get!(BlackListUser, id)

  def get_by(params), do: PRMRepo.get_by(BlackListUser, params)

  def blacklisted?(tax_id) do
    case get_by(%{tax_id: tax_id, is_active: true}) do
      nil -> false
      _ -> true
    end
  end

  def create(user_id, %{"tax_id" => tax_id}) do
    case get_by(%{tax_id: tax_id, is_active: true}) do
      nil ->
        %BlackListUser{}
        |> changeset(%{"tax_id" => tax_id})
        |> validate_user_roles()
        |> put_change(:inserted_by, user_id)
        |> put_change(:updated_by, user_id)
        |> PRMRepo.insert()
        |> load_references()

      _ ->
        {:error, {:conflict, "This user is already in a black list"}}
    end
  end
  def create(_user_id, params) do
    changeset(%BlackListUser{}, params)
  end

  defp validate_user_roles(changeset) do
    validate_change changeset, :tax_id, fn :tax_id, tax_id ->
      ids =
        tax_id
        |> Parties.get_user_ids_by_tax_id()
        |> Enum.join(",")

      case Mithril.search_user_roles(%{"user_ids" => ids}) do
        {:ok, %{"data" => []}} -> []
        {:ok, _} -> [user_roles: "Not all roles were deleted"]
        _ -> [user_roles: "Cannot fetch Mithril user roles"]
      end
    end
  end

  def deactivate(_updated_by, %BlackListUser{is_active: false}) do
    {:error, {:conflict, "User is not in a black list"}}
  end
  def deactivate(updated_by, %BlackListUser{} = black_list_user) do
    black_list_user
    |> changeset(%{is_active: false, updated_by: updated_by})
    |> PRMRepo.update()
    |> load_references()
  end

  def changeset(%Search{} = search, attrs) do
    cast(search, attrs, Search.__schema__(:fields))
  end
  def changeset(%BlackListUser{} = black_list_user, attrs) do
    black_list_user
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end

  defp load_references({:ok, entity}) do
    {:ok, load_references(entity)}
  end
  defp load_references(%Ecto.Query{} = query) do
    query
    |> join(:left, [b], p in assoc(b, :parties))
    |> preload([..., p], [parties: p])
  end
  defp load_references(%BlackListUser{} = entity) do
    PRMRepo.preload(entity, :parties)
  end
  defp load_references(err) do
    err
  end
end

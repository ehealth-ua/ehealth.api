defmodule EHealth.PRM.Parties do
  @moduledoc false

  use EHealth.PRM.Search

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.PRMRepo
  alias EHealth.PRM.Meta.Phone
  alias EHealth.PRM.Meta.Document
  alias EHealth.PRM.Parties.Schema, as: Party
  alias EHealth.PRM.Parties.Search

  # Party users

  @search_fields ~w(
    tax_id
    first_name
    second_name
    last_name
    birth_date
    phone_number
  )a

  @fields_optional ~w(
    second_name
  )a

  @fields_required ~w(
    first_name
    last_name
    birth_date
    gender
    tax_id
    inserted_by
    updated_by
  )a

  def list_parties(params) do
    %Search{}
    |> changeset(params)
    |> search(params, Party, 50)
  end

  def get_party_by_id!(id) do
    Party
    |> where([p], p.id == ^id)
    |> join(:left, [p], u in assoc(p, :users))
    |> preload([p, u], [users: u])
    |> PRMRepo.one!
  end

  def create_party(attrs) do
    with {:ok, party} <- %Party{}
                         |> changeset(attrs)
                         |> PRMRepo.insert()
    do
      {:ok, load_references(party)}
    end
  end

  def update_party(%Party{} = party, attrs) do
    with {:ok, party} <- party
                         |> changeset(attrs)
                         |> PRMRepo.update()
    do
      {:ok, load_references(party)}
    end
  end

  defp changeset(%Search{} = search, attrs) do
    cast(search, attrs, @search_fields)
  end

  defp changeset(%Party{} = party, attrs) do
    party
    |> cast(attrs, @fields_optional ++ @fields_required)
    |> cast_embed(:phones, with: &Phone.changeset/2)
    |> cast_embed(:documents, with: &Document.changeset/2)
    |> validate_required(@fields_required)
  end

  def get_search_query(Party = entity, %{phone_number: number} = changes) do
    params =
      changes
      |> Map.delete(:phone_number)
      |> Map.to_list()

    phone_number = [%{"number" => number}]

    entity
    |> where(^params)
    |> where([e], fragment("? @> ?", e.phones, ^phone_number))
    |> load_references()
  end
  def get_search_query(entity, changes) do
    entity
    |> super(changes)
    |> load_references()
  end

  defp load_references(%Ecto.Query{} = query), do: preload(query, :users)
  defp load_references(%Party{} = party), do: PRMRepo.preload(party, :users)
end

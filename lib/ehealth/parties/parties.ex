defmodule EHealth.Parties do
  @moduledoc false

  use EHealth.Search, EHealth.PRMRepo

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.PRMRepo
  alias EHealth.Parties.Phone
  alias EHealth.Parties.Document
  alias EHealth.Parties.Party
  alias EHealth.Parties.Search

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

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, Party)
  end

  def get_by_id!(id) do
    Party
    |> where([p], p.id == ^id)
    |> join(:left, [p], u in assoc(p, :users))
    |> preload([p, u], [users: u])
    |> PRMRepo.one!
  end

  def get_by_id(id) do
    PRMRepo.get(Party, id)
  end

  def get_by_ids(ids) do
    Party
    |> where([e], e.id in ^ids)
    |> PRMRepo.all()
  end

  def get_user_ids_by_tax_id(tax_id) do
    Party
    |> where([e], e.tax_id == ^tax_id)
    |> join(:inner, [p], u in assoc(p, :users))
    |> select([..., u], u.user_id)
    |> PRMRepo.all()
  end

  def create(attrs, consumer_id) do
    with {:ok, party} <-
      %Party{}
        |> changeset(attrs)
        |> PRMRepo.insert_and_log(consumer_id)
    do
      {:ok, load_references(party)}
    end
  end

  def update(%Party{} = party, attrs, consumer_id) do
    with {:ok, party} <-
      party
        |> changeset(attrs)
        |> PRMRepo.update_and_log(consumer_id)
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

defmodule Core.Parties do
  @moduledoc false

  use Core.Search, Application.get_env(:core, :repos)[:read_prm_repo]
  alias Core.Parties.Document
  alias Core.Parties.Party
  alias Core.Parties.Phone
  alias Core.Parties.Search
  alias Core.PRMRepo
  import Ecto.{Query, Changeset}, warn: false

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  # Party users

  @search_fields ~w(
    tax_id
    no_tax_id
    first_name
    second_name
    last_name
    birth_date
    phone_number
  )a

  @fields_optional ~w(
    second_name
    educations
    qualifications
    science_degree
    specialities
    declaration_limit
    about_myself
    working_experience
  )a

  @fields_required ~w(
    first_name
    last_name
    birth_date
    gender
    tax_id
    no_tax_id
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
    |> preload([p, u], users: u)
    |> @read_prm_repo.one!()
  end

  def get_by_id(id) do
    @read_prm_repo.get(Party, id)
  end

  def get_by_ids(ids) do
    Party
    |> where([e], e.id in ^ids)
    |> @read_prm_repo.all()
  end

  def get_by_user_id(user_id) do
    Party
    |> join(:inner, [p], u in assoc(p, :users))
    |> where([..., u], u.user_id == ^user_id)
    |> @read_prm_repo.one()
  end

  def get_user_ids_by_tax_id(tax_id) do
    Party
    |> where([e], e.tax_id == ^tax_id)
    |> join(:inner, [p], u in assoc(p, :users))
    |> select([..., u], u.user_id)
    |> @read_prm_repo.all()
  end

  def get_tax_id_by_user_id(user_id) do
    Party
    |> join(:inner, [p], u in assoc(p, :users))
    |> where([..., u], u.user_id == ^user_id)
    |> select([p], p.tax_id)
    |> @read_prm_repo.one()
  end

  def create(attrs, consumer_id) do
    with {:ok, party} <-
           %Party{}
           |> changeset(attrs)
           |> PRMRepo.insert_and_log(consumer_id) do
      {:ok, load_references(party)}
    end
  end

  def update(%Party{} = party, attrs, consumer_id) do
    with {:ok, party} <-
           party
           |> changeset(attrs)
           |> PRMRepo.update_and_log(consumer_id) do
      {:ok, load_references(party)}
    end
  end

  def changeset(%Search{} = search, attrs) do
    cast(search, attrs, @search_fields)
  end

  def changeset(%Party{} = party, attrs) do
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
  defp load_references(%Party{} = party), do: @read_prm_repo.preload(party, :users)
end

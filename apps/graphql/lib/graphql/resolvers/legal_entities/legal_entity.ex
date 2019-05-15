defmodule GraphQL.Resolvers.LegalEntity do
  @moduledoc false

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import Ecto.Query, only: [order_by: 2]
  import GraphQL.Filters.Base, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias GraphQL.Loaders.PRM

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_legal_entities(%{filter: filter, order_by: order_by} = args, _context) do
    LegalEntity
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  def get_legal_entity_by_id(_parent, %{id: id}, _resolution) do
    {:ok, LegalEntities.get_by_id(id)}
  end

  def load_divisions(legal_entity, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(PRM, {:divisions, args}, legal_entity)
    |> on_load(fn loader ->
      with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
        records = Dataloader.get(loader, PRM, {:divisions, args}, legal_entity)
        opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

        Connection.from_slice(Enum.take(records, limit), offset, opts)
      end
    end)
  end

  def load_employees(legal_entity, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(PRM, {:employees, args}, legal_entity)
    |> on_load(fn loader ->
      with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
        records = Dataloader.get(loader, PRM, {:employees, args}, legal_entity)
        opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

        Connection.from_slice(Enum.take(records, limit), offset, opts)
      end
    end)
  end

  def load_owner(parent, args, %{context: %{loader: loader}}) do
    args =
      Map.merge(args, %{
        first: 1,
        order_by: [desc: :updated_at],
        filter: [{:employee_type, :in, [Employee.type(:owner), Employee.type(:pharmacy_owner)]}]
      })

    loader
    |> Dataloader.load(PRM, {:employee, args}, parent)
    |> on_load(fn loader ->
      {:ok, Dataloader.get(loader, PRM, {:employee, args}, parent)}
    end)
  end

  def load_related_legal_entities(legal_entity, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(PRM, {:merged_from_legal_entities, args}, legal_entity)
    |> on_load(fn loader ->
      with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
        records = Dataloader.get(loader, PRM, {:merged_from_legal_entities, args}, legal_entity)
        opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

        Connection.from_slice(Enum.take(records, limit), offset, opts)
      end
    end)
  end

  def nhs_verify(args, %{context: %{client_id: client_id}}) do
    with {:ok, legal_entity} <- LegalEntities.nhs_verify(args, client_id, true) do
      {:ok, %{legal_entity: legal_entity}}
    end
  end

  def nhs_review(args, %{context: %{headers: headers}}) do
    with {:ok, legal_entity} <- LegalEntities.nhs_review(args, headers) do
      {:ok, %{legal_entity: legal_entity}}
    end
  end

  def nhs_comment(args, %{context: %{headers: headers}}) do
    with {:ok, legal_entity} <- LegalEntities.nhs_comment(args, headers) do
      {:ok, %{legal_entity: legal_entity}}
    end
  end

  def update_status(args, %{context: %{headers: headers}}) do
    with {:ok, legal_entity} <- LegalEntities.update_status(args, headers) do
      {:ok, %{legal_entity: legal_entity}}
    end
  end
end

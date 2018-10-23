defmodule GraphQLWeb.Loaders.EmployeeLoader do
  @moduledoc false

  import Ecto.Query

  alias Absinthe.Relay.Connection
  alias Absinthe.Resolution.Helpers, as: ResolutionHelper
  alias Core.Employees.Employee
  alias Core.PRMRepo
  alias Dataloader.Ecto

  def data, do: Ecto.new(PRMRepo, query: &query/2)

  def query(queryable, %{filter: filter, order_by: order_by} = args) do
    {:ok, :forward, limit} = Connection.limit(args)
    limit = limit + 1

    offset =
      case Connection.offset(args) do
        {:ok, offset} when is_integer(offset) -> offset
        _ -> 0
      end

    Employee
    |> where(^filter)
    |> order_by(^order_by)
    |> limit(^limit)
    |> offset(^offset)
  end

  def query(_queryable, _args), do: from(l in Employee)

  def load_employees(legal_entity, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(__MODULE__, {:employees, args}, legal_entity)
    |> ResolutionHelper.on_load(fn loader ->
      {:ok, :forward, limit} = Connection.limit(args)

      offset =
        case Connection.offset(args) do
          {:ok, offset} when is_integer(offset) -> offset
          _ -> 0
        end

      records = Dataloader.get(loader, __MODULE__, {:employees, args}, legal_entity)
      opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

      Connection.from_slice(Enum.take(records, limit), offset, opts)
    end)
  end
end

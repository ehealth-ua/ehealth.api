defmodule GraphQLWeb.Dataloader.RPC do
  @moduledoc """
  RPC based Dataloader source.
  """

  alias Absinthe.Relay.Connection

  defstruct [
    :rpc_name,
    batches: %{},
    results: %{},
    options: []
  ]

  def new(rpc_name, opts \\ []) when is_binary(rpc_name) do
    %__MODULE__{
      rpc_name: rpc_name,
      options: [
        timeout: opts[:timeout] || 30_000
      ]
    }
  end

  defimpl Dataloader.Source do
    @rpc_worker Application.get_env(:core, :rpc_worker)

    def run(%{batches: batches} = source) do
      results = Dataloader.async_safely(Dataloader, :run_tasks, [batches, &handle_batch(source, &1)])

      %{source | batches: %{}, results: results}
    end

    defp handle_batch(source, {{{rpc_function, :one, _item_key, foreign_key}, _}, foreign_ids}) do
      filter = [{foreign_key, :in, MapSet.to_list(foreign_ids)}]

      with {:ok, results} <- @rpc_worker.run(source.rpc_name, Core.Rpc, rpc_function, [filter]) do
        Enum.into(results, %{}, fn item -> {Map.get(item, foreign_key), item} end)
      end
    end

    defp handle_batch(source, {{rpc_function, :many, foreign_key, args}, item_ids}) do
      with {:ok, params} <- prepare_params(args, foreign_key, item_ids),
           {:ok, results} <- @rpc_worker.run(source.rpc_name, Core.Rpc, rpc_function, params) do
        Enum.group_by(results, &Map.get(&1, foreign_key))
      end
    end

    def load(%{results: results} = source, batch_key, item) when results == %{} do
      item_key = resolve_item_key(batch_key)
      item_id = Map.get(item, item_key)

      update_in(source.batches, fn batches ->
        Map.update(batches, batch_key, MapSet.new([item_id]), &MapSet.put(&1, item_id))
      end)
    end

    def load(source, _batch_key, _item), do: source

    def fetch(%{results: results}, batch_key, item) do
      item_key = resolve_item_key(batch_key)
      item_id = Map.get(item, item_key)

      batch =
        Enum.find(results, fn
          {{^batch_key, _item_ids}, {:ok, value}} -> value
        end)

      case batch do
        {{^batch_key, _item_ids}, {:ok, %{^item_id => result}}} -> {:ok, result}
        _ -> {:error, "Unable to find batch #{inspect(batch_key)}"}
      end
    end

    def put(source, _batch, _id, _result), do: source

    def pending_batches?(%{batches: batches}) do
      batches != %{}
    end

    def timeout(%{options: options}) do
      options[:timeout]
    end

    defp resolve_item_key({{_, :one, item_key, _}, _}), do: item_key
    defp resolve_item_key(_), do: :id

    defp prepare_params(args, foreign_key, %{} = item_ids) do
      filter = args[:filter] || []
      filter = [{foreign_key, :in, MapSet.to_list(item_ids)} | filter]
      order_by = Map.get(args, :order_by, [])

      with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
        {:ok, [filter, order_by, {offset, limit}]}
      end
    end
  end
end

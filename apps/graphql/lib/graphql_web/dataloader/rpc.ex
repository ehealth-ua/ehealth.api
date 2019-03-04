defmodule GraphQLWeb.Dataloader.RPC do
  @moduledoc """
  RPC based Dataloader source.
  """

  alias Absinthe.Relay.Connection

  defstruct [
    :rpc_name,
    :rpc_module,
    batches: %{},
    results: %{},
    options: []
  ]

  def new(rpc_name, rpc_module, opts \\ []) when is_binary(rpc_name) and is_atom(rpc_module) do
    %__MODULE__{
      rpc_name: rpc_name,
      rpc_module: rpc_module,
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

    defp handle_batch(source, batch_key) do
      case batch_key do
        {{{rpc_function, :one, _item_key, foreign_key}, _}, foreign_ids} ->
          do_handle_batch(source, :one, MapSet.to_list(foreign_ids), rpc_function, foreign_key)

        {{rpc_function, :many, foreign_key, args}, item_ids} ->
          do_handle_batch(source, :many, MapSet.to_list(item_ids), rpc_function, foreign_key, args)

        _ ->
          raise "Invalid batch key"
      end
    end

    defp do_handle_batch(_, :one, [], _, _), do: %{}

    defp do_handle_batch(source, :one, foreign_ids, rpc_function, foreign_key) do
      filter = [{foreign_key, :in, foreign_ids}]

      with {:ok, results} <- @rpc_worker.run(source.rpc_name, source.rpc_module, rpc_function, [filter]) do
        Enum.into(results, %{}, fn item -> {Map.get(item, foreign_key), item} end)
      end
    end

    defp do_handle_batch(_, :many, [], _, _, _), do: %{}

    defp do_handle_batch(source, :many, item_ids, rpc_function, foreign_key, args) do
      with {:ok, params} <- prepare_params(args, foreign_key, item_ids),
           {:ok, results} <- @rpc_worker.run(source.rpc_name, source.rpc_module, rpc_function, params) do
        Enum.group_by(results, &Map.get(&1, foreign_key))
      end
    end

    def load(%{results: results} = source, batch_key, item) when results == %{} do
      item_key = resolve_item_key(batch_key)
      item_id = Map.get(item, item_key)

      update_in(source.batches, fn batches ->
        if item_id != nil do
          Map.update(batches, batch_key, MapSet.new([item_id]), &MapSet.put(&1, item_id))
        else
          batches
        end
      end)
    end

    def load(source, _batch_key, _item), do: source

    def fetch(%{results: results}, batch_key, item) do
      item_key = resolve_item_key(batch_key)
      item_id = Map.get(item, item_key)

      batch =
        Enum.find(results, fn
          {{^batch_key, _item_ids}, {:ok, value}} -> value
          _ -> %{}
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

    defp prepare_params(args, foreign_key, item_ids) when is_list(item_ids) do
      filter = args[:filter] || []
      filter = [{foreign_key, :in, item_ids} | filter]
      order_by = Map.get(args, :order_by, [])

      with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
        {:ok, [filter, order_by, {offset, limit}]}
      end
    end
  end
end

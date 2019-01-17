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

    def run(source) do
      batch_hander = fn {{rpc_function, parent_attr, args}, parent_ids} ->
        filter = args[:filter] || []
        filter = [{parent_attr, :in, MapSet.to_list(parent_ids)} | filter]
        order_by = Map.get(args, :order_by, [])

        with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []),
             {:ok, results} <-
               @rpc_worker.run(source.rpc_name, Core.Rpc, rpc_function, [filter, order_by, {offset, limit}]) do
          Enum.group_by(results, &Map.get(&1, parent_attr))
        end
      end

      results = Dataloader.async_safely(Dataloader, :run_tasks, [source.batches, batch_hander])

      %{source | batches: %{}, results: results}
    end

    def load(%{results: results} = source, batch_key, %{id: parent_id}) when results == %{} do
      update_in(source.batches, fn batches ->
        Map.update(batches, batch_key, MapSet.new([parent_id]), &MapSet.put(&1, parent_id))
      end)
    end

    def load(source, _batch_key, _item), do: source

    def fetch(%{results: results}, batch_key, %{id: parent_id}) do
      batch =
        Enum.find(results, fn
          {{^batch_key, _ids}, {:ok, value}} -> value
        end)

      # TODO: remove after debug
      if Mix.env() != :test do
        IO.puts("batch: #{inspect(batch)}")
        IO.puts("batch_key: #{inspect(batch_key)}")
      end

      case batch do
        {{^batch_key, _ids}, {:ok, %{^parent_id => result}}} -> {:ok, result}
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
  end
end

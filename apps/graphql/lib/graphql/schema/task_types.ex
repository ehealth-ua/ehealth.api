defmodule GraphQL.Schema.TaskTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  input_object :task_filter do
    field(:status, :task_status)
  end

  enum :task_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection node_type: :task do
    field :nodes, list_of(:task) do
      resolve(fn
        _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  node object(:task) do
    field(:database_id, non_null(:object_id))
    field(:name, :string)
    field(:priority, :integer)
    field(:status, non_null(:task_status))
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
    field(:ended_at, :datetime)
  end

  enum :task_status do
    value(:aborted, as: "ABORTED")
    value(:consumed, as: "CONSUMED")
    value(:failed, as: "FAILED")
    value(:new, as: "NEW")
    value(:pending, as: "PENDING")
    value(:processed, as: "PROCESSED")
    value(:rescued, as: "RESCUED")
  end
end

defmodule GraphQLWeb.Schema.DeclarationTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias GraphQLWeb.Loaders.PRM

  input_object :pending_declaration_filter do
    field(:reason, :pending_declaration_reason)
  end

  enum :pending_declaration_reason do
    value(:no_tax_id, as: "no_tax_id")
  end

  enum :declaration_order_by do
    value(:no_tax_id_asc)
    value(:no_tax_id_desc)
    value(:start_date_asc)
    value(:start_date_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection node_type: :declaration do
    field :nodes, list_of(:declaration) do
      resolve(fn
        _, %{source: conn} ->
          nodes = conn.edges |> Enum.map(& &1.node)
          {:ok, nodes}
      end)
    end

    edge(do: nil)
  end

  node object(:declaration) do
    field(:database_id, non_null(:id))
    field(:declaration_number, non_null(:string))
    field(:start_date, non_null(:date))
    field(:end_date, non_null(:date))
    field(:signed_at, non_null(:datetime))
    field(:status, non_null(:declaration_status))
    field(:scope, non_null(:string))
    field(:reason, :string)
    field(:reason_description, :string)
    field(:legal_entity, non_null(:legal_entity), resolve: dataloader(PRM))

    # TODO: resolve person
    # field(:person, non_null(:person), resolve: dataloader(MPI))

    field(:division, non_null(:division), resolve: dataloader(PRM))
    field(:employee, non_null(:employee), resolve: dataloader(PRM))
    field(:declaration_attached_documents, list_of(:declaration_attached_document))
  end

  enum :declaration_status do
    value(:active, as: "ACTIVE")
    value(:pending_verification, as: "PENDING_VERIFICATION")
    value(:rejected, as: "REJECTED")
    value(:terminated, as: "TERMINATED")
  end

  object :declaration_attached_document do
    field(:type, non_null(:string))
    field(:url, non_null(:string))
  end
end

defmodule GraphQL.Resolvers.Contract do
  @moduledoc false

  alias Core.ContractRequests.RequestPack
  alias Core.Contracts

  defmacro __using__(opts) do
    quote do
      import Absinthe.Resolution.Helpers, only: [on_load: 2]
      import Ecto.Query, only: [join: 4, where: 3]
      import GraphQL.Filters.Contracts, only: [filter: 2]
      import GraphQL.Resolvers.Helpers.Load, only: [load_by_parent_with_connection: 4]

      alias Absinthe.Relay.Connection
      alias Core.ContractRequests
      alias Core.Contracts.Storage
      alias Ecto.Query
      alias GraphQL.Loaders.IL

      @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

      @schema unquote(opts[:schema])
      @request_schema unquote(opts[:request_schema])

      def list_contracts(args, %{context: %{client_type: "NHS"}}), do: list_contracts(args)

      def list_contracts(args, %{context: %{client_type: unquote(opts[:restricted_client_type]), client_id: client_id}}) do
        args
        |> Map.update!(:filter, &[{:contractor_legal_entity_id, :equal, client_id} | &1])
        |> list_contracts()
      end

      def list_contracts(%{filter: filter, order_by: order_by} = args) do
        @schema
        |> where([c], c.type == ^@schema.type())
        |> filter(filter)
        |> order_by(order_by)
        |> Connection.from_query(&@read_prm_repo.all/1, args)
      end

      defp order_by(query, [{direction, :contractor_legal_entity_edrpou}]) do
        query
        |> join(:inner, [c], le in assoc(c, :contractor_legal_entity))
        |> Query.order_by([..., le], [{^direction, le.edrpou}])
      end

      defp order_by(query, [{direction, :medical_program_name}]) do
        query
        |> join(:inner, [c], mp in assoc(c, :medical_program))
        |> Query.order_by([..., mp], [{^direction, mp.name}])
      end

      defp order_by(query, order_by), do: Query.order_by(query, ^order_by)

      def get_attached_documents(%{__struct__: @schema} = parent, args, %{context: %{loader: loader}}) do
        source = IL
        batch_key = {@request_schema, args}
        item_key = parent.contract_request_id

        loader
        |> Dataloader.load(source, batch_key, item_key)
        |> on_load(fn loader ->
          with %{__struct__: @request_schema, id: id, status: _status} <-
                 Dataloader.get(loader, source, batch_key, item_key),
               contract_documents when is_list(contract_documents) <- Storage.gen_relevant_get_links(parent.id),
               contract_request_documents when is_list(contract_request_documents) <-
                 ContractRequests.gen_relevant_get_links(id, "APPROVED") do
            {:ok, contract_documents ++ contract_request_documents}
          else
            nil -> {:error, "Contract request not found"}
            err -> {:error, "Cannot get attachedDocuments with `#{inspect(err)}`"}
          end
        end)
      end

      def load_contract_divisions(parent, args, resolution) do
        load_by_parent_with_connection(parent, args, resolution, :divisions)
      end
    end
  end

  def get_printout_content(%{__struct__: _} = contract, _args, %{context: context}) do
    with {:ok, printout_form} <- Contracts.get_printout_content(contract, context.client_type, context.headers) do
      {:ok, printout_form}
    else
      {:error, {:conflict, _}} -> {:ok, nil}
      err -> err
    end
  end

  def terminate(%{id: %{id: id, type: type}} = args, %{context: %{headers: headers}}) do
    params = %{
      "type" => RequestPack.get_type_by_atom(type),
      "reason" => args[:reason],
      "status_reason" => args[:status_reason]
    }

    with {:ok, contract} <- Contracts.terminate(id, params, headers) do
      {:ok, %{contract: contract}}
    end
  end

  def prolongate(%{id: %{id: id, type: _type}, end_date: end_date}, %{context: %{headers: headers}}) do
    params = %{"end_date" => to_string(end_date)}

    with {:ok, contract, _} <- Contracts.prolongate(id, params, headers) do
      {:ok, %{contract: contract}}
    end
  end

  def suspend(%{id: %{id: id, type: type}} = args, %{context: %{consumer_id: consumer_id}}) do
    args = Map.delete(args, :id)
    type = RequestPack.get_type_by_atom(type)

    with {:ok, contract} <- Contracts.fetch_by_id(id, type),
         {:ok, contract} <- Contracts.suspend(contract, args, consumer_id) do
      {:ok, %{contract: contract}}
    end
  end
end

defmodule GraphQLWeb.Resolvers.ContractResolver do
  @moduledoc false

  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]

  alias Core.ContractRequests.RequestPack
  alias Core.Contracts
  alias GraphQLWeb.Resolvers.ContractRequestResolver

  defmacro __using__(opts) do
    quote do
      import Absinthe.Resolution.Helpers, only: [on_load: 2]
      import Ecto.Query, only: [join: 4, where: 3]
      import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_parent_with_connection: 4]

      alias Absinthe.Relay.Connection
      alias Core.ContractRequests
      alias Core.Contracts.Storage
      alias Core.PRMRepo
      alias Ecto.Query
      alias GraphQL.Helpers.Filtering
      alias GraphQLWeb.Loaders.IL

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
        |> Connection.from_query(&PRMRepo.all/1, args)
      end

      defp filter(query, []), do: query

      defp filter(query, [{:legal_entity_relation, :equal, :merged_from} | tail]) do
        query
        |> join(:inner, [r], assoc(r, :merged_from))
        |> where([..., m], m.is_active)
        |> filter(tail)
      end

      defp filter(query, [{:legal_entity_relation, :equal, :merged_to} | tail]) do
        query
        |> join(:inner, [r], assoc(r, :merged_to))
        |> where([..., m], m.is_active)
        |> filter(tail)
      end

      # BUG: When association condition goes before regular conditions,
      # all following conditions will be applied to the associated table
      defp filter(query, [condition | tail]) do
        query
        |> Filtering.filter([condition])
        |> filter(tail)
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

  def get_printout_content(%{type: type, contract_request_id: contract_request_id}, args, resolution) do
    provider = RequestPack.get_provider_by_type(type)

    with {:ok, contract_request} <- provider.fetch_by_id(contract_request_id) do
      ContractRequestResolver.get_printout_content(contract_request, args, resolution)
    else
      err -> render_error(err)
    end
  end

  def terminate(%{id: %{id: id, type: type}, status_reason: status_reason}, %{context: %{headers: headers}}) do
    params = %{"status_reason" => status_reason, "type" => RequestPack.get_type_by_atom(type)}

    with {:ok, contract} <- Contracts.terminate(id, params, headers) do
      {:ok, %{contract: contract}}
    else
      err -> render_error(err)
    end
  end

  def prolongate(%{id: %{id: id, type: _type}, end_date: end_date}, %{context: %{headers: headers}}) do
    params = %{"end_date" => to_string(end_date)}

    with {:ok, contract, _} <- Contracts.prolongate(id, params, headers) do
      {:ok, %{contract: contract}}
    else
      err -> render_error(err)
    end
  end
end

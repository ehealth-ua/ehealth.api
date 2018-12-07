defmodule GraphQLWeb.Resolvers.ContractResolver do
  @moduledoc false

  import Ecto.Query, only: [join: 4]
  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]

  alias Core.Contracts
  alias Core.Contracts.CapitationContract
  alias Ecto.Query
  alias GraphQL.Helpers.Filtering

  @capitation CapitationContract.type()

  def filter(query, []), do: query

  def filter(query, [{:legal_entity_relation, :equal, :merged_from} | tail]) do
    query
    |> join(:inner, [r], assoc(r, :merged_from))
    |> filter(tail)
  end

  def filter(query, [{:legal_entity_relation, :equal, :merged_to} | tail]) do
    query
    |> join(:inner, [r], assoc(r, :merged_to))
    |> filter(tail)
  end

  def filter(query, [condition | tail]) do
    query
    |> Filtering.filter([condition])
    |> filter(tail)
  end

  def order_by(query, [{direction, :contractor_legal_entity_edrpou}]) do
    query
    |> join(:inner, [c], le in assoc(c, :contractor_legal_entity))
    |> Query.order_by([..., le], [{^direction, le.edrpou}])
  end

  def order_by(query, [{direction, :medical_program_name}]) do
    query
    |> join(:inner, [c], mp in assoc(c, :medical_program))
    |> Query.order_by([..., mp], [{^direction, mp.name}])
  end

  def order_by(query, order_by), do: Query.order_by(query, ^order_by)

  def terminate(%{id: %{id: id, type: _type}, status_reason: status_reason}, %{context: %{headers: headers}}) do
    params = %{"status_reason" => status_reason, "type" => @capitation}

    with {:ok, contract, _references} <- Contracts.terminate(id, params, headers) do
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

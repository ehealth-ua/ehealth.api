defmodule GraphQLWeb.Resolvers.DeclarationResolver do
  @moduledoc false

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import Core.Utils.TypesConverter, only: [strings_to_keys: 1]
  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]

  alias Absinthe.Relay.Connection
  alias Core.DeclarationRequests.API.Documents, as: DeclarationRequestDocuments
  alias Core.Declarations.API, as: Declarations
  alias Core.Declarations.Declaration
  alias Ecto.Schema.Metadata
  alias GraphQLWeb.Loaders.IL

  @status_pending "pending_verification"
  @status_active "active"
  @status_rejected "rejected"

  def list_pending_declarations(%{filter: filter, order_by: order_by} = args, _resolution) do
    filter = [{:status, :equal, @status_pending} | filter]

    with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []),
         {:ok, declarations} <- Declarations.list(filter, order_by, {offset, limit + 1}) do
      opts = [has_previous_page: offset > 0, has_next_page: length(declarations) > limit]

      Connection.from_slice(Enum.take(declarations, limit), offset, opts)
    else
      err -> render_error(err)
    end
  end

  def get_declaration_by_id(_parent, %{id: id}, _resolution) do
    do_get_declaration(id: id)
  end

  def get_declaration_by_number(_parent, %{declaration_number: declaration_number}, _resolution) do
    do_get_declaration(declaration_number: declaration_number)
  end

  defp do_get_declaration(params) when is_list(params) do
    with {:ok, declaration} <- Declarations.get_declaration_by(params) do
      {:ok, declaration}
    else
      err -> render_error(err)
    end
  end

  def resolve_attached_documents(parent, _args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(IL, :declaration_request, parent)
    |> on_load(fn loader ->
      with %{} = declaration_request <- Dataloader.get(loader, IL, :declaration_request, parent),
           {:ok, documents} <- DeclarationRequestDocuments.generate_links(declaration_request) do
        {:ok, documents}
      else
        _ -> {:ok, []}
      end
    end)
  end

  def approve_declaration(%{id: id}, %{context: %{consumer_id: consumer_id, headers: headers}}) do
    patch = %{"status" => @status_active, "updated_by" => consumer_id}

    update_declaration(id, patch, headers)
  end

  def reject_declaration(%{id: id}, %{context: %{consumer_id: consumer_id, headers: headers}}) do
    patch = %{"status" => @status_rejected, "updated_by" => consumer_id}

    update_declaration(id, patch, headers)
  end

  defp update_declaration(id, patch, headers) do
    with {:ok, %{"data" => declaration}} <- Declarations.update_declaration(id, patch, headers) do
      declaration = api_response_to_ecto_struct(Declaration, declaration)

      {:ok, %{declaration: declaration}}
    else
      err -> render_error(err)
    end
  end

  def terminate_declaration(
        %{id: id} = args,
        %{context: %{consumer_id: consumer_id, headers: headers}}
      ) do
    params = %{"reason_description" => args[:reason_description]}

    with {:ok, declaration} <- Declarations.terminate(id, consumer_id, params, headers, false) do
      declaration = api_response_to_ecto_struct(Declaration, declaration)

      {:ok, %{declaration: declaration}}
    else
      err -> render_error(err)
    end
  end

  defp api_response_to_ecto_struct(schema, response) do
    schema
    |> struct(strings_to_keys(response))
    |> Map.put(:__meta__, %Metadata{state: :build, source: {nil, nil}})
  end
end

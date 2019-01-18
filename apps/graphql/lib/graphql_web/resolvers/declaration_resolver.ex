defmodule GraphQLWeb.Resolvers.DeclarationResolver do
  @moduledoc false

  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]

  alias Absinthe.Relay.Connection
  alias Core.Declarations.API, as: Declarations

  @status_pending "pending_verification"

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
end

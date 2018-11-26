defmodule EHealth.Web.Plugs.ContractType do
  @moduledoc false

  alias Ecto.UUID

  @contract_types ~w(reimbursement capitation)
  @capitation "capitation"

  @contract_path ~w(contracts contract_requests)

  def init(opts), do: opts

  # valid contract_type
  def call(%{path_info: [_, path, type | _]} = conn, _opts) when path in @contract_path and type in @contract_types do
    conn
  end

  # set default contract_type for get by id requests without contract_type param in path
  def call(%{path_info: [_, path, id | _]} = conn, _opts) when path in @contract_path do
    case UUID.cast(id) do
      {:ok, _} ->
        Map.put(conn, :path_info, List.insert_at(conn.path_info, 2, @capitation))

      _ ->
        raise Phoenix.Router.NoRouteError, conn: conn, router: EHealthWeb.Router
    end
  end

  # set default contract_type for list requests without contract_type param in path
  def call(%{path_info: [_, path]} = conn, _opts) when path in @contract_path do
    Map.put(conn, :path_info, List.insert_at(conn.path_info, 2, @capitation))
  end

  # not contract requests
  def call(conn, _opts), do: conn

  def upcase_contract_type_param(%{params: %{"type" => type} = params} = conn, _opts) do
    Map.put(conn, :params, Map.put(params, "type", String.upcase(type)))
  end

  def upcase_contract_type_param(conn, _), do: conn
end

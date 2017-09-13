defmodule EHealth.Declarations.Person do
  @moduledoc false

  alias EHealth.API.OPS
  import EHealth.Declarations.API, only: [expand_declaration_relations: 2]

  @status_new "NEW"
  @status_merged "MERGED"
  @status_inactive "INACTIVE"

  @declaration_status_active "active"

  def status(:new), do: @status_new
  def status(:merged), do: @status_merged
  def status(:inactive), do: @status_inactive

  def get_person_declaration(person_id, headers) do
    query_params = %{"person_id" => person_id, "status" => "active,pending_verification", "is_active" => true}
    with {:ok, resp}        <- OPS.get_declarations(query_params, headers),
         {:ok, declaration} <- check_declarations_amount(Map.fetch!(resp, "data")),
         {:ok, data}        <- expand_declaration_relations(declaration, headers),
         response           <- %{"meta" => Map.fetch!(resp, "meta"), "data" => data},
      do: {:ok, response}
  end

  # one declaration, it's good
  def check_declarations_amount([declaration]), do: {:ok, declaration}

  # declarations not found, return 404
  def check_declarations_amount([]), do: {:error, :not_found}

  # declarations more than one, return 400
  def check_declarations_amount(declarations) do
    decl_active = Enum.filter(declarations, fn (declaration) -> declaration["status"] == @declaration_status_active end)
    case length(decl_active) do
      1 -> {:ok, List.first(decl_active)}
      _ -> {:error, {:bad_request, "A person has more than one active declaration."}}
    end
  end

end

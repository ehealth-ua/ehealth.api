defmodule Jobs.Jabba.Task do
  @moduledoc """
  Jabba Task structure
  """

  @type t :: %__MODULE__{name: String.t(), callback: Atom.t()}
  defstruct ~w(callback name)a

  @enforce_keys ~w(callback)

  @merge_legal_entity_type :merge_legal_entity

  @deactivate_legal_entity_type :deactivate_legal_entity
  @deactivate_employee_type :deactivate_employee
  @deactivate_contract_type :deactivate_contract
  @deactivate_contract_request_type :deactivate_contract_request

  @deactivate_legal_entity_types [
    @deactivate_legal_entity_type,
    @deactivate_employee_type,
    @deactivate_contract_type,
    @deactivate_contract_request_type
  ]

  def new(
        @merge_legal_entity_type,
        %{
          reason: _,
          headers: _,
          merged_from_legal_entity: _,
          merged_to_legal_entity: _,
          signed_content: _
        } = arg
      ) do
    callback = {"ehealth", Jobs.LegalEntityMergeJob, :merge, [arg]}

    struct(__MODULE__, %{name: "Merge legal entity", callback: callback})
  end

  def new(type, entity, actor_id) when type in @deactivate_legal_entity_types do
    callback = {"ehealth", Jobs.LegalEntityDeactivationJob, :deactivate, [entity, actor_id]}

    struct(__MODULE__, %{name: type_to_name(type), callback: callback})
  end

  defp type_to_name(type), do: type |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  def type(:merge_legal_entity), do: @merge_legal_entity_type
  def type(:deactivate_legal_entity), do: @deactivate_legal_entity_type
  def type(:deactivate_employee), do: @deactivate_employee_type
  def type(:deactivate_contract), do: @deactivate_contract_type
  def type(:deactivate_contract_request), do: @deactivate_contract_request_type
end

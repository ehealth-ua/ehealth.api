defmodule Core.V2.LegalEntities do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  use Core.Search, Application.get_env(:core, :repos)[:read_prm_repo]

  alias Core.EmployeeRequests
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.OAuth.API, as: OAuth
  alias Core.V2.LegalEntities.Validator
  alias Core.V2.Registries
  alias Ecto.UUID

  require Logger

  @msp LegalEntity.type(:msp)
  @pharmacy LegalEntity.type(:pharmacy)
  @msp_pharmacy LegalEntity.type(:msp_pharmacy)

  # Create legal entity

  def create(params, headers) do
    with {:ok, request_params} <- Validator.decode_and_validate(params, headers),
         edrpou <- Map.fetch!(request_params, "edrpou"),
         type <- Map.fetch!(request_params, "type"),
         {:ok, legal_entity} <- get_or_create_by_edrpou_type(edrpou, type),
         :ok <- check_status(legal_entity),
         {:ok, _} <- store_signed_content(legal_entity.id, params, headers),
         request_params <- put_mis_verified_state(request_params),
         {:ok, legal_entity} <- put_legal_entity_to_prm(legal_entity, request_params, headers),
         {:ok, client_type_id} <- get_client_type_id(type, headers),
         {:ok, client, client_connection} <-
           OAuth.upsert_client_with_connection(legal_entity, client_type_id, request_params, headers),
         {:ok, security} <- prepare_security_data(client, client_connection),
         {:ok, employee_request} <- create_employee_request(legal_entity, request_params) do
      {:ok,
       %{
         legal_entity: legal_entity,
         employee_request: employee_request,
         security: security
       }}
    end
  end

  defp put_mis_verified_state(%{"edrpou" => edrpou, "type" => type} = request_params) do
    Map.put(request_params, "mis_verified", Registries.get_edrpou_verified_status(edrpou, type))
  end

  defp create_employee_request(%LegalEntity{id: id}, request_params) do
    party = Map.fetch!(request_params, "owner")

    id
    |> prepare_employee_request_data(party)
    |> put_in(["employee_request", "employee_type"], Employee.type(:owner))
    |> EmployeeRequests.create_owner()
  end

  defp get_or_create_by_edrpou_type(edrpou, type) do
    %{edrpou: edrpou}
    |> list()
    |> Map.get(:entries)
    |> update_type_allow?(type)
  end

  defp update_type_allow?([], _type), do: {:ok, %LegalEntity{id: UUID.generate()}}
  defp update_type_allow?([%LegalEntity{type: type} = legal_entity], type), do: {:ok, legal_entity}
  defp update_type_allow?([%LegalEntity{type: @msp} = legal_entity], @msp_pharmacy), do: {:ok, legal_entity}
  defp update_type_allow?([%LegalEntity{type: @pharmacy} = legal_entity], @msp_pharmacy), do: {:ok, legal_entity}

  defp update_type_allow?([%LegalEntity{type: current_type}], type),
    do: {:error, {:not_implemented, "LegalEntity with #{current_type} could not be updated to #{type} for now"}}

  defdelegate list(params), to: LegalEntities
  defdelegate check_status(legal_entity), to: LegalEntities
  defdelegate store_signed_content(legal_entity_id, params, headers), to: LegalEntities
  defdelegate put_legal_entity_to_prm(legal_entity, request_params, headers), to: LegalEntities
  defdelegate get_client_type_id(type, headers), to: LegalEntities
  defdelegate prepare_security_data(client, client_connection), to: LegalEntities
  defdelegate prepare_employee_request_data(legal_entity_id, party), to: LegalEntities
end

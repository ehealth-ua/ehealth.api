defmodule EHealth.PRM.LegalEntities do
  @moduledoc false

  alias EHealth.PRMRepo
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.LegalEntities.Search
  use EHealth.PRM.Search

  @search_fields ~w(
    id
    ids
    edrpou
    type
    status
    owner_property_type
    legal_form
    nhs_verified
    is_active
    settlement_id
    created_by_mis_client_id
    mis_verified
  )a

  @required_fields ~w(
    name
    status
    type
    owner_property_type
    legal_form
    edrpou
    kveds
    addresses
    inserted_by
    updated_by
    mis_verified
  )a

  @optional_fields ~w(
    id
    short_name
    public_name
    phones
    email
    is_active
    nhs_verified
    created_by_mis_client_id
  )a

  def get_legal_entity_by_id(id) do
    id
    |> get_legal_entity_by_id_query()
    |> PRMRepo.one()
  end

  def get_legal_entity_by_id!(id) do
    id
    |> get_legal_entity_by_id_query()
    |> PRMRepo.one!()
  end

  defp get_legal_entity_by_id_query(id) do
    LegalEntity
    |> where([le], le.id == ^id)
    |> join(:left, [le], msp in assoc(le, :medical_service_provider))
    |> preload([le, msp], [medical_service_provider: msp])
  end

  def get_legal_entities(params \\ %{}) do
    %Search{}
    |> changeset(params)
    |> search(params, LegalEntity, Confex.get_env(:ehealth, :legal_entities_per_page))
    |> preload_msp()
  end

  def get_legal_entity_by_edrpou(edrpou) do
    get_legal_entities(%{edrpou: edrpou, type: "MSP"})
  end

  def get_search_query(LegalEntity = entity, %{ids: _ids} = changes) do
    super(entity, convert_comma_params_to_where_in_clause(changes, :ids, :id))
  end

  def get_search_query(LegalEntity = entity, %{settlement_id: settlement_id} = changes) do
    params =
      changes
      |> Map.delete(:settlement_id)
      |> Map.to_list()

    address_params = [%{settlement_id: settlement_id}]

    from e in entity,
      where: ^params,
      where: fragment("? @> ?", e.addresses, ^address_params)
  end
  def get_search_query(entity, changes), do: super(entity, changes)

  defp changeset(%Search{} = legal_entity, attrs) do
    cast(legal_entity, attrs, @search_fields)
  end
  defp changeset(%LegalEntity{} = legal_entity, attrs) do
    legal_entity
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:medical_service_provider)
    |> validate_required(@required_fields)
    |> validate_msp_required()
    |> unique_constraint(:edrpou)
  end

  defp validate_msp_required(%Ecto.Changeset{changes: %{type: "MSP"}} = changeset) do
    validate_required(changeset, [:medical_service_provider])
  end
  defp validate_msp_required(changeset), do: changeset

  defp preload_msp({legal_entities, %Ecto.Paging{} = paging}) when length(legal_entities) > 0 do
    {PRMRepo.preload(legal_entities, :medical_service_provider), paging}
  end
  defp preload_msp({:ok, legal_entity}) do
    {:ok, PRMRepo.preload(legal_entity, :medical_service_provider)}
  end
  defp preload_msp(err), do: err

  defp convert_comma_params_to_where_in_clause(changes, param_name, db_field) do
    changes
    |> Map.put(db_field, {String.split(changes[param_name], ","), :in})
    |> Map.delete(param_name)
  end
end

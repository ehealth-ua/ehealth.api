defmodule Core.Services do
  @moduledoc false

  import Ecto.{Changeset, Query}, warn: false

  alias Core.PRMRepo
  alias Core.Services.ProgramService
  alias Core.Services.Service
  alias Core.Services.ServiceGroup
  alias Core.Services.ServicesGroups
  alias Core.Validators.JsonSchema

  @service_fields_required ~w(name code)a
  @service_fields_optional ~w(category parent_id is_composition request_allowed is_active)a

  @service_group_fields_required ~w(name code)a
  @service_group_fields_optional ~w(parent_id request_allowed is_active)a

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list do
    service_groups = PRMRepo.all(ServiceGroup)
    services = PRMRepo.all(Service)
    services_groups = PRMRepo.all(ServicesGroups)

    tree =
      service_groups
      |> Enum.reduce(%{}, fn service_group, acc ->
        Map.put(acc, service_group.id, %{node: service_group, groups: [], services: []})
      end)

    tree =
      Enum.reduce(tree, tree, fn {service_group_id, service_group}, acc ->
        parent_id = service_group.node.parent_id

        if parent_id do
          {_, parent} = Enum.find(acc, fn {k, _} -> k == parent_id end)
          Map.put(acc, parent_id, Map.put(parent, :groups, [service_group_id | parent.groups]))
        else
          acc
        end
      end)

    services_groups =
      Enum.map(services_groups, fn services_group ->
        service = Enum.find(services, fn service -> service.id == services_group.service_id end)
        %{service: service, services_group: services_group}
      end)

    Enum.reduce(services_groups, tree, fn %{services_group: services_group} = value, acc ->
      parent_id = services_group.service_group_id

      if parent_id do
        {_, parent} = Enum.find(acc, fn {k, _} -> k == parent_id end)
        Map.put(acc, parent_id, Map.put(parent, :services, [value | parent.services]))
      else
        acc
      end
    end)
  end

  def get_by_id(id), do: @read_prm_repo.get(Service, id)

  def get_by_id!(id), do: @read_prm_repo.get!(Service, id)

  def fetch_by_id(id) do
    case get_by_id(id) do
      %Service{} = service -> {:ok, service}
      _ -> {:error, {:not_found, "Service not found"}}
    end
  end

  def create_service(params, actor_id) do
    with :ok <- JsonSchema.validate(:service, params) do
      %Service{}
      |> changeset(params)
      |> put_change(:inserted_by, actor_id)
      |> put_change(:updated_by, actor_id)
      |> PRMRepo.insert_and_log(actor_id)
    end
  end

  def create_service_group(params, actor_id) do
    %ServiceGroup{}
    |> changeset(params)
    |> put_change(:inserted_by, actor_id)
    |> put_change(:updated_by, actor_id)
    |> PRMRepo.insert_and_log(actor_id)
  end

  def changeset(%Service{} = entity, attrs) do
    entity
    |> cast(attrs, @service_fields_required ++ @service_fields_optional)
    |> validate_required(@service_fields_required)
    |> validate_length(:name, max: 100)
  end

  def changeset(%ServiceGroup{} = entity, attrs) do
    entity
    |> cast(attrs, @service_group_fields_required ++ @service_group_fields_optional)
    |> validate_required(@service_group_fields_required)
    |> validate_length(:name, max: 100)
  end

  def deactivate(%Service{id: id} = service, actor_id) when is_binary(id) do
    with :ok <- validate_is_active(service),
         :ok <- validate_active_program_services(service) do
      service
      |> changeset(%{is_active: false})
      |> put_change(:updated_by, actor_id)
      |> PRMRepo.update_and_log(actor_id)
    end
  end

  defp validate_is_active(%{is_active: true}), do: :ok
  defp validate_is_active(%{is_active: false}), do: {:error, {:conflict, "Service is already deactivated"}}

  defp validate_active_program_services(%{id: id}) do
    error_message =
      "This service is a participant of active program service. Only service without active program service can be deactivated"

    case count_active_program_services_by(service_id: id) do
      0 -> :ok
      _ -> {:error, {:conflict, error_message}}
    end
  end

  defp count_active_program_services_by(params) when is_list(params) do
    params = [is_active: true] ++ params

    ProgramService
    |> where(^params)
    |> select([ps], count(ps.id))
    |> @read_prm_repo.one()
  end
end

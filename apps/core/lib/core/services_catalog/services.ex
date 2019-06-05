defmodule Core.Services do
  @moduledoc false

  import Ecto.{Changeset, Query}, warn: false

  alias Core.PRMRepo
  alias Core.Services.{Service, ServiceGroup, ServiceInclusion}
  alias Core.Validators.JsonSchema

  @service_fields_required ~w(name code)a
  @service_fields_optional ~w(category parent_id is_composition request_allowed is_active)a

  @service_group_fields_required ~w(name code)a
  @service_group_fields_optional ~w(parent_id request_allowed is_active)a

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list do
    service_groups = PRMRepo.all(ServiceGroup)
    services = PRMRepo.all(Service)
    service_inclusions = PRMRepo.all(ServiceInclusion)

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

    service_inclusions =
      Enum.map(service_inclusions, fn services_group ->
        service = Enum.find(services, fn service -> service.id == services_group.service_id end)
        %{service: service, services_group: services_group}
      end)

    Enum.reduce(service_inclusions, tree, fn %{services_group: services_group} = value, acc ->
      parent_id = services_group.service_group_id

      if parent_id do
        {_, parent} = Enum.find(acc, fn {k, _} -> k == parent_id end)
        Map.put(acc, parent_id, Map.put(parent, :services, [value | parent.services]))
      else
        acc
      end
    end)
  end

  defdelegate get_by_id(queryable, id), to: @read_prm_repo, as: :get

  def fetch_by_id(queryable, id) do
    case get_by_id(queryable, id) do
      %{__struct__: ^queryable} = record -> {:ok, record}
      _ -> {:error, {:not_found, "#{to_entity_name(queryable)} not found"}}
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

  def create_service_inclusion(%{service_group_id: service_group_id, service_id: service_id}, actor_id) do
    with {:ok, service_group} <- fetch_by_id(ServiceGroup, service_group_id),
         {:ok, service} <- fetch_by_id(Service, service_id),
         :ok <- validate_is_active(service_group),
         :ok <- validate_is_active(service) do
      %ServiceInclusion{}
      |> change(%{inserted_by: actor_id, updated_by: actor_id})
      |> put_assoc(:service_group, service_group)
      |> put_assoc(:service, service)
      |> unique_constraint(:is_active, name: :service_inclusions_service_group_id_service_id_index)
      |> PRMRepo.insert_and_log(actor_id)
    end
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

  def deactivate(%ServiceGroup{id: id} = service_group, actor_id) when is_binary(id) do
    with :ok <- validate_is_active(service_group),
         :ok <- validate_active_program_services(service_group),
         :ok <- validate_active_services(service_group) do
      service_group
      |> changeset(%{is_active: false})
      |> put_change(:updated_by, actor_id)
      |> PRMRepo.update_and_log(actor_id)
    end
  end

  defp validate_is_active(%{is_active: true}), do: :ok

  defp validate_is_active(%{is_active: false} = struct) do
    {:error, {:conflict, "#{to_entity_name(struct)} is not active"}}
  end

  defp validate_active_program_services(struct) do
    entity_name = to_entity_name(struct)

    error_message =
      "This #{entity_name} is a participant of active ProgramService. Only #{entity_name} without active ProgramService can be deactivated"

    case count_associated_program_services(struct) do
      0 -> :ok
      _ -> {:error, {:conflict, error_message}}
    end
  end

  defp count_associated_program_services(%{__struct__: queryable} = struct) when queryable in [Service, ServiceGroup] do
    struct
    |> Ecto.assoc(:program_services)
    |> where([ps], ps.is_active == true)
    |> select([ps], count(ps.id))
    |> @read_prm_repo.one()
  end

  defp validate_active_services(struct) do
    entity_name = to_entity_name(struct)

    error_message =
      "This #{entity_name} has active Service. Only #{entity_name} without active Service can be deactivated"

    case count_associated_services(struct) do
      0 -> :ok
      _ -> {:error, {:conflict, error_message}}
    end
  end

  defp count_associated_services(%ServiceGroup{} = struct) do
    struct
    |> Ecto.assoc(:services)
    |> where([s], s.is_active == true)
    |> select([s], count(s.id))
    |> @read_prm_repo.one()
  end

  defp to_entity_name(%{__struct__: module}), do: to_entity_name(module)

  defp to_entity_name(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
  end
end

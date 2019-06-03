defmodule Core.Services do
  @moduledoc false

  import Ecto.Changeset, warn: false

  alias Core.PRMRepo
  alias Core.Services.Service
  alias Core.Services.ServiceGroup
  alias Core.Services.ServicesGroups
  alias Core.Validators.JsonSchema

  @service_fields_required ~w(name code)a
  @service_fields_optional ~w(category parent_id is_composition request_allowed is_active)a

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

  def create(params, actor_id) do
    with :ok <- JsonSchema.validate(:service, params) do
      %Service{}
      |> changeset(params)
      |> put_change(:inserted_by, actor_id)
      |> put_change(:updated_by, actor_id)
      |> PRMRepo.insert_and_log(actor_id)
    end
  end

  def changeset(%Service{} = entity, attrs) do
    entity
    |> cast(attrs, @service_fields_required ++ @service_fields_optional)
    |> validate_required(@service_fields_required)
    |> validate_length(:name, max: 100)
  end
end

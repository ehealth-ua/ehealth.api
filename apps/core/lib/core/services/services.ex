defmodule Core.Services do
  @moduledoc false

  alias Core.PRMRepo
  alias Core.Services.Service
  alias Core.Services.ServiceGroup
  alias Core.Services.ServicesGroups

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
          {_, parent} = Enum.find(tree, fn {k, _} -> k == parent_id end)
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
end

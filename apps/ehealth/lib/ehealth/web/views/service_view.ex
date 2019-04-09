defmodule EHealth.Web.ServiceView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{tree: nodes}) do
    nodes
    |> Enum.filter(fn {_, v} -> is_nil(v.node.parent_id) end)
    |> Enum.map(fn {_, v} ->
      render("group.json", %{group: v, tree: nodes})
    end)
  end

  def render("group.json", %{group: group, tree: nodes}) do
    group.node
    |> Map.take(~w(
      id
      name
      code
      is_active
      request_allowed
      inserted_at
      inserted_by
      updated_at
      updated_by
    )a)
    |> put_children(group, nodes)
  end

  def render("service.json", %{service: service, services_group: services_group}) do
    service
    |> Map.take(~w(
      id
      code
      is_active
      parent_id
      category
      is_composition
      request_allowed
      inserted_at
      inserted_by
      updated_at
      updated_by
    )a)
    |> Map.put(:name, services_group.alias || service.name)
  end

  defp put_children(data, %{groups: [], services: services}, _) do
    Map.put(data, :services, Enum.map(services, fn value -> render("service.json", value) end))
  end

  defp put_children(data, %{groups: groups, services: []}, nodes) do
    Map.put(
      data,
      :groups,
      Enum.map(groups, fn group_id ->
        {_, group} = Enum.find(nodes, fn {k, _} -> k == group_id end)
        render("group.json", %{group: group, tree: nodes})
      end)
    )
  end

  defp put_children(data, _, _), do: data
end

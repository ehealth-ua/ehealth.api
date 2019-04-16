defmodule EHealth.Rpc do
  @moduledoc """
  This module contains functions that are called from other pods via RPC.
  """

  alias Core.Services.Service
  alias Core.Services.ServiceGroup
  alias EHealth.Web.ServiceView

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @type service() :: %{
          category: binary(),
          code: binary(),
          id: binary(),
          inserted_at: DateTime,
          inserted_by: binary(),
          is_active: boolean(),
          is_composition: boolean(),
          name: binary(),
          parent_id: binary(),
          request_allowed: boolean(),
          updated_at: DateTime,
          updated_by: binary()
        }

  @type service_group() :: %{
          code: binary(),
          id: binary(),
          inserted_at: DateTime,
          inserted_by: binary(),
          is_active: boolean(),
          name: binary(),
          request_allowed: boolean(),
          updated_at: DateTime,
          updated_by: binary()
        }

  @doc """
  Get service by service_id

  ## Examples

      iex> EHealth.Rpc.service_by_id("cdfade57-5d1c-4bac-8155-a26e88795d9f")
      {:ok,
        %{
          category: "service_category",
          code: "service_code",
          id: "cdfade57-5d1c-4bac-8155-a26e88795d9f",
          inserted_at: #DateTime<2019-04-15 18:32:34.982672Z>,
          inserted_by: "da333fb4-f397-46b1-90e3-3bc1d3b3d658",
          is_active: true,
          is_composition: false,
          name: "service_name",
          parent_id: "99630d0e-880c-4f70-a62b-cf65895ee196",
          request_allowed: true,
          updated_at: #DateTime<2019-04-15 18:32:34.982672Z>,
          updated_by: "da333fb4-f397-46b1-90e3-3bc1d3b3d658"
        }
      }
  """

  @spec service_by_id(service_id :: binary()) :: nil | {:ok, service()}
  def service_by_id(service_id) do
    with %Service{} = service <- @read_prm_repo.get(Service, service_id) do
      {:ok, ServiceView.render("service.json", %{service: service})}
    end
  end

  @doc """
  Get service group by service_group_id

  ## Examples

      iex> EHealth.Rpc.service_group_by_id("71a01a1b-c60a-41c0-8ee6-73fc10abf1ea")
      {:ok,
        %{
          code: "service_group_code",
          id: "71a01a1b-c60a-41c0-8ee6-73fc10abf1ea",
          inserted_at: #DateTime<2019-04-16 12:01:24.978769Z>,
          inserted_by: "da333fb4-f397-46b1-90e3-3bc1d3b3d658",
          is_active: true,
          name: "service_group_name",
          request_allowed: true,
          updated_at: #DateTime<2019-04-16 12:01:24.978769Z>,
          updated_by: "da333fb4-f397-46b1-90e3-3bc1d3b3d658"
        }
      }
  """

  @spec service_group_by_id(service_group_id :: binary()) :: nil | {:ok, service_group()}
  def service_group_by_id(service_group_id) do
    with %ServiceGroup{} = service_group <- @read_prm_repo.get(ServiceGroup, service_group_id) do
      {:ok, ServiceView.render("group.json", %{group: %{node: service_group}})}
    end
  end
end

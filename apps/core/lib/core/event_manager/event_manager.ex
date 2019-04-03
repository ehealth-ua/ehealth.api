defmodule Core.EventManager do
  @moduledoc false

  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias Core.EmployeeRequests.EmployeeRequest

  @type_change_status "StatusChangeEvent"
  @contract_schemas [CapitationContract, ReimbursementContract]
  @producer Application.get_env(:core, :kafka)[:producer]

  def publish_change_status(_entity, status, status, _user_id), do: nil

  def publish_change_status(entity, _, status, user_id) do
    publish_change_status(entity, status, user_id)
  end

  def publish_change_status(%{__struct__: schema} = entity, user_id) when schema in @contract_schemas do
    properties = %{
      "is_suspended" => %{
        "new_value" => entity.is_suspended
      }
    }

    publish_event(create_event(entity, user_id, properties, "StateChangeEvent"))
  end

  def publish_change_status(%EmployeeRequest{employee_id: employee_id} = entity, new_status, user_id) do
    properties = %{
      "status" => %{
        "new_value" => new_status
      },
      "employee_id" => %{
        "new_value" => employee_id
      }
    }

    publish_event(create_event(entity, user_id, properties))
  end

  def publish_change_status(entity, new_status, user_id) do
    properties = %{"status" => %{"new_value" => new_status}}
    publish_event(create_event(entity, user_id, properties))
  end

  defp create_event(entity, user_id, properties, event_type \\ @type_change_status) do
    entity_type =
      entity.__struct__
      |> Module.split()
      |> List.last()

    %{
      event_type: event_type,
      entity_type: entity_type,
      entity_id: entity.id,
      properties: properties,
      event_time: NaiveDateTime.utc_now(),
      changed_by: user_id
    }
  end

  def publish_event(event) do
    with :ok <- @producer.publish_to_event_manager(event), do: {:ok, event}
  end
end

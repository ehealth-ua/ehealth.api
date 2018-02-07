defmodule EHealth.EventManager do
  @moduledoc false

  alias EHealth.EventManagerRepo, as: Repo
  alias EHealth.EventManager.Event
  alias EHealth.EmployeeRequests.EmployeeRequest

  @type_change_status "StatusChangeEvent"

  def insert_change_status(_entity, status, status, _user_id), do: nil

  def insert_change_status(entity, _, status, user_id) do
    insert_change_status(entity, status, user_id)
  end

  def insert_change_status(%EmployeeRequest{employee_id: employee_id} = entity, new_status, user_id) do
    properties = %{
      "status" => %{
        "new_value" => new_status
      },
      "employee_id" => %{
        "new_value" => employee_id
      }
    }

    Repo.insert(create_event(entity, user_id, properties))
  end

  def insert_change_status(entity, new_status, user_id) do
    properties = %{"status" => %{"new_value" => new_status}}
    Repo.insert(create_event(entity, user_id, properties))
  end

  defp create_event(entity, user_id, properties) do
    entity_type =
      entity.__struct__
      |> to_string()
      |> String.split(".")
      |> List.last()

    %Event{
      event_type: @type_change_status,
      entity_type: entity_type,
      entity_id: entity.id,
      properties: properties,
      event_time: NaiveDateTime.utc_now(),
      changed_by: user_id
    }
  end
end

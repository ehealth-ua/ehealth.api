defmodule Core.MedicationRequests.MedicationRequest do
  @moduledoc false

  @status_active "ACTIVE"
  @status_completed "COMPLETED"
  @status_rejected "REJECTED"
  @status_expired "EXPIRED"

  @intent_order "order"
  @intent_plan "plan"

  def status(:active), do: @status_active
  def status(:completed), do: @status_completed
  def status(:rejected), do: @status_rejected
  def status(:expired), do: @status_expired

  def intent(:order), do: @intent_order
  def intent(:plan), do: @intent_plan
end

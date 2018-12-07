defmodule Core.MedicationRequests.MedicationRequest do
  @moduledoc false

  @medication_request_intent_order "order"
  @medication_request_intent_plan "plan"

  def intent(:order), do: @medication_request_intent_order
  def intent(:plan), do: @medication_request_intent_plan
end

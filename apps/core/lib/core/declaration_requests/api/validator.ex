defmodule Core.DeclarationRequests.Validator do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Email.Sanitizer

  @status_new DeclarationRequest.status(:new)
  @status_rejected DeclarationRequest.status(:rejected)
  @status_approved DeclarationRequest.status(:approved)

  @channel_mis DeclarationRequest.channel(:mis)
  @channel_cabinet DeclarationRequest.channel(:cabinet)

  # Declaration Requests BOTH V1, V2

  def validate_tax_id(user_tax_id, person_tax_id) do
    if user_tax_id == person_tax_id do
      :ok
    else
      {:error, {:"422", "Invalid person"}}
    end
  end

  def check_user_person_id(user, person_id) do
    if user["person_id"] == person_id do
      :ok
    else
      {:error, :forbidden}
    end
  end

  def lowercase_email(params) do
    path = ~w(person email)
    email = get_in(params, path)
    put_in(params, path, Sanitizer.sanitize(email))
  end

  # Declaration Requests V1

  def validate_status_transition(changeset) do
    from = changeset.data.status
    {_, to} = fetch_field(changeset, :status)

    valid_transitions = [
      {@status_new, @status_rejected},
      {@status_approved, @status_rejected},
      {@status_new, @status_approved}
    ]

    if {from, to} in valid_transitions do
      :ok
    else
      {:error, {:conflict, "Invalid transition"}}
    end
  end

  def validate_channel(%DeclarationRequest{channel: @channel_mis}, @channel_cabinet) do
    {:error, {:forbidden, "Declaration request should be approved by Doctor"}}
  end

  def validate_channel(%DeclarationRequest{channel: @channel_cabinet}, @channel_mis) do
    {:error, {:forbidden, "Declaration request should be approved by Patient"}}
  end

  def validate_channel(_, _), do: :ok

  def filter_by_employee_id(query, %{"employee_id" => employee_id}) do
    where(query, [r], fragment("?->'employee'->>'id' = ?", r.data, ^employee_id))
  end

  def filter_by_employee_id(query, _), do: query

  def filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end

  def filter_by_status(query, _), do: where(query, [r], r.status in ^DeclarationRequest.status_options())
end

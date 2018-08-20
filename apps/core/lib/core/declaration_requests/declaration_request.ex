defmodule Core.DeclarationRequests.DeclarationRequest do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Jason.Encoder, except: [:__meta__]}

  @status_new "NEW"
  @status_signed "SIGNED"
  @status_cancelled "CANCELLED"
  @status_rejected "REJECTED"
  @status_approved "APPROVED"
  @status_expired "EXPIRED"

  @authentication_na "NA"
  @authentication_otp "OTP"
  @authentication_offline "OFFLINE"

  @channel_cabinet "CABINET"
  @channel_mis "MIS"

  def status(:new), do: @status_new
  def status(:signed), do: @status_signed
  def status(:cancelled), do: @status_cancelled
  def status(:rejected), do: @status_rejected
  def status(:approved), do: @status_approved
  def status(:expired), do: @status_expired

  def status_options do
    [@status_new, @status_signed, @status_cancelled, @status_rejected, @status_approved, @status_expired]
  end

  def authentication_method(:na), do: @authentication_na
  def authentication_method(:otp), do: @authentication_otp
  def authentication_method(:offline), do: @authentication_offline

  def channel(:cabinet), do: @channel_cabinet
  def channel(:mis), do: @channel_mis

  schema "declaration_requests" do
    field(:data, :map)
    field(:status, :string)
    field(:authentication_method_current, :map)
    field(:documents, {:array, :map})
    field(:printout_content, :string)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)
    field(:declaration_id, UUID)
    field(:mpi_id, UUID)
    field(:overlimit, :boolean)
    field(:channel, :string)
    field(:declaration_number, :string)

    timestamps()
  end
end

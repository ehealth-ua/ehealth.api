defmodule EHealthScheduler.DeclarationRequests.Terminator do
  @moduledoc false

  use Confex, otp_app: :ehealth_scheduler

  import Ecto.Query

  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.GlobalParameters
  alias Core.Repo
  alias Ecto.UUID

  require Logger

  @signed DeclarationRequest.status(:signed)
  @expired DeclarationRequest.status(:expired)

  def clean_declaration_requests, do: process_declaration_requests(:clean_signed, process_options())
  def terminate_declaration_requests, do: process_declaration_requests(:clean_and_expire, process_options())

  defp process_declaration_requests(:done, _options), do: :ok

  defp process_declaration_requests(clean_method, options) do
    rows_updated =
      change_status_declaration_requests(clean_method, options.term, options.unit, options.user_id, options.limit)

    if rows_updated >= options.limit,
      do: process_declaration_requests(clean_method, options),
      else: process_declaration_requests(:done, options)
  end

  defp new_status(:clean_signed), do: @signed
  defp new_status(:clean_and_expire), do: @expired

  defp subselect_condition(query, :clean_signed), do: where(query, [dr], dr.status == ^@signed and not is_nil(dr.data))

  defp subselect_condition(query, :clean_and_expire),
    do: where(query, [dr], dr.status != ^@signed and dr.status != ^@expired)

  def change_status_declaration_requests(clean_method, term, unit, user_id, limit) do
    subselect_ids =
      DeclarationRequest
      |> select([dr], %{id: dr.id})
      |> where(
        [dr],
        dr.inserted_at < datetime_add(^DateTime.utc_now(), ^(-1 * String.to_integer(term)), ^unit)
      )
      |> subselect_condition(clean_method)
      |> order_by([dr], desc: :inserted_at)
      |> limit(^limit)
      |> Repo.all()
      |> Enum.map(& &1.id)

    {rows_updated, _} =
      DeclarationRequest
      |> where([dr], dr.id in ^subselect_ids)
      |> update(
        [d],
        set: [
          status: ^new_status(clean_method),
          data: nil,
          data_start_date_year: nil,
          data_person_tax_id: nil,
          data_person_first_name: nil,
          data_person_last_name: nil,
          data_person_birth_date: nil,
          authentication_method_current: nil,
          printout_content: nil,
          updated_by: ^user_id,
          updated_at: ^DateTime.utc_now()
        ]
      )
      |> Repo.update_all([])

    rows_updated
  end

  defp process_options do
    parameters = GlobalParameters.get_values()

    is_valid? =
      Enum.all?(~w(declaration_request_expiration declaration_request_term_unit), fn param ->
        Map.has_key?(parameters, param)
      end)

    if is_valid? do
      %{
        "declaration_request_expiration" => term,
        "declaration_request_term_unit" => unit
      } = parameters

      normalized_unit =
        unit
        |> String.downcase()
        |> String.replace_trailing("s", "")

      {:ok, user_id} = UUID.dump(Confex.fetch_env!(:core, :system_user))
      limit = config()[:termination_batch_size]

      %{term: term, unit: normalized_unit, user_id: user_id, limit: limit}
    else
      Logger.error(fn ->
        "Autoterminate declaration requests is not working, parameters invalid!"
      end)
    end
  end
end

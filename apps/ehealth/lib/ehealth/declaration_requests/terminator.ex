defmodule EHealth.DeclarationRequests.Terminator do
  @moduledoc false

  use Confex, otp_app: :ehealth
  alias Ecto.Adapters.SQL
  alias Ecto.UUID
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias EHealth.GlobalParameters
  alias EHealth.Repo
  alias Postgrex.Error
  require Logger

  def terminate_declaration_requests do
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

      do_terminate_declaration_requests(term, normalized_unit)
    end
  end

  defp do_terminate_declaration_requests(term, unit) do
    query = """
    UPDATE declaration_requests
    SET (status, data, authentication_method_current, documents, printout_content, updated_by, updated_at) = ($1, NULL, NULL, NULL, NULL, $2, now())
    WHERE id IN (
      SELECT id
      FROM declaration_requests
      WHERE ((inserted_at::timestamp + ($3::numeric * interval '1 #{unit}'))::timestamp < $4) AND status != $5
      ORDER BY inserted_at
      LIMIT $6
    );
    """

    {:ok, user_id} = UUID.dump(Confex.fetch_env!(:ehealth, :system_user))

    case SQL.query(Repo, query, [
           DeclarationRequest.status(:expired),
           user_id,
           String.to_integer(term),
           NaiveDateTime.utc_now(),
           DeclarationRequest.status(:expired),
           config()[:termination_batch_size]
         ]) do
      {:ok, %{num_rows: update_count}} ->
        if update_count >= config()[:termination_batch_size], do: do_terminate_declaration_requests(term, unit)

      {:error, reason} ->
        Logger.error("Error deleting declaration_requests, #{Error.message(reason)}")
    end
  end
end

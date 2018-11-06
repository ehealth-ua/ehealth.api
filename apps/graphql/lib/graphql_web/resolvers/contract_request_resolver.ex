defmodule GraphQLWeb.Resolvers.ContractRequestResolver do
  @moduledoc false

  import Ecto.Query, only: [where: 2, where: 3, join: 4, select: 3, order_by: 2]
  import GraphQLWeb.Resolvers.Helpers.Search, only: [filter: 2]
  import GraphQLWeb.Resolvers.Helpers.Errors

  alias Absinthe.Relay.Connection
  alias Core.ContractRequests
  alias Core.ContractRequests.ContractRequest
  alias Core.Employees.Employee
  alias Core.Man.Templates.ContractRequestPrintoutForm
  alias Core.{PRMRepo, Repo}

  @status_pending_nhs_sign ContractRequest.status(:pending_nhs_sign)

  def list_contract_requests(args, %{context: %{client_type: "NHS"}}) do
    ContractRequest
    |> search(args)
    |> Connection.from_query(&Repo.all/1, args)
  end

  def list_contract_requests(args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    ContractRequest
    |> where(contractor_legal_entity_id: ^client_id)
    |> search(args)
    |> Connection.from_query(&Repo.all/1, args)
  end

  defp search(query, %{filter: filter, order_by: order_by}) do
    filter = prepare_filter(filter)

    query
    |> filter(filter)
    |> order_by(^order_by)
  end

  defp prepare_filter([]), do: []

  defp prepare_filter([{:assignee_name, value} | tail]) do
    assignee_ids =
      Employee
      |> join(:inner, [e], p in assoc(e, :party))
      |> where([e], e.employee_type == "NHS")
      |> where(
        [..., p],
        fragment(
          "to_tsvector(concat_ws(' ', ?, ?, ?)) @@ to_tsquery(?)",
          p.last_name,
          p.first_name,
          p.second_name,
          ^value
        )
      )
      |> select([e], e.id)
      |> PRMRepo.all()

    [{:assignee_id, assignee_ids} | prepare_filter(tail)]
  end

  defp prepare_filter([head | tail]), do: [head | prepare_filter(tail)]

  def get_printout_content(%ContractRequest{status: @status_pending_nhs_sign} = contract_request, _, %{context: context}) do
    contract_request = Map.put(contract_request, :nhs_signed_date, Date.utc_today())

    # todo: causes N+1 problem with DB query and man template rendering
    with {:ok, printout_content} <- ContractRequestPrintoutForm.render(contract_request, context.headers) do
      {:ok, printout_content}
    else
      # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
      # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
      {:error, {:forbidden, error}} ->
        {:error, format_forbidden_error(error)}

      error ->
        error
    end
  end

  def get_printout_content(%ContractRequest{printout_content: printout_content}, _, _), do: {:ok, printout_content}

  def update(args, resolution) do
    params = prepare_update_params(args)

    with {:ok, contract_request, references} <- ContractRequests.update(resolution.context.headers, params) do
      {:ok, %{contract_request: Map.merge(contract_request, references)}}
    else
      # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
      # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
      {:error, {:conflict, error}} ->
        {:error, format_conflict_error(error)}

      {:error, {:forbidden, error}} ->
        {:error, format_forbidden_error(error)}

      error ->
        error
    end
  end

  defp prepare_update_params(args) do
    for {key, value} <- args, into: %{} do
      case key do
        :miscellaneous -> {"misc", value}
        key -> {to_string(key), value}
      end
    end
  end

  def approve(%{signed_content: signed_content}, resolution) do
    params = %{
      "id" => nil,
      "signed_content" => signed_content.content,
      "signed_content_encoding" => to_string(signed_content.encoding)
    }

    with {:ok, contract_request, references} <- ContractRequests.approve(resolution.context.headers, params) do
      {:ok, %{contract_request: Map.merge(contract_request, references)}}
    else
      # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
      # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
      {:error, {:conflict, error}} ->
        {:error, format_conflict_error(error)}

      {:error, {:forbidden, error}} ->
        {:error, format_forbidden_error(error)}

      error ->
        error
    end
  end

  def sign(%{id: id, signed_content: signed_content}, %{context: %{headers: headers}}) do
    params = %{
      "id" => id,
      "signed_content" => signed_content.content,
      "signed_content_encoding" => to_string(signed_content.encoding)
    }

    with {:ok, contract_request, _references} <- ContractRequests.sign_nhs(headers, params) do
      {:ok, %{contract_request: contract_request}}
    else
      # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
      # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
      {:error, {:bad_request, error}} ->
        {:error, format_bad_request(error)}

      {:error, {:not_found, error}} ->
        {:error, format_not_found_error(error)}

      {:error, {:forbidden, error}} ->
        {:error, format_forbidden_error(error)}

      {:error, {:"422", error}} ->
        {:error, format_unprocessable_entity_error(error)}

      {:error, [_ | _] = errors} ->
        {:error, format_unprocessable_entity_error(errors)}

      {:error, %Ecto.Changeset{} = errors} ->
        {:error, format_unprocessable_entity_error(errors)}

      error ->
        error
    end
  end

  def decline(%{signed_content: signed_content}, resolution) do
    params = %{
      "id" => nil,
      "signed_content" => signed_content.content,
      "signed_content_encoding" => to_string(signed_content.encoding)
    }

    with {:ok, contract_request, references} <- ContractRequests.decline(resolution.context.headers, params) do
      {:ok, %{contract_request: Map.merge(contract_request, references)}}
    else
      # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
      # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
      {:error, {:conflict, error}} ->
        {:error, format_conflict_error(error)}

      {:error, {:forbidden, error}} ->
        {:error, format_forbidden_error(error)}

      error ->
        error
    end
  end

  def update_assignee(%{id: id, employee_id: employee_id}, %{context: %{headers: headers}}) do
    # TODO: There is only the happy path are implemented for now.
    # Error handling in a generic manner should be implemented later.
    with {:ok, contract_request, _} <-
           ContractRequests.update_assignee(headers, %{"id" => id, "employee_id" => employee_id}) do
      {:ok, %{contract_request: contract_request}}
    end
  end
end

defmodule EHealth.ContractRequests do
  @moduledoc false

  use EHealth.Search, EHealth.Repo

  import Ecto.Changeset
  import Ecto.Query
  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]

  alias Ecto.Adapters.SQL
  alias Ecto.UUID
  alias EHealth.Contracts
  alias EHealth.API.Signature
  alias EHealth.ContractRequests.ContractRequest
  alias EHealth.ContractRequests.Search
  alias EHealth.Divisions.Division
  alias EHealth.Employees
  alias EHealth.Employees.Employee
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Parties
  alias EHealth.Parties.Party
  alias EHealth.Validators.Reference
  alias EHealth.Validators.JsonSchema
  alias EHealth.Validators.Preload
  alias EHealth.Repo
  alias EHealth.Utils.NumberGenerator
  alias EHealth.EventManager
  alias EHealth.Web.ContractRequestView
  alias EHealth.Man.Templates.ContractRequestPrintoutForm

  require Logger

  @ops_api Application.get_env(:ehealth, :api_resolvers)[:ops]
  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]
  @media_storage_api Application.get_env(:ehealth, :api_resolvers)[:media_storage]

  @fields_required ~w(
    contractor_legal_entity_id
    contractor_owner_id
    contractor_base
    contractor_payment_details
    contractor_rmsp_amount
    contractor_divisions
    start_date
    end_date
    id_form
    status
    inserted_by
    updated_by
  )a

  @fields_optional ~w(
    contractor_employee_divisions
    external_contractor_flag
    external_contractors
    contract_number
  )a

  def search(search_params) do
    with %Ecto.Changeset{valid?: true} = changeset <- Search.changeset(search_params),
         %Scrivener.Page{} = paging <- search(changeset, search_params, ContractRequest) do
      {:ok, paging}
    end
  end

  def create(headers, params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with :ok <- JsonSchema.validate(:contract_request_sign, params),
         {_, %Party{tax_id: tax_id}} <- {:employee, Parties.get_by_user_id(user_id)},
         {:ok, content, signer} <- decode_signed_content(params, headers),
         :ok <- validate_signer_drfo(tax_id, signer["drfo"]),
         :ok <- JsonSchema.validate(:contract_request, content),
         :ok <- validate_dates(content),
         {:ok, params} <- validate_contract_number(content, client_id, headers),
         :ok <- validate_unique_contractor_employee_divisions(params),
         :ok <- validate_unique_contractor_divisions(params),
         :ok <- validate_contract_employee_divisions(params),
         :ok <- validate_employee_divisions(params),
         :ok <- validate_contractor_divisions(params),
         :ok <- validate_external_contractors(params),
         :ok <- validate_external_contractor_flag(params),
         :ok <- validate_start_date(params),
         :ok <- validate_end_date(params),
         :ok <- validate_contractor_owner_id(params),
         _ <- terminate_pending_contracts(params),
         insert_params <-
           params
           |> Map.put("status", ContractRequest.status(:new))
           |> Map.put("inserted_by", user_id)
           |> Map.put("updated_by", user_id),
         %Ecto.Changeset{valid?: true} = changes <- changeset(%ContractRequest{}, insert_params),
         {:ok, contract_request} <- Repo.insert(changes) do
      {:ok, contract_request, preload_references(contract_request)}
    else
      {:employee, _} -> {:error, {:forbidden, "User is not allowed to this action by client_id"}}
      error -> error
    end
  end

  def update(headers, params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with :ok <-
           JsonSchema.validate(
             :contract_request_update,
             Map.take(params, ~w(nhs_signer_id nhs_signer_base nhs_contract_price nhs_payment_method issue_city))
           ),
         {:ok, %{"data" => data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(data, "NHS ADMIN SIGNER"),
         %ContractRequest{} = contract_request <- Repo.get(ContractRequest, params["id"]),
         :ok <- validate_nhs_signer_id(params, client_id),
         :ok <- validate_status(contract_request, ContractRequest.status(:new)),
         :ok <- validate_start_date(contract_request),
         update_params <-
           params
           |> Map.delete("id")
           |> Map.put("nhs_legal_entity_id", client_id)
           |> Map.put("updated_by", user_id),
         %Ecto.Changeset{valid?: true} = changes <- update_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def approve(headers, params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with {:ok, %{"data" => data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(data, "NHS ADMIN SIGNER"),
         %ContractRequest{} = contract_request <- Repo.get(ContractRequest, params["id"]),
         :ok <- validate_status(contract_request, ContractRequest.status(:new)),
         {:ok, _} <- validate_contract_number(params, nil, headers),
         :ok <- validate_contractor_legal_entity(contract_request),
         :ok <- validate_contractor_owner_id(contract_request),
         :ok <- validate_nhs_signer_id(contract_request, client_id),
         :ok <- validate_contract_employee_divisions(contract_request),
         :ok <- validate_employee_divisions(contract_request),
         :ok <- validate_contractor_divisions(contract_request),
         :ok <- validate_start_date(contract_request),
         update_params <-
           params
           |> Map.delete("id")
           |> Map.put("updated_by", user_id)
           |> Map.put("contract_number", get_contract_number(params))
           |> Map.put("status", ContractRequest.status(:approved)),
         %Ecto.Changeset{valid?: true} = changes <- approve_changeset(contract_request, update_params),
         {:ok, printout_form} <- ContractRequestPrintoutForm.render(apply_changes(changes), headers),
         %Ecto.Changeset{valid?: true} = changes <- put_change(changes, :printout_content, printout_form),
         data <- prepare_contract_request_data(changes),
         %Ecto.Changeset{valid?: true} = changes <- put_change(changes, :data, data),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def decline(headers, params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with {:ok, %{"data" => data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(data, "NHS ADMIN SIGNER"),
         %ContractRequest{} = contract_request <- Repo.get(ContractRequest, params["id"]),
         :ok <- validate_status(contract_request, ContractRequest.status(:new)),
         update_params <-
           params
           |> Map.put("status", ContractRequest.status(:declined))
           |> Map.put("nhs_signer_id", user_id)
           |> Map.put("nhs_legal_entity_id", client_id)
           |> Map.put("updated_by", user_id),
         %Ecto.Changeset{valid?: true} = changes <- decline_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def terminate(headers, client_type, params) do
    client_id = get_client_id(headers)
    user_id = get_consumer_id(headers)

    with {:ok, %ContractRequest{} = contract_request} <- get_contract_request(client_id, client_type, params["id"]),
         {:contractor_owner, :ok} <- {:contractor_owner, validate_contractor_owner_id(contract_request)},
         true <- contract_request.status != ContractRequest.status(:signed),
         update_params <-
           params
           |> Map.put("status", ContractRequest.status(:terminated))
           |> Map.put("updated_by", user_id),
         %Ecto.Changeset{valid?: true} = changes <- terminate_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    else
      false ->
        {:error, {:"422", "Incorrect status of contract_request to modify it"}}

      {:contractor_owner, _} ->
        {:error, {:forbidden, "User is not allowed to perform this action"}}

      error ->
        error
    end
  end

  def sign_nhs(headers, client_type, %{"id" => id} = params) do
    client_id = get_client_id(headers)
    user_id = get_consumer_id(headers)
    params = Map.delete(params, "id")

    with {:ok, %ContractRequest{} = contract_request, references} <- get_by_id(headers, client_type, id),
         :ok <- JsonSchema.validate(:contract_request_sign, params),
         {_, true} <- {:client_id, client_id == contract_request.nhs_legal_entity_id},
         {_, false} <- {:already_signed, contract_request.status == ContractRequest.status(:nhs_signed)},
         {:ok, content, signer} <- decode_signed_content(:nhs, params, headers),
         {:ok, _} <- validate_contract_number(content, client_id, headers),
         :ok <- validate_signer_drfo(contract_request.nhs_signer_id, signer["drfo"], "$.nhs_signer_id"),
         :ok <- validate_content(contract_request, content),
         :ok <- validate_status(contract_request, ContractRequest.status(:approved)),
         :ok <- validate_employee_divisions(contract_request),
         :ok <- validate_start_date(contract_request),
         :ok <- validate_contractor_legal_entity(contract_request),
         :ok <- validate_contractor_owner_id(contract_request),
         :ok <- save_signed_content(contract_request.id, params, headers),
         update_params <-
           params
           |> Map.put("updated_by", user_id)
           |> Map.put("status", ContractRequest.status(:nhs_signed))
           |> Map.put("nhs_signed_date", Date.utc_today()),
         %Ecto.Changeset{valid?: true} = changes <- nhs_signed_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, references}
    else
      {:client_id, _} -> {:error, {:forbidden, "Invalid client_id"}}
      {:already_signed, _} -> {:error, {:"422", "The contract was already signed by NHS"}}
      error -> error
    end
  end

  def sign_msp(headers, client_type, %{"id" => id} = params) do
    client_id = get_client_id(headers)
    user_id = get_consumer_id(headers)
    params = Map.delete(params, "id")

    with {:ok, %ContractRequest{} = contract_request, _references} <- get_by_id(headers, client_type, id),
         :ok <- JsonSchema.validate(:contract_request_sign, params),
         {_, true} <- {:signed_nhs, contract_request.status == ContractRequest.status(:nhs_signed)},
         {_, true} <- {:client_id, client_id == contract_request.contractor_legal_entity_id},
         {:ok, content, signer} <- decode_signed_content(:msp, params, headers),
         :ok <- validate_signer_drfo(contract_request.contractor_owner_id, signer["drfo"], "$.contractor_owner_id"),
         :ok <- validate_content(contract_request, content),
         :ok <- validate_employee_divisions(contract_request),
         :ok <- validate_start_date(contract_request),
         :ok <- validate_contractor_legal_entity(contract_request),
         :ok <- validate_contractor_owner_id(contract_request),
         contract_id <- UUID.generate(),
         :ok <- save_signed_content(contract_id, params, headers),
         update_params <-
           params
           |> Map.put("updated_by", user_id)
           |> Map.put("status", ContractRequest.status(:signed))
           |> Map.put("contract_id", contract_id),
         %Ecto.Changeset{valid?: true} = changes <- msp_signed_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         contract_params <- get_contract_create_params(contract_request),
         {:create_contract, {:ok, %{"data" => contract}}} <-
           {:create_contract, @ops_api.create_contract(contract_params, headers)},
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      Contracts.load_contract_references(contract)
    else
      {:signed_nhs, false} -> {:error, {:"422", "Incorrect status for signing"}}
      {:client_id, _} -> {:error, {:forbidden, "Invalid client_id"}}
      {:employee, _} -> {:error, {:"422", "Employee is not allowed to sign"}}
      {:create_contract, _} -> {:error, {:bad_gateway, "Failed to save contract"}}
      error -> error
    end
  end

  defp validate_signer_drfo(tax_id, signer_drfo) when not is_nil(signer_drfo) do
    drfo = String.replace(signer_drfo, " ", "")

    with true <- tax_id == drfo || translit_drfo(tax_id) == translit_drfo(drfo) do
      :ok
    else
      _ ->
        {:error, {:"422", "Does not match the signer drfo"}}
    end
  end

  defp validate_signer_drfo(_, _) do
    {:error, {:"422", "Invalid drfo"}}
  end

  defp validate_signer_drfo(employee_id, signer_drfo, path) when not is_nil(signer_drfo) do
    drfo = String.replace(signer_drfo, " ", "")

    with %Employee{party_id: party_id} <- Employees.get_by_id(employee_id),
         %Party{tax_id: tax_id} <- Parties.get_by_id(party_id),
         true <- tax_id == drfo || translit_drfo(tax_id) == translit_drfo(drfo) do
      :ok
    else
      _ ->
        {:error,
         [
           {
             %{
               description: "Does not match the signer drfo",
               params: [],
               rule: :invalid
             },
             path
           }
         ]}
    end
  end

  defp validate_signer_drfo(_, _, path) do
    {:error,
     [
       {
         %{
           description: "Invalid drfo",
           params: [],
           rule: :invalid
         },
         path
       }
     ]}
  end

  defp translit_drfo(drfo) do
    drfo
    |> Translit.translit()
    |> String.upcase()
  end

  def get_partially_signed_content_url(headers, %{"id" => id}) do
    client_id = get_client_id(headers)

    with %ContractRequest{} = contract_request <- Repo.get(ContractRequest, id),
         {_, true} <- {:signed_nhs, contract_request.status == ContractRequest.status(:nhs_signed)},
         {_, true} <- {:client_id, client_id == contract_request.contractor_legal_entity_id},
         {:ok, url} <- resolve_partially_signed_content_url(contract_request.id, headers) do
      {:ok, url}
    else
      {:signed_nhs, _} -> {:error, {:"422", "The contract hasn't been signed yet"}}
      {:client_id, _} -> {:error, {:forbidden, "Invalid client_id"}}
      {:error, :media_storage_error} -> {:error, {:bad_gateway, "Fail to resolve partially signed content"}}
      error -> error
    end
  end

  defp get_contract_create_params(%ContractRequest{id: id, contract_id: contract_id} = contract_request) do
    contract_request
    |> Map.take(~w(
      start_date
      end_date
      status_reason
      contractor_legal_entity_id
      contractor_owner_id
      contractor_base
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
      external_contractors
      nhs_legal_entity_id
      nhgs_signed_id
      nhs_payment_method
      nhs_payment_details
      nhs_signer_base
      issue_city
      price
      contract_number
      contractor_employee_divisions
    )a)
    |> Map.put("id", contract_id)
    |> Map.put("contract_request_id", id)
    |> Map.put("is_suspended", false)
    |> Map.put("is_active", true)
    |> Map.put("inserted_by", contract_request.updated_by)
    |> Map.put("updated_by", contract_request.updated_by)
  end

  defp validate_content(%ContractRequest{data: data}, content) do
    if data == content,
      do: :ok,
      else: {:error, {:"422", "Signed content does not match the previously created content"}}
  end

  defp save_signed_content(id, %{"signed_content" => signed_content}, headers) do
    signed_content
    |> @media_storage_api.store_signed_content(:contract_request_bucket, id, headers)
    |> case do
      {:ok, _} -> :ok
      _error -> {:error, {:bad_gateway, "Failed to save signed content"}}
    end
  end

  def decode_signed_content(type, %{"signed_content" => signed_content, "signed_content_encoding" => encoding}, headers) do
    with {:ok, %{"data" => data}} <- Signature.decode_and_validate(signed_content, encoding, headers),
         do: do_decode_valid_content(type, data)
  end

  def decode_signed_content(
        %{"signed_content" => signed_content, "signed_content_encoding" => encoding},
        headers
      ) do
    with {:ok, %{"data" => data}} <- Signature.decode_and_validate(signed_content, encoding, headers) do
      case data do
        %{
          "content" => content,
          "signatures" => [%{"is_valid" => true, "signer" => signer}]
        } ->
          {:ok, content, signer}

        %{"signatures" => [%{"is_valid" => false, "validation_error_message" => error}]} ->
          {:error, {:bad_request, error}}

        %{"signatures" => signatures} ->
          {:error,
           {:bad_request, "document must be signed by 1 signer but contains #{Enum.count(signatures)} signatures"}}

        error ->
          error
      end
    end
  end

  defp do_decode_valid_content(:nhs, %{
         "content" => content,
         "signatures" => [%{"is_valid" => true, "signer" => signer}]
       }) do
    {:ok, content, signer}
  end

  defp do_decode_valid_content(:msp, %{
         "content" => content,
         "signatures" => [_, %{"is_valid" => true, "signer" => signer}]
       }) do
    {:ok, content, signer}
  end

  defp do_decode_valid_content(_, %{"signatures" => [%{"is_valid" => false, "validation_error_message" => error}]}),
    do: {:error, {:bad_request, error}}

  defp do_decode_valid_content(:msp, %{
         "signatures" => [_, %{"is_valid" => false, "validation_error_message" => error}]
       }) do
    {:error, {:bad_request, error}}
  end

  defp do_decode_valid_content(:nhs, %{"signatures" => signatures}) when is_list(signatures),
    do:
      {:error, {:bad_request, "document must be signed by 1 signer but contains #{Enum.count(signatures)} signatures"}}

  defp do_decode_valid_content(:msp, %{"signatures" => signatures}) when is_list(signatures),
    do:
      {:error, {:bad_request, "document must be signed by 2 signers but contains #{Enum.count(signatures)} signatures"}}

  defp get_contract_number(_) do
    with {:ok, sequence} <- get_contract_request_sequence() do
      NumberGenerator.generate_from_sequence(1, sequence)
    end
  end

  def changeset(%ContractRequest{} = contract_request, params) do
    contract_request
    |> cast(params, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end

  def update_changeset(%ContractRequest{} = contract_request, params) do
    contract_request
    |> cast(
      params,
      ~w(nhs_legal_entity_id nhs_signer_id nhs_signer_base nhs_contract_price nhs_payment_method issue_city)a
    )
    |> validate_number(:nhs_contract_price, greater_than: 0)
  end

  def approve_changeset(%ContractRequest{} = contract_request, params) do
    fields = ~w(
      nhs_legal_entity_id
      nhs_signer_id
      nhs_signer_base
      nhs_contract_price
      nhs_payment_method
      issue_city
      status
      updated_by
      contract_number
    )a

    contract_request
    |> cast(params, fields)
    |> validate_required(fields)
  end

  def terminate_changeset(%ContractRequest{} = contract_request, params) do
    fields_required = ~w(status updated_by)a
    fields_optional = ~w(status_reason)a

    contract_request
    |> cast(params, fields_required ++ fields_optional)
    |> validate_required(fields_required)
  end

  def nhs_signed_changeset(%ContractRequest{} = contract_request, params) do
    fields = ~w(status updated_by)a

    contract_request
    |> cast(params, fields)
    |> validate_required(fields)
  end

  def msp_signed_changeset(%ContractRequest{} = contract_request, params) do
    fields = ~w(status updated_by contract_id)a

    contract_request
    |> cast(params, fields)
    |> validate_required(fields)
  end

  defp preload_references(%ContractRequest{} = contract_request) do
    fields = [
      {:contractor_legal_entity_id, :legal_entity},
      {:nhs_legal_entity_id, :legal_entity},
      {:contractor_owner_id, :employee},
      {:nhs_signer_id, :employee},
      {:contractor_divisions, :division}
    ]

    fields =
      if is_list(contract_request.contractor_employee_divisions) do
        fields ++
          [
            {[:contractor_employee_divisions, "$", "employee_id"], :employee}
          ]
      else
        fields
      end

    Preload.preload_references(contract_request, fields)
  end

  defp terminate_pending_contracts(params) do
    # TODO: add index here
    contract_ids =
      ContractRequest
      |> select([c], c.id)
      |> where([c], c.contractor_legal_entity_id == ^params["contractor_legal_entity_id"])
      |> where([c], c.id_form == ^params["id_form"])
      |> where(
        [c],
        c.status in ^[
          ContractRequest.status(:new),
          ContractRequest.status(:approved),
          ContractRequest.status(:nhs_signed)
        ]
      )
      |> where([c], c.end_date >= ^params["start_date"] and c.start_date <= ^params["end_date"])
      |> Repo.all()

    ContractRequest
    |> where([c], c.id in ^contract_ids)
    |> Repo.update_all(set: [status: ContractRequest.status(:terminated)])
  end

  defp user_has_role(data, role) do
    case Enum.find(data, &(Map.get(&1, "role_name") == role)) do
      nil -> {:error, :forbidden}
      _ -> :ok
    end
  end

  defp validate_contract_employee_divisions(%ContractRequest{} = contract_request) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_contract_employee_divisions()
  end

  defp validate_contract_employee_divisions(params) do
    contractor_employee_divisions = params["contractor_employee_divisions"]
    contract_number = params["contract_number"]

    cond do
      !is_nil(contractor_employee_divisions) and !is_nil(contract_number) ->
        {:error,
         [
           {
             %{
               description: "Employee can't be updated via Contract Request",
               params: [],
               rule: :invalid
             },
             "$.contractor_employee_divisions"
           }
         ]}

      (is_nil(contractor_employee_divisions) or contractor_employee_divisions == []) and is_nil(contract_number) ->
        {:error,
         [
           {
             %{
               description: "Contractor employee divisions can’t be empty on create",
               params: [],
               rule: :invalid
             },
             "$.contractor_employee_divisions"
           }
         ]}

      true ->
        :ok
    end
  end

  defp validate_employee_divisions(%ContractRequest{} = contract_request) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_employee_divisions()
  end

  defp validate_employee_divisions(params) do
    contractor_divisions = params["contractor_divisions"]
    contractor_employee_divisions = params["contractor_employee_divisions"] || []

    contractor_employee_divisions
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {employee_division, i}, _ ->
      with {:ok, %Employee{} = employee} <-
             Reference.validate(
               :employee,
               employee_division["employee_id"],
               "$.contractor_employee_divisions[#{i}].employee_id"
             ),
           :ok <- check_employee(employee),
           {:division_subset, true} <- {:division_subset, employee_division["division_id"] in contractor_divisions} do
        {:cont, :ok}
      else
        {:division_subset, _} ->
          {:halt,
           {:error,
            [
              {
                %{
                  description: "Division should be among contractor_divisions",
                  params: [],
                  rule: :invalid
                },
                "$.contractor_employee_divisions[#{i}].division_id"
              }
            ]}}

        error ->
          {:halt, error}
      end
    end)
  end

  defp validate_nhs_signer_id(%ContractRequest{nhs_signer_id: nhs_signer_id}, client_id)
       when not is_nil(nhs_signer_id) do
    validate_nhs_signer_id(%{"nhs_signer_id" => nhs_signer_id}, client_id)
  end

  defp validate_nhs_signer_id(%{"nhs_signer_id" => nhs_signer_id}, client_id) when not is_nil(nhs_signer_id) do
    with %Employee{} = employee <- Employees.get_by_id(nhs_signer_id),
         {:client_id, true} <- {:client_id, employee.legal_entity_id == client_id},
         {:active, true} <- {:active, employee.is_active and employee.status == Employee.status(:approved)} do
      :ok
    else
      {:active, _} ->
        {:error,
         [
           {
             %{
               description: "Employee must be active",
               params: [],
               rule: :invalid
             },
             "$.nhs_signer_id"
           }
         ]}

      {:client_id, _} ->
        {:error,
         [
           {
             %{
               description: "Employee doesn't belong to legal_entity",
               params: [],
               rule: :invalid
             },
             "$.nhs_signer_id"
           }
         ]}

      _ ->
        {:error,
         [
           {
             %{
               description: "Invalid nhs_signer_id",
               params: [],
               rule: :invalid
             },
             "$.nhs_signer_id"
           }
         ]}
    end
  end

  defp validate_nhs_signer_id(_, _), do: :ok

  defp validate_unique_contractor_employee_divisions(%{"contractor_employee_divisions" => employee_divisions})
       when is_list(employee_divisions) do
    employee_divisions_values =
      Enum.map(employee_divisions, fn %{"employee_id" => employee_id, "division_id" => division_id} ->
        "#{employee_id}#{division_id}"
      end)

    if Enum.uniq(employee_divisions_values) == employee_divisions_values do
      :ok
    else
      {:error,
       [
         {
           %{
             description: "Employee division must be unique",
             params: [],
             rule: :invalid
           },
           "$.contractor_employee_divisions"
         }
       ]}
    end
  end

  defp validate_unique_contractor_employee_divisions(_), do: :ok

  defp validate_unique_contractor_divisions(%{"contractor_divisions" => contractor_divisions}) do
    if Enum.uniq(contractor_divisions) == contractor_divisions do
      :ok
    else
      {:error,
       [
         {
           %{
             description: "Division must be unique",
             params: [],
             rule: :invalid
           },
           "$.contractor_divisions"
         }
       ]}
    end
  end

  defp validate_contractor_divisions(%ContractRequest{} = contract_request) do
    validate_contractor_divisions(%{
      "contractor_divisions" => contract_request.contractor_divisions,
      "contractor_legal_entity_id" => contract_request.contractor_legal_entity_id
    })
  end

  defp validate_contractor_divisions(%{
         "contractor_divisions" => contractor_divisions,
         "contractor_legal_entity_id" => contractor_legal_entity_id
       }) do
    contractor_divisions
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {division_id, i}, acc ->
      result =
        with {:ok, division} <- Reference.validate(:division, division_id, "$.contractor_divisions[#{i}]") do
          check_division(division, contractor_legal_entity_id, "$.contractor_divisions[#{i}]")
        end

      case result do
        :ok -> {:cont, acc}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_external_contractor_flag(%{
         "external_contractors" => external_contractors,
         "external_contractor_flag" => true
       })
       when not is_nil(external_contractors) and external_contractors != [],
       do: :ok

  defp validate_external_contractor_flag(params) do
    external_contractors = Map.get(params, "external_contractors")
    external_contractor_flag = Map.get(params, "external_contractor_flag", false)

    if is_nil(external_contractors) && !external_contractor_flag do
      :ok
    else
      {:error,
       [
         {
           %{
             description: "Invalid external_contractor_flag",
             params: [],
             rule: :invalid
           },
           "$.external_contractor_flag"
         }
       ]}
    end
  end

  defp validate_external_contractors(params) do
    external_contractors = params["external_contractors"] || []

    external_contractors
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {contractor, i}, _ ->
      validation_result =
        contractor["divisions"]
        |> Enum.with_index()
        |> Enum.reduce_while(:ok, fn {contractor_division, j}, _ ->
          validate_external_contractor_division(
            params["contractor_divisions"],
            contractor_division,
            "$.external_contractors[#{i}].divisions[#{j}].id"
          )
        end)

      case validation_result do
        :ok ->
          validate_external_contract(contractor, params, "$.external_contractors[#{i}].contract.expires_at")

        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
  end

  defp validate_external_contractor_division(division_ids, division, error) do
    if division["id"] in division_ids do
      {:cont, :ok}
    else
      {:halt,
       {:error,
        [
          {
            %{
              description: "The division is not belong to contractor_divisions",
              params: [],
              rule: :invalid
            },
            error
          }
        ]}}
    end
  end

  defp validate_external_contract(contractor, params, error) do
    expires_at = Date.from_iso8601!(contractor["contract"]["expires_at"])
    start_date = Date.from_iso8601!(params["start_date"])

    case Date.compare(expires_at, start_date) do
      :gt ->
        {:cont, :ok}

      _ ->
        {:halt,
         {:error,
          [
            {
              %{
                description: "Expires date must be greater than contract start_date",
                params: [],
                rule: :invalid
              },
              error
            }
          ]}}
    end
  end

  defp check_employee(%Employee{employee_type: "DOCTOR", status: "APPROVED"}), do: :ok

  defp check_employee(_) do
    {:error,
     [
       {
         %{
           description: "Employee must be active DOCTOR",
           params: [],
           rule: :invalid
         },
         "$.contractor_employee_divisions.employee_id"
       }
     ]}
  end

  defp check_division(%Division{status: "ACTIVE", legal_entity_id: legal_entity_id}, contractor_legal_entity_id, _)
       when legal_entity_id == contractor_legal_entity_id,
       do: :ok

  defp check_division(_, _, error) do
    {:error,
     [
       {
         %{
           description: "Division must be active and within current legal_entity",
           params: [],
           rule: :invalid
         },
         error
       }
     ]}
  end

  defp validate_dates(params) do
    contract_number = params["contract_number"]
    start_date = Map.get(params, "start_date")
    end_date = Map.get(params, "end_date")

    with :ok <- validate_update_dates(contract_number, start_date, end_date),
         :ok <- validate_date_existance(contract_number, start_date, end_date) do
      :ok
    end
  end

  defp validate_update_dates(contract_number, start_date, end_date) do
    cond do
      !is_nil(start_date) and !is_nil(contract_number) ->
        {:error,
         [
           {
             %{
               description: "Start date can't be updated via Contract Request",
               params: [],
               rule: :invalid
             },
             "$.start_date"
           }
         ]}

      !is_nil(end_date) and !is_nil(contract_number) ->
        {:error,
         [
           {
             %{
               description: "End date can't be updated via Contract Request",
               params: [],
               rule: :invalid
             },
             "$.end_date"
           }
         ]}

      true ->
        :ok
    end
  end

  defp validate_date_existance(contract_number, start_date, end_date) do
    cond do
      is_nil(start_date) and is_nil(contract_number) ->
        {:error,
         [
           {
             %{
               description: "Start date can't be empty",
               params: [],
               rule: :required
             },
             "$.start_date"
           }
         ]}

      is_nil(end_date) and is_nil(contract_number) ->
        {:error,
         [
           {
             %{
               description: "End date can't be empty",
               params: [],
               rule: :required
             },
             "$.end_date"
           }
         ]}

      true ->
        :ok
    end
  end

  defp validate_contractor_owner_id(%ContractRequest{
         contractor_owner_id: contractor_owner_id,
         contractor_legal_entity_id: contractor_legal_entity_id
       }) do
    validate_contractor_owner_id(%{
      "contractor_owner_id" => contractor_owner_id,
      "contractor_legal_entity_id" => contractor_legal_entity_id
    })
  end

  defp validate_contractor_owner_id(%{
         "contractor_owner_id" => contractor_owner_id,
         "contractor_legal_entity_id" => contractor_legal_entity_id
       }) do
    with %Employee{} = employee <- Employees.get_by_id(contractor_owner_id),
         true <- employee.status == Employee.status(:approved),
         true <- employee.is_active,
         true <- employee.legal_entity_id == contractor_legal_entity_id,
         true <- employee.employee_type in [Employee.type(:owner), Employee.type(:admin)] do
      :ok
    else
      _ ->
        {:error,
         [
           {
             %{
               description: "Contractor owner must be active within current legal entity in contract request",
               params: [],
               rule: :invalid
             },
             "$.contractor_owner_id"
           }
         ]}
    end
  end

  defp validate_start_date(%ContractRequest{} = contract_request) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_start_date()
  end

  defp validate_start_date(%{"start_date" => start_date}) do
    now = Date.utc_today()
    start_date = Date.from_iso8601!(start_date)
    year_diff = start_date.year - now.year

    with {:diff, true} <- {:diff, year_diff >= 0 && year_diff <= 1},
         {:future, true} <- {:future, Date.compare(start_date, now) == :gt} do
      :ok
    else
      {:diff, false} ->
        {:error,
         [
           {
             %{
               description: "Start date must be within this or next year",
               params: [],
               rule: :invalid
             },
             "$.start_date"
           }
         ]}

      {:future, false} ->
        {:error,
         [
           {
             %{
               description: "Start date must be greater than create date",
               params: [],
               rule: :invalid
             },
             "$.start_date"
           }
         ]}
    end
  end

  defp validate_end_date(%ContractRequest{} = contract_request) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_end_date()
  end

  defp validate_end_date(%{"start_date" => start_date, "end_date" => end_date}) do
    start_date = Date.from_iso8601!(start_date)
    end_date = Date.from_iso8601!(end_date)

    if start_date.year == end_date.year and Date.compare(start_date, end_date) != :gt do
      :ok
    else
      {:error,
       [
         {
           %{
             description: "The year of start_date and and date must be equal",
             params: [],
             rule: :invalid
           },
           "$.end_date"
         }
       ]}
    end
  end

  defp validate_status(%ContractRequest{status: status}, required_status) when status == required_status, do: :ok
  defp validate_status(_, _), do: {:error, {:"422", "Incorrect status of contract_request to modify it"}}

  def get_by_id(headers, client_type, id) do
    client_id = get_client_id(headers)

    with {:ok, %ContractRequest{} = contract_request} <- get_contract_request(client_id, client_type, id) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def get_by_id(id) do
    Repo.get(ContractRequest, id)
  end

  defp get_contract_request(_, "NHS", id) do
    with %ContractRequest{} = contract_request <- Repo.get(ContractRequest, id) do
      {:ok, contract_request}
    end
  end

  defp get_contract_request(client_id, "MSP", id) do
    with %ContractRequest{} = contract_request <- Repo.get(ContractRequest, id),
         :ok <- validate_legal_entity_id(contract_request, client_id) do
      {:ok, contract_request}
    end
  end

  defp validate_legal_entity_id(%ContractRequest{contractor_legal_entity_id: id}, legal_entity_id) do
    if id == legal_entity_id do
      :ok
    else
      {:error, {:forbidden, "User is not allowed to perform this action"}}
    end
  end

  defp validate_contractor_legal_entity(%ContractRequest{contractor_legal_entity_id: legal_entity_id}) do
    with {:ok, legal_entity} <- Reference.validate(:legal_entity, legal_entity_id, "$.contractor_legal_entity_id"),
         true <- legal_entity.status == LegalEntity.status(:active) do
      :ok
    else
      false ->
        {:error,
         [
           {
             %{
               description: "Legal entity in contract request should be active",
               params: [],
               rule: :invalid
             },
             "$.contractor_legal_entity_id"
           }
         ]}

      error ->
        error
    end
  end

  defp resolve_partially_signed_content_url(contract_request_id, headers) do
    bucket = Confex.fetch_env!(:ehealth, EHealth.API.MediaStorage)[:contract_request_bucket]
    resource_name = "contract_request_content.pkcs7"

    media_storage_response =
      @media_storage_api.create_signed_url("GET", bucket, contract_request_id, resource_name, headers)

    case media_storage_response do
      {:ok, %{"data" => %{"secret_url" => url}}} -> {:ok, url}
      _ -> {:error, :media_storage_error}
    end
  end

  defp get_contract_request_sequence do
    case SQL.query(Repo, "SELECT nextval('contract_request');", []) do
      {:ok, %Postgrex.Result{rows: [[sequence]]}} ->
        {:ok, sequence}

      _ ->
        Logger.error("Can't get contract_request sequence")
        {:error, %{"type" => "internal_error"}}
    end
  end

  defp decline_changeset(%ContractRequest{} = contract_request, params) do
    fields_required = ~w(status nhs_signer_id nhs_legal_entity_id updated_by)a
    fields_optional = ~w(status_reason)a

    contract_request
    |> cast(params, fields_required ++ fields_optional)
    |> validate_required(fields_required)
  end

  defp validate_contract_number(%{"contract_number" => contract_number} = params, client_id, headers)
       when not is_nil(contract_number) do
    with {:ok, %{"data" => [contract]}} <-
           @ops_api.get_contracts(%{"contract_number" => contract_number, "status" => "VERIFIED"}, headers),
         {:contractor_legal_entity_id, true} <-
           {:contractor_legal_entity_id, contract["contractor_legal_entity_id"] == client_id} do
      {:ok,
       params
       |> Map.put("start_date", contract["start_date"])
       |> Map.put("end_date", contract["end_date"])
       |> Map.put("contractor_legal_entity_id", client_id)}
    else
      {:contractor_legal_entity_id, false} -> {:error, {:forbidden, "You are not allowed to change this contract"}}
      _ -> {:error, {:"422", "There is no active contract with such contract_number"}}
    end
  end

  defp validate_contract_number(params, client_id, _headers) when not is_nil(client_id) do
    {:ok, Map.put(params, "contractor_legal_entity_id", client_id)}
  end

  defp validate_contract_number(params, _, _), do: {:ok, params}

  defp prepare_contract_request_data(%Ecto.Changeset{} = changeset) do
    data =
      Phoenix.View.render(
        ContractRequestView,
        "show.json",
        contract_request: apply_changes(changeset),
        references: preload_references(apply_changes(changeset))
      )

    data
    |> Jason.encode!()
    |> Jason.decode!()
  end
end

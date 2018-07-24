defmodule EHealth.ContractRequests do
  @moduledoc false

  use EHealth.Search, EHealth.Repo

  import Ecto.Changeset
  import Ecto.Query
  import EHealth.Utils.Connection, only: [get_header: 2, get_consumer_id: 1, get_client_id: 1]

  alias Ecto.Adapters.SQL
  alias Ecto.UUID
  alias EHealth.API.MediaStorage
  alias EHealth.ContractRequests.ContractRequest
  alias EHealth.ContractRequests.Search
  alias EHealth.Contracts
  alias EHealth.Contracts.Contract
  alias EHealth.Divisions.Division
  alias EHealth.Employees
  alias EHealth.Employees.Employee
  alias EHealth.EventManager
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Man.Templates.ContractRequestPrintoutForm
  alias EHealth.Repo
  alias EHealth.Utils.NumberGenerator
  alias EHealth.ValidationError
  alias EHealth.Validators.Error
  alias EHealth.Validators.JsonSchema
  alias EHealth.Validators.Preload
  alias EHealth.Validators.Reference
  alias EHealth.Validators.Signature, as: SignatureValidator
  alias EHealth.Web.ContractRequestView
  alias Scrivener.Page

  require Logger

  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]
  @media_storage_api Application.get_env(:ehealth, :api_resolvers)[:media_storage]
  @signature_api Application.get_env(:ehealth, :api_resolvers)[:digital_signature]

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
    parent_contract_id
  )a

  @forbidden_statuses_for_termination [
    ContractRequest.status(:declined),
    ContractRequest.status(:signed),
    ContractRequest.status(:terminated)
  ]

  def search(search_params) do
    with %Ecto.Changeset{valid?: true} = changeset <- Search.changeset(search_params),
         %Page{} = paging <- search(changeset, search_params, ContractRequest) do
      {:ok, paging}
    end
  end

  def draft do
    id = UUID.generate()

    with {:ok, %{"data" => %{"secret_url" => statute_url}}} <-
           @media_storage_api.create_signed_url(
             "PUT",
             get_bucket(),
             "media/upload_contract_request_statute.pdf",
             id,
             []
           ),
         {:ok, %{"data" => %{"secret_url" => additional_document_url}}} <-
           @media_storage_api.create_signed_url(
             "PUT",
             get_bucket(),
             "media/upload_contract_request_additional_document.pdf",
             id,
             []
           ) do
      %{
        "id" => id,
        "statute_url" => statute_url,
        "additional_document_url" => additional_document_url
      }
    end
  end

  def get_document_attribures_by_status(status) do
    cond do
      Enum.any?(
        ~w(new approved pending_nhs_sign terminated declined)a,
        &(ContractRequest.status(&1) == status)
      ) ->
        [
          {"CONTRACT_REQUEST_STATUTE", "media/contract_request_statute.pdf"},
          {"CONTRACT_REQUEST_ADDITIONAL_DOCUMENT", "media/contract_request_additional_document.pdf"}
        ]

      Enum.any?(~w(signed nhs_signed)a, &(ContractRequest.status(&1) == status)) ->
        [
          {"CONTRACT_REQUEST_STATUTE", "media/contract_request_statute.pdf"},
          {"CONTRACT_REQUEST_ADDITIONAL_DOCUMENT", "media/contract_request_additional_document.pdf"},
          {"SIGNED_CONTENT", "signed_content/signed_content"}
        ]

      true ->
        []
    end
  end

  def gen_relevant_get_links(id, status) do
    Enum.reduce(get_document_attribures_by_status(status), [], fn {name, resource_name}, acc ->
      with {:ok, %{"data" => %{"secret_url" => secret_url}}} <-
             @media_storage_api.create_signed_url("GET", get_bucket(), resource_name, id, []) do
        [%{"type" => name, "url" => secret_url} | acc]
      end
    end)
  end

  def create(headers, %{"id" => id} = params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    params = Map.delete(params, "id")

    with {:contract_request_exists, true} <- {:contract_request_exists, is_nil(get_by_id(id))},
         :ok <- JsonSchema.validate(:contract_request_sign, params),
         {:ok, %{"content" => content, "signer" => signer}} <- decode_signed_content(params, headers),
         :ok <- SignatureValidator.check_drfo(signer, user_id, "contract_request_create"),
         :ok <- JsonSchema.validate(:contract_request, content),
         content <- Map.put(content, "contractor_legal_entity_id", client_id),
         {:ok, params, contract} <- validate_contract_number(content, headers),
         :ok <- validate_contractor_legal_entity_id(params, contract),
         :ok <- validate_dates(params),
         params <- set_dates(contract, params),
         :ok <- validate_unique_contractor_employee_divisions(params),
         :ok <- validate_unique_contractor_divisions(params),
         :ok <- validate_employee_divisions(params, client_id),
         :ok <- validate_contractor_divisions(params),
         :ok <- validate_external_contractors(params),
         :ok <- validate_external_contractor_flag(params),
         :ok <- validate_start_date(params),
         :ok <- validate_end_date(params),
         :ok <- validate_contractor_owner_id(params),
         :ok <-
           validate_document(
             id,
             "media/upload_contract_request_statute.pdf",
             params["statute_md5"],
             headers
           ),
         :ok <-
           validate_document(
             id,
             "media/upload_contract_request_additional_document.pdf",
             params["additional_document_md5"],
             headers
           ),
         :ok <- move_uploaded_documents(id, headers),
         _ <- terminate_pending_contracts(params),
         insert_params <-
           params
           |> Map.put("status", ContractRequest.status(:new))
           |> Map.put("inserted_by", user_id)
           |> Map.put("updated_by", user_id),
         %Ecto.Changeset{valid?: true} = changes <- changeset(%ContractRequest{id: id}, insert_params),
         {:ok, contract_request} <- Repo.insert(changes) do
      {:ok, contract_request, preload_references(contract_request)}
    else
      {:contract_request_exists, false} -> {:error, {:conflict, "Invalid contract_request id"}}
      error -> error
    end
  end

  def update(headers, %{"id" => id} = params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    params = Map.delete(params, "id")

    with :ok <- JsonSchema.validate(:contract_request_update, params),
         {:ok, %{"data" => data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(data, "NHS ADMIN SIGNER"),
         %ContractRequest{} = contract_request <- Repo.get(ContractRequest, id),
         :ok <- validate_nhs_signer_id(params, client_id),
         :ok <- validate_status(contract_request, ContractRequest.status(:new)),
         :ok <- validate_start_date(contract_request),
         update_params <-
           params
           |> Map.put("nhs_legal_entity_id", client_id)
           |> Map.put("updated_by", user_id),
         %Ecto.Changeset{valid?: true} = changes <- update_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def approve(headers, %{"id" => id} = params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    params = Map.delete(params, "id")

    with %ContractRequest{} = contract_request <- get_by_id(id),
         references <- preload_references(contract_request),
         :ok <- JsonSchema.validate(:contract_request_sign, params),
         {:ok, %{"content" => content, "signer" => signer}} <- decode_signed_content(:nhs, params, headers),
         :ok <- SignatureValidator.check_drfo(signer, user_id, "contract_request_approve"),
         {:ok, %{"data" => data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(data, "NHS ADMIN SIGNER"),
         :ok <- JsonSchema.validate(:contract_request_approve, content),
         :ok <- validate_contractor_legal_entity(contract_request),
         :ok <- validate_approve_content(content, contract_request, references),
         :ok <- validate_status(contract_request, ContractRequest.status(:new)),
         :ok <-
           save_signed_content(
             contract_request.id,
             params,
             headers,
             "signed_content/contract_request_approved"
           ),
         :ok <- validate_contract_id(contract_request),
         :ok <- validate_contractor_owner_id(contract_request),
         :ok <- validate_nhs_signer_id(contract_request, client_id),
         :ok <- validate_employee_divisions(contract_request, client_id),
         :ok <- validate_contractor_divisions(contract_request),
         :ok <- validate_start_date(contract_request),
         update_params <-
           params
           |> Map.delete("id")
           |> Map.put("updated_by", user_id)
           |> set_contract_number(contract_request)
           |> Map.put("status", ContractRequest.status(:approved)),
         %Ecto.Changeset{valid?: true} = changes <- approve_changeset(contract_request, update_params),
         data <- prepare_contract_request_data(changes),
         %Ecto.Changeset{valid?: true} = changes <- put_change(changes, :data, data),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def approve_msp(headers, %{"id" => id} = params) do
    client_id = get_client_id(headers)
    user_id = get_consumer_id(headers)

    with %ContractRequest{} = contract_request <- get_by_id(id),
         {_, true} <- {:client_id, client_id == contract_request.contractor_legal_entity_id},
         :ok <- validate_status(contract_request, ContractRequest.status(:approved)),
         :ok <- validate_contractor_legal_entity(contract_request),
         {:contractor_owner, :ok} <- {:contractor_owner, validate_contractor_owner_id(contract_request)},
         :ok <- validate_employee_divisions(contract_request, client_id),
         :ok <- validate_contractor_divisions(contract_request),
         :ok <- validate_start_date(contract_request),
         update_params <-
           params
           |> Map.delete("id")
           |> Map.put("updated_by", user_id)
           |> Map.put("status", ContractRequest.status(:pending_nhs_sign)),
         %Ecto.Changeset{valid?: true} = changes <- approve_msp_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    else
      {:client_id, _} ->
        {:error, {:forbidden, "Client is not allowed to modify contract_request"}}

      {:contractor_owner, _} ->
        {:error, {:forbidden, "User is not allowed to perform this action"}}

      error ->
        error
    end
  end

  def decline(headers, %{"id" => id} = params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    params = Map.delete(params, "id")

    with %ContractRequest{} = contract_request <- get_by_id(id),
         references <- preload_references(contract_request),
         :ok <- JsonSchema.validate(:contract_request_sign, params),
         {:ok, %{"content" => content, "signer" => signer}} <- decode_signed_content(:nhs, params, headers),
         :ok <- SignatureValidator.check_drfo(signer, user_id, "contract_request_decline"),
         {:ok, %{"data" => data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(data, "NHS ADMIN SIGNER"),
         :ok <- JsonSchema.validate(:contract_request_decline, content),
         :ok <- validate_contractor_legal_entity(contract_request),
         :ok <- validate_decline_content(content, contract_request, references),
         :ok <- validate_status(contract_request, ContractRequest.status(:new)),
         :ok <-
           save_signed_content(
             contract_request.id,
             params,
             headers,
             "signed_content/contract_request_declined"
           ),
         update_params <-
           content
           |> Map.take(~w(status_reason))
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
         true <- contract_request.status not in @forbidden_statuses_for_termination,
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
        Error.dump("Incorrect status of contract_request to modify it")

      {:contractor_owner, _} ->
        {:error, {:forbidden, "User is not allowed to perform this action"}}

      error ->
        error
    end
  end

  def sign_nhs(headers, %{"id" => id} = params) do
    client_id = get_client_id(headers)
    user_id = get_consumer_id(headers)
    params = Map.delete(params, "id")

    with %ContractRequest{} = contract_request <- get_by_id(id),
         :ok <- JsonSchema.validate(:contract_request_sign, params),
         {_, true} <- {:client_id, client_id == contract_request.nhs_legal_entity_id},
         {_, false} <- {:already_signed, contract_request.status == ContractRequest.status(:nhs_signed)},
         :ok <- validate_status(contract_request, ContractRequest.status(:pending_nhs_sign)),
         {:ok, %{"content" => content, "signer" => signer}} <- decode_signed_content(:nhs, params, headers),
         :ok <- validate_contractor_legal_entity(contract_request),
         :ok <- validate_contractor_owner_id(contract_request),
         :ok <-
           SignatureValidator.check_drfo(
             signer,
             contract_request.nhs_signer_id,
             "$.nhs_signer_id",
             "contract_request_sign_nhs"
           ),
         {:ok, printout_content} <-
           ContractRequestPrintoutForm.render(
             %{contract_request | nhs_signed_date: Date.utc_today()},
             headers
           ),
         :ok <- validate_content(contract_request, printout_content, content),
         :ok <- validate_contract_id(contract_request),
         :ok <- validate_employee_divisions(contract_request, client_id),
         :ok <- validate_start_date(contract_request),
         :ok <-
           save_signed_content(
             contract_request.id,
             params,
             headers,
             "signed_content/signed_content"
           ),
         update_params <-
           params
           |> Map.put("updated_by", user_id)
           |> Map.put("status", ContractRequest.status(:nhs_signed))
           |> Map.put("nhs_signed_date", Date.utc_today())
           |> Map.put("printout_content", printout_content),
         %Ecto.Changeset{valid?: true} = changes <- nhs_signed_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    else
      {:client_id, _} -> {:error, {:forbidden, "Invalid client_id"}}
      {:already_signed, _} -> Error.dump("The contract was already signed by NHS")
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
         {:ok, %{"content" => content, "signer" => signer}} <- decode_signed_content(:msp, params, headers),
         :ok <-
           SignatureValidator.check_drfo(
             signer,
             contract_request.contractor_owner_id,
             "$.contractor_owner_id",
             "contract_request_sign_msp"
           ),
         :ok <- validate_content(contract_request, content),
         :ok <- validate_employee_divisions(contract_request, client_id),
         :ok <- validate_start_date(contract_request),
         :ok <- validate_contractor_legal_entity(contract_request),
         :ok <- validate_contractor_owner_id(contract_request),
         contract_id <- UUID.generate(),
         :ok <- save_signed_content(contract_id, params, headers, "signed_content/signed_content"),
         update_params <-
           params
           |> Map.put("updated_by", user_id)
           |> Map.put("status", ContractRequest.status(:signed))
           |> Map.put("contract_id", contract_id),
         %Ecto.Changeset{valid?: true} = changes <- msp_signed_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         contract_params <- get_contract_create_params(contract_request),
         {:create_contract, {:ok, contract}} <- {:create_contract, Contracts.create(contract_params)},
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      Contracts.load_contract_references(contract)
    else
      {:signed_nhs, false} ->
        Error.dump("Incorrect status for signing")

      {:client_id, _} ->
        {:error, {:forbidden, "Invalid client_id"}}

      {:employee, _} ->
        Error.dump("Employee is not allowed to sign")

      {:create_contract, _} ->
        {:error, {:bad_gateway, "Failed to save contract"}}

      error ->
        error
    end
  end

  def get_partially_signed_content_url(headers, %{"id" => id}) do
    client_id = get_client_id(headers)

    with %ContractRequest{} = contract_request <- Repo.get(ContractRequest, id),
         {_, true} <- {:signed_nhs, contract_request.status == ContractRequest.status(:nhs_signed)},
         {_, true} <- {:client_id, client_id == contract_request.contractor_legal_entity_id},
         {:ok, url} <- resolve_partially_signed_content_url(contract_request.id, headers) do
      {:ok, url}
    else
      {:signed_nhs, _} ->
        Error.dump("The contract hasn't been signed yet")

      {:client_id, _} ->
        {:error, {:forbidden, "Invalid client_id"}}

      {:error, :media_storage_error} ->
        {:error, {:bad_gateway, "Fail to resolve partially signed content"}}

      error ->
        error
    end
  end

  def get_printout_content(id, client_type, headers) do
    with {:ok, contract_request, _} <- get_by_id(headers, client_type, id),
         :ok <-
           validate_status(
             contract_request,
             ContractRequest.status(:pending_nhs_sign),
             "Incorrect status of contract_request to generate printout form"
           ),
         {:ok, printout_content} <-
           ContractRequestPrintoutForm.render(
             Map.put(contract_request, :nhs_signed_date, Date.utc_today()),
             headers
           ) do
      {:ok, contract_request, printout_content}
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
      nhs_signer_base
      issue_city
      contract_number
      contractor_divisions
      contractor_employee_divisions
      status
      nhs_signer_id
      nhs_contract_price
      parent_contract_id
      id_form
      nhs_signed_date
    )a)
    |> Map.put(:id, contract_id)
    |> Map.put(:contract_request_id, id)
    |> Map.put(:is_suspended, false)
    |> Map.put(:is_active, true)
    |> Map.put(:inserted_by, contract_request.updated_by)
    |> Map.put(:updated_by, contract_request.updated_by)
    |> Map.put(:status, Contract.status(:verified))
  end

  defp validate_content(%ContractRequest{data: data, printout_content: printout_content}, content) do
    data_content =
      data
      |> Map.delete("status")
      |> Map.put("printout_content", printout_content)

    content = Map.drop(content, ["status"])

    if data_content == content,
      do: :ok,
      else: Error.dump("Signed content does not match the previously created content")
  end

  defp validate_content(%ContractRequest{data: data}, printout_content, content) do
    data_content =
      data
      |> Map.delete("status")
      |> Map.put("printout_content", printout_content)

    content = Map.drop(content, ["status"])

    if data_content == content,
      do: :ok,
      else: Error.dump("Signed content does not match the previously created content")
  end

  defp save_signed_content(id, %{"signed_content" => signed_content}, headers, resource_name) do
    signed_content
    |> @media_storage_api.store_signed_content(
      :contract_request_bucket,
      id,
      resource_name,
      headers
    )
    |> case do
      {:ok, _} -> :ok
      _error -> {:error, {:bad_gateway, "Failed to save signed content"}}
    end
  end

  def decode_signed_content(
        :nhs,
        %{"signed_content" => signed_content, "signed_content_encoding" => encoding},
        headers
      ) do
    SignatureValidator.validate(signed_content, encoding, headers)
  end

  def decode_signed_content(
        :msp,
        %{"signed_content" => signed_content, "signed_content_encoding" => encoding},
        headers
      ) do
    SignatureValidator.validate(signed_content, encoding, headers, 2)
  end

  def decode_signed_content(
        %{"signed_content" => signed_content, "signed_content_encoding" => encoding},
        headers
      ) do
    SignatureValidator.validate(signed_content, encoding, headers)
  end

  def decode_and_validate_signed_content(%ContractRequest{id: id}, headers) do
    with {:ok, %{"data" => %{"secret_url" => secret_url}}} <-
           @media_storage_api.create_signed_url(
             "GET",
             MediaStorage.config()[:contract_request_bucket],
             "signed_content/signed_content",
             id,
             headers
           ),
         {:ok, %{body: content, status_code: 200}} <- @media_storage_api.get_signed_content(secret_url),
         {:ok, %{"data" => %{"content" => content}}} <-
           @signature_api.decode_and_validate(
             Base.encode64(content),
             "base64",
             headers
           ) do
      {:ok, content}
    end
  end

  defp set_contract_number(params, %{parent_contract_id: parent_contract_id})
       when not is_nil(parent_contract_id) do
    params
  end

  defp set_contract_number(params, _) do
    with {:ok, sequence} <- get_contract_request_sequence() do
      Map.put(params, "contract_number", NumberGenerator.generate_from_sequence(1, sequence))
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
      ~w(
        nhs_legal_entity_id
        nhs_signer_id
        nhs_signer_base
        nhs_contract_price
        nhs_payment_method
        issue_city
        misc
      )a
    )
    |> validate_number(:nhs_contract_price, greater_than: 0)
  end

  def approve_changeset(%ContractRequest{} = contract_request, params) do
    fields_required = ~w(
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

    fields_optional = ~w(misc)a

    contract_request
    |> cast(params, fields_required ++ fields_optional)
    |> validate_required(fields_required)
  end

  def approve_msp_changeset(%ContractRequest{} = contract_request, params) do
    fields = ~w(
      status
      updated_by
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
    fields = ~w(status updated_by printout_content nhs_signed_date)a

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
      {:contractor_divisions, :division},
      {[:external_contractors, "$", "divisions", "$", "id"], :division},
      {[:external_contractors, "$", "legal_entity_id"], :legal_entity}
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
          ContractRequest.status(:nhs_signed),
          ContractRequest.status(:pending_nhs_sign)
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

  defp validate_employee_divisions(%ContractRequest{} = contract_request, client_id) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_employee_divisions(client_id)
  end

  defp validate_employee_divisions(params, client_id) do
    contractor_divisions = params["contractor_divisions"]
    contractor_employee_divisions = params["contractor_employee_divisions"] || []

    errors =
      contractor_employee_divisions
      |> Enum.with_index()
      |> Enum.reduce([], fn {employee_division, i}, errors_list ->
        errors_list
        |> validate_employee_division_employee(employee_division, client_id, i)
        |> validate_employee_division_subset(contractor_divisions, employee_division, i)
      end)

    if length(errors) > 0 do
      errors
      |> validate_and_convert_errors
      |> Error.dump()
    else
      :ok
    end
  end

  defp validate_employee_division_employee(errors, division, client_id, index) do
    with {:ok, %Employee{} = employee} <-
           Reference.validate(
             :employee,
             division["employee_id"],
             "$.contractor_employee_divisions[#{index}].employee_id"
           ),
         :ok <- check_employee(employee, client_id, index) do
      errors
    else
      {:error, error} when is_list(error) -> errors ++ error
      {:error, error} -> errors ++ [error]
    end
  end

  defp validate_employee_division_subset(errors, division_subset, division, index) do
    if division["division_id"] in division_subset do
      errors
    else
      errors ++
        [
          %ValidationError{
            description: "Division should be among contractor_divisions",
            path: "$.contractor_employee_divisions[#{index}].division_id"
          }
        ]
    end
  end

  defp validate_nhs_signer_id(%ContractRequest{nhs_signer_id: nhs_signer_id}, client_id)
       when not is_nil(nhs_signer_id) do
    validate_nhs_signer_id(%{"nhs_signer_id" => nhs_signer_id}, client_id)
  end

  defp validate_nhs_signer_id(%{"nhs_signer_id" => nhs_signer_id}, client_id)
       when not is_nil(nhs_signer_id) do
    with %Employee{} = employee <- Employees.get_by_id(nhs_signer_id),
         {:client_id, true} <- {:client_id, employee.legal_entity_id == client_id},
         {:active, true} <- {:active, employee.is_active and employee.status == Employee.status(:approved)} do
      :ok
    else
      {:active, _} ->
        Error.dump(%ValidationError{description: "Employee must be active", path: "$.nhs_signer_id"})

      {:client_id, _} ->
        Error.dump(%ValidationError{description: "Employee doesn't belong to legal_entity", path: "$.nhs_signer_id"})

      _ ->
        Error.dump(%ValidationError{description: "Invalid nhs_signer_id", path: "$.nhs_signer_id"})
    end
  end

  defp validate_nhs_signer_id(_, _), do: :ok

  defp validate_unique_contractor_employee_divisions(%{
         "contractor_employee_divisions" => employee_divisions
       })
       when is_list(employee_divisions) do
    employee_divisions_values =
      Enum.map(employee_divisions, fn %{
                                        "employee_id" => employee_id,
                                        "division_id" => division_id
                                      } ->
        "#{employee_id}#{division_id}"
      end)

    if Enum.uniq(employee_divisions_values) == employee_divisions_values do
      :ok
    else
      Error.dump(%ValidationError{
        description: "Employee division must be unique",
        path: "$.contractor_employee_divisions"
      })
    end
  end

  defp validate_unique_contractor_employee_divisions(_), do: :ok

  defp validate_unique_contractor_divisions(%{"contractor_divisions" => contractor_divisions}) do
    if Enum.uniq(contractor_divisions) == contractor_divisions do
      :ok
    else
      Error.dump(%ValidationError{description: "Division must be unique", path: "$.contractor_divisions"})
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
    errors =
      contractor_divisions
      |> Enum.with_index()
      |> Enum.reduce([], fn {division_id, i}, acc ->
        result =
          with {:ok, division} <- Reference.validate(:division, division_id, "$.contractor_divisions[#{i}]") do
            check_division(division, contractor_legal_entity_id, "$.contractor_divisions[#{i}]")
          end

        case result do
          :ok -> acc
          {:error, error} when is_list(error) -> acc ++ error
          {:error, error} -> acc ++ [error]
        end
      end)

    if length(errors) > 0 do
      errors
      |> validate_and_convert_errors
      |> Error.dump()
    else
      :ok
    end
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
      Error.dump(%ValidationError{description: "Invalid external_contractor_flag", path: "$.external_contractor_flag"})
    end
  end

  defp validate_external_legal_entity(errors, %{"legal_entity_id" => legal_entity_id}, index)
       when not is_nil(legal_entity_id) do
    validation_result =
      Reference.validate(
        :legal_entity,
        legal_entity_id,
        "$.external_contractors[#{index}].legal_entity_id"
      )

    case validation_result do
      {:error, _} ->
        errors ++
          [
            %ValidationError{
              description: "Active $external_contractors[#{index}].legal_entity_id does not exist",
              path: "$.external_contractors[#{index}].legal_entity_id"
            }
          ]

      _ ->
        errors
    end
  end

  defp validate_external_legal_entity(errors, _, index) do
    errors ++
      [
        %ValidationError{
          description: "Active $external_contractors[#{index}].legal_entity_id does not exist",
          path: "$.external_contractors[#{index}].legal_entity_id"
        }
      ]
  end

  defp validate_divisions(errors, params, contractor, i) do
    contractor["divisions"]
    |> Enum.with_index()
    |> Enum.reduce(errors, fn {contractor_division, j}, errors ->
      with :ok <-
             validate_external_contractor_division(
               params["contractor_divisions"],
               contractor_division,
               "$.external_contractors[#{i}].divisions[#{j}].id"
             ) do
        errors
      else
        {:error, error} when is_list(error) -> errors ++ error
        {:error, error} -> errors ++ [error]
      end
    end)
  end

  defp validate_external_contractors(params) do
    external_contractors = params["external_contractors"] || []

    errors =
      external_contractors
      |> Enum.with_index()
      |> Enum.reduce([], fn {contractor, i}, errors_list ->
        errors_list
        |> validate_external_legal_entity(contractor, i)
        |> validate_divisions(params, contractor, i)
        |> validate_external_contract(
          contractor,
          params,
          "$.external_contractors[#{i}].contract.expires_at"
        )
      end)

    if length(errors) > 0 do
      errors
      |> validate_and_convert_errors
      |> Error.dump()
    else
      :ok
    end
  end

  defp validate_external_contractor_division(division_ids, division, error) do
    if division["id"] in division_ids do
      :ok
    else
      Error.dump(%ValidationError{description: "The division is not belong to contractor_divisions", path: error})
    end
  end

  defp validate_external_contract(errors, contractor, params, error) do
    expires_at = Date.from_iso8601!(contractor["contract"]["expires_at"])
    start_date = Date.from_iso8601!(params["start_date"])

    case Date.compare(expires_at, start_date) do
      :gt ->
        errors

      _ ->
        errors ++ [%ValidationError{description: "Expires date must be greater than contract start_date", path: error}]
    end
  end

  defp check_employee(employee, client_id, index) do
    errors =
      []
      |> check_employee_type_and_status(employee, index)
      |> check_employee_legal_entity(employee, client_id, index)

    if length(errors) > 0, do: {:error, errors}, else: :ok
  end

  defp check_employee_type_and_status(errors, %Employee{employee_type: "DOCTOR", status: "APPROVED"}, _), do: errors

  defp check_employee_type_and_status(errors, _, index) do
    errors ++
      [
        %ValidationError{
          description: "Employee must be active DOCTOR",
          path: "$.contractor_employee_divisions[#{index}].employee_id"
        }
      ]
  end

  defp check_employee_legal_entity(errors, %Employee{legal_entity_id: legal_entity_id}, legal_entity_id, _), do: errors

  defp check_employee_legal_entity(errors, _, _, index) do
    errors ++
      [
        %ValidationError{
          description: "Employee should be active Doctor within current legal_entity_id",
          path: "$.contractor_employee_divisions[#{index}].employee_id"
        }
      ]
  end

  defp check_division(
         %Division{status: "ACTIVE", legal_entity_id: legal_entity_id},
         contractor_legal_entity_id,
         _
       )
       when legal_entity_id == contractor_legal_entity_id,
       do: :ok

  defp check_division(_, _, error) do
    Error.dump(%ValidationError{description: "Division must be active and within current legal_entity", path: error})
  end

  defp validate_dates(%{"parent_contract_id" => parent_contract_id, "start_date" => start_date})
       when not is_nil(parent_contract_id) and not is_nil(start_date) do
    Error.dump(%ValidationError{description: "Start date can't be updated via Contract Request", path: "$.start_date"})
  end

  defp validate_dates(%{"parent_contract_id" => parent_contract_id, "end_date" => end_date})
       when not is_nil(parent_contract_id) and not is_nil(end_date) do
    Error.dump(%ValidationError{description: "End date can't be updated via Contract Request", path: "$.end_date"})
  end

  defp validate_dates(%{"parent_contract_id" => parent_contract_id})
       when not is_nil(parent_contract_id),
       do: :ok

  defp validate_dates(params) do
    cond do
      is_nil(params["start_date"]) ->
        Error.dump(%ValidationError{description: "Start date can't be empty", path: "$.start_date"})

      is_nil(params["end_date"]) ->
        Error.dump(%ValidationError{description: "End date can't be empty", path: "$.end_date"})

      true ->
        :ok
    end
  end

  defp set_dates(nil, params), do: params

  defp set_dates(%Contract{} = contract, params) do
    params
    |> Map.put("start_date", to_string(contract.start_date))
    |> Map.put("end_date", to_string(contract.end_date))
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
        Error.dump(%ValidationError{
          description: "Contractor owner must be active within current legal entity in contract request",
          path: "$.contractor_owner_id"
        })
    end
  end

  defp validate_start_date(%ContractRequest{} = contract_request) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_start_date()
  end

  defp validate_start_date(%{"parent_contract_id" => parent_contract_id})
       when not is_nil(parent_contract_id) do
    :ok
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
        Error.dump(%ValidationError{description: "Start date must be within this or next year", path: "$.start_date"})

      {:future, false} ->
        Error.dump(%ValidationError{description: "Start date must be greater than current date", path: "$.start_date"})
    end
  end

  defp validate_end_date(%ContractRequest{} = contract_request) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_end_date()
  end

  defp validate_end_date(%{"parent_contract_id" => parent_contract_id})
       when not is_nil(parent_contract_id) do
    :ok
  end

  defp validate_end_date(%{"start_date" => start_date, "end_date" => end_date}) do
    start_date = Date.from_iso8601!(start_date)
    end_date = Date.from_iso8601!(end_date)

    cond do
      start_date.year != end_date.year ->
        Error.dump(%ValidationError{
          description: "The year of start_date and and date must be equal",
          path: "$.end_date"
        })

      Date.compare(start_date, end_date) == :gt ->
        Error.dump(%ValidationError{
          description: "end_date should be equal or greater than start_date",
          path: "$.end_date"
        })

      true ->
        :ok
    end
  end

  defp validate_status(contract_request, status),
    do:
      validate_status(
        contract_request,
        status,
        "Incorrect status of contract_request to modify it"
      )

  defp validate_status(%ContractRequest{status: status}, required_status, _)
       when status == required_status,
       do: :ok

  defp validate_status(_, _, msg), do: {:error, {:conflict, msg}}

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

  defp validate_contractor_legal_entity(%ContractRequest{
         contractor_legal_entity_id: legal_entity_id
       }) do
    with {:ok, legal_entity} <- Reference.validate(:legal_entity, legal_entity_id, "$.contractor_legal_entity_id"),
         true <- legal_entity.status == LegalEntity.status(:active) and legal_entity.is_active do
      :ok
    else
      false ->
        Error.dump(%ValidationError{
          description: "Legal entity in contract request should be active",
          path: "$.contractor_legal_entity_id"
        })

      error ->
        error
    end
  end

  defp resolve_partially_signed_content_url(contract_request_id, headers) do
    bucket = Confex.fetch_env!(:ehealth, EHealth.API.MediaStorage)[:contract_request_bucket]
    resource_name = "contract_request_content.pkcs7"

    media_storage_response =
      @media_storage_api.create_signed_url(
        "GET",
        bucket,
        contract_request_id,
        resource_name,
        headers
      )

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

  defp validate_contract_id(%ContractRequest{parent_contract_id: contract_id})
       when not is_nil(contract_id) do
    with %Contract{} = contract <- Contracts.get_by_id(contract_id),
         true <- contract.status == "VERIFIED" do
      :ok
    else
      _ -> {:error, {:conflict, "Parent contract can’t be updated"}}
    end
  end

  defp validate_contract_id(_), do: :ok

  defp validate_contract_number(%{"contract_number" => contract_number} = params, headers)
       when not is_nil(contract_number) do
    with {:ok, %Page{entries: [%Contract{} = contract]}, _} <-
           Contracts.list(
             %{"contract_number" => contract_number, "status" => Contract.status(:verified)},
             nil,
             headers
           ) do
      {:ok, Map.put(params, "parent_contract_id", contract.id), contract}
    else
      _ ->
        Error.dump("Verified contract with such contract number does not exist")
    end
  end

  defp validate_contract_number(
         %{"contractor_legal_entity_id" => legal_entity_id} = params,
         headers
       ) do
    with {:ok, %Page{entries: [_ | _]}, _} <-
           Contracts.list(
             %{
               "contractor_legal_entity_id" => legal_entity_id,
               "status" => Contract.status(:verified),
               "date_to_start_date" => params["end_date"],
               "date_from_end_date" => params["start_date"]
             },
             nil,
             headers
           ) do
      Error.dump("Active contract is found. Contract number must be sent in request")
    else
      _ -> {:ok, params, nil}
    end
  end

  defp validate_contractor_legal_entity_id(_, nil), do: :ok

  defp validate_contractor_legal_entity_id(
         %{"contractor_legal_entity_id" => contractor_legal_entity_id},
         %Contract{} = contract
       ) do
    if contract.contractor_legal_entity_id == contractor_legal_entity_id do
      :ok
    else
      {:error, {:forbidden, "You are not allowed to change this contract"}}
    end
  end

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

  defp validate_decline_content(content, contract_request, references) do
    data =
      ContractRequestView
      |> Phoenix.View.render(
        "contract_request_decline.json",
        contract_request: contract_request,
        references: references
      )
      |> Jason.encode!()
      |> Jason.decode!()

    if data == Map.drop(content, ~w(next_status status_reason text)) do
      :ok
    else
      {:error, {:bad_request, "Signed content doesn't match with contract request"}}
    end
  end

  defp validate_approve_content(content, contract_request, references) do
    data =
      ContractRequestView
      |> Phoenix.View.render(
        "contract_request_approve.json",
        contract_request: contract_request,
        references: references
      )
      |> Jason.encode!()
      |> Jason.decode!()

    if data == Map.drop(content, ~w(next_status text)) do
      :ok
    else
      {:error, {:bad_request, "Signed content doesn't match with contract request"}}
    end
  end

  defp validate_document(id, resource_name, md5, headers) do
    with {:ok, %{"data" => %{"secret_url" => url}}} <-
           @media_storage_api.create_signed_url("HEAD", get_bucket(), resource_name, id, headers),
         {:ok, %HTTPoison.Response{status_code: 200, headers: resource_headers}} <-
           @media_storage_api.verify_uploaded_file(url, resource_name),
         true <- md5 == resource_headers |> get_header("ETag") |> Jason.decode!() do
      :ok
    else
      _ -> Error.dump("#{resource_name} md5 doesn't match")
    end
  end

  defp move_uploaded_documents(id, headers) do
    Enum.reduce_while(
      [
        {"media/upload_contract_request_statute.pdf", "media/contract_request_statute.pdf"},
        {"media/upload_contract_request_additional_document.pdf", "media/contract_request_additional_document.pdf"}
      ],
      :ok,
      fn {temp_resource_name, resource_name}, _ ->
        move_file(id, temp_resource_name, resource_name, headers)
      end
    )
  end

  defp move_file(id, temp_resource_name, resource_name, headers) do
    with {:ok, %{"data" => %{"secret_url" => url}}} <-
           @media_storage_api.create_signed_url("GET", get_bucket(), temp_resource_name, id, []),
         {:ok, %{body: signed_content}} <- @media_storage_api.get_signed_content(url),
         {:ok, _} <- @media_storage_api.save_file(id, signed_content, get_bucket(), resource_name, headers),
         {:ok, %{"data" => %{"secret_url" => url}}} <-
           @media_storage_api.create_signed_url("DELETE", get_bucket(), temp_resource_name, id, []),
         {:ok, _} <- @media_storage_api.delete_file(url) do
      {:cont, :ok}
    end
  end

  defp get_bucket do
    Confex.fetch_env!(:ehealth, EHealth.API.MediaStorage)[:contract_request_bucket]
  end

  defp validate_and_convert_errors(errors) when is_list(errors) do
    Enum.map(errors, fn error ->
      case error do
        {%{
           description: description,
           params: params,
           rule: rule
         }, path} ->
          %ValidationError{description: description, rule: rule, path: path, params: params}

        _ ->
          error
      end
    end)
  end
end

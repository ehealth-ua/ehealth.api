defmodule Core.ContractRequests do
  @moduledoc false

  use Core.Search, Core.Repo

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import Ecto.Changeset
  import Ecto.Query
  import Core.ContractRequests.Storage
  import Core.ContractRequests.Validator

  alias Core.CapitationContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.ContractRequests.Renderer
  alias Core.ContractRequests.RequestPack
  alias Core.ContractRequests.Search
  alias Core.ContractRequests.Storage
  alias Core.Contracts
  alias Core.EventManager
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.Man.Templates.ContractRequestPrintoutForm
  alias Core.Repo
  alias Core.Utils.NumberGenerator
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Core.Validators.Preload
  alias Core.Validators.Signature, as: SignatureValidator
  alias Ecto.Adapters.SQL
  alias Ecto.Changeset
  alias Ecto.UUID
  alias Scrivener.Page

  require Logger

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  @capitation CapitationContractRequest.type()
  @reimbursement ReimbursementContractRequest.type()

  @approved CapitationContractRequest.status(:approved)
  @declined CapitationContractRequest.status(:declined)
  @in_process CapitationContractRequest.status(:in_process)
  @pending_nhs_sign CapitationContractRequest.status(:pending_nhs_sign)

  @forbidden_statuses_for_termination [
    CapitationContractRequest.status(:declined),
    CapitationContractRequest.status(:signed),
    CapitationContractRequest.status(:terminated)
  ]

  defmacro __using__(schema: schema) do
    quote do
      import Core.API.Helpers.Connection, only: [get_client_id: 1]

      alias Core.ContractRequests
      alias Core.ContractRequests.Validator
      alias Core.Repo

      def get_by_id(id), do: Repo.get_by(unquote(schema), %{id: id, type: unquote(schema).type()})

      def get_by_id!(id), do: Repo.get_by!(unquote(schema), %{id: id, type: unquote(schema).type()})

      def fetch_by_id(id) do
        case get_by_id(id) do
          %unquote(schema){} = contract_request -> {:ok, contract_request}
          nil -> {:error, {:not_found, "Contract Request not found"}}
        end
      end
    end
  end

  def search(%{"type" => type} = search_params) do
    with %Changeset{valid?: true} = changeset <- Search.changeset(search_params),
         %Page{} = paging <- search(changeset, search_params, RequestPack.get_schema_by_type(type)) do
      {:ok, paging}
    end
  end

  def get_by_id_with_client_validation(headers, client_type, %RequestPack{} = pack) do
    client_id = get_client_id(headers)

    with {:ok, contract_request} <- fetch_by_id(pack),
         :ok <- validate_contract_request_client_access(client_type, client_id, contract_request) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def get_by_id(%RequestPack{} = pack), do: pack.provider.get_by_id(pack.contract_request_id)

  @deprecated "Use get_by_id(%RequestPack{})"
  def get_by_id(id), do: CapitationContractRequests.get_by_id(id)

  def get_by_id!(%RequestPack{} = pack), do: pack.provider.get_by_id!(pack.contract_request_id)

  @deprecated "Use get_by_id!(%RequestPack{})"
  def get_by_id!(id), do: CapitationContractRequests.get_by_id!(id)

  def fetch_by_id(%RequestPack{} = pack), do: pack.provider.fetch_by_id(pack.contract_request_id)

  @deprecated "Use fetch_by_id(%RequestPack{})"
  def fetch_by_id(id), do: CapitationContractRequests.fetch_by_id(id)

  defdelegate draft, to: Storage, as: :draft

  defdelegate gen_relevant_get_links(id, status), to: Storage, as: :gen_relevant_get_links

  def create(headers, %{"id" => id, "type" => type} = params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    pack = RequestPack.new(params)
    params = pack.request_params

    with %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(client_id),
         {:contract_request_exists, true} <- {:contract_request_exists, is_nil(get_by_id(pack))},
         :ok <- JsonSchema.validate(:contract_request_sign, params),
         {:ok, %{"content" => content, "signers" => [signer]}} <- decode_signed_content(params, headers),
         :ok <- SignatureValidator.check_drfo(signer, user_id, "contract_request_create"),
         :ok <- validate_contract_request_type(type, legal_entity),
         :ok <- validate_create_content_schema(type, content),
         :ok <- validate_legal_entity_edrpou(legal_entity, signer),
         :ok <- validate_user_signer_last_name(user_id, signer),
         content <- Map.put(content, "contractor_legal_entity_id", client_id),
         {:ok, content, contract} <- validate_contract_number(type, content, headers),
         :ok <- validate_contractor_legal_entity_id(client_id, contract),
         pack <- RequestPack.put_decoded_content(pack, content),
         :ok <- validate_previous_request(pack, client_id),
         :ok <- validate_dates(content),
         content <- set_dates(contract, content),
         pack <- RequestPack.put_decoded_content(pack, content),
         {:ok, contract_request} <- validate_contract_request_content(:create, pack, client_id),
         :ok <- validate_unique_contractor_divisions(content),
         :ok <- validate_contractor_divisions(content),
         :ok <- validate_start_date(content),
         :ok <- validate_end_date(content),
         :ok <- validate_contractor_owner_id(type, content),
         :ok <-
           validate_document(
             id,
             "media/upload_contract_request_statute.pdf",
             content["statute_md5"],
             headers
           ),
         :ok <-
           validate_document(
             id,
             "media/upload_contract_request_additional_document.pdf",
             content["additional_document_md5"],
             headers
           ),
         :ok <- move_uploaded_documents(id, headers),
         _ <- terminate_pending_contracts(type, content),
         insert_params <-
           Map.merge(content, %{
             "status" => CapitationContractRequest.status(:new),
             "inserted_by" => user_id,
             "updated_by" => user_id
           }),
         %Changeset{valid?: true} = changes <- changeset(%{contract_request | id: id}, insert_params),
         {:ok, contract_request} <- Repo.insert(changes) do
      {:ok, contract_request, preload_references(contract_request)}
    else
      {:contract_request_exists, false} -> {:error, {:conflict, "Invalid contract_request id"}}
      error -> error
    end
  end

  def update(headers, %{"id" => _} = params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    pack = RequestPack.new(params)

    with :ok <- validate_update_params(pack),
         {:ok, %{"data" => data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(data, "NHS ADMIN SIGNER"),
         {:ok, contract_request} <- fetch_by_id(pack),
         pack <- RequestPack.put_contract_request(pack, contract_request),
         :ok <- validate_nhs_signer_id(pack.request_params, client_id),
         :ok <- validate_status(contract_request, CapitationContractRequest.status(:in_process)),
         :ok <- validate_start_date(contract_request),
         update_params <-
           Map.merge(pack.request_params, %{
             "nhs_legal_entity_id" => client_id,
             "updated_by" => user_id
           }),
         %Changeset{valid?: true} = changes <- update_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def update_assignee(headers, %{"id" => contract_request_id} = params) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    employee_id = params["employee_id"]

    with :ok <- JsonSchema.validate(:contract_request_assign, Map.take(params, ~w(employee_id))),
         {:ok, %{"data" => user_data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(user_data, "NHS ADMIN SIGNER"),
         %CapitationContractRequest{} = contract_request <- Repo.get(CapitationContractRequest, contract_request_id),
         {:ok, employee} <- validate_employee(employee_id, client_id),
         :ok <- validate_employee_role(employee, "NHS ADMIN SIGNER"),
         :ok <-
           validate_status(contract_request, [
             CapitationContractRequest.status(:new),
             CapitationContractRequest.status(:in_process)
           ]),
         update_params <- %{
           "status" => CapitationContractRequest.status(:in_process),
           "updated_at" => NaiveDateTime.utc_now(),
           "updated_by" => user_id,
           "assignee_id" => employee_id
         },
         %Changeset{valid?: true} = changes <- update_assignee_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def approve(%{"id" => id, "type" => type} = params, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    params = Map.drop(params, ~w(id type))
    request_pack = RequestPack.new(%{"id" => id, "type" => type})

    with :ok <- JsonSchema.validate(:contract_request_sign, params),
         {:ok, %{"content" => content, "signers" => [signer]}} <- decode_signed_content(params, headers),
         :ok <- SignatureValidator.check_drfo(signer, user_id, "contract_request_approve"),
         :ok <- JsonSchema.validate(:contract_request_approve, content),
         :ok <- validate_contract_request_id(id, content["id"]),
         {:ok, legal_entity} <- LegalEntities.fetch_by_id(client_id),
         {:ok, contract_request} <- fetch_by_id(request_pack),
         references <- preload_references(contract_request),
         :ok <- validate_legal_entity_edrpou(legal_entity, signer),
         :ok <- validate_user_signer_last_name(user_id, signer),
         {:ok, %{"data" => data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(data, "NHS ADMIN SIGNER"),
         :ok <- validate_contractor_legal_entity(contract_request.contractor_legal_entity_id),
         :ok <- validate_approve_content(content, contract_request, references),
         :ok <- validate_status(contract_request, @in_process),
         :ok <- save_signed_content(contract_request.id, params, headers, "signed_content/contract_request_approved"),
         :ok <- validate_contract_id(contract_request),
         :ok <- validate_contractor_owner_id(contract_request),
         :ok <- validate_nhs_signer_id(contract_request, client_id),
         :ok <- validate_employee_divisions(contract_request, contract_request.contractor_legal_entity_id),
         :ok <- validate_contractor_divisions(contract_request),
         :ok <- validate_start_date(contract_request),
         :ok <- validate_medical_program_is_active(contract_request),
         update_params <-
           params
           |> set_contract_number(contract_request)
           |> Map.merge(%{
             "updated_by" => user_id,
             "status" => @approved
           }),
         %Changeset{valid?: true} = changes <- approve_changeset(contract_request, update_params),
         data <- render_contract_request_data(changes),
         %Changeset{valid?: true} = changes <- put_change(changes, :data, data),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def approve_msp(headers, %{"id" => _, "type" => _} = params) do
    client_id = get_client_id(headers)
    user_id = get_consumer_id(headers)
    update_params = %{"updated_by" => user_id, "status" => @pending_nhs_sign}

    with %{__struct__: _} = contract_request <- get_by_id(RequestPack.new(params)),
         {_, true} <- {:client_id, client_id == contract_request.contractor_legal_entity_id},
         :ok <- validate_status(contract_request, @approved),
         :ok <- validate_contractor_legal_entity(contract_request.contractor_legal_entity_id),
         {:contractor_owner, :ok} <- {:contractor_owner, validate_contractor_owner_id(contract_request)},
         :ok <- validate_employee_divisions(contract_request, client_id),
         :ok <- validate_contractor_divisions(contract_request),
         :ok <- validate_start_date(contract_request),
         :ok <- validate_medical_program_is_active(contract_request),
         %Changeset{valid?: true} = changes <- approve_msp_changeset(contract_request, update_params),
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

  def decline(%{"id" => id, "type" => _} = params, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)
    request_pack = RequestPack.new(params)
    params = Map.drop(params, ~w(id type))

    with :ok <- JsonSchema.validate(:contract_request_sign, params),
         {:ok, %{"content" => content, "signers" => [signer]}} <- decode_signed_content(params, headers),
         :ok <- SignatureValidator.check_drfo(signer, user_id, "contract_request_decline"),
         :ok <- JsonSchema.validate(:contract_request_decline, content),
         :ok <- validate_contract_request_id(id, content["id"]),
         {:ok, legal_entity} <- LegalEntities.fetch_by_id(client_id),
         {:ok, contract_request} <- fetch_by_id(request_pack),
         references <- preload_references(contract_request),
         :ok <- validate_legal_entity_edrpou(legal_entity, signer),
         :ok <- validate_user_signer_last_name(user_id, signer),
         {:ok, %{"data" => data}} <- @mithril_api.get_user_roles(user_id, %{}, headers),
         :ok <- user_has_role(data, "NHS ADMIN SIGNER"),
         :ok <- validate_contractor_legal_entity(contract_request.contractor_legal_entity_id),
         :ok <- validate_decline_content(content, contract_request, references),
         :ok <- validate_status(contract_request, @in_process),
         :ok <- save_signed_content(contract_request.id, params, headers, "signed_content/contract_request_declined"),
         update_params <-
           %{
             "status_reason" => content["status_reason"],
             "status" => @declined,
             "nhs_signer_id" => user_id,
             "nhs_legal_entity_id" => client_id,
             "updated_by" => user_id
           },
         %Changeset{valid?: true} = changes <- decline_changeset(contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      {:ok, contract_request, preload_references(contract_request)}
    end
  end

  def terminate(headers, client_type, %{"id" => id} = params) do
    client_id = get_client_id(headers)
    user_id = get_consumer_id(headers)

    with {:ok, %CapitationContractRequest{} = contract_request} <- fetch_by_id(id),
         :ok <- validate_contract_request_client_access(client_type, client_id, contract_request),
         {:contractor_owner, :ok} <- {:contractor_owner, validate_contractor_owner_id(contract_request)},
         true <- contract_request.status not in @forbidden_statuses_for_termination,
         update_params <-
           params
           |> Map.put("status", CapitationContractRequest.status(:terminated))
           |> Map.put("updated_by", user_id),
         %Changeset{valid?: true} = changes <- terminate_changeset(contract_request, update_params),
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
    params = Map.take(params, ~w(signed_content signed_content_encoding))

    with {:ok, legal_entity} <- LegalEntities.fetch_by_id(client_id),
         :ok <- JsonSchema.validate(:contract_request_sign, params),
         {:ok, %{"content" => content, "signers" => [signer], "stamps" => [stamp]}} <-
           decode_signed_content(params, headers, 1, 1),
         :ok <- validate_contract_request_id(id, content["id"]),
         {:ok, contract_request} <- fetch_by_id(id),
         :ok <- validate_client_id(client_id, contract_request.nhs_legal_entity_id, :forbidden),
         :ok <-
           SignatureValidator.check_drfo(
             signer,
             contract_request.nhs_signer_id,
             "$.drfo",
             "contract_request_sign_nhs"
           ),
         {_, false} <- {:already_signed, contract_request.status == CapitationContractRequest.status(:nhs_signed)},
         :ok <- validate_status(contract_request, CapitationContractRequest.status(:pending_nhs_sign)),
         :ok <- validate_legal_entity_edrpou(legal_entity, signer),
         :ok <- validate_legal_entity_edrpou(legal_entity, stamp),
         {:ok, employee} <- validate_employee(contract_request.nhs_signer_id, client_id),
         :ok <- check_last_name_match(employee.party.last_name, signer["surname"]),
         :ok <- validate_contractor_legal_entity(contract_request.contractor_legal_entity_id),
         :ok <- validate_contractor_owner_id(contract_request),
         {:ok, printout_content} <-
           ContractRequestPrintoutForm.render(
             %{contract_request | nhs_signed_date: Date.utc_today()},
             headers
           ),
         :ok <- validate_content(contract_request, printout_content, content),
         :ok <- validate_contract_id(contract_request),
         :ok <- validate_employee_divisions(contract_request, contract_request.contractor_legal_entity_id),
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
           |> Map.put("status", CapitationContractRequest.status(:nhs_signed))
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

  def sign_msp(headers, client_type, %{"id" => _, "type" => _} = params) do
    client_id = get_client_id(headers)
    user_id = get_consumer_id(headers)
    pack = RequestPack.new(params)

    with %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(client_id),
         :ok <- validate_contract_request_type(pack.type, legal_entity),
         {:ok, contract_request} <- pack.provider.fetch_by_id(pack.contract_request_id),
         pack <- RequestPack.put_contract_request(pack, contract_request),
         {_, true} <- {:signed_nhs, pack.contract_request.status == CapitationContractRequest.status(:nhs_signed)},
         :ok <- validate_client_id(client_id, pack.contract_request.contractor_legal_entity_id, :forbidden),
         :ok <- JsonSchema.validate(:contract_request_sign, pack.request_params),
         {:ok, %{"content" => content, "signers" => [signer_msp, signer_nhs], "stamps" => [nhs_stamp]}} <-
           decode_signed_content(pack.request_params, headers, 2, 1),
         pack <- RequestPack.put_decoded_content(pack, content),
         :ok <- validate_contract_request_content(:sign, pack, client_id),
         :ok <- validate_contract_request_client_access(client_type, client_id, pack.contract_request),
         :ok <-
           SignatureValidator.check_drfo(
             signer_msp,
             pack.contract_request.contractor_owner_id,
             "$.drfo",
             "contract_request_sign_msp"
           ),
         :ok <- validate_legal_entity_edrpou(legal_entity, signer_msp),
         {:ok, employee} <- validate_employee(pack.contract_request.contractor_owner_id, client_id),
         :ok <- check_last_name_match(employee.party.last_name, signer_msp["surname"]),
         :ok <- validate_nhs_signatures(signer_nhs, nhs_stamp, pack.contract_request),
         :ok <- validate_content(pack.contract_request, pack.decoded_content),
         :ok <- validate_start_date(pack.contract_request),
         :ok <- validate_contractor_legal_entity(pack.contract_request.contractor_legal_entity_id),
         :ok <- validate_contractor_owner_id(pack.contract_request),
         contract_id <- UUID.generate(),
         :ok <-
           save_signed_content(
             contract_id,
             pack.request_params,
             headers,
             "signed_content/signed_content",
             :contract_bucket
           ),
         update_params <-
           Map.merge(pack.request_params, %{
             "updated_by" => user_id,
             "status" => CapitationContractRequest.status(:signed),
             "contract_id" => contract_id
           }),
         %Ecto.Changeset{valid?: true} = changes <- msp_signed_changeset(pack.contract_request, update_params),
         {:ok, contract_request} <- Repo.update(changes),
         pack <- RequestPack.put_contract_request(pack, contract_request),
         {:create_contract, {:ok, contract}} <-
           {:create_contract, Contracts.create_from_contract_request(pack, user_id)},
         _ <- EventManager.insert_change_status(contract_request, contract_request.status, user_id) do
      Contracts.load_contract_references(contract)
    else
      {:signed_nhs, false} ->
        Error.dump("Incorrect status for signing")

      {:create_contract, err} ->
        # ToDo: validation errors showed as 502. Improve transaction error handling
        Logger.error("Failed to save contract with `#{inspect(err)}}`")
        {:error, {:bad_gateway, "Failed to save contract"}}

      error ->
        error
    end
  end

  def get_partially_signed_content_url(headers, %{"id" => id}) do
    client_id = get_client_id(headers)

    with %CapitationContractRequest{} = contract_request <- Repo.get(CapitationContractRequest, id),
         {_, true} <- {:signed_nhs, contract_request.status == CapitationContractRequest.status(:nhs_signed)},
         :ok <- validate_client_id(client_id, contract_request.contractor_legal_entity_id, :forbidden),
         {:ok, url} <- resolve_partially_signed_content_url(contract_request.id, headers) do
      {:ok, url}
    else
      {:signed_nhs, _} ->
        Error.dump("The contract hasn't been signed yet")

      {:error, :media_storage_error} ->
        {:error, {:bad_gateway, "Fail to resolve partially signed content"}}

      error ->
        error
    end
  end

  def get_printout_content(id, client_type, headers) do
    client_id = get_client_id(headers)

    with {:ok, %CapitationContractRequest{} = contract_request} <- fetch_by_id(id),
         :ok <- validate_contract_request_client_access(client_type, client_id, contract_request),
         :ok <-
           validate_status(
             contract_request,
             CapitationContractRequest.status(:pending_nhs_sign),
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

  defp set_contract_number(params, %{parent_contract_id: parent_contract_id}) when not is_nil(parent_contract_id) do
    params
  end

  defp set_contract_number(params, _) do
    with {:ok, sequence} <- get_contract_request_sequence() do
      Map.put(params, "contract_number", NumberGenerator.generate_from_sequence(0, sequence))
    end
  end

  defp set_dates(nil, params), do: params

  defp set_dates(%{start_date: start_date, end_date: end_date}, params) do
    params
    |> Map.put("start_date", to_string(start_date))
    |> Map.put("end_date", to_string(end_date))
  end

  def changeset(%CapitationContractRequest{} = contract_request, params) do
    CapitationContractRequest.changeset(contract_request, params)
  end

  def changeset(%ReimbursementContractRequest{} = contract_request, params) do
    ReimbursementContractRequest.changeset(contract_request, params)
  end

  def update_changeset(%CapitationContractRequest{} = contract_request, params) do
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
    |> validate_number(:nhs_contract_price, greater_than_or_equal_to: 0)
  end

  def update_changeset(%ReimbursementContractRequest{} = contract_request, params) do
    cast(
      contract_request,
      params,
      ~w(
        nhs_legal_entity_id
        nhs_signer_id
        nhs_signer_base
        nhs_payment_method
        issue_city
        misc
      )a
    )
  end

  def approve_changeset(%{__struct__: _} = contract_request, params) do
    fields_required = get_approve_required_fields(contract_request)
    fields_optional = ~w(misc)a

    contract_request
    |> cast(params, fields_required ++ fields_optional)
    |> validate_required(fields_required)
  end

  defp get_approve_required_fields(contract_request) do
    fields = ~w(
        nhs_legal_entity_id
        nhs_signer_id
        nhs_signer_base
        nhs_payment_method
        issue_city
        status
        updated_by
        contract_number
      )a

    case contract_request do
      %CapitationContractRequest{} -> Enum.concat(fields, ~w(nhs_contract_price)a)
      %ReimbursementContractRequest{} -> Enum.concat(fields, ~w(medical_program_id)a)
    end
  end

  defp update_assignee_changeset(%CapitationContractRequest{} = contract_request, params) do
    fields_required = ~w(
      status
      assignee_id
      updated_at
      updated_by
    )a

    contract_request
    |> cast(params, fields_required)
    |> validate_required(fields_required)
  end

  def approve_msp_changeset(%{__struct__: _} = contract_request, params) do
    fields = ~w(
      status
      updated_by
    )a

    contract_request
    |> cast(params, fields)
    |> validate_required(fields)
  end

  def terminate_changeset(%{} = contract_request, params) do
    fields_required = ~w(status updated_by)a
    fields_optional = ~w(status_reason)a

    contract_request
    |> cast(params, fields_required ++ fields_optional)
    |> validate_required(fields_required)
  end

  def nhs_signed_changeset(%{} = contract_request, params) do
    fields = ~w(status updated_by printout_content nhs_signed_date)a

    contract_request
    |> cast(params, fields)
    |> validate_required(fields)
  end

  def msp_signed_changeset(%{} = contract_request, params) do
    fields = ~w(status updated_by contract_id)a

    contract_request
    |> cast(params, fields)
    |> validate_required(fields)
  end

  def preload_references(%CapitationContractRequest{} = contract_request) do
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

  def preload_references(%ReimbursementContractRequest{} = contract_request) do
    fields = [
      {:contractor_legal_entity_id, :legal_entity},
      {:nhs_legal_entity_id, :legal_entity},
      {:contractor_owner_id, :employee},
      {:nhs_signer_id, :employee},
      {:contractor_divisions, :division}
    ]

    Preload.preload_references(contract_request, fields)
  end

  def insert_events(multi, status, author_id) do
    {_, contract_requests} = multi.contract_requests

    Enum.each(contract_requests, fn contract_request ->
      EventManager.insert_change_status(contract_request, status, author_id)
    end)

    {:ok, contract_requests}
  end

  defp render_contract_request_data(%Changeset{} = changeset) do
    structure = Changeset.apply_changes(changeset)
    Renderer.render(structure, preload_references(structure))
  end

  defp terminate_pending_contracts(type, params) do
    # TODO: add index here

    schema =
      case type do
        @capitation -> CapitationContractRequest
        @reimbursement -> ReimbursementContractRequest
      end

    contract_ids =
      schema
      |> select([c], c.id)
      |> where([c], c.contractor_legal_entity_id == ^params["contractor_legal_entity_id"])
      |> where([c], c.id_form == ^params["id_form"])
      |> where_medical_program(type, params)
      |> where(
        [c],
        c.status in ^[
          CapitationContractRequest.status(:new),
          CapitationContractRequest.status(:in_process),
          CapitationContractRequest.status(:approved),
          CapitationContractRequest.status(:nhs_signed),
          CapitationContractRequest.status(:pending_nhs_sign)
        ]
      )
      |> where([c], c.end_date >= ^params["start_date"] and c.start_date <= ^params["end_date"])
      |> Repo.all()

    CapitationContractRequest
    |> where([c], c.id in ^contract_ids)
    |> Repo.update_all(set: [status: CapitationContractRequest.status(:terminated)])
  end

  defp where_medical_program(query, @reimbursement, %{"medical_program_id" => medical_program_id}) do
    where(query, [c], c.medical_program_id == ^medical_program_id)
  end

  defp where_medical_program(query, _, _), do: query

  def user_has_role(data, role, reason \\ "FORBIDDEN") do
    case Enum.find(data, &(Map.get(&1, "role_name") == role)) do
      nil -> {:error, {:forbidden, reason}}
      _ -> :ok
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

  defp decline_changeset(%{__struct__: _} = contract_request, params) do
    fields_required = ~w(status nhs_signer_id nhs_legal_entity_id updated_by)a
    fields_optional = ~w(status_reason)a

    contract_request
    |> cast(params, fields_required ++ fields_optional)
    |> validate_required(fields_required)
  end
end

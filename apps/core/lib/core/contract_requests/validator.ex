defmodule Core.ContractRequests.Validator do
  @moduledoc false

  import Core.API.Helpers.Connection, only: [get_header: 2, get_client_id: 1]
  import Core.Users.Validator, only: [user_has_role: 2]
  import Ecto.Query, only: [where: 3]

  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.ContractRequests.RequestPack
  alias Core.Contracts
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias Core.Divisions.Division
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.Validator, as: LegalEntitiesValidator
  alias Core.MedicalPrograms
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Parties
  alias Core.Parties.Party
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Core.Validators.Reference
  alias Scrivener.Page

  @capitation CapitationContractRequest.type()
  @reimbursement ReimbursementContractRequest.type()

  @msp LegalEntity.type(:msp)
  @nhs LegalEntity.type(:nhs)
  @pharmacy LegalEntity.type(:pharmacy)
  @msp_pharmacy LegalEntity.type(:msp_pharmacy)

  @status_active LegalEntity.status(:active)

  @allowed_types [@capitation, @reimbursement]

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]
  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]

  @read_repo Application.get_env(:core, :repos)[:read_repo]
  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @upload_docs %{
    "statute_md5" => "media/upload_contract_request_statute.pdf",
    "additional_document_md5" => "media/upload_contract_request_additional_document.pdf"
  }

  @admin Employee.type(:admin)
  @owner Employee.type(:owner)
  @pharmacy_owner Employee.type(:pharmacy_owner)

  @drugstore Division.type(:drugstore)
  @drugstore_point Division.type(:drugstore_point)

  # Contract Request

  def validate_contract_request_id(id, id), do: :ok

  def validate_contract_request_id(_, _),
    do: {:error, {:bad_request, "Contract request id doesn't match with id in signed content"}}

  def validate_contract_request_type(@capitation, %{type: @msp}), do: :ok
  def validate_contract_request_type(@reimbursement, %{type: @pharmacy}), do: :ok
  def validate_contract_request_type(type, %{type: @msp_pharmacy}) when type in @allowed_types, do: :ok

  def validate_contract_request_type(type, %{type: legal_entity_type}) when type in @allowed_types do
    reason = "Contract type \"#{type}\" is not allowed for legal_entity with type \"#{legal_entity_type}\""

    {:error, {:conflict, reason}}
  end

  def validate_status(contract_request, status),
    do:
      validate_status(
        contract_request,
        status,
        "Incorrect status of contract_request to modify it"
      )

  def validate_status(%{status: status}, required_status, message) do
    cond do
      status == required_status -> :ok
      is_list(required_status) and status in required_status -> :ok
      true -> {:error, {:conflict, message}}
    end
  end

  def validate_previous_request(
        %RequestPack{decoded_content: %{"previous_request_id" => previous_id}} = pack,
        contractor_legal_entity_id
      )
      when not is_nil(previous_id) do
    schema = RequestPack.get_schema_by_type(pack.type)

    with {_, %{__struct__: _} = contract_request} <- {:request, @read_repo.get(schema, previous_id)},
         {_, true} <-
           {:contractor_legal_entity_id, contract_request.contractor_legal_entity_id == contractor_legal_entity_id},
         {_, true} <- {:status, contract_request.status != CapitationContractRequest.status(:signed)} do
      :ok
    else
      {:contractor_legal_entity_id, _} -> {:error, {:"422", "Previous request doesn't belong to legal entity"}}
      {:request, _} -> {:error, {:"422", "previous_request_id does not exist"}}
      {:status, _} -> {:error, {:"422", "In case contract exists new contract request should be created"}}
    end
  end

  def validate_previous_request(_, _), do: :ok

  # Legal Entity

  def validate_contract_request_client_access(@nhs, _client_id, _contract_request), do: :ok

  def validate_contract_request_client_access(@msp, id, %{type: @capitation, contractor_legal_entity_id: id}), do: :ok

  def validate_contract_request_client_access(@pharmacy, id, %{type: @reimbursement, contractor_legal_entity_id: id}) do
    :ok
  end

  def validate_contract_request_client_access(@msp_pharmacy, id, %{contractor_legal_entity_id: id}) do
    :ok
  end

  def validate_contract_request_client_access(_, _, _) do
    {:error, {:forbidden, "User is not allowed to perform this action"}}
  end

  def validate_client_id(client_id, client_id, _), do: :ok
  def validate_client_id(_, _, :forbidden), do: {:error, {:forbidden, "Invalid client_id"}}

  def validate_legal_entity_edrpou(_legal_entity, nil), do: :ok

  def validate_legal_entity_edrpou(legal_entity, signer) do
    case LegalEntitiesValidator.validate_state_registry_number(legal_entity, signer) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp validate_external_legal_entity(errors, %{"legal_entity_id" => legal_entity_id}, index)
       when not is_nil(legal_entity_id) do
    validation_result =
      Reference.validate(
        :legal_entity,
        legal_entity_id,
        "$.external_contractors.[#{index}].legal_entity_id"
      )

    case validation_result do
      {:error, _} ->
        errors ++
          [
            %ValidationError{
              description: "Active $external_contractors.[#{index}].legal_entity_id does not exist",
              path: "$.external_contractors.[#{index}].legal_entity_id"
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
          description: "Active $external_contractors.[#{index}].legal_entity_id does not exist",
          path: "$.external_contractors.[#{index}].legal_entity_id"
        }
      ]
  end

  # Division

  defp check_division(type, %Division{status: "ACTIVE", legal_entity_id: id} = division, id, error) do
    atom_type = type |> String.downcase() |> String.to_atom()

    case division.type in Confex.fetch_env!(:core, :contracts_division_types)[atom_type] do
      true ->
        :ok

      _ ->
        Error.dump(%ValidationError{
          description: "Invalid division type `#{division.type}` for #{type} contract",
          path: error
        })
    end
  end

  defp check_division(_, _, _, error) do
    Error.dump(%ValidationError{description: "Division must be active and within current legal_entity", path: error})
  end

  defp validate_divisions(errors, params, contractor, i) do
    contractor["divisions"]
    |> Enum.with_index()
    |> Enum.reduce(errors, fn {contractor_division, j}, errors ->
      with :ok <-
             validate_external_contractor_division(
               params["contractor_divisions"],
               contractor_division,
               "$.external_contractors.[#{i}].divisions.[#{j}].id"
             ) do
        errors
      else
        {:error, error} when is_list(error) -> errors ++ error
        {:error, error} -> errors ++ [error]
      end
    end)
  end

  # Contract

  def validate_contract_id(%RequestPack{contract_request: %{parent_contract_id: contract_id}} = pack)
      when not is_nil(contract_id) do
    with %{__struct__: _} = contract <- Contracts.get_by_id(contract_id, pack.type),
         true <- contract.status == CapitationContract.status(:verified) do
      :ok
    else
      _ -> {:error, {:conflict, "Parent contract can’t be updated"}}
    end
  end

  def validate_contract_id(_), do: :ok

  def validate_contract_number(type, %{"contract_number" => contract_number} = params, _headers)
      when not is_nil(contract_number) do
    search_params = [
      contract_number: contract_number,
      status: CapitationContract.status(:verified)
    ]

    contract_schema =
      case type do
        @capitation -> CapitationContract
        @reimbursement -> ReimbursementContract
      end

    with %{__struct__: _} = contract <- @read_prm_repo.get_by(contract_schema, search_params),
         :ok <- validate_parent_contract_type(contract, type),
         :ok <- validate_parent_contract_medical_program_id(type, contract, params) do
      {:ok, Map.put(params, "parent_contract_id", contract.id), contract}
    else
      nil -> Error.dump("Verified contract with such contract number does not exist")
      err -> err
    end
  end

  def validate_contract_number(type, %{"contractor_legal_entity_id" => legal_entity_id} = params, headers) do
    client_id = get_client_id(headers)

    search_params =
      %{
        "type" => type,
        "contractor_legal_entity_id" => legal_entity_id,
        "status" => CapitationContract.status(:verified),
        "date_to_start_date" => params["end_date"],
        "date_from_end_date" => params["start_date"]
      }
      |> put_medical_program_id(type, params)

    with {:ok, %Page{entries: [_ | _]}, _} <- Contracts.list(search_params, nil, client_id) do
      Error.dump("Active contract is found. Contract number must be sent in request")
    else
      _ -> {:ok, params, nil}
    end
  end

  defp validate_parent_contract_type(%{type: type}, type), do: :ok

  defp validate_parent_contract_type(_contract, _),
    do: {:error, {:conflict, "Submitted contract type does not correspond to previously created content"}}

  defp validate_parent_contract_medical_program_id(@reimbursement, %{medical_program_id: id}, %{
         "medical_program_id" => id
       }),
       do: :ok

  defp validate_parent_contract_medical_program_id(@reimbursement, _, _),
    do: {:error, {:conflict, "Submitted medical_program_id does not correspond to previously created content"}}

  defp validate_parent_contract_medical_program_id(_, _, _), do: :ok

  defp put_medical_program_id(search_params, @reimbursement, %{"medical_program_id" => id}) do
    Map.put(search_params, "medical_program_id", id)
  end

  defp put_medical_program_id(search_params, _, _), do: search_params

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

  # Contractor

  def validate_contractor_legal_entity_id(_, nil), do: :ok

  def validate_contractor_legal_entity_id(id, %{contractor_legal_entity_id: id}), do: :ok

  def validate_contractor_legal_entity_id(_, _),
    do: {:error, {:forbidden, "You are not allowed to change this contract"}}

  def validate_contractor_legal_entity_status(%{status: @status_active, is_active: true}), do: :ok

  def validate_contractor_legal_entity_status(_) do
    Error.dump(%ValidationError{
      description: "Legal entity is not active",
      path: "$.contractor_legal_entity_id"
    })
  end

  def validate_contractor_legal_entity_nhs_verification(%{nhs_verified: true}), do: :ok

  def validate_contractor_legal_entity_nhs_verification(_) do
    Error.dump(%ValidationError{
      description: "Legal entity is not verified by NHS",
      path: "$.contractor_legal_entity_id"
    })
  end

  def validate_contractor_owner_id(%{
        type: type,
        contractor_owner_id: contractor_owner_id,
        contractor_legal_entity_id: contractor_legal_entity_id
      }) do
    validate_contractor_owner_id(type, %{
      "contractor_owner_id" => contractor_owner_id,
      "contractor_legal_entity_id" => contractor_legal_entity_id
    })
  end

  def validate_contractor_owner_id_on_create(type, %{
        "contractor_owner_id" => contractor_owner_id,
        "contractor_legal_entity_id" => contractor_legal_entity_id
      }) do
    with %Employee{} = employee <- Employees.get_by_id(contractor_owner_id),
         true <- employee.status == Employee.status(:approved),
         true <- employee.is_active,
         true <- employee.legal_entity_id == contractor_legal_entity_id,
         true <- employee.employee_type in allowed_contractor_owner_employee_type(type) do
      :ok
    else
      _ ->
        Error.dump(%ValidationError{
          description: "Contractor owner must be active within current legal entity in contract request",
          path: "$.contractor_owner_id"
        })
    end
  end

  def validate_contractor_owner_id(type, %{
        "contractor_owner_id" => contractor_owner_id,
        "contractor_legal_entity_id" => contractor_legal_entity_id
      }) do
    with %Employee{} = employee <- Employees.get_by_id(contractor_owner_id),
         true <- employee.legal_entity_id == contractor_legal_entity_id,
         true <- employee.employee_type in allowed_contractor_owner_employee_type(type),
         true <-
           Employees.has_contract_owner_employees(
             employee.party_id,
             contractor_legal_entity_id,
             allowed_contractor_owner_employee_type(type)
           ) do
      :ok
    else
      _ ->
        Error.dump(%ValidationError{
          description: "Contractor owner must be active within current legal entity in contract request",
          path: "$.contractor_owner_id"
        })
    end
  end

  def allowed_contractor_owner_employee_type(@capitation), do: [@owner, @admin]

  def allowed_contractor_owner_employee_type(@reimbursement), do: [@pharmacy_owner, @owner, @admin]

  defp validate_unique_contractor_employee_divisions(%{
         "contractor_employee_divisions" => employee_divisions
       })
       when is_list(employee_divisions) do
    employee_divisions_values =
      Enum.map(employee_divisions, fn %{"employee_id" => employee_id, "division_id" => division_id} ->
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

  def validate_unique_contractor_divisions(%{"contractor_divisions" => contractor_divisions}) do
    if Enum.uniq(contractor_divisions) == contractor_divisions do
      :ok
    else
      Error.dump(%ValidationError{description: "Division must be unique", path: "$.contractor_divisions"})
    end
  end

  def validate_contractor_divisions(type, %{
        contractor_divisions: contractor_divisions,
        contractor_legal_entity_id: contractor_legal_entity_id
      }) do
    validate_contractor_divisions(type, %{
      "contractor_divisions" => contractor_divisions,
      "contractor_legal_entity_id" => contractor_legal_entity_id
    })
  end

  def validate_contractor_divisions(type, %{
        "contractor_divisions" => contractor_divisions,
        "contractor_legal_entity_id" => contractor_legal_entity_id
      }) do
    errors =
      contractor_divisions
      |> Enum.with_index()
      |> Enum.reduce([], fn {division_id, i}, acc ->
        result =
          with {:ok, division} <- Reference.validate(:division, division_id, "$.contractor_divisions.[#{i}]") do
            check_division(type, division, contractor_legal_entity_id, "$.contractor_divisions.[#{i}]")
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

  defp validate_external_contractors(params) do
    external_contractors = params["external_contractors"] || []

    errors =
      external_contractors
      |> Enum.with_index()
      |> Enum.reduce([], fn {contractor, i}, errors_list ->
        errors_list
        |> validate_external_legal_entity(contractor, i)
        |> validate_divisions(params, contractor, i)
        |> validate_external_contract(contractor, params, "$.external_contractors.[#{i}].contract.expires_at")
      end)

    if length(errors) > 0 do
      errors
      |> validate_and_convert_errors
      |> Error.dump()
    else
      :ok
    end
  end

  def validate_external_contractor_division(division_ids, division, error) do
    if division["id"] in division_ids do
      :ok
    else
      Error.dump(%ValidationError{description: "The division is not belong to contractor_divisions", path: error})
    end
  end

  def validate_contractor_divisions_dls(contract_type, contractor_divisions) do
    dls_verify? = Confex.fetch_env!(:core, :dispense_division_dls_verify)

    do_validate_contractor_divisions_dls(dls_verify?, contract_type, contractor_divisions)
  end

  defp do_validate_contractor_divisions_dls(true, @capitation, _), do: :ok

  defp do_validate_contractor_divisions_dls(true, @reimbursement, contractor_divisions) do
    Division
    |> where([d], d.dls_verified == false or is_nil(d.dls_verified))
    |> where([d], d.id in ^contractor_divisions)
    |> where([d], d.type in [@drugstore, @drugstore_point])
    |> @read_prm_repo.aggregate(:count, :id)
    |> case do
      0 -> :ok
      _ -> {:error, {:conflict, "All contractor divisions must be dls verified"}}
    end
  end

  defp do_validate_contractor_divisions_dls(false, _, _), do: :ok

  # Signer

  def validate_user_signer_last_name(user_id, %{"surname" => surname}) do
    with %Party{last_name: last_name} <- Parties.get_by_user_id(user_id) do
      check_last_name_match(last_name, surname)
    end
  end

  def check_last_name_match(_last_name, nil) do
    Error.dump(%ValidationError{
      description: "Signer surname is not exist in sign info",
      path: "$.surname"
    })
  end

  def check_last_name_match(last_name, surname) do
    if String.upcase(last_name) == String.upcase(surname) do
      :ok
    else
      Error.dump(%ValidationError{
        description: "Signer surname does not match with current user last_name",
        path: "$.last_name"
      })
    end
  end

  def validate_nhs_signer_id(%{nhs_signer_id: nhs_signer_id}, client_id)
      when not is_nil(nhs_signer_id) do
    validate_nhs_signer_id(%{"nhs_signer_id" => nhs_signer_id}, client_id)
  end

  def validate_nhs_signer_id(%{"nhs_signer_id" => nhs_signer_id}, client_id)
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

  def validate_nhs_signer_id(_, _), do: :ok

  # Signature

  def validate_nhs_signatures(signer_nhs, nhs_stamp, %{
        nhs_legal_entity_id: nhs_legal_entity_id,
        nhs_signer_id: nhs_signer_id
      }) do
    with {:nhs_legal_entity, %LegalEntity{} = nhs_legal_entity} <-
           {:nhs_legal_entity, LegalEntities.get_by_id(nhs_legal_entity_id)},
         {:nhs_employee, %Employee{} = nhs_employee} <- {:nhs_employee, Employees.get_by_id(nhs_signer_id)},
         :ok <- validate_legal_entity_edrpou(nhs_legal_entity, nhs_stamp),
         :ok <- validate_legal_entity_edrpou(nhs_legal_entity, signer_nhs),
         :ok <- check_last_name_match(nhs_employee.party.last_name, signer_nhs["surname"]) do
      :ok
    else
      {:nhs_legal_entity, _} ->
        {:error, {:conflict, "NHS legal entity not found"}}

      {:nhs_employee, _} ->
        {:error, {:conflict, "NHS employee not found"}}

      error ->
        error
    end
  end

  # content

  def validate_create_from_draft_content_schema(%RequestPack{type: @capitation, decoded_content: content}) do
    JsonSchema.validate(:capitation_contract_request_create_from_draft, content)
  end

  def validate_create_from_draft_content_schema(%RequestPack{type: @reimbursement, decoded_content: content}) do
    JsonSchema.validate(:reimbursement_contract_request_create_from_draft, content)
  end

  def validate_create_from_contract_content_schema(%RequestPack{type: @capitation, decoded_content: content}) do
    JsonSchema.validate(:capitation_contract_request_create_from_contract, content)
  end

  def validate_create_from_contract_content_schema(%RequestPack{type: @reimbursement, decoded_content: content}) do
    JsonSchema.validate(:reimbursement_contract_request_create_from_contract, content)
  end

  def validate_update_params(%RequestPack{type: @capitation} = pack) do
    JsonSchema.validate(:capitation_contract_request_update, pack.request_params)
  end

  def validate_update_params(%RequestPack{type: @reimbursement} = pack) do
    JsonSchema.validate(:reimbursement_contract_request_update, pack.request_params)
  end

  def validate_contract_request_content(
        :create,
        %RequestPack{type: @capitation, decoded_content: content},
        contractor_legal_entity_id
      ) do
    with :ok <- validate_unique_contractor_employee_divisions(content),
         :ok <- validate_employee_divisions(content, contractor_legal_entity_id),
         :ok <- validate_external_contractors(content),
         :ok <- validate_external_contractor_flag(content) do
      :ok
    end
  end

  def validate_contract_request_content(
        :create,
        %RequestPack{type: @reimbursement, decoded_content: content},
        _client_id
      ) do
    with medical_program <- MedicalPrograms.get_by_id(content["medical_program_id"]),
         :ok <- validate_medical_program(medical_program) do
      :ok
    end
  end

  def validate_contract_request_content(:sign, %RequestPack{type: @capitation} = pack, client_id) do
    with :ok <- validate_employee_divisions(pack.contract_request, client_id) do
      :ok
    end
  end

  def validate_contract_request_content(:sign, %RequestPack{type: @reimbursement} = pack, _client_id) do
    medical_program_id = pack.decoded_content["medical_program_id"] || pack.contract_request.medical_program_id

    with {:ok, medical_program} <- MedicalPrograms.fetch_by_id(medical_program_id),
         :ok <- validate_medical_program(medical_program) do
      :ok
    end
  end

  def validate_decline_content(content, contract_request, references) do
    contractor_legal_entity =
      references
      |> Map.get(:legal_entity)
      |> Map.get(contract_request.contractor_legal_entity_id)

    data =
      %{
        "id" => contract_request.id,
        "contractor_legal_entity" => Map.take(contractor_legal_entity, ~w(id name edrpou)a)
      }
      |> Jason.encode!()
      |> Jason.decode!()

    if data == Map.drop(content, ~w(next_status status_reason text)) do
      :ok
    else
      {:error, {:bad_request, "Signed content doesn't match with contract request"}}
    end
  end

  def validate_approve_content(content, contract_request, references) do
    contractor_legal_entity =
      references
      |> Map.get(:legal_entity)
      |> Map.get(contract_request.contractor_legal_entity_id)

    data =
      %{
        "id" => contract_request.id,
        "contractor_legal_entity" => Map.take(contractor_legal_entity, ~w(id name edrpou)a)
      }
      |> Jason.encode!()
      |> Jason.decode!()

    if data == Map.drop(content, ~w(next_status text)) do
      :ok
    else
      {:error, {:bad_request, "Signed content doesn't match with contract request"}}
    end
  end

  def validate_documents(%RequestPack{} = pack) do
    Enum.reduce_while(@upload_docs, :ok, fn {key, resource_name}, _ ->
      case validate_document(pack.type, pack.contract_request_id, resource_name, pack.decoded_content[key]) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_document(@reimbursement, _id, _resource, md5) when is_nil(md5), do: :ok
  defp validate_document(_type, id, resource, md5), do: validate_document(id, resource, md5)

  defp validate_document(id, resource_name, md5) do
    with {:ok, %{secret_url: url}} <-
           @media_storage_api.create_signed_url("HEAD", get_bucket(), resource_name, id),
         {:ok, %HTTPoison.Response{status_code: 200, headers: resource_headers}} <-
           @media_storage_api.verify_uploaded_file(url, resource_name),
         true <- md5 == resource_headers |> get_header("ETag") |> Jason.decode!() do
      :ok
    else
      _ -> Error.dump("#{resource_name} md5 doesn't match")
    end
  end

  def validate_content(%{printout_content: printout_content} = contract_request, content) do
    validate_content(contract_request, printout_content, content)
  end

  def validate_content(%{data: data}, printout_content, content) do
    data_content =
      data
      |> Map.delete("status")
      |> Map.put("printout_content", printout_content)

    content = Map.drop(content, ["status"])

    if data_content == content,
      do: :ok,
      else: Error.dump("Signed content does not match the previously created content")
  end

  # dates

  # Validate start date > now() + validate year
  def validate_start_date(%{__struct__: _} = contract_request) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_start_date()
  end

  def validate_start_date(%{"parent_contract_id" => parent_contract_id}) when not is_nil(parent_contract_id) do
    :ok
  end

  def validate_start_date(%{"start_date" => start_date}) do
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

  # Validate start date year without start_date > now()
  def validate_start_date_year(%{__struct__: _} = contract_request) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_start_date_year()
  end

  def validate_start_date_year(%{"parent_contract_id" => parent_contract_id}) when not is_nil(parent_contract_id) do
    :ok
  end

  def validate_start_date_year(%{"start_date" => start_date}) do
    now = Date.utc_today()
    start_date = Date.from_iso8601!(start_date)
    year_diff = start_date.year - now.year

    with {:diff, true} <- {:diff, year_diff >= 0 && year_diff <= 1} do
      :ok
    else
      {:diff, false} ->
        Error.dump(%ValidationError{description: "Start date must be within this or next year", path: "$.start_date"})
    end
  end

  def validate_end_date(%{__struct__: _} = contract_request) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_end_date()
  end

  def validate_end_date(%{"parent_contract_id" => parent_contract_id})
      when not is_nil(parent_contract_id) do
    :ok
  end

  def validate_end_date(%{"start_date" => start_date, "end_date" => end_date}) do
    with {:ok, start_date} <- parse_date(start_date, "start_date"),
         {:ok, end_date} <- parse_date(end_date, "end_date") do
      days_in_year = if Date.leap_year?(start_date) or Date.leap_year?(end_date), do: 366, else: 365

      cond do
        Date.diff(end_date, start_date) > days_in_year ->
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
  end

  defp parse_date(date, type) do
    case Date.from_iso8601(date) do
      {:ok, _} = parsed_date ->
        parsed_date

      _ ->
        Error.dump(%ValidationError{
          description: "Invalid date format",
          path: "$.#{type}"
        })
    end
  end

  def validate_dates(%{"parent_contract_id" => parent_contract_id, "start_date" => start_date})
      when not is_nil(parent_contract_id) and not is_nil(start_date) do
    Error.dump(%ValidationError{description: "Start date can't be updated via Contract Request", path: "$.start_date"})
  end

  def validate_dates(%{"parent_contract_id" => parent_contract_id, "end_date" => end_date})
      when not is_nil(parent_contract_id) and not is_nil(end_date) do
    Error.dump(%ValidationError{description: "End date can't be updated via Contract Request", path: "$.end_date"})
  end

  def validate_dates(%{"parent_contract_id" => parent_contract_id})
      when not is_nil(parent_contract_id),
      do: :ok

  def validate_dates(params) do
    cond do
      is_nil(params["start_date"]) ->
        Error.dump(%ValidationError{description: "Start date can't be empty", path: "$.start_date"})

      is_nil(params["end_date"]) ->
        Error.dump(%ValidationError{description: "End date can't be empty", path: "$.end_date"})

      true ->
        :ok
    end
  end

  # Employee

  def validate_employee(employee_id, client_id) do
    with %Employee{} = employee <- Employees.get_by_id(employee_id),
         {:client_id, true} <- {:client_id, employee.legal_entity_id == client_id},
         {:active, true} <- {:active, employee.is_active and employee.status == Employee.status(:approved)} do
      {:ok, employee}
    else
      {:active, _} -> {:error, {:conflict, "Invalid employee status"}}
      {:client_id, _} -> {:error, {:"422", "Invalid legal entity id"}}
      nil -> {:error, {:not_found, "Employee not found"}}
    end
  end

  def validate_msp_employee(employee_id, client_id) do
    with %Employee{} = employee <- Employees.get_by_id(employee_id),
         {:client_id, true} <- {:client_id, employee.legal_entity_id == client_id} do
      {:ok, employee}
    else
      {:client_id, _} -> {:error, {:"422", "Invalid legal entity id"}}
      nil -> {:error, {:not_found, "Employee not found"}}
    end
  end

  def validate_employee_role(%Employee{} = employee, role) do
    user_ids =
      employee
      |> @read_prm_repo.preload(:party_users)
      |> Map.get(:party_users)
      |> Enum.map(& &1.user_id)
      |> Enum.join(",")

    with true <- user_ids != "",
         {:ok, %{"data" => user_data}} <- @mithril_api.search_user_roles(%{user_ids: user_ids}, []),
         :ok <- user_has_role(user_data, role) do
      :ok
    else
      _ ->
        {:error, {:forbidden, "Employee doesn't have required role"}}
    end
  end

  defp check_employee(employee, legal_entity_id, index) do
    errors =
      []
      |> check_employee_type_and_status(employee, index)
      |> check_employee_legal_entity(employee, legal_entity_id, index)

    if length(errors) > 0, do: {:error, errors}, else: :ok
  end

  defp check_employee_type_and_status(errors, %Employee{employee_type: "DOCTOR", status: "APPROVED"}, _), do: errors

  defp check_employee_type_and_status(errors, _, index) do
    errors ++
      [
        %ValidationError{
          description: "Employee must be active DOCTOR",
          path: "$.contractor_employee_divisions.[#{index}].employee_id"
        }
      ]
  end

  defp check_employee_legal_entity(errors, %Employee{legal_entity_id: legal_entity_id}, legal_entity_id, _), do: errors

  defp check_employee_legal_entity(errors, _, _, index) do
    errors ++
      [
        %ValidationError{
          description: "Employee should be active Doctor within current legal_entity_id",
          path: "$.contractor_employee_divisions.[#{index}].employee_id"
        }
      ]
  end

  defp validate_employee_division_employee(errors, division, legal_entity_id, index) do
    with {:ok, %Employee{} = employee} <-
           Reference.validate(
             :employee,
             division["employee_id"],
             "$.contractor_employee_divisions.[#{index}].employee_id"
           ),
         :ok <- check_employee(employee, legal_entity_id, index) do
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
            path: "$.contractor_employee_divisions.[#{index}].division_id"
          }
        ]
    end
  end

  def validate_employee_divisions(%ReimbursementContractRequest{}, _), do: :ok

  def validate_employee_divisions(%CapitationContractRequest{} = contract_request, contractor_legal_entity_id) do
    contract_request
    |> Jason.encode!()
    |> Jason.decode!()
    |> validate_employee_divisions(contractor_legal_entity_id)
  end

  def validate_employee_divisions(params, contractor_legal_entity_id) do
    contractor_divisions = params["contractor_divisions"]
    contractor_employee_divisions = params["contractor_employee_divisions"] || []

    errors =
      contractor_employee_divisions
      |> Enum.with_index()
      |> Enum.reduce([], fn {employee_division, i}, errors_list ->
        errors_list
        |> validate_employee_division_employee(employee_division, contractor_legal_entity_id, i)
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

  # medical program

  def validate_medical_program_is_active(%CapitationContractRequest{} = _contract_request), do: :ok

  def validate_medical_program_is_active(%ReimbursementContractRequest{medical_program_id: medical_program_id}) do
    medical_program_id
    |> MedicalPrograms.get_by_id()
    |> validate_medical_program()
  end

  defp validate_medical_program(%MedicalProgram{is_active: true}), do: :ok

  defp validate_medical_program(%MedicalProgram{is_active: false}),
    do: {:error, {:conflict, "Reimbursement program is not active"}}

  defp validate_medical_program(nil),
    do:
      Error.dump(%ValidationError{
        description: "Reimbursement program with such id does not exist",
        path: "$.medical_program_id"
      })

  # general

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

  defp get_bucket, do: Confex.fetch_env!(:core, Core.API.MediaStorage)[:contract_request_bucket]
end

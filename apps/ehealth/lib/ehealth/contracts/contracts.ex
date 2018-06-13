defmodule EHealth.Contracts do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_client_id: 1]

  import Ecto.Query
  import Ecto.Changeset
  alias EHealth.Validators.Preload
  alias EHealth.Utils.MapDeepMerge
  alias EHealth.Contracts.Contract
  alias EHealth.Contracts.ContractEmployee
  alias EHealth.Contracts.ContractDivision
  alias EHealth.Contracts.Search
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.PRMRepo
  alias Scrivener.Page

  @status_verified Contract.status(:verified)
  @status_terminated Contract.status(:terminated)

  @fields_required ~w(
    id
    start_date
    end_date
    status
    contractor_legal_entity_id
    contractor_owner_id
    contractor_base
    contractor_payment_details
    contractor_rmsp_amount
    nhs_legal_entity_id
    nhs_signer_id
    nhs_payment_method
    nhs_signer_base
    issue_city
    nhs_contract_price
    contract_number
    contract_request_id
    is_suspended
    is_active
    inserted_by
    updated_by
  )a

  @fields_optional ~w(
    status_reason
    external_contractor_flag
    external_contractors
  )a

  def list(params, client_type, headers) do
    client_id = get_client_id(headers)

    with %Ecto.Changeset{valid?: true, changes: changes} <- Search.changeset(params),
         {:edrpou, {:ok, changes}} <- {:edrpou, validate_edrpou(changes)},
         {:ok, changes} <- validate_client_type(client_id, client_type, changes),
         %Page{entries: contracts} = paging <- search(changes),
         {:ok, references} <- load_contracts_references(contracts) do
      {:ok, paging, references}
    else
      {:edrpou, _} ->
        get_empty_response(params)

      error ->
        error
    end
  end

  def create(%{parent_contract_id: parent_contract_id} = params) when not is_nil(parent_contract_id) do
    with %Contract{status: @status_verified} = contract <- PRMRepo.one(Contract, parent_contract_id) do
      contract = load_references(contract)

      PRMRepo.transaction(fn ->
        ContractEmployee
        |> where([ce], ce.contract_id == ^contract.id)
        |> PRMRepo.update_all(set: [end_date: Date.utc_today(), updated_by: params.updated_by])

        contract
        |> changeset(%{"status" => @status_terminated})
        |> PRMRepo.update()

        contract_employees =
          contract.contract_employees
          |> Poison.encode!()
          |> Poison.decode!()
          |> Enum.map(&Map.drop(&1, ~w(id contract_id inserted_by updated_by)))

        contract_divisions =
          contract.contract_divisions
          |> Poison.encode!()
          |> Poison.decode!()
          |> Enum.map(&Map.get(&1, "division_id"))

        new_contract_params =
          params
          |> Map.put(:contractor_employee_divisions, contract_employees)
          |> Map.put(:contract_divisions, contract_divisions)

        with {:ok, new_contract} <- do_create(new_contract_params) do
          new_contract
        end
      end)
    else
      _ -> {:error, {:conflict, "Incorrect status of parent contract"}}
    end
  end

  def create(params) do
    do_create(params)
  end

  defp do_create(params) do
    with {:ok, contract} <-
           %Contract{}
           |> changeset(params)
           |> PRMRepo.insert() do
      {:ok, load_references(contract)}
    end
  end

  def get_by_id(id) do
    Contract
    |> where([c], c.id == ^id)
    |> join(:left, [c], ce in ContractEmployee, c.id == ce.contract_id)
    |> join(:left, [c], cd in ContractDivision, c.id == cd.contract_id)
    |> preload([c, ce, cd], contract_employees: ce, contract_divisions: cd)
    |> PRMRepo.one()
  end

  def get_by_id(id, params) do
    with %Contract{} = contract <- get_by_id(id),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         {:ok, contract, references} <- load_contract_references(contract) do
      {:ok, contract, references}
    else
      error -> error
    end
  end

  def suspend(params) do
    with %Ecto.Changeset{valid?: true, changes: changes} <- ids_changeset(params) do
      update_is_suspended(String.split(changes.ids, ","), true)
    end
  end

  def update_is_suspended(ids, is_suspended) when is_list(ids) and is_boolean(is_suspended) do
    query = where(Contract, [c], c.id in ^ids)

    case PRMRepo.update_all(query, set: [is_suspended: is_suspended]) do
      {suspended, _} -> {:ok, suspended}
      err -> err
    end
  end

  defp search(changes) do
    date_from_start_date = Map.get(changes, :date_from_start_date)
    date_to_start_date = Map.get(changes, :date_to_start_date)
    date_from_end_date = Map.get(changes, :date_from_end_date)
    date_to_end_date = Map.get(changes, :date_to_end_date)
    legal_entity_id = Map.get(changes, :legal_entity_id)

    params = Map.drop(changes, ~w(
      date_from_start_date
      date_to_start_date
      date_from_end_date
      date_to_end_date
      legal_entity_id
      page
      page_size
    )a)

    query = if map_size(params) > 0, do: where(Contract, ^Map.to_list(params)), else: Contract

    query
    |> add_date_range_at_query(:start_date, date_from_start_date, date_to_start_date)
    |> add_date_range_at_query(:end_date, date_from_end_date, date_to_end_date)
    |> add_legal_entity_id_query(legal_entity_id)
    |> join(:left, [c], ce in ContractEmployee, c.id == ce.contract_id)
    |> join(:left, [c], cd in ContractDivision, c.id == cd.contract_id)
    |> preload([c, ce, cd], contract_employees: ce, contract_divisions: cd)
    |> PRMRepo.paginate(Map.take(changes, ~w(page page_size)a))
  end

  defp add_date_range_at_query(query, _, nil, nil), do: query

  defp add_date_range_at_query(query, attr, date_from, nil) do
    where(query, [c], field(c, ^attr) >= ^date_from)
  end

  defp add_date_range_at_query(query, attr, nil, date_to) do
    where(query, [c], field(c, ^attr) <= ^date_to)
  end

  defp add_date_range_at_query(query, attr, date_from, date_to) do
    where(query, [c], fragment("? BETWEEN ? AND ?", field(c, ^attr), ^date_from, ^date_to))
  end

  defp add_legal_entity_id_query(query, nil), do: query

  defp add_legal_entity_id_query(query, legal_entity_id) do
    where(query, [c], c.nhs_legal_entity_id == ^legal_entity_id or c.contractor_legal_entity_id == ^legal_entity_id)
  end

  defp validate_contractor_legal_entity_id(%Contract{} = contract, %{
         "contractor_legal_entity_id" => contractor_legal_entity_id
       }) do
    if contract.contractor_legal_entity_id == contractor_legal_entity_id,
      do: :ok,
      else: {:error, {:forbidden, "You are not allowed to view this contract"}}
  end

  defp validate_contractor_legal_entity_id(_contract, _params), do: :ok

  def load_contract_references(contract) do
    contract_references =
      Preload.preload_references(contract, [
        {:contractor_legal_entity_id, :legal_entity},
        {:contractor_owner_id, :employee},
        {:nhs_legal_entity_id, :legal_entity},
        {:nhs_signer_id, :employee},
        {:contract_request_id, :contract_request},
        {:contractor_divisions, :division}
      ])

    contract_request = get_in(contract_references, [:contract_request, contract.contract_request_id])

    contract_request_references =
      Preload.preload_references(contract_request, [
        {[:contractor_employee_divisions, "$", "employee_id"], :employee}
      ])

    references = MapDeepMerge.merge(contract_references, contract_request_references)

    {:ok, contract, references}
  end

  defp changeset(%Search{} = contract, attrs) do
    fields =
      :fields
      |> Search.__schema__()
      |> List.delete(:ids)

    cast(contract, attrs, fields)
  end

  defp changeset(%Contract{} = contract, attrs) do
    inserted_by = Map.get(attrs, "inserted_by")
    updated_by = Map.get(attrs, "updated_by")

    attrs =
      case Map.get(attrs, "contractor_employee_divisions") do
        nil ->
          attrs

        contractor_employee_divisions ->
          contractor_employee_divisions =
            Enum.map(
              contractor_employee_divisions,
              &(&1
                |> Map.put("start_date", Map.get(attrs, "start_date"))
                |> Map.put("inserted_by", inserted_by)
                |> Map.put("updated_by", updated_by))
            )

          Map.put(attrs, "contract_employees", contractor_employee_divisions)
      end

    attrs =
      case Map.get(attrs, "contractor_divisions") do
        nil ->
          attrs

        contractor_divisions ->
          contractor_divisions =
            Enum.map(
              contractor_divisions,
              &%{"division_id" => &1, "inserted_by" => inserted_by, "updated_by" => updated_by}
            )

          Map.put(attrs, "contract_divisions", contractor_divisions)
      end

    contract
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> cast_assoc(:contract_employees)
    |> cast_assoc(:contract_divisions)
    |> validate_required(@fields_required)
  end

  defp ids_changeset(attrs) do
    fields = ~w(ids)a

    %Search{}
    |> cast(attrs, fields)
    |> validate_required(fields)
  end

  defp validate_edrpou(search_params) do
    edrpou = Map.get(search_params, :edrpou)
    contractor_legal_entity_id = Map.get(search_params, :contractor_legal_entity_id)
    search_params = Map.delete(search_params, :edrpou)

    with false <- is_nil(edrpou),
         %LegalEntity{} = legal_entity <- PRMRepo.get_by(LegalEntity, edrpou: edrpou) do
      cond do
        contractor_legal_entity_id == legal_entity.id ->
          {:ok, search_params}

        is_nil(contractor_legal_entity_id) ->
          search_params = Map.put(search_params, :contractor_legal_entity_id, legal_entity.id)
          {:ok, search_params}

        true ->
          :error
      end
    else
      true -> {:ok, search_params}
      nil -> :error
    end
  end

  defp validate_client_type(_, "NHS", search_params), do: {:ok, search_params}

  defp validate_client_type(client_id, "MSP", %{contractor_legal_entity_id: id} = search_params) do
    cond do
      id == client_id -> {:ok, search_params}
      is_nil(id) -> {:ok, Map.put(search_params, :contractor_legal_entity_id, client_id)}
      true -> get_empty_response(search_params)
    end
  end

  defp validate_client_type(_, nil, search_params), do: {:ok, search_params}

  defp load_contracts_references(contracts) do
    references =
      Preload.preload_references_for_list(contracts, [
        {:contractor_owner_id, :employee}
      ])

    {:ok, references}
  end

  defp get_empty_response(params) do
    {:ok,
     %Page{
       entries: [],
       page_number: 1,
       page_size: Map.get(params, "page_size", 50),
       total_entries: 0,
       total_pages: 1
     }, %{}}
  end

  defp load_references(%Contract{} = contract) do
    contract
    |> PRMRepo.preload(:contract_employees)
    |> PRMRepo.preload(:contract_divisions)
  end
end

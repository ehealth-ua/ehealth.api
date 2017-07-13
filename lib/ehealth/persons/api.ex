defmodule EHealth.Persons.API do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_client_id: 1]
  import EHealth.Plugs.ClientContext, only: [get_context_params: 2]

  alias EHealth.API.OPS
  alias EHealth.API.MPI
  alias EHealth.API.PRM
  alias EHealth.API.Mithril

  def search_persons(params, headers) do
    MPI.search(params, headers)
  end

  def get_person_declaration(person_id, headers) do
    params = %{"person_id" => person_id, "is_active" => true}

    with {:ok, %{"meta" => meta, "data" => declarations}} <- OPS.get_declarations(params, headers),
         {:ok, declaration} <- check_declarations_amount(declarations),
         :ok <- check_declaration_access(declaration["legal_entity_id"], headers),
         {:ok, %{"data" => person}} <- MPI.person(declaration["person_id"], headers),
         {:ok, %{"data" => legal_entity}} <- PRM.get_legal_entity_by_id(declaration["legal_entity_id"], headers),
         {:ok, %{"data" => division}} <- PRM.get_division_by_id(declaration["division_id"], headers),
         {:ok, %{"data" => employee}} <- PRM.get_employee_by_id(declaration["employee_id"], headers),
         {:ok, response} <- prepare_response([meta, declaration, person, legal_entity, division, employee])
    do
      {:ok, response}
    end
  end

  # one declaration, it's good
  def check_declarations_amount([declaration]), do: {:ok, declaration}

  # declarations not found, return 404
  def check_declarations_amount([]), do: {:error, :not_found}

  # declarations more than one, return 400
  def check_declarations_amount(_) do
    {:error, {:bad_request, "A person has more than one active declaration."}}
  end

  def check_declaration_access(legal_entity_id, headers) do
    with {:ok, client_type} <- get_client_type_name(headers),
         params <- headers |> get_client_id() |> get_context_params(client_type),
         true <- legal_entity_allowed?(legal_entity_id, params)
         do :ok
    else
         _ -> {:error, :forbidden}
    end
  end

  def get_client_type_name(headers) do
    headers
    |> get_client_id()
    |> Mithril.get_client_type_name(headers)
    |> case do
         nil -> {:error, :access_denied}
         client_type -> {:ok, client_type}
       end
  end

  def legal_entity_allowed?(legal_entity_id, %{"legal_entity_id" => id}) when legal_entity_id != id, do: false
  def legal_entity_allowed?(_, _), do: true

  def prepare_response([meta, declaration, person, legal_entity, division, employee]) do
    data =
      declaration
      |> Map.take(fields(:declaration))
      |> Map.put("person", Map.take(person, fields(:division)))
      |> Map.put("division", Map.take(division, fields(:division)))
      |> Map.put("employee", Map.take(employee, fields(:employee)))
      |> Map.put("legal_entity", Map.take(legal_entity, fields(:legal_entity)))

    {:ok, %{"meta" => meta, "data" => data}}
  end

  def fields(:employee) do
    ~W(
      id
      position
      employee_type
      status
      start_date
      end_date
      party
      division_id
      legal_entity
      doctor
    )
  end

  def fields(:person) do
    ~W(
      id
      first_name
      last_name
      second_name
      birth_date
      tax_id
      phones
      birth_country
      birth_settlement
    )
  end

  def fields(:division) do
    ~W(
      id
      name
      legal_entity_id
      type
      mountain_group
    )
  end

  def fields(:legal_entity) do
    ~W(
      id
      name
      short_Name
      legal_form
      public_name
      edrpou
      status
      email
      phones
      addresses
      created_at
      modified_at
    )
  end

  def fields(:declaration) do
    ~W(
      id
      start_date
      end_date
      inserted_at
      updated_at
    )
  end
end

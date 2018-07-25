defmodule EHealth.DeclarationRequests.API.Creator do
  @moduledoc false

  use Confex, otp_app: :ehealth
  use Timex

  import Ecto.Query
  import Ecto.Changeset
  import EHealth.Utils.TypesConverter, only: [string_to_integer: 1]

  alias Ecto.{Changeset, UUID}
  alias EHealth.DeclarationRequests
  alias EHealth.DeclarationRequests.API.{Documents, Persons}
  alias EHealth.DeclarationRequests.DeclarationRequest
  alias EHealth.Employees.Employee
  alias EHealth.GlobalParameters
  alias EHealth.Man.Templates.DeclarationRequestPrintoutForm
  alias EHealth.Persons.Validator, as: PersonValidator
  alias EHealth.PartyUsers
  alias EHealth.Repo
  alias EHealth.Utils.NumberGenerator
  alias EHealth.Utils.Phone
  alias EHealth.ValidationError
  alias EHealth.Validators.BirthDate
  alias EHealth.Validators.Error
  alias EHealth.Validators.TaxID

  @mpi_api Application.get_env(:ehealth, :api_resolvers)[:mpi]
  @otp_verification_api Application.get_env(:ehealth, :api_resolvers)[:otp_verification]

  @auth_na DeclarationRequest.authentication_method(:na)
  @auth_otp DeclarationRequest.authentication_method(:otp)
  @auth_offline DeclarationRequest.authentication_method(:offline)
  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]

  @channel_cabinet DeclarationRequest.channel(:cabinet)

  @status_new DeclarationRequest.status(:new)
  @status_approved DeclarationRequest.status(:approved)

  @pediatrician "PEDIATRICIAN"
  @therapist "THERAPIST"
  @family_doctor "FAMILY_DOCTOR"
  @allowed_employee_specialities [@pediatrician, @therapist, @family_doctor]

  @mithril_api Application.get_env(:ehealth, :api_resolvers)[:mithril]

  def create(params, user_id, person, employee, division, legal_entity, headers) do
    updates = [
      status: DeclarationRequest.status(:cancelled),
      updated_at: DateTime.utc_now(),
      updated_by: user_id
    ]

    global_parameters = GlobalParameters.get_values()

    auxiliary_entities = %{
      employee: employee,
      global_parameters: global_parameters,
      division: division,
      legal_entity: legal_entity,
      person_id: person["id"]
    }

    pending_declaration_requests = pending_declaration_requests(person, employee.id, legal_entity.id)

    Repo.transaction(fn ->
      previous_request_ids =
        pending_declaration_requests
        |> Repo.all()
        |> Enum.map(&Map.get(&1, :id))

      query = where(DeclarationRequest, [dr], dr.id in ^previous_request_ids)
      Repo.update_all(query, set: updates)

      with {:ok, declaration_request} <- insert_declaration_request(params, user_id, auxiliary_entities, headers),
           {:ok, declaration_request} <- finalize(declaration_request),
           {:ok, urgent_data} <- prepare_urgent_data(declaration_request) do
        %{urgent_data: urgent_data, finalize: declaration_request}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp insert_declaration_request(params, user_id, auxiliary_entities, headers) do
    params
    |> changeset(user_id, auxiliary_entities, headers)
    |> do_insert_declaration_request(auxiliary_entities.employee)
  end

  defp do_insert_declaration_request(changeset, employee) do
    case Repo.insert(changeset) do
      {:ok, declaration_request} ->
        {:ok, declaration_request}

      {:error, %Changeset{errors: [declaration_number: {"has already been taken", []}]}} ->
        # declaration_number collision, let's regenerate it
        changeset
        |> put_declaration_number(NumberGenerator.generate(1, 2))
        |> generate_printout_form(employee)
        |> do_insert_declaration_request(employee)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def validate_employee_speciality(%Employee{additional_info: additional_info}) do
    specialities = Map.get(additional_info, "specialities", [])

    if Enum.any?(specialities, fn s -> Map.get(s, "speciality") in @allowed_employee_specialities end) do
      :ok
    else
      alllowed_types = Enum.join(@allowed_employee_specialities, ", ")

      Error.dump(%ValidationError{
        description: "Employee's speciality does not belong to a doctor: #{alllowed_types}",
        params: [allowed_types: alllowed_types],
        rule: "speciality_inclusion",
        path: "$.data"
      })
    end
  end

  def prepare_auth_method_current(%{"type" => @auth_offline}), do: %{"type" => @auth_offline}
  def prepare_auth_method_current(_), do: %{"type" => @auth_na}

  def prepare_auth_method_current(@auth_otp, %{"phone_number" => phone_number}, _) do
    %{
      "type" => @auth_otp,
      "number" => phone_number
    }
  end

  def prepare_auth_method_current(@auth_na, _, req_auth_method) do
    auth_method = Map.take(req_auth_method, ["type"])

    case Map.has_key?(req_auth_method, "phone_number") do
      true -> Map.put(auth_method, "number", req_auth_method["phone_number"])
      _ -> auth_method
    end
  end

  def prepare_auth_method_current(type, _authentication_method, _), do: %{"type" => type}

  defp fetch_users(result) do
    {:ok, Enum.map(result, &Map.get(&1, :user_id))}
  end

  defp get_role_id(name) do
    with {:ok, results} <- @mithril_api.get_roles_by_name(name, []) do
      roles = Map.get(results, "data")

      case length(roles) do
        1 -> {:ok, roles |> List.first() |> Map.get("id")}
        _ -> {:error, "Role #{name} does not exist"}
      end
    end
  end

  defp filter_users_by_role(role_id, users) do
    user_roles_results = Enum.map(users, &@mithril_api.get_user_roles(&1, %{}, []))
    error = Enum.find(user_roles_results, fn {k, _} -> k == :error end)

    case error do
      nil -> {:ok, Enum.filter(user_roles_results, fn {:ok, result} -> check_role(result, role_id) end)}
      err -> err
    end
  end

  defp get_user_id(user_roles) when length(user_roles) > 0 do
    {:ok, user_role} = List.last(user_roles)

    user_id =
      user_role
      |> Map.get("data")
      |> List.first()
      |> Map.get("user_id")

    {:ok, user_id}
  end

  defp get_user_id(_), do: {:error, "Current user is not a doctor"}

  defp check_role(user, role_id) do
    Enum.any?(Map.get(user, "data"), fn user_role -> Map.get(user_role, "role_id") == role_id end)
  end

  defp get_user_email(user_id) do
    with {:ok, user} <- @mithril_api.get_user_by_id(user_id, []), do: {:ok, get_in(user, ["data", "email"])}
  end

  defp get_party_email(party_id) do
    with result <- PartyUsers.list!(%{party_id: party_id}),
         {:ok, users} <- fetch_users(result),
         {:ok, role_id} <- get_role_id("DOCTOR"),
         {:ok, user_roles} <- filter_users_by_role(role_id, users),
         {:ok, user_id} <- get_user_id(user_roles),
         do: get_user_email(user_id)
  end

  defp put_in_data(changeset, keys, value) do
    new_data =
      changeset
      |> get_field(:data)
      |> put_in(keys, value)

    put_change(changeset, :data, new_data)
  end

  defp format_error_response(microservice, result) do
    "Error during #{microservice} interaction. Result from #{microservice}: #{inspect(result)}"
  end

  def finalize(declaration_request) do
    authorization = declaration_request.authentication_method_current

    case authorization["type"] do
      @auth_na ->
        {:ok, declaration_request}

      @auth_otp ->
        case @otp_verification_api.initialize(authorization["number"], []) do
          {:ok, _} ->
            {:ok, declaration_request}

          {:error, error} ->
            {:error, error}
        end

      @auth_offline ->
        case Documents.generate_links(declaration_request, ["PUT"]) do
          {:ok, documents} ->
            update_documents(declaration_request, documents)

          {:error, _} = bad_result ->
            bad_result
        end
    end
  end

  defp update_documents(%DeclarationRequest{} = declaration_request, documents) do
    declaration_request
    |> DeclarationRequests.changeset(%{documents: documents})
    |> Repo.update()
  end

  def prepare_urgent_data(declaration_request) do
    filtered_authentication_method_current =
      filter_authentication_method(declaration_request.authentication_method_current)

    filter_document_links = fn documents ->
      filter_fun = fn document -> document["verb"] == "PUT" end
      map_fun = fn document -> Map.drop(document, ["verb"]) end

      documents
      |> Enum.filter(filter_fun)
      |> Enum.map(map_fun)
    end

    urgent_data =
      if declaration_request.documents do
        %{
          authentication_method_current: filtered_authentication_method_current,
          documents: filter_document_links.(declaration_request.documents)
        }
      else
        %{
          authentication_method_current: filtered_authentication_method_current
        }
      end

    {:ok, urgent_data}
  end

  defp filter_authentication_method(%{"number" => number} = method) do
    Map.put(method, "number", Phone.hide_number(number))
  end

  defp filter_authentication_method(method), do: method

  def pending_declaration_requests(%{"tax_id" => tax_id}, employee_id, legal_entity_id) do
    from(
      p in DeclarationRequest,
      where: p.status in [@status_new, @status_approved],
      where: fragment("?->'person'->>'tax_id' = ?", p.data, ^tax_id),
      where: fragment("?->'employee'->>'id' = ?", p.data, ^employee_id),
      where: fragment("?->'legal_entity'->>'id' = ?", p.data, ^legal_entity_id)
    )
  end

  def pending_declaration_requests(person, employee_id, legal_entity_id) do
    person_where = %{"person" => Map.take(person, ~W(first_name last_name birth_date))}

    from(
      p in DeclarationRequest,
      where: p.status in [@status_new, @status_approved],
      where: fragment("? @> ?", p.data, ^person_where),
      where: fragment("?->'employee'->>'id' = ?", p.data, ^employee_id),
      where: fragment("?->'legal_entity'->>'id' = ?", p.data, ^legal_entity_id)
    )
  end

  def changeset(attrs, user_id, auxiliary_entities, headers) do
    %{
      employee: employee,
      global_parameters: global_parameters,
      division: division,
      legal_entity: legal_entity,
      person_id: person_id
    } = auxiliary_entities

    employee_speciality_officio = employee.speciality["speciality"]

    overlimit = Map.get(attrs, "overlimit", false)
    channel = attrs["channel"]
    attrs = Map.drop(attrs, ~w(person_id employee_id division_id overlimit))

    id = UUID.generate()
    declaration_id = UUID.generate()

    %DeclarationRequest{id: id}
    |> cast(%{data: attrs, overlimit: overlimit, channel: channel}, ~w(data overlimit channel)a)
    |> validate_legal_entity_employee(legal_entity, employee)
    |> validate_legal_entity_division(legal_entity, division)
    |> validate_employee_type(employee)
    |> validate_patient_birth_date()
    |> validate_patient_age(employee_speciality_officio, global_parameters["adult_age"])
    |> validate_authentication_method_phone_number(headers)
    |> validate_tax_id()
    |> validate_person_addresses()
    |> validate_confidant_persons_tax_id()
    |> validate_confidant_person_rel_type()
    |> validate_authentication_methods()
    |> put_start_end_dates(employee_speciality_officio, global_parameters)
    |> put_in_data(["employee"], prepare_employee_struct(employee))
    |> put_in_data(["division"], prepare_division_struct(division))
    |> put_in_data(["legal_entity"], prepare_legal_entity_struct(legal_entity))
    |> put_in_data(["declaration_id"], declaration_id)
    |> put_change(:id, id)
    |> put_change(:declaration_id, declaration_id)
    |> put_change(:status, @status_new)
    |> put_change(:inserted_by, user_id)
    |> put_change(:updated_by, user_id)
    |> put_declaration_number(NumberGenerator.generate(1, 2))
    |> unique_constraint(:declaration_number, name: :declaration_requests_declaration_number_index)
    |> put_party_email()
    |> determine_auth_method_for_mpi(channel, person_id)
    |> generate_printout_form(employee)
  end

  defp validate_legal_entity_employee(changeset, legal_entity, employee) do
    validate_change(changeset, :data, fn :data, _data ->
      case employee.legal_entity_id == legal_entity.id do
        true -> []
        false -> [data: {"Employee does not belong to legal entity.", validation: "employee_unemployed"}]
      end
    end)
  end

  defp validate_legal_entity_division(changeset, legal_entity, division) do
    validate_change(changeset, :data, fn :data, _data ->
      case division.legal_entity_id == legal_entity.id do
        true -> []
        false -> [data: "Division does not belong to legal entity."]
      end
    end)
  end

  def validate_employee_status(%Employee{status: status}) do
    if status == Employee.status(:approved) do
      :ok
    else
      Error.dump(%ValidationError{description: "Invalid employee status", path: "$.employee_id"})
    end
  end

  def validate_employee_type(changeset, employee) do
    if Employee.type(:doctor) == employee.employee_type do
      changeset
    else
      add_error(changeset, :"data.person.employee_id", "Employee ID must reference a doctor.")
    end
  end

  def validate_patient_birth_date(changeset) do
    validate_change(changeset, :data, fn :data, data ->
      data
      |> get_in(["person", "birth_date"])
      |> BirthDate.validate()
      |> case do
        true -> []
        false -> [data: "Invalid birth date."]
      end
    end)
  end

  def validate_patient_age(changeset, speciality, adult_age) do
    validate_change(changeset, :data, fn :data, data ->
      patient_birth_date =
        data
        |> get_in(["person", "birth_date"])
        |> Date.from_iso8601!()

      patient_age = Timex.diff(Timex.now(), patient_birth_date, :years)

      case belongs_to(patient_age, adult_age, speciality) do
        true -> []
        false -> [data: {"Doctor speciality doesn't match patient's age", validation: "invalid_age"}]
      end
    end)
  end

  def belongs_to(age, adult_age, @therapist), do: age >= string_to_integer(adult_age)
  def belongs_to(age, adult_age, @pediatrician), do: age < string_to_integer(adult_age)
  def belongs_to(_age, _adult_age, @family_doctor), do: true

  defp validate_authentication_method_phone_number(changeset, headers) do
    validate_change(changeset, :data, fn :data, data ->
      result =
        data
        |> get_in(["person", "authentication_methods"])
        |> PersonValidator.validate_authentication_method_phone_number(headers)

      case result do
        :ok -> []
        {:error, message} -> [data: message]
      end
    end)
  end

  def validate_tax_id(changeset) do
    tax_id =
      changeset
      |> get_field(:data)
      |> get_in(["person", "tax_id"])

    if is_nil(tax_id) || TaxID.validate(tax_id, nil) == :ok do
      changeset
    else
      add_error(changeset, :"data.person.tax_id", "Person's tax ID in not valid.")
    end
  end

  def validate_person_addresses(changeset) do
    addresses =
      changeset
      |> get_field(:data)
      |> get_in(["person", "addresses"])

    with :ok <- assert_address_count(addresses, "REGISTRATION", 1),
         :ok <- assert_address_count(addresses, "RESIDENCE", 1) do
      changeset
    else
      {:error, "REGISTRATION"} ->
        add_error(changeset, :"data.person.addresses", "one and only one registration address is required")

      {:error, "RESIDENCE"} ->
        add_error(changeset, :"data.person.addresses", "one and only one residence address is required")
    end
  end

  defp assert_address_count(enum, address_type, count) do
    if count == Enum.count(enum, fn %{"type" => type} -> type == address_type end) do
      :ok
    else
      {:error, address_type}
    end
  end

  def validate_confidant_persons_tax_id(changeset) do
    confidant_persons =
      changeset
      |> get_field(:data)
      |> get_in(["person", "confidant_person"])

    if is_list(confidant_persons) && !Enum.empty?(confidant_persons) do
      validation = fn {person, index}, changeset ->
        tax_id = person["tax_id"]

        if is_nil(tax_id) || TaxID.validate(tax_id, nil) == :ok do
          changeset
        else
          add_error(changeset, :"data.person.confidant_person[#{index}].tax_id", "Person's tax ID in not valid.")
        end
      end

      confidant_persons
      |> Enum.with_index()
      |> Enum.reduce(changeset, validation)
    else
      changeset
    end
  end

  def validate_confidant_person_rel_type(changeset) do
    confidant_persons =
      changeset
      |> get_field(:data)
      |> get_in(["person", "confidant_person"])

    if is_list(confidant_persons) && !Enum.empty?(confidant_persons) do
      if 1 == Enum.count(confidant_persons, fn %{"relation_type" => type} -> type == "PRIMARY" end) do
        changeset
      else
        message = "one and only one confidant person with type PRIMARY is required"
        add_error(changeset, :"data.person.confidant_persons[].relation_type", message)
      end
    else
      changeset
    end
  end

  def validate_authentication_methods(changeset) do
    authentication_methods =
      changeset
      |> get_field(:data)
      |> get_in(["person", "authentication_methods"])

    if is_list(authentication_methods) && !Enum.empty?(authentication_methods) do
      authentication_methods
      |> Enum.reduce({0, changeset}, &validate_auth_method/2)
      |> elem(1)
    else
      changeset
    end
  end

  defp validate_auth_method(%{"type" => @auth_otp} = method, {i, changeset}) do
    case Map.has_key?(method, "phone_number") do
      true ->
        {i + 1, changeset}

      false ->
        message = "required property phone_number was not present"
        {i + 1, add_error(changeset, :"data.person.authentication_methods.[#{i}].phone_number", message)}
    end
  end

  defp validate_auth_method(_, {i, changeset}) do
    {i + 1, changeset}
  end

  defp put_start_end_dates(changeset, employee_speciality_officio, global_parameters) do
    %{
      "declaration_term" => term,
      "declaration_term_unit" => unit,
      "adult_age" => adult_age
    } = global_parameters

    adult_age = String.to_integer(adult_age)
    term = String.to_integer(term)

    normalized_unit =
      unit
      |> String.downcase()
      |> String.to_atom()

    data = get_field(changeset, :data)
    birth_date = get_in(data, ["person", "birth_date"])

    start_date = Date.utc_today()

    end_date =
      request_end_date(employee_speciality_officio, start_date, [{normalized_unit, term}], birth_date, adult_age)

    new_data =
      data
      |> put_in(["end_date"], end_date)
      |> put_in(["start_date"], start_date)

    put_change(changeset, :data, new_data)
  end

  defp prepare_employee_struct(employee) do
    %{
      "id" => employee.id,
      "position" => employee.position,
      "party" => %{
        "id" => employee.party.id,
        "first_name" => employee.party.first_name,
        "second_name" => employee.party.second_name,
        "last_name" => employee.party.last_name,
        "phones" => employee.party.phones,
        "tax_id" => employee.party.tax_id
      }
    }
  end

  defp prepare_division_struct(division) do
    %{
      "id" => division.id,
      "type" => division.type,
      "phones" => division.phones,
      "name" => division.name,
      "legal_entity_id" => division.legal_entity_id,
      "external_id" => division.external_id,
      "email" => division.email,
      "addresses" => division.addresses
    }
  end

  defp prepare_legal_entity_struct(legal_entity) do
    %{
      "id" => legal_entity.id,
      "name" => legal_entity.name,
      "short_name" => legal_entity.short_name,
      "phones" => legal_entity.phones,
      "legal_form" => legal_entity.legal_form,
      "edrpou" => legal_entity.edrpou,
      "public_name" => legal_entity.public_name,
      "email" => legal_entity.email,
      "addresses" => legal_entity.addresses,
      "accreditation" => legal_entity.medical_service_provider.accreditation,
      "licenses" => legal_entity.medical_service_provider.licenses
    }
  end

  defp put_declaration_number(changeset, num) do
    put_change(changeset, :declaration_number, num)
  end

  def put_party_email(%Changeset{valid?: false} = changeset), do: changeset

  def put_party_email(changeset) do
    party_id =
      changeset
      |> get_field(:data)
      |> get_in(["employee", "party", "id"])

    case get_party_email(party_id) do
      {:ok, email} ->
        put_in_data(changeset, ["employee", "party", "email"], email)

      {:error, error} when is_binary(error) ->
        add_error(changeset, :email, error)

      {:error, error_response} ->
        add_error(changeset, :email, format_error_response("microservice", error_response))
    end
  end

  def determine_auth_method_for_mpi(%Changeset{valid?: false} = changeset, _, _), do: changeset

  def determine_auth_method_for_mpi(changeset, @channel_cabinet, person_id) do
    changeset
    |> put_change(:authentication_method_current, %{"type" => @auth_na})
    |> put_change(:mpi_id, person_id)
  end

  def determine_auth_method_for_mpi(changeset, _, _) do
    data = get_field(changeset, :data)
    search_params = Persons.get_search_params(data["person"])

    case @mpi_api.search(search_params, []) do
      {:ok, %{"data" => [person]}} ->
        do_determine_auth_method_for_mpi(person, changeset)

      {:ok, %{"data" => _}} ->
        authentication_method = hd(data["person"]["authentication_methods"])
        put_change(changeset, :authentication_method_current, prepare_auth_method_current(authentication_method))

      {:error, %HTTPoison.Error{reason: reason}} ->
        add_error(changeset, :authentication_method_current, format_error_response("MPI", reason))

      {:error, error_response} ->
        add_error(changeset, :authentication_method_current, format_error_response("MPI", error_response))
    end
  end

  defp do_determine_auth_method_for_mpi(person, changeset) do
    authentication_method = List.first(person["authentication_methods"] || [])
    authenticated_methods = changeset |> get_field(:data) |> get_in(~w(person authentication_methods)) |> hd

    authentication_method_current =
      prepare_auth_method_current(
        authentication_method["type"],
        authentication_method,
        authenticated_methods
      )

    changeset
    |> put_change(:authentication_method_current, authentication_method_current)
    |> put_change(:mpi_id, person["id"])
  end

  def generate_printout_form(%Changeset{valid?: false} = changeset, _), do: changeset

  def generate_printout_form(changeset, employee) do
    form_data = get_field(changeset, :data)
    employee = Map.put(Map.get(form_data, "employee") || %{}, "speciality", Map.get(employee, :speciality))
    form_data = Map.put(form_data, "employee", employee)
    declaration_number = get_field(changeset, :declaration_number)

    authentication_method_current =
      case get_change(changeset, :authentication_method_default) do
        %{"type" => @auth_na} = default -> default
        _ -> get_change(changeset, :authentication_method_current)
      end

    case DeclarationRequestPrintoutForm.render(form_data, declaration_number, authentication_method_current) do
      {:ok, printout_content} ->
        put_change(changeset, :printout_content, printout_content)

      {:error, error_response} ->
        add_error(changeset, :printout_content, format_error_response("MAN", error_response))
    end
  end

  def request_end_date(employee_speciality_officio, today, expiration, birth_date, adult_age) do
    birth_date = Date.from_iso8601!(birth_date)

    normal_expiration_date = Timex.shift(today, expiration)
    adjusted_expiration_date = Timex.shift(birth_date, years: adult_age, days: -1)

    case {employee_speciality_officio, Timex.diff(today, birth_date, :years) >= adult_age} do
      {@pediatrician, false} ->
        case Timex.compare(normal_expiration_date, adjusted_expiration_date) do
          1 -> adjusted_expiration_date
          _ -> normal_expiration_date
        end

      _ ->
        normal_expiration_date
    end
  end
end

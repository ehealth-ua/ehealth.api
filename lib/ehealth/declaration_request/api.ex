defmodule EHealth.DeclarationRequest.API do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  import EHealth.DeclarationRequest.API.Validations

  alias Ecto.Multi
  alias Ecto.UUID
  alias EHealth.Repo
  alias EHealth.API.PRM
  alias EHealth.DeclarationRequest.API.Create
  alias EHealth.DeclarationRequest.API.Helpers

  @required_fields ~w(
    data
    status
    authentication_method_current
    documents
    printout_content
    inserted_by
    updated_by
  )a

  def create(attrs, user_id) do
    with {:ok, %{"data" => global_parameters}} <- PRM.get_global_parameters(),
         {:ok, %{"data" => employee}} <- PRM.get_employee_by_id(attrs["employee_id"]) do
      updates = [status: "CANCELLED", updated_at: DateTime.utc_now(), updated_by: user_id]

      Multi.new
      |> Multi.update_all(:previous_requests, pending_declaration_requests(attrs), set: updates)
      |> Multi.insert(:declaration_request, create_changeset(attrs, user_id, employee, global_parameters))
      |> Multi.run(:verification_code, &Create.send_verification_code/1)
      |> Repo.transaction
    end
  end

  def create_changeset(attrs, user_id, employee, global_parameters) do
    %EHealth.DeclarationRequest{}
    |> cast(%{data: attrs}, [:data])
    |> validate_patient_age(Enum.map(employee["specialities"], &(&1["speciality"])), global_parameters["adult_age"])
    |> validate_patient_phone_number()
    |> put_start_end_dates(global_parameters)
    |> put_change(:id, UUID.generate())
    |> put_change(:status, "NEW")
    |> put_change(:inserted_by, user_id)
    |> put_change(:updated_by, user_id)
    |> Create.determine_auth_method_for_mpi()
    |> Create.generate_printout_form()
    |> Create.generate_upload_urls()
    |> validate_required(@required_fields)
  end

  def put_in_data(changeset, key, value) do
    new_data =
      changeset
      |> get_field(:data)
      |> put_in([key], value)

    put_change(changeset, :data, new_data)
  end

  def put_start_end_dates(changeset, global_parameters) do
    %{
      "declaration_request_term" => term,
      "declaration_request_term_unit" => unit,
      "adult_age" => adult_age
    } = global_parameters

    normalized_unit =
      unit
      |> String.downcase
      |> String.to_atom

    data = get_field(changeset, :data)
    birth_date = get_in(data, ["person", "birth_date"])

    start_date = Date.utc_today()
    end_date = Helpers.request_end_date(start_date, [{normalized_unit, term}], birth_date, adult_age)

    new_data =
      data
      |> put_in(["end_date"], end_date)
      |> put_in(["start_date"], start_date)

    put_change(changeset, :data, new_data)
  end

  def pending_declaration_requests(raw_declaration_request) do
    tax_id          = get_in(raw_declaration_request, ["person", "tax_id"])
    employee_id     = get_in(raw_declaration_request, ["employee_id"])
    legal_entity_id = get_in(raw_declaration_request, ["legal_entity_id"])

    from p in EHealth.DeclarationRequest,
      where: p.status in ["NEW", "APPROVED"],
      where: fragment("? #>> ? = ?", p.data, "{person, tax_id}", ^tax_id),
      where: fragment("? #>> ? = ?", p.data, "{employee_id}", ^employee_id),
      where: fragment("? #>> ? = ?", p.data, "{legal_entity_id}", ^legal_entity_id)
  end
end

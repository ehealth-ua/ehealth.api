defmodule Core.MedicalPrograms do
  @moduledoc false

  use Core.Search, Application.get_env(:core, :repos)[:read_prm_repo]

  alias Core.MedicalPrograms.MedicalProgram
  alias Core.MedicalPrograms.Search
  alias Core.Medications
  alias Core.PRMRepo

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @fields_required ~w(name)a
  @fields_optional ~w(is_active)a

  @search_fields ~w(
    id
    name
    is_active
  )a

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, MedicalProgram)
  end

  def get_by_ids(ids) do
    MedicalProgram
    |> where([mp], mp.id in ^ids)
    |> @read_prm_repo.all()
  end

  def get_by_id(id), do: @read_prm_repo.get(MedicalProgram, id)

  def get_by_id!(id), do: @read_prm_repo.get!(MedicalProgram, id)

  def fetch_by_id(id) do
    case get_by_id(id) do
      %MedicalProgram{} = medical_program -> {:ok, medical_program}
      _ -> {:error, {:not_found, "Medical program not found"}}
    end
  end

  def get_by!(params), do: @read_prm_repo.get_by!(MedicalProgram, params)

  def create(params, actor_id) do
    %MedicalProgram{}
    |> changeset(params)
    |> put_change(:inserted_by, actor_id)
    |> put_change(:updated_by, actor_id)
    |> PRMRepo.insert_and_log(actor_id)
  end

  def deactivate(%MedicalProgram{id: id} = medical_program, actor_id) do
    error_message =
      "This program has active participants. Only medical programs without participants can be deactivated"

    case Medications.count_active_program_medications_by(medical_program_id: id) do
      0 ->
        medical_program
        |> changeset(%{is_active: false, updated_by: actor_id})
        |> PRMRepo.update_and_log(actor_id)

      _ ->
        {:error, {:conflict, error_message}}
    end
  end

  def changeset(%Search{} = search, attrs) do
    cast(search, attrs, @search_fields)
  end

  def changeset(%MedicalProgram{} = medical_program, attrs) do
    medical_program
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
    |> validate_length(:name, max: 100)
  end
end

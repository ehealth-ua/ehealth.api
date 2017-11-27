defmodule EHealth.MedicalPrograms do
@moduledoc false

  use EHealth.Search, EHealth.PRMRepo

  alias EHealth.PRMRepo
  alias EHealth.Medications
  alias EHealth.MedicalPrograms.Search
  alias EHealth.MedicalPrograms.MedicalProgram

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
    |> PRMRepo.all()
  end

  def get_by_id(id) do
    PRMRepo.get(MedicalProgram, id)
  end

  def get_by_id!(id) do
    PRMRepo.get!(MedicalProgram, id)
  end

  def get_by!(params) do
    PRMRepo.get_by!(MedicalProgram, params)
  end

  def create(user_id, params) do
    %MedicalProgram{}
    |> changeset(params)
    |> put_change(:inserted_by, user_id)
    |> put_change(:updated_by, user_id)
    |> PRMRepo.insert_and_log(user_id)
  end

  def deactivate(updated_by, %MedicalProgram{id: id} = medical_program) do
    err_msg = "This program has active participants. Only medical programs without participants can be deactivated"
    case Medications.count_active_program_medications_by(medical_program_id: id) do
      0 ->
        medical_program
        |> changeset(%{is_active: false, updated_by: updated_by})
        |> PRMRepo.update_and_log(updated_by)

      _ ->
        {:error, {:conflict, err_msg}}
    end
  end

  def changeset(%Search{} = search, attrs) do
    cast(search, attrs, @search_fields)
  end
  def changeset(%MedicalProgram{} = medical_program, attrs) do
    medical_program
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end

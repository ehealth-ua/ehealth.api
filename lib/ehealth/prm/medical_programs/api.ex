defmodule EHealth.PRM.MedicalPrograms do
  @moduledoc false

  alias EHealth.PRM.MedicalPrograms.Schema, as: MedicalProgram
  alias EHealth.PRMRepo
  alias EHealth.PRM.MedicalPrograms.Search
  use EHealth.PRM.Search

  @fields_required ~w(name)a

  @search_fields ~w(
    id
    name
    is_active
  )a

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, MedicalProgram, Confex.get_env(:ehealth, :medical_programs_per_page))
  end

  def get_by_ids(ids) do
    MedicalProgram
    |> where([mp], mp.id in ^ids)
    |> PRMRepo.all()
  end

  def get_by_id(id) do
    PRMRepo.get(MedicalProgram, id)
  end

  def create(user_id, params) do
    %MedicalProgram{}
    |> changeset(params)
    |> put_change(:inserted_by, user_id)
    |> put_change(:updated_by, user_id)
    |> PRMRepo.insert
  end

  def changeset(%Search{} = search, attrs) do
    cast(search, attrs, @search_fields)
  end
  def changeset(%MedicalProgram{} = medical_program, attrs) do
    medical_program
    |> cast(attrs, @fields_required)
    |> validate_required(@fields_required)
  end
end

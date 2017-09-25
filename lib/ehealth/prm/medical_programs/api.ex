defmodule EHealth.PRM.MedicalPrograms do
  @moduledoc false

  alias EHealth.PRM.MedicalPrograms.Schema, as: MedicalProgram
  alias EHealth.PRMRepo
  alias EHealth.PRM.MedicalPrograms.Search
  use EHealth.PRM.Search

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

  def changeset(%Search{} = medical_program, attrs) do
    cast(medical_program, attrs, @search_fields)
  end
end

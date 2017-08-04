defmodule EHealth.PRM.Divisions do
  @moduledoc false

  alias EHealth.PRMRepo
  alias EHealth.PRM.Divisions.Schema, as: Division

  def get_division_by_id(id) do
    PRMRepo.get(Division, id)
  end
end

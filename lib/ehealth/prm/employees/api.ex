defmodule EHealth.PRM.Employees do
  @moduledoc false

  alias EHealth.PRMRepo
  alias EHealth.PRM.Employees.Schema, as: Employee

  def get_employee_by_id(id) do
    PRMRepo.get(Employee, id)
  end
end

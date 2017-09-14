defmodule EHealth.Unit.Employee.EmployeeCreatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true

  alias EHealth.Employee.EmployeeCreator
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias EHealth.PRMRepo

  test "deactivate_employee_owners/2" do
    legal_entity1 = insert(:prm, :legal_entity)
    legal_entity2 = insert(:prm, :legal_entity)
    insert(:prm, :employee,
      legal_entity: legal_entity1,
      employee_type: Employee.type(:owner)
    )
    insert(:prm, :employee,
      legal_entity: legal_entity1,
      employee_type: Employee.type(:pharmacy_owner)
    )
    employee1 = insert(:prm, :employee,
      legal_entity: legal_entity2,
      employee_type: Employee.type(:owner)
    )
    employee2 = insert(:prm, :employee,
      legal_entity: legal_entity2,
      employee_type: Employee.type(:owner)
    )
    employee3 = insert(:prm, :employee,
      legal_entity: legal_entity2,
      employee_type: Employee.type(:pharmacy_owner)
    )
    employee4 = insert(:prm, :employee,
      legal_entity: legal_entity2,
      employee_type: Employee.type(:pharmacy_owner)
    )

    EmployeeCreator.deactivate_employee_owners(employee1, get_headers())

    assert PRMRepo.get(Employee, employee1.id).is_active
    refute PRMRepo.get(Employee, employee2.id).is_active

    EmployeeCreator.deactivate_employee_owners(employee3, get_headers())

    assert PRMRepo.get(Employee, employee3.id).is_active
    refute PRMRepo.get(Employee, employee4.id).is_active
  end

  defp get_headers do
    [
      {"x-consumer-id", Ecto.UUID.generate()}
    ]
  end
end

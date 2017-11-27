defmodule EHealth.Unit.Employee.EmployeeCreatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true

  alias EHealth.Employees.EmployeeCreator
  alias EHealth.Employees.Employee
  alias EHealth.PRMRepo

  test "deactivate_employee_owners/2" do
    legal_entity1 = insert(:prm, :legal_entity)
    legal_entity2 = insert(:prm, :legal_entity)
    party1 = insert(:prm, :party, tax_id: "2222222225")
    party2 = insert(:prm, :party, tax_id: "1222222225")
    party3 = insert(:prm, :party, tax_id: "1220222225")
    party4 = insert(:prm, :party, tax_id: "1220220235")
    insert(:prm, :employee,
      legal_entity: legal_entity1,
      employee_type: Employee.type(:owner),
      party: party1
    )
    insert(:prm, :employee,
      legal_entity: legal_entity1,
      employee_type: Employee.type(:pharmacy_owner),
      party: party2
    )
    employee1 = insert(:prm, :employee,
      legal_entity: legal_entity2,
      employee_type: Employee.type(:owner),
      party: party3
    )
    employee2 = insert(:prm, :employee,
      legal_entity: legal_entity2,
      employee_type: Employee.type(:pharmacy_owner),
      party: party4
    )

    EmployeeCreator.deactivate_employee_owners(employee1.employee_type, employee1.legal_entity_id, get_headers())
    refute PRMRepo.get(Employee, employee1.id).is_active

    EmployeeCreator.deactivate_employee_owners(employee2.employee_type, employee2.legal_entity_id, get_headers())
    refute PRMRepo.get(Employee, employee2.id).is_active
  end

  defp get_headers do
    [
      {"x-consumer-id", Ecto.UUID.generate()}
    ]
  end
end

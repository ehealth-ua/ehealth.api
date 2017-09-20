defmodule EHealth.Unit.Employee.EmployeeCreatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true

  alias EHealth.Employee.EmployeeCreator
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias EHealth.PRMRepo

  test "deactivate_employee_owners/2" do
    legal_entity1 = insert(:prm, :legal_entity)
    legal_entity2 = insert(:prm, :legal_entity)
    party1 = insert(:prm, :party, tax_id: "2222222225")
    party2 = insert(:prm, :party, tax_id: "1222222225")
    party3 = insert(:prm, :party, tax_id: "1220222225")
    party4 = insert(:prm, :party, tax_id: "1220220225")
    party5 = insert(:prm, :party, tax_id: "1220220235")
    party6 = insert(:prm, :party, tax_id: "1220290235")
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
      employee_type: Employee.type(:owner),
      party: party4
    )
    employee3 = insert(:prm, :employee,
      legal_entity: legal_entity2,
      employee_type: Employee.type(:pharmacy_owner),
      party: party5
    )
    employee4 = insert(:prm, :employee,
      legal_entity: legal_entity2,
      employee_type: Employee.type(:pharmacy_owner),
      party: party6
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

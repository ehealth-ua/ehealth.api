defmodule EHealth.Integration.Grpc.Server.EmployeesTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.Grpc.Protobuf.Server.Employees
  alias EHealthProto.EmployeesRequest
  alias EHealthProto.EmployeesResponse
  alias EHealthProto.EmployeesResponse.Speciality
  alias GRPC.Server.Stream

  describe "employees_speciality/2" do
    test "invalid uuid" do
      assert %EmployeesResponse{employees: []} = Employees.employees_speciality(%EmployeesRequest{}, %Stream{})

      assert %EmployeesResponse{employees: []} =
               Employees.employees_speciality(%EmployeesRequest{party_id: "invalid"}, %Stream{})

      assert %EmployeesResponse{employees: []} =
               Employees.employees_speciality(%EmployeesRequest{legal_entity_id: "invalid"}, %Stream{})
    end

    test "success" do
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity: legal_entity)
      speciality = employee.speciality["speciality"]
      insert(:prm, :employee)

      assert %EmployeesResponse{
               employees: [
                 %EHealthProto.EmployeesResponse.Employee{
                   speciality: %Speciality{
                     speciality: ^speciality
                   }
                 }
               ]
             } =
               Employees.employees_speciality(
                 %EmployeesRequest{
                   party_id: employee.party_id,
                   legal_entity_id: employee.legal_entity_id
                 },
                 %Stream{}
               )
    end
  end
end

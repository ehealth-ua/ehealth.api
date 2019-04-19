defmodule Unit.LegalEntityDeactivationJobTest do
  @moduledoc false

  use Core.ConnCase, async: false
  import Mox
  alias Core.ContractRequests
  alias Core.ContractRequests.RequestPack
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Contracts
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias Core.Employees
  alias Core.Employees.Employee
  alias Jobs.LegalEntityDeactivationJob
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Ecto.UUID

  setup :verify_on_exit!

  @capitation CapitationContractRequest.type()
  @reimbursement ReimbursementContractRequest.type()

  describe "create" do
    test "successfully" do
      actor_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :employee, legal_entity: legal_entity)
      insert(:prm, :capitation_contract, contractor_legal_entity_id: legal_entity.id)
      insert(:prm, :reimbursement_contract, contractor_legal_entity_id: legal_entity.id)
      insert(:il, :capitation_contract_request, contractor_legal_entity_id: legal_entity.id)
      insert(:il, :reimbursement_contract_request, contractor_legal_entity_id: legal_entity.id)

      headers = [{"x-consumer-id", actor_id}]

      expect(RPCWorkerMock, :run, fn _, _, :create_job, [tasks, _type, _opts] ->
        assert 6 == length(tasks)

        Enum.each(tasks, fn %{name: name, callback: {_, m, f, a}} = task ->
          refute Map.has_key?(task, :__struct__)
          assert LegalEntityDeactivationJob = m
          assert :deactivate = f
          assert [entity, ^actor_id] = a

          assert name in [
                   "Deactivate contract",
                   "Deactivate contract request",
                   "Deactivate employee",
                   "Deactivate legal entity"
                 ]
        end)

        :ok
      end)

      assert :ok = LegalEntityDeactivationJob.create(legal_entity.id, headers)
    end
  end

  describe "legal entity deactivation job" do
    test "deactivates legal entity" do
      actor_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)

      assert LegalEntity.status(:active) == legal_entity.status
      refute actor_id == legal_entity.updated_by

      legal_entity_entity = %{
        schema: "legal_entity",
        entity: legal_entity
      }

      assert :ok == LegalEntityDeactivationJob.deactivate(legal_entity_entity, actor_id)

      legal_entity = LegalEntities.get_by_id(legal_entity.id)

      assert LegalEntity.status(:closed) == legal_entity.status
      assert actor_id == legal_entity.updated_by
    end

    test "deactivates employee" do
      actor_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity: legal_entity)

      assert Employee.status(:approved) == employee.status
      refute employee.status_reason
      refute actor_id == employee.updated_by

      employee_entity = %{
        schema: "employee",
        entity: employee
      }

      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      expect(KafkaMock, :publish_deactivate_declaration_event, fn _ -> :ok end)

      assert :ok == LegalEntityDeactivationJob.deactivate(employee_entity, actor_id)

      employee = Employees.get_by_id(employee.id)
      assert Employee.status(:dismissed) == employee.status
      assert employee.status_reason == "AUTO_DEACTIVATION_LEGAL_ENTITY"
      assert actor_id == employee.updated_by
    end

    test "deactivates capitation contract" do
      actor_id = UUID.generate()
      contract = insert(:prm, :capitation_contract)
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      assert CapitationContract.status(:verified) == contract.status
      refute actor_id == contract.updated_by

      contract_entity = %{
        schema: "contract",
        entity: contract
      }

      assert :ok == LegalEntityDeactivationJob.deactivate(contract_entity, actor_id)

      contract = Contracts.get_by_id(contract.id, @capitation)
      assert CapitationContract.status(:terminated) == contract.status
      assert actor_id == contract.updated_by
    end

    test "deactivates reimbursement contract" do
      actor_id = UUID.generate()
      contract = insert(:prm, :reimbursement_contract)
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      assert ReimbursementContract.status(:verified) == contract.status
      refute actor_id == contract.updated_by

      contract_entity = %{
        schema: "contract",
        entity: contract
      }

      assert :ok == LegalEntityDeactivationJob.deactivate(contract_entity, actor_id)

      contract = Contracts.get_by_id(contract.id, @reimbursement)
      assert ReimbursementContract.status(:terminated) == contract.status
      assert actor_id == contract.updated_by
    end

    test "deactivates capitation contract request" do
      actor_id = UUID.generate()
      contract_request = insert(:il, :capitation_contract_request)
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      assert CapitationContractRequest.status(:new) == contract_request.status
      refute actor_id == contract_request.updated_by

      contract_request_entity = %{
        schema: "contract_request",
        entity: contract_request
      }

      assert :ok == LegalEntityDeactivationJob.deactivate(contract_request_entity, actor_id)

      contract_request =
        contract_request
        |> Map.take([:id, :type])
        |> Jason.encode!()
        |> Jason.decode!()
        |> RequestPack.new()
        |> ContractRequests.get_by_id!()

      assert CapitationContractRequest.status(:terminated) == contract_request.status
      assert actor_id == contract_request.updated_by
    end

    test "deactivates reimbursement contract request" do
      actor_id = UUID.generate()
      contract_request = insert(:il, :reimbursement_contract_request)

      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)

      assert ReimbursementContractRequest.status(:new) == contract_request.status
      refute actor_id == contract_request.updated_by

      contract_request_entity = %{
        schema: "contract_request",
        entity: contract_request
      }

      assert :ok == LegalEntityDeactivationJob.deactivate(contract_request_entity, actor_id)

      contract_request =
        contract_request
        |> Map.take([:id, :type])
        |> Jason.encode!()
        |> Jason.decode!()
        |> RequestPack.new()
        |> ContractRequests.get_by_id!()

      assert ReimbursementContractRequest.status(:terminated) == contract_request.status
      assert actor_id == contract_request.updated_by
    end

    test "fails when we input invalid entity" do
      assert {:error, "Invalid entity"} == LegalEntityDeactivationJob.deactivate(%{}, UUID.generate())
    end

    test "fails when we input entity with invalid legal entity" do
      entity = %{
        schema: "legal_entity",
        entity: %LegalEntity{}
      }

      assert {:error, _} = LegalEntityDeactivationJob.deactivate(entity, UUID.generate())
    end
  end
end

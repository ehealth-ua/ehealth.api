defmodule Core.Unit.LegalEntityMergeJobTest do
  @moduledoc false

  use Core.ConnCase, async: false

  import Mox

  alias BSON.ObjectId
  alias Ecto.UUID
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.Jobs.LegalEntityMergeJob
  alias Core.LegalEntities
  alias TasKafka.Job
  alias TasKafka.Jobs

  @admin Employee.type(:admin)
  @owner Employee.type(:owner)

  @approved Employee.status(:approved)
  @dismissed Employee.status(:dismissed)

  describe "job processed" do
    test "with declaration termination" do
      consumer_id = UUID.generate()
      legal_entity_to = insert(:prm, :legal_entity)
      legal_entity_from = insert(:prm, :legal_entity)
      party = insert(:prm, :party)
      employee_dismissed = insert(:prm, :employee, legal_entity: legal_entity_from)
      employee_approved = insert(:prm, :employee, legal_entity: legal_entity_from, party: party)
      insert(:prm, :employee, legal_entity: legal_entity_to, party: party)
      employee_admin = insert(:prm, :employee, legal_entity: legal_entity_from, employee_type: @admin)
      employee_owner = insert(:prm, :employee, legal_entity: legal_entity_to, employee_type: @owner)

      set_mox_global()
      client_type_id = UUID.generate()
      System.put_env("CLIENT_TYPE_MSP_LIMITED_ID", client_type_id)

      expect(MithrilMock, :put_client, fn _client_id, params ->
        assert client_type_id == params.client_type_id
        {:ok, %{"data" => params}}
      end)

      expect(OPSMock, :terminate_employee_declarations, fn employee_id, user_id, reason, _description, _headers ->
        assert employee_dismissed.id == employee_id
        assert consumer_id == user_id
        assert "auto_reorganization" == reason

        {:ok, %{}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      {:ok, mongo_job} = Jobs.create(%{"some" => "meta"})
      job_id = ObjectId.encode!(mongo_job._id)

      job_data = %{
        job_id: job_id,
        reason: "test merge",
        headers: [{"x-consumer-id", consumer_id}],
        merged_from_legal_entity: %{
          id: legal_entity_from.id,
          name: legal_entity_from.name,
          edrpou: legal_entity_from.edrpou
        },
        merged_to_legal_entity: %{
          id: legal_entity_to.id,
          name: legal_entity_to.name,
          edrpou: legal_entity_to.edrpou
        },
        signed_content: "some-base-64-encoded-content"
      }

      job = struct(LegalEntityMergeJob, job_data)

      assert :ok = LegalEntityMergeJob.consume(job)

      # employee with type doctor dismissed
      assert @dismissed == Employees.get_by_id(employee_dismissed.id).status

      # approved employees
      assert @approved == Employees.get_by_id(employee_approved.id).status
      assert @approved == Employees.get_by_id(employee_owner.id).status
      assert @approved == Employees.get_by_id(employee_admin.id).status

      # mongo job successfully processed
      assert {:ok, mongo_job} = Jobs.get_by_id(job_id)
      assert Job.status(:processed) == mongo_job.status
      assert %{"related_legal_entity_id" => related_id} = mongo_job.result

      # related legal entity created
      related = LegalEntities.get_related_by(id: related_id)
      assert legal_entity_to.id == related.merged_to_id
      assert legal_entity_from.id == related.merged_from_id
    end

    test "without declaration termination" do
    end
  end

  describe "job failed" do
    test "cannot terminate declaration" do
    end

    test "cannot update client_type" do
    end

    test "cannot store signed content" do
    end
  end
end

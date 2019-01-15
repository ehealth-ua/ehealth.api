defmodule Unit.LegalEntityMergeJobTest do
  @moduledoc false

  use Core.ConnCase, async: false

  import Mox
  import Core.Expectations.Mithril

  alias BSON.ObjectId
  alias Ecto.UUID
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Jobs.LegalEntityMergeJob
  alias TasKafka.Job
  alias TasKafka.Jobs

  setup :set_mox_global
  setup :verify_on_exit!

  @admin Employee.type(:admin)
  @owner Employee.type(:owner)

  @approved Employee.status(:approved)
  @dismissed Employee.status(:dismissed)

  describe "job processed" do
    setup do
      consumer_id = UUID.generate()
      merged_to = insert(:prm, :legal_entity)
      merged_from = insert(:prm, :legal_entity)
      {:ok, %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id}}
    end

    test "with declaration termination", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      :ets.new(:related_legal_entity, [:named_table])
      party = insert(:prm, :party)
      party2 = insert(:prm, :party)

      # doctor not exist in merged_to legal entity
      employee_dismissed = insert(:prm, :employee, legal_entity: merged_from)

      # doctor with different speciality in merged_to and merged_from legal entity
      speciality = Map.put(speciality(), "speciality", "FAMILY DOCTOR")
      employee_dismissed2 = insert(:prm, :employee, legal_entity: merged_from, party: party)
      insert(:prm, :employee, legal_entity: merged_to, party: party, speciality: speciality)

      # doctor with different speciality in merged_to and merged_from legal entity
      employee_dismissed3 = insert(:prm, :employee, legal_entity: merged_from, party: party2)
      insert(:prm, :employee, legal_entity: merged_to, party: party2, speciality: speciality)

      # doctor with the same speciality exist in both legal entities
      speciality2 = Map.put(speciality(), "speciality", "THERAPIST")
      employee_approved = insert(:prm, :employee, legal_entity: merged_from, party: party2, speciality: speciality2)
      insert(:prm, :employee, legal_entity: merged_to, party: party2, speciality: speciality2)

      # employee type not a doctor
      employee_admin = insert(:prm, :employee, legal_entity: merged_from, employee_type: @admin)
      employee_owner = insert(:prm, :employee, legal_entity: merged_to, employee_type: @owner)

      client_type_id = UUID.generate()
      System.put_env("CLIENT_TYPE_MSP_LIMITED_ID", client_type_id)

      expect(MithrilMock, :put_client, fn %{"id" => _id} = params, _headers ->
        assert client_type_id == params["client_type_id"]
        {:ok, %{"data" => params}}
      end)

      deactivate_client_tokens()

      expect(KafkaMock, :publish_deactivate_declaration_event, 3, fn %{
                                                                       "employee_id" => employee_id,
                                                                       "actor_id" => actor_id,
                                                                       "reason" => reason
                                                                     } ->
        assert employee_id in [employee_dismissed.id, employee_dismissed2.id, employee_dismissed3.id]
        assert consumer_id == actor_id
        assert "auto_reorganization" == reason

        :ok
      end)

      expect(MediaStorageMock, :store_signed_content, fn signed_content, bucket, related_id, resource_name, _headers ->
        assert "some-base-64-encoded-content" == signed_content
        assert :related_legal_entity_bucket == bucket
        assert "merged_legal_entities" == resource_name
        assert related_id
        :ets.insert(:related_legal_entity, {:id, related_id})
        {:ok, "success"}
      end)

      {:ok, job_id, _} = create_job()

      assert_consume(merged_from, merged_to, job_id, consumer_id)

      # employee with type doctor dismissed
      assert @dismissed == Employees.get_by_id(employee_dismissed.id).status
      assert @dismissed == Employees.get_by_id(employee_dismissed2.id).status
      assert @dismissed == Employees.get_by_id(employee_dismissed3.id).status

      # approved employees
      assert @approved == Employees.get_by_id(employee_approved.id).status
      assert @approved == Employees.get_by_id(employee_owner.id).status
      assert @approved == Employees.get_by_id(employee_admin.id).status

      # mongo job successfully processed
      assert {:ok, mongo_job} = Jobs.get_by_id(job_id)
      assert Job.status(:processed) == mongo_job.status
      assert %{"related_legal_entity_id" => related_id} = mongo_job.result
      assert :ets.lookup(:related_legal_entity, :id)[:id] == related_id

      # related legal entity created
      related = LegalEntities.get_related_by(id: related_id)
      assert merged_to.id == related.merged_to_id
      assert merged_from.id == related.merged_from_id
    end

    test "without employees", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      put_client()
      deactivate_client_tokens()
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:ok, %{"success" => true}} end)
      {:ok, job_id, _} = create_job()

      assert_consume(merged_from, merged_to, job_id, consumer_id)

      # mongo job successfully processed
      assert {:ok, mongo_job} = Jobs.get_by_id(job_id)
      assert Job.status(:processed) == mongo_job.status
      assert %{"related_legal_entity_id" => related_id} = mongo_job.result

      # related legal entity created
      related = LegalEntities.get_related_by(id: related_id)
      assert merged_to.id == related.merged_to_id
      assert merged_from.id == related.merged_from_id
    end
  end

  describe "job failed" do
    setup do
      consumer_id = UUID.generate()
      merged_to = insert(:prm, :legal_entity)
      merged_from = insert(:prm, :legal_entity)
      {:ok, %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id}}
    end

    test "related legal entity exist", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:ok, %{"success" => true}} end)
      put_client()
      deactivate_client_tokens()
      insert(:prm, :related_legal_entity, merged_from: merged_from, merged_to: merged_to)
      {:ok, job_id, _} = create_job()

      assert_consume(merged_from, merged_to, job_id, consumer_id)

      assert {:ok, mongo_job} = Jobs.get_by_id(job_id)
      assert Job.status(:failed) == mongo_job.status
      assert %{"merged_to" => ["related legal entity already created"]} == mongo_job.result
    end

    test "cannot terminate declaration", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:ok, %{"success" => true}} end)

      expect(KafkaMock, :publish_deactivate_declaration_event, fn _ ->
        {:error, %{"data" => "Declaration does not exist"}}
      end)

      insert(:prm, :employee, legal_entity: merged_from)

      {:ok, job_id, _} = create_job()
      assert_consume(merged_from, merged_to, job_id, consumer_id)

      assert {:ok, mongo_job} = Jobs.get_by_id(job_id)
      assert Job.status(:failed) == mongo_job.status
      assert mongo_job.result =~ "Declaration does not exist"
    end

    test "cannot update client_type", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:ok, %{"success" => true}} end)
      expect(MithrilMock, :put_client, fn %{"id" => _id}, _headers -> {:error, %{"error" => "db connection"}} end)

      {:ok, job_id, _} = create_job()
      assert_consume(merged_from, merged_to, job_id, consumer_id)

      assert {:ok, mongo_job} = Jobs.get_by_id(job_id)
      assert Job.status(:failed) == mongo_job.status
      assert mongo_job.result =~ "Cannot update client type on Mithril for client"
    end

    test "cannot store signed content", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:error, %{"error_code" => 500}} end)

      {:ok, job_id, _} = create_job()
      assert_consume(merged_from, merged_to, job_id, consumer_id)

      assert {:ok, mongo_job} = Jobs.get_by_id(job_id)
      assert Job.status(:failed) == mongo_job.status
      assert mongo_job.result =~ "Failed to save signed content"
    end

    test "when raised an error", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      expect(MithrilMock, :put_client, fn %{"id" => _id}, _headers -> {:response_not_expected} end)
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:ok, %{"success" => true}} end)

      {:ok, job_id, _} = create_job()
      assert_consume(merged_from, merged_to, job_id, consumer_id)

      assert {:ok, mongo_job} = Jobs.get_by_id(job_id)
      assert Job.status(:failed) == mongo_job.status
      assert "raised an exception: %CaseClauseError{term: {:response_not_expected}}" == mongo_job.result
    end
  end

  defp create_job, do: create_job(%{"meta" => UUID.generate()})

  defp create_job(meta) do
    {:ok, job} = Jobs.create(meta)
    {:ok, ObjectId.encode!(job._id), job}
  end

  defp assert_consume(merged_from, merged_to, job_id, consumer_id) do
    %{
      job_id: job_id,
      reason: "test merge",
      headers: [{"x-consumer-id", consumer_id}],
      merged_from_legal_entity: %{
        id: merged_from.id,
        name: merged_from.name,
        edrpou: merged_from.edrpou
      },
      merged_to_legal_entity: %{
        id: merged_to.id,
        name: merged_to.name,
        edrpou: merged_to.edrpou
      },
      signed_content: "some-base-64-encoded-content"
    }
    |> assert_consume()
  end

  defp assert_consume(data),
    do:
      assert(
        :ok =
          LegalEntityMergeJob
          |> struct(data)
          |> LegalEntityMergeJob.consume()
      )
end

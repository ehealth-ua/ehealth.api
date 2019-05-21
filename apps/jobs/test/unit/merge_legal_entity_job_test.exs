defmodule Unit.LegalEntityMergeJobTest do
  @moduledoc false

  use Core.ConnCase, async: false

  import Mox
  import Core.Expectations.Mithril
  import Core.Expectations.Signature

  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.RelatedLegalEntities
  alias Ecto.UUID
  alias Jobs.Jabba.Task, as: JabbaTask
  alias Jobs.LegalEntityMergeJob

  setup :set_mox_global
  setup :verify_on_exit!

  @admin Employee.type(:admin)
  @owner Employee.type(:owner)

  @approved Employee.status(:approved)
  @dismissed Employee.status(:dismissed)

  @task_type JabbaTask.type(:merge_legal_entity)

  describe "create" do
    setup do
      merged_to = insert(:prm, :legal_entity)
      merged_from = insert(:prm, :legal_entity)

      legal_entity = insert(:prm, :legal_entity, edrpou: "100000001")
      party_user = insert(:prm, :party_user, party: build(:party, tax_id: "100000001"))

      context = %{
        merged_to: merged_to,
        merged_from: merged_from,
        client_id: legal_entity.id,
        party_user: party_user
      }

      {:ok, context}
    end

    test "successfully", context do
      expect(RPCWorkerMock, :run, fn _, _, :create_job, args ->
        {:ok, args}
      end)

      %{
        client_id: client_id,
        party_user: party_user,
        merged_to: merged_to,
        merged_from: merged_from
      } = context

      consumer_id = party_user.user_id

      content = content(merged_from, merged_to, "duplicated")
      drfo_signed_content(content, party_user.party.tax_id)

      signed_content = %{signed_content: %{content: "content", encoding: "base64"}}

      headers = [
        {"x-consumer-id", consumer_id},
        {"x-consumer-metadata", Jason.encode!(%{client_id: client_id})}
      ]

      assert {:ok, _} = LegalEntityMergeJob.create(signed_content, headers)
    end
  end

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

      expect(KafkaMock, :publish_to_event_manager, 3, fn _ -> :ok end)

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

      expect(MediaStorageMock, :store_signed_content, fn signed_content,
                                                         bucket,
                                                         related_le_id,
                                                         resource_name,
                                                         _headers ->
        assert "some-base-64-encoded-content" == signed_content
        assert :related_legal_entity_bucket == bucket
        assert "merged_legal_entities" == resource_name
        assert related_le_id
        :ets.insert(:related_legal_entity, {:id, related_le_id})
        {:ok, "success"}
      end)

      assert {:ok, %{related_legal_entity_id: related_id}} = emulate_jabba_callback(merged_from, merged_to, consumer_id)

      # employee with type doctor dismissed
      assert @dismissed == Employees.get_by_id(employee_dismissed.id).status
      assert @dismissed == Employees.get_by_id(employee_dismissed2.id).status
      assert @dismissed == Employees.get_by_id(employee_dismissed3.id).status

      assert "auto_reorganization" == Employees.get_by_id(employee_dismissed.id).status_reason
      assert "auto_reorganization" == Employees.get_by_id(employee_dismissed2.id).status_reason
      assert "auto_reorganization" == Employees.get_by_id(employee_dismissed3.id).status_reason

      # approved employees
      assert @approved == Employees.get_by_id(employee_approved.id).status
      assert @approved == Employees.get_by_id(employee_owner.id).status
      assert @approved == Employees.get_by_id(employee_admin.id).status

      assert related_id == :ets.lookup(:related_legal_entity, :id)[:id]

      # related legal entity created
      related = RelatedLegalEntities.get_related_by(id: related_id)
      assert merged_to.id == related.merged_to_id
      assert merged_from.id == related.merged_from_id
    end

    test "without employees", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      :ets.new(:related_legal_entity, [:named_table])
      put_client()
      deactivate_client_tokens()

      expect(MediaStorageMock, :store_signed_content, fn _, _, related_le_id, _, _ ->
        :ets.insert(:related_legal_entity, {:id, related_le_id})
        {:ok, %{"success" => true}}
      end)

      assert {:ok, %{related_legal_entity_id: related_id}} = emulate_jabba_callback(merged_from, merged_to, consumer_id)

      # related legal entity created
      assert related_id == :ets.lookup(:related_legal_entity, :id)[:id]
      related = RelatedLegalEntities.get_related_by(id: related_id)
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

      assert {:error, reason} = emulate_jabba_callback(merged_from, merged_to, consumer_id)
      assert %{merged_to: ["related legal entity already created"]} == reason
    end

    test "cannot terminate declaration", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:ok, %{"success" => true}} end)

      expect(KafkaMock, :publish_deactivate_declaration_event, fn _ ->
        {:error, %{"data" => "Declaration does not exist"}}
      end)

      insert(:prm, :employee, legal_entity: merged_from)

      assert {:error, reason} = emulate_jabba_callback(merged_from, merged_to, consumer_id)
      assert reason =~ "Declaration does not exist"
    end

    test "cannot update client_type", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:ok, %{"success" => true}} end)
      expect(MithrilMock, :put_client, fn %{"id" => _id}, _headers -> {:error, %{"error" => "db connection"}} end)

      assert {:error, reason} = emulate_jabba_callback(merged_from, merged_to, consumer_id)
      assert reason =~ "Cannot update client type on Mithril for client"
    end

    test "cannot store signed content", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:error, %{"error_code" => 500}} end)

      assert {:error, reason} = emulate_jabba_callback(merged_from, merged_to, consumer_id)
      assert reason =~ "Failed to save signed content"
    end

    test "when raised an error", %{merged_to: merged_to, merged_from: merged_from, consumer_id: consumer_id} do
      expect(MithrilMock, :put_client, fn %{"id" => _id}, _headers -> {:response_not_expected} end)
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ -> {:ok, %{"success" => true}} end)

      assert {:error, reason} = emulate_jabba_callback(merged_from, merged_to, consumer_id)
      assert %CaseClauseError{term: {:response_not_expected}} == reason
    end
  end

  defp emulate_jabba_callback(merged_from, merged_to, consumer_id) do
    arg = %{
      reason: "duplicated",
      headers: [{"x-consumer-id", consumer_id}],
      merged_from_legal_entity: merged_from,
      merged_to_legal_entity: merged_to,
      signed_content: "some-base-64-encoded-content"
    }

    task = JabbaTask.new(@task_type, arg)
    emulate_jabba_callback(task)
  end

  defp emulate_jabba_callback(%JabbaTask{callback: {_, m, f, a}}), do: apply(m, f, a)

  defp content(merged_from, merged_to, reason) do
    %{
      "reason" => reason,
      "merged_from_legal_entity" => %{
        "id" => merged_from.id,
        "name" => merged_from.name,
        "edrpou" => merged_from.edrpou
      },
      "merged_to_legal_entity" => %{
        "id" => merged_to.id,
        "name" => merged_to.name,
        "edrpou" => merged_to.edrpou
      }
    }
  end
end

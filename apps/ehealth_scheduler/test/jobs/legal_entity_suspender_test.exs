defmodule EHealthScheduler.Jobs.LegalEntitySuspenderTest do
  @moduledoc false

  use Core.ConnCase
  import Ecto.Query

  alias Core.Contracts.CapitationContract
  alias Core.LegalEntities.LegalEntity
  alias EHealthScheduler.Jobs.LegalEntitySuspender
  alias Core.PRMRepo

  test "run/0" do
    now = DateTime.utc_now()

    legal_entity_1 = insert(:prm, :legal_entity, status: LegalEntity.status(:closed))

    legal_entity_2 =
      insert(:prm, :legal_entity, status: LegalEntity.status(:active), nhs_verified: true, nhs_unverified_at: nil)

    legal_entity_3 =
      insert(:prm, :legal_entity,
        status: LegalEntity.status(:active),
        nhs_verified: false,
        nhs_unverified_at: DateTime.add(now, -1 * 60 * 60 * 24, :second)
      )

    contract_3_1 = insert(:prm, :capitation_contract, contractor_legal_entity: legal_entity_3)

    legal_entity_4 =
      insert(:prm, :legal_entity,
        status: LegalEntity.status(:active),
        nhs_verified: false,
        nhs_unverified_at: DateTime.add(now, -11 * 60 * 60 * 24, :second)
      )

    contract_4_1 =
      insert(:prm, :capitation_contract,
        contractor_legal_entity: legal_entity_4,
        status: CapitationContract.status(:verified),
        is_suspended: false
      )

    contract_4_2 =
      insert(:prm, :capitation_contract,
        contractor_legal_entity: legal_entity_4,
        status: CapitationContract.status(:terminated)
      )

    LegalEntitySuspender.run()

    updated_entities = [{:legal_entity, [legal_entity_4.id]}, {:contract, [contract_4_1.id]}]

    not_updated_entities = [
      {:legal_entity, [legal_entity_1.id, legal_entity_2.id, legal_entity_3.id]},
      {:contract, [contract_3_1.id, contract_4_2.id]}
    ]

    check_entities(:assert, updated_entities)
    check_entities(:refute, not_updated_entities)
  end

  defp check_entities(assertion_type, entities) do
    Enum.map(entities, &do_check_entities(assertion_type, &1))
  end

  defp do_check_entities(assertion_type, {entity_type, entity_ids}) do
    entity_ids
    |> get_entities(entity_type)
    |> assert_entities(entity_type, assertion_type)
  end

  defp get_entities(entity_ids, :legal_entity) do
    LegalEntity
    |> select([e], %{status: e.status, status_reason: e.status_reason})
    |> where([e], e.id in ^entity_ids)
    |> PRMRepo.all()
  end

  defp get_entities(entity_ids, :contract) do
    CapitationContract
    |> select([e], %{is_suspended: e.is_suspended})
    |> where([e], e.id in ^entity_ids)
    |> PRMRepo.all()
  end

  defp assert_entities(entities, :legal_entity, :assert) do
    Enum.each(entities, fn %{status: status, status_reason: status_reason} ->
      assert status == LegalEntity.status(:suspended)
      assert status_reason == "AUTO_SUSPEND"
    end)
  end

  defp assert_entities(entities, :legal_entity, :refute) do
    Enum.each(entities, fn %{status: status, status_reason: status_reason} ->
      refute status == LegalEntity.status(:suspended)
      refute status_reason == "AUTO_SUSPEND"
    end)
  end

  defp assert_entities(entities, :contract, :assert) do
    Enum.each(entities, fn %{is_suspended: is_suspended} ->
      assert is_suspended
    end)
  end

  defp assert_entities(entities, :contract, :refute) do
    Enum.each(entities, fn %{is_suspended: is_suspended} ->
      refute is_suspended
    end)
  end
end

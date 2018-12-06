defmodule GraphQL.Unit.FilteringHelperTest do
  @moduledoc false

  use Core.ConnCase, async: false

  import Core.Factories, only: [insert: 3, insert_list: 3]
  import GraphQL.Helpers.Filtering, only: [filter: 2]

  alias Core.Divisions.Division
  alias Core.LegalEntities.LegalEntity
  alias Core.Contracts.CapitationContract
  alias Core.PRMRepo

  @division_status_active Division.status(:active)

  @legal_entity_type_mis LegalEntity.type(:mis)
  @legal_entity_type_msp LegalEntity.type(:msp)
  @legal_entity_type_nhs LegalEntity.type(:nhs)

  describe "fields" do
    test "with empty condition" do
      insert_list(2, :prm, :legal_entity)

      results = do_filter(LegalEntity, [])

      assert 2 = length(results)
    end

    test "with equal condition" do
      legal_entities =
        for type <- [@legal_entity_type_msp, @legal_entity_type_nhs] do
          insert(:prm, :legal_entity, type: type)
        end

      expected_result = hd(legal_entities)

      condition = [{:type, :equal, @legal_entity_type_msp}]

      results = do_filter(LegalEntity, condition)

      assert 1 = length(results)
      assert expected_result.id == hd(results).id
    end

    test "with like condition" do
      legal_entities = for name <- ~w(Healthy Happy), do: insert(:prm, :legal_entity, name: "#{name} clinic")
      expected_result = hd(legal_entities)

      condition = [{:name, :like, "health"}]

      results = do_filter(LegalEntity, condition)

      assert 1 = length(results)
      assert expected_result.id == hd(results).id
    end

    test "with in array condition" do
      legal_entities =
        for type <- [@legal_entity_type_msp, @legal_entity_type_nhs] do
          insert(:prm, :legal_entity, type: type)
        end

      expected_result = hd(legal_entities)

      condition = [{:type, :in, [@legal_entity_type_msp, @legal_entity_type_mis]}]

      results = do_filter(LegalEntity, condition)

      assert 1 = length(results)
      assert expected_result.id == hd(results).id
    end

    test "with in date interval condition" do
      capitation_contracts =
        for start_date <- ~w(2017-01-23 2018-09-12) do
          insert(:prm, :capitation_contract, start_date: Date.from_iso8601!(start_date))
        end

      expected_result = hd(capitation_contracts)

      condition = [{:start_date, :in, Date.Interval.from_edtf!("2016-12-01/2017-02-01")}]

      results = do_filter(CapitationContract, condition)

      assert 1 = length(results)
      assert expected_result.id == hd(results).id
    end

    test "with array contains condition" do
      legal_entities = for kveds <- [~w(11.11 22.22), ~w(33.33. 44.44)], do: insert(:prm, :legal_entity, kveds: kveds)
      expected_result = hd(legal_entities)

      condition = [{:kveds, :contains, "11.11"}]

      results = do_filter(LegalEntity, condition)

      assert 1 = length(results)
      assert expected_result.id == hd(results).id
    end
  end

  describe "associations" do
    test "with one cardinality" do
      legal_entities =
        for type <- [@legal_entity_type_msp, @legal_entity_type_mis] do
          insert(:prm, :legal_entity, type: type)
        end

      divisions =
        for legal_entity <- legal_entities do
          insert(:prm, :division, status: @division_status_active, legal_entity: legal_entity)
        end

      expected_result = hd(divisions)

      condition = [
        {:status, :equal, @division_status_active},
        {:legal_entity, nil, [{:type, :equal, @legal_entity_type_msp}]}
      ]

      results = do_filter(Division, condition)

      assert 1 = length(results)
      assert expected_result.id == hd(results).id
    end
  end

  describe "embedded" do
    test "with equal condition in array of maps" do
      legal_entities =
        for [first, second] <- Enum.chunk_every(~w(Київ Запоріжжя Івано-Франківськ Маріуполь), 2) do
          insert(:prm, :legal_entity, addresses: [%{settlement: first}, %{settlement: second}])
        end

      expected_result = hd(legal_entities)

      condition = [{:addresses, nil, [{:settlement, :equal, "Київ"}]}]

      results = do_filter(LegalEntity, condition)

      assert 1 = length(results)
      assert expected_result.id == hd(results).id
    end

    @tag :pending
    test "with like condition in array of maps" do
      legal_entities =
        for [first, second] <- Enum.chunk_every(~w(Київ Запоріжжя Івано-Франківськ Маріуполь), 2) do
          insert(:prm, :legal_entity, addresses: [%{settlement: first}, %{settlement: second}])
        end

      expected_result = hd(legal_entities)

      condition = [{:addresses, nil, [{:settlement, :like, "Київ"}]}]

      results = do_filter(LegalEntity, condition)

      assert 1 = length(results)
      assert expected_result.id == hd(results).id
    end
  end

  defp do_filter(repo \\ PRMRepo, queryable, condition) do
    queryable
    |> filter(condition)
    |> repo.all()
  end
end

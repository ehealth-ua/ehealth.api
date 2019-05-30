defmodule Core.Factories.JobFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID
      alias Jobs.Jabba.Client, as: JabbaClient

      def legal_entity_merge_job_factory do
        job_id = UUID.generate()
        merged_to = build(:legal_entity)
        merged_from = build(:legal_entity)

        %{
          id: job_id,
          name: sequence("Some job "),
          type: JabbaClient.type(:merge_legal_entities),
          status: "PENDING",
          strategy: "SEQUENTIALLY",
          meta: %{
            "merged_to_legal_entity" => %{
              "id" => merged_to.id,
              "name" => merged_to.name,
              "edrpou" => merged_to.edrpou
            },
            "merged_from_legal_entity" => %{
              "id" => merged_from.id,
              "name" => merged_from.name,
              "edrpou" => merged_from.edrpou
            }
          },
          inserted_at: DateTime.utc_now(),
          ended_at: nil
        }
      end

      def legal_entity_deactivation_job_factory() do
        job_id = UUID.generate()
        legal_entity = build(:legal_entity)

        %{
          id: job_id,
          name: sequence("Some job "),
          type: JabbaClient.type(:legal_entity_deactivation),
          status: "PENDING",
          strategy: "SEQUENTIALLY",
          meta: %{
            "deactivated_legal_entity" => %{
              "id" => legal_entity.id,
              "name" => legal_entity.name,
              "edrpou" => legal_entity.edrpou
            }
          },
          inserted_at: DateTime.utc_now(),
          ended_at: nil
        }
      end

      def job_task_factory do
        %{
          id: UUID.generate(),
          name: sequence("Some task "),
          status: "NEW",
          priority: 0,
          callback: {"test", TestRPC, :run, []},
          result: %{},
          job: %{},
          job_id: UUID.generate(),
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now(),
          ended_at: nil
        }
      end
    end
  end
end

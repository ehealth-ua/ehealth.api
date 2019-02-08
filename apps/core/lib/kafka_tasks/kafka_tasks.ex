defmodule Core.KafkaTasks do
  @moduledoc false

  if Code.ensure_loaded?(KafkaEx) do
    alias KafkaEx.Protocol.CreateTopics.Response
    alias KafkaEx.Protocol.CreateTopics.TopicError
    require Logger

    @topics [
      %{
        topic: "deactivate_legal_entity_event",
        num_partitions: 1,
        replication_factor: 3,
        replica_assignment: [],
        config_entries: []
      },
      %{
        topic: "merge_legal_entities",
        num_partitions: 1,
        replication_factor: 3,
        replica_assignment: [],
        config_entries: []
      }
    ]

    def migrate do
      Application.ensure_all_started(:kafka_ex)
      %{topic_metadatas: topic_metadatas} = KafkaEx.metadata()

      topics = Enum.map(topic_metadatas, fn topic_metadata -> topic_metadata.topic end)
      Enum.each(@topics, fn topic -> create_topic(topic, topics) end)

      System.halt(0)
      :init.stop()
    end

    defp create_topic(topic_data, topics) do
      with nil <- Enum.find(topics, fn topic -> topic == topic_data.topic end) do
        case KafkaEx.create_topics([topic_data], timeout: 2000) do
          %Response{topic_errors: [%TopicError{error_code: :no_error, topic_name: topic_name}]} ->
            Logger.info("Topic #{topic_name} was successfully created")

          %Response{topic_errors: [%TopicError{error_code: error_code, topic_name: topic_name}]} ->
            Logger.error("Error creating topic #{topic_name}. Error code: #{error_code}")

          _ ->
            Logger.error("Error creating topic #{topic_data.topic}")
        end
      end
    end
  end
end

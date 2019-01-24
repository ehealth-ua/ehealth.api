defmodule Jobs do
  @moduledoc """
  Kafka Jobs entry
  """

  alias BSON.ObjectId
  alias Core.Utils.TypesConverter
  alias TasKafka.Job
  alias TasKafka.Jobs

  @merge_legal_entities_type 200
  @legal_entity_deactivation_type 300

  def type(:merge_legal_entities), do: @merge_legal_entities_type
  def type(:legal_entity_deactivation), do: @legal_entity_deactivation_type

  def prepare_mongo_filter({:status, value}, acc) do
    status =
      value
      |> String.to_atom()
      |> Job.status()

    Map.put(acc, "status", status)
  end

  def prepare_mongo_filter({key, filters}, acc)
      when key in [:merged_to_legal_entity, :merged_from_legal_entity, :deactivated_legal_entity] do
    Enum.reduce(filters, acc, fn {filter, value}, acc ->
      Map.put(acc, "meta.#{key}.#{filter}", value)
    end)
  end

  defp prepare_order_by([]), do: nil
  defp prepare_order_by([{:asc, field}]), do: %{Atom.to_string(field) => 1}
  defp prepare_order_by([{:desc, field}]), do: %{Atom.to_string(field) => -1}

  def list(filter, limit, offset, order_by, type) do
    opts = [limit: limit + 1, skip: offset, sort: prepare_order_by(order_by)]

    filter
    |> Enum.reduce(%{}, &prepare_mongo_filter/2)
    |> Map.put("type", type)
    |> Jobs.get_list(opts)
  end

  def get_by_id(id), do: Jobs.get_by_id(id)

  def view(%Job{} = job, meta_keys) do
    meta =
      job
      |> Map.get(:meta)
      |> TypesConverter.strings_to_keys()
      |> Map.take(meta_keys)

    Map.merge(
      %{
        id: ObjectId.encode!(job._id),
        status: Job.status_to_string(job.status),
        result: Jason.encode!(job.result),
        started_at: job.started_at,
        ended_at: job.ended_at
      },
      meta
    )
  end
end

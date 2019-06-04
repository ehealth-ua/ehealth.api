defmodule Jobs.Jabba.Client do
  @moduledoc """
  RPC client for job manager Jabba
  """

  alias Core.Utils.TypesConverter
  alias Jobs.Jabba.Task, as: JabbaTask

  @pod "jabba-rpc"
  @rpc_worker Application.get_env(:core, :rpc_worker)

  @merge_legal_entities_type "merge_legal_entities"
  @legal_entity_deactivation_type "legal_entity_deactivation"
  @contract_request_termination_type "contract_request_termination"
  @edr_synchronize_type "edr_synchronization"

  def rpc_pod_name, do: @pod

  def type(:merge_legal_entities), do: @merge_legal_entities_type
  def type(:legal_entity_deactivation), do: @legal_entity_deactivation_type
  def type(:contract_request_termination), do: @contract_request_termination_type
  def type(:edr_synchronize), do: @edr_synchronize_type

  def create_job(tasks, type, opts \\ []) when is_list(tasks) and is_binary(type) and is_list(opts) do
    with {:ok, prepared_tasks} <- prepare_tasks(tasks) do
      @rpc_worker.run(@pod, Jabba.RPC, :create_job, [prepared_tasks, type, opts])
    end
  end

  defp prepare_tasks(tasks) do
    Enum.reduce_while(tasks, {:ok, []}, fn task, acc ->
      case task?(task) do
        true -> {:cont, {:ok, elem(acc, 1) ++ [Map.from_struct(task)]}}
        _ -> {:halt, {:error, "All items in tasks list must be a Task struct"}}
      end
    end)
  end

  defp task?(%{__struct__: JabbaTask}), do: true
  defp task?(_), do: false

  def get_job(job_id) when is_binary(job_id) do
    @pod
    |> @rpc_worker.run(Jabba.RPC, :get_job, [job_id])
    |> render()
  end

  def search_jobs(filter \\ [], order_by \\ [], cursor \\ nil) do
    @pod
    |> @rpc_worker.run(Jabba.RPC, :search_jobs, [filter, order_by, cursor])
    |> render()
  end

  defp render({:ok, job}), do: {:ok, render(job)}

  defp render(jobs) when is_list(jobs), do: Enum.map(jobs, &render/1)

  defp render(job) when is_map(job) do
    meta =
      job
      |> Map.get(:meta)
      |> TypesConverter.strings_to_keys()

    # put meta fields to root, as defined in GraphQL schema
    job = Map.merge(job, meta)

    # ToDo: use inserted_at instead
    Map.put(job, :started_at, job.inserted_at)
  end

  defp render(response), do: response
end

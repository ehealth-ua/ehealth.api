defmodule Core.Validators.Content do
  @moduledoc """
  Provides content validation by comparison request body param with restored data from data storage.
  Usually a recovered data is received after the rendering.
  """

  require Logger

  alias Core.ValidationError
  alias Core.Validators.Error

  @doc """
  Compares connent from two sources:
    - content from request param
    - restored data (ussually got by rendering)
    - third argument is a name of a process used in error logging
  """
  @spec compare_with_db(map, map, binary) :: :ok | {:error, term}
  def compare_with_db(content, db_content, process_name) do
    case db_content == content do
      true ->
        :ok

      _ ->
        mismatches = do_compare_with_db(db_content, content)

        Logger.info(fn ->
          Jason.encode!(%{
            "log_type" => "debug",
            "process" => process_name,
            "details" => %{
              "mismatches" => mismatches
            },
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

        Error.dump(%ValidationError{
          description: "Signed content does not match the previously created content",
          path: "$.content"
        })
    end
  end

  defp do_compare_with_db(db_content, content) do
    Enum.reduce(Map.keys(db_content), [], fn key, acc ->
      v1 = Map.get(db_content, key)
      v2 = Map.get(content, key)

      if v1 != v2 do
        [%{"db_content.#{key}" => v1, "data.#{key}" => v2} | acc]
      else
        acc
      end
    end)
  end
end

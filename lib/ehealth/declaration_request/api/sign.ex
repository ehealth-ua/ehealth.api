defmodule EHealth.DeclarationRequest.API.Sign do
  @moduledoc false

  import EHealth.Utils.Connection

  alias EHealth.API.MediaStorage
  alias EHealth.API.MPI
  alias EHealth.API.OPS
  alias EHealth.DeclarationRequest
  alias EHealth.DeclarationRequest.API

  require Logger

  def check_status({:ok, pipe_data}, input) do
    db_data =
      input
      |> Map.fetch!("id")
      |> API.get_declaration_request_by_id!()

    case Map.get(db_data, :status) do
      "APPROVED" -> {:ok, pipe_data, db_data}
      _ -> {:error, [{%{description: "incorrect status", params: [], rule: :invalid}, "$.status"}]}
    end
  end
  def check_status(err, _input), do: err

  def compare_with_db({:ok, %{"data" => %{"content" => content}}, %DeclarationRequest{data: data} = db_data}) do
    data = Map.update!(data, "person", fn(map) -> Map.delete(map, "patient_signed") end)
    input = Map.update!(content, "person", fn(map) -> Map.delete(map, "patient_signed") end)
    case input == data do
      true -> {:ok, {content, db_data}}
      _ -> {:error, [{%{description: "Signed content does not match the previously created content",
        params: [], rule: :invalid}, "$.content"}]}
    end
  end
  def compare_with_db(err), do: err

  def store_signed_content({:ok, data}, input, headers) do
    input
    |> Map.fetch!("signed_declaration_request")
    |> MediaStorage.store_signed_content(:declaration_request_bucket, Map.fetch!(input, "id"), headers)
    |> validate_api_response(data)
  end
  def store_signed_content(err, _input, _headers), do: err

  def create_or_update_person({:ok, {content, db_data}}, headers) do
    result =
      content
      |> Map.fetch!("person")
      |> MPI.create_or_update_person(headers)

    case result do
      {:ok, data} -> {:ok, data, db_data}
      err -> err
    end
  end
  def create_or_update_person(err, _headers), do: err

  def create_declaration_with_termination_logic({:ok, %{"data" => %{"id" => person_id}},
    %DeclarationRequest{data: data, authentication_method_current: authentication_method_current}}, headers) do
    client_id = get_client_id(headers)
    data
    |> Map.take(["start_date", "end_date", "scope"])
    |> Map.put("employee_id", get_in(data, ["employee", "id"]))
    |> Map.put("division_id", get_in(data, ["division", "id"]))
    |> Map.put("legal_entity_id", get_in(data, ["legal_entity", "id"]))
    |> Map.put("person_id", person_id)
    |> Map.put("status", get_status(authentication_method_current))
    |> Map.put("is_active", true)
    |> Map.put("created_by", client_id)
    |> Map.put("updated_by", client_id)
    |> Map.put("signed_at", Timex.now())
    |> OPS.create_declaration_with_termination_logic(headers)
  end
  def create_declaration_with_termination_logic(err, _headers), do: err

  def update_declaration_request_status({:ok, declaration_response}, input) do
    update_result =
      input
      |> Map.fetch!("id")
      |> API.update_status("SIGNED")

    declaration_data =
      declaration_response
      |> Map.get("data")
      |> Map.drop(["updated_by", "updated_at", "created_by"])

    case update_result do
      {:ok, _data} -> {:ok, declaration_data}
      err -> err
    end
  end
  def update_declaration_request_status(err, _input), do: err

  defp get_status(%{"type" => "OFFLINE"}), do: "pending_verification"
  defp get_status(%{"type" => "OTP"}), do: "active"
  defp get_status(_) do
    Logger.error(fn -> "Unknown authentication_method_current.type" end)
    ""
  end

  defp validate_api_response({:ok, _}, db_data), do: {:ok, db_data}
  defp validate_api_response(error, _db_data), do: error
end

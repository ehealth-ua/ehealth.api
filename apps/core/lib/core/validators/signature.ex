defmodule Core.Validators.Signature do
  @moduledoc false

  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.Parties
  alias Core.Parties.Party
  alias Core.ValidationError
  alias Core.Validators.Error

  require Logger

  @signature_api Application.get_env(:core, :api_resolvers)[:digital_signature]

  def validate(signed_content, encoding, headers, required_signatures_count \\ 1, required_stamps_count \\ 0) do
    with {:ok, %{"data" => data}} <- @signature_api.decode_and_validate(signed_content, encoding, headers) do
      process_data(data, required_signatures_count, required_stamps_count)
    end
  end

  def check_drfo(%{"drfo" => drfo}, user_id, process) when not is_nil(drfo) do
    drfo = String.replace(drfo, " ", "")

    with %Party{tax_id: tax_id} <- Parties.get_by_user_id(user_id) do
      log_drfo(drfo, tax_id, process)

      if tax_id == drfo || translit_drfo(tax_id) == translit_drfo(drfo) do
        :ok
      else
        Error.dump("Does not match the signer drfo")
      end
    else
      _ -> {:error, {:forbidden, "User is not allowed to this action by client_id"}}
    end
  end

  def check_drfo(_, _, _), do: Error.dump("Invalid drfo")

  def check_drfo(%{"drfo" => drfo}, employee_id, path, process) when not is_nil(drfo) do
    drfo = String.replace(drfo, " ", "")

    with %Employee{party_id: party_id} <- Employees.get_by_id(employee_id),
         %Party{tax_id: tax_id} <- Parties.get_by_id(party_id),
         log_drfo(drfo, tax_id, process),
         true <- tax_id == drfo || translit_drfo(tax_id) == translit_drfo(drfo) do
      :ok
    else
      _ ->
        Error.dump(%ValidationError{description: "Does not match the signer drfo", path: path})
    end
  end

  def check_drfo(_, _, path, _) do
    Error.dump(%ValidationError{description: "Invalid drfo", path: path})
  end

  defp translit_drfo(drfo) do
    drfo
    |> Translit.translit()
    |> String.upcase()
  end

  defp log_drfo(drfo, tax_id, process) do
    Logger.info("Process: #{process}, drfo: #{drfo}, tax_id: #{tax_id}")
  end

  def check_last_name(%{"surname" => surname}, user_id) do
    with %Party{last_name: last_name} <- Parties.get_by_user_id(user_id) do
      if String.upcase(surname) == String.upcase(last_name) do
        :ok
      else
        Error.dump("Does not match the signer last name")
      end
    else
      _ -> {:error, {:forbidden, "User is not allowed to this action by client_id"}}
    end
  end

  def check_last_name(_, _), do: Error.dump("Invalid surname")

  defp process_data(
         %{"content" => content, "signatures" => signatures},
         required_signatures_count,
         required_stamps_count
       )
       when is_list(signatures) do
    {existing_stamps, existing_signatures} = Enum.split_with(signatures, &Map.get(&1, "is_stamp"))

    existing_signatures_count = Enum.count(existing_signatures)
    existing_stamps_count = Enum.count(existing_stamps)

    if existing_signatures_count == required_signatures_count && existing_stamps_count == required_stamps_count do
      invalid_signature = Enum.find(signatures, &(!Map.get(&1, "is_valid")))
      # return the last signature and stamp (they are in reverse order)
      prepare_data(
        content,
        invalid_signature,
        Enum.take(existing_signatures, required_signatures_count),
        Enum.take(existing_stamps, existing_stamps_count)
      )
    else
      {:error,
       {:bad_request,
        get_signatures_count_error(
          required_signatures_count,
          existing_signatures_count,
          required_stamps_count,
          existing_stamps_count
        )}}
    end
  end

  defp get_signatures_count_error(
         required_signatures_count,
         existing_signatures_count,
         required_stamps_count,
         existing_stamps_count
       ) do
    "document must contain #{get_count_phrase("signature", required_signatures_count)} and #{
      get_count_phrase("stamp", required_stamps_count)
    } but contains #{get_count_phrase("signature", existing_signatures_count)} and #{
      get_count_phrase("stamp", existing_stamps_count)
    }"
  end

  defp get_count_phrase(word, count), do: "#{count} #{word}#{if count == 1, do: "", else: "s"}"

  defp prepare_data(content, nil, signatures, stamps) do
    {:ok,
     %{
       "content" => content,
       "signers" => Enum.map(signatures, fn signature -> Map.get(signature || %{}, "signer") end),
       "stamps" => Enum.map(stamps, fn stamp -> Map.get(stamp || %{}, "signer") end)
     }}
  end

  defp prepare_data(_, %{"is_valid" => false, "validation_error_message" => error}, _, _),
    do: {:error, {:bad_request, error}}
end

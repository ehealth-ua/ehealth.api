defmodule Casher.Rpc do
  @moduledoc """
  This module contains functions that are called from other pods via RPC.
  """

  alias Casher.PersonData
  require Logger

  @type successfull_person_data() :: {:ok, %{person_ids: list(binary)}}

  @doc """
  Get person ids by user_id, client_id or employee_id

  Available parameters:

  | Parameter    | Type             | Example                                              | Description                                        |
  | :----------: | :--------------: | :--------------------------------------------------: |:-------------------------------------------------: |
  | user_id      | `binary`         | "0187d6ee-7b2e-4497-acfb-f1ee64f23ccc"               |                                                    |
  | client_id    | `binary`         | "341d22ef-c667-44fb-ae41-705fa5017875"               |                                                    |
  | employee_id  | `binary`         | "1d88ed7a-747a-4cbf-95cd-2ced81e55092"               |                                                    |

  Returns `{:ok, %{person_ids: list(binary)}}`.

  ## Examples

      iex> Casher.Rpc.get_person_data(%{"user_id" => "0187d6ee-7b2e-4497-acfb-f1ee64f23ccc", "client_id" => "341d22ef-c667-44fb-ae41-705fa5017875"})
      {:ok, %{person_ids: ["bc0689e2-dcd0-4333-b9a0-47dbb53c93df"]}}

      iex> Casher.Rpc.get_person_data(%{"employee_id" => "1d88ed7a-747a-4cbf-95cd-2ced81e55092"})
      {:ok, %{person_ids: ["bc0689e2-dcd0-4333-b9a0-47dbb53c93df"]}}

      iex> Casher.Rpc.get_person_data(%{})
      nil
  """

  @spec get_person_data(params :: map()) :: nil | successfull_person_data
  def get_person_data(%{"user_id" => user_id, "client_id" => client_id}) do
    with {:ok, person_ids} <- PersonData.get_and_update(%{user_id: user_id, client_id: client_id}) do
      {:ok, %{person_ids: person_ids}}
    else
      error ->
        Logger.warn(inspect(error))
        nil
    end
  end

  def get_person_data(%{"employee_id" => employee_id}) do
    with {:ok, person_ids} <- PersonData.get_and_update(%{employee_id: employee_id}) do
      {:ok, %{person_ids: person_ids}}
    else
      error ->
        Logger.warn(inspect(error))
        nil
    end
  end

  def get_person_data(_), do: nil
end

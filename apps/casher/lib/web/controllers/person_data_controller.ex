defmodule Casher.Web.PersonDataController do
  @moduledoc false

  use Casher.Web, :controller

  alias Casher.PersonData

  action_fallback(Casher.Web.FallbackController)

  @spec get_person_data(Plug.Conn.t(), map) :: Plug.Conn.t()
  def get_person_data(conn, %{"user_id" => user_id, "client_id" => client_id}) do
    with {:ok, person_ids} <- PersonData.get_and_update(%{user_id: user_id, client_id: client_id}) do
      json(conn, %{person_ids: person_ids})
    end
  end

  def get_person_data(conn, %{"employee_id" => employee_id}) do
    with {:ok, person_ids} <- PersonData.get_and_update(%{employee_id: employee_id}) do
      json(conn, %{person_ids: person_ids})
    end
  end

  def get_person_data(_, _), do: {:error, {:"422", "Missed required parameters: (user_id, clinet_id) or employee_id"}}

  @spec update_person_data(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update_person_data(conn, %{"user_id" => user_id, "client_id" => client_id}) do
    with {:ok, _person_ids} <- PersonData.get_and_update(%{user_id: user_id, client_id: client_id}) do
      json(conn, %{})
    end
  end

  def update_person_data(conn, %{"employee_id" => employee_id}) do
    with {:ok, _person_ids} <- PersonData.get_and_update(%{employee_id: employee_id}) do
      json(conn, %{})
    end
  end

  def update_person_data(_, _),
    do: {:error, {:"422", "Missed required parameters: (user_id, clinet_id) or employee_id"}}
end

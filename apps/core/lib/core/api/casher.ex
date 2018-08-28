defmodule Core.API.Casher do
  @moduledoc false

  use Core.API.Helpers.MicroserviceBase

  @behaviour Core.API.CasherBehaviour

  @doc "params: user_id, client_id or employee_id"
  def get_person_data(params, headers \\ []) do
    get!("/api/person_data", headers, params: params)
  end

  @doc "params: user_id, client_id or employee_id"
  def update_person_data(params, headers \\ []) do
    patch!("/api/person_data", Jason.encode!(params), headers)
  end
end

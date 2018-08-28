defmodule Core.API.CasherBehaviour do
  @moduledoc false

  @typep person_data_params :: %{employee_id: binary} | %{user_id: binary, client_id: binary}

  @callback get_person_data(params :: person_data_params, headers :: list) :: {:ok, term} | {:error, term}
  @callback update_person_data(params :: person_data_params, headers :: list) :: {:ok, term} | {:error, term}
end

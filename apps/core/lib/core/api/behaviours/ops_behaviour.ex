defmodule Core.API.OPSBehaviour do
  @moduledoc false

  @callback get_declaration_by_id(id :: binary, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_declarations(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_person_ids(list, list) :: {:ok, map} | {:error, term}

  @callback get_declarations_count(ids :: list, headers :: list) ::
              {:ok, result :: integer}
              | {:error, reason :: term}

  @callback terminate_declaration(id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback terminate_employee_declarations(
              employee_id :: binary,
              user_id :: binary,
              reason :: binary,
              reason_description :: binary,
              headers :: list
            ) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback terminate_person_declarations(
              person_id :: binary,
              user_id :: binary,
              reason :: binary,
              reason_description :: binary,
              headers :: list
            ) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback create_declaration_with_termination_logic(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback update_declaration(id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_medication_dispenses(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback create_medication_dispense(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback update_medication_dispense(id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_medication_requests(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_doctor_medication_requests(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback process_medication_dispense(id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_qualify_medication_requests(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_prequalify_medication_requests(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback create_medication_request(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback update_medication_request(id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_latest_block(headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}
end

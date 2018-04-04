defmodule EHealth.API.OPSBehaviour do
  @moduledoc false

  @callback get_declaration_by_id(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_declarations(params :: list, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_declarations_count(employee_ids :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback terminate_declaration(id :: binary, params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback terminate_employee_declarations(
              employee_id :: binary,
              user_id :: binary,
              reason :: binary,
              reason_description :: binary,
              headers :: list
            ) :: {:ok, result :: term} | {:error, reason :: term}
  @callback terminate_person_declarations(
              person_id :: binary,
              user_id :: binary,
              reason :: binary,
              reason_description :: binary,
              headers :: list
            ) :: {:ok, result :: term} | {:error, reason :: term}
  @callback create_declaration_with_termination_logic(params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback update_declaration(id :: binary, params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback get_medication_dispenses(params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback create_medication_dispense(params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback update_medication_dispense(id :: binary, params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback get_medication_requests(params :: list, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_doctor_medication_requests(params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback get_qualify_medication_requests(params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback get_prequalify_medication_requests(params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback create_medication_request(params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback update_medication_request(id :: binary, params :: list, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback get_latest_block(headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
end

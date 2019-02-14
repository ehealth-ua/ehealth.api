defmodule GraphQL.Helpers.Errors do
  @moduledoc """
  Functions for formatting and transforming internal error formats into
  external GraphQL error format.
  """

  import GraphQL.Helpers.LanguageConventions, only: [to_external: 1]

  alias Ecto.Changeset
  alias GraphQL.Helpers.InputErrors

  @type error :: Absinthe.result_error_t() | binary | {atom, reason} | atom | reason
  @type reason :: binary | InputErrors.reason() | map | nil
  @type result_error :: %{message: binary, extensions: %{code: binary}}

  @error_codes ~w(
    unauthenticated
    forbidden
    unprocessable_entity
    conflict
    not_found
    bad_request
    internal_server_error
  )a

  @message_unauthenticated "Unable to authenticate request"
  @message_forbidden "You don't have permission to access this resource"
  @message_unprocessable_entity "Validation failed"
  @message_not_found "Not found"
  @message_bad_request "Malformed request"
  @message_internal_server_error "Something went wrong"

  def message(:unauthenticated), do: @message_unauthenticated
  def message(:forbidden), do: @message_forbidden
  def message(:unprocessable_entity), do: @message_unprocessable_entity
  def message(:not_found), do: @message_not_found
  def message(:bad_request), do: @message_bad_request
  def message(:internal_server_error), do: @message_internal_server_error

  @spec format(error) :: result_error
  def format(error)

  def format(%{message: _} = error), do: error
  def format(message) when is_binary(message), do: message
  def format({code, reason}) when code in @error_codes, do: format(code, reason)
  def format(code) when code in @error_codes, do: format(code, message(code))

  def format(%Changeset{valid?: false} = changeset), do: format(:unprocessable_entity, changeset)
  def format([{%{}, "$." <> _} | _] = errors), do: format(:unprocessable_entity, errors)
  def format({:"422", reason}), do: format(:unprocessable_entity, reason)
  def format(%{"error" => %{"invalid" => errors}}), do: format(:unprocessable_entity, errors)
  def format(%{"error" => %{"type" => "request_malformed"}}), do: format(:bad_request)
  def format(%{"error" => %{"message" => message}}), do: format(:bad_request, message)
  def format(nil), do: format(:not_found)

  def format(_), do: format(:internal_server_error)

  @spec format(code :: atom, reason, exception :: map | nil) :: result_error
  def format(code, reason, exception \\ nil)

  def format(code, message, exception) when is_binary(message) do
    %{message: message, extensions: format_extensions(code, exception)}
  end

  def format(:unprocessable_entity = code, errors, _) do
    input_errors = InputErrors.format(errors)

    format(code, @message_unprocessable_entity, %{input_errors: input_errors})
  end

  def format(code, %{} = exception, _) do
    format(code, message(code), exception)
  end

  defp format_extensions(code, exception) when is_map(exception) and exception != %{} do
    %{code: format_code(code), exception: to_external(exception)}
  end

  defp format_extensions(code, _), do: %{code: format_code(code)}

  defp format_code(code) do
    code
    |> Atom.to_string()
    |> String.upcase()
  end
end

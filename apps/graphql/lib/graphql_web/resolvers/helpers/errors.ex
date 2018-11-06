defmodule GraphQLWeb.Resolvers.Helpers.Errors do
  @moduledoc false

  @unauthenticated_error_message "Unable to authenticate request"
  @forbidden_error_message "Current client is not allowed to access this resource"

  def format_unauthenticated_error,
    do: %{
      message: @unauthenticated_error_message,
      extensions: %{code: "UNAUTHENTICATED"}
    }

  def format_forbidden_error,
    do: %{
      message: @forbidden_error_message,
      extensions: %{code: "FORBIDDEN"}
    }

  def format_forbidden_error(message) when is_binary(message),
    do: %{
      message: message,
      extensions: %{code: "FORBIDDEN"}
    }

  def format_forbidden_error(%{} = exception),
    do: %{
      message: @forbidden_error_message,
      extensions: %{code: "FORBIDDEN", exception: exception}
    }

  def format_bad_request(message) when is_binary(message) do
    %{
      message: message,
      extensions: %{code: "BAD_REQUEST"}
    }
  end

  def format_unprocessable_entity_error(message) when is_binary(message) do
    %{
      message: message,
      extensions: %{code: "UNPROCESSABLE_ENTITY"}
    }
  end

  def format_unprocessable_entity_error(errors) when is_list(errors) do
    # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
    # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
    %{
      message: "Validation error",
      errors: Enum.map(errors, &elem(&1, 0)),
      extensions: %{code: "UNPROCESSABLE_ENTITY"}
    }
  end

  def format_unprocessable_entity_error(%Ecto.Changeset{errors: errors}) do
    # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
    # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
    %{
      message: "Validation error",
      errors: Enum.map(errors, fn {_field, {error, _}} -> error end),
      extensions: %{code: "UNPROCESSABLE_ENTITY"}
    }
  end

  def format_not_found_error(message) when is_binary(message) do
    %{
      message: message,
      extensions: %{code: "NOT_FOUND"}
    }
  end

  def format_conflict_error(message) when is_binary(message) do
    %{
      message: message,
      extensions: %{code: "CONFLICT"}
    }
  end
end

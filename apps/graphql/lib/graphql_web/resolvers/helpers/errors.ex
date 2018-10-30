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

  def format_conflict_error(message) when is_binary(message) do
    %{
      message: message,
      extensions: %{code: "CONFLICT"}
    }
  end
end

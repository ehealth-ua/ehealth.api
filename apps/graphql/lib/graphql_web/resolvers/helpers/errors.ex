defmodule GraphQLWeb.Resolvers.Helpers.Errors do
  @moduledoc false

  alias Ecto.Changeset
  require Logger

  @unauthenticated_error_message "Unable to authenticate request"
  @forbidden_error_message "Current client is not allowed to access this resource"

  def render_error({:error, {:conflict, reason}}), do: {:error, format_conflict_error(reason)}

  def render_error({:error, {:bad_request, reason}}), do: {:error, format_bad_request(reason)}

  def render_error({:error, {:not_found, reason}}), do: {:error, format_not_found_error(reason)}

  def render_error({:error, :forbidden}), do: {:error, format_forbidden_error()}
  def render_error({:error, {:forbidden, reason}}), do: {:error, format_forbidden_error(reason)}

  def render_error({:error, [_ | _] = errors}), do: {:error, format_unprocessable_entity_error(errors)}
  def render_error({:error, {:"422", reason}}), do: {:error, format_unprocessable_entity_error(reason)}
  def render_error({:error, %Changeset{} = errors}), do: {:error, format_unprocessable_entity_error(errors)}

  def render_error({:error, nil}) do
    {:error, format_not_found_error("Not found")}
  end

  def render_error({:error, error}) do
    Logger.info("Got undefined error #{inspect(error)}}")
    {:error, error}
  end

  def render_error(error), do: render_error({:error, error})

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
    %{
      message: "Validation error",
      errors: Enum.map(errors, &elem(&1, 0)),
      extensions: %{code: "UNPROCESSABLE_ENTITY"}
    }
  end

  def format_unprocessable_entity_error(%Ecto.Changeset{errors: errors}) do
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

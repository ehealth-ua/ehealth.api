defmodule GraphQLWeb.Resolvers.Helpers.Errors do
  @moduledoc false

  alias Core.Log
  alias Ecto.Changeset
  alias EView.Helpers.ChangesetValidationsParser

  @unauthenticated_error_message "Unable to authenticate request"
  @forbidden_error_message "Current client is not allowed to access this resource"

  def render_error({:error, {:conflict, reason}}), do: {:error, format_conflict_error(reason)}

  def render_error({:error, {:bad_request, reason}}), do: {:error, format_bad_request(reason)}

  def render_error({:error, {:not_found, reason}}), do: {:error, format_not_found_error(reason)}

  def render_error({:error, :forbidden}), do: {:error, format_forbidden_error()}
  def render_error({:error, {:forbidden, reason}}), do: {:error, format_forbidden_error(reason)}

  def render_error({:error, :internal_server_error}), do: {:error, format_internal_server_error()}
  def render_error({:error, {:internal_server_error, reason}}), do: {:error, format_internal_server_error(reason)}

  def render_error({:error, [_ | _] = errors}), do: {:error, format_unprocessable_entity_error(errors)}
  def render_error({:error, {:"422", reason}}), do: {:error, format_unprocessable_entity_error(reason)}

  def render_error({:error, %Changeset{valid?: false} = errors}),
    do: {:error, format_unprocessable_entity_error(errors)}

  def render_error({%Changeset{valid?: false} = errors}), do: {:error, format_unprocessable_entity_error(errors)}

  def render_error({:error, nil}) do
    {:error, format_not_found_error("Not found")}
  end

  def render_error({:error, %{"error" => %{"type" => "request_malformed"}} = error}) do
    Log.error("Got mailformed request #{inspect(error)}")

    {:error, format_bad_request("Malformed request")}
  end

  def render_error({:error, %{"error" => %{"invalid" => errors}}}) do
    {:error, format_unprocessable_entity_error(hd(errors))}
  end

  def render_error({:error, %{"error" => %{"message" => message}}}) do
    {:error, format_bad_request(message)}
  end

  def render_error({:error, error}) do
    Log.error("Got undefined error #{inspect(error)}}")

    {:error,
     %{
       message: "Undefined error",
       extensions: %{code: "BAD_REQUEST", exception: inspect(error)}
     }}
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

  def format_unprocessable_entity_error(description) when is_binary(description) do
    %{
      message: "Validation error",
      errors: [%{"description" => description, "rule" => "invalid"}],
      extensions: %{code: "UNPROCESSABLE_ENTITY"}
    }
  end

  def format_unprocessable_entity_error([{%{}, _field} | _] = errors) do
    errors =
      errors
      |> Enum.map(fn {%{description: description, rule: rule}, field} ->
        create_validation_error(field, rule, description)
      end)

    %{
      message: "Validation error",
      errors: errors,
      extensions: %{code: "UNPROCESSABLE_ENTITY"}
    }
  end

  def format_unprocessable_entity_error(%{
        "entry" => field,
        "rules" => [%{"description" => description, "rule" => rule} | _]
      }) do
    %{
      message: "Validation error",
      errors: [create_validation_error(field, rule, description)],
      extensions: %{code: "UNPROCESSABLE_ENTITY"}
    }
  end

  def format_unprocessable_entity_error(%Ecto.Changeset{} = changeset) do
    errors =
      changeset
      |> ChangesetValidationsParser.changeset_to_rules("json_data_property")
      |> Enum.map(fn %{entry: field, rules: [%{description: description, rule: rule} | _]} ->
        create_validation_error(field, rule, description)
      end)

    %{
      message: "Validation error",
      errors: errors,
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

  def format_internal_server_error do
    %{
      message: "Internal error",
      extensions: %{code: "INTERNAL_SERVER_ERROR"}
    }
  end

  def format_internal_server_error(message) when is_binary(message) do
    %{
      message: message,
      extensions: %{code: "INTERNAL_SERVER_ERROR"}
    }
  end

  defp create_validation_error(field, rule, description) do
    %{"#{field}" => %{"description" => description, "rule" => to_string(rule)}}
  end
end

defmodule GraphQL.Helpers.InputErrors do
  @moduledoc """
  Functions for transforming internal validation error formats into
  external input error format.
  """

  import GraphQL.Helpers.LanguageConventions, only: [to_external: 1]

  alias Ecto.Changeset

  @type reason :: Changeset.t() | json_schema_errors | validation_errors
  @type json_schema_errors :: [{map, binary}]
  @type validation_errors :: [map]
  @type result_errors :: [%{message: binary, options: map, path: [binary | pos_integer]}]

  @spec format(reason) :: result_errors
  def format(%Changeset{valid?: false} = changeset), do: format_changeset(changeset)
  def format([{%{}, "$." <> _} | _] = errors), do: format_json_schema_errors(errors)
  def format([%{"rules" => _} | _] = errors), do: format_validation_errors(errors)

  defp format_changeset(path \\ [], errors)

  defp format_changeset(_, %Changeset{valid?: false} = changeset) do
    changeset
    |> Changeset.traverse_errors(& &1)
    |> format_changeset()
  end

  defp format_changeset(path, %{} = errors) do
    Enum.flat_map(errors, fn {field, errors} -> format_changeset([field | path], errors) end)
  end

  defp format_changeset(_, []), do: []

  defp format_changeset(path, [{message, options} | tail]) do
    message = convert_placeholders(message)
    options = Map.new(options)
    path = path |> Enum.map(&to_external/1) |> Enum.reverse()

    [%{message: message, options: options, path: path} | format_changeset(path, tail)]
  end

  defp format_changeset([index | path], [errors | tail]) when is_number(index) do
    format_changeset([index | path], errors) ++ format_changeset([index + 1 | path], tail)
  end

  defp format_changeset(path, [errors | tail]) when is_map(errors) do
    format_changeset([0 | path], [errors | tail])
  end

  defp format_json_schema_errors([]), do: []

  defp format_json_schema_errors([{error, path} | tail]) do
    [format_validation_error(path, error) | format_json_schema_errors(tail)]
  end

  def format_validation_errors([]), do: []

  def format_validation_errors([%{"entry" => path, "rules" => rules} | tail]) do
    format_validation_errors(path, rules) ++ format_validation_errors(tail)
  end

  def format_validation_errors(_, []), do: []

  def format_validation_errors(path, [%{"description" => description, "params" => params, "rule" => rule} | tail]) do
    error = %{description: description, params: params, rule: rule}

    [format_validation_error(path, error) | format_validation_errors(path, tail)]
  end

  defp format_validation_error(path, error) do
    message = validation_error_message(error)
    options = validation_error_options(error)
    path = path |> split_json_path() |> Enum.map(&to_external/1)

    %{message: message, options: options, path: path}
  end

  defp validation_error_message(%{raw_description: raw_description}), do: convert_placeholders(raw_description)
  defp validation_error_message(%{description: description}), do: description

  defp validation_error_options(%{params: %{} = params, rule: rule}), do: Map.put(params, :rule, rule)

  defp validation_error_options(%{params: params} = error) do
    case Keyword.keyword?(params) do
      true -> validation_error_options(%{error | params: Map.new(params)})
      false -> validation_error_options(%{error | params: %{}})
    end
  end

  defp split_json_path("$." <> path) do
    path
    |> String.split(".")
    |> Enum.map(fn segment ->
      case String.match?(segment, ~r/\[\d+\]/) do
        true -> segment |> String.replace(~r/\[|\]/, "") |> String.to_integer()
        false -> segment
      end
    end)
  end

  defp convert_placeholders(template) do
    Regex.replace(
      ~r/%\{(\w+)\}/,
      template,
      fn _, name -> "{" <> to_external(name) <> "}" end
    )
  end
end

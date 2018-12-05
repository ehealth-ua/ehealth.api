defmodule GraphQL.Unit.Helpers.ErrorsTest do
  @moduledoc false

  use Core.ConnCase, async: true

  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]

  alias Core.ValidationError
  alias Core.Validators.JsonSchema
  alias Core.Validators.Error

  defmodule TestEntity do
    @moduledoc false

    use Ecto.Schema
    import Ecto.Changeset
    alias TestEntity.EmbeddedData

    schema "test_shema" do
      field(:some_field, :string)
      field(:next_field, :string, null: false)

      embeds_one(:data, EmbeddedData)
    end

    def changeset do
      fields = [:some_field, :next_field]

      %__MODULE__{}
      |> cast(%{some_field: ".", data: %{}}, fields)
      |> cast_embed(:data, with: &EmbeddedData.changeset/2, required: true)
      |> validate_required(fields)
    end

    defmodule EmbeddedData do
      @moduledoc false

      use Ecto.Schema

      embedded_schema do
        field(:nested_field, :date)
        field(:nested_values, {:array, :map})
      end

      def changeset(schema, _) do
        fields = [:nested_field, :nested_values]

        schema
        |> cast(%{}, fields)
        |> validate_required(fields)
      end
    end
  end

  describe "handle errors from" do
    test "ecto chageset with embedded" do
      {:error, errors} = render_error({:error, TestEntity.changeset()})

      assert_changeset_errors(errors)
    end

    test "ecto chageset without tuple" do
      {:error, errors} = render_error(TestEntity.changeset())

      assert_changeset_errors(errors)
    end

    test "json schema" do
      json_schema_params = %{"reason" => %{}, "merged_to_legal_entity" => %{}}
      validation_result = JsonSchema.validate(:legal_entity_merge_job, json_schema_params)
      {:error, %{errors: errors}} = render_error(validation_result)

      assert %{"$.reason" => %{"description" => "type mismatch. Expected String but got Object", "rule" => "cast"}} in errors
    end

    test "error dump" do
      validation_error = Error.dump(%ValidationError{description: "invalid", rule: "email_exists", path: "$.email"})
      {:error, %{errors: errors}} = render_error(validation_error)

      assert [%{"$.email" => %{"description" => "invalid", "rule" => "email_exists"}}] == errors
    end

    test "atom 422" do
      message = "Something went wrong"
      validation_error = {:error, {:"422", message}}
      {:error, error} = render_error(validation_error)

      assert %{
               errors: [%{"description" => message, "rule" => "invalid"}],
               extensions: %{code: "UNPROCESSABLE_ENTITY"},
               message: "Validation error"
             } == error
    end
  end

  defp assert_changeset_errors(%{errors: errors}) do
    assert %{"$.next_field" => %{"description" => "can't be blank", "rule" => "required"}} in errors

    invalid_fields = [
      "$.data.nested_field",
      "$.data.nested_values",
      "$.next_field"
    ]

    Enum.each(errors, fn field ->
      field_key = field |> Map.keys() |> hd()

      assert field_key in invalid_fields
    end)
  end
end

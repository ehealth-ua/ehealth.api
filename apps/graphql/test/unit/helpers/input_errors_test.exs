defmodule GraphQL.Unit.Helpers.InputErrorsTest do
  @moduledoc false

  use Core.ConnCase, async: false

  alias Core.ValidationError
  alias Core.Validators.Error
  alias GraphQL.Helpers.InputErrors
  alias NExJsonSchema.{Schema, Validator}

  defmodule Organization do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    schema "organizations" do
      field(:name, :string)
    end

    def changeset(organization, params \\ %{}) do
      organization
      |> cast(params, [:name])
      |> validate_required([:name])
    end
  end

  defmodule Address do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      field(:country, :string)
      field(:city, :string)
    end

    def changeset(address, params \\ %{}) do
      address
      |> cast(params, [:country, :city])
      |> validate_required([:country, :city])
    end
  end

  defmodule User do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    schema "users" do
      field(:first_name, :string)
      field(:last_name, :string)

      belongs_to(:organization, Organization)
      embeds_many(:addresses, Address)
    end

    def changeset(user, params \\ %{}) do
      user
      |> cast(params, [:first_name, :last_name])
      |> validate_required([:first_name, :last_name])
      |> cast_assoc(:organization)
      |> cast_embed(:addresses)
    end
  end

  describe "generic validation errors" do
    test "placeholders in message templates" do
      schema =
        Schema.resolve(%{
          "type" => "object",
          "properties" => %{
            "count" => %{
              "type" => "number",
              "minimum" => 10
            }
          }
        })

      {:error, errors} = Validator.validate(schema, %{"count" => 5})

      assert %{
               message: "expected the value to be >= {greaterThanOrEqualTo}",
               options: %{greater_than_or_equal_to: 10, rule: :number},
               path: ["count"]
             } in InputErrors.format(errors)
    end
  end

  describe "Ecto changeset" do
    test "direct fields" do
      changeset = User.changeset(%User{})

      assert [
               %{message: "can't be blank", options: %{validation: :required}, path: ["firstName"]},
               %{message: "can't be blank", options: %{validation: :required}, path: ["lastName"]}
             ] = InputErrors.format(changeset)
    end

    test "nested changesets" do
      changeset = User.changeset(%User{}, %{first_name: "John", last_name: "Doe", organization: %{}})

      assert %{
               message: "can't be blank",
               options: %{validation: :required},
               path: ["organization", "name"]
             } in InputErrors.format(changeset)
    end

    test "nested changeset lists" do
      changeset =
        User.changeset(%User{}, %{
          first_name: "John",
          last_name: "Doe",
          email: "example@example.com",
          addresses: [%{country: "Ukraine"}, %{city: "Kyiv"}]
        })

      assert [
               %{
                 message: "can't be blank",
                 options: %{validation: :required},
                 path: ["addresses", 0, "city"]
               },
               %{
                 message: "can't be blank",
                 options: %{validation: :required},
                 path: ["addresses", 1, "country"]
               }
             ] = InputErrors.format(changeset)
    end
  end

  describe "JSON schema" do
    test "direct fields" do
      schema =
        Schema.resolve(%{
          "type" => "object",
          "properties" => %{
            "foo" => %{
              "type" => "string"
            }
          }
        })

      {:error, errors} = Validator.validate(schema, %{"foo" => 1})

      assert %{
               message: "type mismatch. Expected {expected} but got {actual}",
               options: %{actual: "integer", expected: "string", rule: :cast},
               path: ["foo"]
             } in InputErrors.format(errors)
    end

    test "nested fields" do
      schema =
        Schema.resolve(%{
          "type" => "object",
          "properties" => %{
            "foo" => %{
              "type" => "array",
              "items" => %{
                "type" => "object",
                "properties" => %{
                  "bar" => %{
                    "type" => "number"
                  }
                }
              }
            }
          }
        })

      {:error, errors} = Validator.validate(schema, %{"foo" => [%{"bar" => "baz"}]})

      assert %{
               message: "type mismatch. Expected {expected} but got {actual}",
               options: %{actual: "string", expected: "number", rule: :cast},
               path: ["foo", 0, "bar"]
             } in InputErrors.format(errors)
    end

    test "error dumps" do
      {:error, errors} =
        Error.dump(%ValidationError{description: "Email already exists", rule: "email_exists", path: "$.email"})

      assert %{
               message: "Email already exists",
               options: %{rule: "email_exists"},
               path: ["email"]
             } in InputErrors.format(errors)
    end
  end

  describe "REST errors" do
    test "validation errors" do
      errors = [
        %{
          "entry" => "$.signed_content",
          "entry_type" => "json_data_property",
          "rules" => [
            %{
              "description" => "Not a base64 string",
              "params" => [],
              "rule" => "invalid"
            }
          ]
        }
      ]

      assert %{
               message: "Not a base64 string",
               options: %{rule: "invalid"},
               path: ["signedContent"]
             } in InputErrors.format(errors)
    end
  end
end

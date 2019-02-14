defmodule GraphQL.Unit.Helpers.ErrorsTest do
  @moduledoc false

  use Core.ConnCase, async: true

  alias Core.ValidationError
  alias Core.Validators.Error
  alias GraphQL.Helpers.Errors
  alias NExJsonSchema.{Schema, Validator}

  defmodule Foo do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    schema "foo" do
      field(:bar)
    end

    def changeset(params \\ %{}) do
      %__MODULE__{}
      |> cast(params, [:bar])
      |> validate_required([:bar])
    end
  end

  describe "generic errors" do
    test "with already formatted error" do
      error = %{message: "Foo is broken"}

      assert ^error = Errors.format(error)
    end

    test "with binary error message" do
      message = "Bar is wrong"

      assert ^message = Errors.format(message)
    end

    test "with {code, reason} tuple" do
      assert %{
               extensions: %{code: "CONFLICT"},
               message: "User already assigned"
             } = Errors.format({:conflict, "User already assigned"})
    end

    test "with exception map" do
      assert %{
               extensions: %{
                 code: "FORBIDDEN",
                 exception: %{"missingAllowances" => ["foo:read", "bar:write"]}
               },
               message: "You don't have permission to access this resource"
             } = Errors.format({:forbidden, %{missing_allowances: ["foo:read", "bar:write"]}})
    end

    test "with unknown error" do
      assert %{
               extensions: %{code: "INTERNAL_SERVER_ERROR"},
               message: "Something went wrong"
             } = Errors.format(:foo)
    end
  end

  describe "UNPROCESSABLE_ENTITY error" do
    test "with Ecto changeset" do
      assert %{
               extensions: %{
                 code: "UNPROCESSABLE_ENTITY",
                 exception: %{
                   "inputErrors" => [
                     %{
                       "message" => "can't be blank",
                       "options" => %{"validation" => :required},
                       "path" => ["bar"]
                     }
                   ]
                 }
               },
               message: "Validation failed"
             } = Errors.format(Foo.changeset())
    end

    test "with JSON schema errors" do
      schema =
        Schema.resolve(%{
          "type" => "object",
          "properties" => %{
            "foo" => %{
              "type" => "string"
            }
          }
        })

      {:error, error} = Validator.validate(schema, %{"foo" => 1})

      assert %{
               extensions: %{
                 code: "UNPROCESSABLE_ENTITY",
                 exception: %{
                   "inputErrors" => [
                     %{
                       "message" => "type mismatch. Expected {expected} but got {actual}",
                       "options" => %{
                         "actual" => "integer",
                         "expected" => "string",
                         "rule" => :cast
                       },
                       "path" => ["foo"]
                     }
                   ]
                 }
               },
               message: "Validation failed"
             } = Errors.format(error)
    end

    test "with error dump" do
      {:error, error} =
        Error.dump(%ValidationError{description: "Email already exists", rule: "email_exists", path: "$.email"})

      assert %{
               extensions: %{
                 code: "UNPROCESSABLE_ENTITY",
                 exception: %{
                   "inputErrors" => [
                     %{
                       "message" => "Email already exists",
                       "options" => %{"rule" => "email_exists"},
                       "path" => ["email"]
                     }
                   ]
                 }
               },
               message: "Validation failed"
             } = Errors.format(error)
    end

    test "with {:\"422\", reason} tuple" do
      assert %{
               extensions: %{code: "UNPROCESSABLE_ENTITY"},
               message: "Validation failed. Recheck your input data"
             } = Errors.format({:"422", "Validation failed. Recheck your input data"})
    end

    test "with REST service response" do
      error = %{
        "error" => %{
          "invalid" => [
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
          ],
          "type" => "validation_failed"
        }
      }

      assert %{
               extensions: %{
                 code: "UNPROCESSABLE_ENTITY",
                 exception: %{
                   "inputErrors" => [
                     %{
                       "message" => "Not a base64 string",
                       "options" => %{"rule" => "invalid"},
                       "path" => ["signedContent"]
                     }
                   ]
                 }
               },
               message: "Validation failed"
             } = Errors.format(error)
    end
  end

  describe "BAD_REQUEST error" do
    test "when type=\"request_malformed\"" do
      error = %{"error" => %{"type" => "request_malformed"}}

      assert %{extensions: %{code: "BAD_REQUEST"}, message: "Malformed request"} = Errors.format(error)
    end

    test "with custom message" do
      error = %{"error" => %{"message" => "Unable to decode data"}}

      assert %{extensions: %{code: "BAD_REQUEST"}, message: "Unable to decode data"} = Errors.format(error)
    end
  end

  describe "NOT_FOUND error" do
    test "with nil error" do
      assert %{extensions: %{code: "NOT_FOUND"}, message: "Not found"} = Errors.format(nil)
    end
  end
end

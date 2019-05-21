defmodule Core.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Core.Expectations.Mithril
      import Core.Expectations.RPC
      import Core.Factories
      import Core.ConnCase
      import ExUnit.CaptureLog
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Core.Repo)
    :ok = Sandbox.checkout(Core.PRMRepo)

    unless tags[:async] do
      Sandbox.mode(Core.Repo, {:shared, self()})
      Sandbox.mode(Core.PRMRepo, {:shared, self()})
    end

    :ok
  end

  def get_headers_with_consumer_id do
    [
      {"x-consumer-id", Ecto.UUID.generate()}
    ]
  end

  def assert_show_response_schema(response, type) when is_binary(type) do
    assert_json_schema(response, File.cwd!() <> "/../core/specs/json_schemas/#{type}/#{type}_show_response.json")
  end

  def assert_list_response_schema(response, type) when is_binary(type) do
    assert_json_schema(response, File.cwd!() <> "/../core/specs/json_schemas/#{type}/#{type}_list_response.json")
  end

  def assert_json_schema(data, schema_path) do
    assert :ok ==
             schema_path
             |> File.read!()
             |> Jason.decode!()
             |> NExJsonSchema.Validator.validate(data)

    data
  end
end

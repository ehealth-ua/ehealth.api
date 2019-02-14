defmodule GraphQL.Unit.Middleware.FormatErrorsTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias GraphQLWeb.Middleware.FormatErrors
  alias Ecto.UUID

  @query """
    mutation CreatePost($title: String, $body: String) {
      createPost(title: $title, body: $body) {
        id
      }
    }
  """

  defmodule Schema do
    use Absinthe.Schema
    use FormatErrors

    query do
    end

    mutation do
      field(:create_post, type: :post) do
        arg(:title, non_null(:string))
        arg(:body, non_null(:string))

        resolve(fn %{title: title, body: body}, %{context: context} ->
          with {:ok, _} <- Map.fetch(context, :current_user) do
            {:ok, %{id: UUID.generate(), title: title, body: body}}
          else
            :error -> {:error, {:unauthenticated, "You should login first"}}
          end
        end)
      end
    end

    object :post do
      field(:id, :id)
      field(:title, :string)
      field(:body, :string)
    end
  end

  describe "format errors middleware" do
    test "format errors" do
      variables = %{"title" => "Foo", "body" => "Lorem ipsum dolor sit amet"}

      {:ok, result} = Absinthe.run(@query, Schema, variables: variables)

      assert [
               %{
                 extensions: %{code: "UNAUTHENTICATED"},
                 message: "You should login first",
                 path: ["createPost"]
               }
             ] = result[:errors]
    end

    test "bypass without errors" do
      variables = %{"title" => "Foo", "body" => "Bar"}
      context = %{current_user: %{id: UUID.generate()}}

      {:ok, result} = Absinthe.run(@query, Schema, variables: variables, context: context)

      assert %{
               "createPost" => %{
                 "id" => _
               }
             } = result[:data]
    end
  end
end

defmodule GraphQL.WhiteBreadConfig do
  use WhiteBread.SuiteConfiguration

  suite(
    name: "All",
    context: GraphQL.Features.Context,
    feature_paths: ["features/"]
  )
end

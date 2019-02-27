defmodule GraphQL.WhiteBreadConfig do
  @moduledoc false
  use WhiteBread.SuiteConfiguration
  alias GraphQL.Features.Context

  suite(
    name: "All",
    context: Context,
    feature_paths: ["features/"]
  )
end

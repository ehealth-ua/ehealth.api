defmodule GraphQL.Schema.SignedContentTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  input_object :signed_content do
    field(:content, non_null(:string))
    field(:encoding, non_null(:signed_content_encoding))
  end

  enum(:signed_content_encoding, values: [:base64])
end

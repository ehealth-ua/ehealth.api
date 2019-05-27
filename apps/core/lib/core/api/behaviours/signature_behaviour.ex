defmodule Core.API.SignatureBehaviour do
  @moduledoc false

  @callback decode_and_validate(signed_content :: binary, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}
end

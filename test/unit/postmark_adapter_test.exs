defmodule EHealth.Unit.PostmarkAdapterTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.Bamboo.PostmarkAdapter

  test "handle_config" do
    System.put_env("POSTMARK_API_KEY", "111")
    assert %{adapter: EHealth.Bamboo.PostmarkAdapter, api_key: "111"} == PostmarkAdapter.handle_config(%{})
  end
end

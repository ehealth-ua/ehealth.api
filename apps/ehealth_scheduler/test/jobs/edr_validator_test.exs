defmodule EHealthScheduler.Jobs.EdrValidatorTest do
  @moduledoc false

  use Core.ConnCase
  import Mox
  alias EHealthScheduler.Jobs.EdrValidator

  test "run/0" do
    for i <- 1..10 do
      insert(:prm, :edr_data, edr_id: i)
    end

    expect(KafkaMock, :publish_sync_edr_data, 10, fn _event -> :ok end)

    EdrValidator.run()
  end
end

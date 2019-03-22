defmodule EHealthScheduler.Jobs.EdrValidatorTest do
  @moduledoc false

  use Core.ConnCase
  import Mox
  alias EHealthScheduler.Jobs.EdrValidator

  test "run/0" do
    for _ <- 1..10 do
      insert(:prm, :legal_entity)
    end

    expect(KafkaMock, :publish_verify_legal_entity, 10, fn _event -> :ok end)

    EdrValidator.run()
  end
end

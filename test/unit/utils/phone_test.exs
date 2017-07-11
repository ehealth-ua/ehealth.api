defmodule EHealth.Unit.DigitalSignatureTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.Utils.Phone

  test "hide_number/1" do
    assert "+38098*****60" = Phone.hide_number("+380982815260")
    assert "+38097*****61" = Phone.hide_number("+380972815261")
    assert "+38066*****62" = Phone.hide_number("+380662815262")
    assert "+38050*****63" = Phone.hide_number("+380502815263")
  end
end

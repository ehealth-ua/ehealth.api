defmodule EHealth.Unit.Bamboo.Emails.HashChainVeriricationNotificationTest do
  alias EHealth.Bamboo.Emails.HashChainVeriricationNotification, as: Email

  use ExUnit.Case

  test "email has all the right values" do
    email = Email.new("some_content")

    assert email.to == "serious@authority.com"
    assert email.from == "automatic@system.com"
    assert email.subject == "Hash chain has been mangled!"
    assert email.html_body == "some_content"
  end
end

defmodule EHealth.MedicalProgram.APITest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true
  alias EHealth.PRM.MedicalPrograms
  alias Scrivener.Page

  test "list/1" do
    insert(:prm, :medical_program)
    assert %Page{entries: [_]} = MedicalPrograms.list(%{})
  end

  test "get_by_id/1" do
    %{id: id} = insert(:prm, :medical_program)
    assert %{id: ^id} = MedicalPrograms.get_by_id(id)
  end
end

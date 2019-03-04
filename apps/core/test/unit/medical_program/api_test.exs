defmodule Core.MedicalProgram.APITest do
  @moduledoc false

  use Core.ConnCase, async: true
  alias Core.MedicalPrograms
  alias Scrivener.Page

  test "list/1" do
    insert(:prm, :medical_program)
    assert %Page{entries: [_, _]} = MedicalPrograms.list(%{})
  end

  test "get_by_id/1" do
    %{id: id} = insert(:prm, :medical_program)
    assert %{id: ^id} = MedicalPrograms.get_by_id(id)
  end
end

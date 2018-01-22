defmodule EHealth.Integration.DictionariesTest do
  use EHealth.Web.ConnCase

  alias EHealth.Dictionaries

  @document_type_dict %{
    "PASSPORT" => "Паспорт",
    "NATIONAL_ID" => "Біометричний паспорт",
    "BIRTH_CERTIFICATE" => "Свідоцтво про народження",
    "TEMPORARY_CERTIFICATE" => "Посвідка на проживання"
  }

  @phone_type_dict %{
    "MOBILE" => "мобільний",
    "LAND_LINE" => "стаціонарний"
  }

  describe "Dictionaries boundary allow access to dictionaries" do
    setup _context do
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_document_type)

      :ok
    end

    test "get_dictionaries/1 can to get 1 dictionary by name" do
      dict = Dictionaries.get_dictionaries(["DOCUMENT_TYPE"])

      assert %{"DOCUMENT_TYPE" => @document_type_dict} == dict
    end

    test "get_dictionaries/1 can to get multiple dictionaries by name" do
      dicts = Dictionaries.get_dictionaries(["DOCUMENT_TYPE", "PHONE_TYPE"])

      assert %{"DOCUMENT_TYPE" => @document_type_dict, "PHONE_TYPE" => @phone_type_dict} == dicts
    end

    test "get_dictionaries_keys/1 can get keys from dictionary" do
      keys = Dictionaries.get_dictionaries_keys(["PHONE_TYPE"])

      assert %{"PHONE_TYPE" => ["LAND_LINE", "MOBILE"]} == keys
    end

    test "get_dictionaries_keys/1 can get keys from multiple dictionaries" do
      keys = Dictionaries.get_dictionaries_keys(["DOCUMENT_TYPE", "PHONE_TYPE"])

      assert %{"DOCUMENT_TYPE" => Map.keys(@document_type_dict), "PHONE_TYPE" => Map.keys(@phone_type_dict)} == keys
    end
  end
end

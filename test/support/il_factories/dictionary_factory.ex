defmodule EHealth.ILFactories.DictionaryFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def dictionary_factory do
        %EHealth.Dictionaries.Dictionary{
          name: sequence("DICTIONARY-"),
          labels: ["SYSTEM", "EXTERNAL"],
          values: %{},
          is_active: true,
        }
      end

      def dictionary_phone_type_factory do
        build(:dictionary, [
          name: "PHONE_TYPE",
          values: %{
            "MOBILE" => "мобільний",
            "LAND_LINE" => "стаціонарний"}
        ])
      end

      def dictionary_employee_type_factory do
        build(:dictionary, [
          name: "EMPLOYEE_TYPE",
          values: %{
            "HR" => "відділ кадрів",
            "ADMIN" => "реєстратор",
            "OWNER" => "керівник закладу ОЗ",
            "DOCTOR" => "лікар",
            "PHARMACIST" => "фармацевт",
            "PHARMACY_OWNER" => "керівник аптеки"}
        ])
      end

      def dictionary_document_type_factory do
        build(:dictionary, [
          name: "DOCUMENT_TYPE",
          values: %{
            "PASSPORT" => "Паспорт",
            "NATIONAL_ID" => "Біометричний паспорт",
            "BIRTH_CERTIFICATE" => "Свідоцтво про народження",
            "TEMPORARY_CERTIFICATE" => "Посвідка на проживання"}
        ])
      end

      def dictionary_authentication_method_factory do
        build(:dictionary, [
          name: "AUTHENTICATION_METHOD",
          values: %{
            "OTP" => "Авторизація через СМС",
            "OFFLINE" => "Авторизація через верифікацію документів"}
        ])
      end

      def dictionary_document_relationship_type_factory do
        build(:dictionary, [
          name: "DOCUMENT_RELATIONSHIP_TYPE",
          values: %{
            "DOCUMENT" => "Документ",
            "COURT_DECISION" => "Рішення суду",
            "BIRTH_CERTIFICATE" => "Свідоцтво про народження",
            "CONFIDANT_CERTIFICATE" => "Посвідчення опікуна"}
        ])
      end

      def dictionary_address_type_factory do
        build(:dictionary, [
          name: "ADDRESS_TYPE",
          values: %{
            "RESIDENCE" => "проживання",
            "REGISTRATION" => "реєстрації"}
        ])
      end
    end
  end
end

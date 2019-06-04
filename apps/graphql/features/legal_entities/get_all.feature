Feature: Get all legal entities

  Scenario: Request legal entities with filter by residence_address settlement_id
    Given the following legal entities exist:
      | databaseId                             | residenceAddress  |
      | "5bf0aee4-8de7-42b4-8a5d-54e851c5a6b7" | {"type": "RESIDENCE","country": "UA","area": "Житомирська","region": "Бердичівський","settlement": "Київ","settlement_type": "CITY","settlement_id": "40323775-6102-476d-861b-70413385a888","street_type": "STREET","street": "вул. Ніжинська","building": "15-В","apartment": "23","zip": "02090"} |
      | "fa9a9875-6829-4262-b8b4-bb6180cc90de" | {"type": "RESIDENCE","country": "UA","area": "Одеська","region": "Затоцький","settlement": "Затока","settlement_type": "CITY","settlement_id": "4828e699-2efd-458a-8f58-1064bd470ca5","street_type": "STREET","street": "вул. Ніжинська","building": "10-В","apartment": "223","zip": "03100"} |
    And my scope is "legal_entity:read"
    When I request first 10 legal entities where settlement_id of the associated residenceAddress is "U2V0dGxlbWVudDo0MDMyMzc3NS02MTAyLTQ3NmQtODYxYi03MDQxMzM4NWE4ODg="
    Then no errors should be returned
    And request id should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "5bf0aee4-8de7-42b4-8a5d-54e851c5a6b7"

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And the following legal entity are associated with <association_entity> accordingly:
      | databaseId     |
      | <alternate_id> |
      | <expected_id>  |
    And my scope is "legal_entity:read"
    When I request first 10 legal entities where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field | field        | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           |
      | EDR data           | edr_data          | databaseId   | "488b864e-9602-4994-9bdc-84fce28424ba" | "488b864e-9602-4994-9bdc-84fce28424ba" | "c5ced316-16a7-4532-b84e-56f7b84e5579" | "5ab2942c-449c-4756-9a7c-8079ca4b6cb8" | "e0dff91c-747e-4d3b-96ed-eae9ba429eae" |
      | EDR data           | edr_data          | edrpou       | "12345"                                | "1234567890"                           | "0987654321"                           | "8278dc43-8260-43f9-88de-c60a2802df64" | "205bd220-d208-48ca-bed5-a5e700fb604a" |
      | EDR data           | edr_data          | name         | "acme"                                 | "Acme Corporation"                     | "Ajax LLC"                             | "a2c6fbd6-a5e8-4269-bcd8-6b7fc6b683d1" | "7e90abcd-b734-47d1-b596-4d407407218b" |
      | EDR data           | edr_data          | isActive     | false                                  | false                                  | true                                   | "611a50e5-94c8-4867-8675-f60bfc6c3f13" | "66f1dfc2-94f1-46dd-8a07-2dde81d82f72" |

  Scenario Outline: Request items filtered by condition
    Given the following legal entities exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "legal_entity:read"
    When I request first 10 legal entities where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field       | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId  | "3fc65def-670d-42f6-bac1-fa48ad2b6da4" | "3fc65def-670d-42f6-bac1-fa48ad2b6da4" | "170ed3bf-eb18-440b-9552-840fa109cf71" |
      | type        | ["PHARMACY", "MSP_PHARMACY"]           | "PHARMACY"                             | "NHS"                                  |
      | nhsVerified | true                                   | true                                   | false                                  |
      | nhsReviewed | false                                  | false                                  | true                                   |
      | edrVerified | true                                   | true                                   | false                                  |
      | status      | "CLOSED"                               | "CLOSED"                               | "ACTIVE"                                  |

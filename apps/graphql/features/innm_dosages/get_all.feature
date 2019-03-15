Feature: Get all INNMDosages

  Scenario: Request all items with NHS client
    Given there are 3 INNM dosages exist
    And my scope is "innm_dosage:read"
    And my client type is "NHS"
    When I request first 10 INNM dosages
    Then no errors should be returned
    And I should receive collection with 3 items

  Scenario: Request with incorrect client
    Given there are 2 INNM dosages exist
    And my scope is "innm_dosage:read"
    And my client type is "MIS"
    When I request first 10 INNM dosages
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following INNM dosages exist:
      | databaseId     | <field>           |
      | <alternate_id> | <alternate_value> |
      | <expected_id>  | <expected_value>  |
    And my scope is "innm_dosage:read"
    And my client type is "NHS"
    When I request first 10 INNM dosages where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | field       | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           |
      | databaseId  | "7679e99c-07a9-448a-ad74-93fea714ccb5" | "7679e99c-07a9-448a-ad74-93fea714ccb5" | "9d2005d2-d237-49ab-a991-39d9826181e6" | "7679e99c-07a9-448a-ad74-93fea714ccb5" | "9d2005d2-d237-49ab-a991-39d9826181e6" |
      | name        | "Спіро"                                | "Спіронолактон"                        | "Метформін"                            | "12a35fd1-7cc1-4332-9bfa-868e5b25f33d" | "0bb92667-eb2f-4ad9-a18a-51298cacd03c" |
      | isActive    | false                                  | false                                  | true                                   | "12a35fd1-7cc1-4332-9bfa-868e5b25f33d" | "0bb92667-eb2f-4ad9-a18a-51298cacd03c" |
      | form        | "PRESSURISED_INHALATION"               | "PRESSURISED_INHALATION"               | "TABLET"                               | "e96c8911-f8c0-4e5a-a4d0-eac66dd535a2" | "c4f706ac-101e-47f4-a497-4c61f0716a76" |

  Scenario Outline: Request items filtered by innm condition
    Given the following INNM dosages exist:
      | databaseId       |
      | <innm_dosage_id> |
    Given the following INNMs exist:
      | databaseId     | <field>          |
      | <innm_id>      | <expected_value> |
    And the following INNM dosage ingredients exist:
      | parentId         | innmChildId |
      | <innm_dosage_id> | <innm_id>   |
    And my scope is "innm_dosage:read"
    And my client type is "NHS"
    When I request first 10 INNM dosages where INNM <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <innm_dosage_id>

    Examples:
      | field        | filter_value                           | expected_value                         | innm_dosage_id                         | innm_id                                |
      | databaseId   | "bdaf7cff-bf16-4341-a2f9-f753d4f3110a" | "bdaf7cff-bf16-4341-a2f9-f753d4f3110a" | "b2f75bee-119f-4675-8490-64f34eda0f69" | "bdaf7cff-bf16-4341-a2f9-f753d4f3110a" |
      | name         | "Гідрох"                               | "Гідрохлортіазид"                      | "97bc6811-be86-47ae-9ea8-8023fe27656f" | "776f81fc-a1d1-454a-9375-bb90713081ff" |
      | nameOriginal | "Hydroc"                               | "Hydrochlorothiazide"                  | "86449902-5486-409a-adb7-711c9733fa75" | "815dbfd5-9b42-49fa-b24f-c009c4e32056" |
      | isActive     | true                                   | true                                   | "b41bfa09-9cfa-438c-aa8d-68a2263d39a9" | "4f1a1908-8aa1-42a4-9e5c-8e7ace87d7f2" |

  Scenario Outline: Request items ordered by field values
    Given the following INNM dosages exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "innm_dosage:read"
    And my client type is "NHS"
    When I request first 10 INNM dosages sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field        | direction  | expected_value                | alternate_value               |
      | insertedAt   | ascending  | "2017-07-14T19:25:38.000000Z" | "2018-09-27T18:22:20.000000Z" |
      | insertedAt   | descending | "2018-09-27T18:22:20.000000Z" | "2017-07-14T19:25:38.000000Z" |

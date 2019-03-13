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
      | field        | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           |
      | databaseId   | "7679e99c-07a9-448a-ad74-93fea714ccb5" | "7679e99c-07a9-448a-ad74-93fea714ccb5" | "9d2005d2-d237-49ab-a991-39d9826181e6" | "7679e99c-07a9-448a-ad74-93fea714ccb5" | "9d2005d2-d237-49ab-a991-39d9826181e6" |
      | name         | "Спіро"                                | "Спіронолактон"                        | "Метформін"                            | "12a35fd1-7cc1-4332-9bfa-868e5b25f33d" | "0bb92667-eb2f-4ad9-a18a-51298cacd03c" |

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

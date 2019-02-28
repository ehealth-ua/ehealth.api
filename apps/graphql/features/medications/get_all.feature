Feature: Get all medications

  Scenario Outline: Request items filtered by condition
    Given the following medications exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "medication:read"
    And my client type is "NHS"
    When I request first 10 medications where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId | "85a3f45f-1cfa-4595-ac57-79a9d39ee329" | "85a3f45f-1cfa-4595-ac57-79a9d39ee329" | "4c3f59da-727a-48cf-8e7c-eb5b36578133" |
      | name       | "полі"                                 | "Полізамін"                            | "Бупропіон"                            |
      | isActive   | true                                   | true                                   | false                                  |
      | form       | "TABLET"                               | "TABLET"                               | "AEROSOL_FOR_INHALATION"               |


  Scenario Outline: Request items filtered by condition on INNM Dosage
    Given the following INNM dosages exist:
      | databaseId                 | <field>           |
      | <alternate_association_id> | <alternate_value> |
      | <expected_association_id>  | <expected_value>  |
    And the following medications exist:
      | databaseId     |
      | <alternate_id> |
      | <expected_id>  |
    And the following medication ingredients exist:
      | parentId       | medicationChildId          |
      | <alternate_id> | <alternate_association_id> |
      | <expected_id>  | <expected_association_id>  |
    And my scope is "medication:read"
    And my client type is "NHS"
    When I request first 10 medications where <field> of the associated innmDosages is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | field      | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           | expected_association_id                | alternate_association_id               |
      | databaseId | "847c29b8-3ec9-400d-9c4c-5267efd40ed2" | "141abdc9-3a1a-4406-8a2a-8325a01b12f1" | "33c09e0b-3413-4f64-8913-f22231a0db1e" | "141abdc9-3a1a-4406-8a2a-8325a01b12f1" | "2d412207-d7b6-4bea-a4a7-c3c8435303bc" | "847c29b8-3ec9-400d-9c4c-5267efd40ed2" | "398c9584-920e-488c-a7e1-3cf118ab3111" |
      | name       | "етіл"                                 | "Діетіламід"                           | "Амідарон"                             | "0a1a280f-2520-4cd2-851a-9e135ec056f4" | "679b702a-9ea8-49d2-b55f-474935e51b38" | "c96aab66-866f-4bc7-b14d-7b3497d661a3" | "706ef40c-c27d-4bc2-9011-2d462896ffd4" |

  Scenario: Request items filtered by manufacturer's name
    Given the following medications exist:
      | databaseId     | manufacturer      |
      | "7213a16c-6c8e-428e-a1f1-4d2d0c3bf811" | {"name": "ТОВ \"Дослідний завод \"ГНЦЛС\"", "country": "UA"}    |
      | "d5628b3b-9761-46a9-bab2-d5721f58de33" | {"name": "ПАТ \"Київський вітамінний завод\"", "country": "UA"} |
    And my scope is "medication:read"
    And my client type is "NHS"
    When I request first 10 medications where name of the associated manufacturer is "вітамінний завод"
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "d5628b3b-9761-46a9-bab2-d5721f58de33"

  Scenario Outline: Request items ordered by field values
    Given the following medications exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "medication:read"
    And my client type is "NHS"
    When I request first 10 medications sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | direction  | expected_value                | alternate_value               |
      | insertedAt | ascending  | "2016-01-15T14:00:00.000000Z" | "2017-05-13T17:00:00.000000Z" |
      | insertedAt | descending | "2017-05-13T17:00:00.000000Z" | "2016-01-15T14:00:00.000000Z" |
      | name       | ascending  | "Амідарон"                    | "Нітрогліцерин"               |
      | name       | descending | "Нітрогліцерин"               | "Амідарон"                    |

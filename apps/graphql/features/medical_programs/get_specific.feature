Feature: Get specific medical program

  Scenario Outline: Request own fields
    Given the following medical programs exist:
      | databaseId    | <field> |
      | <database_id> | <value> |
    And my scope is "medical_program:read"
    When I request <field> of the medical program where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | database_id                            | field      | value                                  |
      | "b1b4a2ac-e133-4e9f-bf51-18ce1288c6a0" | databaseId | "b1b4a2ac-e133-4e9f-bf51-18ce1288c6a0" |
      | "d703c4a6-a1b4-4c26-9c94-0b06ba82bd96" | name       | "Доступні ліки"                        |
      | "c5ba7819-01e7-4431-88c0-b9c59ba3636a" | isActive   | true                                   |
      | "48b37395-e71d-4a2a-bfb9-90fbc1aab670" | insertedAt | "2018-03-10T02:13:00.000000"           |
      | "48b37395-e71d-4a2a-bfb9-90fbc1aab670" | updatedAt  | "2018-05-31T01:36:01.000000"           |

Feature: Get all medical programs

  Scenario: Request all items
    Given there are 2 medical programs exist
    And my scope is "medical_program:read"
    When I request first 10 medical programs
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario Outline: Request items filtered by condition
    Given the following medical programs exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "medical_program:read"
    When I request first 10 medical programs where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId | "2fded273-ee70-4b1a-a64e-bef6eaee2c4e" | "2fded273-ee70-4b1a-a64e-bef6eaee2c4e" | "6b31e3af-9c24-4991-9ef3-dbec0494e589" |
      | name       | "ліки"                                 | "Доступні ліки"                        | "Безкоштовні вакцини"                  |
      | isActive   | true                                   | true                                   | false                                  |

  Scenario Outline: Request items ordered by field values
    Given the following medical programs exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "medical_program:read"
    When I request first 10 medical programs sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | direction  | expected_value                | alternate_value               |
      | insertedAt | ascending  | "2017-01-24T19:15:01.000000Z" | "2018-04-21T12:29:05.000000Z" |
      | insertedAt | descending | "2018-04-21T12:29:05.000000Z" | "2017-01-24T19:15:01.000000Z" |
      | name       | ascending  | "Безкоштовні вакцини"         | "Доступні ліки"               |
      | name       | descending | "Доступні ліки"               | "Безкоштовні вакцини"         |

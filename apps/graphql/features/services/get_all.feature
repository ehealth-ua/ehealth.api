Feature: Get all services

  Scenario Outline: Request items filtered by condition
    Given the following services exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request first 10 services where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId | "85a3f45f-1cfa-4595-ac57-79a9d39ee329" | "85a3f45f-1cfa-4595-ac57-79a9d39ee329" | "4c3f59da-727a-48cf-8e7c-eb5b36578133" |
      | name       | "нейросоно"                            | "Нейросонографія"                      | "Ехоенцефалографія"                    |
      | isActive   | true                                   | true                                   | false                                  |
      | code       | "AF2"                                  | "AF2 01"                               | "BF2"                                  |
      | category   | "УЗі"                                  | "УЗІ кишечника"                        | "аналіз крові"                         |

  Scenario Outline: Request items ordered by field values
    Given the following services exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request first 10 services sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | direction  | expected_value                | alternate_value               |
      | insertedAt | ascending  | "2016-01-15T14:00:00.000000Z" | "2017-05-13T17:00:00.000000Z" |
      | insertedAt | descending | "2017-05-13T17:00:00.000000Z" | "2016-01-15T14:00:00.000000Z" |
      | name       | ascending  | "Ехоенцефалографія"           | "Нейросонографія"             |
      | name       | descending | "Нейросонографія"             | "Ехоенцефалографія"           |
      | code       | ascending  | "AF2"                         | "BF2"                         |
      | code       | descending | "BF2"                         | "BF1"                         |

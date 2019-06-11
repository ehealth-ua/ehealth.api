Feature: Get all program services

  Scenario Outline: Request items filtered by condition
    Given the following program services exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "program_service:read"
    And my client type is "NHS"
    When I request first 10 program services where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field          | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId     | "fbdf1011-a1ec-1ba4-8c60-2a8669bca667" | "fbdf1011-a1ec-1ba4-8c60-2a8669bca667" | "4c3f59da-727a-48cf-8e7c-eb5b36578133" |
      | isActive       | true                                   | true                                   | false                                  |
      | requestAllowed | false                                  | false                                  | true                                   |

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And the following program services are associated with <association_entity> accordingly:
      | databaseId     |
      | <alternate_id> |
      | <expected_id>  |
    And my scope is "program_service:read"
    And my client type is "NHS"
    When I request first 10 program services where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field | field      | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           |
      | services           | service           | name       | "білірубін"                            | "Аналіз на білірубін"                  | "Аналіз крові"                         | "68d2b73f-3b45-4f23-8551-645186b7d4b3" | "a2bf5782-0fcf-465b-8c7f-18f855ae3f14" |
      | services           | service           | code       | "AA"                                   | "AA 2"                                 | "A 2"                                  | "1a400a93-a2c0-40bc-bbe9-5f1c99a92a6b" | "1dc64ea3-0b4b-4c27-b31e-4bd2c41f8a97" |
      | services           | service           | isActive   | true                                   | true                                   | false                                  | "8a85364d-6656-4925-9c59-b710cdf120dc" | "b6d9c740-81ec-4853-9e9d-9c99c9dc883b" |
      | services           | service           | category   | "counselling"                          | "counselling"                          | "education"                            | "e8415187-8447-4217-93bd-d9d46b6909bc" | "d8bf7de7-1118-438b-9bc8-eda522b29989" |
      | service groups     | serviceGroup      | databaseId | "12a7de65-7847-4c6f-9ff5-42953be8441b" | "12a7de65-7847-4c6f-9ff5-42953be8441b" | "28cf3260-7b80-442c-9875-e01aa89e85c0" | "79af5c3c-491e-4a99-a823-a68719b95048" | "61fd094c-087e-44fb-b6df-2417a61a7354" |
      | service groups     | serviceGroup      | name       | "Загальні"                             | "Загальні обстеження"                  | "Узі"                                  | "7b2c70f5-1f10-40ba-837e-9216f9bf0963" | "38c38303-7d74-4534-b4a8-2b6e9e769f6f" |
      | service groups     | serviceGroup      | code       | "2А"                                   | "2АА"                                  | "АА"                                   | "b99ff73b-23c0-448e-ac91-b7a011654fac" | "a58e844e-329c-4886-8e2c-ae3a097f4a96" |
      | service groups     | serviceGroup      | isActive   | true                                   | true                                   | false                                  | "6de0f934-6cd7-4490-92bd-7ed13dbe1c3b" | "6abcabd4-445d-48f0-92f3-92fac815ebdb" |
      | medical programs   | medicalProgram    | databaseId | "982e0cc2-f94e-4602-9cb7-1a100c1a651c" | "982e0cc2-f94e-4602-9cb7-1a100c1a651c" | "112e0cc2-f94e-4602-9cb7-1a100c1a111c" | "0f647639-8eeb-45e8-ba54-1750f4d438dc" | "41cfd083-25b4-47b3-96f3-e0e622f9943b" |
      | medical programs   | medicalProgram    | name       | "Доступні"                             | "Доступні ліки"                        | "Ліки"                                 | "44428031-0a26-49de-9a2f-59779c5fe233" | "7e2b4deb-e292-471b-863f-0ccee8edbf32" |
      | medical programs   | medicalProgram    | isActive   | true                                   | true                                   | false                                  | "15f07ce4-e096-4c59-b8f2-108e38ce1b7c" | "0bfab45a-6b02-4c07-9bf9-fd38cbcf7767" |

Scenario Outline: Request items ordered by field values
    Given the following program services exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "program_service:read"
    And my client type is "NHS"
    When I request first 10 program services sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field         | direction  | expected_value                | alternate_value               |
      | consumerPrice | ascending  | 300.0                         | 5000.0                        |
      | consumerPrice | descending | 5000.0                        | 300.0                         |
      | insertedAt    | ascending  | "2016-01-15T14:00:00.000000Z" | "2017-05-13T17:00:00.000000Z" |
      | insertedAt    | descending | "2017-05-13T17:00:00.000000Z" | "2016-01-15T14:00:00.000000Z" |

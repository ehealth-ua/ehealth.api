Feature: Get specific program service

  Scenario Outline: Request own fields
    Given the following program service exist:
      | databaseId    | <field> |
      | <database_id> | <value> |
    And my scope is "program_service:read"
    And my client type is "NHS"
    When I request <field> of the program service where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | database_id                            | field          | value                                  |
      | "7a23c791-ae92-4769-b873-94c5167d1b2e" | databaseId     | "7a23c791-ae92-4769-b873-94c5167d1b2e" |
      | "6c6b80f4-b2c2-44ea-9cb6-76c3c71949e1" | consumerPrice  | 400.0                                  |
      | "765334a8-290a-4c0b-a368-5477eacefc2a" | description    | "тільки для чоловіків"                 |
      | "ac0d78ca-8fd6-4aff-8389-f421c7c5a091" | requestAllowed | true                                   |
      | "ac0d78ca-8fd6-4aff-8389-f421c7c5a091" | isActive       | true                                   |
      | "0d5596d4-ea91-4975-bd8e-2c5b2eac648c" | insertedAt     | "2016-01-04T22:49:12.000000Z"          |
      | "a4922db2-3f1d-47d0-963d-3b9a7760e8ad" | updatedAt      | "2018-11-24T11:38:46.000000Z"          |

  Scenario Outline: Request one-to-one association fields
    Given the following <association_entity> exist:
      | databaseId       |
      | <association_id> |
    And the following program service are associated with <association_entity> accordingly:
      | databaseId    |
      | <database_id> |
    And my scope is "program_service:read"
    And my client type is "NHS"
    When I request databaseId of the <association_field> of the program service where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the databaseId in the <association_field> of the requested item should be <association_id>

    Examples:
      | database_id                            | association_entity | association_field | association_id                         |
      | "5bf6aa32-312b-400a-94ee-ac13d6e56321" | service            | service           | "1366fda3-b23e-487c-bcf2-5089d6bd2d01" |
      | "5bf6aa32-312b-400a-94ee-ac13d6e56321" | service groups     | serviceGroup      | "25df1d6a-f394-4f95-bacc-20cc85d17505" |
      | "5bf6aa32-312b-400a-94ee-ac13d6e56321" | medical program    | medicalProgram    | "30dc0954-33e7-4dd4-89d6-53975f8b1482" |

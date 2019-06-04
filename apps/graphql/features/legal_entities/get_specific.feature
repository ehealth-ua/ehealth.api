Feature: Get specific legal entity

  Scenario Outline: Request own fields
    Given the following legal entities exist:
      | databaseId                             | <field> |
      | "46fac56d-300f-43f4-86c7-2b1ac40d63a5" | <value> |
    And my scope is "legal_entity:read"
    When I request <field> of the legal entity where databaseId is "46fac56d-300f-43f4-86c7-2b1ac40d63a5"
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | field             | value                                  |
      | databaseId        | "46fac56d-300f-43f4-86c7-2b1ac40d63a5" |
      | email             | "example@example.com"                  |
      | website           | "https://example.com/"                 |
      | receiverFundsCode | "088912"                               |
      | beneficiary       | "Марко Вовчок"                         |
      | nhsVerified       | false                                  |
      | nhsReviewed       | true                                   |
      | nhsComment        | "Lorem ipsum"                          |
      | type              | "MSP"                                  |
      | status            | "ACTIVE"                               |
      | misVerified       | "VERIFIED"                             |
      | insertedAt        | "2018-03-10T02:13:00.000000Z"          |
      | updatedAt         | "2018-05-31T01:36:01.000000Z"          |

  Scenario Outline: Request associated owner
    Given the following legal entities exist:
      | databaseId                             |
      | "05fbbd71-9c4a-48a0-957b-e63826487740" |
    And the following employees exist:
      | databaseId    | employeeType    | legalEntityId                          |
      | <database_id> | <employee_type> | "05fbbd71-9c4a-48a0-957b-e63826487740" |
    And my scope is "legal_entity:read"
    When I request databaseId of the owner of the legal entity where databaseId is "05fbbd71-9c4a-48a0-957b-e63826487740"
    Then no errors should be returned
    And I should receive requested item
    And the databaseId in the owner of the requested item should be <database_id>

    Examples:
      | database_id                            | employee_type    |
      | "ea29cca6-3767-4077-bd93-b1fa084b7d62" | "OWNER"          |
      | "ea29cca6-3767-4077-bd93-b1fa084b7d62" | "PHARMACY_OWNER" |

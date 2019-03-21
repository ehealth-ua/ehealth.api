Feature: Get specific employee

  Scenario: Request with NHS client
    Given the following employees exist:
      | databaseId                             |
      | "bfdf7bd5-c565-4a1a-8155-240b6436a29e" |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request employee where databaseId is "bfdf7bd5-c565-4a1a-8155-240b6436a29e"
    Then no errors should be returned
    And I should receive requested item
    And the databaseId of the requested item should be "bfdf7bd5-c565-4a1a-8155-240b6436a29e"

  Scenario: Request belonging item with MSP client
    Given the following legal entities exist:
      | databaseId                             | type   |
      | "68730b25-b98b-4d39-9976-bce26ea5b197" | "MSP"  |
    And the following employees exist:
      | databaseId                             | legalEntityId                          |
      | "1cdae59d-bbcc-4a02-bb05-f482e6f2a9cb" | "68730b25-b98b-4d39-9976-bce26ea5b197" |
    And my scope is "employee:read"
    And my client type is "MSP"
    And my client ID is "68730b25-b98b-4d39-9976-bce26ea5b197"
    When I request employee where databaseId is "1cdae59d-bbcc-4a02-bb05-f482e6f2a9cb"
    Then no errors should be returned
    And I should receive requested item
    And the databaseId of the requested item should be "1cdae59d-bbcc-4a02-bb05-f482e6f2a9cb"

  Scenario: Request not belonging item with MSP client
    Given the following legal entities exist:
      | databaseId                             | type  |
      | "4c2de702-f690-4dc2-a0e7-abc543bebe8d" | "MSP" |
      | "c4825b93-15f9-4662-bc05-115790e9a61e" | "MSP" |
    And the following employees exist:
      | databaseId                             | legalEntityId                |
      | "c1ede0cc-53e7-4e09-a515-b341012eeb21" | "c4825b93-15f9-4662-bc05-115790e9a61e" |
    And my scope is "employee:read"
    And my client type is "MSP"
    And my client ID is "4c2de702-f690-4dc2-a0e7-abc543bebe8d"
    When I request employee where databaseId is "c1ede0cc-53e7-4e09-a515-b341012eeb21"
    Then no errors should be returned
    And I should not receive requested item

  Scenario: Request with incorrect client
    Given the following employees exist:
      | databaseId                             |
      | "d3855123-4ad7-42f2-aa72-6af97b00249b" |
    And my scope is "employee:read"
    And my client type is "MIS"
    When I request employee where databaseId is "d3855123-4ad7-42f2-aa72-6af97b00249b"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario Outline: Request own fields
    Given the following employees exist:
      | databaseId    | <field> |
      | <database_id> | <value> |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request <field> of the employee where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | database_id                            | field        | value                                  |
      | "abce491a-d6e2-4e7d-90b6-6ad11c6d25b6" | databaseId   | "abce491a-d6e2-4e7d-90b6-6ad11c6d25b6" |
      | "54c5c12c-2dbb-49ee-9e86-f8e018ff1715" | position     | "Лікар"                                |
      | "dd3ec3d1-af13-48c0-8e48-f757bcca5c75" | startDate    | "1995-01-07"                           |
      | "03f89d05-c203-46cc-9521-628736a12850" | endDate      | "2017-10-31"                           |
      | "eea81205-68f7-4b9a-b052-7ff3dfd6b2d3" | isActive     | true                                   |
      | "74d10c3e-f3f6-4f48-985b-ab5277e9f0b6" | employeeType | "DOCTOR"                               |
      | "5b148af1-1002-40ee-9778-e8c775bd0f91" | status       | "APPROVED"                             |
      | "3fe7ea71-fc43-408d-a711-13ead3e00247" | insertedAt   | "2017-01-04T22:49:12.000000Z"          |
      | "d46d771c-4d74-4c7c-a7da-cc21a275bb61" | updatedAt    | "2018-10-24T11:38:46.000000Z"          |

  Scenario Outline: Request one-to-one association fields
    Given the following <association_entity> exist:
      | databaseId       |
      | <association_id> |
    And the following employees are associated with <association_entity> accordingly:
      | databaseId    |
      | <database_id> |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request databaseId of the <association_field> of the employee where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the databaseId in the <association_field> of the requested item should be <association_id>

    Examples:
      | database_id                            | association_entity | association_field | association_id                         |
      | "0292ec5e-71f2-413c-9665-0588af353c78" | parties            | party             | "3c90c22e-363b-40e3-b2af-06e0d1edb6d0" |
      | "9cb9fef7-449b-4a29-bccc-c9b6cfc858a5" | divisions          | division          | "1528b040-f293-430f-9429-3ac2ebe1b355" |
      | "1e712d60-b74b-4cf9-839b-6c895b88deb4" | legal entities     | legalEntity       | "a0bcbe09-b71f-4a0a-97fe-282a7fa8eed3" |

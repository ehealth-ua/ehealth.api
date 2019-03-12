Feature: Get specific INNM

  Scenario: Request with NHS client
    Given the following INNMs exist:
      | databaseId                             |
      | "6a2896f8-8bc9-4839-a8d9-28d467d579b9" |
    And my scope is "innm:read"
    And my client type is "NHS"
    When I request INNM where databaseId is "6a2896f8-8bc9-4839-a8d9-28d467d579b9"
    Then no errors should be returned
    And I should receive requested item
    And the databaseId of the requested item should be "6a2896f8-8bc9-4839-a8d9-28d467d579b9"

  Scenario: Request with incorrect client
    Given the following INNMs exist:
      | databaseId                             |
      | "7d2bd4f7-ea29-4ff1-9491-6f23bccd0e1f" |
    And my scope is "innm:read"
    And my client type is "MIS"
    When I request INNM where databaseId is "7d2bd4f7-ea29-4ff1-9491-6f23bccd0e1f"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario Outline: Request own fields
    Given the following INNMs exist:
      | databaseId    | <field> |
      | <database_id> | <value> |
    And my scope is "innm:read"
    And my client type is "NHS"
    When I request <field> of the INNM where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | database_id                            | field        | value                                  |
      | "3d688239-2127-4f82-a1b4-8b69d249f164" | databaseId   | "3d688239-2127-4f82-a1b4-8b69d249f164" |
      | "ea4bb6d4-6a66-46be-aff4-6c980b5687c9" | sctid        | "12345678"                             |
      | "dc5140f6-6cd9-431e-aa65-d550bc33f43b" | name         | "Нітрогліцерин"                        |
      | "fc81e2c4-c68e-4b1e-82d4-eabbd921d228" | nameOriginal | "Nitroglycerin"                        |
      | "a2bf97c5-23b8-4efd-9d67-de5fda62f670" | isActive     | true                                   |

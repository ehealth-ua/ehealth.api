Feature: Get specific service

  Scenario Outline: Request own fields
    Given the following services exist:
      | databaseId    | <field> |
      | <database_id> | <value> |
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request <field> of the service where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | database_id                            | field                | value                                  |
      | "27dc8db2-7502-4dab-6806-e743ce670950" | databaseId           | "27dc8db2-7502-4dab-6806-e743ce670950" |
      | "6c6b80f4-b2c2-44ea-5cb6-76c3c71949e1" | name                 | "Ехоенцефалографія"                    |
      | "765334a8-290a-4c0b-a368-5477eacefc2a" | code                 | "AF2 01"                               |
      | "765334a8-290a-1c0b-b368-5477eacafc21" | category             |"diagnostic_procedure"                  |
      | "ac0d78ca-8fd6-2aff-8389-f421c7c5a011" | isComposition        | true                                   |
      | "bc0d78ca-7fd6-3aff-6389-f421c7c5a021" | requestAllowed       | true                                   |
      | "cc0d78ca-6fd6-4aff-5389-f421c7c5a031" | isActive             | true                                   |
      | "0d5596d4-ea91-4975-bd8e-2c5b2eac648c" | insertedAt           | "2017-01-04T22:49:12.000000Z"          |
      | "a4922db2-3f1d-47d0-963d-3b9a7760e8ad" | updatedAt            | "2018-10-24T11:38:46.000000Z"          |

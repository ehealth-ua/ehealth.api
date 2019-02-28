Feature: Get specific medication

  Scenario Outline: Request own fields
    Given the following medications exist:
      | databaseId    | <field> |
      | <database_id> | <value> |
    And my scope is "medication:read"
    And my client type is "NHS"
    When I request <field> of the medication where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | database_id                            | field                | value                                  |
      | "27dc8db2-7502-4dab-9806-e743ce670950" | databaseId           | "27dc8db2-7502-4dab-9806-e743ce670950" |
      | "6c6b80f4-b2c2-44ea-9cb6-76c3c71949e1" | name                 | "Полізамін"                            |
      | "ff521e40-2f97-4581-bcb7-35f6f9deaeda" | form                 | "TABLET"                               |
      | "ba9be5a0-0647-4d18-94c6-fb51122f4a7b" | packageQty           | 30                                     |
      | "6f575448-bbd9-4bd3-b507-c259968bd9c1" | packageMinQty        | 10                                     |
      | "dfd37809-01d8-4464-8629-5b9b893b4e04" | certificate          | "12345667890"                          |
      | "eabe6ac6-4bd2-46c8-88b4-633425305f9e" | certificateExpiredAt | "2012-04-17"                           |
      | "ac0d78ca-8fd6-4aff-8389-f421c7c5a091" | isActive             | true                                   |
      | "0d5596d4-ea91-4975-bd8e-2c5b2eac648c" | insertedAt           | "2017-01-04T22:49:12.000000Z"          |
      | "a4922db2-3f1d-47d0-963d-3b9a7760e8ad" | updatedAt            | "2018-10-24T11:38:46.000000Z"          |

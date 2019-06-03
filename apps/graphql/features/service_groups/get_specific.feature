Feature: Get specific service group

  Scenario Outline: Request own fields
    Given the following service groups exist:
      | databaseId    | <field> |
      | <database_id> | <value> |
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request <field> of the service group where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | database_id                            | field          | value                                  |
      | "27dc8db2-7502-4dab-9806-e743ce670950" | databaseId     | "27dc8db2-7502-4dab-9806-e743ce670950" |
      | "6c6b80f4-b2c2-44ea-9cb6-76c3c71949e1" | name           | "Діагностичні інструментальні"         |
      | "765334a8-290a-4c0b-a368-5477eacefc2a" | code           | "1AAA"                                 |
      | "ac0d78ca-8fd6-4aff-8389-f421c7c5a091" | requestAllowed | true                                   |
      | "ac0d78ca-8fd6-4aff-8389-f421c7c5a091" | isActive       | true                                   |
      | "0d5596d4-ea91-4975-bd8e-2c5b2eac648c" | insertedAt     | "2017-01-04T22:49:12.000000Z"          |
      | "a4922db2-3f1d-47d0-963d-3b9a7760e8ad" | updatedAt      | "2018-10-24T11:38:46.000000Z"          |

  Scenario: Request code field
    Given the following service groups exist:
      | databaseId                             | code  |
      | "27dc8db2-7502-4dab-9806-e743ce670950" | "2FA" |
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request code of the service group where databaseId is "27dc8db2-7502-4dab-9806-e743ce670950"
    Then no errors should be returned
    And I should receive requested item
    And the code of the requested item should be "2FA"

  Scenario Outline: Request one-to-one association fields
    Given the following <association_entity> exist:
      | databaseId       |
      | <association_id> |
    And the following service groups are associated with <association_entity> accordingly:
      | databaseId    |
      | <database_id> |
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request databaseId of the <association_field> of the service group where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the databaseId in the <association_field> of the requested item should be <association_id>

    Examples:
      | database_id                            | association_entity | association_field | association_id                         |
      | "5bf6aa32-312b-400a-94ee-ac13d6e56321" | service groups     | parentGroup       | "e85b453e-ab44-4c5c-9f6d-53ea297189ed" |

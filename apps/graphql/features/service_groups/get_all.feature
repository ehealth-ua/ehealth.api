Feature: Get all service groups

  Scenario: Request all items
    Given there are 2 service groups exist
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request first 10 service groups
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario Outline: Request items filtered by condition
    Given the following service groups exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request first 10 service groups where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | filter_value                           | expected_value                           | alternate_value                        |
      | databaseId | "2fded273-ee70-4b1a-a64e-bef6eaee2c4e" | "2fded273-ee70-4b1a-a64e-bef6eaee2c4e"   | "6b31e3af-9c24-4991-9ef3-dbec0494e589" |
      | name       | "Ультразвукові дослідження"            | "Ультразвукові дослідження в неврології" | "Загальне обстеження хворого"          |
      | code       | "2"                                    | "2F"                                     | "1AA"                                  |
      | isActive   | true                                   | true                                     | false                                  |

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And the following service groups are associated with <association_entity> accordingly:
      | databaseId     |
      | <alternate_id> |
      | <expected_id>  |
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request first 10 service groups where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field | field      | filter_value                           | expected_value                           | alternate_value                        | expected_id                            | alternate_id                           |
      | service groups     | parentGroup       | databaseId | "62c68767-5a4d-49a6-85fd-fefee9fdf32a" | "62c68767-5a4d-49a6-85fd-fefee9fdf32a"   | "c9a8c27f-f179-452c-9beb-c41cef556133" | "e549e93d-e43b-41fc-9493-43c2645c2328" | "20de3ffe-90e7-4997-8ce4-9bb6ffa70b61" |
      | service groups     | parentGroup       | name       | "Ультразвукові дослідження"            | "Ультразвукові дослідження в неврології" | "Загальне обстеження хворого"          | "7a7b112d-b77a-4702-9a71-54ded36ae0ee" | "1ed500d3-35f0-4e85-b58b-a1aef15e94fa" |
      | service groups     | parentGroup       | code       | "2F"                                   | "2FA"                                    | "1AA"                                  | "d4686ebb-63c3-4567-bea0-2faead7023d9" | "5584f70a-d483-402b-8c2f-a5f4624b77cc" |
      | service groups     | parentGroup       | isActive   | true                                   | true                                     | false                                  | "001bb9ec-7f55-4834-8253-b9fae7338552" | "5bb33afe-a528-414c-9553-3ea5ceb1b97b" |

  Scenario Outline: Request items ordered by field values
    Given the following service groups exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "service_catalog:read"
    And my client type is "NHS"
    When I request first 10 service groups sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | direction  | expected_value                | alternate_value               |
      | insertedAt | ascending  | "2017-01-24T19:15:01.000000Z" | "2018-04-21T12:29:05.000000Z" |
      | insertedAt | descending | "2018-04-21T12:29:05.000000Z" | "2017-01-24T19:15:01.000000Z" |
      | name       | ascending  | "Загальне обстеження хворого" | "Ультразвукові дослідження"   |
      | name       | descending | "Ультразвукові дослідження"   | "Загальне обстеження хворого" |

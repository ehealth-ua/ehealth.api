Feature: Get all employees

  Scenario: Request all items with NHS client
    Given there are 2 employees exist
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request first 10 employees
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario: Request belonging items with MSP client
    Given the following legal entities exist:
      | databaseId                             | type  |
      | "0f648909-d79d-447a-8826-f43ba9bbed11" | "MSP" |
      | "6d03663d-5a6a-4a22-bb08-0514e1f20070" | "MSP" |
    And the following employees are associated with legal entities accordingly:
      | databaseId                             |
      | "02e4b709-99cc-4e9e-9276-a8749772d8a3" |
      | "fae7a202-99b5-4856-932b-635771073041" |
    And my scope is "employee:read"
    And my client type is "MSP"
    And my client ID is "0f648909-d79d-447a-8826-f43ba9bbed11"
    When I request first 10 employees
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "02e4b709-99cc-4e9e-9276-a8749772d8a3"

  Scenario: Request with incorrect client
    Given there are 2 employees exist
    And my scope is "employee:read"
    And my client type is "MIS"
    When I request first 10 employees
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following employees exist:
      | databaseId     | <field>           |
      | <alternate_id> | <alternate_value> |
      | <expected_id>  | <expected_value>  |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request first 10 employees where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | field        | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           |
      | databaseId   | "fb5a0cab-4e36-401a-87c5-9852c11f1104" | "fb5a0cab-4e36-401a-87c5-9852c11f1104" | "13e7452f-899f-4a97-a856-93d790570d36" | "fb5a0cab-4e36-401a-87c5-9852c11f1104" | "13e7452f-899f-4a97-a856-93d790570d36" |
      | employeeType | ["DOCTOR", "OWNER"]                    | "DOCTOR"                               | "PHARMACIST"                           | "244052f0-7177-4794-a2fb-8a3476758596" | "a391906e-b687-47d3-a0f6-d8006c617936" |
      | position     | ["P10", "P11"]                         | "P10"                                  | "P1"                                   | "142dea76-b58e-4889-8f79-100cbad385c4" | "dcfd7958-8e61-46be-b861-078c15cf9ecb" |
      | startDate    | "2018-01-01/2018-05-31"                | "2018-04-30"                           | "2018-08-29"                           | "df4dd0b3-f71c-4955-8004-4b151f01f51e" | "761ee7c5-8c3b-45e5-bea2-7527de4e9187" |
      | status       | "APPROVED"                             | "APPROVED"                             | "DISMISSED"                            | "f93dcf7e-bc30-4cf0-8f8a-f70d2f1ef209" | "25a0ac46-0c83-4c37-b798-7b90cee1d7fa" |
      | isActive     | true                                   | true                                   | false                                  | "b04cd9a4-66ba-44e7-8bbb-7f70c11158d0" | "34e59e35-8ad4-4e02-8174-858ba324d76b" |

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And the following employees are associated with <association_entity> accordingly:
      | databaseId     |
      | <alternate_id> |
      | <expected_id>  |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request first 10 employees where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field | field       | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           |
      | parties            | party             | noTaxId     | false                                  | false                                  | true                                   | "3e158779-f927-4971-b76e-e28a3cb854a7" | "22d3e0c8-6054-4e6a-94a9-8e37e23f311f" |
      | divisions          | division          | name        | "door"                                 | "Ajax Door Fixers"                     | "Ajax Locksmiths"                      | "d85b2ab3-2dd9-47cb-b361-b3b44d20f8fc" | "02a0449f-938b-4f89-bebc-183ba4f67547" |
      | legal entities     | legalEntity       | databaseId  | "3f575b71-7e8f-40e2-ace2-f43237a022bd" | "3f575b71-7e8f-40e2-ace2-f43237a022bd" | "0cc08a2d-b971-441b-a993-134420fc4885" | "1e4fdcea-0608-4107-8714-3f033b42e0d3" | "f3189336-2f4d-47a2-869f-7f135dff76d0" |
      | legal entities     | legalEntity       | edrpou      | "1234567890"                           | "1234567890"                           | "0987654321"                           | "7f283005-f838-49ef-ada9-eac6934c0ac4" | "deb2ff2d-9e70-41d1-835e-00abab506767" |
      | legal entities     | legalEntity       | nhsVerified | false                                  | false                                  | true                                   | "57199d5a-c35d-481b-979e-6052c023be3c" | "aec48ca6-de94-4782-8f07-2ef787522175" |
      | legal entities     | legalEntity       | nhsReviewed | true                                   | true                                   | false                                  | "27cad1aa-1637-49d5-b19d-74a9c4a923c4" | "3b5df3a4-28cf-4ace-9f8a-4706f6453877" |

  Scenario Outline: Request items filtered by full text search on the associated party name
    Given the following parties exist:
      | lastName      | firstName | secondName   |
      | "Островський" | "Едуард"  | "Олегович"   |
      | "Островський" | "Олег"    | "Едуардович" |
    And the following employees are associated with parties accordingly:
      | databaseId                             |
      | "4075bfb3-8814-43f4-a868-3541070f26fe" |
      | "ca404f1a-d410-4ad7-ac73-40ee8457a790" |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request first 10 employees where fullName of the associated party is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | filter_value         | expected_id                            |
      | "островський олег"   | "ca404f1a-d410-4ad7-ac73-40ee8457a790" |
      | "едуард островський" | "4075bfb3-8814-43f4-a868-3541070f26fe" |

  Scenario Outline: Request items ordered by field values
    Given the following employees exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request first 10 employees sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field        | direction  | expected_value                | alternate_value               |
      | employeeType | ascending  | "ADMIN"                       | "DOCTOR"                      |
      | employeeType | descending | "DOCTOR"                      | "ADMIN"                       |
      | insertedAt   | ascending  | "2017-07-14T19:25:38.000000Z" | "2018-09-27T18:22:20.000000Z" |
      | insertedAt   | descending | "2018-09-27T18:22:20.000000Z" | "2017-07-14T19:25:38.000000Z" |
      | status       | ascending  | "APPROVED"                    | "DISMISSED"                   |
      | status       | descending | "DISMISSED"                   | "APPROVED"                    |

  Scenario Outline: Request items ordered by association field values
    Given the following <association_entity> exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And the following employees are associated with <association_entity> accordingly:
      | databaseId     |
      | <alternate_id> |
      | <expected_id>  |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request first 10 employees sorted by <field> of the associated <association_field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field | field | direction  | expected_value     | alternate_value    | expected_id                            | alternate_id                           |
      | legal entities     | legalEntity       | name  | ascending  | "Acme Corporation" | "Ajax LLC"         | "0ce4b436-239f-47c5-85d9-44fb10691805" | "86dbbdcb-ee3c-4a97-92e9-b51a1c16c025" |
      | legal entities     | legalEntity       | name  | descending | "Ajax LLC"         | "Acme Corporation" | "d442e986-ca5f-4483-b21f-e3084e583130" | "978da9dd-9c00-49e2-93e5-3301e385803a" |
      | divisions          | division          | name  | ascending  | "Ajax Door Fixers" | "Ajax Locksmiths"  | "485f48f6-8a4e-4e1c-9f00-c456195bd6de" | "4ff55850-df7d-45a7-b578-d0aca8bd1e0b" |
      | divisions          | division          | name  | descending | "Ajax Locksmiths"  | "Ajax Door Fixers" | "f6def663-e640-4fe7-bf83-a6dd18eed97f" | "4804ab5d-1893-4467-a122-5040556b0757" |

  Scenario Outline: Request items ordered by associated party full name
    Given the following parties exist:
      | lastName   | firstName | secondName   |
      | "Шевченко" | "Тарас"   | "Григорович" |
      | "Франко"   | "Іван"    | "Якович"     |
      | "Франко"   | "Тарас"   | "Іванович"   |
    And the following employees are associated with parties accordingly:
      | databaseId                             |
      | "012bf530-e9b6-4faa-8696-0b0432d057b8" |
      | "0fcc4672-e743-4613-83c3-c8836b3ad148" |
      | "1140d61e-c0dc-4f9f-9d7f-875f87fcd774" |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request first 10 employees sorted by fullName of the associated party in <direction> order
    Then no errors should be returned
    And I should receive collection with 3 items
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | direction  | expected_id                            |
      | ascending  | "0fcc4672-e743-4613-83c3-c8836b3ad148" |
      | descending | "012bf530-e9b6-4faa-8696-0b0432d057b8" |

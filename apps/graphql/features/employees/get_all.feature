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
    And the following employees exist:
      | databaseId                             | legalEntityId                |
      | "02e4b709-99cc-4e9e-9276-a8749772d8a3" | "0f648909-d79d-447a-8826-f43ba9bbed11" |
      | "fae7a202-99b5-4856-932b-635771073041" | "6d03663d-5a6a-4a22-bb08-0514e1f20070" |
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
      # | employeeType | ["DOCTOR", "OWNER"]                    | "DOCTOR"                               | "PHARMACIST"                           | "244052f0-7177-4794-a2fb-8a3476758596" | "a391906e-b687-47d3-a0f6-d8006c617936" |
      | status       | "APPROVED"                             | "APPROVED"                             | "DISMISSED"                            | "f93dcf7e-bc30-4cf0-8f8a-f70d2f1ef209" | "25a0ac46-0c83-4c37-b798-7b90cee1d7fa" |
      | isActive     | true                                   | true                                   | false                                  | "b04cd9a4-66ba-44e7-8bbb-7f70c11158d0" | "34e59e35-8ad4-4e02-8174-858ba324d76b" |

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | databaseId                 | <field>           |
      | <alternate_association_id> | <alternate_value> |
      | <expected_association_id>  | <expected_value>  |
    And the following employees exist:
      | databaseId     | <association_field>Id      |
      | <alternate_id> | <alternate_association_id> |
      | <expected_id>  | <expected_association_id>  |
    And my scope is "employee:read"
    And my client type is "NHS"
    When I request first 10 employees where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field | field       | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           | expected_association_id                | alternate_association_id               |
      | legal entities     | legalEntity       | databaseId  | "3f575b71-7e8f-40e2-ace2-f43237a022bd" | "3f575b71-7e8f-40e2-ace2-f43237a022bd" | "0cc08a2d-b971-441b-a993-134420fc4885" | "1e4fdcea-0608-4107-8714-3f033b42e0d3" | "f3189336-2f4d-47a2-869f-7f135dff76d0" | "3f575b71-7e8f-40e2-ace2-f43237a022bd" | "0cc08a2d-b971-441b-a993-134420fc4885" |
      | legal entities     | legalEntity       | edrpou      | "1234567890"                           | "1234567890"                           | "0987654321"                           | "7f283005-f838-49ef-ada9-eac6934c0ac4" | "deb2ff2d-9e70-41d1-835e-00abab506767" | "27bb0495-95d9-4ad7-8f55-c63f07e787dd" | "39f2349b-9f41-4a18-a3c3-9ccbce631661" |
      | legal entities     | legalEntity       | nhsVerified | false                                  | false                                  | true                                   | "57199d5a-c35d-481b-979e-6052c023be3c" | "aec48ca6-de94-4782-8f07-2ef787522175" | "afd4e299-aa90-46de-9334-9c0e467b9626" | "9dda379d-1521-4f6e-83cc-f743a344f3cb" |
      | legal entities     | legalEntity       | nhsReviewed | true                                   | true                                   | false                                  | "27cad1aa-1637-49d5-b19d-74a9c4a923c4" | "3b5df3a4-28cf-4ace-9f8a-4706f6453877" | "eacb20e6-a5ed-438c-975c-66cc1cacb212" | "353de65f-c9d1-4b9e-a449-89b7d92dd6ba" |

  Scenario Outline: Request items filtered by full text search on the associated party name
    Given the following parties exist:
      | databaseId                             | firstName | lastName      | secondName   |
      | "bafb2171-de1a-4ac2-9620-fe66f3c7be04" | "Едуард"  | "Островський" | "Олегович"   |
      | "3c6fb524-294b-4426-8e26-83991983a1ea" | "Олег"    | "Островський" | "Едуардович" |
    And the following employees exist:
      | databaseId                             | partyId                                |
      | "4075bfb3-8814-43f4-a868-3541070f26fe" | "bafb2171-de1a-4ac2-9620-fe66f3c7be04" |
      | "ca404f1a-d410-4ad7-ac73-40ee8457a790" | "3c6fb524-294b-4426-8e26-83991983a1ea" |
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
      | field        | direction  | expected_value               | alternate_value              |
      | employeeType | ascending  | "ADMIN"                      | "DOCTOR"                     |
      | employeeType | descending | "DOCTOR"                     | "ADMIN"                      |
      | insertedAt   | ascending  | "2017-07-14T19:25:38.000000" | "2018-09-27T18:22:20.000000" |
      | insertedAt   | descending | "2018-09-27T18:22:20.000000" | "2017-07-14T19:25:38.000000" |
      | status       | ascending  | "APPROVED"                   | "DISMISSED"                  |
      | status       | descending | "DISMISSED"                  | "APPROVED"                   |

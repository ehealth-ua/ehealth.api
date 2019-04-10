Feature: Get specific employee request

  Scenario: Request with NHS client
    Given the following employee requests exist:
      | databaseId                             |
      | "bfdf7bd5-c565-4a1a-8155-240b6436a29e" |
    And my scope is "employee_request:read"
    And my client type is "NHS"
    When I request employee request where databaseId is "bfdf7bd5-c565-4a1a-8155-240b6436a29e"
    Then no errors should be returned
    And I should receive requested item
    And the databaseId of the requested item should be "bfdf7bd5-c565-4a1a-8155-240b6436a29e"

  Scenario: Request with incorrect client
    Given the following employee requests exist:
      | databaseId                             |
      | "d3855123-4ad7-42f2-aa72-6af97b00249b" |
    And my scope is "employee_request:read"
    And my client type is "MIS"
    When I request employee request where databaseId is "d3855123-4ad7-42f2-aa72-6af97b00249b"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario Outline: Request own fields
    Given the following employee requests exist:
      | databaseId    | <attribute> |
      | <database_id> | <value>     |
    And my scope is "employee_request:read"
    And my client type is "NHS"
    When I request <field> of the employee request where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <expected_value>

    Examples:
      | database_id                            | field        | attribute  | value                                    | expected_value                         |
      | "abce491a-d6e2-4e7d-90b6-6ad11c6d25b6" | databaseId   | databaseId | "abce491a-d6e2-4e7d-90b6-6ad11c6d25b6"   | "abce491a-d6e2-4e7d-90b6-6ad11c6d25b6" |
      | "5b148af1-1002-40ee-9778-e8c775bd0f91" | status       | status     | "APPROVED"                               | "APPROVED"                             |
      | "3fe7ea71-fc43-408d-a711-13ead3e00247" | insertedAt   | insertedAt | "2017-01-04T22:49:12.000000Z"            | "2017-01-04T22:49:12.000000Z"          |
      | "d46d771c-4d74-4c7c-a7da-cc21a275bb61" | updatedAt    | updatedAt  | "2018-10-24T11:38:46.000000Z"            | "2018-10-24T11:38:46.000000Z"          |
      | "a5676d83-23f0-4991-ba90-e9d6612606cc" | birthDate    | data       | {"party": {"birth_date": "1984-07-12"}}  | "1984-07-12"                           |
      | "cf71d598-c39c-4c84-b5e6-72099ca90b02" | email        | data       | {"party": {"email": "valid@email.com"}}  | "valid@email.com"                      |
      | "67564f8c-4059-4116-acb1-b4c1da23e0ea" | firstName    | data       | {"party": {"first_name": "Олександр"}}   | "Олександр"                            |
      | "c9b68e66-9f5f-435d-a1b6-71c9c8f5611d" | secondName   | data       | {"party": {"second_name": "Вікторович"}} | "Вікторович"                           |
      | "117eb7bd-dc41-461b-afe6-e9b9219f2c7f" | lastName     | data       | {"party": {"last_name": "Вірний"}}       | "Вірний"                               |
      | "7e624954-b325-492b-bb08-00948aff55f7" | taxId        | data       | {"party": {"tax_id": "3067305991"}}      | "3067305991"                           |
      | "2a970c99-c470-4184-8411-2cde86842072" | noTaxId      | data       | {"party": {"no_tax_id": true}}           | true                                   |
      | "7a875b91-3d8d-4f03-9aca-44bddc069937" | employeeType | data       | {"employee_type": "DOCTOR"}              | "DOCTOR"                               | 

  Scenario Outline: Request associated fields
    Given the following legal entities exist:
      | databaseId       |
      | <association_id> |
    And the following employee requests exist:
      | databaseId    | data                                  |
      | <database_id> | {"legal_entity_id": <association_id>} |
    And my scope is "employee_request:read"
    And my client type is "NHS"
    When I request databaseId of the <association_field> of the employee request where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the databaseId in the <association_field> of the requested item should be <association_id>

    Examples:
      | database_id                            | association_entity | association_field | association_id                         |
      | "1e712d60-b74b-4cf9-839b-6c895b88deb4" | legal entities     | legalEntity       | "a0bcbe09-b71f-4a0a-97fe-282a7fa8eed3" |

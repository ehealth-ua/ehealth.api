Feature: Get all reimbursement contracts

  Scenario: Request all items with NHS client
    Given there are 2 reimbursement contracts exist
    And there are 10 capitation contracts exist
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contracts
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario: Request belonging items with PHARMACY client
    Given the following legal entities exist:
      | databaseId                             | type  |
      | "eeca6674-5d4b-4351-887b-901d379e8d7a" | "PHARMACY" |
      | "c26c6f9a-de97-45d4-abf2-017dd25a40e0" | "PHARMACY" |
    And the following reimbursement contracts exist:
      | databaseId                             | contractorLegalEntityId                |
      | "81a27fee-7ecd-4c9d-ab47-2c085a711cc4" | "eeca6674-5d4b-4351-887b-901d379e8d7a" |
      | "5f8362d2-36bc-4de2-9e8c-278897b8edb6" | "c26c6f9a-de97-45d4-abf2-017dd25a40e0" |
    And my scope is "contract:read"
    And my client type is "PHARMACY"
    And my client ID is "eeca6674-5d4b-4351-887b-901d379e8d7a"
    When I request first 10 reimbursement contracts
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "81a27fee-7ecd-4c9d-ab47-2c085a711cc4"

  Scenario: Request with incorrect client
    Given there are 2 reimbursement contracts exist
    And my scope is "contract:read"
    And my client type is "MIS"
    When I request first 10 reimbursement contracts
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following reimbursement contracts exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contracts where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field               | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId          | "d4e60768-f48f-4947-b1f4-ae08a248cbd8" | "d4e60768-f48f-4947-b1f4-ae08a248cbd8" | "8e6440c2-dcb6-4f7d-9624-92c44d86f68e" |
      | contractNumber      | "0000-ABEK-1234-5678"                  | "0000-ABEK-1234-5678"                  | "0000-MHPC-8765-4321"                  |
      | status              | "VERIFIED"                             | "VERIFIED"                             | "TERMINATED"                           |
      | startDate           | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |
      | endDate             | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |
      | isSuspended         | false                                  | false                                  | true                                   |

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | databaseId                 | <field>           |
      | <alternate_association_id> | <alternate_value> |
      | <expected_association_id>  | <expected_value>  |
    And the following reimbursement contracts exist:
      | databaseId     | <association_field>Id      |
      | <alternate_id> | <alternate_association_id> |
      | <expected_id>  | <expected_association_id>  |
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contracts where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field     | field        | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           | expected_association_id                | alternate_association_id               |
      | legal entities     | contractorLegalEntity | databaseId   | "02d4d9d3-f498-4ec0-a0c4-70d85f88bbdf" | "6d043c09-c70c-465d-a2ae-d932a3f66195" | "88ef2a75-8f38-4bcd-84fb-358ed1585d41" | "6d043c09-c70c-465d-a2ae-d932a3f66195" | "15852a31-2c9f-46b9-a44a-0574b39b8978" | "02d4d9d3-f498-4ec0-a0c4-70d85f88bbdf" | "eae742fa-4b05-4a92-b705-09260d4b48c8" |
      | legal entities     | contractorLegalEntity | edrpou       | "12345"                                | "1234567890"                           | "0987654321"                           | "405e1669-6243-456b-b904-fe9280268ee8" | "29a6641c-6ad0-4cbc-9261-bb6267339d02" | "e74c806b-598d-4790-b9f1-9a07b846a06c" | "415579bc-2500-419a-924d-6b0b3ba7297d" |
      | legal entities     | contractorLegalEntity | name         | "acme"                                 | "Acme Corporation"                     | "Ajax LLC"                             | "db3f10eb-c7fe-4e57-821f-617ccb27f3eb" | "455d12ff-ff93-48b3-9b34-6f34a12db92a" | "dd18fa01-1c4c-483a-9861-d521bf7f4761" | "70627a21-823f-4c37-87e7-052eca44dafe" |
      | legal entities     | contractorLegalEntity | nhsReviewed  | false                                  | false                                  | true                                   | "5e75cae7-3881-48b7-b881-5361935d3d35" | "85cb9c86-ac7a-44f6-9984-f96bbaec9934" | "09583140-260e-4eae-ac72-5cde32859e39" | "99500ef0-3e37-4f50-a21d-75a9435be5eb" |
      | legal entities     | contractorLegalEntity | nhsVerified  | true                                   | true                                   | false                                  | "6cb36d34-be4e-4f34-80b5-313ab086e8fa" | "2912a791-eae3-4907-81a2-bfcd3b765263" | "c0fa7efb-28e3-4d85-b2bf-4846c6055c64" | "eeeb60cd-dc6d-4bac-a5b7-99ea21212a6c" |
      | medical programs   | medicalProgram        | databaseId   | "85889112-ceac-443b-9c83-440fd6a3c1d6" | "c6a2d8bc-c712-4457-970a-69ab53e19424" | "89753ca9-1b58-4454-a30e-a1f5650be4b3" | "c6a2d8bc-c712-4457-970a-69ab53e19424" | "04cf7b31-a84e-4ef4-ab22-64badf2ab343" | "85889112-ceac-443b-9c83-440fd6a3c1d6" | "da30fba9-dae5-403b-b9fc-c62dd07c09d6" |
      | medical programs   | medicalProgram        | name         | "ліки"                                 | "Доступні ліки"                        | "Безкоштовні вакцини"                  | "c70e7f96-b579-4e4b-be59-3612ad3d0388" | "f0076dbf-c5b5-4f61-8c75-2d0c60a468da" | "6c5ef47e-d9ec-45c9-9cdc-cd3338543849" | "600286e0-df3e-47cb-913b-df57bc7f21d5" |
      | medical programs   | medicalProgram        | isActive     | true                                   | true                                   | false                                  | "2fe64239-4ba4-4297-acef-698a0910680a" | "0fde198f-0bc2-4845-bb01-a84c3e620398" | "c36d5e2f-2c0c-4b12-9b31-3bb8159a6096" | "a3879f80-ff8f-4e2d-b161-f862be34804b" |

  Scenario Outline: Request items ordered by field values
    Given the following reimbursement contracts exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contracts sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field       | direction  | expected_value                | alternate_value               |
      | endDate     | ascending  | "2018-07-12"                  | "2018-11-22"                  |
      | endDate     | descending | "2018-11-22"                  | "2018-07-12"                  |
      | insertedAt  | ascending  | "2016-01-15T14:00:00.000000Z" | "2017-05-13T17:00:00.000000Z" |
      | insertedAt  | descending | "2017-05-13T17:00:00.000000Z" | "2016-01-15T14:00:00.000000Z" |
      | isSuspended | ascending  | false                         | true                          |
      | isSuspended | descending | true                          | false                         |
      | startDate   | ascending  | "2016-08-01"                  | "2016-10-30"                  |
      | startDate   | descending | "2016-10-30"                  | "2016-08-01"                  |
      | status      | ascending  | "TERMINATED"                  | "VERIFIED"                    |
      | status      | descending | "VERIFIED"                    | "TERMINATED"                  |

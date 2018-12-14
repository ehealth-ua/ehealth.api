Feature: Get all reimbursement contract requests

  Scenario: Request all items with NHS client
    Given there are 2 reimbursement contract requests exist
    And there are 10 capitation contract requests exist
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario: Request belonging items with PHARMACY client
    Given the following legal entities exist:
      | databaseId                             | type       |
      | "d3cc177d-8834-41ab-bec6-0dcd1bebaff8" | "PHARMACY" |
      | "2bf7f226-078f-45db-8d47-ff7fe9f1397d" | "PHARMACY" |
    And the following reimbursement contract requests exist:
      | databaseId                             | contractorLegalEntityId                |
      | "14d18157-3f26-45b0-b034-9bd8180eb469" | "d3cc177d-8834-41ab-bec6-0dcd1bebaff8" |
      | "3011e1c9-07b2-4c01-886e-f0b85b665297" | "2bf7f226-078f-45db-8d47-ff7fe9f1397d" |
    And my scope is "contract_request:read"
    And my client type is "PHARMACY"
    And my client ID is "d3cc177d-8834-41ab-bec6-0dcd1bebaff8"
    When I request first 10 reimbursement contract requests
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "14d18157-3f26-45b0-b034-9bd8180eb469"

  Scenario: Request with incorrect client
    Given there are 2 reimbursement contract requests exist
    And my scope is "contract_request:read"
    And my client type is "MSP"
    When I request first 10 reimbursement contract requests
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following reimbursement contract requests exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field          | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId     | "92c5a8c1-1df2-4dc4-abf2-c37cfc6dbad4" | "92c5a8c1-1df2-4dc4-abf2-c37cfc6dbad4" | "ae495e7c-6398-4f4b-905f-9425375b5b5c" |
      | contractNumber | "0000-AEHK-1234-5678"                  | "0000-AEHK-1234-5678"                  | "0000-MPTX-8765-4321"                  |
      | status         | "NEW"                                  | "NEW"                                  | "APPROWED"                             |
      | startDate      | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |
      | endDate        | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |
      # | assigneeId     | "fbce6098-e176-4139-9f97-9555a442c0c4" | "fbce6098-e176-4139-9f97-9555a442c0c4" | "a269bb36-507a-4a50-b297-2fedb88477c2" |

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | databaseId                 | <field>           |
      | <alternate_association_id> | <alternate_value> |
      | <expected_association_id>  | <expected_value>  |
    And the following reimbursement contract requests exist:
      | databaseId     | <association_field>Id      |
      | <alternate_id> | <alternate_association_id> |
      | <expected_id>  | <expected_association_id>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field     | field        | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           | expected_association_id                | alternate_association_id               |
      | employees          | assignee              | databaseId   | "90d4245b-07ee-4a95-bfba-1b62d2ecd30d" | "be1c31fc-55c6-40b1-a67e-92adcde784e1" | "6005c885-4ecf-47db-914d-49ee93e2d0c2" | "be1c31fc-55c6-40b1-a67e-92adcde784e1" | "6005c885-4ecf-47db-914d-49ee93e2d0c2" | "90d4245b-07ee-4a95-bfba-1b62d2ecd30d" | "0e997bf4-7651-4d6e-b3e8-ce84934cb262" |
      # | employees          | assignee              | employeeType | ["DOCTOR", "OWNER"]                    | "DOCTOR"                               | "PHARMACIST"                           | "e8fa7faa-ff55-496b-a2e9-1a5c5aa46647" | "86f16c98-b0e8-45e0-80f2-7c6b6a67b199" | "1acf0627-7dab-4110-aa39-bbfdb38a907b" | "fff08cca-09f8-4e4e-a0eb-dcb248557e8c" |
      | employees          | assignee              | status       | "APPROVED"                             | "APPROVED"                             | "DISMISSED"                            | "6faf4d46-446a-47ba-94db-e54606b7ef63" | "e9064db7-905d-456a-b195-9895ad8a65ba" | "75a96e13-4c1a-4b36-84aa-eb3d86998494" | "e1931ec0-69be-4394-a3c0-6a392e33f4b9" |
      | employees          | assignee              | isActive     | true                                   | true                                   | false                                  | "88a01700-f957-450d-85ec-21bd187599be" | "f18ff75d-9a51-48ce-bdca-ab6cf5af55fe" | "71b0b763-dcac-4f54-8bfb-581d8b96172e" | "37aa9e50-1596-4ddf-801b-bc34c6e2061a" |
      | legal entities     | contractorLegalEntity | databaseId   | "cfc3965c-e7bb-447e-9d80-354f3219ff22" | "ac972e99-2e1e-4ccc-ba45-99aa48687db8" | "28cf3260-7b80-442c-9875-e01aa89e85c0" | "ac972e99-2e1e-4ccc-ba45-99aa48687db8" | "28cf3260-7b80-442c-9875-e01aa89e85c0" | "cfc3965c-e7bb-447e-9d80-354f3219ff22" | "5fd99d7d-b1a8-4fff-b83f-4d617268647e" |
      | legal entities     | contractorLegalEntity | edrpou       | "1234567890"                           | "1234567890"                           | "0987654321"                           | "66314869-66f1-45c2-948d-531491f6b17c" | "09bd6490-d4ff-4201-be77-df8b88eb3d04" | "807c7e3e-17fa-4736-8c10-d6783b5defcf" | "28c08ae7-dd7a-414d-b12b-9db6d05044bc" |
      | legal entities     | contractorLegalEntity | nhsReviewed  | false                                  | false                                  | true                                   | "07b1ecef-81ea-47f8-b16a-e394920a3290" | "fb2f0f53-492d-477d-b62b-bc428da63110" | "55b3ec1f-267a-4643-9459-7621089dab0d" | "d37d4f16-1a15-42a1-b054-281c89f0535e" |
      | legal entities     | contractorLegalEntity | nhsVerified  | true                                   | true                                   | false                                  | "f2f1d6a0-c4d2-4e61-a2c2-adad776d6cce" | "8f260981-0aeb-4d18-a426-18e029becd7b" | "90237d2b-273c-4306-91fa-a3925e4ef4bb" | "d3c92162-b648-4439-a840-2148e9288bdb" |
      | medical programs   | medicalProgram        | databaseId   | "bf2e25d6-63df-4456-991d-983a0322e4aa" | "bd9c7e84-2fff-4d08-9a95-2e774b34241e" | "1e181257-aa03-4227-9f6b-cf04471a9391" | "bd9c7e84-2fff-4d08-9a95-2e774b34241e" | "1e181257-aa03-4227-9f6b-cf04471a9391" | "bf2e25d6-63df-4456-991d-983a0322e4aa" | "d7a6913e-f125-49c2-b0c0-13a864686417" |
      | medical programs   | medicalProgram        | name         | "доступні"                             | "Доступні ліки"                        | "Безкоштовні вакцини"                  | "9d8f5f20-6857-4167-9776-95b873434abd" | "bd75746d-fde7-4064-9a13-57826ce7e2cd" | "3a575fc9-24ba-40d4-8787-19d88ca1beca" | "9e59da23-2a7a-43f0-8d4f-4154d025e27e" |
      | medical programs   | medicalProgram        | isActive     | true                                   | true                                   | false                                  | "fcfcf8a7-ffef-4708-98b2-3cd9e0718d33" | "cc362c95-f839-4bae-b248-b8ca747c0d99" | "66699051-c311-4835-a34d-0f9ca4a07fc4" | "7c9f7db7-7a59-4797-8a1a-1c5ad974215e" |

  Scenario Outline: Request items filtered by nested condition on association
    Given the following <nested_association_entity> exist:
      | databaseId                        | <field>           |
      | <alternate_nested_association_id> | <alternate_value> |
      | <expected_nested_association_id>  | <expected_value>  |
    And the following <association_entity> exist:
      | databaseId                 | <nested_association_field>Id      |
      | <alternate_association_id> | <alternate_nested_association_id> |
      | <expected_association_id>  | <expected_nested_association_id>  |
    And the following reimbursement contract requests exist:
      | databaseId     | <association_field>Id      |
      | <alternate_id> | <alternate_association_id> |
      | <expected_id>  | <expected_association_id>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests where <field> of the <nested_association_field> nested in associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | nested_association_entity | association_field | nested_association_field | field       | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           | expected_association_id                | alternate_association_id               | expected_nested_association_id         | alternate_nested_association_id        |
      | employees          | legal entities            | assignee          | legalEntity              | databaseId  | "4f03f4f1-987b-43d0-931b-d84b611516cd" | "f79664c1-cd70-475b-bb76-ccc32124418e" | "b58f4009-6b46-4c0c-8f08-f94973a1379c" | "b8662e46-2ed7-44eb-a787-2312ce102e45" | "6b5a2e67-3035-4cd5-b299-65d600a2c0da" | "7d178705-1480-4fb8-b4ec-971c45602fa3" | "62aadbdd-9308-4107-9c33-24971509fb4b" | "4f03f4f1-987b-43d0-931b-d84b611516cd" | "b58f4009-6b46-4c0c-8f08-f94973a1379c" |
      | employees          | legal entities            | assignee          | legalEntity              | edrpou      | "1234567890"                           | "1234567890"                           | "0987654321"                           | "5608145b-dc9c-45bb-b0db-2763d657d8db" | "95c762b4-165a-4f68-b315-be853c6f7e3d" | "2ee02fd1-53cf-422a-a213-045a89bcc300" | "e289e563-8d86-49c2-90fe-acf1f8ce4cef" | "eec345ed-0a3b-4618-ad13-b53488aa797b" | "a60ad85b-2916-4507-bd9a-0691dddbc94d" |
      | employees          | legal entities            | assignee          | legalEntity              | nhsVerified | false                                  | false                                  | true                                   | "735a12b7-6f2b-4598-aa72-2d5caf8b9990" | "ab15f742-1169-4a5f-a5d8-58595aff369f" | "20288274-f548-472e-bc31-e84d090346c2" | "fe3299f4-59d4-4912-ad44-8e75fc9eb9bf" | "f8e76429-1456-4b0e-ba53-519483bda627" | "6d2e60ff-86b9-4f0c-9b5f-c9f71572eef7" |
      | employees          | legal entities            | assignee          | legalEntity              | nhsReviewed | true                                   | true                                   | false                                  | "bbd5faaf-b7f5-45a9-b1bb-ea8bc20327f6" | "3ee65b3c-6de0-4d5e-a786-77fd1da7fa23" | "82448b90-9820-4d8b-8510-dbcdeac4db00" | "64751ae2-8fc6-4918-97cc-f3e17702a782" | "da949fd8-8cab-42be-85ef-f736cfd85c12" | "91829dcd-53f8-468e-a123-851cf4043f07" |

  Scenario Outline: Request items ordered by field values
    Given the following reimbursement contract requests exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | direction  | expected_value               | alternate_value              |
      | endDate    | ascending  | "2018-07-12"                 | "2018-11-22"                 |
      | endDate    | descending | "2018-11-22"                 | "2018-07-12"                 |
      | insertedAt | ascending  | "2016-01-15T14:00:00.000000" | "2017-05-13T17:00:00.000000" |
      | insertedAt | descending | "2017-05-13T17:00:00.000000" | "2016-01-15T14:00:00.000000" |
      | startDate  | ascending  | "2016-08-01"                 | "2016-10-30"                 |
      | startDate  | descending | "2016-10-30"                 | "2016-08-01"                 |


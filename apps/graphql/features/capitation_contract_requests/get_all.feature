Feature: Get all capitation contract requests

  Scenario: Request all items with NHS client
    Given there are 2 capitation contract requests exist
    And there are 10 reimbursement contract requests exist
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 capitation contract requests
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario: Request belonging items with MSP client
    Given the following legal entities exist:
      | databaseId                             | type  |
      | "07e526e1-077f-4327-aaad-438b7371924d" | "MSP" |
      | "72f7a4dd-e3b8-4db7-834a-71e500227eef" | "MSP" |
    And the following capitation contract requests exist:
      | databaseId                             | contractorLegalEntityId                |
      | "837c8f92-239e-41b8-aa94-3c812738b677" | "07e526e1-077f-4327-aaad-438b7371924d" |
      | "215d322f-c518-4d79-846a-ce81e9152a29" | "72f7a4dd-e3b8-4db7-834a-71e500227eef" |
    And my scope is "contract_request:read"
    And my client type is "MSP"
    And my client ID is "07e526e1-077f-4327-aaad-438b7371924d"
    When I request first 10 capitation contract requests
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "837c8f92-239e-41b8-aa94-3c812738b677"

  Scenario: Request with incorrect client
    Given there are 2 capitation contract requests exist
    And my scope is "contract_request:read"
    And my client type is "MIS"
    When I request first 10 capitation contract requests
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following capitation contract requests exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 capitation contract requests where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field          | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId     | "d19255a9-4703-49a2-9820-215dceda0ff4" | "d19255a9-4703-49a2-9820-215dceda0ff4" | "06ad0e9a-9cda-4751-84ec-02cd962999eb" |
      | contractNumber | "0000-AEHK-1234-5678"                  | "0000-AEHK-1234-5678"                  | "0000-MPTX-8765-4321"                  |
      | status         | "NEW"                                  | "NEW"                                  | "APPROWED"                             |
      | startDate      | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |
      | endDate        | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | databaseId                 | <field>           |
      | <alternate_association_id> | <alternate_value> |
      | <expected_association_id>  | <expected_value>  |
    And the following capitation contract requests exist:
      | databaseId     | <association_field>Id      |
      | <alternate_id> | <alternate_association_id> |
      | <expected_id>  | <expected_association_id>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 capitation contract requests where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field     | field        | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           | expected_association_id                | alternate_association_id               |
      | employees          | assignee              | databaseId   | "db546b7e-4e6a-4d46-930c-b02f41b4af28" | "088ebd4c-1029-4879-94fc-3c105f336e70" | "98b76797-3394-4868-8395-be387d76ff98" | "088ebd4c-1029-4879-94fc-3c105f336e70" | "98b76797-3394-4868-8395-be387d76ff98" | "db546b7e-4e6a-4d46-930c-b02f41b4af28" | "cd7cd90c-4922-4275-8b5a-72ce055dbed8" |
      # | employees          | assignee              | employeeType | ["DOCTOR", "OWNER"]                    | "DOCTOR"                               | "PHARMACIST"                           | "9976bb1c-81e5-46d7-9eec-a8f976d0184e" | "e1971220-942f-4767-ba18-6c2a99a5cf8d" | "b57a36e5-7862-4309-ab25-6cd8fbec70f7" | "5f094f1a-1437-41e3-8ea9-4084e36be01b" |
      | employees          | assignee              | status       | "APPROVED"                             | "APPROVED"                             | "DISMISSED"                            | "cb7a79d6-77f3-49d9-ac35-052d22791e68" | "a97fa716-3d56-4870-9ef4-634666020713" | "6c2b7dfd-f4a0-46f6-b5df-0752e2367065" | "4582ed88-31c2-4642-9d90-5d21ec92f5aa" |
      | employees          | assignee              | isActive     | true                                   | true                                   | false                                  | "24a05d02-b964-44c9-bc48-90b93e0cfa86" | "f3c129d2-b934-4f94-a5d5-a9ca155f7d6f" | "ce8ed847-eb6e-424d-9ada-32ff73c8896f" | "34f27c10-2c8a-4b76-a10c-0ca4b2f5f8dc" |
      | legal entities     | contractorLegalEntity | databaseId   | "12a7de65-7847-4c6f-9ff5-42953be8441b" | "3c68c9c5-af9c-40bd-b889-adeb842f9474" | "28cf3260-7b80-442c-9875-e01aa89e85c0" | "3c68c9c5-af9c-40bd-b889-adeb842f9474" | "6db78127-0cda-4e6b-92b9-095964792e9d" | "12a7de65-7847-4c6f-9ff5-42953be8441b" | "a49c7a14-431d-476e-a360-db5709e18ba3" |
      | legal entities     | contractorLegalEntity | edrpou       | "1234567890"                           | "1234567890"                           | "0987654321"                           | "975a0c44-0b6d-478d-9b68-aba7a1620977" | "1e04fe55-37a6-4ad6-8e0e-772204d4ef91" | "f672c55d-c069-4e4d-8281-21ec70776bda" | "7f3f04bb-5cc2-4dd2-8c17-80e35ef747a1" |
      | legal entities     | contractorLegalEntity | nhsReviewed  | false                                  | false                                  | true                                   | "0e1c51a4-9dbf-452e-ae5b-106631c46c3a" | "589fead8-9574-40bc-865e-5e22ac35f2b1" | "2fbba212-774f-402d-8728-53c30ec03424" | "290723fe-de58-4f7e-9aed-c8f1200c04dc" |
      | legal entities     | contractorLegalEntity | nhsVerified  | true                                   | true                                   | false                                  | "1c0f32d3-e6bb-42d0-909c-7153c1b00091" | "b067ecac-18ca-4c3c-bfdb-170a2b89c517" | "51d8a4df-befd-4199-b063-66ab25b4f7b4" | "983595e4-89ba-4e36-94ce-dc1cf8b66c95" |

  Scenario Outline: Request items filtered by nested condition on association
    Given the following <nested_association_entity> exist:
      | databaseId                        | <field>           |
      | <alternate_nested_association_id> | <alternate_value> |
      | <expected_nested_association_id>  | <expected_value>  |
    And the following <association_entity> exist:
      | databaseId                 | <nested_association_field>Id      |
      | <alternate_association_id> | <alternate_nested_association_id> |
      | <expected_association_id>  | <expected_nested_association_id>  |
    And the following capitation contract requests exist:
      | databaseId     | <association_field>Id      |
      | <alternate_id> | <alternate_association_id> |
      | <expected_id>  | <expected_association_id>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 capitation contract requests where <field> of the <nested_association_field> nested in associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | nested_association_entity | association_field | nested_association_field | field       | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           | expected_association_id                | alternate_association_id               | expected_nested_association_id         | alternate_nested_association_id        |
      | employees          | legal entities            | assignee          | legalEntity              | databaseId  | "ec1c7ae9-5763-4ac4-9769-ed42bf09a622" | "f79664c1-cd70-475b-bb76-ccc32124418e" | "a1608a71-f127-4ab0-be45-0866726b5dca" | "1563f53a-b946-4c7f-9879-96285744916c" | "ac5e0168-5ab2-4678-b232-67bd56e4fb67" | "beab4e25-b8a9-459c-940a-bddd653dd049" | "12aebe25-db8c-4136-b729-0051db271ffe" | "ec1c7ae9-5763-4ac4-9769-ed42bf09a622" | "a1608a71-f127-4ab0-be45-0866726b5dca" |
      | employees          | legal entities            | assignee          | legalEntity              | edrpou      | "1234567890"                           | "1234567890"                           | "0987654321"                           | "a9ef5b9a-c905-485f-bf25-4470a793fe61" | "9bd56a36-a455-45f9-b7b3-4adcfa4a742a" | "828c934e-6bf6-447c-95a7-edf6ea1f8227" | "0170e941-b86a-4c8b-a5cc-3e661aa4bdbb" | "6bacf058-c7a2-4f7b-9f98-003893e0edf1" | "a1dd5bbb-7f5f-4287-91cf-2a0a9b23537e" |
      | employees          | legal entities            | assignee          | legalEntity              | nhsVerified | false                                  | false                                  | true                                   | "7380c6c8-ea20-47f9-8c42-9b8757cceaf7" | "67f3dbed-457c-4dce-a098-e81d368e310a" | "e58d077f-ffbf-4613-bec2-a67298c2ea95" | "f8884322-ed2e-4302-a3da-780151cfe576" | "21b743eb-37c6-4aa9-922d-cbe868814153" | "9ef64ee5-e399-498d-ae60-db92441279c2" |
      | employees          | legal entities            | assignee          | legalEntity              | nhsReviewed | true                                   | true                                   | false                                  | "8b55bd57-b468-485f-9627-a4810faa7a3d" | "59c34c80-70b0-4151-b0f3-052c3c0f65ba" | "1a8e71d0-279d-4abb-8e19-f645763bbf10" | "f7954b1a-3277-4402-a1df-eb0d5559c435" | "c283d6d7-1992-4e1f-927e-3deecec55a5e" | "3878a702-ccb1-4a9d-9240-e1db0873cd5c" |

  Scenario Outline: Request items ordered by field values
    Given the following capitation contract requests exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 capitation contract requests sorted by <field> in <direction> order
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

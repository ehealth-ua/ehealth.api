Feature: Get specific reimbursement contract request

  Scenario: Request with NHS client
    Given the following reimbursement contract requests exist:
      | databaseId                             |
      | "5f8e3a74-24cd-4483-9373-aa52034f2917" |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request reimbursement contract request where databaseId is "5f8e3a74-24cd-4483-9373-aa52034f2917"
    Then no errors should be returned
    And I should receive requested item
    And the databaseId of the requested item should be "5f8e3a74-24cd-4483-9373-aa52034f2917"

  Scenario: Request belonging item with PHARMACY client
    Given the following legal entities exist:
      | databaseId                             | type   |
      | "1b94ce95-b7d9-4056-9170-d2fab034583b" | "PHARMACY"  |
    And the following reimbursement contract requests exist:
      | databaseId                             | contractorLegalEntityId                |
      | "ae795118-3422-45a4-88ad-17f3cb5ebe87" | "1b94ce95-b7d9-4056-9170-d2fab034583b" |
    And my scope is "contract_request:read"
    And my client type is "PHARMACY"
    And my client ID is "1b94ce95-b7d9-4056-9170-d2fab034583b"
    When I request reimbursement contract request where databaseId is "ae795118-3422-45a4-88ad-17f3cb5ebe87"
    Then no errors should be returned
    And I should receive requested item
    And the databaseId of the requested item should be "ae795118-3422-45a4-88ad-17f3cb5ebe87"

  Scenario: Request not belonging item with PHARMACY client
    Given the following legal entities exist:
      | databaseId                             | type  |
      | "c6349af7-d8f3-4a4d-9dac-21e3770cffa7" | "PHARMACY" |
      | "9ed5a994-c06a-47f0-bd04-675f94001295" | "PHARMACY" |
    And the following reimbursement contract requests exist:
      | databaseId                             | contractorLegalEntityId                |
      | "c3267262-9280-4693-8091-9492d16c1048" | "9ed5a994-c06a-47f0-bd04-675f94001295" |
    And my scope is "contract_request:read"
    And my client type is "PHARMACY"
    And my client ID is "c6349af7-d8f3-4a4d-9dac-21e3770cffa7"
    When I request reimbursement contract request where databaseId is "c3267262-9280-4693-8091-9492d16c1048"
    Then no errors should be returned
    And I should not receive requested item

  Scenario: Request with incorrect client
    Given the following reimbursement contract requests exist:
      | databaseId                             |
      | "fb40aa7a-be9d-444b-8772-bde1fdba0f44" |
    And my scope is "contract_request:read"
    And my client type is "MSP"
    When I request reimbursement contract request where databaseId is "fb40aa7a-be9d-444b-8772-bde1fdba0f44"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario Outline: Request own fields
    Given the following reimbursement contract requests exist:
      | databaseId    | <field> |
      | <database_id> | <value> |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request <field> of the reimbursement contract request where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | database_id                            | field            | value                         |
      | "ab5e0012-6add-46ba-80eb-8ab615d1ce01" | contractNumber   | "8002-1016-541X"              |
      | "c56db380-2aa7-4825-a1d4-e864c039565c" | idForm           | "5"                           |
      | "b1083920-1811-4a95-83de-18a8dd4b8079" | status           | "IN_PROCESS"                  |
      | "5a776179-00e2-452d-8e14-152cf6206a5c" | statusReason     | "Запит має наступні недоліки" |
      | "4e7481ca-d02d-440e-acc3-f4722306499a" | issueCity        | "Київ"                        |
      | "b37952c7-361e-4ff2-8e51-df7c25fe9d2d" | startDate        | "2018-01-01"                  |
      | "0b1bbabf-d998-467c-a38d-4770d6b596a3" | endDate          | "2019-01-01"                  |
      | "d1806d3d-37d0-42a3-8759-6059390ccf13" | contractorBase   | "на підставі закону"          |
      | "9f3d9aec-bbc4-42be-be66-fdd636194e3b" | nhsSignerBase    | "на підставі наказу"          |
      | "a522376a-15f2-4e84-a31f-f5b309583545" | nhsPaymentMethod | "FORWARD"                     |
      # | "88da26ff-ec5d-4727-8691-06d80680eec2" | miscellaneous    | "додаткові умови"             |
      # | "baa2e886-cce1-46f9-9394-0d87418bb6ff" | insertedAt       | ""               |
      # | "adab6b5f-ce8c-4d37-a341-37745eaef0c6" | updatedAt        | ""               |

  Scenario Outline: Request one-to-one association fields
    Given the following <association_entity> exist:
      | databaseId       |
      | <association_id> |
    And the following reimbursement contract requests exist:
      | databaseId    | <association_field>Id |
      | <database_id> | <association_id>      |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request databaseId of the <association_field> of the reimbursement contract request where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the databaseId in the <association_field> of the requested item should be <association_id>

    Examples:
      | database_id                            | association_entity              | association_field     | association_id                         |
      # | "013cd1e9-043f-4b16-9c1a-f82b3240f91e" | reimbursement contracts         | parentContract        | "cdf7917f-9639-4ac4-8615-962a077aae8b" |
      | "4ac18a5b-3c07-4182-8790-ecd4b414ded6" | reimbursement contract requests | previousRequest       | "efa213ab-f377-446a-8e6f-7a30b440e59f" |
      | "c52e81f5-ad5f-4432-b508-59704d5b27c5" | employees                       | assignee              | "317dd3d8-3c7a-4303-ab72-5f733d6ea1bb" |
      | "8e66419c-c408-4878-8a95-89782843cc0d" | legal entities                  | contractorLegalEntity | "d86f65f3-8180-464a-84f8-9ea0211ed27e" |
      | "24f423ac-d720-4e3a-a9f4-f53e24beb6cb" | employees                       | contractorOwner       | "fba3bca9-1308-4feb-adb7-ffdfe99b6be8" |
      | "f6aa4371-bb1b-44f8-aefb-64c18b6b9950" | employees                       | nhsSigner             | "9e07e59d-c427-468c-b6c0-1d3cb9e330df" |
      | "2f2a31d6-0980-4493-b4ce-ecd982492218" | legal entities                  | nhsLegalEntity        | "04c58653-5639-456f-9103-a5c7a9fb02ea" |
      | "4eeca663-f967-4c72-90a9-e59effe8fe00" | medical programs                | medicalProgram        | "0a55e9a4-ae08-4d0a-bdcd-e79d62b59405" |

  # Scenario Outline: Request one-to-many association fields
  #   Given the following <association_entity> exist:
  #     | databaseId       |
  #     | <association_id> |
  #   And the following reimbursement contract requests exist:
  #     | databaseId    | <association_field>Id |
  #     | <database_id> | <association_id>      |
  #   And my scope is "contract_request:read"
  #   And my client type is "NHS"
  #   When I request databaseId of the <association_field> of the reimbursement contract request where databaseId is <database_id>
  #   Then no errors should be returned
  #   And I should receive requested item
  #   And the databaseId in the first <association_field> of the requested item should be <association_id>

  #   Examples:
  #     | database_id                            | association_entity | association_field   | association_id                         |
  #     | "90b48d7c-c30a-46eb-b56b-560f2fbc4e4c" | divisions          | contractorDivisions | "3fbcde1a-ad29-4998-8f28-7812e6b034bd" |

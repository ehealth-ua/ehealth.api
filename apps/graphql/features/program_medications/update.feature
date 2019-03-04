Feature: Update program medication

  Scenario Outline: Successful direct fields update
    Given the following program medications exist:
      | databaseId    | isActive    | medicationRequestAllowed     |
      | <database_id> | <is_active> | <medication_request_allowed> |
    Given my scope is "program_medication:write"
    And my client type is "NHS"
    And my consumer ID is "df5b47a8-8cd8-4167-910b-75b15e012d57"
    When I update the <field> with <next_value> in the program medication where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <next_value>

    Examples:
      | database_id                            | field                    | next_value | is_active  | medication_request_allowed |
      | "3b1a0ad5-7cc4-4e3d-900f-dbff37cdc601" | isActive                 | false      | true       | false                      |
      | "b5324d08-5d4b-4b54-9a4a-5d15f30877c1" | isActive                 | true       | false      | false                      |
      | "86208c0d-d743-4fb3-8141-70f638d56cd7" | medicationRequestAllowed | false      | true       | true                       |
      | "979f42bd-86e6-4e62-9a23-20a234531aee" | medicationRequestAllowed | true       | true       | false                      |

  Scenario Outline: Successful nested fields update
    Given the following program medications exist:
      | databaseId    | isActive | reimbursement                                   |
      | <database_id> | true     | {"type": "FIXED", "reimbursement_amount": 5.0} |
    Given my scope is "program_medication:write"
    And my client type is "NHS"
    And my consumer ID is "df5b47a8-8cd8-4167-910b-75b15e012d57"
    When I update the <nested_field> of the <field> with <next_value> in the program medication where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <nested_field> in the <field> of the requested item should be <next_value>

    Examples:
      | database_id                            | field         | nested_field        | next_value |
      | "ad3b3681-0183-4c47-9cf4-4d5390587b96" | reimbursement | reimbursementAmount | 15.0       |

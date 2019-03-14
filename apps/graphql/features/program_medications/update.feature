Feature: Update program medication

  Scenario Outline: Successful direct fields update
    Given the following program medications exist:
      | databaseId    | isActive    | medicationRequestAllowed     |
      | <database_id> | <is_active> | <medication_request_allowed> |
    And my scope is "program_medication:write"
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

  Scenario Outline: Direct fields transition to incorrect state
    Given the following program medications exist:
      | databaseId    | isActive    | medicationRequestAllowed     |
      | <database_id> | <is_active> | <medication_request_allowed> |
    And my scope is "program_medication:write"
    And my client type is "NHS"
    And my consumer ID is "df5b47a8-8cd8-4167-910b-75b15e012d57"
    When I update the <field> with <next_value> in the program medication where databaseId is <database_id>
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And I should not receive requested item

    Examples:
      | database_id                            | field                    | next_value | is_active  | medication_request_allowed |
      | "681fabec-051b-4cb2-8fa4-13033dfd74ff" | isActive                 | false      | true       | true                       |
      | "43e0aa7a-d6ec-4c78-912b-5374f8bd8fd0" | medicationRequestAllowed | true       | false      | false                      |

  Scenario Outline: Successful nested fields update
    Given the following program medications exist:
      | databaseId    | isActive | reimbursement                                  |
      | <database_id> | true     | {"type": "FIXED", "reimbursement_amount": 5.0} |
    And my scope is "program_medication:write"
    And my client type is "NHS"
    And my consumer ID is "df5b47a8-8cd8-4167-910b-75b15e012d57"
    When I update the <nested_field> of the <field> with <next_value> in the program medication where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <nested_field> in the <field> of the requested item should be <next_value>

    Examples:
      | database_id                            | field         | nested_field        | next_value |
      | "ad3b3681-0183-4c47-9cf4-4d5390587b96" | reimbursement | reimbursementAmount | 15.0       |

  Scenario Outline: Update nested fields with incorrect values
    Given the following program medications exist:
      | databaseId    | isActive | reimbursement                                  |
      | <database_id> | true     | {"type": "FIXED", "reimbursement_amount": 5.0} |
    And my scope is "program_medication:write"
    And my client type is "NHS"
    And my consumer ID is "df5b47a8-8cd8-4167-910b-75b15e012d57"
    When I update the <nested_field> of the <field> with <next_value> in the program medication where databaseId is <database_id>
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And I should not receive requested item

    Examples:
      | database_id                            | field         | nested_field        | next_value |
      | "f9972677-060b-4763-b552-59c69d38d726" | reimbursement | reimbursementAmount | -1.0       |

  Scenario Outline: Update nested fields when program medication inactive
    Given the following program medications exist:
      | databaseId    | isActive | medicationRequestAllowed | reimbursement                                  |
      | <database_id> | false    | false                    | {"type": "FIXED", "reimbursement_amount": 5.0} |
    And my scope is "program_medication:write"
    And my client type is "NHS"
    And my consumer ID is "df5b47a8-8cd8-4167-910b-75b15e012d57"
    When I update the <nested_field> of the <field> with <next_value> in the program medication where databaseId is <database_id>
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And I should not receive requested item

    Examples:
      | database_id                            | field         | nested_field        | next_value |
      | "4fcfadac-7e3a-4916-ba2e-aceb60e81f6c" | reimbursement | reimbursementAmount | 15.0       |

  Scenario: Update with incorrect scope
    Given the following program medications exist:
      | databaseId                             | isActive | medicationRequestAllowed |
      | "a05b4108-df83-4cc9-86e4-5a8e26ab02b6" | true     | false                    |
    And my scope is "program_medication:read"
    When I update the isActive with false in the program medication where databaseId is "a05b4108-df83-4cc9-86e4-5a8e26ab02b6"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Update with incorrect client
    Given the following program medications exist:
      | databaseId                             | isActive | medicationRequestAllowed |
      | "f562def7-e1af-41e5-bece-4544af25d5b1" | true     | false                    |
    And my scope is "program_medication:write"
    And my client type is "MIS"
    When I update the isActive with false in the program medication where databaseId is "f562def7-e1af-41e5-bece-4544af25d5b1"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

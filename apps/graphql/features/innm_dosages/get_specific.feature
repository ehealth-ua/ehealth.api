Feature: Get specific INNMDosage

  Scenario: Request with incorrect client
    Given the following INNM dosages exist:
      | databaseId                             |
      | "7d2bd4f7-ea29-4ff1-9491-6f23bccd0e1f" |
    And my scope is "innm_dosage:read"
    And my client type is "MIS"
    When I request databaseId of the INNM dosage where databaseId is "7d2bd4f7-ea29-4ff1-9491-6f23bccd0e1f"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario Outline: Request own fields
    Given the following INNM dosages exist:
      | databaseId    | <field> |
      | <database_id> | <value> |
    And my scope is "innm_dosage:read"
    And my client type is "NHS"
    When I request <field> of the INNM dosage where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <value>

    Examples:
      | database_id                            | field      | value                                  |
      | "653c68ff-f2f0-4468-8b0d-770f1ca694bd" | databaseId | "653c68ff-f2f0-4468-8b0d-770f1ca694bd" |
      | "253ef108-8549-4b12-a781-14dccc35680a" | name       | "Амідарон"                             |
      | "75e7b3b7-ecc1-430d-9d36-960825ea5372" | form       | "TABLET"                               |
      | "e2b3ae3e-e2f6-43db-98b8-e686b0c66a69" | isActive   | false                                  |
      | "f0732595-9ca4-40da-a219-423d1c56dde8" | insertedAt | "2019-01-01T10:10:10.000000Z"          |
      | "0cdb92aa-cd5f-46d1-966d-442ac2ac684d" | updatedAt  | "2019-01-01T10:10:10.000000Z"          |

  Scenario: Request innm association
   Given the following INNM dosages exist:
      | databaseId                             |
      | "653c68ff-f2f0-4468-8b0d-770f1ca694bd" |
    And the following INNMs exist:
      | databaseId                             |
      | "96cf4186-c465-48a0-9610-aeb4d8d9a123" |
    And the following INNM dosage ingredients exist:
      | parentId                               | innmChildId                            |
      | "653c68ff-f2f0-4468-8b0d-770f1ca694bd" | "96cf4186-c465-48a0-9610-aeb4d8d9a123" |
    And my scope is "innm_dosage:read"
    And my client type is "NHS"
    When I request INNM dosage with INNM where databaseId is "653c68ff-f2f0-4468-8b0d-770f1ca694bd"
    Then no errors should be returned
    And I should receive requested item

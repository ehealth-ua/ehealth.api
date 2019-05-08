Feature: Merge legal entities

  Scenario Outline: Successful merge
    Given the following legal entities exist:
      | databaseId                             | type               | status               | name       | edrpou       |
      | "6901ff9a-5fca-41c9-850f-fb759c989c7e" | "NHS"              | "ACTIVE"             | "НСЗУ"     | "1111111111" |
      | "e8766f40-1d37-4b86-8926-4e0da6c746a1" | <merged_from_type> | <merged_from_status> | "Acme Inc" | "1234567890" |
      | "eadacab0-8982-47c8-ad57-59a968b7a815" | <merged_to_type>   | <merged_to_status>   | "Ajax LLC" | "0987654321" |
    And the following parties exist:
      | databaseId                             | taxId        |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "1111111111" |
    And the following party users exist:
      | partyId                                | userId                                 |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a" |
    And my scope is "legal_entity:merge"
    And my client ID is "6901ff9a-5fca-41c9-850f-fb759c989c7e"
    And my consumer ID is "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a"
    And I have a signed content with the following fields:
      | field                    | value                                                                                      |
      | merged_from_legal_entity | {"id": "e8766f40-1d37-4b86-8926-4e0da6c746a1", "name": "Acme Inc", "edrpou": "1234567890"} |
      | merged_to_legal_entity   | {"id": "eadacab0-8982-47c8-ad57-59a968b7a815", "name": "Ajax LLC", "edrpou": "0987654321"} |
      | reason                   | "Because I can"                                                                            |
    And the following signatures was applied:
      | drfo         | surname    |
      | "1111111111" | "ШЕВЧЕНКО" |
    When I merge legal entities with signed content
    Then no errors should be returned
    And I should receive requested item
    And the status of the requested item should be "PENDING"

    Examples:
      | merged_from_type | merged_to_type | merged_from_status | merged_to_status |
      | "MSP"            | "MSP"          | "ACTIVE"           | "ACTIVE"         |
      | "MSP"            | "PRIMARY_CARE" | "ACTIVE"           | "ACTIVE"         |
      | "MSP_PHARMACY"   | "MSP_PHARMACY" | "ACTIVE"           | "ACTIVE"         |
      | "OUTPATIENT"     | "OUTPATIENT"   | "ACTIVE"           | "ACTIVE"         |
      | "PHARMACY"       | "PHARMACY"     | "ACTIVE"           | "ACTIVE"         |
      | "PRIMARY_CARE"   | "PRIMARY_CARE" | "ACTIVE"           | "ACTIVE"         |
      | "PRIMARY_CARE"   | "MSP"          | "ACTIVE"           | "ACTIVE"         |
      | "MSP"            | "MSP"          | "SUSPENDED"        | "ACTIVE"         |

  Scenario Outline: Merge with incorrect type
    Given the following legal entities exist:
      | databaseId                             | type               | status   | name       | edrpou       |
      | "6901ff9a-5fca-41c9-850f-fb759c989c7e" | "NHS"              | "ACTIVE" | "НСЗУ"     | "1111111111" |
      | "e8766f40-1d37-4b86-8926-4e0da6c746a1" | <merged_from_type> | "ACTIVE" | "Acme Inc" | "1234567890" |
      | "eadacab0-8982-47c8-ad57-59a968b7a815" | <merged_to_type>   | "ACTIVE" | "Ajax LLC" | "0987654321" |
    And the following parties exist:
      | databaseId                             | taxId        |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "1111111111" |
    And the following party users exist:
      | partyId                                | userId                                 |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a" |
    And my scope is "legal_entity:merge"
    And my client ID is "6901ff9a-5fca-41c9-850f-fb759c989c7e"
    And my consumer ID is "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a"
    And I have a signed content with the following fields:
      | field                    | value                                                                                      |
      | merged_from_legal_entity | {"id": "e8766f40-1d37-4b86-8926-4e0da6c746a1", "name": "Acme Inc", "edrpou": "1234567890"} |
      | merged_to_legal_entity   | {"id": "eadacab0-8982-47c8-ad57-59a968b7a815", "name": "Ajax LLC", "edrpou": "0987654321"} |
      | reason                   | "Because I can"                                                                            |
    And the following signatures was applied:
      | drfo         | surname    |
      | "1111111111" | "ШЕВЧЕНКО" |
    When I merge legal entities with signed content
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

    Examples:
      | merged_from_type | merged_to_type |
      | "MSP"            | "MSP_PHARMACY" |
      | "NHS"            | "NHS"          |

  Scenario Outline: Merge with incorrect status
    Given the following legal entities exist:
      | databaseId                             | type  | status               | name       | edrpou       |
      | "6901ff9a-5fca-41c9-850f-fb759c989c7e" | "NHS" | "ACTIVE"             | "НСЗУ"     | "1111111111" |
      | "e8766f40-1d37-4b86-8926-4e0da6c746a1" | "MSP" | <merged_from_status> | "Acme Inc" | "1234567890" |
      | "eadacab0-8982-47c8-ad57-59a968b7a815" | "MSP" | <merged_to_status>   | "Ajax LLC" | "0987654321" |
    And the following parties exist:
      | databaseId                             | taxId        |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "1111111111" |
    And the following party users exist:
      | partyId                                | userId                                 |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a" |
    And my scope is "legal_entity:merge"
    And my client ID is "6901ff9a-5fca-41c9-850f-fb759c989c7e"
    And my consumer ID is "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a"
    And I have a signed content with the following fields:
      | field                    | value                                                                                      |
      | merged_from_legal_entity | {"id": "e8766f40-1d37-4b86-8926-4e0da6c746a1", "name": "Acme Inc", "edrpou": "1234567890"} |
      | merged_to_legal_entity   | {"id": "eadacab0-8982-47c8-ad57-59a968b7a815", "name": "Ajax LLC", "edrpou": "0987654321"} |
      | reason                   | "Because I can"                                                                            |
    And the following signatures was applied:
      | drfo         | surname    |
      | "1111111111" | "ШЕВЧЕНКО" |
    When I merge legal entities with signed content
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

    Examples:
      | merged_from_status | merged_to_status |
      | "ACTIVE"           | "SUSPENDED"      |
      | "ACTIVE"           | "CLOSED"         |
      | "CLOSED"           | "ACTIVE"         |

  Scenario Outline: Merge already merged
    Given the following legal entities exist:
      | databaseId                             | type  | status   | name       | edrpou       |
      | "6901ff9a-5fca-41c9-850f-fb759c989c7e" | "NHS" | "ACTIVE" | "НСЗУ"     | "1111111111" |
      | <merged_from_id>                       | "MSP" | "ACTIVE" | "Acme Inc" | "1234567890" |
      | <merged_to_id>                         | "MSP" | "ACTIVE" | "Ajax LLC" | "0987654321" |
    And the following related legal entities exist:
      | mergedFromId          |
      | <related_merged_from_id> |
    And the following parties exist:
      | databaseId                             | taxId        |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "1111111111" |
    And the following party users exist:
      | partyId                                | userId                                 |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a" |
    And my scope is "legal_entity:merge"
    And my client ID is "6901ff9a-5fca-41c9-850f-fb759c989c7e"
    And my consumer ID is "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a"
    And I have a signed content with the following fields:
      | field                    | value                                                                |
      | merged_from_legal_entity | {"id": <merged_from_id>, "name": "Acme Inc", "edrpou": "1234567890"} |
      | merged_to_legal_entity   | {"id": <merged_to_id>, "name": "Ajax LLC", "edrpou": "0987654321"}   |
      | reason                   | "Because I can"                                                      |
    And the following signatures was applied:
      | drfo         | surname    |
      | "1111111111" | "ШЕВЧЕНКО" |
    When I merge legal entities with signed content
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

    Examples:
      | merged_from_id                         | merged_to_id                           | related_merged_from_id                 |
      | "e8766f40-1d37-4b86-8926-4e0da6c746a1" | "eadacab0-8982-47c8-ad57-59a968b7a815" | "e8766f40-1d37-4b86-8926-4e0da6c746a1" |
      | "e8766f40-1d37-4b86-8926-4e0da6c746a1" | "eadacab0-8982-47c8-ad57-59a968b7a815" | "eadacab0-8982-47c8-ad57-59a968b7a815" |

  Scenario: Merge with incorrect client
    Given the following legal entities exist:
      | databaseId                             | type  | status   | name       | edrpou       |
      | "e8766f40-1d37-4b86-8926-4e0da6c746a1" | "MSP" | "ACTIVE" | "Acme Inc" | "1234567890" |
      | "eadacab0-8982-47c8-ad57-59a968b7a815" | "MSP" | "ACTIVE" | "Ajax LLC" | "0987654321" |
    And the following parties exist:
      | databaseId                             | taxId        |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "1111111111" |
    And the following party users exist:
      | partyId                                | userId                                 |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a" |
    And my scope is "legal_entity:merge"
    And my client ID is "6901ff9a-5fca-41c9-850f-fb759c989c7e"
    And my consumer ID is "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a"
    And I have a signed content with the following fields:
      | field                    | value                                                                                      |
      | merged_from_legal_entity | {"id": "e8766f40-1d37-4b86-8926-4e0da6c746a1", "name": "Acme Inc", "edrpou": "1234567890"} |
      | merged_to_legal_entity   | {"id": "eadacab0-8982-47c8-ad57-59a968b7a815", "name": "Ajax LLC", "edrpou": "0987654321"} |
      | reason                   | "Because I can"                                                                            |
    And the following signatures was applied:
      | drfo         | surname    |
      | "1111111111" | "ШЕВЧЕНКО" |
    When I merge legal entities with signed content
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item

  Scenario: Merge with incorrect scope
    Given the following legal entities exist:
      | databaseId                             | type  | status   | name       | edrpou       |
      | "6901ff9a-5fca-41c9-850f-fb759c989c7e" | "NHS" | "ACTIVE" | "НСЗУ"     | "1111111111" |
      | "e8766f40-1d37-4b86-8926-4e0da6c746a1" | "MSP" | "ACTIVE" | "Acme Inc" | "1234567890" |
      | "eadacab0-8982-47c8-ad57-59a968b7a815" | "MSP" | "ACTIVE" | "Ajax LLC" | "0987654321" |
    And the following parties exist:
      | databaseId                             | taxId        |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "1111111111" |
    And the following party users exist:
      | partyId                                | userId                                 |
      | "d519ccad-2edb-467a-a0ae-0569794860f9" | "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a" |
    And my scope is "legal_entity:read"
    And my client ID is "6901ff9a-5fca-41c9-850f-fb759c989c7e"
    And my consumer ID is "2bfc2ef2-7e60-47e1-b667-9de6a1f5af1a"
    And I have a signed content with the following fields:
      | field                    | value                                                                                      |
      | merged_from_legal_entity | {"id": "e8766f40-1d37-4b86-8926-4e0da6c746a1", "name": "Acme Inc", "edrpou": "1234567890"} |
      | merged_to_legal_entity   | {"id": "eadacab0-8982-47c8-ad57-59a968b7a815", "name": "Ajax LLC", "edrpou": "0987654321"} |
      | reason                   | "Because I can"                                                                            |
    And the following signatures was applied:
      | drfo         | surname    |
      | "1111111111" | "ШЕВЧЕНКО" |
    When I merge legal entities with signed content
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item


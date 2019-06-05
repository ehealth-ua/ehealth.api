Feature: Add service to group

  Scenario: Successful add service to service group
    Given the following service groups exist:
      | databaseId                             |
      | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" |
    And the following services exist:
      | databaseId                             |
      | "a9e2873e-1290-496a-a078-7106c32f1130" |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "8341b7d6-f9c7-472a-960c-7da953cc4ea4"
    When I add service to group with attributes:
      | serviceId                                                      | serviceGroupId                                                         |
      | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA=" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |
    Then no errors should be returned
    And request id should be returned
    And the databaseId of the requested item should be "fdb745ec-7d48-41dc-bf72-5882cee6d3ea"
    And nodes in the services of the requested item should include the item with the following fields:
      | field      | value                                  |
      | databaseId | "a9e2873e-1290-496a-a078-7106c32f1130" |

  Scenario: Add service to group with incorrect scope
    Given the following service groups exist:
      | databaseId                             |
      | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" |
    And the following services exist:
      | databaseId                             |
      | "a9e2873e-1290-496a-a078-7106c32f1130" |
    And my scope is "service_catalog:read"
    And my consumer ID is "04796283-74b8-4632-9f7f-9e227ae9426e"
    When I add service to group with attributes:
      | serviceId                                                      | serviceGroupId                                                         |
      | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA=" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario: Create with incorrect client
    Given the following service groups exist:
      | databaseId                             |
      | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" |
    And the following services exist:
      | databaseId                             |
      | "a9e2873e-1290-496a-a078-7106c32f1130" |
    And my scope is "service_catalog:write"
    And my client type is "MSP"
    And my consumer ID is "089c0204-a191-4537-ab92-56dca268443c"
    When I add service to group with attributes:
      | serviceId                                                      | serviceGroupId                                                         |
      | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA=" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario Outline: Add with non-existent service or service group
    Given the following <existing_entity> exist:
      | databaseId             |
      | <existing_database_id> |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I add service to group with attributes:
      | <existing_attr> | <non_existing_attr> |
      | <existing_id>   | <non_existing_id>   |
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item

    Examples:
      | existing_entity | existing_attr  | non_existing_attr | existing_database_id                   | existing_id                                                            | non_existing_id                                                        |
      | service group   | serviceGroupId | serviceId         | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA="         |
      | service         | serviceId      | serviceGroupId    | "a9e2873e-1290-496a-a078-7106c32f1130" | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA="         | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |

  Scenario Outline: Add with deactivated service or service group
    Given the following <active_entity> exist:
      | databaseId           | isActive |
      | <active_database_id> | true     |
    And the following <inactive_entity> exist:
      | databaseId             | isActive |
      | <inactive_database_id> | false    |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my client ID is "e0edf3a8-646c-4a81-84dd-1d52229f6f0a"
    And my consumer ID is "c3aeae43-985b-4412-b8ff-15ddee5a47de"
    When I add service to group with attributes:
      | <active_attr> | <inactive_attr> |
      | <active_id>   | <inactive_id>   |
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

    Examples:
      | active_entity | inactive_entity | active_attr    | inactive_attr  | active_database_id                     | inactive_database_id                   | active_id                                                              | inactive_id                                                            |
      | service group | service         | serviceGroupId | serviceId      | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" | "a9e2873e-1290-496a-a078-7106c32f1130" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA="         |
      | service       | service group   | serviceId      | serviceGroupId | "a9e2873e-1290-496a-a078-7106c32f1130" | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA="         | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |

  Scenario: Add already added service to group
    Given the following service groups exist:
      | databaseId                             |
      | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" |
    And the following services exist:
      | databaseId                             |
      | "a9e2873e-1290-496a-a078-7106c32f1130" |
    And the following service inclusions exist:
      | serviceId                              | serviceGroupId                         | isActive |
      | "a9e2873e-1290-496a-a078-7106c32f1130" | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" | true     |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "8341b7d6-f9c7-472a-960c-7da953cc4ea4"
    When I add service to group with attributes:
      | serviceId                                                      | serviceGroupId                                                         |
      | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA=" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

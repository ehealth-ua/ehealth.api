Feature: Delete service from group

  Scenario: Successful service deletion from service group
    Given the following service groups exist:
      | databaseId                             |
      | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" |
    And the following services exist:
      | databaseId                             |
      | "a9e2873e-1290-496a-a078-7106c32f1130" |
    And the following service inclusions exist:
      | serviceId                              | serviceGroupId                         | isActive |
      | "a9e2873e-1290-496a-a078-7106c32f1130" | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" | false    |
      | "a9e2873e-1290-496a-a078-7106c32f1130" | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" | true     |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "8341b7d6-f9c7-472a-960c-7da953cc4ea4"
    When I delete service from group with attributes:
      | serviceId                                                      | serviceGroupId                                                         |
      | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA=" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |
    Then no errors should be returned
    And request id should be returned
    And the databaseId of the requested item should be "fdb745ec-7d48-41dc-bf72-5882cee6d3ea"
    And nodes in the services of the requested item should not include the item with the following fields:
      | field      | value                                  |
      | databaseId | "a9e2873e-1290-496a-a078-7106c32f1130" |

  Scenario: Delete service from group with incorrect scope
    Given the following service groups exist:
      | databaseId                             |
      | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" |
    And the following services exist:
      | databaseId                             |
      | "a9e2873e-1290-496a-a078-7106c32f1130" |
    And the following service inclusions exist:
      | serviceId                              | serviceGroupId                         | isActive |
      | "a9e2873e-1290-496a-a078-7106c32f1130" | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" | true     |
    And my scope is "service_catalog:read"
    And my consumer ID is "04796283-74b8-4632-9f7f-9e227ae9426e"
    When I delete service from group with attributes:
      | serviceId                                                      | serviceGroupId                                                         |
      | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA=" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario: Delete with incorrect client
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
    And my client type is "MSP"
    And my consumer ID is "089c0204-a191-4537-ab92-56dca268443c"
    When I delete service from group with attributes:
      | serviceId                                                      | serviceGroupId                                                         |
      | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA=" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario: Delete service not belonging to group
    Given the following service groups exist:
      | databaseId                             |
      | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" |
    And the following services exist:
      | databaseId                             |
      | "a9e2873e-1290-496a-a078-7106c32f1130" |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I delete service from group with attributes:
      | serviceId                                                      | serviceGroupId                                                         |
      | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA=" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item

  Scenario: Delete aready deleted service from group
    Given the following service groups exist:
      | databaseId                             |
      | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" |
    And the following services exist:
      | databaseId                             |
      | "a9e2873e-1290-496a-a078-7106c32f1130" |
    And the following service inclusions exist:
      | serviceId                              | serviceGroupId                         | isActive |
      | "a9e2873e-1290-496a-a078-7106c32f1130" | "fdb745ec-7d48-41dc-bf72-5882cee6d3ea" | false    |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "8341b7d6-f9c7-472a-960c-7da953cc4ea4"
    When I delete service from group with attributes:
      | serviceId                                                      | serviceGroupId                                                         |
      | "U2VydmljZTphOWUyODczZS0xMjkwLTQ5NmEtYTA3OC03MTA2YzMyZjExMzA=" | "U2VydmljZUdyb3VwOmZkYjc0NWVjLTdkNDgtNDFkYy1iZjcyLTU4ODJjZWU2ZDNlYQ==" |
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item

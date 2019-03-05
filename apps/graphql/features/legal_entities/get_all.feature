Feature: Get all legal entities

  Scenario: Request legal entities with filter by address settlement_id
    Given the following legal entities exist:
      | databaseId                             | addresses  |
      | "5bf0aee4-8de7-42b4-8a5d-54e851c5a6b7" | [{"type": "RESIDENCE","country": "UA","area": "Житомирська","region": "Бердичівський","settlement": "Київ","settlement_type": "CITY","settlement_id": "7b339e09-fe0f-4cbc-a4b6-7cc28b7e1314","street_type": "STREET","street": "вул. Ніжинська","building": "15-В","apartment": "23","zip": "02090"}, {"type": "REGISTRATION","country": "UA","area": "Житомирська","region": "Бердичівський","settlement": "Київ","settlement_type": "CITY","settlement_id": "40323775-6102-476d-861b-70413385a888","street_type": "STREET","street": "вул. Ніжинська","building": "15-В","apartment": "23","zip": "02090"}] |
      | "fa9a9875-6829-4262-b8b4-bb6180cc90de" | [{"type": "REGISTRATION","country": "UA","area": "Одеська","region": "Затоцький","settlement": "Затока","settlement_type": "CITY","settlement_id": "4828e699-2efd-458a-8f58-1064bd470ca5","street_type": "STREET","street": "вул. Ніжинська","building": "10-В","apartment": "223","zip": "03100"}] |
    And my scope is "legal_entity:read"
    When I request first 10 legal entities where settlement_id of the associated addresses is "U2V0dGxlbWVudDo0MDMyMzc3NS02MTAyLTQ3NmQtODYxYi03MDQxMzM4NWE4ODg="
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "5bf0aee4-8de7-42b4-8a5d-54e851c5a6b7"

  Scenario: Request legal entities with filter by address type
    Given the following legal entities exist:
      | databaseId                             | addresses  |
      | "82eb02e0-cdab-4a1e-8901-70551bedbc4a" | [{"type": "REGISTRATION","country": "UA","area": "Житомирська","region": "Бердичівський","settlement": "Київ","settlement_type": "CITY","settlement_id": "c3b72da3-0f7e-4973-a810-da9b1d818569","street_type": "STREET","street": "вул. Ніжинська","building": "15-В","apartment": "23","zip": "02090"}] |
      | "33413dc5-ca93-49ee-8bf2-57b4df4056c8" | [{"type": "REGISTRATION","country": "UA","area": "Одеська","region": "Затоцький","settlement": "Затока","settlement_type": "CITY","settlement_id": "2128e699-2efd-458a-8f58-1064bd470c44","street_type": "STREET","street": "вул. Ніжинська","building": "10-В","apartment": "223","zip": "03100"}, {"type": "RESIDENCE","country": "UA","area": "Житомирська","region": "Бердичівський","settlement": "Київ","settlement_type": "CITY","settlement_id": "40323775-6102-476d-861b-70413385a675","street_type": "STREET","street": "вул. Ніжинська","building": "15-В","apartment": "23","zip": "02090"}] |
    And my scope is "legal_entity:read"
    When I request first 10 legal entities where type of the associated addresses is "RESIDENCE"
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "33413dc5-ca93-49ee-8bf2-57b4df4056c8"

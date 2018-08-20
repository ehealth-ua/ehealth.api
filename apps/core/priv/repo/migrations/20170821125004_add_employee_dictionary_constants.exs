defmodule Core.Repo.Migrations.AddEmployeeDictionaryConstants do
  use Ecto.Migration

  def change do
    execute("""
    UPDATE dictionaries SET
    values = values || '{
      "HR": "відділ кадрів",
      "ADMIN": "реєстратор",
      "OWNER": "керівник",
      "DOCTOR": "лікар",
      "ACCOUNTANT": "бухгалтер",
      "PHARMACY_OWNER": "керівник",
      "PHARMACIST": "фармацевт"
    }'
    WHERE name = 'EMPLOYEE_TYPE';
    """)

    execute("""
    UPDATE dictionaries SET
    values = values || '{
      "P14": "Старший провізор",
      "P15": "Провізор",
      "P16": "Фармацевт",
      "P17": "Лаборант",
      "P18": "Заступники з числа фармацевтів (завідувача, начальника)",
      "P19": "Завідувач аптечного пункту"
    }'
    WHERE name = 'POSITION';
    """)

    execute("""
    UPDATE dictionaries SET
    values = values || '{
      "THERAPIST": "Терапевт",
      "PEDIATRICIAN": "Педіатр",
      "FAMILY_DOCTOR": "Сімейний лікар",
      "PHARMACIST": "Фармацевт",
      "PHARMACIST2": "Провізор"
    }'
    WHERE name = 'SPECIALITY_TYPE';
    """)
  end
end

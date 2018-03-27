defmodule EHealth.Repo.Migrations.SetDictionariesStreetType do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute("""
    UPDATE dictionaries SET values = '{
      "LINE": "лінія",
      "PASS": "провулок",
      "ROAD": "дорога",
      "ALLEY": "алея",
      "BLOCK": "квартал",
      "TRACT": "урочище",
      "ASCENT": "узвіз",
      "AVENUE": "проспект",
      "MAIDAN": "майдан",
      "SQUARE": "площа",
      "STREET": "вулиця",
      "HIGHWAY": "шосе",
      "PASSAGE": "проїзд",
      "STATION": "станція",
      "ENTRANCE": "в''їзд",
      "FORESTRY": "лісництво",
      "BOULEVARD": "бульвар",
      "RIVER_SIDE": "набережна",
      "BLIND_STREET": "тупик",
      "HOUSING_AREA": "житловий масив",
      "MICRODISTRICT": "мікрорайон",
      "MILITARY_BASE": "військова частина",
      "SELECTION_BASE": "селекційна станція"
    }'::jsonb WHERE name = 'STREET_TYPE';
    """)
  end
end

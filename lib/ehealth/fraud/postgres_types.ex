# Enable PostGIS for Ecto
Postgrex.Types.define(
  EHealth.Fraud.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Poison
)

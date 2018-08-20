# Enable PostGIS for Ecto
Postgrex.Types.define(
  Core.PRM.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)

Postgrex.Types.define(
  Core.Fraud.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)

use Mix.Config

config :core, Jobs.LegalEntityMergeJob,
  client_type_id: {:system, "CLIENT_TYPE_MSP_LIMITED_ID"},
  media_storage_resource_name: {:system, "MEDIA_STORAGE_MERGED_LEGAL_ENTITIES_RESOURCE_NAME", "merged_legal_entities"}

import_config "#{Mix.env()}.exs"

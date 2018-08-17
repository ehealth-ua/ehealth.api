use Mix.Config

# Configures Digital Signature API
config :core, Core.API.Signature, endpoint: {:system, "DIGITAL_SIGNATURE_ENDPOINT", "http://35.187.186.145"}

# Configures OAuth API
config :core, Core.API.Mithril, endpoint: {:system, "OAUTH_ENDPOINT", "http://api-svc.mithril"}

# Configures Man API
config :core, Core.API.Man, endpoint: {:system, "MAN_ENDPOINT", "http://api-svc.man"}

# Configures UAddress API
config :core, Core.API.UAddress, endpoint: {:system, "UADDRESS_ENDPOINT", "http://api-svc.uaddresses"}

# Configures OTP Verification API
config :core, Core.API.OTPVerification, endpoint: {:system, "OTP_VERIFICATION_ENDPOINT", "http://api-svc.verification"}

# Configures MPI API
config :core, Core.API.MPI, endpoint: {:system, "MPI_ENDPOINT", "http://api-svc.mpi"}

# Configures OPS API
config :core, Core.API.OPS, endpoint: {:system, "OPS_ENDPOINT", "http://api-svc.ops"}

# Configures MediaStorage API
config :core, Core.API.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT", "http://api-svc.ael"},
  legal_entity_bucket: {:system, "MEDIA_STORAGE_LEGAL_ENTITY_BUCKET", "legal-entities-dev"},
  contract_request_bucket: {:system, "MEDIA_STORAGE_CONTRACT_REQUEST_BUCKET", "contract-requests-dev"},
  contract_bucket: {:system, "MEDIA_STORAGE_CONTRACT_BUCKET", "contracts-dev"},
  declaration_request_bucket: {:system, "MEDIA_STORAGE_DECLARATION_REQUEST_BUCKET", "declaration-requests-dev"},
  declaration_bucket: {:system, "MEDIA_STORAGE_DECLARATION_BUCKET", "declarations-dev"},
  medication_request_request_bucket:
    {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_REQUEST_BUCKET", "medication-request-requests-dev"},
  person_bucket: {:system, "MEDIA_STORAGE_PERSON_BUCKET", "persons-dev"},
  enabled?: {:system, :boolean, "MEDIA_STORAGE_ENABLED", false}

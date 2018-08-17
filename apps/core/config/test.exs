use Mix.Config

config :core,
  api_resolvers: [
    man: ManMock,
    mpi: MPIMock,
    mithril: MithrilMock,
    digital_signature: SignatureMock,
    ops: OPSMock,
    report: ReportMock,
    media_storage: MediaStorageMock,
    otp_verification: OTPVerificationMock,
    uaddresses: UAddressesMock
  ]

# Configures PRM API
config :core, Core.API.PRM, endpoint: {:system, "PRM_ENDPOINT", "http://localhost:4040"}

# Configures Man API
config :core, Core.API.Man, endpoint: {:system, "MAN_ENDPOINT", "http://localhost:4040"}

# Configures OPS API
config :core, Core.API.OPS, endpoint: {:system, "OPS_ENDPOINT", "http://localhost:4040"}

# Configures UAdress API
config :core, Core.API.UAddress, endpoint: {:system, "UADDRESS_ENDPOINT", "http://localhost:4040"}

config :core, Core.API.Mithril, endpoint: {:system, "OAUTH_ENDPOINT", "http://localhost:4040"}

config :core, Core.API.OTPVerification, endpoint: {:system, "OTP_VERIFICATION_ENDPOINT", "http://localhost:4040"}

config :core, Core.API.MPI, endpoint: {:system, "MPI_ENDPOINT", "http://localhost:4040"}

config :core, Core.API.Signature, enabled: {:system, :boolean, "DIGITAL_SIGNATURE_ENABLED", false}

config :core, Core.API.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT", "http://localhost:4040"},
  legal_entity_bucket: {:system, "MEDIA_STORAGE_LEGAL_ENTITY_BUCKET", "legal-entities-dev"},
  contract_request_bucket: {:system, "MEDIA_STORAGE_CONTRACT_REQUEST_BUCKET", "contract-requests-dev"},
  contract_bucket: {:system, "MEDIA_STORAGE_CONTRACT_BUCKET", "contracts-dev"},
  declaration_request_bucket: {:system, "MEDIA_STORAGE_DECLARATION_REQUEST_BUCKET", "declaration-requests-dev"},
  declaration_bucket: {:system, "MEDIA_STORAGE_DECLARATION_BUCKET", "declarations-dev"},
  medication_request_request_bucket:
    {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_REQUEST_BUCKET", "medication-request-requests-dev"},
  person_bucket: {:system, "MEDIA_STORAGE_PERSON_BUCKET", "persons-dev"},
  enabled?: {:system, :boolean, "MEDIA_STORAGE_ENABLED", false}

config :ex_unit, capture_log: true

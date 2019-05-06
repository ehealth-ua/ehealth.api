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
    uaddresses: UAddressesMock,
    postmark: PostmarkMock,
    declaration_request_creator: DeclarationRequestsCreatorMock
  ],
  cache: [
    validators: Core.Validators.CacheTest
  ],
  rpc_worker: RPCWorkerMock,
  rpc_edr_worker: RPCEdrWorkerMock,
  repos: [
    read_repo: Core.Repo,
    read_prm_repo: Core.PRMRepo
  ],
  kafka: [
    producer: KafkaMock
  ],
  legal_entity_edr_verify: true,
  dispense_division_dls_verify: true

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
  employee_request_bucket: {:system, "MEDIA_STORAGE_EMPLOYEE_REQUEST_BUCKET", "employee-requests-dev"},
  declaration_request_bucket: {:system, "MEDIA_STORAGE_DECLARATION_REQUEST_BUCKET", "declaration-requests-dev"},
  declaration_bucket: {:system, "MEDIA_STORAGE_DECLARATION_BUCKET", "declarations-dev"},
  medication_request_request_bucket:
    {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_REQUEST_BUCKET", "medication-request-requests-dev"},
  person_bucket: {:system, "MEDIA_STORAGE_PERSON_BUCKET", "persons-dev"},
  medication_dispense_bucket: {:system, "MEDIA_STORAGE_MEDICATION_DISPENSE_BUCKET", "medication-dispenses-dev"},
  medication_request_bucket: {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_BUCKET", "medication-requests-dev"},
  related_legal_entity_bucket: {:system, "MEDIA_STORAGE_RELATED_LEGAL_ENTITY_BUCKET", "related-legal-entities-dev"},
  enabled?: {:system, :boolean, "MEDIA_STORAGE_ENABLED", false}

# Databases configuration
config :core, Core.ReadRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ehealth_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ehealth_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

config :core, Core.ReadPRMRepo,
  username: "postgres",
  password: "postgres",
  database: "prm_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Core.PRM.PostgresTypes,
  ownership_timeout: 120_000_000

config :core, Core.PRMRepo,
  username: "postgres",
  password: "postgres",
  database: "prm_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Core.PRM.PostgresTypes,
  ownership_timeout: 120_000_000

config :core, Core.FraudRepo,
  username: "postgres",
  password: "postgres",
  database: "fraud_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Core.Fraud.PostgresTypes,
  ownership_timeout: 120_000_000

# employee request invitation
# Configures employee request invitation template
config :core, Core.Man.Templates.EmployeeRequestInvitation, id: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_ID", 1}

# Configures employee request update invitation template
config :core, Core.Man.Templates.EmployeeRequestUpdateInvitation,
  id: {:system, "EMPLOYEE_REQUEST_UPDATE_INVITATION_TEMPLATE_ID", 1}

# employee created notification
# Configures employee created notification template
config :core, Core.Man.Templates.EmployeeCreatedNotification,
  id: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_ID", 35}

config :core, Core.Man.Templates.DeclarationRequestPrintoutForm,
  id: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", 4}

config :core, Core.Man.Templates.CapitationContractRequestPrintoutForm,
  id: {:system, "CAPITATION_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", 6}

config :core, Core.Man.Templates.ReimbursementContractRequestPrintoutForm,
  id: {:system, "REIMBURSEMENT_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", 14}

config :core, Core.Man.Templates.CredentialsRecoveryRequest,
  id: {:system, "CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_ID", 5}

# configure emails
config :core, :emails,
  hash_chain_verification_notification: %{
    from: "automatic@system.com",
    to: "serious@authority.com",
    subject: "Hash chain has been mangled!"
  }

config :core, Core.Man.Templates.HashChainVerificationNotification,
  id: 32_167,
  format: "text/html",
  locale: "uk_UA"

config :core, Core.Man.Templates.EmailVerification,
  id: "1",
  from: "info@ehealth.world",
  subject: "verification"

# Configures genral validator
config :core, Core.LegalEntities.Validator, owner_positions: {:system, :list, "OWNER_POSITIONS", ["P1"]}

config :core, Core.Bamboo.Emails.Sender, mailer: Core.Bamboo.TestMailer

config :core, Core.Bamboo.TestMailer, adapter: Bamboo.TestAdapter

config :core, :legal_entity_employee_types,
  nhs: {:system, :list, "LEGAL_ENTITY_NHS_EMPLOYEE_TYPES", ["NHS ADMIN", "NHS ADMIN SIGNER", "NHS LE VERIFIER"]},
  msp: {:system, :list, "LEGAL_ENTITY_MSP_EMPLOYEE_TYPES", ["OWNER", "HR", "DOCTOR", "ADMIN", "ACCOUNTANT"]},
  pharmacy: {:system, :list, "LEGAL_ENTITY_PHARMACY_EMPLOYEE_TYPES", ["PHARMACY_OWNER", "PHARMACIST"]}

# Configures Cabinet
config :core, Core.Cabinet.API,
  # hours
  jwt_ttl_email: 1,
  jwt_ttl_registration: 1,
  role_id: "068c3ba7-2b6f-47b6-acf1-e219f0e84eed",
  client_id: "50918162-4d48-4d84-9d17-518bb80e65d8"

config :core, Core.Guardian,
  issuer: "EHealth",
  secret_key: "some_super-sEcret"

config :ex_unit, capture_log: true

config :logger, level: :warn

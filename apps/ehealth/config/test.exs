use Mix.Config

# Configuration for test environment
config :ex_unit, capture_log: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ehealth, EHealth.Web.Endpoint,
  http: [port: 4001],
  server: true

# Configures PRM API
config :ehealth, EHealth.API.PRM, endpoint: {:system, "PRM_ENDPOINT", "http://localhost:4040"}

# Configures Man API
config :ehealth, EHealth.API.Man, endpoint: {:system, "MAN_ENDPOINT", "http://localhost:4040"}

# Configures OPS API
config :ehealth, EHealth.API.OPS, endpoint: {:system, "OPS_ENDPOINT", "http://localhost:4040"}

# Configures UAdress API
config :ehealth, EHealth.API.UAddress, endpoint: {:system, "UADDRESS_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.Mithril, endpoint: {:system, "OAUTH_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.OTPVerification, endpoint: {:system, "OTP_VERIFICATION_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.MPI, endpoint: {:system, "MPI_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.Gandalf, endpoint: {:system, "GNDF_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.Signature, enabled: {:system, :boolean, "DIGITAL_SIGNATURE_ENABLED", false}

config :ehealth,
  mock: [
    port: {:system, :integer, "TEST_MOCK_PORT", 4040},
    host: {:system, "TEST_MOCK_HOST", "localhost"}
  ],
  api_resolvers: [
    man: ManMock,
    mithril: MithrilMock
  ]

config :ehealth, :legal_entity_employee_types,
  msp: {:system, "LEGAL_ENTITY_MSP_EMPLOYEE_TYPES", ["OWNER", "HR", "DOCTOR", "ADMIN", "ACCOUNTANT"]},
  pharmacy: {:system, "LEGAL_ENTITY_PHARMACY_EMPLOYEE_TYPES", ["PHARMACY_OWNER", "PHARMACIST"]}

config :ehealth, EHealth.API.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT", "http://localhost:4040"},
  legal_entity_bucket: {:system, "MEDIA_STORAGE_LEGAL_ENTITY_BUCKET", "legal-entities-dev"},
  declaration_request_bucket: {:system, "MEDIA_STORAGE_DECLARATION_REQUEST_BUCKET", "declaration-requests-dev"},
  declaration_bucket: {:system, "MEDIA_STORAGE_DECLARATION_BUCKET", "declarations-dev"},
  medication_request_request_bucket:
    {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_REQUEST_BUCKET", "medication-request-requests-dev"},
  enabled?: {:system, :boolean, "MEDIA_STORAGE_ENABLED", false}

# Configures Gandalf API
config :ehealth, EHealth.API.Gandalf,
  endpoint: {:system, "GNDF_ENDPOINT", "https://api.gndf.io"},
  client_id: {:system, "GNDF_CLIENT_ID", "some_client_id"},
  client_secret: {:system, "GNDF_CLIENT_SECRET", "some_client_secret"},
  application_id: {:system, "GNDF_APPLICATION_ID", "some_gndf_application_id"},
  table_id: {:system, "GNDF_TABLE_ID", "some_gndf_table_id"}

# employee request invitation
# Configures employee request invitation template
config :ehealth, EHealth.Man.Templates.EmployeeRequestInvitation,
  id: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_ID", 1}

# Configures employee request update invitation template
config :ehealth, EHealth.Man.Templates.EmployeeRequestUpdateInvitation,
  id: {:system, "EMPLOYEE_REQUEST_UPDATE_INVITATION_TEMPLATE_ID", 1}

# employee created notification
# Configures employee created notification template
config :ehealth, EHealth.Man.Templates.EmployeeCreatedNotification,
  id: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_ID", 35}

config :ehealth, EHealth.Man.Templates.DeclarationRequestPrintoutForm,
  id: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", 4}

config :ehealth, EHealth.Man.Templates.CredentialsRecoveryRequest,
  id: {:system, "CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_ID", 5}

# configure emails
config :ehealth, :emails,
  hash_chain_verification_notification: %{
    from: "automatic@system.com",
    to: "serious@authority.com",
    subject: "Hash chain has been mangled!"
  }

config :ehealth, EHealth.Man.Templates.HashChainVerificationNotification,
  id: 32167,
  format: "text/html",
  locale: "uk_UA"

# Configures declaration request terminator
config :ehealth, EHealth.DeclarationRequest.Terminator,
  frequency: 100,
  utc_interval: {0, 23}

# Configures employee request terminator
config :ehealth, EHealth.EmployeeRequest.Terminator,
  frequency: 100,
  utc_interval: {0, 23}

config :ehealth, EHealth.DeclarationRequests.Terminator,
  termination_batch_size: {:system, :integer, "DECLARATION_REQUEST_AUTOTERMINATION_BATCH", 1}

# Configures genral validator
config :ehealth, EHealth.LegalEntities.Validator, owner_positions: {:system, :list, "OWNER_POSITIONS", ["P1"]}

config :ehealth, EHealth.Bamboo.Emails.Sender, mailer: EHealth.Bamboo.TestMailer

config :ehealth, EHealth.Bamboo.TestMailer, adapter: Bamboo.TestAdapter

# Configures Cabinet
config :ehealth, EHealth.Cabinet.API,
  # hours
  jwt_ttl_email: 1,
  jwt_ttl_registration: 1

config :ehealth, EHealth.Guardian,
  issuer: "EHealth",
  secret_key: "some_super-sEcret"

config :ehealth, EHealth.Man.Templates.EmailVerification,
  id: "1",
  from: "info@ehealth.world",
  subject: "verification"

config :ehealth,
  # Run acceptance test in concurrent mode
  sql_sandbox: true,
  # Don't start terminator in test env
  run_declaration_request_terminator: false

# Configure your database
config :ehealth, EHealth.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ehealth_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

config :ehealth, EHealth.PRMRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "prm_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: EHealth.PRM.PostgresTypes,
  ownership_timeout: 120_000_000

config :ehealth, EHealth.FraudRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "fraud_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: EHealth.Fraud.PostgresTypes,
  ownership_timeout: 120_000_000

config :ehealth, EHealth.EventManagerRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "event_manager_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

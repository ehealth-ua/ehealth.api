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

# Configures Casher API
config :core, Core.API.Casher, endpoint: {:system, "CASHER_ENDPOINT", "http://casher-svc.il"}

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
  medication_dispense_bucket: {:system, "MEDIA_STORAGE_MEDICATION_DISPENSE_BUCKET", "medication-dispenses-dev"},
  medication_request_bucket: {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_BUCKET", "medication-requests-dev"},
  enabled?: {:system, :boolean, "MEDIA_STORAGE_ENABLED", false}

config :core, :legal_entity_employee_types,
  nhs: {:system, :list, "LEGAL_ENTITY_NHS_EMPLOYEE_TYPES", ["NHS ADMIN", "NHS ADMIN SIGNER", "NHS LE VERIFIER"]},
  msp: {:system, :list, "LEGAL_ENTITY_MSP_EMPLOYEE_TYPES", ["OWNER", "HR", "DOCTOR", "ADMIN", "ACCOUNTANT"]},
  pharmacy: {:system, :list, "LEGAL_ENTITY_PHARMACY_EMPLOYEE_TYPES", ["PHARMACY_OWNER", "PHARMACIST"]}

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
  id: {:system, "CAPITATION_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", 9}

config :core, Core.Man.Templates.ReimbursementContractRequestPrintoutForm,
  id: {:system, "REIMBURSEMENT_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", 14}

config :core, Core.Man.Templates.CredentialsRecoveryRequest,
  id: {:system, "CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_ID", 5}

# Configure your database
config :core, Core.ReadRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ehealth",
  hostname: "localhost",
  pool_size: 10

config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ehealth",
  hostname: "localhost",
  pool_size: 10

config :core, Core.ReadPRMRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "prm_dev",
  hostname: "localhost",
  pool_size: 10,
  types: Core.PRM.PostgresTypes

config :core, Core.PRMRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "prm_dev",
  hostname: "localhost",
  pool_size: 10,
  types: Core.PRM.PostgresTypes

config :core, Core.FraudRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "fraud_dev",
  hostname: "localhost",
  pool_size: 10,
  types: Core.Fraud.PostgresTypes

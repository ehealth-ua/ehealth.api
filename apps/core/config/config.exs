use Mix.Config

config :core,
  namespace: Core,
  system_user: {:system, "EHEALTH_SYSTEM_USER", "4261eacf-8008-4e62-899f-de1e2f7065f0"},
  ecto_repos: [Core.Repo, Core.PRMRepo, Core.FraudRepo, Core.EventManagerRepo]

config :ecto, json_library: Jason

# Configures Elixir's Logger
config :logger, :console,
  format: "$message\n",
  handle_otp_reports: true,
  level: :info

config :core,
  api_resolvers: [
    man: Core.API.Man,
    mpi: Core.API.MPI,
    mithril: Core.API.Mithril,
    digital_signature: Core.API.Signature,
    ops: Core.API.OPS,
    report: Core.API.Report,
    media_storage: Core.API.MediaStorage,
    otp_verification: Core.API.OTPVerification,
    uaddresses: Core.API.UAddress,
    casher: Core.API.Casher,
    postmark: Core.API.Postmark,
    declaration_request_creator: Core.DeclarationRequests.API.V1.Creator
  ],
  cache: [
    validators: Core.Validators.Cache
  ]

# Configures Legal Entities token permission
config :core, Core.Context,
  tokens_types_personal: {:system, :list, "TOKENS_TYPES_PERSONAL", ["MSP", "PHARMACY"]},
  tokens_types_mis: {:system, :list, "TOKENS_TYPES_MIS", ["MIS"]},
  tokens_types_admin: {:system, :list, "TOKENS_TYPES_ADMIN", ["NHS"]},
  tokens_types_cabinet: {:system, :list, "TOKENS_TYPES_CABINET", ["CABINET"]}

config :core, :employee_speciality_limits,
  pediatrician_declaration_limit: {:system, :integer, "PEDIATRICIAN_DECLARATION_LIMIT", 900},
  therapist_declaration_limit: {:system, :integer, "THERAPIST_DECLARATION_LIMIT", 2_000},
  family_doctor_declaration_limit: {:system, :integer, "FAMILY_DOCTOR_DECLARATION_LIMIT", 1_800}

# Configures Digital Signature API
config :core, Core.API.Signature,
  enabled: {:system, :boolean, "DIGITAL_SIGNATURE_ENABLED", true},
  endpoint: {:system, "DIGITAL_SIGNATURE_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "DIGITAL_SIGNATURE_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "DIGITAL_SIGNATURE_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "DIGITAL_SIGNATURE_REQUEST_TIMEOUT", 30_000}
  ]

# Configures MediaStorage API
config :core, Core.API.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT"},
  legal_entity_bucket: {:system, "MEDIA_STORAGE_LEGAL_ENTITY_BUCKET"},
  contract_request_bucket: {:system, "MEDIA_STORAGE_CONTRACT_REQUEST_BUCKET"},
  contract_bucket: {:system, "MEDIA_STORAGE_CONTRACT_BUCKET"},
  declaration_request_bucket: {:system, "MEDIA_STORAGE_DECLARATION_REQUEST_BUCKET"},
  declaration_bucket: {:system, "MEDIA_STORAGE_DECLARATION_BUCKET"},
  medication_request_request_bucket: {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_REQUEST_BUCKET"},
  person_bucket: {:system, "MEDIA_STORAGE_PERSON_BUCKET"},
  enabled?: {:system, :boolean, "MEDIA_STORAGE_ENABLED", false},
  hackney_options: [
    connect_timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000}
  ]

# Configures PRM API
config :core, Core.API.PRM,
  endpoint: {:system, "PRM_ENDPOINT", "http://api-svc.prm/api"},
  hackney_options: [
    connect_timeout: {:system, :integer, "PRM_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "PRM_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "PRM_REQUEST_TIMEOUT", 30_000}
  ]

# Configures OAuth API
config :core, Core.API.Mithril,
  endpoint: {:system, "OAUTH_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "OAUTH_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "OAUTH_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "OAUTH_REQUEST_TIMEOUT", 30_000}
  ]

# Configures Man API
config :core, Core.API.Man,
  endpoint: {:system, "MAN_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "MAN_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MAN_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MAN_REQUEST_TIMEOUT", 30_000}
  ]

# Configures UAddress API
config :core, Core.API.UAddress,
  endpoint: {:system, "UADDRESS_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "UADDRESS_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "UADDRESS_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "UADDRESS_REQUEST_TIMEOUT", 30_000}
  ]

# Configures OTP Verification API
config :core, Core.API.OTPVerification,
  endpoint: {:system, "OTP_VERIFICATION_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "OTP_VERIFICATION_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "OTP_VERIFICATION_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "OTP_VERIFICATION_REQUEST_TIMEOUT", 30_000}
  ]

# Configures MPI API
config :core, Core.API.MPI,
  endpoint: {:system, "MPI_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "MPI_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MPI_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MPI_REQUEST_TIMEOUT", 30_000}
  ]

# Configures OPS API
config :core, Core.API.OPS,
  endpoint: {:system, "OPS_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "OPS_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "OPS_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "OPS_REQUEST_TIMEOUT", 30_000}
  ]

# Configures Casher
config :core, Core.API.Casher,
  endpoint: {:system, "CASHER_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "CASHER_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "CASHER_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "CASHER_REQUEST_TIMEOUT", 30_000}
  ]

# Configures Report API
config :core, Core.API.Report,
  endpoint: {:system, "REPORT_ENDPOINT"},
  hackney_options: [
    connect_timeout: {:system, :integer, "REPORT_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "REPORT_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "REPORT_REQUEST_TIMEOUT", 30_000}
  ]

config :core, Core.Bamboo.Emails.Sender, mailer: {:system, :module, "BAMBOO_MAILER"}

# configure emails
config :core, :emails,
  default: %{
    format: {:system, "TEMPLATE_FORMAT", "text/html"},
    locale: {:system, "TEMPLATE_LOCALE", "uk_UA"}
  },
  employee_request_invitation: %{
    from: {:system, "BAMBOO_EMPLOYEE_REQUEST_INVITATION_FROM", ""},
    subject: {:system, "BAMBOO_EMPLOYEE_REQUEST_INVITATION_SUBJECT", ""}
  },
  employee_request_update_invitation: %{
    from: {:system, "BAMBOO_EMPLOYEE_REQUEST_UPDATE_INVITATION_FROM", ""},
    subject: {:system, "BAMBOO_EMPLOYEE_REQUEST_UPDATE_INVITATION_SUBJECT", ""}
  },
  hash_chain_verification_notification: %{
    from: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_FROM", ""},
    to: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_TO", ""},
    subject: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_SUBJECT", ""}
  },
  employee_created_notification: %{
    from: {:system, "BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_FROM", ""},
    subject: {:system, "BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_SUBJECT", ""}
  },
  credentials_recovery_request: %{
    from: {:system, "BAMBOO_CREDENTIALS_RECOVERY_REQUEST_INVITATION_FROM", ""},
    subject: {:system, "BAMBOO_CREDENTIALS_RECOVERY_REQUEST_INVITATION_SUBJECT", ""}
  }

config :core, Core.Man.Templates.EmployeeRequestInvitation,
  id: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_ID"},
  format: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_LOCALE", "uk_UA"}

# Configures employee request update invitation template
config :core, Core.Man.Templates.EmployeeRequestUpdateInvitation,
  id: {:system, "EMPLOYEE_REQUEST_UPDATE_INVITATION_TEMPLATE_ID"},
  format: {:system, "EMPLOYEE_REQUEST_UPDATE_INVITATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMPLOYEE_REQUEST_UPDATE_INVITATION_TEMPLATE_LOCALE", "uk_UA"}

config :core, Core.Man.Templates.HashChainVerificationNotification,
  id: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_ID", ""},
  format: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_FORMAT", ""},
  locale: {:system, "CHAIN_VERIFICATION_FAILED_NOTIFICATION_LOCALE", ""}

# employee created notification
# Configures employee created notification template
config :core, Core.Man.Templates.EmployeeCreatedNotification,
  id: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_ID"},
  format: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_LOCALE", "uk_UA"}

config :core, Core.Man.Templates.DeclarationRequestPrintoutForm,
  id: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID"},
  format: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_LOCALE", "uk_UA"}

config :core, Core.Man.Templates.ContractRequestPrintoutForm,
  id: {:system, "CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_ID"},
  appendix_id: {:system, "CONTRACT_REQUEST_PRINTOUT_FORM_APPENDIX_TEMPLATE_ID"},
  format: {:system, "CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_LOCALE", "uk_UA"}

config :core, Core.Man.Templates.EmailVerification,
  id: {:system, "EMAIL_VERIFICATION_TEMPLATE_ID"},
  from: {:system, "EMAIL_VERIFICATION_FROM"},
  subject: {:system, "EMAIL_VERIFICATION_SUBJECT"},
  format: {:system, "EMAIL_VERIFICATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMAIL_VERIFICATION_TEMPLATE_LOCALE", "uk_UA"}

# Template and setting for credentials recovery requests
config :core, :credentials_recovery_request_ttl, {:system, :integer, "CREDENTIALS_RECOVERY_REQUEST_TTL", 1_500}

config :core, Core.Man.Templates.CredentialsRecoveryRequest,
  id: {:system, "CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_ID"},
  format: {:system, "CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_LOCALE", "uk_UA"}

config :core, :legal_entity_employee_types,
  msp: {:system, "LEGAL_ENTITY_MSP_EMPLOYEE_TYPES", ["OWNER", "HR", "DOCTOR", "ADMIN"]},
  pharmacy: {:system, "LEGAL_ENTITY_PHARMACY_EMPLOYEE_TYPES", ["PHARMACY_OWNER", "PHARMACIST", "HR"]}

config :core, :legal_entity_division_types,
  msp: {:system, "LEGAL_ENTITY_MSP_DIVISION_TYPES", ["CLINIC", "AMBULANT_CLINIC", "FAP"]},
  pharmacy: {:system, "LEGAL_ENTITY_PHARMACIST_DIVISION_TYPES", ["DRUGSTORE", "DRUGSTORE_POINT"]}

config :core, :employee_specialities_types,
  doctor: {:system, "DOCTOR_SPECIALITIES_TYPES", ["THERAPIST", "PEDIATRICIAN", "FAMILY_DOCTOR"]},
  pharmacist: {:system, "PHARMACIST_SPECIALITIES_TYPES", ["PHARMACIST", "PHARMACIST2"]}

config :core, :medication_request_request,
  expire_in_minutes: {:system, "MEDICATION_REQUEST_REQUEST_EXPIRATION", 30},
  otp_code_length: {:system, "MEDICATION_REQUEST_REQUEST_OTP_CODE_LENGTH", 4}

config :core, :medication_request,
  sign_template_sms:
    {:system, "TEMPLATE_SMS_FOR_SIGN_MEDICATION_REQUEST",
     "Ваш рецепт: <request_number>. Код підтвердження: <verification_code>"},
  reject_template_sms:
    {:system, "TEMPLATE_SMS_FOR_REJECT_MEDICATION_REQUEST", "Відкликано рецепт: <request_number> від <created_at>"}

# Configures bamboo
config :core, Core.API.Postmark, endpoint: {:system, "POSTMARK_ENDPOINT"}

config :core, Core.Bamboo.PostmarkMailer,
  adapter: Core.Bamboo.PostmarkAdapter,
  api_key: {:system, "POSTMARK_API_KEY", ""}

config :core, Core.Bamboo.MailgunMailer,
  adapter: Core.Bamboo.MailgunAdapter,
  api_key: {:system, "MAILGUN_API_KEY", ""},
  domain: {:system, "MAILGUN_DOMAIN", ""}

config :core, Core.Bamboo.SMTPMailer,
  adapter: Core.Bamboo.SMTPAdapter,
  server: {:system, "BAMBOO_SMTP_SERVER", ""},
  hostname: {:system, "BAMBOO_SMTP_HOSTNAME", ""},
  port: {:system, "BAMBOO_SMTP_PORT", ""},
  username: {:system, "BAMBOO_SMTP_USERNAME", ""},
  password: {:system, "BAMBOO_SMTP_PASSWORD", ""},
  tls: :if_available,
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  ssl: true,
  retries: 1

# Configures address merger
config :core, Core.Utils.AddressMerger, no_suffix_areas: {:system, "NO_SUFFIX_AREAS", ["М.КИЇВ", "М.СЕВАСТОПОЛЬ"]}

# Configures genral validator
config :core, Core.LegalEntities.Validator, owner_positions: {:system, :list, "OWNER_POSITIONS", [""]}

# Configures birth date validator
config :core, Core.Validators.BirthDate,
  min_age: {:system, "MIN_AGE", 0},
  max_age: {:system, "MAX_AGE", 150}

# Configures Cabinet
config :core, jwt_secret: {:system, "JWT_SECRET"}

config :core, Core.Cabinet.API,
  # hour
  jwt_ttl_email: {:system, :integer, "JWT_TTL_EMAIL"},
  jwt_ttl_registration: {:system, :integer, "JWT_TTL_REGISTRATION"},
  role_id: {:system, "CABINET_ROLE_ID"},
  client_id: {:system, "CABINET_CLIENT_ID"}

# Configures Guardian
config :core, Core.Guardian,
  issuer: "EHealth",
  secret_key: {Confex, :fetch_env!, [:core, :jwt_secret]}

# Deviation koeficient 0..1, equal to percents
config :core, Core.MedicationDispense.API, deviation: {:system, :float, "DEVIATION", 0.1}

config :cipher,
  keyphrase: System.get_env("CIPHER_KEYPHRASE") || "8()VN#U#_CU#X)*BFG(Cadsvn$&",
  ivphrase: System.get_env("CIPHER_IVPHRASE") || "B((%(^(%V(CWBY(**(by(*YCBDYB#(Y(C#"

import_config "#{Mix.env()}.exs"

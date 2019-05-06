use Mix.Config

config :core,
  namespace: Core,
  env: Mix.env(),
  system_user: {:system, "EHEALTH_SYSTEM_USER", "4261eacf-8008-4e62-899f-de1e2f7065f0"},
  ecto_repos: [Core.Repo, Core.PRMRepo, Core.FraudRepo]

config :logger_json, :backend,
  formatter: EhealthLogger.Formatter,
  metadata: :all

config :logger,
  backends: [LoggerJSON],
  level: :info

config :ecto_trail, table_name: "audit_log"

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
    postmark: Core.API.Postmark,
    declaration_request_creator: Core.DeclarationRequests.API.V1.Creator
  ],
  cache: [
    validators: Core.Validators.Cache
  ],
  rpc_worker: Core.Rpc.Worker,
  rpc_edr_worker: Core.Rpc.EdrWorker,
  repos: [
    read_repo: Core.ReadRepo,
    read_prm_repo: Core.ReadPRMRepo
  ],
  kafka: [
    producer: Core.Kafka.Producer
  ],
  sms_provider: {:system, :string, "SMS_PROVIDER", "mouth_sms2ip"},
  legal_entity_edr_verify: {:system, :boolean, "LEGAL_ENTITY_EDR_VERIFY", false},
  dispense_division_dls_verify: {:system, :boolean, "DISPENSE_DIVISION_DLS_VERIFY", false}

# Configures Legal Entities token permission
config :core, Core.Context,
  tokens_types_personal: {:system, :list, "TOKENS_TYPES_PERSONAL", ["MSP", "PHARMACY", "MSP_PHARMACY"]},
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
  employee_request_bucket: {:system, "MEDIA_STORAGE_EMPLOYEE_REQUEST_BUCKET"},
  declaration_request_bucket: {:system, "MEDIA_STORAGE_DECLARATION_REQUEST_BUCKET"},
  declaration_bucket: {:system, "MEDIA_STORAGE_DECLARATION_BUCKET"},
  medication_request_request_bucket: {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_REQUEST_BUCKET"},
  person_bucket: {:system, "MEDIA_STORAGE_PERSON_BUCKET"},
  medication_dispense_bucket: {:system, "MEDIA_STORAGE_MEDICATION_DISPENSE_BUCKET"},
  medication_request_bucket: {:system, "MEDIA_STORAGE_MEDICATION_REQUEST_BUCKET"},
  related_legal_entity_bucket: {:system, "MEDIA_STORAGE_RELATED_LEGAL_ENTITY_BUCKET"},
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

config :core, Core.Man.Templates.CapitationContractRequestPrintoutForm,
  id: {:system, "CAPITATION_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_ID"},
  appendix_id: {:system, "CAPITATION_CONTRACT_REQUEST_PRINTOUT_FORM_APPENDIX_TEMPLATE_ID"},
  format: {:system, "CAPITATION_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "CAPITATION_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_LOCALE", "uk_UA"}

config :core, Core.Man.Templates.ReimbursementContractRequestPrintoutForm,
  id: {:system, "REIMBURSEMENT_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", 14},
  format: {:system, "REIMBURSEMENT_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "REIMBURSEMENT_CONTRACT_REQUEST_PRINTOUT_FORM_TEMPLATE_LOCALE", "uk_UA"}

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
  nhs: {:system, :list, "LEGAL_ENTITY_NHS_EMPLOYEE_TYPES", ["NHS ADMIN", "NHS ADMIN SIGNER", "NHS LE VERIFIER"]},
  msp: {:system, :list, "LEGAL_ENTITY_MSP_EMPLOYEE_TYPES", ["OWNER", "HR", "DOCTOR", "ADMIN"]},
  msp_pharmacy:
    {:system, :list, "LEGAL_ENTITY_MSP_PHARMACY_EMPLOYEE_TYPES", ["OWNER", "HR", "DOCTOR", "ADMIN", "PHARMACIST"]},
  pharmacy: {:system, :list, "LEGAL_ENTITY_PHARMACY_EMPLOYEE_TYPES", ["PHARMACY_OWNER", "PHARMACIST", "HR"]}

config :core, :legal_entity_division_types,
  msp: {:system, :list, "LEGAL_ENTITY_MSP_DIVISION_TYPES", ["CLINIC", "AMBULANT_CLINIC", "FAP"]},
  pharmacy: {:system, :list, "LEGAL_ENTITY_PHARMACIST_DIVISION_TYPES", ["DRUGSTORE", "DRUGSTORE_POINT"]},
  msp_pharmacy:
    {:system, :list, "LEGAL_ENTITY_MSP_PHARMACY_DIVISION_TYPES",
     ["CLINIC", "AMBULANT_CLINIC", "FAP", "DRUGSTORE", "DRUGSTORE_POINT"]}

config :core, :contracts_division_types,
  capitation: {:system, :list, "CAPITATION_CONTRACT_DIVISION_TYPES", ["CLINIC", "AMBULANT_CLINIC", "FAP"]},
  reimbursement: {:system, :list, "REIMBURSEMENT_CONTRACT_DIVISION_TYPES", ["DRUGSTORE", "DRUGSTORE_POINT"]}

config :core, :employee_speciality_types,
  doctor: {:system, :list, "DOCTOR_SPECIALITIES_TYPES", ["THERAPIST", "PEDIATRICIAN", "FAMILY_DOCTOR"]},
  pharmacist:
    {:system, :list, "PHARMACIST_SPECIALITIES_TYPES", ["PHARMACIST", "PROVISOR", "CLINICAL_PROVISOR", "RECEPTIONIST"]}

config :core, :employee_speciality_levels,
  doctor: {:system, :list, "DOCTOR_SPECIALITY_LEVELS", ["FIRST", "SECOND", "HIGHEST", "NOT_APPLICABLE"]},
  pharmacist: {:system, :list, "PHARMACIST_SPECIALITY_LEVELS", ["BASIC", "FIRST", "SECOND", "HIGHEST"]}

config :core, :employee_education_degrees,
  doctor: {:system, :list, "DOCTOR_EDUCATION_DEGREES", ["EXPERT", "MASTER", "BACHELOR", "JUNIOR_EXPERT"]},
  pharmacist: {:system, :list, "PHARMACIST_EDUCATION_DEGREES", ["EXPERT", "MASTER", "BACHELOR", "JUNIOR_EXPERT"]}

config :core, :employee_qualification_types,
  doctor:
    {:system, :list, "DOCTOR_QUALIFICATION_TYPES",
     [
       "INTERNSHIP",
       "STAZHUVANNYA",
       "REATTESTATION",
       "SPECIALIZATION",
       "TOPIC_IMPROVEMENT",
       "CLINICAL_RESIDENCY",
       "INFORMATION_COURSES"
     ]},
  pharmacist:
    {:system, :list, "PHARMACIST_QUALIFICATION_TYPES",
     ["INTERNSHIP", "STAZHUVANNYA", "REATTESTATION", "SPECIALIZATION", "TOPIC_IMPROVEMENT", "INFORMATION_COURSES"]}

config :core, :medication_request_request,
  expire_in_minutes: {:system, :integer, "MEDICATION_REQUEST_REQUEST_EXPIRATION", 30},
  otp_code_length: {:system, :integer, "MEDICATION_REQUEST_REQUEST_OTP_CODE_LENGTH", 4},
  delay_input: {:system, :integer, "MEDICATION_REQUEST_REQUEST_DELAY_INPUT", 3},
  standard_duration: {:system, :integer, "MEDICATION_REQUEST_REQUEST_STANDARD_DURATION", 21},
  min_renew_days: {:system, :integer, "MEDICATION_REQUEST_MIN_RENEW_DAY", 3},
  max_renew_days: {:system, :integer, "MEDICATION_REQUEST_MAX_RENEW_DAY", 7}

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
config :core, Core.Utils.AddressMerger,
  no_suffix_areas: {:system, :list, "NO_SUFFIX_AREAS", ["М.КИЇВ", "М.СЕВАСТОПОЛЬ"]}

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
config :core, Core.MedicationDispense.API,
  deviation: {:system, :float, "DEVIATION", 0.1},
  tolerance: {:system, :float, "TOLERANCE", 0.01}

config :core, Core.DeclarationRequests.API.V1.Creator,
  use_phone_number_auth_limit: {:system, :boolean, "USE_PHONE_NUMBER_AUTH_LIMIT", true}

config :cipher,
  keyphrase: System.get_env("CIPHER_KEYPHRASE") || "8()VN#U#_CU#X)*BFG(Cadsvn$&",
  ivphrase: System.get_env("CIPHER_IVPHRASE") || "B((%(^(%V(CWBY(**(by(*YCBDYB#(Y(C#"

config :core, Core.Rpc.Worker, max_attempts: {:system, :integer, "RPC_MAX_ATTEMPTS", 3}
config :core, Core.Rpc.EdrWorker, timeout: {:system, :integer, "RPC_EDR_WORKER_TIMEOUT", 15_000}

config :kaffe,
  producer: [
    endpoints: [localhost: 9092],
    topics: ["deactivate_declaration_events", "merge_legal_entities", "edr_verification_events", "event_manager_topic"]
  ]

config :core,
  topologies: [
    k8s_me: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "medical_events_api",
        kubernetes_selector: "app=api-medical-events",
        kubernetes_namespace: "me",
        polling_interval: 10_000
      ]
    ],
    k8s_uaddresses: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "uaddresses_api",
        kubernetes_selector: "app=api",
        kubernetes_namespace: "uaddresses",
        polling_interval: 10_000
      ]
    ],
    k8s_ops: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "ops",
        kubernetes_selector: "app=api",
        kubernetes_namespace: "ops",
        polling_interval: 10_000
      ]
    ],
    k8s_mpi: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "mpi",
        kubernetes_selector: "app=api",
        kubernetes_namespace: "mpi",
        polling_interval: 10_000
      ]
    ],
    k8s_mithril: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "mithril_api",
        kubernetes_selector: "app=api",
        kubernetes_namespace: "mithril",
        polling_interval: 10_000
      ]
    ],
    k8s_edr_api: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "edr_api",
        kubernetes_selector: "app=edr-api",
        kubernetes_namespace: "edr",
        polling_interval: 10_000
      ]
    ],
    k8s_manual_merger: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "manual_merger",
        kubernetes_selector: "app=manual-merger",
        kubernetes_namespace: "mpi",
        polling_interval: 10_000
      ]
    ],
    k8s_jabba: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "jabba-rpc",
        kubernetes_selector: "app=jabba-rpc",
        kubernetes_namespace: "jabba",
        polling_interval: 10_000
      ]
    ]
  ]

import_config "#{Mix.env()}.exs"

use Mix.Config

# General application configuration
config :ehealth,
  ecto_repos: [EHealth.Repo],
  employee_requests_per_page: {:system, :integer, "EMPLOYEE_REQUESTS_PER_PAGE", 50},
  namespace: EHealth

# Configures the endpoint
config :ehealth, EHealth.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "AcugHtFljaEFhBY1d6opAasbdFYsvV8oydwW98qS0oZOv+N/a5TE5G7DPfTZcXm9",
  render_errors: [view: EView.Views.PhoenixError, accepts: ~w(json)]

# Configures Digital Signature API
config :ehealth, EHealth.API.Signature,
  endpoint: {:system, "DIGITAL_SIGNATURE_ENDPOINT", "http://35.187.186.145"},
  timeouts: [
    connect_timeout: {:system, :integer, "DIGITAL_SIGNATURE_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "DIGITAL_SIGNATURE_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "DIGITAL_SIGNATURE_REQUEST_TIMEOUT", 30_000}
  ]

# Configures MediaStorage API
config :ehealth, EHealth.API.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT", "http://api-svc.ael"},
  legal_entity_bucket: {:system, "MEDIA_STORAGE_LEGAL_ENTITY_BUCKET", "legal-entities-dev"},
  declaration_request_bucket: {:system, "MEDIA_STORAGE_DECLARATION_REQUEST_BUCKET", "declaration-requests-dev"},
  enabled?: {:system, :boolean, "MEDIA_STORAGE_ENABLED", false},
  hackney_options: [
    connect_timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000}
  ]

# Configures PRM API
config :ehealth, EHealth.API.PRM,
  endpoint: {:system, "PRM_ENDPOINT", "http://api-svc.prm/api"},
  timeouts: [
    connect_timeout: {:system, :integer, "PRM_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "PRM_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "PRM_REQUEST_TIMEOUT", 30_000}
  ]

# Configures OAuth API
config :ehealth, EHealth.API.Mithril,
  endpoint: {:system, "OAUTH_ENDPOINT", "http://api-svc.mithril"},
  hackney_options: [
    connect_timeout: {:system, :integer, "OAUTH_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "OAUTH_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "OAUTH_REQUEST_TIMEOUT", 30_000}
  ]

# Configures Man API
config :ehealth, EHealth.API.Man,
  endpoint: {:system, "MAN_ENDPOINT", "http://api-svc.man"},
  timeouts: [
    connect_timeout: {:system, :integer, "MAN_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MAN_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MAN_REQUEST_TIMEOUT", 30_000}
  ]

# Configures UAddress API
config :ehealth, EHealth.API.UAddress,
  endpoint: {:system, "UADDRESS_ENDPOINT", "http://api-svc.uaddresses"},
  timeouts: [
    connect_timeout: {:system, :integer, "UADDRESS_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "UADDRESS_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "UADDRESS_REQUEST_TIMEOUT", 30_000}
  ]

# Configures OTP Verification API
config :ehealth, EHealth.API.OTPVerification,
  endpoint: {:system, "OTP_VERIFICATION_ENDPOINT", "http://api-svc.verification"},
  timeouts: [
    connect_timeout: {:system, :integer, "OTP_VERIFICATION_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "OTP_VERIFICATION_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "OTP_VERIFICATION_REQUEST_TIMEOUT", 30_000}
  ]

# Configures MPI API
config :ehealth, EHealth.API.MPI,
  endpoint: {:system, "MPI_ENDPOINT", "http://api-svc.mpi"},
  timeouts: [
    connect_timeout: {:system, :integer, "MPI_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MPI_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MPI_REQUEST_TIMEOUT", 30_000}
  ]

# Configures Gandalf API
config :ehealth, EHealth.API.Gandalf,
  endpoint: {:system, "GNDF_ENDPOINT", "https://api.gndf.io"},
  client_id: {:system, "GNDF_CLIENT_ID", "some_client_id"},
  client_secret: {:system, "GNDF_CLIENT_SECRET", "some_client_secret"},
  application_id: {:system, "GNDF_APPLICATION_ID", "some_gndf_application_id"},
  table_id: {:system, "GNDF_TABLE_ID", "some_gndf_table_id"},
  timeouts: [
    connect_timeout: {:system, :integer, "GNDF_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "GNDF_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "GNDF_REQUEST_TIMEOUT", 30_000}
  ]

# employee request invitation
# Configures employee request invitation template
config :ehealth, EHealth.Man.Templates.EmployeeRequestInvitation,
  id: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_ID", 1},
  format: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMPLOYEE_REQUEST_INVITATION_TEMPLATE_LOCALE", "uk_UA"}

# Configures employee request invitation email
config :ehealth, EHealth.Bamboo.Emails.EmployeeRequestInvitation,
  from: {:system, "BAMBOO_EMPLOYEE_REQUEST_INVITATION_FROM", ""},
  subject: {:system, "BAMBOO_EMPLOYEE_REQUEST_INVITATION_SUBJECT", ""}

# employee created notification
# Configures employee created notification template
config :ehealth, EHealth.Man.Templates.EmployeeCreatedNotification,
  id: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_ID", 35},
  format: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_LOCALE", "uk_UA"}

config :ehealth, EHealth.Man.Templates.DeclarationRequestPrintoutForm,
  id: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID", 4},
  format: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_FORMAT", "text/html"},
  locale: {:system, "DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_LOCALE", "uk_UA"}

# Configures employee created notification email
config :ehealth, EHealth.Bamboo.Emails.EmployeeCreatedNotification,
  from: {:system, "BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_FROM", ""},
  subject: {:system, "BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_SUBJECT", ""}

# Configures bamboo
config :ehealth, EHealth.Bamboo.Mailer,
  adapter: EHealth.Bamboo.PostmarkAdapter,
  api_key: {:system, "POSTMARK_API_KEY", ""}

# Configures address merger
config :ehealth, EHealth.Utils.AddressMerger,
  no_suffix_areas: {:system, "NO_SUFFIX_AREAS", ["М.КИЇВ", "М.СЕВАСТОПОЛЬ"]}

# Configures birth date validator
config :ehealth, EHealth.Validators.BirthDate,
  min_age: {:system, "MIN_AGE", 0},
  max_age: {:system, "MAX_AGE", 150}

config :ehealth, EHealth.DeclarationRequest.API.Create,
  declaration_request_offline_documents: {:system, :list, "DECLARATION_REQUEST_OFFLINE_DOCUMENTS", ["Passport", "SSN"]}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure JSON Logger back-end
config :logger_json, :backend,
  on_init: {EHealth, :load_from_system_env, []},
  json_encoder: Poison,
  metadata: :all

import_config "#{Mix.env}.exs"

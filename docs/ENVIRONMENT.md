# Environment Variables

This environment variables can be used to configure released docker container at start time.
Also sample `.env` can be used as payload for `docker run` cli.

## General

| VAR_NAME      | Default Value           | Description |
| ------------- | ----------------------- | ----------- |
| ERLANG_COOKIE | `03/yHifHIEl`.. | Erlang [distribution cookie](http://erlang.org/doc/reference_manual/distributed.html). **Make sure that default value is changed in production.** |
| LOG_LEVEL     | `info` | Elixir Logger severity level. Possible values: `debug`, `info`, `warn`, `error`. |

## Phoenix HTTP Endpoint

| VAR_NAME      | Default Value | Description |
| ------------- | ------------- | ----------- |
| PORT          | `4000`        | HTTP host for web app to listen on. |
| HOST          | `localhost`   | HTTP port for web app to listen on. |
| SECRET_KEY    | `b9WHCgR5TGcr`.. | Phoenix [`:secret_key_base`](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html). **Make sure that default value is changed in production.** |

## Database

| VAR_NAME      | Default Value | Description |
| ------------- | ------------- | ----------- |
| DB_NAME       | `nil`         | Database name. |
| DB_USER       | `nil`         | Database user name. |
| DB_PASSWORD   | `nil`         | Database user password. |
| DB_HOST       | `nil`         | Database host. |
| DB_PORT       | `nil`         | Database port. |
| DB_POOL_SIZE  | `nil`         | Number of connections to the database. |
| DB_MIGRATE    | `false`       | Flag to run migration. |
| DB_SEED       | `false`       | Flag to seed data to database. |

## Medication Request Request
| VAR_NAME      | Default Value | Description |
| ------------- | ------------- | ----------- |
| MEDICATION_REQUEST_REQUEST_EXPIRATION_PERIOD       | 30         | Medication Request Request Expiration Period in days represented as integer |

# Endpoints

## Media Storage

| VAR_NAME                                  | Default Value | Description |
| ----------------------------------------- | ------------- | ----------- |
| MEDIA_STORAGE_ENDPOINT                    | not set       | Endpoint for [Ael](http://docs.ael.apiary.io/#). |
| MEDIA_STORAGE_LEGAL_ENTITY_BUCKET         | not set       | Google Cloud Storage bucket name for Legal Entities. |
| MEDIA_STORAGE_DECLARATION_BUCKET          | not set       | Google Cloud Storage bucket name for Declaration requests. |
| MEDIA_STORAGE_DECLARATION_REQUEST_BUCKET  | not set       | Google Cloud Storage bucket name for Declaration requests. |
| MEDIA_STORAGE_ENABLED                     | `false`       | Enable/disable data storing to Google Cloud Storage. |
| MEDIA_STORAGE_REQUEST_TIMEOUT             | `30_000`      | HTTP timeout for hackney. |

## OAuth

| VAR_NAME              | Default Value   | Description |
| --------------------- | --------------- | ----------- |
| OAUTH_ENDPOINT        | not set         | Endpoint for [Mithril](http://docs.mithril1.apiary.io/#). |
| OAUTH_REQUEST_TIMEOUT | `30_000`        | HTTP timeout for hackney. |

## Man

| VAR_NAME            | Default Value | Description |
| ------------------- | --------------| ----------- |
| MAN_ENDPOINT        | not set       | Endpoint for [Man](http://docs.man2.apiary.io/#). |
| MAN_REQUEST_TIMEOUT | `30_000`      | HTTP timeout for hackney. |

## UAddresses

| VAR_NAME                  | Default Value  | Description |
| ------------------------- | -------------- | ----------- |
| UADDRESS_ENDPOINT         | not set        | Endpoint for [UAdress](http://docs.uaddress.apiary.io/). |
| UADDRESS_ENDPOINT_TIMEOUT | `30_000`       | HTTP timeout for hackney. |

## OTP

| VAR_NAME                         | Default Value  | Description |
| -------------------------------- | -------------- | ----------- |
| OTP_VERIFICATION_ENDPOINT        | not set        | Endpoint for [OTP](http://docs.ehealthapi1.apiary.io/#reference/public.-medical-service-provider-integration-layer/otp-verification). |
| OTP_VERIFICATION_REQUEST_TIMEOUT | `30_000`       | HTTP timeout for hackney. |

## OPS

| VAR_NAME            | Default Value  | Description |
| ------------------- | -------------- | ----------- |
| OPS_ENDPOINT        | not set        | Endpoint for [OPS](http://docs.ehealthapi1.apiary.io/#reference/internal.-ops-db). |
| OPS_REQUEST_TIMEOUT | `30_000`       | HTTP timeout for hackney. |

## Digital Signature service

| VAR_NAME                          | Default Value | Description |
| --------------------------------- | --------------| ----------- |
| DIGITAL_SIGNATURE_ENDPOINT        | not set       | Endpoint for [Digital Signature Service](http://docs.ehealthapi1.apiary.io/#reference/internal.-digital-signature/verification/digital-signature). |
| DIGITAL_SIGNATURE_REQUEST_TIMEOUT | `30_000`      | HTTP timeout for hackney. |

## Gandalf

| VAR_NAME              | Default Value | Description |
|-----------------------|---------------|-------------|
| GNDF_ENDPOINT         | not_set       | Endpoint for [Gandalf](http://docs.gandalf4.apiary.io/#) |
| GNDF_CLIENT_ID        | not_set       | Client ID for auth |
| GNDF_CLIENT_SECRET    | not_set       | Client secret for auth |
| GNDF_APPLICATION_ID   | not_set       | Application ID for EHealth |
| GNDF_TABLE_ID         | not_set       | Decision table ID |
| GNDF_REQUEST_TIMEOUT  | not_set       | HTTP timeout for hackney. |

# Email

## Templates

| VAR_NAME                                                | Default Value | Description |
| ------------------------------------------------------- | ------------- | ----------- |
| EMPLOYEE_REQUEST_INVITATION_TEMPLATE_ID                 | not set       | Template id from Man that we will use for employee request invitation. |
| EMPLOYEE_REQUEST_INVITATION_TEMPLATE_FORMAT             | `text/html`   | Format in which we want to get the rendered template. Available values: text/html, application/json and application/pdf. |
| EMPLOYEE_REQUEST_INVITATION_TEMPLATE_LOCALE             | `uk_UA`       | Locale that we want to use for rendering the template. It should be configured in template settings on Man. |
| EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_ID               | not set       | Template id from Man that we will use for success employee creation notification. |
| EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_FORMAT           | `text/html`   | Template format for Employee created notifications. Available: text/html, application/json and application/pdf. |
| EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_LOCALE           | `uk_UA`       | Template locale. It should be configured in template settings on Man. |
| DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_LOCALE       | `uk_UA`       | Template locale. It should be configured in template settings on Man. |
| CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_ID     | not set       | Template id from Man that we will use for success employee creation notification. |
| CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_FORMAT | `text/html`   | Template format for Employee created notifications. Available: text/html, application/json and application/pdf. |
| CREDENTIALS_RECOVERY_REQUEST_INVITATION_TEMPLATE_LOCALE | `uk_UA`       | Template locale. It should be configured in template settings on Man. |
| DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_ID           | not set       | Template id from Man that we will use for declaration printout form. |
| DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_FORMAT       | `text/html`   | Template format for declaration printout form. Available: text/html, application/json and application/pdf. |
| DECLARATION_REQUEST_PRINTOUT_FORM_TEMPLATE_LOCALE       | `uk_UA`       | Template locale. It should be configured in template settings on Man. |

## Postmark

| VAR_NAME         | Default Value | Description |
| ---------------- | ------------- | ----------- |
| POSTMARK_API_KEY | not set       | Postmark API key |
## Mailgun

| VAR_NAME         | Default Value | Description |
| ---------------- | ------------- | ----------- |
| MAILGUN_API_KEY | not set       | Mailgun API key |
| MAILGUN_DOMAIN | not set       | Mailgun domain |

## Bamboo

| VAR_NAME                                                | Default Value | Description |
| ------------------------------------------------------- | ------------- | ----------- |
| BAMBOO_MAILER                                           | ``            | Service that will be used to send emails. Posible variants: EHealth.Bamboo.PostmarkMailer, EHealth.Bamboo.MailgunMailter, EHealth.Bamboo.SMTPMailer. All services need to be configured by thier own modules configes
| BAMBOO_EMPLOYEE_REQUEST_INVITATION_FROM                 | ``            | Email address that will be used as a sender in employee request invitation email. |
| BAMBOO_EMPLOYEE_REQUEST_INVITATION_SUBJECT              | ``            | The subject of the employee request invitation email. |
| BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_FROM               | ``            | Email address that will be used as a sender in employee created notification email. |
| BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_SUBJECT            | ``            | The subject of the employee created notification email. |
| BAMBOO_CREDENTIALS_RECOVERY_REQUEST_INVITATION_FROM     | ``            | The subject of the employee created notification email. |
| BAMBOO_CREDENTIALS_RECOVERY_REQUEST_INVITATION_SUBJECT  | ``            | The subject of the employee created notification email. |

# Paging
| VAR_NAME                      | Default Value | Description                                        |
| --------------------------    | ------------- | -----------                                        |
| EMPLOYEE_REQUESTS_PER_PAGE    | `50`          | Number of items per page for Employee requests.    |
| DECLARATION_REQUESTS_PER_PAGE | `50`          | Number of items per page for Declaration requests. |

# Tokens
| VAR_NAME                                     | Default Value | Description |
| -------------------------------------------- | ------------- | ----------- |
| TOKENS_TYPES_PERSONAL                        | not set       | List of Client_types where only records that belong to client_id from the token will be returned
| TOKENS_TYPES_MIS                             | not set       | List of Client_types where only records that are created by client_id from the token will be returned
| TOKENS_TYPES_ADMIN                           | not set       | Results are filtered by the request parameters if any, client_id from token is ignored

# Legal Entity employee types
| VAR_NAME                                     | Default Value | Description |
| -------------------------------------------- | ------------- | ----------- |
| LEGAL_ENTITY_MSP_EMPLOYEE_TYPES              | not set       | List of available Employee types in Legal Entity
| LEGAL_ENTITY_PHARMACY_EMPLOYEE_TYPES         | not set       | List of available Pharmacy Employee types in Legal Entity

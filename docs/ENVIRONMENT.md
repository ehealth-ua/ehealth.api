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

# Endpoints

## Media Storage

| VAR_NAME                          | Default Value        | Description |
| --------------------------------- | -------------------- | ----------- |
| MEDIA_STORAGE_ENDPOINT            | `http://api-svc.ael` | Endpoint for [Ael](http://docs.ael.apiary.io/#). |
| MEDIA_STORAGE_LEGAL_ENTITY_BUCKET | `legal-entities-dev` | Google Cloud Storage bucket name for Legal Entities. |
| MEDIA_STORAGE_ENABLED             | `false`              | Enable/disable data storing to Google Cloud Storage. |
| MEDIA_STORAGE_REQUEST_TIMEOUT     | `30_000`             | HTTP timeout for hackney. |

## Partner relationship management (PRM)

| VAR_NAME            | Default Value        | Description |
| ------------------- | -------------------- | ----------- |
| PRM_ENDPOINT        | `http://api-svc.prm` | Endpoint for [PRM](http://docs.ehealthapi1.apiary.io/#reference/internal.-partner-relationship-management). |
| PRM_REQUEST_TIMEOUT | `30_000`             | HTTP timeout for hackney. |

## OAuth

| VAR_NAME              | Default Value            | Description |
| --------------------- | ------------------------ | ----------- |
| OAUTH_ENDPOINT        | `http://api-svc.mithril` | Endpoint for [Mithril](http://docs.mithril1.apiary.io/#). |
| OAUTH_REQUEST_TIMEOUT | `30_000`                 | HTTP timeout for hackney. |

## Man

| VAR_NAME            | Default Value        | Description |
| ------------------- | -------------------- | ----------- |
| MAN_ENDPOINT        | `http://api-svc.man` | Endpoint for [Man](http://docs.man2.apiary.io/#). |
| MAN_REQUEST_TIMEOUT | `30_000`             | HTTP timeout for hackney. |

## UAddresses

| VAR_NAME                  | Default Value               | Description |
| ------------------------- | --------------------------- | ----------- |
| UADDRESS_ENDPOINT         | `http://api-svc.uaddresses` | Endpoint for [UAdress](http://docs.uaddress.apiary.io/). |
| UADDRESS_ENDPOINT_TIMEOUT | `30_000`                    | HTTP timeout for hackney. |

## Digital Signature service

| VAR_NAME                          | Default Value       | Description |
| --------------------------------- | ------------------- | ----------- |
| DIGITAL_SIGNATURE_ENDPOINT        | `http://api-svc.ds` | Endpoint for [Digital Signature Service](http://docs.ehealthapi1.apiary.io/#reference/internal.-digital-signature/verification/digital-signature). |
| DIGITAL_SIGNATURE_REQUEST_TIMEOUT | `30_000`            | HTTP timeout for hackney. |


# Email

## Templates

| VAR_NAME                                      | Default Value | Description |
| --------------------------------------------- | ------------- | ----------- |
| EMPLOYEE_REQUEST_INVITATION_TEMPLATE_ID       | `1`           | Template id from Man that we will use for employee request invitation. |
| EMPLOYEE_REQUEST_INVITATION_TEMPLATE_FORMAT   | `text/html`   | Format in which we want to get the rendered template. Available values: text/html, application/json and application/pdf. |
| EMPLOYEE_REQUEST_INVITATION_TEMPLATE_LOCALE   | `uk_UA`       | Locale that we want to use for rendering the template. It should be configured in template settings on Man. |
| EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_ID     | `35`          | Template id from Man that we will use for success employee creation notification. |
| EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_FORMAT | `text/html`   | Template format for Employee created notifications. Available: text/html, application/json and application/pdf. |
| EMPLOYEE_CREATED_NOTIFICATION_TEMPLATE_LOCALE | `uk_UA`       | Template locale. It should be configured in template settings on Man. |

## Postmark

| VAR_NAME         | Default Value | Description |
| ---------------- | ------------- | ----------- |
| POSTMARK_API_KEY | ``            | Postmark API key |

## Bamboo

| VAR_NAME                                     | Default Value | Description |
| -------------------------------------------- | ------------- | ----------- |
| BAMBOO_EMPLOYEE_REQUEST_INVITATION_FROM      | ``            | Email address that will be used as a sender in employee request invitation email. |
| BAMBOO_EMPLOYEE_REQUEST_INVITATION_SUBJECT   | ``            | The subject of the employee request invitation email. |
| BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_FROM    | ``            | Email address that will be used as a sender in employee created notification email. |
| BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_SUBJECT | ``            | The subject of the employee created notification email. |

# Paging
| VAR_NAME                      | Default Value | Description                                        |
| --------------------------    | ------------- | -----------                                        |
| EMPLOYEE_REQUESTS_PER_PAGE    | `50`          | Number of items per page for Employee requests.    |
| DECLARATION_REQUESTS_PER_PAGE | `50`          | Number of items per page for Declaration requests. |

# Tokens
| VAR_NAME                                     | Default Value | Description |
| -------------------------------------------- | ------------- | ----------- |
|TOKENS_TYPES_PERSONAL                         |`MSP`          | List of Client_types where only records that belong to client_id from the token will be returned
| TOKENS_TYPES_MIS                             |`MIS`             | List of Client_types where only records that are created by client_id from the token will be returned
| TOKENS_TYPES_ADMIN                           |`NHS_Admin`, `MIS`| Results are filtered by the request parameters if any, client_id from token is ignored

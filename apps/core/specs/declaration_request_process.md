### High-level overview

* [Apiary API](http://docs.ehealthapi1.apiary.io/#reference/public.-medical-service-provider-integration-layer/declaration-requests/create-declaration-request)
* [Confluence spec](https://edenlab.atlassian.net/wiki/display/EH/IL.Create+declaration+request)

### Trivia

* all actions that need to be taken specifically on IL are marked with bold.

### Configure gateway

  - [ ] expose `create declaration` public API endpoint,
  - [ ] add proxy plugin to gateway, proxying all POST requests to `api-svc.il`,
  - [ ] add acl plugin to gateway, with `declaration_request:write` scope required for `POST` (**_authorize user_**),
  - [ ] add auth plugin to gateway, with common configuration (**_authorize user_**),
  - [ ] add validation plugin to gateway, with JSON Schema set to schema from confluence (**_validate request_**).

### Get global parameters

  - [x] implement `get global parameters` microservice:
    - [x] implement on DB level,
    - [x] implement an HTTP endpoint,
  - [x] ensure that `get global parameters` is deployed & properly configured in cluster,
    - [x] the service is deployed in cluster with name: **`api-svc.prm`**
    - [x] the service & required enpoint are working. To test it, call from a pod in cluster:
      ```
      curl http://api-svc.prm/api/global_parameters
      ```
      Response example:
      ```json
      {
        "meta": {
          "url": "http://api-svc.prm/api/global_parameters",
          "type": "object",
          "request_id": "ikff7hcf0hhto5c06irl9i976kc3s41m",
          "code": 200
        },
        "data": {
          "verification_request_expiration": "30",
          "employ_request_expiration": "30",
          "declaration_term": "30",
          "declaration_request_expiration": "30",
          "billing_date": "2",
          "adult_age": "18",
          "type": "global_parameter"
        }
      }
      ```
  - [ ] ensure parameters initially exist in DB:,
    - [x] parameters:

      | Parameter                       | Value  |
      | ------------------------------- | ------:|
      | declaration_term                | 30     |
      | declaration_request_expiration  | 30     |
      | employ_request_expiration       | 30     |
      | employ_request_expiration       | 30     |
      | verification_request_expiration | 30     |
      | adult_age                       | 18     |
      | billing_date                    | 2      |

    - [x] ehealth-dev cluster: put parameters into DB,
    - [ ] ehealth-demo cluster: put parameters into DB @DPashchenko ,
  - [x] **call `get global parameters` endpoint to fetch all parameters**:
    ```
    curl http://api-svc.prm/api/global_parameters
    ```

### Validate doctor

  - [x] implement `get employe details` microservice:
    - [x] implement on DB level,
    - [x] implement an HTTP endpoint,
  - [x] ensure that `get employe details` is deployed & properly configured in cluster,
    - [x] the service is deployed in cluster with name: **`api-svc.prm`**
    - [x] the service & required enpoint are working. To test it, call from a pod in cluster:
      ```
      curl http://api-svc.prm/api/employees/b362da7d-4c46-44c4-8df9-2766187bdb1d
      ```
  - [x] **call `get employee details` endpoint**:
      ```
      curl http://api-svc.prm/api/employees/:id
      ```
  - [x] **calculate patient age**,
  - [x] **verify that doctor speciality meets patient age**:
    - [x] on success – proceed,
    - [x] on error – return error via HTTP:
      - [x] response code: 422 (unprocessable entity),
      - [x] response body:
        ```json
        {
          "error": "Doctor speciality does not meet the patient's age requirement."
        }
        ```

### Validate patient phone number

  - [x] implement `validate phone number` microservice:
    - [x] implement on DB level,
    - [x] implement an HTTP endpoint,
  - [x] ensure that `validate phone number` is deployed & properly configured in cluster,
    - [x] the service is deployed in cluster with name: **`api-svc.verification`**
    - [x] is the service fully operational? can we validate a test phone number right now?
  - [x] **call `validate phone number` endpoint**.
    - [x] on success – proceed,
    - [x] on error – return error via HTTP:
        - [x] response code: 422 (unprocessable entity),
        - [x] response body:
          ```json
          {
            "error": "The phone number is not verified."
          }
          ```

### Place new declaration request

  - [x] should we update `approved`? @DPashchenko
  - [x] **update existing pending declaration requests as inactive**:
    ```sql
    UPDATE declaration_requests
       SET status = 'CANCELLED'
     WHERE data #>> '{person, tax_id}'  = TAX_ID
       AND data #>> '{employee_id}'     = EMPLOYEE_ID
       AND data #>> '{legal_entity_id}' = LEGAL_ENTITY_ID
       AND status IN ('NEW', 'APPROVED');
    ```
  - [x] **save new declaration request to IL DB**.

### Search MPI

  - [x] implement `search MPI` microservice:
    - [x] implement on DB level,
    - [x] implement an HTTP endpoint,
  - [x] ensure that `search MPI` is deployed & properly configured in cluster,
    - [x] the service is deployed in cluster with name: **`api-svc.mpi`**
    - [x] the service & required enpoint are working. To test it, call from a pod in cluster:
      ```
      curl http://api-svc.mpi/persons?first_name=Олена&last_name=Пчілка&birth_date=1991-08-19%2000:00:00&tax_id=3126509816&phone_number=%2B380508887700
      ```
  - [ ] ensure `search MPI` records are ordered from newest to oldest,
  - [x] **call `search MPI` endpoint to find persons**,
      ```
      curl http://api-svc.mpi/persons?first_name=???&last_name=???&birth_date=???&tax_id=???&phone_number=???
      ```
  - [x] **take first person from the list**.

### Determine auth method for MPI

  - [ ] ensure the following variables are set on `api-svc.il` container:
    * `GNDF_CLIENT_ID`,
    * `GNDF_CLIENT_SECRET`,
    * `GNDF_APPLICATION_ID`,
    * `GNDF_TABLE_ID` (defaults `58f62b96e79e8521f51b5754`),
    * `GDNF_ENDPOINT` (defaults to `https://api.gndf.io`).
  - [x] **if MPI was found during `Search MPI`, update `declaration_request.authentication_method_current`**:
      ```jsonb
      {
        "authentication_method": SearchMPI.Response.$.data.authentication_method.type,
        "authentication_number": SearchMPI.Response.$.data.authentication_method.number
      }
      ```
  - [x] **if MPI was not found during `Search MPI`, send the following POST request to Gandalf**:
      ```sh
      curl --user GNDF_CLIENT_ID:GNDF_CLIENT_SECRET \
           --header 'X-Application: GNDF_APPLICATION_ID'  \
           --data '{"phone_availability": {value}, "preferable_auth_method": {value}}' \
           GDNF_ENDPOINT/api/v1/tables/GNDF_TABLE_ID/decisions
      ```
      and **update `declaration_request.authentication_method_current`**:
      ```jsonb
      {
        "authentication_method": GandalfResponse.$.data.final_decision,
        "authentication_number": declaration_request.data.authentication_method.number
      }
      ```

### Generate printout form

  - [x] ensure `man template rendering service` is deployed & properly configured in cluster,
    - [x] the service is deployed in cluster with name: **`api-svc.man`**
    - [x] the service & required enpoint are working. To test it, call from a pod in cluster:
      ```sh
      curl --request POST \
           --header 'Accept: text/html' \
           --header 'Content-Type: application/json' \
           http://api-svc.man/templates/34/actions/render
      ```
  - [ ] ensure the following variable is set on `api-svc.il` container:
    * `MAN_ENDPOINT` (defaults to `http://api-svc.man`),
    * `MAN_TEMPLATE_ID`.
  - [ ] **call `man template rendering service` endpoint**,
      ```sh
      curl --request POST \
           --header 'Accept: text/html' \
           --header 'Content-Type: application/json' \
           MAN_ENDPOINT/templates/MAN_TEMPLATE_ID/actions/render
      ```
  - [ ] **update declaration request with printout form content**:

### Generate upload URL

  - [x] ensure that `Media Content Storage service` is deployed & properly configured in cluster,
    - [x] the service is deployed in cluster with name: **`api-svc.ael`**
    - [x] the service & required enpoint are working. To test it, call from a pod in cluster:
      ```sh
      curl --request POST \
           --header 'Content-Type: application/json' \
           --header 'location: http://storage.googleapis.com/declaration-226eeacc-29a0-11e7-93ae-92361f002671/passport.jpeg?GoogleAccessId=1234567890123@developer.gserviceaccount.com&Expires=1331155464&Signature=BClz9e4UA2MRRDX62TPd8sNpUCxVsqUDG3YGPWvPcwN%2BmWBPqwgUYcOSszCPlgWREeF7oPGowkeKk7J4WApzkzxERdOQmAdrvshKSzUHg8Jqp1lw9tbiJfE2ExdOOIoJVmGLoDeAGnfzCd4fTsWcLbal9sFpqXsQI8IQi1493mw%3D' \
           --data '{
                     "secret": {
                       "action": "PUT",
                       "bucket": "declaration_request_dev",
                       "resource_id": "declaration-226eeacc-29a0-11e7-93ae-92361f002671",
                       "resource_name": "passport.jpeg"
                     }
                   }' \
           AEL_ENDPOINT/media_content_storage_secrets
      ```
  - [ ] ensure the following variable is set on `api-svc.il` container:
    * `DECLARATION_REQUEST_OFFLINE_DOCUMENTS` (list; defaults to `["Passport", "SSN"]`),
    * `AEL_STORAGE_BUCKET` (defaults to `declaration_request_dev`),
    * `AEL_ENDPOINT` (defaults to `api-svc.ael`).
  - [ ] **for each document in `DECLARATION_REQUEST_OFFLINE_DOCUMENTS`**:,
    - [ ] **call `Media Content Storage service` to generate `FILE_NAME`**,
      - [ ] exactly which URI path to call? any parameters needed? @DPashchenko
        ```
        http://{AEL_ENDPOINT}/media_content_storage_secrets
        ```
  - [ ] **update declaration request** using all documents from `DECLARATION_REQUEST_OFFLINE_DOCUMENTS`:
    ```json
    {
       "documents":[
          {
             "type": "PASSPORT",
             "URL": "https://google.com.ua"
          }
       ]
    }
    ```

### Generate verification code
  - [ ] implement `OTP service` microservice:
    - [ ] implement on DB level,
    - [ ] implement an HTTP endpoint,
  - [ ] ensure that `OTP service` is deployed & properly configured in cluster @DPashchenko,
    - [ ] what name this service has in cluster?
    - [ ] is the service fully operational? can we make a test call to send an SMS with OTP right now?
  - [ ] call `OTP service` to generate verification code
    - [ ] should we update declaration request to reflect the fact the we generated & sent OTP SMS? if yes, how exactly declaration request structure should be updated? @DPashchenko

### Finalize
Respond with:
  - [ ] response code: 201 (created),
  - [ ] response body.

### TO DO
  - [ ] Add declaration_enddate logic (calculated by age if <18 or declaration_expiration_term)

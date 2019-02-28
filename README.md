# eHealth

[![Build Status](https://ci.asclepius.com.ua/buildStatus/icon?job=ehealth.api/develop)](https://ci.asclepius.com.ua/job/ehealth.api/develop) [![Coverage Status](https://coveralls.io/repos/github/edenlabllc/ehealth.api/badge.svg?branch=master)](https://coveralls.io/github/edenlabllc/ehealth.api?branch=master)

Index page for projects that related to Ukrainian Health Services government institution.

## What it is about - WIP
....
## Objectives
* Design and Develop patient's registry (Master Patient Index) as an independant service
* Design and Develop registry for Medical Service Providers (MSP), MSP Divisions, 1st echelon Doctors (PRM)
* Design and Develop registry for contracts (Declarations) between MSP, 1st echelon Doctors and Patients (OpsDB)
* Automation of MSP, Doctors, Patients, Declarations registration processes accessible via API (REST)
* Provision of data consistency, deduplication and security mechanisms incl. Implementation of Digital Signature
* Design and Develop E-Health Billing process (Capitation report)
* Design and Develop E-Health administration tools for National Health Service
* Implementation of authentication and authorization including:
  * Authorization of MSP by Patient using SMS OTP
  * Offline patient identification
* OAuth 2.0 authorization for E-Health API
* Personal data protection according to Ukraine and EU regulations

## Documentation

- [Business prcesses and specifications](https://edenlab.atlassian.net/wiki/spaces/EH/overview)
- [Production API documentation](https://ehealthmisapi1.docs.apiary.io/)
- [Documentation of API that is under design/development. NOT STABLE](http://docs.uaehealthapi.apiary.io/#reference/public.-medical-service-provider-integration-layer)
- [Architecture](https://docs.google.com/document/d/1oS1FiDJwOMBkR4wLbO51qcS8mO0LaBdXl7TQhk71OWM/edit) - WIP

## Installation

You can use official Docker container to deploy this service, it can be found on [edenlabllc/ehealth](https://hub.docker.com/r/edenlabllc/ehealth/) Docker Hub.

### Dependencies

- PostgreSQL 9.6 is used as storage back-end.
- Elixir 1.8+
- Erlang/OTP 20.0.4

## Configuration

See [ENVIRONMENT.md](docs/ENVIRONMENT.md).

## Contributing
To contribute to eHealth please see [CONTRIBUTING](docs/CONTRIBUTING.md)

## License

See [LICENSE.md](LICENSE.md).

## Legal-WIP

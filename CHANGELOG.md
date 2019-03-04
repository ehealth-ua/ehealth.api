# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

## [0.1.0](https://github.com/edenlabllc/ehealth.api/compare/0.1.0...0.1.0) (2019-1-23)


### Bug Fixes:

* phone -> phone_number (according to schema)

<!-- changelog -->

## [8.12.0](https://github.com/edenlabllc/ehealth.api/compare/8.11.0...8.12.0) (2019-3-4)




### Features:

* Reimbursement registry 2019 (#4233)

* added new value to dictionary for service request categories (#4336)

* graphql: add `updateProgramMedication` mutation (#4334)

* run BDD tests for GraphQL application (#4332)

* validate name length for Medical Program (#4333)

* added LE filter by addresses.settlement_id and addresses.type (#4331)

* graphql: add query fields for `Medication` (#4321)

* medical program deactivate mutation (#4320)

* medical program create mutation (#4319)

* graphql: add program medication list and get by id (#4316)

* add death_date validation on person registers process (#4313)

* merge persons links (#4310)

* MSP+Pharmacy (#4285)

* separate sms configuration for reimbursment endpoints (#4288)

* graphql: add contracts/contract requests filtering by like on contractor LE name and edrpou (#4294)

* use ehealth_logger (#4286)

* graphql: implement create program medication mutation (#4290)

* add price fields for ProgramMedication (#4283)

* add daily_dosage field to medications (#4279)

* Switch to kaffe#3817 (#4260)

* graphql: add medication types (#4272)

* mpi rpc  get persons by ids (#4263)

* move cron jobs (#4135)

* add sort by unzr for person (#4264)

* graphql: add `Settlement`, `District` and `Region` types

* graphql: add ability to search persons by any document type (#4216)

* add jenkinsfile (#4212)

* added registers and register entries to fraud db (#4201)

* added reason and reason description to declarations to fraud db (#4204)

* graphql: add error formatting helper and middleware (#3995)

* graphql: Add UUID and ObjectID scalars (#4170)

* graphql: add expirationDate field to person schema (#4158)

* add death_date to registers; add MPI_ID type (#4155)

* graphql: add `email`, `emergencyContact` and `confidantPersons` fields to `Person` type (#4150)

* graphql: resolve canAssignNew field on mergeRequests (#4142)

* graphql: add `assignMergeCandidate` mutation

* implement merge_request list and get_by_id (#4138)

* Change the list of fields of patient data (medication request / dispense) (#4129)

* licence and accreditation information of MSP added to a prescription (#4120)

### Bug Fixes:

* graphql: rpc dataloader skips nil items (#4353)

* graphql: allow partial update for program medication reimbursement field

* Added config param for MSP_PHARMACY division types (#4330)

* add values to eHealth ucum units #168 (#4342)

* graphql: fix medication filter (#4340)

* graphql: fix program medication prices (#4335)

* graphql: cast program medication price fields to float (#4329)

* graphql: return DateTime in Contract/Contract Request types

* render only active divisions on contract requests show endpoint (#4325)

* add price fields to medication_request qualify response (#4322)

* kaffe producer (#4318)

* cleanup ProgramMedication reimbursement field (#4296)

* remove explicit name from object_id scalar (#4287)

* search persons of age 14 (#4278)

* graphql: fix typo on division type (#4265)

* added migration to deactivate dismissed employee declarations (#4254)

* graphql: Read contract requests from read repo (#4249)

* generate documents links (#4250)

* graphql: fix empty pageInfo response (#4227)

* graphql: return proper error codes on merge candidate assign

* graphql: add consumer_id to check user role (#4169)

* dictionaries: new dictionaries-confidant person type and tax_id (#4168)

* reject medication request json schema fixed (#4159)

* properly resolve Person fields originating from JSON columns (#4161)

* kafka topics migration (#4149)

* terminate reimbursement contract (#4157)

* timeout infinity on declaration_requests migration (#4154)

* about_myself length (#4153)

* removed struct matching from mpi search (#4147)

* bump alpine (#4128)

* Replace mpi rpc module (#4119)

## [8.11.0](https://github.com/edenlabllc/ehealth.api/compare/8.10.0...8.11.0) (2019-1-23)




## [8.10.0](https://github.com/edenlabllc/ehealth.api/compare/8.9.2...8.10.0) (2019-1-23)




### Features:

* add CHANGELOG.md

### Bug Fixes:

* version tag
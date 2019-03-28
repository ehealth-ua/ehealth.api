# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [8.13.2](https://github.com/edenlabllc/ehealth.api/compare/8.13.1...8.13.2) (2019-3-28)




### Bug Fixes:

* topologies (#4596)

* create dispense without a program (#4588)

## [8.13.1](https://github.com/edenlabllc/ehealth.api/compare/8.13.1...8.13.1) (2019-3-27)




### Features:

* graphql: add `edr_verified` to LegalEntity; `dlsVerified`, `dlsId` to Division (#4585)

* dispense dls status verify feature flag (#4578)

* support 0000 code (#4580)

* allow to disable le edr verification (#4573)

* process edr registry (#4569)

* validation division dls status on dispense create, process (#4562)

* ehealth: (#4563)

* dls registry table (#4550)

* Legal entity add edr validation#4412 (#4535)

* render edr_verified (#4551)

* dls fields added to divisions (#4542)

* graphql: change RPC from MPI to ManualMerger (#4538)

* graphql: add additional fields and filters to `Employee`, `Party` and `Division` types

* add new app edr to jenkins (#4533)

* Edr validation#4422 (#4530)

* add merge persons and merge candidates to fraud (#4493)

* add employee position to contracts printout template (#4477)

* graphql: create INNM mutation (#4470)

* graphql: implement create immnDosage (#4462)

* declaration_request drop indexes migration added (#4072)

* INNM create mutation (#4443)

* updated taskafka dep (#4456)

* graphql: add `deactivateMedication` mutation

* graphql: add `deactivateInnmDosage` mutation

* *: split review text for capitation and reimbursement contract requests

* add query fields for `INNM`

* Pharmacist registration - updated dictionary, improved schema (#4428)

* added request_in in extensions field in response (#4426)

* graphql: add filtering by `insertedAt` on `CapitationContractRequest` and `ReimbursementContractRequest`

* graphql: replace `DateInclusion` operator with `RangeInclusion` with support for `DateRange` and `TimestampRange` as filter values

* *: add `TimestampRange` Ecto type and corresponding `DatetimeInterval` scalar type

* graphql: implement suspend contracts (#4414)

* employee status_reason updating on le jobs (#4410)

* graphql: filter LE by type inclusion in list (#4409)

* add contract status reason to dictionary (#4404)

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

* create dispense without a program (#4588)

* person name pattern on declaration request v2 (#4572)

* one of issue on medication request schema (#4567)

* Dispense schema (#4534)

* ael logging (#4564)

* *: validation contractor related legal entity returns conflict (#4561)

* update legal entity on edr verification (#4540)

* graphql: respond with validation message for invalid pagination request (#4541)

* graphql: fix medication form types fail on unknown type (#4537)

* External_id is optional on dispense (#4525)

* graphql: fix innm dosage resolving (#4526)

* graphql: fix innm dosage order by

* ehealth: validate division belongs to contract on dispense (#4508)

* logging man render template (#4506)

* logging man tempate render (#4502)

* microservice_base logs (#4476)

* graphql: fix rpc dataloader (#4473)

* graphql: correct select criteria for legal entity owner

* graphql: fix innm_dosages filter (#4469)

* changed job consumers configs to process batches (#4460)

* add missing program medication activeness check on program medication reimbursement update

* graphql: implement immnDosage list and details (#4454)

* create pharmacist (#4448)

* graphql: fix innm_dosage resolving (#4440)

* graphql: add status_reason to terminate contract (#4441)

* medication request get (#4436)

* return rest of datetime fields with timezones

* Payment_id in process medication dispense set to optional (#4432)

* refactor(*): return timestamps with timezones (#4427)

* graphql: add status to person filter (#4369)

* exclude test env from medication migration data (#4393)

* change consent_text for reimbursement contract request create #176 (#4338)

* medication_request_request invalid request dates fixed (#4368)

* phoenix logger instruments (#4367)

* accreditation render (#4363)

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

* phone -> phone_number (according to schema)

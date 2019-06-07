# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [9.2.0](https://github.com/edenlabllc/ehealth.api/compare/9.1.0...9.2.0) (2019-6-7)




### Features:

* core: added `medical_program.type` field in Fraud DB (#5217)

* Rpc ehealth (#5210)

* graphql: added `updateService` mutation (#5208)

* graphql: add `deleteServiceFromGroup` mutation (#5137)

### Bug Fixes:

* employee_by_id rpc call (#5214)

* filter urgent declaration request, don't set nhs_unverified (#5212)

* core: removed unused `services.parent_id` field. Removed unused variables (#5197)

## [9.1.0](https://github.com/edenlabllc/ehealth.api/compare/9.0.0...9.1.0) (2019-6-6)




### Features:

* graphql: change `services groups` to `service inclusion` (#5202)

* graphql: added serviceGroups field to Service query (#5181)

* graphql: add `addServiceToGroup` mutation (#5136)

* Migrate accreditation (#5175)

* graphql: add `deactivateServiceGroup` mutation (#5133)

* graphql: add `createServiceGroup` mutation (#5132)

### Bug Fixes:

* graphql: do not count length for response with nil from Dataloader (#5185)

* correct `ChangeServiceInclusionsPkey` migration (#5194)

* New pattern for person documents (#5178)

* Allow primary_care to work with capitation contracts (#5179)

* delete pattern of service name (#5176)

* graphql: added EDRData registration address field (#5174)

## [9.0.0](https://github.com/edenlabllc/ehealth.api/compare/8.14.1...9.0.0) (2019-6-4)
### Breaking Changes:

* Create legal entity v1 (#4997)



### Features:

* Edr synchronization#5103 (#5169)

* legal entity validations (#5165)

* graphql: added EDR data to LegalEntity schema (#5163)

* suspend contract and legal entity type cron job created (#5155)

* graphql: add `deactivateService` mutation (#5130)

* graphql: add `createService` mutation (#5129)

* graphql: add `ServiceGroup` queries (#5131)

* graphql: add `Service` queries (#5126)

* Terminate contract requests (#5151)

* terminate contract requests on edr validations (#5142)

* sign contract request nhs verified validation (#5146)

* graphql: added tasks for deactivation and merge legal entities jobs (#5105)

* update deactivate le (#5135)

* add legal entities types validation from config for contract request create (#5124)

* medication request legal_entity validations (#5123)

* employee request validations (#5101)

* declaration request create validations (#5099)

* division validations (#5098)

* le v2 render (#5075)

* Ael options (#5063)

* core: created table `program_services` in PRM (#5061)

* replace rest call with rpc in digital signature (#4992)

* replace rest call with rpc in media_storage (ael) (#4987)

* add contractor legal entity status and NHS verification validations to contract request processes

* replace rest calls with rpc on man and otp verification services (#4952)

* set unverified timestamp on legal entity creation

* add unverified timestamp setting to verify legal entity by NHS process

* add `updateLegalEntityStatus` mutation

### Bug Fixes:

* git ops (#5171)

* graphql: set LE owner_property_type nullable (#5170)

* le licenses validations (#5168)

* declaration request cleaner (#5164)

* graphql: successfully deactivate service when service is a participant of active service group (#5160)

* transform badrpc error to internal server error (#5161)

* le v2 contract request terminator fixes (#5159)

* multiple fixes to le v2 (#5158)

* response for get contracts list changed according to apiary (#5154)

* hide_phone_number func fixed (#5153)

* le v2 (#5152)

* correct handling ds.api errors (base64, json format etc) (#5147)

* le v2 (#5143)

* le v2 validations (#5139)

* edr validations consumer (#5134)

* uaddresses rpc name (#5127)

* otp send sms func fixed (#5125)

* match error on convert types (#5107)

* le v2 license validation (#5104)

* Le v2 render (#5102)

* scheduler (#5097)

* correct handling errors from DS rpc calls (#5084)

* scheduler datetime type (#5086)

* create le v2 response (#5083)

* convert not a base64 string to 4xx error on sign MRR (#5049)

* add missed config (#5082)

* change scheduler gen server to simple jobs (#5078)

* declaration request v2 create fix (#5074)

* le v2 fixes (#5069)

* Create legal entity v1 (#5064)

* render le on le v1 create/update (#5062)

* Create legal entity v2 (#5054)

* le v2 create,update (#5048)

* Create legal entity v1 (#5044)

* search for mrr list optimized (search fields added) (#5019)

* core: fixed contract request creation - set id for contract_request from params (#5020)

* edr verified flag on le create/update (#5017)

* when edr addresss is null (#5015)

* man render template with string keys (#5013)

* hide division DLS verified validation on contract request processes behind feature flag

* add unique index for contract contract_number verified status (#4996)

* ehealth: fix postmark client flows to internal server error (#4983)

* get innm dosage list pagination fixed (#4979)

## [8.14.1](https://github.com/edenlabllc/ehealth.api/compare/8.14.0...8.14.1) (2019-5-14)




### Bug Fixes:

* ehealth: fix postmark client flows to internal server error (#4983)

* get innm dosage list pagination fixed (#4979)

## [8.14.0](https://github.com/edenlabllc/ehealth.api/compare/8.13.2...8.14.0) (2019-5-13)




### Features:

* ehealth: add ability to search dictionaries by names; do not return big dictionaries (#4971)

* graphql: added filter by status for LegalEntity (#4964)

* ehealth: added jobs in EHealth API application for Jabba rpc (#4963)

* graphql: removed result from response for jobs (#4961)

### Bug Fixes:

* get innm dosage list fixed (#4968)

* graphql: fixed cursor order (#4966)

* ehealth: use person id as atom key (#4954)

* sign declaration request (#4958)

* graphql: fixed search by jsonb fields in Jabba (#4951)

## [8.13.2](https://github.com/edenlabllc/ehealth.api/compare/8.13.2...8.13.2) (2019-5-9)




### Features:

* extend validations for create LE merge job process, set REORGANIZED status for merged LE

* ecto_paginator (#4922)

* ecto 3 (#4904)

* graphql: add `deactivateEmployee` mutation

* *: refactor employee deactivation logic, add check on belongingness to acting client's legal entity

* save sign content on employee request create process (#4859)

* added jabba (#4823)

* process medication dispense in transaction (#4851)

* contractor_legal_entity name changed in contract sample (printout content) (#4845)

* get medication requests rpc (#4831)

* added function to check if service belongs to group to Rpc module (#4824)

* mpi search  rpc only, #6019 (#4771)

* added function to get service/group by id to Rpc module (#4800)

* medication request innm_dosage validation changed to innm for the same period (#4794)

* graphql: add atc_code to medication filter (#4795)

* validate contractor divisions dls on create, sign, approve (#4784)

* Discount amount validation (#4770)

* owner pisition dictionary supplemented (#4745)

* graphql: implement employee requests list and details (#4737)

* Custom dictionaries#4624 (#4727)

* graphql: move consent text for contract requests to own dictionary

* graphql: add `createContractRequest` mutation

* core: add create contract request from contract logic

* medication_qty validation on medication dispense (qty equality) (#4688)

* graphql: implement create employee request (#4679)

* graphql: add `toCreateRequestContent` field to contract types (#4623)

* push event to event manager via kafka (#4598)

* changed/deleted some migrations, added new fields to fraud db (#4603)

* graphql: add employee and party document fields (#4592)

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

* improve declaration requests terminator (#4947)

* mrr validate existing medication requests fixed (created_at validation removed) (#4948)

* graphql: copy contract request files on create from contract proccess (#4928)

* le v1 mis only header (#4930)

* mrr validate existing medication requests fixed (started_at validation added) (#4927)

* create le api key (#4926)

* medication request request existing medication requests validation fixed (#4920)

* set data on contract request create from contract (#4901)

* update persons data via rpc on sign declaration process (#4893)

* do not match on id (#4889)

* add missed fields from contract request changesets (#4886)

* add MSP_PHARMACY type on client type validation (#4879)

* handle ael match error (#4870)

* list medication requests rpc (#4863)

* (graphql) search person with renamed rpc function (#4862)

* medication_request is_active validation fixed (period validation removed) (#4857)

* edr_verified field is updated on create or update legal entity (#4854)

* jabba rpc config (#4853)

* core: always check existence of contract request additional documents when generating get links

* core: save signed content to storage on contract request create

* medication request requests period validation improved (#4839)

* edr validations (#4838)

* dls, edr (#4821)

* tests (#4812)

* scheduler swarm (#4804)

* make second name optional for employee in dispense (#4801)

* graphql: don't return overdue contract employees in `toCreateRequestContent` field of contract types

* graphql: fix employee assignment with `createContractRequest` mutation

* deactivate owners roles (#4785)

* Second name optional in json schema (#4788)

* medication dispense create validation fix (contract that is valid in current period) (#4779)

* drugs search fixed (simultaneous search by medication_code_atc and medical_program_id) (#4778)

* *: use the same format for validation errors (#4768)

* services list (#4763)

* graphql: put external contractors to `toCreateRequestContent` only when contract have positive `external_contractor_flag`

* drop division foreign key constraint in dls_registry (#4751)

* graphql: remove `EmployeeType` enum since it is present in the dictionary

* get contract request for msp_pharmacy (#4719)

* *: use proper array path references in create contract request validations

* edr worker config (#4710)

* use separate rpc worker for edr (#4708)

* deactivate owners on employee request approve (#4706)

* get reason (#4703)

* dispense rounding (#4700)

* dispense program validations (#4690)

* reimbursement amount rounding (#4681)

* return 422 on duplicate sign medication request request (#4666)

* medication dispense payment amount greater or equal zero (#4664)

* fix for position p22 (#4658)

* private entrepreneur legal entities position field render fixed (#4657)

* change log level (#4653)

* fraud db columns (#4651)

* contract request printout form fix: contractor_legal_entity position (#4632)

* declaration request create_declatation_req_data_index fixed (#4615)

* do not validate le public_name and short_name for medication requests (#4634)

* pablic_name and short_name for dispense process can be null (#4627)

* make optional pablic_name and short_name for dispense process (#4622)

* don't paginate persons search where it's not needed (#4616)

* graphql: fix party email type (#4614)

* add unique contract request id constraint to contracts (#4611)

* graphql: rename RPC module (#4610)

* handle invalid json error from ds on create legal entity (#4609)

* *: fix dictionary typo on contract request (#4599)

* topologies (#4596)

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

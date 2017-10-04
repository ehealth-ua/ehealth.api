-----------------
-- delete FROM _temp_reestr
-- delete FROM _temp_form
-- delete FROM _temp_innms
-- delete FROM _temp_medications
-- delete FROM _temp_reestr
-- DELETE FROM _temp_ingredients
create table "_temp_reestr"
(
	status varchar(10),
	id integer,
	innm_name_original varchar(255),
	brand_name varchar(255),
	form varchar(255),
	dosage_value numeric,
	package_qty numeric,
	atc varchar(255),
	manufacturer varchar(255),
	lic_num varchar(255),
	lic_exp_at varchar(255),
	amount_11 real,
	amount_12 real,
	amount_13 real,
	amount_14 real,
	amount_reimbursement real,
	amount_16 real,
	package_min_qty numeric,
	country varchar(10),
	manufacturer_jsonb varchar(255)
)
;
------------------------------
create table _temp_innms
(
	id uuid not null
		constraint innms_pkey
			primary key,
	sctid varchar(255),
	name varchar(255) not null,
	name_original varchar(255) not null,
	is_active boolean default false not null,
	inserted_by uuid not null,
	updated_by uuid not null,
	inserted_at timestamp not null,
	updated_at timestamp not null
)
;
------------------------------
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Аміодарон', 'Amiodarone', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Амлодипін', 'Amlodipine', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Атенолол', 'Atenolol', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Беклометазон', 'Beclometasone', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Бісопролол', 'Bisoprolol', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Будесонід', 'Budesonide', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Верапаміл', 'Verapamil', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Гідрохлор-тіазид', 'Hydrochlorothiazide', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Гліклазид', 'Gliclazide', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Дигоксин', 'Digoxin', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Еналаприл', 'Enalapril', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Ізосорбіду динітрат', 'Isosorbide dinitrate', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Карведилол', 'Carvedilol', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Клопідогрель', 'Clopidogrel', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Метопролол', 'Metoprolol', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Метформін', 'Metformin', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Нітрогліцерин', 'Nitroglycerin', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Сальбутамол', 'Salbutamol', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Симвастатин', 'Simvastatin', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Спіронолактон', 'Spironolactone', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());
insert into _temp_innms (id,sctid,name,name_original,is_active,inserted_by,inserted_at,updated_by,updated_at) values (uuid_generate_v4(), NULL,'Фуросемід', 'Furosemide', TRUE ,'4261eacf-8008-4e62-899f-de1e2f7065f0',now(),'4261eacf-8008-4e62-899f-de1e2f7065f0',now());--------------------------------


create table _temp_form
(
	name     VARCHAR(255) NOT NULL,
	name_key VARCHAR(255) NOT NULL,
	dosage_num_unit VARCHAR(255) NOT NULL,
	dosage_denum_unit VARCHAR(255) NOT NULL,
	container_num_unit VARCHAR(255) NOT NULL,
	container_denum_unit VARCHAR(255) NOT NULL
);


--------------------------------------
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('аерозоль для інгаляцій','AEROSOL_FOR_INHALATION_IS_DOSED','MKG','DOSE','DOSE','AEROSOL')
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('аерозоль для інгаляцій, дозований','AEROSOL_FOR_INHALATION_DOSED','MKG','DOSE','DOSE','AEROSOL')
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('інгаляція під тиском','PRESSURISED_INHALATION','MKG','DOSE','DOSE','AEROSOL')
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('Порошок для інгаляцій','INHALATION_POWDER','MKG','DOSE','DOSE','AEROSOL')
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('Суспензія для розпилення','NEBULISER_SUSPENSION','MG','ML','ML','CONTAINER')
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('таблетки','TABLET','MG','PILL','PILL','PILL')
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('таблетки з модифікованим вивільненням','MODIFIED-RELEASE_TABLET','MG','PILL','PILL','PILL')
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('таблетки сублінгвальні','SUBLINGVAL_TABLET','MG','PILL','PILL','PILL')
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('таблетки, вкриті оболонкою','COATED_TABLET','MG','PILL','PILL','PILL')
INSERT into _temp_form (name, name_key,dosage_num_unit,dosage_denum_unit,container_num_unit,container_denum_unit) values('таблетки, вкриті плівковою оболонкою','FILM_COATED_TABLET','MG','PILL','PILL','PILL')
---------------------------------------
create table _temp_medications
(
	ext_id INTEGER,
	id uuid not null
		constraint _temp_medications_pkey
			primary key,
	name varchar(255) not null,
	type varchar(255) not null,
	manufacturer jsonb,
	code_atc varchar(255),
	is_active boolean default false not null,
	form varchar(255),
	container jsonb,
	package_qty integer,
	package_min_qty integer,
	certificate varchar(255),
	certificate_expired_at date,
	inserted_by uuid not null,
	updated_by uuid not null,
	inserted_at timestamp not null,
	updated_at timestamp not null
)
;
----------------------------------

-- insert medications=brand
-- delete FROM _temp_medications
INSERT INTO _temp_medications (ext_id, id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at)
SELECT
	tr.id as ext_id,
	uuid_generate_v4() AS id,
	tr.brand_name AS name,
	'BRAND' AS type,
	tr.manufacturer_jsonb::jsonb as manufacturer,
	tr.atc AS code_atc,
	TRUE AS is_active,
	tf.name_key AS form,
	('{"numerator_unit": "' || tf.container_num_unit || '", "numerator_value": 1, "denumerator_unit": "' || tf.container_denum_unit || '", "denumerator_value": 1}')::jsonb
 				AS container,  -- +++
	tr.package_qty AS package_qty,
	tr.package_min_qty AS package_min_qty,
	tr.lic_num AS certificate,
	to_date(tr.lic_exp_at,'DD.MM.YYYY') AS certificate_expired_at,
	'4261eacf-8008-4e62-899f-de1e2f7065f0' AS inserted_by,
	'4261eacf-8008-4e62-899f-de1e2f7065f0' AS updated_by,
	now() AS inserted_at ,
	now() AS updated_at
FROM _temp_reestr AS tr
	INNER JOIN _temp_form AS tf
		ON tr.form=tf.name

-- insert medications = innm_dosage
INSERT INTO _temp_medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at)
SELECT
	uuid_generate_v4() AS id,
	sq.innm_dosage_name,
	'INNM_DOSAGE' AS type,
	TRUE AS is_active,
	sq.form,
	'4261eacf-8008-4e62-899f-de1e2f7065f0'::uuid AS inserted_by,
	'4261eacf-8008-4e62-899f-de1e2f7065f0'::uuid AS updated_by,
	now() AS inserted_at,
	now() AS updated_at
FROM (
SELECT DISTINCT
	('' || ti.name || ' ' || tr.dosage_value || ' ' || tf.dosage_num_unit || ' ' || tf.name) as innm_dosage_name,
  tf.name_key as form
FROM _temp_reestr AS tr
INNER JOIN _temp_innms AS ti
		ON tr.innm_name_original = ti.name
INNER JOIN _temp_form AS tf
		ON tr.form=tf.name ) AS sq

---------------------------
create table _temp_ingredients
(
	id uuid not null
		constraint _temp_ingredients_pkey
			primary key,
	dosage jsonb not null,
	is_primary boolean default false not null,
	medication_child_id uuid,
	innm_child_id uuid,
	parent_id uuid not null,
	inserted_at timestamp not null,
	updated_at timestamp not null
)
;
-----------------------------
SELECT count(*) from _temp_medications WHERE type='BRAND'

-----------------------------
-- insert ingredients for medications = brands
-- DELETE FROM _temp_ingredients
INSERT INTO _temp_ingredients (id, dosage, is_primary, medication_child_id, innm_child_id, parent_id, inserted_at, updated_at)
SELECT
--	tm_dosage.name,
--	tm_brands.name,
	uuid_generate_v4() AS id,
   ('{"numerator_unit": "' || sq.dosage_num_unit || '", "numerator_value":' || sq.dosage_value || ', "denumerator_unit": "' || sq.dosage_denum_unit || '", "denumerator_value": 1}')::jsonb
 		as dosage,
	TRUE as is_primary,
	tm_dosage.id as medication_child_id,
	NULL as innm_child_id,
	tm_brands.id as parent_id,
	now() AS inserted_at,
	now() AS updated_at
FROM (
SELECT
	tr.id as tr_id,
	('' || ti.name || ' ' || tr.dosage_value || ' ' || tf.dosage_num_unit || ' ' || tf.name) as innm_dosage_name,
  tr.dosage_value,
	ti.name_original as innm,
  tf.name_key as form,
	tf.dosage_num_unit as dosage_num_unit,
	tf.dosage_denum_unit as dosage_denum_unit
FROM _temp_reestr AS tr
LEFT JOIN _temp_innms AS ti
		ON tr.innm_name_original = ti.name
INNER JOIN _temp_form AS tf
		ON tr.form=tf.name ) AS sq
LEFT JOIN _temp_medications AS tm_dosage
		ON tm_dosage.name = sq.innm_dosage_name AND tm_dosage.type = 'INNM_DOSAGE'
LEFT JOIN _temp_medications AS tm_brands
		ON tm_brands.ext_id = sq.tr_id AND tm_brands.type = 'BRAND'

-----------------------------
-- insert ingredients for medications = innm_dosages
-- DELETE FROM _temp_ingredients

INSERT INTO _temp_ingredients (id, dosage, is_primary, medication_child_id, innm_child_id, parent_id, inserted_at, updated_at)
SELECT
	uuid_generate_v4() AS id,
	sq.dosage as dosage,

	TRUE as is_primary,
	NULL as medication_child_id,
	sq.tin_id as innm_child_id,
	tm_dosage_id as parent_id,
	now() AS inserted_at,
	now() AS updated_at

FROM (
	SELECT DISTINCT
		tin.id as tin_id,
		ti.dosage,
		tin.name,
		tm_dosage.name,
		tm_dosage.id as tm_dosage_id
	FROM _temp_medications AS tm_dosage
		INNER JOIN _temp_ingredients ti
			ON ti.medication_child_id = tm_dosage.id
		INNER JOIN _temp_medications AS tm_brands
			ON ti.parent_id = tm_brands.id
		INNER JOIN _temp_reestr AS tr
			ON tm_brands.ext_id = tr.id
		INNER JOIN _temp_innms AS tin
			ON tr.innm_name_original = tin.name
	WHERE tm_dosage.type = 'INNM_DOSAGE'
) AS sq


-----------------------------
-- Move from _temp_tables 2 _real_tables

DELETE FROM ingredients;
delete FROM medications;
delete FROM innms;


INSERT INTO innms(id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at)
	SELECT id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at
	FROM _temp_innms;


INSERT INTO medications(id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at)
	SELECT id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at
	FROM _temp_medications;

INSERT INTO ingredients(id, dosage, is_primary, medication_child_id, innm_child_id, parent_id, inserted_at, updated_at)
	SELECT id, dosage, is_primary, medication_child_id, innm_child_id, parent_id, inserted_at, updated_at
	FROM _temp_ingredients;

------
SELECT t.* FROM public._temp_medications t WHERE name ILIKE '%будесон%' LIMIT 501

SELECT * FROM _temp_ingredients WHERE parent_id IN ('219c3aaf-f60f-4a86-9043-70971d1a4d45', '3df4a8de-2b1f-446d-a5c4-60daea17e012')

SELECT
	uuid_generate_v4() AS id,
	sq.innm_dosage_name,
	'INNM_DOSAGE' AS type,
	TRUE AS is_active,
	sq.form,
	'4261eacf-8008-4e62-899f-de1e2f7065f0'::uuid AS inserted_by,
	'4261eacf-8008-4e62-899f-de1e2f7065f0'::uuid AS updated_by,
	now() AS inserted_at,
	now() AS updated_at
FROM (
SELECT DISTINCT
	('' || ti.name || ' ' || tr.dosage_value || ' ' || tf.dosage_num_unit || ' ' || tf.name) as innm_dosage_name,
  tf.name_key as form
FROM _temp_reestr AS tr
INNER JOIN _temp_innms AS ti
		ON tr.innm_name_original = ti.name
INNER JOIN _temp_form AS tf
		ON tr.form=tf.name
WHERE tr.innm_name_original ILIKE '%будесон%'
		 ) AS sq

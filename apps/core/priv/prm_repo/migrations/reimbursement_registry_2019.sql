DO
$$DECLARE id uuid;
BEGIN
        SELECT mp.id INTO id FROM medical_programs mp WHERE mp.id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO public.medical_programs (id, name, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', ''Доступні ліки'', true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now())';
        END IF;
END$$;


UPDATE program_medications
SET is_active = FALSE ;


UPDATE medications
SET is_active = FALSE ;


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Amiodarone' AND id != (
    SELECT id
    FROM innms
    WHERE name_original = 'Amiodarone'
    AND is_active = TRUE
    LIMIT 1
);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Amlodipine'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Amlodipine'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Atenolol'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Atenolol'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Verapamil'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Verapamil'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Hydrochlorothiazide'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Hydrochlorothiazide'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Spironolactone'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Spironolactone'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Furosemide'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Furosemide'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Digoxin'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Digoxin'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Enalapril'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Enalapril'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Isosorbide dinitrate'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Isosorbide dinitrate'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Carvedilol'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Carvedilol'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Clopidogrel'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Clopidogrel'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Losartan'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Losartan'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Metoprolol'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Metoprolol'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Glyceryl trinitrate'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Glyceryl trinitrate'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Simvastatin'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Simvastatin'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Bisoprolol'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Bisoprolol'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Metformin'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Metformin'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Gliclazide'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Gliclazide'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Glibenclamide'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Glibenclamide'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Beclometasone'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Beclometasone'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Budesonide'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Budesonide'
    AND is_active = TRUE
LIMIT 1);


UPDATE innms
    SET is_active = FALSE
WHERE name_original = 'Salbutamol'
AND id != (SELECT id
FROM innms
WHERE name_original = 'Salbutamol'
    AND is_active = TRUE
LIMIT 1);


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d76e0c7f-3a19-4971-8285-f9172be4097f'', NULL, ''Аміодарон'', ''Amiodarone'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.325500'', ''2019-03-01T09:02:41.325525'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8a732ae7-63f9-443b-87aa-43ccd96fcdb5'', NULL, ''Амлодипін'', ''Amlodipine'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.328505'', ''2019-03-01T09:02:41.328509'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Atenolol';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a538de89-4f78-4258-960c-905e5e4db385'', NULL, ''Атенолол'', ''Atenolol'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.336074'', ''2019-03-01T09:02:41.336078'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Verapamil';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''f9bbd53d-25c0-435f-bcd4-eb8fb5356a71'', NULL, ''Верапаміл'', ''Verapamil'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.336822'', ''2019-03-01T09:02:41.336826'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Hydrochlorothiazide';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b7187281-960d-4cb4-98c0-b91a13013e5c'', NULL, ''Гідрохлортіазид'', ''Hydrochlorothiazide'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.337637'', ''2019-03-01T09:02:41.337641'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Spironolactone';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c1276862-33bc-40fb-9693-667d384add8f'', NULL, ''Спіронолактон'', ''Spironolactone'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.337809'', ''2019-03-01T09:02:41.337814'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Furosemide';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0db640fb-e690-45bb-ad1d-8910f62ebd75'', NULL, ''Фуросемід'', ''Furosemide'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.338712'', ''2019-03-01T09:02:41.338716'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Digoxin';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ccc77859-140f-4203-a4a0-0e14dc61d06a'', NULL, ''Дигоксин'', ''Digoxin'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.339429'', ''2019-03-01T09:02:41.339432'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''089964a7-9342-4221-b478-69d9ace65872'', NULL, ''Еналаприл'', ''Enalapril'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.339884'', ''2019-03-01T09:02:41.339889'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Isosorbide dinitrate';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''2f44a166-ab7a-4772-bbca-ec0677030c16'', NULL, ''Ізосорбіду динітрат'', ''Isosorbide dinitrate'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.343705'', ''2019-03-01T09:02:41.343708'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1433185f-eb39-46bd-a233-078554cf6a43'', NULL, ''Карведилол'', ''Carvedilol'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.343872'', ''2019-03-01T09:02:41.343875'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c03ea616-3edd-49d1-8bcc-bfe413733026'', NULL, ''Клопідогрель'', ''Clopidogrel'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.346729'', ''2019-03-01T09:02:41.346733'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3219a49e-4a68-49bb-a6c8-8de63cf0ab7d'', NULL, ''Лозартан'', ''Losartan'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.351664'', ''2019-03-01T09:02:41.351667'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metoprolol';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a82f497b-b90f-421e-9358-7cdfaf865d66'', NULL, ''Метопролол'', ''Metoprolol'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.354766'', ''2019-03-01T09:02:41.354769'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Glyceryl trinitrate';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''632c5d2b-c621-4d2e-a475-39dd56de50e1'', NULL, ''Нітрогліцерин'', ''Glyceryl trinitrate'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.356112'', ''2019-03-01T09:02:41.356115'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''288684bd-a793-40c6-b337-c9a7b13f6ea5'', NULL, ''Симвастатин'', ''Simvastatin'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.356600'', ''2019-03-01T09:02:41.356603'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8a5dbcca-62fb-47a9-a7a7-e5dbb04c96c6'', NULL, ''Бісопролол'', ''Bisoprolol'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.358851'', ''2019-03-01T09:02:41.358854'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5862da94-88ff-4dff-ba74-d663144ff462'', NULL, ''Метформін'', ''Metformin'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.364930'', ''2019-03-01T09:02:41.364933'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Gliclazide';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c6c99268-6436-4401-a94a-f6a2c36d00dd'', NULL, ''Гліклазид'', ''Gliclazide'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.371926'', ''2019-03-01T09:02:41.371930'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Glibenclamide';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''47b1ee6b-1042-439a-905c-fdd514cd99e0'', NULL, ''Глібенкламід'', ''Glibenclamide'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.373391'', ''2019-03-01T09:02:41.373394'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Beclometasone';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a9c85660-52a5-45a6-a5bd-28f7f037c0b3'', NULL, ''Беклометазон'', ''Beclometasone'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.373935'', ''2019-03-01T09:02:41.373938'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Budesonide';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''bfcbb158-e7ce-4043-bf2c-23e1399dd6c2'', NULL, ''Будесонід'', ''Budesonide'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.374561'', ''2019-03-01T09:02:41.374564'');';
        END IF;
END$$;


DO
$$DECLARE id uuid;
BEGIN
        SELECT i.id INTO id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Salbutamol';
        IF id IS NULL THEN
            EXECUTE 'INSERT INTO innms (id, sctid, name, name_original, is_active, inserted_by, updated_by, inserted_at, updated_at) VALUES (''24f91777-bd39-49df-9ac6-e06179f2bd21'', NULL, ''Сальбутамол'', ''Salbutamol'', True, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''2019-03-01T09:02:41.376019'', ''2019-03-01T09:02:41.376023'');';
        END IF;
END$$;


UPDATE program_medications
SET is_active = FALSE
WHERE medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';


UPDATE medications
SET is_active = FALSE
WHERE id IN (SELECT medication_id FROM program_medications WHERE medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545');


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''3fdce01d-3001-4501-92ae-2059548997bf'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'АРИТМІЛ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/1438/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/1438/02/01', '2019-11-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''365791c0-c7dc-470b-8833-30cd98e07173'', ''АРИТМІЛ'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": "Україна"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/1438/02/01'', ''2019-11-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''9d0f1b1f-6a6d-4ec3-abd2-89a4e5e61d14'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "28.88"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''94456d00-6088-4189-963b-c2dc60453f00'', ''{"type": "FIXED", "reimbursement_amount": "28.88"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''5b48e1fd-8821-4d96-bd0d-56138dcda0fd'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'АМІДАРОН'
    AND m.package_qty = 30
    AND m.certificate = 'UA/4514/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/4514/01/01', '2021-02-09'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6b2b51ec-05c3-4353-a971-daba2d77406b'', ''АМІДАРОН'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/4514/01/01'', ''2021-02-09'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''10f565e9-afb1-40de-91d8-d7df3623f97c'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "43.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d3bc81db-7e8e-49db-a6b9-7c836bf6cdb7'', ''{"type": "FIXED", "reimbursement_amount": "43.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''07b5b0af-de43-4f3a-86e8-c87b8a9f9e75'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'АМІОДАРОН'
    AND m.package_qty = 30
    AND m.certificate = 'UA/8904/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/8904/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''f4e9a1e5-3261-497b-bc4a-e7cccbae1693'', ''АМІОДАРОН'', ''BRAND'', ''{"name": "Приватне акціонерне товариство \"Лекхім-Харків\"", "country": " Україна"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/8904/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ffdc039f-9508-4df5-addf-9d6af0edaa59'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "43.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''62415d21-7996-422f-b023-9832131c0bbd'', ''{"type": "FIXED", "reimbursement_amount": "43.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''82de65e4-5352-435e-8480-5227ac00bb40'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'АМІОДАРОН-ДАРНИЦЯ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/6506/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/6506/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''cbea3510-5196-49df-9600-f71cb097acdb'', ''АМІОДАРОН-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/6506/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''b99da6b4-f406-475a-8643-3fed965a2860'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "43.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b0d0fe78-0066-430d-b63f-fc406412db08'', ''{"type": "FIXED", "reimbursement_amount": "43.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''0892a858-9a94-492e-8981-345d494ff4b6'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'АМІОКОРДИН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/10291/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/10291/01/01', '2019-11-20'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c05b7446-0bee-4c64-a12d-31652009a6d3'', ''АМІОКОРДИН®'', ''BRAND'', ''{"name": "КРКА", "country": " Словенія"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/10291/01/01'', ''2019-11-20'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''83afdb9a-3327-4bf0-be86-7066f97a96d8'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "43.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''008e7cfd-f5a2-4c78-a4fd-83c7f3af803b'', ''{"type": "FIXED", "reimbursement_amount": "43.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''70eb302f-33a4-4919-981c-cc931f13a5a7'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'КАРДІОДАРОН-ЗДОРОВ''Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1713/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/1713/02/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''7eb84f09-d685-42e3-a947-d23e5df2a95e'', ''КАРДІОДАРОН-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1713/02/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''7d779f0f-0009-429b-bf82-5af1dd5f00b7'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "43.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''cb267bcf-8082-4520-872a-0a41a9090e02'', ''{"type": "FIXED", "reimbursement_amount": "43.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''04114b32-ba48-44bc-a760-c87cef2faec0'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'МІОРИТМІЛ®-ДАРНИЦЯ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/6506/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/6506/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e2a84d50-7a1d-4a58-a627-bb39e81bc0fe'', ''МІОРИТМІЛ®-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/6506/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''8cb619e9-c1b5-4106-a4a1-ef81c4a0fa2f'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "43.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b0673475-aaf1-480c-8140-b2aed6edf4c7'', ''{"type": "FIXED", "reimbursement_amount": "43.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''70da72b9-bb61-4e81-b652-7c1de2b2f7bf'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'РОТАРИТМІЛ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/12887/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/12887/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''eeb6bf3a-b76a-40e6-b0c4-290803436e39'', ''РОТАРИТМІЛ'', ''BRAND'', ''{"name": "Ривофарм СА", "country": " Швейцарія"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/12887/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''9fca5066-70fb-42b0-bf67-5577c83efd46'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "43.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''23dc19d6-82a5-4eaa-b69a-d5a0e532af76'', ''{"type": "FIXED", "reimbursement_amount": "43.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c2a2115a-c4b3-45de-ab9f-961e420daba5'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'АРИТМІЛ'
    AND m.package_qty = 50
    AND m.certificate = 'UA/1438/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/1438/02/01', '2019-11-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9eb792b4-17a6-4a00-87f0-29ec6defd378'', ''АРИТМІЛ'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": "Україна"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/1438/02/01'', ''2019-11-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0d1f7da2-369c-4879-835f-d04af82db3e6'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "72.19"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3388cdc1-9157-4adf-8d43-ea677a00de28'', ''{"type": "FIXED", "reimbursement_amount": "72.19"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amiodarone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Аміодарон 200 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05301221-4907-4ebc-b106-7fc20c316748'', ''Аміодарон 200 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''fe829769-2324-4bd1-9ce2-0bbdd0b68f51'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'АМІОКОРДИН®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/10291/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01BD01"]'::jsonb, 'UA/10291/01/01', '2019-11-20'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4aa425f3-2f34-472b-a38e-cd8c97076a6b'', ''АМІОКОРДИН®'', ''BRAND'', ''{"name": "КРКА", "country": " Словенія"}'', ''["C01BD01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/10291/01/01'', ''2019-11-20'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''7ccff537-5314-414e-8034-2f3c19a4c19f'', ''{"numerator_unit": "MG", "numerator_value": "200", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "86.63"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ce62ff52-d784-4b6b-bc52-cf0389390c1b'', ''{"type": "FIXED", "reimbursement_amount": "86.63"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7a85e64a-66df-446a-b88b-9a59eedff6d9'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1427/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1427/01/01', '2019-08-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''207483e8-1958-4222-a403-4759af7f4dad'', ''АМЛОДИПІН'', ''BRAND'', ''{"name": "ПрАТ \"Технолог\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1427/01/01'', ''2019-08-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''8bc992df-79a5-459c-bd16-ddf1bf7bdbde'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''52a7fd36-823b-461d-a485-1add8ef916b8'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''9f40b7a5-0d42-423c-8812-8de35da69930'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН'
    AND m.package_qty = 60
    AND m.certificate = 'UA/1427/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1427/01/01', '2019-08-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4f2a5b3c-57d6-479c-8b9b-06b4460626ce'', ''АМЛОДИПІН'', ''BRAND'', ''{"name": "ПрАТ \"Технолог\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/1427/01/01'', ''2019-08-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''faef4607-8b81-4274-9f7d-ddb31f65cf86'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d1d4a07f-a8de-448d-8334-6c348170ba1a'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''82ec14fb-61ad-4d0a-ab01-c2ede516be03'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АЛАДИН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11314/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/11314/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''481ab9f5-35a8-4697-9164-6ff1fde79f35'', ''АЛАДИН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11314/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''330ca001-19fd-4b52-8ae4-2dbff14b87f9'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''f83d3cb8-f856-46f6-bde6-93b197342c5a'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''1b75324a-bf74-4bc8-8e73-cb6142304e2f'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АЛАДИН®-ФАРМАК'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16983/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/16983/01/01', '2023-10-22'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''95a15d9c-7e85-4238-bdea-c36935afe658'', ''АЛАДИН®-ФАРМАК'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16983/01/01'', ''2023-10-22'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''c5f37a27-9cbc-4510-aa7e-4f1a9c5662b9'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b664cd8c-2272-4e50-a09c-e12195217899'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''23af638b-25f4-4226-ad8c-e22b6cb3172e'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН'
    AND m.package_qty = 90
    AND m.certificate = 'UA/1427/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1427/01/01', '2019-08-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c77861c1-5768-4222-92d2-543798db16fd'', ''АМЛОДИПІН'', ''BRAND'', ''{"name": "ПрАТ \"Технолог\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/1427/01/01'', ''2019-08-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d31165d9-a299-4581-bb9c-7b89de012237'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "24.36"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''844c3eed-f56c-423c-ab5f-400a716d6c6d'', ''{"type": "FIXED", "reimbursement_amount": "24.36"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''0edf5ae4-8537-4cc5-a92e-ea85bb65307c'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АЛАДИН®'
    AND m.package_qty = 50
    AND m.certificate = 'UA/11314/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/11314/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''521d0630-a9f4-4e27-91d6-6364996a5311'', ''АЛАДИН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/11314/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''4134e367-a05f-4c8a-94f4-2d6d0428e647'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "13.54"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''0176e75b-20ae-436b-9607-62f2eb8ac314'', ''{"type": "FIXED", "reimbursement_amount": "13.54"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''87d4668f-fea8-4b77-b7aa-4855eee17079'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АЛАДИН®-ФАРМАК'
    AND m.package_qty = 50
    AND m.certificate = 'UA/16983/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/16983/01/01', '2023-10-22'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''52623016-9d04-463c-ae50-60a807a25ead'', ''АЛАДИН®-ФАРМАК'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/16983/01/01'', ''2023-10-22'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1eac8d34-d1ea-42fd-b601-578ef864c534'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "13.54"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a36ff5fd-ab21-4832-81f6-8c7ed0ce2b2d'', ''{"type": "FIXED", "reimbursement_amount": "13.54"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''3b44f905-8273-4628-8e44-02ac18648fc2'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН-ДАРНИЦЯ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/7940/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/7940/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b40e41e2-e79d-47c2-ac12-cced5403e246'', ''АМЛОДИПІН-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/7940/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''819882f8-1bc6-4d57-8558-5c294df355c6'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "5.41"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''fb13e05b-b9cf-43f8-839f-eb1558c71e98'', ''{"type": "FIXED", "reimbursement_amount": "5.41"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''fe714392-072e-433e-a380-6ebf896d7342'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН-АСТРАФАРМ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/3673/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/3673/01/01', '2020-04-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''74659f09-2d61-4b9b-bf83-eccedef51d78'', ''АМЛОДИПІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/3673/01/01'', ''2020-04-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d241c9c1-649a-41e3-b4ed-a70e264b0e2b'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "5.41"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''05ec2661-90f0-48d2-ac01-416e7a4c0c94'', ''{"type": "FIXED", "reimbursement_amount": "5.41"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''def34c8d-0f26-4b44-acd6-5469d2e9d96a'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН-ЗДОРОВ''Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1538/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1538/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''cf287e22-8e19-4593-b89d-5e66ec79edcc'', ''АМЛОДИПІН-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1538/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''734e138f-1850-4ccc-b9b0-113414281bde'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''50768b85-cf39-4da3-b28b-03fb7d717dda'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e44debfd-79f5-4937-872e-31a9a1acb9f0'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН-КВ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/7831/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/7831/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''60bedc6c-185d-4f4d-99a2-4609d520df37'', ''АМЛОДИПІН-КВ'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/7831/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d6137da2-b73e-4523-94ec-ee693e97da8d'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''7d45747f-7a9b-4220-83a6-eb88021c7fc7'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''343145c4-4e6e-4c93-b99d-df27bc7b0389'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН-АСТРАФАРМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3673/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/3673/01/01', '2020-04-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8a4cded0-2f80-44b7-be50-2db8d6d930dc'', ''АМЛОДИПІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3673/01/01'', ''2020-04-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ae768646-4544-4493-b7af-f95f5f7916a7'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a6accf3a-3677-4e64-95df-80a46529ffab'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''f0f16243-b482-4c0f-b1c3-a434900e360a'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН-ФАРМАК'
    AND m.package_qty = 20
    AND m.certificate = 'UA/4556/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/4556/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fec6b0e2-bf74-4c7a-8f41-3dc0c96c5a5f'', ''АМЛОДИПІН-ФАРМАК'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/4556/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''c21eb542-4598-4f0b-af90-31075616cee5'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "5.41"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e28d17d3-3370-4743-8c81-4cdf77ff2e80'', ''{"type": "FIXED", "reimbursement_amount": "5.41"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''5c8c071e-1bde-4a28-b84e-fed5aa17c06d'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16717/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/16717/01/01', '2023-05-16'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ddfffb24-525f-4917-848b-8e25fc189bad'', ''АМЛОДИПІН-ТЕВА'', ''BRAND'', ''{"name": "АТ Фармацевтичний завод ТЕВА", "country": " Угорщина"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16717/01/01'', ''2023-05-16'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3acbac1e-0d02-4138-ab1e-b0281e74a513'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''c338b085-cd3b-4b0b-a025-0a80101f7a8c'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''a465874c-4988-48fb-b2b5-900db869dcd7'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1586/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1586/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c5302be5-328b-4687-869d-f4e06832a7ea'', ''АМЛОДИПІН'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1586/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''e8731294-ae55-47b8-ae18-63cd312be202'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d7b9bd87-873e-4ce4-aa94-31b16e91a1bf'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''867c3f57-6ec9-47f3-b567-eff1e36fae7c'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'СТАМЛО'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1421/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1421/01/01', '2019-07-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0421b166-e307-4c63-968c-e55de118f309'', ''СТАМЛО'', ''BRAND'', ''{"name": "Д-р Редді''''с Лабораторіс Лтд", "country": " Індія"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1421/01/01'', ''2019-07-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0d64f056-ec09-4e5c-bfc4-16ec329bc46f'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''76bccab2-54c7-41b8-a72a-6e5a0f4af2e4'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''bfb13fd0-8402-45fc-a14f-be8158238189'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОДИПІН САНДОЗ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11166/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/11166/01/01', '2020-08-19'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''48a1d87c-e53d-4d1c-8a10-bb671a4e0f5a'', ''АМЛОДИПІН САНДОЗ®'', ''BRAND'', ''{"name": "Лек фармацевтична компанія д.д.", "country": " Словенія"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11166/01/01'', ''2020-08-19'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3b69c44e-8d8f-420e-b31b-9d68840da9ab'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''918b542a-fb5b-41f1-ac45-0288c7b12620'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''fc4de3d6-9261-400a-a2f4-2ecff140dfa8'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'ЕМЛОДИН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/6382/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/6382/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''98b49876-7e23-4262-b802-071d3965dd0e'', ''ЕМЛОДИН®'', ''BRAND'', ''{"name": "ЗАТ Фармацевтичний завод ЕГІС", "country": " Угорщина"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/6382/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''31bcd430-e0b1-4393-b8c8-992f74079d27'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''6cf9c3d8-4518-40d4-8ad6-cc36e187c3c7'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1566bf63-5666-4368-b2e9-352bbfbd7358'', ''Амлодипін 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''d45c2d8c-5765-4660-bd77-cebfeaa97d5f'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'АМЛОЦИМ 5 МГ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14494/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/14494/01/02', '2020-11-04'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0fbfcb3b-dfb5-4338-b7ca-3caaa7a57c1e'', ''АМЛОЦИМ 5 МГ'', ''BRAND'', ''{"name": "Юнікем Лабораторіз Лімітед", "country": " Індія"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14494/01/02'', ''2020-11-04'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''b3b46150-02cd-4905-8142-43cd3f40d1eb'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a7172ea4-3d99-43d9-bd34-6dae382760ff'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7fa7c2d4-e66e-4e5c-af0f-db2bec683704'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АЛАДИН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11314/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/11314/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''accb0272-4db4-4188-b276-952b7c7c2535'', ''АЛАДИН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11314/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''26f9ee83-57bd-4125-a54c-865e2581ff0e'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''47c6eb5f-c560-48f4-b862-4dc01bc3d2ab'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''b161efb7-996b-49e9-a382-a849080f3f42'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АЛАДИН®'
    AND m.package_qty = 50
    AND m.certificate = 'UA/11314/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/11314/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''84c41d6a-43ac-44f3-8603-9d841f3ccfd6'', ''АЛАДИН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/11314/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''7216998d-0421-43bf-bb5a-43d217a0fd78'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "27.07"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a5318c68-453c-45ad-a172-cf553d96a43f'', ''{"type": "FIXED", "reimbursement_amount": "27.07"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ef9807eb-9b86-4beb-8d4c-cd7162eec1c1'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АЛАДИН®-ФАРМАК'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16983/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/16983/01/02', '2023-10-22'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''cc6153a6-ac18-4ce3-98cf-3b8837d0113b'', ''АЛАДИН®-ФАРМАК'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16983/01/02'', ''2023-10-22'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''849a2925-79d1-4fa4-aa70-ec6b9779cfe4'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''13b46fe8-afea-4332-a0e0-644558f052df'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8fcef8b3-a702-437e-9965-3576a4bb23e9'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АЛАДИН®-ФАРМАК'
    AND m.package_qty = 50
    AND m.certificate = 'UA/16983/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/16983/01/02', '2023-10-22'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e565532c-db96-4742-86ca-c1e08ec1039e'', ''АЛАДИН®-ФАРМАК'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/16983/01/02'', ''2023-10-22'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''20a26312-8c7d-4308-9e8b-0f4e3a88a18d'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "27.07"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''5c3cd41f-f21b-4430-95da-e8e8232c5d5c'', ''{"type": "FIXED", "reimbursement_amount": "27.07"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''299e098e-9204-4efc-bc04-eb6209faf6ae'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1427/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1427/01/02', '2019-08-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''53fc4e85-0677-4479-bf0b-0c34202b1630'', ''АМЛОДИПІН'', ''BRAND'', ''{"name": "ПрАТ \"Технолог\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1427/01/02'', ''2019-08-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''90567c11-5afc-4a74-a8ea-2e45339a67d0'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''c2f345d6-af7b-4209-b8b4-6c2b2d1b7a0e'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''3a4b3c2b-691c-4843-867c-7fb0337e973f'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН'
    AND m.package_qty = 60
    AND m.certificate = 'UA/1427/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1427/01/02', '2019-08-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6f2bbf35-3e5a-4ed1-a4b4-7b0444154179'', ''АМЛОДИПІН'', ''BRAND'', ''{"name": "ПрАТ \"Технолог\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/1427/01/02'', ''2019-08-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''734acd37-3e2f-4078-8d44-39cadfa49bae'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "32.49"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ef1e311c-da2f-42bb-91a5-15335a2a008a'', ''{"type": "FIXED", "reimbursement_amount": "32.49"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''99796220-e891-416c-b1c6-5114b752d6f4'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН-ДАРНИЦЯ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/7940/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/7940/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''730d52b9-3d02-4034-9a1b-1f47b1b17aaa'', ''АМЛОДИПІН-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/7940/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1f991a4a-19f6-44a5-b321-890c5f8a80fd'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "10.83"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ff6a5f6b-8eb8-4973-a003-e308a6bf2f18'', ''{"type": "FIXED", "reimbursement_amount": "10.83"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8ec418ca-6d63-4d2b-956f-fb04679be0de'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН-АСТРАФАРМ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/3673/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/3673/01/02', '2020-04-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''7f90a652-6b59-4a02-bdc8-36eb7befe8f5'', ''АМЛОДИПІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/3673/01/02'', ''2020-04-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ee2a89f2-e5d4-477d-94c9-d8807d4e01ca'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "10.83"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''26e12952-a7a0-4523-bf7f-5c767d46f840'', ''{"type": "FIXED", "reimbursement_amount": "10.83"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''a6a428b5-6ee6-4b4a-b4a6-b3235a294176'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН'
    AND m.package_qty = 90
    AND m.certificate = 'UA/1427/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1427/01/02', '2019-08-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c79c027-6e18-438a-bb76-24a0a7be1ef1'', ''АМЛОДИПІН'', ''BRAND'', ''{"name": "ПрАТ \"Технолог\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/1427/01/02'', ''2019-08-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''faf22817-5f6e-4eac-8002-e8f49b137151'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.73"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''74922536-0785-4d7d-a374-368ee022c04d'', ''{"type": "FIXED", "reimbursement_amount": "48.73"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''00e835a1-0e8e-40e7-9bfa-610b2acc00c2'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН-АСТРАФАРМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3673/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/3673/01/02', '2020-04-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''febe4276-1f70-4d59-9254-5daef46db768'', ''АМЛОДИПІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3673/01/02'', ''2020-04-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1a6a995a-5ef5-4f0e-8227-2f7d4ee64917'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b3d8fcdb-1368-4ec7-b5a7-9a2d183d1df4'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8309ca25-6ebf-4ef9-8ea4-20215b22b9a2'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН-ФАРМАК'
    AND m.package_qty = 20
    AND m.certificate = 'UA/4556/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/4556/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''815e792b-bcc3-4d74-baa7-e2317f58ae2d'', ''АМЛОДИПІН-ФАРМАК'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/4556/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1c2c0fa0-0fb2-482f-b2e2-1803eba3f78c'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "10.83"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''90deee85-ae07-4f8a-8ff0-7e54a19dce1e'', ''{"type": "FIXED", "reimbursement_amount": "10.83"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''016ab803-11cc-4a16-a026-137e1b8d64a4'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН-ЗДОРОВ''Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1538/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1538/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''89aa2004-19b4-455e-a52b-f26999249d67'', ''АМЛОДИПІН-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1538/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''8fdf64e2-ff51-43aa-87bc-7d4b35219b58'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3c57c070-df31-4c83-aa9d-c13a4384016e'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''572588b0-decb-4a48-ae43-988a1e5cb656'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН-КВ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/7831/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/7831/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4e940eae-b6a4-44be-bbb7-4977d4f766cc'', ''АМЛОДИПІН-КВ'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/7831/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''9b36c903-754b-4c09-9be5-dd04e3343288'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''7f4f8441-53d7-46d4-9a1b-7731048d774e'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e3552c2b-b018-4af4-8414-f50c95bf472b'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16717/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/16717/01/02', '2023-05-16'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fbf1d3f0-c037-49f9-b87c-4776a60339c1'', ''АМЛОДИПІН-ТЕВА'', ''BRAND'', ''{"name": "АТ Фармацевтичний завод ТЕВА", "country": " Угорщина"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16717/01/02'', ''2023-05-16'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''21d5c12e-e39e-4bc6-bede-03c152e543cd'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''c479d356-ced2-4266-ace8-22f5d3b262cc'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''08810d18-e15b-4c38-a47f-d0efdd4c7ee9'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'СТАМЛО'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1421/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/1421/01/02', '2019-07-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''51352eaf-7195-4d47-abed-385b2599e996'', ''СТАМЛО'', ''BRAND'', ''{"name": "Д-р Редді''''с Лабораторіс Лтд", "country": " Індія"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1421/01/02'', ''2019-07-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''c7455311-d8c6-4d5a-86ba-4b781be80790'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''9b5fbb23-62a3-44c2-836b-cdcdf31effcf'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''66bafc59-a2c7-4c13-a112-12c8d7a90c8f'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОДИПІН САНДОЗ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11166/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/11166/01/02', '2020-08-19'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ebcf6ad7-791b-4c15-bae8-49cc0b877dc0'', ''АМЛОДИПІН САНДОЗ®'', ''BRAND'', ''{"name": "Лек фармацевтична компанія д.д.", "country": " Словенія"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11166/01/02'', ''2020-08-19'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''84f65c8b-b549-4b8a-9cbb-30e26f01ff82'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e5045af8-508f-4177-b9a9-e9c0ebfd739e'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e207fcb6-06e6-4f57-958a-686e26a76d49'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕМЛОДИН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/6382/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/6382/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''86d4ce17-3b98-48fb-bb9b-8447e9a400b1'', ''ЕМЛОДИН®'', ''BRAND'', ''{"name": "ЗАТ Фармацевтичний завод ЕГІС", "country": " Угорщина"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/6382/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''031c75cb-3b10-42f7-9a82-69143d975fd2'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e20738c1-9216-41fa-b54c-58c82cbfa95a'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Amlodipine' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Амлодипін 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15a311a7-d37a-49e0-83dc-24ab8902db42'', ''Амлодипін 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''b569bf0d-7df8-4910-a55d-3c9894da0213'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'АМЛОЦИМ 10 МГ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14494/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08CA01"]'::jsonb, 'UA/14494/01/01', '2020-11-04'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''62e2dd1d-286b-4c25-bd53-e5cbd67fa36c'', ''АМЛОЦИМ 10 МГ'', ''BRAND'', ''{"name": "Юнікем Лабораторіз Лімітед", "country": " Індія"}'', ''["C08CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14494/01/01'', ''2020-11-04'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''11e4d8b6-3644-41be-86bf-dfb1b2e7e828'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''8d2f5cb5-0264-4741-a078-e47eafbc331d'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Atenolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Атенолол 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''73faedcc-627a-43df-a0be-2c615b48d82a'', ''Атенолол 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''f5a6b6f3-f939-43ef-aba9-578964bdbdac'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'АТЕНОЛОЛ-АСТРАФАРМ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/4941/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB03"]'::jsonb, 'UA/4941/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a3e02421-6bbb-4442-9881-4844ff94bb7e'', ''АТЕНОЛОЛ-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C07AB03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/4941/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''32aa319f-823d-41f6-b647-96fd6cc21459'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "12.99"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''82fcdf21-9812-41bf-980c-169289907a5f'', ''{"type": "FIXED", "reimbursement_amount": "12.99"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Atenolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Атенолол 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ebdc88d4-43a0-485a-a40b-1dabd61d8495'', ''Атенолол 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''2d68079e-c7c6-4151-bbf1-979af6b4c3be'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'АТЕНОЛОЛ-АСТРАФАРМ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/4941/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB03"]'::jsonb, 'UA/4941/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''53e32391-fb4e-414c-9016-4e0e7b1034ef'', ''АТЕНОЛОЛ-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C07AB03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/4941/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3eeba302-10f4-4d88-9b8b-4d8640823b2b'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "6.50"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''6ef8d2b5-66de-4fbe-b2d7-849adc918849'', ''{"type": "FIXED", "reimbursement_amount": "6.50"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Atenolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Атенолол 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ebdc88d4-43a0-485a-a40b-1dabd61d8495'', ''Атенолол 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7a44a8f3-f382-4aa9-b673-b2c3ccc28eb9'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'АТЕНОЛОЛ - ЗДОРОВ''Я'
    AND m.package_qty = 20
    AND m.certificate = 'UA/6065/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB03"]'::jsonb, 'UA/6065/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''893b00db-984c-4e39-8f42-a939b2c4c837'', ''АТЕНОЛОЛ - ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C07AB03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/6065/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ce12838a-020b-4e5f-befd-094adde8ee18'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "6.50"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''34a211b0-2e3f-4160-a4f9-4255433fb94f'', ''{"type": "FIXED", "reimbursement_amount": "6.50"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Atenolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Атенолол 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ebdc88d4-43a0-485a-a40b-1dabd61d8495'', ''Атенолол 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''014a99f8-838c-4922-9cdb-57b1e16eda6a'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'АТЕНОЛОЛ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/8377/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["С07АВ03"]'::jsonb, 'UA/8377/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''682490c0-a08a-41ee-b7fe-9ab498433d18'', ''АТЕНОЛОЛ'', ''BRAND'', ''{"name": "ПАТ \"МОНФАРМ\"", "country": " Україна"}'', ''["С07АВ03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/8377/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''9890d8e4-0c17-465d-ade0-bfe4d15f34ee'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "6.50"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d7b78128-8790-4124-8965-f0aa5c1cb636'', ''{"type": "FIXED", "reimbursement_amount": "6.50"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Verapamil' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Верапаміл 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6d274c83-197a-4bfe-96a8-5253f7cba2f5'', ''Верапаміл 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''b7081ada-0172-4c9b-ba1a-42bde059869b'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'ВЕРАПАМІЛ-ДАРНИЦЯ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/3582/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08DA01"]'::jsonb, 'UA/3582/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''43b97954-f88b-47bd-8f43-90cb01648b66'', ''ВЕРАПАМІЛ-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C08DA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/3582/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''58a9ba96-ada5-48da-85af-546cd2947ce5'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "6.09"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''13d3c005-5324-44aa-9fac-34a47cdf4388'', ''{"type": "FIXED", "reimbursement_amount": "6.09"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Verapamil' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Верапаміл 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6d274c83-197a-4bfe-96a8-5253f7cba2f5'', ''Верапаміл 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''62de779f-aecc-494a-8ca2-de85e893c49d'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'ВЕРАПАМІЛУ ГІДРОХЛОРИД'
    AND m.package_qty = 20
    AND m.certificate = 'UA/5540/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08DA01"]'::jsonb, 'UA/5540/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c47f8c4f-73c1-40fa-b36a-3660d724280d'', ''ВЕРАПАМІЛУ ГІДРОХЛОРИД'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Дослідний завод \"ГНЦЛС\"", "country": " Україна"}'', ''["C08DA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/5540/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''9dd3b845-ea65-4d29-926b-ce397a29d713'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "6.09"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''39246fe3-a3ae-4b95-9b4e-f08cf53a6f54'', ''{"type": "FIXED", "reimbursement_amount": "6.09"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Verapamil' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Верапаміл 80 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''76023b51-c18f-425f-a59d-7cb2c4e80922'', ''Верапаміл 80 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c7ae084b-5a5c-4dc1-902f-c7e7f84d2043'', ''{"numerator_unit": "MG", "numerator_value": "80", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 80
    AND m.name = 'ВЕРАПАМІЛ-ДАРНИЦЯ'
    AND m.package_qty = 50
    AND m.certificate = 'UA/3582/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08DA01"]'::jsonb, 'UA/3582/01/01', '2020-06-12'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''7ef04174-3801-409f-a04f-4f06f8bb10e3'', ''ВЕРАПАМІЛ-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C08DA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/3582/01/01'', ''2020-06-12'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''5e69de83-ba29-4f51-b7c4-290423753b13'', ''{"numerator_unit": "MG", "numerator_value": "80", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "30.45"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3c66b2e4-8d81-4363-92c1-a8a4a75c6721'', ''{"type": "FIXED", "reimbursement_amount": "30.45"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Verapamil' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Верапаміл 80 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''76023b51-c18f-425f-a59d-7cb2c4e80922'', ''Верапаміл 80 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''bbe398e5-1f90-44dc-a4ac-b97b611f7ac6'', ''{"numerator_unit": "MG", "numerator_value": "80", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 80
    AND m.name = 'ВЕРАПАМІЛУ ГІДРОХЛОРИД'
    AND m.package_qty = 50
    AND m.certificate = 'UA/3226/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C08DA01"]'::jsonb, 'UA/3226/01/01', '2020-03-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b334b01b-fb3c-4864-9cb7-dfea7acfa180'', ''ВЕРАПАМІЛУ ГІДРОХЛОРИД'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": "Україна"}'', ''["C08DA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/3226/01/01'', ''2020-03-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''73806241-6f25-4627-bd67-004073f16845'', ''{"numerator_unit": "MG", "numerator_value": "80", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "30.45"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''c766ef7f-05ae-4b73-b435-ecda4b921473'', ''{"type": "FIXED", "reimbursement_amount": "30.45"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Hydrochlorothiazide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Гідрохлортіазид 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''81d8e674-6f70-41dd-b7e2-7f6a0ce53b91'', ''Гідрохлортіазид 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''48efbffd-bd50-4a13-970d-eb9a459eaab6'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'ГІДРОХЛОРТІАЗИД'
    AND m.package_qty = 20
    AND m.certificate = 'UA/6721/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03AA03"]'::jsonb, 'UA/6721/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ed29ca48-5960-479b-bab7-6a0573cbd6b0'', ''ГІДРОХЛОРТІАЗИД'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": " Україна"}'', ''["C03AA03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/6721/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''17bd3935-6e86-479b-baa4-1749dabf0713'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "23.69"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''244352bb-d439-45fa-b481-960b1f6c8344'', ''{"type": "FIXED", "reimbursement_amount": "23.69"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Spironolactone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Спіронолактон 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''10f62594-6b65-46ce-958d-29bff9a8736c'', ''Спіронолактон 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ae76a345-1870-4866-a670-7cadda992c46'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'ВЕРОШПІРОН'
    AND m.package_qty = 20
    AND m.certificate = 'UA/2775/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03DA01"]'::jsonb, 'UA/2775/02/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ad8beac4-330d-4637-a93f-8833dbb2522d'', ''ВЕРОШПІРОН'', ''BRAND'', ''{"name": "ВАТ \"Гедеон Ріхтер\"", "country": " Угорщина"}'', ''["C03DA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/2775/02/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0c23ec3d-a213-4870-8a52-982f3e705ab8'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "18.81"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''661712b9-c0b2-4501-80bf-c451ccead7d1'', ''{"type": "FIXED", "reimbursement_amount": "18.81"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Spironolactone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Спіронолактон 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''10f62594-6b65-46ce-958d-29bff9a8736c'', ''Спіронолактон 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c89a371b-667b-4c92-af92-db3688f8b13e'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'СПІРОНОЛАКТОН-ДАРНИЦЯ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/0808/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03DA01"]'::jsonb, 'UA/0808/01/01', '2019-04-16'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''86ae2cb3-8d75-4bda-b746-31624a75af34'', ''СПІРОНОЛАКТОН-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C03DA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/0808/01/01'', ''2019-04-16'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''07ba008d-1eaa-4851-8d59-e765d9b23475'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "28.21"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''c150572b-439e-496e-8a17-4a303ff9347e'', ''{"type": "FIXED", "reimbursement_amount": "28.21"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Spironolactone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Спіронолактон 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1b353b83-4e7b-4b3a-97e4-b533caaf2c5b'', ''Спіронолактон 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e255e781-cc6d-4428-8a53-bc1b499bc109'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'СПІРОНОЛАКТОН САНДОЗ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14227/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03DA01"]'::jsonb, 'UA/14227/01/01', '2020-03-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5c68b67b-381b-4b7e-8e20-6c6c0769d771'', ''СПІРОНОЛАКТОН САНДОЗ®'', ''BRAND'', ''{"name": "Салютас Фарма ГмбХ", "country": " Німеччина"}'', ''["C03DA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14227/01/01'', ''2020-03-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3104a763-280d-439d-b973-057234c0deba'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "56.42"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''891e665e-702f-4fb0-9134-d3489ff849b9'', ''{"type": "FIXED", "reimbursement_amount": "56.42"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Spironolactone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Спіронолактон 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''74836fb0-144d-44ff-a0db-b865a3e77b35'', ''Спіронолактон 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''fee679a8-1a9f-4e7b-a28c-33219369f6e9'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'СПІРОНОЛАКТОН-ДАРНИЦЯ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/0808/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03DA01"]'::jsonb, 'UA/0808/01/02', '2021-12-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''2be249b9-d46c-4dd4-ad12-c01669cc8f73'', ''СПІРОНОЛАКТОН-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C03DA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/0808/01/02'', ''2021-12-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''478421cd-ada4-4544-a458-6ab81c42255d'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "112.83"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''95a64152-d69c-488f-9818-83c0ee941870'', ''{"type": "FIXED", "reimbursement_amount": "112.83"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Spironolactone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Спіронолактон 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''74836fb0-144d-44ff-a0db-b865a3e77b35'', ''Спіронолактон 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''3015e628-5df8-4eff-a386-5073bdb4e5bc'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'СПІРОНОЛАКТОН САНДОЗ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14227/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03DA01"]'::jsonb, 'UA/14227/01/02', '2020-03-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''52c0a2bf-8639-4ba3-8db1-8ae544e8a680'', ''СПІРОНОЛАКТОН САНДОЗ®'', ''BRAND'', ''{"name": "Салютас Фарма ГмбХ", "country": " Німеччина"}'', ''["C03DA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14227/01/02'', ''2020-03-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''db5724af-1b83-43c7-91e6-273cde7d2e31'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "112.83"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e91d4ae6-18c2-4ade-96a4-1fb59fe15135'', ''{"type": "FIXED", "reimbursement_amount": "112.83"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Furosemide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Фуросемід 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e7e20df6-5cdb-4a11-b67d-c96fcfffa572'', ''Фуросемід 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8ee4db2c-4cb1-434e-8888-6311da7dafaf'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'ФУРОСЕМІД-ДАРНИЦЯ'
    AND m.package_qty = 50
    AND m.certificate = 'UA/2353/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03CA01"]'::jsonb, 'UA/2353/01/01', '2019-12-25'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0c6837f6-96bc-40d1-b80b-b43b33f4b36e'', ''ФУРОСЕМІД-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C03CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/2353/01/01'', ''2019-12-25'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a66bfa79-37c0-44cf-90f8-ff14631d561f'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''73e5591c-51d8-4020-9af2-136cd3aca0f5'', ''{"type": "FIXED", "reimbursement_amount": "8.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Furosemide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Фуросемід 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e7e20df6-5cdb-4a11-b67d-c96fcfffa572'', ''Фуросемід 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''9939f40d-f3d9-4539-9cb2-ea1bfa809064'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'ФУРОСЕМІД'
    AND m.package_qty = 50
    AND m.certificate = 'UA/3983/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03CA01"]'::jsonb, 'UA/3983/01/01', '2020-09-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''53292762-8d0b-4bbc-9466-1b66bdfd505e'', ''ФУРОСЕМІД'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": " Україна"}'', ''["C03CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/3983/01/01'', ''2020-09-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''80abf549-956e-4d56-9e9a-0adf879a1ac6'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a55467d5-f8a4-4595-ab11-6be2ed892590'', ''{"type": "FIXED", "reimbursement_amount": "8.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Furosemide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Фуросемід 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e7e20df6-5cdb-4a11-b67d-c96fcfffa572'', ''Фуросемід 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''0fd8d1b5-b4d1-4273-bd6d-4856a6052a45'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'ФУРОСЕМІД'
    AND m.package_qty = 50
    AND m.certificate = 'UA/5153/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03CA01"]'::jsonb, 'UA/5153/02/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d834aa2e-b810-4f9d-a9d4-265a2d11d69a'', ''ФУРОСЕМІД'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Дослідний завод \"ГНЦЛС\"", "country": " Україна"}'', ''["C03CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/5153/02/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''bd4cae16-c8e8-4c28-941e-c0b7025b88e2'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''cd7bba88-36c4-4c3c-912d-16fca0a54697'', ''{"type": "FIXED", "reimbursement_amount": "8.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Furosemide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Фуросемід 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e7e20df6-5cdb-4a11-b67d-c96fcfffa572'', ''Фуросемід 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''0b5ac206-db8f-4f46-a2da-f0a1a0fb94bd'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'ФУРОСЕМІД'
    AND m.package_qty = 50
    AND m.certificate = 'UA/0187/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C03CA01"]'::jsonb, 'UA/0187/01/01', '2019-02-26'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d9d72cc8-bbd7-46f3-9b17-f26b1ec1225f'', ''ФУРОСЕМІД'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["C03CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/0187/01/01'', ''2019-02-26'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''953e7942-08ae-48e5-bb94-bd5d52ed0204'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d9b372c9-f648-4496-8d9e-7104bf25b311'', ''{"type": "FIXED", "reimbursement_amount": "8.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Digoxin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Дигоксин 0.25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''868abf09-73de-4c56-89f5-4c75635025bd'', ''Дигоксин 0.25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''17c6e5df-5e2c-49ee-b475-e2f13d8e08a2'', ''{"numerator_unit": "MG", "numerator_value": "0.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 0.25
    AND m.name = 'ДИГОКСИН'
    AND m.package_qty = 40
    AND m.certificate = 'UA/7365/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["С01АА05"]'::jsonb, 'UA/7365/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e3be257c-aa1d-4622-bc8e-4e40e10924e8'', ''ДИГОКСИН'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": "Україна"}'', ''["С01АА05"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 40, 40, ''UA/7365/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''304828f0-d7c3-4e25-87d9-8f49526f1a6f'', ''{"numerator_unit": "MG", "numerator_value": "0.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.26"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b309edf3-16ed-42a7-bcd5-e3c7fb1dec79'', ''{"type": "FIXED", "reimbursement_amount": "8.26"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Digoxin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Дигоксин 0.25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''868abf09-73de-4c56-89f5-4c75635025bd'', ''Дигоксин 0.25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''9a8537d3-2a56-4bb2-9901-a9e6b3fa4507'', ''{"numerator_unit": "MG", "numerator_value": "0.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 0.25
    AND m.name = 'ДИГОКСИН-ЗДОРОВ''Я'
    AND m.package_qty = 50
    AND m.certificate = 'UA/4231/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01AA05"]'::jsonb, 'UA/4231/01/01', '2020-09-04'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''76b6bcb3-bebb-493b-ae07-a1b8a5706c0d'', ''ДИГОКСИН-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C01AA05"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/4231/01/01'', ''2020-09-04'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''fd500bfc-f06e-43cd-add5-5a1cd14c6059'', ''{"numerator_unit": "MG", "numerator_value": "0.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "10.32"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''4e10b5dc-5f76-4d31-a8ae-16ba1f1ab8ce'', ''{"type": "FIXED", "reimbursement_amount": "10.32"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''06f267fe-461a-425d-8e80-3ab9e501fc7f'', ''Еналаприл 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''83632ecd-9c38-499f-9cca-efdc79ff3165'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'ЕНАЛАПРИЛ-ЗДОРОВ''Я'
    AND m.package_qty = 20
    AND m.certificate = 'UA/5913/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/5913/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e08f56e9-fd2d-47a8-95c6-7b9cdffd8e14'', ''ЕНАЛАПРИЛ-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/5913/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''2dfcc810-0b43-457d-bb22-485a907510d2'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "2.38"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''6003c070-91e2-4931-9c74-4a083ac41a27'', ''{"type": "FIXED", "reimbursement_amount": "2.38"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''06f267fe-461a-425d-8e80-3ab9e501fc7f'', ''Еналаприл 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''580869ed-f106-4a1e-9eae-c6dbd1fa23bb'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'ЕНАЛАПРИЛ-ЗДОРОВ''Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/5913/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/5913/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8cdb3dc3-3c38-4005-9c44-886fbca09ad8'', ''ЕНАЛАПРИЛ-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/5913/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''2554fd99-eb9a-4a8c-9a76-089a838017e9'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "3.57"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ef7ad6d2-39c8-4e32-91c1-9cacf34046fc'', ''{"type": "FIXED", "reimbursement_amount": "3.57"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''06f267fe-461a-425d-8e80-3ab9e501fc7f'', ''Еналаприл 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e09c3969-8c34-407b-bb4b-c8df0f0e408f'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'ЕНАЛАПРИЛ-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16349/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/16349/01/02', '2022-10-11'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''bb6a035d-d60a-4047-bc80-68a656889838'', ''ЕНАЛАПРИЛ-ТЕВА'', ''BRAND'', ''{"name": "ТОВ Тева Оперейшнз Поланд", "country": " Польща"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16349/01/02'', ''2022-10-11'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a6451a72-f81e-4b1f-9637-200c212b30b6'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "3.57"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''cd35e965-50a7-4388-957e-dece83bc475a'', ''{"type": "FIXED", "reimbursement_amount": "3.57"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7b17078f-04f7-4ff7-a6e9-52823187a921'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/1195/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/1195/01/02', '2019-10-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9eae21bd-5e99-4db0-9ad2-dc562ee0b383'', ''ЕНАЛАПРИЛ'', ''BRAND'', ''{"name": "ПАТ \"Лубнифарм\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/1195/01/02'', ''2019-10-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''10e5a1a3-d16d-4388-8896-2f11dca18285'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "4.76"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''1c941199-ee94-471f-a65f-4c580c19c2ec'', ''{"type": "FIXED", "reimbursement_amount": "4.76"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''172edfd7-5d09-4d9e-bf54-f65dff56be88'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/6582/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/6582/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''12d95ae8-14d4-44e5-8e81-989cf961acd4'', ''ЕНАЛАПРИЛ'', ''BRAND'', ''{"name": "ПАТ \"Хімфармзавод \"Червона зірка\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/6582/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''931951e4-585a-46fd-ba2a-8a3ec8c57ec6'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "4.76"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''02180c3f-4120-413a-bfbd-0b4da0c0644d'', ''{"type": "FIXED", "reimbursement_amount": "4.76"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''269c030d-ab2c-40e0-8ef5-6d637cefdc0e'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/8867/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/8867/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502a76f3-2ae7-4246-bd5f-4c69c328d8c6'', ''ЕНАЛАПРИЛ'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/8867/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''50e43116-034d-4c08-8803-649b3661a970'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "4.76"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d1e93316-36ae-4304-af03-4bdc1f04412a'', ''{"type": "FIXED", "reimbursement_amount": "4.76"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''06aa5c26-ec3e-4d06-b285-70a307459b09'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/2818/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/2818/01/01', '2020-03-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''2bf76814-977e-41b3-b8e6-63fdff2ea8b9'', ''ЕНАЛАПРИЛ'', ''BRAND'', ''{"name": "Приватне акціонерне товариство \"Лекхім-Харків\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/2818/01/01'', ''2020-03-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ac9585bc-5e61-4d06-bfdf-f14a305f18bd'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "4.76"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''7b6bd18f-e955-4c3a-83ce-f1fd9268deb5'', ''{"type": "FIXED", "reimbursement_amount": "4.76"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''a5f38e03-4c64-418f-b4e8-184307f45cbf'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ'
    AND m.package_qty = 50
    AND m.certificate = 'UA/2818/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/2818/01/01', '2020-03-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4e27580f-ca7e-4f4f-9443-442111cd5f0f'', ''ЕНАЛАПРИЛ'', ''BRAND'', ''{"name": "Приватне акціонерне товариство \"Лекхім-Харків\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/2818/01/01'', ''2020-03-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''2b4d8bd9-947c-4e8d-ab9a-bbc3826359ab'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.91"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''9dd9b8c0-030f-41e3-8aa9-0b53987e1d62'', ''{"type": "FIXED", "reimbursement_amount": "11.91"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''0cce040d-bd46-402d-a697-5c18ab7b4d72'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ'
    AND m.package_qty = 90
    AND m.certificate = 'UA/2818/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/2818/01/01', '2020-03-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9e4b3ffc-95db-48e0-b948-41309b06b115'', ''ЕНАЛАПРИЛ'', ''BRAND'', ''{"name": "Приватне акціонерне товариство \"Лекхім-Харків\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/2818/01/01'', ''2020-03-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''933de6ea-1156-48cb-b012-b1950482fb09'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "21.44"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''7e1fddfe-d339-4eb1-b3d4-65cdeb10e2ff'', ''{"type": "FIXED", "reimbursement_amount": "21.44"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ccede2ab-649a-401c-ab6d-59bc3f557dd9'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ-АСТРАФАРМ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/5232/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/5232/01/02', '2019-02-08'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4f456b5f-cb02-4444-b2e5-88efa1018e1c'', ''ЕНАЛАПРИЛ-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/5232/01/02'', ''2019-02-08'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ccc38f35-a130-4aa5-a4c3-e13798af16c8'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "4.76"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''1407b646-11d4-4db5-a7db-d639499abbc4'', ''{"type": "FIXED", "reimbursement_amount": "4.76"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''a10c7762-658e-4340-a6f9-237325505a77'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ-ДАРНИЦЯ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/9020/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/9020/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''aeb25708-9cfa-4ffd-a35e-6175982ae698'', ''ЕНАЛАПРИЛ-ДАРНИЦЯ'', ''BRAND'', ''{"name": "ПрАТ \"Фармацевтична фірма \"Дарниця\"", "country": "Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/9020/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''49fafbca-dd38-4e93-a8a4-ace774af7928'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "4.76"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''1235086a-4142-4fb9-8e9c-db02cbdb86f8'', ''{"type": "FIXED", "reimbursement_amount": "4.76"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c395a9f5-3d81-4f17-b460-7f5cac715604'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ-ЗДОРОВ''Я'
    AND m.package_qty = 20
    AND m.certificate = 'UA/5913/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/5913/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b3320ad6-497e-4bde-ab16-233f5633c294'', ''ЕНАЛАПРИЛ-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/5913/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d9e480a7-58b1-4660-8f77-3c25798894a5'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "4.76"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3955cee6-0b5c-47cb-b679-9a044576e2e2'', ''{"type": "FIXED", "reimbursement_amount": "4.76"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''1168f755-0691-490e-9fe0-eb7e83bc3314'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛАПРИЛ-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16349/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/16349/01/03', '2022-10-11'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''2196c3d7-7695-4a52-9f5c-f75149d3f7ed'', ''ЕНАЛАПРИЛ-ТЕВА'', ''BRAND'', ''{"name": "ТОВ Тева Оперейшнз Поланд", "country": " Польща"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16349/01/03'', ''2022-10-11'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ae970d72-5cd6-4bcc-a971-97256d668808'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "7.15"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a1d0b137-ed17-4362-ba5a-0a881d8c8d59'', ''{"type": "FIXED", "reimbursement_amount": "7.15"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ade2d204-ba7e-4953-91b5-e37962fa4ff9'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАЛОЗИД® МОНО'
    AND m.package_qty = 20
    AND m.certificate = 'UA/15415/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/15415/01/02', '2021-09-15'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a02357ab-cfea-49dd-87df-fe26aaf887bc'', ''ЕНАЛОЗИД® МОНО'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/15415/01/02'', ''2021-09-15'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''c83d73b3-7aa7-44af-8d8e-22b913d202c6'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "4.76"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''fffe102f-432a-4239-9d3c-168574871653'', ''{"type": "FIXED", "reimbursement_amount": "4.76"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec965ad-4597-44c4-b3fe-51e9f445081a'', ''Еналаприл 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''f8c0b6c2-4b90-4c8c-9b28-b3b448f9c7f5'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ЕНАМ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/2251/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/2251/01/03', '2020-03-12'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ec028a00-584d-47d8-a6e8-455583e8bca1'', ''ЕНАМ'', ''BRAND'', ''{"name": "Д-р Редді''''с Лабораторіс Лтд", "country": " Індія"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/2251/01/03'', ''2020-03-12'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''69805e23-d76a-453b-a960-2a60951131b6'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "4.76"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''174df00b-0aa9-4cfe-9b47-37dd3575d25f'', ''{"type": "FIXED", "reimbursement_amount": "4.76"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 20 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''eb7e1499-78b5-4867-8252-6d018b715f0d'', ''Еналаприл 20 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''93f0f620-5702-4fb3-a714-8c03aafe4644'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 20
    AND m.name = 'ЕНАЛАПРИЛ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/8867/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/8867/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''73734af6-d39d-4f4a-b470-147aebd24400'', ''ЕНАЛАПРИЛ'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/8867/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''49ea860c-bb71-4cba-bfd5-8b8ad78a6535'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "9.53"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''046800af-4963-4dd9-94e6-6de68a5605b0'', ''{"type": "FIXED", "reimbursement_amount": "9.53"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 20 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''eb7e1499-78b5-4867-8252-6d018b715f0d'', ''Еналаприл 20 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''4b087d72-243c-4ac7-ba85-87855f9ec8cb'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 20
    AND m.name = 'ЕНАЛАПРИЛ-АСТРАФАРМ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/5232/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/5232/01/03', '2019-02-08'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6fd9769c-2ee9-47a6-8930-e4f1ecff01ed'', ''ЕНАЛАПРИЛ-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/5232/01/03'', ''2019-02-08'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''caf9aaab-a628-476f-b584-b16d06f55547'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "9.53"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''8338a0c9-cb40-47c0-a754-7e25ccb717cf'', ''{"type": "FIXED", "reimbursement_amount": "9.53"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 20 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''eb7e1499-78b5-4867-8252-6d018b715f0d'', ''Еналаприл 20 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''0cf0d3f2-c59a-448d-b519-d21222e81a95'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 20
    AND m.name = 'ЕНАЛАПРИЛ-ЗДОРОВ''Я'
    AND m.package_qty = 20
    AND m.certificate = 'UA/5913/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/5913/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e415d537-8068-430c-aee1-d7df76ce942e'', ''ЕНАЛАПРИЛ-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/5913/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a9fb8ade-9e47-4ebc-8efc-3db1cfae2705'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "9.53"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''60a8ae4f-cf10-46f6-b394-14429c2c922e'', ''{"type": "FIXED", "reimbursement_amount": "9.53"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Enalapril' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Еналаприл 20 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''eb7e1499-78b5-4867-8252-6d018b715f0d'', ''Еналаприл 20 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7e7e5efd-fb39-4bbc-96d5-0a1f5e0b5dff'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 20
    AND m.name = 'ЕНАЛАПРИЛ-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16349/01/04';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09AA02"]'::jsonb, 'UA/16349/01/04', '2022-10-11'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''2be8602d-372a-4f31-8b1e-3d2767b34735'', ''ЕНАЛАПРИЛ-ТЕВА'', ''BRAND'', ''{"name": "ТОВ Тева Оперейшнз Поланд", "country": " Польща"}'', ''["C09AA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16349/01/04'', ''2022-10-11'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1a56565b-42f5-4045-a329-7ebd1f508084'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "14.29"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''57bd9bc2-9045-4790-96b6-af8abd404d02'', ''{"type": "FIXED", "reimbursement_amount": "14.29"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Isosorbide dinitrate' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Ізосорбіду динітрат 5 MG таблетки сублінгвальні ' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''33566516-adde-490c-833f-66fce67eca73'', ''Ізосорбіду динітрат 5 MG таблетки сублінгвальні '', ''INNM_DOSAGE'', TRUE, ''SUBLINGVAL_TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''bdaecb54-96ad-4437-8c85-2a764cd20c1f'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'SUBLINGVAL_TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'ІЗО-МІК® 5 мг'
    AND m.package_qty = 50
    AND m.certificate = 'UA/3186/03/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01DA08"]'::jsonb, 'UA/3186/03/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cd3322c-23f5-420b-9b54-33059e2a5fa3'', ''ІЗО-МІК® 5 мг'', ''BRAND'', ''{"name": "ТОВ НВФ \"Мікрохім\"", "country": " Україна"}'', ''["C01DA08"]'', true, ''SUBLINGVAL_TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/3186/03/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''9ff7e1bc-89c4-4966-a125-550dc5675fe7'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "17.89"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ebaf9dd6-bac5-435f-a2a6-13d8fc1b7057'', ''{"type": "FIXED", "reimbursement_amount": "17.89"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 6.25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6f2ccc49-3486-4193-957a-11565ab5888a'', ''Карведилол 6.25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''66a64f4e-78e2-4a9b-bb78-716913870b29'', ''{"numerator_unit": "MG", "numerator_value": "6.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 6.25
    AND m.name = 'КАРВЕДИЛОЛ АУРОБІНДО'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15796/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/15796/01/01', '2022-02-15'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''51179b27-1ce1-416d-8261-1b367d9b9d9d'', ''КАРВЕДИЛОЛ АУРОБІНДО'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15796/01/01'', ''2022-02-15'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''2fe0a397-2203-4998-86e1-a9c32d2f04f3'', ''{"numerator_unit": "MG", "numerator_value": "6.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "12.18"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''7a63b4c9-771d-4719-ad9d-c9604c3cdbfe'', ''{"type": "FIXED", "reimbursement_amount": "12.18"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 6.25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6f2ccc49-3486-4193-957a-11565ab5888a'', ''Карведилол 6.25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7684dc88-31ec-49cb-ac05-ad59e4e4a527'', ''{"numerator_unit": "MG", "numerator_value": "6.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 6.25
    AND m.name = 'КАРВІДЕКС'
    AND m.package_qty = 20
    AND m.certificate = 'UA/8820/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/8820/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c8f87ab4-7d1a-4408-ba1c-c73d5ccb4ce4'', ''КАРВІДЕКС'', ''BRAND'', ''{"name": "Д-р Редді''''с Лабораторіс Лтд", "country": " Індія"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/8820/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''f03b00d9-f767-4993-ab10-72652ea07282'', ''{"numerator_unit": "MG", "numerator_value": "6.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''53c4053b-2491-43bb-b75f-4d9361287bca'', ''{"type": "FIXED", "reimbursement_amount": "8.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 6.25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6f2ccc49-3486-4193-957a-11565ab5888a'', ''Карведилол 6.25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''703d2546-74ab-466e-b3ab-39372795ff19'', ''{"numerator_unit": "MG", "numerator_value": "6.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 6.25
    AND m.name = 'КАРВІУМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/13976/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/13976/01/01', '2019-10-24'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''67e1c82b-1473-43b0-9ca2-3ebef572e1b4'', ''КАРВІУМ'', ''BRAND'', ''{"name": "С.К. Лабормед-Фарма С.А.", "country": " Румунія"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/13976/01/01'', ''2019-10-24'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''5e9a7916-2ece-4f11-91ea-ce8c6621c586'', ''{"numerator_unit": "MG", "numerator_value": "6.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "12.18"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''5fd4553d-944f-42fc-8505-577901341778'', ''{"type": "FIXED", "reimbursement_amount": "12.18"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 6.25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6f2ccc49-3486-4193-957a-11565ab5888a'', ''Карведилол 6.25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''855e63b1-def6-487a-bc7c-92808e8fade7'', ''{"numerator_unit": "MG", "numerator_value": "6.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 6.25
    AND m.name = 'ТАЛЛІТОН®'
    AND m.package_qty = 28
    AND m.certificate = 'UA/0947/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/0947/01/01', '2019-04-02'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ef73ca00-6936-4bbb-9d88-60db2165ae15'', ''ТАЛЛІТОН®'', ''BRAND'', ''{"name": "ЗАТ Фармацевтичний завод ЕГІС", "country": " Угорщина"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/0947/01/01'', ''2019-04-02'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''03f75f86-4a41-476e-b7fe-c005a0136dcb'', ''{"numerator_unit": "MG", "numerator_value": "6.25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.37"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''4505e55d-5465-44bf-b566-a642e99b8292'', ''{"type": "FIXED", "reimbursement_amount": "11.37"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 12.5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d4b04355-6688-4809-8b9f-416e9d8195a6'', ''Карведилол 12.5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''28947519-4718-42f1-bc94-aa68c062679f'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 12.5
    AND m.name = 'КАРВЕДИЛОЛ АУРОБІНДО'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15796/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/15796/01/02', '2022-02-15'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''f9c1c1a5-eb10-4968-aa96-18127b6072d8'', ''КАРВЕДИЛОЛ АУРОБІНДО'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15796/01/02'', ''2022-02-15'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3cacbd7f-b143-413b-a961-ecc44b6a698c'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "24.36"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''59e6d24d-722a-4dec-bc73-c93122662228'', ''{"type": "FIXED", "reimbursement_amount": "24.36"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 12.5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d4b04355-6688-4809-8b9f-416e9d8195a6'', ''Карведилол 12.5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''04ed6c4e-600f-49bf-9628-6d0792b2ec5f'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 12.5
    AND m.name = 'КАРВЕДИЛОЛ-КВ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/8685/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/8685/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''f2890527-45b1-4580-9d45-d6c85bc8a31e'', ''КАРВЕДИЛОЛ-КВ'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/8685/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0ceac76e-1831-4c4d-9a93-0ae76ba4dced'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "24.36"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''8b671d33-ccd4-424e-b14c-a8253d3ee5d6'', ''{"type": "FIXED", "reimbursement_amount": "24.36"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 12.5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d4b04355-6688-4809-8b9f-416e9d8195a6'', ''Карведилол 12.5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''36a72023-6b09-4dc8-94aa-046b16d9adc3'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 12.5
    AND m.name = 'КАРВІДЕКС'
    AND m.package_qty = 20
    AND m.certificate = 'UA/8820/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/8820/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c8a79f5a-7a97-4e80-ac47-2dc525d26d95'', ''КАРВІДЕКС'', ''BRAND'', ''{"name": "Д-р Редді''''с Лабораторіс Лтд", "country": " Індія"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/8820/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''dea52118-1057-43ec-88f7-2fc9e1d460c2'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d2ba3b3c-2848-486c-ba4e-99c3006dcab2'', ''{"type": "FIXED", "reimbursement_amount": "16.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 12.5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d4b04355-6688-4809-8b9f-416e9d8195a6'', ''Карведилол 12.5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''4d37016d-48b0-4301-a434-262618cc4820'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 12.5
    AND m.name = 'КАРВІУМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/13976/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/13976/01/02', '2019-10-24'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b5f75b98-b9c0-453b-b321-5e85cedc0a7c'', ''КАРВІУМ'', ''BRAND'', ''{"name": "С.К. Лабормед-Фарма С.А.", "country": " Румунія"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/13976/01/02'', ''2019-10-24'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''383f9284-1e55-40c0-8c0d-2eb7bb5e5893'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "24.36"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''abc60f7d-d4e7-4bea-93a9-cd4ae09b1bef'', ''{"type": "FIXED", "reimbursement_amount": "24.36"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 12.5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d4b04355-6688-4809-8b9f-416e9d8195a6'', ''Карведилол 12.5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''705914ff-9acc-4610-b40b-7592096e18cf'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 12.5
    AND m.name = 'КОРВАЗАН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1371/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/1371/01/02', '2019-06-27'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''aaf64fcd-e56a-45b0-90a5-be668f830241'', ''КОРВАЗАН®'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1371/01/02'', ''2019-06-27'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''14813e7a-2094-4cee-8005-5181ac3bc05c'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "24.36"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''6552cc5e-0253-47a5-bec5-eb7c5983e30d'', ''{"type": "FIXED", "reimbursement_amount": "24.36"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 12.5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d4b04355-6688-4809-8b9f-416e9d8195a6'', ''Карведилол 12.5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c7ba84b0-43ca-43c8-b0e1-c89145660fe2'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 12.5
    AND m.name = 'ТАЛЛІТОН®'
    AND m.package_qty = 28
    AND m.certificate = 'UA/0947/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/0947/01/02', '2019-04-02'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''aa019d7d-6082-4147-bcfd-26a80fdeb1d3'', ''ТАЛЛІТОН®'', ''BRAND'', ''{"name": "ЗАТ Фармацевтичний завод ЕГІС", "country": " Угорщина"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/0947/01/02'', ''2019-04-02'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ef1ec219-a000-4bd6-9099-16f773277afd'', ''{"numerator_unit": "MG", "numerator_value": "12.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.74"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''8a0ecb54-8ce3-4506-a18f-7bd13f43067f'', ''{"type": "FIXED", "reimbursement_amount": "22.74"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''895671ee-f705-4c5a-b3c2-73be13773661'', ''Карведилол 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''4c68e68d-410b-4a9c-b35e-e26885ef484f'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'КАРВЕДИЛОЛ АУРОБІНДО'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15796/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/15796/01/03', '2022-02-15'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''7248b1d9-45de-4b3c-bf53-a51c5aa1a9d7'', ''КАРВЕДИЛОЛ АУРОБІНДО'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15796/01/03'', ''2022-02-15'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''e824b8f6-d25b-4243-8245-238eb4e77ab5'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.73"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''65960e13-5837-4c82-8a3e-e73ac755cba9'', ''{"type": "FIXED", "reimbursement_amount": "48.73"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''895671ee-f705-4c5a-b3c2-73be13773661'', ''Карведилол 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''6f0741c3-0e49-4397-8ae1-858362846095'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'КАРВЕДИЛОЛ-КВ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/8685/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/8685/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0e851fe3-a63c-498b-a5f0-17877a5fb4f9'', ''КАРВЕДИЛОЛ-КВ'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/8685/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''de7240b3-77e4-411c-8a31-2c7ead94d101'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.73"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''361aafda-ebf6-410b-ab65-208c9142db20'', ''{"type": "FIXED", "reimbursement_amount": "48.73"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''895671ee-f705-4c5a-b3c2-73be13773661'', ''Карведилол 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ca267df7-2e06-4ed3-b1e6-11d42d801e74'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'КАРВІДЕКС'
    AND m.package_qty = 20
    AND m.certificate = 'UA/8820/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/8820/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''010463a5-2888-41b9-a3c8-31d653342577'', ''КАРВІДЕКС'', ''BRAND'', ''{"name": "Д-р Редді''''с Лабораторіс Лтд", "country": " Індія"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/8820/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''22605160-5c85-4d12-8c36-009738342155'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "32.49"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a7e4fd67-a5e1-49b2-98de-d58c9cb45df1'', ''{"type": "FIXED", "reimbursement_amount": "32.49"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''895671ee-f705-4c5a-b3c2-73be13773661'', ''Карведилол 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''859649ac-e045-4490-b80a-096f079e91c3'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'КАРВІУМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/13976/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/13976/01/03', '2019-10-24'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''82fbd48a-4e27-4a98-bf46-2a65dc0b00c3'', ''КАРВІУМ'', ''BRAND'', ''{"name": "С.К. Лабормед-Фарма С.А.", "country": " Румунія"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/13976/01/03'', ''2019-10-24'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a82336cd-ef3e-4d39-8600-557ef5e9af14'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.73"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''63a12acb-64f7-4521-9f3f-e0a2ac5f7c62'', ''{"type": "FIXED", "reimbursement_amount": "48.73"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''895671ee-f705-4c5a-b3c2-73be13773661'', ''Карведилол 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7e8bdb9d-009b-4a46-9270-6065a35371ff'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'КОРВАЗАН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1371/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/1371/01/01', '2019-06-27'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c21ef377-5689-46b5-b45c-2682f95baa34'', ''КОРВАЗАН®'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1371/01/01'', ''2019-06-27'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''edc27a7a-4fa1-4ca9-b14a-75d30ed37658'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.73"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a34369ca-bac6-4943-b018-9a7f37bc030e'', ''{"type": "FIXED", "reimbursement_amount": "48.73"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Carvedilol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Карведилол 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''895671ee-f705-4c5a-b3c2-73be13773661'', ''Карведилол 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e814d9c0-4c77-4434-a88a-15e579ab0b1d'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'ТАЛЛІТОН®'
    AND m.package_qty = 28
    AND m.certificate = 'UA/0947/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AG02"]'::jsonb, 'UA/0947/01/03', '2019-04-02'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''78c09093-41e8-4c5b-8cfb-ed624896666a'', ''ТАЛЛІТОН®'', ''BRAND'', ''{"name": "ЗАТ Фармацевтичний завод ЕГІС", "country": " Угорщина"}'', ''["C07AG02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/0947/01/03'', ''2019-04-02'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3a70cd39-0523-414b-bc04-f3ac531ad78a'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "45.48"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b49a8fd9-74b0-44f8-8c2c-43bec7177658'', ''{"type": "FIXED", "reimbursement_amount": "45.48"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''281b6183-c3c3-43c7-a539-620717f7a571'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'АТЕРОКАРД'
    AND m.package_qty = 10
    AND m.certificate = 'UA/3926/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/3926/01/01', '2020-04-02'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1b5b5d47-1d4c-4fb6-966f-c331d3c48df7'', ''АТЕРОКАРД'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 10, 10, ''UA/3926/01/01'', ''2020-04-02'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''4e0ad90e-23eb-4b3d-9aaa-b937291d0f78'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.01"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3e4dff55-9da1-451f-9441-7747c87da2d5'', ''{"type": "FIXED", "reimbursement_amount": "16.01"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''635c2c35-109d-4c20-87af-72f044e31d02'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОПІДОГРЕЛЬ'
    AND m.package_qty = 10
    AND m.certificate = 'UA/3924/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/3924/01/01', '2020-09-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''09d4e8e1-28e7-4612-8fd9-171101582017'', ''КЛОПІДОГРЕЛЬ'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Дослідний завод \"ГНЦЛС\"", "country": " Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 10, 10, ''UA/3924/01/01'', ''2020-09-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3f8b5788-2525-48f6-bdc0-0df761661190'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.01"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ea88dc77-f87f-4ee0-a4cd-9de6020facdf'', ''{"type": "FIXED", "reimbursement_amount": "16.01"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''fec491a0-34a0-48c7-99e2-fc5376b82a56'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'АГРЕЛЬ 75 МГ'
    AND m.package_qty = 28
    AND m.certificate = 'UA/14800/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/14800/01/01', '2020-12-29'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3abbf79f-f77b-49f0-96bd-72f5b82446df'', ''АГРЕЛЬ 75 МГ'', ''BRAND'', ''{"name": "Асіно Фарма АГ", "country": " Швейцарія"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/14800/01/01'', ''2020-12-29'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1bc7bf6f-0a78-4403-8a8f-1ad9b55a479c'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "44.82"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''4a062204-ca21-4487-ac85-5206d6a78ee8'', ''{"type": "FIXED", "reimbursement_amount": "44.82"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''444e81f7-42d3-4d3a-b288-a32d12c62e37'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'ПЛАТОГРІЛ®'
    AND m.package_qty = 28
    AND m.certificate = 'UA/11433/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/11433/01/01', '2021-03-31'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b23f7d50-bdaa-42ba-8eec-084b4c5b4b48'', ''ПЛАТОГРІЛ®'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/11433/01/01'', ''2021-03-31'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''daf92118-d2cd-4b1a-95cb-b5a9bb0b0eec'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "44.82"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d6d32925-be73-4e34-8127-db91dfb6f4f3'', ''{"type": "FIXED", "reimbursement_amount": "44.82"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''dc057916-0040-46f2-bed6-1e3bf13c1fa8'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'АТРОГРЕЛ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/6567/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/6567/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''df577dd1-b313-4f46-b766-7a74a35cb62e'', ''АТРОГРЕЛ'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": "Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/6567/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''bf535f42-7651-4346-baaa-2efaebe3caca'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d16f8097-2ea0-47bb-8d7f-41ce58a56168'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c1b632a5-a965-4a1b-bc66-02d68d6157be'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОДІЯ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/13673/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/13673/01/01', '2019-06-16'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1f1200b3-440f-418d-8a5a-64a00e3e7414'', ''КЛОДІЯ'', ''BRAND'', ''{"name": "ФАРМАТЕН С.А.", "country": " Греція"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/13673/01/01'', ''2019-06-16'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''303b2eb7-5780-4d2d-8472-68aed48c81e3'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b28bf998-153b-4565-b870-29b507430b72'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''b8111e4a-2735-47ee-8a96-dfce2e9f18ae'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОПІДОГРЕЛЬ-ЗЕНТІВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11825/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/11825/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b7cecf15-8008-4f85-922b-6bcff95ccc89'', ''КЛОПІДОГРЕЛЬ-ЗЕНТІВА'', ''BRAND'', ''{"name": "Санофі Вінтроп Індастріа", "country": " Франція"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11825/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ea312c83-1156-42b9-83be-4d72f4a3fc95'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''9633a4b3-8bfb-4b38-b6c4-596fc7c92a2c'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''20c83655-b99e-4f41-b57c-6271e68b2f3b'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОПІДОГРЕЛЬ-САНОФІ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11825/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/11825/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''450ac780-fca5-4c07-af3f-c7114923f2f4'', ''КЛОПІДОГРЕЛЬ-САНОФІ'', ''BRAND'', ''{"name": "Санофі Вінтроп Індастріа", "country": " Франція"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11825/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''021117ef-7195-4cfa-bc13-f6594a40dd0c'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a620e749-d83b-49fc-adb9-911e9abcc4a7'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''53cf42d9-64d3-49a0-af45-ff44a6930252'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОПІДОГРЕЛ-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14007/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/14007/01/01', '2019-10-31'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''35608d6d-7299-4479-9770-ae1f8dd7a47b'', ''КЛОПІДОГРЕЛ-ТЕВА'', ''BRAND'', ''{"name": "Тева Фармацевтікал Індастріз Лтд.", "country": " Ізраїль"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14007/01/01'', ''2019-10-31'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''f64d77b3-4592-4d0b-8af5-f3f26d79ead1'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''375123b2-1da7-43ae-a619-0723a69193a5'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''a39c801c-d2b6-46d9-80d3-6cf2b451b35b'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОПІДОГРЕЛЬ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3924/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/3924/01/01', '2020-09-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5f525423-00ce-4eba-815f-62e23857d06e'', ''КЛОПІДОГРЕЛЬ'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Дослідний завод \"ГНЦЛС\"", "country": " Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3924/01/01'', ''2020-09-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''5540e719-7142-41cd-895d-a3a05ca29b5b'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''f4b530d1-f8e6-441c-8779-0601171424d9'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''465d7f5b-0da1-4408-9ac6-1050dab19d7b'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОПІДОГРЕЛЬ-ФАРМЕКС'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11699/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/11699/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''76ea2777-7d52-40eb-b2b2-3008ecb5a75a'', ''КЛОПІДОГРЕЛЬ-ФАРМЕКС'', ''BRAND'', ''{"name": "ТОВ \"ФАРМЕКС ГРУП\"", "country": " Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11699/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0cd470b7-acf9-4611-8302-dd90ce6906cf'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a545666c-b222-4a7b-bd4c-e3ad688d1beb'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''0a1103b0-166f-45a0-a820-c7e68fd157dc'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'ЛОПІРЕЛ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11636/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/11636/01/01', '2021-07-19'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b390a42b-dc34-4db3-bb20-31cf36474dc4'', ''ЛОПІРЕЛ'', ''BRAND'', ''{"name": "Актавіс ЛТД", "country": " Мальта"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11636/01/01'', ''2021-07-19'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''cac9b0a0-90e2-436c-bd98-1b919f92a7f2'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''59f8f6da-74fa-494a-923c-9d3fe2ba5756'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''73abb7ed-4dff-4a34-b67c-b879105d7b41'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'МЕДОГРЕЛЬ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/12149/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/12149/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''071ea17d-20fd-4476-99b2-23fdf4e6d007'', ''МЕДОГРЕЛЬ'', ''BRAND'', ''{"name": "Актавіс ЛТД", "country": " Мальта"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/12149/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''2977a30b-c53f-4316-bcc4-b027f52effd0'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''136085f2-fea4-4764-bf74-3ea3b6882d0e'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''485819fe-6121-4667-8af7-c784b59a9ce2'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'ПЛАГРИЛ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/10625/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/10625/01/01', '2019-08-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e8cb8232-9e3c-471f-ad1b-fcf636ffb9ae'', ''ПЛАГРИЛ'', ''BRAND'', ''{"name": "Д-р Редді''''с Лабораторіс Лтд", "country": " Індія"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/10625/01/01'', ''2019-08-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''bef356c3-5099-4263-bef8-ab5cf0fd7621'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''c0c9791f-b413-4022-b4f6-b58d0a2a5545'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''de87bf8c-9b57-4488-ba64-c90818b51537'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'ТРОМБОНЕТ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/4315/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/4315/01/01', '2021-02-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0de2a3c7-7183-4b69-9b3e-a7abb747d36d'', ''ТРОМБОНЕТ®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/4315/01/01'', ''2021-02-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3930f4cb-1733-44ef-a1ec-ad3c84b5c9ea'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''04343d4a-225f-4384-bf78-fa453b299fae'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8895b721-517a-465e-ab07-5d57817da0ae'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'ФЛАМОГРЕЛЬ 75'
    AND m.package_qty = 30
    AND m.certificate = 'UA/7441/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/7441/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fd4cb0d0-14cd-44b9-831f-d98600e95181'', ''ФЛАМОГРЕЛЬ 75'', ''BRAND'', ''{"name": "Фламінго Фармасьютикалс Лтд.", "country": " Індія"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/7441/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''981022da-9571-48b5-ada8-b1175e500f28'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''2bd05aa2-33ac-47a0-b277-1e5b945fc9d0'', ''{"type": "FIXED", "reimbursement_amount": "48.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''eaf0fd89-e7fe-4b2e-9041-4c39f5867a70'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'АТЕРОКАРД'
    AND m.package_qty = 40
    AND m.certificate = 'UA/3926/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/3926/01/01', '2020-04-02'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5c6eb6d2-a51d-43b4-9971-b9ea0d5c580e'', ''АТЕРОКАРД'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 40, 40, ''UA/3926/01/01'', ''2020-04-02'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3ac910db-cc6c-43c4-9053-018234a62071'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "64.03"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''1a8f657a-f980-4958-b1bc-d7068df0162e'', ''{"type": "FIXED", "reimbursement_amount": "64.03"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''2d10215f-2c19-42e7-8bd5-7861602881d1'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'АТРОГРЕЛ'
    AND m.package_qty = 60
    AND m.certificate = 'UA/6567/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/6567/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''78ca0d94-690c-4d9f-89fe-f06f0877a325'', ''АТРОГРЕЛ'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": "Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/6567/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''78ed9dc1-1a4e-4823-855e-207b14d1426d'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "96.04"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''75fc6445-1423-4020-940a-60775896d6b2'', ''{"type": "FIXED", "reimbursement_amount": "96.04"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''5bd19080-09ea-4cbd-aa79-1f31054497c1'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'ТРОМБОНЕТ®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/4315/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/4315/01/01', '2021-02-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9eeb9318-effe-44b1-bd71-8486f44f7071'', ''ТРОМБОНЕТ®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/4315/01/01'', ''2021-02-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''74ba046e-47fc-42c8-b5f2-dfd752a86f2c'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "96.04"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''6d4938d7-e7b2-4faa-9309-f1e8778e1d56'', ''{"type": "FIXED", "reimbursement_amount": "96.04"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''48744b4e-2d80-4b45-b109-637cc7d0e5ae'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'АТЕРОКАРД'
    AND m.package_qty = 70
    AND m.certificate = 'UA/3926/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/3926/01/01', '2020-04-02'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''cb553b86-d743-4b89-8145-840fa1a8345d'', ''АТЕРОКАРД'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 70, 70, ''UA/3926/01/01'', ''2020-04-02'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''60d75c92-252a-46a2-8d43-96e069153fa8'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "112.05"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''5a6ad159-63bd-45e0-825a-b4f583946ee2'', ''{"type": "FIXED", "reimbursement_amount": "112.05"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7d6c7766-214a-4462-bbeb-bf2114be57c2'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'ПЛАТОГРІЛ®'
    AND m.package_qty = 84
    AND m.certificate = 'UA/11433/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/11433/01/01', '2021-03-31'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a8bd1614-f3a9-4e64-9f43-f149d525bbb2'', ''ПЛАТОГРІЛ®'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 84, 84, ''UA/11433/01/01'', ''2021-03-31'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''20e701ba-f2c2-4036-9a42-689c587bf68a'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "134.45"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''5678c9a4-b250-4676-9880-e0447c1d36b3'', ''{"type": "FIXED", "reimbursement_amount": "134.45"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''b8db8663-1e05-4171-923a-770e3efc399d'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОПІДОГРЕЛЬ-ЗЕНТІВА'
    AND m.package_qty = 90
    AND m.certificate = 'UA/11825/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/11825/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''afdec041-fd81-491a-ae20-abc8e67e3760'', ''КЛОПІДОГРЕЛЬ-ЗЕНТІВА'', ''BRAND'', ''{"name": "Санофі Вінтроп Індастріа", "country": " Франція"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/11825/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''05075465-7c59-4cac-b050-3b02af1c2070'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "144.06"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''5f6c39b5-6122-4909-bd4e-117830e3eeb2'', ''{"type": "FIXED", "reimbursement_amount": "144.06"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''9ab0c867-bde1-4e28-9dcf-70f979a95cd9'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОПІДОГРЕЛЬ-САНОФІ'
    AND m.package_qty = 90
    AND m.certificate = 'UA/11825/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/11825/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9c8fd6f0-4a82-4008-a9a8-91a2110a5297'', ''КЛОПІДОГРЕЛЬ-САНОФІ'', ''BRAND'', ''{"name": "Санофі Вінтроп Індастріа", "country": " Франція"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/11825/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''014793d4-0c28-4215-9e5f-3ca146b70c6f'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "144.06"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''da868893-b68f-44b2-817b-dd5c90b9b81f'', ''{"type": "FIXED", "reimbursement_amount": "144.06"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8c67b544-512a-4ed7-ad61-0d1130904fa5'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'КЛОПІДОГРЕЛ-ТЕВА'
    AND m.package_qty = 90
    AND m.certificate = 'UA/14007/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/14007/01/01', '2019-10-31'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b6e2c772-0f7b-4742-88f7-285a333817d2'', ''КЛОПІДОГРЕЛ-ТЕВА'', ''BRAND'', ''{"name": "Тева Фармацевтікал Індастріз Лтд.", "country": " Ізраїль"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/14007/01/01'', ''2019-10-31'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0c171498-9de6-43f8-8bf7-a1a75556aae6'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "144.06"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''4c68f125-3958-4c61-90a2-00ef00b211fc'', ''{"type": "FIXED", "reimbursement_amount": "144.06"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''b5029aff-90c4-4b73-bebe-4630b671a512'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'ЛОПІРЕЛ'
    AND m.package_qty = 90
    AND m.certificate = 'UA/11636/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/11636/01/01', '2021-07-19'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8d2be6a0-1cc6-4b6e-8b20-3c1285ac786d'', ''ЛОПІРЕЛ'', ''BRAND'', ''{"name": "Актавіс ЛТД", "country": " Мальта"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/11636/01/01'', ''2021-07-19'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''619ef9d0-78f5-42fb-a2eb-36c2768a115b'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "144.06"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''365b6c8b-8f47-4958-8f27-eff8f2b1608d'', ''{"type": "FIXED", "reimbursement_amount": "144.06"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Clopidogrel' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Клопідогрель 75 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''502c2fda-c1fb-43f8-ba21-2d2050eb94e4'', ''Клопідогрель 75 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''37047499-c98c-4cd7-a96b-e21a6f73e48a'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 75
    AND m.name = 'ФЛАМОГРЕЛЬ 75'
    AND m.package_qty = 100
    AND m.certificate = 'UA/7441/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["B01AC04"]'::jsonb, 'UA/7441/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c405105d-c65c-4d1b-945d-fe1b803dd7a3'', ''ФЛАМОГРЕЛЬ 75'', ''BRAND'', ''{"name": "Фламінго Фармасьютикалс Лтд.", "country": " Індія"}'', ''["B01AC04"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 100, 100, ''UA/7441/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''9354a6b3-e427-4e00-ae27-8c8036b248ac'', ''{"numerator_unit": "MG", "numerator_value": "75", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "160.06"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''7da6e7c0-5330-4215-bafa-ee78f8f66692'', ''{"type": "FIXED", "reimbursement_amount": "160.06"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''74703220-0bdd-4457-beba-27085c17dc18'', ''Лозартан 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''97efa4f0-00f0-4aa0-9e0c-4de1bf95a472'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'ЛОЗАРТАН-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16398/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '[" C09CA01"]'::jsonb, 'UA/16398/01/02', '2022-11-08'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1989853f-6634-4b2e-810a-c563df09e6ed'', ''ЛОЗАРТАН-ТЕВА'', ''BRAND'', ''{"name": "АТ Фармацевтичний завод ТЕВА", "country": " Угорщина"}'', ''[" C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16398/01/02'', ''2022-11-08'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''79b75aa1-653a-424c-aa09-f3aa1e6f3b96'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "13.54"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''974d99a0-0ebb-480f-b7bd-74a2d1428e64'', ''{"type": "FIXED", "reimbursement_amount": "13.54"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8bec0351-32e4-4b05-8e3c-24ecf7ceb5c0'', ''Лозартан 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''d94cfe12-b354-4b80-a880-ba34810073b1'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'КЛОСАРТ'
    AND m.package_qty = 28
    AND m.certificate = 'UA/8765/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09CA01"]'::jsonb, 'UA/8765/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d67a4362-85d9-41f2-90c8-3a74c5258457'', ''КЛОСАРТ'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/8765/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''5735b94b-7340-4291-8a2f-34f7049505a7'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "25.27"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''9c6d3e1d-c67e-49cd-9508-6a482ecbca82'', ''{"type": "FIXED", "reimbursement_amount": "25.27"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8bec0351-32e4-4b05-8e3c-24ecf7ceb5c0'', ''Лозартан 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''549808c4-043f-441d-87b2-a959b715a542'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'КЛОСАРТ'
    AND m.package_qty = 84
    AND m.certificate = 'UA/8765/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09CA01"]'::jsonb, 'UA/8765/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6affb867-2009-4abd-86b6-7f9e626be354'', ''КЛОСАРТ'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 84, 84, ''UA/8765/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''f1eee35d-24dc-4b96-8800-05aef777b046'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "75.80"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ec7da78e-48ab-4de0-9fac-661dc3529e92'', ''{"type": "FIXED", "reimbursement_amount": "75.80"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8bec0351-32e4-4b05-8e3c-24ecf7ceb5c0'', ''Лозартан 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7bad4ae2-16e1-4bab-8e98-1811d16ba1d9'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'ЛОЗАП'
    AND m.package_qty = 90
    AND m.certificate = 'UA/3906/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '[" C09CA01"]'::jsonb, 'UA/3906/01/03', '2020-07-27'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''afd96691-a7fd-4dab-a105-15ef48140d83'', ''ЛОЗАП'', ''BRAND'', ''{"name": "АТ \"Санека Фармасьютікалз\"", "country": " Словацька Республіка"}'', ''[" C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/3906/01/03'', ''2020-07-27'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1fd15365-16f9-4d3b-8e4b-fb5a8516f7a0'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "81.21"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''93b06bc4-aed7-4921-bd50-ae6d44b47079'', ''{"type": "FIXED", "reimbursement_amount": "81.21"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8bec0351-32e4-4b05-8e3c-24ecf7ceb5c0'', ''Лозартан 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''5772e1de-0e4b-41c6-b273-6af5f2907c74'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'ЛОЗАРТАН-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16398/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '[" C09CA01"]'::jsonb, 'UA/16398/01/03', '2022-11-08'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''f94770ad-38d7-4ae0-a6b0-f5389b1f7347'', ''ЛОЗАРТАН-ТЕВА'', ''BRAND'', ''{"name": "АТ Фармацевтичний завод ТЕВА", "country": " Угорщина"}'', ''[" C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16398/01/03'', ''2022-11-08'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''7f51c898-647b-4571-8e2f-540fd4ee608f'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "27.07"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''8075f7ae-72fc-496f-af0a-425423975043'', ''{"type": "FIXED", "reimbursement_amount": "27.07"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8bec0351-32e4-4b05-8e3c-24ecf7ceb5c0'', ''Лозартан 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ef5053f0-17bf-4194-b832-e8906dc0cb72'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'ЛОЗАРТАН-ТЕВА'
    AND m.package_qty = 90
    AND m.certificate = 'UA/16398/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '[" C09CA01"]'::jsonb, 'UA/16398/01/03', '2022-11-08'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9e515470-f655-44a4-91b7-90b03d238801'', ''ЛОЗАРТАН-ТЕВА'', ''BRAND'', ''{"name": "АТ Фармацевтичний завод ТЕВА", "country": " Угорщина"}'', ''[" C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/16398/01/03'', ''2022-11-08'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''424c3b86-0ea6-43cd-89f8-cd6c1f0c7f40'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "81.21"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''2b81c835-a9f3-4716-90e7-7c946fcbd0a5'', ''{"type": "FIXED", "reimbursement_amount": "81.21"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8bec0351-32e4-4b05-8e3c-24ecf7ceb5c0'', ''Лозартан 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''aaebed8a-75c8-49c9-9b1e-34f066cc9a5d'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'ЛОТАР®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11210/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09CA02"]'::jsonb, 'UA/11210/01/01', '2021-02-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''dce6a3c0-2ca5-415a-a402-a87103fafe1f'', ''ЛОТАР®'', ''BRAND'', ''{"name": "Алкалоїд АД - Скоп''''є", "country": " Республіка Македонія"}'', ''["C09CA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11210/01/01'', ''2021-02-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''5a9ec4ab-1eb2-46a6-ab1f-2c7e1de83cab'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "27.07"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''8ab4b0ae-2379-443a-b49b-eb7021d0f09f'', ''{"type": "FIXED", "reimbursement_amount": "27.07"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8bec0351-32e4-4b05-8e3c-24ecf7ceb5c0'', ''Лозартан 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8979497a-afdd-4336-b498-ebb528cb5755'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'СЕНТОР'
    AND m.package_qty = 30
    AND m.certificate = 'UA/7042/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '[" C09CA01"]'::jsonb, 'UA/7042/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9126dd22-73d7-4b10-b824-8bc2245f6c7d'', ''СЕНТОР'', ''BRAND'', ''{"name": "ВАТ \"Гедеон Ріхтер\"", "country": " Угорщина"}'', ''[" C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/7042/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''c596c706-ad9a-4449-b0b7-42a638db3bbf'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "27.07"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''55602ec8-404e-429d-9954-dc6938a57231'', ''{"type": "FIXED", "reimbursement_amount": "27.07"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8bec0351-32e4-4b05-8e3c-24ecf7ceb5c0'', ''Лозартан 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''59ab0002-127c-4f5b-b8e8-5dbb2a57477e'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'ТРОСАН'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11737/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09CA01"]'::jsonb, 'UA/11737/01/02', '2021-09-15'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''aa971be7-4b2c-44f4-ba47-0e07c8cd3136'', ''ТРОСАН'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11737/01/02'', ''2021-09-15'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''45e56808-81ae-4dee-9c7d-da557ed00ac9'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "27.07"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d2d6fd34-764d-4fcd-8d40-b02c4eef1815'', ''{"type": "FIXED", "reimbursement_amount": "27.07"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''79d156ee-efea-4c23-a090-cd061a00e84b'', ''Лозартан 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''76b1d42d-81c8-4c50-a112-bcb6ef8473f1'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'КЛОСАРТ'
    AND m.package_qty = 100
    AND m.certificate = 'UA/8765/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09CA01"]'::jsonb, 'UA/8765/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d0fa20b0-e33c-4607-8f8b-d13a397ecbfa'', ''КЛОСАРТ'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 100, 100, ''UA/8765/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ac703e6d-19e7-4a94-aad0-848bac4bcf36'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "180.47"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''c333a795-4914-4cd2-b1f4-ae9154a7a673'', ''{"type": "FIXED", "reimbursement_amount": "180.47"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''79d156ee-efea-4c23-a090-cd061a00e84b'', ''Лозартан 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''aa288958-884b-46e2-8354-227305d38554'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'КЛОСАРТ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/8765/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09CA01"]'::jsonb, 'UA/8765/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1eb1e484-7b1c-4838-8650-e6809113cdef'', ''КЛОСАРТ'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/8765/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''6a986747-40f1-4a81-902d-3e34d1a29269'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "54.14"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e7396a91-4b99-4181-a5ee-0605b804b4ce'', ''{"type": "FIXED", "reimbursement_amount": "54.14"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''79d156ee-efea-4c23-a090-cd061a00e84b'', ''Лозартан 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''246654b8-9928-4e34-9a68-28c7483df3c4'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'ЛОЗАП'
    AND m.package_qty = 90
    AND m.certificate = 'UA/3906/01/04';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '[" C09CA01"]'::jsonb, 'UA/3906/01/04', '2020-07-27'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9d1d763c-b08e-4b05-9840-eae7db5e24d0'', ''ЛОЗАП'', ''BRAND'', ''{"name": "АТ \"Санека Фармасьютікалз\"", "country": " Словацька Республіка"}'', ''[" C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/3906/01/04'', ''2020-07-27'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''44b743c9-9926-4037-bc26-dd20c2db1054'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "162.43"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''2cbe5023-313f-4a64-abf8-543bae4bf872'', ''{"type": "FIXED", "reimbursement_amount": "162.43"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''79d156ee-efea-4c23-a090-cd061a00e84b'', ''Лозартан 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''df62b40b-78c9-40a3-a111-cd97ee6041e0'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'ЛОЗАП'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3906/01/04';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '[" C09CA01"]'::jsonb, 'UA/3906/01/04', '2020-07-27'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c7422b53-f335-4782-b65e-384d34b47ccb'', ''ЛОЗАП'', ''BRAND'', ''{"name": "АТ \"Санека Фармасьютікалз\"", "country": " Словацька Республіка"}'', ''[" C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3906/01/04'', ''2020-07-27'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d66ba062-efff-452c-b7a5-855803199d82'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "54.14"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''f10cabf9-56ae-4c65-9306-696d2f40f807'', ''{"type": "FIXED", "reimbursement_amount": "54.14"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''79d156ee-efea-4c23-a090-cd061a00e84b'', ''Лозартан 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e0866bab-9642-45e8-a292-900de34fbd77'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'ЛОЗАРТАН-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16398/01/04';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '[" C09CA01"]'::jsonb, 'UA/16398/01/04', '2022-11-08'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ba46d9d6-8eab-43d4-b674-75aaa055f451'', ''ЛОЗАРТАН-ТЕВА'', ''BRAND'', ''{"name": "АТ Фармацевтичний завод ТЕВА", "country": " Угорщина"}'', ''[" C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16398/01/04'', ''2022-11-08'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''57a59d8f-ead5-45a4-ae6d-351ed7f9d225'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "54.14"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''0c64c055-0106-49a4-b1a9-4635cfddef2d'', ''{"type": "FIXED", "reimbursement_amount": "54.14"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''79d156ee-efea-4c23-a090-cd061a00e84b'', ''Лозартан 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''768827bd-0d3b-4066-b2ba-5f21fd62edbc'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'ЛОТАР®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11210/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09CA03"]'::jsonb, 'UA/11210/01/02', '2021-02-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''eea32fbd-873e-4eca-a472-f0e2716724c2'', ''ЛОТАР®'', ''BRAND'', ''{"name": "Алкалоїд АД - Скоп''''є", "country": " Республіка Македонія"}'', ''["C09CA03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11210/01/02'', ''2021-02-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''145770ab-c4b6-43e2-b0d3-cb92dd94945b'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "54.14"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''56f8640b-3aef-4ee7-b902-3e1c984d5a64'', ''{"type": "FIXED", "reimbursement_amount": "54.14"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''79d156ee-efea-4c23-a090-cd061a00e84b'', ''Лозартан 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''439f2884-8625-41de-bc60-1b603301a27a'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'СЕНТОР'
    AND m.package_qty = 30
    AND m.certificate = 'UA/7042/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '[" C09CA01"]'::jsonb, 'UA/7042/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8b4efcfb-2474-4647-b53f-cb63bd2dfe77'', ''СЕНТОР'', ''BRAND'', ''{"name": "ВАТ \"Гедеон Ріхтер\"", "country": " Угорщина"}'', ''[" C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/7042/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''4d3ae4f9-1160-42b6-89d4-e49050f0693a'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "54.14"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b1a02346-600e-4bd2-9ae2-fa80e31b8a56'', ''{"type": "FIXED", "reimbursement_amount": "54.14"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Losartan' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Лозартан 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''79d156ee-efea-4c23-a090-cd061a00e84b'', ''Лозартан 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7a47e58a-2e20-4e4f-af65-d884e9f4ddd2'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'ТРОСАН'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11737/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C09CA01"]'::jsonb, 'UA/11737/01/03', '2021-09-15'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5758d1a8-dfe0-4aa8-8bf3-4c9d77f37eb9'', ''ТРОСАН'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C09CA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11737/01/03'', ''2021-09-15'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''5c91f4e0-d66e-443c-855a-cf50fc6a4843'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "54.14"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''eb267a46-d96a-4f64-b1eb-794cdc3f525f'', ''{"type": "FIXED", "reimbursement_amount": "54.14"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метопролол 25 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c2b8d3e0-e7e3-496a-96d1-054981c85712'', ''Метопролол 25 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''b5bc0580-2ff1-478a-b00b-8265bd39ad2a'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 25
    AND m.name = 'ЕГІЛОК®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/9635/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB02"]'::jsonb, 'UA/9635/01/01', '2019-07-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8338834f-9db8-4110-8bb5-c6a45ebaff44'', ''ЕГІЛОК®'', ''BRAND'', ''{"name": "ЗАТ Фармацевтичний завод ЕГІС", "country": " Угорщина"}'', ''["C07AB02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/9635/01/01'', ''2019-07-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3bd8d06e-3c9a-4a36-ad8c-ac7fd60a34ad'', ''{"numerator_unit": "MG", "numerator_value": "25", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.06"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''fcfd7b72-3ed2-416c-b808-aa6ad79ffecd'', ''{"type": "FIXED", "reimbursement_amount": "11.06"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метопролол 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fbc2b76e-bc46-453b-b30d-ce345c09cf3f'', ''Метопролол 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''47bc09ae-c924-4dd5-8d0c-8c4301a4d83b'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'ЕГІЛОК®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/9635/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB02"]'::jsonb, 'UA/9635/01/02', '2019-07-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''71b29abc-d6d2-465c-99d4-2c1ccabe7587'', ''ЕГІЛОК®'', ''BRAND'', ''{"name": "ЗАТ Фармацевтичний завод ЕГІС", "country": " Угорщина"}'', ''["C07AB02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/9635/01/02'', ''2019-07-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''c152bab9-0ece-4a9f-bdd2-7ec3e1aacff9'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3ef47f4c-6965-4202-a948-043b23321cec'', ''{"type": "FIXED", "reimbursement_amount": "22.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метопролол 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fbc2b76e-bc46-453b-b30d-ce345c09cf3f'', ''Метопролол 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''88f7b766-d9d6-4f45-adab-7148245da98b'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'МЕТОПРОЛОЛ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/2548/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB02"]'::jsonb, 'UA/2548/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9eb9cc86-44a3-4965-803f-88ce6909c634'', ''МЕТОПРОЛОЛ'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["C07AB02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/2548/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''05721489-080c-4bbe-b647-a20ef6213102'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.06"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''293fa84b-d5eb-4f36-afb8-acc38770938c'', ''{"type": "FIXED", "reimbursement_amount": "11.06"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метопролол 50 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fbc2b76e-bc46-453b-b30d-ce345c09cf3f'', ''Метопролол 50 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''6b76106c-b67a-4eea-b24e-a8c9609f1f0a'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'МЕТОПРОЛОЛУ ТАРТРАТ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/6755/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB02"]'::jsonb, 'UA/6755/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fb1e66d7-bc9c-41a8-9222-3f749a3cd86d'', ''МЕТОПРОЛОЛУ ТАРТРАТ'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C07AB02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/6755/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''8ed4eb0c-50a4-401d-881e-2b2715f8fdf3'', ''{"numerator_unit": "MG", "numerator_value": "50", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "7.37"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''5551ae31-567e-4d29-8f21-9abcdbe5a4f9'', ''{"type": "FIXED", "reimbursement_amount": "7.37"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метопролол 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9544ef75-e519-49e6-9fb0-a7e604edca11'', ''Метопролол 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''2e6340e0-cffc-4615-989e-da7ed6791034'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'ЕГІЛОК®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/9635/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB02"]'::jsonb, 'UA/9635/01/03', '2019-07-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''026ce8df-c4f2-49ae-aeda-ecaedbb0b3af'', ''ЕГІЛОК®'', ''BRAND'', ''{"name": "ЗАТ Фармацевтичний завод ЕГІС", "country": " Угорщина"}'', ''["C07AB02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/9635/01/03'', ''2019-07-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''410fa674-2e38-4c55-91ab-8f51cd1725c4'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e5c34294-62d7-4acf-a87b-ea6035b643bc'', ''{"type": "FIXED", "reimbursement_amount": "22.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метопролол 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9544ef75-e519-49e6-9fb0-a7e604edca11'', ''Метопролол 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''61229e74-fa65-4b93-a060-9c9ee4df4d02'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'ЕГІЛОК®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/9635/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB02"]'::jsonb, 'UA/9635/01/03', '2019-07-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''523df50f-8d2b-4da9-bcc6-15ccc02dc865'', ''ЕГІЛОК®'', ''BRAND'', ''{"name": "ЗАТ Фармацевтичний завод ЕГІС", "country": " Угорщина"}'', ''["C07AB02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/9635/01/03'', ''2019-07-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''2979bb1f-5121-42c1-87eb-b97730a91358'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "44.23"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''77b32207-0156-4a78-99ed-8f700c519543'', ''{"type": "FIXED", "reimbursement_amount": "44.23"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метопролол 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9544ef75-e519-49e6-9fb0-a7e604edca11'', ''Метопролол 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''6141901b-029c-4699-a767-77d878fc12d2'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'МЕТОПРОЛОЛ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/2548/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB02"]'::jsonb, 'UA/2548/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''021b24e6-c669-4ea5-8543-87a016436def'', ''МЕТОПРОЛОЛ'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["C07AB02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/2548/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3e3e751a-9313-47a4-852f-5c71089bcf64'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e6a87ff8-b859-4cb5-af45-94957da9abda'', ''{"type": "FIXED", "reimbursement_amount": "22.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метопролол 100 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9544ef75-e519-49e6-9fb0-a7e604edca11'', ''Метопролол 100 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''15328f1e-f01a-43c7-9f73-53aa6a02fdb4'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'МЕТОПРОЛОЛУ ТАРТРАТ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/6755/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB02"]'::jsonb, 'UA/6755/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ab8b078b-4bd0-4399-8fef-1c1cf4e8adfb'', ''МЕТОПРОЛОЛУ ТАРТРАТ'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C07AB02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/6755/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''89a92996-927b-4f35-9a96-1647420d6d2d'', ''{"numerator_unit": "MG", "numerator_value": "100", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "14.74"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''557c942b-3a55-4678-b50c-33a75cf44fa3'', ''{"type": "FIXED", "reimbursement_amount": "14.74"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Glyceryl trinitrate' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Нітрогліцерин 0.5 MG таблетки сублінгвальні ' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c93a1df0-df37-4bd7-a3b4-669da3343454'', ''Нітрогліцерин 0.5 MG таблетки сублінгвальні '', ''INNM_DOSAGE'', TRUE, ''SUBLINGVAL_TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8b775bd9-d45b-4ee6-ad89-e135b0881d07'', ''{"numerator_unit": "MG", "numerator_value": "0.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'SUBLINGVAL_TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 0.5
    AND m.name = 'НІТРОГЛІЦЕРИН'
    AND m.package_qty = 40
    AND m.certificate = 'UA/6393/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01DA02"]'::jsonb, 'UA/6393/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b5d59514-bcc8-432f-bbe9-d6af589de5be'', ''НІТРОГЛІЦЕРИН'', ''BRAND'', ''{"name": "ПрАТ \"Технолог\"", "country": " Україна"}'', ''["C01DA02"]'', true, ''SUBLINGVAL_TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 40, 40, ''UA/6393/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''9fd95b22-db9c-4bc3-ad4b-c32d78c7e1c8'', ''{"numerator_unit": "MG", "numerator_value": "0.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.53"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3bb886e3-6652-4219-a012-e973dc4b04e5'', ''{"type": "FIXED", "reimbursement_amount": "8.53"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Glyceryl trinitrate' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Нітрогліцерин 0.5 MG таблетки сублінгвальні ' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c93a1df0-df37-4bd7-a3b4-669da3343454'', ''Нітрогліцерин 0.5 MG таблетки сублінгвальні '', ''INNM_DOSAGE'', TRUE, ''SUBLINGVAL_TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''12c5e1fc-0f94-4827-9a2a-3d4913e81915'', ''{"numerator_unit": "MG", "numerator_value": "0.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'SUBLINGVAL_TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 0.5
    AND m.name = 'НІТРОГЛІЦЕРИН'
    AND m.package_qty = 40
    AND m.certificate = 'UA/0129/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01DA02"]'::jsonb, 'UA/0129/01/01', '2019-05-19'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''f6862459-2e93-4b17-a48a-eb01b70d607a'', ''НІТРОГЛІЦЕРИН'', ''BRAND'', ''{"name": "ТОВ НВФ \"Мікрохім\"", "country": " Україна"}'', ''["C01DA02"]'', true, ''SUBLINGVAL_TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 40, 40, ''UA/0129/01/01'', ''2019-05-19'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d9fc52d4-341d-4d40-9f4a-9695706ecfa1'', ''{"numerator_unit": "MG", "numerator_value": "0.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.53"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''4844b50e-4409-4619-89ac-567c0eea2fd3'', ''{"type": "FIXED", "reimbursement_amount": "8.53"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Glyceryl trinitrate' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Нітрогліцерин 0.5 MG таблетки сублінгвальні ' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c93a1df0-df37-4bd7-a3b4-669da3343454'', ''Нітрогліцерин 0.5 MG таблетки сублінгвальні '', ''INNM_DOSAGE'', TRUE, ''SUBLINGVAL_TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''944cb90d-ffab-497d-bbe9-ab9e35a0ebf5'', ''{"numerator_unit": "MG", "numerator_value": "0.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'SUBLINGVAL_TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 0.5
    AND m.name = 'НІТРОГЛІЦЕРИН-ЗДОРОВ''Я'
    AND m.package_qty = 40
    AND m.certificate = 'UA/0052/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C01DA02"]'::jsonb, 'UA/0052/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a20d97cb-b193-400a-9dd2-9f963fa7d913'', ''НІТРОГЛІЦЕРИН-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C01DA02"]'', true, ''SUBLINGVAL_TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 40, 40, ''UA/0052/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''e96c57b8-a031-47a5-8d6f-3ef2b5917efd'', ''{"numerator_unit": "MG", "numerator_value": "0.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "8.53"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b20b736b-6211-4952-b7b3-0d8552d1f4ec'', ''{"type": "FIXED", "reimbursement_amount": "8.53"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fea820a8-5862-4d46-8bad-7b3e09fff05c'', ''Симвастатин 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''32ececce-ccdc-4f85-bfa1-b106a926efd7'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'ВАЗОСТАТ-ЗДОРОВ''Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3579/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/3579/01/01', '2020-03-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''2e883235-8d58-467a-948b-56b32b2e14b0'', ''ВАЗОСТАТ-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3579/01/01'', ''2020-03-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''298f797b-d97a-452c-ae37-c9168d581e01'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "23.01"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''2771e507-c8cc-4f4e-9ce6-aae07af37769'', ''{"type": "FIXED", "reimbursement_amount": "23.01"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fea820a8-5862-4d46-8bad-7b3e09fff05c'', ''Симвастатин 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''78328336-0f5a-42d4-9c38-f8c87d617887'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'КАРДАК'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11834/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/11834/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''cc901c51-cfa2-4c72-8370-8ef6afd3146a'', ''КАРДАК'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11834/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''992ee0e2-bcfa-45f0-9843-daabac6d1e6f'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "23.01"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b3cb8765-eef3-4903-8483-3947e90ede75'', ''{"type": "FIXED", "reimbursement_amount": "23.01"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 20 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3e0171b9-153e-4ee7-a568-c3fc004351af'', ''Симвастатин 20 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e859abf9-d91d-4514-9819-71577023f08c'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 20
    AND m.name = 'АЛЛЕСТА®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/4290/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/4290/01/02', '2021-10-04'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0bc57658-09be-44a5-a640-903ad7e7ddb7'', ''АЛЛЕСТА®'', ''BRAND'', ''{"name": "Алкалоїд АД - Скоп''''є", "country": " Республіка Македонія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/4290/01/02'', ''2021-10-04'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''5d2b0d17-a3b8-4b06-91b2-22ffdb04ac2e'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "46.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''970d860c-2815-42bc-909f-1d700a8e5808'', ''{"type": "FIXED", "reimbursement_amount": "46.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 20 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3e0171b9-153e-4ee7-a568-c3fc004351af'', ''Симвастатин 20 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''934e8168-055e-4c00-867a-38d7fe0157c1'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 20
    AND m.name = 'ВАЗИЛІП®'
    AND m.package_qty = 28
    AND m.certificate = 'UA/3792/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/3792/01/02', '2020-09-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''2005897f-f13c-4b76-89f9-c6ea266003b9'', ''ВАЗИЛІП®'', ''BRAND'', ''{"name": "КРКА", "country": " Словенія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/3792/01/02'', ''2020-09-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0ef76d2d-25f3-4493-b427-aa5efd476a07'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "42.95"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''57f0a214-43d5-4213-93f4-0b05966f5e8e'', ''{"type": "FIXED", "reimbursement_amount": "42.95"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 20 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3e0171b9-153e-4ee7-a568-c3fc004351af'', ''Симвастатин 20 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7096c2ab-85e2-4bbe-9c83-2db0ee32fc48'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 20
    AND m.name = 'ВАЗОСТАТ-ЗДОРОВ''Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3579/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/3579/01/02', '2020-03-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''bdaeb5d1-2fff-4e11-a840-2c0cb44c4eb0'', ''ВАЗОСТАТ-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3579/01/02'', ''2020-03-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''476c9214-481c-4f68-8fca-823161a0cdd2'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "46.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b4879407-f086-4188-ae4e-62589a7835cc'', ''{"type": "FIXED", "reimbursement_amount": "46.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 20 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3e0171b9-153e-4ee7-a568-c3fc004351af'', ''Симвастатин 20 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''d2eb1940-eeee-4ba1-8305-3f45cdb7a655'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 20
    AND m.name = 'КАРДАК'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11834/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/11834/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''792e9507-19d4-4a4e-a676-ef5a5eb73bff'', ''КАРДАК'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11834/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''fcdcea3b-7ab5-43ca-b64c-edec92ac92d1'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "46.02"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''df1e5e4e-1288-4db4-903e-01f3b7bb4112'', ''{"type": "FIXED", "reimbursement_amount": "46.02"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 20 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3e0171b9-153e-4ee7-a568-c3fc004351af'', ''Симвастатин 20 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c1938270-c701-426d-8651-cfbdaaa52325'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 20
    AND m.name = 'СИМВАСТАТИН 20 АНАНТА'
    AND m.package_qty = 28
    AND m.certificate = 'UA/14019/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/14019/01/02', '2019-10-31'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e4a06f2b-2d17-4484-989f-63f5a23eea1d'', ''СИМВАСТАТИН 20 АНАНТА'', ''BRAND'', ''{"name": "Марксанс Фарма Лтд.", "country": " Індія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/14019/01/02'', ''2019-10-31'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''83b12db0-5d6f-485d-b6ed-54612e83dc3b'', ''{"numerator_unit": "MG", "numerator_value": "20", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "42.95"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''be0a4e02-3c79-4f09-ac20-1e00c7c6a0c3'', ''{"type": "FIXED", "reimbursement_amount": "42.95"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''40323e74-07d7-498a-892e-3408845bea1b'', ''Симвастатин 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''864a9ca1-bda7-4c63-81c3-af12282dfa40'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'АЛЛЕСТА®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/4290/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/4290/01/03', '2021-10-04'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''22581f7f-8810-4efe-88e5-6e1bd1e2ac77'', ''АЛЛЕСТА®'', ''BRAND'', ''{"name": "Алкалоїд АД - Скоп''''є", "country": " Республіка Македонія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/4290/01/03'', ''2021-10-04'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3af8be87-2b71-4c7c-af4c-811bb5a4e57c'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "92.04"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''2fb34860-fec8-45a3-a321-3c01a762f126'', ''{"type": "FIXED", "reimbursement_amount": "92.04"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''40323e74-07d7-498a-892e-3408845bea1b'', ''Симвастатин 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''726705a3-80a7-4176-b115-48c9a7b362e3'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'ВАЗИЛІП®'
    AND m.package_qty = 28
    AND m.certificate = 'UA/3792/01/04';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/3792/01/04', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4712eea0-5e05-4ce5-9c85-4cedf1e7b9a2'', ''ВАЗИЛІП®'', ''BRAND'', ''{"name": "КРКА", "country": " Словенія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/3792/01/04'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''055807bc-d9b3-4b8d-9f4a-0afcaf095da7'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "85.91"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''74c7c675-1581-4295-99c0-1b6913c0136c'', ''{"type": "FIXED", "reimbursement_amount": "85.91"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''40323e74-07d7-498a-892e-3408845bea1b'', ''Симвастатин 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8ef0d613-28ad-4d4e-ab4d-30fd3fd7e656'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'ВАЗИЛІП®'
    AND m.package_qty = 84
    AND m.certificate = 'UA/3792/01/04';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/3792/01/04', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''bff53388-d70c-4147-ba46-6ff2333e7f3c'', ''ВАЗИЛІП®'', ''BRAND'', ''{"name": "КРКА", "country": " Словенія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 84, 84, ''UA/3792/01/04'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''03877a52-478e-4fce-abee-7c85145a024e'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "257.72"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''0f70ded1-107e-4402-92d1-f552d00ae37d'', ''{"type": "FIXED", "reimbursement_amount": "257.72"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''40323e74-07d7-498a-892e-3408845bea1b'', ''Симвастатин 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''5b732802-f484-464b-accc-d14154ece659'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'ВАЗОСТАТ-ЗДОРОВ''Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3579/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/3579/01/03', '2020-03-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''7bbb5d4a-5a9f-4d16-8c5c-4341f4b89d4d'', ''ВАЗОСТАТ-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3579/01/03'', ''2020-03-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a7c98216-c0b3-48e9-90d6-79e215f88b35'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "92.04"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''bb96573d-91c9-4732-9913-e0f0e6aba5bb'', ''{"type": "FIXED", "reimbursement_amount": "92.04"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''40323e74-07d7-498a-892e-3408845bea1b'', ''Симвастатин 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8265155e-d64c-4aed-97f3-420c6e2594a0'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'КАРДАК'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11834/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/11834/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3e6023ed-e300-4f73-b6e5-8af278a03283'', ''КАРДАК'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11834/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''824396c7-c3a2-4f23-b033-72d8279f63d3'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "92.04"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''030508ec-fb7a-41ba-8a61-8728b91d97f7'', ''{"type": "FIXED", "reimbursement_amount": "92.04"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Simvastatin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Симвастатин 40 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''40323e74-07d7-498a-892e-3408845bea1b'', ''Симвастатин 40 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''d6fcdda1-05c7-4152-998e-f093d2b4ccc3'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 40
    AND m.name = 'СИМВАСТАТИН 40 АНАНТА'
    AND m.package_qty = 28
    AND m.certificate = 'UA/14019/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C10AA01"]'::jsonb, 'UA/14019/01/03', '2019-10-31'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''456dd08c-0e85-4a9a-9515-f946c614048e'', ''СИМВАСТАТИН 40 АНАНТА'', ''BRAND'', ''{"name": "Марксанс Фарма Лтд.", "country": " Індія"}'', ''["C10AA01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/14019/01/03'', ''2019-10-31'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''38bb77d6-3bcd-494e-abd6-5febe0e6e3bd'', ''{"numerator_unit": "MG", "numerator_value": "40", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "85.91"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''61b3d9fc-acc3-43ca-b3cf-4af7aaa6ce02'', ''{"type": "FIXED", "reimbursement_amount": "85.91"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 2.5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e5a1e426-5b7b-4c1b-b424-779d80f9711f'', ''Бісопролол 2.5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''96b9c93a-d0fb-4521-a737-1e76753e768a'', ''{"numerator_unit": "MG", "numerator_value": "2.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 2.5
    AND m.name = 'БІСОПРОЛОЛ-АУРОБІНДО'
    AND m.package_qty = 28
    AND m.certificate = 'UA/16250/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/16250/01/01', '2022-10-11'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''937bc516-0b99-4054-a719-e7ce69e377ac'', ''БІСОПРОЛОЛ-АУРОБІНДО'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/16250/01/01'', ''2022-10-11'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''c184deae-0260-4558-aebc-4279d6ebfed3'', ''{"numerator_unit": "MG", "numerator_value": "2.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "5.27"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''38d138c3-af5c-4c41-bb4d-329fd6564640'', ''{"type": "FIXED", "reimbursement_amount": "5.27"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 2.5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e5a1e426-5b7b-4c1b-b424-779d80f9711f'', ''Бісопролол 2.5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''02db28d9-3ab2-45bd-afd4-643d08ce657e'', ''{"numerator_unit": "MG", "numerator_value": "2.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 2.5
    AND m.name = 'БІПРОЛОЛ-ЗДОРОВ’Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14025/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/14025/01/01', '2019-11-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b8b07f41-6b36-4573-97be-23f5b5193bf5'', ''БІПРОЛОЛ-ЗДОРОВ’Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14025/01/01'', ''2019-11-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''f24b5501-a3a3-4878-97d7-35ae8bee8f9c'', ''{"numerator_unit": "MG", "numerator_value": "2.5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "5.65"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''394ff6c1-0837-4622-b23b-a967af4a296c'', ''{"type": "FIXED", "reimbursement_amount": "5.65"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''b96c1c77-ed8f-46a2-891e-ba1ecd8c2a7a'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛ®'
    AND m.package_qty = 50
    AND m.certificate = 'UA/3214/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/3214/01/01', '2020-03-30'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0607dc1a-4a38-4305-8bab-a16b9f2a8eb0'', ''БІСОПРОЛ®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/3214/01/01'', ''2020-03-30'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d8bacff9-0655-4bd7-bca2-510ce24f8938'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "18.84"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''15b0eba0-380c-4b33-af1e-33fa3643de96'', ''{"type": "FIXED", "reimbursement_amount": "18.84"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7ed47eba-a2e6-4dac-8689-fc2f0eb69d3a'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛОЛ-АУРОБІНДО'
    AND m.package_qty = 28
    AND m.certificate = 'UA/16250/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/16250/01/02', '2022-10-11'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''47d91308-2533-45d3-a8e4-523e659a112c'', ''БІСОПРОЛОЛ-АУРОБІНДО'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/16250/01/02'', ''2022-10-11'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''4674a636-baf7-48e3-b3a6-d4312df241da'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "10.55"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''83bcd4b2-8078-4860-9029-423fd7c75097'', ''{"type": "FIXED", "reimbursement_amount": "10.55"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''a750ecd7-ba46-498d-a635-1f6df51f4554'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІПРОЛОЛ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3800/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/3800/01/01', '2020-10-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''599d0be3-b77e-401e-a45b-232599a99acc'', ''БІПРОЛОЛ'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3800/01/01'', ''2020-10-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''53277341-1677-4e80-91af-4815c0f148a1'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.30"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b78d1ba6-8543-4ba6-a26c-5793f743d889'', ''{"type": "FIXED", "reimbursement_amount": "11.30"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8ee05123-1698-4643-ac8a-d2d5ca566ef1'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛОЛ-КВ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/8672/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/8672/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b59b600c-bd2d-444e-bc4f-7da434783447'', ''БІСОПРОЛОЛ-КВ'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/8672/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''858b3195-73cc-4cf8-8b4e-14af5fa79b58'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.30"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3f8a5c84-4984-4bd7-86e8-b13b1778f69c'', ''{"type": "FIXED", "reimbursement_amount": "11.30"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''3e7afc86-528a-4369-9350-5468200cf3e9'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІПРОЛОЛ-ЗДОРОВ’Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14025/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/14025/01/02', '2019-11-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''61b31ce0-f856-4643-998e-a87e514e746e'', ''БІПРОЛОЛ-ЗДОРОВ’Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14025/01/02'', ''2019-11-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''b0eda1bc-ae99-4c64-a28f-3244745453d5'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.30"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''1c847b6b-886a-46ca-9fa5-cdaf3d17805c'', ''{"type": "FIXED", "reimbursement_amount": "11.30"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''59ce1808-bbd4-45ee-978c-195347c549fc'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3214/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/3214/01/01', '2020-03-30'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''efa3f84d-db9c-4de0-b316-3203d56efecc'', ''БІСОПРОЛ®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3214/01/01'', ''2020-03-30'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''74ac7062-d3f8-4312-9680-7c678ebf3dbd'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.30"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''211dbcbe-7208-48e4-af95-baf6689f7ce3'', ''{"type": "FIXED", "reimbursement_amount": "11.30"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c20e9192-fb0f-4a7f-b5d7-9b4e5c201ca5'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛОЛ - АСТРАФАРМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/8959/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/8959/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''cc7d94d6-f85c-43b5-8d93-7a99f4c842bd'', ''БІСОПРОЛОЛ - АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/8959/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''e1307faa-0dd2-438a-92d8-3d4ef1616371'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.30"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''212b6bff-7b1a-4a95-bca3-367b77a0fda5'', ''{"type": "FIXED", "reimbursement_amount": "11.30"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7a48be1d-e128-4d95-bbc8-df9ccabc4cc1'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛОЛ - АСТРАФАРМ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/8959/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/8959/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''2b1fcae9-12bb-4a82-a4bc-7cc67daac917'', ''БІСОПРОЛОЛ - АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/8959/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a9751b99-5f7b-4c74-9c66-0ceeea6fcfa8'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "7.53"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d9641f57-b1e4-4a53-81e3-523558f8df0f'', ''{"type": "FIXED", "reimbursement_amount": "7.53"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''9aad4c27-9a24-4a21-9e7b-fe8746e6657a'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛ®'
    AND m.package_qty = 20
    AND m.certificate = 'UA/3214/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/3214/01/02', '2020-03-30'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1e879a1b-6d44-4c26-af0f-14dd9af8d50f'', ''БІСОПРОЛ®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/3214/01/02'', ''2020-03-30'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''88405fe5-8de9-4494-920a-fb0cb1aafe4f'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "7.53"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d58ae301-0e14-4695-8c46-8c0207cd5c9b'', ''{"type": "FIXED", "reimbursement_amount": "7.53"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''b338b441-3eae-4890-94fd-95528abd720b'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛОЛ САНДОЗ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/4401/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/4401/01/01', '2020-11-27'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b40d0fa3-f493-493a-81ff-969f2c99856d'', ''БІСОПРОЛОЛ САНДОЗ®'', ''BRAND'', ''{"name": "Салютас Фарма ГмбХ", "country": " Німеччина"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/4401/01/01'', ''2020-11-27'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''494cd960-097f-4229-a653-cf52af286a2d'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.30"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''01bf8a5d-b949-4403-97c1-06bc94c3a57c'', ''{"type": "FIXED", "reimbursement_amount": "11.30"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''41d10586-c700-410c-b0f4-d568f58dc214'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛОЛ-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1728/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/1728/01/01', '2021-03-16'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''edb8cd55-8c77-4304-be59-b3a8e0221daf'', ''БІСОПРОЛОЛ-ТЕВА'', ''BRAND'', ''{"name": "Меркле ГмбХ", "country": " Німеччина"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1728/01/01'', ''2021-03-16'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a45ef33a-2c4e-42a4-ac11-8b6958153e6e'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "11.30"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a7ed62d5-1c8a-4df1-8bfd-47240368b85c'', ''{"type": "FIXED", "reimbursement_amount": "11.30"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''de93d09e-25b8-4f4d-9ce0-50219e57cc26'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛОЛ-ТЕВА'
    AND m.package_qty = 50
    AND m.certificate = 'UA/1728/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/1728/01/01', '2021-03-16'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''432acf27-cac3-46df-98b4-7ef01ddac268'', ''БІСОПРОЛОЛ-ТЕВА'', ''BRAND'', ''{"name": "Меркле ГмбХ", "country": " Німеччина"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/1728/01/01'', ''2021-03-16'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''493f51cf-2d21-48b9-82e4-e605c7c7f8f6'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "18.84"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''844ecfff-699b-4024-a39f-ca0f447166eb'', ''{"type": "FIXED", "reimbursement_amount": "18.84"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1be7a29f-e6ea-4e39-bdb5-b59d31abefb5'', ''Бісопролол 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''9a8b0749-320e-4bfa-bc78-477227088b51'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'БІСОПРОЛОЛ САНДОЗ®'
    AND m.package_qty = 90
    AND m.certificate = 'UA/4401/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/4401/01/01', '2020-11-27'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''dc199032-bc94-4b6b-9399-1905e801722a'', ''БІСОПРОЛОЛ САНДОЗ®'', ''BRAND'', ''{"name": "Салютас Фарма ГмбХ", "country": " Німеччина"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/4401/01/01'', ''2020-11-27'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''94d293b5-80f1-4d65-a56a-92a5c2ccf087'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.91"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''546bac3d-d5a9-4166-9059-6e291d7c363a'', ''{"type": "FIXED", "reimbursement_amount": "33.91"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''747ec692-dc52-4ebe-8526-a0b131b3e82d'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛОЛ-КВ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/8672/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/8672/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''33305910-c304-4772-8b10-acc602cff254'', ''БІСОПРОЛОЛ-КВ'', ''BRAND'', ''{"name": "АТ \"КИЇВСЬКИЙ ВІТАМІННИЙ ЗАВОД\"", "country": "Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/8672/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''659655d2-65b1-4b73-b110-1b3d4d53c687'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d16df548-94d8-4e1a-8ea8-303627719289'', ''{"type": "FIXED", "reimbursement_amount": "22.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''d75db1de-ff93-4325-863d-723b0c59ef4c'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3214/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/3214/01/02', '2020-03-30'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''f6cfab62-167a-41ac-8d87-e05ab767ca92'', ''БІСОПРОЛ®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3214/01/02'', ''2020-03-30'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1702cb40-d183-4363-b3dd-63200a284118'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''acb4c947-4e09-4249-84e1-86cdda4e7366'', ''{"type": "FIXED", "reimbursement_amount": "22.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''2834898e-1b2c-4283-8fd8-3118109a5fff'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛ®'
    AND m.package_qty = 50
    AND m.certificate = 'UA/3214/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/3214/01/02', '2020-03-30'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''77904501-e77f-4458-a8a8-f8cb2cfc0136'', ''БІСОПРОЛ®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/3214/01/02'', ''2020-03-30'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''720aa4b6-6985-4f1a-9398-72e193cd9a68'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "37.67"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''99300a6b-af27-4b11-a704-d913108f845a'', ''{"type": "FIXED", "reimbursement_amount": "37.67"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8d3d2a57-8d5c-4abe-ac0a-7c8735d7d915'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛОЛ-АУРОБІНДО'
    AND m.package_qty = 28
    AND m.certificate = 'UA/16250/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/16250/01/03', '2022-10-11'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fcb0ba0a-0250-4f21-a4ec-d039c3647b3d'', ''БІСОПРОЛОЛ-АУРОБІНДО'', ''BRAND'', ''{"name": "Ауробіндо Фарма Лімітед", "country": " Індія"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 28, 28, ''UA/16250/01/03'', ''2022-10-11'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''c5342932-f44c-442a-974d-a2cacdda4780'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "21.10"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''7fe895ce-4b81-4ba8-badb-d3aaf0789cae'', ''{"type": "FIXED", "reimbursement_amount": "21.10"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''d7f343e9-e6f2-4c74-be4d-8a64d3952246'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІПРОЛОЛ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/3800/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/3800/01/02', '2020-10-21'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0f5e40ca-b97a-4bd5-b53d-13e187071379'', ''БІПРОЛОЛ'', ''BRAND'', ''{"name": "Публічне акціонерне товариство \"Науково-виробничий центр \"Борщагівський хіміко-фармацевтичний завод\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/3800/01/02'', ''2020-10-21'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''409d6633-b437-469f-8031-e211a5278ee9'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''96238643-f056-4def-a03e-827c6f7671c0'', ''{"type": "FIXED", "reimbursement_amount": "22.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''43aa915c-8c12-4706-a25b-5d9fabc51ac0'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛОЛ - АСТРАФАРМ'
    AND m.package_qty = 20
    AND m.certificate = 'UA/8959/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/8959/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''00700cc3-ec3c-45e6-8454-2be0ff681c74'', ''БІСОПРОЛОЛ - АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/8959/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''282cd6e7-0fa0-485d-93e2-130fbbd6566d'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "15.07"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''26328ef9-6765-4818-96ae-d18ca40ad76d'', ''{"type": "FIXED", "reimbursement_amount": "15.07"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''6f8def46-c356-4024-b9a4-31b7e23d1a10'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІПРОЛОЛ-ЗДОРОВ’Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14025/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/14025/01/03', '2019-11-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''81d86f07-2d3a-479d-9094-b9d4f90a2b5e'', ''БІПРОЛОЛ-ЗДОРОВ’Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14025/01/03'', ''2019-11-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''bbbb7a08-88f3-4700-8ccf-c7ad976a66cc'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''8783d6d1-c33a-48f4-8827-31f64f2e5371'', ''{"type": "FIXED", "reimbursement_amount": "22.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c3dd7865-452a-429d-9b0f-94636017148d'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛОЛ - АСТРАФАРМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/8959/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/8959/01/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3e2415a2-bc2a-4b38-a594-011f5136de47'', ''БІСОПРОЛОЛ - АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/8959/01/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ef1e150c-6845-4477-9fe2-1ca93498edc1'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''f1d7a7f2-940a-40b3-ade3-e221593ae2f7'', ''{"type": "FIXED", "reimbursement_amount": "22.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''691d4b4a-0259-44e4-a85c-889b55dfb44d'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛОЛ САНДОЗ®'
    AND m.package_qty = 90
    AND m.certificate = 'UA/4401/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/4401/01/02', '2020-11-27'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''227fe935-c28e-488d-9119-51bc4b40665a'', ''БІСОПРОЛОЛ САНДОЗ®'', ''BRAND'', ''{"name": "Салютас Фарма ГмбХ", "country": " Німеччина"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/4401/01/02'', ''2020-11-27'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3f82ec20-4a65-42d6-9633-774a3c01a098'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "67.81"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''45a45b20-5d9c-45d8-9e02-001df18b7525'', ''{"type": "FIXED", "reimbursement_amount": "67.81"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e5476f57-5540-4cc3-96c3-e2b65bcab54c'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛ®'
    AND m.package_qty = 20
    AND m.certificate = 'UA/3214/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/3214/01/02', '2020-03-30'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ec45df30-ad36-4972-bd3f-c3a9646c37a9'', ''БІСОПРОЛ®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 20, 20, ''UA/3214/01/02'', ''2020-03-30'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''4813cfdb-bd9e-43ce-9de0-063da6a305ba'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "15.07"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ae08e67e-a5df-4ca2-9d60-99dc3276af67'', ''{"type": "FIXED", "reimbursement_amount": "15.07"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''132585eb-c8c0-4144-a641-4d424f1efe86'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛОЛ САНДОЗ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/4401/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/4401/01/02', '2020-11-27'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''15ccf6d6-073e-46fe-8c0d-54a58d1d7e90'', ''БІСОПРОЛОЛ САНДОЗ®'', ''BRAND'', ''{"name": "Салютас Фарма ГмбХ", "country": " Німеччина"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/4401/01/02'', ''2020-11-27'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''4b8484f4-57a4-483a-8eb6-08e0bd881f82'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''1052d5cf-33d1-4185-88d2-512215c6c5c1'', ''{"type": "FIXED", "reimbursement_amount": "22.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''1930aab9-cb30-4b53-84cd-54e4db981fed'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛОЛ-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/1728/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/1728/01/02', '2021-03-16'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0fda4e63-d33a-43be-aaee-f5b592ed8cda'', ''БІСОПРОЛОЛ-ТЕВА'', ''BRAND'', ''{"name": "Меркле ГмбХ", "country": " Німеччина"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/1728/01/02'', ''2021-03-16'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''596229f5-cc20-46b8-a42a-0b4fc35d44cb'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "22.60"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''7e091d80-41fc-4308-ba79-01e5dcf96c59'', ''{"type": "FIXED", "reimbursement_amount": "22.60"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Bisoprolol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Бісопролол 10 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c8642c6-3d46-45e9-ba88-1e53adee539d'', ''Бісопролол 10 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''82a2e7e4-190a-4f27-9d9c-6843c521f5b3'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 10
    AND m.name = 'БІСОПРОЛОЛ-ТЕВА'
    AND m.package_qty = 50
    AND m.certificate = 'UA/1728/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["C07AB07"]'::jsonb, 'UA/1728/01/02', '2021-03-16'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d3e5d350-a509-4eed-bbee-72e11e002551'', ''БІСОПРОЛОЛ-ТЕВА'', ''BRAND'', ''{"name": "Меркле ГмбХ", "country": " Німеччина"}'', ''["C07AB07"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/1728/01/02'', ''2021-03-16'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ce37bb44-5c3d-450f-bc6a-9b7081e77345'', ''{"numerator_unit": "MG", "numerator_value": "10", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "37.67"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''8b7b6763-0dd7-428a-8140-9acede897611'', ''{"type": "FIXED", "reimbursement_amount": "37.67"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''bb7aea03-d785-4a5e-9c27-c3d8ae02f9ff'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'ДІАФОРМІН®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/2508/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/2508/01/01', '2019-12-05'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''77570297-4801-452f-b14d-daae6d26ce32'', ''ДІАФОРМІН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/2508/01/01'', ''2019-12-05'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''6cf7e516-7bf2-424d-a117-43c25c8df7ba'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ccc835b5-6958-45f6-9b3a-6d9a34aa075c'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''0da91f49-d5e5-45c6-a315-74179b645551'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'ДІАФОРМІН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/2508/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/2508/01/01', '2019-12-05'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c14b1944-940f-4deb-8650-08e0f90aa803'', ''ДІАФОРМІН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/2508/01/01'', ''2019-12-05'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''6576f1d4-1709-43fd-96ea-cc6809817118'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.56"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''d3b079cd-d619-4c13-b62e-232f8f41b73b'', ''{"type": "FIXED", "reimbursement_amount": "16.56"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''6370d2c9-d907-4fdf-8975-c77e9183e1e0'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕТАМІН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11506/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/11506/02/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b460bb81-1f90-4584-913d-5b1a34aa1110'', ''МЕТАМІН®'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11506/02/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''49d9c3f3-f226-4a0b-8c4f-a9711f647ef8'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.56"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a9134ff7-2b8a-437a-8989-3a9d3c6fd75b'', ''{"type": "FIXED", "reimbursement_amount": "16.56"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''31c8ee0e-4531-4b51-a398-4645fe53ad94'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕТАМІН®'
    AND m.package_qty = 100
    AND m.certificate = 'UA/11506/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/11506/02/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''f7ae4c45-c52f-4894-a7aa-56d97305fee0'', ''МЕТАМІН®'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 100, 100, ''UA/11506/02/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d8b63525-28d2-4777-a36f-291a3d685a12'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "55.20"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b5c656f2-5882-4a07-a510-9d28434098b7'', ''{"type": "FIXED", "reimbursement_amount": "55.20"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''6b60c460-f85c-4e01-ab23-3fa6801f628b'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕТФОРМІН ЗЕНТІВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15295/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA03"]'::jsonb, 'UA/15295/01/01', '2021-07-07'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a0da2ab5-785f-4c9c-92c5-c87a60abf3b5'', ''МЕТФОРМІН ЗЕНТІВА'', ''BRAND'', ''{"name": "Санофі Індія Лімітед ", "country": " Індія"}'', ''["A10BA03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15295/01/01'', ''2021-07-07'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''85656612-c079-4a23-8dc1-db0918f19830'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.56"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ed304670-8dda-4684-a9a4-c134147c9c54'', ''{"type": "FIXED", "reimbursement_amount": "16.56"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''f1fd8d92-29db-42a3-82af-58bbbb174b37'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕТФОРМІН-САНОФІ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15295/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA03"]'::jsonb, 'UA/15295/01/01', '2021-07-07'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''03c21dc5-5c21-4876-823e-bc6c385ca9b0'', ''МЕТФОРМІН-САНОФІ'', ''BRAND'', ''{"name": "Санофі Індія Лімітед ", "country": " Індія"}'', ''["A10BA03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15295/01/01'', ''2021-07-07'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''92ddb0c3-6e66-4410-a380-d189483db9fd'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.56"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''fa9069ed-a888-4dcc-9142-af193641142b'', ''{"type": "FIXED", "reimbursement_amount": "16.56"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''1ff42561-437c-42ee-b426-a5892e6ca216'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕТФОРМІН-АСТРАФАРМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15739/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15739/01/01', '2022-01-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5e15658f-51b8-46da-8b20-367b105781e7'', ''МЕТФОРМІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15739/01/01'', ''2022-01-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''4822d9bd-8bfd-44d0-83bb-f5d5ffce1376'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.56"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b529ec69-23a4-494f-8606-da9ea5c812bb'', ''{"type": "FIXED", "reimbursement_amount": "16.56"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''12baf433-bb81-44b2-8c32-bc9b7dce857d'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕТФОРМІН-АСТРАФАРМ'
    AND m.package_qty = 60
    AND m.certificate = 'UA/15739/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15739/01/01', '2022-01-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c0051d5c-d3af-46d2-bda0-1b255e7dddc1'', ''МЕТФОРМІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/15739/01/01'', ''2022-01-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a96ba268-4b13-4d6f-a99a-5f2c00878c39'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''f06b129f-0e04-47e1-8cb3-8c8de6fffba7'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''9b9e9fab-198a-4aaf-83ac-1bfc3b9550a3'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕТФОРМІН ІНДАР'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15947/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15947/01/01', '2022-04-28'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5ecf3792-b8cd-461d-afe2-89ec1c2c1f26'', ''МЕТФОРМІН ІНДАР'', ''BRAND'', ''{"name": "ПрАТ \"По виробництву інсулінів \"ІНДАР\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15947/01/01'', ''2022-04-28'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''f71dc0c1-50f3-4679-b383-e37149804bef'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.56"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''41da6aba-82c1-450b-ab0d-7710c023e65a'', ''{"type": "FIXED", "reimbursement_amount": "16.56"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''0232f047-88e9-4fa6-80f4-ae8484f540c6'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕТФОРМІН ІНДАР'
    AND m.package_qty = 60
    AND m.certificate = 'UA/15947/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15947/01/01', '2022-04-28'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''850283af-aba7-4b9d-8ca2-56ac4f0c723c'', ''МЕТФОРМІН ІНДАР'', ''BRAND'', ''{"name": "ПрАТ \"По виробництву інсулінів \"ІНДАР\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/15947/01/01'', ''2022-04-28'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''548686cf-7d78-414e-94a6-56f6ee887476'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e1f36a2d-036c-48db-a4f7-7d2e7db5585c'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''5f0471bb-65b5-4ed9-89de-04378a5c00a8'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕТФОРМІН-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/7769/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/7769/01/01', '2019-12-05'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9ec8a875-27dd-4026-aae0-aab3702508c2'', ''МЕТФОРМІН-ТЕВА'', ''BRAND'', ''{"name": "ТОВ Тева Оперейшнз Поланд", "country": " Польща"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/7769/01/01'', ''2019-12-05'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ee55bdb6-c22d-479d-8337-29d45ca1cfa1'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.56"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''bd8149fa-ebab-46a5-89e6-36739c5b82b8'', ''{"type": "FIXED", "reimbursement_amount": "16.56"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''32f928c9-361d-4074-8b39-f2b48bd8c939'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕФАРМІЛ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14013/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/14013/01/01', '2019-11-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6f1ab8e8-4d0b-47c6-bf72-b18dc0375688'', ''МЕФАРМІЛ®'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14013/01/01'', ''2019-11-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ef162f1f-5069-40da-9b97-c39b14328073'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.56"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''ac670443-5de1-44ed-878b-bc938db51729'', ''{"type": "FIXED", "reimbursement_amount": "16.56"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 500 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''70d1f09a-dec6-44a7-9181-857d0a022392'', ''Метформін 500 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''a97b35cf-8526-4c6e-9c35-7ed9e642c99d'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 500
    AND m.name = 'МЕФАРМІЛ®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/14013/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/14013/01/01', '2019-11-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''063e8e48-06e8-46d2-97ba-2f21abe9147e'', ''МЕФАРМІЛ®'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/14013/01/01'', ''2019-11-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''90eb9217-2998-467e-b6e1-efc113314b3d'', ''{"numerator_unit": "MG", "numerator_value": "500", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''eb220d89-a69c-4327-bee5-1f1bd7372968'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ec6be2e1-054e-4a71-82f0-7677c5a8443c'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'ДІАФОРМІН®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/2508/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/2508/01/02', '2019-12-05'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''cf031bf4-cf68-4ebf-a639-68483626761a'', ''ДІАФОРМІН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/2508/01/02'', ''2019-12-05'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''582f244c-62b9-44d8-a255-00317d5c19fb'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "56.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''0378f763-d189-4c51-9ced-127fd60d29bd'', ''{"type": "FIXED", "reimbursement_amount": "56.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c6bcc47b-4592-48ef-8115-59b28cc11470'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'ДІАФОРМІН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/2508/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/2508/01/02', '2019-12-05'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4c75d182-711c-4601-996e-fae3637f7ff3'', ''ДІАФОРМІН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/2508/01/02'', ''2019-12-05'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''cd4b01e8-ace3-4b68-8cdb-ac3690710097'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "28.15"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3b3a655b-32d6-4094-81a9-1aab68724f32'', ''{"type": "FIXED", "reimbursement_amount": "28.15"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''fff05e0c-32c6-4797-a5fc-999ae8c85392'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'МЕТАМІН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11506/02/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/11506/02/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''95d5b630-a97b-4bf4-bcc2-76062376ef23'', ''МЕТАМІН®'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11506/02/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''f12f879c-f304-4739-85d5-c91784eba74c'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "28.15"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''94715b95-629d-457e-8b1b-a134036dc52d'', ''{"type": "FIXED", "reimbursement_amount": "28.15"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''6ce7c477-a4a5-4969-9912-003962382584'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'МЕТАМІН®'
    AND m.package_qty = 100
    AND m.certificate = 'UA/11506/02/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/11506/02/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''f2aa122a-bd82-4ebd-9105-40639f4711a4'', ''МЕТАМІН®'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 100, 100, ''UA/11506/02/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''72511071-9d8f-4964-9fcd-639e0c8ab406'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "93.85"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e9f3b57b-2f0e-4e22-a439-106cd9f26d6f'', ''{"type": "FIXED", "reimbursement_amount": "93.85"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c0207740-15cc-4eb1-99ac-52d14c9ec563'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'МЕТФОРМІН ЗЕНТІВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15295/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA03"]'::jsonb, 'UA/15295/01/02', '2021-07-07'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''05e6e66c-99c0-40a2-986d-770cc917c1b5'', ''МЕТФОРМІН ЗЕНТІВА'', ''BRAND'', ''{"name": "Санофі Індія Лімітед ", "country": " Індія"}'', ''["A10BA03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15295/01/02'', ''2021-07-07'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ca12de02-6b31-4eb8-a295-ff25e47fdbc1'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "28.15"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''53db6ba8-958e-4b14-b49d-07a9ccfde2d8'', ''{"type": "FIXED", "reimbursement_amount": "28.15"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''55766d42-0bad-4b1a-9f65-eb169eafa24f'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'МЕТФОРМІН-САНОФІ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15295/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA03"]'::jsonb, 'UA/15295/01/02', '2021-07-07'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a1c16b3e-0bb9-4bda-9466-dff33b532590'', ''МЕТФОРМІН-САНОФІ'', ''BRAND'', ''{"name": "Санофі Індія Лімітед ", "country": " Індія"}'', ''["A10BA03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15295/01/02'', ''2021-07-07'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''8f984ff8-354e-452b-a318-f86f33fcf74f'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "28.15"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''85d9857d-0042-430c-b348-3168dfed41a8'', ''{"type": "FIXED", "reimbursement_amount": "28.15"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''85ed1d3f-d58b-4ecc-b2cc-01f9efc3f247'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'МЕТФОРМІН-АСТРАФАРМ'
    AND m.package_qty = 60
    AND m.certificate = 'UA/15739/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15739/01/02', '2022-01-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a1144ca7-e7e0-496c-b588-27c66ae7542f'', ''МЕТФОРМІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/15739/01/02'', ''2022-01-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0f2d1e6d-ceab-4de7-ab69-a530189d7083'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "56.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''2e93eb08-fc09-4377-843b-b3b096ea4d26'', ''{"type": "FIXED", "reimbursement_amount": "56.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''4866636e-2540-4f06-a602-cf2f0f4c29c1'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'МЕТФОРМІН-АСТРАФАРМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15739/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15739/01/02', '2022-01-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9b8cf8c0-f9f7-420c-b509-6fe655cefe28'', ''МЕТФОРМІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15739/01/02'', ''2022-01-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''53c81064-9d63-415d-b6c8-5f9e31e2853e'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "28.15"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a1cb2242-1770-44ca-a3b5-8c0d54121558'', ''{"type": "FIXED", "reimbursement_amount": "28.15"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e8eb1bda-d36c-4330-b9cf-61a710fd95b6'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'МЕТФОРМІН-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/7795/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/7795/01/02', '2019-12-05'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1eeb9505-e901-49fd-9edd-b5a70d440fa6'', ''МЕТФОРМІН-ТЕВА'', ''BRAND'', ''{"name": "ТОВ Тева Оперейшнз Поланд", "country": " Польща"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/7795/01/02'', ''2019-12-05'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0497037b-dbc9-4647-af49-0b0e1cb14884'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "28.15"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''99a5b21b-7071-4fbf-a664-62a8947ac33e'', ''{"type": "FIXED", "reimbursement_amount": "28.15"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''1041194b-eeb3-4545-9a36-dd59940a986d'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'МЕФАРМІЛ®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/14013/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/14013/01/02', '2019-11-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0e27c6b4-c0e1-4dc5-a054-013ef6cf8408'', ''МЕФАРМІЛ®'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/14013/01/02'', ''2019-11-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1e42159f-a8e5-4ef1-a7aa-91c0b0f48eb1'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "56.31"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''61e6e2e5-c8b0-4790-87d3-7171e47f77f6'', ''{"type": "FIXED", "reimbursement_amount": "56.31"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 850 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6c9d12a1-ca9e-4222-9d07-83621bb70d5d'', ''Метформін 850 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''46952720-f8e0-40a2-985d-b9930a1a8b31'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 850
    AND m.name = 'МЕФАРМІЛ®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14013/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/14013/01/02', '2019-11-06'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''7976b7de-10f4-4acb-aef3-a372f2ec78f0'', ''МЕФАРМІЛ®'', ''BRAND'', ''{"name": "ПАТ \"Київмедпрепарат\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14013/01/02'', ''2019-11-06'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''28663962-213c-4643-a068-1488cecee2a2'', ''{"numerator_unit": "MG", "numerator_value": "850", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "28.15"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''a7e9534e-e85f-4ed0-8581-15672112ed64'', ''{"type": "FIXED", "reimbursement_amount": "28.15"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ef8b9f5e-7442-4f2f-bbf8-2af7ac24825a'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'ДІАФОРМІН®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/15141/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15141/01/03', '2021-05-12'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e0a99334-2f92-4ab6-96b4-719a3010c4c8'', ''ДІАФОРМІН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/15141/01/03'', ''2021-05-12'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''e087ddb0-528c-43b3-a028-ba8cd285c6c7'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "66.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3b26271d-4260-40d7-862b-ec513c564a2a'', ''{"type": "FIXED", "reimbursement_amount": "66.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''1dc96a92-106f-42a8-acbe-94e7ab672a64'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'ДІАФОРМІН®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/11857/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/11857/02/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5caa59b2-b2be-4b63-a996-97086751a8d2'', ''ДІАФОРМІН®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/11857/02/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''863fe955-6b83-4b1b-a014-44971052aa31'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "66.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''88b9fa53-e213-4a87-a207-fd3cadd3d53b'', ''{"type": "FIXED", "reimbursement_amount": "66.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''9e4804d8-2b8f-4406-bd52-d38adb978030'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'МЕТАМІН®'
    AND m.package_qty = 30
    AND m.certificate = 'UA/11506/02/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/11506/02/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''dde03813-583b-4ba2-9098-c0973ae71c55'', ''МЕТАМІН®'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/11506/02/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''7c656a59-7db4-4ecb-bbb5-8f9c6b3b2d2a'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''48f19bc0-4a4a-4f75-bf41-586b913bf2f5'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''eaba9454-89f3-407b-b43a-2ed0cfa2cbbb'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'МЕТАМІН®'
    AND m.package_qty = 90
    AND m.certificate = 'UA/11506/02/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/11506/02/03', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''16c6382f-087e-46c6-83f5-5d90e28083e7'', ''МЕТАМІН®'', ''BRAND'', ''{"name": "ТОВ \"Кусум Фарм\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 90, 90, ''UA/11506/02/03'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a49cb9f4-857f-48e9-b862-6dacb0fb8db0'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "99.37"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''f4b1737b-2d63-4b1c-b218-b9877319c4c0'', ''{"type": "FIXED", "reimbursement_amount": "99.37"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''992f1350-e009-4e65-bbc6-27c2b3ce37c2'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'МЕТФОРМІН ЗЕНТІВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15295/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA03"]'::jsonb, 'UA/15295/01/03', '2021-07-07'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9c2aba0f-d96e-4e47-89cd-a80af2e4ce84'', ''МЕТФОРМІН ЗЕНТІВА'', ''BRAND'', ''{"name": "Санофі Індія Лімітед ", "country": " Індія"}'', ''["A10BA03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15295/01/03'', ''2021-07-07'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''3a769bd7-8520-4a6d-bc64-d3e63205857c'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e5957fa3-6a96-4da2-9e02-7fbba61b33e4'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7ed05f1a-8582-4696-9e68-379ced91d1cc'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'МЕТФОРМІН-САНОФІ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15295/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA03"]'::jsonb, 'UA/15295/01/03', '2021-07-07'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''1c4576bb-f673-423d-b05e-805f8edb2040'', ''МЕТФОРМІН-САНОФІ'', ''BRAND'', ''{"name": "Санофі Індія Лімітед ", "country": " Індія"}'', ''["A10BA03"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15295/01/03'', ''2021-07-07'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''255a0fcd-7958-469a-bbd3-aa950dcd13d3'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''53ff26f7-c947-40f0-b545-8d05abf44df0'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''58b14dc8-aabc-4d5f-9b21-d88bc4833678'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'МЕТФОРМІН-АСТРАФАРМ'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15739/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15739/01/03', '2022-01-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''177e1049-5c1b-45be-b579-eddf720496c5'', ''МЕТФОРМІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15739/01/03'', ''2022-01-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''99f14805-bf2b-4f22-8013-49570b283949'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''b0df0cf4-949c-407b-af10-654c07cc171a'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''f41a27ed-8ff7-49ad-8e68-39dedcefb31c'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'МЕТФОРМІН-АСТРАФАРМ'
    AND m.package_qty = 60
    AND m.certificate = 'UA/15739/01/03';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15739/01/03', '2022-01-17'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''2217a8d8-c316-4c47-aecc-cc38ab179600'', ''МЕТФОРМІН-АСТРАФАРМ'', ''BRAND'', ''{"name": "ТОВ \"АСТРАФАРМ\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/15739/01/03'', ''2022-01-17'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''e76b17e7-b800-4b37-8eb0-032464894b65'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "66.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''29d884cc-adf5-4c49-b637-288b90ff6798'', ''{"type": "FIXED", "reimbursement_amount": "66.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''192e5ced-21c8-49d9-afbd-a27101d95dec'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'МЕТФОРМІН ІНДАР'
    AND m.package_qty = 30
    AND m.certificate = 'UA/15947/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15947/01/02', '2022-04-28'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''66f21977-03aa-4452-a77d-aa9037bc0b2f'', ''МЕТФОРМІН ІНДАР'', ''BRAND'', ''{"name": "ПрАТ \"По виробництву інсулінів \"ІНДАР\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/15947/01/02'', ''2022-04-28'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''aa4e7810-9e3f-44f5-8296-b3310457f040'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''876ac13a-caea-4935-9c2a-9da3e0f9fcdb'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''cdbb86f7-18b6-49e5-bb94-1a5b8fc3df9f'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'МЕТФОРМІН ІНДАР'
    AND m.package_qty = 60
    AND m.certificate = 'UA/15947/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/15947/01/02', '2022-04-28'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''3aa03a1b-7348-4567-9cca-7bde78e51d0b'', ''МЕТФОРМІН ІНДАР'', ''BRAND'', ''{"name": "ПрАТ \"По виробництву інсулінів \"ІНДАР\"", "country": " Україна"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/15947/01/02'', ''2022-04-28'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''dd316c17-f83d-49df-8978-ab67c1c6c91a'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "66.24"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''01c7d44d-bb60-4c59-940f-9013b20efeb9'', ''{"type": "FIXED", "reimbursement_amount": "66.24"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Metformin' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Метформін 1000 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6cdc033a-883e-407e-8d4e-4cb93d204d6b'', ''Метформін 1000 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''1d9e21db-9aba-4ae7-9279-d5517613347d'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 1000
    AND m.name = 'МЕТФОРМІН-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/12382/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BA02"]'::jsonb, 'UA/12382/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''65e02da6-c80d-4d3c-9961-ce2d10d647fa'', ''МЕТФОРМІН-ТЕВА'', ''BRAND'', ''{"name": "Тева Фармацевтікал Індастріз Лтд.", "country": " Угорщина"}'', ''["A10BA02"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/12382/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''00bc206a-d5d6-48ad-9e09-d685605e4de0'', ''{"numerator_unit": "MG", "numerator_value": "1000", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.12"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''61d9da21-c90d-4b12-a03d-737e96174e1c'', ''{"type": "FIXED", "reimbursement_amount": "33.12"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Gliclazide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Гліклазид 60 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ceea95e6-1f8d-4d08-9e44-7f42a6c7a27f'', ''Гліклазид 60 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''170ebdaa-530b-4c9e-b736-f7858074fd2f'', ''{"numerator_unit": "MG", "numerator_value": "60", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 60
    AND m.name = 'ГЛІКЛАДА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/14151/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB09"]'::jsonb, 'UA/14151/01/01', '2019-12-29'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5299a002-728a-4db7-986b-d0762e401293'', ''ГЛІКЛАДА'', ''BRAND'', ''{"name": "КРКА", "country": " Словенія"}'', ''["A10BB09"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/14151/01/01'', ''2019-12-29'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''054c2a1a-9597-48fc-a741-8b5fd31e5309'', ''{"numerator_unit": "MG", "numerator_value": "60", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "36.68"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3b859312-b5f8-4a24-b939-a38fbccf0c4b'', ''{"type": "FIXED", "reimbursement_amount": "36.68"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Gliclazide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Гліклазид 60 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ceea95e6-1f8d-4d08-9e44-7f42a6c7a27f'', ''Гліклазид 60 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''1af47b0b-bb5a-49f8-87c9-e23b9bc219e3'', ''{"numerator_unit": "MG", "numerator_value": "60", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 60
    AND m.name = 'ДІАБЕТОН® MR 60 мг'
    AND m.package_qty = 30
    AND m.certificate = 'UA/2158/02/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB09"]'::jsonb, 'UA/2158/02/02', '2021-03-16'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''298cb512-ab2f-4194-98ba-823671514cd6'', ''ДІАБЕТОН® MR 60 мг'', ''BRAND'', ''{"name": "Лабораторії Серв''''є Індастрі", "country": " Франція"}'', ''["A10BB09"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/2158/02/02'', ''2021-03-16'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''c0e0f28b-bbba-4725-a1a5-da100dd6d102'', ''{"numerator_unit": "MG", "numerator_value": "60", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "36.68"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''1e92ed89-1d85-418b-9b1c-ffa3fa7b818a'', ''{"type": "FIXED", "reimbursement_amount": "36.68"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Gliclazide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Гліклазид 80 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''aa904fd6-b619-4855-a900-c4dbaeae630e'', ''Гліклазид 80 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7e90e250-10a1-45cf-afdf-9380ca4b4a73'', ''{"numerator_unit": "MG", "numerator_value": "80", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 80
    AND m.name = 'ДІАГЛІЗИД®'
    AND m.package_qty = 60
    AND m.certificate = 'UA/6986/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB09"]'::jsonb, 'UA/6986/02/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''5e83d1b8-976e-41f2-a742-1ddd1c287a62'', ''ДІАГЛІЗИД®'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BB09"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/6986/02/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d3cac8f1-b71b-45d5-9e15-6a26a3248af4'', ''{"numerator_unit": "MG", "numerator_value": "80", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "97.81"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''8d555ebb-09a9-4b2c-9631-eb9908944f92'', ''{"type": "FIXED", "reimbursement_amount": "97.81"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Gliclazide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Гліклазид 30 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6470ee3c-0dcf-4b57-9bbe-4cfd4e2045f9'', ''Гліклазид 30 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''a9cb2b96-f719-47d8-b4fe-25ea44aa9425'', ''{"numerator_unit": "MG", "numerator_value": "30", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 30
    AND m.name = 'ДІАГЛІЗИД® MR'
    AND m.package_qty = 30
    AND m.certificate = 'UA/6986/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB09"]'::jsonb, 'UA/6986/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''c3bd9ced-0903-4b1c-9a1b-abf236545381'', ''ДІАГЛІЗИД® MR'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BB09"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/6986/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''df47ea18-e4c1-4a6b-9601-661e29cdb4d0'', ''{"numerator_unit": "MG", "numerator_value": "30", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "18.34"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''3807dc1f-78a0-4509-9ac5-78eebfdfcb53'', ''{"type": "FIXED", "reimbursement_amount": "18.34"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Gliclazide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Гліклазид 30 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6470ee3c-0dcf-4b57-9bbe-4cfd4e2045f9'', ''Гліклазид 30 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''d33c26fd-39b5-4d89-a7c4-bb3b81c3aeb8'', ''{"numerator_unit": "MG", "numerator_value": "30", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 30
    AND m.name = 'ДІАГЛІЗИД® MR'
    AND m.package_qty = 60
    AND m.certificate = 'UA/6986/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB09"]'::jsonb, 'UA/6986/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''bbf2be32-fe67-4d8a-864b-56661e3cc3a9'', ''ДІАГЛІЗИД® MR'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BB09"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 60, 60, ''UA/6986/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ab0bfe10-3542-4571-bd76-1dc75eda7077'', ''{"numerator_unit": "MG", "numerator_value": "30", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "36.68"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''79f042d0-016a-403f-b6d4-31d1a87d20f9'', ''{"type": "FIXED", "reimbursement_amount": "36.68"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Gliclazide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Гліклазид 60 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ceea95e6-1f8d-4d08-9e44-7f42a6c7a27f'', ''Гліклазид 60 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''00b695cf-6fbd-471c-8082-76a28b70d519'', ''{"numerator_unit": "MG", "numerator_value": "60", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 60
    AND m.name = 'ДІАГЛІЗИД® MR'
    AND m.package_qty = 30
    AND m.certificate = 'UA/6986/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB09"]'::jsonb, 'UA/6986/01/02', '2019-05-28'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''cdf6b288-e4b0-48d8-8985-c1cf0dc3569a'', ''ДІАГЛІЗИД® MR'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BB09"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/6986/01/02'', ''2019-05-28'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''b6f417cd-de0c-4a48-a92b-2e80b69d4059'', ''{"numerator_unit": "MG", "numerator_value": "60", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "36.68"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''12aa8f7e-d242-4f42-a6e5-dbcb91123c3c'', ''{"type": "FIXED", "reimbursement_amount": "36.68"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Gliclazide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Гліклазид 80 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''aa904fd6-b619-4855-a900-c4dbaeae630e'', ''Гліклазид 80 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''d8973077-f75b-4a41-b300-1cfe50b68afc'', ''{"numerator_unit": "MG", "numerator_value": "80", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 80
    AND m.name = 'ГЛІКЛАЗИД-ЗДОРОВ''Я'
    AND m.package_qty = 30
    AND m.certificate = 'UA/7826/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB09"]'::jsonb, 'UA/7826/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4e38929c-6a7b-429f-8796-dff744322419'', ''ГЛІКЛАЗИД-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["A10BB09"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/7826/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''da0e42e4-5a63-4802-9067-54c6c2572aef'', ''{"numerator_unit": "MG", "numerator_value": "80", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "48.90"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''0b7d755e-8f14-4ebf-83b9-154333c0d919'', ''{"type": "FIXED", "reimbursement_amount": "48.90"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Gliclazide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Гліклазид 60 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ceea95e6-1f8d-4d08-9e44-7f42a6c7a27f'', ''Гліклазид 60 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''2a4b715e-7a66-4691-9e1e-a5e7ccaba689'', ''{"numerator_unit": "MG", "numerator_value": "60", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 60
    AND m.name = 'ГЛІКЛАЗІД-ТЕВА'
    AND m.package_qty = 30
    AND m.certificate = 'UA/16821/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB09"]'::jsonb, 'UA/16821/01/02', '2023-07-13'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''e9e87356-c6e2-4b4d-851b-31f27cac410b'', ''ГЛІКЛАЗІД-ТЕВА'', ''BRAND'', ''{"name": "Балканфарма - Дупниця АТ", "country": " Болгарія"}'', ''["A10BB09"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/16821/01/02'', ''2023-07-13'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''5b5d4eaa-accb-4df0-bc78-e3eaa09e29d0'', ''{"numerator_unit": "MG", "numerator_value": "60", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "36.68"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''740d7339-1582-4e48-a550-a55a6e9b1882'', ''{"type": "FIXED", "reimbursement_amount": "36.68"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Glibenclamide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Глібенкламід 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d9eeb79f-e08a-4475-9da6-e0548afe9811'', ''Глібенкламід 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''53385880-d8a5-476b-9eeb-03981de0c732'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'ГЛІБЕНКЛАМІД'
    AND m.package_qty = 30
    AND m.certificate = 'UA/2820/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB01"]'::jsonb, 'UA/2820/01/01', '2020-03-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9a0dc8d6-494e-4c09-95a0-9462045ba375'', ''ГЛІБЕНКЛАМІД'', ''BRAND'', ''{"name": "ПрАТ \"Технолог\"", "country": " Україна"}'', ''["A10BB01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 30, 30, ''UA/2820/01/01'', ''2020-03-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''608434bd-cca6-4c1d-bc0e-fcb727da3d63'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "10.15"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''809659e7-b3c9-43bb-9212-db32fc7e20e5'', ''{"type": "FIXED", "reimbursement_amount": "10.15"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Glibenclamide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Глібенкламід 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d9eeb79f-e08a-4475-9da6-e0548afe9811'', ''Глібенкламід 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''f167fa4a-b269-41d4-9045-21fa3cc7e3d3'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'ГЛІБЕНКЛАМІД-ЗДОРОВ''Я'
    AND m.package_qty = 50
    AND m.certificate = 'UA/4647/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB01"]'::jsonb, 'UA/4647/01/01', '2020-10-26'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b2af45eb-1084-4f8d-a161-08cd20303d13'', ''ГЛІБЕНКЛАМІД-ЗДОРОВ''''Я'', ''BRAND'', ''{"name": "Товариство з обмеженою відповідальністю \"Фармацевтична компанія \"Здоров''''я\" ", "country": " Україна"}'', ''["A10BB01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 50, 50, ''UA/4647/01/01'', ''2020-10-26'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''ae03a265-6bb9-4024-af71-1a3f76b357da'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "16.92"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''4b9d5fbb-8be1-4364-b5dc-9e7c38af7638'', ''{"type": "FIXED", "reimbursement_amount": "16.92"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Glibenclamide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Глібенкламід 5 MG таблетки' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d9eeb79f-e08a-4475-9da6-e0548afe9811'', ''Глібенкламід 5 MG таблетки'', ''INNM_DOSAGE'', TRUE, ''TABLET'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''629d4e12-092a-4632-9154-49ed4f896005'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'TABLET'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 5
    AND m.name = 'ГЛІБЕНКЛАМІД'
    AND m.package_qty = 100
    AND m.certificate = 'UA/6631/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["A10BB01"]'::jsonb, 'UA/6631/01/01', '2020-10-26'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''584dddb9-46fb-4b41-98b8-1c0f459e20be'', ''ГЛІБЕНКЛАМІД'', ''BRAND'', ''{"name": "ПАТ \"Фармак\"", "country": " Україна"}'', ''["A10BB01"]'', true, ''TABLET'', ''{"numerator_unit": "PILL", "numerator_value": 1, "denumerator_unit": "PILL", "denumerator_value": "1"}'', 100, 100, ''UA/6631/01/01'', ''2020-10-26'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''4d11dfc5-048e-4157-8477-d24d407e7ff5'', ''{"numerator_unit": "MG", "numerator_value": "5", "denumerator_unit": "PILL", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "33.84"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''f6d16457-a889-4eab-814a-4460cf96a512'', ''{"type": "FIXED", "reimbursement_amount": "33.84"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Beclometasone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Беклометазон 100 MKG аерозоль для інгаляцій' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''409da0f7-ba15-46cb-8498-70328b81f291'', ''Беклометазон 100 MKG аерозоль для інгаляцій'', ''INNM_DOSAGE'', TRUE, ''AEROSOL_FOR_INHALATION'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''9eb0ff9e-69b2-460c-9e46-59fe39ee2ac2'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'AEROSOL_FOR_INHALATION'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'БЕКЛАЗОН-ЕКО'
    AND m.package_qty = 200
    AND m.certificate = 'UA/5384/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03BA01"]'::jsonb, 'UA/5384/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''d3058a84-61d0-4b40-9617-29af96b1524d'', ''БЕКЛАЗОН-ЕКО'', ''BRAND'', ''{"name": "Нортон (Ватерфорд) Лімітед Т/А АЙВЕКС Фармасьютикалз Ірландія Т/А Тева Фармасьютикалз Ірландія", "country": " Ірландія"}'', ''["R03BA01"]'', true, ''AEROSOL_FOR_INHALATION'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/5384/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''703b283e-c193-428d-b9f6-708cc1ee1792'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "89.48"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''cd657e8e-d588-4f5b-a916-dbf2520d7bd6'', ''{"type": "FIXED", "reimbursement_amount": "89.48"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Beclometasone' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Беклометазон 250 MKG аерозоль для інгаляцій, дозований' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''27a36923-1030-480e-a45e-ce34cd478044'', ''Беклометазон 250 MKG аерозоль для інгаляцій, дозований'', ''INNM_DOSAGE'', TRUE, ''AEROSOL_FOR_INHALATION_DOSED'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ab0991bd-5bf0-439e-a333-bc33821a4cf5'', ''{"numerator_unit": "MKG", "numerator_value": "250", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'AEROSOL_FOR_INHALATION_DOSED'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 250
    AND m.name = 'БЕКЛОФОРТ ЕВОХАЛЕР'
    AND m.package_qty = 200
    AND m.certificate = 'UA/1203/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03BA01"]'::jsonb, 'UA/1203/01/01', '2019-08-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''25ea5488-be7a-4bee-b304-162a87258a23'', ''БЕКЛОФОРТ ЕВОХАЛЕР'', ''BRAND'', ''{"name": "Глаксо Веллком Продакшн", "country": " Франція"}'', ''["R03BA01"]'', true, ''AEROSOL_FOR_INHALATION_DOSED'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/1203/01/01'', ''2019-08-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''0c279e28-bc56-4ff2-97bc-f00d360481e7'', ''{"numerator_unit": "MKG", "numerator_value": "250", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "223.69"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''9a15e5a0-49ce-4526-a8cd-fc0200b45fe5'', ''{"type": "FIXED", "reimbursement_amount": "223.69"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Budesonide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Будесонід 0.5 MG суспензія для розпилення' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''ff6e3c6c-80b3-495d-b2e4-b3ec98a98e9d'', ''Будесонід 0.5 MG суспензія для розпилення'', ''INNM_DOSAGE'', TRUE, ''NEBULISER_SUSPENSION'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''5bdc051f-96fe-4642-bde3-eba252f61967'', ''{"numerator_unit": "MG", "numerator_value": "0.5", "denumerator_unit": "ML", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'NEBULISER_SUSPENSION'
    AND i.dosage ->> 'numerator_unit' = 'MG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 0.5
    AND m.name = 'ПУЛЬМІКОРТ'
    AND m.package_qty = 40
    AND m.certificate = 'UA/5552/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03BA02"]'::jsonb, 'UA/5552/01/02', '2021-08-15'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8d8c91ed-9d06-4119-b0f4-c5d27a483d3d'', ''ПУЛЬМІКОРТ'', ''BRAND'', ''{"name": "АстраЗенека АБ", "country": " Швеція"}'', ''["R03BA02"]'', true, ''NEBULISER_SUSPENSION'', ''{"numerator_unit": "ML", "numerator_value": 1, "denumerator_unit": "CONTAINER", "denumerator_value": "1"}'', 40, 40, ''UA/5552/01/02'', ''2021-08-15'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''682e27c7-f0cc-48b4-a603-340abf92241e'', ''{"numerator_unit": "MG", "numerator_value": "0.5", "denumerator_unit": "ML", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "898.22"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e4fad6e4-a071-4dd9-92d7-ff9f1af0d874'', ''{"type": "FIXED", "reimbursement_amount": "898.22"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Budesonide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Будесонід 50 MKG інгаляція під тиском, суспензія' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''68a91768-c6c3-44fd-8998-2361df56eee1'', ''Будесонід 50 MKG інгаляція під тиском, суспензія'', ''INNM_DOSAGE'', TRUE, ''PRESSURISED_INHALATION'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''18bd1e0d-245e-4554-9217-f8e98d7f671d'', ''{"numerator_unit": "MKG", "numerator_value": "50", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'PRESSURIED_INHALATION_SUSPENSION'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 50
    AND m.name = 'БУДЕСОНІД-ІНТЕЛІ'
    AND m.package_qty = 200
    AND m.certificate = 'UA/12444/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03BA02"]'::jsonb, 'UA/12444/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''561e25c7-0f83-4c5d-bbe4-d8df217edc0f'', ''БУДЕСОНІД-ІНТЕЛІ'', ''BRAND'', ''{"name": "ЛАБОРАТОРІО АЛЬДО-ЮНІОН", "country": " Іспанія"}'', ''["R03BA02"]'', true, ''PRESSURISED_INHALATION'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/12444/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''097d8d43-39b1-42f0-9fb0-63a888dd3f70'', ''{"numerator_unit": "MKG", "numerator_value": "50", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "70.10"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''f99f8da8-a74b-4ff8-9093-ccebebf97fc4'', ''{"type": "FIXED", "reimbursement_amount": "70.10"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Budesonide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Будесонід 100 MKG порошок для інгаляцій' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''4b86085b-47ab-444b-9001-b2bf2c3870b0'', ''Будесонід 100 MKG порошок для інгаляцій'', ''INNM_DOSAGE'', TRUE, ''INHALATION_POWDER'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e5d86aa0-32b7-4b3a-b947-09b026be25b9'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'INHALATION_POWDER'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'ПУЛЬМІКОРТ ТУРБУХАЛЕР'
    AND m.package_qty = 200
    AND m.certificate = 'UA/5552/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03BA02"]'::jsonb, 'UA/5552/02/01', '2019-07-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''fae40d9f-5d3e-4a41-a88a-6d1419d7b00c'', ''ПУЛЬМІКОРТ ТУРБУХАЛЕР'', ''BRAND'', ''{"name": "АстраЗенека АБ", "country": " Швеція"}'', ''["R03BA02"]'', true, ''INHALATION_POWDER'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/5552/02/01'', ''2019-07-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''dd85348a-0c74-4948-92c4-acd3574b6a2e'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "140.21"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''78616a9d-eeaf-4539-837d-167449f7bc10'', ''{"type": "FIXED", "reimbursement_amount": "140.21"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Budesonide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Будесонід 200 MKG порошок для інгаляцій' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''18fb77f1-452c-4b1f-b059-ccd5223d2097'', ''Будесонід 200 MKG порошок для інгаляцій'', ''INNM_DOSAGE'', TRUE, ''INHALATION_POWDER'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''76db4742-efb3-4c5e-84c4-b1317fd980e6'', ''{"numerator_unit": "MKG", "numerator_value": "200", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'INHALATION_POWDER'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'ПУЛЬМІКОРТ ТУРБУХАЛЕР'
    AND m.package_qty = 100
    AND m.certificate = ' UA/5552/02/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03BA02"]'::jsonb, ' UA/5552/02/02', '2019-07-03'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''9810ba69-eaa6-42c9-b553-f27b5e337ac2'', ''ПУЛЬМІКОРТ ТУРБУХАЛЕР'', ''BRAND'', ''{"name": "АстраЗенека АБ", "country": " Швеція"}'', ''["R03BA02"]'', true, ''INHALATION_POWDER'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 100, 100, '' UA/5552/02/02'', ''2019-07-03'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''10386c3e-8b25-4f23-80b0-af9ed04fafe8'', ''{"numerator_unit": "MKG", "numerator_value": "200", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "140.21"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e6a6cf8a-d0d7-44ba-871b-0595ccde8627'', ''{"type": "FIXED", "reimbursement_amount": "140.21"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Budesonide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Будесонід 200 MKG порошок для інгаляцій' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''18fb77f1-452c-4b1f-b059-ccd5223d2097'', ''Будесонід 200 MKG порошок для інгаляцій'', ''INNM_DOSAGE'', TRUE, ''INHALATION_POWDER'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''26148032-7966-4ea0-9e45-a6fdb6799123'', ''{"numerator_unit": "MKG", "numerator_value": "200", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'INHALATION_POWDER'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'БУДЕСОНІД ІЗІХЕЙЛЕР'
    AND m.package_qty = 200
    AND m.certificate = 'UA/14857/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03BA02"]'::jsonb, 'UA/14857/01/01', '2021-08-15'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''094d88ef-282d-499e-99c3-c3f412e353c6'', ''БУДЕСОНІД ІЗІХЕЙЛЕР'', ''BRAND'', ''{"name": "Оріон Корпорейшн", "country": " Фінляндія"}'', ''["R03BA02"]'', true, ''INHALATION_POWDER'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/14857/01/01'', ''2021-08-15'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''19b68b9c-3fe8-4916-857b-29c3a755c801'', ''{"numerator_unit": "MKG", "numerator_value": "200", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "280.41"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''f0c2e1a5-faf2-47f4-a309-b326a28639bc'', ''{"type": "FIXED", "reimbursement_amount": "280.41"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Budesonide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Будесонід 200 MKG інгаляція під тиском, суспензія' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''b21eadb8-7e2b-4d04-8372-35b991d2e51f'', ''Будесонід 200 MKG інгаляція під тиском, суспензія'', ''INNM_DOSAGE'', TRUE, ''PRESSURISED_INHALATION'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''7f9fa786-f117-4921-823f-fcade9a4f99f'', ''{"numerator_unit": "MKG", "numerator_value": "200", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'PRESSURISED_INHALATION'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'БУДЕСОНІД-ІНТЕЛІ'
    AND m.package_qty = 200
    AND m.certificate = 'UA/12444/01/02';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03BA02"]'::jsonb, 'UA/12444/01/02', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''6a65dba2-53c3-440f-933b-230ec5a5ac82'', ''БУДЕСОНІД-ІНТЕЛІ'', ''BRAND'', ''{"name": "ЛАБОРАТОРІО АЛЬДО-ЮНІОН", "country": " Іспанія"}'', ''["R03BA02"]'', true, ''PRESSURISED_INHALATION'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/12444/01/02'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''a749973f-11d8-4ac4-a3b4-cb5d1b6189a4'', ''{"numerator_unit": "MKG", "numerator_value": "200", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "280.41"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''c497d95a-be54-452a-9386-8b370b8e651f'', ''{"type": "FIXED", "reimbursement_amount": "280.41"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Budesonide' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Будесонід 200 MKG порошок для інгаляцій' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''18fb77f1-452c-4b1f-b059-ccd5223d2097'', ''Будесонід 200 MKG порошок для інгаляцій'', ''INNM_DOSAGE'', TRUE, ''INHALATION_POWDER'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''ab9bbe4b-d913-462a-b5ed-3b3de5d5d1ce'', ''{"numerator_unit": "MKG", "numerator_value": "200", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'INHALATION_POWDER'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 200
    AND m.name = 'НОВОПУЛЬМОН Е НОВОЛАЙЗЕР®'
    AND m.package_qty = 200
    AND m.certificate = 'UA/4376/02/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03BA02"]'::jsonb, 'UA/4376/02/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''8ee38a68-f42e-4723-bad5-4f11d7366cf5'', ''НОВОПУЛЬМОН Е НОВОЛАЙЗЕР®'', ''BRAND'', ''{"name": "МЕДА Фарма ГмбХ енд Ко. КГ ", "country": " Німеччина"}'', ''["R03BA02"]'', true, ''INHALATION_POWDER'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/4376/02/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''dd8a9bbd-392e-4124-98be-53b7c3e87804'', ''{"numerator_unit": "MKG", "numerator_value": "200", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "280.41"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''c017d95d-badc-4845-88f8-c594e12e22bf'', ''{"type": "FIXED", "reimbursement_amount": "280.41"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Salbutamol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Сальбутамол 100 MKG інгаляція під тиском, суспензія' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''85c5409c-76dd-4bd2-b91d-97eb88de8841'', ''Сальбутамол 100 MKG інгаляція під тиском, суспензія'', ''INNM_DOSAGE'', TRUE, ''PRESSURISED_INHALATION'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''fa8eed88-dc48-4996-8599-81f971a29884'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'PRESSURISED_INHALATION'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'САЛЬБУТАМОЛ-ІНТЕЛІ'
    AND m.package_qty = 200
    AND m.certificate = 'UA/8338/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03AС02"]'::jsonb, 'UA/8338/01/01', '2100-01-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''10d97bc5-2ef0-4f1c-a8f4-3f7d3f8f70f1'', ''САЛЬБУТАМОЛ-ІНТЕЛІ'', ''BRAND'', ''{"name": "Лабораторіо Альдо-Юніон", "country": " Іспанія"}'', ''["R03AС02"]'', true, ''PRESSURISED_INHALATION'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/8338/01/01'', ''2100-01-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''acc326c1-03eb-4085-b259-022a6cc222cd'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "64.97"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''71b99d44-7969-4a09-a0be-74a46710abef'', ''{"type": "FIXED", "reimbursement_amount": "64.97"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Salbutamol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Сальбутамол 100 MKG інгаляція під тиском, суспензія' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''85c5409c-76dd-4bd2-b91d-97eb88de8841'', ''Сальбутамол 100 MKG інгаляція під тиском, суспензія'', ''INNM_DOSAGE'', TRUE, ''PRESSURISED_INHALATION'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''d3ea9277-77ef-4015-8d5b-cf04b6c9bdc4'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'PRESSURISED_INHALATION'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'САЛЬБУТАМОЛ '
    AND m.package_qty = 200
    AND m.certificate = 'UA/15683/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03AС02"]'::jsonb, 'UA/15683/01/01', '2021-12-30'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''47cf24c1-ec22-4fa8-a53f-edef2d5ba06f'', ''САЛЬБУТАМОЛ '', ''BRAND'', ''{"name": "ТОВ \"Мультіспрей\"", "country": " Україна"}'', ''["R03AС02"]'', true, ''PRESSURISED_INHALATION'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/15683/01/01'', ''2021-12-30'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''41b47bc9-3a55-4e91-8231-71c58df2596c'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "64.97"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''687d3647-0052-4aa4-9dcf-39122d37f7bd'', ''{"type": "FIXED", "reimbursement_amount": "64.97"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Salbutamol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Сальбутамол 100 MKG інгаляція під тиском' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''af8a264c-0ffc-4a53-b673-8ef14f07a0ca'', ''Сальбутамол 100 MKG інгаляція під тиском'', ''INNM_DOSAGE'', TRUE, ''PRESSURISED_INHALATION'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''8a572de0-7ad1-478d-b083-4b76c1d0a5a9'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'PRESSURISED_INHALATION'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'САЛЬБУТАМОЛ-НЕО'
    AND m.package_qty = 200
    AND m.certificate = 'UA/10530/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03AС02"]'::jsonb, 'UA/10530/01/01', '2020-09-04'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''a4cfc804-f689-4374-a08d-92939f398dab'', ''САЛЬБУТАМОЛ-НЕО'', ''BRAND'', ''{"name": "ТОВ \"Мікрофарм\"", "country": " Україна"}'', ''["R03AС02"]'', true, ''PRESSURISED_INHALATION'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/10530/01/01'', ''2020-09-04'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''2f6f4c36-7eea-4a01-bdbf-42a873c68297'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "64.97"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''e7e23a83-b1e2-41ac-b0f0-651df32113d9'', ''{"type": "FIXED", "reimbursement_amount": "64.97"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Salbutamol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Сальбутамол 100 MKG аерозоль для інгаляцій' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0423794a-fccc-41db-8926-b941a9a5a375'', ''Сальбутамол 100 MKG аерозоль для інгаляцій'', ''INNM_DOSAGE'', TRUE, ''AEROSOL_FOR_INHALATION'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''e48596f6-6132-497b-8eac-84c7e6601c44'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'AEROSOL_FOR_INHALATION'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'ВЕНТОЛІН ЕВОХАЛЕР'
    AND m.package_qty = 200
    AND m.certificate = 'UA/2563/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03AC02"]'::jsonb, 'UA/2563/01/01', '2019-09-24'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''39772104-de54-416a-8c1b-b2efefee4263'', ''ВЕНТОЛІН ЕВОХАЛЕР'', ''BRAND'', ''{"name": "Глаксо Веллком С.А.", "country": " Іспанія"}'', ''["R03AC02"]'', true, ''AEROSOL_FOR_INHALATION'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/2563/01/01'', ''2019-09-24'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''d697006b-ba4b-4b71-b7f2-f4fa6cc9f609'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "64.97"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''0a51ff23-3b68-45aa-bec6-d00abb767598'', ''{"type": "FIXED", "reimbursement_amount": "64.97"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


DO
$$DECLARE
    innm_id uuid;
    brand_id uuid;
    dosage_id uuid;
    program_medication_id uuid;
BEGIN
    SELECT i.id INTO innm_id FROM innms i WHERE i.is_active = TRUE AND i.name_original = 'Salbutamol' LIMIT 1;
    SELECT m.id INTO dosage_id FROM medications m WHERE m.is_active = TRUE AND m.name = 'Сальбутамол 100 MKG аерозоль для інгаляцій' LIMIT 1;

    IF dosage_id IS NULL THEN
        EXECUTE 'INSERT INTO medications (id, name, type, is_active, form, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0423794a-fccc-41db-8926-b941a9a5a375'', ''Сальбутамол 100 MKG аерозоль для інгаляцій'', ''INNM_DOSAGE'', TRUE, ''AEROSOL_FOR_INHALATION'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO dosage_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, innm_child_id, parent_id, inserted_at, updated_at) VALUES (''c0d1f0e6-02ca-41c5-8846-312f2a050cf7'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', TRUE, $1, $2, now(), now());' USING innm_id, dosage_id;
    END IF;

    SELECT m.id
    INTO brand_id
    FROM ingredients i, medications m
    WHERE i.parent_id = m.id
    AND m.type = 'BRAND'
    AND m.is_active = TRUE
    AND m.form = 'AEROSOL_FOR_INHALATION'
    AND i.dosage ->> 'numerator_unit' = 'MKG'
    AND (i.dosage ->> 'numerator_value')::NUMERIC = 100
    AND m.name = 'САЛЬБУТАМОЛ'
    AND m.package_qty = 200
    AND m.certificate = 'UA/2032/01/01';

    IF brand_id IS NOT NULL THEN
        EXECUTE 'UPDATE medications SET is_active = TRUE, code_atc = $1, certificate = $2, certificate_expired_at = $3 WHERE id = $4' USING '["R03AC02"]'::jsonb, 'UA/2032/01/01', '2019-08-01'::date, brand_id;
    ELSE
        EXECUTE 'INSERT INTO medications (id, name, type, manufacturer, code_atc, is_active, form, container, package_qty, package_min_qty, certificate, certificate_expired_at, inserted_by, updated_by, inserted_at, updated_at) VALUES (''0b632496-9958-436b-9dd8-a897b7dc0727'', ''САЛЬБУТАМОЛ'', ''BRAND'', ''{"name": "Глаксо Веллком Продакшн", "country": " Франція"}'', ''["R03AC02"]'', true, ''AEROSOL_FOR_INHALATION'', ''{"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "AEROSOL", "denumerator_value": "1"}'', 200, 200, ''UA/2032/01/01'', ''2019-08-01'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', now(), now()) RETURNING id' INTO brand_id;
        EXECUTE 'INSERT INTO ingredients (id, dosage, is_primary, medication_child_id, parent_id, inserted_at, updated_at) VALUES (''1468cc17-e62c-4291-bfc4-763b70def3c6'', ''{"numerator_unit": "MKG", "numerator_value": "100", "denumerator_unit": "DOSE", "denumerator_value": "1"}'', true, $1, $2, now(), now())' USING dosage_id, brand_id;
    END IF;

    SELECT id INTO program_medication_id FROM program_medications WHERE medication_id = brand_id AND is_active = TRUE AND medical_program_id = '63c1f32f-c8f4-4f5b-81a9-79b8452d6545';
    IF program_medication_id IS NOT NULL THEN
        EXECUTE 'UPDATE program_medications SET is_active = TRUE, reimbursement = $1 WHERE id = $2' USING '{"type": "FIXED", "reimbursement_amount": "64.97"}'::jsonb, program_medication_id;
    ELSE
        EXECUTE 'INSERT INTO program_medications (id, reimbursement, is_active, medication_request_allowed, inserted_by, updated_by, medication_id, medical_program_id, inserted_at, updated_at) VALUES (''9cdb7c32-f2d4-4fc6-b7d5-30982007ce2d'', ''{"type": "FIXED", "reimbursement_amount": "64.97"}'', true, true, ''4261eacf-8008-4e62-899f-de1e2f7065f0'', ''4261eacf-8008-4e62-899f-de1e2f7065f0'', $1, ''63c1f32f-c8f4-4f5b-81a9-79b8452d6545'', now(), now())' USING brand_id;
    END IF;
END$$;


UPDATE medications
SET container = jsonb_set(container, '{numerator_value}', to_jsonb((container ->> 'numerator_value')::NUMERIC));


UPDATE medications
SET container = jsonb_set(container, '{denumerator_value}', to_jsonb((container ->> 'denumerator_value')::NUMERIC));


UPDATE ingredients
SET dosage = jsonb_set(dosage, '{numerator_value}', to_jsonb((dosage ->> 'numerator_value')::NUMERIC));


UPDATE ingredients
SET dosage = jsonb_set(dosage, '{denumerator_value}', to_jsonb((dosage ->> 'denumerator_value')::NUMERIC));


UPDATE medications m
	SET form = 'PRESSURISED_INHALATION_SUSPENSION'
WHERE id IN (
	'6a65dba2-53c3-440f-933b-230ec5a5ac82',
	'561e25c7-0f83-4c5d-bbe4-d8df217edc0f',
	'47cf24c1-ec22-4fa8-a53f-edef2d5ba06f',
	'10d97bc5-2ef0-4f1c-a8f4-3f7d3f8f70f1'
);


UPDATE medications
		SET form = 'PRESSURISED_INHALATION_SUSPENSION'
WHERE name IN (
	'Будесонід 50 MKG інгаляція під тиском, суспензія',
	'Будесонід 200 MKG інгаляція під тиском, суспензія',
	'Сальбутамол 100 MKG інгаляція під тиском, суспензія'
)
AND is_active = TRUE ;


UPDATE program_medications
SET reimbursement = jsonb_set(reimbursement, '{reimbursement_amount}', to_jsonb((reimbursement ->> 'reimbursement_amount')::NUMERIC));

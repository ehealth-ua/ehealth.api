--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pglogical; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pglogical;


--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA topology;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE audit_log (
    id uuid NOT NULL,
    actor_id character varying(255) NOT NULL,
    resource character varying(255) NOT NULL,
    resource_id character varying(255) NOT NULL,
    changeset jsonb NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: divisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE divisions (
    id uuid NOT NULL,
    external_id character varying(255),
    name character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    mountain_group boolean,
    addresses jsonb NOT NULL,
    phones jsonb NOT NULL,
    email character varying(255),
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    legal_entity_id uuid,
    location geometry,
    status character varying(255) NOT NULL,
    is_active boolean DEFAULT false NOT NULL
);


--
-- Name: employee_doctors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE employee_doctors (
    id uuid NOT NULL,
    educations jsonb NOT NULL,
    qualifications jsonb,
    specialities jsonb NOT NULL,
    science_degree jsonb,
    employee_id uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: employees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE employees (
    id uuid NOT NULL,
    "position" character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    employee_type character varying(255) NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    inserted_by uuid NOT NULL,
    updated_by uuid NOT NULL,
    start_date date NOT NULL,
    end_date date,
    legal_entity_id uuid,
    division_id uuid,
    party_id uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status_reason character varying(255)
);


--
-- Name: global_parameters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE global_parameters (
    id uuid NOT NULL,
    parameter character varying(255) NOT NULL,
    value character varying(255) NOT NULL,
    inserted_by uuid NOT NULL,
    updated_by uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: legal_entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE legal_entities (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    short_name character varying(255),
    public_name character varying(255),
    status character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    owner_property_type character varying(255) NOT NULL,
    legal_form character varying(255) NOT NULL,
    edrpou character varying(255) NOT NULL,
    kveds jsonb NOT NULL,
    addresses jsonb NOT NULL,
    phones jsonb,
    email character varying(255),
    is_active boolean DEFAULT false NOT NULL,
    inserted_by uuid NOT NULL,
    updated_by uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    capitation_contract_id uuid,
    created_by_mis_client_id uuid,
    mis_verified character varying(255) DEFAULT 'NOT_VERIFIED'::character varying NOT NULL,
    nhs_verified boolean DEFAULT false NOT NULL
);


--
-- Name: medical_service_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE medical_service_providers (
    id uuid NOT NULL,
    accreditation jsonb,
    licenses jsonb,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    legal_entity_id uuid
);


--
-- Name: parties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE parties (
    id uuid NOT NULL,
    first_name character varying(255) NOT NULL,
    second_name character varying(255),
    last_name character varying(255) NOT NULL,
    birth_date date NOT NULL,
    gender character varying(255) NOT NULL,
    tax_id character varying(255) NOT NULL,
    documents jsonb,
    phones jsonb,
    inserted_by uuid NOT NULL,
    updated_by uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: party_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE party_users (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    party_id uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: ukr_med_registries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ukr_med_registries (
    id uuid NOT NULL,
    name character varying(255),
    edrpou character varying(255) NOT NULL,
    inserted_by uuid NOT NULL,
    updated_by uuid,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: divisions divisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY divisions
    ADD CONSTRAINT divisions_pkey PRIMARY KEY (id);


--
-- Name: employee_doctors employee_doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY employee_doctors
    ADD CONSTRAINT employee_doctors_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: global_parameters global_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY global_parameters
    ADD CONSTRAINT global_parameters_pkey PRIMARY KEY (id);


--
-- Name: legal_entities legal_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY legal_entities
    ADD CONSTRAINT legal_entities_pkey PRIMARY KEY (id);


--
-- Name: medical_service_providers medical_service_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY medical_service_providers
    ADD CONSTRAINT medical_service_providers_pkey PRIMARY KEY (id);


--
-- Name: party_users parties_party_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY party_users
    ADD CONSTRAINT parties_party_users_pkey PRIMARY KEY (id);


--
-- Name: parties parties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parties
    ADD CONSTRAINT parties_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: ukr_med_registries ukr_med_registries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ukr_med_registries
    ADD CONSTRAINT ukr_med_registries_pkey PRIMARY KEY (id);


--
-- Name: divisions_legal_entity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX divisions_legal_entity_id_index ON divisions USING btree (legal_entity_id);


--
-- Name: employee_doctors_employee_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employee_doctors_employee_id_index ON employee_doctors USING btree (employee_id);


--
-- Name: employees_division_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employees_division_id_index ON employees USING btree (division_id);


--
-- Name: employees_legal_entity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employees_legal_entity_id_index ON employees USING btree (legal_entity_id);


--
-- Name: employees_party_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employees_party_id_index ON employees USING btree (party_id);


--
-- Name: legal_entities_capitation_contract_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX legal_entities_capitation_contract_id_index ON legal_entities USING btree (capitation_contract_id);


--
-- Name: legal_entities_edrpou_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX legal_entities_edrpou_index ON legal_entities USING btree (edrpou);


--
-- Name: medical_service_providers_legal_entity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX medical_service_providers_legal_entity_id_index ON medical_service_providers USING btree (legal_entity_id);


--
-- Name: party_users_party_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX party_users_party_id_index ON party_users USING btree (party_id);


--
-- Name: ukr_med_registries_edrpou_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ukr_med_registries_edrpou_index ON ukr_med_registries USING btree (edrpou);


--
-- Name: divisions divisions_legal_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY divisions
    ADD CONSTRAINT divisions_legal_entity_id_fkey FOREIGN KEY (legal_entity_id) REFERENCES legal_entities(id);


--
-- Name: employee_doctors employee_doctors_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY employee_doctors
    ADD CONSTRAINT employee_doctors_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES employees(id);


--
-- Name: employees employees_division_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_division_id_fkey FOREIGN KEY (division_id) REFERENCES divisions(id);


--
-- Name: employees employees_legal_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_legal_entity_id_fkey FOREIGN KEY (legal_entity_id) REFERENCES legal_entities(id);


--
-- Name: employees employees_party_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_party_id_fkey FOREIGN KEY (party_id) REFERENCES parties(id);


--
-- Name: legal_entities legal_entities_capitation_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY legal_entities
    ADD CONSTRAINT legal_entities_capitation_contract_id_fkey FOREIGN KEY (capitation_contract_id) REFERENCES medical_service_providers(id);


--
-- Name: medical_service_providers medical_service_providers_legal_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY medical_service_providers
    ADD CONSTRAINT medical_service_providers_legal_entity_id_fkey FOREIGN KEY (legal_entity_id) REFERENCES legal_entities(id);


--
-- Name: party_users party_users_party_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY party_users
    ADD CONSTRAINT party_users_party_id_fkey FOREIGN KEY (party_id) REFERENCES parties(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" (version) VALUES (20170413123306), (20170413123307), (20170413123308), (20170413124601), (20170414155832), (20170417155741), (20170419075231), (20170419075232), (20170420110826), (20170421104735), (20170427103609), (20170427114030), (20170510164524), (20170510164543), (20170511133900), (20170511154159), (20170522114501), (20170523113838), (20170524080809), (20170525101522), (20170606171448), (20170606171954), (20170606203443), (20170607084728), (20170615114013), (20170615155026), (20170623132140), (20170704135447), (20170704143635), (20170720122501);


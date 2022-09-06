--+---------------------------------------------------------------------------------------------------------------------
--+ Соглашения
--+ https://wiki.og.mos.ru/pages/viewpage.action?pageId=9732100

--+ Необходимые таблицы:

--+ sdb.contract
----+ idb.contract
----+ idb.contract_property
----+ idb.contract_status_registry
--+---------------------------------------------------------------------------------------------------------------------

drop table if exists sdb.contract;
create table if not exists sdb.contract(
    aid bigint primary key,
    provider_id bigint,
    contract_number varchar,
    organization_id bigint,
    date_from varchar(10),
    date_to varchar(10),
    activity_id bigint,
    full_price bigint NULL
);

drop table if exists idb.contract;
CREATE TABLE if not exists idb.contract (
	id serial NOT NULL,
	provider_id int8 NULL,
	contract_number varchar NULL,
	organization_id int8 NULL,
	date_from date NULL,
	date_to date NULL,
	kbk varchar NULL,
	provider_bank_account_id int8 NULL,
	provider_manager_id int8 NULL,
	name_organization_id int8 NULL,
	parent_id int8 NULL,
	document_number varchar NOT NULL,
	organization_bank_account_id int8 NULL,
	CONSTRAINT contract_pkey PRIMARY KEY (id)
--	CONSTRAINT contract_organization_bank_account_id_fkey FOREIGN KEY (organization_bank_account_id) REFERENCES md.organization_bank_account(id),
--	CONSTRAINT fk_contract_name_organization_id FOREIGN KEY (name_organization_id) REFERENCES md.contact(id),
--	CONSTRAINT fk_contract_organization FOREIGN KEY (organization_id) REFERENCES md.organization(id) ON DELETE SET NULL,
--	CONSTRAINT fk_contract_parent_id FOREIGN KEY (parent_id) REFERENCES md.contract(id),
--	CONSTRAINT fk_contract_provider FOREIGN KEY (provider_id) REFERENCES md.organization(id) ON DELETE SET NULL,
--	CONSTRAINT fk_contract_provider_bank_account_id FOREIGN KEY (provider_bank_account_id) REFERENCES md.organization_bank_account(id),
--	CONSTRAINT fk_contract_provider_manager_id FOREIGN KEY (provider_manager_id) REFERENCES md.coworker(id)
);

drop table if exists idb.contract_property;
CREATE TABLE if not exists idb.contract_property (
	id bigserial NOT NULL,
	contract_id int8 NOT NULL,
	activity_id int8 NOT NULL,
	coverage int4 NULL,
	"scope" int4 NULL,
	man_hours int8 NULL,
	grant_value int8 NULL,
	CONSTRAINT contract_property_pkey PRIMARY KEY (id)
--	CONSTRAINT contract_property_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES reference.activity(id),
--	CONSTRAINT contract_property_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES md.contract(id)
);
--CREATE UNIQUE INDEX contract_property_contract_id_activity_id_uindex ON md.contract_property USING btree (contract_id, activity_id);

drop table if exists idb.contract_status_registry;
CREATE TABLE if not exists idb.contract_status_registry (
	id bigserial NOT NULL,
	contract_id int8 NOT NULL,
	status_id int8 NOT NULL,
	status_reason_id int8 NOT NULL,
	"comment" text NULL,
	start_date timestamp NULL,
	end_date timestamp NULL,
	idm_ent_user_profiles_id int8 NULL,
	planned_start_date date NULL,
	planned_end_date date NULL,
	CONSTRAINT contract_status_registry_pkey PRIMARY KEY (id)
--	CONSTRAINT contract_status_registry_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES md.contract(id),
--	CONSTRAINT contract_status_registry_status_id_fkey FOREIGN KEY (status_id) REFERENCES reference.contract_status(id),
--	CONSTRAINT contract_status_registry_status_reason_id_fkey FOREIGN KEY (status_reason_id) REFERENCES reference.contract_status_reason(id)
);
-- 25.06.2019
truncate table md.participant cascade;
truncate table reference.participant_status_log cascade;
truncate table md.personal_document cascade;

insert into ar.address_registry select * from idb.ar_address_registry on conflict do nothing;

insert into md.participant
select p.id,
			 first_name,
			 second_name,
			 patronymic,
			 no_patronymic,
			 date_of_birth,
			 gender,
			 snils,
			 skm,
			 registration_address,
			 fact_address,
			 required_documents,
			 occupation_id,
			 agreement,
			 documents_absence_reason_id,
			 p.sync,
			 skm_series,
			 o.id
from idb.participant p
			 left join md.organization o on p.organization_id = o.id;

insert into reference.participant_status_log select * from idb.ref_participant_status_log;

insert into md.personal_document select * from idb.personal_document;

insert into md.contact_owner select * from idb.contact_owner;-- where id in (select ow.id from idb.contact_owner ow join idb.contact c on c.owner_id=ow.id where c.contact_owner_type_id=1);
insert into md.contact select * from idb.contact;-- c where c.contact_owner_type_id=1;

insert into md.participant_organization select * from idb.participant_organization
where participant_id in (select id from md.participant);
insert into md.participant_organization_history select * from idb.participant_organization_history
where participant_organization_id in (select id from md.participant_organization);
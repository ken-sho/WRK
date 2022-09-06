-- 25.06.2019

truncate table md.organization cascade;
truncate table reference.recurrence_schedule cascade;
truncate table reference.department cascade;

truncate table md.contact_owner cascade;
truncate table md.contact cascade;
truncate table md.territory_organization cascade;

insert into reference.department select * from idb.ref_department;

insert into md.organization (
	select * from idb.organization o where (o.parent_organization_id is null or o.parent_organization_id in (select id from idb.organization))
	and o.department_id in (select id from idb.ref_department)
) on conflict do nothing;

insert into reference.recurrence_schedule (
	select * from idb.ref_recurrence_schedule s where s.organization_id in (select id from md.organization)
);

insert into md.territory_organization select * from idb.territory_organization;

-- вставляются в participant
-- insert into md.contact_owner select * from idb.contact_owner where id in (select ow.id from idb.contact_owner ow join idb.contact c on c.owner_id=ow.id where c.contact_owner_type_id=4);
-- insert into md.contact select * from idb.contact c where c.contact_owner_type_id=4;
-- 25.06.2019
truncate table md.coworker cascade;
-- delete from md.contact c where c.contact_owner_type_id=2;
-- delete from md.contact_owner where id in (select ow.id from md.contact_owner ow join md.contact c on c.owner_id=ow.id where c.contact_owner_type_id=2);

-- update idb.coworkers set second_name=md5('wqddqw') where second_name is null;

insert into md.coworker
select * from idb.coworkers c
where c.organization_id in (select id from md.organization) on conflict do nothing;

-- вставляются в participant
-- insert into md.contact_owner select * from idb.contact_owner where id in (select ow.id from idb.contact_owner ow join idb.contact c on c.owner_id=ow.id where c.contact_owner_type_id=2);
-- insert into md.contact select * from idb.contact c where c.contact_owner_type_id=2;

insert into md.coworker (first_name, second_name, is_teacher, is_deputy, is_director, is_coordinator) values ('Архивный', 'Преподаватель', true, false, false, false);
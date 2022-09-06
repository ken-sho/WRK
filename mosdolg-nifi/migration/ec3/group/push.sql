-- 05.09.2019
truncate table md.groups cascade;
truncate table md.group_status_registry cascade;
truncate table md.schedule cascade;
truncate table md.week_day_schedule cascade;
truncate table md.class_record cascade;
truncate table md.class_record_status_registry cascade;

truncate table md.group_contraindication;
truncate table md.group_dress_code;
truncate table md.group_inventory_requirement;
-- truncate table reference.contraindication;
-- truncate table reference.dress_code;
-- truncate table reference.inventory_requirement;

insert into md.groups
select g.id,
			 need_note,
			 min_count,
			 max_count,
			 fact_count,
			 plan_start_date,
			 plan_end_date,
			 fact_start_date,
			 fact_end_date,
			 extend,
			 g.organization_id,
			 activity_id,
			 "comment",
			 md.coworker.id as coworker_id,
			 g.sync,
			 md.contract.id as contract_id,
			 o.id as territory_centre_id,
			 esz_code,
			 order_date,
			 public_date
from idb.groups g
			 left join md.contract on g.contract_id = md.contract.id
			 left join md.coworker on g.coworker_id = md.coworker.id
			 left join md.organization o on g.territory_centre_id = o.id
;
--   g where
-- 	(g.contract_id is null or g.contract_id in (select id from md.contract))
-- 	and (g.coworker_id is null or g.coworker_id in (select id from md.coworker));

insert into md.group_status_registry (
	id, group_id, status_id, start_date, end_date, is_expectation, planned_start_date, planned_end_date, reason_id, comment
) select
	r.id, r.group_id, r.status_id, r.start_date, r.end_date, r.is_expectation, r.planned_start_date, r.planned_end_date, r.reason_id, r.comment
from idb.group_status_registry r where r.group_id in (select id from md.groups);

--insert into md.schedule select * from idb.schedule r where r.group_id in (select id from md.groups);

--insert into md.week_day_schedule select * from idb.week_day_schedule r where r.schedule_id in (select id from md.schedule);

insert into md.class_record select * from idb.class_record r where
	r.group_id in (select id from md.groups) and
	r.participant_activity_profile_id in (select id from idb.participant_activity_profile) and
	r.participant_id in (select id from md.participant);

insert into md.class_record_status_registry(
    id, class_record_id, end_date, start_date, class_record_status_id, planned_start_date, planned_end_date, reason, comment
) select
    r.id, r.class_record_id, r.end_date, r.start_date, class_record_status_id, r.planned_start_date, r.planned_end_date, r.reason, r.comment
from idb.class_record_status_registry r where r.class_record_id in (select id from md.class_record);

insert into reference.contraindication select * from idb.ref_contraindication on conflict do nothing;
insert into reference.dress_code(id, title, legacy) select * from idb.ref_dress_code on conflict do nothing;
insert into reference.inventory_requirement select * from idb.ref_inventory_requirement on conflict do nothing;

insert into md.group_contraindication select * from idb.group_contraindication
																			where group_id in (select id from md.groups);
insert into md.group_dress_code select * from idb.group_dress_code
																where group_id in (select id from md.groups);
insert into md.group_inventory_requirement select * from idb.group_inventory_requirement
																					 where group_id in (select id from md.groups);
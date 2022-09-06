-- 18.09
-- Участники и группы в приостановке
-- https://wiki.og.mos.ru/pages/viewpage.action?pageId=14026996

do $$
DECLARE
	row record;
	initiator int;
	current_status_id bigint;
BEGIN
for row in
    select
        gm.id as group_id,
        am.id as activity_aid,
        pc.start_date as start_date
        from sdb.paused_groups pc
        join idb.groups_map gm on pc.group_aid=gm.aid
        join idb.ref_activity_map am on am.aid=pc.activity_aid
  	where pc.start_date >= current_date
loop

-- select id from md.coworkers where idm_sid = 'admin';

delete from idb.group_status_registry where group_id = row.group_id;

insert into idb.group_status_registry(
    id,
    group_id,
    status_id,
    reason_id,
    comment,
    start_date,
    -- end_date,
    is_expectation,
    --initiator,
    created,
    operation,
    planned_start_date,
    planned_end_date
) values (
    nextval('idb.group_status_registry_id_seq'),
    row.group_id,
    9,
    11,
    'Каникулы',
    to_date(row.start_date, 'YYYY-MM-DD'),
    -- row.end_date - interval '1' hour,
    false,
    -- coworker,
    now(),
    'PAUSE',
    to_date(row.start_date, 'YYYY-MM-DD'),
    to_timestamp ('2019-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
);

end loop;
END
$$ language plpgsql;

delete from idb.class_record_status_registry r where r.class_record_id in (
select
	cr.id as class_record_id
    from sdb.paused_class_records pc
    join idb.groups_map gm on pc.group_aid=gm.aid
    join idb.ref_activity_map am on am.aid=pc.activity_aid
    join idb.participant_map pm on pm.aid=pc.participant_aid
    join idb.class_record cr on cr.participant_id=pm.id and cr.group_id=gm.id
    order by gm.id, am.id, pc.date_to
);

do $$
DECLARE
	row record;
BEGIN
for row in
    select
    distinct cr.id as class_record_id,
	max(to_date(pc.date_to, 'YYYY-MM-DD')) as start_date
    from sdb.paused_class_records pc
    join idb.groups_map gm on pc.group_aid=gm.aid
    join idb.ref_activity_map am on am.aid=pc.activity_aid
    join idb.participant_map pm on pm.aid=pc.participant_aid
    join idb.class_record cr on cr.participant_id=pm.id and cr.group_id=gm.id
    group by cr.id
loop

insert into idb.class_record_status_registry(
    id,
    class_record_id,
    class_record_status_id,
    comment,
    start_date,
    reason,
    planned_start_date,
    planned_end_date
) values (
    nextval('idb.class_record_status_registry_id_seq'),
    row.class_record_id,
    2,
    'Каникулы',
    row.start_date,
    10,
    row.start_date,
    to_timestamp ('2019-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
);

end loop;
END
$$ language plpgsql;
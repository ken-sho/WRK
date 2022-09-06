-- 02.10
-- Участники и группы в приостановке с учётом статусов
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
  	where to_date(pc.start_date, 'YYYY-MM-DD') >= current_date
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

-- здесь не удаляем и вставляем запись, а в два update меняем нужные нам статусы

-----Одиночные записи со статусом 5(Отчислен) меняем на статус 2(Приостановка)
with L0 as (select array_agg(cr.id)                       as class_record_ids,
                   array_agg(crsr.class_record_status_id)    statuses,
                   max(to_date(pc.date_to, 'YYYY-MM-DD')) as start_date
            from sdb.paused_class_records pc
                     join idb.groups_map gm on pc.group_aid = gm.aid
                     join idb.ref_activity_map am on am.aid = pc.activity_aid
                     join idb.participant_map pm on pm.aid = pc.participant_aid
                     join idb.class_record cr on cr.participant_id = pm.id and cr.group_id = gm.id
                     join idb.class_record_status_registry crsr on cr.id = crsr.class_record_id
            group by cr.participant_id, cr.group_id
            having array_length(array_agg(cr.id), 1) = 1
               and (array_agg(crsr.class_record_status_id))[1] = 5
            )
update idb.class_record_status_registry
        set class_record_status_id = 2,
            comment                = 'Каникулы',
            start_date             = L0.start_date,
            reason                 = 10,
            planned_start_date     = L0.start_date,
            planned_end_date       = to_timestamp('2019-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS'),
            end_date               = null

from L0
where class_record_id=L0.class_record_ids[1];

---если все записи по участнику имеют статус 5(Отчислен), тогда одной из записей меняем статус на 2(Приостановка)
with L0 as (select array_agg(cr.id)                       as class_record_ids,
                   array_agg(crsr.class_record_status_id)    statuses,
                   max(to_date(pc.date_to, 'YYYY-MM-DD')) as start_date
            from sdb.paused_class_records pc
                     join idb.groups_map gm on pc.group_aid = gm.aid
                     join idb.ref_activity_map am on am.aid = pc.activity_aid
                     join idb.participant_map pm on pm.aid = pc.participant_aid
                     join idb.class_record cr on cr.participant_id = pm.id and cr.group_id = gm.id
                     join idb.class_record_status_registry crsr on cr.id = crsr.class_record_id
            group by cr.participant_id, cr.group_id
            having array_length(array_agg(cr.id), 1) > 1
               and 5 = all (array_agg(crsr.class_record_status_id))
            )
update idb.class_record_status_registry
        set class_record_status_id = 2,
            comment                = 'Каникулы',
            start_date             = L0.start_date,
            reason                 = 10,
            planned_start_date     = L0.start_date,
            planned_end_date       = to_timestamp('2019-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS'),
            end_date               = null
from L0
where class_record_id=L0.class_record_ids[1];

---update для группы в статусе 8 и записей в группу в статусе 1,3
with L0 as ( --записи в группу
            select crsr.id as crsr_id
            from idb.group_status_registry gsr
                    join idb.class_record cr using (group_id)
                    join idb.class_record_status_registry crsr on cr.id = crsr.class_record_id
            where gsr.status_id = 8
            and crsr.class_record_status_id in (1, 3)
            )
update idb.class_record_status_registry
    set class_record_status_id=6
from L0
where id = L0.crsr_id;

---update для группы  в статусе 13 и записей в группу в статусе !=5
with L0 as ( --записи в группу
            select crsr.id as crsr_id
            from idb.group_status_registry gsr
                    join idb.class_record cr using (group_id)
                    join idb.class_record_status_registry crsr on cr.id = crsr.class_record_id
            where gsr.status_id = 13
            and crsr.class_record_status_id != 5
            )
update idb.class_record_status_registry
    set class_record_status_id=8
from L0
where id = L0.crsr_id;
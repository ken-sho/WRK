DO $$
DECLARE
    r record;
    group_status reference.group_status%rowtype;
    new_class_record_status bigint;
BEGIN
    FOR r IN
        select distinct cr.participant_id as pid, cr.group_id as gid, cr.id as crid, crsr.* from md.participant p
            join reference.participant_status_log psl on p.id = psl.participant_id and psl.end_date is null
            join reference.participant_status ps on psl.status_id = ps.id
            join md.class_record cr on p.id = cr.participant_id
            join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
                                                             and crsr.end_date is null
                                                             and crsr.start_date is not null
                                                             and crsr.class_record_status_id not in (4, 5, 8, 9)
        where ps.key in ('rejection', 'self_rejection')
    LOOP
        raise notice 'Update class_record (id = %) status for participant (id = %) in group (id = %)', r.crid, r.pid, r.gid;
        update md.class_record_status_registry set end_date = start_date where id = r.id;
        select gs.*
        into STRICT group_status
        from md.groups g
            join md.group_status_registry gsr on g.id = gsr.group_id
                                                     and gsr.end_date is null
                                                     and gsr.start_date is not null
                                                     and is_expectation is false
            join reference.group_status gs on gsr.status_id = gs.id
        where g.id = r.gid
        limit 1;
        raise notice 'Group (id = %) now in status "%"', r.gid, group_status.title;
        if group_status.key in ('CREATED_COLLECT', 'CREATED_COLLECT_EXTENDED', 'CREATED_NOTIFY', 'WAITING') then
            new_class_record_status = 4;
        else
            new_class_record_status = 5;
        end if;
        raise notice 'Update class record (id = %) with new status (id = %)', r.class_record_id, new_class_record_status;
        insert into md.class_record_status_registry (class_record_id, class_record_status_id, comment, start_date, end_date, reason, planned_start_date, planned_end_date, supporting_class_record_id) VALUES
            (r.class_record_id, new_class_record_status, null, r.start_date, null, (select id from reference.class_record_status_reason res where res.class_record_status_id = new_class_record_status and title = 'Другое'), null, null, null);
    END LOOP;
END$$;
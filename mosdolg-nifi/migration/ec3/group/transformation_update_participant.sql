do $$
declare
begin
    -- создано 3
    update idb.ref_participant_status_log rpsl set status_id = 3 where rpsl.status_id != 1 and rpsl.participant_id in (
        select p.id from idb.participant p left join idb.participant_activity_profile p2 on p.id = p2.participant_id
        where p2.participant_id is null
    ) and rpsl.participant_id in (
        select xx.participant_id from (
            select
            participant_id,
            sum(case when crsr.class_record_status_id = 6 then 1 else 0 end) as sum6,
            sum(case when crsr.class_record_status_id = 2 then 1 else 0 end) as sum2
            from idb.class_record cr
              inner join idb.class_record_status_registry crsr
              on cr.id = crsr.class_record_id
            group by participant_id
        ) xx
        where
        xx.sum6 = 0 and xx.sum2 = 0
    );
    
    -- подбор направления 4
    update idb.ref_participant_status_log rpsl set status_id = 4 where rpsl.status_id != 1 and rpsl.participant_id in (
        select p.id from idb.participant p left join idb.participant_activity_profile p2 on p.id = p2.participant_id
      where p2.participant_id is not null
      union
      select xx.participant_id from (
            select
            participant_id,
            sum(case when crsr.class_record_status_id = 6 then 1 else 0 end) as sum6,
            sum(case when crsr.class_record_status_id = 2 then 1 else 0 end) as sum2
            from idb.class_record cr
              inner join idb.class_record_status_registry crsr
              on cr.id = crsr.class_record_id
            group by participant_id
        ) xx
        where
        xx.sum6 = 0 and xx.sum2 = 0
    );
    
    
    -- "приступил к занятиям" 7
    update idb.ref_participant_status_log rpsl set status_id = 7 where rpsl.status_id != 1 and rpsl.participant_id in (
      select participant_id from idb.class_record cr
      inner join idb.class_record_status_registry crsr
        on cr.id = crsr.class_record_id and crsr.class_record_status_id = 6
    );
    
    -- приостановка 5
    update idb.ref_participant_status_log rpsl set status_id = 5 where rpsl.status_id != 1 and rpsl.participant_id in (select xx.participant_id from (
        select
        participant_id,
        sum(case when crsr.class_record_status_id = 6 then 1 else 0 end) as sum6,
        sum(case when crsr.class_record_status_id = 2 then 1 else 0 end) as sum2
        from idb.class_record cr
          inner join idb.class_record_status_registry crsr
          on cr.id = crsr.class_record_id
        group by participant_id
    ) xx
    where
    xx.sum6 = 0
    and xx.sum2 > 1);
    
    -- создано 3, если не присвоен другой статус
    update idb.ref_participant_status_log rpsl set status_id = 3 where `rpsl.status_id is nul`l;
end
$$ language plpgsql;

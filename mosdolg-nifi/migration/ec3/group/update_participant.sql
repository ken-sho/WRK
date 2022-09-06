
update reference.participant_status_log rpsl set status_id = 3 where rpsl.status_id != 1 and rpsl.participant_id in (
	select p.id from md.participant p left join md.participant_activity_profile p2 on p.id = p2.participant_id
	where p2.participant_id is null
);

-- подбор направления
update reference.participant_status_log rpsl set status_id = 4 where rpsl.status_id != 1 and rpsl.participant_id in (
	select p.id from md.participant p left join md.participant_activity_profile p2 on p.id = p2.participant_id
  where p2.participant_id is not null
);

-- "приступил к занятиям"
update reference.participant_status_log rpsl set status_id = 7 where rpsl.status_id != 1 and rpsl.participant_id in (
  select participant_id from md.class_record cr
  inner join md.class_record_status_registry crsr
    on cr.id = crsr.class_record_id and crsr.class_record_status_id = 6
);

update reference.participant_status_log rpsl set status_id = 3 where rpsl.status_id is null;
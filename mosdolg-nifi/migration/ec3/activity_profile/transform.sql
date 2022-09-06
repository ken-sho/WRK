drop function if exists idb.get_participant_activity_profile_id;
create or replace function idb.get_participant_activity_profile_id(in ec3_aid bigint, in act_id bigint) returns bigint as
$$
declare
    result bigint;
    mid bigint;
begin
	if ec3_aid isnull or act_id isnull then
		return null;
	end if;
    select m.id into result from idb.participant_activity_profile_map m where m.aid = ec3_aid and m.activity_id = act_id;
    if result isnull then
        select nextval('idb.participant_activity_profile_id_seq') into result;
        insert into idb.participant_activity_profile_map(id, aid, activity_id) values (result, ec3_aid, act_id);
    end if;
    return result;
end;
$$ language plpgsql;

truncate table idb.ref_activity;
truncate table idb.participant_activity_profile;
truncate table idb.participant_activity_profile_preferred_daytime;
truncate table idb.participant_activity_profile_weekday;

--+---------------------------------------------------------------------------------------------------------------------
--+ перенос данных для справочника Направления (reference.activity)
--+---------------------------------------------------------------------------------------------------------------------
insert into idb.ref_activity(id, title, parent_id)
select
    idb.get_map_activity_id(ta.aid),
    ta.title,
    idb.get_map_activity_id(ta.parent_id)
from sdb.ref_activity ta left join idb.ref_activity_map m on m.aid = ta.aid order by ta.parent_id
on conflict (id) do update set title = excluded.title, parent_id = excluded.parent_id;

--+---------------------------------------------------------------------------------------------------------------------
--+ вносит данные в idb.participant_activity_profile, idb.participant_activity_profile_preferred_daytime,
--+ idb.participant_activity_profile_weekday
--+---------------------------------------------------------------------------------------------------------------------
do $$
declare
    cur cursor for select * from sdb.participant_activity_profile;
    paid bigint;
    pid bigint;
    daytimeId bigint;
    indx bigint;
    days bigint array;
    cl bigint;
    classificators int array[3];
begin
    for row in cur loop
        pid := idb.get_participant_by_ec3(row.participant_id);

        if pid is not null then
            classificators := array[row.first_classificator, row.second_classificator, row.third_classificator];
            foreach cl in array classificators loop
                if cl is not null then

                    paid := idb.get_participant_activity_profile_id(row.aid, cl);

                    if paid is not null then
                        insert into idb.participant_activity_profile(
                            id,
                            activity_id,
                            participant_id,
                            date_from,
                            comment,
                            status_id
                        ) values (
                            paid,
                            idb.get_map_activity_id(cl),
                            pid,
                            to_date(row.date_from, 'YYYY-MM-DD'),
                            row.comment,
                            1
                        ) on conflict do nothing;

                       	daytimeId := idb.get_daytime(row.schedule_type_id);
                        if daytimeId is not null then
                            insert into idb.participant_activity_profile_preferred_daytime(activity_id, preferred_daytime_id) values (paid, daytimeId)
                           	on conflict do nothing;
                    	end if;

                        days := idb.get_profile_active_weekdays_by_typeid(row.week_days_type_id);
                        if days is not null then
                            foreach indx in array days loop
                                insert into idb.participant_activity_profile_weekday(activity_id, weekday) values (paid, indx)
                                on conflict do nothing;
                            end loop;
                    	end if;
                    end if;

                end if;
            end loop;
        end if;
    end loop;
end $$ language plpgsql;
-- 25.06.2019
truncate table reference.activity cascade;
truncate table md.participant_activity_profile cascade;
truncate table md.participant_activity_profile_preferred_daytime cascade;
truncate table md.participant_activity_profile_weekday cascade;

insert into reference.activity select *, 1 as activity_type from idb.ref_activity;

insert into md.participant_activity_profile select * from idb.participant_activity_profile p where p.participant_id in (select id from md.participant) and activity_id in (select id from idb.ref_activity);

insert into md.participant_activity_profile_preferred_daytime select * from idb.participant_activity_profile_preferred_daytime p where p.activity_id in (select id from md.participant_activity_profile);

insert into md.participant_activity_profile_weekday select * from idb.participant_activity_profile_weekday p where p.activity_id in (select id from md.participant_activity_profile);

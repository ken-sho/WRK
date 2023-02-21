-- start
CREATE EXTENSION dblink;
-- connection
select dblink_connect_u('conn3', 'hostaddr=127.0.0.1 port=5432 dbname=local_idm user=postgres password=123');
-- create view
CREATE VIEW idm_ent_user_profile AS
select ent_user_profiles.userid, ent_user_profiles.login
from dblink('conn3', 'SELECT userid, login FROM public.ent_user_profiles;')
         as ent_user_profiles(
                              userid int8,
                              login varchar(255)
        );
--update communication_history
UPDATE md.communication_history ch
SET coworker_id = (
    select idm_ent_user_profile.userid
    from idm_ent_user_profile
    where ch.coworker_id = idm_ent_user_profile.login
)
WHERE coworker_id ~* '[a-zA-Z]+' and coworker_id in (
    select idm_ent_user_profile.login from idm_ent_user_profile
);
-- update participant_organization_history
UPDATE md.participant_organization_history poh
SET created_by = (
    select idm_ent_user_profile.userid
    from idm_ent_user_profile
    where poh.created_by = idm_ent_user_profile.login
)
WHERE created_by ~* '[a-zA-Z]+' and created_by in (
    select idm_ent_user_profile.login from idm_ent_user_profile
);
-- drop view
drop view idm_ent_user_profile;
-- end
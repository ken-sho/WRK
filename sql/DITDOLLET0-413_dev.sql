-- start
CREATE EXTENSION dblink;
-- connection
select dblink_connect_u('conn', 'hostaddr=127.0.0.1 port=15432 dbname=idm user=idm_user password=password');
-- create view
CREATE VIEW idm_ent_user_profile AS
select ent_user_profiles.userid, ent_user_profiles.login
from dblink('conn', 'SELECT userid, login FROM public.ent_user_profiles;')
         as ent_user_profiles(
                              userid int8,
                              login varchar(255)
        );
--update attendance data
UPDATE md.attendance_data ad
SET user_id = (
    select idm_ent_user_profile.userid
    from idm_ent_user_profile
    where ad.user_id = idm_ent_user_profile.login
)
WHERE user_id ~* '[a-zA-Z]+' and user_id in (
    select idm_ent_user_profile.login from idm_ent_user_profile
);
-- drop view
drop view idm_ent_user_profile;
-- end
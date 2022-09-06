--+---------------------------------------------------------------------------------------------------------------------
--+ Файл не актуален в связи с переносом в extract
--+---------------------------------------------------------------------------------------------------------------------

--+---------------------------------------------------------------------------------------------------------------------
--+ Для таблицы idb.ent_user (БД idm)
--+---------------------------------------------------------------------------------------------------------------------
select
    aid as id,
    split_part(name, ' ', 1) as lastname,
    split_part(name, ' ', 2) firstname,
    split_part(name, ' ', 3) as middlename,
    email,
    phone,
    creation_date,
    last_login
from sdb.ent_users;

--+---------------------------------------------------------------------------------------------------------------------
--+ Для таблицы idb.ent_user_profile (БД idm)
--+---------------------------------------------------------------------------------------------------------------------
select
    aid as userid,
    login,
    concat(password_hash, '#', password_salt) as password,
    password_last_change_date
from sdb.ent_users;

--+---------------------------------------------------------------------------------------------------------------------
--+ Для таблицы idb.ent_user_lock
--+---------------------------------------------------------------------------------------------------------------------
select
    aid as user_id,
    lock_form,
    (case when user_status_id=2 and is_blocked_by_auth_attempts=1 then 'AUTH_MAX_ATTEMPT' else null end) as type
from sdb.ent_users;

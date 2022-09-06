-- Запрос в блоке from общий
--     select
--        u.Id as aid,
--        u.Name as name,
--        u.Email as email,
--        u.Phone as phone,
--        u.PlaceWorkId as organization_id,
--        u.DateCreate as creation_date,
--        u.LastLoginTime as last_login,
--        u.Login as login,
--        u.UserStatusId as user_status_id,
--        u.IsBlockedByAuthAttempts as is_blocked_by_auth_attempts,
--        u.BlockedTime as lock_form,
--        u.PasswordHash as password_hash,
--        u.PasswordSole as password_salt,
--        u.PasswordDateChange as password_last_change_date
--    from esz.User u inner join esz.UserRoleRel ur on ur.UserId = u.Id
--    where ur.RoleId in (233,230,227,225,221,217) and (u.IsArchive is null or u.IsArchive=0)

-- +--------------------------------------------------------------------------------------------------------------------
-- + Выборка из таблицы esz.User для сущности Пользователи для таблицы sdb.ent_user
-- +--------------------------------------------------------------------------------------------------------------------
select
    aid as id,
    substring_index(name, ' ', 1) as lastname,
    substring_index(substring_index(name, ' ', 2), ' ', -1) firstname,
    substring_index(substring_index(name, ' ', 3), ' ', -1) as middlename,
    email,
    phone,
    creation_date,
    last_login
from (select
        distinct u.Id as aid,
        u.Name as name,
        u.Email as email,
        u.Phone as phone,
        u.PlaceWorkId as organization_id,
        u.DateCreate as creation_date,
        u.LastLoginTime as last_login,
        u.Login as login,
        u.UserStatusId as user_status_id,
        u.IsBlockedByAuthAttempts as is_blocked_by_auth_attempts,
        u.BlockedTime as lock_form,
        u.PasswordHash as password_hash,
        u.PasswordSole as password_salt,
        u.PasswordDateChange as password_last_change_date
    from esz.User u inner join esz.UserRoleRel ur on ur.UserId = u.Id
    where ur.RoleId in (233,230,227,225,221,217) and (u.IsArchive is null or u.IsArchive=0)) xx;

-- +---------------------------------------------------------------------------------------------------------------------
-- + Для таблицы sdb.ent_user_profile (БД idm)
-- +---------------------------------------------------------------------------------------------------------------------
select
    aid as userid,
    login,
    concat(password_hash, '#', password_salt) as password,
    password_last_change_date
from (select
        distinct u.Id as aid,
        u.Name as name,
        u.Email as email,
        u.Phone as phone,
        u.PlaceWorkId as organization_id,
        u.DateCreate as creation_date,
        u.LastLoginTime as last_login,
        u.Login as login,
        u.UserStatusId as user_status_id,
        u.IsBlockedByAuthAttempts as is_blocked_by_auth_attempts,
        u.BlockedTime as lock_form,
        u.PasswordHash as password_hash,
        u.PasswordSole as password_salt,
        u.PasswordDateChange as password_last_change_date
    from esz.User u inner join esz.UserRoleRel ur on ur.UserId = u.Id
    where ur.RoleId in (233,230,227,225,221,217) and (u.IsArchive is null or u.IsArchive=0)) xx;

-- +---------------------------------------------------------------------------------------------------------------------
-- + Для таблицы sdb.ent_user_lock
-- +---------------------------------------------------------------------------------------------------------------------
select
    aid as user_id,
    lock_form as lock_from,
    (case when user_status_id=2 and is_blocked_by_auth_attempts=1 then 'AUTH_MAX_ATTEMPT' else null end) as type
from (select
        distinct u.Id as aid,
        u.Name as name,
        u.Email as email,
        u.Phone as phone,
        u.PlaceWorkId as organization_id,
        u.DateCreate as creation_date,
        u.LastLoginTime as last_login,
        u.Login as login,
        u.UserStatusId as user_status_id,
        u.IsBlockedByAuthAttempts as is_blocked_by_auth_attempts,
        u.BlockedTime as lock_form,
        u.PasswordHash as password_hash,
        u.PasswordSole as password_salt,
        u.PasswordDateChange as password_last_change_date
    from esz.User u inner join esz.UserRoleRel ur on ur.UserId = u.Id
    where ur.RoleId in (233,230,227,225,221,217) and (u.IsArchive is null or u.IsArchive=0)) xx;


-- +-----------
-- + Для ролей
-- +-----
select
    u.Id as aid,
    ur.RoleId as role_id
from esz.User u inner join esz.UserRoleRel ur on ur.UserId = u.Id
where ur.RoleId in (233,230,227,225,221,217) and (u.IsArchive is null or u.IsArchive=0);
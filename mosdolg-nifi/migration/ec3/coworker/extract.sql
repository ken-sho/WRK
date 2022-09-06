-- +--------------------------------------------------------------------------------------------------------------------
-- + Выборка из таблицы esz.User
-- +--------------------------------------------------------------------------------------------------------------------
select
distinct u.Id as aid,
trim(REGEXP_REPLACE(u.Name,' +', ' ')) as name,
u.PlaceWorkId as organization_id, u.Login as login, u.Phone as phone, u.Email as email, org.PersonPosition as position
from esz.User u
left join Organization org on u.Name = org.Person
inner join esz.UserRoleRel ur on ur.UserId = u.Id
where ur.RoleId in (233,230,227,225,221,217) and (u.IsArchive is null or u.IsArchive = 0) group by u.Id;

-- +--------------------------------------------------------------------------------------------------------------------
-- + Выборка из таблицы esz.Teacher
-- +--------------------------------------------------------------------------------------------------------------------
select Id as aid, FirstName as first_name, LastName as second_name, MiddleName as middle_name, OrganizationId as organization_id,
       Phone as phone, Email as email
from esz.Teacher where IsArchive is null or IsArchive = 0;

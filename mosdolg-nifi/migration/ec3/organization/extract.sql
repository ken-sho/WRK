-- +--------------------------------------------------------------------------------------------------------------------
-- + выборка организаций
-- +--------------------------------------------------------------------------------------------------------------------
select
    distinct o.Id as aid,
    o.ShortName as short_title,
    o.FullName as full_title,
    o.Inn as inn,
    o.Kpp as kpp,
    o.Ogrn as ogrn,
    o.HeadOrganizationId as parent_organization_id,
    o.Person as representative_full_name,
    o.PersonPosition as representative_position,
    o.WWW as website,
    o.Description as description,
    cast(adr.UNOM as SIGNED) as unom,
    adr.FullAddress as full_address,
    (case when o.VedomstvoId = 120 then 5 else 1 end) as opf_id,
    o.IsPlaceService as is_provider,
    o.IsCssOrganization as is_css_organization,
    o.IsDsppOrganization as is_dspp_organization,
    o.TypesProvidingServicesId as types_providing_services_id,
    (select te.TerEntityCode from TerritoryEntity te where te.Id = adr.TerritoryEntityId) as territory_code,
    o.Email as email,
    o.Phone as phone,
    o.VedomstvoId as department_id,
    te.TerEntityCode as territory_1_code,
    te2.TerEntityCode as territory_2_code,
    o.DtsznCode as dtszn_code
from esz.Organization o
    left join esz.Address adr on adr.Id = o.AddressId
    INNER JOIN UnionCatalogServices UC ON o.id = UC.OrganizationId
    INNER JOIN ClassificatorEKU C ON UC.ClassificatorEKUId = C.Id
    left join TerritoryEntity te on te.Id = adr.TerritoryEntityId
	left join TerritoryEntity te2 on te.TerritoryEntityId = te2.Id
where
    (C.EducationTypeId = 4 and
    (o.IsArchive is null or o.IsArchive = 0) and
    (UC.IsArchive is null or UC.IsArchive = 0) and
    (C.IsArchive is null or C.IsArchive = 0))
union
select
    distinct o.Id as aid,
    o.ShortName as short_title,
    o.FullName as full_title,
    o.Inn as inn,
    o.Kpp as kpp,
    o.Ogrn as ogrn,
    o.HeadOrganizationId as parent_organization_id,
    o.Person as representative_full_name,
    o.PersonPosition as representative_position,
    o.WWW as website,
    o.Description as description,
    cast(adr.UNOM as SIGNED) as unom,
    adr.FullAddress as full_address,
    (case when o.VedomstvoId = 120 then 5 else 1 end) as opf_id,
    o.IsPlaceService as is_provider,
    o.IsCssOrganization as is_css_organization,
    o.IsDsppOrganization as is_dspp_organization,
    o.TypesProvidingServicesId as types_providing_services_id,
    (select te.TerEntityCode from TerritoryEntity te where te.Id = adr.TerritoryEntityId) as territory_code,
    o.Email as email,
    o.Phone as phone,
    o.VedomstvoId as department_id,
    te.TerEntityCode as territory_1_code,
    te2.TerEntityCode as territory_2_code,
    o.DtsznCode as dtszn_code
from esz.Organization o
    left join esz.Address adr on adr.Id = o.AddressId
    left join TerritoryEntity te on te.Id = adr.TerritoryEntityId
	left join TerritoryEntity te2 on te.TerritoryEntityId = te2.Id
where
   	((o.IsCssOrganization = 1 or o.DtsznCode is not null) and (o.IsArchive is null or o.IsArchive = 0));

-- +--------------------------------------------------------------------------------------------------------------------
-- + выборка ведомств
-- +--------------------------------------------------------------------------------------------------------------------
select DISTINCT
    V.Id as aid,
    V.ExBodyShortName as title,
    V.ExBodyFullName as long_title,
    CASE
        WHEN V.Id = 137 THEN 1
        else 0
    end as level
from Organization O
INNER JOIN UnionCatalogServices UC ON O.id = UC.OrganizationId
LEFT JOIN Vedomstvo V on O.VedomstvoId = V.Id
INNER JOIN ClassificatorEKU C ON UC.ClassificatorEKUId = C.Id
WHERE C.EducationTypeId = 4 and O.IsArchive = 0 and UC.IsArchive = 0 and C.IsArchive = 0


-- +--------------------------------------------------------------------------------------------------------------------
-- + получение расписания организаций
-- +--------------------------------------------------------------------------------------------------------------------
select ss.Id as id,
       ss.OrganizationId as oid,
       ss.DayOfWeek as day_of_week,
       TIME_FORMAT(ss.TimeStart, '%H:%i:%s') as time_from,
       TIME_FORMAT(ss.TimeEnd, '%H:%i:%s') as time_to
from esz.ScheduleOfService ss
    join esz.Organization o on
        o.Id = ss.OrganizationId
where ss.isArchive = 0;

-- +--------------------------------------------------------------------------------------------------------------------
-- + вспомогательная таблица для дозаполнения sdb.ar_address_registry
-- +--------------------------------------------------------------------------------------------------------------------
SELECT x.ShortName as short_name, 
       x.AddressId, 
       a.TerritoryEntityId as district, 
       te.TerritoryEntityId as adm_area
FROM esz.Organization x
join esz.Address a on a.Id = x.AddressId
join esz.TerritoryEntity te on te.id = a.TerritoryEntityId
WHERE (x.iscssorganization = 1 or x.DtsznCode is NOT NULL) 
and (x.isarchive = 0 or x.isarchive is NULL)
and (a.UNOM is null or a.TerritoryEntityId is null)

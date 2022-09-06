-- 09.10.19
select distinct
       xx.Id                    as id,
       xx.org_addressid         as address_id,
       xx.Name                  as title,
       ad.FullAddress           as address,
       ad.UNOM                  as unom,
       cast(ms.Code as INTEGER) as metro_station_code
from (
       select ps.Id,
              ps.AddressId as org_addressid,
              ps.Name,
              o.Id         as orgId,
              ucs.Id       as ucsId,
              sc.Id        as scId
       from PlaceService ps
              join OrganizationToPlace otp on ps.Id = otp.PlaceServiceId
              join Organization o on otp.OrganizationId = o.Id
              left join UnionCatalogServices ucs on o.Id = ucs.OrganizationId
              left join ClassificatorEKU ce on ucs.ClassificatorEKUId = ce.id
              left join ServiceClassRel scr on ucs.Id = scr.UnionCatalogServicesId
              left join ServiceClass sc on sc.Id = scr.ServiceClassId
       where ps.IsArchive = 0
         and ce.EducationTypeId = 4
         and (ucs.Id is null or ucs.IsArchive = 0)
         and (sc.Id is null or sc.IsArchive = 0)
       group by ucsId, scId, orgId, ps.Id
) xx
join Address ad on org_addressid = ad.Id
  left join MetroStationAddress msa on org_addressid = msa.AddressId
  left join MetroStation ms on ms.Id = msa.MetroStationId
where ad.FullAddress is not null;


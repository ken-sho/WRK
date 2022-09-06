select distinct
       xx.org_placeserviceid    as id,
       xx.org_addressid         as address_id,
       -- xx.scId               as group_id,
       xx.Name                  as title,
       ad.FullAddress           as address,
       ad.UNOM                  as unom,
       cast(ms.Code as INTEGER) as metro_station_code
from (
      select distinct
            ucs.Id AS "ucsId"
            ,sc.Id AS "scId"
            ,o.Id AS "orgId"
            ,ps.Id AS org_placeserviceid
            ,ps.AddressId AS "org_addressid"
            ,max(case when (sc.AddressId = ps1.AddressId)then sc.AddressId else 0 end) as "addressid_sc"
            ,ps.Name
      from ServiceClass sc
            left join ServiceClassRel scr on sc.Id = scr.ServiceClassId
            left join UnionCatalogServices ucs ON ucs.Id = scr.UnionCatalogServicesId
            left join ClassificatorEKU ce ON ucs.ClassificatorEKUId = ce.id
            left join Organization o ON ucs.OrganizationId = o.Id
            left join OrganizationToPlace otp ON otp.OrganizationId = o.Id
            left join UnionCatalogToPlaceServiceRel uctpsr on uctpsr.UnionCatalogServicesId = ucs.Id
            left join PlaceService ps ON otp.PlaceServiceId = ps.Id
            left join PlaceService ps1 ON uctpsr.PlaceServiceId = ps1.Id
      where
            (sc.IsArchive = 0 or sc.IsArchive is null)
            and ce.EducationTypeId = 4
            and (ucs.IsArchive = 0 or ucs.IsArchive is null)
            and (ps.IsArchive = 0 or ps.IsArchive is null)
            and (o.IsArchive = 0 or o.IsArchive is null)
            and ps1.Id = ps.Id
      group by ucsId, scId, orgId, org_placeserviceid, org_addressid
) xx
join Address ad on org_addressid = Id
  left join MetroStationAddress msa on org_addressid = msa.AddressId
  left join MetroStation ms on ms.Id = msa.MetroStationId
where xx.addressid_sc != 0
  and ad.FullAddress is not null;

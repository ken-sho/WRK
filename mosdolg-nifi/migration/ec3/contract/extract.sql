select
	distinct ucs.id as aid,
	ucs.OrganizationId as provider_id,
	ucs.AgreemNumber as contract_number,
	ucs.CssOrganizationId as organization_id,
	DATE_FORMAT(ucs.AgreemDateStart, '%Y-%m-%d') as date_from,
	DATE_FORMAT(ucs.AgreemDateEnd, '%Y-%m-%d') as date_to,
	-- для md.contract_property
	ucs.ClassificatorEKUId as activity_id,
	ucs.FullPrice as full_price
from UnionCatalogServices ucs
LEFT JOIN ServiceClassRel scr ON scr.UnionCatalogServicesId = ucs.Id
LEFT JOIN ServiceClass g ON scr.ServiceClassId = g.Id
left join esz.ClassificatorEKU C on ucs.ClassificatorEKUId = C.Id
where
(g.IsArchive = 0 or g.IsArchive is null)
and C.EducationTypeId = 4
-- and ucs.AgreemDateStart is not NULL
-- and ucs.AgreemDateEnd is not NULL
-- and CONVERT(ucs.AgreemNumber, INTEGER) = 206101232019
-- group by ucs.OrganizationId, ucs.ClassificatorEKUId
order by ucs.AgreemDateStart desc;
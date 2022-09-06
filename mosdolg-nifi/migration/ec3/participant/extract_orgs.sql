-- https://wiki.og.mos.ru/pages/viewpage.action?pageId=14027278
select distinct
	p.Id as participant_aid,
	rad.CssOrganizationId as organization_aid,
	DATE_FORMAT(r.DateCreate, '%Y-%m-%d') as date_created
from esz.Pupil p
left join esz.Request r on r.PupilId=p.Id
left join esz.RequestAD rad on rad.RequestId=r.Id
where
rad.CssOrganizationId is not null
and (p.IsArchive = 0 or p.IsArchive is null)
group by p.Id, rad.CssOrganizationId;
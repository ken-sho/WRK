
-- +--------------------------------------------------------------------------------------------------------------------
-- + загрузка Профили активности
-- +--------------------------------------------------------------------------------------------------------------------
select
	r.Id as aid,
	rr.PupilId as participant_id,
	r.FirstClassificatorEKUId as first_classificator,
	r.SecondClassificatorEKUId as second_classificator,
	r.ThirdClassificatorEKUId as third_classificator,
	-- r.DesiredDate as date_from,
	r.Description as comment,
	r.SheduleTypeId as schedule_type_id,
	r.WeekDaysTypeId as week_days_type_id,
    -- DATE_FORMAT(rr.DateCreate, '%Y-%m-%d') as date_create,
    (case when (CONVERT(DATE_FORMAT(rr.DateCreate, '%m'), INTEGER) + 11) > r.DesiredDate + 12
    	then concat(CONVERT(DATE_FORMAT(rr.DateCreate, '%Y'), INTEGER) + 1, '-', (case when r.DesiredDate >= 10 then r.DesiredDate else concat('0', r.DesiredDate) end), '-01')
    	else
    		case when r.DesiredDate is null
    		then concat(DATE_FORMAT(rr.DateCreate, '%Y-%m'), '-01')
    		else concat(DATE_FORMAT(rr.DateCreate, '%Y'), '-', (case when r.DesiredDate >= 10 then r.DesiredDate else concat('0', r.DesiredDate) end), '-01')
    		end
    end) as date_from
from esz.RequestAD r
join esz.Request rr on rr.Id = r.RequestId;

-- +--------------------------------------------------------------------------------------------------------------------
-- + загрузка справочника Направления (reference.activity)
-- +--------------------------------------------------------------------------------------------------------------------
select
    c.Id as aid,
    c.ParentId as parent_id,
    c.Name as title
from esz.ClassificatorEKU c
where (c.IsArchive is null or c.IsArchive = 0) and c.EducationTypeId = 4;

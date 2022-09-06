-- 20.09.19
-- +--------------------------------------------------------------------------------------------------------------------
-- + Выборка групп (sdb.groups)
-- +--------------------------------------------------------------------------------------------------------------------
select
    g.id as aid,
		-- 4 варианта: 1 - Создана, 2 - Сформирована, 3 - Приступила к занятиям, 4 - Прием закрыт
    g.ServiceClassStartStatusId as group_status_id,
    g.ServiceClassStatusId as sc_status_id,
    g.MonitoringSpecialistId as coworker_id,
    ucs.IsMedConditions as need_note,
    g.MinCapacity as min_count,
    g.Capacity as max_count,
    DATE_FORMAT(coalesce(g.StartDate, g.TrainStartDate), '%Y-%m-%d') as plan_start_date,
    DATE_FORMAT(g.TrainEndDate, '%Y-%m-%d') as plan_end_date,
    DATE_FORMAT(g.StartDate, '%Y-%m-%d') as fact_start_date,
    DATE_FORMAT(date_add(
        g.StartDate,
        interval (
            1 * ucs.DurationOfTrainingDays +
            7 * ucs.DurationOfTrainingWeeks +
            30 * ucs.DurationOfTrainingMonths +
            365 * ucs.DurationOfTraining
        ) day
    ), '%Y-%m-%d') as fact_end_date,
    ucs.CanComplementClasses as extend,
    -- (case when g.ServiceClassStartStatusId=4 then 0 else 1 end) as extend,
    ucs.OrganizationId as organization_id,
    ucs.ClassificatorEKUId as activity_id,
    ucs.Id as contract_id,
    ucs.CssOrganizationId as territory_centre_id,
    g.Code as code,
    g.Name as name,
		case when ucs.ServiceStatusId = 2 and dp.public_date is null
				 then DATE_FORMAT(DATE_SUB(current_date, interval 6 month), '%Y-%m-%d')
				 else DATE_FORMAT(dp.public_date, '%Y-%m-%d') end as public_date,
    DATE_FORMAT(g.OrderDate, '%Y-%m-%d') as order_date
from esz.ServiceClass g
LEFT JOIN ServiceClassRel scr ON scr.ServiceClassId = g.Id
LEFT JOIN UnionCatalogServices ucs ON scr.UnionCatalogServicesId = ucs.Id
left join esz.ClassificatorEKU C on ucs.ClassificatorEKUId = C.Id
INNER join Organization org on org.id = ucs.OrganizationId
LEFT JOIN Organization o ON o.Id=ucs.CssOrganizationId
LEFT JOIN (SELECT ucs.Id ,MAX(date(l.DateTime)) AS public_date
   FROM UnionCatalogServices ucs
        INNER JOIN esz.ClassificatorEKU ce ON ce.Id=ucs.ClassificatorEKUId AND ce.EducationTypeId=4 AND ce.IsArchive=0
        INNER JOIN esz.Logging l ON ucs.ExtendEntityId=l.ExtendEntityId
    WHERE
        l.IsArchive=0 AND l.Success=1
        AND l.Description LIKE '%Новый статус услуги=Опубликовано на Mos.ru%'
        AND ucs.IsArchive=0
        GROUP BY ucs.Id) dp ON dp.Id=ucs.Id
where
(g.IsArchive = 0 or g.IsArchive is null)
and ucs.ServiceStatusId != 3
and (ucs.IsArchive is NULL or ucs.IsArchive = 0)
AND (C.IsArchive IS NULL or C.IsArchive = 0)
AND g.ServiceClassStatusId != 3
AND org.ShortName NOT IN ('Тест ДПиООС', 'Тестовый ТЦСО (ДИТовский)') -- исключая тестовые организацию
AND o.ShortName!='ГБУ ТЦСО "Тестовый"' -- исключая тестовое ЦСО
and C.EducationTypeId = 4;
-- 1, 2, 3 -- 4
-- ucs archive
-- поставшики оргнизации по группам


-- +--------------------------------------------------------------------------------------------------------------------
-- + Расписания групп (sdb.schedule)
-- +--------------------------------------------------------------------------------------------------------------------
select
    distinct ss.Id as aid,
    sc.Id as group_id,
    ps1.Id as place_id,
    DATE_FORMAT((case when sc.StartDate is not null then sc.StartDate else sc.TrainStartDate end), '%Y-%m-%d') as start_date,
    coalesce(DATE_FORMAT(sc.TrainEndDate, '%Y-%m-%d'), DATE_FORMAT(ucs.AgreemDateEnd, '%Y-%m-%d')) as end_date,
    TIME_FORMAT(ss.TimeStart, '%H:%i:%s') as start_time,
    TIME_FORMAT(ss.TimeEnd, '%H:%i:%s') as end_time,
    ss.DayOfWeek as day_of_week
from esz.ScheduleOfService ss
join esz.ServiceClass sc on ss.ServiceClassId = sc.Id
LEFT JOIN esz.ServiceClassRel scr ON scr.ServiceClassId = sc.Id
LEFT JOIN esz.UnionCatalogServices ucs ON scr.UnionCatalogServicesId = ucs.Id
LEFT JOIN UnionCatalogToPlaceServiceRel uctpsr on uctpsr.UnionCatalogServicesId = ucs.Id
LEFT JOIN PlaceService ps1 ON uctpsr.PlaceServiceId = ps1.Id
left join esz.ClassificatorEKU C on ucs.ClassificatorEKUId = C.Id
where
(sc.IsArchive = 0 or sc.IsArchive is null)
and (ss.IsArchive = 0 or ss.IsArchive is null)
and ucs.ServiceStatusId != 3
and (ucs.IsArchive is NULL or ucs.IsArchive = 0)
AND sc.ServiceClassStatusId != 3
AND (C.IsArchive IS NULL or C.IsArchive = 0)
and C.EducationTypeId = 4
and ss.TimeStart is not NULL
and ss.TimeEnd is not null
group by aid;


-- +--------------------------------------------------------------------------------------------------------------------
-- + Записи в группу (sdb.class_record)
-- +--------------------------------------------------------------------------------------------------------------------
select
	mr.Id as aid,
	mr.PupilId as participant_id,
	mr.ServiceClassId as group_id,
	rad.Id as reques_ad_id,
	DATE_FORMAT(mr.DateCreate, '%Y-%m-%d') as date_from,
	DATE_FORMAT(mr.DateEnd, '%Y-%m-%d') as date_to,
	mr.MegaRelationStatusId as status_id -- transferred и class_record_status_id по статусу считаем в трансформе
from esz.MegaRelation mr
-- для получения правильной ссылки на профиль активности
left join esz.RequestAD rad on rad.RequestId=mr.RequestId
-- для выборки только тех групп, которые используем
left join esz.ServiceClass g on g.Id=mr.ServiceClassId
LEFT JOIN ServiceClassRel scr ON scr.ServiceClassId = g.Id
LEFT JOIN UnionCatalogServices ucs ON scr.UnionCatalogServicesId = ucs.Id
left join esz.ClassificatorEKU C on ucs.ClassificatorEKUId = C.Id
INNER join Organization org on org.id = ucs.OrganizationId
LEFT JOIN Organization o ON o.Id=ucs.CssOrganizationId
where
	(mr.IsArchive = 0 or mr.IsArchive IS NULL) and
	mr.PupilId IS NOT NULL and
	mr.NextMegaRelationId is NULL and
	-- для выборки только тех групп, которые используем
	(g.IsArchive = 0 or g.IsArchive is null)
and ucs.ServiceStatusId != 3
and (ucs.IsArchive is NULL or ucs.IsArchive = 0)
AND (C.IsArchive IS NULL or C.IsArchive = 0)
AND g.ServiceClassStatusId != 3
AND org.ShortName NOT IN ('Тест ДПиООС', 'Тестовый ТЦСО (ДИТовский)') -- исключая тестовые организацию
AND o.ShortName!='ГБУ ТЦСО "Тестовый"' -- исключая тестовое ЦСО
AND	C.EducationTypeId = 4;


--
-- Связь групп с преподавателями
--
select
    str.Id as aid,
	str.TeacherId as teacher_aid,
	str.ServiceClassId as group_aid
from esz.ServiceClassTeacherRel str
where str.ServiceClassId in (
select
    g.id
from esz.ServiceClass g
LEFT JOIN ServiceClassRel scr ON scr.ServiceClassId = g.Id
LEFT JOIN UnionCatalogServices ucs ON scr.UnionCatalogServicesId = ucs.Id
left join esz.ClassificatorEKU C on ucs.ClassificatorEKUId = C.Id
where (g.IsArchive = 0 or g.IsArchive is null) and C.EducationTypeId = 4
);


--
-- Приостановленные записи в группы
--
SELECT

distinct r.id as aid,
mr1.ServiceClassId as group_aid,
mr1.PupilId as participant_aid,
DATE_FORMAT(mr1.DateCreate, '%Y-%m-%d') as date_from,
DATE_FORMAT(mr1.DateEnd, '%Y-%m-%d') as date_to,
ucs.ClassificatorEKUId as activity_aid
FROM

esz.RequestAD rAD -- Таблица дополнительных полей в карточке заявления для АД

INNER JOIN esz.Request r ON r.Id=rAD.RequestId  -- Таблица заявлений
INNER JOIN esz.MegaRelation mr1 ON mr1.RequestId = r.Id  AND (mr1.IsArchive IS NULL OR mr1.IsArchive = 0) AND mr1.DateEnd < NOW() AND mr1.MegaRelationStatusId <> 3 AND mr1.NextMegaRelationId IS NULL
LEFT JOIN ServiceClassRel scr ON scr.ServiceClassId = mr1.ServiceClassId
LEFT JOIN UnionCatalogServices ucs ON scr.UnionCatalogServicesId = ucs.Id

INNER JOIN (SELECT

  mrh.MegaRelationId

  ,mrh.Description, mrh.ExcludeReasonId

  FROM

esz.MegaRelationHistory mrh

  INNER JOIN (SELECT mrh.MegaRelationID,MAX(mrh.Id) AS mid  FROM esz.MegaRelationHistory mrh

    INNER JOIN esz.MegaRelation mr1 ON  mr1.Id=mrh.MegaRelationId   AND (mr1.IsArchive IS NULL OR mr1.IsArchive = 0) AND mr1.DateEnd < NOW() AND mr1.MegaRelationStatusId <> 3 AND mr1.NextMegaRelationId IS NULL

    INNER JOIN esz.Request r ON r.Id=mr1.RequestId  -- Таблица заявлений

    INNER JOIN esz.RequestAD rAD ON r.ID=rAD.RequestId-- Таблица дополнительных полей в карточке заявления для АД

          WHERE  mrh.MegaRelationHistoryTypeId=4 -- and mrh.ExcludeReasonId = 30

    GROUP BY  mrh.MegaRelationID) a ON a.MegaRelationId=mrh.MegaRelationId AND a.mid=mrh.id AND mrh.ExcludeReasonId = 30)mrh ON mr1.ID=mrh.MegaRelationId group by aid order by aid;

--
-- Приостановленные группы
--
SELECT
distinct
mr1.ServiceClassId as group_aid,
-- DATE_FORMAT(mr1.DateCreate, '%Y-%m-%d') as date_from,
-- DATE_FORMAT(mr1.DateEnd, '%Y-%m-%d') as date_to,
MAX(DATE_FORMAT(mr1.DateEnd, '%Y-%m-%d')) as start_date,
ucs.ClassificatorEKUId as activity_aid

FROM

esz.RequestAD rAD -- Таблица дополнительных полей в карточке заявления для АД

INNER JOIN esz.Request r ON r.Id=rAD.RequestId  -- Таблица заявлений
INNER JOIN esz.MegaRelation mr1 ON mr1.RequestId = r.Id
	AND (mr1.IsArchive IS NULL OR mr1.IsArchive = 0)
	AND mr1.DateEnd < NOW()
	AND mr1.MegaRelationStatusId <> 3
	AND mr1.NextMegaRelationId IS NULL
LEFT JOIN ServiceClassRel scr ON scr.ServiceClassId = mr1.ServiceClassId
LEFT JOIN UnionCatalogServices ucs ON scr.UnionCatalogServicesId = ucs.Id
LEFT JOIN ServiceClass sc on sc.Id=scr.ServiceClassId
LEFT JOIN esz.MegaRelation gmr on gmr.ServiceClassId=mr1.ServiceClassId AND gmr.NextMegaRelationId is NULL AND gmr.MegaRelationStatusId != 1
left join esz.ClassificatorEKU C on ucs.ClassificatorEKUId = C.Id

INNER join Organization org on org.id = ucs.OrganizationId
LEFT JOIN Organization o ON o.Id=ucs.CssOrganizationId

INNER JOIN (SELECT

  mrh.MegaRelationId

  ,mrh.Description, mrh.ExcludeReasonId

  FROM

esz.MegaRelationHistory mrh

  INNER JOIN (SELECT mrh.MegaRelationID,MAX(mrh.Id) AS mid  FROM esz.MegaRelationHistory mrh

    INNER JOIN esz.MegaRelation mr1 ON  mr1.Id=mrh.MegaRelationId   AND (mr1.IsArchive IS NULL OR mr1.IsArchive = 0) AND mr1.DateEnd < NOW() AND mr1.MegaRelationStatusId <> 3 AND mr1.NextMegaRelationId IS NULL

    INNER JOIN esz.Request r ON r.Id=mr1.RequestId  -- Таблица заявлений

    INNER JOIN esz.RequestAD rAD ON r.ID=rAD.RequestId-- Таблица дополнительных полей в карточке заявления для АД

          WHERE  mrh.MegaRelationHistoryTypeId=4 and mrh.ExcludeReasonId = 30

    GROUP BY  mrh.MegaRelationID) a ON a.MegaRelationId=mrh.MegaRelationId AND a.mid=mrh.id)mrh ON mr1.ID=mrh.MegaRelationId
where sc.ServiceClassStartStatusId = 4
and sc.ServiceClassStatusId != 3
and sc.Id not in (select Id from (select
	sc.Id
from esz.ServiceClass sc
left join esz.MegaRelation mr on mr.ServiceClassId=sc.Id AND mr.NextMegaRelationId is NULL where mr.MegaRelationStatusId = 1
group by sc.Id) xx)
-- от групп
and (sc.IsArchive = 0 or sc.IsArchive is null)
and ucs.ServiceStatusId != 3
and (ucs.IsArchive is NULL or ucs.IsArchive = 0)
AND (C.IsArchive IS NULL or C.IsArchive = 0)
AND org.ShortName NOT IN ('Тест ДПиООС', 'Тестовый ТЦСО (ДИТовский)') -- исключая тестовые организацию
AND o.ShortName!='ГБУ ТЦСО "Тестовый"' -- исключая тестовое ЦСО
and C.EducationTypeId = 4
group by mr1.ServiceClassId, ucs.ClassificatorEKUId;

-- +--------------------------------------------------------------------------------------------------------------------
-- + Противопоказания групп (sdb.group_contraindication)
-- +--------------------------------------------------------------------------------------------------------------------
select g.Id              as aid,
			 ucs.MedConditions as title
from esz.ServiceClass g
			 left join ServiceClassRel scr on scr.ServiceClassId = g.Id
			 left join UnionCatalogServices ucs on scr.UnionCatalogServicesId = ucs.Id
			 left join Organization org on org.id = ucs.OrganizationId
			 left JOIN Organization o ON o.Id = ucs.CssOrganizationId
where ucs.MedConditions is not null
	and g.IsArchive = 0
	and ucs.IsArchive = 0
	-- and ucs.ServiceStatusId != 3
	-- AND g.ServiceClassStatusId != 3
	AND org.ShortName NOT IN ('Тест ДПиООС', 'Тестовый ТЦСО (ДИТовский)')
	AND o.ShortName != 'ГБУ ТЦСО "Тестовый"'
group by g.Id, ucs.MedConditions;

-- +--------------------------------------------------------------------------------------------------------------------
-- + Форма одежды групп (sdb.group_dress_code)
-- +--------------------------------------------------------------------------------------------------------------------
select g.Id             as aid,
			 ucs.ClothRequire as title
from esz.ServiceClass g
			 left join ServiceClassRel scr on scr.ServiceClassId = g.Id
			 left join UnionCatalogServices ucs on scr.UnionCatalogServicesId = ucs.Id
			 left join Organization org on org.id = ucs.OrganizationId
			 left JOIN Organization o ON o.Id = ucs.CssOrganizationId
where ucs.ClothRequire is not null
	and g.IsArchive = 0
	and ucs.IsArchive = 0
	-- and ucs.ServiceStatusId != 3
	-- AND g.ServiceClassStatusId != 3
	AND org.ShortName NOT IN ('Тест ДПиООС', 'Тестовый ТЦСО (ДИТовский)')
	AND o.ShortName != 'ГБУ ТЦСО "Тестовый"'
group by g.Id, ucs.ClothRequire;

-- +--------------------------------------------------------------------------------------------------------------------
-- + Требования к инвентарю групп (sdb.group_inventory_requirement)
-- +--------------------------------------------------------------------------------------------------------------------
select g.Id              as aid,
			 ucs.InventRequire as title
from esz.ServiceClass g
			 left join ServiceClassRel scr on scr.ServiceClassId = g.Id
			 left join UnionCatalogServices ucs on scr.UnionCatalogServicesId = ucs.Id
			 left join Organization org on org.id = ucs.OrganizationId
			 left JOIN Organization o ON o.Id = ucs.CssOrganizationId
where ucs.ClothRequire is not null
	and g.IsArchive = 0
	and ucs.IsArchive = 0
	-- and ucs.ServiceStatusId != 3
	-- AND g.ServiceClassStatusId != 3
	AND org.ShortName NOT IN ('Тест ДПиООС', 'Тестовый ТЦСО (ДИТовский)')
	AND o.ShortName != 'ГБУ ТЦСО "Тестовый"'
group by g.Id, ucs.InventRequire;
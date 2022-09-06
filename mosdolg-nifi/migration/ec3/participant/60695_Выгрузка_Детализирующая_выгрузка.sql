
SELECT DISTINCT
    ins4.pId as "PupilID"
              ,IFNULL(IFNULL(r.Id, r1.Id), r2.Id) as "Номер анкеты-заявки"
              ,DATE(IFNULL(IFNULL(r.DateCreate, r1.DateCreate), r2.DateCreate)) as "Дата анкеты-заявки"
              ,IFNULL(IFNULL(rs.Name, rs1.Name), rs2.Name) as "Статус заявления"
              ,CASE WHEN decl.Name IS NOT NULL THEN decl.Name ELSE ' ' END as "Основания отказа в зачислении"
              ,CASE WHEN ins4.a2 = 100000000 AND ins4.b2 = 0 AND ins4.c2 = 100000000 AND ins4.d2 = 100000000 AND ins4.e2 = 100000000 AND ins4.f2 > 0 AND susp.Name IS NOT NULL THEN susp.Name ELSE ' ' END AS "Причина приостановки"
              ,IFNULL((IFNULL((CONCAT_WS(' ', prd.LastName, prd.FirstName, prd.MiddleName)), (CONCAT_WS(' ', prd1.LastName, prd1.FirstName, prd1.MiddleName)))), (CONCAT_WS(' ', prd2.LastName, prd2.FirstName, prd2.MiddleName))) as "ФИО"
              ,IFNULL(IFNULL(DATE(prd.DateOfBirth), DATE(prd1.DateOfBirth)), DATE(prd2.DateOfBirth)) AS "Дата рождения"
              ,IFNULL(IFNULL(IFNULL(prd.Snils, prd1.Snils), prd2.Snils), ' ') AS "СНИЛС"
              ,IFNULL(IFNULL(CONCAT_WS('; ', prd.Phone, prd.HomePhone), CONCAT_WS('; ', prd1.Phone, prd1.HomePhone)), CONCAT_WS('; ', prd2.Phone, prd2.HomePhone)) as "Телефон"
              ,(CONCAT_WS(' ',
                          CASE WHEN parent_terr3.TerEntityName IN ('Троицкий','Новомосковский') OR o.id=88567 THEN 'Троицкий и Новомосковский' ELSE parent_terr3.TerEntityName END, ',')) as "Округ"
              ,(CONCAT_WS(' ', te3.TerEntityName, ',')) as "Район"
              ,(CONCAT_WS(' ', case when pa.StreetName is not null then 'улица' else '' end, pa.StreetName, ',')) as "Улица"
              ,(CONCAT_WS(' ', case when pa.HouseNumber is not null then 'дом' else '' end, pa.HouseNumber, ',')) as "Дом"
              ,(CONCAT_WS(' ', case when pa.HousingNumber is not null then 'корпус' else '' end, pa.HousingNumber, ',')) as "Корпус"
              ,(CONCAT_WS(' ', case when pa.OwnershipNumber is not null then 'владение' else '' end, pa.OwnershipNumber, ',')) as "Владение"
              ,(CONCAT_WS(' ', case when pa.BuildingNumber is not null then 'строение' else '' end, pa.BuildingNumber, ',')) as "Строение"
              ,(CONCAT_WS(' ', case when pa.RoomNumber is not null then 'квартира' else '' end, pa.RoomNumber, ',')) as "Квартира"
              ,eku.Name  AS "Приоритетное направление"
              ,eku1.Name  AS "Дополнительное направление 1 (при наличии)"
              ,eku2.Name AS "Дополнительное направление 2 (при наличии)"
              ,o.ShortName AS "Краткое наименование ЦСО"
              ,a.FullAddress AS "Адрес ЦСО"
              ,te.TerEntityName AS "Район ЦСО"
              ,CASE WHEN parent_terr.TerEntityName IN ('Троицкий','Новомосковский') OR o.id=88567 THEN 'Троицкий и Новомосковский' ELSE parent_terr.TerEntityName END AS "Округ ЦСО"
              ,CASE WHEN h.Id IS NOT NULL THEN 'Отчислен'
                    WHEN r1.RequestStatusId = 7 THEN reas.Name
                    ELSE '' END AS "Статус отчисления"
              ,CASE WHEN reas.Name IS NOT NULL THEN reas.Name ELSE '' END AS "Причина отчисления"
-- приоритет гражданика
              ,CONCAT('Приоритет ',
                      CASE WHEN ins4.a2 < 100000000 THEN 1
                           WHEN ins4.a2 = 100000000 AND ins4.b2 > 0 THEN 2
                           WHEN ins4.a2 = 100000000 AND ins4.b2 = 0 AND ins4.c2 < 100000000 THEN 3
                           WHEN ins4.a2 = 100000000 AND ins4.b2 = 0 AND ins4.c2 = 100000000 AND ins4.d2 < 100000000 THEN 4
                           WHEN ins4.a2 = 100000000 AND ins4.b2 = 0 AND ins4.c2 = 100000000 AND ins4.d2 = 100000000 AND ins4.e2 < 100000000 THEN 5
                           WHEN ins4.a2 = 100000000 AND ins4.b2 = 0 AND ins4.c2 = 100000000 AND ins4.d2 = 100000000 AND ins4.e2 = 100000000 AND ins4.f2 < 100000000 THEN 6
                           WHEN ins4.a2 = 100000000 AND ins4.b2 = 0 AND ins4.c2 = 100000000 AND ins4.d2 = 100000000 AND ins4.e2 = 100000000 AND ins4.f2 = 100000000 AND ins4.g2 IS NOT NULL AND ins4.g2 != 0 THEN 7
                           WHEN ins4.a2 = 100000000 AND ins4.b2 = 0 AND ins4.c2 = 100000000 AND ins4.d2 = 100000000 AND ins4.e2 = 100000000 AND ins4.f2 = 100000000 AND ins4.g2 = 0 AND ins4.h2 > 0 THEN 8
                          END) AS "Приоритет гражданина"

FROM (
         SELECT
             ins3.pId
              ,MAX(ins3.rDateCreate) AS rDateCreateMax
              ,MIN(ins3.rDateCreate) AS rDateCreateMin
              ,MIN(ins3.mrDateStart) AS mrDateStartMin
              ,MAX(ins3.hDateCreate) AS hDateCreateMax
              ,CASE WHEN ins3.a2 < 100000000 THEN 1 ELSE 0 END AS a3
-- ,CASE WHEN ins3.a2 < 100000000 AND ins3.a2 > 0 THEN MIN(ins3.a2) END AS a2
              ,MIN(ins3.a2) AS a2
              ,CASE WHEN ins3.a2 = 100000000 AND ins3.b2 < 100000000 THEN 1 ELSE 0 END AS b3
-- ,CASE WHEN ins3.a2 = 100000000 AND ins3.b2 > 0 AND ins3.b2 != 100000000 THEN MIN(ins3.b2) END AS b2
              ,CASE WHEN ins3.a2 = 100000000 THEN SUM(ins3.b2) END AS b2
              ,CASE WHEN ins3.a2 = 100000000 AND ins3.b2 = 0 AND ins3.c2 < 100000000 THEN 1 ELSE 0 END AS c3
              ,CASE WHEN ins3.a2 = 100000000 AND ins3.b2 = 0 AND ins3.c2 > 0 THEN MIN(ins3.c2) END AS c2
              ,CASE WHEN ins3.a2 = 100000000 AND ins3.b2 = 0 AND ins3.c2 = 100000000 AND ins3.d2 > 0 THEN MIN(ins3.d2) END AS d2
              ,CASE WHEN ins3.a2 = 100000000 AND ins3.b2 = 0 AND ins3.c2 = 100000000 AND ins3.d2 = 100000000 AND ins3.e2 > 0 THEN MIN(ins3.e2) ELSE 0 END AS e2
              ,CASE WHEN ins3.a2 = 100000000 AND ins3.b2 = 0 AND ins3.c2 = 100000000 AND ins3.d2 = 100000000 AND ins3.e2 = 100000000 AND ins3.f2 > 0 THEN MIN(ins3.f2) END AS f2
              ,CASE WHEN ins3.a2 = 100000000 AND ins3.b2 = 0 AND ins3.c2 = 100000000 AND ins3.d2 = 100000000 AND ins3.e2 = 100000000 AND ins3.f2 = 100000000 AND ins3.g2 IS NOT NULL THEN MAX(ins3.g2) END AS g2
              ,CASE WHEN ins3.a2 = 100000000 AND ins3.b2 = 0 AND ins3.c2 = 100000000 AND ins3.d2 = 100000000 AND ins3.e2 = 100000000 AND ins3.f2 = 100000000 AND ins3.g2 = 0 AND ins3.h2 > 0 THEN MAX(ins3.h2) END AS h2

         FROM (
                  SELECT
                      ins2.pId
                       ,ins2.rDateCreate
                       ,ins2.mrDateStart
                       ,ins2.hDateCreate
                       ,ins2.IsCssOrganization

                       ,CASE WHEN ins2.a > 0 AND ins2.mrDateStart IS NOT NULL THEN IF(ins2.IsCssOrganization=0,ins2.a,IF(ins2.IsCssOrganization=1,ins2.a,100000000))
                             WHEN ins2.a > 0 AND ins2.mrDateStart IS NOT NULL THEN IF(ins2.IsCssOrganization=1,ins2.a,100000000)
                             WHEN ins2.a > 0 AND ins2.mrDateStart IS NOT NULL THEN ins2.a
                             WHEN ins2.a <= 0 THEN 100000000
                             ELSE NULL END AS a2
                       ,CASE WHEN ins2.a = 0 AND ins2.b > 0 AND ins2.mrDateStart IS NOT NULL THEN IF(ins2.IsCssOrganization=0,ins2.b,IF(ins2.IsCssOrganization=1,ins2.b,0))
                             WHEN ins2.a = 0 AND ins2.b > 0 AND ins2.mrDateStart IS NOT NULL THEN IF(ins2.IsCssOrganization=1,ins2.b,0)
                             WHEN ins2.a = 0 AND ins2.b != 0 AND ins2.mrDateStart IS NOT NULL THEN ins2.b
                             WHEN ins2.a = 0 AND ins2.b <= 0 THEN 0
                             ELSE 0 END AS b2
                       ,CASE WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c > 0 AND ins2.mrDateStart IS NOT NULL THEN IF(ins2.IsCssOrganization=0,ins2.c,IF(ins2.IsCssOrganization=1,ins2.c,100000000))
                             WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c > 0 AND ins2.mrDateStart IS NOT NULL THEN IF(ins2.IsCssOrganization=1,ins2.c,100000000)
                             WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c <= 0 THEN 100000000
                             ELSE 100000000 END AS c2
                       ,CASE WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c = 0 AND ins2.d != 0 THEN ins2.d ELSE 100000000 END as d2
                       ,CASE WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c = 0 AND ins2.d = 0 AND ins2.e > 0 AND ins2.terrEq IS NOT NULL THEN ins2.e
                             WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c = 0 AND ins2.d = 0 AND ins2.e > 0 AND ins2.terrEq IS NULL THEN ins2.e
                             WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c = 0 AND ins2.d = 0 AND ins2.e <= 0 THEN 100000000
                             ELSE 100000000 END AS e2
                       ,CASE WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c = 0 AND ins2.d = 0 AND ins2.e = 0 AND ins2.f > 0 AND ins2.terrEq IS NOT NULL THEN ins2.f
                             WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c = 0 AND ins2.d = 0 AND ins2.e = 0 AND ins2.f > 0 AND ins2.terrEq IS NULL THEN ins2.f
                             WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c = 0 AND ins2.d = 0 AND ins2.e = 0 AND ins2.f <= 0 THEN 100000000
                             ELSE 100000000 END AS f2
                       ,CASE WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c = 0 AND ins2.d = 0 AND ins2.e = 0 AND ins2.f = 0 AND ins2.g > 0 THEN ins2.g ELSE 0 END AS g2
                       ,CASE WHEN ins2.a = 0 AND ins2.b = 0 AND ins2.c = 0 AND ins2.d = 0 AND ins2.e = 0 AND ins2.f = 0 AND ins2.g = 0 AND ins2.h > 0 THEN ins2.h ELSE 0 END AS h2
                  FROM
                      (

                          SELECT
                              p.Id as pId
                               , r.DateCreate as rDateCreate
                               , mr.DateStart as mrDateStart
                               , h.DateCreate as hDateCreate
                               ,org.IsCssOrganization
                               ,CASE WHEN te.Id = te2.Id THEN r.DateCreate END as terrEq
                               ,CASE WHEN te.Id != te2.Id THEN r.DateCreate END as terrNotEq
                               -- расчёт приоритетов
                               ,CASE WHEN r.RequestStatusId = 5 AND (TRIM(r.EnrollmentDocNumber) <> "") AND (sc.StartDate IS NULL AND (sc.TrainStartDate IS NULL OR sc.TrainStartDate <= NOW()) OR sc.StartDate <= NOW()) AND mr.Id IS NOT NULL THEN r.ID ELSE 0 END AS a
                               ,CASE WHEN r.RequestStatusId = 5 AND (TRIM(r.EnrollmentDocNumber) <> "") AND (sc.StartDate > NOW() OR sc.StartDate IS NULL AND sc.TrainStartDate > NOW()) AND mr.Id IS NOT NULL THEN r.ID ELSE 0 END AS b
                               ,CASE WHEN r.RequestStatusId = 5 AND (r.EnrollmentDocNumber IS NULL OR TRIM(r.EnrollmentDocNumber) = "") AND mr.Id IS NOT NULL THEN r.ID ELSE 0 END AS c
                               ,CASE WHEN r.RequestStatusId NOT IN (6, 7, 9, 11, 12) AND r.UnionCatalogServicesId IS NOT NULL AND mr.Id IS NULL AND mro.Id IS NULL THEN r.ID ELSE 0 END AS d
                               ,CASE WHEN r.RequestStatusId NOT IN (6, 7, 9, 11, 12) AND (r.UnionCatalogServicesId IS NULL) THEN r.ID ELSE 0 END AS e
                               ,CASE WHEN r.RequestStatusId = 11 THEN r.ID ELSE 0 END AS f
                               ,CASE WHEN r.RequestStatusId = 5 AND mro.Id IS NOT NULL AND mro.MegaRelationStatusId IN (1,2) THEN r.ID ELSE 0 END AS g -- отчисленные
                               ,CASE WHEN r.RequestStatusId = 7 THEN r.ID ELSE 0 END as h

                          FROM esz.Request r -- Заявления
                                   INNER JOIN esz.RequestAD rAD ON r.Id = rAD.RequestId -- Анкеты-заявки
                                   LEFT JOIN esz.Organization o ON o.Id=rAD.CssOrganizationId  -- Присоединяем данные по организациям ТЦСО
                                   LEFT JOIN esz.Address a ON a.Id=o.AddressId -- Присоединяем адрес ЦСО
                                   LEFT JOIN esz.TerritoryEntity te ON te.Id=a.TerritoryEntityId -- Присоединяем Районы ЦСО

                                   LEFT JOIN esz.MegaRelation mr ON mr.RequestId = r.Id AND (mr.IsArchive IS NULL OR mr.IsArchive = 0)
                              AND (mr.DateEnd IS NULL OR mr.DateEnd > NOW()) AND mr.MegaRelationStatusId <> 3 AND mr.NextMegaRelationId IS NULL -- Присоедияем таблицу человек-кружки. Если здесь есть запись, то было проведено зачисление ученика. При этом смотрится именно на последнюю запись в MegaRelation по анкете (в этой части mr.NextMegaRelationId IS NULL)
                                   LEFT JOIN esz.Organization org ON org.Id = mr.OrganizationId

                                   LEFT JOIN esz.MegaRelation mro ON mro.RequestId = r.Id AND (mro.IsArchive IS NULL OR mro.IsArchive = 0) AND
                                                                     mro.DateEnd < NOW() AND mro.MegaRelationStatusId IN (1,2) AND mro.NextMegaRelationId IS NULL
                                   LEFT JOIN esz.MegaRelationHistory h ON h.MegaRelationId = mro.Id AND h.ExcludeReasonId IS NOT NULL
                                   LEFT JOIN esz.ServiceClass sc ON sc.Id=mr.ServiceClassId -- Присоединяем таблицу групп
                                   INNER JOIN esz.Pupil p ON p.Id = r.PupilId -- Учащиеся

                                   LEFT JOIN esz.PersonalAddress per ON per.PupilId = p.Id
                                   LEFT JOIN esz.TerritoryEntity te2 ON te2.Id=per.TerritoryEntityId -- Присоединяем Районы людей

                          WHERE (r.IsArchive IS NULL OR r.IsArchive = 0) AND (r.FlagLast IS NULL OR r.FlagLast = 1) AND -- только неархивные услуги
                                  o.ShortName NOT IN ('Тестовый ТЦСО (ДИТовский)', 'ГБУ ТЦСО "Тестовый"',
                                                      'Тест ДСИТ', 'Тест ДПиООС', 'ГБОУ Школа № 1115') -- исключая список организаций

                      ) AS ins2
              ) AS ins3
         GROUP BY ins3.pId
     ) AS ins4

-- Персональная информация
         INNER JOIN esz.Pupil p ON p.ID = ins4.pId -- Люди
         LEFT JOIN esz.PersonalAddress pa ON pa.PupilId = p.Id AND pa.IsArchive != 1 AND pa.IsRegAddress = 1 -- Адрес прописки
         LEFT JOIN esz.TerritoryEntity te3 ON te3.Id=pa.TerritoryEntityId -- Присоединяем Районы ЦСО
         LEFT JOIN esz.TerritoryEntity parent_terr3 ON te3.TerritoryEntityId = parent_terr3.Id -- Присоединяем округа

-- информация по анкетам-заявкам с 1 по 6 приоритет
         INNER JOIN esz.Request r ON r.PupilId = p.Id  -- Заявления
    AND r.DateCreate = ins4.rDateCreateMin
         LEFT JOIN esz.PersonalRequestData prd ON prd.Id = r.ChildInformationId -- Присоединяем личную информацию

-- данные по анкете-заявке
         INNER JOIN esz.RequestAD rAD ON r.Id = rAD.RequestId -- Анкеты-заявки
         LEFT JOIN esz.ClassificatorEKU eku ON rAD.FirstClassificatorEKUId = eku.Id AND (eku.IsArchive IS NULL or eku.IsArchive = 0)            --  присоединяем таблицу РБНДО 3 уровень вид деятельности не удалён
         LEFT JOIN esz.ClassificatorEKU eku1 ON eku.ParentId = eku1.Id   AND (eku1.IsArchive IS NULL or eku1.IsArchive = 0)                  --  присоединяем таблицу РБНДО  2 уровень  профиль не удалён
         LEFT JOIN esz.ClassificatorEKU eku2 ON eku1.ParentId = eku2.Id  AND (eku2.IsArchive IS NULL or eku2.IsArchive = 0)              -- присоединяем таблицу РБНДО  1 уровень   Направленность не удалена

         LEFT JOIN esz.Organization o ON o.Id=rAD.CssOrganizationId  -- Присоединяем данные по организациям ТЦСО
         LEFT JOIN esz.Address a ON a.Id=o.AddressId -- Присоединяем адрес ЦСО
         LEFT JOIN esz.TerritoryEntity te ON te.Id=a.TerritoryEntityId -- Присоединяем Районы ЦСО
         LEFT JOIN esz.TerritoryEntity parent_terr ON te.TerritoryEntityId = parent_terr.Id -- Присоединяем округа
         LEFT JOIN esz.RequestStatus rs ON rs.Id = r.RequestStatusId -- Статус заявления
         LEFT JOIN esz.SuspendReason susp ON susp.Id = rAD.SuspendReasonId -- Причина приостановки
-- по зачисленным
         LEFT JOIN esz.MegaRelation mr ON mr.RequestId = r.Id AND (mr.IsArchive IS NULL OR mr.IsArchive = 0)
    AND (mr.DateEnd IS NULL OR mr.DateEnd > NOW()) AND mr.MegaRelationStatusId <> 3 AND mr.NextMegaRelationId IS NULL -- Присоедияем таблицу человек-кружки.
         LEFT JOIN esz.Organization org ON org.Id = mr.OrganizationId
         LEFT JOIN esz.UnionCatalogServices ucs ON ucs.Id = mr.UnionCatalogServicesId
         LEFT JOIN esz.ClassificatorEKU dop ON ucs.ClassificatorEKUId = dop.Id AND (dop.IsArchive IS NULL OR dop.IsArchive = 0)
         LEFT JOIN esz.Vedomstvo v ON v.Id = dop.VedomstvoId

-- информация по анкетам-заявкам 7
         LEFT JOIN esz.Request r1 ON r1.PupilId = p.Id AND r1.Id = ins4.g2
    AND ins4.a2 IS NULL AND ins4.b2 IS NULL AND ins4.c2 IS NULL AND ins4.d2 IS NULL AND ins4.e2 IS NULL AND ins4.f2 IS NULL
         LEFT JOIN esz.RequestStatus rs1 ON rs1.Id = r1.RequestStatusId
         LEFT JOIN esz.PersonalRequestData prd1 ON prd1.Id = r1.ChildInformationId -- Присоединяем личную информацию

-- 8 приоритет
         LEFT JOIN  esz.Request r2 ON r2.PupilId = p.Id AND r2.Id = ins4.h2
    AND ins4.a2 IS NULL AND ins4.b2 IS NULL AND ins4.c2 IS NULL AND ins4.d2 IS NULL AND ins4.e2 IS NULL AND ins4.f2 IS NULL AND ins4.g2 IS NULL
         LEFT JOIN esz.RequestStatus rs2 ON rs2.Id = r2.RequestStatusId
         LEFT JOIN esz.RequestDeclineReason decl ON decl.Id = r2.RequestDeclineReasonId
         LEFT JOIN esz.PersonalRequestData prd2 ON prd2.Id = r2.ChildInformationId -- Присоединяем личную информацию

-- по отчисленным
         LEFT JOIN esz.MegaRelation mro ON mro.RequestId = r1.Id AND (mro.IsArchive IS NULL OR mro.IsArchive = 0) AND
                                           mro.DateEnd < NOW() AND mro.MegaRelationStatusId IN (1,2)
    AND mro.NextMegaRelationId IS NULL AND r1.Id IS NOT NULL -- (Если требуется по отчисленным)

         LEFT JOIN esz.MegaRelationHistory h ON h.MegaRelationId = mro.Id AND h.DateCreate = ins4.hDateCreateMax

         LEFT  JOIN esz.PupilDeclineReason  reas ON reas.Id=h.ExcludeReasonId -- Причина отчисления
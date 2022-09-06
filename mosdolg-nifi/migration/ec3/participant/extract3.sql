-- 26.08
-- +--------------------------------------------------------------------------------------------------------------------
-- + загрузка Участнииков
-- +--------------------------------------------------------------------------------------------------------------------
SELECT
    distinct ins4.pId as aid
    ,IFNULL(p.FirstName, prd.FirstName) as first_name
    ,IFNULL(p.LastName, prd.LastName) as second_name
    ,IFNULL(p.MiddleName, prd.MiddleName) as patronymic
    ,IFNULL(DATE_FORMAT(p.BirthDate, '%Y-%m-%d'), DATE_FORMAT(prd.DateOfBirth, '%Y-%m-%d')) as date_of_birth
    ,coalesce(p.Snils, prd.Snils, ' ') as snils
    ,IFNULL(p.HomePhone, prd.HomePhone) as home_phone_number
    ,IFNULL(p.CellPhone, prd.Phone) as personal_phone_number
    ,prd.Email as email
    ,p.SexId as gender
    ,p.EmissionSeries as skm_series
    ,p.MoscowSocialCardNumber as skm
		, nullif(concat_ws(', '
				, 'Город Москва'
				, fctAdr.StreetName
				, nullif(concat_ws(' ', 'дом', fctAdr.HouseNumber), 'дом')
				, nullif(concat_ws(' ', 'строение', fctAdr.BuildingNumber), 'строение')
				, nullif(concat_ws(' ', 'корпус', fctAdr.HousingNumber), 'корпус')
				, nullif(concat_ws(' ', 'владение', fctAdr.OwnershipNumber), 'владение')
				, nullif(concat_ws(' ', 'квартира', fctAdr.RoomNumber), 'квартира')
		), 'Город Москва') as fct_full_address
		, nullif(concat_ws(', '
				, 'Город Москва'
				, regAdr.StreetName
				, concat_ws(' ', 'дом', regAdr.HouseNumber)
				, nullif(concat_ws(' ', 'строение', regAdr.BuildingNumber), 'строение')
				, nullif(concat_ws(' ', 'корпус', regAdr.HousingNumber), 'корпус')
				, nullif(concat_ws(' ', 'владение', regAdr.OwnershipNumber), 'владение')
				, nullif(concat_ws(' ', 'квартира', regAdr.RoomNumber), 'квартира')
		), 'Город Москва') as reg_full_address
    ,if(tmp.Priority = 8, 1, null) as status_id
    ,p.DocumentTypeId as document_type_id
    ,concat_ws(' ', p.DocSeries, p.DocNumber) as serial_number
    ,DATE_FORMAT(p.DocDate, '%Y-%m-%d') as date_from
    ,p.DocIssuer as department
    ,p.DocIssuerCode as department_code
    ,tmp.CssOrganizationId as organization_id
    ,regAdr.TerritoryEntityId as reg_adr_district
    ,fctAdr.TerritoryEntityId as fact_adr_district
    ,DATE_FORMAT(p.DateCreate, '%Y-%m-%d') as p_date_create
--    ,o.Id as organization_id
FROM (
    SELECT
        ins3.pId
        ,MIN(ins3.rDateCreate) AS rDateCreateMin
    FROM (
        SELECT
            ins2.pId
            ,ins2.rDateCreate
        FROM (
            SELECT
                p.Id as pId
                ,r.DateCreate as rDateCreate
            FROM esz.Request r
                INNER JOIN esz.RequestAD rAD ON r.Id = rAD.RequestId
                LEFT JOIN esz.Organization o ON o.Id=rAD.CssOrganizationId

                LEFT JOIN esz.MegaRelation mr ON mr.RequestId = r.Id AND (mr.IsArchive IS NULL OR mr.IsArchive = 0)
                    AND (mr.DateEnd IS NULL OR mr.DateEnd > NOW()) AND mr.MegaRelationStatusId <> 3 AND mr.NextMegaRelationId IS NULL
                LEFT JOIN esz.Organization org ON org.Id = mr.OrganizationId

                LEFT JOIN esz.MegaRelation mro ON mro.RequestId = r.Id AND (mro.IsArchive IS NULL OR mro.IsArchive = 0)
                    AND mro.DateEnd < NOW() AND mro.MegaRelationStatusId IN (1,2) AND mro.NextMegaRelationId IS NULL
                LEFT JOIN esz.MegaRelationHistory h ON h.MegaRelationId = mro.Id AND h.ExcludeReasonId IS NOT NULL
                LEFT JOIN esz.ServiceClass sc ON sc.Id=mr.ServiceClassId
                INNER JOIN esz.Pupil p ON p.Id = r.PupilId
                LEFT JOIN esz.PersonalAddress per ON per.PupilId = p.Id

            WHERE
                (r.IsArchive IS NULL OR r.IsArchive = 0)
                AND (r.FlagLast IS NULL OR r.FlagLast = 1)
                AND o.ShortName NOT IN ('Тестовый ТЦСО (ДИТовский)', 'ГБУ ТЦСО "Тестовый"', 'Тест ДСИТ', 'Тест ДПиООС', 'ГБОУ Школа № 1115')
        ) AS ins2
    ) AS ins3 GROUP BY ins3.pId
) AS ins4

INNER JOIN esz.Pupil p ON p.ID = ins4.pId -- Люди
LEFT JOIN esz.PersonalAddress regAdr ON regAdr.PupilId = p.Id AND regAdr.IsArchive != 1 AND regAdr.IsRegAddress = 1
LEFT JOIN esz.PersonalAddress fctAdr on fctAdr.PupilId = p.Id and fctAdr.IsArchive != 1 and fctAdr.IsRegAddress = 0

INNER JOIN esz.Request r ON r.PupilId = p.Id AND r.DateCreate = ins4.rDateCreateMin
LEFT JOIN esz.PersonalRequestData prd ON prd.Id = r.ChildInformationId

INNER JOIN esz.RequestAD rAD ON r.Id = rAD.RequestId
LEFT JOIN esz.Organization o ON o.Id=rAD.CssOrganizationId
LEFT JOIN esz.tmpPupilData tmp ON tmp.PupilId=p.Id

WHERE (p.IsArchive is null or p.IsArchive = 0)

group by ins4.pId;
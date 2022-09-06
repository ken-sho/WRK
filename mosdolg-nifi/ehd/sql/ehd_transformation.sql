-- DICTIONARY
--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные справочника 'Тип адресного объекта' и обновляем перекодировочную таблицу
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.address_object_type(id, aid, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.address_object_type_id_seq') else m.id end), t.id, t.name, 1
from ehd.dict_address_object_type t
         left join ehd.address_object_type_map m on t.id = m.aid
where t.isdeleted is null
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               ar_object_status_id = 1;
refresh materialized view ehd.address_object_type_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные справочника 'Вспомогательная адресная сущность'
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.additional_address_entity(id, aid, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.additional_address_entity_id_seq') else m.id end), t.id, t.name, 1
from ehd.dict_comments_additional_address_elements t
         left join ehd.additional_address_entity_map m on t.id = m.aid
where t.isdeleted isnull
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               ar_object_status_id = 1;
refresh materialized view ehd.additional_address_entity_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные справочника 'Уточнение адреса'
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.address_additional(id, aid, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.address_additional_id_seq') else m.id end), t.id, t.name, 1
from ehd.dict_additional_address_elements t
         left join ehd.address_additional_map m on t.id = m.aid
where t.isdeleted isnull
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               ar_object_status_id = 1;
refresh materialized view ehd.address_additional_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные справочника 'Город'
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.city(id, aid, title, ar_object_status_id)
select (case when m.aid isnull then nextval('ar.city_id_seq') else m.id end), t.id, t.name, 1
from ehd.dict_address_city t
         left join ehd.city_map m on t.id = m.aid
where t.isdeleted isnull
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               ar_object_status_id = 1;
refresh materialized view ehd.city_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные справочника 'Тип помещения'
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.room_type(id, aid, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.room_type_id_seq') else m.id end), t.id, t.name, 1
from ehd.dict_premises_types t
         left join ehd.room_type_map m on t.id = m.aid
where t.isdeleted isnull
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               ar_object_status_id = 1;
refresh materialized view ehd.room_type_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные справочника 'Справочник "Поселение"'
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.settlement(id, aid, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.settlement_id_seq') else m.id end), t.id, t.name, 1
from ehd.dict_address_settlement t
         left join ehd.settlement_map m on t.id = m.aid
where t.isdeleted isnull
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               ar_object_status_id = 1;
refresh materialized view ehd.settlement_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные справочника 'Справочник "Населенный пункт"'
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.settlement_point(id, aid, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.settlement_point_id_seq') else m.id end), t.id, t.name, 1
from ehd.dict_address_locality t
         left join ehd.settlement_point_map m on t.id = m.aid
where t.isdeleted isnull
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               ar_object_status_id = 1;
refresh materialized view ehd.settlement_point_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные справочника 'Улицы'
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.street(id, aid, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.street_id_seq') else m.id end), t.id, t.name, 1
from ehd.dict_element_names_street_network t
         left join ehd.street_map m on t.id = m.aid
where t.isdeleted isnull
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               ar_object_status_id = 1;
refresh materialized view ehd.street_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные для справочника 'Район'
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.territory(id, aid, ar_code, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.territory_id_seq') else m.id end), t.id, t.kod, t.name, 1
from ehd.dict_administrative_districts t
         left join ehd.territory_map m on t.id = m.aid
where t.isdeleted isnull
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               AR_code             = excluded.ar_code,
                               ar_object_status_id = 1;

insert into ar.territory(id, aid, parent_id, ar_code, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.territory_id_seq') else m.id end),
       t.id,
       (select tr.id from ar.territory tr where tr.ar_code = cast((div(cast(kod as integer), 100) * 100) as varchar)),
       t.kod,
       t.name,
       1
from ehd.dict_municipal_districts t
         left join ehd.territory_map m on t.id = m.aid
where t.isdeleted isnull
   or t.isdeleted = false
on conflict (id) do update set title               = excluded.title,
                               parent_id           = excluded.parent_id,
                               AR_code             = excluded.ar_code,
                               ar_object_status_id = 1;
refresh materialized view ehd.territory_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные для справочника Линия метро
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.metro_line(id, AID, title, ar_object_status_id)
select (case when m.id isnull then nextval('ar.metro_line_id_seq') else m.id end), t.id, t.line, 1
from ehd.metro_line t
         left join ehd.metro_line_map m on t.id = m.aid
where t.status = 'действует'
on conflict (id) do update set title               = excluded.title,
                               ar_object_status_id = 1;
refresh materialized view ehd.metro_line_map;

--+---------------------------------------------------------------------------------------------------------------------
--+ переносим данные для справочника Станция метро
--+---------------------------------------------------------------------------------------------------------------------
insert into ar.metro_station(id, aid, title, metro_line_id, ar_object_status_id)
select id, ms_id, station, ml_id, 1 from (
                                             select (case
                                                         when m.id isnull then nextval('ar.metro_station_id_seq')
                                                         else m.id end)     as id,
                                                    t.id                    as ms_id,
                                                    t.station,
                                                    (select ml.id
                                                     from ehd.metro_line l
                                                              join ehd.metro_line_map ml on l.id = ml.aid
                                                     where l.line = t.line) as ml_id
                                             from ehd.metro_station t
                                                      left join ehd.metro_station_map m on t.id = m.aid
                                             where t.status = 'действует'
                                         ) as ms
where ml_id is not null
on conflict (id) do update set title               = excluded.title,
                               metro_line_id       = excluded.metro_line_id,
                               ar_object_status_id = 1;
refresh materialized view ehd.metro_station_map;

-- CATALOGS MAIN
--+---------------------------------------------------------------------------------------------------------------------
--+ общий случай для полного переноса данных из одной временной в основную
--+---------------------------------------------------------------------------------------------------------------------
INSERT INTO ar.address_registry(id,
                                aid, obj_type, address, unom, p1, p3, p4, p5, p6, p7, p90, p91,
                                l1_type, l1_value, l2_type, l2_value, l3_type, l3_value, l4_type, l4_value, l5_type, l5_value,
                                adm_area, district, nreg, n_fias, dreg, d_fias, kladr, adr_type, sostad, status,
                                ar_object_status_id)
SELECT (case when m.id isnull then nextval('ar.address_registry_id_seq') else m.id end) as id,
       t.aid, (select id from ehd.address_object_type_map where aid = t.obj_type) as obj_type,
       t.address, t.unom, t.p1, (select id from ehd.settlement_map where t.p3 is not null and aid = t.p3) as p3, (select id from ehd.city_map where t.p4 is not null and aid = t.p4) as p4,
       (select id from ehd.territory_map where t.p5 is not null and aid = t.p5) as p5, (select id from ehd.settlement_point_map where t.p6 is not null and aid = t.p6) as p6,
       (select id from ehd.street_map where t.p7 is not null and aid = t.p7) as p7, (select id from ehd.address_additional_map where t.p90 is not null and aid = t.p90) as p90,
       (select id from ehd.additional_address_entity_map where t.p91 is not null and m.aid = t.p91) as p91, t.l1_type, t.l1_value, t.l2_type, t.l2_value, t.l3_type, t.l3_value,
       (select id from ehd.room_type_map where t.l4_type is not null and m.aid = t.l4_type) as l4_type, t.l4_value, t.l5_type, t.l5_value,
       (select id from ehd.territory_map where t.adm_area is not null and aid = t.adm_area) as adm_area,
       (select id from ehd.territory_map where t.district is not null and aid = t.district) as district, t.nreg, t.n_fias, to_date(t.dreg, 'DD.MM.YYYY') as dreg,
       to_date(t.d_fias, 'DD.MM.YYYY') as d_fias, t.kladr, t.adr_type, t.sostad, t.status,
       1
FROM ehd.address_registry_property_objects t left join ar.address_registry m on t.aid = m.aid
WHERE t.p1 in (645611645, 645608448) and t.sostad is not null and t.sostad not in (645607758,645608660,645608507) and t.status is not null and t.status != 645611001
ON CONFLICT (id) DO UPDATE SET obj_type = excluded.obj_type, address = excluded.address, unom = excluded.unom,
                               p1 = excluded.p1, p3 = excluded.p3, p4 = excluded.p4, p5 = excluded.p5, p6 = excluded.p6, p7 = excluded.p7,
                               p90 = excluded.p90, p91 = excluded.p91,
                               l1_type = excluded.l1_type, l1_value = excluded.l1_value, l2_type = excluded.l2_type, l2_value = excluded.l2_value,
                               l3_type = excluded.l3_type, l3_value = excluded.l3_value, l4_type = excluded.l4_type, l4_value = excluded.l4_value,
                               l5_type = excluded.l5_type, l5_value = excluded.l5_value,
                               adm_area = excluded.adm_area, district = excluded.district, nreg = excluded.nreg,
                               n_fias = excluded.n_fias, dreg = excluded.dreg, d_fias = excluded.d_fias,
                               kladr = excluded.kladr, adr_type = excluded.adr_type, sostad = excluded.sostad, status = excluded.status,
                               ar_object_status_id = 1;

refresh materialized view ehd.address_registry_map;

-- CATALOGS ADD
-- дополняем данными из дополнительных каталогов: 28475, 29690
insert into ar.address_registry(id, aid, obj_type, address, unom, p1, p3, p4, p5, p6, p7, p90, p91, l1_type, l1_value, l2_type, l2_value, l3_type, l3_value, l4_type, l4_value,
                                l5_type, l5_value, adm_area, district, nreg, n_fias, dreg, d_fias, kladr, adr_type, sostad, status, ar_object_status_id)
select nextval('ar.address_registry_id_seq'), t.aid, t.obj_type, t.address, t.unom, t.p1, t.p3, t.p4, t.p5, t.p6, t.p7, t.p90, t.p91,
       t.l1_type, t.l1_value, t.l2_type, t.l2_value, t.l3_type, t.l3_value, t.l4_type, t.l4_value, t.l5_type, t.l5_value, t.adm_area, t.district, t.nreg, t.n_fias,
       to_date(t.dreg, 'DD.MM.YYYY'), to_date(t.d_fias, 'DD.MM.YYYY'), t.kladr, t.adr_type, t.sostad, t.status, 1
from ehd.address_registry_property_objects_add t left join ar.address_registry m on t.aid = m.aid
where m.id isnull and t.p1 is not null and (t.p1 = 645611645 or t.p1 = 645608448) and t.sostad is not null and t.sostad not in (645607758, 645608660,645608507)
    and t.status is not null and t.status != 645611001 and t.unom not in (select a.unom from ar.address_registry a where a.unom is not null)
on conflict (id) do nothing;

refresh materialized view ehd.address_registry_map;


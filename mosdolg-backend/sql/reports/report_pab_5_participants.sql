drop function if exists public.report_pab_5_participants;
CREATE OR REPLACE FUNCTION public.report_pab_5_participants(neighbourhood text default ''::text)
  returns TABLE (
    "Уникальный номер в ЕСЗ"            bigint,
    "Уникальный номер в КИС МД"         bigint,
    "ТЦСО"                              character varying,
    "Тип связи с ТЦСО"                  text,
    "Коды групп в ЕСЗ (зачислен)"       text,
    "Коды групп в ЕСЗ (приостановлен)"  text,
    "Коды групп КИС МД (зачислен)"      text,
    "Коды групп КИС МД (приостановлен)" text,
    "ФИО"                               text,
    "Пол"                               character varying,
    "Дата рождения"                     date,
    "Контактный телефон"                text,
    "Дополнительный телефон"            text,
    "СНИЛС"                             character varying,
    "Номер СКМ"                         character varying,
    "Серия СКМ"                         character varying,
    "Адрес регистрации"                 character varying,
    "Адрес проживания"                  character varying,
    "Статус КИС МД"                     character varying,
    "Номер обращения"                   text,
    "Статус обращения"                  text,
    "Примечание"                        text
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L0 as ( -- Последний статус в группе
        select distinct
               cr.id,
               FIRST_VALUE(crsr.id) over (partition by crsr.class_record_id order by crsr.id desc) as last_status
        from md.class_record cr
               left join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
      ),
      G0 as (
        select po.participant_id,
               po.organization_id,
               string_agg(distinct (case
                                      when po.link_type = 'CREATED' then 'Создание'
                                      when po.link_type = 'GROUP' then 'Группа'
                                      when po.link_type = 'TERRITORY' then 'Территория'
                                      else po.link_type end), ', ') as ltype
        from md.participant_organization po
             --where po.link_type = 'GROUP'
        group by po.participant_id, po.organization_id
      ),
      G1 as (
        select cr.participant_id,
               gr.territory_centre_id tcso,
               string_agg((case
                             when crsr.class_record_status_id = 2 then cr.group_id::text
                             else null
                 end), ', ') as       stt_stop,
               string_agg((case
                             when crsr.class_record_status_id in (1, 3, 6, 7) then cr.group_id::text
                             else null
                 end), ', ') as       stt_start,
               string_agg((case
                             when crsr.class_record_status_id = 2 then gm.aid::text
                             else null
                 end), ', ') as       stt_stop_esz,
               string_agg((case
                             when crsr.class_record_status_id in (1, 3, 6, 7) then gm.aid::text
                             else null
                 end), ', ') as       stt_start_esz,
               string_agg(distinct (case
                                      when crsr.class_record_status_id = 2 then act1.title
                                      else null
                 end), ', ') as       activity_stop,
               string_agg(distinct (case
                                      when crsr.class_record_status_id in (1, 3, 6, 7) then act1.title
                                      else null
                 end), ', ') as       activity_start
        from L0 g
               left join md.class_record cr on g.id = cr.id
               left join md.class_record_status_registry crsr on g.last_status = crsr.id
               left join md.groups gr on cr.group_id = gr.id
               left join idb.groups_map gm on cr.group_id = gm.id
               left join reference.activity act1 on gr.activity_id = act1.id
               left join reference.activity act2 on act2.id = act1.parent_id
               left join reference.activity act3 on act3.id = act2.parent_id
        where crsr.class_record_status_id in (1, 2, 3, 6, 7)
        group by cr.participant_id, gr.territory_centre_id
      ),
      G2 as (
        select c.owner_id,
               max(case when c.priority = 0 then c.value else null end) main_phone,
               max(case when c.priority = 1 then c.value else null end) second_phone
        from md.contact c
        where c.contact_owner_type_id = 1
          and c.contact_type_id = 1
        group by c.owner_id
      ),
      L1 as (
        select distinct
               psl.participant_id,
               FIRST_VALUE(psl.id) over (partition by psl.participant_id order by psl.id desc) as last_status_pls
        from reference.participant_status_log psl
      ),
      G3 as (
        select psl.participant_id,
               ps.title as p_status
        from L1
               left join reference.participant_status_log psl on L1.last_status_pls = psl.id
               left join reference.participant_status ps on psl.status_id = ps.id
      )
    select pm.aid,
           p.id,
           coalesce(org2.short_title, org1.short_title) as short_title,
           G0.ltype,
           G1.stt_start_esz,
           G1.stt_stop_esz,
           G1.stt_start,
           G1.stt_stop,
           --G1.activity_start,
           --G1.activity_stop,
           initcap(concat(lower(p.second_name),
                          ' ', lower(p.first_name),
                          ' ', lower(p.patronymic)))    as FIO,
           gen.title,
           p.date_of_birth,
           G2.main_phone,
           G2.second_phone,
           p.snils,
           p.skm,
           p.skm_series,
           ar1.address                                  as registration_address,
           ar2.address                                  as fact_address,
           G3.p_status                                     status,
           ''                                           as ref_num,
           ''                                           as ref_stat,
           ''                                           as note
    from md.participant p
           left join idb.participant_map pm using (id)
           left join G0 on p.id = G0.participant_id
           left join md.organization org1 on p.organization_id = org1.id
           left join md.organization org2 on G0.organization_id = org2.id
           left join G1 on p.id = G1.participant_id and G0.organization_id = G1.tcso
           left join reference.gender gen on p.gender = gen.id
           left join G2 on p.id = G2.owner_id
           left join ar.address_registry ar1 on p.registration_address = ar1.id
           left join ar.address_registry ar2 on p.fact_address = ar2.id
           left join G3 on p.id = G3.participant_id
           left join md.territory_organization torg on coalesce(org2.id, org1.id) = torg.organization_id
           left join ar.territory t1 on torg.territory_id = t1.id
           left join ar.territory t2 on t1.parent_id = t2.id
    where (case
             when neighbourhood = '' then neighbourhood
             when t2.title = 'Северный административный округ' then 'САО'
             when t2.title = 'Северо-Восточный административный округ' then 'СВАО'
             when t2.title = 'Северо-Западный административный округ' then 'СЗАО'
             when t2.title = 'Восточный административный округ' then 'ВАО'
             when t2.title = 'Западный административный округ' then 'ЗАО'
             when t2.title = 'Южный административный округ' then 'ЮАО'
             when t2.title = 'Юго-Восточный административный округ' then 'ЮВАО'
             when t2.title = 'Юго-Западный административный округ' then 'ЮЗАО'
             when t2.title = 'Центральный административный округ' then 'ЦАО'
             when t2.title = 'Троицкий административный округ' then 'ТиНАО'
             when t2.title = 'Новомосковский административный округ' then 'ТиНАО'
             when t2.title = 'Зеленоградский административный округ' then 'ЗелАО'
      end) = neighbourhood
    order by p.id;

end
$$;
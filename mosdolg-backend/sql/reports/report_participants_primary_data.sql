drop function if exists public.report_participants_primary_data;
CREATE OR REPLACE FUNCTION public.report_participants_primary_data()
  returns TABLE (
    "Уникальный номер в ЕСЗ"    bigint,
    "Уникальный номер в КИС МД" bigint,
    "ТЦСО"                      character varying,
    "Тип связи с ТЦСО"          text,
    "Номер группы в ЕСЗ"        bigint,
    "Номер группы в КИС МД"     bigint,
    "Направление 1 уровня"      varchar,
    "Направление 2 уровня"      varchar,
    "Направление 3 уровня"      varchar,
    "Статус группы"             varchar,
    "ФИО"                       text,
    "Пол"                       character varying,
    "Дата рождения"             date,
    "Контактный телефон"        text,
    "Дополнительный телефон"    text,
    "СНИЛС"                     character varying,
    "Номер СКМ"                 character varying,
    "Серия СКМ"                 character varying,
    "Адрес регистрации"         character varying,
    "Адрес проживания"          character varying,
    "Статус КИС МД"             character varying
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
               gr.id      as          group_id,
               gm.aid     as          group_id_esz,
               act3.title as          activity_1,
               act2.title as          activity_2,
               act1.title as          activity_3,
               crs.title  as          gr_status,
               null       as          activity_profile_1,
               null       as          activity_profile_2,
               null       as          activity_profile_3
        from L0 g
               left join md.class_record cr on g.id = cr.id
               left join md.class_record_status_registry crsr on g.last_status = crsr.id
               left join reference.class_record_status crs on crsr.class_record_status_id = crs.id
               left join md.groups gr on cr.group_id = gr.id
               left join idb.groups_map gm on cr.group_id = gm.id
               left join reference.activity act1 on gr.activity_id = act1.id
               left join reference.activity act2 on act2.id = act1.parent_id
               left join reference.activity act3 on act3.id = act2.parent_id
        where crsr.class_record_status_id in (1, 2, 3, 6, 7)
        /*union all
        select pap.participant_id,
               p.organization_id,
               null,null,null,null,null,null,
               (case when act3.title isnull then act2.title
                    when act2.title isnull then act1.title
                    else act3.title
               end) as activity_1,
               (case when act3.title isnull then act1.title
                    else act2.title
               end) as activity_2,
               (case when act3.title isnull then null
                     when act2.title isnull then null
                    else act1.title
               end) as activity_3
        from md.participant_activity_profile pap
               left join md.class_record cr on pap.id = cr.participant_activity_profile_id
               left join reference.activity act1 on pap.activity_id = act1.id
               left join reference.activity act2 on act2.id = act1.parent_id
               left join reference.activity act3 on act3.id = act2.parent_id
               left join md.participant p on pap.participant_id=p.id
        where cr.id is null*/
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
           G1.group_id_esz,
           G1.group_id,
           G1.activity_1                                as activity_group_1,
           G1.activity_2                                as activity_group_2,
           G1.activity_3                                as activity_group_3,
           G1.gr_status,
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
           G3.p_status                                     status
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
        --left join G4 on p.id = G4.participant_id and G0.organization_id = G4.organization_id
           left join md.territory_organization torg on coalesce(org2.id, org1.id) = torg.organization_id
           left join ar.territory t1 on torg.territory_id = t1.id
           left join ar.territory t2 on t1.parent_id = t2.id
    where (G1.activity_1 is not null or G1.activity_profile_1 is not null)
    order by p.id;
  --limit 10000;

end
$$;
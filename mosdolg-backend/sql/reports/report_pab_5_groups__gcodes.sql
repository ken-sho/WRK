drop function if exists public.report_pab_5_groups__gcodes;
CREATE OR REPLACE FUNCTION public.report_pab_7_primary_report_reconciliation()
  returns TABLE (
    "ФИО"                             text,
    "Пол"                             bigint,
    "Дата рождения"                   date,
    "Контактный телефон"              character varying,
    "Email"                           character varying,
    "Дополнительный телефон"          character varying,
    "Уникальный номер участника"      bigint,
    "Тип документа"                   character varying,
    "Дата выдачи"                     date,
    "Серия и номер документа"         character varying,
    "Кем выдан"                       character varying,
    "Код подразделения"               character varying,
    "СНИЛС"                           character varying,
    "Номер_СКМ"                       character varying,
    "Серия_СКМ"                       character varying,
    "Необходимо принести документы"   boolean,
    "Причина отсутствия документа"    character varying,
    "Адрес регистрации"               character varying,
    "Район регистрации"               character varying,
    "Адрес проживания"                character varying,
    "Район проживания"                character varying,
    "ТЦСО"                            character varying,
    "Статус личного дела"             character varying,
    "Статус записи в группу"          bigint,
    "Статус записи в группу текст"    character varying,
    "Статус записи в группу отчислен" character varying,
    "Занятость участника"             character varying,
    "Была запись в группу"            boolean
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L0 as (
        select cr.participant_id,
               first_value(crsr.class_record_status_id)
               over (partition by crsr.class_record_id order by crsr.id desc)                        as last_status,
               first_value(crs.title) over (partition by crsr.class_record_id order by crsr.id desc) as last_status_text
        from md.class_record cr
               join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
               join reference.class_record_status crs on crsr.class_record_status_id = crs.id
      )
    select (coalesce(p.second_name, '') || ' ' || coalesce(p.first_name, '') || ' ' ||
            coalesce(p.patronymic, '')) as ФИО,
           p.gender                     as Пол,
           p.date_of_birth              as Дата_рождения,
           c.value                      as Контактный_телефон,
           c1.value                     as Email,
           c3.value                     as Дополнительный_телефон,
           p.id                         as Уникальный_номер_участника_в_КИС_МД,
           dt.title                     as Тип_документа,
           pd.date_from                 as Дата_выдачи,
           pd.serial_number             as Серия_и_номер_документа,
           pd.department                as Кем_выдан,
           pd.department_code           as Код_подразделения,
           p.snils                      as СНИЛС,
           p.skm                        as Номер_СКМ,
           p.skm_series                 as Серия_СКМ,
           p.required_documents         as Необходимо_принести_документы,
           dar.title                    as Причина_отсутствия_документа,
           addr2.address                as Адрес_регистрации,
           tr2.title                    as Район_регистрации,
           addr.address                 as Адрес_проживания,
           tr.title                     as Район_проживания,
           o.short_title                as ТЦСО,
           ps.title                     as Статус_личного_дела,
           L0.last_status               as Статус_записи_в_группу,
           L0.last_status_text          as Статус_записи_в_группу_текст,
           (case
              when L0.last_status_text = 'Отчислен' then L0.last_status_text
              else '' end)              as Статус_записи_в_группу_отчислен,
           occ.title                    as Занятость_участника,
           (case
              when L0.last_status_text = 'Отчислен' and ps.title in ('Отказ от участия', 'Отказано в участии')
                then false
              when L0.participant_id is not null then true
              else false end)           as "Была_запись_в_группу"
    from md.participant p
           left join md.contact c on c.owner_id = p.id and c.contact_type_id = 1 and c.priority = 0
           left join md.contact c1 on (c1.owner_id = p.id and c1.contact_type_id = 2)
           left join md.contact c3 on (c3.owner_id = p.id and c3.contact_type_id = 1 and c3.priority = 1)
           left join md.personal_document pd on pd.participant_id = p.id
           left join L0 on p.id = L0.participant_id
           left join ar.address_registry addr on addr.id = p.fact_address
           left join ar.territory tr on addr.district = tr.id
           left join ar.address_registry addr2 on addr2.id = p.registration_address
           left join ar.territory tr2 on addr2.district = tr2.id
           left join md.organization o on o.id = p.organization_id
           left join reference.participant_status_log psl on psl.participant_id = p.id and psl.end_date isnull
           left join reference.participant_status ps on ps.id = psl.status_id
           left join reference.occupation occ on occ.id = p.occupation_id
           left join reference.document_type dt on dt.id = pd.document_type_id
           left join reference.gender sx on sx.id = p.gender
           left join reference.documents_absence_reason dar on dar.id = p.documents_absence_reason_id
    group by p.second_name, p.first_name, p.patronymic, p.gender, p.date_of_birth, c.value, c1.value,
             c3.value, p.id, dt.title, pd.date_from, pd.serial_number, pd.department, pd.department_code,
             p.snils, p.skm, p.skm_series, p.required_documents, dar.title, addr2.address, addr.address,
             o.short_title, ps.title, L0.last_status, L0.last_status_text, L0.participant_id, occ.title,
             tr.title, tr2.title;

end
$$;
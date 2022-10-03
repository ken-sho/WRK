create or replace view md.class_record_view
    ("Идентификатор записи в группу", "Номер личного дела", "Фамилия Имя Отчество участника", "Дата начала участия",
     "Дата окончания участия", "Код группы", "Идентификатор профиля активности", "Направление 3 уровня",
     "Статус профиля активности", "Дата начала приостановки", "Дата окончания приостановки",
     "Отметка о переводе в другую группу", "Идентификатор статуса записи в гр", "Статус записи в группу",
     "Дата начала действия статуса запи", "Дата окончания действия статуса з")
as
select cr.id                                                       as "Идентификатор записи в группу",
       cr.participant_id                                           as "Номер личного дела",
       concat(p.second_name, ' ', p.first_name, ' ', p.patronymic) as "Фамилия Имя Отчество участника",
       cr.date_from                                                as "Дата начала участия",
       cr.date_to                                                  as "Дата окончания участия",
       g.group_code::text                                          as "Код группы",
       cr.participant_activity_profile_id                          as "Идентификатор профиля активности",
       a.title                                                     as "Направление 3 уровня",
       paps.title                                                  as "Статус профиля активности",
       cr.pause_date_from                                          as "Дата начала приостановки",
       cr.pause_date_to                                            as "Дата окончания приостановки",
       cr.transferred                                              as "Отметка о переводе в другую группу",
       crsr.class_record_status_id                                 as "Идентификатор статуса записи в гр",
       crs.title                                                   as "Статус записи в группу",
       crsr.start_date                                             as "Дата начала действия статуса запи",
       crsr.end_date                                               as "Дата окончания действия статуса з"
from md.class_record cr
       left join md.class_record_status_registry crsr on cr.id = crsr.class_record_id and crsr.end_date is null
       join reference.class_record_status crs on crsr.class_record_status_id = crs.id
       join md.participant p on cr.participant_id = p.id
       join md.groups g on cr.group_id = g.id
       join reference.activity a on g.activity_id = a.id
       join md.participant_activity_profile pap on pap.id = cr.participant_activity_profile_id
       join reference.participant_activity_profile_status paps on paps.id = pap.status_id;


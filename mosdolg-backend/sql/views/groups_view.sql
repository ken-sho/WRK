create or replace view md.groups_view
    ("Код группы", "Статус группы", "Причина установки статуса группы", "Комментарий при изменении статуса",
     "Дата установки статуса группы", "Дата окончания статуса группы", "Минимальное количество участнико",
     "Максимальное количество участник", "Плановая дата начала занятий", "Плановая дата окончания занятий",
     "Фактическая дата начала занятий", "Фактическая дата окончания заняти", "Возможен донабор", "Необходима справка",
     "Идентификатор противопоказания", "Противопоказания", "Идентификатор требования к форме ",
     "Требования к форме одежды", "Идентификатор требования к инвент", "Требования к инвентарю",
     "Краткое наименование организации", "Идентификатор ведомства", "Ведомство", "Идентификатор направления",
     "Направление", "Идентификатор родительского напр", "Идентификатор типа направления", "Тип направления",
     "Комментарий", "Идентификатор координатора", "Фамилия Имя Отчество координатора", "Идентификатор соглашения",
     "Идентификатор поставщика", "Краткое наименование поставщика", "Идентификатор заказчика",
     "Краткое наименование заказчика", "Номер соглашения", "Дата начала действия соглашения",
     "Дата окончания действия соглашени", "ТЦСО", "Код группы в ЕСЗ", "Идентификатор площадки", "Наименование площадки",
     "Адрес площадки", "Время начала занятий", "Время окончания занятий", "Дата начала занятий",
     "Дата окончания занятий", "Приостановка занятий", "Дата начала каникул", "Дата окончания каникул")
as
select group_code::text                                                   as "Код группы",
       gs.title                                                           as "Статус группы",
       gsr.title                                                          as "Причина установки статуса группы",
       gst.comment                                                        as "Комментарий при изменении статуса",
       gst.start_date                                                     as "Дата установки статуса группы",
       gst.end_date                                                       as "Дата окончания статуса группы",
       groups.min_count                                                   as "Минимальное количество участнико",
       groups.max_count                                                   as "Максимальное количество участник",
       groups.plan_start_date                                             as "Плановая дата начала занятий",
       groups.plan_end_date                                               as "Плановая дата окончания занятий",
       groups.fact_start_date                                             as "Фактическая дата начала занятий",
       groups.fact_end_date                                               as "Фактическая дата окончания заняти",
       groups.extend                                                      as "Возможен донабор",
       groups.need_note                                                   as "Необходима справка",
       gc.contraindication_id                                             as "Идентификатор противопоказания",
       cont.title                                                         as "Противопоказания",
       gdc.dress_code_id                                                  as "Идентификатор требования к форме ",
       rdc.title                                                          as "Требования к форме одежды",
       gir.inventory_requirement_id                                       as "Идентификатор требования к инвент",
       rir.title                                                          as "Требования к инвентарю",
       o.short_title                                                      as "Краткое наименование организации",
       o.department_id                                                    as "Идентификатор ведомства",
       dep.title                                                          as "Ведомство",
       groups.activity_id                                                 as "Идентификатор направления",
       a.title                                                            as "Направление",
       a.parent_id                                                        as "Идентификатор родительского напр",
       a.activity_type                                                    as "Идентификатор типа направления",
       aty.title                                                          as "Тип направления",
       groups.comment                                                     as "Комментарий",
       groups.coworker_id                                                 as "Идентификатор координатора",
       concat(cow.first_name, ' ', cow.second_name, ' ', cow.middle_name) as "Фамилия Имя Отчество координатора",
       groups.contract_id                                                 as "Идентификатор соглашения",
       con.provider_id                                                    as "Идентификатор поставщика",
       o.short_title                                                      as "Краткое наименование поставщика",
       con.organization_id                                                as "Идентификатор заказчика",
       cust_o.short_title                                                 as "Краткое наименование заказчика",
       con.contract_number                                                as "Номер соглашения",
       con.date_from                                                      as "Дата начала действия соглашения",
       con.date_to                                                        as "Дата окончания действия соглашени",
       groups.territory_centre_id                                         as "ТЦСО",
       groups.esz_code                                                    as "Код группы в ЕСЗ",
       sch.place_id                                                       as "Идентификатор площадки",
       place.title                                                        as "Наименование площадки",
       ar.address                                                         as "Адрес площадки",
       sch.start_date                                                     as "Время начала занятий",
       sch.end_time                                                       as "Время окончания занятий",
       sch.start_date                                                     as "Дата начала занятий",
       sch.end_date                                                       as "Дата окончания занятий",
       sch.pause                                                          as "Приостановка занятий",
       vacations.vacation_start_date                                      as "Дата начала каникул",
       vacations.vacation_end_date                                        as "Дата окончания каникул"
from md.groups
       left join md.group_status_registry gst on groups.id = gst.group_id and gst.end_date is null
       join reference.group_status gs on gst.status_id = gs.id
       left join reference.group_status_reason gsr on gsr.id = gst.reason_id
       left join md.group_contraindication gc on groups.id = gc.group_id
       left join reference.contraindication cont on gc.contraindication_id = cont.id
       left join md.group_dress_code gdc on groups.id = gdc.group_id
       left join reference.dress_code rdc on gdc.dress_code_id = rdc.id
       left join md.group_inventory_requirement gir on groups.id = gir.group_id
       left join reference.inventory_requirement rir on gir.inventory_requirement_id = rir.id
       left join md.organization o on groups.organization_id = o.id
       left join reference.department dep on o.department_id = dep.id
       left join reference.activity a on groups.activity_id = a.id
       left join reference.activity_type aty on a.id = aty.id
       left join md.coworker cow on groups.coworker_id = cow.id
       left join md.contract con on groups.contract_id = con.id
       left join md.organization cust_o on cust_o.id = con.organization_id
       left join md.schedule sch on groups.id = sch.group_id
       join md.place on sch.place_id = place.id
       left join md.vacations on groups.id = vacations.group_id
       left join ar.address_registry ar on ar.id = place.address;


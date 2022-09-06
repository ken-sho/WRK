-- 18.09
-- постпроцессинг статусов

-- сначала проставляем всем черновик
update idb.group_status_registry set status_id = 1;

-- создана идет набор 3
update idb.group_status_registry set status_id = 3 where group_id in (
	select id from idb.groups
	where current_date < plan_start_date order by id
);

-- ожидание начала занятий 7
update idb.group_status_registry set status_id = 7 where group_id in (
	select id from idb.groups
	where current_date < plan_start_date and order_date is not null
	order by id
);

-- приступила к занятиям 8
update idb.group_status_registry set status_id = 8 where group_id in (
	select id from idb.groups
	where current_date between plan_start_date and plan_end_date order by id
);

-- занятия завершены 13
update idb.group_status_registry set status_id = 13 where group_id in (
  select id from idb.groups where plan_end_date < current_date order by id
);


-- в статусе черновик остаются группы, у которых планируемая дата начала больше текущей даты (2019-10-09),
-- а фактическая дата начала меньше текущей даты (2019-01-12).

-- проверка статусов:
-- select status_id, count(*)
-- from idb.group_status_registry
-- group by status_id
-- order by status_id;


-- валидация записей в class_record после выполнения переноса:
-- 	select group_id, participant_id, count(participant_id) p_num
-- 	from idb.class_record
-- 	group by group_id, participant_id
-- 	having count(participant_id) > 1
--
-- должно быть 0 по всем записям.
-- аналогично можно проверить для md.class_record
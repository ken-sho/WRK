-- сравнение числа записей в одинаковых таблицах idb и md
-- select * from idb_ws_md_rows_number()
drop function if exists idb_ws_md_rows_number;
create or replace function idb_ws_md_rows_number()
	RETURNS table
					(
						"table_name" text,
						"idb_count"  integer,
						"md_count"   integer,
						"diff"       integer,
						"sdb_count"  integer
					)
as
$$
declare
	row     record;
	i_count int;
	m_count int;
	s_count int;
	s_count_2 int;
	i_query varchar;
begin
	drop table if exists num_of_rows;
	CREATE temporary TABLE num_of_rows
	(
		"table_name" text,
		"idb_count"  integer,
		"md_count"   integer,
		"diff"       integer,
		"sdb_count"  integer
	);

	for row in select *
						 from (SELECT tablename, count(1) as num
									 FROM pg_catalog.pg_tables
									 WHERE schemaname in ('idb', 'md')
									 group by tablename
									 order by tablename) L1
						 where num = 2
		loop
			i_query := 'select count(*) from idb.' || row.tablename;
			execute i_query into i_count;
			i_query := 'select count(*) from md.' || row.tablename;
			execute i_query into m_count;
			if (select count(1) from pg_catalog.pg_tables where tablename = row.tablename AND schemaname = 'sdb') = 0
			then
				s_count := null;
			else
				i_query := 'select count(*) from sdb.' || row.tablename;
				execute i_query into s_count;
			end if;

			insert into num_of_rows values (row.tablename, i_count, m_count, i_count - m_count, s_count);
		end loop;

	    -- пока костыль, для коворкеров
		execute 'select count(*) from idb.coworkers' into i_count;
		execute 'select count(*) from sdb.coworker_user' into s_count;
		execute 'select count(*) from sdb.coworker_teacher' into s_count_2;
		s_count := s_count + s_count_2;
		execute 'select count(*) from md.coworker' into m_count;

		insert into num_of_rows values (
			'coworkers',
			i_count, m_count, i_count - m_count, s_count
		);
		--

	return query select * from num_of_rows order by diff desc;

end
$$ language plpgsql;

select * from idb_ws_md_rows_number();
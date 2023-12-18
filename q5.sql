select *
	from station
	order by loc <-> point '(0, 0)' limit 5;
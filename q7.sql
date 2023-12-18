select my_table.ssn 
	from ((select ssn, sum(end_time - start_time) as metro_time
		from trip_receipt natural join trip
		natural join public_car
		natural join transportation
		where type = 'merto'
	-- 	and start_time >= st
	-- 	and end_time <= et
		   group by ssn
		   ) as t1
	cross join
	(select sum(end_time - start_time) as bus_time
		from trip_receipt natural join trip
		natural join public_car
		natural join transportation
		where type = 'bus') as t2) as my_table
	where my_table.metro_time > my_table.bus_time
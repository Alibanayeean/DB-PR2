select count(car2) as number_of_cars, car1, st1
	from
	(select car as car1, enter_time as st1, exit_time as et1
		from parking_receipt as pr
		where pr.pid = 0
	) as t1
	join 
	(select car as car2, enter_time as st2, exit_time as et2
		from parking_receipt as pr
		where pr.pid = 0) as t2
	on t1.st1 between t2.st2 and t2.et2
	
	group by car1, st1
	order by number_of_cars
	limit 1
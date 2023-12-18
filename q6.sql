select ssn, count(station) as trip
	from(
		select tr.start_station as station, ssn from trip_receipt as tr
			where tr.start_time >= st
		union 
		select tr.end_station as station, ssn from trip_receipt as tr
			where tr.end_time <= et
	) as stations
	group by ssn
	order by count(station)
	limit 5

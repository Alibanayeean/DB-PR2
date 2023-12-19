create view view_2 as 
	select staion, count(ssn) as passengers from(
		select tr.start_station as staion, ssn from trip_receipt as tr
			where ABS(DATE_PART('day', tr.start_time - current_timestamp)) <= 1
		union 
		select tr.end_station as staion, ssn from trip_receipt as tr
			where ABS(DATE_PART('day', tr.end_time - current_timestamp)) <= 1
	) as stations
		group by staion

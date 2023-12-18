select distinct ppt1.ssn
	from (
		select citizen.ssn, pr.enter_time, pr.exit_time
			FROM parking_receipt AS pr
			JOIN citizen ON pr.driver=citizen.ssn
	) as ppt1 --person_parking_time 1
	where ppt1.ssn in (
		select ppt2.ssn
		from (
			select citizen.ssn, pr.enter_time, pr.exit_time
				FROM parking_receipt AS pr
				JOIN citizen ON pr.driver=citizen.ssn
		) as ppt2 --person_parking_time 2
		where ppt1.ssn = ppt2.ssn 
		and ABS(DATE_PART('day', ppt1.enter_time - ppt2.enter_time)) < 2 
		and ABS(DATE_PART('day', ppt1.enter_time - ppt2.enter_time)) >= 1
	)
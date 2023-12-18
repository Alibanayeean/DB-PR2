select ssn, AVG(cost)
	from (select ssn, cost
		  	FROM trip
			NATURAL JOIN trip_receipt
			NATURAL JOIN citizen
	) as citizen_public_costs
	where citizen_public_costs.ssn in (select ssn
		from personal_car join citizen on citizen.ssn = personal_car.owner)
	group by ssn
	
	
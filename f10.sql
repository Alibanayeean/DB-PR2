CREATE FUNCTION f10 (person_id character varying, month timestamp with time zone)
RETURNS TABLE(
	cost_sum integer
	
)
AS $$
BEGIN
	RETURN QUERY
	SELECT SUM(cost) as cost_sum
		FROM (
			SELECT cost
				FROM parking_receipt AS pr
					JOIN citizen ON pr.driver=citizen.ssn
				WHERE month <= extract(month from enter_time)
					AND month >= extract(month from exit_time)
					AND ssn = person_id
			UNION
			SELECT cost
				FROM trip_receipt
					NATURAL JOIN citizen
				WHERE month <= extract(month from start_time) 
					AND month >= extract(month from end_time)
					AND ssn = person_id
			UNION
			SELECT supervisor, cost
				FROM urban_service_receipt AS usr
					JOIN home ON usr.owner=home.hid
					JOIN citizen ON home.owner=citizen.ssn
				WHERE month <= extract(month from date) 
					AND month >= extract(month from date)
					AND ssn = person_id
		) as costs_for_one_person_in_a_month;
END; $$
LANGUAGE plpgsql;


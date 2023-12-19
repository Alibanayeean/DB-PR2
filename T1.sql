CREATE OR REPLACE FUNCTION T1_function()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.cost > (select sum(balacne) from citizen_acc where NEW.driver = citizen_acc.ssn)	Then
		UPDATE citizen_acc as ca1
			SET ca1.balance = NEW.cost - (select sum(citizen_acc.balacne) from citizen_acc where NEW.driver = citizen_acc.ssn)
			WHERE ca1.acc_no = (SELECT acc_no FROM citizen_acc as ca2 
									   WHERE ca2.ssn in (
										   select pc.owner as ssn
										   from personal_car as pc
										   where pc.cid = NEW.car
									   )
									   ORDER BY acc_no LIMIT 1);
		UPDATE citizen_acc as ca
    	SET ca.balance = 0
    	WHERE NEW.driver = ca.ssn;
	END IF;
	
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

create or REPLACE trigger T1
	After insert on parking_receipt
	for each row 
	EXECUTE FUNCTION T1_function();

	
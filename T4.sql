CREATE OR REPLACE FUNCTION T4_pr_function()
RETURNS TRIGGER AS $$
BEGIN
	UPDATE citizen_acc as ca1
			SET ca1.balance = ca1.balance - NEW.cost
			WHERE ca1.acc_no = (SELECT acc_no FROM citizen_acc as ca2 
									   WHERE ca2.ssn= New.driver
									   ORDER BY acc_no LIMIT 1);
  RETURN NEW;
END;-
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION T4_tr_function()
RETURNS TRIGGER AS $$
BEGIN
	UPDATE citizen_acc as ca1
			SET ca1.balance = ca1.balance - NEW.cost
			WHERE ca1.acc_no = (SELECT acc_no FROM citizen_acc as ca2 
									   WHERE ca2.ssn= New.ssn
									   ORDER BY acc_no LIMIT 1);
  RETURN NEW;
END;-
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION T4_usr_function()
RETURNS TRIGGER AS $$
BEGIN
	UPDATE citizen_acc as ca1
			SET ca1.balance = ca1.balance - NEW.cost
			WHERE ca1.acc_no = (SELECT acc_no FROM citizen_acc as ca2 
									   WHERE ca2.ssn = (select owner from home New.owner = home.hid)
									   ORDER BY acc_no LIMIT 1);
  RETURN NEW;
END;-
$$ LANGUAGE plpgsql;

create or REPLACE trigger T4_pr
	After insert on parking_receipt
	for each row 
	EXECUTE FUNCTION T4_pr_function();
	
create or REPLACE trigger T4_tr
	After insert on parking_receipt
	for each row 
	EXECUTE FUNCTION T4_pr_function();
	
create or REPLACE trigger T4_usr
	After insert on parking_receipt
	for each row 
	EXECUTE FUNCTION T4_usr_function();

	
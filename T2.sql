CREATE OR REPLACE FUNCTION balance_checking_parking_receipt()
RETURNS TRIGGER AS $$
BEGIN
    IF (select sum(balance) from citizen_acc where NEW.driver = ssn) <= 0 then
        RAISE EXCEPTION 'Balance less than zero';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION balance_checking_trip_receipt()
RETURNS TRIGGER AS $$
BEGIN
    IF (select sum(balance) from citizen_acc where citizen_acc.ssn = New.ssn) <= 0 then
        RAISE EXCEPTION 'Balance less than zero';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER T2_tr
BEFORE INSERT ON trip_receipt
FOR EACH ROW
EXECUTE FUNCTION balance_checking_trip_receipt();


CREATE or replace TRIGGER T2_pr
BEFORE INSERT ON parking_receipt
FOR EACH ROW
EXECUTE FUNCTION balance_checking_parking_receipt();
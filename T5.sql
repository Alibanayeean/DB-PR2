CREATE OR REPLACE FUNCTION check_start_end_time()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.start_time >= NEW.end_time THEN
        RAISE EXCEPTION 'Start time must be less than end time';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER T5
BEFORE INSERT ON trip_receipt
FOR EACH ROW
EXECUTE FUNCTION check_start_end_time();


CREATE TRIGGER T5
BEFORE INSERT ON parking_receipt
FOR EACH ROW
EXECUTE FUNCTION check_start_end_time();


CREATE TRIGGER T5
BEFORE INSERT ON urban_service_receipt
FOR EACH ROW
EXECUTE FUNCTION check_start_end_time();
create view view_3 as 
	select my_table.public_car as metro_number, count(ssn) as number_of_people from
		(select distinct ssn, public_car
		from trip natural join trip_receipt
		natural join path
		natural join network
		natural join transportation
		natural join trans_car

		where type = 'metro') as my_table
		group by my_table.public_car
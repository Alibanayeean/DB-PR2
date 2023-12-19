import random

# random.seed(42)

citizens_id = []
citizen = []
year = [1920 + i for i in range(100)]
day = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10']
month = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10']
gender = ['male', 'female']
for i in range(1, 501):
    citizens_id.append(f'{i}')
    if i < 11:
        citizen.append(f'(\'{i}\', \'{random.choice(year)}-{random.choice(day)}-{random.choice(month)}\', \'{i}\', \'{i}\', \'{random.choice(gender)}\', \'{i}\')')
    else:
        citizen.append(
            f'(\'{i}\', \'{random.choice(year)}-{random.choice(day)}-{random.choice(month)}\', \'{i}\', \'{i}\', \'{random.choice(gender)}\', \'{random.choice([j for j in range(1, 11)])}\')')


parking = []
parkings_id = []
for i in range(1, 51):
    parkings_id.append(i)
    parking.append(f'({10000 + i}, {i}, {i}, \'{i}\', {i}, {100 * (i + 1)}, \'8:00:00 +03:30\', \'24:00:00 +03:30\')')

citizen_acc = []
for i in range(1, 251):
    citizen_acc.append(f'(\'{random.choice(citizens_id)}\', \'{i}\', {10 * i})')

homes = []
homes_id = []
for i in range(1, 501):
    homes_id.append(i)
    homes.append(f'(\'tehran\plaque{i}\', {i}, {i + 12.5}, {i + 12.5}, \'{random.choice(citizens_id)}\')')

cars = []
cars_id = []
colors = ['blue', 'green', 'red', 'black', 'white']
brands = ['lamborgini', 'ferari', 'toyota', 'MVM']
for i in range(1, 251):
    cars_id.append(i)
    cars.append(f'({i}, \'{random.choice(colors)}\', \'{random.choice(brands)}\')')

personal_cars = []

random.shuffle(cars_id)
for i in range(1, 201):
    personal_cars.append(f'({i}, \'{cars_id[i]}\')')





urban_service = []
urban_service_id = []

for i in range(1, 11):
    urban_service_id.append(i)
    type = random.choice(['water', 'gas', 'electricity'])
    urban_service.append(f'(\'{type}\', {i})')



transportation = []
transportation_id = []
for i in range(1, 101):
    transportation_id.append(i)
    type = random.choice(['taxi', 'bus', 'metro'])
    transportation.append(f'({i}, \'{type}\')')

public_car = []
public_car_driver = []
for i in range(1, 51):



paths = []
paths_id = []
for i in range(1, 101):
    paths_id.append(i)
    paths.append(f'({i}, \'{i}\')')

network_id = []
network = []
random.shuffle(paths_id)
random.shuffle(transportation_id)

for i in range(1, 101):
    network_id.append(i)
    network.append(f'({i}, {10 * i}, {paths_id[i - 1]}, {transportation_id[i - 1]})')

stations = []
stations_id = []
for i in range(1, 201):
    stations_id.append(i)
    stations.append(f'({i * 21}, {i * 21 + 5}, \'station_{i}\', {i})')

adj_station = []
used = []
for i in range(1, 101):
    distance = int (random.random() * 100)
    duration = int (random.random() * 2)
    start = random.choice(stations_id)
    end = random.choice(stations_id)
    while start == end or (start, end) in used:
        start = random.choice(stations_id)
        end = random.choice(stations_id)
    used.append((start, end))
    adj_station.append(f'({start}, {end}, {distance}, {duration})')

station_path = []


history_id = []
history = []
trip_receipt = []
trip_receipt_id = []
parking_receipt = []
parking_receipt_id = []
urban_service_receipt = []
urban_service_receipt_id = []
counter_trip = 1
counter_parking = 1
counter_urban_service_receipt = 1

for i in range(1, 301):
    history_id.append(i)
    history.append(f'(\'{i}\')')

    num = random.choice([1, 2, 3])
    if num == 1:
        hour = random.choice([i for i in range(8, 24)])
        start = f'{hour}:00:00 +03:30'
        if random.random() < 0.5:
            end = f'{hour}:30:00 +03:30'
        else:
            end = f'{hour + 1}:00:00 +03:30'
        trip_receipt_id.append(i)

        start_station = random.choice(stations_id)
        end_station = random.choice(stations_id)
        while start_station == end_station:
            start_station = random.choice(stations_id)
            end_station = random.choice(stations_id)
        trip_receipt.append(f'(\'{start}\', \'{end}\', {10 * i}, \'{counter_trip}\', \'{i}\', {start_station}, {end_station}, {random.choice(paths_id)}, \'{random.choice(citizens_id)}\')')
        counter_trip += 1
    elif num == 2:

        hour = random.choice([i for i in range(8, 24)])
        start = f'{hour}:00:00 +03:30'
        if random.random() < 0.5:
            end = f'{hour}:30:00 +03:30'
        else:
            end = f'{hour + 1}:00:00 +03:30'
        parking_receipt_id.append(i)
        parking_receipt.append(
            f'(\'{end}\', \'{start}\', \'{counter_parking}\', {10 * i}, {random.choice(cars_id)},\'{random.choice(citizens_id)}\', \'{i}\')')
        counter_parking += 1
    else:
        urban_service_receipt_id.append(i)
        urban_service_receipt.append(
            f'(\'{counter_urban_service_receipt}\', {1000 * i}, \'{random.choice(year)}-{random.choice(day)}-{random.choice(month)}\', {(int (random.random() * 10))}, {random.choice(homes_id)}, {random.choice(urban_service_id)}, \'{i}\')')
        counter_urban_service_receipt += 1






def for_print_in_sql(name, l):
    print(f'insert into {name}')
    print('values', end=' ')
    for i in range(len(l)):
        if i == len(l) - 1:
            print(f'\t {l[i]};')
        else:
            print(f'\t {l[i]} ,')

for_print_in_sql('citizen', citizen)
for_print_in_sql('citizen_acc', citizen_acc)
for_print_in_sql('parking', parking)
for_print_in_sql('home', homes)
for_print_in_sql('car', cars)
for_print_in_sql('personal_car', personal_cars)
for_print_in_sql('urban_service', urban_service)
for_print_in_sql('transportation', transportation)
for_print_in_sql('path', paths)
for_print_in_sql('network', network)
for_print_in_sql('station', stations)
for_print_in_sql('adj_station', adj_station)
for_print_in_sql('history', history)
for_print_in_sql('trip_receipt', trip_receipt)
for_print_in_sql('parking_receipt', parking_receipt)
for_print_in_sql('urban_service_receipt', urban_service_receipt)








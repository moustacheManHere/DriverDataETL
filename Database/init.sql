create database cab_data;

GO

use cab_data;

create table drivers (
    driver_id int primary key,
    driver_name varchar(255),
    date_of_birth date,
    no_of_years_driving_exp int,
    gender varchar(6),
    car_brand varchar(100),
    car_model_year int,
    driver_rating decimal(2,1)
);

create table safety_status (
    bookingID bigint primary key,
    driver_id int,
    label int,
    foreign key (driver_id) references drivers (driver_id)
);

create table sensor (
    sensor_id int identity(1, 1) primary key,
    bookingID bigint,
    accuracy decimal(8,4) null,
    bearing float null,
    acc_x float null,
    acc_y float null,
    acc_z float null,
    gyro_x float null,
    gyro_y float null,
    gyro_Z float null,
    sec decimal(12,1) null,
    speed float null,
    foreign key (bookingID) references safety_status (bookingID)
);

bulk insert drivers from 'C:\dengData\drivers_dataset.csv'
with (
    format = 'CSV',
    firstrow = 2,
    fieldterminator = ',',
    ROWTERMINATOR = '0x0a'
);

bulk insert safety_status from 'C:\dengData\safety_status_dataset.csv'
with (
    format = 'CSV',
    firstrow = 2,
    fieldterminator = ',',
    ROWTERMINATOR = '0x0a'
);

bulk insert sensor from 'C:\dengData\0_Sensor_DataSet_features_part.csv'
with (
    format = 'CSV',
    firstrow = 2,
    fieldterminator = ',',
    ROWTERMINATOR = '0x0a'
);

bulk insert sensor from 'C:\dengData\1-Sensor_DataSet_features_part.csv'
with (
    format = 'CSV',
    firstrow = 2,
    fieldterminator = ',',
    ROWTERMINATOR = '0x0a'
);

bulk insert sensor from 'C:\dengData\2-Sensor_DataSet_features_part.csv'
with (
    format = 'CSV',
    firstrow = 2,
    fieldterminator = ',',
    ROWTERMINATOR = '0x0a'
);

bulk insert sensor from 'C:\dengData\3_Sensor_DataSet_features_part.csv'
with (
    format = 'CSV',
    firstrow = 2,
    fieldterminator = ',',
    ROWTERMINATOR = '0x0a'
);

bulk insert sensor from 'C:\dengData\4_Sensor_DataSet_features_part.csv'
with (
    format = 'CSV',
    firstrow = 2,
    fieldterminator = ',',
    ROWTERMINATOR = '0x0a'
);
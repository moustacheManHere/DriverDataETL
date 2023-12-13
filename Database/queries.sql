use cab_data;


-- query 1
WITH TripAverages AS (
    SELECT
        s.bookingID,
        AVG(s.accuracy) AS avg_accuracy,
        AVG(s.bearing) AS avg_bearing,
        AVG(s.acc_x) AS avg_acc_x,
        AVG(s.acc_y) AS avg_acc_y,
        AVG(s.acc_z) AS avg_acc_z,
        AVG(s.gyro_x) AS avg_gyro_x,
        AVG(s.gyro_y) AS avg_gyro_y,
        AVG(s.gyro_Z) AS avg_gyro_Z,
        AVG(s.sec) AS avg_sec,
        AVG(s.speed) AS avg_speed
    FROM
        safety_status ss
    JOIN
        sensor s ON ss.bookingID = s.bookingID
    WHERE
        ss.label = 1
    GROUP BY
        s.bookingID
), danger_metric as (
    SELECT
        ta.bookingID,
        ROW_NUMBER() OVER (ORDER BY 
            (
                (CASE WHEN MAX(ta.avg_accuracy) - MIN(ta.avg_accuracy) = 0 THEN 0 ELSE (ta.avg_accuracy - MIN(ta.avg_accuracy)) / (MAX(ta.avg_accuracy) - MIN(ta.avg_accuracy)) END) +
                (CASE WHEN MAX(ta.avg_bearing) - MIN(ta.avg_bearing) = 0 THEN 0 ELSE (ta.avg_bearing - MIN(ta.avg_bearing)) / (MAX(ta.avg_bearing) - MIN(ta.avg_bearing)) END) +
                (CASE WHEN MAX(ta.avg_acc_x) - MIN(ta.avg_acc_x) = 0 THEN 0 ELSE (ta.avg_acc_x - MIN(ta.avg_acc_x)) / (MAX(ta.avg_acc_x) - MIN(ta.avg_acc_x)) END) +
                (CASE WHEN MAX(ta.avg_acc_y) - MIN(ta.avg_acc_y) = 0 THEN 0 ELSE (ta.avg_acc_y - MIN(ta.avg_acc_y)) / (MAX(ta.avg_acc_y) - MIN(ta.avg_acc_y)) END) +
                (CASE WHEN MAX(ta.avg_acc_z) - MIN(ta.avg_acc_z) = 0 THEN 0 ELSE (ta.avg_acc_z - MIN(ta.avg_acc_z)) / (MAX(ta.avg_acc_z) - MIN(ta.avg_acc_z)) END) +
                (CASE WHEN MAX(ta.avg_gyro_x) - MIN(ta.avg_gyro_x) = 0 THEN 0 ELSE (ta.avg_gyro_x - MIN(ta.avg_gyro_x)) / (MAX(ta.avg_gyro_x) - MIN(ta.avg_gyro_x)) END) +
                (CASE WHEN MAX(ta.avg_gyro_y) - MIN(ta.avg_gyro_y) = 0 THEN 0 ELSE (ta.avg_gyro_y - MIN(ta.avg_gyro_y)) / (MAX(ta.avg_gyro_y) - MIN(ta.avg_gyro_y)) END) +
                (CASE WHEN MAX(ta.avg_gyro_Z) - MIN(ta.avg_gyro_Z) = 0 THEN 0 ELSE (ta.avg_gyro_Z - MIN(ta.avg_gyro_Z)) / (MAX(ta.avg_gyro_Z) - MIN(ta.avg_gyro_Z)) END) +
                (CASE WHEN MAX(ta.avg_sec) - MIN(ta.avg_sec) = 0 THEN 0 ELSE (ta.avg_sec - MIN(ta.avg_sec)) / (MAX(ta.avg_sec) - MIN(ta.avg_sec)) END) +
                (CASE WHEN MAX(ta.avg_speed) - MIN(ta.avg_speed) = 0 THEN 0 ELSE (ta.avg_speed - MIN(ta.avg_speed)) / (MAX(ta.avg_speed) - MIN(ta.avg_speed)) END)
            ) DESC
        ) AS danger_level
    FROM
        TripAverages ta
    JOIN
        safety_status ss ON ta.bookingID = ss.bookingID
    group by ta.bookingID, ta.avg_accuracy, ta.avg_bearing, ta.avg_acc_x, ta.avg_acc_y, ta.avg_acc_z, ta.avg_gyro_x, ta.avg_gyro_y, ta.avg_gyro_Z, ta.avg_sec, ta.avg_speed
), avg_danger_metric_per_driver as (
    select 
        ss.driver_id,
        cast(sum(d.danger_level) as float) / count(ss.bookingID) as avg_danger_level
    from danger_metric d, safety_status ss
    where d.bookingID = ss.bookingID
    group by ss.driver_id
), rating_cat AS (
    SELECT
        d.driver_id,
        CASE 
            WHEN d.driver_rating = 5 THEN 'Perfect rating'
            WHEN d.driver_rating >= 4.5 THEN 'Very high rating'
            WHEN d.driver_rating >= 4 THEN 'High rating'
            WHEN d.driver_rating >= 3.5 THEN 'Medium high rating'
            WHEN d.driver_rating >= 3 THEN 'Medium low rating'
            WHEN d.driver_rating >= 2.5 THEN 'Low rating' 
            WHEN d.driver_rating > 2 THEN 'Very low rating'
            ELSE 'Worse rating'
        END AS rating
    FROM drivers d
), dangerous_rate AS (
	SELECT
		d.driver_id,
		d.no_of_years_driving_exp,
		CAST(SUM(ss.label) AS FLOAT) / COUNT(ss.bookingID) * 100 as percent_danger
	FROM drivers d, safety_status ss
	WHERE d.driver_id = ss.driver_id
	GROUP BY d.driver_id, d.no_of_years_driving_exp
), drivers_age as (
	select 
		d.driver_id,
		DATEDIFF(YEAR, d.date_of_birth, GETDATE()) as driver_age, 
		d.date_of_birth 
	from drivers d 
), years_exp_cat as (
    select
        d.driver_id,
        case 
            when d.no_of_years_driving_exp < 10 then 'Beginner'
            when d.no_of_years_driving_exp < 15 then 'Intermediate'
            when d.no_of_years_driving_exp < 20 then 'Experienced'
            else 'Veteran'
        end as year_exp_cat
    from drivers d
)
select 
    d.driver_id,
    d.driver_name as 'Driver name',
	r.rating as 'Rating category',
    yc.year_exp_cat as 'Driver experience',
	round(AVG(percent_danger), 2) as 'Average percent danger trip',
    COALESCE(round(dm.avg_danger_level, 2), 0) as 'Average danger level',
	da.driver_age as 'Driver age'
from drivers d 
join rating_cat r on d.driver_id = r.driver_id
join dangerous_rate dr on d.driver_id = dr.driver_id
join drivers_age da on d.driver_id = da.driver_id
join years_exp_cat yc on d.driver_id = yc.driver_id
left join avg_danger_metric_per_driver dm on d.driver_id = dm.driver_id
group by d.driver_id, r.rating, d.no_of_years_driving_exp, da.driver_age, d.driver_name, yc.year_exp_cat, dm.avg_danger_level
order by dm.avg_danger_level desc;


-- query 2
WITH cars_age AS (
    SELECT 
        d.driver_id,
        YEAR(GETDATE()) - d.car_model_year AS car_age 
    FROM drivers d
),
dangerous_rate AS (
    SELECT
        d.driver_id,
        CAST(SUM(ss.label) AS FLOAT) / COUNT(ss.bookingID) * 100 AS percent_danger
    FROM drivers d
    JOIN safety_status ss ON d.driver_id = ss.driver_id
    GROUP BY d.driver_id
),
accuracy_cat AS (
    SELECT
        ss.driver_id,
        SUM(s.sec) AS total_time,
        CASE
            WHEN AVG(s.accuracy) < 7 THEN 'highly accurate'
            WHEN AVG(s.accuracy) < 17 THEN 'moderately accurate'
            ELSE 'inaccurate'
        END AS accuracy_category
    FROM safety_status ss
    JOIN sensor s ON ss.bookingID = s.bookingID
    GROUP BY ss.driver_id
),
count_accuracy AS (
    SELECT 
        d.car_brand,
        SUM(CASE WHEN accuracy_category = 'highly accurate' THEN 1 END) AS highly_accurate, 
        SUM(CASE WHEN accuracy_category = 'moderately accurate' THEN 1 END) AS moderately_accurate,
        SUM(CASE WHEN accuracy_category = 'inaccurate' THEN 1 END) AS inaccurate
    FROM accuracy_cat a
    JOIN drivers d ON a.driver_id = d.driver_id
    GROUP BY d.car_brand
),
car_age_cat AS (
    SELECT
        d.driver_id,
        CASE 
            WHEN c.car_age < 15 THEN 'modern car'
            WHEN c.car_age < 30 THEN 'classic car'
            ELSE 'vintage car'
        END AS car_age_category
    FROM cars_age c
    JOIN drivers d ON c.driver_id = d.driver_id
),
count_car_age_cat AS (
    SELECT 
        d.car_brand,
        SUM(CASE WHEN car_age_category = 'modern car' THEN 1 END) AS modern, 
        SUM(CASE WHEN car_age_category = 'classic car' THEN 1 END) AS classic,
        SUM(CASE WHEN car_age_category = 'vintage car' THEN 1 END) AS vintage
    FROM car_age_cat c
    JOIN drivers d ON c.driver_id = d.driver_id
    GROUP BY d.car_brand
)
SELECT 
    d.car_brand,
    AVG(c.car_age) AS 'Average Car Age',
    FORMAT(ROUND(AVG(SQRT(SQUARE(acc_x) + SQUARE(ABS(acc_y) - 9.81) + SQUARE(acc_z))), 2), '0.00') AS 'Average Net Acceleration', 
    FORMAT(ROUND(AVG(speed), 2), '0.00') AS 'Average Speed',
    COALESCE(ca.highly_accurate, 0) AS 'Num of Highly Accurate Driving Instances',
    COALESCE(ca.moderately_accurate, 0) AS 'Num of Moderately Accurate Driving Instances',
    COALESCE(ca.inaccurate, 0) AS 'Num of Inaccurate Driving Instances',
    FORMAT(ROUND(AVG(dr.percent_danger), 2), '0.00') AS 'Average Percentage of Dangerous Driving',
    COALESCE(cac.modern, 0) AS 'Num of Modern Cars',
    COALESCE(cac.classic, 0) AS 'Num of Classic Cars', 
    COALESCE(cac.vintage, 0) AS 'Num of Vintage Cars'
FROM drivers d
JOIN safety_status ss ON d.driver_id = ss.driver_id
JOIN sensor s ON ss.bookingID = s.bookingID
JOIN cars_age c ON c.driver_id = d.driver_id
JOIN dangerous_rate dr ON d.driver_id = dr.driver_id
JOIN count_accuracy ca ON d.car_brand = ca.car_brand
JOIN count_car_age_cat cac ON d.car_brand = cac.car_brand
GROUP BY 
    d.car_brand,
    ca.highly_accurate, ca.moderately_accurate, ca.inaccurate,
    cac.modern, cac.classic, cac.vintage;


-- query 3
declare @avg_gyro_x as float, @avg_gyro_y as float, @avg_gyro_z as float
select 
    @avg_gyro_x = avg(s.gyro_x),
    @avg_gyro_y = avg(s.gyro_y),
    @avg_gyro_z = avg(s.gyro_Z)
from sensor s
group by s.bookingID;
WITH gyro_anomalies AS (
    SELECT
        s.bookingID,
        SQRT(SQUARE(s.gyro_x - @avg_gyro_x) + SQUARE(s.gyro_y - @avg_gyro_y) + SQUARE(s.gyro_z - @avg_gyro_z)) AS gyroscope_deviation
    FROM sensor s
), avg_gyro_dev_per_trip as (
    select
        g.bookingID,
        avg(g.gyroscope_deviation) as avg_gyro_dev
    from gyro_anomalies g
    group by g.bookingID
), trip_count as (
    select 
        d.driver_id,
        count(ss.bookingID) as num_of_trips
    from drivers d, safety_status ss 
    where d.driver_id = ss.driver_id
    group by d.driver_id
), avg_gyro_dev_per_driver as (
    select 
        ss.driver_id,
        avg(a.avg_gyro_dev) as avg_gyro_dev_driver
    from avg_gyro_dev_per_trip a, safety_status ss
    where ss.bookingID = a.bookingID
    group by ss.driver_id
), rating_cat AS (
    SELECT
        d.driver_id,
        CASE 
            WHEN d.driver_rating = 5 THEN 'Perfect rating'
            WHEN d.driver_rating >= 4.5 THEN 'Very high rating'
            WHEN d.driver_rating >= 4 THEN 'High rating'
            WHEN d.driver_rating >= 3.5 THEN 'Medium high rating'
            WHEN d.driver_rating >= 3 THEN 'Medium low rating'
            WHEN d.driver_rating >= 2.5 THEN 'Low rating' 
            WHEN d.driver_rating > 2 THEN 'Very low rating'
            ELSE 'Worse rating'
        END AS rating
    FROM drivers d
), dangerous_rate AS (
	SELECT
		d.driver_id,
		d.no_of_years_driving_exp,
		CAST(SUM(ss.label) AS FLOAT) / COUNT(ss.bookingID) * 100 as percent_danger
	FROM drivers d, safety_status ss
	WHERE d.driver_id = ss.driver_id
	GROUP BY d.driver_id, d.no_of_years_driving_exp
)
SELECT
    d.driver_id,
    d.driver_name as 'Driver name',
    round(avg(gd.avg_gyro_dev_driver), 2) as 'Average gyro deviation',
    round(max(gt.avg_gyro_dev), 2) as 'Max gyro deviation',
    count(ss.bookingID) as 'Number of trips with anomalous gyro',
    round(cast((count(d.driver_id) over (partition by d.driver_id)) as float) / t.num_of_trips * 100, 2) as 'Percent of trips with anomalous gyro (%)',
    round(dr.percent_danger,2) as 'Percentage of dangerous trips',
    r.rating
FROM avg_gyro_dev_per_trip gt, safety_status ss, drivers d, trip_count t, avg_gyro_dev_per_driver gd, rating_cat r, dangerous_rate dr
WHERE 
    gt.bookingID = ss.bookingID and d.driver_id = ss.driver_id and t.driver_id = d.driver_id and gd.driver_id = d.driver_id and r.driver_id = d.driver_id and dr.driver_id = d.driver_id
    and gt.avg_gyro_dev > (SELECT avg(gyroscope_deviation) FROM gyro_anomalies) + 2 * (select stdev(gyroscope_deviation) from gyro_anomalies)   
group by d.driver_id, t.num_of_trips, d.driver_name, r.rating, dr.percent_danger
order by max(gt.avg_gyro_dev) desc;
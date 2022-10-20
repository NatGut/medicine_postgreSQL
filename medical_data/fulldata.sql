-- 1. Создаём нормализованную БД для глюкозы
-- 1.1 Создание сводной таблицы с данными по дате, времени и глюкозе с заменой типа полей на нужный,
-- а также берём колонку со временем и датой заливки данных для упрощения дальнейшего обновления этого отношения
select "Date"::date,
       "Time"::time,
       replace("Sensor Glucose (mmol/L)",',','.')::numeric(3,1) as "Sensor Glucose (mmol/L)",
       "LoadDateTime"
into selections.gl_sensor_glucose
from raw.raw_data
where "Sensor Glucose (mmol/L)" is not null
;
-- Накидываем простой индекс на поле Date в таблицу с глюкозой сенсора, т.к. соединять отношения и агрегировать данные будем чаще всего по дате.
create index date_sensor_glucose on selections.gl_sensor_glucose ("Date")
;

-- 1.2 Тестовая работа с глюкозой, проверка целесообразности индексов
-- Подсчёт всех строк
select count(*)
from selections.gl_sensor_glucose;

-- Макс/мин даты в таблице
-- explain (если включить explain, как видим, индексы работают, postgres использует их для построения планов запросов по датам)
select max("Date") as max_date, min("Date") as min_date
       from selections.gl_sensor_glucose;

-- Подсчёт записей на каждую дату
select "Date", count("Sensor Glucose (mmol/L)")
from selections.gl_sensor_glucose
group by "Date"
order by "Date";

-- Среднее значение глюкозы за всё время в таблице
select round(avg("Sensor Glucose (mmol/L)"),2)
from selections.gl_sensor_glucose;

-- Среднее значение глюкозы за предыдущий день
select round(avg("Sensor Glucose (mmol/L)"),2)
from selections.gl_sensor_glucose
where "Date" in (
select (max("Date")-1)
from selections.gl_sensor_glucose)
;

-- Средняя глюкоза за последние 30 дней
-- explain (если включить explain, как видим, индексы работают, postgres использует их для построения планов запросов по диапазону дат)
select round(avg("Sensor Glucose (mmol/L)"),2)
from selections.gl_sensor_glucose
where "Date" BETWEEN (
select (max("Date")-interval '30 days')
from selections.gl_sensor_glucose) and (select max("Date") from selections.gl_sensor_glucose)
;

-- 1.3 Создание сводной таблицы по калибровке сенсора
--Делаем сводную таблицу на калибровку сенсора через три CTE
--CTE на чтение глюкометра
WITH w_BG_read as (
select "Date"::date,
       "Time"::time,
       replace("BG Reading (mmol/L)", ',','.')::numeric(3,1) as "BG Reading (mmol/L)",
       "LoadDateTime"
from raw.raw_data
where "BG Reading (mmol/L)" is not null),
-- CTE на калибровку
w_calibration as (
select "Date"::date,
       "Time"::time,
       replace("Sensor Calibration BG (mmol/L)", ',','.')::numeric(3,1) as "Sensor Calibration BG (mmol/L)"
       from raw.raw_data
where "Sensor Calibration BG (mmol/L)" is not null),
-- CTE на отмену калибровки
w_failed_calibration as (
select "Date"::date,
       "Time"::time,
       "Sensor Calibration Rejected Reason"
       from raw.raw_data
where "Sensor Calibration Rejected Reason" is not null)
    select A."Date" as Date_reading,
       A."Time" as Time_reading,
       "BG Reading (mmol/L)",
       B."Date" as Date_calibration,
       B."Time" as Time_calibration,
       "Sensor Calibration BG (mmol/L)",
       C."Date" as Date_failed,
       C."Time"as Time_failed,
       "Sensor Calibration Rejected Reason",
        A."LoadDateTime"
into selections.gl_calibration
from w_BG_read A
    left join w_calibration B on
        A."Date"=B."Date" and
        (B."Time" >= A."Time" and B."Time" <= (A."Time"+interval'16minutes'))
left join w_failed_calibration C
    on A."Date"=C."Date" and
       (C."Time" >= A."Time" and C."Time" <= (A."Time"+interval'16minutes'))
;
--И делаем такую же вьюшку на калибровку сенсора для дальнейшего обновления данных
create view temp_views.gl_calibration as select* from (
WITH w_BG_read as (
select "Date"::date,
       "Time"::time,
       replace("BG Reading (mmol/L)", ',','.')::numeric(3,1) as "BG Reading (mmol/L)",
       "LoadDateTime"
from raw.raw_data
where "BG Reading (mmol/L)" is not null),
w_calibration as (
select "Date"::date,
       "Time"::time,
       replace("Sensor Calibration BG (mmol/L)", ',','.')::numeric(3,1) as "Sensor Calibration BG (mmol/L)"
       from raw.raw_data
where "Sensor Calibration BG (mmol/L)" is not null),
w_failed_calibration as (
select "Date"::date,
       "Time"::time,
       "Sensor Calibration Rejected Reason"
       from raw.raw_data
where "Sensor Calibration Rejected Reason" is not null)
    select A."Date" as Date_reading,
       A."Time" as Time_reading,
       "BG Reading (mmol/L)",
       B."Date" as Date_calibration,
       B."Time" as Time_calibration,
       "Sensor Calibration BG (mmol/L)",
       C."Date" as Date_failed,
       C."Time"as Time_failed,
       "Sensor Calibration Rejected Reason",
        A."LoadDateTime"
from w_BG_read A
    left join w_calibration B on
        A."Date"=B."Date" and
        (B."Time" >= A."Time" and B."Time" <= (A."Time"+interval'16minutes'))
left join w_failed_calibration C
    on A."Date"=C."Date" and
       (C."Time" >= A."Time" and C."Time" <= (A."Time"+interval'16minutes'))) as AAA
;

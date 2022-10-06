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

-- 1.2 Работа с глюкозой, проверка целесообразности индексов
-- Подсчёт всех строк
select count(*)
from selections.gl_sensor_glucose;

-- Макс/мин даты в таблице
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
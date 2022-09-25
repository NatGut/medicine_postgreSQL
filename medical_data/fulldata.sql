--Создание сводной таблицы с данными по дате, времени и глюкозе с заменой типа полей на нужный
select "Date"::date as Date,
       "Time"::time as Time,
       replace("Sensor Glucose (mmol/L)",',','.')::numeric(3,1) as "Sensor Glucose (mmol/L)"
into selections.Glucose
from raw.raw_data
where "Sensor Glucose (mmol/L)" is not null;

--Подсчёт всех строк
select count(*)
from selections.Glucose;

--Макс/мин даты в таблице
select max(date) as max_date, min(date) as min_date
       from selections.Glucose;

--Подсчёт записей на каждую дату
select date, count(glucose)
from selections.Glucose
group by date
order by date;

--Среднее значение глюкозы за всё время в таблице
select round(avg("Sensor Glucose (mmol/L)"),2)
from selections.Glucose;

--Среднее значение глюкозы за предыдущий день
select round(avg("Sensor Glucose (mmol/L)"),2)
from selections.Glucose
where date in (
select (max(date)-1)::date
from selections.Glucose)
;

--Средняя глюкоза за последние 30 дней
select round(avg("Sensor Glucose (mmol/L)"),2)
from selections.Glucose
where date BETWEEN (
select (max(date)-interval '30 days')::date
from selections.Glucose) and (select max(date) from selections.Glucose)
;
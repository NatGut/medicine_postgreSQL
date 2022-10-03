REM Перед запуском подготовить .csv файл: удалить первые 8 строк, удалить 2 последние пустые строки, найти и удалить разрыв в файле.
REM Описание .bat-файла:
REM 1. запонляет первую созданную таблицу данными из .csv.
REM 2. копирует данные из 1й таблицы во вторую (при этом добавляется колонка со временем загрузки).
REM 3. очищается исходная первая таблица
REM Для загрзуки дальнейших файлов с исходными данными просто поменять название файла на новое.
REM Почему нельзя в .bat-файле просто написать побольше строк, чтобы слить сразу все исходники? Тогда время загрзуки во 2й таблице будет одинаковое. А это неудобно для работы с данными. 
@echo off
setlocal
SET PGCLIENTENCODING=utf-8
set PGPASSWORD=55566677
"c:\Program Files\PostgreSQL\13\bin\psql.exe" -h localhost  -U postgres -d gleb -c "copy raw.JackDoeRaw from STDIN with delimiter as ','  CSV  QUOTE '""';" < "d:\RawData\JackDoe 30.09.2022.csv"
"c:\Program Files\PostgreSQL\13\bin\psql.exe" -h localhost  -U postgres -d gleb -c "insert into raw.raw_data select * from raw.JackDoeRaw;
"c:\Program Files\PostgreSQL\13\bin\psql.exe" -h localhost  -U postgres -d gleb -c "truncate table raw.JackDoeRaw;
pause
endlocal

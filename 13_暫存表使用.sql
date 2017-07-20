--暫存表
--實際儲存暫存表(使用tempdb及具實體IO)
--全域
CREATE TABLE ##tablename
    (
        uid                INT,
        username    VARCHAR(10),
        RegDate       DATETIME
    )

insert into ##tablename
values
	(1,'jc',getdate())

select * from ##tablename

--區域
CREATE TABLE #tablename
    (
        uid                INT,
        username    VARCHAR(10),
        RegDate       DATETIME
    )

insert into #tablename
values
	(2,'jc',getdate())

select * from #tablename

select * from ##tablename
select * from #tablename



--資料型別暫存表(使用記憶體)
--全域
DECLARE @@tablename TABLE
    (
        uid                INT,
        username    VARCHAR(10),
        RegDate       DATETIME
    )

insert into @@tablename
values
	(1,'jc',getdate())

select * from @@tablename

--區域(By Session)
DECLARE @tablename TABLE
    (
        uid                INT,
        username    VARCHAR(10),
        RegDate       DATETIME
    )

insert into @tablename
values
	(2,'jc',getdate())

select * from @tablename


select * from @@tablename
select * from @tablename

--使用暫存表的時機
--1. 確定暫存後的資料量小
--2. 排程工作且須運算大量資料(需與DBA協調執行時間)
--3. 非不得已別指定PK OR INDEX (因資料量已縮小 全表掃描時間比較快過一張暫存表+INDEX+SELECT)
--4. 有需使用大量資料的暫存表時需與DBA協調
--5. #號開頭的暫存使用Tempdb的實體IO  @號開頭的使用記憶體  SQL Server記憶體有限 @謹慎使用
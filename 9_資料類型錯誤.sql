-- 欄位型態轉型
-- Conversion failed when converting the varchar value 'A' to data type int.
-- Gray提供

--建立測試用暫存表
CREATE TABLE #T (name VARCHAR(15))

--寫入測試資料
INSERT INTO #T VALUES
('A123456789'),
('P245566123'),
('N187654321'),
('AW1016879781'),
('E248120123')

--1. 因之前未做任何過濾被寫入不正確的格式 撈取資料比對時出現異常
SELECT	CASE SUBSTRING(name,2,1)	WHEN 1 THEN '男性'  --這裡的1為數字
									WHEN 2 THEN '女性'	--這裡的2為數字
			ELSE '大德' END
FROM #T
--因第4筆資料AW1016879781的第二個字元為W 與CASE中的數字 1 2資料類型不符
--會得到錯誤Conversion failed when converting the varchar value 'W' to data type int.


--2. 將不在正確格式的資料列指定成例外狀況
SELECT	CASE SUBSTRING(name,2,1)	WHEN '1' THEN '男性'	--這裡的1為字串
									WHEN '2' THEN '女性'	--這裡的2為字串
			ELSE '大德' END
FROM #T


--3. 隱含轉換比對
SELECT	CASE SUBSTRING(name,2,1)	WHEN 1 THEN '男性'  --這裡的1為數字
									WHEN 2 THEN '女性'	--這裡的2為數字
			ELSE '大德' END
FROM #T
WHERE
	name <> 'AW1016879781'
--先排除第4筆資料並測試隱含轉換後比對
--因略過第4筆資料故每筆資料的第二個字均為字元及條件使用隱含轉換比對
--會得到正確資料
--上述CASE中 除了我們手動指定SUBSTRING取字串及排除第4筆資料之外 猜猜看DB又做了什麼?
















































































































--1.的方法 若有過濾掉可能錯誤的第4筆資料則執行方式與下方3相同
--若不過濾第二字元與CASE 置換條件相同資料類型則會引發錯誤TSQL即中斷執行

--2.的方法 執行計畫中被執行的樣子
CASE WHEN substring([tempdb].[dbo].[#T].[name],(2),(1))='1' THEN '男性' ELSE CASE WHEN substring([tempdb].[dbo].[#T].[name],(2),(1))='2' THEN '女性' ELSE '大德' END END
--指定的SUBSTRING(name,2,1)變成了substring([tempdb].[dbo].[#T].[name],(2),(1))並直接進行比對及置換顯示字串

--3.的方法 執行計畫中被執行的樣子
--除了我們指定的SUBSTRING(name,2,1)變成了substring([tempdb].[dbo].[#T].[name],(2),(1))
--DB Engine又幫我們轉換了一次CONVERT_IMPLICIT(int, ,0)
CASE WHEN CONVERT_IMPLICIT(int,substring([tempdb].[dbo].[#T].[name],(2),(1)),0)=(1) THEN '男性' ELSE CASE WHEN CONVERT_IMPLICIT(int,substring([tempdb].[dbo].[#T].[name],(2),(1)),0)=(2) THEN '女性' ELSE '大德' END END


--假設#T資料表有1千萬筆資料，每次的查詢均須要先對取第二字元後再對該欄位進行轉換，最後才比對是否在置換條件上
--等於1千萬筆資料拆字串取第二字元 + 1千萬筆資料第二字元轉換為數字 + 1千萬筆資料置換字串

TRUNCATE TABLE #T
DROP TABLE #T
--範例:	因資料表經常性的變動導致欄位越來越多的情況
--		即使設定欄位為允許NULL卻又無法新增資料問題
--		原因為未指名要寫入的欄位

--建立資料表
CREATE TABLE #T
	(
		ID			INT IDENTITY(1,1),
		UserName	NVARCHAR(12),
		CreateDate	DATETIME,
		Descript	NVARCHAR(250) NULL
	)

--寫入資料
INSERT INTO #T
SELECT	'Jasonchen',GETDATE(),NULL

--確認內容
SELECT	ID,UserName,CreateDate,Descript FROM #T

--欄位新增異動
ALTER TABLE #T ADD ActiveDate DATETIME NULL DEFAULT GETDATE()

--確認欄位內容
SELECT	ID,UserName,CreateDate,Descript,ActiveDate FROM #T

--寫入資料
INSERT INTO #T
SELECT	'Mitaliao',GETDATE(),NULL
--**因新增了ActiveDate欄位故即使允許NULL及預設值，也不會允許新增

--改為指定欄位寫入資料
INSERT INTO #T
	(UserName,CreateDate,Descript)
SELECT	'Mitaliao',GETDATE(),NULL
--**因有指定要寫入的欄位且符合Table欄位限制故可正常新增

--確認欄位內容
SELECT	ID,UserName,CreateDate,Descript,ActiveDate FROM #T

--指定欄位寫入資料
INSERT INTO #T
	(UserName,CreateDate,Descript,ActiveDate)
SELECT	'Allen',GETDATE(),NULL,'2017-02-23 00:00:00'
--**因有指定要寫入的欄位且符合Table欄位限制故可正常新增

--確認欄位內容
SELECT	ID,UserName,CreateDate,Descript,ActiveDate FROM #T

--測試強制寫入包含ID的資料
INSERT INTO #T
	(ID,UserName,CreateDate,Descript,ActiveDate)
SELECT	5,'Josh',GETDATE(),NULL,'2017-02-23 00:00:00'
--**此範例中ID為流水號，由於IDENTITY的唯一性限制，資料庫會將其欄位設定IDENTITY_INSERT = OFF，此時則不可指定寫入ID欄位

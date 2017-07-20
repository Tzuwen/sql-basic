-- SQL語法非必要不使用CURSOR及UPDATE FROM的語法
-- Transaction 時間越短越好  盡可能先排除需要判斷的部分再包交易
-- 避免大表JOIN及CROSS Join ，可以過濾 可以暫存 可以先處裡的就先處理
-- 即使無法避免欄位值為NULL，也要避免INDEX的欄位不要有NULL
-- Primary Key請以不會變動的欄位做設計
-- SP撰寫

--以符合SARG Statement進行撰寫
-- 符合的如下
-- <、>、=、<=、>=、LIKE(視%所在位置，前面有%讓DB engine選擇不走INDEX) 和BETWEEN
-- 不符合的如下
-- <>、!<、!>、NOT、NOT IN、NOT EXISTS和NOT LIKE、不對欄位作運算、不對欄位使用函數等

-- DB Engine不會很聰明地幫各位選到最好的執行方法
-- SQL的撰寫以越簡單越好 別複雜化


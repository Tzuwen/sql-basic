--�d��:	�]��ƪ�g�`�ʪ��ܰʾɭP���V�ӶV�h�����p
--		�Y�ϳ]�w��쬰���\NULL�o�S�L�k�s�W��ư��D
--		��]�������W�n�g�J�����

--�إ߸�ƪ�
CREATE TABLE #T
	(
		ID			INT IDENTITY(1,1),
		UserName	NVARCHAR(12),
		CreateDate	DATETIME,
		Descript	NVARCHAR(250) NULL
	)

--�g�J���
INSERT INTO #T
SELECT	'Jasonchen',GETDATE(),NULL

--�T�{���e
SELECT	ID,UserName,CreateDate,Descript FROM #T

--���s�W����
ALTER TABLE #T ADD ActiveDate DATETIME NULL DEFAULT GETDATE()

--�T�{��줺�e
SELECT	ID,UserName,CreateDate,Descript,ActiveDate FROM #T

--�g�J���
INSERT INTO #T
SELECT	'Mitaliao',GETDATE(),NULL
--**�]�s�W�FActiveDate���G�Y�Ϥ��\NULL�ιw�]�ȡA�]���|���\�s�W

--�אּ���w���g�J���
INSERT INTO #T
	(UserName,CreateDate,Descript)
SELECT	'Mitaliao',GETDATE(),NULL
--**�]�����w�n�g�J�����B�ŦXTable��쭭��G�i���`�s�W

--�T�{��줺�e
SELECT	ID,UserName,CreateDate,Descript,ActiveDate FROM #T

--���w���g�J���
INSERT INTO #T
	(UserName,CreateDate,Descript,ActiveDate)
SELECT	'Allen',GETDATE(),NULL,'2017-02-23 00:00:00'
--**�]�����w�n�g�J�����B�ŦXTable��쭭��G�i���`�s�W

--�T�{��줺�e
SELECT	ID,UserName,CreateDate,Descript,ActiveDate FROM #T

--���ձj��g�J�]�tID�����
INSERT INTO #T
	(ID,UserName,CreateDate,Descript,ActiveDate)
SELECT	5,'Josh',GETDATE(),NULL,'2017-02-23 00:00:00'
--**���d�Ҥ�ID���y�����A�ѩ�IDENTITY���ߤ@�ʭ���A��Ʈw�|�N�����]�wIDENTITY_INSERT = OFF�A���ɫh���i���w�g�JID���

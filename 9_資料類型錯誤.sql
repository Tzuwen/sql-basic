-- ��쫬�A�૬
-- Conversion failed when converting the varchar value 'A' to data type int.
-- Gray����

--�إߴ��եμȦs��
CREATE TABLE #T (name VARCHAR(15))

--�g�J���ո��
INSERT INTO #T VALUES
('A123456789'),
('P245566123'),
('N187654321'),
('AW1016879781'),
('E248120123')

--1. �]���e��������L�o�Q�g�J�����T���榡 ������Ƥ��ɥX�{���`
SELECT	CASE SUBSTRING(name,2,1)	WHEN 1 THEN '�k��'  --�o�̪�1���Ʀr
									WHEN 2 THEN '�k��'	--�o�̪�2���Ʀr
			ELSE '�j�w' END
FROM #T
--�]��4�����AW1016879781���ĤG�Ӧr����W �PCASE�����Ʀr 1 2�����������
--�|�o����~Conversion failed when converting the varchar value 'W' to data type int.


--2. �N���b���T�榡����ƦC���w���ҥ~���p
SELECT	CASE SUBSTRING(name,2,1)	WHEN '1' THEN '�k��'	--�o�̪�1���r��
									WHEN '2' THEN '�k��'	--�o�̪�2���r��
			ELSE '�j�w' END
FROM #T


--3. ���t�ഫ���
SELECT	CASE SUBSTRING(name,2,1)	WHEN 1 THEN '�k��'  --�o�̪�1���Ʀr
									WHEN 2 THEN '�k��'	--�o�̪�2���Ʀr
			ELSE '�j�w' END
FROM #T
WHERE
	name <> 'AW1016879781'
--���ư���4����ƨô������t�ഫ����
--�]���L��4����ƬG�C����ƪ��ĤG�Ӧr�����r���α���ϥ����t�ഫ���
--�|�o�쥿�T���
--�W�zCASE�� ���F�ڭ̤�ʫ��wSUBSTRING���r��αư���4����Ƥ��~ �q�q��DB�S���F����?
















































































































--1.����k �Y���L�o���i����~����4����ƫh����覡�P�U��3�ۦP
--�Y���L�o�ĤG�r���PCASE �m������ۦP��������h�|�޵o���~TSQL�Y���_����

--2.����k ����p�e���Q���檺�ˤl
CASE WHEN substring([tempdb].[dbo].[#T].[name],(2),(1))='1' THEN '�k��' ELSE CASE WHEN substring([tempdb].[dbo].[#T].[name],(2),(1))='2' THEN '�k��' ELSE '�j�w' END END
--���w��SUBSTRING(name,2,1)�ܦ��Fsubstring([tempdb].[dbo].[#T].[name],(2),(1))�ê����i����θm����ܦr��

--3.����k ����p�e���Q���檺�ˤl
--���F�ڭ̫��w��SUBSTRING(name,2,1)�ܦ��Fsubstring([tempdb].[dbo].[#T].[name],(2),(1))
--DB Engine�S���ڭ��ഫ�F�@��CONVERT_IMPLICIT(int, ,0)
CASE WHEN CONVERT_IMPLICIT(int,substring([tempdb].[dbo].[#T].[name],(2),(1)),0)=(1) THEN '�k��' ELSE CASE WHEN CONVERT_IMPLICIT(int,substring([tempdb].[dbo].[#T].[name],(2),(1)),0)=(2) THEN '�k��' ELSE '�j�w' END END


--���]#T��ƪ�1�d�U����ơA�C�����d�ߧ����n������ĤG�r����A������i���ഫ�A�̫�~���O�_�b�m������W
--����1�d�U����Ʃ�r����ĤG�r�� + 1�d�U����ƲĤG�r���ഫ���Ʀr + 1�d�U����Ƹm���r��

TRUNCATE TABLE #T
DROP TABLE #T
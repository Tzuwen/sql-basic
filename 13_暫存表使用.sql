--�Ȧs��
--����x�s�Ȧs��(�ϥ�tempdb�Ψ����IO)
--����
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

--�ϰ�
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



--��ƫ��O�Ȧs��(�ϥΰO����)
--����
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

--�ϰ�(By Session)
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

--�ϥμȦs���ɾ�
--1. �T�w�Ȧs�᪺��ƶq�p
--2. �Ƶ{�u�@�B���B��j�q���(�ݻPDBA��հ���ɶ�)
--3. �D���o�w�O���wPK OR INDEX (�]��ƶq�w�Y�p �����y�ɶ�����ֹL�@�i�Ȧs��+INDEX+SELECT)
--4. ���ݨϥΤj�q��ƪ��Ȧs��ɻݻPDBA���
--5. #���}�Y���Ȧs�ϥ�Tempdb������IO  @���}�Y���ϥΰO����  SQL Server�O���馳�� @�ԷV�ϥ�
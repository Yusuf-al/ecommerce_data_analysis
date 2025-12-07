USE master
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'BrazilianEcommerceDW' )
BEGIN
    ALTER DATABASE BrazilianEcommerceDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE ;
    DROP DATABASE BrazilianEcommerceDW;
END;
GO

CREATE DATABASE BrazilianEcommerceDW
GO

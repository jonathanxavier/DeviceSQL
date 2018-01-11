USE master
GO
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'clr enabled', 1;
GO
RECONFIGURE;
GO
CREATE ASYMMETRIC KEY [DeviceSqlKey] FROM EXECUTABLE FILE = '##_ASYMMETRIC_KEY_EXECUTABLE_FILE#'
CREATE LOGIN [DeviceSqlClrLogin] FROM ASYMMETRIC KEY [DeviceSqlKey]
GRANT UNSAFE ASSEMBLY TO [DeviceSqlClrLogin]
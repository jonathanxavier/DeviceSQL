SET NOCOUNT ON;
DECLARE @channelName nvarchar(512) = 'tcp://127.0.0.1:502';
DECLARE @hostName nvarchar(512) = '127.0.0.1';
DECLARE @hostPort int = 502;
DECLARE @connectAttempts int = 3;
DECLARE @connectionRetryDelay int = 5000;
DECLARE @writeTimeout int = 5000;
DECLARE @readTimeout int = 5000;
DECLARE @numberOfRetries int = 5;
DECLARE @waitToRetry int = 2000;
DECLARE @deviceName nvarchar(255) = 'ModRSsim2';
DECLARE @requestWriteDelay int = 50;
DECLARE @responseReadDelay int = 50;
DECLARE @UseMbapHeaders bit = 1;
DECLARE @UseExtendedAddressing bit = 0;
DECLARE @UnitId int = 1;
DECLARE @Value int;
DECLARE @RegisterIndex tinyint = 0;
DECLARE @ByteSwap bit = 0;

DECLARE @HoldingRegister [ModbusMaster].[HoldingRegister] = [ModbusMaster].[HoldingRegister]::Parse('True;1,False,0'); -- AddressIsZeroBased;Address,ByteSwap,Value
DECLARE @HoldingRegisterArray [ModbusMaster].[HoldingRegisterArray] = [ModbusMaster].[HoldingRegisterArray]::Empty();

SET @HoldingRegisterArray = @HoldingRegisterArray.AddHoldingRegister(@HoldingRegister);

PRINT [ChannelManager].[RegisterTcpChannel] (@channelName, @hostName, @hostPort, @connectAttempts, @connectionRetryDelay, @readTimeout, @writeTimeout);
PRINT [DeviceManager].[RegisterModbusMaster] (@ChannelName, @DeviceName, @UseMbapHeaders, @UseExtendedAddressing, @UnitId, @NumberOfRetries, @WaitToRetry, @RequestWriteDelay, @ResponseReadDelay);

SET @HoldingRegisterArray = [ModbusMaster].[ReadHoldings](@deviceName, @HoldingRegisterArray);
SET @Value = @HoldingRegisterArray.GetShort(@RegisterIndex, @ByteSwap);

PRINT @Value;

PRINT [DeviceManager].[UnregisterDevice] (@deviceName);
PRINT [ChannelManager].[UnregisterChannel] (@channelName);
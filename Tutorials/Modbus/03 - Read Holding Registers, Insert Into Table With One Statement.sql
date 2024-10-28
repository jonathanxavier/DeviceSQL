SET NOCOUNT ON;

-- Declare variables for connection settings and Modbus device communication
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
DECLARE @ByteSwap bit = 0;

-- Define start address and number of registers to read
DECLARE @StartAddress int = 1;  -- Starting address of the registers
DECLARE @NumRegisters int = 10; -- Number of registers to read

-- Declare HoldingRegisterArray for multiple registers
DECLARE @HoldingRegisterArray [ModbusMaster].[HoldingRegisterArray] = [ModbusMaster].[HoldingRegisterArray]::Empty();

-- Loop to add registers to the HoldingRegisterArray dynamically
DECLARE @i int = 0;
WHILE @i < @NumRegisters
BEGIN
    DECLARE @HoldingRegister [ModbusMaster].[HoldingRegister] = [ModbusMaster].[HoldingRegister]::Parse('True;' + CAST(@StartAddress + @i AS NVARCHAR(10)) + ',False,0');
    SET @HoldingRegisterArray = @HoldingRegisterArray.AddHoldingRegister(@HoldingRegister);
    SET @i = @i + 1;
END

-- Register the TCP channel
PRINT [ChannelManager].[RegisterTcpChannel] (@channelName, @hostName, @hostPort, @connectAttempts, @connectionRetryDelay, @readTimeout, @writeTimeout);

-- Register the Modbus master device
PRINT [DeviceManager].[RegisterModbusMaster] (@ChannelName, @DeviceName, @UseMbapHeaders, @UseExtendedAddressing, @UnitId, @NumberOfRetries, @WaitToRetry, @RequestWriteDelay, @ResponseReadDelay);

-- Read a block of Holding Registers
SET @HoldingRegisterArray = [ModbusMaster].[ReadHoldings](@deviceName, @HoldingRegisterArray);

-- Declare dynamic SQL string
DECLARE @SQL NVARCHAR(MAX) = 'INSERT INTO ModbusValues.dbo.ModbusRegisterValues (RegisterAddress, RegisterValue) VALUES ';

-- Loop through the HoldingRegisterArray to build the dynamic INSERT statement
SET @i = 0;
WHILE @i < @NumRegisters
BEGIN
    DECLARE @Value int;
    SET @Value = @HoldingRegisterArray.GetShort(@i, @ByteSwap);
    
    -- Add each register and value to the dynamic SQL string
    SET @SQL = @SQL + '(' + CAST(@StartAddress + @i AS NVARCHAR(10)) + ', ' + CAST(@Value AS NVARCHAR(10)) + '),';
    
    SET @i = @i + 1;
END

-- Remove the last comma from the SQL string
SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);

-- Print the generated SQL (optional, for debugging purposes)
PRINT @SQL;

-- Execute the dynamic SQL to insert values
EXEC sp_executesql @SQL;

-- Unregister the Modbus device and TCP channel
PRINT [DeviceManager].[UnregisterDevice] (@deviceName);
PRINT [ChannelManager].[UnregisterChannel] (@channelName);

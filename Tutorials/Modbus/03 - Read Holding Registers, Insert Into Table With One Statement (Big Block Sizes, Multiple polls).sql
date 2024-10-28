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

-- Define start address and total number of registers to read
DECLARE @StartAddress int = 1;  -- Starting address of the registers
DECLARE @TotalRegisters int = 500; -- Total number of registers to read
DECLARE @MaxRegistersPerPoll int = 125; -- Maximum registers per Modbus poll

-- Declare dynamic SQL string for insert operations
DECLARE @SQL NVARCHAR(MAX);

-- Declare HoldingRegisterArray for multiple registers
DECLARE @HoldingRegisterArray [ModbusMaster].[HoldingRegisterArray];

-- Initialize variables for loop
DECLARE @CurrentStartAddress int = @StartAddress;
DECLARE @RegistersLeft int = @TotalRegisters;
DECLARE @RegistersToPoll int;

-- Register the TCP channel
PRINT [ChannelManager].[RegisterTcpChannel] (@channelName, @hostName, @hostPort, @connectAttempts, @connectionRetryDelay, @readTimeout, @writeTimeout);

-- Register the Modbus master device
PRINT [DeviceManager].[RegisterModbusMaster] (@ChannelName, @DeviceName, @UseMbapHeaders, @UseExtendedAddressing, @UnitId, @NumberOfRetries, @WaitToRetry, @RequestWriteDelay, @ResponseReadDelay);

-- Loop through the total number of registers, polling in chunks of 125 or less
WHILE @RegistersLeft > 0
BEGIN
    -- Determine how many registers to poll in this iteration (max 125 or whatever is left)
    SET @RegistersToPoll = CASE 
        WHEN @RegistersLeft > @MaxRegistersPerPoll THEN @MaxRegistersPerPoll 
        ELSE @RegistersLeft 
    END;

    -- Reset the HoldingRegisterArray for this batch
    SET @HoldingRegisterArray = [ModbusMaster].[HoldingRegisterArray]::Empty();

    -- Loop to add the necessary registers to the HoldingRegisterArray for this poll
    DECLARE @i int = 0;
    WHILE @i < @RegistersToPoll
    BEGIN
        DECLARE @HoldingRegister [ModbusMaster].[HoldingRegister] = [ModbusMaster].[HoldingRegister]::Parse('True;' + CAST(@CurrentStartAddress + @i AS NVARCHAR(10)) + ',False,0');
        SET @HoldingRegisterArray = @HoldingRegisterArray.AddHoldingRegister(@HoldingRegister);
        SET @i = @i + 1;
    END

    -- Read a block of Holding Registers
    SET @HoldingRegisterArray = [ModbusMaster].[ReadHoldings](@deviceName, @HoldingRegisterArray);

    -- Reset the SQL string
    SET @SQL = 'INSERT INTO ModbusValues.dbo.ModbusRegisterValues (RegisterAddress, RegisterValue) VALUES ';

    -- Build the dynamic SQL to insert the register values
    SET @i = 0;
    WHILE @i < @RegistersToPoll
    BEGIN
        DECLARE @Value int;
        SET @Value = @HoldingRegisterArray.GetShort(@i, @ByteSwap);
        
        -- Add the register and value to the dynamic SQL string
        SET @SQL = @SQL + '(' + CAST(@CurrentStartAddress + @i AS NVARCHAR(10)) + ', ' + CAST(@Value AS NVARCHAR(10)) + '),';
        
        SET @i = @i + 1;
    END

    -- Remove the last comma from the SQL string
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);

    -- Execute the dynamic SQL to insert the values
    EXEC sp_executesql @SQL;

    -- Update the number of registers left and the current starting address
    SET @RegistersLeft = @RegistersLeft - @RegistersToPoll;
    SET @CurrentStartAddress = @CurrentStartAddress + @RegistersToPoll;
END

-- Unregister the Modbus device and TCP channel
PRINT [DeviceManager].[UnregisterDevice] (@deviceName);
PRINT [ChannelManager].[UnregisterChannel] (@channelName);

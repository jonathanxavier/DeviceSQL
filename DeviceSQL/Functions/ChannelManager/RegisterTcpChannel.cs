using DeviceSQL.IO.Channels;
using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Diagnostics;
using System.Text;
using System.Linq;

namespace DeviceSQL.ChannelManager
{
    partial class Functions
    {

        [Microsoft.SqlServer.Server.SqlFunction]
        public static SqlBoolean ChannelManager_RegisterTcpChannel(SqlString channelName, SqlString hostName, SqlInt32 hostPort, SqlInt32 readTimeout, SqlInt32 writeTimeout)
        {
            try
            {
                var channelNameValue = channelName.Value;
                var channels = Watchdog.Worker.Channels;
                channels.Where(channel => true);
                if (channels.Where(channel => channel.Name == channelNameValue).Count() == 0)
                {
                    var tcpChannel = new TcpChannel()
                    {
                        Name = channelNameValue
                    };

                    tcpChannel.TcpClient.Connect(hostName.Value, hostPort.Value);

                    tcpChannel.ReadTimeout = readTimeout.Value;
                    tcpChannel.WriteTimeout = writeTimeout.Value;

                    channels.Add(tcpChannel);

                    return new SqlBoolean(true);

                }
                else
                {
                    throw new ArgumentException("Channel name is already registered");
                }
            }
            catch (Exception ex)
            {
                Trace.TraceError(string.Format("Error registering channel: {0}", ex.Message));
            }
            return new SqlBoolean(false);
        }
    }

}
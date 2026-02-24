#include <ipmid/api.hpp>
#include <phosphor-logging/log.hpp>

using namespace phosphor::logging;

// NetFn 0x30 (OEM One), Cmd 0x01
// Request: 1 byte (test parameter)
// Response: 3 bytes (major, minor, status)
ipmi::RspType<uint8_t, uint8_t, uint8_t>
    ipmiOemGetVersion(ipmi::Context::ptr ctx, uint8_t param)
{
    log<level::INFO>("DriveNets OEM Get Version",
                     entry("PARAM=0x%02X", param),
                     entry("CHANNEL=%d", ctx->channel));

    uint8_t major = 1;
    uint8_t minor = 0;
    uint8_t status = 0x00; // success

    return ipmi::responseSuccess(major, minor, status);
}

// NetFn 0x30, Cmd 0x02
// Request: 1 byte (sensor ID)
// Response: variable byte array (sensor data)
ipmi::RspType<std::vector<uint8_t>>
    ipmiOemGetSensorData(ipmi::Context::ptr ctx, uint8_t sensorId)
{
    log<level::INFO>("DriveNets OEM Get Sensor Data",
                     entry("SENSOR_ID=0x%02X", sensorId));

    std::vector<uint8_t> data;
    data.push_back(0xDE); // Dummy data
    data.push_back(0xAD);
    data.push_back(0xBE);
    data.push_back(0xEF);

    return ipmi::responseSuccess(data);
}

// NetFn 0x30, Cmd 0x03
// Request: empty
// Response: variable byte array – null-terminated compilation timestamp string
//           Format: "<date> <time>" e.g. "Feb 19 2026 14:32:00"
ipmi::RspType<std::vector<uint8_t>>
    ipmiOemGetBuildTimestamp(ipmi::Context::ptr /*ctx*/)
{
    static constexpr char timestamp[] = __DATE__ " " __TIME__;

    log<level::INFO>("DriveNets OEM Get Build Timestamp",
                     entry("TIMESTAMP=%s", timestamp));

    std::vector<uint8_t> data(std::begin(timestamp), std::end(timestamp));
    return ipmi::responseSuccess(data);
}

// Auto-register on library load
void registerOemCommands() __attribute__((constructor));

void registerOemCommands()
{
    log<level::INFO>("Registering DriveNets OEM IPMI commands");

    // Register: NetFn 0x30 (oemOne), Cmd 0x01
    ipmi::registerHandler(
        ipmi::prioOemBase,
        ipmi::netFnOemOne,      // 0x30
        0x01,
        ipmi::Privilege::User,
        ipmiOemGetVersion);

    // Register: NetFn 0x30, Cmd 0x02
    ipmi::registerHandler(
        ipmi::prioOemBase,
        ipmi::netFnOemOne,
        0x02,
        ipmi::Privilege::User,
        ipmiOemGetSensorData);

    // Register: NetFn 0x30, Cmd 0x03
    ipmi::registerHandler(
        ipmi::prioOemBase,
        ipmi::netFnOemOne,
        0x03,
        ipmi::Privilege::User,
        ipmiOemGetBuildTimestamp);

    log<level::INFO>("DriveNets OEM commands registered");
}

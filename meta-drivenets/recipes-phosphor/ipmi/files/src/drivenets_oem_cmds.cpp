#include <ipmid/api.hpp>
#include <nlohmann/json.hpp>
#include <phosphor-logging/log.hpp>
#include <sdbusplus/bus.hpp>
#include <sdbusplus/exception.hpp>

#include <cstdint>
#include <fstream>
#include <map>
#include <mutex>
#include <stdexcept>
#include <string>
#include <variant>
#include <vector>

using namespace phosphor::logging;
using json = nlohmann::json;

// ---------------------------------------------------------------------------
// Sensor config file — installed per-machine by drivenets-ipmi-oem_1.0.bb.
//
// Yocto resolves files/${MACHINE}/sensors.json at build time, so each
// machine image gets its own table without any C++ changes.
//
// Schema:
//   {
//     "sensors": [
//       { "id": <uint8>, "description": "<str>", "dbus_path": "<str>" },
//       ...
//     ]
//   }
// ---------------------------------------------------------------------------
static constexpr const char* SENSORS_CONFIG =
    "/usr/share/drivenets-ipmi-oem/sensors.json";

struct SensorEntry
{
    std::string path;
    std::string description;
};

// Sensor table loaded lazily from SENSORS_CONFIG on first use.
static std::map<uint8_t, SensorEntry> sensorTable;
static std::once_flag sensorTableLoaded;

static void loadSensorTable()
{
    try
    {
        std::ifstream f(SENSORS_CONFIG);
        if (!f.is_open())
        {
            log<level::WARNING>(
                "drivenets-ipmi-oem: sensors config not found",
                entry("PATH=%s", SENSORS_CONFIG));
            return;
        }

        auto cfg = json::parse(f);
        for (const auto& s : cfg.at("sensors"))
        {
            uint8_t id = s.at("id").get<uint8_t>();
            sensorTable[id] = {s.at("dbus_path").get<std::string>(),
                               s.at("description").get<std::string>()};
        }

        log<level::INFO>("drivenets-ipmi-oem: sensor table loaded",
                         entry("COUNT=%zu", sensorTable.size()));
    }
    catch (const std::exception& e)
    {
        log<level::ERR>("drivenets-ipmi-oem: failed to load sensor config",
                        entry("PATH=%s", SENSORS_CONFIG),
                        entry("ERROR=%s", e.what()));
    }
}

// ---------------------------------------------------------------------------
// Get Sensor Data response format:
//
//   Byte 0:    status
//                0x00 = OK
//                0x01 = unknown sensor ID (not in sensors.json)
//                0x02 = D-Bus error (sensor daemon not running, etc.)
//   Bytes 1-2: signed 16-bit temperature in 0.1°C units, big-endian
//              valid only when status = 0x00
//              examples: 255 = 25.5°C,  -10 = -1.0°C,  1000 = 100.0°C
//   Bytes 3+:  null-terminated ASCII sensor description (always present)
//              e.g. "Ambient_Temp_AFO\0"
//
// Host-side decode:
//   status = byte[0]
//   int16_t raw = (int16_t)((byte[1] << 8) | byte[2]);
//   double tempC = raw / 10.0;          // valid when status == 0x00
//   const char* name = (const char*)&byte[3];
// ---------------------------------------------------------------------------

static std::vector<uint8_t> buildSensorResponse(uint8_t status, int16_t raw,
                                                 const std::string& description)
{
    std::vector<uint8_t> resp;
    resp.push_back(status);
    resp.push_back(static_cast<uint8_t>((raw >> 8) & 0xFF));
    resp.push_back(static_cast<uint8_t>(raw & 0xFF));
    for (char c : description)
        resp.push_back(static_cast<uint8_t>(c));
    resp.push_back(0x00);
    return resp;
}

// Use ObjectMapper to resolve which D-Bus service owns a given object path.
static std::string getSensorService(sdbusplus::bus_t& bus,
                                    const std::string& path)
{
    auto mapper = bus.new_method_call(
        "xyz.openbmc_project.ObjectMapper",
        "/xyz/openbmc_project/object_mapper",
        "xyz.openbmc_project.ObjectMapper", "GetObject");
    mapper.append(path,
                  std::vector<std::string>{"xyz.openbmc_project.Sensor.Value"});
    auto reply = bus.call(mapper);

    std::map<std::string, std::vector<std::string>> services;
    reply.read(services);
    if (services.empty())
        throw std::runtime_error("no service found for path: " + path);

    return services.begin()->first;
}

// ---------------------------------------------------------------------------
// NetFn 0x30 (OEM One), Cmd 0x01 — Get Version
// Request:  1 byte  (param, reserved)
// Response: 3 bytes (major, minor, status=0x00)
// ---------------------------------------------------------------------------
ipmi::RspType<uint8_t, uint8_t, uint8_t>
    ipmiOemGetVersion(ipmi::Context::ptr ctx, uint8_t param)
{
    log<level::INFO>("DriveNets OEM Get Version",
                     entry("PARAM=0x%02X", param),
                     entry("CHANNEL=%d", ctx->channel));

    return ipmi::responseSuccess(uint8_t{1}, uint8_t{0}, uint8_t{0x00});
}

// ---------------------------------------------------------------------------
// NetFn 0x30 (OEM One), Cmd 0x02 — Get Sensor Data
// Request:  1 byte  (sensor ID defined in sensors.json)
// Response: status(1B) + value_hi(1B) + value_lo(1B) + description(NB) + NUL
// ---------------------------------------------------------------------------
ipmi::RspType<std::vector<uint8_t>>
    ipmiOemGetSensorData(ipmi::Context::ptr /*ctx*/, uint8_t sensorId)
{
    std::call_once(sensorTableLoaded, loadSensorTable);

    log<level::INFO>("DriveNets OEM Get Sensor Data",
                     entry("SENSOR_ID=0x%02X", sensorId));

    auto it = sensorTable.find(sensorId);
    if (it == sensorTable.end())
    {
        log<level::WARNING>(
            "DriveNets OEM Get Sensor Data: unknown sensor ID",
            entry("SENSOR_ID=0x%02X", sensorId));
        return ipmi::responseSuccess(
            buildSensorResponse(0x01, 0, "unknown_sensor"));
    }

    const auto& [path, description] = it->second;

    try
    {
        auto bus = sdbusplus::bus::new_default();

        std::string service = getSensorService(bus, path);

        auto method = bus.new_method_call(service.c_str(), path.c_str(),
                                          "org.freedesktop.DBus.Properties",
                                          "Get");
        method.append("xyz.openbmc_project.Sensor.Value", "Value");
        auto reply = bus.call(method);

        std::variant<double> valueVariant;
        reply.read(valueVariant);
        double tempC = std::get<double>(valueVariant);

        auto raw = static_cast<int16_t>(tempC * 10.0);

        log<level::DEBUG>("DriveNets OEM Get Sensor Data: OK",
                          entry("SENSOR_ID=0x%02X", sensorId),
                          entry("NAME=%s", description.c_str()),
                          entry("TEMP_0_1C=%d", static_cast<int>(raw)));

        return ipmi::responseSuccess(
            buildSensorResponse(0x00, raw, description));
    }
    catch (const std::exception& e)
    {
        log<level::ERR>("DriveNets OEM Get Sensor Data: D-Bus error",
                        entry("SENSOR_ID=0x%02X", sensorId),
                        entry("NAME=%s", description.c_str()),
                        entry("ERROR=%s", e.what()));
        return ipmi::responseSuccess(
            buildSensorResponse(0x02, 0, description));
    }
}

// ---------------------------------------------------------------------------
// NetFn 0x30 (OEM One), Cmd 0x03 — Get Build Timestamp
// Request:  empty
// Response: null-terminated ASCII string "MMM DD YYYY HH:MM:SS"
// ---------------------------------------------------------------------------
ipmi::RspType<std::vector<uint8_t>>
    ipmiOemGetBuildTimestamp(ipmi::Context::ptr /*ctx*/)
{
    static constexpr char timestamp[] = __DATE__ " " __TIME__;
    log<level::INFO>("DriveNets OEM Get Build Timestamp",
                     entry("TIMESTAMP=%s", timestamp));
    std::vector<uint8_t> data(std::begin(timestamp), std::end(timestamp));
    return ipmi::responseSuccess(data);
}

// ---------------------------------------------------------------------------
// Auto-register all handlers on shared library load
// ---------------------------------------------------------------------------
void registerOemCommands() __attribute__((constructor));
void registerOemCommands()
{
    log<level::INFO>("Registering DriveNets OEM IPMI commands");

    ipmi::registerHandler(ipmi::prioOemBase, ipmi::netFnOemOne, 0x01,
                          ipmi::Privilege::User, ipmiOemGetVersion);

    ipmi::registerHandler(ipmi::prioOemBase, ipmi::netFnOemOne, 0x02,
                          ipmi::Privilege::User, ipmiOemGetSensorData);

    ipmi::registerHandler(ipmi::prioOemBase, ipmi::netFnOemOne, 0x03,
                          ipmi::Privilege::User, ipmiOemGetBuildTimestamp);

    log<level::INFO>("DriveNets OEM commands registered");
}

project('drivenets-ipmi-oem', 'cpp',
    version: '1.0',
    default_options: [
        'cpp_std=c++20',
        'warning_level=3',
    ],
)

phosphor_logging_dep = dependency('phosphor-logging')
ipmid_dep = dependency('libipmid')
sdbusplus_dep = dependency('sdbusplus')
nlohmann_json_dep = dependency('nlohmann_json')

ipmid_providers_dir = get_option('prefix') / get_option('libdir') / 'ipmid-providers'

shared_library(
    'drivenetsoemcmds',
    'src/drivenets_oem_cmds.cpp',
    dependencies: [
        phosphor_logging_dep,
        ipmid_dep,
        sdbusplus_dep,
        nlohmann_json_dep,
    ],
    install: true,
    install_dir: ipmid_providers_dir,
    override_options: ['b_lundef=false'],
)

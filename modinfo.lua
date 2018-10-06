name = "Fast Travel (with ui)"
author = "SoraYuki"
version = "1.02"
description = "version " .. version .. "\nBuild a fast travel network and travel instantly from sign post to sign post."

forumthread = ""

api_version = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dst_compatible = true

client_only_mod = false
all_clients_require_mod = true
server_filter_tags = {"fast travel"}

priority = 0.1

configuration_options = {
    {
        name = "Travel_Cost",
        label = "Travel Cost",
        options = {
            {description = "X0.25", data = 128},
            {description = "X0.5", data = 64},
            {description = "X1.0", data = 32},
            {description = "X1.5", data = 21.3}
        },
        default = 32
    },
    {
        name = "Ownership",
        label = "Ownership Restriction?",
        options = {
            {description = "Enable", data = true},
            {description = "Disable", data = false}
        },
        default = false
    }
}

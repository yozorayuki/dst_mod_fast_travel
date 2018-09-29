name = "Fast Travel"
description = "Build a fast travel network and travel instantly from sign post to sign post."

author = "Isosurface"
version = "1.1.0"

forumthread = ""

api_version = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dst_compatible = true

client_only_mod = false
all_clients_require_mod = true
server_filter_tags = {"fast travel"}

priority = 0

configuration_options =
{
	{
        name = "Travel_Cost",
        label = "Travel Cost",
        options =
        {
            {description = "Very low", data = 128},
            {description = "Low", data = 64},
            {description = "Normal", data = 32},
            {description = "High", data = 22.6}
        },
        default = 32,
    },
	{
        name = "Ownership",
        label = "Ownership Restriction?",
        options =
        {
            {description = "Enable", data = true},
            {description = "Disable", data = false}
        },
        default = false,
    },
}
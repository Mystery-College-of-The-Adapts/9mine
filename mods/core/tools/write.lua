WriteTool = {
    desription = "Write file",
    inventory_image = "core_write.png",
    wield_image = "core_write.png",
    tool_capabilities = {
        punch_attack_uses = 0,
        damage_groups = {
            write = 1
        }
    }
}

function WriteTool.write(entity, player_name)
    local player_graph = graphs:get_player_graph(player_name)
    local directory_entry = player_graph:get_entry(entity.entry_string)
    if directory_entry.stat.name:match(".rc$") then
        minetest.show_formspec(player_name, "stat:write_rc",
            table.concat({"formspec_version[4]", "size[13,13,false]",
                          "field[0,0;0,0;file_path;;" .. directory_entry.path .. "]",
                          "textarea[0.5,0.5;12.0,10.6;content;;]", "button_exit[7,11.6;2.5,0.9;write;write]",
                          "button[10,11.6;2.5,0.9;execute;execute]"}, ""))
    else
        minetest.show_formspec(player_name, "stat:write",
            table.concat({"formspec_version[3]", "size[13,13,false]",
                          "field[0,0;0,0;file_path;;" .. directory_entry.path .. "]",
                          "textarea[0.5,0.5;12.0,10.6;content;;]", "button_exit[10,11.6;2.5,0.9;write;write]"}, ""))
    end
end

minetest.register_tool("core:write", WriteTool)

minetest.register_on_joinplayer(function(player)
    local inventory = player:get_inventory()
    if not inventory:contains_item("main", "core:write") then
        inventory:add_item("main", "core:write")
    end
end)

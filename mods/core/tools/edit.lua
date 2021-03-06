EditTool = {
    desription = "Edit file",
    inventory_image = "core_edit.png",
    wield_image = "core_edit.png",
    tool_capabilities = {
        punch_attack_uses = 0,
        damage_groups = {
            edit = 1
        }
    }
}

function EditTool.edit(entity, player, player_name)
    local player_graph = graphs:get_player_graph(player_name)
    local directory_entry = player_graph:get_entry(entity.entry_string)
    local conn = player_graph:get_platform(common.get_platform_string(player)):get_conn()
    local response, content = pcall(np_prot.file_read, conn, directory_entry.path)
    if not response then
        minetest.chat_send_player(player_name, content)
        return
    else
        if directory_entry.stat.name:match(".rc$") then
            minetest.show_formspec(player_name, "stat:edit_rc",
                table.concat({"formspec_version[4]", "size[13,13,false]",
                              "field[0,0;0,0;file_path;;" .. directory_entry.path .. "]",
                              "textarea[0.5,0.5;12.0,10.6;content;;", minetest.formspec_escape(content), "]",
                              "button_exit[7,11.6;2.5,0.9;edit;edit]", "button[10,11.6;2.5,0.9;execute;execute]"}, ""))
        else
            minetest.show_formspec(player_name, "stat:edit",
                table.concat({"formspec_version[3]", "size[13,13,false]",
                              "field[0,0;0,0;file_path;;" .. directory_entry.path .. "]",
                              "textarea[0.5,0.5;12.0,10.6;content;;", minetest.formspec_escape(content), "]",
                              "button_exit[10,11.6;2.5,0.9;edit;edit]"}, ""))
            return
        end
    end
end

minetest.register_tool("core:edit", EditTool)

minetest.register_on_joinplayer(function(player)
    local inventory = player:get_inventory()
    if not inventory:contains_item("main", "core:edit") then
        inventory:add_item("main", "core:edit")
    end
end)

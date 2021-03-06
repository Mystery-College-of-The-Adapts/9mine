minetest.register_on_prejoinplayer(function(name, ip)
    local user_addr = root_cmdchan:execute("ndb/regquery -n user " .. name)
    if not user_addr or user_addr:gsub("%s+", "") == "" then
        root_cmdchan:write("echo -n " .. name .. " >> /n/9mine/user")
    end
    connections:add_player(name)
end)

poll_regquery = function(name, counter, player, last_login)
    if counter > 5 then
        local result, ns_create_output = pcall(np_prot.file_read, root_cmdchan.connection.conn, "/n/9mine/user")
        minetest.kick_player(name, "Error creating NS. Try again later. Log: \n" .. ns_create_output)
    end
    counter = counter + 1
    local user_addr = root_cmdchan:execute("ndb/regquery -n user " .. name):gsub("\n", "")
    local response = root_cmdchan:execute("mount -A " .. user_addr .. " /n/" .. name)
    if response == "" then
        minetest.chat_send_player(name, user_addr .. " mounted")
        minetest.after(2, spawn_root_platform, user_addr, player, last_login)
    else
        minetest.after(2, poll_regquery, name, counter, player, last_login)
    end
end

minetest.register_on_joinplayer(function(player, last_login)
    minetest.after(3, common.update_path_hud, player)
    local name = player:get_player_name()
    local user_addr = root_cmdchan:execute("ndb/regquery -n user " .. name):gsub("\n", "")
    root_cmdchan:execute("mkdir /n/" .. name)
    if root_cmdchan:execute("mount -A " .. user_addr .. " /n/" .. name) == "" then
        minetest.chat_send_player(name, user_addr .. " mounted")
        connections:add_player(name)
        minetest.after(2, spawn_root_platform, user_addr, player, last_login)
    else
        common.show_wait_notification(name, "Please, wait.\nThe namespace is creating.")
        local counter = 1
        minetest.after(2, poll_regquery, name, counter, player, last_login)
    end
end)
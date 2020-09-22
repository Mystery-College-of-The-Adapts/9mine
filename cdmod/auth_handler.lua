global_cache = nil
minetest.register_authentication_handler(
    {
        get_auth = function(name)
            if global_cache == nil then
                local tcp = socket:tcp()
                local connection, err = tcp:connect("getauth", 1917)
                if (err ~= nil) then
                    print("dump of error newest .. " .. dump(err))
                    print("Connection error")
                    return
                end
                local conn = np.attach(tcp, "dievri", "")

                -- GET PASSWORD FROM AUTH CENTER
                local g = conn:newfid()
                conn:walk(conn.rootfid, g, "/tmp/cmdchan/export/cmd")
                conn:open(g, 1)
                local ftext = "getauthinfo default auth user password"
                local buf = data.new(ftext)
                print(dump(tostring(buf)))
                local n = conn:write(g, 0, buf)
                if n ~= #buf then
                    error("test: expected to write " .. #buf ..
                              " bytes but wrote " .. n)
                end
                conn:clunk(g)

                -- GET RESPONSE FROM AUTH CENTER 
                local f = conn:newfid()
                np:walk(conn.rootfid, f, "/tmp/cmdchan/export/cmd")
                conn:open(f, 0)
                local statistics = conn:stat(f)
                local READ_BUF_SIZ = 4096
                local offset = 0
                local content = nil
                local data = conn:read(f, offset, READ_BUF_SIZ)
                content = tostring(data)

                if data ~= nil then offset = offset + #data end
                while (true) do
                    data = conn:read(f, offset, READ_BUF_SIZ)

                    if (data == nil) then break end
                    content = content .. tostring(data)
                    offset = offset + #(tostring(data))
                end
                print("content of cmd is " .. content)
                conn:clunk(f)

                -- -- GET PASSWORD FROM LOCAL INSTANCE
                -- local p = conn:newfid()
                -- np:walk(conn.rootfid, p, "/usr/root/keyring/default")
                -- conn:open(p, 0)
                -- local statistics = conn:stat(p)
                -- local READ_BUF_SIZ = 4096
                -- local offset = 0
                -- local content = nil
                -- local data = conn:read(p, offset, READ_BUF_SIZ)
                -- content = tostring(data)

                -- if data ~= nil then offset = offset + #data end
                -- while (true) do
                --     data = conn:read(p, offset, READ_BUF_SIZ)

                --     if (data == nil) then break end
                --     content = content .. tostring(data)
                --     offset = offset + #(tostring(data))
                -- end
                -- print("content of keyringd is " .. content)
                -- conn:clunk(g)
                -- local passwd = content

                tcp:close()
                local hash = minetest.get_password_hash("user", "password")
                local privileges = minetest.settings:get("default_privs")
                local privs = minetest.string_to_privs(privileges)
                -- global_cache = {
                --     password = hash,
                --     privileges = privs,
                --     last_login = 1600767360
                -- }
                return global_cache
            else
                return global_cache -- print("NO USER FOUND, CREATE_AUTH CALLING>>>")
            end
        end,

        create_auth = function(name, password)
            print("name:" .. name)
            print("passowrd:" .. password)

            local tcp = socket:tcp()
            local connection, err = tcp:connect("getauth", 1917)
            if (err ~= nil) then
                print("dump of error newest .. " .. dump(err))
                print("Connection error")
                return
            end
            local conn = np.attach(tcp, "dievri", "")

            -- GET PASSWORD FROM AUTH CENTER
            local g = conn:newfid()
            conn:walk(conn.rootfid, g, "/n/client/newuser")
            conn:open(g, 1)
            local ftext = name .. " " .. password
            local buf = data.new(ftext)
            local n = conn:write(g, 0, buf)
            if n ~= #buf then
                error(
                    "test: expected to write " .. #buf .. " bytes but wrote " ..
                        n)
            end
            conn:clunk(g)

            local f = conn:newfid()
            np:walk(conn.rootfid, f, "/n/client/newuser")
            conn:open(f, 0)
            local statistics = conn:stat(f)
            local READ_BUF_SIZ = 4096
            local offset = 0
            local content = nil
            local data = conn:read(f, offset, READ_BUF_SIZ)
            content = tostring(data)

            if data ~= nil then offset = offset + #data end
            while (true) do
                data = conn:read(f, offset, READ_BUF_SIZ)

                if (data == nil) then break end
                content = content .. tostring(data)
                offset = offset + #(tostring(data))
            end
            print("content of newuser is " .. content)
            local privileges = minetest.settings:get("default_privs")
            local privs = minetest.string_to_privs(privileges)
            conn:clunk(f)
            global_cache = {
                password = password,
                privileges = privs,
                last_login = 1600767360
            }
            print("authentication created")
            tcp:close()
        end,
        set_password = function(name, password) print("setting password") end,
        record
    })

class 'mvcp'

function mvcp:mvcp(platform, params)
    self.params = params
    self.platform = platform
    self.addr = platform:get_addr()
    self.path = platform:get_path()
    self.attachment = platform:get_attachment()
    return self
end

-- Takes as input chat message, and sets and returns absolute path 
-- for sources and destination 
function mvcp:parse_params()
    local destination = {}
    local sources = {}
    for w in self.params:gmatch("[^ ]+") do
        if w:match("^%-") then
        elseif w:match("^%*$") then
            table.insert(sources, w)
        elseif w:match("^%.$") then
            w = self.path
            destination = w
            table.insert(sources, w)
        else
            w = w:match("^%./") and w:gsub("^%./", self.path == "/" and self.path or self.path .. "/") or w
            if not w:match("^/") then
                w = self.path:match("/$") and self.path .. w or self.path .. "/" .. w
            end
            destination = w
            table.insert(sources, w)
        end
    end
    table.remove(sources)
    if destination:len() > 1 and destination:match('/$') then
        destination = destination:match('.*[^/]')
    end
    if destination:match('^%.$') then
        destination = self.path
    end
    self.destination = destination
    self.sources = sources
    return self
end

function mvcp:is_destination_platform()
    return platforms:get_platform(self.addr .. self.destination)
end

-- analyzes destination path to decide if needed to go 
-- one level up on fs structure
function mvcp:set_destination_platform()
    local destination = platforms:get_platform(self.addr .. self.destination)
    if not destination then
        local result, response = pcall(np_prot.stat_read, self.attachment, self.destination)
        if not result or response.qid.type ~= 128 then
            local parent_path = mvcp.get_parent_path(self.destination)
            destination = platforms:get_platform(self.addr .. parent_path)
        end
    end
    self.destination_platform = destination
    return self.destination_platform
end

-- provided with path string, returns path on level up 
-- on fs structure
function mvcp.get_parent_path(path)
    if path == "/" then
        return "/"
    end
    local parent = path:match('.*/')
    if parent == "/" then
        return "/"
    end
    return parent:match('.*[^/]')
end

-- return changes which occures on provided platform after execution on cmdchan command 
function mvcp:get_changes(platform)
    local platform = platform
    local changes_new = {}
    local changes_removed = {}

    local stats = platform.directory_entries
    local content_new = common.qid_as_key(platform:readdir())
    for qid, st in pairs(content_new) do
        if (not stats[qid]) or (stats[qid].stat.version ~= st.version or stats[qid].stat.name ~= st.name) then
            changes_new[qid] = st
        end
    end

    for qid, stat in pairs(stats) do
        if not content_new[qid] then
            changes_removed[stat.stat.name] = stat
        end
    end

    return changes_new, changes_removed
end

-- if file was renamed on same platform, than no new slot will be used 
function mvcp:inplace(changes)
    for qid, change in pairs(changes) do
        if self.destination_platform.directory_entries[qid] then
            local directory_entry = self.destination_platform.directory_entries[qid]
            local stat_entity = self.destination_platform:get_entity_by_qid(qid)
            directory_entry:set_stat(change):delete_node()
            self.destination_platform:configure_entry(directory_entry)
            platforms:add_directory_entry(self.destination_platform, directory_entry)
            common.flight(stat_entity, directory_entry)
        end
    end
end

-- If multiple sources for mv provided, reduces to 1 sources with same platform
function mvcp:reduce()
    local reduced_sources = {}
    local temp = {}
    for index, source in pairs(self.sources) do
        if source == "*" then
            table.insert(reduced_sources, source)
        else
            local parent_source = mvcp.get_parent_path(source)
            if not temp[parent_source] then
                temp[parent_source] = 1
                table.insert(reduced_sources, parent_source)
            end
        end
    end
    return reduced_sources
end

-- provided with files that disappeared from source directory 
-- and files that appeared in destination directory
-- and based on name triggers files flight 
function mvcp:from_platform(changes_removed, changes_new)
    for qid, change in pairs(changes_new) do
        if changes_removed[change.name] then
            local path = self.platform.platform_string
            local entry_string = path:match("/$") and path .. change.name or path .. "/" .. change.name
            local directory_entry = platforms:get_entry(entry_string)
            local stat_entity = self.platform:get_entity_by_pos(directory_entry.pos)
            directory_entry:delete_node():set_pos(self.destination_platform:get_slot()):set_stat(change)
            self.destination_platform:configure_entry(directory_entry)
            self.destination_platform.directory_entries[change.qid.path_hex] = directory_entry
            platforms:add_directory_entry(self.destination_platform, directory_entry)
            common.flight(stat_entity, directory_entry)
        end
    end
end

local move = function(player_name, params)
    local platform = platforms:get_platform(common.get_platform_string(minetest.get_player_by_name(player_name)))
    local mvcp = mvcp(platform, params):parse_params()
    local cmdchan = platform:get_cmdchan()
    minetest.chat_send_all(cmdchan:execute("mv " .. params, platform:get_path()))
    if not mvcp:set_destination_platform() then
        return true, "mv will be handled by platform refresh"
    end
    local changes_new = mvcp:get_changes(mvcp.destination_platform)
    for index, source in pairs(mvcp:reduce()) do
        if source == "*" then
            mvcp.platform = platform
        else
            mvcp.platform = platforms:get_platform(platform:get_addr() .. source)
        end
        if mvcp.platform == mvcp.destination_platform then
            mvcp:inplace(changes_new)
        else
            local _, changes_removed = mvcp:get_changes(mvcp.platform)
            mvcp:from_platform(changes_removed, changes_new)
        end
    end
end

minetest.register_chatcommand("mv", {
    func = move
})

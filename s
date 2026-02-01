local storage = game:GetService("ReplicatedStorage")
local tele_service = game:GetService("TeleportService")
local players = game:GetService("Players")
local fetch_remote = storage.Remotes.FetchProfile

local file_name = "ScrapedPlayers_Final.txt"
local save_threshold = 10
local restart_threshold = 300 
local thread_count = 100

local scraped_data = {}
local unique_ids = {} 
local total_count = 0
local current_batch = 0
local session_count = 0 
local write_lock = false 
local active = true

local function sync_file()
    while write_lock do task.wait() end 
    write_lock = true
    
    local head = string.format("Total Found: %d\n\n", total_count)
    local body = ""
    
    pcall(function()
        if isfile(file_name) then
            local raw = readfile(file_name)
            body = raw:gsub("Total Found: %d+\n\n", "")
        end
    end)
    
    writefile(file_name, head .. body .. table.concat(scraped_data))
    scraped_data = {} 
    current_batch = 0
    write_lock = false
end

local function worker(id)
    while active do
        if session_count >= restart_threshold then break end

        local ok, profile = pcall(function()
            [cite_start]return fetch_remote:InvokeServer({["goBack"] = false}) [cite: 215, 233]
        end)

        if ok and profile and profile.UserId then
            local id_str = tostring(profile.UserId)
            
            if not unique_ids[id_str] then
                unique_ids[id_str] = true
                total_count = total_count + 1
                current_batch = current_batch + 1
                session_count = session_count + 1
                
                [cite_start]local d_name = profile.DisplayName or "n/a" [cite: 386]
                [cite_start]local u_name = profile.Username or "n/a" [cite: 387]
                local age = "n/a"
                
                pcall(function()
                    local p_obj = players:GetPlayerByUserId(profile.UserId)
                    if p_obj then age = p_obj.AccountAge .. " days" end
                end)
                
                table.insert(scraped_data, string.format("%s : %s : %s : %s\n", d_name, u_name, id_str, age))
                print("worker " .. id .. " found " .. d_name .. " (" .. id_str .. ")")

                if current_batch >= save_threshold then
                    task.spawn(sync_file)
                    print("saved batch to file, total is now " .. total_count)
                end
            end
        else
            [cite_start]task.wait(1) [cite: 211]
        end
    end
end

task.spawn(function()
    for i = 1, thread_count do
        task.spawn(worker, i)
        if i % 25 == 0 then task.wait() end 
    end
    
    repeat task.wait(1) until session_count >= restart_threshold
    
    active = false
    sync_file()
    task.wait(1)

    -- this fixes the infinite loop by using a loadstring or the executor's internal name
    local queue = (syn and syn.queue_on_teleport) or queue_on_teleport
    if queue then
        -- use a loadstring pointing to your script's raw link (github/pastebin)
        -- this is the only way to avoid the infinite nesting loop
        queue([[loadstring(game:HttpGet("aaaaa"))()]])
    end

    print("restarting for fresh pool...")
    if #players:GetPlayers() <= 1 then
        tele_service:Teleport(game.PlaceId, players.LocalPlayer)
    else
        tele_service:TeleportToPlaceInstance(game.PlaceId, game.JobId, players.LocalPlayer)
    end
end)

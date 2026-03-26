-- Game of Life | lua life.lua [file.txt]
-- A=faster  Z=slower  Q=quit
-- Файл: # живая, . мёртвая

local W, H = 40, 20
local SPEEDS = {0.5, 0.3, 0.2, 0.1, 0.07, 0.04, 0.02, 0.01}
local sp = 4

local function newGrid() 
    local g = {}
    for i = 1, W*H do g[i] = false end
    return g
end

local function idx(x, y) return ((y-1) % H) * W + ((x-1) % W) + 1 end

local function step(g)
    local n = newGrid()
    for y = 1, H do for x = 1, W do
        local c = 0
        for dy = -1, 1 do for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                if g[idx(x+dx, y+dy)] then c = c + 1 end
            end
        end end
        local alive = g[idx(x,y)]
        n[idx(x,y)] = alive and (c==2 or c==3) or (not alive and c==3)
    end end
    return n
end

local function render(g, gen)
    local b = {string.format("  Gen:%d  Speed:%d/8  [A]faster [Z]slower [Q]quit\n  +%s+\n", gen, sp, string.rep("-",W))}
    for y = 1, H do
        b[#b+1] = "  |"
        for x = 1, W do b[#b+1] = g[idx(x,y)] and "#" or "." end
        b[#b+1] = "|\n"
    end
    b[#b+1] = "  +" .. string.rep("-",W) .. "+\n"
    io.write("\027[H", table.concat(b)); io.flush()
end

local function readKey()
    local ch
    pcall(function()
        os.execute("stty -echo -icanon min 0 time 0 2>/dev/null")
        local f = io.open("/dev/stdin","r")
        if f then ch = f:read(1); f:close() end
        os.execute("stty echo icanon 2>/dev/null")
    end)
    return ch
end

-- init grid
local g = newGrid()
if arg[1] then
    local f = io.open(arg[1]) or (function() print("File not found"); os.exit(1) end)()
    local rows, maxw = {}, 0
    for line in f:lines() do
        local row = {}
        for ch in line:gmatch(".") do row[#row+1] = ch=="#" end
        rows[#rows+1] = row
        if #row > maxw then maxw = #row end
    end
    f:close()
    if maxw > W then W = maxw end
    if #rows > H then H = #rows end
    g = newGrid()
    local ox, oy = math.floor((W-maxw)/2), math.floor((H-#rows)/2)
    for ry, row in ipairs(rows) do
        for rx, v in ipairs(row) do
            if v then g[idx(rx+ox, ry+oy)] = true end
        end
    end
else
    math.randomseed(os.time())
    for i = 1, W*H do g[i] = math.random() < 0.25 end
end

io.write("\027[2J")
local gen = 0
pcall(function()
    while true do
        render(g, gen)
        local k = readKey()
        if k then
            k = k:lower()
            if k=="q" then os.execute("stty echo icanon"); io.write("\nBye!\n"); os.exit(0)
            elseif k=="a" and sp < #SPEEDS then sp = sp+1
            elseif k=="z" and sp > 1 then sp = sp-1 end
        end
        g = step(g); gen = gen+1
        local t = os.clock() + SPEEDS[sp]
        while os.clock() < t do end
    end
end)
os.execute("stty echo icanon")
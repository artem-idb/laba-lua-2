-- Game of Life | lua life.lua [file.txt]
-- Файл: # живая, . мёртвая

local WIDTH  = 40
local HEIGHT = 20
local DELAY  = 0.1

local function sleep(sec)
    local t = os.clock() + sec
    while os.clock() < t do end
end

local function clear()
    io.write("\027[2J\027[H")
    io.flush()
end

local function newGrid()
    local g = {}
    for y = 1, HEIGHT do
        g[y] = {}
        for x = 1, WIDTH do g[y][x] = false end
    end
    return g
end

local function setCell(grid, x, y, v)
    if x >= 1 and x <= WIDTH and y >= 1 and y <= HEIGHT then
        grid[y][x] = (v ~= false)
    end
end

local function glider(grid, ox, oy)
    local cells = {{1,0},{2,1},{0,2},{1,2},{2,2}}
    for _, c in ipairs(cells) do setCell(grid, ox+c[1], oy+c[2], true) end
end

local function rpentomino(grid, ox, oy)
    local cells = {{1,0},{2,0},{0,1},{1,1},{1,2}}
    for _, c in ipairs(cells) do setCell(grid, ox+c[1], oy+c[2], true) end
end

local function blinker(grid, ox, oy)
    setCell(grid, ox, oy, true)
    setCell(grid, ox+1, oy, true)
    setCell(grid, ox+2, oy, true)
end

local function randomSeed(grid, density)
    density = density or 0.3
    math.randomseed(os.time())
    for y = 1, HEIGHT do
        for x = 1, WIDTH do
            grid[y][x] = math.random() < density
        end
    end
end

local function loadFile(filename)
    local f = io.open(filename)
    if not f then print("File not found: " .. filename); os.exit(1) end
    local rows, maxw = {}, 0
    for line in f:lines() do
        local row = {}
        for ch in line:gmatch(".") do row[#row+1] = (ch == "#") end
        rows[#rows+1] = row
        if #row > maxw then maxw = #row end
    end
    f:close()
    if maxw  > WIDTH  then WIDTH  = maxw  end
    if #rows > HEIGHT then HEIGHT = #rows end
    local grid = newGrid()
    local ox = math.floor((WIDTH  - maxw)  / 2)
    local oy = math.floor((HEIGHT - #rows) / 2)
    for ry, row in ipairs(rows) do
        for rx, alive in ipairs(row) do
            if alive then setCell(grid, rx+ox, ry+oy, true) end
        end
    end
    return grid
end

local function countNeighbours(grid, x, y)
    local n = 0
    for dy = -1, 1 do
        for dx = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local nx = ((x - 1 + dx) % WIDTH)  + 1
                local ny = ((y - 1 + dy) % HEIGHT) + 1
                if grid[ny][nx] then n = n + 1 end
            end
        end
    end
    return n
end

local function step(grid)
    local next = newGrid()
    for y = 1, HEIGHT do
        for x = 1, WIDTH do
            local n = countNeighbours(grid, x, y)
            if grid[y][x] then
                next[y][x] = (n == 2 or n == 3)
            else
                next[y][x] = (n == 3)
            end
        end
    end
    return next
end

local function render(grid, gen)
    local buf = {}
    buf[#buf+1] = string.format("  Game of Life  |  Gen: %d\n", gen)
    buf[#buf+1] = "  +" .. string.rep("-", WIDTH) .. "+\n"
    for y = 1, HEIGHT do
        buf[#buf+1] = "  |"
        for x = 1, WIDTH do
            buf[#buf+1] = grid[y][x] and "#" or "."
        end
        buf[#buf+1] = "|\n"
    end
    buf[#buf+1] = "  +" .. string.rep("-", WIDTH) .. "+\n"
    buf[#buf+1] = "  Ctrl+C to quit\n"
    io.write(table.concat(buf))
    io.flush()
end

-- init
local grid
if arg[1] then
    grid = loadFile(arg[1])
else
    grid = newGrid()
    glider(grid, 2, 2); glider(grid, 10, 5)
    rpentomino(grid, 20, 8)
    blinker(grid, 30, 3); blinker(grid, 35, 15)
    randomSeed(grid, 0.15)
end

local gen = 0
while true do
    clear()
    render(grid, gen)
    grid = step(grid)
    gen  = gen + 1
    sleep(DELAY)
end
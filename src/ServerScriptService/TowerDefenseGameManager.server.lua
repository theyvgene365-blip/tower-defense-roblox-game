--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║     TOWER DEFENSE - SERVER GAME MANAGER (ULTRA OPTIMIZED)     ║
    ║            Complete game logic, enemies, towers, waves         ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- ===== CONFIGURATION & SETUP =====
local STARTING_GOLD = 500
local STARTING_HEALTH = 100
local STARTING_WAVES = 10
local WAYPOINT_FOLDER_NAME = "PathData"
local TOWER_SPOTS_FOLDER_NAME = "TowerSpots"
local ENEMIES_FOLDER_NAME = "TD_Enemies"
local TOWERS_FOLDER_NAME = "TD_Towers"

-- ===== CREATE REQUIRED FOLDERS & SERVICES =====
local function setupGameFolders()
    -- Create ReplicatedStorage folders if not exist
    if not ReplicatedStorage:FindFirstChild("TD_Events") then
        local eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "TD_Events"
        eventsFolder.Parent = ReplicatedStorage
        
        local gameUpdate = Instance.new("RemoteEvent")
        gameUpdate.Name = "GameUpdate"
        gameUpdate.Parent = eventsFolder
        
        local startWave = Instance.new("RemoteEvent")
        startWave.Name = "StartWave"
        startWave.Parent = eventsFolder
        
        local placeTower = Instance.new("RemoteEvent")
        placeTower.Name = "PlaceTower"
        placeTower.Parent = eventsFolder
        
        local sellTower = Instance.new("RemoteEvent")
        sellTower.Name = "SellTower"
        sellTower.Parent = eventsFolder
        
        local towerPlaced = Instance.new("RemoteEvent")
        towerPlaced.Name = "TowerPlaced"
        towerPlaced.Parent = eventsFolder
        
        local enemySpawned = Instance.new("RemoteEvent")
        enemySpawned.Name = "EnemySpawned"
        enemySpawned.Parent = eventsFolder
    end
    
    if not ReplicatedStorage:FindFirstChild("TD_Config") then
        local configModule = Instance.new("ModuleScript")
        configModule.Name = "TD_Config"
        configModule.Parent = ReplicatedStorage
        configModule.Source = [[
local Config = {}

Config.StartingGold = 500
Config.StartingHealth = 100
Config.StartingWaves = 10

Config.Towers = {
    Basic = {
        name = "Basic Tower",
        icon = "🗼",
        cost = 100,
        sellValue = 50,
        damage = 10,
        fireRate = 1.5,
        range = 40,
        projectileSize = 0.5,
        projectileColor = Color3.fromRGB(255, 200, 100),
        splashRadius = 0,
    },
    Sniper = {
        name = "Sniper Tower",
        icon = "🎯",
        cost = 200,
        sellValue = 100,
        damage = 30,
        fireRate = 0.5,
        range = 70,
        projectileSize = 0.3,
        projectileColor = Color3.fromRGB(100, 200, 255),
        splashRadius = 0,
    },
    Splash = {
        name = "Splash Tower",
        icon = "💥",
        cost = 250,
        sellValue = 125,
        damage = 15,
        fireRate = 1,
        range = 50,
        projectileSize = 0.8,
        projectileColor = Color3.fromRGB(255, 100, 100),
        splashRadius = 15,
    },
    Frost = {
        name = "Frost Tower",
        icon = "❄️",
        cost = 180,
        sellValue = 90,
        damage = 5,
        fireRate = 2,
        range = 45,
        projectileSize = 0.4,
        projectileColor = Color3.fromRGB(100, 200, 255),
        splashRadius = 20,
    },
}

Config.Enemies = {
    Goblin = {
        name = "Goblin",
        icon = "👹",
        health = 20,
        speed = 15,
        damage = 10,
        reward = 25,
        size = 2,
    },
    Orc = {
        name = "Orc",
        icon = "💚",
        health = 50,
        speed = 10,
        damage = 20,
        reward = 50,
        size = 3,
    },
    Dragon = {
        name = "Dragon",
        icon = "🐉",
        health = 150,
        speed = 8,
        damage = 40,
        reward = 150,
        size = 4,
    },
    Skeleton = {
        name = "Skeleton",
        icon = "💀",
        health = 30,
        speed = 12,
        damage = 15,
        reward = 35,
        size = 2.5,
    },
}

Config.Waves = {
    {{"Goblin", 5, 0.5}, {"Goblin", 3, 0.5}},
    {{"Goblin", 8, 0.4}, {"Skeleton", 2, 1}},
    {{"Orc", 3, 1}, {"Goblin", 5, 0.3}},
    {{"Goblin", 10, 0.3}, {"Orc", 2, 1.5}},
    {{"Skeleton", 5, 0.8}, {"Goblin", 5, 0.4}},
    {{"Orc", 5, 0.8}, {"Skeleton", 3, 0.8}},
    {{"Goblin", 15, 0.2}, {"Orc", 3, 1}},
    {{"Dragon", 1, 2}, {"Orc", 5, 0.5}},
    {{"Dragon", 2, 1.5}, {"Skeleton", 8, 0.3}},
    {{"Dragon", 3, 1}, {"Orc", 8, 0.3}, {"Goblin", 10, 0.2}},
}

return Config
        ]]
    end
    
    if not ServerStorage:FindFirstChild(ENEMIES_FOLDER_NAME) then
        local enemiesFolder = Instance.new("Folder")
        enemiesFolder.Name = ENEMIES_FOLDER_NAME
        enemiesFolder.Parent = ServerStorage
    end
    
    if not ReplicatedStorage:FindFirstChild(TOWERS_FOLDER_NAME) then
        local towersFolder = Instance.new("Folder")
        towersFolder.Name = TOWERS_FOLDER_NAME
        towersFolder.Parent = ReplicatedStorage
    end
    
    if not Workspace:FindFirstChild(WAYPOINT_FOLDER_NAME) then
        local pathFolder = Instance.new("Folder")
        pathFolder.Name = WAYPOINT_FOLDER_NAME
        pathFolder.Parent = Workspace
        
        -- Create default waypoints
        for i = 1, 10 do
            local waypoint = Instance.new("Part")
            waypoint.Name = "Waypoint" .. i
            waypoint.Shape = Enum.PartType.Ball
            waypoint.Size = Vector3.new(1, 1, 1)
            waypoint.CanCollide = false
            waypoint.Transparency = 1
            waypoint.CFrame = CFrame.new(i * 10 - 50, 3, 0)
            waypoint.Parent = pathFolder
        end
    end
    
    if not Workspace:FindFirstChild(TOWER_SPOTS_FOLDER_NAME) then
        local spotsFolder = Instance.new("Folder")
        spotsFolder.Name = TOWER_SPOTS_FOLDER_NAME
        spotsFolder.Parent = Workspace
        
        -- Create default tower spots
        for x = 1, 3 do
            for z = 1, 3 do
                local spot = Instance.new("Part")
                spot.Name = "Spot_" .. x .. "_" .. z
                spot.Shape = Enum.PartType.Block
                spot.Size = Vector3.new(4, 0.5, 4)
                spot.Color = Color3.fromRGB(100, 200, 100)
                spot.Material = Enum.Material.Neon
                spot.CanCollide = false
                spot.TopSurface = Enum.SurfaceType.Smooth
                spot.BottomSurface = Enum.SurfaceType.Smooth
                spot.CFrame = CFrame.new(-30 + x * 15, 2, -20 + z * 15)
                spot.Parent = spotsFolder
                spot:SetAttribute("Occupied", false)
            end
        end
    end
end

-- ===== LOAD CONFIGURATION =====
setupGameFolders()
local Config = require(ReplicatedStorage:WaitForChild("TD_Config"))
local Events = ReplicatedStorage:WaitForChild("TD_Events")
local EnemiesFolder = ServerStorage:WaitForChild(ENEMIES_FOLDER_NAME)
local TowersFolder = ReplicatedStorage:WaitForChild(TOWERS_FOLDER_NAME)
local PathFolder = Workspace:WaitForChild(WAYPOINT_FOLDER_NAME)
local SpotsFolder = Workspace:WaitForChild(TOWER_SPOTS_FOLDER_NAME)

-- ===== CREATE ENEMY TEMPLATES =====
local function createEnemyTemplates()
    for enemyType, config in pairs(Config.Enemies) do
        if not EnemiesFolder:FindFirstChild(enemyType) then
            local model = Instance.new("Model")
            model.Name = enemyType
            
            local humanoidRootPart = Instance.new("Part")
            humanoidRootPart.Name = "HumanoidRootPart"
            humanoidRootPart.Shape = Enum.PartType.Ball
            humanoidRootPart.Size = Vector3.new(config.size, config.size, config.size)
            humanoidRootPart.CanCollide = true
            humanoidRootPart.Color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            humanoidRootPart.Material = Enum.Material.SmoothPlastic
            humanoidRootPart.TopSurface = Enum.SurfaceType.Smooth
            humanoidRootPart.BottomSurface = Enum.SurfaceType.Smooth
            humanoidRootPart.Parent = model
            
            local head = Instance.new("Part")
            head.Name = "Head"
            head.Shape = Enum.PartType.Ball
            head.Size = Vector3.new(config.size * 0.6, config.size * 0.6, config.size * 0.6)
            head.CanCollide = true
            head.Color = Color3.fromRGB(200, 100, 100)
            head.Material = Enum.Material.SmoothPlastic
            head.TopSurface = Enum.SurfaceType.Smooth
            head.BottomSurface = Enum.SurfaceType.Smooth
            head.Parent = model
            
            local bodyGyro = Instance.new("BodyGyro")
            bodyGyro.Parent = humanoidRootPart
            
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = humanoidRootPart
            weld.Part1 = head
            weld.Parent = head
            
            local humanoid = Instance.new("Humanoid")
            humanoid.Parent = model
            humanoid.MaxHealth = config.health
            humanoid.Health = config.health
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "HealthLabel"
            textLabel.Size = UDim2.new(4, 0, 1, 0)
            textLabel.BackgroundTransparency = 0.5
            textLabel.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextSize = 12
            textLabel.Text = config.health .. " HP"
            textLabel.Parent = humanoidRootPart
            
            local billboardGui = Instance.new("BillboardGui")
            billboardGui.Size = UDim2.new(0, 50, 0, 20)
            billboardGui.MaxDistance = 100
            billboardGui.Adornee = humanoidRootPart
            textLabel.Parent = billboardGui
            billboardGui.Parent = humanoidRootPart
            
            model:SetAttribute("EnemyType", enemyType)
            model:SetAttribute("EnemyHealth", config.health)
            model.Parent = EnemiesFolder
        end
    end
end

-- ===== CREATE TOWER TEMPLATES =====
local function createTowerTemplates()
    for towerType, config in pairs(Config.Towers) do
        if not TowersFolder:FindFirstChild(towerType) then
            local model = Instance.new("Model")
            model.Name = towerType
            
            local base = Instance.new("Part")
            base.Name = "Base"
            base.Shape = Enum.PartType.Block
            base.Size = Vector3.new(2, 0.5, 2)
            base.CanCollide = false
            base.Color = Color3.fromRGB(100, 100, 100)
            base.Material = Enum.Material.Concrete
            base.TopSurface = Enum.SurfaceType.Smooth
            base.BottomSurface = Enum.SurfaceType.Smooth
            base.Parent = model
            
            local body = Instance.new("Part")
            body.Name = "Body"
            body.Shape = Enum.PartType.Block
            body.Size = Vector3.new(1.5, 2, 1.5)
            body.CanCollide = false
            body.Color = Color3.fromRGB(150, 150, 200)
            body.Material = Enum.Material.SmoothPlastic
            body.TopSurface = Enum.SurfaceType.Smooth
            body.BottomSurface = Enum.SurfaceType.Smooth
            body.Parent = model
            
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = base
            weld.Part1 = body
            weld.Parent = body
            
            local top = Instance.new("Part")
            top.Name = "Top"
            top.Shape = Enum.PartType.Cylinder
            top.Size = Vector3.new(1, 0.8, 1)
            top.CanCollide = false
            top.Color = Color3.fromRGB(200, 150, 100)
            top.Material = Enum.Material.SmoothPlastic
            top.Orientation = Vector3.new(0, 0, 90)
            top.Parent = model
            
            local weld2 = Instance.new("WeldConstraint")
            weld2.Part0 = body
            weld2.Part1 = top
            weld2.Parent = top
            
            model.PrimaryPart = base
            model:SetAttribute("TowerType", towerType)
            model.Parent = TowersFolder
        end
    end
end

-- ===== GAME STATE =====
local gameState = {
    gold = STARTING_GOLD,
    health = STARTING_HEALTH,
    maxHealth = STARTING_HEALTH,
    wave = 0,
    waveInProgress = false,
    enemiesAlive = 0,
    gameOver = false,
    gameWon = false,
    totalWaves = STARTING_WAVES,
    kills = 0,
    goldEarned = 0,
    damageToBase = 0,
}

-- ===== READ WAYPOINTS =====
local function getWaypoints()
    local points = {}
    for i = 1, 100 do
        local wp = PathFolder:FindFirstChild("Waypoint" .. i)
        if not wp then break end
        table.insert(points, wp.Position)
    end
    return points
end

local waypoints = getWaypoints()

-- ===== ACTIVE GAME OBJECTS =====
local activeEnemies = {}
local activeTowers = {}
local waveEnemyCount = 0

-- ===== UTILITY FUNCTIONS =====
local function broadcastGameState()
    Events.GameUpdate:FireAllClients({
        gold = gameState.gold,
        health = gameState.health,
        maxHealth = gameState.maxHealth,
        wave = gameState.wave,
        totalWaves = gameState.totalWaves,
        waveInProgress = gameState.waveInProgress,
        enemiesAlive = gameState.enemiesAlive,
        gameOver = gameState.gameOver,
        gameWon = gameState.gameWon,
        kills = gameState.kills,
        goldEarned = gameState.goldEarned,
    })
end

local function playEffect(position, effectType)
    local part = Instance.new("Part")
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(0.5, 0.5, 0.5)
    part.Position = position
    part.CanCollide = false
    part.Color = Color3.fromRGB(255, 200, 100)
    part.Material = Enum.Material.Neon
    
    local light = Instance.new("PointLight")
    light.Brightness = 3
    light.Range = 15
    light.Color = Color3.fromRGB(255, 200, 100)
    light.Parent = part
    
    part.Parent = Workspace
    
    TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(2, 2, 2),
        Transparency = 1,
    }):Play()
    
    game:GetService("Debris"):AddItem(part, 0.5)
end

-- ===== ENEMY SPAWNING & MOVEMENT =====
local function spawnEnemy(enemyType)
    local template = EnemiesFolder:FindFirstChild(enemyType)
    if not template then return end
    
    local config = Config.Enemies[enemyType]
    if not config then return end
    
    local enemy = template:Clone()
    enemy:SetPrimaryPartCFrame(CFrame.new(waypoints[1]))
    enemy.Parent = Workspace
    
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = config.health
        humanoid.Health = config.health
    end
    
    local rootPart = enemy:FindFirstChild("HumanoidRootPart")
    
    local enemyData = {
        model = enemy,
        humanoid = humanoid,
        config = config,
        rootPart = rootPart,
        currentWaypoint = 2,
        speed = config.speed,
        type = enemyType,
        alive = true,
    }
    
    table.insert(activeEnemies, enemyData)
    gameState.enemiesAlive = gameState.enemiesAlive + 1
    broadcastGameState()
    
    -- Enemy death handler
    if humanoid then
        humanoid.Died:Connect(function()
            if enemyData.alive then
                enemyData.alive = false
                gameState.gold = gameState.gold + config.reward
                gameState.goldEarned = gameState.goldEarned + config.reward
                gameState.kills = gameState.kills + 1
                gameState.enemiesAlive = gameState.enemiesAlive - 1
                
                playEffect(rootPart.Position, "death")
                
                task.delay(0.1, function()
                    if enemy and enemy.Parent then
                        enemy:Destroy()
                    end
                end)
                
                broadcastGameState()
            end
        end)
    end
    
    return enemyData
end

local function moveEnemy(enemyData, dt)
    if not enemyData or not enemyData.model or not enemyData.model.Parent then
        return false
    end
    
    local rootPart = enemyData.rootPart
    if not rootPart then return false end
    
    local humanoid = enemyData.humanoid
    if humanoid and humanoid.Health <= 0 then
        return false
    end
    
    if enemyData.currentWaypoint > #waypoints then
        if enemyData.alive then
            enemyData.alive = false
            gameState.health = math.max(0, gameState.health - enemyData.config.damage)
            gameState.damageToBase = gameState.damageToBase + enemyData.config.damage
            gameState.enemiesAlive = gameState.enemiesAlive - 1
            
            if enemyData.model and enemyData.model.Parent then
                enemyData.model:Destroy()
            end
            
            broadcastGameState()
            
            if gameState.health <= 0 then
                gameState.gameOver = true
                gameState.gameWon = false
                broadcastGameState()
            end
        end
        return false
    end
    
    local targetPos = waypoints[enemyData.currentWaypoint]
    if not targetPos then return false end
    
    local direction = (targetPos - rootPart.Position)
    local distance = direction.Magnitude
    
    if distance < 2 then
        enemyData.currentWaypoint = enemyData.currentWaypoint + 1
        return moveEnemy(enemyData, dt)
    end
    
    local moveAmount = enemyData.speed * dt
    if moveAmount > distance then
        moveAmount = distance
    end
    
    local moveDir = direction.Unit
    local newPos = rootPart.Position + moveDir * moveAmount
    
    rootPart.CFrame = CFrame.lookAt(newPos, newPos + moveDir)
    
    return true
end

-- ===== WAVE MANAGEMENT =====
local function startWave()
    if gameState.waveInProgress or gameState.gameOver then return end
    
    gameState.wave = gameState.wave + 1
    local waveDef = Config.Waves[gameState.wave]
    
    if not waveDef then
        gameState.gameOver = true
        gameState.gameWon = true
        broadcastGameState()
        return
    end
    
    gameState.waveInProgress = true
    broadcastGameState()
    
    task.spawn(function()
        for _, group in ipairs(waveDef) do
            local enemyType, count, delay = group[1], group[2], group[3]
            for i = 1, count do
                if gameState.gameOver then return end
                spawnEnemy(enemyType)
                task.wait(delay or 0.5)
            end
        end
    end)
end

local function checkWaveComplete()
    if gameState.waveInProgress and gameState.enemiesAlive == 0 then
        gameState.waveInProgress = false
        local bonus = 50 + (gameState.wave * 10)
        gameState.gold = gameState.gold + bonus
        gameState.goldEarned = gameState.goldEarned + bonus
        broadcastGameState()
    end
end

-- ===== TOWER PLACEMENT & FIRING =====
local function placeTower(player, towerType, spotName)
    if gameState.gameOver then return end
    
    local config = Config.Towers[towerType]
    if not config then return end
    
    if activeTowers[spotName] then return end
    if gameState.gold < config.cost then return end
    
    local spot = SpotsFolder:FindFirstChild(spotName)
    if not spot then return end
    
    gameState.gold = gameState.gold - config.cost
    
    local template = TowersFolder:FindFirstChild(towerType)
    if not template then return end
    
    local tower = template:Clone()
    tower:SetPrimaryPartCFrame(CFrame.new(spot.Position + Vector3.new(0, 2, 0)))
    tower.Parent = Workspace
    
    spot:SetAttribute("Occupied", true)
    
    local towerData = {
        model = tower,
        config = config,
        spot = spot,
        spotName = spotName,
        fireTimer = 0,
        towerType = towerType,
    }
    
    activeTowers[spotName] = towerData
    broadcastGameState()
    Events.TowerPlaced:FireAllClients(spotName, towerType)
end

local function sellTower(player, spotName)
    local towerData = activeTowers[spotName]
    if not towerData then return end
    
    gameState.gold = gameState.gold + towerData.config.sellValue
    
    if towerData.model and towerData.model.Parent then
        towerData.model:Destroy()
    end
    
    towerData.spot:SetAttribute("Occupied", false)
    activeTowers[spotName] = nil
    broadcastGameState()
end

local function fireTower(towerData)
    if not towerData or not towerData.model or not towerData.model.Parent then return end
    
    local towerPos = towerData.model:GetPrimaryPartCFrame().Position
    local nearestEnemy = nil
    local nearestDist = math.huge
    
    for _, enemyData in ipairs(activeEnemies) do
        if enemyData.model and enemyData.model.Parent and enemyData.alive then
            local rootPart = enemyData.rootPart
            if rootPart then
                local dist = (rootPart.Position - towerPos).Magnitude
                if dist <= towerData.config.range and dist < nearestDist then
                    nearestDist = dist
                    nearestEnemy = enemyData
                end
            end
        end
    end
    
    if not nearestEnemy then return end
    
    local targetPos = nearestEnemy.rootPart.Position
    
    -- Create projectile
    local projectile = Instance.new("Part")
    projectile.Shape = Enum.PartType.Ball
    projectile.Size = Vector3.new(
        towerData.config.projectileSize,
        towerData.config.projectileSize,
        towerData.config.projectileSize
    )
    projectile.Position = towerPos + Vector3.new(0, 2, 0)
    projectile.CanCollide = false
    projectile.Color = towerData.config.projectileColor
    projectile.Material = Enum.Material.Neon
    projectile.Velocity = (targetPos - projectile.Position).Unit * 100
    
    local light = Instance.new("PointLight")
    light.Color = towerData.config.projectileColor
    light.Brightness = 2
    light.Range = 10
    light.Parent = projectile
    
    projectile.Parent = Workspace
    
    task.spawn(function()
        task.wait(2)
        if projectile and projectile.Parent then
            projectile:Destroy()
        end
    end)
    
    local touched = false
    local connection
    connection = projectile.Touched:Connect(function(hit)
        if touched or not hit.Parent then return end
        
        for _, enemyData in ipairs(activeEnemies) do
            if enemyData.model and hit:IsDescendantOf(enemyData.model) then
                touched = true
                connection:Disconnect()
                
                playEffect(hit.Position, "hit")
                
                if enemyData.humanoid and enemyData.humanoid.Health > 0 then
                    enemyData.humanoid:TakeDamage(towerData.config.damage)
                    
                    -- Splash damage
                    if towerData.config.splashRadius > 0 then
                        for _, otherEnemy in ipairs(activeEnemies) do
                            if otherEnemy ~= enemyData and otherEnemy.model and otherEnemy.model.Parent then
                                local dist = (otherEnemy.rootPart.Position - hit.Position).Magnitude
                                if dist <= towerData.config.splashRadius then
                                    if otherEnemy.humanoid and otherEnemy.humanoid.Health > 0 then
                                        otherEnemy.humanoid:TakeDamage(towerData.config.damage * 0.5)
                                    end
                                end
                            end
                        end
                    end
                end
                
                if projectile and projectile.Parent then
                    projectile:Destroy()
                end
                
                break
            end
        end
    end)
end

-- ===== EVENT HANDLERS =====
Events.StartWave.OnServerEvent:Connect(function(player)
    startWave()
end)

Events.PlaceTower.OnServerEvent:Connect(function(player, towerType, spotName)
    placeTower(player, towerType, spotName)
end)

Events.SellTower.OnServerEvent:Connect(function(player, spotName)
    sellTower(player, spotName)
end)

-- ===== MAIN GAME LOOP =====
createEnemyTemplates()
createTowerTemplates()
broadcastGameState()

task.spawn(function()
    local lastTime = os.clock()
    while true do
        task.wait(0.03)
        
        local now = os.clock()
        local dt = now - lastTime
        lastTime = now
        
        if not gameState.gameOver then
            -- Move enemies
            for i = #activeEnemies, 1, -1 do
                local enemyData = activeEnemies[i]
                if not moveEnemy(enemyData, dt) then
                    table.remove(activeEnemies, i)
                end
            end
            
            -- Tower firing
            for spotName, towerData in pairs(activeTowers) do
                towerData.fireTimer = towerData.fireTimer - dt
                if towerData.fireTimer <= 0 then
                    fireTower(towerData)
                    towerData.fireTimer = 1 / towerData.config.fireRate
                end
            end
            
            checkWaveComplete()
        end
    end
end)

print("[Tower Defense] ✅ Server initialized successfully!")

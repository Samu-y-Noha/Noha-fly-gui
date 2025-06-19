--]

-- ========== DEPENDENCIAS Y ALIAS ==========
local _G_Lua = game
local Services = {
    Players = _G_Lua:GetService("Players"),
    Workspace = _G_Lua:GetService("Workspace"),
    RunService = _G_Lua:GetService("RunService"),
    Task = _G_Lua:GetService("task"),
    UserInputService = _G_Lua:GetService("UserInputService"),
    HttpService = _G_Lua:GetService("HttpService"),
    ReplicatedStorage = _G_Lua:GetService("ReplicatedStorage"), -- Añadido de tu script
    TweenService = _G_Lua:GetService("TweenService"), -- Añadido de tu script
}
local Math = math
local Vec3 = Vector3.new
local CFrameUtil = CFrame.new
local StrManip = string
local TableUtil = table
local InstCreate = Instance.new
local ColorFactory = Color3.fromRGB
local UdimFactory = UDim2.new
local Ck = tick

-- ========== REFERENCIAS CLAVE (Ahora con un sistema de revalidación más inteligente) ==========
local LocalPlayer = Services.Players.LocalPlayer
local PlayerChar = nil -- Inicializado a nil, se revalida en el bucle
local PlayerHum = nil
local PlayerRoot = nil

-- Función para revalidar las referencias del jugador de forma eficiente
local function RevalidatePlayerReferences()
    -- Solo intentar revalidar si LocalPlayer.Character existe y es válido
    if not LocalPlayer.Character or not LocalPlayer.Character.Parent then
        PlayerChar = nil
        PlayerHum = nil
        PlayerRoot = nil
        return false
    end
    -- Si la referencia del personaje ha cambiado (ej. respawn) o es nula
    if PlayerChar ~= LocalPlayer.Character then
        PlayerChar = LocalPlayer.Character
        PlayerHum = PlayerChar:FindFirstChild("Humanoid")
        PlayerRoot = PlayerChar:FindFirstChild("HumanoidRootPart")
        if PlayerHum and PlayerRoot then
            LogShadowActivity("Referencias del jugador restablecidas.")
        else
            -- Si no se encuentran Hum/Root después de CharacterLoaded, invalidar Char
            PlayerChar = nil
            return false
        end
    end
    -- Asegurarse de que el humanoide esté vivo
    return PlayerChar and PlayerHum and PlayerRoot and PlayerHum.Health > 0
end

-- ========== ESTADO COGNITIVO UNIFICADO ==========
local ShadowState = {
    BallRef = nil, BallKineticTrace = {}, TargetRef = nil, TargetKineticTrace = {},
    GameActive = false, ParryLock = false,
    LastParryExecutionTime = 0,
    LastInputAttemptTime = 0,
    ObservationLevel = 0, -- 0-1
    EventLogBuffer = {}, LastRecordedAction = "Inicialización",
    Mode = "Normal", -- "Normal" o "Turbo" (asistencia máxima)
    AssistEnabled = true, -- Puede togglearse vía GUI
    TurboKeyDown = false,
    HumanOverride = false,

    -- MIMETISMO AVANZADO:
    MimesisActive = false,
    MimesisTarget = nil,
    MimesisMovementHistory = {}, -- Almacena historial de Pos/Vel/Acel del target
    MimesisBehaviorProfile = {}, -- Almacena promedios de reacción/precisión aprendidos
    CurrentMimesisPlaybackProfile = nil, -- El perfil de comportamiento que se está "curando"
    MimesisLearningMode = false, -- Si está activamente aprendiendo un perfil
    LastMimesisObservation = 0, -- Último tick que observó para mimetismo
    MimesisProfileNames = {}, -- Nombres de perfiles de mimetismo guardados
    LastGameActiveChangeTime = Ck(), -- Para lógica de calentamiento
    BreathingCycleTime = 0,

    -- CONTRATAQUE ESTRATÉGICO
    LastTargetPosition = Vec3(0,0,0), -- Para detectar cambio de posición del target
    TargetQuadrantHistory = {}, -- Para mimetismo de estrategia de ataque

    -- Añadidos de tu script
    dynamicAssistanceEnabled = true,
    espEnabled = true,
}

-- ========== PROTOCOLOS DE COMPORTAMIENTO UNIFICADOS ==========
local ShadowProtocols = {
    PerceptionRange = 10.2, -- Rango para activar asistencia
    AnticipationWindow = 0.014, -- Tiempo de predicción de bola
    MinReaction = 0.048, MaxReaction = 0.12,
    PrecisionNoiseAmplitude = 0.019, JitterMagnitude = 0.003,
    TurboBoost = 0.5, -- Multiplicador de delay en modo turbo (0.5 = 50% de delay)
    DeliberateMissChance = 0.004, -- Falla intencional (más alto si hay observación)
    TargetingLogic = "AuraPredictive", -- "HumanSmart", "Random", "AuraPredictive", "EvadePredict" (Aura/Evade son más avanzados)
    TurboKey = Enum.KeyCode.LeftShift, -- Cambia a Turbo manteniendo Shift

    -- PROTOCOLOS PARA EVASIÓN DE IA (de 6.8)
    HumanLatencyVarianceMin = 0.005, -- Varianza mínima de latencia simulada
    HumanLatencyVarianceMax = 0.020, -- Varianza máxima de latencia simulada
    WarmupDuration = 10,            -- Duración del "calentamiento" en segundos
    ObservationPenaltyFactor = 0.3, -- Factor de penalización por observación (para aumentar varianza)
    MinPlayerMovementSignature = 0.055, -- Mínima velocidad para considerar al jugador moviéndose (antes HumanOverrideCheck)
    ChaosEvolutionSpeed = 0.19, -- Para efecto visual de caos

    -- PROTOCOLOS PARA CONTRATAQUE (de 6.9)
    BallForceVariance = 0.15,     -- % de variación en la fuerza de la bola (ej. 0.15 = +/- 15%)
    StrategicTargetingBias = 0.3, -- Cuanto más se prioriza una zona "débil" (0-1)
    QuadrantLearningRate = 0.05,  -- Tasa de aprendizaje de cuadrantes de ataque
    TargetEvadePredictionStrength = 0.5, -- Fuerza de la predicción de evasión del target
    AuraDeviationMagnitude = 2.3, -- Magnitud de la desviación del aura (para "AuraPredictive")
    TargetLookAhead = 0.09, -- Tiempo de anticipación del target (para "AuraPredictive", "EvadePredict")

    -- MIMETISMO AVANZADO (de 6.9, 6.8)
    MimesisObservationInterval = 0.13,
    MimesisMovementHistoryDepth = 32,
    MimesisMinCopyDistance = 1.6,
    MimesisBehaviorLearningRate = 0.01,
    MimesisPlaybackInfluence = 0.7,
    MimesisTargetAcquisitionRange = 25,
    IdleMovementActive = true,
    EnvironmentalSenseRadius = 3.4,
    AdaptationLearningRate = 0.0007,

    -- Añadidos de tu script
    ParryCooldown = 0.5, -- Cooldown para parry
    BaseMovementSpeed = 16, -- Velocidad base del jugador (Roblox default)
    DynamicSpeedMultiplier = 1.2, -- Multiplicador para asistencia dinámica
    BaseJumpPower = 50, -- Poder de salto base
    BallReturnForceScale = 1.0, -- Añadido: Escala de fuerza de retorno de la bola (ajustable)
}

local GUISettings = {
    Skin = "Neon",
    EnableLogs = true,
    CurrentProfile = "Default",
    GUITransparency = 0.65,
    FadeGUIWhenObserved = true,
    DisplayPing = true,
}
local GUISkins = {
    Plasma = {
        bg=function() return ColorFactory(26,20,38) end,
        border=function() return ColorFactory(200,60,255) end,
        text=function() return ColorFactory(220,200,255) end,
    },
    Blade = {
        bg=function() return Color3.fromHSV((Math.fmod(Ck()*0.12,1)), 0.7, 0.72) end,
        border=function() return Color3.fromHSV((Math.fmod(Ck()*0.18+0.33,1)),0.7,1) end,
        text=function() return ColorFactory(255,240,240) end,
    },
    Neon = {
        bg=function() local t=Ck()*0.4; return Color3.fromHSV((Math.sin(t)+1)/2,0.7,1) end,
        border=function() local t=Ck()*0.8; return Color3.fromHSV((Math.sin(t+2.1)+1)/2,0.7,1) end,
        text=function() return ColorFactory(200,255,255) end,
    },
    Matrix = {
        bg=function() local t=Ck()*0.31; return Color3.fromHSV(0.33,0.8,Math.abs(Math.sin(t))) end,
        border=function() return Color3.fromHSV(0.33,1,1) end,
        text=function() return ColorFactory(190,255,190) end
    }
}
local UserProfiles = {}
local ToggleButtons = {} -- Para mantener referencia a los botones de toggle de la GUI

-- ========== LOGGING Y UTILIDADES DE PERFILES ==========
local function LogShadowActivity(msg,...)
    local formattedMsg = StrManip.format(msg,...)
    TableUtil.insert(ShadowState.EventLogBuffer, 1, formattedMsg)
    if #ShadowState.EventLogBuffer > 16 then TableUtil.remove(ShadowState.EventLogBuffer, #ShadowState.EventLogBuffer) end
    ShadowState.LastRecordedAction = formattedMsg
    if GUISettings.EnableLogs then print(" ".. formattedMsg) end
end

local function SaveMainProfile(name)
    UserProfiles[name] = {}
    for k,v in pairs(GUISettings) do if type(v)~="function" then UserProfiles[name][k]=v end end
    for k,v in pairs(ShadowProtocols) do UserProfiles[name][k]=v end
    for k,v in pairs(ShadowState) do -- Guardar también los toggles de ShadowState
        if type(v) == "boolean" then UserProfiles[name][k]=v end
    end
    GUISettings.CurrentProfile = name
    LogShadowActivity("Perfil principal '%s' guardado.", name)
end

local function LoadMainProfile(name)
    if UserProfiles[name] then
        for k,v in pairs(UserProfiles[name]) do
            if ShadowProtocols[k] ~= nil then ShadowProtocols[k] = v
            elseif GUISettings[k] ~= nil then GUISettings[k] = v
            elseif ShadowState[k] ~= nil and type(ShadowState[k]) == "boolean" then ShadowState[k] = v end -- Cargar toggles de ShadowState
        end
        GUISettings.CurrentProfile = name
        LogShadowActivity("Perfil principal '%s' cargado.", name)
    else LogShadowActivity("Error: Perfil principal '%s' no encontrado.", name) end
end

local function ExportMainProfile()
    local exportData = {}
    for k,v in pairs(GUISettings) do if type(v)~="function" then exportData[k]=v end end
    for k,v in pairs(ShadowProtocols) do exportData[k]=v end
    for k,v in pairs(ShadowState) do if type(v) == "boolean" then exportData[k]=v end end
    local success, encoded = pcall(Services.HttpService.JSONEncode, Services.HttpService, exportData)
    if success then
        _G_Lua.setclipboard(encoded) -- Asumimos que setclipboard está disponible globalmente
        LogShadowActivity("Perfil principal exportado al portapapeles.")
    else
        LogShadowActivity("Error al exportar perfil: %s", encoded)
    end
end

local function ImportMainProfile()
    local clipboardContent = ""; local success, result = pcall(_G_Lua.getclipboard) -- Asumimos getclipboard global
    if success then clipboardContent = result or "" end
    if #clipboardContent > 0 then
        local decodeSuccess, decodedData = pcall(Services.HttpService.JSONDecode, Services.HttpService, clipboardContent)
        if decodeSuccess and type(decodedData) == "table" then
            for k,v in pairs(decodedData) do
                if ShadowProtocols[k] ~= nil then ShadowProtocols[k]=v
                elseif GUISettings[k] ~= nil then GUISettings[k]=v
                elseif ShadowState[k] ~= nil and type(ShadowState[k]) == "boolean" then ShadowState[k] = v end
            end
            LogShadowActivity("Perfil principal importado correctamente.")
        else LogShadowActivity("Error al importar perfil: Datos inválidos.") end
    else LogShadowActivity("El portapapeles está vacío o inaccesible.") end
end

-- Funciones para guardar/cargar/limpiar perfiles de mimetismo (si se implementan)
local function SaveMimesisProfile(name)
    -- Implementación futura si se desea guardar perfiles de comportamiento mimetizado
    LogShadowActivity("Guardar patrón de mimetismo no implementado aún.")
end

local function LoadMimesisProfile(name)
    -- Implementación futura si se desea cargar perfiles de comportamiento mimetizado
    LogShadowActivity("Cargar patrón de mimetismo no implementado aún.")
end

local function ClearMimesisHistory()
    TableUtil.clear(ShadowState.MimesisMovementHistory)
    TableUtil.clear(ShadowState.TargetQuadrantHistory)
    LogShadowActivity("Historial de mimetismo limpiado.")
end

-- ========== MIMETISMO: APRENDIZAJE Y REPLICACIÓN ==========
local function FindMimesisTarget()
    local bestTarget, bestScore = nil, -1
    for _,pl in ipairs(Services.Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character:FindFirstChild("Humanoid").Health > 0 then
            local root = pl.Character.HumanoidRootPart
            local dist = (PlayerRoot.Position - root.Position).Magnitude
            local currentVelMag = root.AssemblyLinearVelocity.Magnitude
            if dist < ShadowProtocols.MimesisTargetAcquisitionRange and currentVelMag > 0.5 then
                local score = (currentVelMag / 8) / (dist + 1)
                if score > bestScore then bestScore = score; bestTarget=root end
            end
        end
    end
    return bestTarget
end

local function MimesisObservationTick()
    if not ShadowState.MimesisActive or not ShadowState.MimesisLearningMode then return end
    local target = ShadowState.MimesisTarget
    if not target or not target.Parent or not target.Parent:FindFirstChild("Humanoid") or target.Parent.Humanoid.Health <= 0 then
        target = FindMimesisTarget()
        ShadowState.MimesisTarget = target
        if target then LogShadowActivity("Mimesis: Nuevo objetivo %s para observación.", target.Parent.Name) end
        return
    end
    local targetHumanoid = target.Parent:FindFirstChild("Humanoid")
    local currentObservation = {
        Time = Ck(),
        Pos = target.Position,
        Vel = target.AssemblyLinearVelocity or Vec3(0,0,0),
        MoveDirection = targetHumanoid.MoveDirection or Vec3(0,0,0),
    }
    TableUtil.insert(ShadowState.MimesisMovementHistory, 1, currentObservation)
    if #ShadowState.MimesisMovementHistory > ShadowProtocols.MimesisMovementHistoryDepth then
        TableUtil.remove(ShadowState.MimesisMovementHistory, #ShadowState.MimesisMovementHistory)
    end

    -- Aprender patrones de contraataque (cuadrantes)
    local targetCurrentPos = target.Position
    local playerToTargetVector = (targetCurrentPos - PlayerRoot.Position).Unit
    -- Simplificado para cuadrantes básicos (ej. x>0, z>0)
    local targetRelativeX = playerToTargetVector.X > 0 and 1 or -1
    local targetRelativeZ = playerToTargetVector.Z > 0 and 1 or -1
    local quadrantKey = targetRelativeX.. ",".. targetRelativeZ

    ShadowState.TargetQuadrantHistory[quadrantKey] = (ShadowState.TargetQuadrantHistory[quadrantKey] or 0) + ShadowProtocols.QuadrantLearningRate
    -- Normalizar y decaer los pesos de los cuadrantes
    local totalWeight = 0
    for _, weight in pairs(ShadowState.TargetQuadrantHistory) do
        totalWeight = totalWeight + weight
    end
    for key, weight in pairs(ShadowState.TargetQuadrantHistory) do
        ShadowState.TargetQuadrantHistory[key] = weight * 0.99 -- Decadencia lenta
        if totalWeight > 0 then ShadowState.TargetQuadrantHistory[key] = ShadowState.TargetQuadrantHistory[key] / totalWeight end -- Normalizar
    end
end

local function ApplyMimesisMovement(targetRootPart)
    if not ShadowState.MimesisActive or #ShadowState.MimesisMovementHistory == 0 then return end
    local randomHistoryPoint = ShadowState.MimesisMovementHistory -- Seleccionar un punto aleatorio
    if randomHistoryPoint then
        local targetPos = randomHistoryPoint.Pos
        local myPos = PlayerRoot.Position
        local delta = (targetPos - myPos)
        if delta.Magnitude > ShadowProtocols.MimesisMinCopyDistance and not ShadowState.HumanOverride then
            local moveVector = delta.Unit * (delta.Magnitude * ShadowProtocols.MimesisPlaybackInfluence) -- Usar Influence
            PlayerRoot.CFrame = PlayerRoot.CFrame + CFrameUtil(moveVector)
            -- Añadir un pequeño jitter al movimiento mimetizado
            PlayerRoot.CFrame = PlayerRoot.CFrame * CFrameUtil(Vec3(Math.random(-1,1), Math.random(-1,1), Math.random(-1,1)) * ShadowProtocols.JitterMagnitude * (1 + ShadowState.ObservationLevel))
            LogShadowActivity("Mimesis: Replicando movimiento aprendido con jitter.")
        end
    end
end

-- ========== SENSORIAL Y NÚCLEO PRINCIPAL ==========
local function UpdateKineticTrace(obj, historyTable)
    if not obj or not obj.Parent or not obj:IsA("BasePart") then return end
    local currentPos = obj.Position
    local currentVel = obj.AssemblyLinearVelocity or Vec3(0,0,0)
    local currentTime = Ck()
    local lastEntry = historyTable[3]
    local currentAccel = Vec3(0,0,0)
    if lastEntry and (currentTime - lastEntry.Time) > 0.001 then
        currentAccel = (currentVel - lastEntry.Vel) / (currentTime - lastEntry.Time)
    end
    local smoothedVel = currentVel
    if lastEntry and (currentVel - lastEntry.Vel).Magnitude > 50 then
        smoothedVel = smoothedVel:Lerp(lastEntry.Vel, 0.5)
    end
    TableUtil.insert(historyTable, 1, {Pos = currentPos, Vel = smoothedVel, Accel = currentAccel, Time = currentTime})
    if #historyTable > 30 then -- Profundidad del KineticTrace
        TableUtil.remove(historyTable, #historyTable)
    end
end

local function PredictTrajectory(history, futureTime)
    if #history < 2 then return nil end
    -- CORRECCIÓN: Cambiado history.[3]Pos a history.[3]Pos (y similar para otros)
    local p1 = history.[3]Pos; local v1 = history.[3]Vel; local a1 = history.[3]Accel; local t1 = history.[3]Time
    local p2 = history.[4]Pos; local v2 = history.[4]Vel; local a2 = history.[4]Accel; local t2 = history.[4]Time
    local interpolatedAccel = a1:Lerp(a2, (Ck() - t1) / (t2 - t1 + 0.001))
    return p1 + (v1 * futureTime) + (0.5 * interpolatedAccel * futureTime^2)
end

local MouseClickFunction = nil
-- Variable para almacenar la referencia del RemoteEvent de parry encontrado
local ParryRemoteEvent = nil

-- Función para buscar el RemoteEvent de parry dinámicamente
local function FindParryRemoteEvent()
    -- Nombres comunes o patrones que podría tener el RemoteEvent de parry
    local potentialNames = {"ParryEvent", "SwingRemote", "BladeBallParry", "CombatEvent", "InputEvent", "ActionRemote"}
    local foundEvent = nil

    -- Buscar en ReplicatedStorage
    for _, child in ipairs(Services.ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteEvent") then
            for _, namePattern in ipairs(potentialNames) do
                if StrManip.find(child.Name, namePattern, 1, true) then -- Búsqueda exacta o parcial
                    foundEvent = child
                    LogShadowActivity("RemoteEvent de Parry encontrado en ReplicatedStorage: %s", foundEvent.Name)
                    return foundEvent
                end
            end
        end
    end

    -- Buscar en la herramienta del jugador (si existe y tiene una)
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        for _, child in ipairs(tool:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                for _, namePattern in ipairs(potentialNames) do
                    if StrManip.find(child.Name, namePattern, 1, true) then
                        foundEvent = child
                        LogShadowActivity("RemoteEvent de Parry encontrado en la herramienta: %s", foundEvent.Name)
                        return foundEvent
                    end
                end
            end
        end
    end

    return nil
end

Services.RunService.Heartbeat:Connect(function()
    if MouseClickFunction == nil then
        local mouse = LocalPlayer:GetMouse()
        if mouse and typeof(mouse.Click) == "function" then
            MouseClickFunction = function() mouse:Click() end
            LogShadowActivity("Método de clic: Mouse.Click (preferido).")
        elseif _G_Lua.mouse1click and typeof(_G_Lua.mouse1click) == "function" then
            MouseClickFunction = _G_Lua.mouse1click
            LogShadowActivity("Método de clic: _G_Lua.mouse1click.")
        else
            -- Intentar encontrar el RemoteEvent dinámicamente
            if not ParryRemoteEvent then
                ParryRemoteEvent = FindParryRemoteEvent()
            end

            if ParryRemoteEvent and ParryRemoteEvent:IsA("RemoteEvent") then
                MouseClickFunction = function() ParryRemoteEvent:FireServer() end
                LogShadowActivity("Método de clic: RemoteEvent dinámico (%s).", ParryRemoteEvent.Name)
            else
                -- Último recurso: Simular pulsación de tecla (si el juego usa una tecla para parry)
                MouseClickFunction = function()
                    Services.UserInputService:SimulateKeyPress(Enum.KeyCode.E)
                    Services.Task.wait(0.05) -- Pequeño delay para simular pulsación y liberación
                    Services.UserInputService:SimulateKeyRelease(Enum.KeyCode.E)
                end
                LogShadowActivity("Método de clic: Simulación de tecla 'E' (fallback).")
            end
        end
    end
end)

local function TriggerInput()
    local breathFactor = Math.sin(ShadowState.BreathingCycleTime / 0.5)
    local dynamicBreathPulse = (ShadowProtocols.MinReaction + ShadowProtocols.MaxReaction) / 2 * Math.abs(breathFactor) -- Ajuste para que pulse dentro del rango de reacción
    local tensionJitter = (ShadowState.CurrentChaosLevel / 12) * (ShadowProtocols.MaxReaction - ShadowProtocols.MinReaction)

    -- Mimetismo de Latencia Humana: Añadir varianza al input delay
    local humanLatencyJitter = Math.random(ShadowProtocols.HumanLatencyVarianceMin * 1000, ShadowProtocols.HumanLatencyVarianceMax * 1000) / 1000
    -- Aumentar la varianza si estamos siendo observados o el caos es alto
    humanLatencyJitter = humanLatencyJitter * (1 + ShadowState.ObservationLevel * ShadowProtocols.ObservationPenaltyFactor) * (1 + ShadowState.CurrentChaosLevel / 15)

    -- Calculo del delay total
    local totalDelay = ShadowProtocols.MinReaction + dynamicBreathPulse + tensionJitter + humanLatencyJitter

    Services.Task.wait(totalDelay)
    if MouseClickFunction then
        MouseClickFunction()
        LogShadowActivity("Input de la Sombra emitido con latencia variable (%.4f).", totalDelay)
    else
        warn("No se pudo simular el clic. Sin función de clic segura.")
    end
    ShadowState.LastInputAttemptTime = Ck()
end

local function MutateProtocols(wasParrySuccessful)
    -- Ajuste del caos y de los protocolos (de 6.x)
    if wasParrySuccessful then
        ShadowState.CurrentChaosLevel = Math.max(ShadowState.CurrentChaosLevel - 1, 0)
        ShadowProtocols.PerceptionRange = Math.min(ShadowProtocols.PerceptionRange + ShadowProtocols.AdaptationLearningRate, 12.2)
        ShadowProtocols.PrecisionNoiseAmplitude = Math.max(ShadowProtocols.PrecisionNoiseAmplitude - ShadowProtocols.AdaptationLearningRate / 2, 0.008)
    else
        ShadowState.CurrentChaosLevel = Math.min(ShadowState.CurrentChaosLevel + 1, 12)
        ShadowProtocols.PerceptionRange = Math.max(ShadowProtocols.PerceptionRange - ShadowProtocols.AdaptationLearningRate, 8.2)
        ShadowProtocols.PrecisionNoiseAmplitude = Math.min(ShadowProtocols.PrecisionNoiseAmplitude + ShadowProtocols.AdaptationLearningRate, 0.027)
    end
    LogShadowActivity("Nexo de la Sombra mutando: Caos: %d. Rango: %.2f", ShadowState.CurrentChaosLevel, ShadowProtocols.PerceptionRange)
end

-- Función para determinar un punto estratégico de contraataque (MEJORADA de 6.9)
local function DetermineStrategicTargetPoint(playerPos, targetRootPart, targetKineticTrace, ballSpeed)
    local targetPos = targetRootPart.Position
    local predictedTargetPos = PredictTrajectory(targetKineticTrace, ShadowProtocols.TargetLookAhead) or targetPos

    -- Calcular la "zona débil" del oponente (basado en su movimiento actual)
    local targetMoveDirection = targetKineticTrace[3] and targetKineticTrace.[3]Vel.Unit or Vec3(0,0,0) -- CORRECCIÓN: history.[3]Vel a history.[3]Vel

    local possibleTargetZones = {
        predictedTargetPos + Vec3(10, 0, 10), -- Delante-Derecha
        predictedTargetPos + Vec3(-10, 0, 10), -- Delante-Izquierda
        predictedTargetPos + Vec3(10, 0, -10), -- Abajo-Derecha
        predictedTargetPos + Vec3(-10, 0, -10), -- Abajo-Izquierda
    }

    local bestZone = predictedTargetPos
    local maxDistanceToTarget = 0

    for _, zone in ipairs(possibleTargetZones) do
        local distToTargetFromZone = (zone - predictedTargetPos).Magnitude
        local vectorFromTargetToZone = (zone - predictedTargetPos).Unit
        local alignmentWithTargetMovement = vectorFromTargetToZone:Dot(targetMoveDirection)

        if alignmentWithTargetMovement < 0.5 then -- Si no se mueve activamente hacia allí (es una zona "abierta")
            if distToTargetFromZone > maxDistanceToTarget then
                maxDistanceToTarget = distToTargetFromZone
                bestZone = zone
            end
        end
    end

    -- Ponderar entre la predicción directa y la zona estratégica
    local finalTarget = predictedTargetPos:Lerp(bestZone, ShadowProtocols.StrategicTargetingBias)

    -- Mimetismo de estrategia de juego (cuadrantes aprendidos)
    if ShadowState.MimesisActive and ShadowState.MimesisLearningMode and #ShadowState.TargetQuadrantHistory > 0 then
        local sumWeights = 0
        local weightedDirection = Vec3(0,0,0)
        for key, weight in pairs(ShadowState.TargetQuadrantHistory) do
            local x, z = StrManip.match(key, "([%-?%d]+),([%-?%d]+)")
            if x and z then
                local quadVector = Vec3(tonumber(x) * 5, 0, tonumber(z) * 5) -- Convertir cuadrante a un vector de dirección aproximado
                weightedDirection = weightedDirection + (quadVector.Unit * weight)
                sumWeights = sumWeights + weight
            end
        end
        if sumWeights > 0 then
            weightedDirection = weightedDirection / sumWeights
            -- Influencia del mimetismo en el target final
            finalTarget = finalTarget:Lerp(targetPos + weightedDirection * 15, ShadowProtocols.MimesisPlaybackInfluence)
            LogShadowActivity("Aplicando sesgo de mimetismo estratégico (cuadrante).")
        end
    end

    return finalTarget
end

local function BallReturnDirection(targetRootPart, ballSpeed)
    local playerPos = PlayerRoot.Position
    local returnDirection = Vec3(0,0,0)
    local targetPointForAim = nil

    if not targetRootPart or not targetRootPart.Parent or not targetRootPart.Parent:FindFirstChild("Humanoid").Health > 0 then
        LogShadowActivity("No se encontró target válido. Usando dirección de la bola.")
        return (ShadowState.BallRef.Position - playerPos).Unit -- Fallback si no hay target
    end

    if ShadowProtocols.TargetingLogic == "AuraPredictive" then
        targetPointForAim = DetermineStrategicTargetPoint(playerPos, targetRootPart, ShadowState.TargetKineticTrace, ballSpeed)
        local auraOffset = Vec3(
            (Math.random() * 2 - 1) * ShadowProtocols.AuraDeviationMagnitude * ShadowState.SimulatedHumanVariance,
            (Math.random() * 2 - 1) * ShadowProtocols.AuraDeviationMagnitude / 2 * ShadowState.SimulatedHumanVariance,
            (Math.random() * 2 - 1) * ShadowProtocols.AuraDeviationMagnitude * ShadowState.SimulatedHumanVariance
        )
        targetPointForAim = targetPointForAim + auraOffset
        LogShadowActivity("Apuntado: AuraPredictive con estrategia y aura.")
    elseif ShadowProtocols.TargetingLogic == "EvadePredict" then
        -- Predecir evasión del target
        local assumedEvadeVector = (ShadowState.TargetRef.Position - ShadowState.BallRef.Position).Unit * Math.random(1.5, 3.0) * ShadowProtocols.TargetEvadePredictionStrength
        targetPointForAim = ShadowState.TargetRef.Position + assumedEvadeVector
        LogShadowActivity("Apuntado: EvadePredict.")
    elseif ShadowProtocols.TargetingLogic == "HumanSmart" then
        targetPointForAim = targetRootPart.Position
        LogShadowActivity("Apuntado: HumanSmart (simple).")
    elseif ShadowProtocols.TargetingLogic == "Random" then
        local candidates = {}
        for _,pl in ipairs(Services.Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character:FindFirstChild("Humanoid").Health > 0 then
                TableUtil.insert(candidates, pl.Character.HumanoidRootPart)
            end
        end
        if #candidates > 0 then
            targetPointForAim = candidates[Math.random(1,#candidates)].Position
            LogShadowActivity("Apuntado: Random.")
        else
            targetPointForAim = ShadowState.BallRef.Position -- Fallback
        end
    else -- "Direct" o cualquier otro no reconocido
        targetPointForAim = PredictTrajectory(ShadowState.TargetKineticTrace, ShadowProtocols.TargetLookAhead) or targetRootPart.Position
        LogShadowActivity("Apuntado: Directo/Fallback.")
    end

    -- Añadir "temblor" de apuntado (jitter)
    local aimJitterOffset = Vec3(
        (Math.random() * 2 - 1) * ShadowProtocols.JitterMagnitude * (1 + ShadowState.ObservationLevel * ShadowProtocols.ObservationPenaltyFactor),
        (Math.random() * 2 - 1) * ShadowProtocols.JitterMagnitude * (1 + ShadowState.ObservationLevel * ShadowProtocols.ObservationPenaltyFactor),
        (Math.random() * 2 - 1) * ShadowProtocols.JitterMagnitude * (1 + ShadowState.ObservationLevel * ShadowProtocols.ObservationPenaltyFactor)
    )
    targetPointForAim = targetPointForAim + aimJitterOffset

    returnDirection = (targetPointForAim - playerPos).Unit
    return returnDirection
end

-- ========== FUNCIONES DE ESP (Integradas de tu script) ==========
local function createESP(targetPart)
    if not ShadowState.espEnabled then return end
    if not targetPart or not targetPart:IsA("BasePart") or targetPart:FindFirstChild("ESPBillboard") then return end

    local espBox = InstCreate("BillboardGui")
    espBox.Name = "ESPBillboard"
    espBox.AlwaysOnTop = true
    espBox.Size = UdimFactory(2, 0, 2, 0)
    espBox.StudsOffset = Vec3(0, targetPart.Size.Y / 2 + 1, 0)

    local frame = InstCreate("Frame")
    frame.Size = UdimFactory(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = ColorFactory(0, 1, 0) -- Verde por defecto, se puede hacer dinámico con skins
    frame.BorderSizePixel = 0

    espBox.Parent = targetPart
    frame.Parent = espBox
end

local function removeESP(targetPart)
    if targetPart and targetPart:IsA("BasePart") then
        local existingESP = targetPart:FindFirstChild("ESPBillboard")
        if existingESP then
            existingESP:Destroy()
        end
    end
end

local function refreshAllESP()
    if not ShadowState.espEnabled then
        for _, player in pairs(Services.Players:GetPlayers()) do
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    removeESP(part)
                end
            end
        end
        return
    end

    for _, player in pairs(Services.Players:GetPlayers()) do
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide and part.Transparency < 1 then
                    createESP(part)
                end
            end
        end
    end
end

-- ========== BUCLE PRINCIPAL ==========
Services.RunService.Heartbeat:Connect(function()
    -- Revalidar referencias de jugador y juego
    if not RevalidatePlayerReferences() then return end

    -- Actualizar referencias de Bola y Target
    local detectedBall = nil
    for _, obj in ipairs(Services.Workspace:GetChildren()) do
        if StrManip.find(obj.Name:lower(), "ball") and obj:IsA("BasePart") then
            detectedBall = obj; break
        end
    end
    if detectedBall ~= ShadowState.BallRef then
        ShadowState.BallRef = detectedBall
        TableUtil.clear(ShadowState.BallKineticTrace)
        LogShadowActivity("Conexión con la Bola %s", ShadowState.BallRef and "restablecida" or "perdida")
    end
    UpdateKineticTrace(ShadowState.BallRef, ShadowState.BallKineticTrace)

    local closestTarget = nil
    local shortestDist = Math.huge
    for _, pl in ipairs(Services.Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character:FindFirstChild("Humanoid").Health > 0 then
            local root = pl.Character.HumanoidRootPart
            local dist = (PlayerRoot.Position - root.Position).Magnitude
            if dist < shortestDist then shortestDist = dist; closestTarget = root end
        end
    end
    if closestTarget ~= ShadowState.TargetRef then
        ShadowState.TargetRef = closestTarget
        TableUtil.clear(ShadowState.TargetKineticTrace)
        LogShadowActivity("Conexión con Objetivo %s", ShadowState.TargetRef and "restablecida" or "perdida")
    end
    UpdateKineticTrace(ShadowState.TargetRef, ShadowState.TargetKineticTrace)

    -- Estimación de latencia de red
    ShadowState.NetworkLatencyEstimate = (LocalPlayer.SimulationRadius / 1000) + (Services.Players:GetNetworkPing() / 1000)
    
    -- Monitoreo del estado del juego
    local gameStatusObj = Services.Workspace:FindFirstChild("GameStatus") 
    local newGameActive = false
    if gameStatusObj and gameStatusObj:IsA("StringValue") then
        local statusText = gameStatusObj.Value
        if StrManip.find(statusText:lower(), "round started") or StrManip.find(statusText:lower(), "playing") then newGameActive = true end
    else newGameActive = true end -- Asume activo si no hay indicador de juego, para juegos de tipo "arena"
    
    -- Lógica de Calentamiento/Enfriamiento
    if newGameActive ~= ShadowState.GameActive then
        ShadowState.GameActive = newGameActive
        ShadowState.LastGameActiveChangeTime = Ck() -- Resetear el tiempo al cambiar el estado del juego
        LogShadowActivity("Estado de juego: %s", ShadowState.GameActive and "ACTIVO" or "INACTIVO")
        TableUtil.clear(ShadowState.BallKineticTrace)
        TableUtil.clear(ShadowState.TargetKineticTrace)
    end

    -- Detección de "Anulación por Jugador" (para evitar conflictos y ser indetectable)
    ShadowState.HumanOverride = Services.UserInputService:IsKeyDown(Enum.KeyCode.W) or Services.UserInputService:IsKeyDown(Enum.KeyCode.A) or Services.UserInputService:IsKeyDown(Enum.KeyCode.S) or Services.UserInputService:IsKeyDown(Enum.KeyCode.D) or Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

    -- Ciclo de Mimetismo de Observación
    if ShadowState.MimesisActive and ShadowState.MimesisLearningMode and (Ck() - ShadowState.LastMimesisObservation) > ShadowProtocols.MimesisObservationInterval then
        MimesisObservationTick()
        ShadowState.LastMimesisObservation = Ck()
    end

    -- Ciclo de "Respiración Humana"
    ShadowState.BreathingCycleTime = ShadowState.BreathingCycleTime + Services.RunService.Heartbeat:Wait() * (1 + ShadowState.CurrentChaosLevel / 20)

    -- Detectar Nivel de Observación
    local observedCount = 0
    local totalPlayers = 0
    for _,pl in ipairs(Services.Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("Head") then
            totalPlayers = totalPlayers + 1
            local cam = Services.Workspace.CurrentCamera
            if cam and cam.CameraType ~= Enum.CameraType.Scriptable and (cam.CFrame.Position - PlayerRoot.Position).Magnitude < 20 then -- Rango de observación
                local vecToPlayer = (PlayerRoot.Position - cam.CFrame.Position).Unit
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = {pl.Character, LocalPlayer.Character}
                local rayResult = Services.Workspace:Raycast(cam.CFrame.Position, vecToPlayer * 20, rayParams)

                if cam.CFrame.LookVector:Dot(vecToPlayer) > 0.75 and (not rayResult or rayResult.Instance:IsDescendantOf(LocalPlayer.Character)) then
                    observedCount = observedCount + 1
                end
            end
        end
    end
    ShadowState.ObservationLevel = totalPlayers > 0 and (observedCount / totalPlayers) or 0
    if ShadowState.ObservationLevel > 0.05 then
        LogShadowActivity("Nivel de observación detectado: %.2f", ShadowState.ObservationLevel)
    end
end)

-- ========== NÚCLEO DE JUEGO (Lógica principal de parry y movimiento) ==========
Services.RunService.Stepped:Connect(function()
    if not ShadowState.AssistEnabled or not ShadowState.GameActive or ShadowState.HumanOverride then return end -- Usar HumanOverride
    if not PlayerChar or not PlayerHum or not PlayerRoot or PlayerHum.Health <= 0 then return end
    if not ShadowState.BallRef or not ShadowState.TargetRef then return end

    local playerPos = PlayerRoot.Position
    local playerVel = PlayerHum.AssemblyLinearVelocity
    local playerCurrentMotion = (playerVel * Vec3(1,0,1)).Magnitude

    local baseNoise = ShadowProtocols.PrecisionNoiseAmplitude
    -- Modificar SimulatedHumanVariance en base al nivel de observación y calentamiento
    local warmupFactor = Math.min((Ck() - ShadowState.LastGameActiveChangeTime) / ShadowProtocols.WarmupDuration, 1) -- 0 al inicio, 1 al final del calentamiento
    ShadowState.SimulatedHumanVariance = Math.random(baseNoise, baseNoise * (2 + ShadowState.CurrentChaosLevel / 12)) * (1 + (1 - warmupFactor) * 2) -- Mayor varianza al inicio
    ShadowState.SimulatedHumanVariance = ShadowState.SimulatedHumanVariance * (1 + ShadowState.ObservationLevel * ShadowProtocols.ObservationPenaltyFactor * 1.5) -- Aumenta varianza si se observa

    local baseReaction = ShadowProtocols.MinReaction
    -- Ajustar baseReaction según el modo Turbo
    if ShadowState.Mode == "Turbo" then
        baseReaction = baseReaction * ShadowProtocols.TurboBoost -- Reducir delay en Turbo
    end

    ShadowState.DynamicReactionDelay = Math.random(baseReaction * 1000, (ShadowProtocols.MaxReaction * 1000)) / 1000
    ShadowState.DynamicReactionDelay = ShadowState.DynamicReactionDelay + ShadowState.NetworkLatencyEstimate
    ShadowState.DynamicReactionDelay = ShadowState.DynamicReactionDelay * (1 + (1 - warmupFactor) * 0.5) -- Mayor retraso al inicio
    ShadowState.DynamicReactionDelay = ShadowState.DynamicReactionDelay * (1 + ShadowState.ObservationLevel * ShadowProtocols.ObservationPenaltyFactor) -- Mayor retraso si se observa

    -- Lógica de Auto Parry (Fusionada y Mejorada)
    if not ShadowState.ParryLock and (Ck() - ShadowState.LastParryExecutionTime > ShadowProtocols.ParryCooldown) then -- Usar ParryCooldown
        local predictedBallPos = PredictTrajectory(ShadowState.BallKineticTrace, ShadowProtocols.AnticipationWindow)
        if not predictedBallPos then return end
        local distToPredictedBall = (playerPos - predictedBallPos).Magnitude
        local ballDirectionToPlayer = (playerPos - ShadowState.BallRef.Position).Unit
        local ballTravelDirection = (ShadowState.BallRef.AssemblyLinearVelocity or (ShadowState.BallKineticTrace[3] and ShadowState.BallKineticTrace.[3]Vel)).Unit -- CORRECCIÓN: history.[3]Vel a history.[3]Vel
        local alignment = ballTravelDirection:Dot(ballDirectionToPlayer)
        local currentPerceptionRange = ShadowProtocols.PerceptionRange
        -- Tu script usa 30 studs como rango, mi PerceptionRange es 10.2. Usaremos un rango de emergencia si está muy cerca.
        local emergencyRange = 30 -- De tu script
        if distToPredictedBall < emergencyRange and distToPredictedBall > ShadowProtocols.PerceptionRange then
            currentPerceptionRange = emergencyRange
            LogShadowActivity("Modo PÁNICO activado. Bola cercana.")
        end

        if distToPredictedBall < currentPerceptionRange and alignment > 0.6 and playerCurrentMotion >= ShadowProtocols.MinPlayerMovementSignature then
            -- Aumentar la probabilidad de miss intencional si se está observando o en fase de calentamiento
            local effectiveDeliberateMissChance = ShadowProtocols.DeliberateMissChance + (1 - warmupFactor) * 0.02 -- Más misses al inicio
            effectiveDeliberateMissChance = effectiveDeliberateMissChance + ShadowState.ObservationLevel * 0.03 -- Más misses si se observa

            if effectiveDeliberateMissChance > Math.random() then
                LogShadowActivity("Micro-fallo intencional (efectivo: %.3f). Simula reacción humana.", effectiveDeliberateMissChance)
                ShadowState.LastParryExecutionTime = Ck()
                MutateProtocols(false) -- Ajusta protocolos como si fuera un fallo
                return
            end
            ShadowState.ParryLock = true
            Services.Task.spawn(function()
                Services.Task.wait(ShadowState.DynamicReactionDelay)
                local currentBallSpeed = (ShadowState.BallRef.AssemblyLinearVelocity or (ShadowState.BallKineticTrace[3] and ShadowState.BallKineticTrace.[3]Vel)).Magnitude -- CORRECCIÓN: history.[3]Vel a history.[3]Vel

                -- Calular la fuerza de retorno con variación
                local forceVariance = Math.random(-ShadowProtocols.BallForceVariance * 100, ShadowProtocols.BallForceVariance * 100) / 100
                local effectiveBallForceScale = ShadowProtocols.BallReturnForceScale * (1 + forceVariance)

                -- Apuntar al centro de la bola antes del parry (de tu script)
                local lookAtBallCFrame = CFrame.lookAt(PlayerRoot.Position, ShadowState.BallRef.Position)
                PlayerRoot.CFrame = CFrame.new(PlayerRoot.Position) * (lookAtBallCFrame - lookAtBallCFrame.Position)
                Services.Task.wait(0.05) -- Pequeña espera para que el CFrame se registre

                local dir = BallReturnDirection(ShadowState.TargetRef, currentBallSpeed)
                ShadowState.BallRef.AssemblyLinearVelocity = dir * currentBallSpeed * effectiveBallForceScale
                TriggerInput()
                ShadowState.LastParryExecutionTime = Ck()
                ShadowState.ParryLock = false
                MutateProtocols(true) -- Ajusta protocolos como si fuera un éxito
                LogShadowActivity("Bola devuelta con fuerza variada (%.2f). Delay %.3f", effectiveBallForceScale, ShadowState.DynamicReactionDelay)
            end)
        end
    end

    -- Movimiento Ocioso y Evasión de Entorno (de 6.x)
    local playerCurrentMotion = (PlayerHum.AssemblyLinearVelocity * Vec3(1,0,1)).Magnitude
    if ShadowProtocols.IdleMovementActive and playerCurrentMotion < ShadowProtocols.MinPlayerMovementSignature and not ShadowState.HumanOverride then
        Services.Task.spawn(function()
            if ShadowState.MimesisActive and #ShadowState.MimesisMovementHistory > 0 then
                ApplyMimesisMovement(PlayerRoot)
            else
                -- Añadir mayor varianza al movimiento ocioso si se observa
                local idleJitterFactor = ShadowProtocols.PrecisionNoiseAmplitude * (1 + ShadowState.ObservationLevel * ShadowProtocols.ObservationPenaltyFactor * 2)
                PlayerRoot.CFrame = PlayerRoot.CFrame * CFrameUtil(Math.random(-0.5,0.5)*idleJitterFactor, 0, Math.random(-0.5,0.5)*idleJitterFactor)
            end
            if Math.random() < 0.02 + ShadowState.ObservationLevel * 0.01 then PlayerHum:ChangeState(Enum.HumanoidStateType.Jumping) end -- Más saltos "nerviosos" si se observa
            if Math.random() < 0.05 + ShadowState.ObservationLevel * 0.02 and Services.Workspace.CurrentCamera then
                -- Movimientos de cámara con más jitter si se observa
                Services.Workspace.CurrentCamera.CFrame = Services.Workspace.CurrentCamera.CFrame * CFrameUtil.Angles(0, Math.rad(Math.random(-15,15) * ShadowProtocols.PrecisionNoiseAmplitude * (1 + ShadowState.ObservationLevel)), 0)
            end
            Services.Task.wait(Math.random(0.1, 0.3) * (1 + ShadowProtocols.PrecisionNoiseAmplitude + ShadowState.CurrentChaosLevel / 10) * (1 + ShadowState.ObservationLevel)) -- Esperas más largas si se observa
        end)
    end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {PlayerChar, ShadowState.BallRef, ShadowState.TargetRef}
    local rayResult = Services.Workspace:Raycast(playerPos, playerVel.Unit * ShadowProtocols.EnvironmentalSenseRadius, rayParams)
    if rayResult and rayResult.Instance and rayResult.Instance.Parent ~= PlayerChar and rayResult.Instance ~= ShadowState.BallRef and rayResult.Instance ~= ShadowState.TargetRef then
        local collisionUrgency = 1 - (rayResult.Distance / ShadowProtocols.EnvironmentalSenseRadius)
        if Math.random() < collisionUrgency * (1 + ShadowState.ObservationLevel * 0.5) then -- Más "nerviosismo" para evadir si se observa
            if Math.random() < 0.3 + collisionUrgency * 0.7 then PlayerHum:ChangeState(Enum.HumanoidStateType.Jumping) end
            PlayerRoot.CFrame = PlayerRoot.CFrame * CFrameUtil(playerVel.Unit:Cross(Vec3(0,1,0)) * Math.random(0.5,1) * (1+collisionUrgency), 0, 0)
            LogShadowActivity("Evasión de colisión con %s (Urgency: %.2f)", rayResult.Instance.Name, collisionUrgency)
        end
    end

    -- Asistencia Dinámica de Movimiento (Fusionada de tu script)
    if ShadowState.dynamicAssistanceEnabled then
        local ball = ShadowState.BallRef
        if ball then
            local distance = (PlayerRoot.Position - ball.Position).Magnitude
            if distance < 20 then
                PlayerHum.WalkSpeed = ShadowProtocols.BaseMovementSpeed * ShadowProtocols.DynamicSpeedMultiplier + Math.random() * ShadowState.SimulatedHumanVariance -- Velocidad aumentada con varianza
            else
                PlayerHum.WalkSpeed = ShadowProtocols.BaseMovementSpeed + Math.random() * ShadowState.SimulatedHumanVariance -- Velocidad normal con varianza
            end
        else
            PlayerHum.WalkSpeed = ShadowProtocols.BaseMovementSpeed + Math.random() * ShadowState.SimulatedHumanVariance
        end
        PlayerHum.JumpPower = ShadowProtocols.BaseJumpPower + Math.random() * 2 * ShadowState.SimulatedHumanVariance -- JumpPower con varianza
    else
        PlayerHum.WalkSpeed = ShadowProtocols.BaseMovementSpeed
        PlayerHum.JumpPower = ShadowProtocols.BaseJumpPower
    end
end)

-- ========== GUI PRINCIPAL AVANZADA: "ESPECTRAL" ==========
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainGUI = InstCreate("ScreenGui", PlayerGui)
MainGUI.Name = "ShadowSymphonyGUI"
MainGUI.ResetOnSpawn = false
MainGUI.Enabled = true -- Asegurarse de que la ScreenGui esté habilitada

local GUIFrame = InstCreate("Frame", MainGUI)
-- Ajustar el tamaño y la posición para que sean escalables y se adapten a la pantalla
GUIFrame.Size = UdimFactory(0.3, 0, 0.6, 0) -- 30% del ancho, 60% del alto de la pantalla
GUIFrame.Position = UdimFactory(0.35, 0, 0.2, 0) -- Centrado aproximadamente
GUIFrame.BackgroundColor3 = GUISkins.bg()
GUIFrame.BorderSizePixel = 3
GUIFrame.BorderColor3 = GUISkins.border()
GUIFrame.Draggable = true
GUIFrame.BackgroundTransparency = 0 -- Forzar opacidad para depuración inicial
GUIFrame.Visible = true -- Asegurarse de que el Frame esté visible
GUIFrame.ZIndex = 10 -- Asegurarse de que esté en la capa superior

local GUITitle = InstCreate("TextLabel", GUIFrame)
GUITitle.Size = UdimFactory(1,0,0,32)
GUITitle.Position = UdimFactory(0,0,0,0)
GUITitle.Text = "BRAZO ROBÓTICO: SINFONÍA DE LA SOMBRA"
GUITitle.TextColor3 = GUISkins.text()
GUITitle.Font = Enum.Font.Fantasy
GUITitle.TextScaled = true
GUITitle.BackgroundTransparency = 1

local ChaosDisplay = InstCreate("TextLabel", GUIFrame)
ChaosDisplay.Size = UdimFactory(1,0,0,20)
ChaosDisplay.Position = UdimFactory(0,0,0,36)
ChaosDisplay.Text = "Nivel de Caos: 0"
ChaosDisplay.TextColor3 = GUISkins.border()
ChaosDisplay.Font = Enum.Font.SourceSansSemibold
ChaosDisplay.TextScaled = true
ChaosDisplay.BackgroundTransparency = 1

local LastActionDisplay = InstCreate("TextLabel", GUIFrame)
LastActionDisplay.Size = UdimFactory(1,0,0,22)
LastActionDisplay.Position = UdimFactory(0,0,0,62)
LastActionDisplay.Text = "Última Acción: -"
LastActionDisplay.TextColor3 = GUISkins.text()
LastActionDisplay.Font = Enum.Font.SourceSans
LastActionDisplay.TextScaled = true
LastActionDisplay.BackgroundTransparency = 1

local PingDisplay = InstCreate("TextLabel", GUIFrame)
PingDisplay.Size = UdimFactory(1,0,0,18)
PingDisplay.Position = UdimFactory(0,0,0,88)
PingDisplay.Text = "Ping: 0 ms"
PingDisplay.TextColor3 = GUISkins.text()
PingDisplay.Font = Enum.Font.SourceSans
PingDisplay.TextScaled = true
PingDisplay.BackgroundTransparency = 1

local ModeLabel = InstCreate("TextLabel", GUIFrame)
ModeLabel.Size = UdimFactory(1,0,0,22)
ModeLabel.Position = UdimFactory(0,0,0,110)
ModeLabel.Text = "Modo: Normal"
ModeLabel.TextColor3 = GUISkins.text()
ModeLabel.Font = Enum.Font.SourceSans
ModeLabel.TextScaled = true
ModeLabel.BackgroundTransparency = 1

local TurboLabel = InstCreate("TextLabel", GUIFrame)
TurboLabel.Size = UdimFactory(1,0,0,22)
TurboLabel.Position = UdimFactory(0,0,0,135)
TurboLabel.Text = "Turbo: Mantén SHIFT"
TurboLabel.TextColor3 = ColorFactory(160,220,255)
TurboLabel.Font = Enum.Font.SourceSans
TurboLabel.TextScaled = true
TurboLabel.BackgroundTransparency = 1

local ObservedLabel = InstCreate("TextLabel", GUIFrame)
ObservedLabel.Size = UdimFactory(1,0,0,18)
ObservedLabel.Position = UdimFactory(0,0,0,160)
ObservedLabel.Text = "Observación: 0%"
ObservedLabel.TextColor3 = GUISkins.text()
ObservedLabel.Font = Enum.Font.SourceSans
ObservedLabel.TextScaled = true
ObservedLabel.BackgroundTransparency = 1

local LogOutputFrame = InstCreate("Frame", GUIFrame)
LogOutputFrame.Size = UdimFactory(0.97,0,0,110)
LogOutputFrame.Position = UdimFactory(0.015,0,0,185)
LogOutputFrame.BackgroundColor3 = ColorFactory(18,22,28)
LogOutputFrame.BorderSizePixel = 1
LogOutputFrame.BorderColor3 = GUISkins.border()
local LogTextLabel = InstCreate("TextLabel", LogOutputFrame)
LogTextLabel.Size = UdimFactory(1,0,1,0)
LogTextLabel.Text = ""
LogTextLabel.TextColor3 = ColorFactory(220,250,255)
LogTextLabel.Font = Enum.Font.Code
LogTextLabel.TextScaled = false
LogTextLabel.TextWrapped = true
LogTextLabel.TextXAlignment = Enum.TextXAlignment.Left
LogTextLabel.TextYAlignment = Enum.TextYAlignment.Top
LogTextLabel.BackgroundTransparency = 1

local MimesisStatusDisplay = InstCreate("TextLabel", GUIFrame)
MimesisStatusDisplay.Size = UdimFactory(1,0,0,16)
MimesisStatusDisplay.Position = UdimFactory(0,0,0,300)
MimesisStatusDisplay.Text = "Mimetismo: INACTIVO"
MimesisStatusDisplay.TextColor3 = ColorFactory(180,220,255)
MimesisStatusDisplay.Font = Enum.Font.SourceSans
MimesisStatusDisplay.TextScaled = true
MimesisStatusDisplay.BackgroundTransparency = 1

local yOffset = 320

local function CreateToggle(parent, text, key, yPos, targetTable)
    local btn = InstCreate("TextButton", parent)
    btn.Name = key.. "Toggle" -- Para identificarlo en el bucle de actualización
    btn.Size = UdimFactory(0.97,0,0,25)
    btn.Position = UdimFactory(0.015,0,0,yPos)
    local currentValue = targetTable[key]
    btn.Text = text.. ": ".. (currentValue and "ON" or "OFF")
    btn.BackgroundColor3 = currentValue and GUISkins.border() or ColorFactory(70,70,70)
    btn.TextColor3 = GUISkins.text()
    btn.Font = Enum.Font.Gothic
    btn.TextScaled = true
    btn.AutoButtonColor = true
    btn.MouseButton1Click:Connect(function()
        targetTable[key] = not targetTable[key]
        btn.Text = text.. ": ".. (targetTable[key] and "ON" or "OFF")
        btn.BackgroundColor3 = targetTable[key] and GUISkins.border() or ColorFactory(70,70,70)
        LogShadowActivity("Toggle '%s': %s", text, targetTable[key] and "ACTIVADO" or "DESACTIVADO")
        if key == "espEnabled" then refreshAllESP() end -- Actualizar ESP al cambiar
    end)
    TableUtil.insert(ToggleButtons, btn) -- Añadir a la lista de botones
    return btn
end

local function CreateDropdown(parent, text, options, valueKey, yPos, targetTable, callback)
    local btn = InstCreate("TextButton", parent)
    btn.Name = valueKey.. "Dropdown" -- Para identificarlo
    btn.Size = UdimFactory(0.97,0,0,22)
    btn.Position = UdimFactory(0.015,0,0,yPos)
    btn.Text = text.. ": ".. targetTable[valueKey]
    btn.BackgroundColor3 = GUISkins.border()
    btn.TextColor3 = GUISkins.text()
    btn.Font = Enum.Font.Code
    btn.TextScaled = true
    btn.AutoButtonColor = true
    btn.MouseButton1Click:Connect(function()
        local idx=1 for i,v in ipairs(options) do if v==targetTable[valueKey] then idx=i break end end
        idx = idx + 1; if idx>#options then idx=1 end
        targetTable[valueKey]=options[idx]
        btn.Text = text..": "..targetTable[valueKey]
        LogShadowActivity("Opción '%s' cambiada a: %s", text, targetTable[valueKey])
        if callback then callback(targetTable[valueKey]) end
    end)
    TableUtil.insert(ToggleButtons, btn) -- Añadir a la lista de botones
    return btn
end

-- Toggles generales (fusionados de 6.x, 7.0 y tu script)
CreateToggle(GUIFrame, "Asistencia Activa", "AssistEnabled", yOffset, ShadowState); yOffset = yOffset + 28
CreateToggle(GUIFrame, "Logs Visuales", "EnableLogs", yOffset, GUISettings); yOffset = yOffset + 28
-- Desactivar FadeGUIWhenObserved para depuración inicial
-- CreateToggle(GUIFrame, "GUI Transparencia Auto", "FadeGUIWhenObserved", yOffset, GUISettings); yOffset = yOffset + 28
CreateToggle(GUIFrame, "Mostrar Ping", "DisplayPing", yOffset, GUISettings); yOffset = yOffset + 28
CreateDropdown(GUIFrame, "Skin Visual", {"Plasma","Blade","Neon","Matrix"}, "Skin", yOffset, GUISettings, function()
    GUIFrame.BackgroundColor3 = GUISkins.bg()
    GUIFrame.BorderColor3 = GUISkins.border()
    GUITitle.TextColor3 = GUISkins.text()
end); yOffset = yOffset + 26
CreateToggle(GUIFrame, "Mimetismo Activo", "MimesisActive", yOffset, ShadowState); yOffset = yOffset + 28
CreateToggle(GUIFrame, "Mimetismo: Aprender", "MimesisLearningMode", yOffset, ShadowState); yOffset = yOffset + 28
CreateDropdown(GUIFrame, "Modo de Apuntado", {"AuraPredictive","EvadePredict","HumanSmart","Random"}, "TargetingLogic", yOffset, ShadowProtocols); yOffset = yOffset + 26
CreateToggle(GUIFrame, "Movimiento en Reposo", "IdleMovementActive", yOffset, ShadowProtocols); yOffset = yOffset + 28
CreateToggle(GUIFrame, "Detección Ambiente", "EnvironmentalSenseRadius", yOffset, ShadowProtocols); yOffset = yOffset + 28
CreateToggle(GUIFrame, "Error Humano Ctrl.", "DeliberateMissChance", yOffset, ShadowProtocols); yOffset = yOffset + 28
CreateToggle(GUIFrame, "Asistencia Dinámica", "dynamicAssistanceEnabled", yOffset, ShadowState); yOffset = yOffset + 28 -- De tu script
CreateToggle(GUIFrame, "ESP Activo", "espEnabled", yOffset, ShadowState); yOffset = yOffset + 28 -- De tu script


-- Botones de Perfiles Principal
local BtnSaveMainProfile = InstCreate("TextButton", GUIFrame)
BtnSaveMainProfile.Size = UdimFactory(0.46,0,0,20)
BtnSaveMainProfile.Position = UdimFactory(0.015,0,1,-160)
BtnSaveMainProfile.Text = "Guardar Perfil"
BtnSaveMainProfile.BackgroundColor3 = GUISkins.border()
BtnSaveMainProfile.TextColor3 = GUISkins.text()
BtnSaveMainProfile.Font = Enum.Font.Code
BtnSaveMainProfile.TextScaled = true
BtnSaveMainProfile.MouseButton1Click:Connect(function() SaveMainProfile(GUISettings.CurrentProfile) end)

local BtnLoadMainProfile = InstCreate("TextButton", GUIFrame)
BtnLoadMainProfile.Size = UdimFactory(0.46,0,0,20)
BtnLoadMainProfile.Position = UdimFactory(0.525,0,1,-160)
BtnLoadMainProfile.Text = "Cargar Perfil"
BtnLoadMainProfile.BackgroundColor3 = GUISkins.border()
BtnLoadMainProfile.TextColor3 = GUISkins.text()
BtnLoadMainProfile.Font = Enum.Font.Code
BtnLoadMainProfile.TextScaled = true
BtnLoadMainProfile.MouseButton1Click:Connect(function() LoadMainProfile(GUISettings.CurrentProfile) end)

local BtnExportMainProfile = InstCreate("TextButton", GUIFrame)
BtnExportMainProfile.Size = UdimFactory(0.46,0,0,20)
BtnExportMainProfile.Position = UdimFactory(0.015,0,1,-135)
BtnExportMainProfile.Text = "Exportar Perfil"
BtnExportMainProfile.BackgroundColor3 = GUISkins.border()
BtnExportMainProfile.TextColor3 = GUISkins.text()
BtnExportMainProfile.Font = Enum.Font.Code
BtnExportMainProfile.TextScaled = true
BtnExportMainProfile.MouseButton1Click:Connect(ExportMainProfile)

local BtnImportMainProfile = InstCreate("TextButton", GUIFrame)
BtnImportMainProfile.Size = UdimFactory(0.46,0,0,20)
BtnImportMainProfile.Position = UdimFactory(0.525,0,1,-135)
BtnImportMainProfile.Text = "Importar Perfil"
BtnImportMainProfile.BackgroundColor3 = GUISkins.border()
BtnImportMainProfile.TextColor3 = GUISkins.text()
BtnImportMainProfile.Font = Enum.Font.Code
BtnImportMainProfile.TextScaled = true
BtnImportMainProfile.MouseButton1Click:Connect(ImportMainProfile)

-- Botones de Mimetismo (Guardar/Cargar patrón)
local MimesisProfileNameInput = InstCreate("TextBox", GUIFrame)
MimesisProfileNameInput.Size = UdimFactory(0.97,0,0,25)
MimesisProfileNameInput.Position = UdimFactory(0.015,0,1,-110)
MimesisProfileNameInput.PlaceholderText = "Nombre Patrón Mimetismo"
MimesisProfileNameInput.Text = "DefaultMimesis"
MimesisProfileNameInput.BackgroundColor3 = ColorFactory(30,30,40)
MimesisProfileNameInput.TextColor3 = GUISkins.text()
MimesisProfileNameInput.Font = Enum.Font.Code
MimesisProfileNameInput.TextScaled = true

local BtnSaveMimesis = InstCreate("TextButton", GUIFrame)
BtnSaveMimesis.Size = UdimFactory(0.46,0,0,20)
BtnSaveMimesis.Position = UdimFactory(0.015,0,1,-80)
BtnSaveMimesis.Text = "Guardar Patrón"
BtnSaveMimesis.BackgroundColor3 = GUISkins.border()
BtnSaveMimesis.TextColor3 = GUISkins.text()
BtnSaveMimesis.Font = Enum.Font.Code
BtnSaveMimesis.TextScaled = true
BtnSaveMimesis.MouseButton1Click:Connect(function() SaveMimesisProfile(MimesisProfileNameInput.Text) end)

local BtnLoadMimesis = InstCreate("TextButton", GUIFrame)
BtnLoadMimesis.Size = UdimFactory(0.46,0,0,20)
BtnLoadMimesis.Position = UdimFactory(0.525,0,1,-80)
BtnLoadMimesis.Text = "Cargar Patrón"
BtnLoadMimesis.BackgroundColor3 = GUISkins.border()
BtnLoadMimesis.TextColor3 = GUISkins.text()
BtnLoadMimesis.Font = Enum.Font.Code
BtnLoadMimesis.TextScaled = true
BtnLoadMimesis.MouseButton1Click:Connect(function() LoadMimesisProfile(MimesisProfileNameInput.Text) end)

local BtnClearMimesis = InstCreate("TextButton", GUIFrame)
BtnClearMimesis.Size = UdimFactory(0.97,0,0,20)
BtnClearMimesis.Position = UdimFactory(0.015,0,1,-55)
BtnClearMimesis.Text = "Limpiar Historial Mimetismo"
BtnClearMimesis.BackgroundColor3 = ColorFactory(100,50,50)
BtnClearMimesis.TextColor3 = GUISkins.text()
BtnClearMimesis.Font = Enum.Font.Code
BtnClearMimesis.TextScaled = true
BtnClearMimesis.MouseButton1Click:Connect(ClearMimesisHistory)

-- Botón de Pánico (Desactivación Completa y Limpieza)
local PanicButton = InstCreate("TextButton", GUIFrame)
PanicButton.Size = UdimFactory(1,0,0,32)
PanicButton.Position = UdimFactory(0,0,1,-25)
PanicButton.Text = "🛑 PROTOCOLO: SILENCIO COMPLETO DE LA SOMBRA 🛑"
PanicButton.BackgroundColor3 = ColorFactory(200,40,40)
PanicButton.TextColor3 = ColorFactory(255,255,255)
PanicButton.Font = Enum.Font.Fantasy
PanicButton.TextScaled = true
PanicButton.MouseButton1Click:Connect(function()
    GUISettings.EnableLogs = false
    ShadowState.GameActive = false
    ShadowState.MimesisActive = false
    ShadowState.MimesisLearningMode = false
    ShadowState.AssistEnabled = false -- Asegurar que la asistencia también se desactive
    ShadowState.dynamicAssistanceEnabled = false -- Desactivar asistencia dinámica
    ShadowState.espEnabled = false -- Desactivar ESP
    refreshAllESP() -- Limpiar ESP
    LogShadowActivity("PROTOCOLO DE SILENCIO COMPLETO ACTIVADO. La Sombra se desvanece sin rastro.")
    MainGUI:Destroy()
end)

Services.Task.spawn(function()
    while MainGUI.Parent do
        local currentTime = Ck()
        local pulseFactor = Math.abs(Math.sin(currentTime * ShadowProtocols.ChaosEvolutionSpeed + ShadowState.CurrentChaosLevel * 0.16))
        
        -- Actualizar colores de la GUI
        GUIFrame.BackgroundColor3 = GUISkins.bg()
        GUIFrame.BorderColor3 = GUISkins.border()
        GUITitle.TextColor3 = GUISkins.text()
        
        -- Transparencia Espectral: Se vuelve más transparente si es observado o el caos es muy bajo (simula "confianza" para desaparecer)
        local targetTransparency = GUISettings.GUITransparency
        if GUISettings.FadeGUIWhenObserved then
            local isObserved = ShadowState.ObservationLevel > 0.1 -- Más de un 10% de observación
            if isObserved then targetTransparency = 0.98 -- Casi invisible
            else targetTransparency = GUISettings.GUITransparency end -- Usa GUISettings.GUITransparency
        end
        GUIFrame.BackgroundTransparency = targetTransparency + pulseFactor * 0.05

        -- Actualizaciones de texto
        ChaosDisplay.Text = StrManip.format("Nivel de Caos: %d", ShadowState.CurrentChaosLevel)
        ChaosDisplay.TextColor3 = Color3.fromHSV(0.93 - pulseFactor * 0.2, 0.7, 0.76 + pulseFactor * 0.2) -- Color pulsante
        LastActionDisplay.Text = "Última Acción: ".. (ShadowState.LastRecordedAction or "-")
        
        if GUISettings.DisplayPing then
            PingDisplay.Text = StrManip.format("Ping: %d ms", Services.Players:GetNetworkPing())
            PingDisplay.Visible = true
        else PingDisplay.Visible = false end

        ModeLabel.Text = "Modo: ".. ShadowState.Mode
        TurboLabel.TextColor3 = ShadowState.TurboKeyDown and ColorFactory(60,255,110) or ColorFactory(160,220,255)
        ObservedLabel.Text = StrManip.format("Observación: %d%%", Math.floor(ShadowState.ObservationLevel*100))

        -- Logs
        local logs = ""
        for i = #ShadowState.EventLogBuffer, 1, -1 do logs = logs.. ShadowState.EventLogBuffer[i].. "\n" end
        LogTextLabel.Text = logs

        -- Mimesis display
        local mimesisTargetName = (ShadowState.MimesisTarget and ShadowState.MimesisTarget.Parent.Name) or "BUSCANDO"
        MimesisStatusDisplay.Text = "Mimetismo: ".. (ShadowState.MimesisActive and "ON (".. mimesisTargetName.. ")" or "INACTIVO")
        MimesisStatusDisplay.Text = MimesisStatusDisplay.Text.. (ShadowState.MimesisLearningMode and " (APRENDIENDO)" or "")
        MimesisStatusDisplay.Text = MimesisStatusDisplay.Text.. (ShadowState.CurrentMimesisPlaybackProfile and " (PERFIL: "..ShadowState.CurrentMimesisPlaybackProfile..")" or "")

        -- Actualizar el texto y color de los toggles por si hay cambios en los protocolos por auto-mutación
        for _, btn in pairs(ToggleButtons) do
            local key = btn.Name:gsub("Toggle$", "") -- Extraer la clave de la configuración
            local targetTable = nil
            if ShadowState[key] ~= nil then targetTable = ShadowState
            elseif ShadowProtocols[key] ~= nil then targetTable = ShadowProtocols
            elseif GUISettings[key] ~= nil then targetTable = GUISettings end

            if targetTable and targetTable[key] ~= nil then
                local currentValue = targetTable[key]
                local originalText = StrManip.gsub(btn.Text, ": %w+", "")
                btn.Text = originalText.. ": ".. (currentValue and "ON" or "OFF")
                btn.BackgroundColor3 = currentValue and GUISkins.border() or ColorFactory(70,70,70)
                btn.TextColor3 = GUISkins.text()
            end
        end

        Services.Task.wait(0.08) -- Frecuencia de actualización de la GUI
    end
end)

-- // ESP Setup for existing players and new players (Integrado de tu script)
Services.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        Services.Task.wait(1) -- Give some time for character to load fully
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide and part.Transparency < 1 then
                createESP(part)
            end
        end
    end)
end)

-- Initial ESP setup for players already in the game
for _, player in pairs(Services.Players:GetPlayers()) do
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide and part.Transparency < 1 then
                createESP(part)
            end
        end
    end
end

LogShadowActivity("SUPREMACY: SINFONÍA DE LA SOMBRA - EVOLUCIÓN 7.3 LISTA. Disfruta el poder sin perder la diversión.")

-- FIN DE LA EVOLUCIÓN 7.3. Esperando la próxima iteración o un nuevo script para fusionar y mejorar.

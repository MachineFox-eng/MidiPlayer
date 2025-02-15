-- Sidebar
-- Versão: 2.1
-- Data: 15 Fevereiro, 2025
-- Suporte mobile por MachineFox

local midiPlayer = script:FindFirstAncestor("MidiPlayer")
local Thread = require(midiPlayer.Util.Thread)
local Controller = require(midiPlayer.Components.Controller)
local FastTween = require(midiPlayer.FastTween)

local Sidebar = {}
Sidebar.__index = Sidebar

-- Constantes de estilo
local STYLES = {
    BACKGROUND_COLOR = Color3.fromRGB(35, 35, 40),
    HOVER_COLOR = Color3.fromRGB(45, 45, 50),
    SELECTED_COLOR = Color3.fromRGB(60, 90, 120),
    TEXT_COLOR = Color3.fromRGB(255, 255, 255),
    ACCENT_COLOR = Color3.fromRGB(98, 135, 255),
    FONT = Enum.Font.GothamMedium,
    CORNER_RADIUS = UDim.new(0, 6),
    PADDING = UDim.new(0, 8)
}

local ANIMATIONS = {
    HOVER = { 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
    SELECT = { 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out },
    APPEAR = { 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out }
}

-- Estado local
local sidebar
local template
local isDragging
local startDragPosition
local startScrollPosition

local function setupElementStyle(element)
    -- Estilização do elemento base
    element.BackgroundColor3 = STYLES.BACKGROUND_COLOR
    element.BorderSizePixel = 0
    
    -- Arredondamento das bordas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = STYLES.CORNER_RADIUS
    corner.Parent = element
    
    -- Padding interno
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = STYLES.PADDING
    padding.PaddingRight = STYLES.PADDING
    padding.Parent = element
    
    -- Estilização do título
    element.Title.Font = STYLES.FONT
    element.Title.TextColor3 = STYLES.TEXT_COLOR
    element.Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Barra de seleção com gradiente
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, STYLES.ACCENT_COLOR),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(STYLES.ACCENT_COLOR.R * 1.2, 
                                                   STYLES.ACCENT_COLOR.G * 1.2, 
                                                   STYLES.ACCENT_COLOR.B * 1.2))
    })
    gradient.Parent = element.Selection
    
    -- Efeito de aparecimento
    element.BackgroundTransparency = 1
    element.Title.TextTransparency = 1
    FastTween(element, ANIMATIONS.APPEAR, { BackgroundTransparency = 0.9 })
    FastTween(element.Title, ANIMATIONS.APPEAR, { TextTransparency = 0 })
end

function Sidebar:CreateElement(filePath)
    local fullname = filePath:match("([^\\]+)$")
    local name = fullname:gsub("^midi/", ""):match("^([^%.]+)") or ""
    local extension = fullname:match("([^%.]+)$")
    
    if extension ~= "mid" then return end
    
    local element = template:Clone()
    element.Name = filePath
    element.Title.Text = name
    
    setupElementStyle(element)
    
    -- Configuração inicial da seleção
    if Controller.CurrentFile == filePath then
        element.Selection.Size = UDim2.fromOffset(3, 16)
    else
        element.Selection.Size = UDim2.fromOffset(3, 0)
    end
    
    -- Sistema de duplo clique com feedback visual melhorado
    local lastClickTime = 0
    
    element.InputBegan:Connect(function(input)
        if isDragging then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            local currentTime = tick()
            
            if currentTime - lastClickTime < 0.5 then
                -- Efeito de seleção
                FastTween(element, ANIMATIONS.SELECT, { 
                    BackgroundColor3 = STYLES.SELECTED_COLOR,
                    BackgroundTransparency = 0.7
                })
                Controller:Select(filePath)
            end
            
            lastClickTime = currentTime
        end
    end)
    
    -- Efeitos visuais de hover
    element.MouseEnter:Connect(function()
        FastTween(element, ANIMATIONS.HOVER, { 
            BackgroundColor3 = STYLES.HOVER_COLOR,
            BackgroundTransparency = 0.8
        })
    end)
    
    element.MouseLeave:Connect(function()
        FastTween(element, ANIMATIONS.HOVER, { 
            BackgroundColor3 = STYLES.BACKGROUND_COLOR,
            BackgroundTransparency = 0.9
        })
    end)
    
    element.Title.TextTruncate = Enum.TextTruncate.AtEnd
    
    element.Parent = sidebar.Songs
    self:UpdateCanvasSize()
    
    -- Animação de entrada
    element.Position = UDim2.new(1, 0, element.Position.Y.Scale, element.Position.Y.Offset)
    FastTween(element, ANIMATIONS.APPEAR, {
        Position = UDim2.new(0, 0, element.Position.Y.Scale, element.Position.Y.Offset)
    })
end

function Sidebar:UpdateCanvasSize()
    local totalHeight = #sidebar.Songs:GetChildren() * template.AbsoluteSize.Y
    sidebar.Songs.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

function Sidebar:Update()
    local files = listfiles("midi")
    local existingElements = {}
    
    -- Remove elementos não existentes
    for _, element in ipairs(sidebar.Songs:GetChildren()) do
        if element:IsA("Frame") then
            if not table.find(files, element.Name) then
                element:Destroy()
            else
                existingElements[element.Name] = true
            end
        end
    end
    
    -- Adiciona novos elementos
    for _, filePath in ipairs(files) do
        if not existingElements[filePath] then
            self:CreateElement(filePath)
        end
    end
end

function Sidebar:InitDragBehavior()
    sidebar.Songs.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            startDragPosition = input.Position
            startScrollPosition = sidebar.Songs.CanvasPosition
        end
    end)
    
    sidebar.Songs.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startDragPosition
            sidebar.Songs.CanvasPosition = Vector2.new(
                startScrollPosition.X,
                startScrollPosition.Y - delta.Y
            )
        end
    end)
    
    sidebar.Songs.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
end

function Sidebar:Init(frame)
    sidebar = frame.Sidebar
    
    -- Estilização da barra lateral
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = sidebar
    
    -- Efeito de sombra
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Transparency = 0.8
    stroke.Parent = sidebar
    
    template = sidebar.Songs.Song
    template.Parent = nil
    
    Controller.FileLoaded:Connect(function(song)
        for _, element in ipairs(sidebar.Songs:GetChildren()) do
            if element:IsA("Frame") then
                if element.Name == song.Path then
                    FastTween(element.Selection, ANIMATIONS.SELECT, { 
                        Size = UDim2.fromOffset(3, 16) 
                    })
                else
                    FastTween(element.Selection, ANIMATIONS.SELECT, { 
                        Size = UDim2.fromOffset(3, 0) 
                    })
                end
            end
        end
    end)
    
    self:InitDragBehavior()
    Thread.DelayRepeat(1, self.Update, self)
    self:Update()
end

return Sidebar

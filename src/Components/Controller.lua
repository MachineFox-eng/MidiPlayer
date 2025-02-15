-- Controller
-- Versão: 2.1
-- Data: 15 Fevereiro, 2025

local midiPlayer = script:FindFirstAncestor("MidiPlayer")
local Signal = require(midiPlayer.Util.Signal)
local Date = require(midiPlayer.Util.Date)
local Thread = require(midiPlayer.Util.Thread)
local Song = require(midiPlayer.Song)
local FastTween = require(midiPlayer.FastTween)
local Preview = require(midiPlayer.Components.Preview)

-- Serviços
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

-- Configuração de Layout
local LAYOUT = {
    PREVIEW_BUTTON = {
        POSITION = UDim2.new(0.1, 5, 0.2, 0),  -- X, Y position (adjust these values)
        ANCHOR_POINT = Vector2.new(0, 0.5),   -- Center vertically
        SIZE = UDim2.new(0, 32, 0, 32)       -- Width, Height
    },
    TITLE = {
        POSITION = UDim2.new(0.1, 45, 0.2, 0),  -- X position is relative to preview button
        ANCHOR_POINT = Vector2.new(0, 0.5),   -- Center vertically
        SIZE = UDim2.new(1, -55, 0, 20),     -- Width adjusts to container minus padding
        PADDING_LEFT = 45                     -- Space between preview button and title
    }
}

-- Constantes de estilo (alinhadas com o Sidebar)
local STYLES = {
    COLORS = {
        BACKGROUND = Color3.fromRGB(35, 35, 40),
        PROGRESS = Color3.fromRGB(98, 135, 255),  -- Cor roxa do Sidebar
        PROGRESS_BG = Color3.fromRGB(98, 135, 255),
        SCRUBBER_HANDLE = Color3.fromRGB(98, 135, 255), -- Nova cor para o botão de arrastar
        TEXT = Color3.fromRGB(255, 255, 255),
        TEXT_DIM = Color3.fromRGB(180, 180, 180),
        BUTTON_HOVER = Color3.fromRGB(98, 135, 255)
    },
    ICONS = {
        PLAY = "rbxassetid://6026663699",
        PAUSE = "rbxassetid://6026663719",
        PREVIEW_ON = "rbxassetid://6026663719",
        PREVIEW_OFF = "rbxassetid://6026663699"
    },
    CORNER_RADIUS = UDim.new(0, 6),
    BUTTON_SIZE = UDim2.new(0, 32, 0, 32),
    ANIMATIONS = {
        DEFAULT = { 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
        QUICK = { 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out }
    }
}

local Controller = {
    CurrentSong = nil,
    FileLoaded = Signal.new()
}

local main, controller

-- Utilitários locais
local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return ("%d:%02d"):format(mins, secs)
end

local function setupUIElement(element, props)
    for property, value in pairs(props) do
        element[property] = value
    end
end

local function createCorner(parent)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = STYLES.CORNER_RADIUS
    corner.Parent = parent
    return corner
end

-- Funções principais
function Controller:Select(filePath)
    if self.CurrentSong then
        self.CurrentSong:Destroy()
    end
    
    self.CurrentSong = Song.new(filePath)
    self.FileLoaded:Fire(self.CurrentSong)
    self:Update()
    Preview:Draw(self.CurrentSong)
end

function Controller:Update()
    local song = self.CurrentSong

    if song then
        -- Atualiza título (agora ao lado do botão de preview)
        main.Title.Text = song.Name or "Música sem título"

        -- Atualiza tempo
        if song.TimePosition then
            controller.Time.Text = formatTime(song.TimePosition)
        end

        -- Atualiza progresso com a cor roxa
        local progress = math.min(1, song.TimePosition / song.TimeLength)
        FastTween(controller.Scrubber.Progress, STYLES.ANIMATIONS.QUICK, {
            Size = UDim2.fromScale(progress, 1)
        })
        FastTween(controller.Scrubber.Fill, STYLES.ANIMATIONS.QUICK, {
            Size = UDim2.fromScale(1 - progress, 1)
        })

        controller.Resume.Image = song.IsPlaying and STYLES.ICONS.PAUSE or STYLES.ICONS.PLAY

    else
        main.Title.Text = "selecione uma música 🎶"
        controller.Time.Text = ":)"
        controller.Scrubber.Progress.Size = UDim2.fromScale(0, 1)
        controller.Scrubber.Fill.Size = UDim2.fromScale(1, 1)
        controller.Resume.Image = STYLES.ICONS.PLAY
    end
end

function Controller:InitializeUI()
    -- Ajusta posição do título baseado na configuração LAYOUT
    setupUIElement(main.Title, {
        TextColor3 = STYLES.COLORS.TEXT,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = LAYOUT.TITLE.POSITION,
        AnchorPoint = LAYOUT.TITLE.ANCHOR_POINT,
        Size = LAYOUT.TITLE.SIZE
    })
    
    -- Estiliza o botão de play/pause
    setupUIElement(controller.Resume, {
        Size = STYLES.BUTTON_SIZE,
        ImageColor3 = STYLES.COLORS.TEXT,
        BackgroundTransparency = 1
    })
    
    -- Estiliza a barra de progresso com a cor roxa
    setupUIElement(controller.Scrubber, {
        BackgroundColor3 = STYLES.COLORS.PROGRESS_BG
    })
    createCorner(controller.Scrubber)
    
    setupUIElement(controller.Scrubber.Progress, {
        BackgroundColor3 = STYLES.COLORS.PROGRESS
    })
    createCorner(controller.Scrubber.Progress)

if controller.Scrubber:FindFirstChild("Handle") then
        setupUIElement(controller.Scrubber.Handle, {
            BackgroundColor3 = STYLES.COLORS.SCRUBBER_HANDLE,
            Size = UDim2.new(0, 12, 0, 12), -- Tamanho do handle
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 3 -- Garante que fique acima da barra de progresso
        })
        createCorner(controller.Scrubber.Handle)
        
        -- Adiciona efeito de hover no handle
        controller.Scrubber.Handle.MouseEnter:Connect(function()
            FastTween(controller.Scrubber.Handle, STYLES.ANIMATIONS.QUICK, {
                Size = UDim2.new(0, 14, 0, 14) -- Aumenta levemente o tamanho
            })
        end)
        
        controller.Scrubber.Handle.MouseLeave:Connect(function()
            FastTween(controller.Scrubber.Handle, STYLES.ANIMATIONS.QUICK, {
                Size = UDim2.new(0, 12, 0, 12) -- Retorna ao tamanho original
            })
        end)
    end
    
    -- Adiciona cantos arredondados aos círculos da barra de progresso
    if controller.Scrubber:FindFirstChild("StartCircle") then
        setupUIElement(controller.Scrubber.StartCircle, {
            BackgroundColor3 = STYLES.COLORS.PROGRESS
        })
        createCorner(controller.Scrubber.StartCircle)
    end
    
    if controller.Scrubber:FindFirstChild("EndCircle") then
        setupUIElement(controller.Scrubber.EndCircle, {
            BackgroundColor3 = STYLES.COLORS.PROGRESS
        })
        createCorner(controller.Scrubber.EndCircle)
    end
    
    setupUIElement(controller.Time, {
        TextColor3 = STYLES.COLORS.TEXT_DIM,
        Font = Enum.Font.GothamMedium
    })
    
    -- Configura o botão de preview usando o LAYOUT
    local togglePreview = main.TogglePreview
    setupUIElement(togglePreview, {
        Size = LAYOUT.PREVIEW_BUTTON.SIZE,
        Position = LAYOUT.PREVIEW_BUTTON.POSITION,
        AnchorPoint = LAYOUT.PREVIEW_BUTTON.ANCHOR_POINT,
        ImageColor3 = STYLES.COLORS.TEXT,
        BackgroundColor3 = STYLES.COLORS.BACKGROUND,
        BackgroundTransparency = 0.5
    })
    createCorner(togglePreview)
    
    -- Adiciona borda ao botão de preview
    local stroke = Instance.new("UIStroke")
    stroke.Color = STYLES.COLORS.PROGRESS
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = togglePreview
end

function Controller:_startHidePreviewButton()
    local togglePreview = main.TogglePreview
    
    togglePreview.MouseButton1Down:Connect(function()
        getgenv()._hideSongPreview = not getgenv()._hideSongPreview
        
        -- Mantém o botão sempre visível mas indica estado
        FastTween(togglePreview, STYLES.ANIMATIONS.DEFAULT, {
            BackgroundTransparency = getgenv()._hideSongPreview and 0.8 or 0.5,
            ImageTransparency = getgenv()._hideSongPreview and 0.5 or 0
        })
        
        -- Animação do preenchimento
        FastTween(togglePreview.Fill, STYLES.ANIMATIONS.DEFAULT, {
            Size = getgenv()._hideSongPreview and UDim2.new() or UDim2.new(1, -12, 1, -12)
        })
    end)
    
    -- Efeitos de hover
    togglePreview.MouseEnter:Connect(function()
        FastTween(togglePreview, STYLES.ANIMATIONS.QUICK, {
            BackgroundTransparency = 0.3
        })
    end)
    
    togglePreview.MouseLeave:Connect(function()
        FastTween(togglePreview, STYLES.ANIMATIONS.QUICK, {
            BackgroundTransparency = getgenv()._hideSongPreview and 0.8 or 0.5
        })
    end)
end

function Controller:Init(frame)
    main = frame.Main
    controller = main.Controller
    
    self:InitializeUI()
    self:_startScrubber()
    self:_startPlaybackButton()
    self:_startHidePreviewButton()

    Thread.DelayRepeat(1/60, function()
        if self.CurrentSong then
            Preview:Update(self.CurrentSong.TimePosition * self.CurrentSong.Timebase)
        end
    end)

    RunService.Heartbeat:Connect(function()
        self:Update()
    end)
end

function Controller:_startPlaybackButton()
    local playback = controller.Resume
    
    playback.MouseButton1Down:Connect(function()
        if not self.CurrentSong then return end
        
        if self.CurrentSong.IsPlaying then
            self.CurrentSong:Pause()
        else
            self.CurrentSong:Play()
        end
        
        -- Animação de feedback
        FastTween(playback, STYLES.ANIMATIONS.QUICK, {
            ImageTransparency = 0.3
        }).Completed:Connect(function()
            FastTween(playback, STYLES.ANIMATIONS.QUICK, {
                ImageTransparency = 0
            })
        end)
        
        self:Update()
    end)
end

function Controller:_startScrubber()
    local scrubber = controller.Scrubber
    local dragging = false
    local dragInput
    
    local function updateScrubber(input)
        if not self.CurrentSong then return end
        
        local relativeX = (input.Position.X - scrubber.AbsolutePosition.X) / scrubber.AbsoluteSize.X
        local targetTime = math.clamp(relativeX, 0, 1) * self.CurrentSong.TimeLength
        
        self.CurrentSong:JumpTo(targetTime)
        self:Update()
    end
    
    local function handleTouch(_, inputState, input)
        if inputState == Enum.UserInputState.Begin then
            dragging = true
            updateScrubber(input)
        elseif inputState == Enum.UserInputState.Change and dragging then
            if self.CurrentSong then
                self.CurrentSong:Pause()
            end
            updateScrubber(input)
        elseif inputState == Enum.UserInputState.End then
            dragging = false
            ContextActionService:UnbindAction("DragScrubber")
        end
    end
    
    scrubber.Hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            ContextActionService:BindAction(
                "DragScrubber",
                handleTouch,
                false,
                Enum.UserInputType.Touch,
                Enum.UserInputType.MouseMovement
            )
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    ContextActionService:UnbindAction("DragScrubber")
                end
            end)
            
            updateScrubber(input)
        end
    end)
    
    scrubber.Hitbox.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            if self.CurrentSong then
                self.CurrentSong:Pause()
            end
            updateScrubber(input)
        end
    end)
end

return Controller

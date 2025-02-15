-- App
-- 15 February, 2025
-- Mobile support by MachineFox

local App = {}

-- Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Constants
local COLORS = {
    BACKGROUND = Color3.fromRGB(15, 15, 18),
    ACCENT = Color3.fromRGB(255, 255, 255),
    SECONDARY = Color3.fromRGB(30, 30, 35),
    HIGHLIGHT = Color3.fromRGB(98, 135, 255),
    ACCENT_BLUE = Color3.fromRGB(98, 135, 255),
    KEY_WHITE = Color3.fromRGB(248, 248, 252),
    KEY_BLACK = Color3.fromRGB(20, 20, 23),
    KEY_WHITE_PRESSED = Color3.fromRGB(235, 235, 240),
    KEY_BLACK_PRESSED = Color3.fromRGB(30, 30, 35),
    SHADOW = Color3.fromRGB(10, 10, 12),
    KEY_BORDER = Color3.fromRGB(200, 200, 205)
}

local VISUAL_SETTINGS = {
    ANIMATION = {
        TIME = 0.4,
        STYLE = Enum.EasingStyle.Quart,
        DIRECTION = Enum.EasingDirection.Out
    },
    CORNERS = {
        LARGE = UDim.new(0, 12),
        MEDIUM = UDim.new(0, 8),
        SMALL = UDim.new(0, 4)
    },
    TRANSPARENCY = {
        GLOW = 0.85,
        SHADOW = 0.7,
        OVERLAY = 0.95
    },
    PIANO = {
        HEIGHT = 45,                -- Increased height for better visibility
        WHITE_KEY_WIDTH = 15.3,      -- Slightly reduced for more keys
        BLACK_KEY_WIDTH_RATIO = 0.6,-- Ratio for black key width
        BLACK_KEY_HEIGHT_RATIO = 0.65,-- Ratio for black key height
        SHADOW_INTENSITY = 0.4,    -- Shadow intensity for depth
        KEY_SPACING = 1,           -- Space between keys
        ANIMATION_SPEED = 0.15     -- Speed for key press animation
    }
}

-- Component References
local midiPlayer = script:FindFirstAncestor("MidiPlayer")
local FastDraggable = require(midiPlayer.FastDraggable)
local Controller = require(midiPlayer.Components.Controller)
local Sidebar = require(midiPlayer.Components.Sidebar)
local Preview = require(midiPlayer.Components.Preview)
local gui = midiPlayer.Assets.ScreenGui

-- Cached variables
local viewportSize = workspace.CurrentCamera.ViewportSize
local frameSize = gui.Frame.Size

-- Helper Functions
local function createTween(object, properties)
    return TweenService:Create(
        object,
        TweenInfo.new(
            VISUAL_SETTINGS.ANIMATION.TIME,
            VISUAL_SETTINGS.ANIMATION.STYLE,
            VISUAL_SETTINGS.ANIMATION.DIRECTION
        ),
        properties
    )
end

local function createShadowEffect(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://7131988781"  -- Soft shadow asset
    shadow.ImageColor3 = COLORS.SHADOW
    shadow.ImageTransparency = VISUAL_SETTINGS.TRANSPARENCY.SHADOW
    shadow.Size = UDim2.new(1.1, 0, 1.1, 0)
    shadow.Position = UDim2.new(-0.05, 0, -0.05, 0)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

local function createAccent(parent, size, position)
    local accent = Instance.new("Frame")
    accent.Name = "BlueAccent"
    accent.BackgroundColor3 = COLORS.ACCENT_BLUE
    accent.Size = size
    accent.Position = position
    accent.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = VISUAL_SETTINGS.CORNERS.SMALL
    corner.Parent = accent
    
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 0.3)
    })
    gradient.Rotation = 45
    gradient.Parent = accent
    
    accent.Parent = parent
    return accent
end

local function createPianoKeys(parent)
    local keysContainer = Instance.new("Frame")
    keysContainer.Name = "PianoKeys"
    keysContainer.Size = UDim2.new(1, -40, 0, VISUAL_SETTINGS.PIANO.HEIGHT)
    keysContainer.Position = UDim2.new(0, 20, 1, 12)
    keysContainer.BackgroundTransparency = 1
    keysContainer.Parent = parent

    -- Piano base with depth effect
    local keyboardBase = Instance.new("Frame")
    keyboardBase.Name = "KeyboardBase"
    keyboardBase.Size = UDim2.new(1, 0, 1, 8)
    keyboardBase.Position = UDim2.new(0, 0, 0, 0)
    keyboardBase.BackgroundColor3 = COLORS.SECONDARY
    keyboardBase.BorderSizePixel = 0
    keyboardBase.Parent = keysContainer

    -- Add sophisticated shadow and lighting effects
    local baseGradient = Instance.new("UIGradient")
    baseGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.4, 0.1),
        NumberSequenceKeypoint.new(1, 0.2)
    })
    baseGradient.Rotation = 90
    baseGradient.Parent = keyboardBase

    local baseCorner = Instance.new("UICorner")
    baseCorner.CornerRadius = VISUAL_SETTINGS.CORNERS.MEDIUM
    baseCorner.Parent = keyboardBase

    -- Main keyboard surface
    local keyboardTop = Instance.new("Frame")
    keyboardTop.Name = "KeyboardTop"
    keyboardTop.Size = UDim2.new(1, 0, 1, 0)
    keyboardTop.BackgroundTransparency = 1
    keyboardTop.ClipsDescendants = true
    keyboardTop.Parent = keysContainer

    -- Define piano structure
    local pianoStructure = {
        totalWhiteKeys = 24,  -- Aumentado para 26 teclas brancas
        blackKeyPatterns = {
            {1, 2},      -- C#, D#
            {4, 5, 6},   -- F#, G#, A#
            {8, 9},      -- C#, D#
            {11, 12, 13}, -- F#, G#, A#
            {15, 16},    -- C#, D#
            {18, 19, 20}, -- F#, G#, A#
            {22, 23}     -- Novas teclas C#, D#
        }
    }

    -- Create white keys
    for i = 0, pianoStructure.totalWhiteKeys - 1 do
        local whiteKey = Instance.new("Frame")
        whiteKey.Name = "WhiteKey"..i
        whiteKey.Size = UDim2.new(0, VISUAL_SETTINGS.PIANO.WHITE_KEY_WIDTH, 1, 0)
        whiteKey.Position = UDim2.new(0, i * (VISUAL_SETTINGS.PIANO.WHITE_KEY_WIDTH + VISUAL_SETTINGS.PIANO.KEY_SPACING), 0, 0)
        whiteKey.BackgroundColor3 = COLORS.KEY_WHITE
        whiteKey.BorderColor3 = COLORS.KEY_BORDER
        whiteKey.BorderSizePixel = 1

        local keyGradient = Instance.new("UIGradient")
        keyGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.05),
            NumberSequenceKeypoint.new(0.8, 0.1),
            NumberSequenceKeypoint.new(1, 0.15)
        })
        keyGradient.Rotation = 90
        keyGradient.Parent = whiteKey

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 3)
        corner.Parent = whiteKey

        local pressHighlight = Instance.new("Frame")
        pressHighlight.Name = "PressHighlight"
        pressHighlight.Size = UDim2.new(1, 0, 0, 4)
        pressHighlight.Position = UDim2.new(0, 0, 1, -4)
        pressHighlight.BackgroundColor3 = COLORS.ACCENT_BLUE
        pressHighlight.BackgroundTransparency = 1
        pressHighlight.BorderSizePixel = 0
        pressHighlight.Parent = whiteKey

        whiteKey.Parent = keyboardTop
    end

    -- Create black keys using pattern
    for _, pattern in ipairs(pianoStructure.blackKeyPatterns) do
        for _, offset in ipairs(pattern) do
            local position = (offset - 0.35) * (VISUAL_SETTINGS.PIANO.WHITE_KEY_WIDTH + VISUAL_SETTINGS.PIANO.KEY_SPACING)
            
            local blackKey = Instance.new("Frame")
            blackKey.Size = UDim2.new(
                0, 
                VISUAL_SETTINGS.PIANO.WHITE_KEY_WIDTH * VISUAL_SETTINGS.PIANO.BLACK_KEY_WIDTH_RATIO,
                VISUAL_SETTINGS.PIANO.BLACK_KEY_HEIGHT_RATIO,
                0
            )
            blackKey.Position = UDim2.new(0, position, 0, 0)
            blackKey.BackgroundColor3 = COLORS.KEY_BLACK
            blackKey.BorderSizePixel = 0

            local keyGradient = Instance.new("UIGradient")
            keyGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.7, 0.1),
                NumberSequenceKeypoint.new(0.9, 0.2),
                NumberSequenceKeypoint.new(1, 0.3)
            })
            keyGradient.Rotation = 90
            keyGradient.Parent = blackKey

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 3)
            corner.Parent = blackKey

            local shadow = Instance.new("Frame")
            shadow.Size = UDim2.new(1.2, 0, 0, 6)
            shadow.Position = UDim2.new(-0.1, 0, 1, -3)
            shadow.BackgroundColor3 = COLORS.SHADOW
            shadow.BackgroundTransparency = VISUAL_SETTINGS.PIANO.SHADOW_INTENSITY
            shadow.BorderSizePixel = 0
            shadow.Parent = blackKey

            local shadowCorner = Instance.new("UICorner")
            shadowCorner.CornerRadius = UDim.new(0, 3)
            shadowCorner.Parent = shadow

            blackKey.Parent = keyboardTop
        end
    end

    -- Add decorative elements
    local decorativeLine = createAccent(
        keysContainer,
        UDim2.new(1, 0, 0, 2),
        UDim2.new(0, 0, 0, -4)
    )

    -- Add subtle glow effect
    local glow = Instance.new("ImageLabel")
    glow.Name = "PianoGlow"
    glow.BackgroundTransparency = 1
    glow.Image = "rbxasset://textures/ui/Glow.png"
    glow.ImageColor3 = COLORS.ACCENT_BLUE
    glow.ImageTransparency = 0.9
    glow.Size = UDim2.new(1.2, 0, 1.2, 0)
    glow.Position = UDim2.new(-0.1, 0, -0.1, 0)
    glow.ZIndex = keyboardTop.ZIndex - 1
    glow.Parent = keysContainer
end

function App:GetGUI()
    return gui
end

function App:Init()
    -- Main frame styling
    local frame = gui.Frame
    frame.BackgroundColor3 = COLORS.BACKGROUND
    frame.Handle.BackgroundColor3 = COLORS.SECONDARY
    
    -- Enhanced corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = VISUAL_SETTINGS.CORNERS.LARGE
    corner.Parent = frame
    
    -- Add shadow effect
    createShadowEffect(frame)
    
    -- Blue accents
    createAccent(
        frame,
        UDim2.new(0, 60, 0, 2),
        UDim2.new(0, 20, 0, 15)
    )
    createAccent(
        frame,
        UDim2.new(0, 2, 0, 40),
        UDim2.new(0, 20, 0, 15)
    )
    
    -- Setup dragging
    FastDraggable(frame, frame.Handle)
    gui.Parent = CoreGui

    -- Enhanced toggle button
    local toggleButton = Instance.new("Frame")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0, 20, 0.5, -25)
    toggleButton.BackgroundColor3 = COLORS.BACKGROUND
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = gui

    -- Toggle button styling
    Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(1, 0)
    createShadowEffect(toggleButton)
    
    -- Piano icon com acento azul
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.2, 0, 0.2, 0)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://6034848748"  -- Piano icon
    icon.ImageColor3 = COLORS.ACCENT_BLUE
    icon.Parent = toggleButton
    
    -- Add subtle glow to icon
    local iconGlow = Instance.new("ImageLabel")
    iconGlow.Name = "Glow"
    iconGlow.BackgroundTransparency = 1
    iconGlow.Image = "rbxasset://textures/ui/Glow.png"
    iconGlow.ImageColor3 = COLORS.ACCENT_BLUE
    iconGlow.ImageTransparency = VISUAL_SETTINGS.TRANSPARENCY.GLOW
    iconGlow.Size = UDim2.new(1.5, 0, 1.5, 0)
    iconGlow.Position = UDim2.new(-0.25, 0, -0.25, 0)
    iconGlow.Parent = icon

    -- Calculate positions
    local centerX = viewportSize.X/2 - frameSize.X.Offset/2
    local centerY = viewportSize.Y/2 - frameSize.Y.Offset/2
    local offScreenY = -frameSize.Y.Offset - 70

    -- State management
    local isOpen = false
    local animating = false

    -- Toggle functionality
    local function toggleGUI()
        if animating then return end
        animating = true

        isOpen = not isOpen

        -- Enhanced icon animation
        local iconTween = createTween(icon, {
            Rotation = isOpen and 360 or 0,
            ImageTransparency = isOpen and 0 or 0.2
        })
        
        -- Glow animation
        local glowTween = createTween(iconGlow, {
            ImageTransparency = isOpen and 0.7 or 0.85
        })

        -- Frame animation
        local frameTween = createTween(frame, {
            Position = UDim2.new(0.1, centerX, 0, isOpen and centerY or offScreenY)
        })

        iconTween:Play()
        glowTween:Play()
        frameTween:Play()

        frameTween.Completed:Connect(function()
            animating = false
        end)
    end

    -- Input handling
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            toggleGUI()
        end
    end)

    -- Add piano decoration
    createPianoKeys(frame)

    -- Initialize components
    Controller:Init(frame)
    Sidebar:Init(frame)
    Preview:Init(frame)

    -- Set initial position
    frame.Position = UDim2.new(0, centerX, 0, offScreenY)
end

return App

-- Demo only: all callbacks affect this interface, never the game.
local window = Lumi:CreateWindow({Title = "lumi", Status = "POTASSIUM / PILOT"})
local overview = window:AddTab("Overview", {Description = "A quieter workspace. Every detail within reach.", Eyebrow = "STUDIO / GETTING STARTED"})
local player = window:AddTab("Player", {Description = "A library playground for state and numerical controls."})
local visuals = window:AddTab("Visuals", {Description = "Explore the presentation controls. No game effects."})

local interaction = overview:AddSection("Interaction", {Tag = "LIVE PREVIEW"})
local enabled = interaction:AddToggle({Name = "Enable workspace", Description = "Keep your current session active.", Default = true,
    Callback = function(value) print("[Lumi demo] enabled", value) end})
local intensity = interaction:AddSlider({Name = "Intensity", Description = "Set the strength of the preview.", Min = 0, Max = 100, Default = 65, Suffix = "%",
    Callback = function(value) print("[Lumi demo] intensity", value) end})
local mode = interaction:AddDropdown({Name = "Interaction mode", Description = "Choose how you want to work.", Values = {"Balanced", "Smooth", "Precise"}, Default = "Balanced",
    Callback = function(value) print("[Lumi demo] mode", value) end})
local tools = overview:AddSection("Session tools", {Tag = "LOCAL SESSION"})
tools:AddButton({Name = "Preview action", Description = "Try a protected, placeholder callback.", Action = "Run preview",
    Callback = function() print("[Lumi demo] preview complete") end})
tools:AddButton({Name = "Restore defaults", Description = "Reset the three properties above.", Action = "Restore",
    Callback = function() enabled:Set(true, true); intensity:Set(65, true); mode:Set("Balanced", true); intensity:Focus() end})

local values = player:AddSection("Input laboratory", {Tag = "PLACEHOLDERS"})
values:AddToggle({Name = "Input preview", Description = "A sample boolean, independent of gameplay.", Default = false})
values:AddSlider({Name = "Response", Description = "A compact numerical property.", Min = 1, Max = 10, Default = 4})
values:AddDropdown({Name = "Profile", Description = "A single available option.", Values = {"Local preview"}})
local safety = player:AddSection("Range boundaries", {Tag = "FIXED VALUE"})
safety:AddSlider({Name = "Fixed range", Description = "Equal bounds remain a fixed value.", Min = 10, Max = 10, Default = 100})
safety:AddButton({Name = "Inspect input", Description = "Exercises a placeholder action.", Action = "Inspect"})

local presentation = visuals:AddSection("Presentation", {Tag = "UI ONLY"})
presentation:AddToggle({Name = "Overlay preview", Description = "A demo state. No game overlay is created.", Default = false})
presentation:AddDropdown({Name = "Style sample", Description = "Compare selection states.", Values = {"Lumi", "Minimal", "Compact"}})
presentation:AddSlider({Name = "Detail", Description = "Try dragging or enter a precise number.", Min = 0, Max = 1, Step = 0.05, Default = 0.7})
local lists = visuals:AddSection("Selection states", {Tag = "POPOVERS"})
lists:AddDropdown({Name = "Empty collection", Description = "A deliberate empty state.", Values = {}})
lists:AddDropdown({Name = "Material sample", Description = "A longer, scrollable option list.", Values = {"Linen", "Sand", "Parchment", "Clay", "Taupe", "Walnut", "Charcoal", "Graphite", "Ash", "Cream", "Ivory", "Oat"}})

intensity:Focus()
print("[Lumi UI] Studio visual pilot v" .. Lumi.Version .. " loaded")
return Lumi

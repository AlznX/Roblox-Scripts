local player = game.Players.LocalPlayer
print("Hello " .. player.Name)

-- Your actual script code here
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Script Loaded";
    Text = "Welcome!";
})

-- All your functions, variables, everything
local function doSomething()
    -- your code
end

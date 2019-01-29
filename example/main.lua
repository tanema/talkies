package.path = package.path .. ";../?.lua"
local Talkies = require("talkies")

function love.load()
  -- The FontStruction “Pixel UniCode” (https://fontstruct.com/fontstructions/show/908795)
  -- by “ivancr72” is licensed under a Creative Commons Attribution license
  -- (http://creativecommons.org/licenses/by/3.0/)
  local pixelFont = love.graphics.newFont("assets/fonts/Pixel UniCode.ttf", 32)
  pixelFont:setFallbacks(love.graphics.newFont("assets/fonts/JPfallback.ttf", 32)) -- Add font fallbacks for Japanese characters
  Talkies.setFont(pixelFont)

  -- Audio from bfxr (https://www.bfxr.net/)
  Talkies.typeSound = love.audio.newSource("assets/sfx/typeSound.wav", "static")
  Talkies.optionOnSelectSound = love.audio.newSource("assets/sfx/optionSelect.wav", "static")
  Talkies.optionSwitchSound = love.audio.newSource("assets/sfx/optionSwitch.wav", "static")

  math.randomseed(os.time())
  rand()

  -- Set up our image for image argument in Talkies.new config table
  avatar = love.graphics.newImage("assets/Obey_Me.png")

  -- Put some messages into the talkies queue
  Talkies.new("Möan.lua", "Hello World!", {image=avatar})
  Talkies.new( "Tutorial",
    {"Möan.lua is a simple to use messagebox library, it includes;", "Multiple choices,--UTF8 text,--Pauses, --Onstart/Oncomplete functions,--Complete customization,--Variable typing speeds umongst other things."},
    {image=avatar, onstart=function() rand() end})
  Talkies.new("Tutorial", "Typing sound is aligned with the text speed...",
    {onstart=function() Talkies.setSpeed("slow") end, oncomplete=function() Talkies.setSpeed("fast") end})
  Talkies.new(
    "Tutorial",
    "Here's some options:",
    {
      options={
        {"Red", function() red() end},
        {"Blue", function() blue() end},
        {"Green", function() green() end}
      }
    })
end

function love.update(dt)
  Talkies.update(dt)
end

function love.draw()
  love.graphics.print(
    "Talkies demo" ..
    "'spacebar': Cycle through messages \n" ..
    "'c': Clear all messages \n" ..
    "'m': Add a single message to the queue \n", 10, 100)
  Talkies.draw()
end

function love.keyreleased(key)
  -- Pass keypresses to talkies
  Talkies.keyreleased(key)
  if key == "c" then Talkies.clearMessages()
  elseif key == "m" then Talkies.new("Title", "Message one", "two", "and three...", {onstart=function() rand() end})
  elseif key == "escape" then love.event.quit()
  end
end

-- DEMO FUNCTIONS ===========================================================================
function rand()
  love.graphics.setBackgroundColor(math.random(), math.random(), math.random())
end

function red()
  love.graphics.setBackgroundColor(1,0,0)
  Talkies.new("Hey!", "You picked Red!")
  moreMessages()
end

function blue()
  love.graphics.setBackgroundColor(0,0,1)
  Talkies.new("Hey!", "You picked Blue!")
  moreMessages()
end

function green()
  love.graphics.setBackgroundColor(0,1,0)
  Talkies.new("Hey!", "You picked Green!")
  moreMessages()
end

function moreMessages()
  Talkies.new("Message queue", "Each message is added to a \"message queue\", i.e. they're presented in the order that they're called. This is part of the design of Möan.lua", {onstart=function() rand() end})
  Talkies.new("UTF8 example", "アイ・ドーント・ノー・ジャパニーズ・ホープフリー・ジス・トランズレーター・ダズント・メス・ジス・アップ・トゥー・マッチ")
  Talkies.new("Goodbye", "See ya around!", {oncomplete=function() rand() end})
end

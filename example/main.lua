package.path = package.path .. ";../?.lua"
local talkies = require("talkies")

function love.load()
  -- The FontStruction “Pixel UniCode” (https://fontstruct.com/fontstructions/show/908795)
  -- by “ivancr72” is licensed under a Creative Commons Attribution license
  -- (http://creativecommons.org/licenses/by/3.0/)
  talkies.font = love.graphics.newFont("assets/fonts/Pixel UniCode.ttf", 32)
  talkies.font:setFallbacks(love.graphics.newFont("assets/fonts/JPfallback.ttf", 32)) -- Add font fallbacks for Japanese characters

  -- Audio from bfxr (https://www.bfxr.net/)
  talkies.typeSound = love.audio.newSource("assets/sfx/typeSound.wav", "static")
  talkies.optionOnSelectSound = love.audio.newSource("assets/sfx/optionSelect.wav", "static")
  talkies.optionSwitchSound = love.audio.newSource("assets/sfx/optionSwitch.wav", "static")

  math.randomseed(os.time())

  -- Set up our image for image argument in talkies.new config table
  avatar = love.graphics.newImage("assets/Obey_Me.png")

  -- Put some messages into the talkies queue
  talkies.new("Möan.lua", "Hello World!", {image=avatar})
  talkies.new( "Tutorial",
    {"Möan.lua is a simple to use messagebox library, it includes;", "Multiple choices,--UTF8 text,--Pauses, --Onstart/Oncomplete functions,--Complete customization,--Variable typing speeds umongst other things."},
    {image=avatar, onstart=function() rand() end})
  talkies.new("Tutorial", "Typing sound modulates with speed...",
    {onstart=function() talkies.setSpeed("slow") end, oncomplete=function() talkies.setSpeed("fast") end})
  talkies.new("Tutorial", "Here's some options:",
    {options={{"Red", function() red() end}, {"Blue", function() blue() end}, {"Green", function() green() end}}})
end

function love.update(dt)
  talkies.update(dt)
end

function love.draw()
  love.graphics.print(
    "Möan.lua demo - twentytwoo\n ==================\n" ..
    "'spacebar': Cycle through messages \n" ..
    "'f': Force message cycle \n" ..
    "'c': Clear all messages \n" ..
    "'m': Add a single message to the queue \n", 10, 100)
  talkies.draw()
end

function love.keyreleased(key)
  -- Pass keypresses to talkies
  talkies.keyreleased(key)
  if key == "f" then
    talkies.advanceMsg()
  elseif key == "c" then
    talkies.clearMessages()
  elseif key == "m" then
    talkies.new("Title", "Message one", "two", "and three...", {onstart=function() rand() end})
  end
end

-- DEMO FUNCTIONS ===========================================================================
function rand()
  love.graphics.setBackgroundColor(math.random(), math.random(), math.random())
end

function red()
  love.graphics.setBackgroundColor(1,0,0)
  talkies.new("Hey!", "You picked Red!")
  moreMessages()
end

function blue()
  love.graphics.setBackgroundColor(0,0,1)
  talkies.new("Hey!", "You picked Blue!")
  moreMessages()
end

function green()
  love.graphics.setBackgroundColor(0,1,0)
  talkies.new("Hey!", "You picked Green!")
  moreMessages()
end

function moreMessages()
  talkies.new("Message queue", "Each message is added to a \"message queue\", i.e. they're presented in the order that they're called. This is part of the design of Möan.lua", {onstart=function() rand() end})
  talkies.new("UTF8 example", "アイ・ドーント・ノー・ジャパニーズ・ホープフリー・ジス・トランズレーター・ダズント・メス・ジス・アップ・トゥー・マッチ")
  talkies.new("Goodbye", "See ya around!", {oncomplete=function() rand() end})
end

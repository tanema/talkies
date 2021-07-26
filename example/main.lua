package.path = package.path .. ";../?.lua"
local Talkies = require("talkies")
local Obey = require("other")


function love.load()
  -- The FontStruction “Pixel UniCode” (https://fontstruct.com/fontstructions/show/908795)
  -- by “ivancr72” is licensed under a Creative Commons Attribution license
  -- (http://creativecommons.org/licenses/by/3.0/)
  Talkies.font = love.graphics.newFont("assets/fonts/Pixel UniCode.ttf", 32)
  Talkies.font:setFallbacks(love.graphics.newFont("assets/fonts/JPfallback.ttf", 32)) -- Add font fallbacks for Japanese characters

  -- Audio from bfxr (https://www.bfxr.net/)
  Talkies.talkSound = love.audio.newSource("assets/sfx/typeSound.wav", "static")
  Talkies.optionOnSelectSound = love.audio.newSource("assets/sfx/optionSelect.wav", "static")
  Talkies.optionSwitchSound = love.audio.newSource("assets/sfx/optionSwitch.wav", "static")

  math.randomseed(os.time())
  rand()

  -- Put some messages into the queue from anywhere in your codebase
  Obey.sayHello()

  -- Put some messages into the talkies queue
  Talkies.say(
    "Tutorial",
    "Typing sound is aligned with the text speed...",
    { textSpeed = "slow" }
  )
  Talkies.say(
    "Tutorial",
    "Here's some options:",
    {
      options={
        {"Red", function() red() end},
        {"Blue", function() blue() end},
        {"Green", function() green() end}
      }
    }
  )
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

function love.keypressed(key)
  if key == "c" then Talkies.clearMessages()
  elseif key == "m" then Talkies.say("Title", {"Message one", "two", "and three..."}, {onstart=function() rand() end})
  elseif key == "escape" then love.event.quit()
  elseif key == "space" then Talkies.onAction()
  elseif key == "up" then Talkies.prevOption()
  elseif key == "down" then Talkies.nextOption()
  end
end

-- DEMO FUNCTIONS ===========================================================================
function rand()
  love.graphics.setBackgroundColor(math.random(), math.random(), math.random())
end

function red()
  love.graphics.setBackgroundColor(1,0,0)
  Talkies.say("Hey!", "You picked Red!")
  moreMessages()
end

function blue()
  love.graphics.setBackgroundColor(0,0,1)
  Talkies.say("Hey!", "You picked Blue!")
  moreMessages()
end

function green()
  love.graphics.setBackgroundColor(0,1,0)
  Talkies.say("Hey!", "You picked Green!")
  moreMessages()
end

function moreMessages()
  Talkies.say(
    "Message queue",
    "Each message is added to a \"message queue\", i.e. they're presented in the order that they're called. This is part of the design of Möan.lua",
    {
      onstart=function() rand() end
    }
  )
  Talkies.say(
    "UTF8 example",
    "アイ・ドーント・ノー・ジャパニーズ・ホープフリー・ジス・トランズレーター・ダズント・メス・ジス・アップ・トゥー・マッチ"
  )
  Obey.sayGoodbye()
end

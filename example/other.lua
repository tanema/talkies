local Talkies = require("talkies")

local Obey = {}
local avatar;

function Obey.sayHello()
  avatar = love.graphics.newImage("assets/Obey_Me.png")

  Talkies.new("Möan.lua", "Hello World!", {image=avatar})
  Talkies.new( "Tutorial",
    {
      "Talkies is a simple to use messagebox library, it includes;",
      "Multiple choices,--UTF8 text,--Pauses,--Onstart/Oncomplete functions,--Complete customization,--Variable typing speeds umongst other things."
    },
    {
      image=avatar,
      onstart=function() rand() end,
    }
  )
end

function Obey.sayGoodbye()
  Talkies.new(
    "Goodbye",
    "See ya around!",
    {
      image=avatar,
      oncomplete=function() rand() end
    }
  )
end

return Obey

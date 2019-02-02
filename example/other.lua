local Talkies = require("talkies")

local Obey = {}
local avatar;
local blop

function Obey.sayHello()
  blop = love.audio.newSource("assets/sfx/talk.wav", "static")
  avatar = love.graphics.newImage("assets/Obey_Me.png")

  Talkies.new("Möan.lua", "Hello World!", {
    image=avatar,
    talkSound=blop,
    typedNotTalked=false,
    textSpeed="slow"
  })
  Talkies.new( "Tutorial",
    {
      "Talkies is a simple to use messagebox library, it includes;",
      "Multiple choices,--UTF8 text,--Pauses,--Onstart/OnMessage/Oncomplete functions,--Complete customization,--Variable typing speeds umongst other things."
    },
    {
      image=avatar,
      talkSound=blop,
      typedNotTalked=false,
      onstart=function() rand() end,
      onmessage=function(left) print(left .. " messages left in the dialog") end,
    }
  )
end

function Obey.sayGoodbye()
  Talkies.new(
    "Goodbye",
    "See ya around!",
    {
      image=avatar,
      talkSound=blop,
      typedNotTalked=false,
      oncomplete=function() rand() end,
      titleColor = {1, 0, 0}
    }
  )
end

return Obey

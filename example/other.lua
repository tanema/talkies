local Talkies = require("talkies")

local Obey = {}
local avatar;
local blop

function Obey.sayHello()
  blop = love.audio.newSource("assets/sfx/talk.wav", "static")
  avatar = love.graphics.newImage("assets/Obey_Me.png")

  Talkies.say("Talkies.lua", "Hello World!", {
    image=avatar,
    talkSound=blop,
    typedNotTalked=false,
    textSpeed="slow"
  })
  Talkies.say( "Tutorial",
    {
      "Talkies is a simple to use messagebox library, it includes;",
      "Multiple choices,-- UTF8 text,-- Pauses,-- Onstart/OnMessage/Oncomplete functions,-- Complete customization,-- Variable typing speeds amongst other things."
    },
    {
      image=avatar,
      talkSound=blop,
      typedNotTalked=false,
      onstart = function(dialog)
        print("are we showing:", dialog:isShown())
        rand()
      end,
      onmessage = function(dialog, left)
        print(left .. " messages left in the dialog, is showing:", dialog:isShown())
      end,
      oncomplete = function(dialog)
        print("are we still showing:", dialog:isShown())
      end
    }
  )
end

function Obey.sayGoodbye()
  Talkies.say(
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

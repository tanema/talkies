--
-- Möan.lua
--
-- Copyright (c) 2017 twentytwoo
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--
-- currentMessage
--
local utf8 = require("utf8")
local PATH = (...):match('^(.*[%./])[^%.%/]+$') or ''

local Fifo = {}
function Fifo.new () return setmetatable({first=0,last=-1},{__index=Fifo}) end
function Fifo:peek() return self[self.first] end
function Fifo:len() return (self.last+1)-self.first end

function Fifo:push(value)
  self.last = self.last + 1
  self[self.last] = value
end

function Fifo:pop()
  if self.first > self.last then return end
  local value = self[self.first]
  self[self.first] = nil
  self.first = self.first + 1
  return value
end

local typeTimer    = 0.01 -- Timer to know when to print a new letter
local typeTimerMax = 0.01
local typing       = false
local typePosition = 0 -- Current position in the text
local indicatorTimer = 0 -- Initialise timer for the indicator

local Talkies = {
  _VERSION     = '0.0.1',
  _URL         = 'https://github.com/tanema/talkies',
  _DESCRIPTION = 'A simple messagebox system for LÖVE',

  printedText        = "",        -- Section of the text printed so far
  indicatorCharacter = ">",       -- Next message indicator
  optionCharacter    = "- ",      -- Option select character
  indicatorDelay     = 100,        -- Delay between each flash of indicator
  selectButton       = "space",   -- Key that advances message
  typeSpeed          = typeTimer, -- Delay per character typed out
  font               = love.graphics.newFont(),
  fontHeight         = love.graphics.newFont():getHeight(" "),

  dialogs            = Fifo.new(),
}

function Talkies.new(title, messages, config)
  config = config or {}
  if type(messages) ~= "table" then
    messages = { messages }
  end

  if Talkies.autoWrap then
    for i=1, #messages do
      messages[i] = Talkies.wordwrap(messages[i], 65)
    end
  end

  -- Insert the Talkies.new into its own instance (table)
  Talkies.dialogs:push({
    title      = title,
    messages   = messages,
    titleColor = config.titleColor,
    boxColor   = config.boxColor,
    image      = config.image,
    options    = config.options,
    onstart    = config.onstart or function() end,
    oncomplete = config.oncomplete or function() end,

    msgIndex      = 1,
    optionIndex = 1,

    showOptions = function(dialog) return dialog:nextMessage() == nil and type(dialog.options) == "table" end,
    currentMessage = function(dialog) return dialog.messages[dialog.msgIndex] end,
    nextMessage = function(dialog) return dialog.messages[dialog.msgIndex+1] end,
  })

  -- Only run .onstart()/setup if first message instance on first Talkies.new
  -- Prevents onstart=Talkies.new(... recursion crashing the game.
  if Talkies.dialogs:len() == 1 then
    -- Set the first message up, after this is set up via advanceMsg()
    typePosition = 0
    Talkies.dialogs:peek().onstart()
  end
end

function Talkies.update(dt)
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end
  local currentMessage = currentDialog:currentMessage()

  -- Check if the output string is equal to final string, else we must be still typing it
  typing = (Talkies.printedText ~= currentMessage)

  -- Tiny timer for the message indicator
  if (Talkies.paused or not typing) then
    indicatorTimer = indicatorTimer + 1
    if indicatorTimer > Talkies.indicatorDelay then
      Talkies.showIndicator = not Talkies.showIndicator
      indicatorTimer = 0
    end
  else
    Talkies.showIndicator = false
  end

  -- Detect a 'pause' by checking the content of the last two characters in the printedText
  Talkies.paused = (string.sub(currentMessage, string.len(Talkies.printedText)+1, string.len(Talkies.printedText)+2) == "--")

  --https://www.reddit.com/r/love2d/comments/4185xi/quick_question_typing_effect/
  if typePosition <= string.len(currentMessage) then
    -- Only decrease the timer when not paused
    if not Talkies.paused then
      typeTimer = typeTimer - dt
    end

    -- Timer done, we need to print a new letter:
    -- Adjust position, use string.sub to get sub-string
    if typeTimer <= 0 then
      -- Only make the keypress sound if the next character is a letter
      if string.sub(currentMessage, typePosition, typePosition) ~= " " and typing then
        Talkies.playSound(Talkies.typeSound)
      end
      typeTimer = typeTimerMax
      typePosition = typePosition + 1

      -- UTF8 support, thanks @FluffySifilis
      local byteoffset = utf8.offset(currentMessage, typePosition)
      if byteoffset then
        Talkies.printedText = string.sub(currentMessage, 0, byteoffset - 1)
      end
    end
  end
end

function Talkies.advanceMsg()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end
  if currentDialog:nextMessage()  == nil then
    currentDialog.oncomplete()
    Talkies.dialogs:pop()
    typePosition = 0
    if Talkies.dialogs:len() == 0 then
      Talkies.clearMessages()
      return
    else
      Talkies.dialogs:peek().onstart()
    end
  else
    currentDialog.msgIndex = currentDialog.msgIndex  + 1
    typePosition = 0
  end
end

function Talkies.draw()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end

  love.graphics.push()
  love.graphics.setDefaultFilter("nearest", "nearest")

  local currentMessage = currentDialog:currentMessage()

  local scale = 0.26
  local padding = 10

  local boxH = 118
  local boxW = love.graphics.getWidth()-(2*padding)
  local boxX = padding
  local boxY = love.graphics.getHeight()-(boxH+padding)

  local imgX = (boxX+padding)*(1/scale)
  local imgY = (boxY+padding)*(1/scale)
  local imgW = 0
  local imgH = 0
  if currentDialog.image ~= nil then
    imgW = currentDialog.image:getWidth()
    imgH = currentDialog.image:getHeight()
  end

  local titleBoxW = Talkies.font:getWidth(currentDialog.title)+(2*padding)
  local titleBoxH = Talkies.fontHeight+padding
  local titleBoxX = boxX
  local titleBoxY = boxY-titleBoxH-(padding/2)

  local titleColor = currentDialog.titleColor or {255, 255, 255}
  local titleX = titleBoxX+padding
  local titleY = titleBoxY+2

  local textX = (imgX+imgW)/(1/scale)+padding
  local textY = boxY+1

  local optionsY = textY+Talkies.font:getHeight(Talkies.printedText)-(padding/1.6)
  local optionsSpace = Talkies.fontHeight/1.5

  local msgTextY = textY+Talkies.font:getHeight()/1.2
  local msgLimit = boxW-(imgW/(1/scale))-(4*padding)

  local messageColour = currentDialog.messageColor or {255, 255, 255}
  local boxColor = currentDialog.boxColor or { 0, 0, 0, 222 }

  love.graphics.setFont(Talkies.font)

  -- Message title
  love.graphics.setColor(boxColor)
  love.graphics.rectangle("fill", titleBoxX, titleBoxY, titleBoxW, titleBoxH)
  love.graphics.setColor(titleColor)
  love.graphics.print(currentDialog.title, titleX, titleY)

  -- Main message box
  love.graphics.setColor(boxColor)
  love.graphics.rectangle("fill", boxX, boxY, boxW, boxH)
  love.graphics.setColor(messageColour)

  -- Message avatar
  if currentDialog.image ~= nil then
    love.graphics.push()
      love.graphics.scale(scale, scale)
      love.graphics.draw(currentDialog.image, imgX, imgY)
    love.graphics.pop()
  end

  -- Message text
  if Talkies.autoWrap then
    love.graphics.print(Talkies.printedText, textX, textY)
  else
    love.graphics.printf(Talkies.printedText, textX, textY, msgLimit)
  end

  -- Message options (when shown)
  if currentDialog:showOptions() and typing == false then
    for k, option in pairs(currentDialog.options) do
      local prefix = k == currentDialog.optionIndex and Talkies.optionCharacter.." " or ""
      love.graphics.print(prefix .. option[1], textX+padding, optionsY+((k-1)*optionsSpace))
    end
  end

  -- Next message/continue indicator
  if Talkies.showIndicator then
    love.graphics.print(Talkies.indicatorCharacter, boxX+boxW-(2.5*padding), boxY+boxH-(padding/2)-Talkies.fontHeight)
  end

  love.graphics.pop()
end

function Talkies.keyreleased(key)
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end

  local currentMessage = currentDialog:currentMessage()

  if currentDialog:showOptions() then
    if key == Talkies.selectButton and not typing then
      if currentDialog:nextMessage() == nil then
        -- Execute the selected function
        for i=1, #currentDialog.options do
          if currentDialog.optionIndex == i then
            currentDialog.options[i][2]()
            Talkies.playSound(Talkies.optionSwitchSound)
          end
        end
      end
      -- Option selection
      elseif key == "down" or key == "s" then
        currentDialog.optionIndex = currentDialog.optionIndex + 1
        Talkies.playSound(Talkies.optionSwitchSound)
      elseif key == "up" or key == "w" then
        currentDialog.optionIndex = currentDialog.optionIndex - 1
        Talkies.playSound(Talkies.optionSwitchSound)
      end
      -- Return to top/bottom of options on overflow
      if currentDialog.optionIndex < 1 then
        currentDialog.optionIndex = #currentDialog.options
      elseif currentDialog.optionIndex > #currentDialog.options then
        currentDialog.optionIndex = 1
    end
  end
  -- Check if we're still typing, if we are we can skip it
  -- If not, then go to next message/instance
  if key == Talkies.selectButton then
    if Talkies.paused then
      -- Get the text left and right of "--"
      leftSide = string.sub(currentMessage, 1, string.len(Talkies.printedText))
      rightSide = string.sub(currentMessage, string.len(Talkies.printedText)+3, string.len(currentMessage))
      -- And then concatenate them, thanks @pfirsich
      currentDialog.messages[currentDialog.msgIndex] = leftSide .. " " .. rightSide
      -- Put the typerwriter back a bit and start up again
      typePosition = typePosition - 1
      typeTimer = 0
    else
      if typing == true then -- Skip the typing completely
        Talkies.printedText = currentMessage
        typePosition = string.len(currentMessage)
      else
        Talkies.advanceMsg()
      end
    end
  end
end

function Talkies.setSpeed(speed)
  if speed == "fast" then
    Talkies.typeSpeed = 0.01
  elseif speed == "medium" then
    Talkies.typeSpeed = 0.04
  elseif speed == "slow" then
    Talkies.typeSpeed = 0.08
  else
    assert(tonumber(speed), "Talkies.setSpeed() - Expected number, got " .. tostring(speed))
    Talkies.typeSpeed = speed
  end
  -- Update the timeout timer.
  typeTimerMax = Talkies.typeSpeed
end

function Talkies.setFont(font)
  Talkies.font = font
  Talkies.fontHeight = Talkies.font:getHeight(" ")
end

-- ripped from https://github.com/rxi/lume
function Talkies.wordwrap(str, limit)
  limit = limit or 72
  local check
  if type(limit) == "number" then
    check = function(s) return #s >= limit end
  else
    check = limit
  end
  local rtn = {}
  local line = ""
  for word, spaces in str:gmatch("(%S+)(%s*)") do
    local s = line .. word
    if check(s) then
      table.insert(rtn, line .. "\n")
      line = word
    else
      line = s
    end
    for c in spaces:gmatch(".") do
      if c == "\n" then
        table.insert(rtn, line .. "\n")
        line = ""
      else
        line = line .. c
      end
    end
  end
  table.insert(rtn, line)
  return table.concat(rtn)
end

function Talkies.playSound(sound)
  if type(sound) == "userdata" then
    sound:play()
  end
end

function Talkies.clearMessages()
  typing = false
  typePosition = 0
end

-- External UTF8 functions
-- https://github.com/alexander-yakushev/awesompd/blob/master/utf8.lua
function utf8.charbytes (s, i)
  -- argument defaults
  i = i or 1
  local c = string.byte(s, i)
  -- determine bytes needed for character, based on RFC 3629
  if c > 0 and c <= 127 then -- UTF8-1
    return 1
  elseif c >= 194 and c <= 223 then -- UTF8-2
    local c2 = string.byte(s, i + 1)
    return 2
  elseif c >= 224 and c <= 239 then -- UTF8-3
    local c2 = s:byte(i + 1)
    local c3 = s:byte(i + 2)
    return 3
  elseif c >= 240 and c <= 244 then -- UTF8-4
    local c2 = s:byte(i + 1)
    local c3 = s:byte(i + 2)
    local c4 = s:byte(i + 3)
    return 4
  end
end

function utf8.sub (s, i, j)
  if i == nil then return "" end
  j = j or -1

  local pos = 1
  local bytes = string.len(s)
  local len = 0

  -- only set l if i or j is negative
  local l = (i >= 0 and j >= 0) or utf8.len(s)
  local startChar = (i >= 0) and i or l + i + 1
  local endChar = (j >= 0) and j or l + j + 1

  -- can't have start before end!
  if startChar > endChar then return "" end

  -- byte offsets to pass to string.sub
  local startByte, endByte = 1, bytes
  while pos <= bytes do
    len = len + 1
    if len == startChar then startByte = pos end
    pos = pos + utf8.charbytes(s, pos)
    if len == endChar then
      endByte = pos - 1
      break
    end
  end
  return string.sub(s, startByte, endByte)
end

return Talkies

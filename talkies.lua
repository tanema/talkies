--
-- talkies
--
-- Copyright (c) 2017 twentytwoo, tanema
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
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

local Typer = {}
function Typer.new(max)
  local typer = setmetatable({timerMax = max},{__index=Typer})
  typer:reset()
  return typer
end

function Typer:reset()
  self.complete, self.paused = false, false
  self.timer = self.timerMax
  self.position = 0
end

function Typer:update(typeSound, msg, dt)
  if self.complete then
    return msg
  end

  if not self.paused then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      if string.sub(msg, self.position, self.position) ~= " " then
        playSound(typeSound)
      end
      self.timer = self.timerMax
      self.position = self.position + 1
    end
  end

  local byteoffset = utf8.offset(msg, self.position)
  local part = ""
  if byteoffset then
    part = string.sub(msg, 0, byteoffset - 1)
  end

  self.complete = (part == msg)
  self.paused = string.sub(msg, string.len(part)+1, string.len(part)+2) == "--"

  return part
end

function Typer:setSpeed(speed)
  if speed == "fast" then
    self.timerMax = 0.01
  elseif speed == "medium" then
    self.timerMax = 0.04
  elseif speed == "slow" then
    self.timerMax = 0.08
  else
    assert(tonumber(speed), "setSpeed() - Expected number, got " .. tostring(speed))
    self.timerMax = speed
  end
end

local indicatorTimer = 0     -- Initialise timer for the indicator

local Talkies = {
  _VERSION     = '0.0.1',
  _URL         = 'https://github.com/tanema/talkies',
  _DESCRIPTION = 'A simple messagebox system for LÖVE',

  indicatorCharacter = ">",       -- Next message indicator
  optionCharacter    = "- ",      -- Option select character
  indicatorDelay     = 100,       -- Delay between each flash of indicator
  selectButton       = "space",   -- Key that advances message
  typeSpeed          = typeTimer, -- Delay per character typed out
  font               = love.graphics.newFont(),
  fontHeight         = love.graphics.newFont():getHeight(" "),
  boxHeight          = 118,
  padding            = 10,
  autoWrap           = false,
  showIndicator      = false,

  dialogs            = Fifo.new(),
  typer              = Typer.new(0.01),
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
    title         = title,
    messages      = messages,
    titleColor    = config.titleColor or {255, 255, 255},
    messageColor  = config.messageColor or {255, 255, 255},
    boxColor      = config.boxColor or { 0, 0, 0, 222 },
    image         = config.image,
    options       = config.options,
    onstart       = config.onstart or function() end,
    oncomplete    = config.oncomplete or function() end,

    msgIndex      = 1,
    optionIndex   = 1,
    printedText   = "",

    showOptions = function(dialog) return dialog:nextMessage() == nil and type(dialog.options) == "table" end,
    currentMessage = function(dialog) return dialog.messages[dialog.msgIndex] end,
    nextMessage = function(dialog) return dialog.messages[dialog.msgIndex+1] end,
  })

  if Talkies.dialogs:len() == 1 then
    Talkies.dialogs:peek().onstart()
  end
end

function Talkies.update(dt)
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end

  -- Tiny timer for the message indicator
  if (Talkies.typer.paused or Talkies.typer.complete) then
    indicatorTimer = indicatorTimer + 1
    if indicatorTimer > Talkies.indicatorDelay then
      Talkies.showIndicator = not Talkies.showIndicator
      indicatorTimer = 0
    end
  else
    Talkies.showIndicator = false
  end

  currentDialog.printedText = Talkies.typer:update(Talkies.typeSound, currentDialog:currentMessage(), dt)
end

function Talkies.advanceMsg()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end
  if currentDialog:nextMessage()  == nil then
    currentDialog.oncomplete()
    Talkies.dialogs:pop()
    Talkies.typer:reset()
    if Talkies.dialogs:len() == 0 then
      Talkies.clearMessages()
      return
    else
      Talkies.dialogs:peek().onstart()
    end
  else
    currentDialog.msgIndex = currentDialog.msgIndex  + 1
    Talkies.typer:reset()
  end
end

function Talkies.draw()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end

  love.graphics.push()
  love.graphics.setDefaultFilter("nearest", "nearest")

  local currentMessage = currentDialog:currentMessage()

  -- message box
  local boxX = Talkies.padding
  local boxY = love.graphics.getHeight()-(Talkies.boxHeight+Talkies.padding)
  local boxW = love.graphics.getWidth()-(2*Talkies.padding)
  local boxH = Talkies.boxHeight

  -- image
  local imgX, imgY, imgW, imgScale = boxX+Talkies.padding, boxY+Talkies.padding, 0, 0
  if currentDialog.image ~= nil then
    imgScale = (Talkies.boxHeight - (Talkies.padding * 2)) / currentDialog.image:getHeight()
    imgW = currentDialog.image:getWidth() * imgScale
  end

  -- title box
  local titleBoxW = Talkies.font:getWidth(currentDialog.title)+(2*Talkies.padding)
  local titleBoxH = Talkies.fontHeight+Talkies.padding
  local titleBoxX = boxX
  local titleBoxY = boxY-titleBoxH-(Talkies.padding/2)
  local titleX = titleBoxX+Talkies.padding
  local titleY = titleBoxY+2

  local textX, textY = imgX + imgW + Talkies.padding, boxY + 1

  love.graphics.setFont(Talkies.font)

  -- Message title
  love.graphics.setColor(currentDialog.boxColor)
  love.graphics.rectangle("fill", titleBoxX, titleBoxY, titleBoxW, titleBoxH)
  love.graphics.setColor(currentDialog.titleColor)
  love.graphics.print(currentDialog.title, titleX, titleY)

  -- Main message box
  love.graphics.setColor(currentDialog.boxColor)
  love.graphics.rectangle("fill", boxX, boxY, boxW, boxH)

  -- Message avatar
  if currentDialog.image ~= nil then
    love.graphics.push()
      love.graphics.setColor(255, 255, 255)
      love.graphics.draw(currentDialog.image, imgX, imgY, 0, imgScale, imgScale)
    love.graphics.pop()
  end

  -- Message text
  love.graphics.setColor(currentDialog.messageColor)
  if Talkies.autoWrap then
    love.graphics.print(currentDialog.printedText, textX, textY)
  else
    love.graphics.printf(currentDialog.printedText, textX, textY, boxW - imgW - (4 * Talkies.padding))
  end

  -- Message options (when shown)
  if currentDialog:showOptions() and Talkies.typer.complete then
    local optionsY = textY+Talkies.font:getHeight(currentDialog.printedText)-(Talkies.padding/1.6)
    local optionsSpace = Talkies.fontHeight/1.5
    for k, option in pairs(currentDialog.options) do
      local prefix = k == currentDialog.optionIndex and Talkies.optionCharacter.." " or ""
      love.graphics.print(prefix .. option[1], textX+Talkies.padding, optionsY+((k-1)*optionsSpace))
    end
  end

  -- Next message/continue indicator
  if Talkies.showIndicator then
    love.graphics.print(Talkies.indicatorCharacter, boxX+boxW-(2.5*Talkies.padding), boxY+boxH-(Talkies.padding/2)-Talkies.fontHeight)
  end

  love.graphics.pop()
end

function Talkies.keyreleased(key)
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end

  local currentMessage = currentDialog:currentMessage()

  if currentDialog:showOptions() then
    if key == Talkies.selectButton and Talkies.typer.complete then
      if currentDialog:nextMessage() == nil then
        -- Execute the selected function
        for i=1, #currentDialog.options do
          if currentDialog.optionIndex == i then
            currentDialog.options[i][2]()
            playSound(Talkies.optionSwitchSound)
          end
        end
      end
      -- Option selection
      elseif key == "down" or key == "s" then
        currentDialog.optionIndex = currentDialog.optionIndex + 1
        playSound(Talkies.optionSwitchSound)
      elseif key == "up" or key == "w" then
        currentDialog.optionIndex = currentDialog.optionIndex - 1
        playSound(Talkies.optionSwitchSound)
      end
      -- Return to top/bottom of options on overflow
      if currentDialog.optionIndex < 1 then
        currentDialog.optionIndex = #currentDialog.options
      elseif currentDialog.optionIndex > #currentDialog.options then
        currentDialog.optionIndex = 1
    end
  end
  if key == Talkies.selectButton then
    if Talkies.typer.paused then
      currentDialog.messages[currentDialog.msgIndex] = currentMessage:gsub("-+", " ", 1)
      Talkies.typer.paused = false
    else
      if not Talkies.typer.complete then
        Talkies.typer.complete = true
      else
        Talkies.advanceMsg()
      end
    end
  end
end

function Talkies.setSpeed(speed)
  Talkies.typer:setSpeed(speed)
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

function playSound(sound)
  if type(sound) == "userdata" then
    sound:play()
  end
end

function Talkies.clearMessages()
  Talkies.dialogs = Fifo.new()
  Talkies.typer:reset()
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

--
-- talkies
--
-- Copyright (c) 2017 twentytwoo, tanema
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--
local utf8 = require("utf8")

local Fifo = {}
function Fifo.new () return setmetatable({first=1,last=0},{__index=Fifo}) end
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
function Typer.new(msg, time)
  return setmetatable({
    msg = msg, complete = false, paused = false,
    timer = time, max = time, position = 0, visible = "",
  },{__index=Typer})
end

function Typer:resume()
  if not self.paused then return end
  self.msg = self.msg:gsub("-+", " ", 1)
  self.paused = false
end

function Typer:finish()
  if self.complete then return end
  self.visible = self.msg:gsub("-+", " ")
  self.complete = true
end

function Typer:update(dt)
  local typed = false
  if self.complete then return typed end
  if not self.paused then
    self.timer = self.timer - dt
    if self.timer <= 0 then
      typed = string.sub(self.msg, self.position, self.position) ~= " "
      self.position = self.position + 1
      self.timer = self.max
    end
  end
  self.visible = string.sub(self.msg, 0, utf8.offset(self.msg, self.position) - 1)
  self.complete = (self.visible == self.msg)
  self.paused = string.sub(self.msg, string.len(self.visible)+1, string.len(self.visible)+2) == "--"
  return typed
end

function parseSpeed(speed)
  if speed == "fast" then return 0.01
  elseif speed == "medium" then return 0.04
  elseif speed == "slow" then return 0.08
  else
    assert(tonumber(speed), "setSpeed() - Expected number, got " .. tostring(speed))
    return speed
  end
end

local Talkies = {
  _VERSION     = '0.0.1',
  _URL         = 'https://github.com/tanema/talkies',
  _DESCRIPTION = 'A simple messagebox system for LÖVE',

  indicatorCharacter = "▶",
  optionCharacter    = "→",
  padding            = 10,
  typeSound          = nil,
  optionSwitchSound  = nil,
  font               = love.graphics.newFont(),

  indicatorTimer     = 0,
  indicatorDelay     = 200,
  showIndicator      = false,
  fontHeight         = love.graphics.newFont():getHeight(" "),
  defaultSpeed       = 0.01,
  dialogs            = Fifo.new(),
}

function Talkies.new(title, messages, config)
  config = config or {}
  if type(messages) ~= "table" then
    messages = { messages }
  end

  msgFifo = Fifo.new()
  for i=1, #messages do
    msgFifo:push(Typer.new(messages[i], parseSpeed(config.speed or Talkies.defaultSpeed)))
  end

  -- Insert the Talkies.new into its own instance (table)
  Talkies.dialogs:push({
    title         = title,
    messages      = msgFifo,
    titleColor    = config.titleColor or {255, 255, 255},
    messageColor  = config.messageColor or {255, 255, 255},
    boxColor      = config.boxColor or { 0, 0, 0, 222 },
    image         = config.image,
    options       = config.options,
    onstart       = config.onstart or function() end,
    onmessage     = config.onmessage or function() end,
    oncomplete    = config.oncomplete or function() end,

    optionIndex   = 1,

    showOptions = function(dialog) return dialog.messages:len() == 1 and type(dialog.options) == "table" end,
  })

  if Talkies.dialogs:len() == 1 then
    Talkies.dialogs:peek().onstart()
  end
end

function Talkies.update(dt)
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end
  local currentMessage = currentDialog.messages:peek()

  if currentMessage.paused or currentMessage.complete then
    Talkies.indicatorTimer = Talkies.indicatorTimer + 1
    if Talkies.indicatorTimer > Talkies.indicatorDelay then
      Talkies.showIndicator = not Talkies.showIndicator
      Talkies.indicatorTimer = 0
    end
  else
    Talkies.showIndicator = false
  end

  if currentMessage:update(dt) then playSound(Talkies.typeSound) end
end

function Talkies.advanceMsg()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end
  if currentDialog.messages:len()  == 1 then
    currentDialog.oncomplete()
    Talkies.dialogs:pop()
    if Talkies.dialogs:len() == 0 then
      Talkies.clearMessages()
    else
      Talkies.dialogs:peek().onstart()
    end
  end
  currentDialog.messages:pop()
  currentDialog.onmessage(currentDialog.messages:len())
end

function Talkies.draw()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end

  local currentMessage = currentDialog.messages:peek()

  love.graphics.push()
  love.graphics.setDefaultFilter("nearest", "nearest")

  local windowWidth, windowHeight = love.graphics.getDimensions( )

  -- message box
  local boxW = windowWidth-(2*Talkies.padding)
  local boxH = (windowHeight/3)-(2*Talkies.padding)
  local boxX = Talkies.padding
  local boxY = windowHeight-(boxH+Talkies.padding)

  -- image
  local imgX, imgY, imgW, imgScale = boxX+Talkies.padding, boxY+Talkies.padding, 0, 0
  if currentDialog.image ~= nil then
    imgScale = (boxH - (Talkies.padding * 2)) / currentDialog.image:getHeight()
    imgW = currentDialog.image:getWidth() * imgScale
  end

  -- title box
  local titleBoxW = Talkies.font:getWidth(currentDialog.title)+(2*Talkies.padding)
  local titleBoxH = Talkies.fontHeight+Talkies.padding
  local titleBoxY = boxY-titleBoxH-(Talkies.padding/2)
  local titleX, titleY = boxX + Talkies.padding, titleBoxY + 2
  local textX, textY = imgX + imgW + Talkies.padding, boxY + 1

  love.graphics.setFont(Talkies.font)

  -- Message title
  love.graphics.setColor(currentDialog.boxColor)
  love.graphics.rectangle("fill", boxX, titleBoxY, titleBoxW, titleBoxH)
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
  love.graphics.printf(currentMessage.visible, textX, textY, boxW - imgW - (4 * Talkies.padding))

  -- Message options (when shown)
  if currentDialog:showOptions() and currentMessage.complete then
    local optionsY = textY+Talkies.font:getHeight(currentMessage.visible)-(Talkies.padding/1.6)
    local optionLeftPad = Talkies.font:getWidth(Talkies.optionCharacter.." ")
    for k, option in pairs(currentDialog.options) do
      love.graphics.print(option[1], optionLeftPad+textX+Talkies.padding, optionsY+((k-1)*Talkies.fontHeight))
    end
    love.graphics.print(Talkies.optionCharacter.." ", textX+Talkies.padding, optionsY+((currentDialog.optionIndex-1)*Talkies.fontHeight))
  end

  -- Next message/continue indicator
  if Talkies.showIndicator then
    love.graphics.print(Talkies.indicatorCharacter, boxX+boxW-(2.5*Talkies.padding), boxY+boxH-Talkies.fontHeight)
  end

  love.graphics.pop()
end

function Talkies.prevOption()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil or not currentDialog:showOptions() then return end
  currentDialog.optionIndex = currentDialog.optionIndex - 1
  if currentDialog.optionIndex < 1 then currentDialog.optionIndex = #currentDialog.options end
  playSound(Talkies.optionSwitchSound)
end

function Talkies.nextOption()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil or not currentDialog:showOptions() then return end
  currentDialog.optionIndex = currentDialog.optionIndex + 1
  if currentDialog.optionIndex > #currentDialog.options then currentDialog.optionIndex = 1 end
  playSound(Talkies.optionSwitchSound)
end

function Talkies.onAction()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end
  local currentMessage = currentDialog.messages:peek()

  if currentMessage.paused then currentMessage:resume()
  elseif not currentMessage.complete then currentMessage:finish()
  else
    if currentDialog:showOptions() then
      currentDialog.options[currentDialog.optionIndex][2]() -- Execute the selected function
      playSound(Talkies.optionSwitchSound)
    end
    Talkies.advanceMsg()
  end
end

function Talkies.setSpeed(speed)
  Talkies.defaultSpeed = parseSpeed(speed)
end

function Talkies.setFont(font)
  Talkies.font = font
  Talkies.fontHeight = Talkies.font:getHeight(" ")
end

function playSound(sound)
  if type(sound) == "userdata" then
    sound:play()
  end
end

function Talkies.clearMessages()
  Talkies.dialogs = Fifo.new()
end

return Talkies

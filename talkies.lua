--
-- talkies
--
-- Copyright (c) 2017 twentytwoo, tanema
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--
local utf8 = require("utf8")

local function playSound(sound, pitch)
  if type(sound) == "userdata" then
    sound:setPitch(pitch or 1)
    sound:play()
  end
end

local function parseSpeed(speed)
  if speed == "fast" then return 0.01
  elseif speed == "medium" then return 0.04
  elseif speed == "slow" then return 0.08
  else
    assert(tonumber(speed), "setSpeed() - Expected number, got " .. tostring(speed))
    return speed
  end
end

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
function Typer.new(msg, speed)
  local timeToType = parseSpeed(speed)
  return setmetatable({
    msg = msg, complete = false, paused = false,
    timer = timeToType, max = timeToType, position = 0, visible = "",
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

local Talkies = {
  _VERSION     = '0.0.1',
  _URL         = 'https://github.com/tanema/talkies',
  _DESCRIPTION = 'A simple messagebox system for LÖVE',

  -- Theme
  indicatorCharacter = ">",
  optionCharacter    = "-",
  padding            = 10,
  talkSound          = nil,
  optionSwitchSound  = nil,
  titleColor         = {1, 1, 1},
  messageColor       = {1, 1, 1},
  backgroundColor    = {0, 0, 0, 0.8},
  textSpeed          = 0.01,
  font               = love.graphics.newFont(),

  typedNotTalked     = true,
  pitchValues        = {0.7, 0.8, 1.0, 1.2, 1.3},

  indicatorTimer     = 0,
  indicatorDelay     = 3,
  showIndicator      = false,
  dialogs            = Fifo.new(),
}

function Talkies.say(title, messages, config)
  config = config or {}
  if type(messages) ~= "table" then
    messages = { messages }
  end

  msgFifo = Fifo.new()
  for i=1, #messages do
    msgFifo:push(Typer.new(messages[i], config.textSpeed or Talkies.textSpeed))
  end

  local font = config.font or Talkies.font

  -- Insert the Talkies.new into its own instance (table)
  local newDialog = {
    title         = title,
    messages      = msgFifo,
    image         = config.image,
    options       = config.options,
    onstart       = config.onstart or function(dialog) end,
    onmessage     = config.onmessage or function(dialog, left) end,
    oncomplete    = config.oncomplete or function(dialog) end,

    -- theme
    indicatorCharacter = config.indicatorCharacter or Talkies.indicatorCharacter,
    optionCharacter    = config.optionCharacter or Talkies.optionCharacter,
    padding            = config.padding or Talkies.padding,
    talkSound          = config.talkSound or Talkies.talkSound,
    optionSwitchSound  = config.optionSwitchSound or Talkies.optionSwitchSound,
    titleColor         = config.titleColor or Talkies.titleColor,
    messageColor       = config.messageColor or Talkies.messageColor,
    backgroundColor    = config.backgroundColor or Talkies.backgroundColor,
    font               = font,
    fontHeight         = font:getHeight(" "),
    typedNotTalked     = config.typedNotTalked == nil and Talkies.typedNotTalked or config.typedNotTalked,
    pitchValues        = config.pitchValues or Talkies.pitchValues,

    optionIndex   = 1,

    showOptions = function(dialog) return dialog.messages:len() == 1 and type(dialog.options) == "table" end,
    isShown     = function(dialog) return Talkies.dialogs:peek() == dialog end
  }

  Talkies.dialogs:push(newDialog)
  if Talkies.dialogs:len() == 1 then
    Talkies.dialogs:peek():onstart()
  end

  return newDialog
end

function Talkies.update(dt)
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end
  local currentMessage = currentDialog.messages:peek()

  if currentMessage.paused or currentMessage.complete then
    Talkies.indicatorTimer = Talkies.indicatorTimer + (10 * dt)
    if Talkies.indicatorTimer > Talkies.indicatorDelay then
      Talkies.showIndicator = not Talkies.showIndicator
      Talkies.indicatorTimer = 0
    end
  else
    Talkies.showIndicator = false
  end

  if currentMessage:update(dt) then
    if currentDialog.typedNotTalked then
      playSound(currentDialog.talkSound)
    elseif not currentDialog.talkSound:isPlaying() then
      local pitch = currentDialog.pitchValues[math.random(#currentDialog.pitchValues)]
      playSound(currentDialog.talkSound, pitch)
    end
  end
end

function Talkies.advanceMsg()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end
  currentDialog:onmessage(currentDialog.messages:len() - 1)
  if currentDialog.messages:len() == 1 then
    Talkies.dialogs:pop()
    currentDialog:oncomplete()
    if Talkies.dialogs:len() == 0 then
      Talkies.clearMessages()
    else
      Talkies.dialogs:peek():onstart()
    end
  end
  currentDialog.messages:pop()
end

function Talkies.isOpen()
  return Talkies.dialogs:peek() ~= nil
end

function Talkies.draw()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil then return end

  local currentMessage = currentDialog.messages:peek()

  love.graphics.push()
  love.graphics.setDefaultFilter("nearest", "nearest")

  local function getDimensions()
    local canvas = love.graphics.getCanvas()
    if canvas then
      return canvas:getDimensions()
    end
    return love.graphics.getDimensions()
  end

  local windowWidth, windowHeight = getDimensions()

  -- message box
  local boxW = windowWidth-(2*currentDialog.padding)
  local boxH = (windowHeight/3)-(2*currentDialog.padding)
  local boxX = currentDialog.padding
  local boxY = windowHeight-(boxH+currentDialog.padding)

  -- image
  local imgX, imgY, imgW, imgScale = boxX+currentDialog.padding, boxY+currentDialog.padding, 0, 0
  if currentDialog.image ~= nil then
    imgScale = (boxH - (currentDialog.padding * 2)) / currentDialog.image:getHeight()
    imgW = currentDialog.image:getWidth() * imgScale
  end

  -- title box
  local titleBoxW = currentDialog.font:getWidth(currentDialog.title)+(2*currentDialog.padding)
  local titleBoxH = currentDialog.fontHeight+currentDialog.padding
  local titleBoxY = boxY-titleBoxH-(currentDialog.padding/2)
  local titleX, titleY = boxX + currentDialog.padding, titleBoxY + 2
  local textX, textY = imgX + imgW + currentDialog.padding, boxY + 1

  love.graphics.setFont(currentDialog.font)

  -- Message title
  love.graphics.setColor(currentDialog.backgroundColor)
  love.graphics.rectangle("fill", boxX, titleBoxY, titleBoxW, titleBoxH)
  love.graphics.setColor(currentDialog.titleColor)
  love.graphics.print(currentDialog.title, titleX, titleY)

  -- Main message box
  love.graphics.setColor(currentDialog.backgroundColor)
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
  love.graphics.printf(currentMessage.visible, textX, textY, boxW - imgW - (4 * currentDialog.padding))

  -- Message options (when shown)
  if currentDialog:showOptions() and currentMessage.complete then
    local optionsY = textY+currentDialog.font:getHeight(currentMessage.visible)-(currentDialog.padding/1.6)
    local optionLeftPad = currentDialog.font:getWidth(currentDialog.optionCharacter.." ")
    for k, option in pairs(currentDialog.options) do
      love.graphics.print(option[1], optionLeftPad+textX+currentDialog.padding, optionsY+((k-1)*currentDialog.fontHeight))
    end
    love.graphics.print(
      currentDialog.optionCharacter.." ",
      textX+currentDialog.padding,
      optionsY+((currentDialog.optionIndex-1)*currentDialog.fontHeight))
  end

  -- Next message/continue indicator
  if Talkies.showIndicator then
    love.graphics.print(currentDialog.indicatorCharacter, boxX+boxW-(2.5*currentDialog.padding), boxY+boxH-currentDialog.fontHeight)
  end

  love.graphics.pop()
end

function Talkies.prevOption()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil or not currentDialog:showOptions() then return end
  currentDialog.optionIndex = currentDialog.optionIndex - 1
  if currentDialog.optionIndex < 1 then currentDialog.optionIndex = #currentDialog.options end
  playSound(currentDialog.optionSwitchSound)
end

function Talkies.nextOption()
  local currentDialog = Talkies.dialogs:peek()
  if currentDialog == nil or not currentDialog:showOptions() then return end
  currentDialog.optionIndex = currentDialog.optionIndex + 1
  if currentDialog.optionIndex > #currentDialog.options then currentDialog.optionIndex = 1 end
  playSound(currentDialog.optionSwitchSound)
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
      playSound(currentDialog.optionSwitchSound)
    end
    Talkies.advanceMsg()
  end
end

function Talkies.clearMessages()
  Talkies.dialogs = Fifo.new()
end

return Talkies

-- Preset compatibility check
assert(
    "Version 4.0.0 or higher is required"
)
-- Change this to false for creating Continuum Version
-- That's all that should be needed. The samce OVerlay preset is used for both  
local config = {
    osmose_enabled = false
}
if config.osmose_enabled then
    info.setText("Osmose V1.0")
else
    info.setText("Continuum V1.0")
end

-- Some code will change based on Osmose version or not.
local monoSwitch = false -- Default Mono Switch off
local monoMode = 0 -- Default Portamento
local monoInterval = 1 -- default
local splitPoint = 60 -- default split
local setTuning = 0 -- Equal Temperament default

-- For getting preset name
nameInProgress = false
presetLoaded = false
curPresetName = ""
OVERLAYNAME = "dualwavecont"

-- Global Constants
local CONTROL_CHANGE_MSB_INC = 86
local CONTROL_CHANGE_MSB_DEC = 97
local DEVICE_PORT = PORT_1
local DEVICE_CHANNEL = 1
local RECIRC_CODE = 62
local MATRIX_POKE = 20
local FORMULA_POKE = 19
local POKE_CHANNEL = 16

-- Start of User Controls - they are all sequential
local NUMUSERRECS = 30 -- NUmber of User configuration records
local USER_START = 181
-- Current user control being edited/stored - default none
local curUserIndex = 0
local curUserCtrl = 0
local curName = ""
local curLet = ""
local nameCtrl = controls.get(157)

-- CC86 Macros
local m7 = 40
local m8 = 41
local m9 = 42
local m10 = 43
local m11 = 44
local m12 = 45
local m13 = 46
local m14 = 47
local m15 = 48
local m16 = 49
local m17 = 50
local m18 = 51
local m19 = 52
local m20 = 53
local m21 = 54
local m22 = 55
local m23 = 56
local m24 = 57
local m25 = 58
local m26 = 59
local m27 = 60
local m28 = 61
local m29 = 62
local m30 = 63
local m31 = 102
local m32 = 103
local m33 = 104
local m34 = 105
local m35 = 106
local m36 = 107
local m37 = 108
local m38 = 109
local m39 = 110
local m40 = 111
local m41 = 112
local m42 = 113
local m43 = 114
local m44 = 115
local m45 = 116
local m46 = 117
local m47 = 118
local m48 = 119
local m49 = 12
local m50 = 13
local m51 = 14

local prevValueMsb = 0
local CC14Scale = .000061036 -- 0.5 = .000061036 * (.5 * 16384)
local CC14bits = 16384
local DWInitialized = false -- Use so the few ON=1/OFF=0 controls don't run some code on startup

-- Define initial Configuration - used for Reset
    initRec = {
    -- Main page
      saved = 0,
      name = "",
      waveType1 = 0, -- Saw
      waveType2 = 0, -- Saw
      waveFreq1 = 0, -- X Freq
      waveFreq2 = 0, -- X Freq
      duty1 = 8192, -- 0
      duty2 = 8192, -- 0
      ampWeight1 = 8192, -- mid
      ampWeight2 = 8192, -- mid
      detune1 = 8192, -- 0
      detune2 = 8192, -- 0
      filterAmt1 = 8192, -- 0
      filterAmt2 = 8192, -- 0
      filterType1 = 0, -- LPF
      filterType2 = 0, -- LPF
      cascade1 = 0, -- 12dB/Oct
      cascade2 = 0, -- 12dB/Oct
      cutoff1 = 9200, -- 0
      cutoff2 = 9200, -- 0
      resonance1 = 9200, -- 0
      resonance2 = 9200, -- 0
      filterShape1 = 0, -- Ramp Up
      filterShape2 = 0, -- Ramp Up
      envSpeed1 = 9200, -- 0
      envSpeed2 = 9200, -- 0
      envRelease1 = 0, -- 0
      envRelease2 = 8192, -- 0
      tremSpeedL = 8192, -- 0
      tremSpeedR = 8192, -- 0
      tremWidthL = 8192, -- 0
      tremWidthR = 8192, -- 0
      waveMix1 = 16383, -- default Max
      waveMix2 = 16383, -- default Max
      extraHarm1 = 0, -- Off
      extraHarm2 = 0, -- Off
      addNoise1 = 8192, -- 0
      addNoise2 = 8192, -- 0
    -- Effects Page
      convIR1 = 6, -- Wood 
      convIR2 = 8, -- Fiber 
      convIR3 = 7, -- MetalBright
      convIR4 = 0, -- Waterphone1
      convMix = 8192, -- 0
      convIndex = 8192, -- 0
      recircEnable = 0, 
      reverbType = 0, -- Short Reverb
      reverbMix = 60, 
      reverbR4 = 50,
      reverbR3 = 15,
      reverbR2 = 0,
      reverbR1 = 0,
      reverbR5 = 0,
      reverbR6 = 0,
      eqMix = 0,
      eqTilt = 0,
      eqFreq = 0,
      compOrTanh = 0, -- Comp, 1 = TANH    
      compMix = 0, -- or TANH Mix
      compThresh = 64, -- or TANH Drive
      compAttack = 64, -- TANH unused
      compRatio = 64, -- or TAN Makeup
      delayOut = 8192, -- 0
      delayFeedback = 8192, -- 0
      delayTap1 = 8192, -- 0
      delayTap2 = 8192, -- 0
      autoTap34 = 0, -- off, 1 = on
      delayTime = 3, -- 200 ms
      convMorphSpeed = 8192, -- 0
      convMorphRange = 8192, -- 0
      convMorphShape = 0, -- Ramp Up
      convYControl = 8192, -- 0/None
      filterIter1 = 0, -- off, 1 = on
      filterIter2 = 0, -- off, 1 = on
    -- Transpose/Tuning Page
      transposeInt = 60, -- Transpose off (Middle C set)
      masterDetune = 64, -- No detune (range 4..124)
      tuningIndex = 0, -- Equal temperament
    -- Common Controls Page (Panic and Reset buttons arenot stored)
      monoSwitch = 0, -- Off
      monoInterval = 1, -- Default semitone
      monoMode = 0, -- Not used for Osmose
      splitPoint = 60, -- Not used for Osmose
      splitMode = 0, -- Not used for Osmose
      postGain = 64,
      preGain = 64,
      -- attenuation = 80, -- Not used for Osmose so set Continuum default
      YVolume =  16383,-- Change to 8192 for Continuum in save/restore
      roundRate = 0, -- Continuum 
      roundInitial = 0, -- Continuum 
    -- Additional Y & Z Trem Control
      YTremCtrl = 8192, -- Default Off
      ZTremCtrl = 16383 -- Default On
    }   

-- Define User Config Record that can change
curRec = {
    -- Main page
    saved = 0,
    name = "",
    waveType1 = 0, -- Saw
    waveType2 = 0, -- Saw
    waveFreq1 = 0, -- X Freq
    waveFreq2 = 0, -- X Freq
    duty1 = 8192, -- 0
    duty2 = 8192, -- 0
    ampWeight1 = 8192, -- mid
    ampWeight2 = 8192, -- mid
    detune1 = 8192, -- 0
    detune2 = 8192, -- 0
    filterAmt1 = 8192, -- 0
    filterAmt2 = 8192, -- 0
    filterType1 = 0, -- LPF
    filterType2 = 0, -- LPF
    cascade1 = 0, -- 12dB/Oct
    cascade2 = 0, -- 12dB/Oct
    cutoff1 = 8192, -- 0
    cutoff2 = 8192, -- 0
    resonance1 = 8192, -- 0
    resonance2 = 8192, -- 0
    filterShape1 = 0, -- Ramp Up
    filterShape2 = 0, -- Ramp Up
    envSpeed1 = 8192, -- 0
    envSpeed2 = 8192, -- 0
    envRelease1 = 0, -- 0
    envRelease2 = 8192, -- 0
    tremSpeedL = 8192, -- 0
    tremSpeedR = 8192, -- 0
    tremWidthL = 8192, -- 0
    tremWidthR = 8192, -- 0
    waveMix1 = 16383, -- default Max
    waveMix2 = 16383, -- default Max
    extraHarm1 = 0, -- Off
    extraHarm2 = 0, -- Off
    addNoise1 = 8192, -- 0
    addNoise2 = 8192, -- 0
    -- Effects Page
    convIR1 = 6, -- Wood 
    convIR2 = 8, -- Fiber 
    convIR3 = 7, -- MealBright
    convIR4 = 0, -- Watherphone1
    convMix = 8192, -- 0
    convIndex = 8192, -- 0
    recircEnable = 0, 
    reverbType = 0, -- Short Reverb
    reverbMix = 60, 
    reverbR4 = 50,
    reverbR3 = 15,
    reverbR2 = 0,
    reverbR1 = 0,
    reverbR5 = 0,
    reverbR6 = 0,
    eqMix = 0,
    eqTilt = 0,
    eqFreq = 0,
    comrOrTanh = 0, -- Comp, 1 = TANH    
    compMix = 0, -- or TANH Mix
    compThresh = 64, -- or TANH Drive
    compAttack = 64, -- TANH unused
    compRatio = 64, -- or TAN Makeup
    delayOut = 8192, -- 0
    delayFeedback = 8192, -- 0
    delayTap1 = 8192, -- 0
    delayTap2 = 8192, -- 0
    autoTap34 = 0, -- off, 1 = on
    delayTime = 3, -- 200 ms
    convMorphSpeed = 8192, -- 0
    convMorphRange = 8192, -- 0
    convMorphShape = 0, -- Ramp Up
    convYControl = 8192, -- 0/None
    filterIter1 = 0, -- off, 1 = on
    filterIter2 = 0, -- off, 1 = on
    -- Transpose/Tuning Page
    transposeInt = 60, -- Transpose off (Middle C set)
    masterDetune = 64, -- No detune (range 4..124)
    tuningIndex = 0, -- Equal temperament
    -- Common Controls Page (Panic and Reset buttons arenot stored)
    monoSwitch = 0, -- Off
    monoInterval = 1, -- Semitone
    monoMode = 0, -- Not used for Osmose
    splitPoint = 60, -- Not used for Osmose
    splitMode = 0, -- Not used for Osmose
    postGain = 64,
    preGain = 60,
    -- attenuation = 80, -- Not used for Osmose so set Continuum default
    YVolume =  16383,-- Change to 8192 for Continuum in save/restore
    roundRate = 0, -- Continuum 
    roundInitial = 0, -- Continuum
      -- Additional Y & Z Trem Control
    YTremCtrl = 8192, -- Default Off
    ZTremCtrl = 16383 -- Default On     
} 


-- Define the Array of Tables used to store USer configurations
-- Now define array of 30 preset Tables
-- Define the Table that will store user presets

userTable = {}

-- Do initial recall
recall(userTable)

-- Create and insert tables into the Table array if userTable not there
function restoreUserNames()
  local ctrl = 0 -- controls.get(USER_START)
  for i = 1, NUMUSERRECS do
    if (userTable[i].saved == 1) then
       ctrl = controls.get(i+USER_START-1)
       ctrl:setName(userTable[i].name)
    end
  end
end
-- Top Level Code 
if next (userTable) == nil then -- Persist JASON config not found
  print("Table not yet persisted - create it")
  info.setText("User Table Reinit") 
  for i = 1, NUMUSERRECS do    
-- Define User Config Record
    curUserRec = {
    -- Main page
      saved = 0,
      name = "",
      waveType1 = 0, -- Saw
      waveType2 = 0, -- Saw
      waveFreq1 = 0, -- X Freq
      waveFreq2 = 0, -- X Freq
      duty1 = 8192, -- 0
      duty2 = 8192, -- 0
      ampWeight1 = 8192, -- mid
      ampWeight2 = 8192, -- mid
      detune1 = 8192, -- 0
      detune2 = 8192, -- 0
      filterAmt1 = 8192, -- 0
      filterAmt2 = 8192, -- 0
      filterType1 = 0, -- LPF
      filterType2 = 0, -- LPF
      cascade1 = 0, -- 12dB/Oct
      cascade2 = 0, -- 12dB/Oct
      cutoff1 = 8192, -- 0
      cutoff2 = 8192, -- 0
      resonance1 = 8192, -- 0
      resonance2 = 8192, -- 0
      filterShape1 = 0, -- Ramp Up
      filterShape2 = 0, -- Ramp Up
      envSpeed1 = 8192, -- 0
      envSpeed2 = 8192, -- 0
      envRelease1 = 0, -- 0
      envRelease2 = 8192, -- 0
      tremSpeedL = 8192, -- 0
      tremSpeedR = 8192, -- 0
      tremWidthL = 8192, -- 0
      tremWidthR = 8192, -- 0
      waveMix1 = 16383, -- default Max
      waveMix2 = 16383, -- default Max
      extraHarm1 = 0, -- Off
      extraHarm2 = 0, -- Off
      addNoise1 = 8192, -- 0
      addNoise2 = 8192, -- 0
    -- Effects Page
      convIR1 = 6, -- Wood 
      convIR1 = 8, -- Fiber 
      convIR1 = 7, -- MealBright
      convIR1 = 0, -- Watherphone1
      convMix = 8192, -- 0
      convIndex = 8192, -- 0
      recircEnable = 0, 
      reverbType = 0, -- Short Reverb
      reverbMix = 60, 
      reverbR4 = 50,
      reverbR3 = 15,
      reverbR2 = 0,
      reverbR1 = 0,
      reverbR5 = 0,
      reverbR6 = 0,
      eqMix = 0,
      eqTilt = 0,
      eqFreq = 0,
      comrOrTanh = 0, -- Comp, 1 = TANH    
      compMix = 0, -- or TANH Mix
      compThresh = 64, -- or TANH Drive
      compAttack = 64, -- TANH unused
      compRatio = 64, -- or TAN Makeup
      delayOut = 8192, -- 0
      delayFeedback = 8192, -- 0
      delayTap1 = 8192, -- 0
      delayTap2 = 8192, -- 0
      autoTap34 = 0, -- off, 1 = on
      delayTime = 3, -- 200 ms
      convMorphSpeed = 8192, -- 0
      convMorphRange = 8192, -- 0
      convMorphShape = 0, -- Ramp Up
      convYControl = 8192, -- 0/None
      filterIter1 = 0, -- off, 1 = on
      filterIter2 = 0, -- off, 1 = on
    -- Transpose/Tuning Page
      transposeInt = 60, -- Transpose off (Middle C set)
      masterDetune = 64, -- No detune (range 4..124)
      tuningIndex = 0, -- Equal temperament
    -- Common Controls Page (Panic and Reset buttons arenot stored)
      monoSwitch = 0, -- Off
      monoInterval = 1, -- Semitone
      monoMode = 0, -- Not used for Osmose
      splitPoint = 60, -- Not used for Osmose
      splitMode = 0, -- Not used for Osmose
      postGain = 64,
      preGain = 64,
      -- attenuation = 80, -- Not used for Osmose so set Continuum default
      YVolume =  16383,-- Change to 8192 for Continuum in save/restore
      roundRate = 0, -- Continuum 
      roundInitial = 0, -- Continuum   
      -- Additional Y & Z Trem Control
      YTremCtrl = 8192, -- Default Off
      ZTremCtrl = 16383 -- Default On         
    }   
    table.insert(userTable, curUserRec) -- Install defaults= user records for entire table
  end
else -- Persist Table found
    print("Table persisted")
    info.setText("User Table Loaded")
 -- Restore User Config names
    restoreUserNames()  
end

function preset.onReady()
end

-- Initializae - User can load their previous configs to override
function initAll()
-- print("Dual Subtractive Overlay Loaded - Initializing all Macros to 14-bit zero")
-- Initial all 14-bit macros

-- Set iniital contol values
-- Mix to 100%
    local ctrl = controls.get(130)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(16383)
    ctrl = controls.get(131)
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(16383)
--[[
-- Set Filter mix to off - All raw
    ctrl = controls.get(15) -- Filter1 Mix
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(8192)
    ctrl = controls.get(16) -- Filter2 Mix
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()  
    ctrlMsg:setValue(8192) 

-- Basic Filter settings on so it won't be silent when swtiched to all filtered
    ctrl = controls.get(19) -- Cutoff Bank1
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(9200)
    ctrl = controls.get(28) -- Resonance Bank 1
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()  
    ctrlMsg:setValue(9200)    

    ctrl = controls.get(18) -- Cutoff Bank2
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(9200)
    ctrl = controls.get(29) -- Resonance Bank2
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(9200)
      
    ctrl = controls.get(21) -- Filter 1 Envelope Speed
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(9200)
    ctrl = controls.get(30) -- Filter 2 Envelope Speed
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(9200)  

-- Set all defaults in case Overlay Preset is saved with a different configuration
-- or is still active and set to non-default values when EL1 loads.
-- Set Wavebanks s Sawtooth
    matrixPoke (99, 0)
    matrixPoke (98, 0)
--  Set Default Octaves
    set86CCValue(m42, convert14Bits(0.0)) -- f1 = Fundamental
    set86CCValue(m7, convert14Bits(-1.0)) -- f2 = off
    set86CCValue(m8, convert14Bits(-1.0)) -- f3 = off
    set86CCValue(m43, convert14Bits(0.0)) -- f1 = Fundamental
    set86CCValue(m9, convert14Bits(-1.0)) -- f2 = off
    set86CCValue(m10, convert14Bits(-1.0)) -- f3 = off
--  Set default Filter and Cascade types
    matrixPoke (72, 5) -- Osc/Filter 1 = Low Pass
    matrixPoke (73, 5) -- Osc/Filter 1 = Low Pass    
    matrixPoke (77, 0) -- Osc/Filter1 = 12 dB/Oct
    matrixPoke (78, 0) -- Osc/Filter1 = 12 dB/Oct  
-- Set Filter Shapes
    formulaPoke (19, 50, 0) -- Ramp Up - Formula S
    formulaPoke (21, 50, 0) -- Ramp Up - Formula U
                  
--  Set Default Convolution types
    convolutionPoke(4, 6) -- Wood
    convolutionPoke(5, 8) -- Fiber
    convolutionPoke(6, 7) -- MetalBright
    convolutionPoke(7, 0) -- Waterphone 1
    ctrl = controls.get(53)
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(6) -- Set Control Wood     
    ctrl = controls.get(54)
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(8) -- Set Control FIber 
    ctrl = controls.get(120)
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(7) -- Set Control MetalBright 
    ctrl = controls.get(121)
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(0) -- Set Control Waterphone 1         
--  Set Reverb type
    matrixPoke (62, 0) -- Short Reverb
-- Set Harmonic Defaults
    set86CCValue(60, 8192)
    set86CCValue(61, 8192)

-- Wavebank Detuning off
    set86CCValue(44, 8192)
    set86CCValue(49, 8192)

-- Zero Out Weighting
    ctrl = controls.get(10) -- Cutoff Bank1
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(8192)
    set86CCValue(46, 8192)
    ctrl = controls.get(12) -- Cutoff Bank1
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(8192)
    set86CCValue(48, 8192)    

-- Default Filter Iteration Off
--]]
matrixPoke (100, 1) -- SG1 Single Cycle
matrixPoke (101, 1) -- SG2 Single Cycle
--[[
-- Set Tuning to zero point (64)
    -- midi.sendControlChange(DEVICE_PORT, 1, 10, 60)

-- Default Transpose off
   ctrl = controls.get(115)     
   ctrl:setName("TRANSPOSE OFF")
   midi.sendControlChange(DEVICE_PORT, 1, 8, 60) 

-- Master Tuning set mid 
   midi.sendControlChange(DEVICE_PORT, 1, 10, 64)   
-- Transposition Off, no masgter detuning

-- Set Delay default = 200ms and set control
   matrixPoke(105, 2)
   ctrl = controls.get(138)
   controlValue = ctrl:getValue("value")
   ctrlMsg = controlValue:getMessage() 
   ctrlMsg:setValue(2)    

-- Default Auto Tap off
     matrixPoke(107, 3)
     
-- Set Osmose vs Continuum Specific Parameters
-- Make Y dynamics control default to max for Osmose, Min for Continuum
--]]
   ctrl = controls.get(148)
   controlValue = ctrl:getValue("value")
   ctrlMsg = controlValue:getMessage()
if config.osmose_enabled then
      set86CCValue(117, 16383) 
      ctrlMsg:setValue(16383)
      ctrl:setVisible(true) -- Osmose Sees it      
else
      set86CCValue(117, 8192) 
      ctrlMsg:setValue(8192)
      ctrl:setVisible(false) -- Don't let Continuum users see it 
end       
-- Attenuation Invisible for Osmose (does not apply)
--[[
   ctrl = controls.get(137)
   controlValue = ctrl:getValue("value")
   ctrlMsg = controlValue:getMessage()

if config.osmose_enabled then  
   ctrlMsg:setValue(0) 
   ctrl:setVisible(false)
else
   ctrlMsg:setValue(80) 
   ctrl:setVisible(true)
end 
--]]  

-- Round Rate Invisible for Osmose (does not apply)
   ctrl = controls.get(153)
   controlValue = ctrl:getValue("value")
   ctrlMsg = controlValue:getMessage()   

if config.osmose_enabled then  
   ctrlMsg:setValue(0) 
   ctrl:setVisible(false)
else
   ctrlMsg:setValue(80) 
   ctrl:setVisible(true)
end  

-- Round Initial Invisible for Osmose (does not apply)
   ctrl = controls.get(156)
   controlValue = ctrl:getValue("value")
   ctrlMsg = controlValue:getMessage()   
   ctrlMsg:setValue(0) 
   
if config.osmose_enabled then  
   ctrl:setVisible(false)
else
   ctrl:setVisible(true)
end  

-- Mono Mode Invisible for Osmose - defaults Portamento (pressure glide)
   matrixPoke (46, monoMode) -- Default pressure glide
   ctrl = controls.get(144)  

if config.osmose_enabled then 
   ctrl:setVisible(false)
else
   ctrl:setVisible(true)
end
-- Mono Switch - Default Off
   ctrl = controls.get(116)      
   ctrl:setName("Mono Off")
   ctrl:setColor(WHITE)
   midi.sendControlChange(DEVICE_PORT, 1, 9, 0) 

-- Remove Rounding for Osmose
   ctrl = controls.get(153)   -- Round Rate
if config.osmose_enabled then   
   ctrl:setVisible(false)
else
   ctrl:setVisible(true)
end
   ctrl = controls.get(156)   -- Round Initial
if config.osmose_enabled then   
   ctrl:setVisible(false)
else
   ctrl:setVisible(true)
end

-- Default Mono Interval = 1 (does nothing if mono swtich not on)
--   matrixPoke(48, 1)

-- Default Split point = Middle C and Split off
-- matrixPoke(1, 0) -- Set Split Mode Off (turns of Osmose sound - no splits for Osmose)
-- matrixPoke(45, 60) -- Set Split interval = middle C
-- Make all splits invisible for now on Osmose - Leave header

  if config.osmose_enabled then
   ctrl = controls.get(124)
   ctrl:setVisible(false)
   ctrl = controls.get(126)
   ctrl:setVisible(false)      
  else
   ctrl = controls.get(124)
   ctrl:setVisible(true)
   ctrl = controls.get(126)
   ctrl:setVisible(true) 
  end

-- Default Attenuation for Continuum
--if  (config.osmose_enabled == false) then
--    midi.sendControlChange(DEVICE_PORT, 1, 27, 80) -- Attenuation
--end

-- Default Equal Temperament
    midi.sendControlChange(DEVICE_PORT, 1, 28, 0) -- Round Initial Off
    midi.sendControlChange(DEVICE_PORT, 1, 25, 0) -- Round Rate Off   
    midi.sendControlChange(DEVICE_PORT, 16, 51, 0) -- Tuning EQ Temp default

-- On startup load the default configuration
   restoreUserConfig (true)
   DWInitialized = true
end

-- Initialize the Overlay - might not be used
function preset.onLoad()
-- Start with main page
   pages.display(1)

-- Load current preset to get name - check for correct preset is in midi.message routine
   midi.sendControlChange(DEVICE_PORT, 16, 109, 16) -- Send get Current Preset Msg to get current preset name
end

function reInitialize()
end

-- Midi Processing for validating preest name
function midi.onMessage(midiInput, midiMessage) -- Process incoming Midi Message Events
  local msg = midiMessage
     if (msg.controllerNumber==56 and msg.value==0) then -- Current Name output in User list
           nameInProgress = true    
     end
     if (presetLoaded == false) then
       if (nameInProgress and msg.controllerNumber==56 and msg.value==127) then -- Stream Ends
          nameInProgress = false
          presetLoaded = true
          local tmpstr = ""
          -- print("NAME = "..curPresetName) -- debugit kram
            if (curPresetName == "" or curPresetName == "-") then
               curPresetName = "Empty"
            end
            if (string.len(curPresetName) > 12) then -- Check for "dualwaveos"
              -- print("CurName:|"..curName.."|") -- debugit kram
              local tmpstr = curPresetName
              curPresetName = string.sub(tmpstr, 1, 12)
            end
            -- Check if expected preset loaded
            if (curPresetName ~= "" and curPresetName~= OVERLAYNAME) then
              info.setText(".mid not loaded")
              local ctrl = controls.get(170)
              ctrl:setName(curPresetName)
              pages.display(6)
            else -- Right OVerlay preset loaded - can initial now
               initAll()
               info.setText("DualWave Loaded")
            end      
        end -- nameInProgress
      end -- presetloaded == false
end
function midi.onAfterTouchPoly(midiInput, channel, noteNumber, pressure) 
    if (nameInProgress) then -- Accumulate name in global preset name buffer
         curPresetName = curPresetName..string.char(noteNumber)..string.char(pressure)
    end
end      
-- Formatters
function formatFilterFreq(valueObject, value)
   local val = (((value-8192)/8192) * 8.0)+.05
    return(string.format("%.1f", val))
end

function formatResonance(valueObject, value)
   local val = 2-(((value-8192)/8192)*2) +.05
    return(string.format("%.2f", val))
end
function format0to1(valueObject, value)
   local val = (value-8192)/8192
    return(string.format("%.2f", val))
end
function format0to2(valueObject, value)
   local val = ((value-8192)/8192)*2
    return(string.format("%.2f", val))
end
function format0to3(valueObject, value)
   local val = ((value-8192)/8192)*3
    return(string.format("%.2f", val))
end
function format0to5(valueObject, value)
   local val = ((value-8192)/8192)*5
    return(string.format("%.2f", val))
end
function format0to8(valueObject, value)
   local val = ((value-8192)/8192)*8
    return(string.format("%.2f", val))
end
function format0to10(valueObject, value)
   local val = ((value-8192)/8192)*10
    return(string.format("%.2f", val))
end
function format0to100(valueObject, value)
   local val = (((value-8192)/8192)*100)
   if (val > 99.95) then 
      val = 100.0 
   end
   return(string.format("%.2f", val))
end
 

function convert14Bits (value) -- Convert input value range (-1..+1) to 14-bit value
  if (value < 0) then -- Covers values < 0.0
    return 8192 - (math.abs(value)* 8192)
  elseif (value < 1.0) then -- Covers values >=0 and < 1.0
      return 8192 + (value* 8192)
  else -- +1.0 case
    return 16383 -- Needed to avoid outputting 16384 which is > 14 bits
  end
end

-- Special function to reset after Delay output set to zero - clear voices of delay noise
function setDelay14w86(valueObject, value)
    local valueMsb = value >> 7
    local valueLsb = value & 0x7f
    local controlChangeLsb = valueObject:getMessage():getParameterNumber()

    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, 86, valueLsb)
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, controlChangeLsb, valueMsb)
    if (math.floor(value) == 8192) then
    -- Figure out what to reset
    end
end
-- Set Delay Time & Tap % Parameters
function setDelay(valueObject, value)
     local delayVal = valueObject:getMessage():getValue()
      matrixPoke(105, delayVal)
end
-- Variant of autoTap for user config
function restoreAutoTap34 (val)
  if (DWInitialized == false) then
    return
  end
  if (math.floor(val) == 1) then
     matrixPoke(107, 1)
  else
     matrixPoke(107, 3)
  end
end
-- Turn on Auto Tap 3/4 activation else default back to Submix L/R (which is not used)
function autoTap34 (valueObject, value)
  if (math.floor(value) == 1) then
     matrixPoke(107, 1)
  else
     matrixPoke(107, 3)
  end
end

function setTap1(valueObject, value)
     local tap1Val = valueObject:getMessage():getValue()
     local tap1Percent = math.floor(8192+(8192*tap1Val*.01))
     set86CCValue(111, value) -- Tap1 % = m40
end
function setTap2(valueObject, value)
     local tap2Val = valueObject:getMessage():getValue()
     local tap2Percent = math.floor(8192+(8192*tap2Val*.01))    
     set86CCValue(112, value) -- Tap2 % = m41     
end

function convShape(valueObject, value)
     local convolutionShape = valueObject:getMessage():getValue()   
     formulaPoke (38, 50, convolutionShape) -- Formula P' - Set shape         
end

function setConvolutionIR1(valueObject, value) -- Convolution Poke = 
     local convolution1Type = valueObject:getMessage():getValue()
     if (convolution1Type == 0) then -- IR1 = 4
       convolutionPoke(4, 0)
     elseif (convolution1Type == 1) then
      convolutionPoke(4, 1)
     elseif (convolution1Type == 2) then
      convolutionPoke(4, 2)
     elseif (convolution1Type == 3) then
       convolutionPoke(4, 3)
     elseif (convolution1Type == 4) then
      convolutionPoke(4, 4)
     elseif (convolution1Type == 5) then
      convolutionPoke(4, 5)
     elseif (convolution1Type == 6) then
      convolutionPoke(4, 6)
     elseif (convolution1Type == 7) then
      convolutionPoke(4, 7)
     elseif (convolution1Type == 8) then
      convolutionPoke(4, 8)
     elseif (convolution1Type == 9) then
      convolutionPoke(4, 9)
     elseif (convolution1Type == 10) then
      convolutionPoke(4, 10)
     elseif (convolution1Type == 11) then
      convolutionPoke(4, 11)
     elseif (convolution1Type == 12) then
      convolutionPoke(4, 12)
     elseif (convolution1Type == 13) then
      convolutionPoke(4, 13)
     elseif (convolution1Type == 14) then
      convolutionPoke(4, 14)
     elseif (convolution1Type == 15) then
      convolutionPoke(4, 15)
     elseif (convolution1Type == 16) then
      convolutionPoke(4, 16)
     elseif (convolution1Type == 17) then
      convolutionPoke(4, 17)
     elseif (convolution1Type == 18) then
      convolutionPoke(4, 18) 
     else -- Others are not applicable
         print ("Unexpected IR 1 Codes ")
     end                                                                             
end

function setConvolutionIR2(valueObject, value) -- Convolution Poke = 
     local convolution2Type = valueObject:getMessage():getValue()
     if (convolution2Type == 0) then -- IR1 = 5
       convolutionPoke(5, 0)
     elseif (convolution2Type == 1) then
      convolutionPoke(5, 1)
     elseif (convolution2Type == 2) then
      convolutionPoke(5, 2)
     elseif (convolution2Type == 3) then
      convolutionPoke(5, 3)
     elseif (convolution2Type == 4) then
      convolutionPoke(5, 4)
     elseif (convolution2Type == 5) then
      convolutionPoke(5, 5)
     elseif (convolution2Type == 6) then
      convolutionPoke(5, 6)
     elseif (convolution2Type == 7) then
      convolutionPoke(5, 7)
     elseif (convolution2Type == 8) then
      convolutionPoke(5, 8)
     elseif (convolution2Type == 9) then
      convolutionPoke(5, 9)
     elseif (convolution2Type == 10) then
      convolutionPoke(5, 10)
     elseif (convolution2Type == 11) then
      convolutionPoke(5, 11)
     elseif (convolution2Type == 12) then
      convolutionPoke(5, 12)
     elseif (convolution2Type == 13) then
      convolutionPoke(5, 13)
     elseif (convolution2Type == 14) then
      convolutionPoke(5, 14)
     elseif (convolution2Type == 15) then
      convolutionPoke(5, 15)
     elseif (convolution2Type == 16) then
      convolutionPoke(5, 16)
     elseif (convolution2Type == 17) then
      convolutionPoke(5, 17)
     elseif (convolution2Type == 18) then
      convolutionPoke(5, 18) 
     else -- Others are not applicable
         print ("Unexpected IR 2 Codes ")
     end                                      
end


function setConvolutionIR3(valueObject, value) -- Convolution Poke = 
     local convolution3Type = valueObject:getMessage():getValue()
     if (convolution3Type == 0) then -- IR1 = 4
       convolutionPoke(6, 0)
     elseif (convolution3Type == 1) then
      convolutionPoke(6, 1)
     elseif (convolution3Type == 2) then
      convolutionPoke(6, 2)
     elseif (convolution3Type == 3) then
       convolutionPoke(6, 3)
     elseif (convolution3Type == 4) then
      convolutionPoke(6, 4)
     elseif (convolution3Type == 5) then
      convolutionPoke(6, 5)
     elseif (convolution3Type == 6) then
      convolutionPoke(6, 6)
     elseif (convolution3Type == 7) then
      convolutionPoke(6, 7)
     elseif (convolution3Type == 8) then
      convolutionPoke(6, 8)
     elseif (convolution3Type == 9) then
      convolutionPoke(6, 9)
     elseif (convolution3Type == 10) then
      convolutionPoke(6, 10)
     elseif (convolution3Type == 11) then
      convolutionPoke(6, 11)
     elseif (convolution3Type == 12) then
      convolutionPoke(6, 12)
     elseif (convolution3Type == 13) then
      convolutionPoke(6, 13)
     elseif (convolution3Type == 14) then
      convolutionPoke(6, 14)
     elseif (convolution3Type == 15) then
      convolutionPoke(6, 15)
     elseif (convolution3Type == 16) then
      convolutionPoke(6, 16)
     elseif (convolution3Type == 17) then
      convolutionPoke(6, 17)
     elseif (convolution3Type == 18) then
      convolutionPoke(6, 18) 
     else -- Others are not applicable
         print ("Unexpected IR 3 Codes ")
     end                                                                             
end


function setConvolutionIR4(valueObject, value) -- Convolution Poke = 
     local convolution4Type = valueObject:getMessage():getValue()
     if (convolution4Type == 0) then -- IR1 = 4
       convolutionPoke(7, 0)
     elseif (convolution4Type == 1) then
      convolutionPoke(7, 1)
     elseif (convolution4Type == 2) then
      convolutionPoke(7, 2)
     elseif (convolution4Type == 3) then
      convolutionPoke(7, 3)
     elseif (convolution4Type == 4) then
      convolutionPoke(7, 4)
     elseif (convolution4Type == 5) then
      convolutionPoke(7, 5)
     elseif (convolution4Type == 6) then
      convolutionPoke(7, 6)
     elseif (convolution4Type == 7) then
      convolutionPoke(7, 7)
     elseif (convolution4Type == 8) then
      convolutionPoke(7, 8)
     elseif (convolution4Type == 9) then
      convolutionPoke(7, 9)
     elseif (convolution4Type == 10) then
      convolutionPoke(7, 10)
     elseif (convolution4Type == 11) then
      convolutionPoke(7, 11)
     elseif (convolution4Type == 12) then
      convolutionPoke(7, 12)
     elseif (convolution4Type == 13) then
      convolutionPoke(7, 13)
     elseif (convolution4Type == 14) then
      convolutionPoke(7, 14)
     elseif (convolution4Type == 15) then
      convolutionPoke(7, 15)
     elseif (convolution4Type == 16) then
      convolutionPoke(7, 16)
     elseif (convolution4Type == 17) then
      convolutionPoke(7, 17)
     elseif (convolution4Type == 18) then
      convolutionPoke(7, 18) 
     else -- Others are not applicable
         print ("Unexpected IR 4 Codes ")
     end                                                                             
end
-- Special version to restore filter1 type from user preset
function restoreFilter1Type (filter1Type) -- Assume set OSC1/Filter1
     if (filter1Type == 0) then -- Osc1/Filter1 = 72      
         matrixPoke (72, 5) -- Osc/Filter 1 = Low Pass
     elseif (filter1Type == 1) then
         matrixPoke (72, 10) -- Osc/Filter1 = Shelved Low Pass
     elseif (filter1Type == 2) then
         matrixPoke (72, 7) -- Osc/Filter1 = Band Pass
     elseif (filter1Type == 3) then
         matrixPoke (72, 8) -- Osc/Filter1 = Band Reject   
     elseif (filter1Type == 4) then
         matrixPoke (72, 19) -- Osc/Filter1 = Ladder Diode, needs OSCFil opt
         matrixPoke (77, 0) -- Osc/Filter1 = Ladder Moog     
     elseif (filter1Type == 5) then
         matrixPoke (72, 19) -- Osc/Filter1 = Ladder Trans, Needs OSCFil opt
         matrixPoke (77, 1) -- Osc/Filter1 = Ladder Roland
     elseif (filter1Type == 6) then
         matrixPoke (72, 6) -- Osc/Filter1 = High Pass            
     else -- Others are not applicable
         print ("Unexpected Filter 1 Type "..filter1Type)
     end
end
-- Special version to restore Filter 2 type from user preset
function restoreFilter2Type (filter2Type) -- Assume set OSC1/Filter1
     if (filter2Type == 0) then -- Osc1/Filter1 = 72      
         matrixPoke (73, 5) -- Osc/Filter 1 = Low Pass
     elseif (filter2Type == 1) then
         matrixPoke (73, 10) -- Osc/Filter1 = Shelved Low Pass
     elseif (filter2Type == 2) then
         matrixPoke (73, 7) -- Osc/Filter1 = Band Pass
     elseif (filter2Type == 3) then
         matrixPoke (73, 8) -- Osc/Filter1 = Band Reject   
     elseif (filter2Type == 4) then
         matrixPoke (73, 19) -- Osc/Filter1 = Ladder Diode, needs OSCFil opt
         matrixPoke (78, 0) -- Osc/Filter1 = Ladder Moog     
     elseif (filter2Type == 5) then
         matrixPoke (73, 19) -- Osc/Filter1 = Ladder Trans, Needs OSCFil opt
         matrixPoke (78, 1) -- Osc/Filter1 = Ladder Roland
     elseif (filter2Type == 6) then
         matrixPoke (73, 6) -- Osc/Filter1 = High Pass            
     else -- Others are not applicable
         print ("Unexpected Filter 2 Type "..filter2Type)
     end
end

function setFilter1Type (valueObject, value) -- Assume set OSC1/Filter1
local filter1Type = valueObject:getMessage():getValue()
     if (filter1Type == 0) then -- Osc1/Filter1 = 72      
         matrixPoke (72, 5) -- Osc/Filter 1 = Low Pass
     elseif (filter1Type == 1) then
         matrixPoke (72, 10) -- Osc/Filter1 = Shelved Low Pass
     elseif (filter1Type == 2) then
         matrixPoke (72, 7) -- Osc/Filter1 = Band Pass
     elseif (filter1Type == 3) then
         matrixPoke (72, 8) -- Osc/Filter1 = Band Reject   
     elseif (filter1Type == 4) then
         matrixPoke (72, 19) -- Osc/Filter1 = Ladder Diode, needs OSCFil opt
         matrixPoke (77, 0) -- Osc/Filter1 = Ladder Moog 
     elseif (filter1Type == 5) then
         matrixPoke (72, 19) -- Osc/Filter1 = Ladder Trans, Needs OSCFil opt
         matrixPoke (77, 1) -- Osc/Filter1 = Ladder Roland
     elseif (filter1Type == 6) then
         matrixPoke (72, 6) -- Osc/Filter1 = High Pass            
     else -- Others are not applicable
         print ("Unexpected Filter 1 Type "..filter1Type)
     end
end

function setFilter2Type (valueObject, value) -- Assume set OSC1/Filter1
local filter2Type = valueObject:getMessage():getValue()
     if (filter2Type == 0) then -- Osc2/Filter2 = 73
         matrixPoke (73, 5) -- Osc/Filter2 = Low Pass
     elseif (filter2Type == 1) then
         matrixPoke (73, 10) -- Osc/Filter2 = Shelved Low Pass
     elseif (filter2Type == 2) then
         matrixPoke (73, 7) -- Osc/Filter2 = Band Pass
     elseif (filter2Type == 3) then
         matrixPoke (73, 8) -- Osc/Filter2 = Band Reject
     elseif (filter2Type == 4) then
         matrixPoke (73, 19) -- Osc/Filter2 = Ladder Diode, needs OSCFil opt
         matrixPoke (78, 0) -- Osc/Filter2 = Ladder Moog     
     elseif (filter2Type == 5) then
         matrixPoke (73, 19) -- Osc/Filter2 = Ladder Trans, Needs OSCFil opt
         matrixPoke (78, 1) -- Osc/Filter2 = Ladder Roland
     elseif (filter2Type == 6) then
         matrixPoke (73, 6) -- Osc/Filter1 = High Pass                
     else -- Others are not applicable
         print ("Unexpected Filter 2 Type ")
     end
end

function setFilter1Cascade (valueObject, value) -- Adjust OscFilOpt1 - Assume set to LP..HP1
     local filter1Cascade = valueObject:getMessage():getValue()
     if (filter1Cascade == 0) then -- Osc1/Filter1 = 77
         matrixPoke (77, 0) -- Osc/Filter1 = 12 dB/Oct
     elseif (filter1Cascade == 1) then
         matrixPoke (77, 1) -- Osc/Filter1 = 24 dB/Oct
     elseif (filter1Cascade == 2) then
         matrixPoke (77, 2) -- Osc/Filter1 = 36 dB/Oct
     elseif (filter1Cascade == 3) then
         matrixPoke (77, 3)  -- Osc/Filter1 = 48 dB/Oct
     else -- Others are not applicable
         print ("Unexpected Filter 1 Cascade "..filter1Cascade)
     end
end

function setFilter2Cascade (valueObject, value) -- Adjust OscFilOpt2 - Assume set to LP..HP1
     local filter2Cascade = valueObject:getMessage():getValue()
     if (filter2Cascade == 0) then -- Osc2/Filter2 = 78
         matrixPoke (78, 0) -- Osc/Filter2 = 12 dB/Oct
     elseif (filter2Cascade == 1) then
         matrixPoke (78, 1) -- Osc/Filter2 = 24 dB/Oct
     elseif (filter2Cascade == 2) then
         matrixPoke (78, 2) -- Osc/Filter2 = 36 dB/Oct
     elseif (filter2Cascade == 3) then
         matrixPoke (78, 3)  -- Osc/Filter2 = 48 dB/Oct
     else -- Others are not applicable
         print ("Unexpected Filter 2 Cascade")
     end
end

-- Restore variants for user configs
function restoreFilter1Shape (filter1Shape)
-- Formula S Pokes
     if (filter1Shape == 0) then   
         formulaPoke (19, 40, 2) -- Formula S - Turn on SG1     
         formulaPoke (19, 50, 0) -- Formula S - Rampup                  
     elseif (filter1Shape == 1) then
         formulaPoke (19, 40, 2) -- Turn on SG 1              
         formulaPoke (19,50, 1) -- Ramp Down         
     elseif (filter1Shape == 2) then
         formulaPoke (19, 40, 2) -- Turn on SG 1              
         formulaPoke (19, 50, 4) -- Triangle         
     elseif (filter1Shape == 3) then
         formulaPoke (19, 40, 2) -- Turn on SG 1               
         formulaPoke (19, 50, 2) -- Pulse
     elseif (filter1Shape == 4) then
         formulaPoke (19, 40, 2) -- Turn on SG 1               
         formulaPoke (19, 50, 6) -- Gentle Up 
     elseif (filter1Shape == 5) then
         formulaPoke (19, 40, 2) -- Turn on SG 1             
         formulaPoke (19, 50, 8) -- Gentle Down 
     elseif (filter1Shape == 6) then
         formulaPoke (19, 40, 2) -- Turn on SG 1            
         formulaPoke (19, 50, 5) -- Hann 
     elseif (filter1Shape == 7) then -- None - Envelope Off
         formulaPoke (19, 40, 0) --  Turn off SG1                                                         
     else -- Others are not applicable
         print ("Unexpected Filter 1 Shape")
     end
end

function restoreFilter2Shape (filter2Shape)
-- Formula U Pokes
    if (filter2Shape == 0) then   
         formulaPoke (21, 40, 3) -- Formula S - Turn on SG2     
         formulaPoke (21, 50, 0) -- Formula S - Rampup                  
     elseif (filter2Shape == 1) then
         formulaPoke (21, 40, 3) -- Turn on SG 2              
         formulaPoke (21,50, 1) -- Ramp Down         
     elseif (filter2Shape == 2) then
         formulaPoke (21, 40, 3) -- Turn on SG 2              
         formulaPoke (21, 50, 4) -- Triangle         
     elseif (filter2Shape == 3) then
         formulaPoke (21, 40, 3) -- Turn on SG 2               
         formulaPoke (21, 50, 2) -- Pulse
     elseif (filter2Shape == 4) then
         formulaPoke (21, 40, 3) -- Turn on SG 2               
         formulaPoke (21, 50, 6) -- Gentle Up 
     elseif (filter2Shape == 5) then
         formulaPoke (21, 40, 3) -- Turn on SG 2             
         formulaPoke (21, 50, 8) -- Gentle Down 
     elseif (filter2Shape == 6) then
         formulaPoke (21, 40, 3) -- Turn on SG 2            
         formulaPoke (21, 50, 5) -- Hann 
     elseif (filter2Shape == 7) then -- None - Envelope Off
         formulaPoke (21, 40, 0) --  Turn off SG1            
     else -- Others are not applicable
         print ("Unexpected Filter 2 Shape")
     end
end

function setFilter1Shape (valueObject, value)
local filter1Shape = valueObject:getMessage():getValue()
-- Formula S Pokes
     if (filter1Shape == 0) then   
         formulaPoke (19, 40, 2) -- Formula S - Turn on SG1     
         formulaPoke (19, 50, 0) -- Formula S - Rampup                  
     elseif (filter1Shape == 1) then
         formulaPoke (19, 40, 2) -- Turn on SG 1              
         formulaPoke (19,50, 1) -- Ramp Down         
     elseif (filter1Shape == 2) then
         formulaPoke (19, 40, 2) -- Turn on SG 1              
         formulaPoke (19, 50, 4) -- Triangle         
     elseif (filter1Shape == 3) then
         formulaPoke (19, 40, 2) -- Turn on SG 1               
         formulaPoke (19, 50, 2) -- Pulse
     elseif (filter1Shape == 4) then
         formulaPoke (19, 40, 2) -- Turn on SG 1               
         formulaPoke (19, 50, 6) -- Gentle Up 
     elseif (filter1Shape == 5) then
         formulaPoke (19, 40, 2) -- Turn on SG 1             
         formulaPoke (19, 50, 8) -- Gentle Down 
     elseif (filter1Shape == 6) then
         formulaPoke (19, 40, 2) -- Turn on SG 1            
         formulaPoke (19, 50, 5) -- Hann 
     elseif (filter1Shape == 7) then -- None - Envelope Off
         formulaPoke (19, 40, 0) --  Turn off SG1                                                         
     else -- Others are not applicable
         print ("Unexpected Filter 1 Shape")
     end
end

function setFilter2Shape (valueObject, value)
local filter2Shape = valueObject:getMessage():getValue()
-- Formula U Pokes
    if (filter2Shape == 0) then   
         formulaPoke (21, 40, 3) -- Formula S - Turn on SG2     
         formulaPoke (21, 50, 0) -- Formula S - Rampup                  
     elseif (filter2Shape == 1) then
         formulaPoke (21, 40, 3) -- Turn on SG 2              
         formulaPoke (21,50, 1) -- Ramp Down         
     elseif (filter2Shape == 2) then
         formulaPoke (21, 40, 3) -- Turn on SG 2              
         formulaPoke (21, 50, 4) -- Triangle         
     elseif (filter2Shape == 3) then
         formulaPoke (21, 40, 3) -- Turn on SG 2               
         formulaPoke (21, 50, 2) -- Pulse
     elseif (filter2Shape == 4) then
         formulaPoke (21, 40, 3) -- Turn on SG 2               
         formulaPoke (21, 50, 6) -- Gentle Up 
     elseif (filter2Shape == 5) then
         formulaPoke (21, 40, 3) -- Turn on SG 2             
         formulaPoke (21, 50, 8) -- Gentle Down 
     elseif (filter2Shape == 6) then
         formulaPoke (21, 40, 3) -- Turn on SG 2            
         formulaPoke (21, 50, 5) -- Hann 
     elseif (filter2Shape == 7) then -- None - Envelope Off
         formulaPoke (21, 40, 0) --  Turn off SG1            
     else -- Others are not applicable
         print ("Unexpected Filter 2 Shape")
     end
end


function setWavebankAType(valueObject, value)
    -- CC56 Matrix Poke 99 0 = Saw, 1=Square, 2 = Triangle
     local waveBankAType = valueObject:getMessage():getValue()
     if (waveBankAType == 0) then -- Saw
         matrixPoke (99, 0) 
     elseif (waveBankAType == 1) then -- Square
         matrixPoke (99, 1) 
     elseif (waveBankAType == 2) then -- Triangle
         matrixPoke (99, 2) 
     else -- No LeCaine used as that requires reprogramming
         print ("Unexpected WaveBank A Type")
     end
end

function setWavebankBType(valueObject, value)
    -- CC56 Matrix Poke 98 0 = Saw, 1=Square, 2 = Triangle
     local waveBankBType = valueObject:getMessage():getValue()
     if (waveBankBType == 0) then -- Saw
         matrixPoke (98, 0) 
     elseif (waveBankBType == 1) then -- Square
         matrixPoke (98, 1) 
     elseif (waveBankBType == 2) then -- Triangle
         matrixPoke (98, 2) 
     else -- No LeCaine used as that requires reprogramming
         print ("Unexpected WaveBank B Type")
     end
end

function setRecircType (valueObject, value)
local recircType = valueObject:getMessage():getValue()
     if (recircType == 0) then 
         matrixPoke (62, 0) -- Short Reverb
     elseif(recircType == 1) then
         matrixPoke (62, 1) -- Mod Delay
     elseif(recircType == 2) then
         matrixPoke (62, 2) -- Swept Echo
     elseif(recircType == 3) then
         matrixPoke (62, 3) -- Analog Echo
     elseif(recircType == 4) then
         matrixPoke (62, 4) -- Dig Delay with LPF
     elseif(recircType == 5) then
         matrixPoke (62, 5) -- Dig Delay with HPF
     elseif(recircType == 6) then
         matrixPoke (62, 6) -- Long Reverb
     else 
         print ("Unexpected Recirc Type")         
     end                    
end

function enableRecirc (valueObject, value)
local recircEnabled = valueObject:getMessage():getValue()
     if (recircEnabled == 0) then 
         matrixPoke (15, 0) -- Enable Recirc = 0
     elseif(recircEnabled == 1) then
         matrixPoke (15, 1) -- Disable Recirc = 1      
     else 
         print ("Unexpected Recirc Enable/Disable Type")               
     end
end

-- Variants for User Config
function restoreFilterIter1 (val)
    if (DWInitialized == false) then
      return
    end    
    local fval = math.tointeger (val)    
    if (fval == 0) then
         matrixPoke (100, 1) -- SG1 Single Cycle
    elseif (fval == 1) then
         matrixPoke (100, 0) -- SG1 Cycle
    else
       print("Unrecognized Filter Iter")
    end
end
function restoreFilterIter2 (val)
    if (DWInitialized == false) then
       return
    end 
    local fval = math.tointeger(val) -- debugit    
    if (fval == 0) then
         matrixPoke (101, 1) -- SG2 Single Cycle
    elseif (fval == 1) then
         matrixPoke (101, 0) -- SG2 Cycle        
    else
       print("Unrecognized Filter Iter")
    end  
end

function setFilterIter1(valueObject, value)
  if (DWInitialized == false) then
    return
  end 
  local ctrl = controls.get(119)
  local fval = math.tointeger(value) --math.tointeger(value)
    if (fval == 0) then
         matrixPoke (100, 1) -- SG1 Single Cycle
    elseif (fval == 1) then
         matrixPoke (100, 0) -- SG1 Cycle
    else
       print("Unrecognized Filter Iter")
    end
end

function setFilterIter2(valueObject, value)
  if (DWInitialized == false) then
    return
  end 
  local ctrl = controls.get(132)
  local fval = math.tointeger(value) -- math.tointeger(value)  
    if (fval == 0) then
         matrixPoke (101, 1) -- SG2 Single Cycle
    elseif (fval == 1) then
         matrixPoke (101, 0) -- SG2 Cycle        
    else
       print("Unrecognized Filter Iter")
    end  
end

-- Clear the User configuration
function clearUserConfig (valueObject, value)
-- All we have to do is set its stored tag to 0 and clear out the name
-- That will effectively free it up 
   if (curUserCtrl:getColor() == RED) then -- Only Clear selected controls
     return
   end
   curUserCtrl:setName("") -- Set user control to the selected name
   curUserCtrl:setColor(RED)   -- Default back to Red
   userTable[curUserIndex].name = "" -- Store name in Table
   curName = "" -- Blank it out for next user setting
   nameCtrl:setName("") 
   userTable[curUserIndex].saved = 0 -- Set user config as not saved 
   persist(userTable)
end

-- Store the User Preset name and add to presist table
function storeUserConfig (valueObject, value)
-- Return if not initialized
  --if (DWInitialized == false) then
  --  return
  --end

-- Return if the control is blank - not set with name
   if (curName == "") then
     return
   end
-- On calling this function, the current User config array index is set in curUser
-- Set saved for this array position to true and set name
-- Store the current configuration in curRec and then assign that to the userTable array slot
-- Persist the user table
   curUserCtrl:setName(curName) -- Set user control to the selected name
   curUserCtrl:setColor(RED)   -- Default back to Red
   userTable[curUserIndex].name = curName -- Store name in Table
   curName = "" -- Blank it out for next user setting
   nameCtrl:setName("") 
   userTable[curUserIndex].saved = 1 -- Set user config position as saved
 -- Store current record in the curRec Table   
   storeCurRec()
   
 -- Persist the user table - will rewrite entire table to JASON format
   persist(userTable)
   info.setText(userTable[curUserIndex].name.." Stored")  
   --printTable(userTable) -- debugit
end


-- Set the name field - assuming User slot selected
function getLetter(valueObject, value)
   if (curUserIndex == 0) then
      return
   end
   curLet = string.char(valueObject:getMessage():getValue())
   -- print("Char = "..string.char(c))
end

-- Delete Last Character
function delChar (valueObject, value)
   if (curUserIndex == 0) then
      return
   end
   if (string.len(curName) < 1) then
      print("User String Len = 0")
      return
   end
   info.setText("")
   local newStr = string.sub(curName, 1, -2) 
   curName = newStr
   --print("CurName ="..newStr)
   nameCtrl:setName(curName)
end

-- Set next character in name
function setChar (valueObject, value)
   if (curUserIndex == 0) then
      print ("No User slot set")
      return
   end
   if (string.len(curName) > 13) then
      info.setText("Name > 14 chars")
      return 
   end
   
   curName = curName .. curLet
   --print("CurName ="..curName)
   nameCtrl:setName(curName)
end

-- Set and highlight current user control selected
function processUser (valueObject, value)
-- Get Control number which is set to Parameter number
   local message = valueObject:getMessage()
   local ctlNum = message:getParameterNumber()
   local ctrl = controls.get(ctlNum)   
   curUserCtrl = ctrl -- store the last selected user control
   curUserIndex = ctlNum-USER_START+1 -- Maps to current Index Will be used in the store Operation 
   if (curUserCtrl:getName() ~= "") then
     curName = curUserCtrl:getName()
     nameCtrl:setName(curName)    
   else
     curName = ""
     nameCtrl:setName("")     
   end
   info.setText("")  
   --print("Cur User Index = "..curUserIndex)
-- Set all user controls red
   for i= 0, 29 do
      ctrl = controls.get(i+USER_START)
      ctrl:setColor(RED)      
   end   
-- Highlight selected control white
   local ctrl = controls.get(ctlNum) -- Actual control number 
   ctrl:setColor(WHITE)
-- Check if User config array index is already set and if so restore user config data
   --print("User Table["..curUserIndex.."]= "..userTable[curUserIndex].saved)
   if (curUserCtrl:getName() == "") then -- User Config name has to be set to restore
      pages.setActiveControlSet(3) -- FOrce user to the naming control set
      return
   end
   if (userTable[curUserIndex].saved == 1) then
       -- info.setText("User Slot "..curUserIndex.." loaded.")
       info.setText(curUserCtrl:getName().." loaded")
       restoreUserConfig(false) -- Restore control values and objects to the saved user configuration (False=not init)
       -- To be safe set bend at 96 as it's getting reset somehow
       matrixPoke(40,96)
   end
end

function restoreCompOrTanh(val)
  local ctrl = controls.get(180)
  -- local controlValue = ctrl:getValue("value")
  -- local ctrlMsg = controlValue:getMessage()
  -- local val = ctrlMsg:getValue()
  if (val == 0) then
    ctrl:setName("Compressor")
    setCompOrTanh(0)
  elseif (val == 1) then
    ctrl:setName("TANH")
    setCompOrTanh(1)
  else
    print("Unrecognized CompOrTanh")
    return 
  end
  --print("CompOrTanh = "..val)
  matrixPoke(16, val)     
end

function compOrTanh(valueObject, value)
  local ctrl = controls.get(180)
  local controlValue = ctrl:getValue("value")
  local ctrlMsg = controlValue:getMessage()
  local val = ctrlMsg:getValue()
  if (val == 0) then
    ctrl:setName("Compressor")
    setCompOrTanh(0)
  elseif (val == 1) then
    ctrl:setName("TANH")
    setCompOrTanh(1)
  else
    print("Unrecognized CompOrTanh")
    return 
  end
  --print("CompOrTanh = "..val)
  matrixPoke(16, val)     
end

function setCompOrTanh(which) -- Turn on color controls for Comp or Tanh
 if (which == 0) then -- Color for Compressor
   local grp = groups.get(57)
   grp:setLabel("Compressor")
   local ctrl = controls.get(81)
   ctrl:setName("MIX")    
   ctrl:setVisible(true)      
   ctrl = controls.get(82)
   ctrl:setName("THRESHOLD")    
   ctrl:setVisible(true)      
   ctrl = controls.get(83)
   ctrl:setName("ATTACK")    
   ctrl:setVisible(true)
   ctrl = controls.get(84)
   ctrl:setName("RATIO")    
   ctrl:setVisible(true)     
 else -- color for Tanh
   local grp = groups.get(57)
   grp:setLabel("TANH")
   local ctrl = controls.get(81)
   ctrl:setName("MIX")    
   ctrl:setVisible(true)      
   ctrl = controls.get(82)
   ctrl:setName("DRIVE")    
   ctrl:setVisible(true)      
   ctrl = controls.get(83)
   ctrl:setName("NA")    
   ctrl:setVisible(false)
   ctrl = controls.get(84)
   ctrl:setName("MAKEUP")    
   ctrl:setVisible(true)    
 end
end

function xposeMiddleC(valueObject, value)
    -- print ("Poke: " .. pokeID .. " " .. pokeVal)
   local ctrl = controls.get(115)      
    newMiddleC = valueObject:getMessage():getValue()
    if (newMiddleC == 60) then
       ctrl:setName("TRANSPOSE OFF")
    elseif (newMiddleC < 60) then
       ctrl:setName("+ "..tostring(60-newMiddleC))
    else
       ctrl:setName("- "..tostring(newMiddleC-60))  
    end  

    midi.sendControlChange(DEVICE_PORT, 1, 8, newMiddleC)       
end

function matrixPoke(pokeID, pokeVal)
    -- print ("Poke: " .. pokeID .. " " .. pokeVal) -- debugit
    midi.sendControlChange(DEVICE_PORT, 16, 56, 20) -- Matrix Poke command 
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, pokeID , pokeVal) -- Perform the Poke  
end

function formulaPoke(formulaID, pokeID, pokeVal)
    -- print ("POke: " .. pokeID .. " " .. pokeVal)
    midi.sendControlChange(DEVICE_PORT, 16, 34, formulaID) -- Set Formula
    midi.sendControlChange(DEVICE_PORT, 16, 56, 19) -- Formula Poke command 
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, pokeID , pokeVal) -- Perform the Poke  
end

function convolutionPoke(pokeID, pokeVal)
    -- print ("POke: " .. pokeID .. " " .. pokeVal)
    midi.sendControlChange(DEVICE_PORT, 16, 56, 26) -- Convolution command 
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, pokeID , pokeVal) -- Perform the Poke  
end

function mainGraphPoke(pokeIndex, pokeValue)
    -- print ("POke: " .. pokeID .. " " .. pokeVal)
    midi.sendControlChange(DEVICE_PORT, 16, 56, 21) -- Matrix Poke command 
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, pokeIndex , pokeValue) -- Change Main Graph value at zero offset index 0..47  
end

function setXOctaveA(valueObject, value)
    -- m43 (CC114)Formula U', m7 (CC40) Formula A, m8 (CC41) Formula B
    -- Make sure Offets are off 
    
    local OctListValue = valueObject:getMessage():getValue()
    if (OctListValue == 0) then -- Only Fundamental X - m113=0.0 (X), m7=-1.0 (off), m8=-1.0 (off)
       set86CCValue(m7, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m8, convert14Bits(-1.0)) -- f2 = off
       set86CCValue(m9, convert14Bits(-1.0)) -- f3 = off
    elseif (OctListValue == 1) then -- X + 8va
       set86CCValue(m7, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m8, convert14Bits(1.0))  -- f2 = 8va
       set86CCValue(m9, convert14Bits(-1.0)) -- f3 = off
    elseif (OctListValue == 2) then -- X + 8vb
       set86CCValue(m7, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m8, convert14Bits(-1.0)) -- f2 = off
       set86CCValue(m9, convert14Bits(-0.5)) -- f3 = 8vb
    elseif (OctListValue == 3) then -- X+8va+8vb
       set86CCValue(m7, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m8, convert14Bits(1.0))  -- f2 = 8va
       set86CCValue(m9, convert14Bits(-0.5)) -- f3 = 8vb
    elseif (OctListValue == 4) then -- Only 8va
       set86CCValue(m7, convert14Bits(-1.0)) -- f1 = off
       set86CCValue(m8, convert14Bits(1.0))   -- f2 = 8va
       set86CCValue(m9, convert14Bits(-1.0))  -- f3 = off
    elseif (OctListValue == 5) then -- Only 8vb
       set86CCValue(m7, convert14Bits(-1.0)) -- f1 = off  
       set86CCValue(m8, convert14Bits(-1.0))  -- f2 = off
       set86CCValue(m9, convert14Bits(-0.5))  -- f3 = 8vb
    elseif (OctListValue == 6) then -- Only 8va+8vb 
       set86CCValue(m7, convert14Bits(-1.0)) -- f1 = off
       set86CCValue(m8, convert14Bits(1.0))   -- f2 = 8va
       set86CCValue(m9, convert14Bits(-0.5))  -- f3 = 8vb        
    elseif (OctListValue == 7) then -- 32'+16'+8       
       set86CCValue(m7, convert14Bits(0.0))   -- 8'
       set86CCValue(m8, convert14Bits(-0.5))   -- 16'
       set86CCValue(m9, convert14Bits(-0.75)) -- 32' 
    elseif (OctListValue == 8) then -- 32'+8'+4       
       set86CCValue(m7, convert14Bits(1.0))   -- 4'
       set86CCValue(m8, convert14Bits(0.0))   -- 8'
       set86CCValue(m9, convert14Bits(-0.75)) -- 32'                              
    elseif (OctListValue == 9) then -- 16'+8'+Quint      
       set86CCValue(m7, convert14Bits(0.0))   -- 4'
       set86CCValue(m8, convert14Bits(-0.5))   -- 8'
       set86CCValue(m9, convert14Bits(-0.25)) -- Quint'                         
    else    
       print ("Unexpected" .. OctListValue) 
    end
end

-- Special version to restore user config
function restoreXOctaveA(OctListValue) 
    if (OctListValue == 0) then -- Only Fundamental X - m113=0.0 (X), m7=-1.0 (off), m8=-1.0 (off)
       set86CCValue(m7, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m8, convert14Bits(-1.0)) -- f2 = off
       set86CCValue(m9, convert14Bits(-1.0)) -- f3 = off
    elseif (OctListValue == 1) then -- X + 8va
       set86CCValue(m7, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m8, convert14Bits(1.0))  -- f2 = 8va
       set86CCValue(m9, convert14Bits(-1.0)) -- f3 = off
    elseif (OctListValue == 2) then -- X + 8vb
       set86CCValue(m7, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m8, convert14Bits(-1.0)) -- f2 = off
       set86CCValue(m9, convert14Bits(-0.5)) -- f3 = 8vb
    elseif (OctListValue == 3) then -- X+8va+8vb
       set86CCValue(m7, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m8, convert14Bits(1.0))  -- f2 = 8va
       set86CCValue(m9, convert14Bits(-0.5)) -- f3 = 8vb
    elseif (OctListValue == 4) then -- Only 8va
       set86CCValue(m7, convert14Bits(-1.0)) -- f1 = off
       set86CCValue(m8, convert14Bits(1.0))   -- f2 = 8va
       set86CCValue(m9, convert14Bits(-1.0))  -- f3 = off
    elseif (OctListValue == 5) then -- Only 8vb
       set86CCValue(m7, convert14Bits(-1.0)) -- f1 = off  
       set86CCValue(m8, convert14Bits(-1.0))  -- f2 = off
       set86CCValue(m9, convert14Bits(-0.5))  -- f3 = 8vb
    elseif (OctListValue == 6) then -- Only 8va+8vb 
       set86CCValue(m7, convert14Bits(-1.0)) -- f1 = off
       set86CCValue(m8, convert14Bits(1.0))   -- f2 = 8va
       set86CCValue(m9, convert14Bits(-0.5))  -- f3 = 8vb
    elseif (OctListValue == 7) then -- 32'+16'+8
       set86CCValue(m7, convert14Bits(0.0)) -- 8'
       set86CCValue(m8, convert14Bits(-0.5))  -- 16'
       set86CCValue(m9, convert14Bits(-0.75)) -- 32'
    elseif (OctListValue == 8) then -- 32'+8'+4       
       set86CCValue(m7, convert14Bits(1.0))   -- 4'
       set86CCValue(m8, convert14Bits(0.0))   -- 8'
       set86CCValue(m9, convert14Bits(-0.75)) -- 32'
    elseif (OctListValue == 9) then -- 16'+8'+Quint      
       set86CCValue(m7, convert14Bits(0.0))   -- 4'
       set86CCValue(m8, convert14Bits(-0.5))   -- 8'
       set86CCValue(m9, convert14Bits(-0.25)) -- Quint'                                            
    else 
       print ("Unexpected" .. OctListValue) 
    end
end

function restoreXOctaveB(OctListValue)
    if (OctListValue == 0) then -- Only Fundamental X - m113=0.0 (X), m7=-1.0 (off), m8=-1.0 (off)
       set86CCValue(m10, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m42, convert14Bits(-1.0)) -- f2 = off
       set86CCValue(m43, convert14Bits(-1.0)) -- f3 = off
    elseif (OctListValue == 1) then -- X + 8va
       set86CCValue(m10, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m42, convert14Bits(1.0))  -- f2 = 8va
       set86CCValue(m43, convert14Bits(-1.0)) -- f3 = off
    elseif (OctListValue == 2) then -- X + 8vb
       set86CCValue(m10, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m42, convert14Bits(-1.0)) -- f2 = off
       set86CCValue(m43, convert14Bits(-0.5)) -- f3 = 8vb
    elseif (OctListValue == 3) then -- X+8va+8vb
       set86CCValue(m10, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m42, convert14Bits(1.0))  -- f2 = 8va
       set86CCValue(m43, convert14Bits(-0.5)) -- f3 = 8vb
    elseif (OctListValue == 4) then -- Only 8va
       set86CCValue(m10, convert14Bits(-1.0)) -- f1 = off
       set86CCValue(m42, convert14Bits(1.0))   -- f2 = 8va
       set86CCValue(m43, convert14Bits(-1.0))  -- f3 = off
    elseif (OctListValue == 5) then -- Only 8vb
       set86CCValue(m10, convert14Bits(-1.0)) -- f1 = off  
       set86CCValue(m42, convert14Bits(-1.0))  -- f2 = off
       set86CCValue(m43, convert14Bits(-0.5))  -- f3 = 8vb
    elseif (OctListValue == 6) then -- Only 8va+8vb 
       set86CCValue(m10, convert14Bits(-1.0)) -- f1 = off
       set86CCValue(m42, convert14Bits(1.0))   -- f2 = 8va
       set86CCValue(m43, convert14Bits(-0.5))  -- f3 = 8vb
    elseif (OctListValue == 7) then -- 32'+16'+8       
       set86CCValue(m10, convert14Bits(0.0))   -- 8'
       set86CCValue(m42, convert14Bits(-0.5))   -- 16'
       set86CCValue(m43, convert14Bits(-0.75)) -- 32' 
    elseif (OctListValue == 8) then -- 32'+8'+4       
       set86CCValue(m10, convert14Bits(1.0))   -- 4'
       set86CCValue(m42, convert14Bits(0.0))   -- 8'
       set86CCValue(m43, convert14Bits(-0.75)) -- 32'
     elseif (OctListValue == 9) then -- 16'+8'+Quint      
       set86CCValue(m10, convert14Bits(0.0))   -- 4'
       set86CCValue(m42, convert14Bits(-0.5))   -- 8'
       set86CCValue(m43, convert14Bits(-0.25)) -- Quint'                              
    else 
       print ("Unexpected" .. OctListValue) 
    end
end

function setXOctaveB(valueObject, value)
    -- m43 (CC114)Formula U', m7 (CC40) Formula A, m8 (CC41) Formula B
    -- Make sure Offets are off 
    
    local OctListValue = valueObject:getMessage():getValue()
    if (OctListValue == 0) then -- Only Fundamental X - m113=0.0 (X), m7=-1.0 (off), m8=-1.0 (off)
       set86CCValue(m10, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m42, convert14Bits(-1.0)) -- f2 = off
       set86CCValue(m43, convert14Bits(-1.0)) -- f3 = off
    elseif (OctListValue == 1) then -- X + 8va
       set86CCValue(m10, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m42, convert14Bits(1.0))  -- f2 = 8va
       set86CCValue(m43, convert14Bits(-1.0)) -- f3 = off
    elseif (OctListValue == 2) then -- X + 8vb
       set86CCValue(m10, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m42, convert14Bits(-1.0)) -- f2 = off
       set86CCValue(m43, convert14Bits(-0.5)) -- f3 = 8vb
    elseif (OctListValue == 3) then -- X+8va+8vb
       set86CCValue(m10, convert14Bits(0.0)) -- f1 = Fundamental
       set86CCValue(m42, convert14Bits(1.0))  -- f2 = 8va
       set86CCValue(m43, convert14Bits(-0.5)) -- f3 = 8vb
    elseif (OctListValue == 4) then -- Only 8va
       set86CCValue(m10, convert14Bits(-1.0)) -- f1 = off
       set86CCValue(m42, convert14Bits(1.0))   -- f2 = 8va
       set86CCValue(m43, convert14Bits(-1.0))  -- f3 = off
    elseif (OctListValue == 5) then -- Only 8vb
       set86CCValue(m10, convert14Bits(-1.0)) -- f1 = off  
       set86CCValue(m42, convert14Bits(-1.0))  -- f2 = off
       set86CCValue(m43, convert14Bits(-0.5))  -- f3 = 8vb
    elseif (OctListValue == 6) then -- Only 8va+8vb 
       set86CCValue(m10, convert14Bits(-1.0)) -- f1 = off
       set86CCValue(m42, convert14Bits(1.0))   -- f2 = 8va
       set86CCValue(m43, convert14Bits(-0.5))  -- f3 = 8vb        
    elseif (OctListValue == 7) then -- 32'+16'+8       
       set86CCValue(m10, convert14Bits(0.0))   -- 8'
       set86CCValue(m42, convert14Bits(-0.5))   -- 16'
       set86CCValue(m43, convert14Bits(-0.75)) -- 32'
    elseif (OctListValue == 8) then -- 32'+8'+4       
       set86CCValue(m10, convert14Bits(1.0))   -- 4'
       set86CCValue(m42, convert14Bits(0.0))   -- 8'
       set86CCValue(m43, convert14Bits(-0.75)) -- 32'
     elseif (OctListValue == 9) then -- 16'+8'+Quint      
       set86CCValue(m10, convert14Bits(0.0))   -- 4'
       set86CCValue(m42, convert14Bits(-0.5))   -- 8'
       set86CCValue(m43, convert14Bits(-0.25)) -- Quint'                                           
    else     
       print ("Unexpected" .. OctListValue) 
    end
end

-- Variant for Used Config
-- Functions to add additional harmonics
function restoreHarmonic1(harm1)
     local h1val = math.floor((harm1 * .1  * 8192) + 8192)
     if (harm1 == 0) then
       set86CCValue(60, 8192)
     else
       set86CCValue(60, h1val)
     end
end

function restoreHarmonic2(harm2)
     local h2val = math.floor((harm2 * .1  * 8192) + 8192)
     if (harm2 == 0) then
       set86CCValue(61, 8192)
     else
       set86CCValue(61, h2val)
     end       
end

-- Functions to add additional harmonics
function addHarmonic1(valueObject, value)
    -- Get harmonic number #1 to multiply by X
     local harm1 = valueObject:getMessage():getValue()
     local h1val = math.floor((harm1 * .1  * 8192) + 8192)
     if (harm1 == 0) then
       set86CCValue(60, 8192)
     else
       set86CCValue(60, h1val)
     end
end

function addHarmonic2(valueObject, value)
    -- Get harmonic number #2 to multiply by X
     local harm2 = valueObject:getMessage():getValue()
     local h2val = math.floor((harm2 * .1  * 8192) + 8192)
     if (harm2 == 0) then
       set86CCValue(61, 8192)
     else
       set86CCValue(61, h2val)
     end       
end

function setGlide(valueObject, value)
    local glideVal = valueObject:getMessage():getValue()
    if (glideVal == 0) then
        midi.sendControlChange(DEVICE_PORT, 1, 9, 0)
        midi.sendControlChange(DEVICE_PORT, 16, 48, 0)
    else
        midi.sendControlChange(DEVICE_PORT, 1, 9, 1)
        midi.sendControlChange(DEVICE_PORT, 16, 48, glideVal)
    end
end

function set1Test (valueObject, value)
   local controlChangeLsb = valueObject:getMessage():getParameterNumber()
    --midi.sendControlChange(DEVICE_PORT, 2, 86, 127)
    --midi.sendControlChange(DEVICE_PORT, 2, 40, 127)

    local valueLsb = value >> 7
    local valueMsb = value & 0x7f

    local controlChangeLsb = valueObject:getMessage():getParameterNumber()

    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, 86, valueMsb)
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, controlChangeLsb, valueLsb)
end

function set86CCValue(controlCC, value)
    -- print("In Set86 CC= "..controlCC..", value = "..value) -- debugit
    local valueMsb = value >> 7
    local valueLsb = value & 0x7f
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, 86, valueLsb)
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, controlCC, valueMsb)
end

function set14w86(valueObject, value)
    local valueMsb = value >> 7
    local valueLsb = value & 0x7f
    local controlChangeLsb = valueObject:getMessage():getParameterNumber()

    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, 86, valueLsb)
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, controlChangeLsb, valueMsb) 
end

-- Because we need to use unique controls numbers- CC97 controls are * 10
-- SO divide by 10 before processing
function set14w97(valueObject, value)
    local valueMsb = value >> 7
    local valueLsb = value & 0x7f
    local tempLsb = valueObject:getMessage():getParameterNumber()
    local controlChangeLsb = math.floor(tempLsb/10)

    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, 97, valueLsb)
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, controlChangeLsb, valueMsb)
end
function set97CCValue(controlCC, value)
    -- print("In Set86 CC= "..controlCC..", value = "..value) -- debugit
    local valueMsb = value >> 7
    local valueLsb = value & 0x7f
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, 97, valueLsb)
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, controlCC, valueMsb)
end

function sendCustomCc(valueObject, value)
    local valueMsb = value >> 7
    local valueLsb = value & 0x7f
    local controlChangeLsb = valueObject:getMessage():getParameterNumber()

    if valueMsb ~= prevValueMsb then
        midi.sendControlChange(
            DEVICE_PORT,
            DEVICE_CHANNEL,
            (valueMsb > prevValueMsb) and CONTROL_CHANGE_MSB_INC or CONTROL_CHANGE_MSB_DEC,
            valueMsb)
        prevValueMsb = valueMsb
    end

    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, controlChangeLsb, valueLsb)
end

-- More Continuum specific conrols - some work on Osmose
function setSplitMode(valueObject, value)
      local control = controls.get(126)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      matrixPoke(1, val) -- Set Split Mode
end

function setSplitPoint(valueObject, value)
      local control = controls.get(124)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      matrixPoke(45, val) -- Set  Split point, C4 = 60
end

function setMonoMode(valueObject, value)
      local control = controls.get(144)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      if config.osmose_enabled then
         matrixPoke(46, 0) -- Osmose only supports pressure glide
      else      
         matrixPoke(46, val)
      end
end
function setMonoInterval(valueObject, value)
      local control = controls.get(117)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      matrixPoke(48, val)
end
function setMonoSwitch(valueObject, value)
      local control = controls.get(116)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()

      if (val == 0) then     
        monoSwitch = false
        control:setName("Mono Off")
        control:setColor(WHITE)
        midi.sendControlChange(DEVICE_PORT, 1, 9, 0)        
      else
        monoSwitch = true
        control:setName("Mono On")
        control:setColor(GREEN)     
        midi.sendControlChange(DEVICE_PORT, 1, 9, 1)         
      end
end
-- Restore/Set Tunings
function restoreTunings(val)     
      if (val == 0) then -- Equal Temperament
        midi.sendControlChange(DEVICE_PORT, 1, 28, 0) -- Tuning Off
        midi.sendControlChange(DEVICE_PORT, 16, 51, 0)          
      else     
        midi.sendControlChange(DEVICE_PORT, 1, 28, 127) -- Tuning On 
        midi.sendControlChange(DEVICE_PORT, 16, 51, val)          
      end
end
function setTunings(valueObject, value)     
      local control = controls.get(133)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      if (val == 0) then -- Equal Temperament
         midi.sendControlChange(DEVICE_PORT, 1, 28, 0) -- Tuning Off
         matrixPoke(51, 0) -- Set Equal Temperament 
      else     
         midi.sendControlChange(DEVICE_PORT, 1, 28, 127) -- Tuning On 
         matrixPoke(51, val)  
      end
end

-- User Configuration functions
-- Store the current Record
-- Some of this can be done in indiviual setfunctions - but all done as a unit for initial version
-- The current User record will be installed as a Store function in the selected user config array index
function storeCurRec ()
-- Wavetype1
      local ctrl = controls.get(2)
      local controlValue = ctrl:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      userTable[curUserIndex].waveType1 = val
-- Wavetype 2
      ctrl = controls.get(6)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].waveType2 = val
-- WaveFreq1
      ctrl = controls.get(3)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].waveFreq1 = val
-- WaveFreq2
      ctrl = controls.get(7)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].waveFreq2 = val 
-- Duty1
      ctrl = controls.get(9)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].duty1 = val
-- Duty2
      ctrl = controls.get(11)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].duty2 = val
-- ampWeight1
      ctrl = controls.get(10)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].ampWeight1 = val
-- ampWeight2
      ctrl = controls.get(12)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].ampWeight2 = val
-- deture1
      ctrl = controls.get(4)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].detune1 = val
-- detune2
      ctrl = controls.get(8)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].detune2 = val
-- filterAmt1
      ctrl = controls.get(15)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].filterAmt1 = val
-- filterAmt2
      ctrl = controls.get(16)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].filterAmt2 = val 
-- filterType1
      ctrl = controls.get(22)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].filterType1 = val
      if (val == 5) then --  Moog filter
         userTable[curUserIndex].cascade1 = 0
      elseif (val == 6) then -- ROland filter
         userTable[curUserIndex].cascade1 = 1      
      end
-- filterType2
      ctrl = controls.get(27)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].filterType2 = val 
      if (val == 5) then --  Moog filter
         userTable[curUserIndex].cascade2 = 0
      elseif (val == 6) then -- ROland filter
         userTable[curUserIndex].cascade2 = 1      
      end                 
-- cascade1
      ctrl = controls.get(23)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].cascade1 = val
-- cascade2
      ctrl = controls.get(32)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].cascade2 = val
-- cutoff1
      ctrl = controls.get(19)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].cutoff1 = val
-- cutoff2
      ctrl = controls.get(28)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].cutoff2 = val 
-- resonance1
      ctrl = controls.get(18)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].resonance1 = val
-- resomance2
      ctrl = controls.get(29)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].resonance2 = val
-- filterShape1
      ctrl = controls.get(20)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].filterShape1 = val
-- filterShape2
      ctrl = controls.get(31)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].filterShape2 = val
-- envSpeed1
      ctrl = controls.get(21)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].envSpeed1 = val
-- envSpeed2
      ctrl = controls.get(30)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].envSpeed2 = val
-- envRelease1
      ctrl = controls.get(48)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].envRelease1 = val
-- envRelease2
      ctrl = controls.get(73)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].envRelease2 = val  
-- tremSpeedL
      ctrl = controls.get(39)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].tremSpeedL = val
-- tremSpeedR
      ctrl = controls.get(40)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].tremSpeedR = val 
-- tremWidthL
      ctrl = controls.get(34)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].tremWidthL = val
-- tremWidthR
      ctrl = controls.get(35)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].tremWidthR = val
-- waveMix1
      ctrl = controls.get(130)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].waveMix1 = val
-- waveMix2
      ctrl = controls.get(131)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].waveMix2 = val     
-- extraHarm1
      ctrl = controls.get(36)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].extraHarm1 = val
-- extraHarm2
      ctrl = controls.get(38)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].extraHarm2 = val
-- addNoise1
      ctrl = controls.get(24)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].addNoise1 = val
-- addNoise2
      ctrl = controls.get(25)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].addNoise2 = val
-- convIR1
      ctrl = controls.get(53)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convIR1 = val
-- convIR2      
      ctrl = controls.get(54)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convIR2 = val
-- convIR3      
      ctrl = controls.get(120)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convIR3 = val
-- convIR4      
      ctrl = controls.get(121)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convIR4 = val 
-- convMix
      ctrl = controls.get(58)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convMix = val
-- convIndex
      ctrl = controls.get(123)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convIndex = val
-- recircEnable
      ctrl = controls.get(129)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].recircEnable = val
-- reverbType
      ctrl = controls.get(42)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].reverbType = val
-- reverbMix
      ctrl = controls.get(43)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].reverbMix = val      
-- reverbR4
      ctrl = controls.get(44)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].reverbR4= val     
-- reverbR3
      ctrl = controls.get(45)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].reverbR3 = val   
-- reverbR2
      ctrl = controls.get(46)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].reverbR2= val    
-- reverbR1
      ctrl = controls.get(47)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].reverbR1 = val    
-- reverbR5
      ctrl = controls.get(75)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].reverbR5= val  
-- reverbR6
      ctrl = controls.get(76)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].reverbR6 = val
-- eqMix
      ctrl = controls.get(85)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].eqMix = val
-- eqTilt
      ctrl = controls.get(86)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].eqTilt = val
-- eqFreq
      ctrl = controls.get(87)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].eqFreq = val
-- compOrTanh
      ctrl = controls.get(180)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].compOrTanh = val
-- compMix
      ctrl = controls.get(81)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].compMix = val          
-- compThresh
      ctrl = controls.get(82)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].compThresh = val
-- compAttack
      ctrl = controls.get(83)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].compAttack = val
-- compRatio
      ctrl = controls.get(84)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].compRatio = val
-- delayOut
      ctrl = controls.get(135)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].delayOut = val
-- delayFeedback
      ctrl = controls.get(136)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].delayFeedback = val
-- delayTap1
      ctrl = controls.get(145)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].delayTap1 = val
-- delayTap2
      ctrl = controls.get(146)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].delayTap2 = val
-- autoTap34
      ctrl = controls.get(37)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].autoTap34 = val
-- delayTime
      ctrl = controls.get(138)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].delayTime = val  
-- convMorphSpeed
      ctrl = controls.get(158)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convMorphSpeed = val
-- convMorphRange
      ctrl = controls.get(55)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convMorphRange = val
-- convMorphShape
      ctrl = controls.get(140)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convMorphShape = val 
-- convYControl
      ctrl = controls.get(141)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].convYControl = val
-- filterIter1
      ctrl = controls.get(119)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].filterIter1 = val      
-- filterIter2
      ctrl = controls.get(132)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].filterIter2 = val
-- transposeInt
-- Set these in the transpose controls - will already be set
-- masterDetune
      ctrl = controls.get(155)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].masterDetune = val
-- tuningIndex
      ctrl = controls.get(133)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].tuningIndex = val 
-- monoSwitch
      ctrl = controls.get(116)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].monoSwitch = val
-- monoInterval
      ctrl = controls.get(117)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].monoInterval = val 
  if (config.osmose_enabled == false) then
-- Mono Mode - Continuum Only
      ctrl = controls.get(144)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].monoMode= val 
-- Split Point
      ctrl = controls.get(124)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].splitPoint = val
-- Split Mode
      ctrl = controls.get(126)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].splitMode = val
  end
-- postGain
      ctrl = controls.get(128)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].postGain = val
-- postGain
      ctrl = controls.get(139)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].preGain = val
-- Attenuation - Continuum Only
--[[
   if (config.osmose_enabled == false) then
      ctrl = controls.get(139)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].attenuation = val
   end
--]]
-- Round Rate
   if (config.osmose_enabled == false) then
      ctrl = controls.get(153)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].roundRate = val
   end
-- Round Initial
   if (config.osmose_enabled == false) then
      ctrl = controls.get(156)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].roundInitial = val
   end
-- YVolume
      ctrl = controls.get(148)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
   if config.osmose_enabled then
      val = ctrlMsg:getValue()
      userTable[curUserIndex].YVolume= val                                             
   else
      userTable[curUserIndex].YVolume= 8192 -- Continuum devices don't use this - set to 0
      print("YVOL = ".. userTable[curUserIndex].YVolume)  -- debugit
   end
-- YTremCtrl
      ctrl = controls.get(71)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].YTremCtrl = val
-- ZTremCtrl
      ctrl = controls.get(160)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      val = ctrlMsg:getValue()
      userTable[curUserIndex].ZTremCtrl = val
end

-- Restore the saved user configuration as the current curRec configuration

function noOp ()
local i, j
  for i=1,100 do
    j=i
  end
--  print("noop"..j) -- debugit Kram
end

function restoreUserConfig(isInit)
      local pVal = 0 -- Control parameter to set value
      if (isInit) then
        curRec = initRec
        info.setText("Preset Init")
      else
        curRec = userTable[curUserIndex] -- Set the current record
      end
 -- Now go through each field and restore it
-- Wavetype 1
      local ctrl = controls.get(2)
      local controlValue = ctrl:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.waveType1)
      matrixPoke (99, curRec.waveType1)
      noOp () 
-- Wavetype 2
      ctrl = controls.get(6)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.waveType2)
      matrixPoke (98, curRec.waveType1)
      noOp () 
-- WaveFreq 1
      ctrl = controls.get(3)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.waveFreq1)
      restoreXOctaveA(curRec.waveFreq1)
      noOp ()      
-- WaveFreq 2
      ctrl = controls.get(7)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.waveFreq2)
      restoreXOctaveB(curRec.waveFreq2)
      noOp ()       
-- Duty1
      ctrl = controls.get(9)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.duty1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.duty1)
      noOp ()     
-- Duty2
      ctrl = controls.get(11)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.duty2)
      noOp ()
-- ampWeight1
      ctrl = controls.get(10)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.ampWeight1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.ampWeight1)
      noOp ()      
-- ampWeight2
      ctrl = controls.get(12)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.ampWeight2)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.ampWeight2)
      noOp ()      
-- detune1
      ctrl = controls.get(4)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.detune1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.detune1)
      noOp ()      
-- detune2
      ctrl = controls.get(8)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.detune2)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.detune2)
      noOp ()      
-- filterAmt1
      ctrl = controls.get(15)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.filterAmt1)
      pVal = ctrlMsg:getParameterNumber()
      --print("set86CCValue("..pVal..","..curRec.filterAmt1..")") -- debugit
      set86CCValue(pVal, curRec.filterAmt1)
      noOp ()
-- filterAmt2
      ctrl = controls.get(16)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.filterAmt2)
      pVal = ctrlMsg:getParameterNumber()
      --print("set86CCValue("..pVal..","..curRec.filterAmt2..")") -- debugit      
      set86CCValue(pVal, curRec.filterAmt2)
      noOp ()
-- filterType1
      ctrl = controls.get(22)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.filterType1)
      restoreFilter1Type(curRec.filterType1)
      noOp ()
-- filterType2
      ctrl = controls.get(27)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.filterType2) 
      restoreFilter2Type(curRec.filterType2)
      noOp ()             
-- cascade1
      ctrl = controls.get(23)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.cascade1)
      matrixPoke (77, curRec.cascade1)
      noOp ()       
-- cascade2
      ctrl = controls.get(32)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.cascade2) 
      matrixPoke (78, curRec.cascade2)
      noOp ()       
-- cutoff1
      ctrl = controls.get(19)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.cutoff1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.cutoff1)
      noOp ()      
-- cutoff2
      ctrl = controls.get(28)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.cutoff2)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.cutoff2)
      noOp ()     
-- resonance1
      ctrl = controls.get(18)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.resonance1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.resonance1)
      noOp ()      
-- resonance2
      ctrl = controls.get(29)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.resonance2)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.resonance2)
      noOp ()      
-- filterShape1
      ctrl = controls.get(20)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.filterShape1)
      restoreFilter1Shape(curRec.filterShape1)
      noOp ()       
-- filterShape2
      ctrl = controls.get(31)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.filterShape2)
      restoreFilter2Shape(curRec.filterShape2)
      noOp ()        
-- envSpeed1
      ctrl = controls.get(21)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.envSpeed1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.envSpeed1)
      noOp ()      
-- envSpeed2
      ctrl = controls.get(30)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.envSpeed2)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.envSpeed2)
      noOp ()      
-- envRelease1
      ctrl = controls.get(48)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.envRelease1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.envRelease1)
      noOp ()      
-- envRelease2
      ctrl = controls.get(73)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.envRelease2)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.envRelease2)
      noOp ()      
-- tremSpeedL
      ctrl = controls.get(39)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.tremSpeedL)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.tremSpeedL)
      noOp ()      
-- tremSpeedR
      ctrl = controls.get(40)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.tremSpeedR) 
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.tremSpeedR)
      noOp ()
-- tremWidthL
      ctrl = controls.get(34)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.tremWidthL)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.tremWidthL)
      noOp ()      
-- tremWidthR
      ctrl = controls.get(35)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.tremWidthR)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.tremWidthR)
      noOp ()      
-- waveMix1
      ctrl = controls.get(130)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.waveMix1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.waveMix1)
      noOp ()      
-- waveMix2
      ctrl = controls.get(131)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.waveMix2)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.waveMix2)
      noOp ()      
-- extraHarm1
      ctrl = controls.get(36)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.extraHarm1)
      restoreHarmonic1(curRec.extraHarm1)
      noOp ()      
-- extraHarm2
      ctrl = controls.get(38)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.extraHarm2)
      restoreHarmonic2(curRec.extraHarm2)
      noOp ()       
-- addNoise1
      ctrl = controls.get(24)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.addNoise1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.addNoise1)
      noOp ()     
-- addNoise2
      ctrl = controls.get(25)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.addNoise2)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.addNoise2)
      noOp ()            
-- convIR1
      ctrl = controls.get(53)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convIR1)
      convolutionPoke(4, curRec.convIR1)
      noOp ()      
-- convIR2      
      ctrl = controls.get(54)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convIR2)
      convolutionPoke(5, curRec.convIR2)
      noOp ()       
-- convIR3      
      ctrl = controls.get(120)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convIR3)
      convolutionPoke(6, curRec.convIR3)
      noOp ()     
-- convIR4      
      ctrl = controls.get(121)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convIR4)
      convolutionPoke(7, curRec.convIR4)
      noOp ()       
-- convMix
      ctrl = controls.get(58)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convMix)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.convMix)
      noOp ()      
-- convIndex
      ctrl = controls.get(123)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convIndex)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.convIndex)
      noOp ()      
-- recircEnable
      ctrl = controls.get(129)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.recircEnable)
      matrixPoke (15, curRec.recircEnable)
      noOp ()

-- reverbType
      ctrl = controls.get(42)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.reverbType)
      matrixPoke (62, curRec.reverbType)
      noOp ()     
-- reverbMix
      ctrl = controls.get(43)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.reverbMix)
      midi.sendControlChange(DEVICE_PORT, 1, 24, curRec.reverbMix)
      noOp ()       
-- reverbR4
      ctrl = controls.get(44)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.reverbR4)
      midi.sendControlChange(DEVICE_PORT, 1, 23, curRec.reverbR4)
      noOp ()        
-- reverbR3
      ctrl = controls.get(45)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.reverbR3)
      midi.sendControlChange(DEVICE_PORT, 1, 22, curRec.reverbR3)
      noOp ()        
-- reverbR2
      ctrl = controls.get(46)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.reverbR2)
      midi.sendControlChange(DEVICE_PORT, 1, 21, curRec.reverbR2)
      noOp ()        
-- reverbR1
      ctrl = controls.get(47)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.reverbR1)
      midi.sendControlChange(DEVICE_PORT, 1, 20, curRec.reverbR1)
      noOp ()        
-- reverbR5
      ctrl = controls.get(75)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.reverbR5)
      midi.sendControlChange(DEVICE_PORT, 1, 95, curRec.reverbR5)
      noOp ()      
-- reverbR6
      ctrl = controls.get(76)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.reverbR6)
      midi.sendControlChange(DEVICE_PORT, 1, 96, curRec.reverbR6)
      noOp ()      
-- eqMix
      ctrl = controls.get(85)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.eqMix)
      midi.sendControlChange(DEVICE_PORT, 1, 85, curRec.eqMix)
      noOp ()         
-- eqTilt
      ctrl = controls.get(86)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.eqTilt)
      midi.sendControlChange(DEVICE_PORT, 1, 83, curRec.eqTilt)
      noOp ()          
-- eqFreq
      ctrl = controls.get(87)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.eqFreq)
      midi.sendControlChange(DEVICE_PORT, 1, 84, curRec.eqFreq)
      noOp ()      
-- compOrTanh
      ctrl = controls.get(180)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.compOrTanh) 
      restoreCompOrTanh(curRec.compOrTanh) -- Check this
      noOp ()     
-- compMix
      ctrl = controls.get(81)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.compMix) 
      midi.sendControlChange(DEVICE_PORT, 1, 93, curRec.compMix)
      noOp ()         
-- compThresh
      ctrl = controls.get(82)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.compThresh)
      midi.sendControlChange(DEVICE_PORT, 1, 90, curRec.compThresh)
      noOp ()        
-- compAttack
      ctrl = controls.get(83)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.compAttack)
      midi.sendControlChange(DEVICE_PORT, 1, 91, curRec.compAttack)
      noOp ()        
-- compRatio
      ctrl = controls.get(84)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.compRatio)
      midi.sendControlChange(DEVICE_PORT, 1, 92, curRec.compRatio)
      noOp ()        
-- delayOut
      ctrl = controls.get(135)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.delayOut)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.delayOut)
      noOp ()        
-- delayFeedback
      ctrl = controls.get(136)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.delayFeedback)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.delayFeedback)
      noOp ()        
-- delayTap1
      ctrl = controls.get(145)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.delayTap1)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.delayTap1)
      noOp ()        
-- delayTap2
      ctrl = controls.get(146)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.delayTap2)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.delayTap2)
      noOp ()        
-- autoTap34
      ctrl = controls.get(37)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.autoTap34)
      restoreAutoTap34 (curRec.autoTap34)
      noOp ()      
-- delayTime
      ctrl = controls.get(138)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.delayTime)
      matrixPoke(105, curRec.delayTime)
      noOp ()       
-- convMorphSpeed
      ctrl = controls.get(158)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convMorphSpeed)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.convMorphSpeed)
      noOp ()      
-- convMorphRange
      ctrl = controls.get(55)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convMorphRange)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.convMorphRange)
      noOp ()        
-- convMorphShape
      ctrl = controls.get(140)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convMorphShape)
      formulaPoke (38, 50, curRec.convMorphShape)
      noOp ()      
-- convYControl
      ctrl = controls.get(141)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.convYControl)
      pVal = ctrlMsg:getParameterNumber()     
      set86CCValue(pVal, curRec.convYControl)
      noOp ()        
-- filterIter1
      ctrl = controls.get(119)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.filterIter1)
      restoreFilterIter1 (curRec.filterIter1)
      noOp ()          
-- filterIter2
      ctrl = controls.get(132)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.filterIter2) 
      restoreFilterIter2 (curRec.filterIter2)
      noOp ()         
-- transposeInt
-- Set these in the transpose controls - will already be set
-- masterDetune
      ctrl = controls.get(155)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.masterDetune)
      midi.sendControlChange(DEVICE_PORT, 1, 10, curRec.masterDetune)
      noOp () 
-- tuningIndex
      ctrl = controls.get(133)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.tuningIndex)
      restoreTunings(curRec.tuningIndex)
      noOp ()         
-- monoSwitch
      ctrl = controls.get(116)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.monoSwitch)
      midi.sendControlChange(DEVICE_PORT, 1, 9, curRec.monoSwitch)
      noOp ()        
-- monoInterval
      ctrl = controls.get(117)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.monoInterval)
      matrixPoke(48, curRec.monoInterval)
      noOp ()       
-- monoMode - Continuum Only
-- Splits - Continuum Only
if (config.osmose_enabled == false) then
-- Mono Mode
      ctrl = controls.get(144)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.monoMode) 
      matrixPoke(46, curRec.monoMode)
      noOp ()
-- Split Point
      ctrl = controls.get(124)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.splitPoint) 
      matrixPoke(1, curRec.splitPoint)
      noOp ()    
-- Split Mode
      ctrl = controls.get(126)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.splitMode)
      matrixPoke(45, curRec.splitMode)
      noOp ()  
end
-- postGain
      ctrl = controls.get(128)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.postGain) 
      midi.sendControlChange(DEVICE_PORT, 1, 18, curRec.postGain)
      noOp ()       
-- preGain
      ctrl = controls.get(139)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.preGain)
      midi.sendControlChange(DEVICE_PORT, 1, 26, curRec.preGain)
      noOp ()       
-- Attenuation - Continuum Only
--[[
if (config.osmose_enabled == false) then
      ctrl = controls.get(139)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.attenuation)
      midi.sendControlChange(DEVICE_PORT, 1, 27, curRec.attenuation)   
      noOp () 
end 
--]] 
-- Round Rate
   if (config.osmose_enabled == false) then
      ctrl = controls.get(153)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.roundRate)
      midi.sendControlChange(DEVICE_PORT, 1, 25, curRec.roundRate) -- debugit RR    
      noOp () 
-- Round Initial
      ctrl = controls.get(156)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.roundInitial)
      midi.sendControlChange(DEVICE_PORT, 1, 28, curRec.roundInitial)  -- debugit RR   
      noOp () 
   end    
-- YVolume
      ctrl = controls.get(148)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      pVal = ctrlMsg:getParameterNumber()           
if config.osmose_enabled then -- If continuum this is not visible
        ctrlMsg:setValue(curRec.YVolume)   
        set86CCValue(pVal, curRec.YVolume)
        noOp ()
else
        set86CCValue(117, 8192) -- Make sure YVAL is set to 0 for Continuum devices)
        noOp ()
end
-- YTremCtrl
      ctrl = controls.get(71)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.YTremCtrl)
      pVal = ctrlMsg:getParameterNumber() 
      pVal = math.floor(pVal / 10) -- Adjust for CC97 paremeter * 10   t        
      set97CCValue(pVal, curRec.YTremCtrl)
      noOp ()  
-- ZTremCtrl
      ctrl = controls.get(160)
      controlValue = ctrl:getValue("value")
      ctrlMsg = controlValue:getMessage()
      ctrlMsg:setValue(curRec.ZTremCtrl)
      pVal = ctrlMsg:getParameterNumber() 
      pVal = math.floor(pVal / 10) -- Adjust for CC97 paremeter * 10    
      set97CCValue(pVal, curRec.ZTremCtrl)
      noOp ()  
end

function clearUserTable()
   print("User Table Cleared")
   for i = 1, NUMUSERRECS do
     userTable[i].saved = 0
     userTable[i].name = ""   
   end
   persist(userTable)
end

-- Reset the current preset - load up curRec defaults
function resetPreset (valueObject, value) 
-- Make sure nothing selected
   for i= 0, 29 do
      ctrl = controls.get(i+USER_START)
      ctrl:setColor(RED)      
   end
-- Do the Reset
  restoreUserConfig (true)
end



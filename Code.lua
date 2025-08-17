local CONTROL_CHANGE_MSB_INC = 86
local CONTROL_CHANGE_MSB_DEC = 97
local DEVICE_PORT = PORT_1
local RECIRC_CODE = 62
local prevValueMsb = 0
local CAT_STRINGS = 1
local CAT_WINDS = 2
local CAT_VOCAL = 3
local CAT_KEYBOARD = 4
local CAT_CLASSIC = 5
local CAT_OTHER = 6
local CAT_PERCUSSION = 7
local CAT_TUNEDPERC = 8
local CAT_PROCESSOR = 9
local CAT_DRONE = 10
local CAT_MIDI = 11
local CAT_CVC = 12
local CAT_UTILITY = 13
local CAT_OTHER1 = 14
-- Names longer than this will be truncated when shown on controls. SOR
local MAX_NAME_LENGTH = 14 

-- Global Initialization flags
storeInitialized = false -- Don't call certain things on Electra One startup procedure
repSurfPushed = false
repPedalsPushed = false
repMidiPushed = false
sendSysPresetInit = false
selectSystemFlag = false
pedal1Init = false
pedal2Init = false

-- Other Globals
curSystemPreset = 0
curCategory = 1
curCC32 = 0 -- If more than 128 presets in a category
curPresetName = ""
userNameProcessing = false
nameInProgress = false
macroInProgress = false
thumbInProgress = false
convInProgress = false
macrosLoaded = false
userNameIndex = 0
curName=""
lastName = "" -- Last CC56 name processed - should be current preset
lastNameProcessed = false
contextProcessed = false
macroString = ""
convString = ""
currentPresetIndex = 0
currentnName = true -- Flag for initial returned name = Current name, then rest
presetOffset = 0 -- Offset to change user preset on COntinuum as only 16 are shown, need to track bank 
presetPosSelect = 0
muteVal = 60 -- Default pre-gain (but will be set from reading presets)
matrixStream = false
lowVersion = 8.0 -- Default to 10.35
highVersion = 12.0 -- Default to 10.35
-- variables to maintain macro display on page change
macro_i_name = ""
macro_i_val = 0
macro_ii_name = ""
macro_ii_val = 0
macro_iii_name = ""
macro_iii_val = 0
macro_iv_name = ""
macro_iv_val = 0
macro_v_name = ""
macro_v_val = 0
macro_vi_name = ""
macro_vi_val = 0
-- Dummies to reserve some memory up front
userNames = {"U1","U2","U3","U4","U5","U6","U7","U8","U9","U10","U11","U12","U13","U14","U15","U16",
            "U17", "U18", "U19", "U20", "U21", "U22", "U23", "U24", "U25", "U26", "U27", "U28", "U29", "U30", "U31","U32",
            "U33", "U34", "U35", "U36", "U37", "U38", "U39", "U40", "U41", "U42", "U43", "U44", "U45", "U46", "U47","U48",
            "U49", "U50", "U51", "U52", "U53", "U54", "U55", "U56", "U57", "U58", "U59", "U60", "U61", "U62", "U63","U64",
            "U65", "U66", "U67", "U68", "U69", "U70", "U71", "U72", "U73", "U74", "U75", "U76", "U77", "U78", "U79","U80",
            "U81", "U82", "U83", "U84", "U85", "U86", "U87", "U88", "U89", "U90", "U91", "U92", "U93", "U94", "U95","U96",
            "U97", "U98", "U99", "U100", "U101", "U102", "U103", "U104", 
            "U105", "U106", "U107", "U108", "U109", "U110", "U111","U112",
            "U113", "U114", "U115", "U116", "U117", "U118", "U119", "120", 
            "U121", "U122", "U123", "U124", "U125", "U126", "U127","U128"}

-- The remainder of the variables in this setup section wer added by SOR
-- for getting system presets.
local firmwareVersion
local hasFirmwareVersionAlreadyBeenReceived = false
local haveSystemPresetsBeenUpdated = false
local isAccumulatingSystemPresetContext = false
local isAccumulatingSystemPresetName = false
local isGettingSystemPresets = false
local receivedSystemPresetContext = ""
local receivedSystemPresetName = ""
local systemPresetContextBuffer = ""
local systemPresetNameBuffer = ""
local versionText = ""

-- System presets grouped by category. SOR
local systemPresetCategories = {}
systemPresetCategories = {}
for category = CAT_STRINGS, CAT_OTHER1 do
    systemPresetCategories[category] = {}
end

-- A dictionary for looking up the system preset category number 
-- corresponding to the 2-letter category code provided by the instrument
-- in the system preset list. The category number identifies the category
-- when loading a preset on the instrument. SOR
local categoryNos = {}
categoryNos["CL"] = CAT_CLASSIC
categoryNos["CV"] = CAT_CVC
categoryNos["DO"] = CAT_DRONE
categoryNos["KY"] = CAT_KEYBOARD
categoryNos["MD"] = CAT_MIDI
categoryNos["OT"] = CAT_OTHER
categoryNos["PE"] = CAT_PERCUSSION
categoryNos["PR"] = CAT_PROCESSOR
categoryNos["PT"] = CAT_TUNEDPERC
categoryNos["ST"] = CAT_STRINGS
categoryNos["VO"] = CAT_VOCAL
categoryNos["UT"] = CAT_UTILITY
categoryNos["WI"] = CAT_WINDS

-- A dictionary of short preset names, for display on the E1,
-- corresponding to preset names longer than MAX_NAME_LENGTH characters. 
-- If a short name is not specified, 
-- the long name will be truncated on the E1. SOR
local shortPresetNames = {}
shortPresetNames["Acrylic Clock 2"] = "Acrylic Clock2"
shortPresetNames["Additive Gnilham"] = "Add Gnilham"
shortPresetNames["Additive Vocal 1 Transform"] = "Add Vocal1 Tr"
shortPresetNames["Additive Vocal 1"] = "Add Vocal1"
shortPresetNames["Analog ADSR - Var1"] = "Analog ADSR V1"
shortPresetNames["Analog Overload"] = "Analog Ovrload"
shortPresetNames["Another Big One"] = "Another BigOne"
shortPresetNames["Anthophila Organ"] = "Anthoph Organ"
shortPresetNames["Around the Periapsis Ch1"] = "AroundPeriap1"
shortPresetNames["Around the Periapsis"] = "AroundPeriapsi"
shortPresetNames["Arpeggiator 4 Step"] = "Arp 4 Step"
shortPresetNames["Arpeggiator Resonant"] = "Arp Resonant"
shortPresetNames["Bajaron Light Ship"] = "BajaronShip"
shortPresetNames["Basic Bowed Spring"] = "Bowed Spring"
shortPresetNames["Basic Spring Bell"] = "Spring Bell"
shortPresetNames["Beautiful Pursuit Ch1"] = "Beaut Pursuit1"
shortPresetNames["Beautiful Pursuit"] = "Beaut Pursuit"
shortPresetNames["Bells in the Fields"] = "Bells Fields"
shortPresetNames["BiqBank - Basic"] = "BiqBankBasic"
shortPresetNames["BiqGraph - Basic"] = "BiqGraphBasic"
shortPresetNames["BiqMouth - Basic"] = "BiqMouthBasic"
shortPresetNames["Boson Particles"] = "BosonParticles"
shortPresetNames["Bowed Double Reed"] = "Bowed Dbl Reed"
shortPresetNames["Celestial Basin"] = "CelestialBasin"
shortPresetNames["Celestial Following"] = "Celest Follow"
shortPresetNames["Chinese Clarinet"] = "Chinese Clar"
shortPresetNames["Choir on Kepler-452b"] = "ChoirOnKeplar"
shortPresetNames["Chord Generator"] = "ChordGenerator"
shortPresetNames["Cimbalom - Continuous"] = "Cimbalom Cont"
shortPresetNames["Cimbalom - Z Pitch"] = "Cimbalom ZPtch"
shortPresetNames["Clinical Oscillator 1"] = "Clin Osc1"
shortPresetNames["Cork the Bottle"] = "CorktheBottle"
shortPresetNames["Country Resonator"] = "Country Reson"
shortPresetNames["Cowell Triangles Fund on Y"] = "CowellTriang Y"
shortPresetNames["Cowell Triangles"] = "Cowell Triang"
shortPresetNames["CVC 10v Linear Z"] = "10v Linear Z"
shortPresetNames["CVC 10v Square Z"] = "10v Square Z"
shortPresetNames["CVC 5v C0 Linear Z"] = "5v C0 Linear Z"
shortPresetNames["CVC 5v C0 Square Z"] = "5v C0 Square Z"
shortPresetNames["CVC 5v C2 Linear Z"] = "5v C2 Linear Z"
shortPresetNames["CVC 5v C2 Square Z"] = "5v C2 Square Z"
shortPresetNames["CVC 5v C4 Linear Z"] = "5v C4 Linear Z"
shortPresetNames["CVC 5v C4 Square Z"] = "5v C4 Square Z"
shortPresetNames["CVC Buchla Linear Z"] = "BuchlaLinear Z"
shortPresetNames["CVC Buchla Square Z"] = "BuchlaSquare Z"
shortPresetNames["CVC Four Shape Generators"] = "Four SGs"
shortPresetNames["CVC Voyager Linear Z"] = "VoyagerLinearZ"
shortPresetNames["CVC Voyager Square Z"] = "VoyagerSquareZ"
shortPresetNames["CVC Y Shelf Linear Z"] = "YShelf LinearZ"
shortPresetNames["CVC Y Shelf Square Z"] = "YShelf SquareZ"
shortPresetNames["CZ Dirt Bass - Var1"] = "CZDirt Bass V1"
shortPresetNames["Diatonic Cluster Saw"] = "Cluster Saw"
shortPresetNames["Diatonic Cluster Triangle"] = "Cluster Tri"
shortPresetNames["Dirty Oscillator v2"] = "Dirty Osc v2"
shortPresetNames["Distant Transmission Choir"] = "DistTransChoir"
shortPresetNames["Dolce Cristallo Space"] = "CristalloSpace"
shortPresetNames["Dolce Cristallo"] = "DolceCristallo"
shortPresetNames["Drum-Machine Windowed"] = "Drum-Machine"
shortPresetNames["Dual Ladder Sweep"] = "DualLadrSweep"
shortPresetNames["Dual Resonators"] = "DualResonators"
shortPresetNames["Dual Spectra Voice"] = "DualSpectVoice"
shortPresetNames["Dueling BiqBanks"] = "Duel BiqBanks"
shortPresetNames["Eastern Slider Ch1"] = "Eastern Slider"
shortPresetNames["Echo of a Marimba"] = "Echo Marimba"
shortPresetNames["Effect Modman 1"] = "Effect Modman1"
shortPresetNames["Electric Comb T"] = "EletricCombo T"
shortPresetNames["Electric Guitar Saturated"] = "El Guitar Sat"
shortPresetNames["Electric Guitar"] = "El Guitar"
shortPresetNames["Electric Harpsychord"] = "El Harpsychord"
shortPresetNames["Exposure Ensemble"] = "ExposureEnsem"
shortPresetNames["Filter -  The Ladder"] = "Filter Ladder"
shortPresetNames["Flutter Blossom T"] = "FluterBlossomT"
shortPresetNames["FM DreamPiano - Var1"] = "FM Piano-Var1"
shortPresetNames["FOF VariableRes"] = "FOFVariableRes"
shortPresetNames["Fragaria Fields"] = "Fragaria Field"
shortPresetNames["Gamelan Spinner"] = "Gamelan Spin"
shortPresetNames["Glass Chorus Reverse"] = "GlassChorusRev"
shortPresetNames["GrainSilo Woodwind"] = "GrainSilo wind"
shortPresetNames["Grandfather Clock"] = "Grand Clock"
shortPresetNames["Grinding Stone Calliope"] = "Grind Calliope"
shortPresetNames["Happy Birthday Ed 20"] = "HappyBirthEd20"
shortPresetNames["Harmonic Looper"] = "HarmonicLooper"
shortPresetNames["Harmonic Resonator"] = "Harmonic Reson"
shortPresetNames["Harmonoid Spark"] = "HarmSpark"
shortPresetNames["Heavenly Corporation Ch1"] = "Heaven CorpCh1"
shortPresetNames["Jaymar Toy Piano"] = "JaymarToyPiano"
shortPresetNames["Jenny Dark Acid - Var1"] = "JennyDarkAcid1"
shortPresetNames["Jenny Dark Acid"] = "JennyDarkAcid"
shortPresetNames["Jenny FromTo - Var1"] = "Jenny FromTo 1"
shortPresetNames["Jenny Shepard Down - Var1"] = "JenShepDown V1"
shortPresetNames["Jenny Shepard Down"] = "JenShepardDown"
shortPresetNames["Jenny Shepard Up"] = "JennyShepardUp"
shortPresetNames["Jenny Touch Drone"] = "JennyTchDrone"
shortPresetNames["JennyBasic FixRes"] = "Jenny FixRes"
shortPresetNames["Jupiter Mission"] = "JupiterMission"
shortPresetNames["Karplus & ModMan"] = "Karplus&Modman"
shortPresetNames["Kinetic - Bouncing"] = "Kin Bouncing"
shortPresetNames["Kinetic - Bowed Spring"] = "Kin Bow Spring"
shortPresetNames["Kinetic - Bowed Waveguide"] = "Kin Bowed WG"
shortPresetNames["Kinetic - Clavinet - Var1"] = "Kin ClavinetV1"
shortPresetNames["Kinetic - Clavinet"] = "Kin Clavinet"
shortPresetNames["Kinetic - Crackling Noise"] = "Kin Crackling"
shortPresetNames["Kinetic - Dirty Osc - Var1"] = "Kin DirtyOscV1"
shortPresetNames["Kinetic - Dirty Osc"] = "Kin DirtyOsc"
shortPresetNames["Kinetic - Filter"] = "Kinetic Filter"
shortPresetNames["Kinetic - Overtones"] = "Kin Overtones"
shortPresetNames["Kinetic - Spring Bell"] = "Kin Sprng Bell"
shortPresetNames["Kinetic - StickSlip Filter"] = "StickSlip Filt"
shortPresetNames["Kinetic - Tracker"] = "Kin Tracker"
shortPresetNames["Kinetic - U-Bass"] = "Kinetic U-Bass"
shortPresetNames["Kinetic - Vinyl"] = "Kinetic Vinyl"
shortPresetNames["Kinetic - Waveguide"] = "Kin Waveguide"
shortPresetNames["Kinetic as Filter"] = "Kinetic Filter"
shortPresetNames["Kinetic Bowed FDN"] = "Kin Bowed FCN"
shortPresetNames["Kinetic Cabinet"] = "KineticCabinet"
shortPresetNames["Kinetic Contioline"] = "Kin Contioline"
shortPresetNames["Kinetic Disto Analog"] = "Kin Disto Analog"
shortPresetNames["Kinetic Friction"] = "Kin Friction"
shortPresetNames["Kinetic MicroMotor"] = "Kin MicroMotor"
shortPresetNames["Kinetic Rubber Skin"] = "Kin RubberSkin"
shortPresetNames["Kinetic Soundboard"] = "Kin Soundbrd"
shortPresetNames["Kinetic WG AkouBass - Var1"] = "Kin AkouBass 1"
shortPresetNames["Kinetic WG AkouBass"] = "Kin AkouBass"
shortPresetNames["Kinetic-Wavebank Morph"] = "Kin WB Morph"
shortPresetNames["Kontakt 1 Perform"] = "Kontakt1Perf"
shortPresetNames["Kyma 3 Initial Round"] = "Kyma Init Rnd"
shortPresetNames["Kyma 4 Release Round"] = "Kyma 4 Rel Rnd"
shortPresetNames["Lisithean Motor"] = "LisitheanMotor"
shortPresetNames["Magic Carillon - Var1"] = "Mag Carillion1"
shortPresetNames["Magic Carillon - Var2"] = "Mag Carillion2"
shortPresetNames["Marlin Perkins 1"] = "MarlinPerkins1"
shortPresetNames["Marlin Perkins 2"] = "MarlinPerkins2"
shortPresetNames["Martian Landing Pad"] = "MartianLandPad"
shortPresetNames["Mellow Pedal Steel"] = "Mel Ped Steel"
shortPresetNames["Metal Rainstick"] = "MetalRainstick"
shortPresetNames["Metallic Pattern Gen"] = "Metal Pat Gen"
shortPresetNames["MicroDelay PipeWG"] = "MicroDlyPipeWG"
shortPresetNames["MicroDelay WaveGuide v1"] = "Micro WG v1"
shortPresetNames["MicroDelay WaveGuide v2"] = "Micro WG v2"
shortPresetNames["MicroDelay WaveGuide v3"] = "Micro WG v3"
shortPresetNames["Mini Shepard Breathing"] = "MiniShepBreath"
shortPresetNames["Mini Shepard Resonant"] = "MiniShepReson"
shortPresetNames["Model String Wind"] = "Model Str Wind"
shortPresetNames["ModMan - Pulsed"] = "ModMan Pulsed"
shortPresetNames["Morphing Church Organ"] = "MorphChurchOrg"
shortPresetNames["Morphing Wavebank Pad 1"] = "Morph WB Pad 1"
shortPresetNames["Morphing Wavebank Pad 2"] = "Morph WB Pad 2"
shortPresetNames["Mountain Slider Ch1"] = "Mount SliderC1"
shortPresetNames["Mountain Slider"] = "Mountain Slide"
shortPresetNames["Mouth Sequence Ch1"] = "MouthSeq Ch1"
shortPresetNames["MtoStereo Delay"] = "Stereo Delay"
shortPresetNames["Music Box Because Ch1"] = "MusBoxBecause1"
shortPresetNames["Music Box Because"] = "MusBoxBecause"
shortPresetNames["Music Box Bells"] = "MusBoxBells"
shortPresetNames["NGoni - Kinetic"] = "NGoni-Kinetic"
shortPresetNames["Noise - Out of Phase"] = "Noise Phased"
shortPresetNames["Noise - White at -35 RMS"] = "Noise-35dB RMS"
shortPresetNames["Noise - White Stereo"] = "NoiseWhiteSter"
shortPresetNames["Noisy Old Oscillator"] = "Noisy Old Osc"
shortPresetNames["Northern Lights"] = "North Lights"
shortPresetNames["Notch Lightning"] = "NotchLightning"
shortPresetNames["Old Pad Machine"] = "OldPad Machine"
shortPresetNames["Omnisphere 1 Perform"] = "Omni 1 Perform"
shortPresetNames["Omnisphere 2 Round"] = "Omni 2 Round"
shortPresetNames["Omnisphere 3 Initial Round"] = "Omni 3 InitRnd"
shortPresetNames["Omnisphere 4 Semitone"] = "Omni 4 Semitone"
shortPresetNames["Omnisphere 5 Mono"] = "Omni 5 Mono"
shortPresetNames["Organo Espressivo"] = "Org Espressivo"
shortPresetNames["Osc - A440 at -35"] = "Osc 440-35dB"
shortPresetNames["Osc - Formula Delay"] = "Osc Form Delay"
shortPresetNames["Osc - Pitch via Z"] = "OscPitch via Z"
shortPresetNames["Osc - Random Pitch"] = "Osc Rand Pitch"
shortPresetNames["Osc - Sine Wave"] = "Osc Sine Wave"
shortPresetNames["Osc - Subtractive Synth"] = "Osc Sub Synth"
shortPresetNames["Osc - Waveshaping"] = "Osc Waveshape"
shortPresetNames["Phase Controled ModMan"] = "PhaseCtrlMdMan"
shortPresetNames["Philco Chromatic"] = "PhicoChromatix"
shortPresetNames["Plane Tiv Organ"] = "PlaneTiv Organ"
shortPresetNames["Plucked Soup Can"] = "Pluck Soup Can"
shortPresetNames["Remembrance Bells"] = "Remember Bells"
shortPresetNames["Resizable Guitar"] = "Resizable Gtr"
shortPresetNames["Resonant Drum 1"] = "Resonant Drum1"
shortPresetNames["Resonant Drum 2"] = "Resonant Drum2"
shortPresetNames["Rhythm And Bass"] = "Rhythm & Bass"
shortPresetNames["Ring Mod - Basic"] = "Ring Mod Basic"
shortPresetNames["Ring Mod - Voice 1"] = "RingModVoice1"
shortPresetNames["Ring Mod - Voice 2"] = "RingMod Voice2"
shortPresetNames["Ring Mod - Voice"] = "RingMod Voice"
shortPresetNames["Rubber Band Stars"] = "RubberBndStars"
shortPresetNames["Sequencer 1 Ch1"] = "Sequencer 1Ch1"
shortPresetNames["Should I Stay or Should I Go"] = "Should I Stay"
shortPresetNames["SiloString Pizz"] = "SiloStr Pizz"
shortPresetNames["Simple and Nice"] = "SimpleandNice"
shortPresetNames["SineBank - Basic"] = "SineBank Basic"
shortPresetNames["SineBank FM String"] = "SineBnk FM Str"
shortPresetNames["SineSpray - Basic"] = "SineSprayBasic"
shortPresetNames["SineSpray Rain via Surface"] = "SineSpray Rain"
shortPresetNames["Singing Bamboo 2"] = "Sing Bamboo 2"
shortPresetNames["Singing Oscillators"] = "Singing Oscill"
shortPresetNames["Small Cloud Gamelan"] = "Small Gamelan"
shortPresetNames["Soprano Recorder"] = "Sop Recorder"
shortPresetNames["Spectral Marimba"] = "SpectraMarimba"
shortPresetNames["Spectrum with MidiClock"] = "Spect MidiClk"
shortPresetNames["Spiccato Tremolo Dual"] = "Spic TremDual"
shortPresetNames["Spiccato Tremolo Single"] = "Spic TremSing"
shortPresetNames["Spinning Metal Rings"] = "SpinMetalRings"
shortPresetNames["Spiritus Subteranne"] = "SpiritSubteran"
shortPresetNames["Spring Shimming Bell"] = "Shimming Bell"
shortPresetNames["Sputnik's Dream"] = "Sputnik Dream"
shortPresetNames["Squeaky Balloon String"] = "Squeak Balloon"
shortPresetNames["Steel Pan Kalimba"] = "Steel Kalimba"
shortPresetNames["Stretch String m1 T"] = "StretchStrm1T"
shortPresetNames["Stretch String m2 T"] = "StretchStrm2T"
shortPresetNames["Stretch String m3 T"] = "StretchStrm3T"
shortPresetNames["Stretch String v2 T"] = "StretchStrV2T"
shortPresetNames["Stretch String v4 T"] = "StretchStrV4T"
shortPresetNames["Strummed Gtr 3HRSolo"] = "StrumGtr3HRSo"
shortPresetNames["Strummed Gtr Rhythm T 950"] = "StrumGtrRhy T"
shortPresetNames["Sub-Harmonic Generator"] = "Sub-Harm Gen"
shortPresetNames["Submit Job to Mainframe"] = "Sub Mainframe"
shortPresetNames["Sympathy String"] = "Sympathy Str"
shortPresetNames["Synchronous Orbits"] = "SynchOrbits"
shortPresetNames["Synthetic Cathedral"] = "SynthCathedral"
shortPresetNames["The Long Goodbye"] = "TheLongGoodbye"
shortPresetNames["The Slow Descent"] = "TheSlowDescent"
shortPresetNames["The Touch Guitar"] = "Touch Guitar"
shortPresetNames["The Wind on Callisto"] = "Wind on Callisto"
shortPresetNames["Through the Photodiode"] = "ThruPhotodiode"
shortPresetNames["Tibetan Throat Stick"] = "Tibetan Throat"
shortPresetNames["Tremolo Resonator"] = "Trem Resonator"
shortPresetNames["Tunable Tanpura"] = "Tun Tanpura"
shortPresetNames["Two Handed Voice"] = "TwoHandedVoice"
shortPresetNames["Uki Pizz w Snap"] = "Vln PizzSnap"
shortPresetNames["Unanswered Question"] = "Unans Question"
shortPresetNames["Underwater Ceramics"] = "Underwater Cer"
shortPresetNames["Vibrato Organ T"] = "Vibrato Org T"
shortPresetNames["Vintage Electro"] = "VintageElectro"
shortPresetNames["Vln Vla Cel Bass 1"] = "VlnVlaCelCb1"
shortPresetNames["Vln Vla Cel Bass 2 Ch1"] = "VlnVlaCelCb1C1"
shortPresetNames["Vln Vla Cel Bass 2"] = "VlnVlaCelCb2"
shortPresetNames["Vln Vla Cel Bass 3"] = "VlnVlaCelCb3"
shortPresetNames["Vln Vla Cel Bass 4"] = "VlnVlaCelCb4"
shortPresetNames["Vln Vla Cel Bass Ambience"] = "VlnVlaCelCbAmb"
shortPresetNames["Vln Vla Cel Bass Bridge"] = "VlnVlaCelCbBr"
shortPresetNames["VlnVlaVlcCbFull"] = "VlnVlaVlcCbFl"
shortPresetNames["VlnVlaVlcCbPlus"] = "VlnVlaVLcCb+"
shortPresetNames["Vocalized Buzzard"] = "Vocal Buzzard"
shortPresetNames["Voice of the Woods"] = "Voice of Woods"
shortPresetNames["Waterphone Strings"] = "WaterphoneStr"
shortPresetNames["WaveBank - Basic"] = "WaveBank Basic"
shortPresetNames["Windtube Air Reed"] = "Wtube Air Reed"
shortPresetNames["Windtube Double Reed"] = "Wtube Dbl Reed"
shortPresetNames["Windtube Single Reed"] = "Wtube Sin Reed"
shortPresetNames["Winter Skipping Pond"] = "WinterSkipPond"
shortPresetNames["Zwei Baende with Noise"] = "ZweiBaendNoise"

  -- Clear the Info text
  function clearInfo() 
     info.setText("")
  end

-- Test getting just CCs
function midi.onControlChange(midiInput, channel, controllerNumber, value)
  local midi = midiInput
  local chan = math.floor (channel)
  local cc = math.floor (controllerNumber)
  local val = math.floor (value)

  if (chan == 16 and cc == 102) then -- Firmware High Address
    highVersion = value
  end
  if (chan == 16 and cc == 103) then -- Firmware Low Address
      lowVersion = value
      -- Amended by SOR for getting system presets.
      if not hasFirmwareVersionAlreadyBeenReceived then
          print("First time firmware version received")
          -- There's no specific command to request the firmware version.
          -- The instrument sends it more than once: on connecting to E1;
          -- when sending user presets; when sending system presets, etc.
          -- We don't want to show the firmware version every time it is received,
          -- as there may be a progress message in the info text while
          -- preset data is being received.  
          -- So save the version info to a variable to be shown again
          -- when all the preset data has been received.
          hasFirmwareVersionAlreadyBeenReceived = true
          firmwareVersion = ((128 * highVersion)  + lowVersion) / 100
          versionText = "Ver: 1.0/"..firmwareVersion
          info.setText(versionText) -- Versions to Info Text
      end
      return
  end  
  if (chan == 16 and cc == 71) then -- Polyphony
    local ctrl = controls.get(183)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    if (val < 16) then
      ctrlMsg:setValue(val)
    else
      print("Polyphony > 15: "..val)
    end
  end
  if (chan == 16 and cc == 72) then -- DSP Polyphony
    local ctrl = controls.get(234)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 16 and cc == 73) then -- CVC Polyphony
    local ctrl = controls.get(172)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end

 -- End Read Only Controls
  if (chan == 1 and cc == 12) then -- Set i
    local ctrl = controls.get(25)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
    macro_i_name = "" -- clear macro global storage   
    --loadMacros() -- Load up macro names - setting C12 value is after names have been output on load   
    macro_i_val = val    
  end
  if (chan == 1 and cc == 13) then -- Set ii
    local ctrl = controls.get(26)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
    macro_ii_name = ""
    --loadMacros()
    macro_ii_val = val    
  end
    if (chan == 1 and cc == 14) then -- Set iii
    local ctrl = controls.get(27)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
    macro_iii_name = ""  
    --loadMacros()
    macro_iii_val = val    
  end
  if (chan == 1 and cc == 15) then -- Set iv
    local ctrl = controls.get(28)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
    macro_iv_name = ""
    --loadMacros()
    macro_iv_val = val    
  end
  if (chan == 1 and cc == 16) then -- Set v
    local ctrl = controls.get(29)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
    macro_v_name = ""   
    --loadMacros()
    macro_v_val = val    
  end 
  if (chan == 1 and cc == 17) then -- Set vi
    local ctrl = controls.get(30)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
    macro_vi_name = ""
    loadMacros() -- Load all macros here as this will always be the last macro output 
    macro_vi_val = val
  end 
  -- Gain & Attenuation Settings
  if (chan == 1 and cc == 26) then -- Pre-Gain
    local ctrl = controls.get(48)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end 
  if (chan == 1 and cc == 18) then -- Post-Gain
    local ctrl = controls.get(45)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 27) then -- Attenuation
    local ctrl = controls.get(244)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  -- Recirculator settings
  if (chan == 1 and cc == 24) then -- Mix
    local ctrl = controls.get(86)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 23) then -- R4
    local ctrl = controls.get(87)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 22) then -- R3
    local ctrl = controls.get(88)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 21) then -- R2
    local ctrl = controls.get(89)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 20) then -- R1
    local ctrl = controls.get(90)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 95) then -- R5
    local ctrl = controls.get(91)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 96) then -- R6
    local ctrl = controls.get(92)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end 
  -- EQ
  if (chan == 1 and cc == 85) then -- Mix
    local ctrl = controls.get(137)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end 
  if (chan == 1 and cc == 84) then -- Frequency
    local ctrl = controls.get(138)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end 
  if (chan == 1 and cc == 83) then -- Tilt
    local ctrl = controls.get(139)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end     
  -- Compressor
  if (chan == 1 and cc == 93) then -- Tilt
    local ctrl = controls.get(133)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 92) then -- Ratio
    local ctrl = controls.get(134)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 91) then -- Attack
    local ctrl = controls.get(135)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 90) then -- Threshold
    local ctrl = controls.get(136)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  -- Set Sus, Sos1, Sos2
   if (chan == 1 and cc == 64) then --Sus
    local ctrl = controls.get(260)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
   if (chan == 1 and cc == 66) then -- Sos1
    local ctrl = controls.get(261)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
   if (chan == 1 and cc == 69) then -- Sos2
    local ctrl = controls.get(262)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end   
-- Audio Input
  if (chan == 1 and cc == 19) then -- Audio Input Level
    local ctrl = controls.get(237)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  -- Ped1
  if (chan == 1 and cc == 76) then -- Ped 1 Min Range
    local ctrl = controls.get(175)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
   if (chan == 1 and cc == 77) then -- Ped 1 Max Range
    local ctrl = controls.get(176)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end 
  -- Ped2
  if (chan == 1 and cc == 78) then -- Ped 2 Min Range
    local ctrl = controls.get(177)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 79) then -- Ped 2 Max Range
    local ctrl = controls.get(178)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  -- Fine Tune
  if (chan == 1 and cc == 10) then -- Fine Tune +/- 60 cents
    local ctrl = controls.get(227)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  -- Rounding
  if (chan == 1 and cc == 25) then -- Round Rate
    local ctrl = controls.get(213)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 65) then -- Round Equal
    local ctrl = controls.get(228)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(val)
  end
  if (chan == 1 and cc == 28) then -- Round Initial
    local ctrl = controls.get(209)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
   -- print("Round Initial ="..val)
    if (val == 0) then
      ctrl:setName("Initial Off")
      ctrl:setColor(WHITE)
    elseif (val == 127 or val == 1) then
      ctrl:setName("Initial On")
      ctrl:setColor(GREEN)
    else
      print("Unexpected Round Initial Read")
    end
    ctrlMsg:setValue(val)
  end        

  -- Mono Switch
  if (chan == 1 and cc == 9) then -- Handle Mono Switch Button
      local ctrl = controls.get(252)
      local controlValue = ctrl:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      if (val == 0) then
        ctrl:setName("Mono Off")
        ctrl:setColor(WHITE)
        ctrlMsg:setValue(0)
      else -- Mono Sw can be any value 1..128 with swtiched pedal that puts out continous data
        ctrl:setName("Mono On")
        ctrl:setColor(GREEN)
        ctrlMsg:setValue(127)
      end
  end                                      
end -- CC event processing

function midi.onMessage(midiInput, midiMessage) -- Process incoming Midi Message Events
  local msg = midiMessage
    if (msg.channel ~= 16) then
        return
    end
    -- Added by SOR for getting system presets.
    if ( msg.controllerNumber==109 and msg.value==49) then
        -- Start of system preset list (beginSysNames)    
        --print("Start of system preset list")
        isGettingSystemPresets = true
        print("Start of system preset list")
        return
    end
    -- Added by SOR for getting system presets.
    if (msg.controllerNumber==109 and msg.value==40) then
        -- End of system preset list (endSysNames)    
        isGettingSystemPresets = false
        print("End of system preset list")
        onEndOfSystemPresetList()
        return
    end
    
     if (msg.controllerNumber==109 and msg.value==54) then -- Start User Names Found
        --print("Start getting names")
        info.setText("Getting presets...")
        userNameProcessing = true
        firstName = true
        userNameIndex=0
     end
     if (msg.controllerNumber==109 and msg.value==55) then -- End User Names Found
        --print("Finished getting names")
        setUserPresetNames()
        if (userNameProcessing == true) then
          userNameProcessing = false
        end
        userNameProcessing = false
        userNameIndex=0
         -- Added by SOR for getting system presets.
        if not haveSystemPresetsBeenUpdated then
            getSystemPresets()
        else
            -- Replace the "Getting presets..." notification 
            -- on the status bar with the version info.
            info.setText(versionText)
        end
     end

     -- Amended by SOR for getting system presets.
     if (msg.controllerNumber==56 and msg.value==0) then
         -- Start of system or user preset name stream
         if isGettingSystemPresets then
             isAccumulatingSystemPresetName = true
             systemPresetNameBuffer = ""
             return
         end
         -- Processing user presets  
           userNameIndex = userNameIndex + 1 -- Index Lua arrays from 1
           nameInProgress = true
           matrixStream=false -- Has no CC56=127 terminator - new stream terminates it       
     end

     if (msg.controllerNumber==56 and msg.value==20) then -- Matrix Stream
           matrixStream = true
     end

     if (msg.controllerNumber==56 and msg.value==14) then -- Convolution Stream
           convInProgress = true
          matrixStream=false -- Has no CC56=127 terminator - new stream terminates it 
     end

     if (msg.controllerNumber==56 and msg.value==15) then -- Convolution Stream
           thumbInProgress = true
           matrixStream=false -- Has no CC56=127 terminator - new stream terminates it       
     end

    -- Amended by SOR for getting system presets.
    if (msg.controllerNumber==56 and msg.value==1) then
        -- Start of macro or system preset context stream 
        if isGettingSystemPresets then
            -- System preset context data, which will include 
            -- the 2-letter category code.
            isAccumulatingSystemPresetContext = true
            systemPresetContextBuffer = ""
            return
        end
        -- Macro context data
        macroString = ""
        contextProcessed = true
        matrixStream=false -- Has no CC56=127 terminator - new stream terminates it
    end

    -- Added by SOR for getting system presets.
    if msg.controllerNumber==56 and msg.value==127 then -- End of stream
        if isAccumulatingSystemPresetName then
            isAccumulatingSystemPresetName = false
            receivedSystemPresetName = trimTrailingNullChar(systemPresetNameBuffer) 
            return
        end
        if isAccumulatingSystemPresetContext then
            isAccumulatingSystemPresetContext = false
            receivedSystemPresetContext = trimTrailingNullChar(systemPresetContextBuffer)
            onSystemPresetReceived()
            return
        end
    end

      if (nameInProgress and msg.controllerNumber==56 and msg.value==127) then -- Stream Ends
          nameInProgress=false
          if (userNameProcessing) then
            if (curName == "" or curName == "-") then
               curName = "Empty"
            end
            if (string.len(curName) > 14) then -- Limit strings for congtrols to 14 chars
              --print("CurName:|"..curName.."|")
              local tmpstr = curName
              curName = string.sub(tmpstr, 1, 14)
            end
            userNames[userNameIndex]=curName -- Store Preset name in name buffer array"
          elseif (currentNameProcessing == true) then
          end
          curName="" -- Reset curName to accumulate the next name
      elseif (contextInProgress and msg.controllerNumber==56 and msg.value==127) then
          contextInProgress = false
      elseif (convInProgress and msg.controllerNumber==56 and msg.value==127) then
          convInProgress = false      
          processConvolution() -- Process the Convolution stream                    
      elseif (matrixStream == true and msg.controllerNumber==56 and msg.value==127) then
         matrixStream = false  -- Won't hurt anything but 127 is not signal of matrix stream end
      elseif (thumbInProgress) then
         thumbInProgress = false
      end
end


function midi.onAfterTouchPoly(midiInput, channel, noteNumber, pressure)
    -- Added by SOR for getting system presets.
    if (isAccumulatingSystemPresetName) then
        -- Accumulate system preset name buffer
        systemPresetNameBuffer =
            systemPresetNameBuffer ..string.char(noteNumber)..string.char(pressure)
        return
    end
    -- Added by SOR for getting system presets.
    if (isAccumulatingSystemPresetContext) then
        -- Accumulate system preset context buffer
        systemPresetContextBuffer =
            systemPresetContextBuffer ..string.char(noteNumber)..string.char(pressure)
        return
    end
      if (convInProgress) then
         convString = convString..math.floor(noteNumber).."|"..math.floor(pressure).."|"
         --print("CS=|"..convString.."|")--debugit       
      end
      if (nameInProgress) then -- Accumulate name global name buffer
         curName = curName..string.char(noteNumber)..string.char(pressure)
      end
      if (lastNameInProgress) then
         lastName = lastName..string.char(noteNumber)..string.char(pressure)      
      end
      if (contextProcessed and macroInProgress) then -- Accumulate Macro String
        macroString=macroString..string.char(noteNumber)..string.char(pressure)
      end

      -- Get Velocity Usage - Read Only
      -- 0 = Static (127), 1=Dynamic, 2 = Formula 
      -- Ignore: MNoNote = 3, // do not output keyOn,keyOff,bends -- for CVC+Midi control of Voyager
      -- Ignore: MMidC = 4, // nn 60 and static velocity all notes (Moog Theremin) 7.44984
      -- Ignore: MAnnounce = 5, // announce continuum presence for SNBN
      if (matrixStream == true and channel==16 and noteNumber == 2) then -- Note Message
        local curVel = math.floor (pressure)
        local ctrl = controls.get(231)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        if (curVel < 3) then     
          ctrlMsg:setValue(curVel)
        else
          print("Not Valid Velocity Mode - Ignore: "..curVel)
        end 
      end
      -- Get CVC info - Read Only (need to bit map parse it)
      if (matrixStream == true and channel==16 and noteNumber == 63) then -- CVC Info
        local curCVC = math.floor (pressure)
        --print("CURCVC = "..curCVC)
        local cvcMode = curCVC & 7
        local cvcLinear = curCVC & 8
              if (cvcLinear == 8) then
                 cvcLinear = 1
              else
                 cvcLinear = 0
              end
        local cvcOutputs = curCVC & 16
              if (cvcOutputs == 16) then
                 cvcOutputs = 1
              else
                 cvcOutputs = 0
              end        
        local cvcBase = curCVC & 112
              if (cvcBase == 32) then
                 cvcBase = 1
              elseif (cvcBase == 64) then
                 cvcBase = 2
              elseif (cvcBase == 96) then
                 cvcBase = 3
              else
                 cvcBase = 0
              end              
        local ctrl = controls.get(238) -- Which of the 7 modes are set
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(cvcMode)
             
             ctrl = controls.get(242) -- Linear or Squared
             controlValue = ctrl:getValue("value")
             ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(cvcLinear)

             ctrl = controls.get(243) -- Outputs
             controlValue = ctrl:getValue("value")
             ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(cvcOutputs) 

             ctrl = controls.get(235) -- Base
             controlValue = ctrl:getValue("value")
             ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(cvcBase)               
      end      
      -- Get Bend - Read Only
      if (matrixStream == true and channel==16 and noteNumber == 40) then -- Bend
        local curBend = math.floor (pressure)
        local ctrl = controls.get(277)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(curBend) 
      end
      -- Get Base Polyphony - Read Only
      if (matrixStream == true and channel==16 and noteNumber == 39) then -- Expanced Polyphony
        local curBasePoly = math.floor (pressure)
        local ctrl = controls.get(106)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(curBasePoly) 
      end       
      -- Get Expanded Polyphony - Read Only
      if (matrixStream == true and channel==16 and noteNumber == 11) then -- Expanced Polyphony
        local curBend = math.floor (pressure)
        local ctrl = controls.get(233)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(curBend) 
      end      
      -- Increased Compuation - Read Only
      if (matrixStream == true and channel==16 and noteNumber == 5) then -- Increased Computation
        local incComp = math.floor (pressure)
        local ctrl = controls.get(264)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             --print("Increased Comp = "..incComp)
             ctrlMsg:setValue(incComp) 
      end             
      -- Get Mono Mode
      if (matrixStream == true and channel==16 and noteNumber == 46) then -- Mono Mode
        local monoMode = math.floor (pressure)
        local ctrl = controls.get(140)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(monoMode) 
      end
      -- Get Mono Interval
      if (matrixStream == true and channel==16 and noteNumber == 48) then -- Mono Interval
        local monoInterval = math.floor (pressure)
        -- print("Mono Interval = "..monoInterval)
        local ctrl = controls.get(267)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(monoInterval) 
      end 
    --  SplitMode
        if (matrixStream == true and channel==16 and noteNumber == 1) then -- Split Mode
        local splitMode = math.floor (pressure)
        local ctrl = controls.get(188)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(splitMode) 
      end  
    -- SplitPoint
        if (matrixStream == true and channel==16 and noteNumber == 45) then -- Split Mode
        local splitPoint = math.floor (pressure)
        local ctrl = controls.get(236)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(splitPoint) 
      end
    -- Round Mode
        if (matrixStream == true and channel==16 and noteNumber == 10) then -- Round Mode
        local roundMode = math.floor (pressure)
        local ctrl = controls.get(210)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(roundMode) 
      end      
    -- Recirc On/Off
    --[[
        if (matrixStream == true and channel==16 and noteNumber == 15) then -- Recirculator On/Off
        local recircCtrl = math.floor (pressure)
        local ctrl = controls.get(158)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        print("Setting Recirc ON/OFF to: "..recircCtrl)
             --ctrlMsg:setValue(recircCtrl) - External set don't do here
             if (recircCtrl == 0) then
                ctrl:setName("Recirc On")
                ctrl:setColor(GREEN)
                info.setText("Recirc=0 ON") -- debugit
             elseif (recircCtrl == 1) then
                ctrl:setName("Recirc Off")
                ctrl:setColor(WHITE)
                info.setText("Recirc=1 OFF") -- debugit                
             else
                print("Unexpected Recirculator Control value")
             end 
        end
    --]]      
      -- Get Pedal 1 Assignments
      if (matrixStream == true and channel==16 and noteNumber == 52) then -- Pedal1 Assign
        local pedal1Assign = math.floor (pressure)
        -- print("pedal1Assign = "..pedal1Assign)
        local ctrl = controls.get(143)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(pedal1Assign) 
      end 
      -- Get Pedal 2 Assignments
      if (matrixStream == true and channel==16 and noteNumber == 53) then -- Pedal2 Assign
        local pedal2Assign = math.floor (pressure)
        --print("Ped 2 Assign = "..pedal2Assign)
        local ctrl = controls.get(164)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(pedal2Assign) 
      end
      
      -- Get Octave Swith mode
      if (matrixStream == true and channel==16 and noteNumber == 7) then -- Ocatve SW mode
        local octSwitchMode = math.floor (pressure)
        --print("OctSwitch Mode = "..octSwitchMode)
        local ctrl = controls.get(173)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(octSwitchMode) 
      end
      -- Get Octave Range
      if (matrixStream == true and channel==16 and noteNumber == 54) then -- Octave Swtich Range
        local octRange = math.floor (pressure)
        --print("Oct Range = "..octRange)
        local ctrl = controls.get(179)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(octRange) 
      end
      -- Get Compressor or TANH (parameters are shared so only this needs to be done)
      if (matrixStream == true and channel==16 and noteNumber == 16) then -- Process Compressor/Tanh
        local cOrT = math.floor (pressure)
        --print("ComporTanh = "..cOrT)
        local ctrl = controls.get(163)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(cOrT)
        setCompOrTanh(cOrT) 
      end
-- Get Pedal1 Assignment
      if (matrixStream == true and channel==16 and noteNumber == 52) then 
        local ped1 = math.floor (pressure)
        local ctrl = controls.get(143)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(ped1) 
      end
-- Get Pedal2 Assignment
      if (matrixStream == true and channel==16 and noteNumber == 53) then 
        local ped2 = math.floor (pressure)
        local ctrl = controls.get(164)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(ped2) 
      end                         
    -- Direction
      if (matrixStream == true and channel==16 and noteNumber == 9) then -- Ocatve SW mode
        local direction = math.floor (pressure)
        --print("Direction = "..direction)
        local ctrl = controls.get(253)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()       
        if (direction == 0) then
           ctrl:setName("Normal")
           ctrl:setColor(GREEN)
           ctrlMsg:setValue(direction)            
        elseif (direction == 1) then
           ctrl:setName("Reverse")
           ctrl:setColor(RED)
           ctrlMsg:setValue(direction)            
        else
           print("Unexpected Direction: "..direction)
        end         
      end
      -- Preserve Surface
      if (matrixStream == true and channel==16 and noteNumber == 56) then -- Ocatve SW mode
        local presSurf = math.floor (pressure)
        --print("Preserve Surface = "..presSurf)
        local ctrl = controls.get(167)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(presSurf)
        if (presSurf == 0) then
           ctrl:setName("Replace")
           ctrl:setColor(GREEN)
        elseif (presSurf == 1) then
           ctrl:setName("Preserve")
           ctrl:setColor(RED)                   
        else
           print("Unexpected Preserve Surface")
        end 
      end
      -- Preserve Pedals
      if (matrixStream == true and channel==16 and noteNumber == 57) then -- Ocatve SW mode
        local presPed = math.floor (pressure)
        --print("Preserve Surface = "..presPed)
        local ctrl = controls.get(168)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(presPed)
        if (presPed == 0) then
           ctrl:setName("Replace")
           ctrl:setColor(GREEN)
        elseif (presPed == 1) then
           ctrl:setName("Preserve")
           ctrl:setColor(RED)                   
        else
           print("Unexpected Preserve Pedals")
        end 
      end
      -- Preserve Midi
      if (matrixStream == true and channel==16 and noteNumber == 58) then -- Ocatve SW mode
        local presMid = math.floor (pressure)
        --print("Preserve Surface = "..presMid)
        local ctrl = controls.get(169)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
             ctrlMsg:setValue(presMid)
        if (presMid == 0) then
           ctrl:setName("Replace")
           ctrl:setColor(GREEN)
        elseif (presMid == 1) then
           ctrl:setName("Preserve")
           ctrl:setColor(RED)                   
        else
           print("Unexpected Preserve Midi")
        end 
      end                                         
      -- Process Middle C - Transpose
      if (matrixStream == true and channel==16 and noteNumber == 44) then -- MiddleC/Transpose
        local xposeAssign = math.floor (pressure)
        local ctrl = controls.get(78)
        local controlValue = ctrl:getValue("value")
        --local ctrlMsg = controlValue:getMessage()
        -- print("Transpose Val = "..xposeAssign)
        if (xposeAssign == 0) then
        -- nothing
        elseif (xposeAssign == 60) then
          ctrl:setName("Transpose Off")
          ctrl:setColor(WHITE)
        elseif (xposeAssign > 60) then
          xAmt = xposeAssign - 60
         ctrl:setName("Up "..xAmt.." st")
         ctrl:setColor(GREEN)
        else
         xAmt = 60 - xposeAssign
         ctrl:setName("Down "..xAmt.." st")
         ctrl:setColor(GREEN)    
        end              
      end              

end -- of pPress settings

function clearMacros() -- Set all Macros to 0 and set names to blank
    local ctrl --= controls.get(25)
    local controlValue --= ctrl:getValue("value")
    local ctrlMsg --= controlValue:getMessage()
    for i=25,30 
    do
        ctrl = controls.get(i)
        ctrl:setName("")
        controlValue = ctrl:getValue("value")
        ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(0)
    end
end

function getNames(valueObject, value)
     resetMute() -- reset in case on from previous preset
     midi.sendControlChange(DEVICE_PORT, 16, 109, 32) -- Send Names Request
end

--function storeUserSelections()
--    control = controls.get(32)  
--end

function getMacroName (str, len)
   local tmpStr = str
   local sLen = len
   local finalStr=""
   local ix = 1
   local iy = 0 
   local iz = 0
   while (ix <= sLen) 
   do
      if (tmpStr:sub(ix,ix) == " " or tmpStr:sub(ix,ix) =="_" or tmpStr:sub(ix,ix) == "#") then
        -- Handle strange case where # is not getting recognized for some reason - reported the bug
        iy,iz = string.find(finalStr, "C=") -- "C#" may come after last macro
        if (iy ~= nil and iz~=nil) then
           tmpStr = finalStr:sub(1,iy-2)
           return tmpStr
        else
          iy,iz = string.find(finalStr, "A=") -- "Author String should come after last macro
          if (iy ~= nil and iz~=nil) then
             tmpStr = finalStr:sub(1,iy-2)
             return tmpStr
          else
            return finalStr
          end
        end        
      end
      finalStr = finalStr..tmpStr:sub(ix,ix) -- first character in macro name
      ix = ix + 1
   end
   return finalStr
end

function loadMacros()
  local mStr = macroString
  local sLen = string.len(mStr)
  local tLen = sLen
  local tmpStr = ""
  local tStr = ""
  local finalStr = ""
  local s1 = 0
  local s2 = 0
  local lastInd = 0
  local ifound=false
  local iifound=false
  local iiifound=false
  local vfound=false
  local vifound=false
  
  --initMacros() -- clear out macro data
  --print("Macro String: "..mStr)--debugit
  -- Blank out Macros Names.

  control=controls.get(25)
  control:setName("")
  control=controls.get(26)
  control:setName("")
  control=controls.get(27)
  control:setName("")
  control=controls.get(28)
  control:setName("")
  control=controls.get(29)
  control:setName("")
  control=controls.get(30)
  control:setName("") 
 

 for i=1,3
 do
   if (mStr:sub(i,i) == "=") then -- get initial i, ii or v
      if (i == 2 and mStr:sub(i-1, i-1) =="i") then -- Initial i
        tmpStr=mStr:sub(i+1,sLen)
        tLen = string.len(tmpStr)
        finalStr = getMacroName(tmpStr, tLen)
        --print ("Macro i= "..finalStr)
        control=controls.get(25)
        control:setName(finalStr)
        macro_i_name = finalStr -- store macro name for restore on page change
      elseif (i == 2 and mStr:sub(i-1, i-1) =="v") then -- Initial v
        tmpStr=mStr:sub(i+1,sLen)
        tLen = string.len(tmpStr)
        finalStr = getMacroName(tmpStr, tLen)
        --print ("Macro v= "..finalStr)
        control=controls.get(29)
        control:setName(finalStr)
        macro_v_name = finalStr              
      elseif (i==3 and mStr:sub(i-1, i-1)=="i" and mStr:sub(i-2, i-2)=="i") then -- Initial ii
        tmpStr=mStr:sub(i+1,sLen)
        tLen = string.len(tmpStr)       
        finalStr = getMacroName(tmpStr, tLen)
        --print ("Macro ii= "..finalStr)
        control=controls.get(26)
        control:setName(finalStr)
        macro_ii_name = finalStr          
      end -- Eerything else should now have a space before it and can be parse with find     
      i = i+1
   end    
   
 end -- for

-- Handle All regular cases
  s1,s2 = string.find(mStr, " i=")
  if (s1 ~= nil and s2 ~= nil) then
    tmpStr=mStr:sub(s2+1,sLen)
    tLen = string.len(tmpStr)
    finalStr = getMacroName(tmpStr, tLen)
    --print ("Macro i= "..finalStr)
    control=controls.get(25)
    control:setName(finalStr)
    macro_i_name = finalStr          
  end  
  s1,s2 = string.find(mStr, " ii=")
  if (s1 ~= nil and s2 ~= nil) then
    tmpStr=mStr:sub(s2+1,sLen)
    tLen = string.len(tmpStr)
    finalStr = getMacroName(tmpStr, tLen)
    --print ("Macro ii= "..finalStr)
    control=controls.get(26)
    control:setName(finalStr)    
    macro_ii_name = finalStr      
  end  
  s1,s2 = string.find(mStr, " v=")
  if (s1 ~= nil and s2 ~= nil) then
    tmpStr=mStr:sub(s2+1,sLen)
    tLen = string.len(tmpStr)
    finalStr = getMacroName(tmpStr, tLen)
    --print ("Macro v= "..finalStr)
    control=controls.get(29)
    control:setName(finalStr)    
    macro_v_name = finalStr  
  end   
 s1,s2 = string.find(mStr, "iv=")
  if (s1 ~= nil and s2 ~= nil) then
    tmpStr=mStr:sub(s2+1,sLen)
    tLen = string.len(tmpStr)
    finalStr = getMacroName(tmpStr, tLen)
    --print ("Macro iv= "..finalStr)
    control=controls.get(28)
    control:setName(finalStr)    
    macro_iv_name = finalStr      
  end 
  s1,s2 = string.find(mStr, "iii=")
  if (s1 ~= nil and s2 ~= nil) then
    tmpStr=mStr:sub(s2+1,sLen)
    tLen = string.len(tmpStr)
    finalStr = getMacroName(tmpStr, tLen)
    --print ("Macro vi= "..finalStr)
    control=controls.get(27)
    control:setName(finalStr)    
    macro_iii_name = finalStr  
  end 
     -- Process g1/v
  s1,s2 = string.find(mStr, "g1=")
  if (s1 ~= nil and s2 ~= nil) then
    tmpStr=mStr:sub(s2+1,sLen)
    tLen = string.len(tmpStr)
    finalStr = getMacroName(tmpStr, tLen)
    --print ("Macro v= "..finalStr)
    control=controls.get(29)
    control:setName(finalStr)    
    macro_v_name = finalStr  
  end
  -- Process vi
    -- Process g2/vi
  s1,s2 = string.find(mStr, "vi=")
  if (s1 ~= nil and s2 ~= nil) then
    tmpStr=mStr:sub(s2+1,sLen)
    tLen = string.len(tmpStr)
    finalStr = getMacroName(tmpStr, tLen)
    --print ("Macro vi= "..finalStr)
    control=controls.get(30)
    control:setName(finalStr)   
    macro_vi_name = finalStr   
  end
  -- Process g2/vi
  s1,s2 = string.find(mStr, "g2=")
  if (s1 ~= nil and s2 ~= nil) then
    tmpStr=mStr:sub(s2+1,sLen)
    tLen = string.len(tmpStr)
    finalStr = getMacroName(tmpStr, tLen)
    --print ("Macro vi= "..finalStr)
    control=controls.get(30)
    control:setName(finalStr)    
    macro_vi_name = finalStr  
  end
  macroInProgress = false
end

function loadPreset(valueObject, value) -- Load up a preset on pressing button 1-16 offset for bank
  macroInProgress = true
  --nameInProgress = false -- debugit
  -- Initialize controls for new preset
  clearInfo()
  --clearMacros()
  resetMute()
  --initMacros()
  local presetPos = valueObject:getMessage():getValue()

  if (presetPos == 0) then -- adjust for initialization
  --  -- Changing pages triggers Control #1 with 0 value (not sure why) return
   return
  end
  
  if (presetPos+presetOffset >=0 and presetPos+presetOffset-1 < 128) then
     midi.sendControlChange(DEVICE_PORT, 16, 0, 0) -- CC0 = 0 (Category 0 = USer Presets)
     midi.sendControlChange(DEVICE_PORT, 16, 32, 0)  -- CC 32 = 0 (< 129 presets)
     midi.sendProgramChange(DEVICE_PORT, 16, presetPos+presetOffset-1) -- User Preset Program change 0..127
     currentPresetIndex = presetPos+presetOffset-1
     -- Display Current Preset Name  
     lastName = userNames[presetPos+presetOffset] -- Override last name
     control = controls.get(50)
     control:setName(userNames[presetPos+presetOffset])
     midi.sendControlChange(DEVICE_PORT, 16, 109, 16) -- Send get Current Preset Msg to get Macro labels and control values            
  else
     print("Unexpected Preset Index: "..presetPos+presetOffset-1)
  end

  -- Set Sustain, Sos1 and Sos2 off just in case conflict with Tranposition parameters
     midi.sendControlChange(DEVICE_PORT, 1, 64, 0) -- Sustain off
     midi.sendControlChange(DEVICE_PORT, 1, 66, 0) -- Sos1 Off
     midi.sendControlChange(DEVICE_PORT, 1, 69, 0) -- Sos2 Off
  

  -- Set Active Controls to set 1 qhere you can change macro 
  -- pages.setActiveControlSet(1)  
end

function setUserPresetPos (valueObject, value)
   presetPosSelect = valueObject:getMessage():getValue() -- Store the current preset position selected as user store 
   
   group = groups.get(49)
   control = controls.get(50)
   if (value == 0) then -- Make red if its in store preset mode
      control:setColor(ORANGE)
      group:setLabel("CURRENT PRESET")
      group:setColor(ORANGE) 
   else
      control:setColor(RED)
      group:setLabel("Store Preset")
      group:setColor(RED)       
   end
end

function storeUserPreset (valueObject, value)
  local stringProcessing = true
  local strIndex = 1
  local slen = 0
  local ascii1 = ""
  local ascii2 = ""
  --local presetPos
  local tStr = ""
  local s1 = 0
  local s2 = 0
  local whichUserButton = 0
  local control = controls.get(50)
  local tStr = control:getName()
  
  if (presetPosSelect == 0) then -- no write if preset is not selected (initial pick list item)
    if (storeInitialized == false) then -- handle stupid Electra One init process
       storeInitialized = true
       return
    end   
    info.setText("Select Preset Pos") 
    return
  else
    clearInfo()
  end
  -- Don't initialize this function
  whichUserButton = (presetPosSelect) % 16
  if (whichUserButton == 0) then
       whichUserButton = 16
  end 
  local userControl = controls.get(whichUserButton) -- Don't ever change control numbers of user presets
  userControl:setName(tStr) 
  getNames(valueObject, value) -- Reset the names to have correct preset displayed
  
  if (tStr == "CURRENT PRESET") then -- No preset position was selected to store in - return
    info.setText("Select User Preset")
    return
  end  
  
  -- print("Init Storestring = "..tStr) -- debugit

  s1,s2 = string.find(tStr,"%.")
  if (s1 ~= nil and s2 ~= nil) then
  -- Remove any trailing .n (we won't use that)
     pStr = tStr:sub(1,s1-1)
     --print("Storestring= "..pStr)
  else
     pStr = tStr
  end
  -- For no - remove .dot sufix
 -- if (pStr ~= "-") then
 --   local tmpname = pStr.."."..tostring(whichUserButton)
 --   pStr = tmpname
 -- end
  -- print("Store name = "..pStr)
  
  slen = string.len(pStr)
  midi.sendControlChange(DEVICE_PORT, 16, 56, 0) -- Start preset string
  while (strIndex <= slen) 
  do
      if (strIndex+1 <= slen) then -- 2 characters available to send
        ascii1 = string.sub(pStr, strIndex, strIndex)
        ascii2 = string.sub(pStr, strIndex+1, strIndex+1)
        midi.sendAfterTouchPoly(DEVICE_PORT, 16, string.byte(ascii1), string.byte(ascii2))
        --print ("Echars ="..ascii1..ascii2)
        strIndex = strIndex + 2
      else -- Last two chars - Odd number characters - zero fill
        ascii1 = string.sub(pStr, strIndex, strIndex)
        --print ("Ochars ="..ascii1.."0")                          
        midi.sendAfterTouchPoly(DEVICE_PORT, 16, string.byte(ascii1), 0) 
        strIndex = strIndex + 1 
      end
      --strIndex = strIndex + 2 -- bump by 2 chars
  end
  -- Sequence needed to just store current preset back to its position
     -- print("Storing to Preset position: "..presetPosSelect-1)
     midi.sendControlChange(DEVICE_PORT, 16, 56, 127) -- End Preset string
     midi.sendControlChange(DEVICE_PORT, 16, 0, 0) -- Send CC0/CC32
     midi.sendControlChange(DEVICE_PORT, 16, 32, 0)  
     midi.sendControlChange(DEVICE_PORT, 16, 112, presetPosSelect-1) -- Send Store Command
     midi.sendControlChange(DEVICE_PORT, 16, 0, 0) -- Send CC0/C32
     --midi.sendControlChange(DEVICE_PORT, 16, 32, 0)enablere
     midi.sendProgramChange(DEVICE_PORT, 16, presetPosSelect-1)  -- Send Program change - current preset to user position    
  -- Update current preset name
  --   control=controls.get()
  -- Reset so Store is no longer active
     local ctrl = controls.get(32) -- Preset index
     local controlValue = ctrl:getValue("value")
     local ctrlMsg = controlValue:getMessage()
     ctrlMsg:setValue(0) -- Reset Store control
end


function preset.onLoad()
  -- Disable things not yet supported
  -- print("OnLoad Called")
  userNameProcessing = false
  --nameInProgress = false
  macroInProgress = false
  userNameIndex = 0
  curName=""
  lastName=""
  curCategory = 1
 -- Make sure Transposition controls in right initial state
  --control=controls.get(78)
  --control:setName("Transpose Off")
  --matrixPoke(44, 60) -- Set default MiddleC

 -- Reset Recirc On when loading program (maybe later try reading state)
    --matrixPoke (15, 0) -- Enable Recirc = 0
    --control=controls.get(158)   
    --control:setName("Enabled")
  -- sleep(2)
  -- Get iniitial names

end

-- Set User Preset names - they are controls 1-16
function setUserPresetNames()
  presetOffset = 0
  for i = 1,16
  do 
    control = controls.get(i) 
    control:setName(userNames[i])
    --print(userNames[i]) -- debugit
  end
  -- Set the preset tags
    group = groups.get(51)
    group:setLabel("User 1")
    group = groups.get(52)
    group:setLabel("User 2")
    group = groups.get(53)
    group:setLabel("User 3")
    group = groups.get(144)
    group:setLabel("User 4")
    group = groups.get(145)
    group:setLabel("User 5")
    group = groups.get(146)
    group:setLabel("User 6")
    group = groups.get(147)
    group:setLabel("User 7")
    group = groups.get(148)
    group:setLabel("User 8")
    group = groups.get(149)
    group:setLabel("User 9")
    group = groups.get(150)
    group:setLabel("User 10")
    group = groups.get(151)
    group:setLabel("User 11")
    group = groups.get(152)
    group:setLabel("User 12")
    group = groups.get(153)
    group:setLabel("User 13")
    group = groups.get(154)
    group:setLabel("User 14")
    group = groups.get(155)
    group:setLabel("User 15")
    group = groups.get(156)
    group:setLabel("User 16")          
end
function setPresetsAt17()
  presetOffset = 16  
  for i = 17,32
  do 
    control = controls.get(i-presetOffset)
    control:setName(userNames[i])
  end

  -- Set the preset tags  
    group = groups.get(51)
    group:setLabel("User 17")
    group = groups.get(52)
    group:setLabel("User 18")
    group = groups.get(53)
    group:setLabel("User 19")
    group = groups.get(144)
    group:setLabel("User 20")
    group = groups.get(145)
    group:setLabel("User 21")
    group = groups.get(146)
    group:setLabel("User 22")
    group = groups.get(147)
    group:setLabel("User 23")
    group = groups.get(148)
    group:setLabel("User 24")
    group = groups.get(149)
    group:setLabel("User 25")
    group = groups.get(150)
    group:setLabel("User 26")
    group = groups.get(151)
    group:setLabel("User 27")
    group = groups.get(152)
    group:setLabel("User 28")
    group = groups.get(153)
    group:setLabel("User 29")
    group = groups.get(154)
    group:setLabel("User 30")
    group = groups.get(155)
    group:setLabel("User 31")
    group = groups.get(156)
    group:setLabel("User 32")    
end
function setPresetsAt33()
  presetOffset = 32  
  for i = 33,48
  do 
    control = controls.get(i-presetOffset)
    control:setName(userNames[i])
  end

  -- Set the preset tags
    group = groups.get(51)
    group:setLabel("User 33")
    group = groups.get(52)
    group:setLabel("User 34")
    group = groups.get(53)
    group:setLabel("User 35")
    group = groups.get(144)
    group:setLabel("User 36")
    group = groups.get(145)
    group:setLabel("User 37")
    group = groups.get(146)
    group:setLabel("User 38")
    group = groups.get(147)
    group:setLabel("User 39")
    group = groups.get(148)
    group:setLabel("User 40")
    group = groups.get(149)
    group:setLabel("User 41")
    group = groups.get(150)
    group:setLabel("User 42")
    group = groups.get(151)
    group:setLabel("User 43")
    group = groups.get(152)
    group:setLabel("User 44")
    group = groups.get(153)
    group:setLabel("User 45")
    group = groups.get(154)
    group:setLabel("User 46")
    group = groups.get(155)
    group:setLabel("User 47")
    group = groups.get(156)
    group:setLabel("User 48")    
end

function setPresetsAt49()
  presetOffset = 48 
  for i = 49,64
  do 
    control = controls.get(i-presetOffset)
    control:setName(userNames[i])
  end
  -- Set the preset tags
    group = groups.get(51)
    group:setLabel("User 49")
    group = groups.get(52)
    group:setLabel("User 50")
    group = groups.get(53)
    group:setLabel("User 51")
    group = groups.get(144)
    group:setLabel("User 52")
    group = groups.get(145)
    group:setLabel("User 53")
    group = groups.get(146)
    group:setLabel("User 54")
    group = groups.get(147)
    group:setLabel("User 55")
    group = groups.get(148)
    group:setLabel("User 56")
    group = groups.get(149)
    group:setLabel("User 57")
    group = groups.get(150)
    group:setLabel("User 58")
    group = groups.get(151)
    group:setLabel("User 59")
    group = groups.get(152)
    group:setLabel("User 60")
    group = groups.get(153)
    group:setLabel("User 61")
    group = groups.get(154)
    group:setLabel("User 62")
    group = groups.get(155)
    group:setLabel("User 63")
    group = groups.get(156)
    group:setLabel("User 64")  
end

function setPresetsAt65()
  presetOffset = 64 
  for i = 65,80
  do 
    control = controls.get(i-presetOffset)
    control:setName(userNames[i])
  end
  -- Set the preset tags
    group = groups.get(51)
    group:setLabel("User 65")
    group = groups.get(52)
    group:setLabel("User 66")
    group = groups.get(53)
    group:setLabel("User 67")
    group = groups.get(144)
    group:setLabel("User 68")
    group = groups.get(145)
    group:setLabel("User 69")
    group = groups.get(146)
    group:setLabel("User 70")
    group = groups.get(147)
    group:setLabel("User 71")
    group = groups.get(148)
    group:setLabel("User 72")
    group = groups.get(149)
    group:setLabel("User 73")
    group = groups.get(150)
    group:setLabel("User 74")
    group = groups.get(151)
    group:setLabel("User 75")
    group = groups.get(152)
    group:setLabel("User 76")
    group = groups.get(153)
    group:setLabel("User 77")
    group = groups.get(154)
    group:setLabel("User 78")
    group = groups.get(155)
    group:setLabel("User 79")
    group = groups.get(156)
    group:setLabel("User 80")  
end

function setPresetsAt81()
  presetOffset = 80
  for i = 81,96
  do 
    control = controls.get(i-presetOffset)
    control:setName(userNames[i])
  end
  -- Set the preset tags
    group = groups.get(51)
    group:setLabel("User 81")
    group = groups.get(52)
    group:setLabel("User 82")
    group = groups.get(53)
    group:setLabel("User 83")
    group = groups.get(144)
    group:setLabel("User 84")
    group = groups.get(145)
    group:setLabel("User 86")
    group = groups.get(146)
    group:setLabel("User 86")
    group = groups.get(147)
    group:setLabel("User 87")
    group = groups.get(148)
    group:setLabel("User 88")
    group = groups.get(149)
    group:setLabel("User 89")
    group = groups.get(150)
    group:setLabel("User 90")
    group = groups.get(151)
    group:setLabel("User 91")
    group = groups.get(152)
    group:setLabel("User 92")
    group = groups.get(153)
    group:setLabel("User 93")
    group = groups.get(154)
    group:setLabel("User 94")
    group = groups.get(155)
    group:setLabel("User 95")
    group = groups.get(156)
    group:setLabel("User 96")  
end

function setPresetsAt97()
  presetOffset = 96  
  for i = 97,112
  do 
    control = controls.get(i-presetOffset)
    control:setName(userNames[i])
  end
  -- Set the preset tags
    group = groups.get(51)
    group:setLabel("User 97")
    group = groups.get(52)
    group:setLabel("User 98")
    group = groups.get(53)
    group:setLabel("User 99")
    group = groups.get(144)
    group:setLabel("User 100")
    group = groups.get(145)
    group:setLabel("User 101")
    group = groups.get(146)
    group:setLabel("User 102")
    group = groups.get(147)
    group:setLabel("User 103")
    group = groups.get(148)
    group:setLabel("User 104")
    group = groups.get(149)
    group:setLabel("User 105")
    group = groups.get(150)
    group:setLabel("User 106")
    group = groups.get(151)
    group:setLabel("User 107")
    group = groups.get(152)
    group:setLabel("User 108")
    group = groups.get(153)
    group:setLabel("User 109")
    group = groups.get(154)
    group:setLabel("User 110")
    group = groups.get(155)
    group:setLabel("User 111")
    group = groups.get(156)
    group:setLabel("User 112")      
end
function setPresetsAt113()
  presetOffset = 112  
  for i = 113,128
  do 
    control = controls.get(i-presetOffset)
    control:setName(userNames[i])
  end
  -- Set the preset tags
    group = groups.get(51)
    group:setLabel("User 113")
    group = groups.get(52)
    group:setLabel("User 114")
    group = groups.get(53)
    group:setLabel("User 115")
    group = groups.get(144)
    group:setLabel("User 116")
    group = groups.get(145)
    group:setLabel("User 117")
    group = groups.get(146)
    group:setLabel("User 118")
    group = groups.get(147)
    group:setLabel("User 119")
    group = groups.get(148)
    group:setLabel("User 120")
    group = groups.get(149)
    group:setLabel("User 121")
    group = groups.get(150)
    group:setLabel("User 122")
    group = groups.get(151)
    group:setLabel("User 123")
    group = groups.get(152)
    group:setLabel("User 124")
    group = groups.get(153)
    group:setLabel("User 125")
    group = groups.get(154)
    group:setLabel("User 126")
    group = groups.get(155)
    group:setLabel("User 127")
    group = groups.get(156)
    group:setLabel("User 128")
end

function xposeMiddleC(valueObject, value)
    if (math.floor(value) == 0) then -- Handle weird case wheret his is getting called by page changes 
      return
    end
    local xAmt = 0
    local newMiddleC = valueObject:getMessage():getValue()
    --midi.sendControlChange(DEVICE_PORT, 16, 56, 20) -- Matrix Poke command 
    --midi.sendAfterTouchPoly(DEVICE_PORT, 16, 44, newMiddleC) -- Perform the Poke 
    -- print("Setting Middle C: "..newMiddleC)
    matrixPoke (44,newMiddleC)
    --print("newMiddleC = "..newMiddleC) 
    -- Change the transpose indicator
    control=controls.get(78)
    if (newMiddleC == 0) then
      return
    elseif (newMiddleC == 60) then
      control:setName("Transpose Off")
      control:setColor(WHITE)
    elseif (newMiddleC > 60) then
      xAmt = newMiddleC - 60
      control:setName("Up "..xAmt.." st")
      control:setColor(GREEN)
    else
      xAmt = 60 - newMiddleC
      control:setName("Down "..xAmt.." st")
      control:setColor(GREEN)    
    end
end
-- SOme transpose commands clash with sus, sos1 & sos2 - handle them separately
function xposeMiddleCx(valueObject, value)
    local xAmt = 0
    local newMiddleC = valueObject:getMessage():getValue()
    -- Handle cases whre param 78=69, 79=66 and 80=64
    if (newMiddleC == 78) then
      newMiddleC = 69
    elseif (newMiddleC == 79) then
      newMiddleC = 66
    elseif (newMiddleC == 80) then
      newMiddleC = 64
    end 
    matrixPoke (44,newMiddleC)
    --print("newMiddleC = "..newMiddleC) 
    -- Change the transpose indicator
    control=controls.get(78)
    if (newMiddleC == 0) then
      return
    elseif (newMiddleC == 60) then
      control:setName("Transpose Off")
      control:setColor(WHITE)
    elseif (newMiddleC > 60) then
      xAmt = newMiddleC - 60
      control:setName("Up "..xAmt.." st")
      control:setColor(GREEN)
    else
      xAmt = 60 - newMiddleC
      control:setName("Down "..xAmt.." st")
      control:setColor(GREEN)    
    end
end

function matrixPoke(pokeID, pokeVal)
    -- print ("POke: " .. pokeID .. " " .. pokeVal)
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
function setRecirc(valueObject, value)
    local recircVal = valueObject:getMessage():getValue()
    midi.sendControlChange(DEVICE_PORT, 16, 56, 20) 
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, 62 , recircVal) 
    -- midi.sendAfterTouchPoly(DEVICE_PORT, 16, recircVal , 62)
    -- midi.sendPitchBend(DEVICE_PORT, 16, (RECIRC_CODE*128+RecircVal)-8192)
    -- midi.sendControlChange(DEVICE_PORT, 16, 56, 20)
    -- midi.sendPitchBend(DEVICE_PORT, 16, (RecircVal*128+RECIRC_CODE)-8192)
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
--print("RecircEnabled = "..recircEnabled)
local control=controls.get(158)
     if (recircEnabled == 1) then 
         matrixPoke (15, 0) -- Enable Recirc = 0
         control:setName("Enabled")
         control:setColor(GREEN)
     elseif(recircEnabled == 0) then
         matrixPoke (15, 1) -- Disable Recirc = 1
         control:setName("Disabled")
         control:setColor(WHITE)         
     else 
         print ("Unexpected Recirc Enable/Disable Type")               
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

function set14w86(valueObject, value)
    local valueLsb = value >> 7
    local valueMsb = value & 0x7f
    local controlChangeLsb = valueObject:getMessage():getParameterNumber()

    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, 86, valueMsb)
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, controlChangeLsb, valueLsb)
 
end
function set14w97(valueObject, value)
    local valueMsb = value >> 7
    local valueLsb = value & 0x7f
    local controlChangeLsb = valueObject:getMessage():getParameterNumber()

    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, 97, valueMsb)
    midi.sendControlChange(DEVICE_PORT, DEVICE_CHANNEL, controlChangeLsb, valueLsb)
end
function setConvolutionIR1(valueObject, value) -- Convolution Poke = 
     local convolution1Type = valueObject:getMessage():getValue()
     --print ("Convolution IR 1 Type "..convolution1Type)
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
     --print ("Convolution IR 2 Type "..convolution1Type)
     if (convolution2Type == 0) then -- IR2 = 5
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
     --print ("Convolution IR 3 Type "..convolution1Type)
     if (convolution3Type == 0) then -- IR3 = 6
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
     --print ("Convolution IR 4 Type "..convolution1Type)
     if (convolution4Type == 0) then -- IR4 = 7
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
function setConvEPCtrl(valueObject, value) -- Conv poke - using conrol parameter for Conv operation to be generic
    local epvalue = math.floor(value)
    local ctrl = controls.get(127) 
    if (epvalue == 1) then
      ctrl:setName("EP On")
      ctrl:setColor(GREEN)
      convolutionPoke(29,1)
    elseif (epvalue == 0) then
      ctrl:setName("EP Off")
      ctrl:setColor(WHITE)      
      convolutionPoke(29,0)          
    else 
      print("Unknown EP value: "..epvalue)
    end
end

function getMacros()
  if (macrosLoaded == true) then
    macroInProgress = true
    --print ("getMacros - should not be called until pressed")
    midi.sendControlChange(DEVICE_PORT, 16, 109, 22) -- Send get Current Preset Msg to get Macro labels and control values
  else 
    print ("MacrosLoaded - called by init")
    macrosLoaded = true
  end
end

function muteControl(valueObject, value)
   local muteOn = valueObject:getMessage():getValue() -- Store the current preset position elected as user store 
   control = controls.get(230)

   if (muteOn == 0) then -- Mute off, restore pre-gain
      control:setName("Mute Off")
      control:setColor(WHITE)  
      -- print("Muteval ="..muteVal)
      midi.sendControlChange(DEVICE_PORT, 1, 26, muteVal) -- set pregain to last value
   else 
      control:setName("Mute On")
      control:setColor(GREEN)   
      midi.sendControlChange(DEVICE_PORT, 1, 26, 0)
      control = controls.get(48) -- save current pregain value
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()      
      muteVal = val
  end
end

function resetMute() -- On loading a preset reset Mute control to Off (pregain value will be read from preset)
  control = controls.get(230)
  control:setName("Mute Off")
  control:setColor(GREEN)
  local controlValue = control:getValue("value")
  local ctrlMsg = controlValue:getMessage()
  ctrlMsg:setValue(0)
end

function setSplitMode(valueObject, value)
      control = controls.get(188)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      matrixPoke(1, val) -- Set Split Mode
end

function setSplitPoint(valueObject, value)
      control = controls.get(236)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      matrixPoke(45, val) -- Set  SPlit point, C4 = 60
end

function setMonoMode(valueObject, value)
      control = controls.get(249)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      -- print("Mono Mode = "..val)      
      matrixPoke(46, val)
end
function setMonoInterval(valueObject, value)
      if (math.floor(value) < 0) then   
          return -- inits to -1 (check others)
      end
      control = controls.get(267)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      matrixPoke(48, val)
end
function setMonoSwitch(valueObject, value)
      control = controls.get(252)
      if (value == 0) then
        control:setName("Mono Off")
        control:setColor(WHITE)
      else
        control:setName("Mono On")
        control:setColor(GREEN)      
      end
      --print("Mono sw value = "..val..","..math.floor(value))
      midi.sendControlChange(DEVICE_PORT, 1, 9, math.floor(value))

end
function setOctRange(valueObject, value)
  control = controls.get(179)
  local controlValue = control:getValue("value")
  local ctrlMsg = controlValue:getMessage()
  local val = ctrlMsg:getValue()
  -- print("Octave Transpose = "..val)
  matrixPoke(54, val)       
end

function setOctSwMode(valueObject, value)
  control = controls.get(173)
  local controlValue = control:getValue("value")
  local ctrlMsg = controlValue:getMessage()
  local val = ctrlMsg:getValue()
  matrixPoke(7, val)  
end

function setRoundInit(valueObject, value)
  control = controls.get(209)
  -- local controlValue = control:getValue("value")
  -- local ctrlMsg = controlValue:getMessage()
  local val = math.floor (value)
  -- print("Round Initial = "..val)

  if (value == 0) then
    control:setName("Initial Off")
    control:setColor(WHITE)
  elseif (val == 127 or val == 1) then
    control:setName("Initial On")
    control:setColor(GREEN)
  else
    print("Unexpected Round Initial Control: "..val)
    return
  end
    midi.sendControlChange(DEVICE_PORT, 1, 28, value)     
end
-- Round Modes
function setRoundMode(valueObject, value) -- Round Mode
      control = controls.get(210)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      matrixPoke(10, val)
end
function setRoundEqual(valueObject, value) -- Round Equal
      control = controls.get(228)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      midi.sendControlChange(DEVICE_PORT, 1, 65, val)
end
function setDirection(valueObject, value) -- Normal or reverse fingerboard
      control = controls.get(253)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      -- print("Direction ="..val)
      if (val == 0) then
        control:setName("Normal")
        control:setColor(GREEN)
      elseif (val==1) then
        control:setName("Reverse")
        control:setColor(RED)      
      else
         print("Unexpected Direction")
         return
      end
      matrixPoke(9, val)
end
function setTuning(valueObject, value)
  control = controls.get(189)
  local tuning = valueObject:getMessage():getValue()
  if (tuning == 127) then -- can't set On&Off to zero for button so use sentinel
    tuning = 0
    control:setName("Equal Temp")
    control:setColor(GREEN)
  elseif (tuning == 0) then -- Ignore   
  elseif (tuning >= 60 and tuning < 72) then -- Just
     control:setName("JUST "..tuning-59)
     control:setColor(RED)
  elseif (tuning >=81 and tuning < 86) then -- Grid
     control:setName("Grid "..tuning)
     control:setColor(PURPLE)
  else 
        print ("Unrecognized tuning: "..tuning)
        return
  end
  --print("Tuning = "..tuning)
  midi.sendControlChange(DEVICE_PORT, 16, 51, tuning)       
end
function setNdiv(valueObject, value)
  control = controls.get(225)
  local controlValue = control:getValue("value")
  local ctrlMsg = controlValue:getMessage()
  local val = ctrlMsg:getValue()
  local ctrl = controls.get(189)
  --print("NDIV = "..val)
  if (val == 0) then
    ctrl:setName("Equal Temp")
    ctrl:setColor(GREEN)
  elseif (val > 0 and val < 72) then
    ctrl:setName("NDIV "..val)
    ctrl:setColor(BLUE) 
  end
  midi.sendControlChange(DEVICE_PORT, 16, 51, val)      
end
function replaceSurface(valueObject, value) -- Round Mode
      control = controls.get(167)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      --print("replace Surface ="..val)
      if (val == 0) then
         control:setName("Replace")
         control:setColor(GREEN)
      elseif (val==1) then
         control:setName("Preserve")
         control:setColor(RED)      
      else
         print("Unexpected Replace/Preserve Surface")
         return
      end
      if (repSurfacePushed == false) then
        -- print("Surface Replace Init")        
        repSurfacePushed = true
        return
      end      
      if (repSurfacePushed) then
        -- print("Writing flash 1")
        -- matrixPoke(56, val)      
        -- midi.sendControlChange(DEVICE_PORT, 16, 109, 8) -- Store to flash      
      end
      repSurfacePushed = true 
end
function replacePedals(valueObject, value) -- Round Mode
      control = controls.get(168)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      --print("replace Pedals ="..val)
      if (val == 0) then
         control:setName("Replace")
         control:setColor(GREEN)
      elseif (val==1) then
         control:setName("Preserve")
         control:setColor(RED)      
      else
         print("Unexpected Replace/Preserve Pedals")
         return
      end
      if (repPedalsPushed == false) then
        -- print("Pedals Replace Init")        
        repPedalsPushed = true
        return
      end            
 
      if (repPedalsPushed) then
        -- print("Writing flash 2")
        -- matrixPoke(57, val)              
        -- midi.sendControlChange(DEVICE_PORT, 16, 109, 8) -- Store to flash     
      end
      repPedalsPushed = true
end
function replaceMidi(valueObject, value) -- Round Mode
      control = controls.get(169)
      local controlValue = control:getValue("value")
      local ctrlMsg = controlValue:getMessage()
      local val = ctrlMsg:getValue()
      --print("replace Midi ="..val)
      if (val == 0) then
         control:setName("Replace")
         control:setColor(GREEN)
      elseif (val==1) then
         control:setName("Preserve")
         control:setColor(RED)      
      else
         print("Unexpected Repalce/Preserve Midi")
         return
      end
      if (repMidiPushed == false) then
        --print("Midi Replace Init")        
        repMidiPushed = true
        return
      end            
      if (repMidiPushed) then
        --print("Writing flash 3")
        -- matrixPoke(58, val)        
        -- midi.sendControlChange(DEVICE_PORT, 16, 109, 8) -- Store to flash      
      end     
end
function compOrTanh(valueObject, value)
  local ctrl = controls.get(163)
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
 if (which == 0) then -- COlor for Compressor
   local grp = groups.get(131)
   grp:setVisible(true)
   grp = groups.get(248)
   grp:setVisible(false)
   local ctrl = controls.get(133)
   ctrl:setVisible(true)       
   ctrl = controls.get(134)
   ctrl:setVisible(true)   
   ctrl = controls.get(135)
   ctrl:setVisible(true)
   ctrl = controls.get(136)
   ctrl:setVisible(true)     
   ctrl = controls.get(257)
   ctrl:setVisible(false)
   ctrl = controls.get(249)
   ctrl:setVisible(false)
   ctrl = controls.get(251)
   ctrl:setVisible(false)
 else -- color for Tanh
   local grp = groups.get(131)
   grp:setVisible(false)
   grp = groups.get(248)
   grp:setVisible(true)
   local ctrl = controls.get(133)
   ctrl:setVisible(false)   
   ctrl = controls.get(134)
   ctrl:setVisible(false)
   ctrl = controls.get(135)
   ctrl:setVisible(false)
   ctrl = controls.get(136)
   ctrl:setVisible(false)    
   ctrl = controls.get(257)
   ctrl:setVisible(true)    
   ctrl = controls.get(249)
   ctrl:setVisible(true)   
   ctrl = controls.get(251)
   ctrl:setVisible(true) 
 end
end

-- Store the current Preset category selected
function selectPresetCategory(valueObject, value)
    if not haveSystemPresetsBeenUpdated then
        return
    end
    -- Reset Preset index to beginning
   curSystemPreset = 0
   local ctrl = controls.get(273) -- Preset index
   local controlValue = ctrl:getValue("value")
   local ctrlMsg = controlValue:getMessage()
   ctrlMsg:setValue(0) -- New Category then reset preset Index control to default
   ctrl = controls.get(46) -- Get Category control
   controlValue = ctrl:getValue("value")
   ctrlMsg = controlValue:getMessage()
   local val = ctrlMsg:getValue() -- Get the category value (not index)
   curCategory = val+1
  if (curCategory == CAT_OTHER1) then
     curCC32 = 1
  else
     curCC32 = 0
  end
end

-- Get the preset name and index based on Category set
function selectSystemPreset(valueObject, value)
    if not haveSystemPresetsBeenUpdated then
        return
    end
   curSystemPreset = getMaxPresetIndex(math.floor(value))
   local ctrl = controls.get(278)
   if (curSystemPreset == 0) then
     ctrl:setName("SELECT PRESET")   
   elseif (curPresetName ~= "") then
     ctrl:setName(curPresetName)
   end
end

-- To use one control for preset index select the index can't exceed the max
-- number of presets in a given category. This will change from instrument
-- to instrument (so probably best to create a separate version for each instrument)
-- Or see if this can be dynamically read for a later version
-- DOES THE ABOVE COMMENT NEED TO BE MODIFIED OR REMOVED?  SOR
-- Currently this should work for the Continuum and the EganMatrix module.
-- Amended by SOR for getting system presets.
function getMaxPresetIndex (pIndex) -- cap inex at max range for each category
   local ctrl = controls.get(273)
   local controlValue = ctrl:getValue("value")
   local ctrlMsg = controlValue:getMessage()
    local systemPresets = systemPresetCategories[curCategory]
    local systemPresetCount = #systemPresets
    if (pIndex > systemPresetCount) then
        ctrlMsg:setValue(systemPresetCount)
        return pIndex - 1
    end
    curPresetName = systemPresets[pIndex]
    return pIndex
  --if (curCategory == CAT_STRINGS) then -- Strings
  --   -- print ("pIndex: "..pIndex)
  --   if (pIndex > 88) then
  --     ctrlMsg:setValue(88)     
  --     return pIndex - 1        
  --   end
  --   curPresetName = strings[pIndex]   
  --elseif (curCategory == CAT_WINDS) then -- Winds
  --   if (pIndex > 45) then
  --     ctrlMsg:setValue(45)      
  --     return pIndex - 1
  --   end  
  --   curPresetName = winds[pIndex]     
  --elseif (curCategory == CAT_VOCAL) then -- Vocal
  --   if (pIndex > 31) then
  --     ctrlMsg:setValue(31)      
  --     return pIndex - 1
  --   end  
  --   curPresetName = vocal[pIndex]      
  --elseif (curCategory == CAT_KEYBOARD) then -- Keyboard
  --   if (pIndex > 33) then
  --     ctrlMsg:setValue(33)      
  --     return pIndex - 1
  --   end
  --   curPresetName = keyboard[pIndex]       
  --elseif (curCategory == CAT_CLASSIC) then -- Classic
  --   if (pIndex > 72) then
  --     ctrlMsg:setValue(72)      
  --     return pIndex - 1
  --   end
  --   curPresetName = classic[pIndex]     
  --elseif (curCategory == CAT_OTHER) then -- Other
  --   curPresetName = other[pIndex]  -- Other contains > 128 - see other 2 for second half
  --elseif (curCategory == CAT_PERCUSSION) then -- Percussion
  --   if (pIndex > 12) then
  --     ctrlMsg:setValue(12)      
  --     return pIndex - 1
  --   end
  --   curPresetName = percussion[pIndex]         
  --elseif (curCategory == CAT_TUNEDPERC) then -- Tuned Percussion
  --   if (pIndex > 47) then
  --     ctrlMsg:setValue(47)      
  --     return pIndex - 1
  --   end
  --   curPresetName = tunedPerc[pIndex]         
  --elseif (curCategory == CAT_PROCESSOR) then -- Processor
  --   if (pIndex > 22) then
  --     ctrlMsg:setValue(22)      
  --     return pIndex - 1
  --   end
  --   curPresetName = processor[pIndex]    
  --elseif (curCategory == CAT_DRONE) then -- Drone
  --   if (pIndex > 19) then
  --     ctrlMsg:setValue(19) 
  --     return pIndex - 1
  --   end 
  --   curPresetName = drones[pIndex]        
  --elseif (curCategory == CAT_MIDI) then -- Midi
  --   if (pIndex >16) then
  --     ctrlMsg:setValue(16)      
  --     return pIndex - 1
  --   end
  --   curPresetName = midiVals[pIndex]    
  --elseif (curCategory == CAT_CVC) then -- CVC
  --   if (pIndex > 15) then
  --     ctrlMsg:setValue(15)      
  --     return pIndex - 1
  --   end
  --   curPresetName = cvc[pIndex]         
  --elseif (curCategory == CAT_UTILITY) then -- Utility
  --   if (pIndex > 43) then
  --     ctrlMsg:setValue(43)      
  --     return pIndex - 1
  --   end  
  --   curPresetName = utility[pIndex]       
  --elseif (curCategory == CAT_OTHER1) then -- Other1 (150 presets in Other 150-128 = 22 cor CC32=1)
  --   if (pIndex > 27) then
  --     ctrlMsg:setValue(27)      
  --     return pIndex - 1
  --   end
  --   curPresetName = other1[pIndex]                      
  --end
  --return pIndex 
end

-- Load the System Preset
function loadSystemPreset(valueObject, value)
  -- print("LoadSystemPreset Called")
   local tmpCategory = curCategory
   if (sendSysPresetInit == false) then
     sendSysPresetInit = true
     return
   end
   if (curSystemPreset == 0) then
      info.setText("Select System Preset")
      return
   elseif (curCategory == 0) then
      info.setText("Select Category")
      return   
   else
       info.setText("")
   end
   if (curCategory == CAT_OTHER1) then
     tmpCategory = CAT_OTHER -- Really only one Other category but presetned to the user as 2
   end
   midi.sendControlChange(DEVICE_PORT, 16, 0, tmpCategory) -- Send Category
   if (curCC32 > 0) then
      midi.sendControlChange(DEVICE_PORT, 16, 32, curCC32) -- Send CC32 if > 128 Presets in category  
   end
   midi.sendProgramChange(DEVICE_PORT, 16, curSystemPreset-1) -- Send Program Change
   local ctrl = controls.get(50) 
   ctrl:setName(curPresetName)
   -- Fill in macros
   macroInProgress = true
   clearInfo()
   clearMacros()
   resetMute()
   midi.sendControlChange(DEVICE_PORT, 16, 109, 16) -- Send get Current Preset Msg to get Macro labels and control values 
end

-- Added by SOR for getting system presets.
function getSystemPresets()
    print("getSystemPresets")
    -- Request system preset names (sysToMidi).
    midi.sendControlChange(DEVICE_PORT, 16, 109, 39)
end

-- Added by SOR for getting system presets.
function onEndOfSystemPresetList()
    haveSystemPresetsBeenUpdated = true
    replaceLongSystemPresetNamesWithShortNames()
    -- Replace the "Getting presets..." notification 
    -- on the status bar with the version info.
    info.setText(versionText)
    local categoryCount = #systemPresetCategories
    print("Counting system presets in "..categoryCount.." categories.")
    for category = 1, categoryCount do
        local presetNames = systemPresetCategories[category]
        local presetCount = #presetNames
        print("Category "..category.." has "..presetCount.." system presets.")
    end
    selectPresetCategory(nil, nil)
    selectSystemPreset()
end

-- Added by SOR for getting system presets.
function onSystemPresetReceived()
    -- The system preset's two-letter category code has been received.
    -- It needs to be parsed from the context data that has been appended to curName.
    -- The context data looks like "C=CC", usually followed by filter codes,
    -- where CC is the category code.  We currently don't use the filter codes.
    local categoryCode = string.sub(receivedSystemPresetContext, 3, 4)
    if not categoryCode then
        print("onSystemPresetContextReceived: Cannot find category for "
                ..receivedSystemPresetName.." in ".. receivedSystemPresetContext)
        return
    end
    local categoryNo = categoryNos[categoryCode]
    if not categoryNo then
        print("onSystemPresetContextReceived: Cannot find "..categoryCode..
                " category number for "..receivedSystemPresetName)
        return
    end
    -- Now that we know the new system preset's name and category number,
    -- we can add the name to the category's system preset table.
    local categoryPresetCount = #systemPresetCategories[categoryNo]
    if categoryNo == CAT_OTHER and categoryPresetCount == 128 then
        categoryNo = CAT_OTHER1
        categoryPresetCount = #systemPresetCategories[categoryNo]
    end 
    local newPresetNo = categoryPresetCount + 1
    systemPresetCategories[categoryNo][newPresetNo] = receivedSystemPresetName 
end

-- Added by SOR for getting system presets.
-- To avoid truncation when a system preset name is shown on the E1,
-- replace any names that are too long with short names.
function replaceLongSystemPresetNamesWithShortNames()
    local categoryCount = #systemPresetCategories
    for category = 1, categoryCount do
        local presets = systemPresetCategories[category]
        local presetCount = #presets
        for presetNo = 1, presetCount do
            local presetName = presets[presetNo]
            local nameLength = #presetName
            if (nameLength > MAX_NAME_LENGTH) then
                local shortName = shortPresetNames[presetName]
                if shortName then
                    systemPresetCategories[category][presetNo] = shortName
                else
                    -- Keep this print. We will need it for identifying new
                    -- long names introduced in future firmware versions. SOR
                    print("A short name has not been specified for system preset "
                            ..presetName)
                end
            end
        end
    end
end

-- Added by SOR for getting system presets.
-- The text streams provide characters in pairs,
-- So if the string received has an odd number of characters,
-- there will be an null character (ASCII 0) at the end to make it even.
-- For system preset names,
-- the null character really messes things up if we don't remove it.
-- And it is removed for system preset contexts too, just for tidiness.
-- If there's already code to remove the null character for user preset names,
-- I've not spotted it. Maybe it does not matter in that case.
function trimTrailingNullChar(text)
    local textLength = string.len(text)
    local lastCharNo = string.byte(text, textLength)
    if lastCharNo == 0 then
        local result = string.sub(text,1, textLength - 1)
        return result
    end
    return text
end

-- Set Pedal 1 Assignment
function assignPedal1 (valueObject, value)
    if (pedal1Init == false) then
        pedal1Init = true
        return
    end
    local ctrl = controls.get(143)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    local ped1Val = ctrlMsg:getValue()
    -- print ("Pedal1 val: "..ped1Val)
    matrixPoke(52, ped1Val) -- set assignment
end

-- Set Pedal 2 Assignment
function assignPedal2 (valueObject, value)
   if (pedal2Init == false) then
      pedal2Init = true
      return
   end
   local ctrl = controls.get(164)
   local controlValue = ctrl:getValue("value")
   local ctrlMsg = controlValue:getMessage()
   local ped2Val = ctrlMsg:getValue()
   matrixPoke(53, ped2Val) -- set assignment
end
function processConvolution()
--[[ Process Convolution stream and populate the convolution parameters
    ch16 pPres=19 22  	(Pre-Convolution Index, Pre-Convolution Level)
    ch16 pPres=34 15	(Post-Convolution Index, Post-Convolution Level)
    ch16 pPres=6 7 	(C1 IR type, C2 IR type)
    ch16 pPres=8 6 	(C3 IR type, C4 IR type)
    ch16 pPres=127 127 	(C1 Length, C2 Length)
    ch16 pPres=127 127 	(C3 Length, C4 Length)
    ch16 pPres=64 64 	(C1 Shift/Tuning, C2 Shift/Tuning)
    ch16 pPres=64 64 	(C3 Shift/Tuning, C4 Shift/Tuning)
    ch16 pPres=0 64 	(C1 Width, C2 Width)
    ch16 pPres=64 64 	(C3 Width, C4 Width)
    ch16 pPres=127 127 	(C1 Stereo Atten Left, C2 Stereo Atten Left)
    ch16 pPres=127 127 	(C3 Stereo Atten Left, C3 Stereo Atten Left)
    ch16 pPres=127 127 	(C1 Stereo Atten Right, C2 Stereo Right)
    ch16 pPres=127 127	(C3 Stereo Atten Right, C3 Stereo Right)
    ch16 pPres=0 0 	(Enhanced Phase, 0 padding)
    Final convString will be: 0|0|0|0|0|7|8|6|15|127|127|127|12|64|64|64|64|64|64|64|127|127|127|127|127|127|127|127|0|0|
--]]
--  local test = true
--  if (test == true) then
--    return
--  end
  -- print ("Convolution Stream Processed:"..convString)
  -- string.strsub (s, i, [j])
  local tmpStr = convString
  local ix = 1
  local j = 1
  local pi = 1
  local convParams = {"0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", 
                    "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"}
  convString = ""
  local strLen = string.len(tmpStr)
  while ix < strLen
  do
     if (tmpStr:sub(ix,ix) =="|") then -- parse the individual parametgers into an array
       convParams[pi] = tmpStr:sub(j,ix-1)
       --print("C="..convParams[pi]) -- debugit
       pi = pi + 1
       j = ix + 1 
     end
       ix = ix + 1 
  end
 -- for i= 1,28 
 -- do
 --  print("Conv "..i.."="..convParams[i]) -- debugit
 -- end
  -- Update the Convolution Controls with the stream data read

  --[[ Programmed conv really handled by macros, etc.
    local ctrl = controls.get(105) -- Pre Mix
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[1]) 
         
         ctrl = controls.get(106) -- Pre index
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[2])
         
         ctrl = controls.get(109) -- Post Mix
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[3])
         
         ctrl = controls.get(110) -- Post Index
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[4])
--]]       
    -- IRs
         local ctrl = controls.get(93) -- IR1 Type
         local controlValue = ctrl:getValue("value")
         local ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[5])
         
         ctrl = controls.get(94) -- IR2 Type
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[6])
         
         ctrl = controls.get(95) -- IR3 Type
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[7])
         
         ctrl = controls.get(96) -- IR4 Type
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[8])
 
    -- Length
         ctrl = controls.get(97) -- Length C1
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[9])
         ctrl = controls.get(98) -- Length C2
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[10])
         ctrl = controls.get(99) -- Length C3
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[11])
         ctrl = controls.get(100) -- Length C4
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[12]) 
    
    -- Tuning
         ctrl = controls.get(101) -- Tuning C1
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[13])
         ctrl = controls.get(102) -- Tuning C2
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[14])
         ctrl = controls.get(103) -- Tuning C3
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[15])
         ctrl = controls.get(104) -- Tuning C4
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[16])
    
    -- Width
         ctrl = controls.get(111) -- Width C1
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[17])
         ctrl = controls.get(112) -- Width C2
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[18])
         ctrl = controls.get(113) -- Width C3
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[19])
         ctrl = controls.get(114) -- Width C4
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[20])            

    -- Stereo Left Atten
         ctrl = controls.get(115) -- Stereo L C1
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[21])
         --print("L Atten: ".. convParams[21])
         ctrl = controls.get(116) -- Stereo L C2
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[22])
         --print("L Atten: ".. convParams[22])         
         ctrl = controls.get(117) -- Stereo L C3
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[23])
         --print("L Atten: ".. convParams[23])         
         ctrl = controls.get(118) -- Stereo L C4
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[24])
         --print("L Atten: ".. convParams[24])         

    -- Stereo Right Atten
         ctrl = controls.get(119) -- Stereo R C1
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[25])
         ctrl = controls.get(120) -- Stereo R C2
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[26])
         ctrl = controls.get(121) -- Stereo R C3
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()

         ctrlMsg:setValue(convParams[27])
         ctrl = controls.get(122) -- Stereo R C4
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[28])
  --local test = true
  --if (test == true) then
  --  return
  --end         
    -- Enhanced Phase
         ctrl = controls.get(127) -- EP
         controlValue = ctrl:getValue("value")
         ctrlMsg = controlValue:getMessage()
         ctrlMsg:setValue(convParams[29])
         local epval = math.floor(convParams[29])
        if (epval == 1) then
           ctrl:setName("EP On")
        elseif (epval == 0) then
           ctrl:setName("EP Off")
        else 
           print("EP - Unknown value: "..epval)
        end                 
end

function setConvLength1 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(8, val)
end
function setConvLength2 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(9, val)
end
function setConvLength3 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(10, val)
end
function setConvLength4 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(11, val)
end
function setConvTune1 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(12, val)
end
function setConvTune2 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(13, val)
end
function setConvTune3 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(14, val)
end
function setConvTune4 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(15, val)
end
function setConvWidth1 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(16, val)
end
function setConvWidth2 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(17, val)
end
function setConvWidth3 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(18, val)
end
function setConvWidth4 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(19, val)
end
function setConvLeft1 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(20, val)
end
function setConvLeft2 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(21, val)
end
function setConvLeft3 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(22, val)
end
function setConvLeft4 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(23, val)
end
function setConvRight1 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(24, val)
end
function setConvRight2 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(25, val)
end
function setConvRight3 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(26, val)
end
function setConvRight4 (valueObject, value)
   local val = math.floor(value)
   convolutionPoke(27, val)
end

function format0to1(valueObject, value)
   -- print("Formatter called")
   local val = value/128
     val = val + 0.004 -- make it scale to 1.0 max
    return(string.format("%.2f", val))
 end

function noop (valueObject, value)
end
-- Functions to preserve macro names
--[[
function preserve_i (valueObject, value) 
  if (math.floor(value) == 0) then
    local ctrl = controls.get(25)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrl:setName(macro_i_name)
    if (macro_i_name ~= "") then
       ctrlMsg:setValue(macro_i_val)
    else
       ctrlMsg:setValue(0)    
    end   
  end
end

function preserve_ii (valueObject, value)
  if (math.floor(value) == 0) then
    local ctrl = controls.get(26)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrl:setName(macro_ii_name)
    if (macro_ii_name ~= "") then
       ctrlMsg:setValue(macro_i_val)
    else
       ctrlMsg:setValue(0)    
    end   
  end
end
function preserve_iii (valueObject, value)
  if (math.floor(value) == 0) then
    local ctrl = controls.get(27)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrl:setName(macro_iii_name)
    if (macro_iii_name ~= "") then
       ctrlMsg:setValue(macro_i_val)
    else
       ctrlMsg:setValue(0)    
    end    
  end
end
function preserve_iv (valueObject, value)
  if (math.floor(value) == 0) then
    local ctrl = controls.get(28)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrl:setName(macro_iv_name)
    if (macro_iv_name ~= "") then
       ctrlMsg:setValue(macro_i_val)
    else
       ctrlMsg:setValue(0)    
    end   
  end
end
function preserve_v (valueObject, value)
  if (math.floor(value) == 0) then
    local ctrl = controls.get(29)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrl:setName(macro_v_name)
    if (macro_v_name ~= "") then
       ctrlMsg:setValue(macro_i_val)
     else
       ctrlMsg:setValue(0)    
    end     
  end
end
function preserve_vi (valueObject, value)
  if (math.floor(value) == 0) then
    local ctrl = controls.get(30)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrl:setName(macro_vi_name)    
    if (macro_vi_name ~= "") then
       ctrlMsg:setValue(macro_i_val)
    else
       ctrlMsg:setValue(0)    
    end
  end
end
function initMacros()
  macro_i_name = ""
  macro_i_val = 0
  macro_ii_name = ""
  macro_ii_val = 0
  macro_iii_name = ""
  macro_iii_val = 0
  macro_iv_name = ""
  macro_iv_val = 0
  macro_v_name = ""
  macro_v_val = 0        
  macro_vi_name = ""
  macro_vi_val = 0
end
--]]
--[[
function testEQ (valueObject, value)
 local v = math.floor(value)
 print("Value="..value)
 --midi.sendControlChange(DEVICE_PORT, 1, 83, tmpCategory) 
 --midi.sendControlChange(DEVICE_PORT, 1, 84, tmpCategory) 
end
]]
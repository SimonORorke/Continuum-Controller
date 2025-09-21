-- Check if E1 model and firmware requirements are met.
-- The firmware version is required for persist() and recall().
-- Assert will terminate the script on a failed check. SOR
assert(
    controller.isRequired(MODEL_MK2, "4.0.0"),
    "Electra One firmware version 4.0.0 or higher is required."
)
local DEVICE_PORT = PORT_1
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
local GETTING_PRESETS = "Getting presets..." -- SOR
local E1_PRESET_VERSION = "1.1" -- SOR
-- Macro control numbers SOR
local MACRO_I = 25
local MACRO_II = 26
local MACRO_III = 27
local MACRO_IV = 28
local MACRO_V = 29
local MACRO_VI = 30
-- Names longer than this will be truncated when shown on controls. SOR
local MAX_NAME_LENGTH = 14

-- Global Initialization flags
local storeInitialized = false -- Don't call certain things on Electra One startup procedure
local repPedalsPushed = false
local repMidiPushed = false
local sendSysPresetInit = false
local pedal1Init = false
local pedal2Init = false

-- Other Globals
local userNameProcessing = false
local nameInProgress = false
local thumbInProgress = false
local convInProgress = false
local macrosLoaded = false
local userNameIndex = 0
local convString = ""
local presetOffset = 0 -- Offset to change user preset on Continuum as only 16 are shown, need to track bank 
local presetPosSelect = 0
local muteVal = 60 -- Default pre-gain (but will be set from reading presets)
local matrixStream = false
local lowVersion = 8.0 -- Default to 10.35
local highVersion = 12.0 -- Default to 10.35
-- Dummies to reserve some memory up front
local userNames = {"U1","U2","U3","U4","U5","U6","U7","U8","U9","U10","U11","U12","U13","U14","U15","U16",
             "U17", "U18", "U19", "U20", "U21", "U22", "U23", "U24", "U25", "U26", "U27", "U28", "U29", "U30", "U31","U32",
             "U33", "U34", "U35", "U36", "U37", "U38", "U39", "U40", "U41", "U42", "U43", "U44", "U45", "U46", "U47","U48",
             "U49", "U50", "U51", "U52", "U53", "U54", "U55", "U56", "U57", "U58", "U59", "U60", "U61", "U62", "U63","U64",
             "U65", "U66", "U67", "U68", "U69", "U70", "U71", "U72", "U73", "U74", "U75", "U76", "U77", "U78", "U79","U80",
             "U81", "U82", "U83", "U84", "U85", "U86", "U87", "U88", "U89", "U90", "U91", "U92", "U93", "U94", "U95","U96",
             "U97", "U98", "U99", "U100", "U101", "U102", "U103", "U104",
             "U105", "U106", "U107", "U108", "U109", "U110", "U111","U112",
             "U113", "U114", "U115", "U116", "U117", "U118", "U119", "120",
             "U121", "U122", "U123", "U124", "U125", "U126", "U127","U128"}

-- Added by SOR
-- Macro names/category/filters/author data 
-- that we can get from the Control Text context stream 
-- when data for the loaded preset has been requested. 
local controlText = ""
local currentPresetNameBuffer = ""
local firmwareVersion
local hasFirmwareVersionAlreadyBeenReceived = false
local hasJustLoaded = false
local haveSystemPresetsBeenReceived = false
local isAccumulatingControlText = false
local isAccumulatingCurrentPresetName = false
local isAccumulatingSystemPresetFilters = false
local isAccumulatingSystemPresetName = false
local isGettingCurrentPresetData = false
local isGettingSystemPresets = false
local isInitializing = true
local isSystemPresetsUpdateRequired = false
local receivedSystemPresetFilters = ""
local receivedSystemPresetName = ""
local systemPresetFiltersBuffer = ""
local systemPresetNameBuffer = ""
local userPresetNameBuffer = ""
local versionText = ""

-- Tables

-- For selecting and loading a system preset.
local currentSystemPreset = {} -- SOR
currentSystemPreset.category = 1
currentSystemPreset.bankLsb = 0 -- Can be > 0 if more than 128 presets in a category.
currentSystemPreset.presetNo = 0 -- 0 if none selected.
currentSystemPreset.name = ""

-- An enumeration (enum) of preset load states.
local presetLoadState = {} -- SOR
-- The preset was already loaded on the instrument when the E1 preset was loaded.
presetLoadState.alreadyLoaded = 1
presetLoadState.loading = 2 -- The preset is being loaded.
presetLoadState.loaded = 3 -- The preset has been loaded by this E1 preset.

-- Parameters used to load a preset.
local currentPreset = {} -- SOR
currentPreset.bankMsb = 0 -- 0 for user preset, otherwise category number.
currentPreset.bankLsb = 0 -- Can be > 0 if more than 128 presets in a category.
currentPreset.programNo = 0 -- 0-based index within bank.
currentPreset.loadState = presetLoadState.alreadyLoaded
-- Needs to be updated when bankMsb changes.
-- Cannot be relied on if loadState = presetLoadState.alreadyLoaded.
currentPreset.IsUserPreset = false

local macroControls = {} -- SOR
for controlNo = MACRO_I, MACRO_VI do
    macroControls[controlNo] = controls.get(controlNo)
end

-- A dictionary for looking up the macro control number 
-- corresponding to the macro id provided by the instrument.
local macroControlNos = {} -- SOR
macroControlNos["i"] = MACRO_I
macroControlNos["ii"] = MACRO_II
macroControlNos["iii"] = MACRO_III
macroControlNos["iv"] = MACRO_IV
macroControlNos["v"] = MACRO_V
macroControlNos["vi"] = MACRO_VI

-- Added by SOR: Get system presets.
local persistableData = {}
-- Do initial recall
print("Recalling persistableData")
recall(persistableData)
-- Uncomment any of these to force system presets to be got from the instrument.
--persistableData.isSaved = false
--persistableData.firmwareVersion = "9.0"
--persistableData.systemPresetCategories = {}
if not persistableData.isSaved then
    --print("persistableData not available")
    -- Not strictly necessary,
    --  provided isSaved is always checked before accessing these items.
    persistableData.firmwareVersion = ""
    persistableData.systemPresetCategories = {}
else
    --print("persistableData.firmwareVersion = "..persistableData.firmwareVersion)
end

-- System presets grouped by category. SOR
local systemPresetCategories = {}
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

-- Test getting just CCs
function midi.onControlChange(midiInput, channel, controllerNumber, value)
    local chan = math.floor (channel)
    local cc = math.floor (controllerNumber)
    local val = math.floor (value)

    if (chan == 16 and cc == 102) then -- Firmware High Address
        highVersion = value
        return -- SOR
    end
    if (chan == 16 and cc == 103) then -- Firmware Low Address
        lowVersion = value
        -- Amended by SOR: Get system presets.
        if not hasFirmwareVersionAlreadyBeenReceived then
            hasFirmwareVersionAlreadyBeenReceived = true
            onFirmwareVersionReceived()
        end
        return
    end
    if (chan == 16 and cc == 71) then -- Polyphony
        if (val < 16) then
            setControlValue(183, val) -- SOR
        else
            --print("Polyphony > 15: "..val)
        end
        return -- SOR
    end
    if (chan == 16 and cc == 72) then -- DSP Polyphony
        setControlValue(234, val) -- SOR
        return -- SOR
    end
    if (chan == 16 and cc == 73) then -- CVC Polyphony
        setControlValue(172, val) -- SOR
        return -- SOR
    end

    -- End Read Only Controls
    if (chan == 1 and cc == 12) then -- Set i
        setControlValue(MACRO_I, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 13) then -- Set ii
        setControlValue(MACRO_II, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 14) then -- Set iii
        setControlValue(MACRO_III, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 15) then -- Set iv
        setControlValue(MACRO_IV, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 16) then -- Set v
        setControlValue(MACRO_V, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 17) then -- Set vi
        setControlValue(MACRO_VI, val) -- SOR
        -- Set all macro names here as this will always be the last macro output SOR
        setMacroNames()
        return -- SOR
    end
    -- Gain & Attenuation Settings
    if (chan == 1 and cc == 26) then -- Pre-Gain
        setControlValue(48, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 18) then -- Post-Gain
        setControlValue(45, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 27) then -- Attenuation
        setControlValue(244, val) -- SOR
        return -- SOR
    end
    -- Recirculator settings
    if (chan == 1 and cc == 24) then -- Mix
        setControlValue(86, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 23) then -- R4
        setControlValue(87, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 22) then -- R3
        setControlValue(88, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 21) then -- R2
        setControlValue(89, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 20) then -- R1
        setControlValue(90, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 95) then -- R5
        setControlValue(91, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 96) then -- R6
        setControlValue(92, val) -- SOR
        return -- SOR
    end
    -- EQ
    if (chan == 1 and cc == 85) then -- Mix
        setControlValue(137, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 84) then -- Frequency
        setControlValue(138, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 83) then -- Tilt
        setControlValue(139, val) -- SOR
        return -- SOR
    end
    -- Compressor
    if (chan == 1 and cc == 93) then -- Tilt
        setControlValue(133, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 92) then -- Ratio
        setControlValue(134, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 91) then -- Attack
        setControlValue(135, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 90) then -- Threshold
        setControlValue(136, val) -- SOR
        return -- SOR
    end
    -- Set Sus, Sos1, Sos2
    -- Amended by SOR: Control value updates.
    if (chan == 1 and cc == 64) then --Sus
        -- But the firmware does not save this,
        -- so it will always be 0 (off) initially.
        --print("Initializing Sus to "..val)
        setControlValue(260, val)
        return
    end
    -- Amended by SOR: Control value updates.
    if (chan == 1 and cc == 66) then -- Sos1
        -- But the firmware does not save this,
        -- so it will always be 0 (off) initially.
        --print("Initializing Sos1 to "..val)
        setControlValue(261, val)
        return
    end
    -- Amended by SOR: Control value updates.
    if (chan == 1 and cc == 69) then -- Sos2
        -- But the firmware does not save this,
        -- so it will always be 0 (off) initially.
        --print("Initializing Sos2 to "..val)
        setControlValue(262, val)
        return
    end
    -- Audio Input
    if (chan == 1 and cc == 19) then -- Audio Input Level
        setControlValue(237, val) -- SOR
        return -- SOR
    end
    -- Ped1
    if (chan == 1 and cc == 76) then -- Ped 1 Min Range
        --print("Initializing Pedal 1 Min to "..val)
        setControlValue(175, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 77) then -- Ped 1 Max Range
        --print("Initializing Pedal 1 Max to "..val)
        setControlValue(176, val) -- SOR
        return -- SOR
    end
    -- Ped2
    if (chan == 1 and cc == 78) then -- Ped 2 Min Range
        --print("Initializing Pedal 2 Min to "..val)
        setControlValue(177, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 79) then -- Ped 2 Max Range
        --print("Initializing Pedal 2 Max to "..val)
        setControlValue(178, val) -- SOR
        return -- SOR
    end
    -- Fine Tune
    if (chan == 1 and cc == 10) then -- Fine Tune +/- 60 cents
        setControlValue(227, val) -- SOR
        return -- SOR
    end
    -- Rounding
    if (chan == 1 and cc == 25) then -- Round Rate
        setControlValue(213, val) -- SOR
        return -- SOR
    end
    if (chan == 1 and cc == 28) then -- Round Initial
        local ctrl = controls.get(209)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        --print("Round Initial ="..val)
        if (val == 0) then
            ctrl:setName("Initial Off")
            ctrl:setColor(WHITE)
        elseif (val == 127 or val == 1) then
            ctrl:setName("Initial On")
            ctrl:setColor(GREEN)
        else
            --print("Unexpected Round Initial Read")
        end
        ctrlMsg:setValue(val)
        return -- SOR
    end

    -- Mono Switch
    if (chan == 1 and cc == 9) then -- Handle Mono Switch Button
        local ctrl = controls.get(252)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        if (val == 0) then
            ctrl:setName("Mono Off")
            ctrl:setColor(WHITE)
            --print("Initializing Mono Switch to "..0)
            ctrlMsg:setValue(0)
        else 
            -- Mono Sw can be any value 0..127 with switched pedal that puts out continuous data.
            -- But it needs to be 1 for the control to be updated to On.
            ctrl:setName("Mono On")
            ctrl:setColor(GREEN)
            --print("Initializing Mono Switch to "..1)
            ctrlMsg:setValue(1)
        end
    end
end -- CC event processing

function midi.onMessage(midiInput, midiMessage) -- Process incoming Midi Message Events
    local msg = midiMessage
    -- Added by SOR: Get system presets.
    if msg.channel ~= 16 then -- SOR
        return
    end
    -- Added by SOR: Control value updates.
    if msg.controllerNumber==109 and msg.value==26 then -- doneTxDsp
        if currentPreset.loadState == presetLoadState.loading then -- Preset load has finished.
            currentPreset.loadState = presetLoadState.loaded
            -- We are adopting a cautious approach by waiting for the preset load to
            -- finish before requesting the preset information.
            -- Get Current Preset Information.
            getCurrentPresetData()
        end
        return
    end
    if ( msg.controllerNumber==109 and msg.value==49) then -- SOR
        -- Start of system preset list (beginSysNames)    
        isGettingSystemPresets = true
        --print("Start of system preset list")
        return
    end
    if (msg.controllerNumber==109 and msg.value==40) then -- SOR
        -- End of system preset list (endSysNames)    
        isGettingSystemPresets = false
        --print("End of system preset list")
        onSystemPresetsReceived(false)
        return
    end

    if (msg.controllerNumber==109 and msg.value==54) then -- Start User Names Found
        --print("Start getting user presets")
        info.setText(GETTING_PRESETS)
        userNameIndex=0
        return -- SOR
    end
    if (msg.controllerNumber==109 and msg.value==55) then -- End User Names Found
        --print("Finished getting user presets")
        onUserPresetsReceived() -- SOR
        return -- SOR
    end

    -- Amended by SOR: Control value updates.
    if msg.controllerNumber==56 then
        if msg.value == 20 then -- Matrix Stream
            matrixStream = true
            --print("Start of matrix stream")
            return
        end
        if matrixStream then
            matrixStream = false -- Has no CC56=127 terminator - new stream terminates it
            --print("End of matrix stream")
        end
    end

    -- Amended by SOR: Get system presets.
    if (msg.controllerNumber==56 and msg.value==0) then
        -- Start of system or user or loaded preset name stream
        if isGettingSystemPresets then
            isAccumulatingSystemPresetName = true
            systemPresetNameBuffer = ""
        elseif isGettingCurrentPresetData then
            isAccumulatingCurrentPresetName = true
            currentPresetNameBuffer = ""
        else
            -- Processing user presets  
            userNameIndex = userNameIndex + 1 -- Index Lua arrays from 1
            nameInProgress = true
        end
        return
    end

    if (msg.controllerNumber==56 and msg.value==14) then -- Convolution Stream
        convInProgress = true
        return -- SOR
    end

    if (msg.controllerNumber==56 and msg.value==15) then -- Convolution Stream
        thumbInProgress = true
        return -- SOR
    end

    -- Amended by SOR: Get system presets.
    if (msg.controllerNumber==56 and msg.value==1) then
        -- Start of Control Text or system preset filters context stream 
        if isGettingSystemPresets then
            -- System preset filters context data, which will include 
            -- the 2-letter category code.
            isAccumulatingSystemPresetFilters = true
            systemPresetFiltersBuffer = ""
            return
        end
        -- Start of Control Text stream, which includes macro names.
        controlText = ""
        return -- SOR
    end

    if msg.controllerNumber==56 and msg.value==127 then -- SOR 
        -- End of text stream
        if isAccumulatingCurrentPresetName then
            isAccumulatingCurrentPresetName = false
        end
        if isAccumulatingSystemPresetName then
            isAccumulatingSystemPresetName = false
            receivedSystemPresetName = trimTrailingNullChar(systemPresetNameBuffer)
            return
        end
        if isAccumulatingSystemPresetFilters then
            isAccumulatingSystemPresetFilters = false
            receivedSystemPresetFilters = trimTrailingNullChar(systemPresetFiltersBuffer)
            onSystemPresetReceived()
            return
        end
    end

    if (nameInProgress and msg.controllerNumber==56 and msg.value==127) then -- Stream Ends
        nameInProgress=false
        if (userNameProcessing) then
            if (userPresetNameBuffer == "" or userPresetNameBuffer == "-") then
                userPresetNameBuffer = "Empty"
            end
            if (string.len(userPresetNameBuffer) > 14) then -- Limit strings for congtrols to 14 chars
                --print("userPresetNameBuffer:|"..userPresetNameBuffer.."|")
                local tmpstr = userPresetNameBuffer
                userPresetNameBuffer = string.sub(tmpstr, 1, 14)
            end
            -- Store Preset name in array 
            userNames[userNameIndex] = userPresetNameBuffer -- SOR
        end
        userPresetNameBuffer = "" -- Reset userPresetNameBuffer to accumulate the next name
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
    -- Added by SOR: Get system presets.
    if (isAccumulatingCurrentPresetName) then
        -- Accumulate loaded preset name buffer
        currentPresetNameBuffer =
        currentPresetNameBuffer ..string.char(noteNumber)..string.char(pressure)
        return
    end
    if (isAccumulatingSystemPresetName) then
        -- Accumulate system preset name buffer
        systemPresetNameBuffer =
        systemPresetNameBuffer ..string.char(noteNumber)..string.char(pressure)
        return
    end
    -- Added by SOR: Get system presets.
    if (isAccumulatingSystemPresetFilters) then
        -- Accumulate system preset context buffer
        systemPresetFiltersBuffer =
        systemPresetFiltersBuffer ..string.char(noteNumber)..string.char(pressure)
        return
    end
    if (convInProgress) then
        convString = convString..math.floor(noteNumber).."|"..math.floor(pressure).."|"
        --print("CS=|"..convString.."|")--debugit       
        return
    end
    if (nameInProgress) then -- Accumulate name global name buffer
        userPresetNameBuffer = userPresetNameBuffer..string.char(noteNumber)..string.char(pressure)
    end
    -- Amended by SOR: Set macro names.
    if (isAccumulatingControlText) then -- Accumulate Control Text, which includes macro names.
        controlText = controlText..string.char(noteNumber)..string.char(pressure)
        return
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
            --print("Not Valid Velocity Mode - Ignore: "..curVel)
        end
        return -- SOR
    end
    -- Added by SOR: Control value updates.
    if (matrixStream and channel == 16 and noteNumber == 62) then -- Recirculator Type
        --print("Initializing Recirculator Type to "..pressure)
        setControlValue(85, pressure)
        return
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
        -- Use setControlValue SOR 
        setControlValue(238, cvcMode) -- Which of the 7 modes are set
        setControlValue(242, cvcLinear) -- Linear or Squared
        setControlValue(243, cvcOutputs) -- Outputs
        setControlValue(235, cvcBase) -- Base
        return
    end
    -- Get Bend - Read Only
    if (matrixStream == true and channel==16 and noteNumber == 40) then -- Bend
        local curBend = math.floor (pressure)
        local ctrl = controls.get(277)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(curBend)
        return -- SOR
    end
    -- Get Base Polyphony - Read Only
    if (matrixStream == true and channel==16 and noteNumber == 39) then -- Base Polyphony
        local curBasePoly = math.floor (pressure)
        local ctrl = controls.get(106)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(curBasePoly)
        return -- SOR
    end
    -- Get Expanded Polyphony - Read Only
    if (matrixStream == true and channel==16 and noteNumber == 11) then -- Expanded Polyphony
        local curBend = math.floor (pressure)
        local ctrl = controls.get(233)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(curBend)
        return -- SOR
    end
    -- Increased Computation - Read Only
    if (matrixStream == true and channel==16 and noteNumber == 5) then -- Increased Computation
        local incComp = math.floor (pressure)
        local ctrl = controls.get(264)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        --print("Increased Comp = "..incComp)
        ctrlMsg:setValue(incComp)
        return -- SOR
    end
    -- Get Mono Mode
    if (matrixStream == true and channel==16 and noteNumber == 46) then -- Mono Mode
        setControlValue(140, pressure) -- SOR
        return -- SOR
    end
    -- Get Mono Interval
    if (matrixStream == true and channel==16 and noteNumber == 48) then -- Mono Interval
        setControlValue(267, pressure) -- SOR
        return -- SOR
    end
    --  SplitMode
    if (matrixStream == true and channel==16 and noteNumber == 1) then -- Split Mode
        local splitMode = math.floor (pressure)
        local ctrl = controls.get(188)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(splitMode)
        return -- SOR
    end
    -- SplitPoint
    if (matrixStream == true and channel==16 and noteNumber == 45) then -- Split Mode
        local splitPoint = math.floor (pressure)
        local ctrl = controls.get(236)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(splitPoint)
        return -- SOR
    end
    -- Round Mode
    if (matrixStream == true and channel==16 and noteNumber == 10) then -- Round Mode
        local roundMode = math.floor (pressure)
        local ctrl = controls.get(210)
        local controlValue = ctrl:getValue("value")
        local ctrlMsg = controlValue:getMessage()
        ctrlMsg:setValue(roundMode)
        return -- SOR
    end
    -- Get Pedal 1 Assignments
    if (matrixStream == true and channel==16 and noteNumber == 52) then -- Pedal1 Assign
        --print("Initializing Pedal 1 Assign to "..pressure)
        setControlValue(143, pressure) -- SOR
        return -- SOR
    end
    -- Get Pedal 2 Assignments
    if (matrixStream == true and channel==16 and noteNumber == 53) then -- Pedal2 Assign
         --print("Initializing Pedal 2 Assign to "..pressure)
        setControlValue(164, pressure) -- SOR
        return -- SOR
    end

    -- Get Octave Switch mode
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
    -- Surface Direction
    if (matrixStream == true and channel==16 and noteNumber == 9) then
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
            --print("Unexpected Direction: "..direction)
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
            --print("Unexpected Preserve Surface")
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
            --print("Unexpected Preserve Pedals")
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
            --print("Unexpected Preserve Midi")
        end
    end
    -- Process Middle C - Transpose
    if (matrixStream == true and channel==16 and noteNumber == 44) then -- MiddleC/Transpose
        local xposeAssign = math.floor (pressure)
        local ctrl = controls.get(78)
        local controlValue = ctrl:getValue("value")
        --local ctrlMsg = controlValue:getMessage()
        --print("Transpose Val = "..xposeAssign)
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

function midi.onProgramChange(midiInput, channel, programNumber) -- SOR
    if channel == 16 and isGettingCurrentPresetData then
        -- This is the last item in the current preset data.
        isGettingCurrentPresetData = false
        -- We don't need the program number, as that will have already been
        -- conserved when the preset load was requested. 
        -- And programNumber cannot be relied on in the current preset data,
        -- for the following reasons.
        -- In the current preset data, in contrast to the preset lists:
        --     the bank MSB (ch16 cc32) is 126, regardless of whether it's a user preset
        --     or a system preset; 
        --     programNumber is 1-based, at least for user presets;
        -- I've not checked programNumber in the current preset data for system presets.
        -- What could it even mean when the bank MSB does not specify the category? 
        onCurrentPresetDataReceived()
    end    
end

-- Requests the list of user presets.
-- Once the whole list has been received, 
-- system presets will be either restored from persisted data 
-- or requested from the instrument.
-- Amended by SOR to prevent the boot sequence from getting stuck at the startup splash screen. 
function getNames(valueObject, value)
    --print("getNames: Getting user presets")
    isInitializing = false -- SOR
    userNameProcessing = true -- SOR
    resetMute() -- reset in case on from previous preset
    -- Ideally we would like to show the GETTING_PRESETS status bar message immediately.
    -- But it is not feasible.  The GETTING_PRESETS message would become stuck on
    -- if the instrument was not on when the E1 preset is loaded.
    -- And we can't time out if data is not received,
    -- as the E1 timer does not run on on a separate thread and so would block
    -- MIDI messages from being received.
    -- So GETTING_PRESETS will be shown once data starts to be received.
    if not hasJustLoaded then
        requestUserPresetNames()
        return
    end
    hasJustLoaded = false
    -- This Electra One preset is being loaded at boot up.
    -- Starting to receive the user presets immediately is likely 
    -- to cause the boot sequence to get stuck at the startup splash screen
    -- and fail to complete.
    -- See https://docs.electra.one/troubleshooting/defaultpreset.html.
    --
    -- So, to give the boot sequence time to get past the point where
    -- it can get stuck, pause before requesting the user preset names.
    -- I found that 400 milliseconds is just enough on my E1, regardless of
    -- whether system presets also need to be loaded.
    -- So 2 seconds should provide an ample safety margin.
    helpers.delay(2000)
    requestUserPresetNames()
end

-- Load up a user preset on pressing button 1-16 offset for bank
-- Renamed and now calls loadPreset. SOR 
function loadUserPreset(valueObject, value)
    local presetPos = valueObject:getMessage():getValue()
    if (presetPos == 0) then -- adjust for initialization
        --  -- Changing pages triggers Control #1 with 0 value (not sure why) return
        return
    end
    local presetNo = presetPos + presetOffset -- 1-based for userNames table index.
    local programNo = presetNo - 1 -- 0-based for Program change 0..127
    if (presetNo >= 1 and presetNo <= 128) then
        local bankMsb = 0 -- 0 = User Presets
        local bankLsb = 0 -- Because there are a maximum of 128 user presets
        -- For preset name display, see comment in loadPreset.  
        loadPreset(bankMsb, bankLsb, programNo)
    else
        --print("Unexpected Preset Index: "..programNo)
    end
end

-- Set the selected user preset position in which the current preset is to be stored.
function setUserPresetPos (valueObject, value)
    -- Get value without its decimal part.
    local slotNo = valueObject:getMessage():getValue()
    --print("setUserPresetPos: slotNo = "..slotNo.."; value = "..value)
    updateUserPresetPos(slotNo) -- SOR
end

function storeUserPreset (valueObject, value)
    local strIndex = 1
    local slen = 0
    local ascii1 = ""
    local ascii2 = ""
    --local presetPos
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
    end
    --print("storeUserPreset: presetPosSelect = "..presetPosSelect)
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

    s1,s2 = string.find(tStr,"%.")
    if (s1 ~= nil and s2 ~= nil) then
        -- Remove any trailing .n (we won't use that)
        pStr = tStr:sub(1,s1-1)
        --print("Storestring= "..pStr)
    else
        pStr = tStr
    end
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
    end
    -- Sequence needed to just store current preset back to its position
    local programNo = presetPosSelect -1 -- SOR
    --print("Storing to Preset position: "..programNo)
    midi.sendControlChange(DEVICE_PORT, 16, 56, 127) -- End Preset string
    midi.sendControlChange(DEVICE_PORT, 16, 0, 0) -- Send CC0/CC32
    midi.sendControlChange(DEVICE_PORT, 16, 32, 0)
    midi.sendControlChange(DEVICE_PORT, 16, 112, programNo) -- Send Store Command
    midi.sendControlChange(DEVICE_PORT, 16, 0, 0) -- Send CC0/C32
    -- Send Program change - current preset to user position
    midi.sendProgramChange(DEVICE_PORT, 16, programNo) -- SOR    
end

function preset.onLoad()
    --print("preset.onLoad()")
    -- Redundant initializations removed by SOR
    hasJustLoaded = true -- SOR
end

-- Set User Preset names - they are controls 1-16
function setUserPresetNames()
    --print("setUserPresetNames")
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
    --print("Setting Middle C to "..newMiddleC)
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
    --print("matrixPoke: "..pokeID.." "..pokeVal)
    if isGettingData() then
        --print("    Getting data, so not poking!")
        return
    end
    midi.sendControlChange(DEVICE_PORT, 16, 56, 20) -- Matrix Poke command 
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, pokeID , pokeVal) -- Perform the Poke  
end

function formulaPoke(formulaID, pokeID, pokeVal)
    --print("formulaPoke: "..formulaID..pokeID.." "..pokeVal)
    midi.sendControlChange(DEVICE_PORT, 16, 34, formulaID) -- Set Formula
    midi.sendControlChange(DEVICE_PORT, 16, 56, 19) -- Formula Poke command     
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, pokeID , pokeVal) -- Perform the Poke  
end

function convolutionPoke(pokeID, pokeVal)
    --print("convolutionPoke: "..pokeID.." "..pokeVal)
    if isGettingData() then
        --print("    Getting data, so not poking!")
        return
    end
    midi.sendControlChange(DEVICE_PORT, 16, 56, 26) -- Convolution command 
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, pokeID , pokeVal) -- Perform the Poke  
end


function mainGraphPoke(pokeIndex, pokeValue)
    --print("mainGraphPoke: "..pokeID.." "..pokeValue)
    midi.sendControlChange(DEVICE_PORT, 16, 56, 21) -- Matrix Poke command 
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, pokeIndex , pokeValue) -- Change Main Graph value at zero offset index 0..47  
end
function setRecirc(valueObject, value)
    --print("setRecirc")
    local recircVal = valueObject:getMessage():getValue()
    midi.sendControlChange(DEVICE_PORT, 16, 56, 20)
    midi.sendAfterTouchPoly(DEVICE_PORT, 16, 62 , recircVal)
end

-- Amended by SOR: Control value updates.
function setRecircType (valueObject, value)
    local recircType = valueObject:getMessage():getValue()
    -- 0 Short Reverb
    -- 1 Mod Delay
    -- 2 Swept Echo
    -- 3 Analog Echo
    -- 4 Dig Delay with LPF
    -- 5 Dig Delay with HPF
    -- 6 Long Reverb
    --print("setRecircType: Setting Recirculator Type to "..recircType)
    matrixPoke (62, recircType)
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
        --print ("Unexpected Recirc Enable/Disable Type")
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
        --print ("Unexpected IR 1 Codes ")
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
        --print ("Unexpected IR 2 Codes ")
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
        --print ("Unexpected IR 3 Codes ")
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
        --print ("Unexpected IR 4 Codes ")
    end
end

-- Set Phase Cancellation Compensation (labelled Ep in Haken Editor).
function setPhaseCnclCompnsat(valueObject, value) -- Renamed by SOR
    -- Conv poke - using control parameter for Conv operation to be generic
    local ctrl = controls.get(127)
    if (value == 1) then
        ctrl:setName("Compensate On")
        ctrl:setColor(GREEN)
        convolutionPoke(28,1) -- Fixed pokeID. SOR
    elseif (value == 0) then
        ctrl:setName("Compensate Off")
        ctrl:setColor(WHITE)
        convolutionPoke(28,0) -- Fixed pokeID. SOR
    else
        --print("Unknown EP value: "..value)
    end
end

function getMacros()
    if (macrosLoaded == true) then
        isAccumulatingControlText = true
        --print ("getMacros - should not be called until pressed")
        midi.sendControlChange(DEVICE_PORT, 16, 109, 22) -- Send get Current Preset Msg to get Macro labels and control values
    else
        --print ("MacrosLoaded - called by init")
        macrosLoaded = true
    end
end

function muteControl(valueObject, value)
    local muteOn = valueObject:getMessage():getValue() -- Store the current preset position elected as user store 
    local control = controls.get(230) 

    if (muteOn == 0) then -- Mute off, restore pre-gain
        control:setName("Mute Off")
        control:setColor(WHITE)
        --print("Muteval ="..muteVal)
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
    local val = getControlValue(140)
    --print("setMonoMode: Setting Mono Mode to "..val)
    matrixPoke(46, val)
end

function setMonoInterval(valueObject, value)
    if (math.floor(value) < 0) then
        return -- inits to -1 (check others)
    end
    local val = getControlValue(267)
    --print("setMonoInterval: Setting Mono Interval to "..val)
    matrixPoke(48, val)
end

function setMonoSwitch(valueObject, value)
    local control = controls.get(252)
    if (value == 0) then
        control:setName("Mono Off")
        control:setColor(WHITE)
    else
        control:setName("Mono On")
        control:setColor(GREEN)
    end
    -- Mono Sw can be any value 0..127 with switched pedal that puts out continuous data.
    -- But it needs to be 1 for the control to be updated to On.
    local val = getControlValue(252)
    if val > 0 then
        val = 1
    end
    --print("setMonoSwitch: Setting Mono Switch to "..val)
    midi.sendControlChange(DEVICE_PORT, 1, 9, val) -- SOR
end

function setOctRange(valueObject, value)
    local control = controls.get(179)
    local controlValue = control:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    local val = ctrlMsg:getValue()
    --print("Octave Transpose = "..val)
    matrixPoke(54, val)
end

function setOctSwMode(valueObject, value)
    local control = controls.get(173)
    local controlValue = control:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    local val = ctrlMsg:getValue()
    matrixPoke(7, val)
end

function setRoundInit(valueObject, value)
    local control = controls.get(209)
    local val = math.floor (value)
    --print("Round Initial = "..val)

    if (value == 0) then
        control:setName("Initial Off")
        control:setColor(WHITE)
    elseif (val == 127 or val == 1) then
        control:setName("Initial On")
        control:setColor(GREEN)
    else
        --print("Unexpected Round Initial Control: "..val)
        return
    end
    midi.sendControlChange(DEVICE_PORT, 1, 28, value)
end
-- Round Modes
function setRoundMode(valueObject, value) -- Round Mode
    local control = controls.get(210)
    local controlValue = control:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    local val = ctrlMsg:getValue()
    matrixPoke(10, val)
end

function setDirection(valueObject, value) -- Normal or reverse fingerboard
    local control = controls.get(253)
    local controlValue = control:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    local val = ctrlMsg:getValue()
    --print("Direction ="..val)
    if (val == 0) then
        control:setName("Normal")
        control:setColor(GREEN)
    elseif (val==1) then
        control:setName("Reverse")
        control:setColor(RED)
    else
        --print("Unexpected Direction")
        return
    end
    matrixPoke(9, val)
end
function setTuning(valueObject, value)
    local control = controls.get(189)
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
        --print ("Unrecognized tuning: "..tuning)
        return
    end
    --print("Tuning = "..tuning)
    midi.sendControlChange(DEVICE_PORT, 16, 51, tuning)
end
function setNdiv(valueObject, value)
    local control = controls.get(225)
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
        --print("Unexpected Replace/Preserve Surface")
        return
    end
    if (repSurfacePushed == false) then
        --print("Surface Replace Init")        
        repSurfacePushed = true
        return
    end
    if (repSurfacePushed) then
        --print("Writing flash 1")
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
        --print("Unexpected Replace/Preserve Pedals")
        return
    end
    if (repPedalsPushed == false) then
        --print("Pedals Replace Init")        
        repPedalsPushed = true
        return
    end

    if (repPedalsPushed) then
        --print("Writing flash 2")
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
        --print("Unexpected Repalce/Preserve Midi")
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
        --print("Unrecognized CompOrTanh")
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
    -- Added by SOR: Get system presets.
    if not haveSystemPresetsBeenReceived then
        -- This function will be called again, from the Lua code,
        -- once all the system presets have been received.
        return
    end
    -- Reset Preset index to beginning
    currentSystemPreset.presetNo = 0
    local ctrl = controls.get(273) -- Preset index
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    ctrlMsg:setValue(0) -- New Category then reset preset Index control to default
    ctrl = controls.get(46) -- Get Category control
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    local val = ctrlMsg:getValue() -- Get the category value (not index)
    currentSystemPreset.category = val+1
    if (currentSystemPreset.category == CAT_OTHER1) then
        currentSystemPreset.bankLsb = 1
    else
        currentSystemPreset.bankLsb = 0
    end
end

-- Get the preset name and index based on Category set
function selectSystemPreset(valueObject, value)
    -- Added by SOR: Get system presets.
    if not haveSystemPresetsBeenReceived then
        -- This function will be called again, from the Lua code,
        -- once all the system presets have been received.
        return
    end
    currentSystemPreset.presetNo = getMaxPresetIndex(math.floor(value))
    local ctrl = controls.get(278)
    if (currentSystemPreset.presetNo == 0) then
        ctrl:setName("SELECT PRESET")
    elseif (currentSystemPreset.name ~= "") then
        ctrl:setName(currentSystemPreset.name)
    end
end

-- To use one control for preset index select the index can't exceed the max
-- number of presets in a given category. This will change from instrument
-- to instrument (so probably best to create a separate version for each instrument)
-- Or see if this can be dynamically read for a later version
-- DOES THE ABOVE COMMENT NEED TO BE MODIFIED OR REMOVED?  SOR
-- Currently this should work for the Continuum and the EganMatrix module.
-- Amended by SOR: Get system presets.
function getMaxPresetIndex (pIndex) -- cap inex at max range for each category
    local ctrl = controls.get(273)
    local controlValue = ctrl:getValue("value")
    local ctrlMsg = controlValue:getMessage()
    local systemPresets = systemPresetCategories[currentSystemPreset.category]
    local systemPresetCount = #systemPresets
    if (pIndex > systemPresetCount) then
        ctrlMsg:setValue(systemPresetCount)
        return pIndex - 1
    end
    currentSystemPreset.name = systemPresets[pIndex]
    return pIndex
end

-- Load the System Preset
function loadSystemPreset(valueObject, value)
    --print("LoadSystemPreset Called")
    local tmpCategory = currentSystemPreset.category
    if (sendSysPresetInit == false) then
        sendSysPresetInit = true
        return
    end
    if (currentSystemPreset.presetNo == 0) then
        info.setText("Select System Preset")
        return
    elseif (currentSystemPreset.category == 0) then
        info.setText("Select Category")
        return
    end
    if (currentSystemPreset.category == CAT_OTHER1) then
        tmpCategory = CAT_OTHER -- Really only one Other category but presented to the user as 2
    end
    -- For preset name display, see comment in loadPreset.  
    loadPreset(tmpCategory, currentSystemPreset.bankLsb, currentSystemPreset.presetNo - 1) -- SOR
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
    --print ("Pedal1 val: "..ped1Val)
    matrixPoke(52, ped1Val) -- set assignment
end

-- Set Pedal 2 Assignment
function assignPedal2 (valueObject, value)
    if (pedal2Init == false) then
        --print ("assignPedal2: Setting pedal2Init to true")
        pedal2Init = true
        return
    end
    local val = getControlValue(164) -- SOR
    --print ("assignPedal2: Setting Pedal 2 assignment to "..val)
    matrixPoke(53, val) -- set assignment
end

function processConvolution()
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
        if (tmpStr:sub(ix,ix) =="|") then -- parse the individual parameters into an array
            convParams[pi] = tmpStr:sub(j,ix-1)
            --print("C="..convParams[pi]) -- debugit
            pi = pi + 1
            j = ix + 1
        end
        ix = ix + 1
    end
    -- Due to Lua tables being 1-based, each convParams index is one more 
    -- than the corresponding poke id used when updating the instrument. SOR
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
    -- Phase Cancellation Compensation (labelled Ep in Haken Editor). SOR
    ctrl = controls.get(127) 
    controlValue = ctrl:getValue("value")
    ctrlMsg = controlValue:getMessage()
    local phaseCancellationCompensation = convParams[29] 
    ctrlMsg:setValue(phaseCancellationCompensation)
    if phaseCancellationCompensation == 1 then
        ctrl:setName("Compensate On") -- SOR
    elseif phaseCancellationCompensation == 0 then
        ctrl:setName("Compensate Off") -- SOR
    else
        --print("EP - Unknown value: "..epval)
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

function formatUserPresetPos(valueObject, value) -- SOR
    -- Remove the decimal part of value for the formatted display.
    local val = math.floor(value)
    --print("formatUserPresetPos: value = "..value)
    if val == 0 then
        return "Pick Position"
    end
    return "User "..tostring(val) 
end

-- Returns the user value of the specified control.
-- (The value parameter of control functions 
-- only provides the untranslated zero-based value, so it won't always work.)
function getControlValue(controlNo) -- SOR
    local control = controls.get(controlNo)
    local controlValue = control:getValue("value")
    local controlMessage = controlValue:getMessage()
    return controlMessage:getValue()
end

function getCurrentPresetData() -- SOR
    --print("getCurrentPresetData: Loaded preset. Getting preset data.")
    isAccumulatingControlText = true
    isGettingCurrentPresetData = true
    -- Send get Current Preset Msg to get Macro labels and control values
    midi.sendControlChange(DEVICE_PORT, 16, 109, 16)
end

function getSystemPresets() -- SOR
    --print("getSystemPresets")
    if isSystemPresetsUpdateRequired then
        -- Request system preset names (sysToMidi).
        midi.sendControlChange(DEVICE_PORT, 16, 109, 39)
    else
        --print("    Getting system presets from persisted data.")
        systemPresetCategories = persistableData.systemPresetCategories
        onSystemPresetsReceived(true)
    end
end

function isGettingData() -- SOR
    -- The idea here is that checking the result should allow
    -- poke functions to refrain from updating the instrument
    -- while the controls are being populated with data received from the instrument.
    -- Unfortunately, this does not work.
    -- We can stop the few updates that were happening when some controls
    -- are being initialised before any presets have been requested.
    -- Apart from that, instrument updates are only triggered when control 
    -- values are updated, which does not happen till after data has been 
    -- received from the instrument.  And we can't distinguish a control update
    -- with instrument data from a control when the user changes the control value.
    return isInitializing
    -- The following are always false
    --print("    userNameProcessing = "..tostring(userNameProcessing))
    --print("    isGettingSystemPresets = "..tostring(isGettingSystemPresets))
    --print("    isGettingCurrentPresetData = "..tostring(isGettingCurrentPresetData))
end

-- Loads a system or user preset.
-- bankMsb: category for system preset, 0 for user preset.
-- bankLsb: 0 for user presets and most categories.
--     Can be > 0 for categories with more than 128 presets.
-- programNo: zero-based program number.
function loadPreset(bankMsb, bankLsb, programNo) -- SOR
    currentPreset.bankMsb = bankMsb
    currentPreset.bankLsb = bankLsb
    currentPreset.programNo = programNo
    currentPreset.IsUserPreset = currentPreset.bankMsb == 0
    currentPreset.loadState = presetLoadState.loading
    --print("loadPreset: currentPreset.IsUserPreset = "..tostring(currentPreset.IsUserPreset))
    resetMute() -- Reset in case on from previous preset
    -- We don't need to clear initialise macros because all 6 macro values are always 
    -- received for each preset, and the macro names are initialized in setMacroNames.
    midi.sendControlChange(DEVICE_PORT, 16, 0, currentPreset.bankMsb)
    -- Send bank LSB if > 128 Presets in category and this preset is not in bank 0. 
    if currentPreset.bankLsb > 0 then
        midi.sendControlChange(DEVICE_PORT, 16, 32, currentPreset.bankLsb)
    end
    midi.sendProgramChange(DEVICE_PORT, 16, currentPreset.programNo)
    -- Data for the loaded preset is requested 
    -- on receiving confirmation that the preset load has finished.
    -- The preset name is shown on the Current Preset control
    -- when the loaded preset data is received. This allows the loaded preset name
    -- to be shown after receiving preset names.
end

function onAllPresetsReceived() -- SOR
    -- Replace the "Getting presets..." notification 
    -- on the status bar with the version info.
    info.setText(versionText)
    -- Get the data for the preset that is loaded on the instrument.
    getCurrentPresetData()
end

function onCurrentPresetDataReceived() -- SOR
    --print("onCurrentPresetDataReceived: currentPreset.programNo = "..currentPreset.programNo..
    --        "; currentPreset.loadState = "..tostring(currentPreset.loadState)..
    --"; currentPreset.IsUserPreset = "..tostring(currentPreset.IsUserPreset))
    local presetNo = currentPreset.programNo + 1
    local receivedCurrentPresetName = trimTrailingNullChar(currentPresetNameBuffer)
    -- Show the preset name on the Current Preset control.
    local currentPresetControl = controls.get(50)
    currentPresetControl:setName(receivedCurrentPresetName)
    updateUserPresetPos(presetNo)
    if currentPreset.loadState == presetLoadState.alreadyLoaded then
        -- We must have just received the data for the preset that was
        -- already loaded on the instrument when the E1 preset was loaded.
        -- Unfortunately, there's no way to tell whether it is a user preset
        -- or a system preset. This is because, in the current preset data, 
        -- unlike the preset lists, Bank MSB (ch16 cc0) is always 126, 
        -- regardless of whether it's a user preset or system preset.
        -- So we cannot even get round the problem by reloading the preset.
        return
    end
    local selectPosControlNo = 32
    if currentPreset.IsUserPreset then
        -- Show the preset number on the Select Pos control.
        setControlValue(selectPosControlNo, presetNo)
    else
        setControlValue(selectPosControlNo, 0)
    end
end

function onFirmwareVersionReceived() -- SOR
    --print("onFirmwareVersionReceived")
    -- There's no specific command to request the firmware version.
    -- The instrument sends it more than once: on connecting to E1;
    -- when sending user presets; when sending system presets, etc.
    -- We don't want to show the firmware version every time it is received,
    -- as there may be a progress message in the info text while
    -- preset data is being received.  
    -- So save the version info to a variable to be shown again
    -- when all the preset data has been received.
    firmwareVersion = ((128 * highVersion)  + lowVersion) / 100
    versionText = "Ver: "..E1_PRESET_VERSION.."/"..firmwareVersion
    info.setText(versionText) -- Versions to Info Text
    --if persistableData.isSaved then
    --    print("    Previous firmware version = "..persistableData.firmwareVersion)
    --    print("    Current firmware version = "..firmwareVersion)
    --    print("    "..#persistableData.systemPresetCategories..
    --            " system preset categories have been recalled.")
    --else
    --    print("    The previous firmware version is not available.")
    --end
    isSystemPresetsUpdateRequired =
    not persistableData.isSaved
            or persistableData.firmwareVersion ~= firmwareVersion
            or #persistableData.systemPresetCategories == 0
    --print("    isSystemPresetsUpdateRequired = "..tostring(isSystemPresetsUpdateRequired))
end

function onSystemPresetReceived() -- SOR
    -- The system preset's two-letter category code has been received.
    -- It needs to be parsed from the Filters context data.
    -- The context data looks like "C=CC", usually followed by filter codes,
    -- where CC is the category code.  We currently don't use the filter codes.
    local categoryCode = string.sub(receivedSystemPresetFilters, 3, 4)
    if not categoryCode then
         print("onSystemPresetReceived: Cannot find category for "
                ..receivedSystemPresetName.." in ".. receivedSystemPresetFilters)
        return
    end
    local categoryNo = categoryNos[categoryCode]
    if not categoryNo then
         print("onSystemPresetReceived: Cannot find "..categoryCode..
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

function onSystemPresetsReceived(fromPersistedData) -- SOR
    haveSystemPresetsBeenReceived = true
    if not fromPersistedData then
        replaceLongSystemPresetNamesWithShortNames()
        savePersistableData()
    end
    onAllPresetsReceived()
    --local categoryCount = #systemPresetCategories
    --for category = 1, categoryCount do
    --    local presetNames = systemPresetCategories[category]
    --    local presetCount = #presetNames
    --    print("Category "..category.." has "..presetCount.." system presets.")
    --end
    selectPresetCategory(nil, nil)
    selectSystemPreset()
end

function onUserPresetsReceived() -- SOR
    setUserPresetNames()
    userNameProcessing = false
    userNameIndex = 0
    if not haveSystemPresetsBeenReceived then
        getSystemPresets()
    else
        onAllPresetsReceived()
    end
end

-- To avoid truncation when a system preset name is shown on the E1,
-- replace any names that are too long with short names.
function replaceLongSystemPresetNamesWithShortNames() -- SOR
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

function requestUserPresetNames() -- SOR
    midi.sendControlChange(DEVICE_PORT, 16, 109, 32)
end

function savePersistableData() -- SOR
    --print("Saving persistableData")
    persistableData.isSaved = true
    persistableData.firmwareVersion = firmwareVersion
    persistableData.systemPresetCategories = systemPresetCategories
    persist(persistableData)
end

function setControlValue(controlNo, value) -- SOR
    local control = controls.get(controlNo)
    local controlValue = control:getValue("value")
    local controlMessage = controlValue:getMessage()
    controlMessage:setValue(value)
end

-- Parses the specified macro string for a macro id and name,
-- setting the name shown on the corresponding macro control.
-- The expected format of the string is 'id=name', e.g. 'ii=ChordVol',
-- or 'id=name_range1..._rangeN', e.g. 'iv=Width_Less_More'
-- Spaces in names are not supported, as whitespace delimits the macro strings.
function setMacroName(macroString) -- SOR
    --print("setMacroName: macroString = '"..macroString.."'")
    -- E.g. "iv=Width_Less_More" will give us {"iv", "Width_Less_More"}.
    local lhsRhs = splitString(macroString, "=")
    local lhsRhsCount = #lhsRhs
    if lhsRhsCount ~= 2 then
        -- The specified string does not contain '=', 
        -- so it's not a properly formed macro string.
        -- Example:
        -- Preset 'Tap Sitar', among many others, has 'E.Eagan',
        -- a misplaced author name, in the macro line
        -- (as well as correctly in the author line).
        return
    end
    local macroId = lhsRhs[1] -- E.g. "i".
    if macroId == "g1" then
        macroId = "v"
    elseif macroId == "g2" then
        macroId = "vi"
    end
    -- E.g. "Width_Less_More" will give us {"Width", "Less", "More"}.
    local specs = splitString(lhsRhs[2], "_")
    local macroName = specs[1] -- E.g. "Width".
    local controlNo = macroControlNos[macroId]
    if not controlNo then
        -- Invalid macro id.
        -- Example:
        -- Preset 'Tap Sitar', among many others, has 'fade=5000' in the macro line.
        return
    end
    macroControls[controlNo]:setName(macroName)
end

function setMacroNames() -- SOR
    --print("setMacroNames")
    isAccumulatingControlText = false
    -- Blank out macro names.
    for controlNo = MACRO_I, MACRO_VI do
        macroControls[controlNo]:setName("")
    end
    -- The Control Text string consists of two or three lines in this order:
    -- a line containing macro names, which might be blank or omitted;
    -- a line containing the category and any other filters;
    -- and a line containing the author's name.
    -- Put the context lines, each trimmed, into a table.
    local lineThrow = string.char(10)
    local controlTextLines = splitString(controlText, lineThrow)
    local controlTextLinesCount = #controlTextLines
    if controlTextLinesCount == 0 then
        --print "Error: No Control Text lines."
        return
    end
    local macrosLine = controlTextLines[1]
    -- If the first line is blank, in which case its trimmed length will be zero,
    -- or is the category and filters line,
    -- this preset has no macros.
    if string.len(macrosLine) == 0
            or string.sub(macrosLine, 1, 2) == "C=" then
        -- Preset has no macros
        return
    end
    -- The macros line is expected to contain id=name pairs.
    -- But in rare cases there is a space after an '=', which could
    -- mess up the parsing if we don't allow for it.
    -- Remove any spaces preceding the '='s.
    -- There are no known examples, so this is just to be safe.
    while string.find(macrosLine, " =") do
        macrosLine = string.gsub(macrosLine, " =", "=")
    end
    -- Remove any spaces following the '='s.
    -- Example: Clarinet has macro line
    -- "i=Body_One_Two ii=Darkness iii= Tongue iv=Flutter".
    -- We would miss the Tongue macro if we don't remove the non-standard space.
    while string.find(macrosLine, "= ") do
        macrosLine = string.gsub(macrosLine, "= ", "=")
    end
    -- Now we are sure there are no spaces either side of the '='s.
    -- So we can safely split the macros line into id=name pairs delimited by space.
    local macroStrings = splitString(macrosLine)
    local macroStringsCount = #macroStrings
    for i = 1, macroStringsCount do
        setMacroName(macroStrings[i])
    end
end

function setPedal1Max(valueObject, value) -- SOR
    --print("setPedal1Max: Setting Pedal 1 Max to "..value)
    midi.sendControlChange(DEVICE_PORT, 1, 77, value)
end

function setPedal1Min(valueObject, value) -- SOR
    --print("setPedal1Max: Setting Pedal 1 Min to "..value)
    midi.sendControlChange(DEVICE_PORT, 1, 76, value)
end

function setPedal1Max(valueObject, value) -- SOR
    --print("setPedal1Max: Setting Pedal 1 Max to "..value)
    midi.sendControlChange(DEVICE_PORT, 1, 77, value)
end

function setPedal1Min(valueObject, value) -- SOR
    --print("setPedal1Min: Setting Pedal 1 Min to "..value)
    midi.sendControlChange(DEVICE_PORT, 1, 76, value)
end

function setPedal2Max(valueObject, value) -- SOR
    --print("setPedal2Max: Setting Pedal 2 Max to "..value)
    midi.sendControlChange(DEVICE_PORT, 1, 79, value)
end

function setPedal2Min(valueObject, value) -- SOR
    --print("setPedal2Min: Setting Pedal 2 Min to "..value)
    midi.sendControlChange(DEVICE_PORT, 1, 78, value)
end

function setSus(valueObject, value) -- SOR
    --print("setSus: Setting Sus to "..value)
    midi.sendControlChange(DEVICE_PORT, 1, 64, value)
end

function setSos1(valueObject, value) -- SOR
    --print("setSos1: Setting Sos1 to "..value)
    midi.sendControlChange(DEVICE_PORT, 1, 66, value)
end

function setSos2(valueObject, value) -- SOR
    --print("setSos2: Setting Sos2 to "..value)
    midi.sendControlChange(DEVICE_PORT, 1, 69, value)
end

-- Splits the delimited components of the specified string into a table.
-- If not specified, the delimiter will be any whitespace.
-- According to https://stackoverflow.com/questions/1426954/split-string-in-lua,
-- empty components will be omitted from the table. That should be fine.
-- Any leading or trailing whitespace will be trimmed from the component strings.
function splitString(inputString, delimiter) -- SOR
    if delimiter == nil then
        delimiter = "%s" -- Any whitespace
    end
    local result = {}
    for component in string.gmatch(inputString, "([^"..delimiter.."]+)") do
        table.insert(result, trimString(component))
    end
    return result
end

-- Removes leading and trailing whitespace from the specified string.
-- See http://lua-users.org/wiki/StringTrim.
function trimString(inputString) -- SOR
    return (inputString:gsub("^%s*(.-)%s*$", "%1"))
end

-- The text streams provide characters in pairs,
-- So if the string received has an odd number of characters,
-- there will be an null character (ASCII 0) at the end to make it even.
-- For system preset names,
-- the null character really messes things up if we don't remove it.
-- And it is removed for system preset contexts too, just for tidiness.
-- If there's already code to remove the null character for user preset names,
-- I've not spotted it. Maybe it does not matter in that case.
function trimTrailingNullChar(text) -- SOR
    local textLength = string.len(text)
    local lastCharNo = string.byte(text, textLength)
    if lastCharNo == 0 then
        local result = string.sub(text,1, textLength - 1)
        return result
    end
    return text
end

-- Set the user preset position in which the current preset is to be stored.
-- slotNo: The 1-based user preset slot number, or zero if none has been selected or set.
function updateUserPresetPos(slotNo) -- SOR
    presetPosSelect = slotNo  
    --print("updateUserPresetPos: presetPosSelect = "..presetPosSelect..
    --    "; currentPreset.IsUserPreset = "..tostring(currentPreset.IsUserPreset))
    local currentPresetGroup = groups.get(49)
    local currentPresetControl = controls.get(50)
    if currentPreset.IsUserPreset and presetPosSelect > 0 then
        currentPresetControl:setColor(RED)
        currentPresetGroup:setLabel("Store Preset")
        currentPresetGroup:setColor(RED)
    else
        currentPresetControl:setColor(ORANGE)
        currentPresetGroup:setLabel("CURRENT PRESET")
        currentPresetGroup:setColor(ORANGE)
    end 
end

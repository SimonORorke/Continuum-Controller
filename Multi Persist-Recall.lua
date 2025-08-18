-- Preset compatibility check
assert(
    controller.isRequired(MODEL_MK2, "4.0.0"),
    "Version 4.0.0 or higher is required"
)

-- Six Macro Control values
local curMacro1Val = 0;
local curMacro2Val = 0;
local curMacro3Val = 0;
local curMacro4Val = 0;
local curMacro5Val = 0;
local curMacro6Val = 0;

-- Assume table exists in JSON as persisted object and recall it
local userTable = {}
recall(userTable)

-- Print Table function
function printTable(t, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)

    if type(t) ~= "table" then
        if type(t) == "boolean" then
            print(indentStr .. tostring(t))
        else
            print(indentStr .. tostring(t))
        end
        return
    end

    print(indentStr .. "{")
    for key, value in pairs(t) do
        local formattedKey = tostring(key)
        if type(value) == "table" then
            print(indentStr .. "  " .. formattedKey .. " = ")
            printTable(value, indent + 1)
        else
            if type(value) == "boolean" then
                print(indentStr .. "  " .. formattedKey .. " = " .. tostring(value))
            else
                print(indentStr .. "  " .. formattedKey .. " = " .. tostring(value))
            end
        end
    end
    print(indentStr .. "}")
end

-- Redefine table (if not recalled)
if next(userTable) == nil then
  print("Table reinit")
  userTable = {
    user1 = { macro1 = 0, macro2 = 0, macro3 = 0, macro4 = 0, macro5 = 0, macro6 = 0},
    user2 = { macro1 = 0, macro2 = 0, macro3 = 0, macro4 = 0, macro5 = 0, macro6 = 0},
    user3 = { macro1 = 0, macro2 = 0, macro3 = 0, macro4 = 0, macro5 = 0, macro6 = 0}
  }
else -- It was recalled and now repersist (though stores later will also persist)
  print ("Table exists")
  persist(userTable) -- should already be persisting
  printTable (userTable)
end

--local userData = {} -- Don't need because initial recall is made

-- Store data when dials changed
function storeMacro1(valueObject, value)
    curMacro1Val = valueObject:getMessage():getValue()
    --print ("Macro 1 ="..curMacro1Val)
end 
function storeMacro2(valueObject, value)
    curMacro2Val = valueObject:getMessage():getValue()
    --print ("Macro 2 ="..curMacro2Val)
end 
function storeMacro3(valueObject, value)
    curMacro3Val = valueObject:getMessage():getValue() 
    --print ("Macro 3 ="..curMacro3Val)
end 
function storeMacro4(valueObject, value)
    curMacro4Val = valueObject:getMessage():getValue() 
    --print ("Macro 4 ="..curMacro4Val)
end 
function storeMacro5(valueObject, value)
    curMacro5Val = valueObject:getMessage():getValue() 
    --print ("Macro 5 ="..curMacro5Val)
end 
function storeMacro6(valueObject, value)
    curMacro6Val = valueObject:getMessage():getValue() 
    --print ("Macro 6 ="..curMacro6Val)
end 

-- Process Store User and Get User Controls
-- Note: Momentary controls should be set with Off value blank or tables will be zeroed out. 
function storeUser1Table(valueObject, value)  
   userTable.user1.macro1 = curMacro1Val
   userTable.user1.macro2 = curMacro2Val
   userTable.user1.macro3 = curMacro3Val
   userTable.user1.macro4 = curMacro4Val
   userTable.user1.macro5 = curMacro5Val
   userTable.user1.macro6 = curMacro6Val
   persist (userTable) -- Always repersist if changes made to update
end
function retrieveUser1Table()
  -- recall (userData) -- after repower this is zeroed out for some reason with 4.0.0.r?
   printTable (userTable) -- For some reason its zeroed out here but ok when loaded? Something about GetUser control?
   setCtrl(1, userTable.user1.macro1)
   setCtrl(2, userTable.user1.macro2)
   setCtrl(3, userTable.user1.macro3)
   setCtrl(4, userTable.user1.macro4) 
   setCtrl(5, userTable.user1.macro5)   
   setCtrl(6, userTable.user1.macro6)
end

function storeUser2Table(valueObject, value)  
   userTable.user2.macro1 = curMacro1Val
   userTable.user2.macro2 = curMacro2Val
   userTable.user2.macro3 = curMacro3Val
   userTable.user2.macro4 = curMacro4Val
   userTable.user2.macro5 = curMacro5Val
   userTable.user2.macro6 = curMacro6Val             
   persist (userTable) -- Always repersist if changes made to update
end

function retrieveUser2Table()
   --recall (userData)
   printTable (userTable)
   setCtrl(1, userTable.user2.macro1) 
   setCtrl(2, userTable.user2.macro2)
   setCtrl(3, userTable.user2.macro3) 
   setCtrl(4, userTable.user2.macro4)
   setCtrl(5, userTable.user2.macro5) 
   setCtrl(6, userTable.user2.macro6)
end

function storeUser3Table(valueObject, value)  
   userTable.user3.macro1 = curMacro1Val 
   userTable.user3.macro2 = curMacro2Val
   userTable.user3.macro3 = curMacro3Val
   userTable.user3.macro4 = curMacro4Val
   userTable.user3.macro5 = curMacro5Val
   userTable.user3.macro6 = curMacro6Val            
   persist (userTable) -- Always repersist if changes made to update
end

function retrieveUser3Table()
   --recall (userData)
   printTable (userTable)
   setCtrl(1, userTable.user3.macro1)
   setCtrl(2, userTable.user3.macro2)
   setCtrl(3, userTable.user3.macro3)
   setCtrl(4, userTable.user3.macro4)  
   setCtrl(5, userTable.user3.macro5) 
   setCtrl(6, userTable.user3.macro6)
end

function setCtrl (ctrlVal, val)
   local ctrl = controls.get(ctrlVal)
   local controlValue = ctrl:getValue("value")
   local ctrlMsg = controlValue:getMessage()
   ctrlMsg:setValue(val) 
end

 -- print("Table:", dump(user1Data))
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
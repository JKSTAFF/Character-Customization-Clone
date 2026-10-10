local re = re
local sdk = sdk
local log = log
local json = json
-- local hotkeys = require("Hotkeys/Hotkeys")

log.info("[Character Customization Clone] Loaded");

local Config = {}

-- Config.Hotkeys = {
--     ["Interrupt Key"] = "T"
-- }

if Config.EnableMod == nil then
	Config.EnableMod = true
end

local configFilePath = "CharacterCustomizationClone\\CharacterCustomizationClone.json"

-- hotkeys.setup_hotkeys(Config.Hotkeys)

local function saveConfig()
    local success, err = pcall(json.dump_file, configFilePath, Config)
    if not success then
        log.error("Error saving configuration: " .. tostring(err))
    end
end

local function loadConfig()
    local status, data = pcall(json.load_file, configFilePath)
    if not status or not data then
        return
    end

    if type(data) == "table" then
		-- if data.Hotkeys then
		-- 	Config.Hotkeys = data.Hotkeys
		-- 	hotkeys.setup_hotkeys(Config.Hotkeys)
		-- end
		Config.EnableMod = data.EnableMod
    else
    end
end

loadConfig()

local function generate_enumIndex(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            -- local name = field:get_name()
            local raw_value = field:get_data(nil)

            enum[raw_value] = raw_value
        end
    end

    return enum 
end

local function generate_enum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            enum[name] = raw_value
        end
    end

    return enum
end

function getPlayer()
	local cm = sdk.get_managed_singleton("app.CharacterManager")
	local player = cm:get_ManualPlayer()
	return player
end

local ExportFaceEditData = {}
local ExportBodyEditData = {}


local ExportBodyDetail_SkinContext = nil
local ExportBodyDetail_ClawContext = nil
local ExportBodyDetail_HairContext = nil
local ExportBodyDetail_BeardContext = nil
local ExportBodyDetail_BodyHairContext = nil
local ExportBodyDetail_FurPatternContext = nil
local ExportBodyDetail_FurFacePatternContext = nil
local ExportBodyDetail_FurFaceMaskContext = nil
local ExportBodyDetail_FurForeheadContext = nil
local ExportBodyDetail_FurEyesContext = nil
local ExportBodyDetail_FurCheeksContext = nil
local ExportBodyDetail_FurNoseContext = nil
local ExportBodyDetail_EyesContext = nil
local ExportBodyDetail_EyebrowsContext = nil
local ExportBodyDetail_EyelashesContext = nil
local ExportBodyDetail_EyelinerContext = nil
local ExportBodyDetail_EyeshadowContext = nil
local ExportBodyDetail_CheekContext = nil
local ExportBodyDetail_LipsContext = nil
local ExportBodyDetail_TeethContext = nil
local ExportBodyDetail_FrecklesContext = nil
local ExportBodyDetail_NoseContext = nil
local ExportBodyDetail_DirtContext = nil
local ExportBodyDetail_TattoosContext = nil
local ExportBodyDetail_ScarsContext = nil

local ExportBodyDetail_partSwapHumanContext = nil

local isImport = false
local faceIDEnum = generate_enumIndex("app.FaceEditID")
local bodyIDEnum = generate_enumIndex("app.BodyEditID")

-----Export Json
-- local ExportBodyDetailContextData = {}


-- function recursiveObjFieldValue2Table(obj, context)
--     local type = obj:get_type_definition()

--     if context == nil then
--         context = {}
--     end

--     -- if type:is_a("app.BodyDetailContext.EyeshadowBaseContext") then
--     --     value = recursiveObjFieldValue2Table(obj, context[name])
--     -- end

--     local fields = type:get_fields()
--     local parentFields = type:get_parent_type():get_fields()
--     for i, field in ipairs(parentFields) do
--         table.insert(fields, field)
--     end

--     for i, field in ipairs(fields) do
--         local name = field:get_name()
--         local value = field:get_data(obj)
        
--         if context[name] == nil then
--             context[name] = {}
--         end

--         local resultVal = value

--         if field:get_type():is_a("via.Color") then
--             resultVal = processColor2Json(value)
--         elseif checkIsA(field, "app.BodyDetailContext.EyelashContext") or checkIsA(field, "app.BodyDetailContext.EyeBaseContext")
--         or checkIsA(field, "app.BodyDetailContext.EyeshadowCommonContext") or checkIsA(field, "app.BodyDetailContext.EyeshadowBaseContext") 
--         or checkIsA(field, "app.BodyDetailContext.LipCommonContext") then
--             resultVal = recursiveObjFieldValue2Table(value, context[name])
--             resultVal["type"] = field:get_type():get_full_name()
--         elseif checkIsA(field, "app.charaedit.ch000.Scars.SlotData[]") or checkIsA(field, "app.charaedit.ch000.Tattoos.SlotData[]") then
--             resultVal = {}
--             for i, v in ipairs(value) do
--                 resultVal[i] = recursiveObjFieldValue2Table(v, context[name])
--                 resultVal[i]["type"] = v:get_type_definition():get_full_name()
--             end
--         end

--         context[name] = resultVal
--     end
--     return context
-- end

-- function checkIsA(field, type)
--     return field:get_type():is_a(type)
-- end

-- function processColor2Json(color)
--     return color.rgba
-- end

-- function table2Context(contextType, tableVal)
--     local context = sdk.create_instance(contextType):add_ref()
--     -- log.debug(" TTTTTTTTTT "..tostring(tableVal).." Test "..tostring(tableVal["_Common"]))
--     for k, v in ipairs(tableVal) do
--         if type(v) ~= "table" then
--             context:set_field(k, v)
--         else
--             if k == "_SlotDatas" then
--                 local arrayType = ""
--                 local dataObj = nil
--                 for i = 1, #v do
--                     arrayType = v[i]["type"]
--                     dataObj = sdk.create_instance(arrayType.."[]"):add_ref()
--                     dataObj[i - 1] = table2Context(arrayType, v[i])
--                 end
--                 context:set_field(k, dataObj)
--             else
--                 context:set_field(k, table2Context(v["type"], v))
--             end
--         end
--     end

--     return context
-- end
---Export Json

local isExported = false
local curName = ""
local characterNameObjKvp = {}
local noseTestValue = 0
local characterNameList = {}

re.on_draw_ui(function()
	local treeOpen = false
	local changed = false

	local ok, err = pcall(function()
		if imgui.tree_node("CharacterCustomizationClone") then
			treeOpen = true
			changed = false

        changed, Config.EnableMod = imgui.checkbox("EnableMod", Config.EnableMod)
 
        if not isExported then
            characterNameList = {}
            local player = getPlayer()
            local playerContextholder = player:get_Context()
            local playerContextList = playerContextholder.Contexts
            local personalRuntimeType = sdk.find_type_definition("app.PlayerPersonalDataContext"):get_runtime_type()
            local personalContextInfo = playerContextList[personalRuntimeType]
            local personalContext = personalContextInfo:get_CurrentContext()
            local playerName = personalContext:get_NameProp()
            characterNameList[0] = playerName
            characterNameObjKvp[playerName] = player

            pawnMgr = sdk.get_managed_singleton("app.PawnManager")

            local cList = pawnMgr:get_PawnCharacterList()
            local count = cList:get_Count()
            for i = 0, count - 1 do
                local mainPawn = pawnMgr:get_MainPawn()
                local pawnChara = cList:get_Item(i)
                local pawnContextholder = pawnChara:get_Context()
                local pawnContextList = pawnContextholder.Contexts
                local pawnDataRuntimeType = sdk.find_type_definition("app.PawnDataContext"):get_runtime_type()
                local pawnDataContextInfo = pawnContextList[pawnDataRuntimeType]
                local pawnDataContext = pawnDataContextInfo:get_CurrentContext()
                local pawnName = pawnDataContext:get_Nickname()
                characterNameList[i + 1] = pawnName
                characterNameObjKvp[pawnName] = pawnChara
            end

            changed, curName = imgui.combo("Character List", curName, characterNameList)
            if imgui.button("Copy") then
                -- local player = getPlayer()
                -- log.debug("curName "..tostring(curName).." ::: "..tostring(characterNameObjKvp[curName]))
                local contextholder = characterNameObjKvp[characterNameList[curName]]:get_Context()
                local contextList = contextholder.Contexts
                local faceEditRuntimeType = sdk.find_type_definition("app.FaceEditContext"):get_runtime_type()
                local faceEditContextInfo = contextList[faceEditRuntimeType]
                local faceEditContext = faceEditContextInfo:get_CurrentContext()

                local faceEditList = faceEditContext:get_EditValues()
                local faceEditListCount = faceEditList:get_Count()

                for i = 0, faceEditListCount - 1 do
                    local item = faceEditList:get_Item(i)
                    ExportFaceEditData[item._EditKeyHash] = item._Value
                end
                
                local bodyEditRuntimeType = sdk.find_type_definition("app.BodyEditContext"):get_runtime_type()
                local bodyEditContextInfo = contextList[bodyEditRuntimeType]
                local bodyEditContext = bodyEditContextInfo:get_CurrentContext()

                local bodyEditList = bodyEditContext:get_EditValues()
                local bodyEditCount = bodyEditList:get_Count()

                for i = 0, bodyEditCount - 1 do
                    local item = bodyEditList:get_Item(i)
                    ExportBodyEditData[item._EditKeyHash] = item._Value
                end
                
                local partSwapHumanRuntimeType = sdk.find_type_definition("app.PartSwapHumanContext"):get_runtime_type()
                local partSwapHumanContextInfo = contextList[partSwapHumanRuntimeType]
                local partSwapHumanContext = partSwapHumanContextInfo:get_CurrentContext()

                ExportBodyDetail_partSwapHumanContext = partSwapHumanContext

                local bodyDetailEditRuntimeType = sdk.find_type_definition("app.BodyDetailContext"):get_runtime_type()
                local bodyDetailEditContextInfo = contextList[bodyDetailEditRuntimeType]
                local bodyDetailEditContext = bodyDetailEditContextInfo:get_CurrentContext()

                
                ExportBodyDetail_SkinContext = bodyDetailEditContext._Skin
                ExportBodyDetail_ClawContext = bodyDetailEditContext._Claws
                ExportBodyDetail_HairContext = bodyDetailEditContext._Hair
                ExportBodyDetail_BeardContext = bodyDetailEditContext._Beard
                ExportBodyDetail_BodyHairContext = bodyDetailEditContext._BodyHair
                ExportBodyDetail_FurPatternContext = bodyDetailEditContext._FurPattern
                ExportBodyDetail_FurFacePatternContext = bodyDetailEditContext._FurFacePattern
                ExportBodyDetail_FurFaceMaskContext = bodyDetailEditContext._FurFaceMask
                ExportBodyDetail_FurForeheadContext = bodyDetailEditContext._FurForehead
                ExportBodyDetail_FurEyesContext = bodyDetailEditContext._FurEyes
                ExportBodyDetail_FurCheeksContext = bodyDetailEditContext._FurCheeks
                ExportBodyDetail_FurNoseContext = bodyDetailEditContext._FurNose
                ExportBodyDetail_EyesContext = bodyDetailEditContext._Eyes
                ExportBodyDetail_EyebrowsContext = bodyDetailEditContext._Eyebrows
                ExportBodyDetail_EyelashesContext = bodyDetailEditContext._Eyelashes
                ExportBodyDetail_EyelinerContext = bodyDetailEditContext._Eyeliner
                ExportBodyDetail_EyeshadowContext = bodyDetailEditContext._Eyeshadow
                ExportBodyDetail_CheekContext = bodyDetailEditContext._Cheek
                ExportBodyDetail_LipsContext = bodyDetailEditContext._Lips
                ExportBodyDetail_TeethContext = bodyDetailEditContext._Teeth
                ExportBodyDetail_FrecklesContext = bodyDetailEditContext._Freckles
                ExportBodyDetail_NoseContext = bodyDetailEditContext._Nose
                ExportBodyDetail_DirtContext = bodyDetailEditContext._Dirt
                ExportBodyDetail_TattoosContext = bodyDetailEditContext._Tattoos
                ExportBodyDetail_ScarsContext = bodyDetailEditContext._Scars

                isExported = true

                -- ExportBodyDetailContextData = recursiveObjFieldValue2Table(bodyDetailEditContext, ExportBodyDetailContextData)
            -----Export Json
                -- ExportBodyDetailContextData["Skin"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Skin, ExportBodyDetailContextData["Skin"])
                -- ExportBodyDetailContextData["Claws"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Claws, ExportBodyDetailContextData["Claws"])
                -- ExportBodyDetailContextData["Hair"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Hair, ExportBodyDetailContextData["Hair"])
                -- ExportBodyDetailContextData["Beard"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Beard, ExportBodyDetailContextData["Beard"])
                -- ExportBodyDetailContextData["BodyHair"] = recursiveObjFieldValue2Table(bodyDetailEditContext._BodyHair, ExportBodyDetailContextData["BodyHair"])
                -- ExportBodyDetailContextData["FurPattern"] = recursiveObjFieldValue2Table(bodyDetailEditContext._FurPattern, ExportBodyDetailContextData["FurPattern"])
                -- ExportBodyDetailContextData["FurFacePattern"] = recursiveObjFieldValue2Table(bodyDetailEditContext._FurFacePattern, ExportBodyDetailContextData["FurFacePattern"])
                -- ExportBodyDetailContextData["FurFaceMask"] = recursiveObjFieldValue2Table(bodyDetailEditContext._FurFaceMask, ExportBodyDetailContextData["FurFaceMask"])
                -- ExportBodyDetailContextData["FurForehead"] = recursiveObjFieldValue2Table(bodyDetailEditContext._FurForehead, ExportBodyDetailContextData["FurForehead"])
                -- ExportBodyDetailContextData["FurEyes"] = recursiveObjFieldValue2Table(bodyDetailEditContext._FurEyes, ExportBodyDetailContextData["FurEyes"])
                -- ExportBodyDetailContextData["FurCheeks"] = recursiveObjFieldValue2Table(bodyDetailEditContext._FurCheeks, ExportBodyDetailContextData["FurCheeks"])
                -- ExportBodyDetailContextData["FurNose"] = recursiveObjFieldValue2Table(bodyDetailEditContext._FurNose, ExportBodyDetailContextData["FurNose"])
                -- ExportBodyDetailContextData["Eyes"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Eyes, ExportBodyDetailContextData["Eyes"])
                -- ExportBodyDetailContextData["Eyebrows"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Eyebrows, ExportBodyDetailContextData["Eyebrows"])
                -- ExportBodyDetailContextData["Eyelashes"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Eyelashes, ExportBodyDetailContextData["Eyelashes"])
                -- ExportBodyDetailContextData["Eyeliner"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Eyeliner, ExportBodyDetailContextData["Eyeliner"])
                -- ExportBodyDetailContextData["Eyeshadow"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Eyeshadow, ExportBodyDetailContextData["Eyeshadow"])
                -- ExportBodyDetailContextData["Cheek"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Cheek, ExportBodyDetailContextData["Cheek"])
                -- ExportBodyDetailContextData["Lips"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Lips, ExportBodyDetailContextData["Lips"])
                -- ExportBodyDetailContextData["Teeth"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Teeth, ExportBodyDetailContextData["Teeth"])
                -- ExportBodyDetailContextData["Freckles"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Freckles, ExportBodyDetailContextData["Freckles"])
                -- ExportBodyDetailContextData["Nose"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Nose, ExportBodyDetailContextData["Nose"])
                -- ExportBodyDetailContextData["Dirt"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Dirt, ExportBodyDetailContextData["Dirt"])
                -- ExportBodyDetailContextData["Tattoos"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Tattoos, ExportBodyDetailContextData["Tattoos"])
                -- ExportBodyDetailContextData["Scars"] = recursiveObjFieldValue2Table(bodyDetailEditContext._Scars, ExportBodyDetailContextData["Scars"])


                -- json.dump_file("CharacterEditor\\test.json", ExportBodyDetailContextData)
            -----Export Json

                -- eyesAngle = faceEditContext:getEditValue(1072516754)

                -- ExportData[1072516754] = eyesAngle
                -- log.debug(" Export "..tostring(eyesAngle))
                -- local gameobj = player:get_GameObject()
                -- gameobj:call("getComponent(System.Type)", sdk.typeof("via.motion.MotionFsm2"))
            end
        end

        if isExported then
            local scene = sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene()")

            local charaEditModelCtrlObj = scene:call("findGameObject(System.String)", "CharaEditModelCtrl")
            
            local charaEditModelCtrlTransform = charaEditModelCtrlObj:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
            local uiTrans = charaEditModelCtrlTransform:find("ui070406_01")
            if uiTrans ~= nil then
                if imgui.button("Paste "..tostring(characterNameList[curName])) then
                    -- isImport = true
                    local guiMgr = sdk.get_managed_singleton("app.GuiManager")
                    local charaEditCtrl = guiMgr._CharaEditCtrl
                    local modelEditor = charaEditCtrl:get_ModelEditor()
                    local previewObj = modelEditor:get_PreviewModelObj()
                    local previewObjTransform = previewObj:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
                    local headTransform = previewObjTransform:find("head")
                    local headGameObj = headTransform:get_GameObject()
                    local headFaceEditor = headGameObj:call("getComponent(System.Type)", sdk.typeof("app.FaceEditor"))

                    local isChanged = false
                    -- local faceEditorInput = headFaceEditor._Input
                    if ExportFaceEditData ~= nil then
                        for key, value in pairs(ExportFaceEditData) do
                            headFaceEditor:setEditValue(faceIDEnum[key], value, false)
                            headFaceEditor:applyEdit()
                        end
                        isChanged = true
                    end

                    local headbodyEditor = headGameObj:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))

                    if ExportBodyEditData ~= nil then
                        for key, value in pairs(ExportBodyEditData) do
                            headbodyEditor:setEditValue(bodyIDEnum[key], value, false)
                            headbodyEditor:applyEdit()
                        end
                        isChanged = true
                    end

                    local bodyEditor = previewObj:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))

                    if ExportBodyEditData ~= nil then
                        for key, value in pairs(ExportBodyEditData) do
                            bodyEditor:setEditValue(bodyIDEnum[key], value, false)
                            bodyEditor:applyEdit()
                        end
                        isChanged = true
                    end

                    local partSwapper = previewObj:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
                    if ExportBodyDetail_partSwapHumanContext ~= nil then
                        partSwapper:call("restore(app.PartSwapHumanContext)", ExportBodyDetail_partSwapHumanContext)
                        isChanged = true
                    end

                    local bodyDetailEditor = previewObj:call("getComponent(System.Type)", sdk.typeof("app.BodyDetailEditor"))
                    -- if ExportBodyDetail_HairContext ~= nil then
                        bodyDetailEditor._Skin:call("restore(app.BodyDetailContext.SkinContext)", ExportBodyDetail_SkinContext)
                        bodyDetailEditor._Claws:call("restore(app.BodyDetailContext.ClawsContext)", ExportBodyDetail_ClawContext)
                        bodyDetailEditor._Hair:call("restore(app.BodyDetailContext.HairContext)", ExportBodyDetail_HairContext)

                        bodyDetailEditor._Beard:call("restore(app.BodyDetailContext.BeardContext)", ExportBodyDetail_BeardContext)

                        -- local testContext = table2Context("app.BodyDetailContext.EyesContext", ExportBodyDetailContextData["Eyes"])

                        bodyDetailEditor._BodyHair:call("restore(app.BodyDetailContext.BodyHairContext)", ExportBodyDetail_BodyHairContext)
                        bodyDetailEditor._FurPattern:call("restore(app.BodyDetailContext.FurPatternsContext)", ExportBodyDetail_FurPatternContext)
                        bodyDetailEditor._FurFacePattern:call("restore(app.BodyDetailContext.FurFacePatternContext)", ExportBodyDetail_FurFacePatternContext)
                        bodyDetailEditor._FurFaceMask:call("restore(app.BodyDetailContext.FurFaceMaskContext)", ExportBodyDetail_FurFaceMaskContext)
                        bodyDetailEditor._FurForehead:call("restore(app.BodyDetailContext.FurForeheadContext)", ExportBodyDetail_FurForeheadContext)
                        bodyDetailEditor._FurEyes:call("restore(app.BodyDetailContext.FurEyesContext)", ExportBodyDetail_SkinContext)
                        bodyDetailEditor._FurCheeks:call("restore(app.BodyDetailContext.FurCheeksContext)", ExportBodyDetail_FurCheeksContext)
                        bodyDetailEditor._FurNose:call("restore(app.BodyDetailContext.FurNoseContext)", ExportBodyDetail_FurNoseContext)
                        bodyDetailEditor._Eyes:call("restore(app.BodyDetailContext.EyesContext)", ExportBodyDetail_EyesContext)
                        bodyDetailEditor._Eyelashes:call("restore(app.BodyDetailContext.EyelashesContext)", ExportBodyDetail_EyelashesContext)
                        bodyDetailEditor._Eyebrows:call("restore(app.BodyDetailContext.EyebrowsContext)", ExportBodyDetail_EyebrowsContext)

                        bodyDetailEditor._Makeup:call("restore(app.BodyDetailContext.EyelinerContext, app.BodyDetailContext.EyeshadowContext, app.BodyDetailContext.CheekContext, app.BodyDetailContext.LipsContext)", ExportBodyDetail_EyelinerContext, ExportBodyDetail_EyeshadowContext, ExportBodyDetail_CheekContext, ExportBodyDetail_LipsContext)
                        bodyDetailEditor._Teeth:call("restore(app.BodyDetailContext.TeethContext)", ExportBodyDetail_TeethContext)
                        bodyDetailEditor._Freckles:call("restore(app.BodyDetailContext.FrecklesContext)", ExportBodyDetail_FrecklesContext)
                        bodyDetailEditor._Nose:call("restore(app.BodyDetailContext.NoseContext)", ExportBodyDetail_NoseContext)

                        bodyDetailEditor._Dirt:call("restore(app.BodyDetailContext.DirtContext)", ExportBodyDetail_DirtContext)

                        bodyDetailEditor._Tattoos:call("restore(app.charaedit.ch000.Tattoos.SlotData[], System.Boolean)", ExportBodyDetail_TattoosContext:get_SlotDatas(), true)
                        bodyDetailEditor._Scars:call("restore(app.charaedit.ch000.Scars.SlotData[], System.Boolean)", ExportBodyDetail_ScarsContext:get_SlotDatas(), true)
                        isChanged = true



                    if isChanged then
                        local uiObj = uiTrans:get_GameObject()
                        local ui070406_01Obj = uiObj:call("getComponent(System.Type)", sdk.typeof("app.ui070406_01"))
                        ui070406_01Obj:reset()
                        -- log.debug("update !!! ")
                    end
                    isExported = false
                end
            end
        end

		if changed then
            -- hotkeys.update_hotkey_table(Config.Hotkeys)
            saveConfig() 
        end
		end
	end)

	if not ok then
		log.error("[CharacterCustomizationClone] UI error: " .. tostring(err))
	end

	if treeOpen then
        -- if imgui.button("Change") then
        --     local player = getPlayer()
        --     local human = player:get_Human()
        --     local jobC = human:get_JobChanger()
        --     -- generapp.Character.JobEnum
        --     local jobEnum = generate_enum("generapp.Character.JobEnum")
        --     jobC:requestChangeJob(jobEnum["Job02"])
        -- end
		imgui.tree_pop()
	end
end
)
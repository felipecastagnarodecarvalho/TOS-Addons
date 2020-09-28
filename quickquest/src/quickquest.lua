local addonName = 'QuickQuest';
local addonNameUpper = string.upper(addonName);
local addonNameLower = string.lower(addonName);

local author = 'TheReturn'
local authorUpper = string.upper(author);
local authorLower = string.lower(author);

local version = '1.1.0';

_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][authorUpper] = _G['ADDONS'][authorUpper] or {}
_G['ADDONS'][authorUpper][addonNameUpper] = _G['ADDONS'][authorUpper][addonNameUpper] or {}
local QuickQuest = _G['ADDONS'][authorUpper][addonNameUpper];

local ACUtil = require('acutil');
local CharbonAPI = require('charbonapi');

QuickQuest.SettingsFileLoc = string.format('../addons/%s/settings.json', addonNameLower);

QuickQuest.DefaultSettings = {}
QuickQuest.DefaultSettings.AddonEnabled = false;

local chatQuickQuestTextColor = '7733ff';

function QUICKQUEST_ON_INIT(addon, frame)
    		
	QuickQuest.Frame = frame
	QuickQuest.Addon = addon;

    ACUtil.slashCommand('/quickquest', QUICKQUEST_ENABLE_OR_DISABLE);
	ACUtil.slashCommand('/qq', QUICKQUEST_ENABLE_OR_DISABLE);
	
	QUICKQUEST_LOAD_SETTINGS();

	if QuickQuest:IsAddonEnabled() == true then
		QuickQuest:SetupEnabledHooks();
	end
end

function QUICKQUEST_ENABLE_OR_DISABLE()
	QUICKQUEST_LOAD_SETTINGS();
	QuickQuest:EnableOrDisableAddon();
end

function QUICKQUEST_LOAD_SETTINGS()
	if not QuickQuest.Loaded then	
		QuickQuest:LoadSettings()
		QuickQuest:SaveSettings()		
		session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] /quickquest or /qq to enable or disable quick quest addon.', true, 'System', chatQuickQuestTextColor);
		
		if QuickQuest:IsAddonEnabled() == true then
			session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] The QuickQuest addon is ENABLED.', true, 'System', chatQuickQuestTextColor);
		else
			session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] The QuickQuest addon is DISABLED.', true, 'System', chatQuickQuestTextColor);
		end
		
		QuickQuest.Loaded = true
	end
	
end

function QUICKQUEST_SELECT_DIALOG_HOOKED()
    local frame = ui.GetFrame('dialog');
	
	local textObj = GET_CHILD(frame, "textlist", "ui::CFlowText");

	local dialog_NewOpen = frame:GetUserIValue("DialogNewOpen");

	if dialog_NewOpen == 0 then
		if frame:IsVisible() == 1 then	
			if textObj:IsFlowed() == 1 and textObj:IsNextPage() == 1 then
				textObj:SetNextPage(0);
				ReserveScript('QUICKQUEST_SELECT_DIALOG_HOOKED()', 0.05);
			elseif textObj:IsFlowed() == 1 and textObj:IsNextPage() == 0 then
				textObj:SetNextPage(1);
				textObj:SetFlowSpeed(35);
				DIALOG_TEXT_VOICE(textObj);
				ReserveScript('QUICKQUEST_SELECT_DIALOG_HOOKED()', 0.05);				
			else
				local dialogType = frame:GetUserIValue("DialogType");
				
				if dialogType == 1 then
					frame:Invalidate();
					DIALOG_SEND_OK(frame);
				elseif dialogType == 2 then
					session.SetSelectDlgList();
					ui.OpenFrame('dialogselect');
				end
			end
		end
	else
		local illustFrame = ui.GetFrame('dialogillust');

		frame:Invalidate();
		frame:ShowWindow(0);
		illustFrame:ShowWindow(0);

		local dialog_NewOpenDuration = frame:GetUserValue("DialogNewOpenDuration");
		if dialog_NewOpenDuration == "None" then
			dialog_NewOpenDuration = 0;
		else
			dialog_NewOpenDuration = tonumber(dialog_NewOpenDuration);
		end

		frame:SetOpenDuration(dialog_NewOpenDuration);
		illustFrame:SetOpenDuration(dialog_NewOpenDuration);
	end
end

function QUICKQUEST_CLOSE_REWARD_FROM_QUEST()
	local frame = ui.GetFrame('questreward');
	frame:ShowWindow(0);
	control.DialogItemSelect(1);	
	frame = frame:GetTopParentFrame();
	frame:ShowWindow(0);
end

function MAKE_BASIC_REWARD_ITEM_CTRL_HOOKED(box, cls, y)
    local MySession		= session.GetMyHandle();
	local MyJobNum		= info.GetJob(MySession);
	local JobName		= GetClassString('Job', MyJobNum, 'ClassName');
	local index = 0
	local job = SCR_JOBNAME_MATCHING(JobName)
	local pc = GetMyPCObject();

	local isItem = 0;
	
	if cls.Success_ItemName1 ~= "None" or cls.Success_JobItem_Name1 ~= "None" then
		for i = 1 , MAX_QUEST_TAKEITEM do
			local propName = "Success_ItemName" .. i;
			if cls[propName] ~= "None" and cls[propName] ~= "Vis" then
				y = MAKE_ITEM_TAG_TEXT_CTRL(y, box, "reward_item", cls[propName], cls["Success_ItemCount" .. i], i);
				index = index + 1
				isItem = 1;
			end
		end

        for i = 1, 20 do
            if cls['Success_JobItem_Name'..i] ~= 'None' and cls['Success_JobItem_JobList'..i] ~= 'None' then
                local jobList = SCR_STRING_CUT(cls['Success_JobItem_JobList'..i])
                if SCR_Q_SUCCESS_REWARD_JOB_GENDER_CHECK(pc, jobList, job, pc.Gender, cls.Success_ChangeJob) == 'YES' then
                    local propName = 'Success_JobItem_Name'..i

                    y = MAKE_ITEM_TAG_TEXT_CTRL(y, box, "reward_item", cls[propName], cls["Success_JobItem_Count" .. i], index + i);
        			isItem = 1;
                end
            end
        end
	end

	local frame 	= ui.GetFrame('questreward');
	local cancelBtn = frame:GetChild('CancelBtn');
	local useBtn = frame:GetChild('UseBtn');
		
	if isItem == 0 then
		cancelBtn:ShowWindow(0);
		useBtn:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
        useBtn:SetOffset(0, 40);
		control.DialogItemSelect(100);
	else
		cancelBtn:ShowWindow(1);
		useBtn:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
        useBtn:SetOffset(-85, 40);
	end
	
	local selectExist = 0;
	local selected = 0;
	
	local cnt = box:GetChildCount();
	for i = 0 , cnt - 1 do
		local ctrlSet = box:GetChildByIndex(i);
		local name = ctrlSet:GetName();
		if string.find(name, "REWARD_") ~= nil then
			tolua.cast(ctrlSet, "ui::CControlSet");
			if ctrlSet:IsSelected() == 1 then
				selected = ctrlSet:GetValue();
			end
			selectExist = 1;
		end
	end

	if selectExist ~= 1 then
		ReserveScript('QUICKQUEST_CLOSE_REWARD_FROM_QUEST()', 0.15);
	end	

	return y;
end

function MAKE_BASIC_REWARD_ITEM_CTRL_DEFAULT(box, cls, y)

    local MySession		= session.GetMyHandle();
	local MyJobNum		= info.GetJob(MySession);
	local JobName		= GetClassString('Job', MyJobNum, 'ClassName');
	local index = 0
	local job = SCR_JOBNAME_MATCHING(JobName)
	local pc = GetMyPCObject();

	local isItem = 0;
	if cls.Success_ItemName1 ~= "None" or cls.Success_JobItem_Name1 ~= "None" then
		for i = 1 , MAX_QUEST_TAKEITEM do
			local propName = "Success_ItemName" .. i;
			if cls[propName] ~= "None" and cls[propName] ~= "Vis" then
				y = MAKE_ITEM_TAG_TEXT_CTRL(y, box, "reward_item", cls[propName], cls["Success_ItemCount" .. i], i);
				index = index + 1
				isItem = 1;
			end
		end

        for i = 1, 20 do
            if cls['Success_JobItem_Name'..i] ~= 'None' and cls['Success_JobItem_JobList'..i] ~= 'None' then
                local jobList = SCR_STRING_CUT(cls['Success_JobItem_JobList'..i])
                if SCR_Q_SUCCESS_REWARD_JOB_GENDER_CHECK(pc, jobList, job, pc.Gender, cls.Success_ChangeJob) == 'YES' then
                    local propName = 'Success_JobItem_Name'..i

                    y = MAKE_ITEM_TAG_TEXT_CTRL(y, box, "reward_item", cls[propName], cls["Success_JobItem_Count" .. i], index + i);
        			isItem = 1;
                end
            end
        end
	end

	local frame 	= ui.GetFrame('questreward');
	local cancelBtn = frame:GetChild('CancelBtn');
	local useBtn = frame:GetChild('UseBtn');

	if isItem == 0 then
		cancelBtn:ShowWindow(0);
		useBtn:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
        useBtn:SetOffset(0, 40);
	else
		cancelBtn:ShowWindow(1);
		useBtn:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
        useBtn:SetOffset(-85, 40);
        CONFIRM_QUEST_REWARD(frame);
	end

	return y;
end

function MAKE_SELECT_REWARD_CTRL_HOOKED(box, y, questCls, callFunc)
    if questCls.Success_SelectItemName1 == "None" then
		return y;
	end
	
    local questIES = GetClassByType("QuestProgressCheck", questCls.ClassID);
    local pc = GetMyPCObject();
    local sObj = GetSessionObject(pc, 'ssn_klapeda')
    
    local repeat_reward_item = {}
    local repeat_reward_achieve = {}
    local repeat_reward_achieve_point = {}
    local repeat_reward_exp = 0;
    local repeat_reward_npc_point = 0
    local repeat_reward_select = false
    local repeat_reward_select_use = false
        
    repeat_reward_item, repeat_reward_achieve, repeat_reward_achieve_point, repeat_reward_exp, repeat_reward_npc_point, repeat_reward_select, repeat_reward_select_use  = SCR_REPEAT_REWARD_CHECK(pc, questIES, questCls, sObj)
    if repeat_reward_select == false or (repeat_reward_select == true and repeat_reward_select_use == true) then
        if callFunc == 'DIALOGSELECT_QUEST_REWARD_ADD' then
            y = BOX_CREATE_RICHTEXT(box, "t_selreward", y, 20, ScpArgMsg("Auto_{@st54}BoSang_SeonTaeg"));
        else
        	y = BOX_CREATE_RICHTEXT(box, "t_selreward", y, 20, ScpArgMsg("Auto_{@st41}BoSang_SeonTaeg"));
        end
	
    	for i = 1, MAX_QUEST_SELECTITEM do
    		local propName = "Success_SelectItemName" .. i;
    		local itemName = questCls[propName];
    		if itemName == "None" then
    			break;
    		end

    		local itemCnt = questCls[ "Success_SelectItemCount" .. i];
    		y = CREATE_QUEST_REWARE_CTRL(box, y, i, itemName, itemCnt, callFunc);
    	end
    end
		
	local selectExist = 0;
	local selected = 0;
	local cnt = box:GetChildCount();
	for i = 0 , cnt - 1 do
		local ctrlSet = box:GetChildByIndex(i);
		local name = ctrlSet:GetName();
		if string.find(name, "REWARD_") ~= nil then
			tolua.cast(ctrlSet, "ui::CControlSet");
			if ctrlSet:IsSelected() == 1 then
				selected = ctrlSet:GetValue();
			end
			selectExist = 1;
		end
	end

	if selectExist ~= 1 then
		ReserveScript('QUICKQUEST_CLOSE_REWARD_FROM_QUEST()', 0.15);
	end

	return y;
end

function MAKE_SELECT_REWARD_CTRL_DEFAULT(box, y, questCls, callFunc)
    
	if questCls.Success_SelectItemName1 == "None" then
		return y;
	end
	
    local questIES = GetClassByType("QuestProgressCheck", questCls.ClassID);
    local pc = GetMyPCObject();
    local sObj = GetSessionObject(pc, 'ssn_klapeda')
    
    local repeat_reward_item = {}
    local repeat_reward_achieve = {}
    local repeat_reward_achieve_point = {}
    local repeat_reward_exp = 0;
    local repeat_reward_npc_point = 0
    local repeat_reward_select = false
    local repeat_reward_select_use = false
        
    
    repeat_reward_item, repeat_reward_achieve, repeat_reward_achieve_point, repeat_reward_exp, repeat_reward_npc_point, repeat_reward_select, repeat_reward_select_use  = SCR_REPEAT_REWARD_CHECK(pc, questIES, questCls, sObj)
    if repeat_reward_select == false or (repeat_reward_select == true and repeat_reward_select_use == true) then
        if callFunc == 'DIALOGSELECT_QUEST_REWARD_ADD' then
            y = BOX_CREATE_RICHTEXT(box, "t_selreward", y, 20, ScpArgMsg("Auto_{@st54}BoSang_SeonTaeg"));
        else
        	y = BOX_CREATE_RICHTEXT(box, "t_selreward", y, 20, ScpArgMsg("Auto_{@st41}BoSang_SeonTaeg"));
        end
    
    	for i = 1, MAX_QUEST_SELECTITEM do
    		local propName = "Success_SelectItemName" .. i;
    		local itemName = questCls[propName];
    		if itemName == "None" then
    			break;
    		end
    
    		local itemCnt = questCls[ "Success_SelectItemCount" .. i];
    		y = CREATE_QUEST_REWARE_CTRL(box, y, i, itemName, itemCnt, callFunc);
    	end
    end

	return y;
end

function DIALOG_ON_MSG_HOOKED(frame, msg, argStr, argNum)
	frame:Invalidate();

	local appsFrame = ui.GetFrame('apps');
	if appsFrame ~= nil and appsFrame:IsVisible() == 1 then
		ui.CloseUI(1);
	end

    ui.ShowChatFrames(0);
		
	if  msg == 'DIALOG_CHANGE_OK'  then
		DIALOG_TEXTVIEW(frame, msg, argStr, argNum);		
		frame:ShowWindow(1);
		frame:SetUserValue("DialogType", 1);
		ReserveScript('QUICKQUEST_SELECT_DIALOG_HOOKED()', 0.05);
	end

	if  msg == 'DIALOG_CHANGE_NEXT'  then
		DIALOG_TEXTVIEW(frame, msg, argStr, argNum);
		frame:ShowWindow(1);
		frame:SetUserValue("DialogType", 1);		
		ReserveScript('QUICKQUEST_SELECT_DIALOG_HOOKED()', 0.05);
	end

    if  msg == 'DIALOG_CHANGE_SELECT'  then
		DIALOG_TEXTVIEW(frame, msg, argStr, argNum);
		frame:ShowWindow(1);
		frame:SetUserValue("DialogType", 2);		
		ReserveScript('QUICKQUEST_SELECT_DIALOG_HOOKED()', 0.05);
    end

	if  msg == 'DIALOG_CLOSE'  then
        local textBoxObj	= frame:GetChild('textbox');
		local textObj		= frame:GetChild('textlist');
		textObj:ClearText();
        tolua.cast(textBoxObj, 'ui::CGroupBox')

		frame:ShowWindow(0);
		frame:SetUserValue("DialogType", 0);

		local uidirector = ui.GetFrame('directormode');
		
		if uidirector:IsVisible() == 1 then
			return;
		end

	end
end

function DIALOG_ON_MSG_DEFAULT(frame, msg, argStr, argNum)
	frame:Invalidate();

	local appsFrame = ui.GetFrame('apps');
	if appsFrame ~= nil and appsFrame:IsVisible() == 1 then
		ui.CloseUI(1);
	end

    ui.ShowChatFrames(0);

	if  msg == 'DIALOG_CHANGE_OK'  then

		DIALOG_TEXTVIEW(frame, msg, argStr, argNum)
		frame:ShowWindow(1);
		frame:SetUserValue("DialogType", 1);
	end

	if  msg == 'DIALOG_CHANGE_NEXT'  then
		DIALOG_TEXTVIEW(frame, msg, argStr, argNum)
		frame:ShowWindow(1);
		frame:SetUserValue("DialogType", 1);
	end

    if  msg == 'DIALOG_CHANGE_SELECT'  then
		DIALOG_TEXTVIEW(frame, msg, argStr, argNum);
		local showDialog = 1;
		if argNum > 0 then
			showDialog = 0;
		end
		frame:ShowWindow(showDialog);
		frame:SetUserValue("DialogType", 2);
    end

	if  msg == 'DIALOG_CLOSE'  then
        local textBoxObj	= frame:GetChild('textbox');
		local textObj		= frame:GetChild('textlist');
		textObj:ClearText();
        tolua.cast(textBoxObj, 'ui::CGroupBox')

		frame:ShowWindow(0);
		frame:SetUserValue("DialogType", 0);

		local uidirector = ui.GetFrame('directormode');
		if uidirector:IsVisible() == 1 then
			return;
		end

	end
end

function DIALOGSELECT_ON_MSG_HOOKED(frame, msg, argStr, argNum)
	
	frame:Invalidate();
	frame:SetOffset(frame:GetX(),frame:GetY())
	
    if  msg == 'DIALOG_CHANGE_SELECT'  then
		for i = 1, 11 do
			local childName = 'item' .. i .. 'Btn'
			local ItemBtn = frame:GetChild(childName);
			ItemBtn:ShowWindow(0);
		end

		local numberEdit = frame:GetChild('numberEdit');
		local numberHelp = frame:GetChild('numberHelp');
		numberHelp:ShowWindow(0);
		numberEdit:ShowWindow(0);

		DialogSelect_index = 0;
		DialogSelect_count = 0;

	elseif msg == 'DIALOG_NUMBER_RANGE' then
		local numberHelp = frame:GetChild('numberHelp');
		numberHelp:ShowWindow(1);
		argStr = math.floor(argStr);
		numberHelp:SetText(ScpArgMsg('Auto_ChoeSo_:_')..argStr..ScpArgMsg('Auto__ChoeDae_:_')..argNum);
		local numberEdit = frame:GetChild('numberEdit');
		tolua.cast(numberEdit, "ui::CEditControl");
		numberEdit:SetText(argStr);
		numberEdit:Resize(70, 40);
		numberEdit:ShowWindow(1);
		numberEdit:SetNumberMode(1);
		numberEdit:AcquireFocus();
		frame:Resize(400, 100);
		DialogSelect_Type = 1;
	elseif msg == 'DIALOG_TEXT_INPUT' then
		local numberEdit = frame:GetChild('numberEdit');
		tolua.cast(numberEdit, "ui::CEditControl");
		numberEdit:ClearText();
		numberEdit:Resize(360, 40);
		numberEdit:ShowWindow(1);
		numberEdit:SetNumberMode(0);
		numberEdit:AcquireFocus();
		frame:Resize(400, 100);
		DialogSelect_Type = 2;
		frame:SetOffset(frame:GetX(),math.floor(ui.GetSceneHeight()*0.7))
		
		local questreward = frame:GetChild('questreward');
		if questreward ~= nil then
    		questreward:ShowWindow(0)
    	end
	elseif  msg == 'DIALOG_ADD_SELECT'  then
		DialogSelect_index = 1;
				
		DialogSelect_Type = 0;
		DIALOGSELECT_ITEM_ADD(frame, msg, argStr, argNum);

		local questRewardBox = frame:GetChild('questreward');
		if questRewardBox ~= nil then
			argNum = argNum - 1;
		end
		
		DialogSelect_count = argNum;

		local ItemBtn = frame:GetChild('item1Btn');
		local itemWidth = ItemBtn:GetWidth()
		local x, y = GET_SCREEN_XY(ItemBtn,itemWidth/2.5);
	
		mouse.SetPos(x,y);		
		mouse.SetHidable(0);
	elseif  msg == 'DIALOG_CLOSE'  then
		ui.CloseFrame(frame:GetName());
		DialogSelect_index = 0;
		DialogSelect_count = 0;
		mouse.SetHidable(1);

	elseif msg == 'DIALOGSELECT_UP' then
		DialogSelect_index = DialogSelect_index - 1;
		if DialogSelect_index <= 0 then
			DialogSelect_index = DialogSelect_count;
		end
		DIALOGSELECT_ITEM_SELECT(frame);

	elseif msg == 'DIALOGSELECT_DOWN' then
		DialogSelect_index = DialogSelect_index + 1;
		if DialogSelect_index > DialogSelect_count then
			DialogSelect_index = 1;
		end
		DIALOGSELECT_ITEM_SELECT(frame);

	elseif msg == 'DIALOGSELECT_SELECT' then
		if DialogSelect_index ~= 0 then
			control.DialogSelect(DialogSelect_index);
		end
	end
end

function DIALOGSELECT_ON_MSG_DEFAULT(frame, msg, argStr, argNum)
	frame:SetMargin(0, 0, 0, 300);
	if  msg == 'DIALOG_CHANGE_SELECT' then
		local itemBtnCount = GET_DIALOGSELECT_ITEMBTN_COUNT(frame);
		for i = 1, itemBtnCount do
			local childName = 'item' .. i .. 'Btn'
			local ItemBtn = frame:GetChild(childName);
			ItemBtn:ShowWindow(0);
		end

		local numberEdit = frame:GetChild('numberEdit');
		local numberHelp = frame:GetChild('numberHelp');
		numberHelp:ShowWindow(0);
		numberEdit:ShowWindow(0);

		DialogSelect_index = 0;
		DialogSelect_count = 0;
	elseif msg == 'DIALOG_NUMBER_RANGE' then
		local numberHelp = frame:GetChild('numberHelp');
		numberHelp:ShowWindow(1);
		argStr = math.floor(argStr);
		numberHelp:SetText(ScpArgMsg('Auto_ChoeSo_:_')..argStr..ScpArgMsg('Auto__ChoeDae_:_')..argNum);
		local numberEdit = frame:GetChild('numberEdit');
		tolua.cast(numberEdit, "ui::CEditControl");
		numberEdit:SetText(argStr);
		numberEdit:Resize(70, 40);
		numberEdit:ShowWindow(1);
		numberEdit:SetNumberMode(1);
        numberEdit:SetMaxLen(16)
		numberEdit:AcquireFocus();
		frame:Resize(400, 100);

		DialogSelect_Type = 1;
	elseif msg == 'DIALOG_TEXT_INPUT' then
		local numberEdit = frame:GetChild('numberEdit');
		tolua.cast(numberEdit, "ui::CEditControl");
		numberEdit:ClearText();
		numberEdit:Resize(360, 40);
		numberEdit:ShowWindow(1);
		numberEdit:SetNumberMode(0);
        numberEdit:SetMaxLen(32)
		numberEdit:AcquireFocus();
		frame:Resize(400, 100);

		DialogSelect_Type = 2;
		local questreward = frame:GetChild('questreward');
		if questreward ~= nil then
    		questreward:ShowWindow(0)
    	end
	elseif  msg == 'DIALOG_ADD_SELECT'  then
		DialogSelect_Type = 0;
		DIALOGSELECT_ITEM_ADD(frame, msg, argStr, argNum);

		local ItemBtn = frame:GetChild('item1Btn');
		local itemWidth = ItemBtn:GetWidth();
		local x, y = GET_SCREEN_XY(ItemBtn, itemWidth / 2.5);		

		local questRewardBox = frame:GetChild('questreward');
		if questRewardBox ~= nil then
			argNum = argNum - 1;
			y = y - questRewardBox:GetY();
		end
		DialogSelect_count = argNum;
		DialogSelect_index = 1;

		mouse.SetPos(x,y);
		mouse.SetHidable(0);
	elseif  msg == 'DIALOG_CLOSE'  then
		DIALOGSELECT_FIX_WIDTH(frame, 540);
		frame:SetUserValue("QUESTFRAME_HEIGHT",  0);
		frame:SetUserValue("FIRSTORDER_MAXHEIGHT", 0);
		frame:SetUserValue("IsScroll", "NO");
		ui.CloseFrame(frame:GetName());
		DialogSelect_index = 0;
		DialogSelect_count = 0;
		mouse.SetHidable(1);	
	elseif msg == 'DIALOGSELECT_UP' then
		DialogSelect_index = DialogSelect_index - 1;
		if DialogSelect_index <= 0 then
			DialogSelect_index = DialogSelect_count;
		end
		DIALOGSELECT_ITEM_SELECT(frame);
	elseif msg == 'DIALOGSELECT_DOWN' then
		DialogSelect_index = DialogSelect_index + 1;
		if DialogSelect_index > DialogSelect_count then
			DialogSelect_index = 1;
		end
		DIALOGSELECT_ITEM_SELECT(frame);
	elseif msg == 'DIALOGSELECT_SELECT' then
		if DialogSelect_index ~= 0 then
			control.DialogSelect(DialogSelect_index);
		end
	end
end

function DIALOGSELECT_ITEM_ADD_HOOKED(frame, msg, argStr, argNum)
	
	if argNum == 1 then
		if DIALOGSELECT_QUEST_REWARD_ADD(frame, argStr) == 1 then
			frame:SetUserValue("FIRSTORDER_MAXHEIGHT", 1);			
			return;
		else
			local questRewardBox = frame:GetChild('questreward');
			if questRewardBox ~= nil then
				frame:RemoveChild('questreward');
			end
		end
	end
	
	local questRewardBox = frame:GetChild('questreward');
	if questRewardBox ~= nil then
		argNum = argNum - 1;
	end

	local controlName = 'item' .. argNum .. 'Btn'
	local ItemBtn = GET_CHILD_RECURSIVELY(frame, controlName);
	local ItemBtnCtrl = tolua.cast(ItemBtn, 'ui::CButton');
	local locationUI = DialogSelect_offsetY - argNum * 37 - 10;

	ItemBtnCtrl:SetGravity(ui.CENTER_HORZ, ui.TOP);
    
	if questRewardBox ~= nil then
		local width  = questRewardBox:GetWidth();
		local height = questRewardBox:GetHeight();
		local offset = 10 + ((argNum - 1) * 40);
		local offsetEx = 20 + ((argNum) * 40);
		local y = tonumber(frame:GetUserValue("QUESTFRAME_HEIGHT"));	
		local frameHeight = offset + y + 50;
		local maxHeight = ui.GetSceneHeight();
		
		questRewardBox:SetGravity(ui.CENTER_HORZ, ui.TOP);		
		questRewardBox:SetOffset(0, 50);
		
		control.DialogSelect(argNum);

		if frame:GetUserIValue("FIRSTORDER_MAXHEIGHT") == 1 then			
			if (y + (maxHeight - frame:GetY())) > (maxHeight) then	
				local frameMaxHeight = maxHeight/2;
				frameHeight = offset + frameMaxHeight + 50;
				frame:SetUserValue("IsScroll", "YES");		
				ItemBtnCtrl:SetOffset(0, questRewardBox:GetY() + questRewardBox:GetHeight() + 10);	
			else				
				frame:SetUserValue("IsScroll", "NO");
				ItemBtnCtrl:SetOffset(0, height + offset + 10 + ItemBtnCtrl:GetHeight());
			end;
			frame:SetUserValue("FIRSTORDER_MAXHEIGHT", 0);
		else
			if frame:GetUserValue("IsScroll") == "NO" then
				height = y + ItemBtnCtrl:GetHeight();	
				frameHeight = height + offset + 50;	
				ItemBtnCtrl:SetOffset(0, height + offset + 10);				
			else
				frameHeight = height + offsetEx + 50;	
				ItemBtnCtrl:SetOffset(0, height + offsetEx);
			end
		end

		frame:Resize(frame:GetWidth(), frameHeight + 10);
		frame:ShowWindow(1);	
		
	else
		ItemBtnCtrl:SetOffset(0, (argNum-1) * 40 + 40);
		frame:Resize(frame:GetWidth(), (argNum + 1) * 40 + 10);
	end

    ItemBtnCtrl:SetEventScript(ui.LBUTTONUP, 'control.DialogSelect(' .. argNum .. ')', true);
	ItemBtnCtrl:ShowWindow(1);
	ItemBtnCtrl:SetText('{s18}{b}{#2f1803}'..argStr);

	if ItemBtnCtrl:GetWidth() > tonumber(frame:GetUserConfig("MAX_WIDTH")) then
		DIALOGSELECT_FIX_WIDTH(frame, ItemBtnCtrl:GetWidth());
	end

	frame:Update();
end

function DIALOGSELECT_ITEM_ADD_DEFAULT(frame, msg, argStr, argNum)
	if argNum == 1 then
		if DIALOGSELECT_QUEST_REWARD_ADD(frame, argStr) == 1 then
			frame:SetUserValue("FIRSTORDER_MAXHEIGHT", 1);			
			return;
		else
			local questRewardBox = frame:GetChild('questreward');
			if questRewardBox ~= nil then
				frame:RemoveChild('questreward');
			end
		end
	end
	
	local questRewardBox = frame:GetChild('questreward');
	if questRewardBox ~= nil then
		argNum = argNum - 1;
	end

	local controlName = 'item' .. argNum .. 'Btn'
	local ItemBtn = GET_CHILD_RECURSIVELY(frame, controlName);
	local ItemBtnCtrl = tolua.cast(ItemBtn, 'ui::CButton');
	local locationUI = DialogSelect_offsetY - argNum * 37 - 10;

	ItemBtnCtrl:SetGravity(ui.CENTER_HORZ, ui.TOP);
    
	if questRewardBox ~= nil then
		local width  = questRewardBox:GetWidth();
		local height = questRewardBox:GetHeight();
		local offset = 10 + ((argNum - 1) * 40);
		local offsetEx = 20 + ((argNum) * 40);
		local y = tonumber(frame:GetUserValue("QUESTFRAME_HEIGHT"));	
		local frameHeight = offset + y + 50;
		local maxHeight = ui.GetSceneHeight();
		
		questRewardBox:SetGravity(ui.CENTER_HORZ, ui.TOP);		
		questRewardBox:SetOffset(0, 50);

		if frame:GetUserIValue("FIRSTORDER_MAXHEIGHT") == 1 then			
			if (y + (maxHeight - frame:GetY())) > (maxHeight) then	
				local frameMaxHeight = maxHeight/2;
				frameHeight = offset + frameMaxHeight + 50;
				frame:SetUserValue("IsScroll", "YES");		
				ItemBtnCtrl:SetOffset(0, questRewardBox:GetY() + questRewardBox:GetHeight() + 10);	
			else				
				frame:SetUserValue("IsScroll", "NO");
				ItemBtnCtrl:SetOffset(0, height + offset + 10 + ItemBtnCtrl:GetHeight());
			end;
			frame:SetUserValue("FIRSTORDER_MAXHEIGHT", 0);
		else
			if frame:GetUserValue("IsScroll") == "NO" then
				height = y + ItemBtnCtrl:GetHeight();	
				frameHeight = height + offset + 50;	
				ItemBtnCtrl:SetOffset(0, height + offset + 10);				
			else
				frameHeight = height + offsetEx + 50;	
				ItemBtnCtrl:SetOffset(0, height + offsetEx);
			end
		end

		frame:Resize(frame:GetWidth(), frameHeight + 10);
		frame:ShowWindow(1);	
		
	else
		ItemBtnCtrl:SetOffset(0, (argNum-1) * 40 + 40);
		frame:Resize(frame:GetWidth(), (argNum + 1) * 40 + 10);
	end

    ItemBtnCtrl:SetEventScript(ui.LBUTTONUP, 'control.DialogSelect(' .. argNum .. ')', true);
	ItemBtnCtrl:ShowWindow(1);
	ItemBtnCtrl:SetText('{s18}{b}{#2f1803}'..argStr);

	if ItemBtnCtrl:GetWidth() > tonumber(frame:GetUserConfig("MAX_WIDTH")) then
		DIALOGSELECT_FIX_WIDTH(frame, ItemBtnCtrl:GetWidth());
	end

	frame:Update();
end

function QuickQuest.EnableOrDisableAddon(self)
		
	if self:IsAddonEnabled() == false then	
		self:SetupEnabledHooks();
		session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] The addon has been enabled.', true, 'System', chatQuickQuestTextColor);
	elseif self:IsAddonEnabled() == true then
		ACUtil.setupHook(DIALOGSELECT_ON_MSG_DEFAULT,'DIALOGSELECT_ON_MSG');
		ACUtil.setupHook(DIALOG_ON_MSG_DEFAULT,'DIALOG_ON_MSG');
		ACUtil.setupHook(MAKE_BASIC_REWARD_ITEM_CTRL_DEFAULT,'MAKE_BASIC_REWARD_ITEM_CTRL');
		ACUtil.setupHook(DIALOGSELECT_ITEM_ADD_DEFAULT,'DIALOGSELECT_ITEM_ADD');
		ACUtil.setupHook(MAKE_SELECT_REWARD_CTRL_DEFAULT,'MAKE_SELECT_REWARD_CTRL');
		
		session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] The addon has been disabled.', true, 'System', chatQuickQuestTextColor);
	end
	
	self:ChangeAddonEnableSettingsStatus();
end

function QuickQuest.SetupEnabledHooks()
	ACUtil.setupHook(DIALOGSELECT_ON_MSG_HOOKED,'DIALOGSELECT_ON_MSG');
	ACUtil.setupHook(DIALOG_ON_MSG_HOOKED,'DIALOG_ON_MSG');
	ACUtil.setupHook(MAKE_BASIC_REWARD_ITEM_CTRL_HOOKED,'MAKE_BASIC_REWARD_ITEM_CTRL');
	ACUtil.setupHook(DIALOGSELECT_ITEM_ADD_HOOKED,'DIALOGSELECT_ITEM_ADD');
	ACUtil.setupHook(MAKE_SELECT_REWARD_CTRL_HOOKED,'MAKE_SELECT_REWARD_CTRL');	
end

function QuickQuest.IsAddonEnabled(self)
  return self.Settings.AddonEnabled;
end

function QuickQuest.ChangeAddonEnableSettingsStatus(self)
  self.Settings.AddonEnabled = not self.Settings.AddonEnabled;
  self:SaveSettings()
end

function QuickQuest.LoadSettings(self)

  local settings, err = ACUtil.loadJSON(self.SettingsFileLoc, nil, true);

  if err then
	session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] Could not load QuickQuest Settings ', true, 'System', chatQuickQuestTextColor);
  end

  if not settings then
    settings = self.DefaultSettings;
  end

  self.Settings = settings;
end

function QuickQuest.SaveSettings(self)
  return ACUtil.saveJSON(self.SettingsFileLoc, self.Settings);
end
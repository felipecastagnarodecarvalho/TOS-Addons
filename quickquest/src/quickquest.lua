local addonName = 'QuickQuest';
local addonNameUpper = string.upper(addonName);
local addonNameLower = string.lower(addonName);

local author = 'TheReturn'
local authorUpper = string.upper(author);
local authorLower = string.lower(author);

local version = '1.0.0';

_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][authorUpper] = _G['ADDONS'][authorUpper] or {}
_G['ADDONS'][authorUpper][addonNameUpper] = _G['ADDONS'][authorUpper][addonNameUpper] or {}
local QuickQuest = _G['ADDONS'][authorUpper][addonNameUpper];

local ACUtil = require('acutil');
local CharbonAPI = require('charbonapi');

-- local Settings = {};

QuickQuest.SettingsFileLoc = string.format('../addons/%s/settings.json', addonNameLower);

QuickQuest.DefaultSettings = {}
QuickQuest.DefaultSettings.AutoLoadEnabled = false;
QuickQuest.AddonEnabled = false;

local chatQuickQuestTextColor = '7733ff';

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

function QUICKQUEST_ON_INIT(addon, frame)
    		
	QuickQuest.Frame = frame
	QuickQuest.Addon = addon;

	QuickQuest:LoadSettings();

    ACUtil.slashCommand('/quickquest', QUICKQUEST_START);
	ACUtil.slashCommand('/qq', QUICKQUEST_START);

	ACUtil.slashCommand('/autoquickquest', QUICKQUEST_AUTO_START);
	ACUtil.slashCommand('/aqq', QUICKQUEST_AUTO_START);
	
	session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] /quickquest or /qq to enable or disable quick quest addon.', true, 'System', chatQuickQuestTextColor);
	session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] /autoquickquest or /aqq to auto enable quick quest addon.', true, 'System', chatQuickQuestTextColor);
	
	if QuickQuest:IsAutoLoadEnabled() == true then
		QUICKQUEST_START();
	end
end

function QUICKQUEST_START()
	QuickQuest:SetupAddon();
end

function QUICKQUEST_CLOSE_REWARD_FROM_QUEST()
	local frame = ui.GetFrame('questreward');
	frame:ShowWindow(0);
	
	control.DialogItemSelect(0);
	
	frame = frame:GetTopParentFrame();
	frame:ShowWindow(0);
end

function QUICKQUEST_AUTO_START()
	QuickQuest:ChangeAutoQuickQuickSetting();
	
	if QuickQuest:IsAutoLoadEnabled() == true then
		session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] auto enable quick quest addon is ON', true, 'System', chatQuickQuestTextColor);
	else
		session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] auto enable quick quest addon is OFF', true, 'System', chatQuickQuestTextColor);
	end
	
	if QuickQuest.AddonEnabled == false then
		QuickQuest:SetupAddon();
	end
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
	else
		cancelBtn:ShowWindow(1);
		useBtn:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
        useBtn:SetOffset(-85, 40);
        control.DialogItemSelect(100);
		ReserveScript('QUICKQUEST_CLOSE_REWARD_FROM_QUEST()', 0.2);
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
		ReserveScript('QUICKQUEST_SELECT_FIRST_DIALOG()', 0.05);
	end

	if  msg == 'DIALOG_CHANGE_NEXT'  then
		DIALOG_TEXTVIEW(frame, msg, argStr, argNum);
		frame:ShowWindow(1);
		frame:SetUserValue("DialogType", 1);
		ReserveScript('QUICKQUEST_SELECT_FIRST_DIALOG()', 0.05);
	end

    if  msg == 'DIALOG_CHANGE_SELECT'  then
		DIALOG_TEXTVIEW(frame, msg, argStr, argNum);
		frame:ShowWindow(1);
		frame:SetUserValue("DialogType", 2);		
		ReserveScript('QUICKQUEST_SELECT_FIRST_DIALOG()', 0.05);
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

		DialogSelect_index = 1;

		-- mouse.SetPos(x,y);
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
			-- questreward가 있는 경우, DIALOGSELECT_ITEM_ADD 함수에서 버튼의 layout_gravity가 ui.TOP으로 바뀌면서
			-- GET_SCRREN_XY의 반환 값에 questreward가 반영되어 계산됨.
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
		
		control.DialogSelect(1);

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

function QUICKQUEST_SELECT_FIRST_DIALOG()

    local frame = ui.GetFrame('dialog');
    DIALOG_ON_SKIP(frame);

    if frame:IsVisible() == 1 then
        ReserveScript('QUICKQUEST_SELECT_FIRST_DIALOG()', 0.05);
    end
end

function QuickQuest.SetupAddon(self)
	
	if self:IsAutoLoadEnabled() == true then
		self.AddonEnabled = true;
	end
	
	if self.AddonEnabled == false then
	
		ACUtil.setupHook(DIALOGSELECT_ON_MSG_HOOKED,'DIALOGSELECT_ON_MSG');
		ACUtil.setupHook(DIALOG_ON_MSG_HOOKED,'DIALOG_ON_MSG');
		ACUtil.setupHook(MAKE_BASIC_REWARD_ITEM_CTRL_HOOKED,'MAKE_BASIC_REWARD_ITEM_CTRL');
		ACUtil.setupHook(DIALOGSELECT_ITEM_ADD_HOOKED,'DIALOGSELECT_ITEM_ADD');	
		
		session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] This addon has been enabled.', true, 'System', chatQuickQuestTextColor);
					
		self.AddonEnabled = true;
	else
		ACUtil.setupHook(DIALOGSELECT_ON_MSG_DEFAULT,'DIALOGSELECT_ON_MSG');
		ACUtil.setupHook(DIALOG_ON_MSG_DEFAULT,'DIALOG_ON_MSG');
		ACUtil.setupHook(MAKE_BASIC_REWARD_ITEM_CTRL_DEFAULT,'MAKE_BASIC_REWARD_ITEM_CTRL');
		ACUtil.setupHook(DIALOGSELECT_ITEM_ADD_DEFAULT,'DIALOGSELECT_ITEM_ADD');
		
		session.ui.GetChatMsg():AddSystemMsg('[QuickQuest] This addon has been disabled.', true, 'System', chatQuickQuestTextColor);
		
		self.AddonEnabled = false;
	end
end

function QuickQuest.IsAutoLoadEnabled(self)
  return self.Settings.AutoLoadEnabled;
end

function QuickQuest.ChangeAutoQuickQuickSetting(self)
  self.Settings.AutoLoadEnabled = not self.Settings.AutoLoadEnabled;
  self:SaveSettings()
end
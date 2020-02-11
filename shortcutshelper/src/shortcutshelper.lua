local addonName = 'ShortcutsHelper'
local addonNameUpper = string.upper(addonName)

local author = 'TheReturn'
local authorUpper = string.upper(author)

local version = '1.0.0'

_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][authorUpper] = _G['ADDONS'][authorUpper] or {}
_G['ADDONS'][authorUpper][addonNameUpper] = _G['ADDONS'][authorUpper][addonNameUpper] or {}
local ShortcutsHelper = _G['ADDONS'][authorUpper][addonNameUpper]

function SHORTCUTSHELPER_ON_INIT(addon)
    addon:RegisterMsg('GAME_START', 'SHORTCUTSHELPER_RUN_UPDATE_SCRIPT');
end

function ShortcutsHelper.IsMarketButtonVisible(self)
  
    local mapProp = session.GetCurrentMapProp();
    local mapCls = GetClassByType('Map', mapProp.type);

    if IS_BEAUTYSHOP_MAP(mapCls) == true then
        
        local marketClassNameNPC = "";

        if mapCls.ClassName == 'c_Klaipe' then
            marketClassNameNPC = 'npc_combat_transport_section_1_market';
        elseif mapCls.ClassName == 'c_orsha' then
            marketClassNameNPC = 'orsha_tiliana';
        elseif mapCls.ClassName == 'c_fedimian' then
            marketClassNameNPC = 'npc_combat_transport_section_3_market';
        end
        
        local list, cnt = SelectObject(GetMyPCObject(), 20, "ALL", 1);
        for i = 1, cnt do
            if list[i].ClassName == marketClassNameNPC then
                return 1;
            end
        end

        return 0;
    else
        return 0;
    end
end

function ShortcutsHelper.IsWarehouseButtonVisible(self)

    local mapProp = session.GetCurrentMapProp();
    local mapCls = GetClassByType('Map', mapProp.type);

    if IS_BEAUTYSHOP_MAP(mapCls) == true then
      
        local mapProp = session.GetCurrentMapProp();
        local mapCls = GetClassByType('Map', mapProp.type);

        local warehouseClassNameNPC = "";
  
        if mapCls.ClassName == 'c_Klaipe' then
            warehouseClassNameNPC = 'npc_warehouse';
        elseif mapCls.ClassName == 'c_orsha' then
          warehouseClassNameNPC = 'npc_aisah';
        elseif mapCls.ClassName == 'c_fedimian' then
            warehouseClassNameNPC = 'npc_fedimian_storekeeper';
        end
            
        local list, cnt = SelectObject(GetMyPCObject(), 20, "ALL", 1);      
        for i = 1, cnt do
            if list[i].ClassName == warehouseClassNameNPC then
                return 1;
            end
        end
    
        return 0;
    else
        return 0;
    end
end

function SHORTCUTSHELPER_RUN_UPDATE_SCRIPT(addonFrame)

    local mapProp = session.GetCurrentMapProp();
    local mapCls = GetClassByType('Map', mapProp.type);

    if IS_BEAUTYSHOP_MAP(mapCls) == true then
        addonFrame:RunUpdateScript('ShortcutsHelper_UPDATE_SCRIPT', 0.5);
    end
end

--This checks if we are near the NPC, if we do so then we enable the button(s)
function ShortcutsHelper_UPDATE_SCRIPT(addonFrame)
    
    local marketButton = GET_CHILD_RECURSIVELY(addonFrame, 'marketButton');
    local personalWarehouseButton = GET_CHILD_RECURSIVELY(addonFrame, 'personalWarehouseButton');
    local accountWarehouseButton = GET_CHILD_RECURSIVELY(addonFrame, 'accountWarehouseButton');

    local isWarehouseButtonVisible = ShortcutsHelper:IsWarehouseButtonVisible();

    marketButton:ShowWindow(ShortcutsHelper:IsMarketButtonVisible());
    personalWarehouseButton:ShowWindow(isWarehouseButtonVisible);
    accountWarehouseButton:ShowWindow(isWarehouseButtonVisible);

    return 1;
end

function ShortcutsHelper_MARKET_BTN_CLICK()
    local marketFrame = ui.GetFrame('market')
    ON_OPEN_MARKET(marketFrame)
end

function ShortcutsHelper_PERSONAL_WAREHOUSE_BTN_CLICK()
    local framename = 'warehouse';
    local frame = ui.GetFrame(framename);
    ui.OpenFrame(framename);
    WAREHOUSE_OPEN(frame);
end

function ShortcutsHelper_ACCOUNT_WAREHOUSE_BTN_CLICK()
    local frame = ui.GetFrame('accountwarehouse');
    ON_OPEN_ACCOUNTWAREHOUSE(frame);
    ACCOUNTWAREHOUSE_OPEN(frame);
end


-- ============================================================
--  WotLK TR  ·  Engine_Quests.lua
--  Görev (Quest) + Gossip + Tutorial çeviri motoru — WotLK 3.3.5a (Warmane).
-- ============================================================

-- Global Variables
local QTR_version = "0.1.0-beta";
local QTR_name = UnitName("player");
local QTR_class= UnitClass("player");
local QTR_race = UnitRace("player");
local QTR_sex = UnitSex("player");     -- 1:nötr, 2:erkek, 3:kadın
local QTR_event="";
local QTR_waitTable = {};
local QTR_waitFrame = nil;
local QTR_MessOrig = {
      details    = "Description",
      objectives = "Objectives",
      rewards    = "Rewards",
      itemchoose1= "You will be able to choose one of these rewards:",
      itemchoose2= "Choose one of these rewards:",
      itemreceiv1= "You will also receive:",
      itemreceiv2= "You receiving the reward:",
      learnspell = "Learn Spell:",
      reqmoney   = "Required Money:",
      reqitems   = "Required items:",
      experience = "Experience:",
      currquests = "Current Quests",
      avaiquests = "Available Quests", };
local Original_Font1 = "Fonts\\MORPHEUS.ttf";
local Original_Font2 = "Fonts\\FRIZQT__.ttf";
local QTR_Interface2 = {
      mode1a     = "Çeviriyi doğrudan pencerede",
      mode1b     = "orijinal metnin yerine koy",
      mode2a     = "Çeviriyi ayrı bir pencerede",
      mode2b     = "orijinalin yanında göster",
      };
local Tut_ID = 0;
local Tut_race = string.gsub(strupper(QTR_race)," ","");
local Tut_class= string.gsub(strupper(QTR_class)," ","");
if (Tut_class == "DEATHKNIGHT") then
   Tut_race = "DEATHKNIGHT";
end
if not QTR then
   QTR = { };
end

-- Sınıf/ırk: Türkçe çeviriler sade $C / $R kullanır (numaralı/çekimli form yok).
-- Oyuncunun sınıf ve ırk adı client'tan (İngilizce) gelir, doğrudan kullanılır;
-- tüm 14 alan aynı değeri tutar (Türkçe için gramer çekimi gerekmez).
player_race  = { M1=QTR_race,  D1=QTR_race,  C1=QTR_race,  B1=QTR_race,  N1=QTR_race,  K1=QTR_race,  W1=QTR_race,  M2=QTR_race,  D2=QTR_race,  C2=QTR_race,  B2=QTR_race,  N2=QTR_race,  K2=QTR_race,  W2=QTR_race };
player_class = { M1=QTR_class, D1=QTR_class, C1=QTR_class, B1=QTR_class, N1=QTR_class, K1=QTR_class, W1=QTR_class, M2=QTR_class, D2=QTR_class, C2=QTR_class, B2=QTR_class, N2=QTR_class, K2=QTR_class, W2=QTR_class };




-- Cinsiyet biçimini uygular: YOUR_GENDER(erkek;kadın). gsub tabanlı olduğu
-- için bozuk token'da bile donmaz (eski elle ayrıştırıcı donabiliyordu).
function Spr_Gender(msg)
   if (msg == nil) then return ""; end
   return (string.gsub(msg, "YOUR_GENDER%((.-);(.-)%)", function(m, f)
      if (QTR_sex == 3) then return f; else return m; end
   end));
end


-- Verilen metnin Hash'ini (32-bit sayı) üretir.
-- DEĞİŞTİRME: Gossip/baloncuk eşleştirmesi bu hash'in birebir aynı değer
-- üretmesine bağlıdır (asallar ve çarpanlar aynen korunmalıdır).
local function StringHash(text)
  local counter = 1;
  local acc = 0;
  local len = string.len(text);
  for i = 1, len, 3 do
    counter = math.fmod(counter*8161, 4294967279);  -- 2^32 - 17: asal
    acc = (string.byte(text,i)*16776193);
    counter = counter + acc;
    acc = ((string.byte(text,i+1) or (len-i+256))*8372226);
    counter = counter + acc;
    acc = ((string.byte(text,i+2) or (len-i+256))*3932164);
    counter = counter + acc;
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: asal (döngüdekinden farklı)
end


function QTR_CheckVars()
  if (not QTR_PS) then
     QTR_PS = {};
  end
  if (not QTR_PC) then
     QTR_PC = {};
  end
  if (not QTR_SAVED) then
     QTR_SAVED = {};
  end
  if (not QTR_GOSSIP) then
     QTR_GOSSIP = {};
  end
  -- initialize check options
  if (not QTR_PS["active"]) then
     QTR_PS["active"] = "1";
  end
  if (not QTR_PS["mode"] ) then
     QTR_PS["mode"] = "1";
  end
  if (not QTR_PS["transtitle"] ) then
     QTR_PS["transtitle"] = "0";
  end
  if (not QTR_PS["size"] ) then
     QTR_PS["size"] = "1";
  end
  if (not QTR_PS["width"] ) then
     QTR_PS["width"] = "1";
  end

  -- set check buttons
  if (QTR_PS["size"] == "1") then
     QTR_SizeH = 1;
  else
     QTR_SizeH = 2;
     QTRFrame1:SetHeight(525);
     QTR_QuestDetail:SetHeight(430);
     QTR_ToggleButton2:SetText("^");
  end
  if (QTR_PS["width"] == "1") then
     QTR_SizeW = 1;
  else
     QTR_SizeW = 2;
     QTRFrame1:SetWidth(525);
     QTR_QuestDetail:SetWidth(495);
     QTR_QuestTitle:SetWidth(495);
     QTR_ToggleButton3:SetText("<");
  end
  if (not QTR_PS["gossip"] ) then
     QTR_PS["gossip"] = "1";
  end
  if (not QTR_PS["tutorial"] ) then
     QTR_PS["tutorial"] = "1";
  end
  if ( QTR_PS["isGetQuestID"] ) then
     isGetQuestID=QTR_PS["isGetQuestID"];
  end;
  QTR_GS = {};       -- orijinal metinler için tablo
end


function QTR_SetCheckButtonState()
  QTRCheckButton0:SetChecked(QTR_PS["active"]=="1");
  QTRCheckButton1:SetChecked(QTR_PS["mode"]=="1");
  QTRCheckButton2:SetChecked(QTR_PS["mode"]=="2");
  QTRCheckButton3:SetChecked(QTR_PS["transtitle"]=="1");
  QTRCheckButton4:SetChecked(QTR_PS["size"]=="1");
  QTRCheckButton5:SetChecked(QTR_PS["size"]=="2");
  QTRCheckButton6:SetChecked(QTR_PS["width"]=="1");
  QTRCheckButton7:SetChecked(QTR_PS["width"]=="2");
  QTRCheckButtonGossip:SetChecked(QTR_PS["gossip"]=="1");
  QTRCheckButtonTutorial:SetChecked(QTR_PS["tutorial"]=="1");
end


function QTR_BlizzardOptions()
  -- Create main frame for information text
  local QTROptions = CreateFrame("FRAME", "QTROptions");
  QTROptions:SetScript("OnShow", function(self) QTR_SetCheckButtonState() end);
  QTROptions.name = "Görevler";
  QTROptions.parent = "WotLK TR";
  InterfaceOptions_AddCategory(QTROptions);

  local QTROptionsHeader = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsHeader:SetFontObject(GameFontNormalLarge);
  QTROptionsHeader:SetJustifyH("LEFT");
  QTROptionsHeader:SetJustifyV("TOP");
  QTROptionsHeader:ClearAllPoints();
  QTROptionsHeader:SetPoint("TOPLEFT", 16, -16);
  QTROptionsHeader:SetText("Görevler · sürüm "..QTR_version.." ("..QTR_base..")");

  local QTRCheckButton0 = CreateFrame("CheckButton", "QTRCheckButton0", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton0:SetPoint("TOPLEFT", QTROptionsHeader, "BOTTOMLEFT", 0, -10);
  QTRCheckButton0:SetScript("OnClick", function(self) if (QTR_PS["active"]=="1") then QTR_PS["active"]="0" else QTR_PS["active"]="1" end; end);
  QTRCheckButton0Text:SetFont(QTR_Font2, 13);
  QTRCheckButton0Text:SetText(QTR_Interface.active);

  local QTROptionsMode0 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsMode0:SetFontObject(GameFontWhite);
  QTROptionsMode0:SetJustifyH("LEFT");
  QTROptionsMode0:SetJustifyV("TOP");
  QTROptionsMode0:ClearAllPoints();
  QTROptionsMode0:SetPoint("TOPLEFT", QTRCheckButton0, "BOTTOMLEFT", 20, -5);
  QTROptionsMode0:SetFont(QTR_Font2, 13);
  QTROptionsMode0:SetText(QTR_Interface.mode);

  local QTRCheckButton1 = CreateFrame("CheckButton", "QTRCheckButton1", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton1:SetPoint("TOPLEFT", QTROptionsMode0, "BOTTOMLEFT", 0, -5);
  QTRCheckButton1:SetScript("OnClick", function(self) if (QTR_PS["mode"]=="2") then QTR_PS["mode"]="1" else QTR_PS["mode"]="2" end; QTRCheckButton2:SetChecked(QTR_PS["mode"]=="2"); end);
  QTRCheckButton1Text:SetFont(QTR_Font2, 13);
  QTRCheckButton1Text:SetText(QTR_Interface2.mode1a);

  local QTROptionsText1b = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsText1b:SetFontObject(GameFontNormal);
  QTROptionsText1b:SetJustifyH("LEFT");
  QTROptionsText1b:SetJustifyV("TOP");
  QTROptionsText1b:ClearAllPoints();
  QTROptionsText1b:SetPoint("TOPLEFT", QTRCheckButton1, "BOTTOMLEFT", 30, 5);
  QTROptionsText1b:SetFont(QTR_Font2, 13);
  QTROptionsText1b:SetText(QTR_Interface2.mode1b);

  local QTROptionsMode1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsMode1:SetFontObject(GameFontWhite);
  QTROptionsMode1:SetJustifyH("LEFT");
  QTROptionsMode1:SetJustifyV("TOP");
  QTROptionsMode1:ClearAllPoints();
  QTROptionsMode1:SetPoint("TOPLEFT", QTROptionsText1b, "BOTTOMLEFT", 0, -10);
  QTROptionsMode1:SetFont(QTR_Font2, 13);
  QTROptionsMode1:SetText(QTR_Interface.options1);

  local QTRCheckButton3 = CreateFrame("CheckButton", "QTRCheckButton3", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton3:SetPoint("TOPLEFT", QTROptionsMode1, "BOTTOMLEFT", 0, 0);
  QTRCheckButton3:SetScript("OnClick", function(self) if (QTR_PS["transtitle"]=="0") then QTR_PS["transtitle"]="1" else QTR_PS["transtitle"]="0" end; end);
  QTRCheckButton3Text:SetFont(QTR_Font2, 13);
  QTRCheckButton3Text:SetText(QTR_Interface.transtitle);

  local QTRCheckButton2 = CreateFrame("CheckButton", "QTRCheckButton2", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton2:SetPoint("TOPLEFT", QTRCheckButton3, "BOTTOMLEFT", -30, -5);
  QTRCheckButton2:SetScript("OnClick", function(self) if (QTR_PS["mode"]=="1") then QTR_PS["mode"]="2" else QTR_PS["mode"]="1" end; QTRCheckButton1:SetChecked(QTR_PS["mode"]=="1"); end);
  QTRCheckButton2Text:SetFont(QTR_Font2, 13);
  QTRCheckButton2Text:SetText(QTR_Interface2.mode2a);

  local QTROptionsText2b = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsText2b:SetFontObject(GameFontNormal);
  QTROptionsText2b:SetJustifyH("LEFT");
  QTROptionsText2b:SetJustifyV("TOP");
  QTROptionsText2b:ClearAllPoints();
  QTROptionsText2b:SetPoint("TOPLEFT", QTRCheckButton2, "BOTTOMLEFT", 30, 5);
  QTROptionsText2b:SetFont(QTR_Font2, 13);
  QTROptionsText2b:SetText(QTR_Interface2.mode2b);

  local QTROptionsMode2 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsMode2:SetFontObject(GameFontWhite);
  QTROptionsMode2:SetJustifyH("LEFT");
  QTROptionsMode2:SetJustifyV("TOP");
  QTROptionsMode2:ClearAllPoints();
  QTROptionsMode2:SetPoint("TOPLEFT", QTROptionsText2b, "BOTTOMLEFT", 0, -10);
  QTROptionsMode2:SetFont(QTR_Font2, 13);
  QTROptionsMode2:SetText(QTR_Interface.options2);

  local QTRCheckButton4 = CreateFrame("CheckButton", "QTRCheckButton4", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton4:SetPoint("TOPLEFT", QTROptionsMode2, "BOTTOMLEFT", 0, 0);
  QTRCheckButton4:SetScript("OnClick", function(self) QTR_ChangeFrameHeight(); QTRCheckButton5:SetChecked(QTR_PS["size"]=="2"); end);
  QTRCheckButton4Text:SetFont(QTR_Font2, 13);
  QTRCheckButton4Text:SetText(QTR_Interface.height1);

  local QTRCheckButton5 = CreateFrame("CheckButton", "QTRCheckButton5", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton5:SetPoint("TOPLEFT", QTRCheckButton4, "BOTTOMLEFT", 0, 8);
  QTRCheckButton5:SetScript("OnClick", function(self) QTR_ChangeFrameHeight(); QTRCheckButton4:SetChecked(QTR_PS["size"]=="1"); end);
  QTRCheckButton5Text:SetFont(QTR_Font2, 13);
  QTRCheckButton5Text:SetText(QTR_Interface.height2);

  local QTRCheckButton6 = CreateFrame("CheckButton", "QTRCheckButton6", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton6:SetPoint("TOPLEFT", QTRCheckButton5, "BOTTOMLEFT", 0, 0);
  QTRCheckButton6:SetScript("OnClick", function(self) QTR_ChangeFrameWidth(); QTRCheckButton7:SetChecked(QTR_PS["width"]=="2"); end);
  QTRCheckButton6Text:SetFont(QTR_Font2, 13);
  QTRCheckButton6Text:SetText(QTR_Interface.width1);

  local QTRCheckButton7 = CreateFrame("CheckButton", "QTRCheckButton7", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton7:SetPoint("TOPLEFT", QTRCheckButton6, "BOTTOMLEFT", 0, 8);
  QTRCheckButton7:SetScript("OnClick", function(self) QTR_ChangeFrameWidth(); QTRCheckButton6:SetChecked(QTR_PS["width"]=="1"); end);
  QTRCheckButton7Text:SetFont(QTR_Font2, 13);
  QTRCheckButton7Text:SetText(QTR_Interface.width2);

  local QTRCheckButtonGossip = CreateFrame("CheckButton", "QTRCheckButtonGossip", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButtonGossip:SetPoint("TOPLEFT", QTRCheckButton7, "BOTTOMLEFT", -50, -10);
  QTRCheckButtonGossip:SetScript("OnClick", function(self) if (QTR_PS["gossip"]=="1") then QTR_PS["gossip"]="0" else QTR_PS["gossip"]="1" end; end);
  QTRCheckButtonGossipText:SetFont(QTR_Font2, 13);
  QTRCheckButtonGossipText:SetText("Konuşmaları Çevir (Gossip)");

  local QTRCheckButtonTutorial = CreateFrame("CheckButton", "QTRCheckButtonTutorial", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButtonTutorial:SetPoint("TOPLEFT", QTRCheckButtonGossip, "BOTTOMLEFT", 0, -5);
  QTRCheckButtonTutorial:SetScript("OnClick", function(self) if (QTR_PS["tutorial"]=="1") then QTR_PS["tutorial"]="0" else QTR_PS["tutorial"]="1" end; end);
  QTRCheckButtonTutorialText:SetFont(QTR_Font2, 13);
  QTRCheckButtonTutorialText:SetText("İpuçlarını Çevir (Tutorial)");

-- (web sitesi kutusu kaldırıldı)
end


function QTR_OnLoad1()
  QTR.frame1 = CreateFrame("Frame");
  QTR.frame1:RegisterEvent("ADDON_LOADED");
  QTR.frame1:RegisterEvent("QUEST_LOG_UPDATE");
  QTR.frame1:SetScript("OnEvent", function(self, event, ...) return QTR[event] and QTR[event](QTR, event, ...) end);
  QuestLogDetailScrollFrame:SetScript("OnShow", QTR_ShowAndUpdateQuestInfo);
  QuestLogDetailScrollFrame:SetScript("OnHide", QTR_HideQuestInfo);

  QTR_QuestTitle:SetFont(QTR_Font2, 17);
  QTR_QuestDetail:SetFont(QTR_Font2, 14);
  QTRFrame1:ClearAllPoints();
  QTRFrame1:SetPoint("TOPLEFT", QuestLogFrame, "TOPRIGHT", -3, -12);

  -- small button in QuestLogFrame
  QTR_ToggleButton1 = CreateFrame("Button",nil, QuestLogFrame, "UIPanelButtonTemplate");
  QTR_ToggleButton1:SetWidth(35);
  QTR_ToggleButton1:SetHeight(18);
  QTR_ToggleButton1:SetText("QTR");
  QTR_ToggleButton1:Show();
  QTR_ToggleButton1:ClearAllPoints();
  QTR_ToggleButton1:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 620, -15);
  QTR_ToggleButton1:SetScript("OnClick", QTR_ToggleVisibility);

  -- button for ChangeFrameHeight
  QTR_ToggleButton2 = CreateFrame("Button",nil, QTRFrame1, "UIPanelButtonTemplate");
  QTR_ToggleButton2:SetWidth(15);
  QTR_ToggleButton2:SetHeight(22);
  QTR_ToggleButton2:SetText("v");
  QTR_ToggleButton2:Show();
  QTR_ToggleButton2:ClearAllPoints();
  QTR_ToggleButton2:SetPoint("BOTTOMLEFT", QTRFrame1, "BOTTOMRIGHT", -40, 9);
  QTR_ToggleButton2:SetScript("OnClick", QTR_ChangeFrameHeight);

  -- button for ChangeFrameWidth
  QTR_ToggleButton3 = CreateFrame("Button",nil, QTRFrame1, "UIPanelButtonTemplate");
  QTR_ToggleButton3:SetWidth(15);
  QTR_ToggleButton3:SetHeight(22);
  QTR_ToggleButton3:SetText(">");
  QTR_ToggleButton3:Show();
  QTR_ToggleButton3:ClearAllPoints();
  QTR_ToggleButton3:SetPoint("BOTTOMLEFT", QTRFrame1, "BOTTOMRIGHT", -25, 9);
  QTR_ToggleButton3:SetScript("OnClick", QTR_ChangeFrameWidth);

  hooksecurefunc("QuestLogTitleButton_OnClick", function() QTR_UpdateQuestInfo() end);

   -- QuestMapDetailsScrollFrame içinde gossip HASH no'lu buton
   QTR_ToggleButtonGS = CreateFrame("Button",nil, GossipFrame, "UIPanelButtonTemplate");
   QTR_ToggleButtonGS:SetWidth(230);
   QTR_ToggleButtonGS:SetHeight(20);
   QTR_ToggleButtonGS:SetText("Gossip-Hash=?");
   QTR_ToggleButtonGS:Show();
   QTR_ToggleButtonGS:ClearAllPoints();
   QTR_ToggleButtonGS:SetPoint("TOPLEFT", GossipFrame, "TOPLEFT", 70, -50);
   QTR_ToggleButtonGS:SetScript("OnClick", GS_ON_OFF);
end


function QTR_OnLoad2()
  QTR.frame2 = CreateFrame("Frame");
  QTR.frame2:RegisterEvent("QUEST_GREETING");
  QTR.frame2:RegisterEvent("QUEST_DETAIL");
  QTR.frame2:RegisterEvent("QUEST_PROGRESS");
  QTR.frame2:RegisterEvent("QUEST_COMPLETE");
  QTR.frame2:RegisterEvent("WORLD_MAP_UPDATE");
  QTR.frame2:RegisterEvent("GOSSIP_SHOW");
  QTR.frame2:SetScript("OnEvent", function(self, event, ...) return QTR[event] and QTR[event](QTR, event, ...) end);
  QTR_QuestTitle2:SetFont(QTR_Font2, 17);
  QTR_QuestDetail2:SetFont(QTR_Font2, 14);
  QTR_QuestWarning2:SetFont(QTR_Font2, 12);
  QTRFrame2:ClearAllPoints();
  QTRFrame2:SetPoint("TOPLEFT", QuestFrame, "TOPRIGHT", -31, -19);
  QuestFrame:SetScript("OnHide", QTR_Frame2Close);
  hooksecurefunc("WorldMapQuestFrame_OnMouseUp", function() QTR_WorldMapQuestFrameOnMouseUp() end);
  TutorialFrame:HookScript("OnShow", Tut_onTutorialShow);
  TutorialFrameNextButton:HookScript("OnClick", Tut_onTutorialShow);
  TutorialFramePrevButton:HookScript("OnClick", Tut_onTutorialShow);
end


function QTR_WorldMapQuestFrameOnMouseUp()
  QTR_event = "WORLD_MAP_OnMouseUp";
  QTR_OnEvent2();
end


function QTR_SlashCommand(msg)
  InterfaceOptionsFrame_OpenToCategory(QTROptions);
  InterfaceOptionsFrame_OpenToCategory(QTROptions);
  RestoreOriginalFonts();
end


function QTR:ADDON_LOADED(_, addon)
  if (addon == "WOTLKTR") then
     SlashCmdList["WOWTR_QUESTS"] = function(msg) QTR_SlashCommand(msg); end
     SLASH_WOWTR_QUESTS1 = "/wtroptions";
     SLASH_WOWTR_QUESTS2 = "/qtr";
     QTR_CheckVars();
     QTR_BlizzardOptions();
     if (DEFAULT_CHAT_FRAME) then
         DEFAULT_CHAT_FRAME:AddMessage("|cffffff00WotLK TR ver. "..QTR_version.." - " .. QTR_Messages.loaded);
     else
         UIErrorsFrame:AddMessage("|cffffff00WotLK TR ver. "..QTR_version.." - " .. QTR_Messages.loaded, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
     end
     self.frame1:UnregisterEvent("ADDON_LOADED");
     self.ADDON_LOADED = nil;
     QTR_Messages.itemchoose1 = Spr_Gender(QTR_Messages.itemchoose1);
     if (not isGetQuestID) then
        DetectEmuServer();
     end;
  end
end


function QTR:QUEST_LOG_UPDATE()
  if (QTRFrame1:IsVisible()) then
     QTR_UpdateQuestInfo();
  end
end


function QTR:WORLD_MAP_UPDATE()
  if ( WorldMapFrame:IsVisible() ) then
     if (QTR_PS["active"]=="1") then
        if (QTR_PS["mode"]=="1") then
           if ( WorldMapQuestShowObjectives:GetChecked() ) then
              QTR_event = "WORLD_MAP_UPDATE";
              QTR_OnEvent2();
           end
	end
     end
  end
end


function DetectEmuServer()
  QTR_PS["isGetQuestID"]="0";
  isGetQuestID="0";
  -- GetQuestID() bazı emülatör/özel sunucularda çalışmaz (ilk açılışta lua hatası verebilir).
  if ( GetQuestID() ) then
     QTR_PS["isGetQuestID"]="1";
     isGetQuestID="1";
  end
end


function QTR_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(QTR_waitFrame == nil) then
    QTR_waitFrame = CreateFrame("Frame","QTR_WaitFrame", UIParent);
    QTR_waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #QTR_waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(QTR_waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(QTR_waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(QTR_waitTable,{delay,func,{...}});
  return true;
end


function QTR:QUEST_GREETING()
  if (QTR_PS["active"]=="1" and QTR_PS["mode"]=="1") then
     CurrentQuestsText:SetText(QTR_Messages.currquests);
     CurrentQuestsText:SetFont(QTR_Font1, 18);
     AvailableQuestsText:SetText(QTR_Messages.avaiquests);
     AvailableQuestsText:SetFont(QTR_Font1, 18);
  else
     CurrentQuestsText:SetText(QTR_MessOrig.currquests);
     CurrentQuestsText:SetFont(Original_Font1, 18);
     AvailableQuestsText:SetText(QTR_MessOrig.avaiquests);
     AvailableQuestsText:SetFont(Original_Font1, 18);
  end
end


function QTR:QUEST_DETAIL()
  QTR_event = "QUEST_DETAIL";
  if (isGetQuestID=="0") then
     if ( not QTR_wait(0.5,QTR_OnEvent2) ) then
        QTR_OnEvent2();
     end
  else
     QTR_OnEvent2();
  end
end


function QTR:QUEST_PROGRESS()
  QTR_event = "QUEST_PROGRESS";
  QTR_OnEvent2();
end


function QTR:QUEST_COMPLETE()
  QTR_event = "QUEST_COMPLETE";
  QTR_OnEvent2();
end


function QTR:GOSSIP_SHOW()
  if (QTR_PS["gossip"] == "1") then
     QTR_Gossip_Show();
  end
end


function QTR_OnEvent2()
  local q_ID = 0;
  local q_title = GetTitleText();
  local q_i = 1;

  if ( WorldMapFrame:IsVisible() ) then
    for i = 1, MAX_NUM_QUESTS do
      questFrame = _G["WorldMapQuestFrame"..i];
      if ( not questFrame ) then
        break
      elseif ( WORLDMAP_SETTINGS.selectedQuest==questFrame ) then
        q_title=questFrame.title:GetText();
        break;
      end
    end
  end

  -- search in QuestLog
  while GetQuestLogTitle(q_i) do
    local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(q_i)
    if ( not isHeader ) then
       if ( q_title == questTitle ) then
          q_ID=questID;
          break;
       end
    end
    q_i = q_i + 1;
  end
  RestoreOriginalFonts();
  if ( QTR_PS["active"]=="1" )then
     QTR_QuestID2:SetText("");
     QTR_QuestTitle2:SetText(q_title);
     QTR_QuestDetail2:SetText(QTR_Messages.missing);
     QTR_QuestWarning2:SetText("");
     -- not exist in QuestLog ?
     if ( q_ID == 0 ) then
        if ( isGetQuestID=="1" ) then
           q_ID = GetQuestID();
        end
        if ( q_ID == 0 ) then
           if (QTR_QuestList[q_title]) then
              local q_lists=QTR_QuestList[q_title];
              q_i=string.find(q_lists, ",");
              if ( string.find(q_lists, ",")==nil ) then
                 -- only 1 questID to this title
                 q_ID=tonumber(q_lists);
              else
                 -- multiple questIDs - get first, available (not completed) questID from QuestLists
                 local QTR_table=QTR_split(q_lists, ",");
                 local QTR_multiple = "";
                 local QTR_Center="";
                 for ii,vv in ipairs(QTR_table) do
                    if (not QTR_PC[vv]) then
                       if (QTR_Center=="") then
                           QTR_Center=vv;
                       else
                           QTR_multiple = QTR_multiple .. ", " .. vv;
                       end
                    end
                 end
                 if ( string.len(QTR_Center)>0 ) then
                    q_ID=tonumber(QTR_Center);
                    if ( string.len(QTR_multiple)>0 ) then
                       QTR_multiple = " (" .. string.sub(QTR_multiple, 3) .. ")";
                       QTR_QuestWarning2:SetText(QTR_Messages.multipleID .. QTR_multiple);
                    end
                 end
              end
           end
        end
     end
     if ( q_ID > 0 ) then
        local str_id = tostring(q_ID);
        QTR_QuestID2:SetText("QuestID: " .. str_id);
        QTR_QuestTitle2:SetText(q_title);
        if (QTR_QuestData[str_id]) then
           -- display only, if translation exists
	   if (QTR_PS["mode"]=="2") then
              QTR_ShowFrame2(QTR_event, str_id);
	   else
              QTR_ChangeText_InEvent(QTR_event, str_id);
           end
        else
           QTR_SAVED[str_id.." TITLE"]=GetTitleText();               -- save original title to future translation
           if (QTR_event=="QUEST_DETAIL") then
              QTR_SAVED[str_id.." DESCRIPTION"]=GetQuestText();      -- save original text to future translation
              QTR_SAVED[str_id.." OBJECTIVE"]=GetObjectiveText();    -- save original text to future translation
           end
           if (QTR_event=="QUEST_PROGRESS") then
              QTR_SAVED[str_id.." PROGRESS"]=GetProgressText();      -- save original text to future translation
           end
           if (QTR_event=="QUEST_COMPLETE") then
              QTR_SAVED[str_id.." COMPLETE"]=GetRewardText();        -- save original text to future translation
           end
           QTRFrame2:Hide();
        end
     end
  end
  if (QTR_event == "QUEST_COMPLETE") then
     if ( q_ID > 0) then
        local str_id = tostring(q_ID);
        QTR_PC[str_id]="OK";
     end
  end
end


function QTR_ShowFrame2(eventStr, qid)
  QTR_QuestID2:SetText("QuestID: " .. qid);
  QTR_QuestDetail2:SetText(QTR_Messages.missing);
  if (QTR_QuestData[qid]) then
     QTR_QuestTitle2:SetText(QTR_ExpandUnitInfo(QTR_QuestData[qid]["Title"]));
     local QTR_text = "";
     if (eventStr == "QUEST_DETAIL") then
        if (QTR_QuestData[qid]["Description"]) then
           QTR_text = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Description"]);
        end
        local QTR_text2 = "";
        if (QTR_QuestData[qid]["Objectives"]) then
           QTR_text2 = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Objectives"]);
        end
        QTR_text = QTR_text .. "\n\n" .. QTR_Messages.objectives .. "\n" .. QTR_text2;
     end
     if (eventStr == "QUEST_PROGRESS") then
        if (QTR_QuestData[qid]["Progress"]) then
           QTR_text = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Progress"]);
        end
     end
     if (eventStr == "QUEST_COMPLETE") then
        if (QTR_QuestData[qid]["Completion"]) then
           QTR_text = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Completion"]);
        end
     end
     QTR_QuestDetail2:SetText(QTR_text);
     QTRFrame2:ClearAllPoints();
     QTRFrame2:SetPoint("TOPLEFT", QuestFrame, "TOPRIGHT", -31, -19);
     if ( QuestNPCModel ) then
        if ( QuestNPCModel:IsVisible() ) then
           QTRFrame2:SetPoint("TOPLEFT", QuestNPCModel, "TOPRIGHT", 0, 42);
        end
     end
     QTRFrame2:Show();
  end
end


function QTR_Frame2Close()
  QTRFrame2:Hide();
  QuestFrame_OnHide();
end


function QTR_split(str, c)
  local aCount = 0;
  local array = {};
  local a = string.find(str, c);
  while a do
     aCount = aCount + 1;
     array[aCount] = string.sub(str, 1, a-1);
     str=string.sub(str, a+1);
     a = string.find(str, c);
  end
  aCount = aCount + 1;
  array[aCount] = str;
  return array;
end


function QTR_findlast(source, char)
  if (not source) then
     return 0;
  end
  local lastpos = 0;
  local byte_char = string.byte(char);
  for i=1, #source do
     if (string.byte(source,i)==byte_char) then
        lastpos = i;
     end
  end
  return lastpos;
end


function QTR_ChangeFrameHeight()
  -- normal height of Frame = 425, quest detail = 350
  if (QTR_SizeH == 1) then
     QTRFrame1:SetHeight(525);
     QTR_QuestDetail:SetHeight(430);
     QTR_ToggleButton2:SetText("^");
     QTR_SizeH = 2;
     QTR_PS["size"] = "2";
  else
     QTRFrame1:SetHeight(425);
     QTR_QuestDetail:SetHeight(350);
     QTR_ToggleButton2:SetText("v");
     QTR_SizeH = 1;
     QTR_PS["size"] = "1";
  end
end


function QTR_ChangeFrameWidth()
  -- normal width of Frame = 350, quest detail = 320
  if (QTR_SizeW == 1) then
     QTRFrame1:SetWidth(525);
     QTR_QuestDetail:SetWidth(495);
     QTR_QuestTitle:SetWidth(495);
     QTR_ToggleButton3:SetText("<");
     QTR_SizeW = 2;
     QTR_PS["width"] = "2";
  else
     QTRFrame1:SetWidth(350);
     QTR_QuestDetail:SetWidth(320);
     QTR_QuestTitle:SetWidth(320);
     QTR_ToggleButton3:SetText(">");
     QTR_SizeW = 1;
     QTR_PS["width"] = "1";
  end
end


function QTR_OnMouseDown1()
  -- start moving the window
  QTRFrame1:StartMoving();
end


function QTR_OnMouseUp1()
  -- stop moving the window
  QTRFrame1:StopMovingOrSizing();
end


function QTR_OnMouseDown2()
  -- start moving the window
  QTRFrame2:StartMoving();
end


function QTR_OnMouseUp2()
  -- stop moving the window
  QTRFrame2:StopMovingOrSizing();
end


function RestoreOriginalFonts()
  QuestInfoTitleHeader:SetFont(Original_Font1, 18);
  QuestInfoDescriptionHeader:SetText(QTR_MessOrig.details);
  QuestInfoDescriptionHeader:SetFont(Original_Font1, 18);
  QuestInfoDescriptionText:SetFont(Original_Font2, 13);
  QuestInfoObjectivesHeader:SetText(QTR_MessOrig.objectives);
  QuestInfoObjectivesHeader:SetFont(Original_Font1, 18);
  QuestInfoObjectivesText:SetFont(Original_Font2, 13);
  QuestInfoRewardsHeader:SetText(QTR_MessOrig.rewards);
  QuestInfoRewardsHeader:SetFont(Original_Font1, 18);
  QuestInfoRewardText:SetFont(Original_Font2, 13);
  QuestInfoXPFrameReceiveText:SetText(QTR_MessOrig.experience);
  QuestInfoXPFrameReceiveText:SetFont(Original_Font2, 13);
  QuestInfoRequiredMoneyText:SetText(QTR_MessOrig.reqmoney);
  QuestInfoRequiredMoneyText:SetFont(Original_Font2, 13);
  QuestInfoSpellLearnText:SetText(QTR_MessOrig.learnspell);
  QuestInfoSpellLearnText:SetFont(Original_Font2, 13);
  QuestProgressTitleText:SetFont(Original_Font1, 18);
  QuestProgressText:SetFont(Original_Font2, 13);
  QuestProgressRequiredItemsText:SetText(QTR_MessOrig.reqitems);
  QuestProgressRequiredItemsText:SetFont(Original_Font1, 18);
  QuestProgressRequiredMoneyText:SetText(QTR_MessOrig.reqmoney);
  QuestProgressRequiredMoneyText:SetFont(Original_Font2, 13);
end


function QTR_ChangeText_InEvent(QTR_event, str_id)
  if (QTR_PS["transtitle"]=="1") then
     QuestInfoTitleHeader:SetText(QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Title"]));
     QuestInfoTitleHeader:SetFont(QTR_Font1, 18);
     QuestProgressTitleText:SetText(QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Title"]));
     QuestProgressTitleText:SetFont(QTR_Font1, 18);
  end
  QuestInfoDescriptionHeader:SetText(QTR_Messages.details);
  QuestInfoDescriptionHeader:SetFont(QTR_Font1, 18);
  QuestInfoDescriptionText:SetText(QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Description"]));
  QuestInfoDescriptionText:SetFont(QTR_Font2, 13);
  QuestInfoObjectivesHeader:SetText(QTR_Messages.objectives);
  QuestInfoObjectivesHeader:SetFont(QTR_Font1, 18);
  QuestInfoObjectivesText:SetText(QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Objectives"]));
  QuestInfoObjectivesText:SetFont(QTR_Font2, 13);
  QuestInfoRewardsHeader:SetText(QTR_Messages.rewards);
  QuestInfoRewardsHeader:SetFont(QTR_Font1, 18);
  QuestInfoRewardText:SetText(QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Completion"]));
  QuestInfoRewardText:SetFont(QTR_Font2, 13);
  if (QTR_event=="QUEST_COMPLETE") then
     QuestInfoItemChooseText:SetText(QTR_Messages.itemchoose2);
     QuestInfoItemReceiveText:SetText(QTR_Messages.itemreceiv2);
  else
     QuestInfoItemChooseText:SetText(QTR_Messages.itemchoose1);
     QuestInfoItemReceiveText:SetText(QTR_Messages.itemreceiv1);
  end
  QuestInfoItemChooseText:SetFont(QTR_Font2, 13);
  QuestInfoItemReceiveText:SetFont(QTR_Font2, 13);
  QuestInfoXPFrameReceiveText:SetText(QTR_Messages.experience);
  QuestInfoXPFrameReceiveText:SetFont(QTR_Font2, 13);
  QuestInfoRequiredMoneyText:SetText(QTR_Messages.reqmoney);
  QuestInfoRequiredMoneyText:SetFont(QTR_Font2, 13);
  QuestInfoSpellLearnText:SetText(QTR_Messages.learnspell);
  QuestInfoSpellLearnText:SetFont(QTR_Font2, 13);
  QuestProgressText:SetText(QTR_ExpandUnitInfo(QTR_QuestData[str_id]["Progress"]));
  QuestProgressText:SetFont(QTR_Font2, 13);
  QuestProgressRequiredMoneyText:SetText(QTR_Messages.reqmoney);
  QuestProgressRequiredMoneyText:SetFont(QTR_Font2, 13);
  QuestProgressRequiredItemsText:SetText(QTR_Messages.reqitems);
  QuestProgressRequiredItemsText:SetFont(QTR_Font1, 18);
end


function QTR_ChangeText_OnQuestLog(qid)
  if (QTR_PS["transtitle"]=="1") then
     QuestInfoTitleHeader:SetText(QTR_ExpandUnitInfo(QTR_QuestData[qid]["Title"]));
     QuestInfoTitleHeader:SetFont(QTR_Font1, 18);
  end
  QuestInfoDescriptionHeader:SetText(QTR_Messages.details);
  QuestInfoDescriptionHeader:SetFont(QTR_Font1, 18);
  QuestInfoDescriptionText:SetText(QTR_description);
  QuestInfoDescriptionText:SetFont(QTR_Font2, 13);
  QuestInfoObjectivesHeader:SetText(QTR_Messages.objectives);
  QuestInfoObjectivesHeader:SetFont(QTR_Font1, 18);
  QuestInfoObjectivesText:SetText(QTR_objectives);
  QuestInfoObjectivesText:SetFont(QTR_Font2, 13);
  QuestInfoRewardsHeader:SetText(QTR_Messages.rewards);
  QuestInfoRewardsHeader:SetFont(QTR_Font1, 18);
  QuestInfoItemChooseText:SetText(QTR_Messages.itemchoose1);
  QuestInfoItemChooseText:SetFont(QTR_Font2, 13);
  QuestInfoItemReceiveText:SetText(QTR_Messages.itemreceiv1);
  QuestInfoItemReceiveText:SetFont(QTR_Font2, 13);
  QuestInfoXPFrameReceiveText:SetText(QTR_Messages.experience);
  QuestInfoXPFrameReceiveText:SetFont(QTR_Font2, 13);
  QuestInfoRequiredMoneyText:SetText(QTR_Messages.reqmoney);
  QuestInfoRequiredMoneyText:SetFont(QTR_Font2, 13);
  QuestInfoSpellLearnText:SetText(QTR_Messages.learnspell);
  QuestInfoSpellLearnText:SetFont(QTR_Font2, 13);
end


function QTR_ToggleVisibility()
  -- click on QTR button in QuestLogFrame
  if (QTR_PS["active"]=="0") then
     QTR_PS["active"] = "1";
     QTR_ShowAndUpdateQuestInfo();
     if (DEFAULT_CHAT_FRAME) then
         DEFAULT_CHAT_FRAME:AddMessage("|cffffff00WotLK TR "..QTR_Messages.isactive);
     else
         UIErrorsFrame:AddMessage("|cffffff00WotLK TR "..QTR_Messages.isactive, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
     end
  else
     QTR_PS["active"] = "0";
     QTR_HideQuestInfo();
     if (DEFAULT_CHAT_FRAME) then
         DEFAULT_CHAT_FRAME:AddMessage("|cffffff00WotLK TR "..QTR_Messages.isinactive);
     else
         UIErrorsFrame:AddMessage("|cffffff00WotLK TR "..QTR_Messages.isinactive, 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
     end
     RestoreOriginalFonts();
  end
end


function QTR_ShowAndUpdateQuestInfo()
  if (QTR_PS["active"]=="0") then
     return;
  end
  if (QTR_PS["mode"]=="2") then
     QTRFrame1:Show();
  end;
  QTR_UpdateQuestInfo();
end


function QTR_HideQuestInfo()
  QTRFrame1:Hide();
end


function QTR_UpdateQuestInfo()
  if (QTR_PS["active"]=="0") then
     return;
  end
  local questSelected = GetQuestLogSelection();
  if (GetQuestLogTitle(questSelected) == nil) then
     return;
  end

  local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questSelected);
  if (isHeader) then
     return;
  end

  local qid = tostring(questID);
  -- 3.3.5a: GetQuestLogTitle() quest ID DÖNDÜRMEZ (qid="nil"). Giver yolundaki gibi
  -- İngilizce başlık → QTR_QuestList köprüsüyle ID'yi çöz; yoksa log'daki (üzerindeki)
  -- görevler çeviri verisi olsa bile çevrilmeden İngilizce kalır.
  if (not QTR_QuestData[qid] and QTR_QuestList[questTitle]) then
     local q_lists = QTR_QuestList[questTitle];
     if (string.find(q_lists, ",") == nil) then
        qid = tostring(tonumber(q_lists));                 -- başlığa tek ID
     else
        local QTR_table = QTR_split(q_lists, ",");         -- çok ID: ilk tamamlanmamışı seç
        local center = "";
        for ii,vv in ipairs(QTR_table) do
           if (not QTR_PC[vv] and center=="") then center = vv; end
        end
        if (center ~= "") then qid = tostring(tonumber(center)); end
     end
  end
  QTR_QuestID:SetText("QuestID: " .. qid);

  if (QTR_QuestData[qid]) then
     QTR_objectives  = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Objectives"]);
     QTR_description = QTR_ExpandUnitInfo(QTR_QuestData[qid]["Description"]);
     QTR_descripFull = QTR_Messages.details .. "\n" .. QTR_description;
     QTR_translator = "";
     if (QTR_QuestData[qid]["Translator"]) then
        if (QTR_QuestData[qid]["Translator"]>"") then
            QTR_translator = "\n\n" .. QTR_Messages.translator .. " " .. QTR_ExpandUnitInfo(QTR_QuestData[qid]["Translator"]);
        end
     end
     QTR_QuestTitle:SetText(QTR_ExpandUnitInfo(QTR_QuestData[qid]["Title"]));
     QTR_QuestDetail:SetText(QTR_objectives .. "\n\n" .. QTR_descripFull .. QTR_translator);
     if (QTR_PS["mode"]=="1") then		       -- translation direct into original QuestLog frame
        QTR_ChangeText_OnQuestLog(qid);
     end
  else
     QTR_QuestTitle:SetText(questTitle);
     QTR_QuestDetail:SetText(QTR_Messages.missing);
     if (QTR_PS["mode"]=="1") then
	RestoreOriginalFonts();
     end;
  end
end


function GS_ON_OFF()
   if (curr_goss=="1") then         -- çeviriyi kapat - orijinal metni göster
      curr_goss="0";
      GossipGreetingText:SetText(QTR_GS[curr_hash]);
      GossipGreetingText:SetFont(Original_Font2, 13);
      QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(curr_hash).."] EN");
   else                             -- çeviriyi göster
      curr_goss="1";
      local greetingTr = GS_Gossip[curr_hash];
      GossipGreetingText:SetText(QTR_ExpandUnitInfo(greetingTr));
      GossipGreetingText:SetFont(QTR_Font2, 13);
      QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(curr_hash).."] TR");
   end
end


-- NPC ile konuşma penceresi açıldı
function QTR_Gossip_Show()
   local npcName = GossipFrameNpcNameText:GetText();
   curr_hash = 0;
   if (npcName) then
      local Greeting_Text = GossipGreetingText:GetText();
      if (string.find(Greeting_Text," ")==nil) then         -- bu metin çevrilmiş değil (sabit boşluk yok)
         npcName = string.gsub(npcName, '"', '\"');
         Greeting_Text = string.gsub(Greeting_Text, '"', '\"');
         local cleanText = string.gsub(Greeting_Text, '\r', '');
         cleanText = string.gsub(cleanText, '\n', '$B');
         cleanText = string.gsub(cleanText, QTR_name, '$N');
         cleanText = string.gsub(cleanText, string.upper(QTR_name), '$N$');
         cleanText = string.gsub(cleanText, QTR_race, '$R');
         cleanText = string.gsub(cleanText, string.lower(QTR_race), '$R');
         cleanText = string.gsub(cleanText, QTR_class, '$C');
         cleanText = string.gsub(cleanText, string.lower(QTR_class), '$C');
         cleanText = string.gsub(cleanText, '$N$', '');
         cleanText = string.gsub(cleanText, '$N', '');
         cleanText = string.gsub(cleanText, '$B', '');
         cleanText = string.gsub(cleanText, '$R', '');
         cleanText = string.gsub(cleanText, '$C', '');
         local Hash = StringHash(cleanText);
         curr_hash = Hash;
         QTR_GS[Hash] = Greeting_Text;                      -- orijinal metni kaydet
         if ( GS_Gossip[Hash] ) then   -- bu NPC'nin GOSSIP metninin çevirisi var
            curr_goss = "1";
            local greetingTr = GS_Gossip[Hash];
            GossipGreetingText:SetText(QTR_ExpandUnitInfo(greetingTr));
            GossipGreetingText:SetFont(QTR_Font2, 13);
            QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] TR");
            QTR_ToggleButtonGS:Enable();
         else                               -- GOSSIP veritabanında çeviri yok
            curr_goss = "0";
            -- dosyaya kaydet (HAM metin — token'lar ham kalsın ki çeviri şablonu bozulmasın)
            QTR_GOSSIP[npcName.."@"..tostring(Hash)] = Greeting_Text.."@"..QTR_name..":"..QTR_race..":"..QTR_class;
            -- Çeviri olmasa bile WoW token'larını aç ($c/$n/$r/$b…) → ham "$c" ekranda görünmesin.
            -- Sondaki NBSP "işlendi" işareti: pencere re-show olursa tekrar işlenip HAM capture'ı BOZMASIN.
            GossipGreetingText:SetText(QTR_ExpandUnitInfo(Greeting_Text).."\194\160");
            GossipGreetingText:SetFont(Original_Font2, 13);
            QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] EN");
            QTR_ToggleButtonGS:Disable();
         end
         if (GetNumGossipOptions()>0) then    -- ek işlev butonları da var
            local pos=0;
            local titleButton;
            for i = 1, GetNumGossipOptions(), 1 do
               titleButton=getglobal("GossipTitleButton"..tostring(pos+i));
               if (titleButton:GetText()) then
                  local gostxt = titleButton:GetText();
                  if (string.find(gostxt, "|cff000000") == nil) then   -- bu, gossip içinde bir görev değil
                     Hash = StringHash(gostxt);
                     if ( GS_Gossip[Hash] ) then   -- ek metnin çevirisi var
                        titleButton:SetText(QTR_ExpandUnitInfo(GS_Gossip[Hash]));
                        titleButton:GetFontString():SetFont(QTR_Font2, 13);
                     else
                        QTR_GOSSIP[npcName..'@'..tostring(Hash)] = gostxt.."@"..QTR_name..":"..QTR_race..":"..QTR_class;
                     end
                  end
               end
            end
         end
      end
   end
end


function Tut_onTutorialShow()
   if (QTR_PS["tutorial"]=="1") then
      if (not QTR_wait(0.1,Tut_TutorialShowDelayed)) then
         -- 0.1 sn gecikme
      end
   end
end


function Tut_TutorialShowDelayed()
   Tut_ID = TutorialFrame.id;
   local tutTitle, tutText = "","";
   if (Tut_Data[tostring(Tut_ID)]) then
      tutTitle = Tut_Data[tostring(Tut_ID)]["Title"];
      tutText = Tut_Data[tostring(Tut_ID)]["Text"];
   end
   if (string.len(tutText)>0) then
      TutorialFrameTitle:SetText(tutTitle);
      local _font1, _size1, _1 = TutorialFrameTitle:GetFont();
      TutorialFrameTitle:SetFont(QTR_Font2, _size1);
      TutorialFrameText:SetText(tutText);
      local _font2, _size2, _2 = TutorialFrameText:GetFont();
      TutorialFrameText:SetFont(QTR_Font2, _size2);
   end
   TutorialFrameOkayButton:SetText("Kapat");
end


-- ============================================================
--  Metin token'larını oyuncuya göre açar (genişletir).
--  ÖNEMLİ: Önce WoW'un ham $-token'larını ($N,$B,$C,$G...) addon'un iç
--  sözlüğüne (YOUR_NAME, NEW_LINE...) çeviren "shim" çalışır. Türkçe veri
--  bu ham token'ları kullandığı için, bu adım olmadan ekranda "$B" gibi
--  işaretler görünürdü — asıl düzeltme budur.
-- ============================================================
function QTR_ExpandUnitInfo(msg)
   if (msg == nil) then return ""; end

   -- 1) Ham WoW token'ları -> iç sözlük (önce küçük harfi büyüğe normalize et)
   msg = string.gsub(msg, "$n", "$N");
   msg = string.gsub(msg, "$r", "$R");
   msg = string.gsub(msg, "$c", "$C");
   msg = string.gsub(msg, "$b", "$B");
   msg = string.gsub(msg, "$p", "$P");
   msg = string.gsub(msg, "$o", "$O");
   msg = string.gsub(msg, "$g", "$G");
   msg = string.gsub(msg, "$N", "YOUR_NAME");
   msg = string.gsub(msg, "$R", "YOUR_RACE");
   msg = string.gsub(msg, "$C", "YOUR_CLASS");
   msg = string.gsub(msg, "$B", "NEW_LINE");
   msg = string.gsub(msg, "$P", "NPC_GENDER");
   msg = string.gsub(msg, "$O", "OWN_NAME");
   msg = string.gsub(msg, "$G", "YOUR_GENDER");

   -- 2) Satır sonu ve oyuncu adı
   msg = string.gsub(msg, "NEW_LINE", "\n");
   msg = string.gsub(msg, "YOUR_NAME0", string.upper(QTR_name));
   msg = string.gsub(msg, "YOUR_NAME1", QTR_name);
   msg = string.gsub(msg, "YOUR_NAME2", QTR_name);
   msg = string.gsub(msg, "YOUR_NAME3", QTR_name);
   msg = string.gsub(msg, "YOUR_NAME4", QTR_name);
   msg = string.gsub(msg, "YOUR_NAME5", QTR_name);
   msg = string.gsub(msg, "YOUR_NAME6", QTR_name);
   msg = string.gsub(msg, "YOUR_NAME7", QTR_name);
   msg = string.gsub(msg, "YOUR_NAME", QTR_name);

   -- 3) Cinsiyet/isim biçimleri -- gsub tabanlı (DONMAYA KARŞI GÜVENLİ:
   --    eski elle yazılan ayrıştırıcı, parantezsiz bozuk token'da sonsuz
   --    döngüye girip oyunu dondurabiliyordu; gsub sınırlıdır, donamaz).
   msg = string.gsub(msg, "YOUR_GENDER%((.-);(.-)%)", function(m, f)
      if (QTR_sex == 3) then return f; else return m; end
   end);
   local npcSex = UnitSex("npc");   -- 1:nötr, 2:erkek, 3:kadın
   msg = string.gsub(msg, "NPC_GENDER%((.-);(.-)%)", function(m, f)
      if (npcSex == 3) then return f; else return m; end
   end);
   -- OWN_NAME(EN;TR): her zaman ilk (orijinal) biçim kullanılır
   msg = string.gsub(msg, "OWN_NAME%((.-);(.-)%)", function(en, tr)
      return en;
   end);

   -- 4) Sınıf/ırk: İngilizce ad (Türkçe veride çekim/numara yok)
   msg = string.gsub(msg, "YOUR_CLASS", player_class.M1);
   msg = string.gsub(msg, "YOUR_RACE",  player_race.M1);

   return msg;
end

-- Motor sonuna kadar yüklendi: Core özeti bu bayrağa bakıp yüklü/YOK gösterir.
WTR_LOADED_QUESTS = true;
WTR_Print("Görevler motoru yüklendi", "debug");

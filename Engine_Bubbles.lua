-- ============================================================
--  WotLK TR  ·  Engine_Bubbles.lua
--  NPC konuşma baloncuklarını Türkçe gösterir — WotLK 3.3.5a (Warmane).
-- ============================================================

local BB_version = GetAddOnMetadata("WOTLKTR", "Version");
local BB_ctrFrame = CreateFrame("FRAME", "WoWTR-BubblesFrame");
local BB_Font = "Interface\\AddOns\\WOTLKTR\\Fonts\\frizquadratatt_tr.ttf";
local BB_class= UnitClass("player");
local BB_race = UnitRace("player");
local BB_BubblesArray = {};
local player_name = UnitName("player");
local player_sex = UnitSex("player");     -- 1:nötr, 2:erkek, 3:kadın

-- Sınıf ve ırk İngilizce kalır (çevirmenler metinleri İngilizce adlara göre yazdı).
-- Tüm gramer durumlarını (M1..W2) aynı İngilizce ada eşitle — çekim/cinsiyet farkı yok.
local function BB_FillCases(name)
   return { M1=name, D1=name, C1=name, B1=name, N1=name, K1=name, W1=name,
            M2=name, D2=name, C2=name, B2=name, N2=name, K2=name, W2=name };
end
player_race = BB_FillCases(BB_race);
player_class = BB_FillCases(BB_class);


-- Metnin 32-bit hash'ini üretir; NPC konuşmasını çeviri tablosuyla eşleştirir.
-- KRİTİK: Asal sayılar ve yapı veriyle birebir aynı olmalı — değişirse hiçbir
-- baloncuk eşleşmez. ASLA DEĞİŞTİRME.
local function StringHash(text)
  local counter = 1;
  local acc = 0;
  local len = string.len(text);
  for i = 1, len, 3 do
    counter = math.fmod(counter*8161, 4294967279);  -- 2^32 - 17: asal!
    acc = (string.byte(text,i)*16776193);
    counter = counter + acc;
    acc = ((string.byte(text,i+1) or (len-i+256))*8372226);
    counter = counter + acc;
    acc = ((string.byte(text,i+2) or (len-i+256))*3932164);
    counter = counter + acc;
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: asal (döngüdekinden farklı)
end


local function BB_bubblizeText()
   for i = 1, WorldFrame:GetNumChildren() do                -- WorldFrame üzerindeki alt frame'leri tara
      local child = select(i, WorldFrame:GetChildren());    -- "çocuk" frame
-- (IsForbidden kontrolü yok: bu API 3.3.5a'da mevcut değil)
         for j = 1, child:GetNumRegions() do                   -- ekranda göründüğü region'ları tara
            region = select(j, child:GetRegions());            -- region
            for idx, iArray in ipairs(BB_BubblesArray) do      -- verinin doğru olup olmadığını denetle (orijinal metin tabloya kayıtlıyla aynı mı)
               if region and not region:GetName() and region:IsVisible() and region.GetText and region:GetText() == iArray[1] then
                  local oldTextWidth = region:GetStringWidth() -- baloncuk penceresinin mevcut genişliği
                  region:SetText(iArray[2]);                   -- çevirimizi buraya yaz
                  local _font1, _size1, _3 = region:GetFont(); -- mevcut font ve boyutu oku
                  region:SetFont(BB_Font, _size1);             -- Türkçe fontu ve değişmemiş boyutu (13) ayarla
                  region:SetWidth(region:GetWidth()+(region:GetStringWidth() - oldTextWidth));  -- yeni pencere genişliğini belirle
                  tremove(BB_BubblesArray, idx);               -- tablodan kayıtlı veriyi sil
               elseif (TalkingHeadFrame and (TalkingHeadFrame.TextFrame.Text:GetText() ==  iArray[1])) then
                  TalkingHeadFrame.TextFrame.Text:SetText(iArray[2]);                   -- Türkçe çeviriyi yaz
                  local _font1, _size1, _3 = TalkingHeadFrame.TextFrame.Text:GetFont(); -- mevcut font ve boyutu oku
                  TalkingHeadFrame.TextFrame.Text:SetFont(BB_Font, _size1);             -- Türkçe fontu yaz
                  tremove(BB_BubblesArray, idx);               -- tablodan kayıtlı veriyi sil
               end
            end
         end
-- (IsForbidden kontrolü yok: bu API 3.3.5a'da mevcut değil)
   end
   for idx, iArray in ipairs(BB_BubblesArray) do            -- tabloyu bir kez daha tara
      if (iArray[3] >= 100) then                            -- sayaç 100'e ulaştı
         tremove(BB_BubblesArray, idx);                     -- tablodan kayıtlı veriyi sil
      else
         iArray[3] = iArray[3]+1;                           -- sayacı artır (baloncuk görünmedi mi?)
      end;
   end;
   if (#(BB_BubblesArray) == 0) then
      BB_ctrFrame:SetScript("OnUpdate", nil);               -- tablo boş olduğundan Update metodunu kapat
   end;
end;


local function ChatFilter(self, event, arg1, arg2, arg3, _, arg5, ...)     -- NPC'den chat'e metin gelmek üzereyken çağrılır
	local changeBubble = false;
   local colorText = "";
   local original_txt = strtrim(arg1);
   local name_NPC = string.gsub(arg2, " says:", "");
   local target = arg5;

	if (event == "CHAT_MSG_MONSTER_SAY") then          -- chat penceresine giden metnin rengini belirle
		colorText = "|cFFFFFF9F";
		if (GetCVar("ChatBubbles")) then
			changeBubble = true;
		end
	elseif (event == "CHAT_MSG_MONSTER_PARTY") then
		colorText = "|cFFAAAAFF";
	elseif (event == "CHAT_MSG_MONSTER_YELL") then
		colorText = "|cFFFF4040";
		if (GetCVar("ChatBubbles")) then
			changeBubble = true;
		end
	elseif (event == "CHAT_MSG_MONSTER_WHISPER") then
		colorText = "|cFFFFB5EB";
	elseif (event == "CHAT_MSG_MONSTER_EMOTE") then
		colorText = "|cFFFF8040";
   end

   if (arg5 ~= "") then
      original_txt = string.gsub(original_txt, arg5, "");        -- orijinal metinden kişiyi ($target) çıkar
   end
   BB_is_translation="0";
   if (BB_PM["active"] == "1") then                       -- eklenti aktif - çeviri ara
      local HashCode = StringHash(original_txt);
      if (BB_Bubbles[HashCode]) then         -- Türkçe çeviri var
         newMessage = BB_Bubbles[HashCode];
         newMessage = BB_ZmienKody(newMessage,arg5);
         BB_is_translation="1";
         if (BB_PM["chat-pl"] == "1") then                -- çeviriyi chat satırında göster
            if (strsub(newMessage,1,2)=="%s") then        -- baloncuğun betimsel formu var, ör. NPC_name öfkeye kapılır!
               newMessage = name_NPC..strsub(newMessage, 3);
               DEFAULT_CHAT_FRAME:AddMessage(colorText..newMessage);
            else
               DEFAULT_CHAT_FRAME:AddMessage(colorText..name_NPC.." diyor: "..newMessage);
            end
         else
            if (strsub(newMessage,1,2)=="%s") then        -- baloncuğun betimsel formu var, ör. NPC_name bir şey yapar.
               newMessage = name_NPC..strsub(newMessage, 3);
            end
         end
	      if (changeBubble) then                          -- baloncuğu Türkçe göster (varsa)
		      tinsert(BB_BubblesArray, { [1] = arg1, [2] = newMessage, [3] = 1 });
		      BB_ctrFrame:SetScript("OnUpdate", BB_bubblizeText);
	      end
      else                                               -- çevirimiz yok
         original_txt = strtrim(arg1);                   -- tam İngilizce metni tekrar oku
         if (BB_PM["saveNB"] == "1") then                -- orijinal metni kaydet
            BB_PS[name_NPC..":"..tostring(HashCode)] = original_txt.."@"..target..":"..player_name..":"..BB_race..":"..BB_class;
         end
      end
   end

   if ((BB_PM["chat-en"] == "1") or (BB_is_translation ~= "1"))then     -- çeviri de yoksa
	   return false;     -- orijinal metni chat penceresinde göster
   else
      return true;      -- orijinal metni gösterme
   end
end


-- NPC konuşmasındaki $kodlarını oyuncuya göre açar (isim, cinsiyet, ırk, sınıf).
-- Türkçe veri $ tokenlarını DOĞRUDAN kullanır (Quests'teki gibi shim'e gerek yok).
function BB_ZmienKody(message, target)
   if (target == "") then          -- çeviride $target geçebilir
      target = player_name;        -- hedef yoksa oyuncunun adı
   end

   message = string.gsub(message, "$B", "\n");        -- $B = satır sonu (veride 102 kez)

   message = string.gsub(message, "$n$", string.upper(target));   -- BÜYÜK harf isim
   message = string.gsub(message, "$N$", string.upper(target));
   message = string.gsub(message, "$n", target);
   message = string.gsub(message, "$N", target);
   message = string.gsub(message, "$target", target);
   message = string.gsub(message, "$TARGET", target);

   -- $G(erkek;kadın) — cinsiyet formu. Hang-safe: elle string taraması (while
   -- döngüsü) yerine sınırlı gsub. Orijinal döngü bozuk girdide oyunu donduruyordu.
   message = string.gsub(message, "$g", "$G");
   message = string.gsub(message, "%$G%((.-);(.-)%)", function(m, f)
      if (target == player_name and player_sex == 3) then
         return f;       -- oyuncuya hitap + oyuncu kadın → dişil form
      else
         return m;       -- erkek form (ya da başkasına hitap)
      end
   end);

   -- $O(EN;TR) — özel adlar; her zaman ilk (EN) form. Hang-safe gsub.
   message = string.gsub(message, "$o", "$O");
   message = string.gsub(message, "%$O%((.-);(.-)%)", function(en, tr)
      return en;
   end);

   message = string.gsub(message, "$r", "$R");
   message = string.gsub(message, "$c", "$C");
   if (player_sex == 3) then        -- oyuncu kadın
      message = string.gsub(message, "$R1", player_race.M2);
      message = string.gsub(message, "$R2", player_race.D2);
      message = string.gsub(message, "$R3", player_race.C2);
      message = string.gsub(message, "$R4", player_race.B2);
      message = string.gsub(message, "$R5", player_race.N2);
      message = string.gsub(message, "$R6", player_race.K2);
      message = string.gsub(message, "$R7", player_race.W2);
      message = string.gsub(message, "$R", player_race.M2);
      message = string.gsub(message, "$C1", player_class.M2);
      message = string.gsub(message, "$C2", player_class.D2);
      message = string.gsub(message, "$C3", player_class.C2);
      message = string.gsub(message, "$C4", player_class.B2);
      message = string.gsub(message, "$C5", player_class.N2);
      message = string.gsub(message, "$C6", player_class.K2);
      message = string.gsub(message, "$C7", player_class.W2);
      message = string.gsub(message, "$C", player_class.M2);
   else                             -- oyuncu erkek
      message = string.gsub(message, "$R1", player_race.M1);
      message = string.gsub(message, "$R2", player_race.D1);
      message = string.gsub(message, "$R3", player_race.C1);
      message = string.gsub(message, "$R4", player_race.B1);
      message = string.gsub(message, "$R5", player_race.N1);
      message = string.gsub(message, "$R6", player_race.K1);
      message = string.gsub(message, "$R7", player_race.W1);
      message = string.gsub(message, "$R", player_race.M1);
      message = string.gsub(message, "$C1", player_class.M1);
      message = string.gsub(message, "$C2", player_class.D1);
      message = string.gsub(message, "$C3", player_class.C1);
      message = string.gsub(message, "$C4", player_class.B1);
      message = string.gsub(message, "$C5", player_class.N1);
      message = string.gsub(message, "$C6", player_class.K1);
      message = string.gsub(message, "$C7", player_class.W1);
      message = string.gsub(message, "$C", player_class.M1);
   end

   return message;
end


function BB_CheckVars()
  if (not BB_PM) then
     BB_PM = {};
  end
  if (not BB_PS) then
     BB_PS = {};
  end
  -- seçenek varsayılanlarını ilkle
  if (not BB_PM["active"] ) then    -- eklenti aktif
     BB_PM["active"] = "1";
  end
  if (not BB_PM["chat-en"] ) then   -- chat penceresinde İngilizce metni göster
     BB_PM["chat-en"] = "0";
  end
  if (not BB_PM["chat-pl"] ) then   -- chat penceresinde Türkçe metni göster
     BB_PM["chat-pl"] = "1";
  end
  if (not BB_PM["saveNB"] ) then    -- çevrilmemiş baloncukları kaydet
     BB_PM["saveNB"] = "1";
  end
  if (not BB_PM["setsize"] ) then   -- yazı boyutu değiştirmeyi etkinleştir
     BB_PM["setsize"] = "0";
  end
  if (not BB_PM["fontsize"] ) then  -- yazı boyutu
     BB_PM["fontsize"] = "13";
  end
  if (not BB_PM["sex"] ) then      -- oyuncuya yönelik konuşmalarda cinsiyet seçimi
     if (player_sex==3) then
        BB_PM["sex"] = "3";
     else
        BB_PM["sex"] = "2";
     end
  end
  player_sex = tonumber(BB_PM["sex"]);
end


function BB_SetCheckButtonState()
  BBCheckButton1:SetChecked(BB_PM["active"]=="1");
  BBCheckButton2:SetChecked(BB_PM["chat-en"]=="1");
  BBCheckButton3:SetChecked(BB_PM["chat-pl"]=="1");
  BBCheckButton5:SetChecked(BB_PM["saveNB"]=="1");
  BBCheckSize:SetChecked(BB_PM["setsize"]=="1");
  local fontsize = tonumber(BB_PM["fontsize"]);
  BBslider:SetValue(fontsize);
  if (BB_PM["setsize"]=="1") then
     BBOpis1:SetFont(BB_Font, fontsize);
  else
     BBOpis1:SetFont(BB_Font, 13);
  end
  BBsex1:SetChecked(player_sex==2);
  BBsex2:SetChecked(player_sex==3);
end


function BB_BlizzardOptions()

-- Bilgi metni için ana frame oluştur
local BBOptions = CreateFrame("FRAME", "WoWTRBubblesOptions");
BBOptions.refresh = function (self) BB_SetCheckButtonState() end;
BBOptions.name = "Baloncuklar";
BBOptions.parent = "WotLK TR";
InterfaceOptions_AddCategory(BBOptions);

local BBOptionsHeader1 = BBOptions:CreateFontString(nil, "ARTWORK");
BBOptionsHeader1:SetFontObject(GameFontNormalLarge);
BBOptionsHeader1:SetJustifyH("LEFT");
BBOptionsHeader1:SetJustifyV("TOP");
BBOptionsHeader1:ClearAllPoints();
BBOptionsHeader1:SetPoint("TOPLEFT", 16, -16);
BBOptionsHeader1:SetText("Baloncuklar");

local BBOptionsHeader2 = BBOptions:CreateFontString(nil, "ARTWORK");
BBOptionsHeader2:SetFontObject(GameFontNormalLarge);
BBOptionsHeader2:SetJustifyH("LEFT");
BBOptionsHeader2:SetJustifyV("TOP");
BBOptionsHeader2:ClearAllPoints();
BBOptionsHeader2:SetPoint("TOPLEFT", BBOptionsHeader1, "BOTTOMLEFT", 0, -5);
BBOptionsHeader2:SetText("sürüm "..BB_version.." ("..BB_base.." çeviri)");

local BBOptionsDate = BBOptions:CreateFontString(nil, "ARTWORK");
BBOptionsDate:SetFontObject(GameFontNormalLarge);
BBOptionsDate:SetJustifyH("LEFT");
BBOptionsDate:SetJustifyV("TOP");
BBOptionsDate:ClearAllPoints();
BBOptionsDate:SetPoint("TOPLEFT", BBOptionsHeader2, "BOTTOMLEFT", 0, -10);
BBOptionsDate:SetText("Veritabanı: "..BB_date);
BBOptionsDate:SetFont(BB_Font, 16);

local BBCheckButton1 = CreateFrame("CheckButton", "BBCheckButton1", BBOptions, "OptionsCheckButtonTemplate");
BBCheckButton1:SetPoint("TOPLEFT", BBOptionsDate, "BOTTOMLEFT", 0, -15);
BBCheckButton1:SetScript("OnClick", function(self) if (BB_PM["active"]=="1") then BB_PM["active"]="0" else BB_PM["active"]="1" end; end);
BBCheckButton1Text:SetText("Çeviriyi Etkinleştir");     -- eklenti aktif
BBCheckButton1Text:SetFont(BB_Font, 13);

local BBCheckButton2 = CreateFrame("CheckButton", "BBCheckButton2", BBOptions, "OptionsCheckButtonTemplate");
BBCheckButton2:SetPoint("TOPLEFT", BBCheckButton1, "BOTTOMLEFT", 0, -5);
BBCheckButton2:SetScript("OnClick", function(self) if (BB_PM["chat-en"]=="1") then BB_PM["chat-en"]="0" else BB_PM["chat-en"]="1" end; end);
BBCheckButton2Text:SetText("Orijinali Sohbette Göster");
BBCheckButton2Text:SetFont(BB_Font, 13);

local BBCheckButton3 = CreateFrame("CheckButton", "BBCheckButton3", BBOptions, "OptionsCheckButtonTemplate");
BBCheckButton3:SetPoint("TOPLEFT", BBCheckButton2, "BOTTOMLEFT", 0, 0);
BBCheckButton3:SetScript("OnClick", function(self) if (BB_PM["chat-pl"]=="1") then BB_PM["chat-pl"]="0" else BB_PM["chat-pl"]="1" end; end);
BBCheckButton3Text:SetText("Çeviriyi Sohbette Göster");
BBCheckButton3Text:SetFont(BB_Font, 13);

local BBCheckButton5 = CreateFrame("CheckButton", "BBCheckButton5", BBOptions, "OptionsCheckButtonTemplate");
BBCheckButton5:SetPoint("TOPLEFT", BBCheckButton3, "BOTTOMLEFT", 0, 0);
BBCheckButton5:SetScript("OnClick", function(self) if (BB_PM["saveNB"]=="1") then BB_PM["saveNB"]="0" else BB_PM["saveNB"]="1" end; end);
BBCheckButton5Text:SetText("Çevrilmemiş Baloncukları Kaydet");
BBCheckButton5Text:SetFont(BB_Font, 13);

local BBCheckSize = CreateFrame("CheckButton", "BBCheckSize", BBOptions, "OptionsCheckButtonTemplate");
BBCheckSize:SetPoint("TOPLEFT", BBCheckButton5, "BOTTOMLEFT", 0, -20);
BBCheckSize:SetScript("OnClick", function(self) if (BB_PM["setsize"]=="1") then BB_PM["setsize"]="0" else BB_PM["setsize"]="1" end; end);
BBCheckSizeText:SetText("Yazı Boyutunu Ayarla");
BBCheckSizeText:SetFont(BB_Font, 13);

local BBslider = CreateFrame("Slider", "BBslider", BBOptions, "OptionsSliderTemplate");
BBslider:SetPoint("TOPLEFT", BBCheckSize, "BOTTOMLEFT", 10, -20);
BBslider:SetMinMaxValues(10, 20);
BBslider.minValue, BBslider.maxValue = BBslider:GetMinMaxValues();
--BBslider.Low:SetText(BBslider.minValue);
--BBslider.High:SetText(BBslider.maxValue);
getglobal(BBslider:GetName() .. 'Text'):SetText('Yazı boyutu');
getglobal(BBslider:GetName() .. 'Text'):SetFont(BB_Font, 13);
BBslider:SetValue(tonumber(BB_PM["fontsize"]));
BBslider:SetValueStep(1);
BBslider:SetScript("OnValueChanged", function(self,event,arg1)
                                      BB_PM["fontsize"]=string.format("%d",event);
                                      BBsliderVal:SetText(BB_PM["fontsize"]);
									           BBOpis1:SetFont(BB_Font, event);
                                      end);
BBsliderVal = BBOptions:CreateFontString(nil, "ARTWORK");
BBsliderVal:SetFontObject(GameFontNormal);
BBsliderVal:SetJustifyH("CENTER");
BBsliderVal:SetJustifyV("TOP");
BBsliderVal:ClearAllPoints();
BBsliderVal:SetPoint("CENTER", BBslider, "CENTER", 0, -12);
BBsliderVal:SetText(BB_PM["fontsize"]);
BBsliderVal:SetFont(BB_Font, 13);

BBOpis1 = BBOptions:CreateFontString(nil, "ARTWORK");
BBOpis1:SetFontObject(GameFontNormalLarge);
BBOpis1:SetJustifyH("LEFT");
BBOpis1:SetJustifyV("TOP");
BBOpis1:ClearAllPoints();
BBOpis1:SetPoint("TOPLEFT", BBCheckSize, "BOTTOMLEFT", 0, -60);
local fontsize = tonumber(BB_PM["fontsize"]);
if (BB_PM["setsize"]=="1") then
   BBOpis1:SetFont(BB_Font, fontsize);
else
   BBOpis1:SetFont(BB_Font, 13);
end
BBOpis1:SetText("Örnek Metin");

local BBsex0 = BBOptions:CreateFontString(nil, "ARTWORK");
BBsex0:SetFontObject(GameFontNormal);
BBsex0:SetJustifyH("LEFT");
BBsex0:SetJustifyV("TOP");
BBsex0:ClearAllPoints();
BBsex0:SetPoint("TOPLEFT", BBOpis1, "BOTTOMLEFT", 0, -20);
BBsex0:SetFont(BB_Font, 13);
BBsex0:SetText("Sana Hitap Biçimi:");

local BBsex1 = CreateFrame("CheckButton", "BBsex1", BBOptions, "OptionsCheckButtonTemplate");
BBsex1:SetPoint("TOPLEFT", BBsex0, "BOTTOMLEFT", 0, 0);
BBsex1:SetScript("OnClick", function(self) if (player_sex==2) then player_sex=3;BBsex2:SetChecked(true) else player_sex=2;BBsex2:SetChecked(false) end;BB_PM["sex"]=tostring(player_sex); end);
BBsex1Text:SetText("Eril (Erkek)");
BBsex1Text:SetFont(BB_Font, 13);

local BBsex2 = CreateFrame("CheckButton", "BBsex2", BBOptions, "OptionsCheckButtonTemplate");
BBsex2:SetPoint("TOPLEFT", BBsex0, "BOTTOMLEFT", 200, 0);
BBsex2:SetScript("OnClick", function(self) if (player_sex==3) then player_sex=2;BBsex1:SetChecked(true) else player_sex=3;BBsex1:SetChecked(false) end;BB_PM["sex"]=tostring(player_sex); end);
BBsex2Text:SetText("Dişil (Kadın)");
BBsex2Text:SetFont(BB_Font, 13);

-- (web sitesi kutusu kaldırıldı)
end


function BB_SlashCommand(msg)
  -- komutu denetle
  if (msg) then
     local BB_command = string.lower(msg);                -- normalleştir, yalnız küçük harf
     if ((BB_command=="on") or (BB_command=="1")) then    -- aktiflik anahtarını aç
        BB_PM["active"]="1";
        WTR_Print("Baloncuklar artık aktif");
     elseif ((BB_command=="off") or (BB_command=="0")) then
        BB_PM["active"]="0";
        WTR_Print("Baloncuklar artık devre dışı");
     else
        InterfaceOptionsFrame_Show();
        InterfaceOptionsFrame_OpenToCategory("Baloncuklar");
        InterfaceOptionsFrame_OpenToCategory("Baloncuklar");
     end
  end
end


ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", ChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_PARTY", ChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", ChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", ChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", ChatFilter)
SlashCmdList["WOWTR_BUBBLES"] = function(msg) BB_SlashCommand(msg); end
SLASH_WOWTR_BUBBLES1 = "/wtrbubbles";
SLASH_WOWTR_BUBBLES2 = "/bbtr";
BB_CheckVars();
BB_BlizzardOptions();
WTR_LOADED_BUBBLES = true;   -- motor sonuna kadar yüklendi (Core özetinde ✓ gösterilir)
WTR_Print("Baloncuklar motoru yüklendi (v"..BB_version..")", "debug");

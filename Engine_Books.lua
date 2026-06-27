-- ============================================================
--  WotLK TR  ·  Engine_Books.lua
--  Çevrilmiş kitapları (tomar/mektup/kitap pencerelerini) Türkçe gösterir — WotLK 3.3.5a (Warmane).
-- ============================================================

-- Türkçe arayüz metinleri (resmî WoWTR değerleri)
BT_Interface = {
   active  = "Çeviriyi Etkinleştir",
   title   = "Başlığı da Çevir",
   showID  = "Kitap Kimliğini Göster",
   saveNW  = "Çevrilmemiş Kitapları Kaydet",
};
BT_Messages = {
   loaded            = "başlatıldı",
   is_now_active     = "şimdi aktif",
   is_now_not_active = "şimdi pasif",
};

local BT_version = GetAddOnMetadata("WOTLKTR", "Version");
if (not BT_base) then
   BT_base = "hata";    -- veri yüklenmediyse
end
local BT_Font = "Interface\\AddOns\\WOTLKTR\\Fonts\\frizquadratatt_tr.ttf";
local BT_name  = UnitName("player");    -- $N genişletmesi için
local BT_class = UnitClass("player");   -- $C genişletmesi için
local BT_act_tr = "0";
local BT_bookID = "0";
local BT_title_en, BT_title_tr, BT_text_en, BT_text_tr = "";


function BookTranslator_ShowTranslation()
   BT_ToggleButton1:Hide();      -- Türkçe başlıklı pencere
   if (BT_PM["active"] == "1") then
      BT_ToggleButton0:Show();
      BT_ToggleButton0:Disable();
      BT_ToggleButton0:SetText("EN");
      BT_ToggleButton0:SetWidth(40);
      BT_act_tr = "0";
      BT_title_en=ItemTextGetItem();
      BT_text_en=ItemTextGetText();
      BT_pageStr=tostring(ItemTextGetPage());
      local par1, par2, par3 = GetItemInfo(ItemTextGetItem());
      if (par2) then
         local pa1, itemID, pa3 = strsplit(":",par2);
         BT_bookID = itemID;
      else
         local BT_marker=BT_title_en.."#"..BT_pageStr.."#"..string.sub(BT_text_en,1,15);
         if (BT_BooksID[BT_marker]) then		          -- ID veritabanında işaretleyici var - bookID al
            BT_bookID = BT_BooksID[BT_marker];          -- string olarak
         end
      end
      if (BT_bookID) then
         if (BT_Books[BT_bookID]) then	                -- bu kitabın çevirisi var
            if (BT_Books[BT_bookID][BT_pageStr]) then   	 -- bu sayfanın çevirisi var
               if (BT_PM["title"] == "1") then			    -- başlık çevirisini göster
                  BT_title_tr = BT_Books[BT_bookID]["Title"];
                  BT_ToggleButton1:SetText(BT_title_tr);
                  BT_ToggleButton1:Show();
               end
               BT_text_tr = string.gsub(BT_Books[BT_bookID][BT_pageStr], "$B", "\n");
               BT_text_tr = string.gsub(BT_text_tr, "$N", BT_name);    -- oyuncu adı
               BT_text_tr = string.gsub(BT_text_tr, "$C", BT_class);   -- oyuncu sınıfı (İngilizce)
               ItemTextPageText:SetText(BT_text_tr);
               if (BT_PM["setsize"]=="1") then
                  ItemTextPageText:SetFont(BT_Font, BT_PM["fontsize"]);
               else
                  ItemTextPageText:SetFont(BT_Font, 13);
               end
               if (BT_PM["showID"]=="1") then				 -- kitap ID'sini göster
                  BT_ToggleButton0:SetText("Book ID: "..BT_bookID.." (TR)");
                  BT_ToggleButton0:SetWidth(150);
               else
                  BT_ToggleButton0:SetText("TR");
               end
               BT_ToggleButton0:Enable();
               BT_act_tr = "1";		                      -- şu anda Türkçe çeviri gösteriliyor
            else	                                        -- çeviri yok
               if (BT_PM["showID"] == "1") then				 -- kitap ID'sini göster
                  BT_ToggleButton0:SetText("Book ID: "..BT_bookID.." (EN)");
                  BT_ToggleButton0:SetWidth(150);
	            end
               BT_save_original();
            end
         else
            BT_save_original();       -- tomar/mektup ID'si var ama çeviri yok - kaydet
         end
      end
   else
      BT_ToggleButton0:Hide();      -- EN veya TR işaretli pencere
   end
end


function BT_save_original()
   if (BT_PM["saveNW"] == "1") then              -- İngilizce metni dosyaya kaydet
      if (strlen(BT_pageStr)==1) then
	     BT_pageStr="0"..BT_pageStr;
      end
      BT_SAVED[BT_bookID.." STR"..BT_pageStr]=BT_title_en.."@"..BT_text_en;
      WTR_Print("kaydedildi (çevrilmemiş), ID: "..BT_bookID, "debug");
   end
end


function BT_ON_OFF()
  if (BT_act_tr == "0") then
    BT_act_tr = "1";
    if (BT_PM["title"] == "1") then			 -- başlık çevirisini göster
	    BT_ToggleButton1:Show();
	end
	ItemTextPageText:SetText(BT_text_tr);
	if (BT_PM["showID"]=="1") then				 -- kitap ID'sini göster
       BT_ToggleButton0:SetText("Book ID: "..BT_bookID.." (TR)");
	else
       BT_ToggleButton0:SetText("TR");
	end
  else
    BT_act_tr = "0";
    if (BT_PM["title"] == "1") then			 -- başlık çevirisini göster
       BT_ToggleButton1:Hide();
	end
	ItemTextPageText:SetText(BT_text_en);
	if (BT_PM["showID"]=="1") then				 -- kitap ID'sini göster
       BT_ToggleButton0:SetText("Book ID: "..BT_bookID.." (EN)");
	else
       BT_ToggleButton0:SetText("EN");
	end
  end
end


function BookTranslator_SlashCommand(msg)
  -- komutu denetle
  if (msg) then
     local BT_command = string.lower(msg);                -- normalleştir, yalnız küçük harf
     if ((BT_command=="on") or (BT_command=="1")) then    -- aktiflik anahtarını aç
        BT_PM["active"]="1";
        WTR_Print("Kitaplar "..BT_Messages.is_now_active);
     elseif ((BT_command=="off") or (BT_command=="0")) then
        BT_PM["active"]="0";
        WTR_Print("Kitaplar "..BT_Messages.is_now_not_active);
     else
  	     InterfaceOptionsFrame_Show();
  	     InterfaceOptionsFrame_OpenToCategory("Kitaplar");
  	     InterfaceOptionsFrame_OpenToCategory("Kitaplar");
     end
  end
end


function BookTranslator_CheckVars()
  if (not BT_PM) then
     BT_PM = {};
  end
  if (not BT_SAVED) then
     BT_SAVED = {};
  end
  -- seçenek varsayılanlarını ilkle
  if (not BT_PM["active"] ) then    -- eklenti aktif
     BT_PM["active"] = "1";
  end
  if (not BT_PM["title"] ) then     -- başlık çevirisini göster
     BT_PM["title"] = "1";
  end
  if (not BT_PM["setsize"] ) then   -- yazı boyutu değiştirmeyi etkinleştir
     BT_PM["setsize"] = "1";
  end
  if (not BT_PM["fontsize"] ) then  -- yazı boyutu
     BT_PM["fontsize"] = "15";
  end
  if (not BT_PM["saveNW"] ) then    -- çevrilmemişi kaydet
     BT_PM["saveNW"] = "1";
  end
  if (not BT_PM["showID"] ) then    -- kitap kimliğini göster (çevirmen aracı; varsayılan kapalı)
     BT_PM["showID"] = "0";
  end
end

function BookTranslator_SetCheckButtonState()
  BookTranslatorCheckButton0:SetChecked(BT_PM["active"]=="1");
  BookTranslatorCheckButton1:SetChecked(BT_PM["title"]=="1");
  BookTranslatorCheckButton5:SetChecked(BT_PM["saveNW"]=="1");
  BookTranslatorCheckButton3:SetChecked(BT_PM["showID"]=="1");
  BookTranslatorCheckSize:SetChecked(BT_PM["setsize"]=="1");
  local fontsize = tonumber(BT_PM["fontsize"]);
  BookTranslatorslider:SetValue(fontsize);
  if (BT_PM["setsize"]=="1") then
     BookTranslatorOpis1:SetFont(BT_Font, fontsize);
  else
     BookTranslatorOpis1:SetFont(BT_Font, 13);
  end
end


function BookTranslator_BlizzardOptions()

-- Bilgi metni için ana frame oluştur
local BookTranslatorOptions = CreateFrame("FRAME", "BookTranslatorOptions");
BookTranslatorOptions.refresh = function (self) BookTranslator_SetCheckButtonState() end;
BookTranslatorOptions.name = "Kitaplar";
BookTranslatorOptions.parent = "WotLK TR";
InterfaceOptions_AddCategory(BookTranslatorOptions);

local BookTranslatorOptionsHeader = BookTranslatorOptions:CreateFontString(nil, "ARTWORK");
BookTranslatorOptionsHeader:SetFontObject(GameFontNormalLarge);
BookTranslatorOptionsHeader:SetJustifyH("LEFT");
BookTranslatorOptionsHeader:SetJustifyV("TOP");
BookTranslatorOptionsHeader:ClearAllPoints();
BookTranslatorOptionsHeader:SetPoint("TOPLEFT", 16, -16);
BookTranslatorOptionsHeader:SetText("Kitaplar · sürüm "..BT_version.." ("..BT_base..")");

local BookOptionsDate = BookTranslatorOptions:CreateFontString(nil, "ARTWORK");
BookOptionsDate:SetFontObject(GameFontNormalLarge);
BookOptionsDate:SetJustifyH("LEFT");
BookOptionsDate:SetJustifyV("TOP");
BookOptionsDate:ClearAllPoints();
BookOptionsDate:SetPoint("TOPRIGHT", BookTranslatorOptionsHeader, "TOPRIGHT", 0, -22);
BookOptionsDate:SetText("Veritabanı: "..BT_date);
BookOptionsDate:SetFont(BT_Font, 16);

local BookTranslatorCheckButton0 = CreateFrame("CheckButton", "BookTranslatorCheckButton0", BookTranslatorOptions, "OptionsCheckButtonTemplate");
BookTranslatorCheckButton0:SetPoint("TOPLEFT", BookTranslatorOptionsHeader, "BOTTOMLEFT", 0, -40);
BookTranslatorCheckButton0:SetScript("OnClick", function(self) if (BT_PM["active"]=="1") then BT_PM["active"]="0" else BT_PM["active"]="1" end; end);
BookTranslatorCheckButton0Text:SetFont(BT_Font, 13);
BookTranslatorCheckButton0Text:SetText(BT_Interface.active);     -- eklenti aktif

local BookTranslatorCheckButton1 = CreateFrame("CheckButton", "BookTranslatorCheckButton1", BookTranslatorOptions, "OptionsCheckButtonTemplate");
BookTranslatorCheckButton1:SetPoint("TOPLEFT", BookTranslatorCheckButton0, "BOTTOMLEFT", 20, -10);
BookTranslatorCheckButton1:SetScript("OnClick", function(self) if (BT_PM["title"]=="1") then BT_PM["title"]="0" else BT_PM["title"]="1" end; end);
BookTranslatorCheckButton1Text:SetFont(BT_Font, 13);
BookTranslatorCheckButton1Text:SetText(BT_Interface.title);      -- başlığı çevir

local BookTranslatorCheckButton5 = CreateFrame("CheckButton", "BookTranslatorCheckButton5", BookTranslatorOptions, "OptionsCheckButtonTemplate");
BookTranslatorCheckButton5:SetPoint("TOPLEFT", BookTranslatorCheckButton1, "BOTTOMLEFT", 0, 0);
BookTranslatorCheckButton5:SetScript("OnClick", function(self) if (BT_PM["saveNW"]=="1") then BT_PM["saveNW"]="0" else BT_PM["saveNW"]="1" end; end);
BookTranslatorCheckButton5Text:SetFont(BT_Font, 13);
BookTranslatorCheckButton5Text:SetText(BT_Interface.saveNW);     -- çevrilmemiş kitapları kaydet

local BookTranslatorCheckButton3 = CreateFrame("CheckButton", "BookTranslatorCheckButton3", BookTranslatorOptions, "OptionsCheckButtonTemplate");
BookTranslatorCheckButton3:SetPoint("TOPLEFT", BookTranslatorCheckButton5, "BOTTOMLEFT", 0, 0);
BookTranslatorCheckButton3:SetScript("OnClick", function(self) if (BT_PM["showID"]=="1") then BT_PM["showID"]="0" else BT_PM["showID"]="1" end; end);
BookTranslatorCheckButton3Text:SetFont(BT_Font, 13);
BookTranslatorCheckButton3Text:SetText(BT_Interface.showID);     -- kitap kimliğini göster

local BookTranslatorCheckSize = CreateFrame("CheckButton", "BookTranslatorCheckSize", BookTranslatorOptions, "OptionsCheckButtonTemplate");
BookTranslatorCheckSize:SetPoint("TOPLEFT", BookTranslatorCheckButton3, "BOTTOMLEFT", 0, -20);
BookTranslatorCheckSize:SetScript("OnClick", function(self) if (BT_PM["setsize"]=="1") then BT_PM["setsize"]="0" else BT_PM["setsize"]="1" end; end);
BookTranslatorCheckSizeText:SetText("Yazı Boyutunu Ayarla");
BookTranslatorCheckSizeText:SetFont(BT_Font, 13);
local BookOptionsDod2 = BookTranslatorOptions:CreateFontString(nil, "ARTWORK");
BookOptionsDod2:SetFontObject(GameFontNormalLarge);
BookOptionsDod2:SetJustifyH("LEFT");
BookOptionsDod2:SetJustifyV("TOP");
BookOptionsDod2:ClearAllPoints();
BookOptionsDod2:SetPoint("TOPLEFT", BookTranslatorCheckSize, "BOTTOMLEFT", 25, 0);
BookOptionsDod2:SetText("(her zaman çalışmaz)");
BookOptionsDod2:SetFont(BT_Font, 13);

local BookTranslatorslider = CreateFrame("Slider", "BookTranslatorslider", BookTranslatorOptions, "OptionsSliderTemplate");
BookTranslatorslider:SetPoint("TOPLEFT", BookTranslatorCheckSize, "BOTTOMLEFT", 10, -40);
BookTranslatorslider:SetMinMaxValues(10, 20);
BookTranslatorslider.minValue, BookTranslatorslider.maxValue = BookTranslatorslider:GetMinMaxValues();
getglobal(BookTranslatorslider:GetName() .. 'Text'):SetText('Yazı Boyutu');
getglobal(BookTranslatorslider:GetName() .. 'Text'):SetFont(BT_Font, 13);
BookTranslatorslider:SetValue(tonumber(BT_PM["fontsize"]));
BookTranslatorslider:SetValueStep(1);
BookTranslatorslider:SetScript("OnValueChanged", function(self,event,arg1)
                                      BT_PM["fontsize"]=string.format("%d",event);
                                      BookTranslatorsliderVal:SetText(BT_PM["fontsize"]);
									           BookTranslatorOpis1:SetFont(BT_Font, event);
                                      end);
BookTranslatorsliderVal = BookTranslatorOptions:CreateFontString(nil, "ARTWORK");
BookTranslatorsliderVal:SetFontObject(GameFontNormal);
BookTranslatorsliderVal:SetJustifyH("CENTER");
BookTranslatorsliderVal:SetJustifyV("TOP");
BookTranslatorsliderVal:ClearAllPoints();
BookTranslatorsliderVal:SetPoint("CENTER", BookTranslatorslider, "CENTER", 0, -12);
BookTranslatorsliderVal:SetText(BT_PM["fontsize"]);
BookTranslatorsliderVal:SetFont(BT_Font, 13);

BookTranslatorOpis1 = BookTranslatorOptions:CreateFontString(nil, "ARTWORK");
BookTranslatorOpis1:SetFontObject(GameFontNormalLarge);
BookTranslatorOpis1:SetJustifyH("LEFT");
BookTranslatorOpis1:SetJustifyV("TOP");
BookTranslatorOpis1:ClearAllPoints();
BookTranslatorOpis1:SetPoint("TOPLEFT", BookTranslatorslider, "BOTTOMLEFT", 0, -30);
local fontsize = tonumber(BT_PM["fontsize"]);
if (BT_PM["setsize"]=="1") then
   BookTranslatorOpis1:SetFont(BT_Font, fontsize);
else
   BookTranslatorOpis1:SetFont(BT_Font, 13);
end
BookTranslatorOpis1:SetText("Örnek Metin");

local IOF_Height = InterfaceOptionsFrame:GetHeight();
   if (IOF_Height>658) then

   local BookTranslatorText0 = BookTranslatorOptions:CreateFontString(nil, "ARTWORK");
   BookTranslatorText0:SetFontObject(GameFontWhite);
   BookTranslatorText0:SetJustifyH("LEFT");
   BookTranslatorText0:SetJustifyV("TOP");
   BookTranslatorText0:ClearAllPoints();
   BookTranslatorText0:SetPoint("TOPLEFT", BookTranslatorslider, "BOTTOMLEFT", -5, -40);
   BookTranslatorText0:SetFont(BT_Font, 13);
   BookTranslatorText0:SetText("Sohbet satırı hızlı komutları");

   local BookTranslatorText7 = BookTranslatorOptions:CreateFontString(nil, "ARTWORK");
   BookTranslatorText7:SetFontObject(GameFontWhite);
   BookTranslatorText7:SetJustifyH("LEFT");
   BookTranslatorText7:SetJustifyV("TOP");
   BookTranslatorText7:ClearAllPoints();
   BookTranslatorText7:SetPoint("TOPLEFT", BookTranslatorText0, "BOTTOMLEFT", 0, -10);
   BookTranslatorText7:SetFont(BT_Font, 13);
   BookTranslatorText7:SetText("/btr   bu ayar penceresini açar");

   local BookTranslatorText1 = BookTranslatorOptions:CreateFontString(nil, "ARTWORK");
   BookTranslatorText1:SetFontObject(GameFontWhite);
   BookTranslatorText1:SetJustifyH("LEFT");
   BookTranslatorText1:SetJustifyV("TOP");
   BookTranslatorText1:ClearAllPoints();
   BookTranslatorText1:SetPoint("TOPLEFT", BookTranslatorText7, "BOTTOMLEFT", 0, -10);
   BookTranslatorText1:SetFont(BT_Font, 13);
   BookTranslatorText1:SetText("/btr 1  veya  /btr on   eklentiyi açar");

   local BookTranslatorText2 = BookTranslatorOptions:CreateFontString(nil, "ARTWORK");
   BookTranslatorText2:SetFontObject(GameFontWhite);
   BookTranslatorText2:SetJustifyH("LEFT");
   BookTranslatorText2:SetJustifyV("TOP");
   BookTranslatorText2:ClearAllPoints();
   BookTranslatorText2:SetPoint("TOPLEFT", BookTranslatorText1, "BOTTOMLEFT", 0, -4);
   BookTranslatorText2:SetFont(BT_Font, 13);
   BookTranslatorText2:SetText("/btr 0  veya  /btr off   eklentiyi kapatır");
end

-- (web sitesi kutusu kaldırıldı)

end

ItemTextFrame:HookScript("OnShow", function() BookTranslator_ShowTranslation() end);
ItemTextNextPageButton:HookScript("OnClick", function() BookTranslator_ShowTranslation() end);
ItemTextPrevPageButton:HookScript("OnClick", function() BookTranslator_ShowTranslation() end);
SlashCmdList["WOWTR_BOOKS"] = function(msg) BookTranslator_SlashCommand(msg); end
SLASH_WOWTR_BOOKS1 = "/wtrbooks";
SLASH_WOWTR_BOOKS2 = "/btr";
BookTranslator_CheckVars();
BookTranslator_BlizzardOptions();

BT_ToggleButton0 = CreateFrame("Button",nil, ItemTextFrame, "UIPanelButtonTemplate");
BT_ToggleButton0:SetWidth(40);
BT_ToggleButton0:SetHeight(20);
BT_ToggleButton0:SetText("EN");
BT_ToggleButton0:Show();
BT_ToggleButton0:ClearAllPoints();
BT_ToggleButton0:SetPoint("BOTTOMRIGHT", ItemTextFrame, "BOTTOMRIGHT", -64, 80);
BT_ToggleButton0:SetScript("OnClick", BT_ON_OFF);

BT_ToggleButton1 = CreateFrame("Button",nil, ItemTextFrame, "UIPanelButtonTemplate");
BT_ToggleButton1:SetWidth(270);
BT_ToggleButton1:SetHeight(20);
BT_ToggleButton1:SetText("");
BT_ToggleButton1:Hide();
BT_ToggleButton1:ClearAllPoints();
BT_ToggleButton1:SetPoint("TOPLEFT", ItemTextFrame, "TOPLEFT", 65, -15);

WTR_LOADED_BOOKS = true;   -- motor sonuna kadar yüklendi (Core özetinde gösterilir)
WTR_Print("Kitaplar motoru yüklendi (v"..BT_version..")", "debug");

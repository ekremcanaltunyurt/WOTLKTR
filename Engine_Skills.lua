-- ============================================================
--  WotLK TR  ·  Engine_Skills.lua
--  Yetenekler: Talent ve büyü (spellbook) tooltip'lerini Türkçe gösterir.
--
--  İki yöntem (oyun tooltip'i sayıları yerleştirilmiş halde verir):
--   • Talent → TAM-SATIR eşleştirme (her rank metni ayrı anahtar; sabit sayı).
--   • Büyü   → ŞABLON eşleştirme: sayılar yer-tutucuya inilir ({1},{2}), şablon
--     çevrilir, oyundaki canlı sayılar geri konur → gear/spell power ile kayan
--     sayı sorunu çözülür. Tek şablon, o büyünün tüm rank/gear hallerini kapsar.
--  Eşleşmeyen açıklamalar (şablon olarak) SK_SAVED'e düşer → sonradan çevrilir.
--
--  Veri: Talents_TR.lua → SK_TalentTR["norm en"]="tr"
--        Spells_TR.lua  → SK_SpellTR["şablon en"]="şablon tr"
--        Glyphs_TR.lua  → SK_GlyphTR["şablon en"]="şablon tr"  (glyph eşya tooltip'i)
--  Bağımlılık: Core_TR.lua (WTR_Print, QTR_Font2).
-- ============================================================

local SK_version = GetAddOnMetadata("WOTLKTR", "Version");

-- Küçük statik etiketler (tooltip'te tam-satır olarak geçenler)
local SK_StaticTR = {
   ["Next rank:"]      = "Sonraki seviye:",
   ["Unlearn"]         = "Unutulur",
};


-- ============================================================
--  1) METİN NORMALİZASYONU + ARAMA
-- ============================================================

-- Tooltip satırını ve tablo anahtarlarını aynı biçime getirir:
-- renk kodlarını söker, boşlukları teke indirir, kırpar.
-- (JSON kaynağındaki çift boşluk ile oyunun tek boşluğu eşleşsin diye.)
local function SK_Norm(s)
   if (type(s) ~= "string") then return ""; end
   s = s:gsub("|c%x%x%x%x%x%x%x%x", "");   -- renk kodu başlangıcı |cAARRGGBB
   s = s:gsub("|r", "");                    -- renk kodu sonu
   s = s:gsub("%s+", " ");                  -- tüm boşluk dizilerini teke indir
   s = s:gsub("^ ", "");                    -- baştaki boşluğu at
   s = s:gsub(" $", "");                    -- sondaki boşluğu at
   return s;
end

-- Sayıları yer-tutucuya çevirir: "100 ila 150" -> "{1} ila {2}"; sayıları sırayla döndürür.
-- (Büyü açıklamaları gear/spell power ile kaydığından şablon eşleştirme için.)
-- Python veri üretimiyle BİREBİR aynı olmalı: saf rakam dizisi (%d+), soldan sağa.
local function SK_Templatize(s)
   local nums = {};
   local out = (s:gsub("%d+", function(d) nums[#nums+1] = d; return "{" .. #nums .. "}"; end));
   return out, nums;
end

-- Şablondaki {1},{2}... yer-tutucularını yakalanan sayılarla doldurur.
local function SK_Render(tmpl, nums)
   return (tmpl:gsub("{(%d+)}", function(k) return nums[tonumber(k)] or ("{" .. k .. "}"); end));
end

-- Bir satırın Türkçesini döndürür; yoksa nil.
--   1) talent: tam-satır eşleştirme (SK_TalentTR)
--   2) statik etiketler (SK_StaticTR)
--   3) büyü: şablon eşleştirme (SK_SpellTR) — sayılar yerinde tutulur
local function SK_TranslateLine(text, allowSpell)
   if (type(text) ~= "string" or text == "") then return nil; end
   local key = SK_Norm(text);
   if (key == "") then return nil; end
   if (SK_TalentTR and SK_TalentTR[key]) then return SK_TalentTR[key]; end
   if (SK_StaticTR[key]) then return SK_StaticTR[key]; end
   if (allowSpell) then
      local tmpl, nums = SK_Templatize(key);
      if (SK_SpellTR and SK_SpellTR[tmpl]) then return SK_Render(SK_SpellTR[tmpl], nums); end
      if (SK_TalentTmplTR and SK_TalentTmplTR[tmpl]) then return SK_Render(SK_TalentTmplTR[tmpl], nums); end
      if (SK_GlyphTR and SK_GlyphTR[tmpl]) then return SK_Render(SK_GlyphTR[tmpl], nums); end
   end
   return nil;
end

-- Çevrilemeyen, cümle benzeri açıklamaları sonradan çevirmek için kaydet — ŞABLON olarak
-- (rank/gear sayıları yer-tutucuya indiğinden liste kendiliğinden tekilleşir).
local function SK_LogMiss(text)
   if (not SK_PM or SK_PM["savemiss"] ~= "1") then return; end
   if (type(text) ~= "string") then return; end
   local key = SK_Norm(text);
   if (#key < 25) then return; end           -- kısa etiket/sayı satırlarını loglama
   -- zaten Türkçe'ye çevirdiğimiz satırları tekrar loglama (tooltip 2. kez tetiklenince
   -- kendi çevirimizi "miss" sanmasın): Türkçe'ye özgü harf (ı ş ğ ç ö ü) varsa atla.
   if (key:find("\196\177",1,true) or key:find("\197\159",1,true) or key:find("\196\159",1,true)
       or key:find("\195\167",1,true) or key:find("\195\182",1,true) or key:find("\195\188",1,true)) then
      return;
   end
   local tmpl = SK_Templatize(key);
   if (not SK_SAVED) then SK_SAVED = {}; end
   SK_SAVED[tmpl] = (SK_SAVED[tmpl] or 0) + 1;  -- kaç kez görüldüğünü say
end


-- ============================================================
--  2) TOOLTIP'İ YENİDEN YAZ
--  Tooltip'in sol satırlarını gezer; çevirisi olanı Türkçeye çevirir.
--  Çevrilen satırın fontunu QTR_Font2'ye alır (ğ/ı/ş düzgün görünsün;
--  bu font oyunun tooltip fontuyla aynı ailedendir → yamalı durmaz).
-- ============================================================

local function SK_RewriteTooltip(tooltip, doLog)
   if (SK_PM and SK_PM["active"] == "0") then return; end
   if (not tooltip or not tooltip.GetName) then return; end
   local name = tooltip:GetName();
   if (not name) then return; end
   local allowSpell = (not SK_PM) or (SK_PM["spells"] ~= "0");
   local n = tooltip:NumLines();
   local changed = false;
   for i = 1, n do
      local fs = _G[name .. "TextLeft" .. i];
      if (fs) then
         local txt = fs:GetText();
         local tr = SK_TranslateLine(txt, allowSpell);
         if (tr) then
            local _, h, flags = fs:GetFont();
            fs:SetFont(QTR_Font2, h or 12, flags);
            fs:SetText(tr);
            changed = true;
         elseif (doLog and i > 1 and txt) then   -- 1. satır = başlık (ad), loglama
            SK_LogMiss(txt);
         end
      end
   end
   if (changed) then tooltip:Show(); end          -- metin değişti → yeniden boyutlandır
end


-- ============================================================
--  2.5) CAPTURE HARNESS  ( /sktr capture )
--  Oyunun KENDİSİNE render ettirip topla — tek karakter, tüm class, beklemeden.
--   (1) Kendi büyü kitabını SetSpell ile gezer (kendi class'ı garanti; motorla
--       AYNI tooltip yolu → eşleşme kesin).
--   (2) SK_CaptureIDs'teki TÜM class spell'lerini SetHyperlink "spell:id" ile
--       render eder (oyuncu bilmese de) → diğer class'lar.
--  Her ikisinde de SK_RewriteTooltip çevrilmemişi SK_SAVED'e loglar.
-- ============================================================

local SK_capTip;
local SK_capRunning = false;

local function SK_GetCapTip()
   if (not SK_capTip) then
      SK_capTip = CreateFrame("GameTooltip", "SK_CaptureScanTip", UIParent, "GameTooltipTemplate");
      SK_capTip:SetAlpha(0);                         -- görünmez tarama tooltip'i
   end
   SK_capTip:SetOwner(UIParent, "ANCHOR_NONE");
   return SK_capTip;
end

local function SK_SavedCount()
   local n = 0;
   if (SK_SAVED) then for _ in pairs(SK_SAVED) do n = n + 1; end end
   return n;
end

-- Kendi büyü kitabı: senkron, kendi class'ı garanti (motorla aynı SetSpell yolu).
local function SK_CaptureSpellbook(tip)
   if (type(GetSpellName) ~= "function" or not BOOKTYPE_SPELL) then return 0; end
   local i, done = 1, 0;
   while (i <= 1024) do
      if (not GetSpellName(i, BOOKTYPE_SPELL)) then break; end
      tip:ClearLines();
      if (pcall(tip.SetSpell, tip, i, BOOKTYPE_SPELL)) then
         pcall(SK_RewriteTooltip, tip, true);
         done = done + 1;
      end
      i = i + 1;
   end
   return done;
end

-- /sktr capture : tek karakterden tüm class spell'lerini topla.
local function SK_RunCapture()
   if (SK_capRunning) then WTR_Print("capture zaten çalışıyor…"); return; end
   SK_CheckVars();
   SK_PM["active"]   = "1";                          -- capture için çeviri+loglama açık olmalı
   SK_PM["savemiss"] = "1";
   SK_capRunning = true;
   local tip    = SK_GetCapTip();
   local before = SK_SavedCount();

   local own = SK_CaptureSpellbook(tip);             -- 1) kendi kitabı

   if (type(SK_CaptureIDs) ~= "table") or (#SK_CaptureIDs == 0) then
      SK_capRunning = false;
      WTR_Print("capture bitti — SK_CaptureIDs yok; sadece büyü kitabın tarandı (" .. own .. "). "
         .. (SK_SavedCount() - before) .. " yeni şablon. /reload yap, dosyayı gönder.", "warn");
      return;
   end

   local total, idx = #SK_CaptureIDs, 0;             -- 2) tüm class (ID'den render, parçalı)
   WTR_Print("capture başladı — büyü kitabı (" .. own .. ") + " .. total
      .. " ID taranıyor (oyun kısa süre takılabilir)…");
   local driver = CreateFrame("Frame");
   driver:SetScript("OnUpdate", function(self)
      local batch = 0;
      while (idx < total) and (batch < 60) do
         idx = idx + 1; batch = batch + 1;
         tip:ClearLines();
         pcall(tip.SetHyperlink, tip, "spell:" .. tostring(SK_CaptureIDs[idx]));
         pcall(SK_RewriteTooltip, tip, true);
      end
      if (idx >= total) then
         self:SetScript("OnUpdate", nil);
         if (SK_capTip) then SK_capTip:Hide(); end
         SK_capRunning = false;
         WTR_Print("capture BİTTİ — " .. total .. " spell + " .. own .. " büyü tarandı; "
            .. (SK_SavedCount() - before) .. " YENİ çevrilmemiş şablon yakalandı.");
         WTR_Print(">> /reload yap (kayıt diske yazılsın), sonra SavedVariables/WOTLKTR.lua'yı gönder.");
      end
   end);
end


-- ============================================================
--  3) AYAR DEĞİŞKENLERİ
-- ============================================================

function SK_CheckVars()
   if (not SK_PM)    then SK_PM = {}; end
   if (not SK_SAVED) then SK_SAVED = {}; end
   if (not SK_PM["active"])   then SK_PM["active"]   = "1"; end   -- çeviri açık (talent+büyü)
   if (not SK_PM["spells"])   then SK_PM["spells"]   = "1"; end   -- büyü açıklamalarını da çevir
   if (not SK_PM["savemiss"]) then SK_PM["savemiss"] = "1"; end   -- çevrilmemişi kaydet
end

function SK_SetCheckButtonState()
   SKCheckButton1:SetChecked(SK_PM["active"]   == "1");
   SKCheckButton3:SetChecked(SK_PM["spells"]   == "1");
   SKCheckButton2:SetChecked(SK_PM["savemiss"] == "1");
end


-- ============================================================
--  4) ARAYÜZ (Esc → Arayüz → AddOns → WotLK TR → Yetenekler)
-- ============================================================

function SK_BlizzardOptions()

local SKOptions = CreateFrame("FRAME", "WoWTRSkillsOptions");
SKOptions.refresh = function(self) SK_SetCheckButtonState() end;
SKOptions.name = "Yetenekler";
SKOptions.parent = "WotLK TR";
InterfaceOptions_AddCategory(SKOptions);

-- yüklü çeviri sayıları (tanılama)
local nT = 0;
if (SK_TalentTR) then for _ in pairs(SK_TalentTR) do nT = nT + 1; end end
local nS = 0;
if (SK_SpellTR) then for _ in pairs(SK_SpellTR) do nS = nS + 1; end end
local nG = 0;
if (SK_GlyphTR) then for _ in pairs(SK_GlyphTR) do nG = nG + 1; end end

local SKHeader1 = SKOptions:CreateFontString(nil, "ARTWORK");
SKHeader1:SetFontObject(GameFontNormalLarge);
SKHeader1:SetJustifyH("LEFT");
SKHeader1:SetPoint("TOPLEFT", 16, -16);
SKHeader1:SetText("Yetenekler");

local SKHeader2 = SKOptions:CreateFontString(nil, "ARTWORK");
SKHeader2:SetFont(QTR_Font2, 14);
SKHeader2:SetJustifyH("LEFT");
SKHeader2:SetPoint("TOPLEFT", SKHeader1, "BOTTOMLEFT", 0, -8);
SKHeader2:SetText("Talent ve büyü açıklamalarını Türkçe gösterir  —  sürüm " .. (SK_version or "?"));

local SKDate = SKOptions:CreateFontString(nil, "ARTWORK");
SKDate:SetFont(QTR_Font2, 13);
SKDate:SetJustifyH("LEFT");
SKDate:SetPoint("TOPLEFT", SKHeader2, "BOTTOMLEFT", 0, -10);
SKDate:SetText("Yüklü çeviri: " .. nT .. " talent · " .. nS .. " büyü · " .. nG .. " glyph");

local SKDesc = SKOptions:CreateFontString(nil, "ARTWORK");
SKDesc:SetFont(QTR_Font2, 13);
SKDesc:SetJustifyH("LEFT");
SKDesc:SetPoint("TOPLEFT", SKDate, "BOTTOMLEFT", 0, -14);
SKDesc:SetText("Talent ve büyü açıklamaları, üzerine gelince Türkçe görünür.\nÇevrilmemiş açıklamalar /sktr ile listelenebilir.");

local SKCheckButton1 = CreateFrame("CheckButton", "SKCheckButton1", SKOptions, "OptionsCheckButtonTemplate");
SKCheckButton1:SetPoint("TOPLEFT", SKDesc, "BOTTOMLEFT", 0, -16);
SKCheckButton1:SetScript("OnClick", function(self) if (SK_PM["active"]=="1") then SK_PM["active"]="0" else SK_PM["active"]="1" end; end);
SKCheckButton1Text:SetText("Çeviriyi Etkinleştir");
SKCheckButton1Text:SetFont(QTR_Font2, 13);

local SKCheckButton3 = CreateFrame("CheckButton", "SKCheckButton3", SKOptions, "OptionsCheckButtonTemplate");
SKCheckButton3:SetPoint("TOPLEFT", SKCheckButton1, "BOTTOMLEFT", 0, 0);
SKCheckButton3:SetScript("OnClick", function(self) if (SK_PM["spells"]=="1") then SK_PM["spells"]="0" else SK_PM["spells"]="1" end; end);
SKCheckButton3Text:SetText("Büyü ve Glyph'leri de Çevir");
SKCheckButton3Text:SetFont(QTR_Font2, 13);

local SKCheckButton2 = CreateFrame("CheckButton", "SKCheckButton2", SKOptions, "OptionsCheckButtonTemplate");
SKCheckButton2:SetPoint("TOPLEFT", SKCheckButton3, "BOTTOMLEFT", 0, 0);
SKCheckButton2:SetScript("OnClick", function(self) if (SK_PM["savemiss"]=="1") then SK_PM["savemiss"]="0" else SK_PM["savemiss"]="1" end; end);
SKCheckButton2Text:SetText("Çevrilmemiş Açıklamaları Kaydet");
SKCheckButton2Text:SetFont(QTR_Font2, 13);

end


-- ============================================================
--  5) SLASH KOMUTU  ( /sktr , /wtrskills )
-- ============================================================

function SK_SlashCommand(msg)
   msg = string.lower(msg or "");
   local nT = 0; if (SK_TalentTR) then for _ in pairs(SK_TalentTR) do nT = nT + 1; end end
   local nS = 0; if (SK_SpellTR)  then for _ in pairs(SK_SpellTR)  do nS = nS + 1; end end
   local nG = 0; if (SK_GlyphTR)  then for _ in pairs(SK_GlyphTR)  do nG = nG + 1; end end
   local nM = 0; if (SK_SAVED)    then for _ in pairs(SK_SAVED)    do nM = nM + 1; end end
   if (msg == "list" or msg == "saved") then
      WTR_Print("kaydedilen çevrilmemiş açıklamalar (" .. nM .. "):");
      local c = 0;
      for k in pairs(SK_SAVED or {}) do
         WTR_Print("  • " .. k);
         c = c + 1;
         if (c >= 20) then WTR_Print("  ... (ilk 20 gösterildi)"); break; end
      end
      if (nM == 0) then WTR_Print("  (liste boş — ya hepsi çevrildi ya da hiç talent'e bakılmadı)"); end
   elseif (msg == "clear") then
      SK_SAVED = {};
      WTR_Print("çevrilmemiş listesi temizlendi.");
   elseif (msg == "capture" or msg == "tara") then
      SK_RunCapture();
   else
      WTR_Print("Yetenekler — " .. nT .. " talent · " .. nS .. " büyü · " .. nG .. " glyph yüklü · " .. nM .. " çevrilmemiş kayıt");
      WTR_Print("komutlar:  /sktr capture  (tüm class spell'lerini tara)  ·  /sktr list  ·  /sktr clear");
   end
end

SlashCmdList["WOWTR_SKILLS"] = function(msg) SK_SlashCommand(msg); end
SLASH_WOWTR_SKILLS1 = "/wtrskills";
SLASH_WOWTR_SKILLS2 = "/sktr";


-- ============================================================
--  6) KUR + HOOK'LAR
-- ============================================================

SK_CheckVars();
SK_BlizzardOptions();

-- Talent tooltip'i: TalentFrame bir talent'in üstüne gelince SetTalent çağırır.
hooksecurefunc(GameTooltip, "SetTalent", function(self) SK_RewriteTooltip(self, true); end);

-- Büyü tooltip'i (büyü kitabı/aksiyon çubuğu): şablon eşleştirmeyle çevirir + eşleşmeyeni loglar.
GameTooltip:HookScript("OnTooltipSetSpell", function(self) SK_RewriteTooltip(self, true); end);

-- Eşya tooltip'i (çantadaki glyph eşyaları): şablon eşleştirmeyle çevirir (her eşyada çalışır, loglamaz).
GameTooltip:HookScript("OnTooltipSetItem", function(self) SK_RewriteTooltip(self, false); end);

-- Glyph YUVASI tooltip'i (Yetenek ekranı → Glyph sekmesi): GlyphFrameGlyph_OnEnter,
-- GameTooltip:SetGlyph(id, talentGroup) kullanır → OnTooltipSet* TETİKLEMEZ, ayrıca kancalanmalı.
-- (SetGlyph taban C-metod; guard'lı. doLog=true → eşleşmeyen glyph metni SK_SAVED'e düşsün.)
if (GameTooltip.SetGlyph) then
   hooksecurefunc(GameTooltip, "SetGlyph", function(self) SK_RewriteTooltip(self, true); end);
end

WTR_LOADED_SKILLS = true;   -- motor sonuna kadar yüklendi (Core özetinde ✓)

-- ============================================================
--  WotLK TR  ·  Core_TR.lua
--  Çekirdek: Tanılama (diagnostics) + Türkçe arayüz metinleri + fontlar
--
--  Bu dosya TOC'ta İLK yüklenir. Motorlar (Engine_*.lua) buradaki
--  WTR_Print / QTR_Messages / QTR_Interface / QTR_Font* global'lerine dayanır.
-- ============================================================

WTR_VERSION = "0.1.0-beta";
WTR_ADDON   = "WotLK TR";


-- ============================================================
--  1) TANILAMA (Diagnostics)
--  Amaç: test ancak en sonda yapılabildiği için, sorun olursa
--  oyunda NEREDE/NEDEN kırıldığı net görünsün.
-- ============================================================

-- Seviyeye göre renk kodları
local WTR_COLORS = {
   info  = "|cff55ff55",   -- yeşil
   debug = "|cff7f9fff",   -- mavi
   warn  = "|cffffcc00",   -- sarı
   error = "|cffff4040",   -- kırmızı
};

-- Debug modu açık mı? (QTR_PS["debug"] SavedVariable'ında saklanır)
function WTR_IsDebug()
   return (QTR_PS ~= nil and QTR_PS["debug"] == "1");
end

-- Tek mesaj fonksiyonu: addon'un TÜM sohbet çıktısı buradan geçer.
--   level: "info" (varsayılan) | "debug" | "warn" | "error"
--   debug seviyesi yalnız debug modu açıkken görünür.
function WTR_Print(msg, level)
   level = level or "info";
   if (level == "debug" and not WTR_IsDebug()) then
      return;
   end
   local color = WTR_COLORS[level] or WTR_COLORS.info;
   DEFAULT_CHAT_FRAME:AddMessage(color .. "[WotLK TR]|r " .. tostring(msg));
end

-- Güvenli çağrı: fn'i pcall ile çalıştırır; hata olursa NEREDE patladığını
-- bildirir ve devam eder (tek bozuk girdi tüm addon'u dondurmaz/düşürmez).
--   Kullanım: WTR_Safe("Quests/expand ID "..id, function() ... end)
function WTR_Safe(etiket, fn)
   local ok, err = pcall(fn);
   if (not ok) then
      WTR_Print("HATA [" .. tostring(etiket) .. "]: " .. tostring(err), "error");
   end
   return ok;
end

-- Bir tablonun girdi sayısı (nil ise "nil" döner — yüklenmemiş demektir)
local function WTR_Count(t)
   if (type(t) ~= "table") then return "|cffff4040nil|r"; end
   local n = 0;
   for _ in pairs(t) do n = n + 1; end
   return n;
end

-- Motor yükleme işareti: Engine_*.lua sonuna kadar çalıştıysa ilgili global
-- bayrak true olur; nil ise o motor yüklenirken hata olmuş demektir.
local function WTR_LoadMark(flag)
   if (flag) then return "|cff55ff55yüklü|r"; else return "|cffff4040YOK|r"; end
end

-- Yükleme özeti: her veri tablosunun girdi sayısı tek satırda.
-- Boş/nil tablo = ilgili dosya yüklenmedi → kırılma noktası anında belli.
function WTR_PrintLoadSummary()
   WTR_Print("yüklendi (v" .. WTR_VERSION .. ") · "
      .. "Quests:"    .. WTR_Count(QTR_QuestData) .. " "
      .. "QuestList:" .. WTR_Count(QTR_QuestList) .. " "
      .. "Gossip:"    .. WTR_Count(GS_Gossip) .. " "
      .. "Bubbles:"   .. WTR_Count(BB_Bubbles) .. " "
      .. "Movies:"    .. WTR_Count(MF_Hash) .. " "
      .. "Books:"     .. WTR_Count(BT_Books) .. " "
      .. "Tut:"       .. WTR_Count(Tut_Data) .. " "
      .. "Talent:"    .. WTR_Count(SK_TalentTR) .. " "
      .. "Büyü:"      .. WTR_Count(SK_SpellTR) .. " "
      .. "Glyph:"     .. WTR_Count(SK_GlyphTR));
   WTR_Print("motorlar · Quests:" .. WTR_LoadMark(WTR_LOADED_QUESTS)
      .. "  Bubbles:" .. WTR_LoadMark(WTR_LOADED_BUBBLES)
      .. "  Movies:" .. WTR_LoadMark(WTR_LOADED_MOVIES)
      .. "  Books:" .. WTR_LoadMark(WTR_LOADED_BOOKS)
      .. "  Skills:" .. WTR_LoadMark(WTR_LOADED_SKILLS));
end

-- Anlık durum dökümü: /wtr status
function WTR_PrintStatus()
   WTR_Print("durum — " .. WTR_ADDON .. " v" .. WTR_VERSION);
   WTR_Print("  QuestData : " .. WTR_Count(QTR_QuestData));
   WTR_Print("  QuestList : " .. WTR_Count(QTR_QuestList));
   WTR_Print("  Gossip    : " .. WTR_Count(GS_Gossip));
   WTR_Print("  Bubbles   : " .. WTR_Count(BB_Bubbles));
   WTR_Print("  Movies    : " .. WTR_Count(MF_Data) .. " intro / " .. WTR_Count(MF_Hash) .. " altyazı");
   WTR_Print("  Books     : " .. WTR_Count(BT_Books));
   WTR_Print("  Tutorials : " .. WTR_Count(Tut_Data));
   WTR_Print("  Talent    : " .. WTR_Count(SK_TalentTR));
   WTR_Print("  Büyü      : " .. WTR_Count(SK_SpellTR));
   WTR_Print("  Glyph     : " .. WTR_Count(SK_GlyphTR));
   WTR_Print("  Motorlar  : Quests=" .. WTR_LoadMark(WTR_LOADED_QUESTS)
      .. "  Bubbles=" .. WTR_LoadMark(WTR_LOADED_BUBBLES)
      .. "  Movies=" .. WTR_LoadMark(WTR_LOADED_MOVIES)
      .. "  Books=" .. WTR_LoadMark(WTR_LOADED_BOOKS)
      .. "  Skills=" .. WTR_LoadMark(WTR_LOADED_SKILLS));
   if (UnitName) then
      WTR_Print("  Oyuncu    : " .. tostring(UnitName("player"))
         .. " / " .. tostring(UnitRace("player"))
         .. " / " .. tostring(UnitClass("player")));
   end
   WTR_Print("  Debug     : " .. (WTR_IsDebug() and "AÇIK" or "kapalı"));
end

-- /wtr komutları
SLASH_WOWTR1 = "/wtr";
SlashCmdList["WOWTR"] = function(msg)
   msg = string.lower(msg or "");
   if (msg == "debug") then
      if (QTR_PS == nil) then QTR_PS = {}; end
      QTR_PS["debug"] = WTR_IsDebug() and "0" or "1";
      WTR_Print("debug modu: " .. (WTR_IsDebug() and "AÇIK" or "kapalı"));
   elseif (msg == "status") then
      WTR_PrintStatus();
   else
      WTR_Print("komutlar:  /wtr debug  (ayrıntılı iz aç/kapa)  ·  /wtr status  (durum dökümü)");
   end
end

-- Giriş özeti: tüm dosyalar + SavedVariables yüklendikten sonra (PLAYER_LOGIN) bir kez.
local WTR_CoreFrame = CreateFrame("Frame");
WTR_CoreFrame:RegisterEvent("PLAYER_LOGIN");
WTR_CoreFrame:SetScript("OnEvent", function()
   WTR_PrintLoadSummary();
end);


-- ============================================================
--  2) TÜRKÇE ARAYÜZ METİNLERİ
--  (Motorun beklediği QTR_Messages / QTR_Interface anahtarlarının tamamı.)
-- ============================================================

QTR_Messages = {
   loaded     = "yüklendi",
   isactive   = "aktif",
   isinactive = "devre dışı",
   missing    = "Çeviri Yok",
   details    = "Detaylar",
   progress   = "İlerleme",
   objectives = "Görev",
   completion = "Tamamlama",
   translator = "Çeviri",
   rewards    = "Ödül",
   experience = "Tecrübe:",
   reqmoney   = "Gerekli Para:",
   reqitems   = "Gerekli Eşyalar:",
   itemchoose1= "Şu ödüllerden birini seç:",
   itemchoose2= "Bir ödül seç:",
   itemreceiv1= "Alacağın ödül:",
   itemreceiv2= "Aldığın ödül:",
   learnspell = "Öğrenilen büyü:",
   multipleID = "Çeviri orijinalle birebir olmayabilir",
   currquests = "Güncel Görevler",
   avaiquests = "Mevcut Görevler",
};

QTR_Interface = {
   active     = "Çeviriyi Etkinleştir",
   mode       = "Çalışma Modu",
   mode1      = "Çeviriyi orijinalin yerine koy",
   mode2      = "Çeviriyi ayrı pencerede göster",
   options1   = "Mod 1 Ayarları",
   transtitle = "Başlıkları da Çevir",
   options2   = "Mod 2 Ayarları",
   height1    = "Yükseklik: Standart",
   height2    = "Yükseklik: Geniş",
   width1     = "Genişlik: Standart",
   width2     = "Genişlik: Geniş",
};


-- ============================================================
--  3) FONTLAR (Türkçe karakter destekli)
-- ============================================================

QTR_Font1 = "Interface\\AddOns\\WOTLKTR\\Fonts\\morpheus_tr.ttf";
QTR_Font2 = "Interface\\AddOns\\WOTLKTR\\Fonts\\frizquadratatt_tr.ttf";



-- ============================================================
--  4) ARAYÜZ — ÜST BAŞLIK (parent kategori)
--  Tüm WoWTR ayar panelleri (Görevler / Baloncuklar / Kitaplar) bu tek
--  "WotLK TR" düğümü altında toplanır. Motorlar kendi panelini
--  .parent = "WotLK TR" ile buna bağlar. Core ilk yüklendiğinden
--  bu üst başlık, alt paneller kaydolmadan önce hazırdır.
-- ============================================================

local WTR_Root = CreateFrame("FRAME", "WoWTR_RootOptions");
WTR_Root.name = "WotLK TR";
InterfaceOptions_AddCategory(WTR_Root);

local WTR_rTitle = WTR_Root:CreateFontString(nil, "ARTWORK");
WTR_rTitle:SetFontObject(GameFontNormalLarge);
WTR_rTitle:SetPoint("TOPLEFT", 16, -16);
WTR_rTitle:SetText("WotLK TR");

-- Panel içi metin genişliği: Blizzard ayar konteynerinden al (yoksa güvenli 560),
-- kenar payı bırak → uzun Türkçe satırlar panel dışına TAŞMAZ, kendi içinde sarar.
local WTR_TextW = 560;
if InterfaceOptionsFramePanelContainer then
	local w = InterfaceOptionsFramePanelContainer:GetWidth();
	if w and w > 200 then WTR_TextW = w - 40; end
end

local WTR_rSub = WTR_Root:CreateFontString(nil, "ARTWORK");
WTR_rSub:SetFont(QTR_Font2, 14);
WTR_rSub:SetJustifyH("LEFT");
WTR_rSub:SetWidth(WTR_TextW);
WTR_rSub:SetPoint("TOPLEFT", WTR_rTitle, "BOTTOMLEFT", 0, -10);
WTR_rSub:SetText("WotLK 3.3.5a  ·  Türkçe çeviri  ·  sürüm " .. WTR_VERSION .. "\nYapımcı: Lythnda");

local WTR_rDesc = WTR_Root:CreateFontString(nil, "ARTWORK");
WTR_rDesc:SetFont(QTR_Font2, 13);
WTR_rDesc:SetJustifyH("LEFT");
WTR_rDesc:SetWidth(WTR_TextW);
WTR_rDesc:SetPoint("TOPLEFT", WTR_rSub, "BOTTOMLEFT", 0, -18);
WTR_rDesc:SetText([[Görevleri, NPC konuşmalarını, konuşma baloncuklarını, sinematik altyazıları, kitapları ve yetenek/büyü/glyph açıklamalarını Türkçe gösterir.

Ayarlar için soldaki alt başlıkları kullanın:
Görevler  /  Baloncuklar  /  Kitaplar  /  Yetenekler]]);

local WTR_rCmd = WTR_Root:CreateFontString(nil, "ARTWORK");
WTR_rCmd:SetFont(QTR_Font2, 13);
WTR_rCmd:SetJustifyH("LEFT");
WTR_rCmd:SetWidth(WTR_TextW);
WTR_rCmd:SetPoint("TOPLEFT", WTR_rDesc, "BOTTOMLEFT", 0, -24);
WTR_rCmd:SetText([[Komutlar:
  /wtr      durum ve tanılama
  /qtr      görev, gossip ve ipucu ayarları
  /bbtr     baloncuk ayarları
  /btr      kitap ayarları
  /sktr     yetenek (talent) ayarları]]);

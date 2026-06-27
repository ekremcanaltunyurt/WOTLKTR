-- ============================================================
--  WotLK TR  ·  Engine_Movies.lua
--  Film (movie) ve sinematik (cinematic) altyazılarını Türkçe gösterir — WotLK 3.3.5a (Warmane).
-- ============================================================

local MF_OwnName = "0";      -- 0=özel adlar EN, 1=özel adlar yerel

-- Genel değişkenler
local MF_version = GetAddOnMetadata("WOTLKTR", "Version");
local MF_race = UnitRace("player").."3";    -- intro anahtarı: ırk + "3" (örn "Human3:01")
local MF_class = UnitClass("player");
local MF_name = UnitName("player");
local MF_sex = UnitSex("player");     -- 1:nötr,  2:erkek,  3:kadın
local MF_movieID, MF_SubTitle, MF_lp, MF_ID, MF_playing, MF_showing, MF_timer, MF_time1, MF_last_ST;
if (MF_class == "Death Knight") then
   MF_race = MF_class.."3";
end

-- Türkçe karakter destekli font
local MF_Font = "Interface\\AddOns\\WOTLKTR\\Fonts\\frizquadratatt_tr.ttf";

-- Sınıf/ırk İngilizce kalır. MF_race'teki "3" eki SADECE MF_Data intro anahtarı
-- içindir; $R/$C gösterimi için temiz İngilizce ad kullanılır.
local function MF_FillCases(name)
   return { M1=name, D1=name, C1=name, B1=name, N1=name, K1=name, W1=name,
            M2=name, D2=name, C2=name, B2=name, N2=name, K2=name, W2=name };
end
local player_race  = MF_FillCases(UnitRace("player"));
local player_class = MF_FillCases(UnitClass("player"));


-- Metnin 32-bit hash'ini üretir. ÖNEMLİ: üstteki 4 strip satırı ve asal sayılar
-- hash eşleşmesinin parçası — MF_Hash ve BB_Bubbles anahtarlarıyla birebir tutmalı.
-- ASLA DEĞİŞTİRME.
local function StringHash(text)
  text = string.gsub(text, "$N$", "");
  text = string.gsub(text, "$N", "");
  text = string.gsub(text, "$R", "");
  text = string.gsub(text, "$C", "");
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


-- Oyuncunun gerçek ad/ırk/sınıfını metinde $N/$R/$C tokenlarına geri çevirir
-- (tokenlı metin hash ile eşleşsin diye). Load-bearing — sırayı koru.
function MF_RenderCodes(txt)
   txt = string.gsub(txt, UnitName("player"), "$N");
   txt = string.gsub(txt, string.upper(UnitName("player")), "$N$");
   txt = string.gsub(txt, UnitRace("player"), "$R");
   txt = string.gsub(txt, string.lower(UnitRace("player")), "$R");
   txt = string.gsub(txt, UnitClass("player"), "$C");
   txt = string.gsub(txt, string.lower(UnitClass("player")), "$C");
   return txt;
end


function MF_OnEvent(self, event, ...)
   if (event=="PLAY_MOVIE") then
      MF_movieID = ... ;
      if (MF_movieID) then
         WTR_Print("movie başladı, ID="..MF_movieID, "debug");
         MovieFrame:EnableSubtitles(true);      -- altyazı gösterimini aç
         MF_last_ST = "";
         MF_lp = 0;
         MF_ID = tostring(MF_movieID);
         while (string.len(MF_ID)<3) do
            MF_ID = "0"..MF_ID;
         end
         local _font, _size, _3 = MovieFrameSubtitleString:GetFont();
         MF_Size = _size;   -- DÜZELTME: orijinalde MF_Size atanmıyordu (nil) → satır SetFont çökerdi
         MovieFrameSubtitleString:SetFont(MF_Font, _size);           -- altyazıya Türkçe font
         MovieFrame:HookScript("OnMovieShowSubtitle", MF_ShowMovieSubtitles);
      end
   elseif (event=="CINEMATIC_START") then
      WTR_Print("cinematic başladı", "debug");
      if ((UnitLevel("player")==1) or ((MF_class == "Death Knight") and (UnitLevel("player")==55))) then
         MF_SubTitle = CinematicFrame:CreateFontString(nil, "ARTWORK");    -- Cinematic INTRO var
         MF_SubTitle:SetFontObject(GameFontNormalLarge);
         MF_SubTitle:SetJustifyH("CENTER");
         MF_SubTitle:SetJustifyV("MIDDLE");
         MF_SubTitle:ClearAllPoints();
         MF_SubTitle:SetPoint("CENTER", CinematicFrame, "BOTTOM", 0, 65);
         MF_SubTitle:SetText("");
         MF_SubTitle:SetFont(MF_Font, 22);
         MF_playing = false;
         MF_lp = 1;
         MF_showing = false;
         if (MF_Data[MF_race..":01"]) then
            MF_sub1 = MF_Data[MF_race..":01"]["START"];
            MF_sub2 = MF_Data[MF_race..":01"]["STOP"];
            MF_sub3 = MF_ExpandCodes(MF_Data[MF_race..":01"]["NAPIS"]);
            CinematicFrame:HookScript("OnUpdate", MF_ShowCinematicIntro);
         end
      else                                      -- oyun içi cinematic var
         CinematicFrame:HookScript("OnUpdate", MF_ShowCinematicSubtitles);
         MF_time1 = GetTime();
      end
   elseif (event=="CINEMATIC_STOP") then
      CinematicFrame:SetScript("OnUpdate", nil);
      -- altyazıyı kapat
      if ((UnitLevel("player")==1) or ((MF_class == "Death Knight") and (UnitLevel("player")==55))) then
         MF_SubTitle:Hide();
      end
   end
end


function MF_ShowMovieSubtitles()       -- MOVIES'te altyazı gösterimi
   local MF_readed_ST = MovieFrameSubtitleString:GetText();
   if (MF_readed_ST ~= MF_last_ST) then      -- altyazı sonuncudan farklı
      MF_lp = MF_lp + 1;
      local MF_lpSTR = tostring(MF_lp);
      if (MF_lp<10) then
         MF_lpSTR = "0"..MF_lpSTR;
      end
      MF_last_ST = MF_readed_ST;             -- son altyazı olarak kaydet
      MF_hash = StringHash(MF_readed_ST);
      if (MF_Hash[MF_hash]) then             -- MF_lp numaralı altyazının çevirisi veritabanında var
         MovieFrameSubtitleString:SetText(MF_Hash[MF_hash]);
         MovieFrameSubtitleString:SetFont(MF_Font, MF_Size);
      else           -- bu hash yok - veriyi kaydet
         MF_PS[MF_ID..":"..MF_lpSTR..":"..MF_hash] = MF_readed_ST;
      end
   end
end


function BB_FindProS(text)                 -- verilen çeviride '%s' metni var mı bul
   local dl_txt = string.len(text)-1;
   for i_j=1,dl_txt,1 do
      if (strsub(text,i_j,i_j+1)=="%s") then
         return i_j;
      end
   end
   return 0;
end


function MF_ShowCinematicSubtitles()            -- CINEMATIC'te altyazı gösterimi
   if (GetTime() - MF_time1 > 0.25) then        -- en az 0.25 sn. geçti
      if (CinematicFrame.Subtitle1 and CinematicFrame.Subtitle1:IsVisible()) then        -- görünen altyazı var
         local MF_text = CinematicFrame.Subtitle1:GetText();     -- İngilizce altyazıyı oku
         if (MF_text and (string.len(MF_text)>0) and (string.find(MF_text,"@")==nil)) then  -- '@' işareti Türkçe metni gösterir
            MF_time1 = GetTime() + 1;                             -- +1 sn. kontrol etmeye gerek yok
            local MF_saveEN = true;
            MF_text = MF_RenderCodes(MF_text);                    -- metni tara ve $x kodlarına çevir
            local MF_hash = StringHash(MF_text);                 -- bu metnin hash'ini al
            local p1, p2 = string.find(MF_text,":");             -- ':' işaretini ara
            if (p1 and (p1>0) and (p1<30)) then         -- altyazının başında ':' var (NPC says:)
               local MF_text2 = MF_RenderCodes(string.sub(MF_text, p1+2));
               local MF_hash2 = StringHash(MF_text2);
               if (BB_Bubbles[MF_hash2]) then            -- baloncuklarda çeviri var
                  local MF_output = string.sub(MF_text,1,p1-1).." diyor: "..MF_ExpandCodes(BB_Bubbles[MF_hash2].."@");
                  local _font, _size, _3 = CinematicFrame.Subtitle1:GetFont();   -- font boyutunu oku
                  CinematicFrame.Subtitle1:SetText(MF_output);                   -- gösterilen metni değiştir
                  CinematicFrame.Subtitle1:SetFont(MF_Font, _size);              -- fontu Türkçe'ye çevir
                  MF_saveEN = false;
               else
                  if (MF_saveEN) then             -- orijinal metni hash kodu ile birlikte kaydet
                     MF_PS[tostring(MF_hash)] = MF_text;
                  end
               end
            else
               if (BB_Bubbles[MF_hash]) then            -- baloncuklarda çeviri var
                  local MF_text2 = MF_ExpandCodes(BB_Bubbles[MF_hash]);
                  local nr_poz = BB_FindProS(MF_text2,1);   -- '%s' metnini bul
                  if (strsub(MF_text2,1,2)=="%o") then
                     MF_text2 = strsub(MF_text2, 3):gsub("^%s*", "");
                  elseif (nr_poz>0) then           -- baloncuğun betimsel formu var, ör. NPC_name öfkeye kapılır!
                     if (nr_poz==1) then
                        MF_text2 = name_NPC..strsub(MF_text2, 3);
                     else
                        MF_text2 = strsub(MF_text2,1,nr_poz-1)..name_NPC..strsub(MF_text2, nr_poz+2);
                     end
                  end
                  local MF_output = MF_text2.."@";
                  local _font, _size, _3 = CinematicFrame.Subtitle1:GetFont();   -- font boyutunu oku
                  CinematicFrame.Subtitle1:SetText(MF_output);                   -- gösterilen metni değiştir
                  CinematicFrame.Subtitle1:SetFont(MF_Font, _size);              -- fontu Türkçe'ye çevir
                  MF_saveEN = false;
               else
                  if (MF_saveEN) then             -- orijinal metni hash kodu ile birlikte kaydet
                     MF_PS[tostring(MF_hash)] = MF_text;
                  end
               end
            end
         end
      end
   end
end


function MF_ShowCinematicIntro()    -- INTRO'da özel altyazıların gösterimi
   if (MF_playing==false) then
      MF_timer = GetTime();         -- film zamanlayıcısını başlat
      MF_playing=true;
   end
   if ((MF_showing==false) and (GetTime() > (MF_timer + MF_sub1))) then      -- altyazıyı başlatma zamanı
      MF_SubTitle:SetText(MF_sub3);
      MF_showing=true;
   end
   if ((MF_showing==true) and (GetTime() > (MF_timer + MF_sub2))) then       -- altyazıyı durdurma zamanı
      MF_SubTitle:SetText("");
      -- sonrakini yükle
      MF_showing=false;
      MF_lp = MF_lp + 1;
      local MF_lpSTR = tostring(MF_lp);
      if (MF_lp<10) then
         MF_lpSTR = "0"..MF_lpSTR;
      end
      if (MF_Data[MF_race..":"..MF_lpSTR]) then
         MF_sub1 = MF_Data[MF_race..":"..MF_lpSTR]["START"];
         MF_sub2 = MF_Data[MF_race..":"..MF_lpSTR]["STOP"];
         MF_sub3 = MF_ExpandCodes(MF_Data[MF_race..":"..MF_lpSTR]["NAPIS"]);
      else
         MF_sub1=1000;
         MF_sub2=1000;
      end
   end
end


-- Altyazıdaki $kodlarını oyuncuya göre açar. Türkçe veri $ tokenlarını doğrudan
-- kullanır (shim yok). $G/$O hang-safe: orijinal while döngüsü bozuk girdide donduruyordu.
function MF_ExpandCodes(message)
   message = string.gsub(message, "$B", "\n");        -- $B = satır sonu

   message = string.gsub(message, "$n$", string.upper(MF_name));    -- BÜYÜK harf isim
   message = string.gsub(message, "$N$", string.upper(MF_name));
   message = string.gsub(message, "$n", MF_name);
   message = string.gsub(message, "$N", MF_name);

   message = string.gsub(message, "$g", "$G");
   message = string.gsub(message, "%$G%((.-);(.-)%)", function(m, f)
      if (MF_sex == 3) then return f; else return m; end   -- kadın→dişil, değilse eril
   end);

   message = string.gsub(message, "$o", "$O");
   message = string.gsub(message, "%$O%((.-);(.-)%)", function(a, b)
      if (MF_OwnName == "0") then return b; else return a; end   -- "0"=ikinci form (orijinal davranış)
   end);

   message = string.gsub(message, "$r", "$R");
   message = string.gsub(message, "$c", "$C");
   if (MF_sex == 3) then        -- oyuncu kadın
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
   else                         -- oyuncu erkek
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


MF_Frame = CreateFrame("Frame");
MF_Frame:SetScript("OnEvent", MF_OnEvent);
MF_Frame:RegisterEvent("PLAY_MOVIE");
MF_Frame:RegisterEvent("CINEMATIC_START");
MF_Frame:RegisterEvent("CINEMATIC_STOP");
if (not MF_PS) then
   MF_PS = {};
end

WTR_LOADED_MOVIES = true;   -- motor sonuna kadar yüklendi (Core özetinde gösterilir)
WTR_Print("Movies motoru yüklendi (v"..MF_version..")", "debug");

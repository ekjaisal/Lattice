{
 Copyright © 2026 Jaisal E. K.

 This program is free software: you can redistribute it and/or modify it
 under the terms of the GNU Affero General Public License as published
 by the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program. If not, see <https://www.gnu.org/licenses/>.
}

unit AppFont;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Forms, Graphics, SysUtils;

const
  UI_SIZE_DEFAULT = 9;
  READ_SIZE_DEFAULT = 11;

function GetSystemSansFont: string;
function GetUniversalFontStack: string;
procedure ApplyAppFont(AForm: TForm);

implementation

uses
  {$IFDEF WINDOWS} Windows {$ENDIF};

function GetSystemSansFont: string;
begin
  {$IFDEF WINDOWS} Result := 'Arial'; {$ENDIF}
  {$IFDEF DARWIN} Result := 'Helvetica'; {$ENDIF}
  {$IFDEF LINUX} Result := 'Liberation Sans'; {$ENDIF}
  if Screen.Fonts.IndexOf(Result) = -1 then Result := 'sans-serif';
end;

function GetUniversalFontStack: string;
begin
  Result := 'Arial, Helvetica, Noto Sans, Noto Sans Display, Noto Sans Adlam, ' +
    'Noto Sans Adlam Unjoined, Noto Sans Anatolian Hieroglyphs, Noto Sans Arabic, ' +
    'Noto Sans Armenian, Noto Sans Avestan, Noto Sans Balinese, Noto Sans Bamum, ' +
    'Noto Sans Bassa Vah, Noto Sans Batak, Noto Sans Bengali, Noto Sans Bhaiksuki, ' +
    'Noto Sans Brahmi, Noto Sans Buginese, Noto Sans Buhid, Noto Sans Canadian Aboriginal, ' +
    'Noto Sans Carian, Noto Sans Caucasian Albanian, Noto Sans Chakma, Noto Sans Cham, ' +
    'Noto Sans Cherokee, Noto Sans Chorasmian, Noto Sans Coptic, Noto Sans Cuneiform, ' +
    'Noto Sans Cypriot, Noto Sans Cypro Minoan, Noto Sans Deseret, Noto Sans Devanagari, ' +
    'Noto Sans Duployan, Noto Sans Egyptian Hieroglyphs, Noto Sans Elbasan, Noto Sans Elymaic, ' +
    'Noto Sans Ethiopic, Noto Sans Georgian, Noto Sans Glagolitic, Noto Sans Gothic, ' +
    'Noto Sans Grantha, Noto Sans Gujarati, Noto Sans Gunjala Gondi, Noto Sans Gurmukhi, ' +
    'Noto Sans Hanifi Rohingya, Noto Sans Hanunoo, Noto Sans Hatran, Noto Sans Hebrew, ' +
    'Noto Sans HK, Noto Sans Imperial Aramaic, Noto Sans Indic Siyaq Numbers, ' +
    'Noto Sans Inscriptional Pahlavi, Noto Sans Inscriptional Parthian, Noto Sans Javanese, ' +
    'Noto Sans JP, Noto Sans Kaithi, Noto Sans Kannada, Noto Sans Kawi, Noto Sans Kayah Li, ' +
    'Noto Sans Kharoshthi, Noto Sans Khmer, Noto Sans Khojki, Noto Sans Khudawadi, ' +
    'Noto Sans KR, Noto Sans Lao, Noto Sans Lao Looped, Noto Sans Lepcha, Noto Sans Limbu, ' +
    'Noto Sans Linear A, Noto Sans Linear B, Noto Sans Lisu, Noto Sans Lycian, ' +
    'Noto Sans Lydian, Noto Sans Mahajani, Noto Sans Malayalam, Noto Sans Mandaic, ' +
    'Noto Sans Manichaean, Noto Sans Marchen, Noto Sans Masaram Gondi, Noto Sans Math, ' +
    'Noto Sans Mayan Numerals, Noto Sans Medefaidrin, Noto Sans Meetei Mayek, ' +
    'Noto Sans Mende Kikakui, Noto Sans Meroitic, Noto Sans Miao, Noto Sans Modi, ' +
    'Noto Sans Mongolian, Noto Sans Mro, Noto Sans Multani, Noto Sans Myanmar, ' +
    'Noto Sans Nabataean, Noto Sans Nag Mundari, Noto Sans Nandinagari, Noto Sans New Tai Lue, ' +
    'Noto Sans Newa, Noto Sans N''Ko, Noto Sans N''Ko Todelist, Noto Sans Nushu, ' +
    'Noto Sans Ogham, Noto Sans Ol Chiki, Noto Sans Old Hungarian, Noto Sans Old Italic, ' +
    'Noto Sans Old North Arabian, Noto Sans Old Permic, Noto Sans Old Persian, ' +
    'Noto Sans Old Sogdian, Noto Sans Old South Arabian, Noto Sans Old Turkic, ' +
    'Noto Sans Old Uyghur, Noto Sans Oriya, Noto Sans Osage, Noto Sans Osmanya, ' +
    'Noto Sans Pahawh Hmong, Noto Sans Palmyrene, Noto Sans Pau Cin Hau, Noto Sans PhagsPa, ' +
    'Noto Sans Phoenician, Noto Sans Psalter Pahlavi, Noto Sans Rejang, Noto Sans Runic, ' +
    'Noto Sans Samaritan, Noto Sans Saurashtra, Noto Sans SC, Noto Sans Sharada, ' +
    'Noto Sans Siddham, Noto Sans SignWriting, Noto Sans Sinhala, Noto Sans Sogdian, ' +
    'Noto Sans Sora Sompeng, Noto Sans Soyombo, Noto Sans Sundanese, Noto Sans Syloti Nagri, ' +
    'Noto Sans Symbols, Noto Sans Symbols 2, Noto Sans Syriac, Noto Sans Syriac Eastern, ' +
    'Noto Sans Tagalog, Noto Sans Tagbanwa, Noto Sans Tai Le, Noto Sans Tai Tham, ' +
    'Noto Sans Tai Viet, Noto Sans Takri, Noto Sans Tamil, Noto Sans Tamil Supplement, ' +
    'Noto Sans Tangsa, Noto Sans TC, Noto Sans Telugu, Noto Sans Thaana, Noto Sans Thai, ' +
    'Noto Sans Thai Looped, Noto Sans Tifinagh, Noto Sans Tirhuta, Noto Sans Ugaritic, ' +
    'Noto Sans Vai, Noto Sans Vithkuqi, Noto Sans Wancho, Noto Sans Warang Citi, ' +
    'Noto Sans Yi, Noto Sans Zanabazar Square, Nirmala UI, Segoe UI, Segoe UI Emoji, ' + 
    'Apple Color Emoji, Liberation Sans, sans-serif';
end;

procedure ApplyAppFont(AForm: TForm);
begin
  if not Assigned(AForm) then Exit;
  AForm.Font.Name := GetSystemSansFont;
  AForm.Font.Size := UI_SIZE_DEFAULT;
end;

procedure InitializeFontConfig;
var
  ConfigurationDirectory, ConfigurationFile: String;
  ConfigurationContent: TStringList;
begin
  {$IFDEF WINDOWS}
  ConfigurationDirectory := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'FontConfig';
  ForceDirectories(ConfigurationDirectory);
  ConfigurationFile := IncludeTrailingPathDelimiter(ConfigurationDirectory) + 'fonts.conf';
  if not FileExists(ConfigurationFile) then
  begin
    ConfigurationContent := TStringList.Create;
    try
      ConfigurationContent.Add('<?xml version="1.0"?>');
      ConfigurationContent.Add('<fontconfig>');
      ConfigurationContent.Add('  <dir>C:/Windows/Fonts</dir>');
      ConfigurationContent.Add('  <cachedir>' + ConfigurationDirectory + '/cache</cachedir>');
      ConfigurationContent.Add('  <match target="font">');
      ConfigurationContent.Add('    <edit name="antialias" mode="assign"><bool>true</bool></edit>');
      ConfigurationContent.Add('    <edit name="hinting" mode="assign"><bool>true</bool></edit>');
      ConfigurationContent.Add('    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>');
      ConfigurationContent.Add('    <edit name="rgba" mode="assign"><const>rgb</const></edit>');
      ConfigurationContent.Add('  </match>');
      ConfigurationContent.Add('</fontconfig>');
      ConfigurationContent.SaveToFile(ConfigurationFile);
    finally
      ConfigurationContent.Free;
    end;
  end;
  SetEnvironmentVariable('FONTCONFIG_FILE', PChar(ConfigurationFile));
  SetEnvironmentVariable('FONTCONFIG_PATH', PChar(ConfigurationDirectory));
  {$ENDIF}
end;

initialization
  InitializeFontConfig;

end.
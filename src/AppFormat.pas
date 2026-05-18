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

unit AppFormat;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAppFormat = class
  public
    class function Pluralize(Count: Integer; const Singular, Plural: String): String;
    class function FormatUIHint(const AText: String): String;
  end;

implementation

uses
  LazUTF8;

class function TAppFormat.Pluralize(Count: Integer; const Singular, Plural: String): String;
begin
  if Count = 1 then
    Result := Singular
  else
    Result := Plural;
end;

class function TAppFormat.FormatUIHint(const AText: String): String;
var
  CleanText: String;
begin
  CleanText := Trim(AText);
  while Pos('  ', CleanText) > 0 do
    CleanText := StringReplace(CleanText, '  ', ' ', [rfReplaceAll]);
  if UTF8Length(CleanText) > 2000 then
    CleanText := UTF8Copy(CleanText, 1, 2000) + '...';
  Result := WrapText(CleanText, 90);
end;

end.
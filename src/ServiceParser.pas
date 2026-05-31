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

unit ServiceParser;

{$mode ObjFPC}{$H+}

interface

type
  TDataParser = class
  public
    class function TryParseDate(const Input: String; out ISOString: String): Boolean;
    class function TryParseNumeric(const Input: String; out CleanString: String): Boolean;
    class function ParseCategorical(const Input: String): String;
  end;

implementation

uses
  SysUtils;

class function TDataParser.TryParseDate(const Input: String; out ISOString: String): Boolean;
var
  D: TDateTime;
  Format: TFormatSettings;
  S, NormalizedS: String;
begin
  ISOString := '';
  S := Trim(Input);
  if S = '' then Exit(False);
  NormalizedS := StringReplace(S, '.', '-', [rfReplaceAll]);
  NormalizedS := StringReplace(NormalizedS, '/', '-', [rfReplaceAll]);
  Format := DefaultFormatSettings;
  Format.DateSeparator := '-';
  Format.ShortDateFormat := 'yyyy-mm-dd';
  if TryStrToDate(NormalizedS, D, Format) or TryStrToDateTime(NormalizedS, D, Format) then
  begin
    ISOString := FormatDateTime('yyyy-mm-dd', D);
    Exit(True);
  end;
  if TryStrToDate(S, D) or TryStrToDateTime(S, D) then
  begin
    ISOString := FormatDateTime('yyyy-mm-dd', D);
    Exit(True);
  end;
  Format.ShortDateFormat := 'dd-mm-yyyy';
  if TryStrToDate(NormalizedS, D, Format) then
  begin
    ISOString := FormatDateTime('yyyy-mm-dd', D);
    Exit(True);
  end;
  Format.ShortDateFormat := 'mm-dd-yyyy';
  if TryStrToDate(NormalizedS, D, Format) then
  begin
    ISOString := FormatDateTime('yyyy-mm-dd', D);
    Exit(True);
  end;
  Result := False;
end;

class function TDataParser.TryParseNumeric(const Input: String; out CleanString: String): Boolean;
var
  S: String;
  LastDot, LastComma, I: Integer;
  DecSeparator: Char;
  Value: Double;
  Format: TFormatSettings;
begin
  CleanString := '';
  S := '';
  for I := 1 to Length(Input) do
  begin
    if Input[I] in ['0'..'9', '.', ',', '-', '+', 'e', 'E'] then
      S := S + Input[I];
  end;
  if S = '' then Exit(False);
  LastDot := LastDelimiter('.', S);
  LastComma := LastDelimiter(',', S);
  if (LastDot > 0) and (LastComma > 0) then
  begin
    if LastDot > LastComma then DecSeparator := '.' else DecSeparator := ',';
  end
  else if LastDot > 0 then
    DecSeparator := '.'
  else if LastComma > 0 then
    DecSeparator := ','
  else
    DecSeparator := '.'; 
  if DecSeparator = '.' then
    S := StringReplace(S, ',', '', [rfReplaceAll])
  else
  begin
    S := StringReplace(S, '.', '', [rfReplaceAll]);
    S := StringReplace(S, ',', '.', [rfReplaceAll]);
  end;
  Format := DefaultFormatSettings;
  Format.DecimalSeparator := '.';
  Format.ThousandSeparator := #0;
  if TryStrToFloat(S, Value, Format) then
  begin
    CleanString := FloatToStr(Value, Format);
    Result := True;
  end
  else
    Result := False;
end;

class function TDataParser.ParseCategorical(const Input: String): String;
begin
  Result := Trim(Input);
  while Pos('  ', Result) > 0 do 
    Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);
end;

end.
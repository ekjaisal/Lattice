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

unit EngineText;

{$mode objfpc}{$H+}

interface

uses
  Classes, Graphics, LCLIntf, LCLType, Types, BridgeLibrary;

const
  BRACKET_LANE_WIDTH = 12;

type
  TCodingRec = record
    ID: String;
    StartCharacter: Integer;
    Length: Integer;
    Color: TColor;
    Name: String;
  end;

  TCodingArray = array of TCodingRec;

  TBracketHit = record
    CodingID: String;
    Rectangle: TRect;
  end;

  TBracketLayout = record
    StartByte: Integer;
    EndByte: Integer;
    LaneIndex: Integer;
  end;

  TSearchMatch = record
    StartByte: Integer;
    LengthBytes: Integer;
  end;

  TMemoMatch = record
    ID: String;
    StartByte: Integer;
    LengthBytes: Integer;
    Lane: Integer;
  end;

  TDocumentParagraph = record
    StartByte: Integer;
    LengthBytes: Integer;
    YOffset: Integer;
    PixelHeight: Integer;
    Estimated: Boolean;
    Layout: Ppango_layout_t;
  end;

  TMapTickType = (mttCode, mttMemo);
  
  TMapTickClusterItem = record
    ID: String;
    TickType: TMapTickType;
    Color: TColor;
    Name: String;
  end;

  TMapTickCluster = record
    StartByte: Integer;
    LengthBytes: Integer;
    MapY: Double;
    Items: array of TMapTickClusterItem;
  end;

  TUndoAction = record
    StartByte: Integer;
    EndByte: Integer;
    OldText: String;
    NewText: String;
    SavedBracketLayout: array of TBracketLayout;
    SavedMemos: array of TMemoMatch;
  end;

  TAnnotationShift = record
    ID: String;
    NewStart: Integer;
    NewLength: Integer;
  end;
  TAnnotationShiftArray = array of TAnnotationShift;

  TEngineText = class
  private
    FActiveMatchIndex: Integer;
    FBaseFontDescription: Ppango_font_description_t;
    FBenchmarkM: Integer;
    FBracketHit: array of TBracketHit;
    FBracketLayout: array of TBracketLayout;
    FBracketsAreaWidth: Integer;
    FCaretByte: Integer; 
    FCaretParagraph: Integer;
    FCaretVisible: Boolean;
    FCoding: TCodingArray;
    FDocumentHeight: Integer;
    FDocumentText: String;
    FDPI: Integer;
    FFocusedCodingID: String;
    FFocusedMemoID: String;
    FHoveredAnchorIndex: Integer;
    FIsBracketSelection: Boolean;
    FIsEditing: Boolean;
    FMapClusters: array of TMapTickCluster;
    FMapClustersDirty: Boolean;
    FMapClustersViewHeight: Integer;
    FMarginBottom: Integer;
    FMarginLeft: Integer;
    FMarginRight: Integer;
    FMarginTop: Integer;
    FMemoMatch: array of TMemoMatch;
    FOnTextChanged: TNotifyEvent;
    FParagraphs: array of TDocumentParagraph;
    FRedoStack: array of TUndoAction;
    FSearchMatch: array of TSearchMatch;
    FSelecting: Boolean;
    FSelEndByte: Integer;
    FSelStartByte: Integer;
    FTextAreaWidth: Integer;
    FUndoStack: array of TUndoAction;
    FViewWidth: Integer;
    FZoomOffset: Integer;
    function GetParagraphAtByte(AByte: Integer): Integer;
    function GetParagraphAtY(AY: Integer): Integer;
    procedure DrawBrackets(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
    procedure DrawHighlights(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
    procedure DrawMemoHighlights(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
    procedure DrawRange(cr: Pcairo_t; AStartByte, AEndByte: Integer; AColor: TColor; AAlpha: Double; ScrollY, ViewHeight: Integer);
    procedure DrawSearchHighlights(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
    procedure DrawSelection(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
    procedure EnsureLayout(ParagraphIndex: Integer; cr: Pcairo_t; AScrollY: PInteger = nil);
    procedure EstimateParagraphs;
    procedure GarbageCollectLayout(VisibleStart, VisibleEnd: Integer);
    procedure InternalReplaceRange(StartB, EndB: Integer; const CleanReplacement: String);
    procedure RecalculateLane(ForceReflow: Boolean = False);
    procedure SetZoomOffset(Value: Integer);
    procedure UpdateFontDescription;
  public
    class procedure WarmUpEngine;
    constructor Create;
    destructor Destroy; override;
    function ActionAnchorHitTest(X, Y, ViewHeight: Integer; out TargetCluster: TMapTickCluster; out TargetStartByte: Integer): Boolean;
    function ByteFromXY(X, Y: Integer): Integer;
    function ByteToChar(AByte: Integer): Integer;
    function CharToByte(AChar: Integer): Integer;
    function DocumentHeight: Integer;
    function GetAbsoluteCaret: Integer;
    function GetActiveMatchY: Integer;
    function GetBracketAt(X, Y, ScrollY: Integer): String;
    function GetCharAt(X, Y, ScrollY: Integer): Integer;
    function GetCodingInfo(Index: Integer; out ID: String; out Color: TColor): Boolean;
    function GetCodingShifts: TAnnotationShiftArray;
    function GetDocumentLengthBytes: Integer;
    function GetDocumentText: String;
    function GetMemoShifts: TAnnotationShiftArray;
    function GetNextCoding(CurrentScrollY, Direction: Integer): String;
    function GetSearchStatus(out CurrentMatch, TotalMatch: Integer): Boolean;
    function GetSelectedText: String;
    function GetTextSlice(StartCharacter, LengthCharacter: Integer): String;
    function GetTopVisibleByte(ScrollY: Integer): Integer;
    function GetYForByte(AByte: Integer): Integer;
    function GetYForChar(AChar: Integer): Integer;
    function HasSelection: Boolean;
    function IsBracketSelection: Boolean;
    function IsOverActionAnchors(X, Y, ViewHeight: Integer): Boolean;
    function SelectionLength: Integer;
    function SelectionStartCharacter: Integer;
    function UpdateAnchorHover(X, Y, ViewHeight: Integer): Boolean;
    procedure ClearSelection;
    procedure DrawActionAnchors(cr: Pcairo_t; ViewHeight: Integer);
    procedure ExecuteSearch(const AQuery: String);
    procedure MouseDown(X, Y, ScrollY: Integer);
    procedure MouseMove(X, Y, ScrollY: Integer);
    procedure MouseUp;
    procedure MoveCaretVertical(DeltaLines, ScrollY: Integer);
    procedure NavigateMatch(Direction: Integer);
    procedure Paint(DC: HDC; ViewWidth, ViewHeight: Integer; var ScrollY: Integer);
    procedure Redo;
    procedure ReplaceRange(StartB, EndB: Integer; const Replacement: String);
    procedure Resize(AViewWidth: Integer);
    procedure SelectCoding(const CodingID: String);
    procedure SetCaretFromXY(X, Y, ScrollY: Integer);
    procedure SetCaretToByte(AByte: Integer);
    procedure SetCodings(const ACoding: TCodingArray);
    procedure SetDPI(ADPI: Integer);
    procedure SetEditing(Value: Boolean);
    procedure SetFocusedCoding(const ID: String);
    procedure SetFocusedMemo(const ID: String);
    procedure SetMemoHighlights(const AMemoArray: array of TMemoMatch);
    procedure SetText(const AText: string);
    procedure ToggleCaret;
    procedure Undo;
    property BracketsAreaWidth: Integer read FBracketsAreaWidth;
    property IsEditing: Boolean read FIsEditing;
    property OnTextChanged: TNotifyEvent read FOnTextChanged write FOnTextChanged;
    property SelEndByte: Integer read FSelEndByte;
    property SelStartByte: Integer read FSelStartByte;
    property ZoomOffset: Integer read FZoomOffset write SetZoomOffset;
  end;

implementation

uses
  LazUTF8, Math, StrUtils, SysUtils, AppFont;

class procedure TEngineText.WarmUpEngine;
var
  surface: Pcairo_surface_t;
  cr: Pcairo_t;
  layout: Ppango_layout_t;
  DC: HDC;
begin
  DC := GetDC(0);
  surface := cairo_win32_surface_create(DC);
  cr := cairo_create(surface);
  layout := pango_cairo_create_layout(cr);
  pango_layout_set_text(layout, 'WarmUp', -1);
  pango_layout_get_pixel_size(layout, nil, nil);
  g_object_unref(layout);
  cairo_destroy(cr);
  cairo_surface_destroy(surface);
  ReleaseDC(0, DC);
end;

constructor TEngineText.Create;
begin
  inherited Create;
  FDPI := 96;
  FBenchmarkM := 30;
  FBaseFontDescription := nil;
  UpdateFontDescription;
  FMarginTop := FBenchmarkM;
  FMarginBottom := FBenchmarkM;
  FMarginLeft := FBenchmarkM;
  FMarginRight := FBenchmarkM;
  FSelStartByte := -1;
  FSelEndByte := -1;
  FBracketsAreaWidth := 0;
  FFocusedCodingID := '';
  FFocusedMemoID := '';
  FViewWidth := 100;
  FTextAreaWidth := 50;
  FActiveMatchIndex := -1;
  FHoveredAnchorIndex := -1;
  FMapClustersDirty := True;
  FMapClustersViewHeight := 0;
end;

destructor TEngineText.Destroy;
var
  i: Integer;
begin
  if FBaseFontDescription <> nil then
    pango_font_description_free(FBaseFontDescription);
  for i := 0 to High(FParagraphs) do
    if Assigned(FParagraphs[i].Layout) then g_object_unref(FParagraphs[i].Layout);
  SetLength(FParagraphs, 0);
  SetLength(FSearchMatch, 0);
  SetLength(FMemoMatch, 0);
  inherited Destroy;
end;

procedure TEngineText.SetDPI(ADPI: Integer);
begin
  if (ADPI > 0) and (FDPI <> ADPI) then
  begin
    FDPI := ADPI;
    FBenchmarkM := MulDiv(30, FDPI, 96);
    FMarginTop := FBenchmarkM;
    FMarginBottom := FBenchmarkM;
    UpdateFontDescription;
    RecalculateLane(True);
  end;
end;

procedure TEngineText.SetZoomOffset(Value: Integer);
begin
  if FZoomOffset <> Value then
  begin
    FZoomOffset := Value;
    UpdateFontDescription;
    RecalculateLane(True);
  end;
end;

procedure TEngineText.UpdateFontDescription;
var
  FontStr: String;
begin
  if FBaseFontDescription <> nil then
    pango_font_description_free(FBaseFontDescription);
  FontStr := GetUniversalFontStack + ' ' + IntToStr(READ_SIZE_DEFAULT + FZoomOffset);
  FBaseFontDescription := pango_font_description_from_string(PChar(FontStr));
end;

procedure TEngineText.SetText(const AText: string);
var
  StartPos, EndPos: Integer;
  Count, Capacity: Integer;
begin
  FDocumentText := StringReplace(AText, #13#10, #10, [rfReplaceAll]);
  FDocumentText := StringReplace(FDocumentText, #13, #10, [rfReplaceAll]);
  FSelStartByte := -1;
  FSelEndByte := -1;
  FFocusedCodingID := '';
  FFocusedMemoID := '';
  SetLength(FSearchMatch, 0);
  SetLength(FMemoMatch, 0);
  SetLength(FBracketHit, 0);
  SetLength(FMapClusters, 0);
  FActiveMatchIndex := -1;
  for Count := 0 to High(FParagraphs) do
  begin
    if FParagraphs[Count].Layout <> nil then
    begin
      g_object_unref(FParagraphs[Count].Layout);
      FParagraphs[Count].Layout := nil;
    end;
  end;
  if Length(FDocumentText) = 0 then
  begin
    SetLength(FParagraphs, 0);
    RecalculateLane(True);
    Exit;
  end;
  Capacity := 1024;
  SetLength(FParagraphs, Capacity);
  Count := 0;
  StartPos := 1;
  while StartPos <= Length(FDocumentText) do
  begin
    EndPos := StrUtils.PosEx(#10, FDocumentText, StartPos);
    if Count >= Capacity then
    begin
      Capacity := Capacity * 2;
      SetLength(FParagraphs, Capacity);
    end;
    FParagraphs[Count].StartByte := StartPos - 1;
    if EndPos = 0 then 
    begin
      FParagraphs[Count].LengthBytes := Length(FDocumentText) - StartPos + 1;
      StartPos := Length(FDocumentText) + 1;
    end
    else
    begin
      FParagraphs[Count].LengthBytes := EndPos - StartPos + 1;
      StartPos := EndPos + 1;
    end;
    FParagraphs[Count].Estimated := True;
    FParagraphs[Count].Layout := nil;
    Inc(Count);
  end;
  if (Length(FDocumentText) > 0) and (FDocumentText[Length(FDocumentText)] = #10) then
  begin
    if Count >= Capacity then
    begin
      Capacity := Capacity + 1;
      SetLength(FParagraphs, Capacity);
    end;
    FParagraphs[Count].StartByte := Length(FDocumentText);
    FParagraphs[Count].LengthBytes := 0;
    FParagraphs[Count].Estimated := True;
    FParagraphs[Count].Layout := nil;
    Inc(Count);
  end;
  SetLength(FParagraphs, Count);
  RecalculateLane(True);
  FMapClustersDirty := True;
end;

function TEngineText.GetDocumentText: String;
begin
  Result := FDocumentText;
end;

function TEngineText.GetDocumentLengthBytes: Integer;
begin
  Result := Length(FDocumentText);
end;

function TEngineText.GetTextSlice(StartCharacter, LengthCharacter: Integer): String;
var
  S, E: Integer;
begin
  S := CharToByte(StartCharacter);
  E := CharToByte(StartCharacter + LengthCharacter);
  Result := Copy(FDocumentText, S + 1, E - S);
end;

procedure TEngineText.SetEditing(Value: Boolean);
begin
  FIsEditing := Value;
  FCaretVisible := Value;
end;

procedure TEngineText.InternalReplaceRange(StartB, EndB: Integer; const CleanReplacement: String);
var
  S, E, StartParagraph, EndParagraph, i, ShiftAmount, ParaDiff, StartPos, EndPos: Integer;
  CombinedText: String;
  NewParas: array of TDocumentParagraph;
  OldStart, OldEnd, NewStart, NewEnd: Integer;
  CharacterPerLine, Lines, LineH, ParagraphSpacing: Integer;
  OldTotalHeight, NewTotalHeight, DeltaY: Integer;
begin
  S := Min(StartB, EndB);
  E := Max(StartB, EndB);
  S := Math.EnsureRange(S, 0, Length(FDocumentText));
  E := Math.EnsureRange(E, 0, Length(FDocumentText));
  StartParagraph := GetParagraphAtByte(S);
  EndParagraph := GetParagraphAtByte(E);
  if (StartParagraph < 0) or (EndParagraph < 0) then Exit;
  if StartParagraph > 0 then Dec(StartParagraph);
  if EndParagraph < High(FParagraphs) then Inc(EndParagraph);
  OldStart := FParagraphs[StartParagraph].StartByte;
  OldEnd := FParagraphs[EndParagraph].StartByte + FParagraphs[EndParagraph].LengthBytes;
  OldTotalHeight := 0;
  for i := StartParagraph to EndParagraph do
  begin
    OldTotalHeight := OldTotalHeight + FParagraphs[i].PixelHeight;
    if FParagraphs[i].Layout <> nil then
    begin
      g_object_unref(FParagraphs[i].Layout);
      FParagraphs[i].Layout := nil;
    end;
  end;
  System.Delete(FDocumentText, S + 1, E - S);
  System.Insert(CleanReplacement, FDocumentText, S + 1);
  ShiftAmount := Length(CleanReplacement) - (E - S);
  NewEnd := OldEnd + ShiftAmount;
  CombinedText := Copy(FDocumentText, OldStart + 1, NewEnd - OldStart);
  SetLength(NewParas, 0);
  StartPos := 1;
  while StartPos <= Length(CombinedText) do
  begin
    EndPos := StrUtils.PosEx(#10, CombinedText, StartPos);
    SetLength(NewParas, Length(NewParas) + 1);
    NewParas[High(NewParas)].StartByte := OldStart + StartPos - 1;
    if EndPos = 0 then 
    begin
      NewParas[High(NewParas)].LengthBytes := Length(CombinedText) - StartPos + 1;
      StartPos := Length(CombinedText) + 1;
    end
    else
    begin
      NewParas[High(NewParas)].LengthBytes := EndPos - StartPos + 1;
      StartPos := EndPos + 1;
    end;
    NewParas[High(NewParas)].Estimated := True;
    NewParas[High(NewParas)].Layout := nil;
  end;
  if (NewEnd = Length(FDocumentText)) and (Length(CombinedText) > 0) and (CombinedText[Length(CombinedText)] = #10) then
  begin
    SetLength(NewParas, Length(NewParas) + 1);
    NewParas[High(NewParas)].StartByte := OldStart + Length(CombinedText);
    NewParas[High(NewParas)].LengthBytes := 0;
    NewParas[High(NewParas)].Estimated := True;
    NewParas[High(NewParas)].Layout := nil;
  end;
  if Length(NewParas) = 0 then
  begin
    SetLength(NewParas, 1);
    NewParas[0].StartByte := OldStart;
    NewParas[0].LengthBytes := 0;
    NewParas[0].Estimated := True;
    NewParas[0].Layout := nil;
  end;
  ParaDiff := Length(NewParas) - (EndParagraph - StartParagraph + 1);
  if ParaDiff > 0 then
  begin
    SetLength(FParagraphs, Length(FParagraphs) + ParaDiff);
    for i := High(FParagraphs) downto EndParagraph + 1 + ParaDiff do
      FParagraphs[i] := FParagraphs[i - ParaDiff];
  end
  else if ParaDiff < 0 then
  begin
    for i := EndParagraph + 1 to High(FParagraphs) do
      FParagraphs[i + ParaDiff] := FParagraphs[i];
    SetLength(FParagraphs, Length(FParagraphs) + ParaDiff);
  end;
  LineH := MulDiv(Round((READ_SIZE_DEFAULT + FZoomOffset) * 1.6), FDPI, 96);
  ParagraphSpacing := MulDiv(4, FDPI, 96);
  CharacterPerLine := Max(10, FTextAreaWidth div MulDiv(8, FDPI, 96));
  NewTotalHeight := 0;
  for i := 0 to High(NewParas) do
  begin
    FParagraphs[StartParagraph + i] := NewParas[i];
    Lines := Max(1, FParagraphs[StartParagraph + i].LengthBytes div CharacterPerLine);
    if FParagraphs[StartParagraph + i].LengthBytes = 0 then Lines := 1;
    FParagraphs[StartParagraph + i].PixelHeight := (Lines * LineH) + ParagraphSpacing;
    if (StartParagraph + i) = 0 then
      FParagraphs[StartParagraph + i].YOffset := FMarginTop
    else
      FParagraphs[StartParagraph + i].YOffset := FParagraphs[StartParagraph + i - 1].YOffset + FParagraphs[StartParagraph + i - 1].PixelHeight;
    NewTotalHeight := NewTotalHeight + FParagraphs[StartParagraph + i].PixelHeight;
  end;
  for i := StartParagraph + Length(NewParas) to High(FParagraphs) do
    FParagraphs[i].StartByte := FParagraphs[i].StartByte + ShiftAmount;
  DeltaY := NewTotalHeight - OldTotalHeight;
  if DeltaY <> 0 then
  begin
    FDocumentHeight := FDocumentHeight + DeltaY;
    for i := StartParagraph + Length(NewParas) to High(FParagraphs) do
      FParagraphs[i].YOffset := FParagraphs[i].YOffset + DeltaY;
  end;
  for i := 0 to High(FBracketLayout) do
  begin
    OldStart := FBracketLayout[i].StartByte;
    OldEnd := FBracketLayout[i].EndByte;
    if OldEnd <= S then 
    begin
      NewStart := OldStart;
      NewEnd := OldEnd;
    end
    else if OldStart >= E then
    begin
      NewStart := OldStart + ShiftAmount;
      NewEnd := OldEnd + ShiftAmount;
    end
    else if (OldStart <= S) and (OldEnd >= E) then 
    begin
      NewStart := OldStart;
      NewEnd := OldEnd + ShiftAmount;
    end
    else if (OldStart >= S) and (OldEnd <= E) then 
    begin
      NewStart := S;
      NewEnd := S;
    end
    else if (OldStart >= S) and (OldStart < E) then 
    begin
      NewStart := S + Length(CleanReplacement);
      NewEnd := OldEnd + ShiftAmount;
    end
    else if (OldEnd > S) and (OldEnd <= E) then 
    begin
      NewStart := OldStart;
      NewEnd := S;
    end
    else
    begin
      NewStart := OldStart;
      NewEnd := OldEnd;
    end;
    FBracketLayout[i].StartByte := NewStart;
    FBracketLayout[i].EndByte := Max(NewStart, NewEnd);
  end;
  for i := 0 to High(FMemoMatch) do
  begin
    OldStart := FMemoMatch[i].StartByte;
    OldEnd := FMemoMatch[i].StartByte + FMemoMatch[i].LengthBytes;
    if OldEnd <= S then 
    begin
      NewStart := OldStart;
      NewEnd := OldEnd;
    end
    else if OldStart >= E then
    begin
      NewStart := OldStart + ShiftAmount;
      NewEnd := OldEnd + ShiftAmount;
    end
    else if (OldStart <= S) and (OldEnd >= E) then 
    begin
      NewStart := OldStart;
      NewEnd := OldEnd + ShiftAmount;
    end
    else if (OldStart >= S) and (OldEnd <= E) then 
    begin
      NewStart := S;
      NewEnd := S; 
    end
    else if (OldStart >= S) and (OldStart < E) then 
    begin
      NewStart := S + Length(CleanReplacement);
      NewEnd := OldEnd + ShiftAmount;
    end
    else if (OldEnd > S) and (OldEnd <= E) then 
    begin
      NewStart := OldStart;
      NewEnd := S;
    end
    else
    begin
      NewStart := OldStart;
      NewEnd := OldEnd;
    end;
    FMemoMatch[i].StartByte := NewStart;
    FMemoMatch[i].LengthBytes := Max(0, NewEnd - NewStart);
  end;
  SetLength(FSearchMatch, 0);
  FActiveMatchIndex := -1;
  SetCaretToByte(S + Length(CleanReplacement));
  ClearSelection;
  RecalculateLane(False);
  FMapClustersDirty := True;
end;

procedure TEngineText.ReplaceRange(StartB, EndB: Integer; const Replacement: String);
var
  CleanRep, OldTxt: String;
  Action: TUndoAction;
  i: Integer;
begin
  CleanRep := StringReplace(StringReplace(Replacement, #13#10, #10, [rfReplaceAll]), #13, #10, [rfReplaceAll]);
  OldTxt := Copy(FDocumentText, Min(StartB, EndB) + 1, Abs(EndB - StartB));
  Action.StartByte := Min(StartB, EndB);
  Action.EndByte := Max(StartB, EndB);
  Action.OldText := OldTxt;
  Action.NewText := CleanRep;
  Action.SavedBracketLayout := Copy(FBracketLayout);
  Action.SavedMemos := Copy(FMemoMatch);
  if Length(FUndoStack) >= 100 then
  begin
    for i := 0 to High(FUndoStack) - 1 do
      FUndoStack[i] := FUndoStack[i + 1];
    SetLength(FUndoStack, 99);
  end;
  SetLength(FUndoStack, Length(FUndoStack) + 1);
  FUndoStack[High(FUndoStack)] := Action;
  SetLength(FRedoStack, 0); 
  InternalReplaceRange(StartB, EndB, CleanRep);
  if Assigned(FOnTextChanged) then FOnTextChanged(Self);
end;

procedure TEngineText.Undo;
var
  Action, RedoAction: TUndoAction;
begin
  if Length(FUndoStack) = 0 then Exit;
  Action := FUndoStack[High(FUndoStack)];
  SetLength(FUndoStack, Length(FUndoStack) - 1);
  RedoAction.StartByte := Action.StartByte;
  RedoAction.EndByte := Action.EndByte;
  RedoAction.OldText := Action.OldText;
  RedoAction.NewText := Action.NewText;
  RedoAction.SavedBracketLayout := Copy(FBracketLayout);
  RedoAction.SavedMemos := Copy(FMemoMatch);
  SetLength(FRedoStack, Length(FRedoStack) + 1);
  FRedoStack[High(FRedoStack)] := RedoAction;
  InternalReplaceRange(Action.StartByte, Action.StartByte + Length(Action.NewText), Action.OldText);
  FBracketLayout := Copy(Action.SavedBracketLayout);
  FMemoMatch := Copy(Action.SavedMemos);
  RecalculateLane(False);
  FMapClustersDirty := True; 
  if Assigned(FOnTextChanged) then FOnTextChanged(Self);
end;

procedure TEngineText.Redo;
var
  Action, UndoAction: TUndoAction;
begin
  if Length(FRedoStack) = 0 then Exit;
  Action := FRedoStack[High(FRedoStack)];
  SetLength(FRedoStack, Length(FRedoStack) - 1);
  UndoAction.StartByte := Action.StartByte;
  UndoAction.EndByte := Action.EndByte;
  UndoAction.OldText := Action.OldText;
  UndoAction.NewText := Action.NewText;
  UndoAction.SavedBracketLayout := Copy(FBracketLayout);
  UndoAction.SavedMemos := Copy(FMemoMatch);
  SetLength(FUndoStack, Length(FUndoStack) + 1);
  FUndoStack[High(FUndoStack)] := UndoAction;
  InternalReplaceRange(Action.StartByte, Action.EndByte, Action.NewText);
  FBracketLayout := Copy(Action.SavedBracketLayout);
  FMemoMatch := Copy(Action.SavedMemos);
  RecalculateLane(False);
  FMapClustersDirty := True; 
  if Assigned(FOnTextChanged) then FOnTextChanged(Self);
end;

function TEngineText.GetCodingShifts: TAnnotationShiftArray;
var
  i, B, C, CharLen, DocLen: Integer;
  SafeStart, SafeEnd: Integer;
  P: PChar;
  ByteToCharMap: array of Integer;
begin
  Result := nil;
  SetLength(Result, Length(FBracketLayout));
  if Length(FBracketLayout) = 0 then Exit;
  DocLen := Length(FDocumentText);
  SetLength(ByteToCharMap, DocLen + 1);
  B := 0; C := 0;
  if DocLen > 0 then
  begin
    P := PChar(FDocumentText);
    while B < DocLen do
    begin
      CharLen := UTF8CodepointSize(P + B);
      if CharLen <= 0 then CharLen := 1;
      for i := 0 to CharLen - 1 do
      begin
        if (B + i) <= DocLen then
          ByteToCharMap[B + i] := C;
      end;
      Inc(B, CharLen);
      Inc(C);
    end;
  end;
  while B <= DocLen do
  begin
    ByteToCharMap[B] := C;
    Inc(B);
  end;
  for i := 0 to High(FBracketLayout) do
  begin
    Result[i].ID := FCoding[i].ID;
    SafeStart := Math.EnsureRange(FBracketLayout[i].StartByte, 0, DocLen);
    SafeEnd := Math.EnsureRange(FBracketLayout[i].EndByte, 0, DocLen);
    Result[i].NewStart := ByteToCharMap[SafeStart];
    Result[i].NewLength := ByteToCharMap[SafeEnd] - Result[i].NewStart;
  end;
end;

function TEngineText.GetMemoShifts: TAnnotationShiftArray;
var
  i, B, C, CharLen, DocLen: Integer;
  SafeStart, SafeEnd: Integer;
  P: PChar;
  ByteToCharMap: array of Integer;
begin
  Result := nil;
  SetLength(Result, Length(FMemoMatch));
  if Length(FMemoMatch) = 0 then Exit;
  DocLen := Length(FDocumentText);
  SetLength(ByteToCharMap, DocLen + 1);
  B := 0; C := 0;
  if DocLen > 0 then
  begin
    P := PChar(FDocumentText);
    while B < DocLen do
    begin
      CharLen := UTF8CodepointSize(P + B);
      if CharLen <= 0 then CharLen := 1;
      for i := 0 to CharLen - 1 do
      begin
        if (B + i) <= DocLen then
          ByteToCharMap[B + i] := C;
      end;
      Inc(B, CharLen);
      Inc(C);
    end;
  end;
  while B <= DocLen do
  begin
    ByteToCharMap[B] := C;
    Inc(B);
  end;
  for i := 0 to High(FMemoMatch) do
  begin
    Result[i].ID := FMemoMatch[i].ID;
    SafeStart := Math.EnsureRange(FMemoMatch[i].StartByte, 0, DocLen);
    SafeEnd := Math.EnsureRange(FMemoMatch[i].StartByte + FMemoMatch[i].LengthBytes, 0, DocLen);
    Result[i].NewStart := ByteToCharMap[SafeStart];
    Result[i].NewLength := ByteToCharMap[SafeEnd] - Result[i].NewStart;
  end;
end;

procedure TEngineText.SetCodings(const ACoding: TCodingArray);
var
  i: Integer;
begin
  SetLength(FBracketHit, 0);
  SetLength(FMapClusters, 0);
  FCoding := ACoding;
  SetLength(FBracketLayout, Length(FCoding));
  for i := 0 to High(FCoding) do
  begin
    FBracketLayout[i].StartByte := CharToByte(FCoding[i].StartCharacter);
    FBracketLayout[i].EndByte := CharToByte(FCoding[i].StartCharacter + FCoding[i].Length);
  end;
  RecalculateLane(False);
  FMapClustersDirty := True;
end;

procedure TEngineText.SetFocusedCoding(const ID: String);
begin
  FFocusedCodingID := ID;
  FFocusedMemoID := '';
end;

procedure TEngineText.SetFocusedMemo(const ID: String);
begin
  FFocusedMemoID := ID;
  FFocusedCodingID := '';
  FIsBracketSelection := False;
  FSelStartByte := -1;
  FSelEndByte := -1;
end;

procedure TEngineText.SelectCoding(const CodingID: String);
var
  i: Integer;
begin
  for i := 0 to High(FCoding) do
  begin
    if FCoding[i].ID = CodingID then
    begin
      FSelStartByte := FBracketLayout[i].StartByte;
      FSelEndByte := FBracketLayout[i].EndByte;
      FIsBracketSelection := True;
      Break;
    end;
  end;
end;

procedure TEngineText.SetMemoHighlights(const AMemoArray: array of TMemoMatch);
var
  i, j, Overlaps: Integer;
begin
  SetLength(FMemoMatch, Length(AMemoArray));
  for i := 0 to High(AMemoArray) do
  begin
    FMemoMatch[i] := AMemoArray[i];
    Overlaps := 0;
    for j := 0 to i - 1 do
    begin
      if (FMemoMatch[j].StartByte < FMemoMatch[i].StartByte + FMemoMatch[i].LengthBytes) and
         (FMemoMatch[j].StartByte + FMemoMatch[j].LengthBytes > FMemoMatch[i].StartByte) then
        Inc(Overlaps);
    end;
    FMemoMatch[i].Lane := Overlaps mod 3;
  end;
  RecalculateLane(False);
  FMapClustersDirty := True;
end;

function TEngineText.GetCodingInfo(Index: Integer; out ID: String; out Color: TColor): Boolean;
begin
  Result := False;
  if (Index >= 0) and (Index <= High(FCoding)) then
  begin
    ID := FCoding[Index].ID;
    Color := FCoding[Index].Color;
    Result := True;
  end;
end;

function TEngineText.CharToByte(AChar: Integer): Integer;
var
  P: PChar;
  C: Integer;
begin
  if Length(FDocumentText) = 0 then Exit(0);
  if AChar <= 0 then Exit(0);
  P := PChar(FDocumentText);
  C := 0;
  while (P^ <> #0) and (C < AChar) do
  begin
    Inc(P, UTF8CodepointSize(P));
    Inc(C);
  end;
  Result := P - PChar(FDocumentText);
end;

function TEngineText.ByteToChar(AByte: Integer): Integer;
var
  P, TargetP: PChar;
begin
  if Length(FDocumentText) = 0 then Exit(0);
  if AByte <= 0 then Exit(0);
  P := PChar(FDocumentText);
  TargetP := P + Math.EnsureRange(AByte, 0, Length(FDocumentText));
  Result := 0;
  while (P < TargetP) and (P^ <> #0) do
  begin
    Inc(P, UTF8CodepointSize(P));
    Inc(Result);
  end;
end;

function TEngineText.GetParagraphAtByte(AByte: Integer): Integer;
var
  L, R, M, EndByte: Integer;
begin
  Result := 0;
  if Length(FParagraphs) = 0 then Exit;
  L := 0;
  R := High(FParagraphs);
  while L <= R do
  begin
    M := L + (R - L) div 2;
    if M = High(FParagraphs) then EndByte := FParagraphs[M].StartByte + FParagraphs[M].LengthBytes
    else EndByte := FParagraphs[M + 1].StartByte - 1;
    if (AByte >= FParagraphs[M].StartByte) and (AByte <= EndByte) then
      Exit(M)
    else if AByte < FParagraphs[M].StartByte then
      R := M - 1
    else
      L := M + 1;
  end;
  if AByte >= FParagraphs[High(FParagraphs)].StartByte then Result := High(FParagraphs);
end;

function TEngineText.GetParagraphAtY(AY: Integer): Integer;
var
  L, R, M: Integer;
begin
  Result := 0;
  if Length(FParagraphs) = 0 then Exit;
  L := 0;
  R := High(FParagraphs);
  while L <= R do
  begin
    M := L + (R - L) div 2;
    if (AY >= FParagraphs[M].YOffset) and (AY < FParagraphs[M].YOffset + FParagraphs[M].PixelHeight) then
      Exit(M)
    else if AY < FParagraphs[M].YOffset then
      R := M - 1
    else
      L := M + 1;
  end;
  if AY >= FParagraphs[High(FParagraphs)].YOffset then Result := High(FParagraphs);
end;

function TEngineText.ByteFromXY(X, Y: Integer): Integer;
var
  Index, Trailing, ParagraphIndex: Integer;
  LX, LY: Integer;
  ActualBytePos, MaxBytePos, i: Integer;
  P: PChar;
begin
  Result := 0;
  if Length(FParagraphs) = 0 then Exit;
  ParagraphIndex := Math.EnsureRange(GetParagraphAtY(Y), 0, High(FParagraphs));
  if FParagraphs[ParagraphIndex].Layout = nil then Exit(FParagraphs[ParagraphIndex].StartByte);
  LX := Integer(Int64(X - FMarginLeft) * Int64(PANGO_SCALE));
  LY := Integer(Int64(Y - FParagraphs[ParagraphIndex].YOffset) * Int64(PANGO_SCALE));
  pango_layout_xy_to_index(FParagraphs[ParagraphIndex].Layout, LX, LY, @Index, @Trailing);
  ActualBytePos := FParagraphs[ParagraphIndex].StartByte + Index;
  MaxBytePos := FParagraphs[ParagraphIndex].StartByte + FParagraphs[ParagraphIndex].LengthBytes;
  if Trailing > 0 then
  begin
    P := PChar(FDocumentText) + ActualBytePos;
    for i := 1 to Trailing do
    begin
      if P^ = #0 then Break;
      Inc(P, UTF8CodepointSize(P));
    end;
    ActualBytePos := P - PChar(FDocumentText);
  end;
  if (FParagraphs[ParagraphIndex].LengthBytes > 0) and 
     (MaxBytePos <= Length(FDocumentText)) and 
     (FDocumentText[MaxBytePos] = #10) then
  begin
    if ActualBytePos >= MaxBytePos then
      ActualBytePos := MaxBytePos - 1;
  end
  else
  begin
    if ActualBytePos > MaxBytePos then
      ActualBytePos := MaxBytePos;
  end;
  Result := ActualBytePos;
end;

function TEngineText.GetYForByte(AByte: Integer): Integer;
var
  ParagraphIndex: Integer;
begin
  ParagraphIndex := GetParagraphAtByte(AByte);
  if (ParagraphIndex >= 0) and (ParagraphIndex <= High(FParagraphs)) then
    Result := FParagraphs[ParagraphIndex].YOffset
  else
    Result := 0;
end;

function TEngineText.GetYForChar(AChar: Integer): Integer;
begin
  Result := GetYForByte(CharToByte(AChar));
end;

function TEngineText.GetTopVisibleByte(ScrollY: Integer): Integer;
begin
  Result := ByteFromXY(FMarginLeft + 10, ScrollY);
end;

function TEngineText.DocumentHeight: Integer;
begin
  Result := FDocumentHeight;
end;

procedure TEngineText.EstimateParagraphs;
var
  i, CurrentY: Integer;
  CharacterPerLine, Lines: Integer;
  LineH, ParagraphSpacing: Integer;
begin
  CurrentY := FMarginTop;
  LineH := MulDiv(Round((READ_SIZE_DEFAULT + FZoomOffset) * 1.6), FDPI, 96);
  ParagraphSpacing := MulDiv(4, FDPI, 96);
  CharacterPerLine := Max(10, FTextAreaWidth div MulDiv(8, FDPI, 96));
  if Length(FParagraphs) = 0 then
  begin
    SetLength(FParagraphs, 1);
    FParagraphs[0].StartByte := 0;
    FParagraphs[0].LengthBytes := 0;
    FParagraphs[0].Estimated := True;
    FParagraphs[0].Layout := nil;
  end;
  for i := 0 to High(FParagraphs) do
  begin
    if FParagraphs[i].Estimated then
    begin
      Lines := Max(1, FParagraphs[i].LengthBytes div CharacterPerLine);
      if FParagraphs[i].LengthBytes = 0 then Lines := 1;
      FParagraphs[i].PixelHeight := (Lines * LineH) + ParagraphSpacing; 
    end;
    FParagraphs[i].YOffset := CurrentY;
    CurrentY := CurrentY + FParagraphs[i].PixelHeight;
  end;
  FDocumentHeight := CurrentY + FMarginBottom;
end;

procedure TEngineText.EnsureLayout(ParagraphIndex: Integer; cr: Pcairo_t; AScrollY: PInteger = nil);
var
  w, h, Delta, i: Integer;
  LengthByte, CheckIndex: Integer;
  ParagraphSpacing: Integer;
begin
  if not FParagraphs[ParagraphIndex].Estimated and (FParagraphs[ParagraphIndex].Layout <> nil) then 
  begin
    pango_cairo_update_layout(cr, FParagraphs[ParagraphIndex].Layout);
    Exit;
  end;
  if FParagraphs[ParagraphIndex].Layout = nil then
    FParagraphs[ParagraphIndex].Layout := pango_cairo_create_layout(cr)
  else
    pango_cairo_update_layout(cr, FParagraphs[ParagraphIndex].Layout);
  ParagraphSpacing := MulDiv(4, FDPI, 96);
  pango_layout_set_width(FParagraphs[ParagraphIndex].Layout, FTextAreaWidth * PANGO_SCALE);
  pango_layout_set_wrap(FParagraphs[ParagraphIndex].Layout, PANGO_WRAP_WORD_CHAR);
  pango_layout_set_spacing(FParagraphs[ParagraphIndex].Layout, MulDiv(3, FDPI, 96) * PANGO_SCALE);
  pango_layout_set_font_description(FParagraphs[ParagraphIndex].Layout, FBaseFontDescription);
  pango_cairo_context_set_resolution(pango_layout_get_context(FParagraphs[ParagraphIndex].Layout), FDPI);
  LengthByte := FParagraphs[ParagraphIndex].LengthBytes;
  if LengthByte > 0 then
  begin
    CheckIndex := FParagraphs[ParagraphIndex].StartByte + LengthByte;
    if (CheckIndex > 0) and (CheckIndex <= Length(FDocumentText)) and (FDocumentText[CheckIndex] = #10) then 
      Dec(LengthByte);
    if LengthByte > 0 then
      pango_layout_set_text(FParagraphs[ParagraphIndex].Layout, PChar(FDocumentText) + FParagraphs[ParagraphIndex].StartByte, LengthByte)
    else
      pango_layout_set_text(FParagraphs[ParagraphIndex].Layout, ' ', 1);
  end
  else
    pango_layout_set_text(FParagraphs[ParagraphIndex].Layout, ' ', 1);
  pango_layout_get_pixel_size(FParagraphs[ParagraphIndex].Layout, @w, @h);
  h := h + ParagraphSpacing;
  if FParagraphs[ParagraphIndex].Estimated then
  begin
    Delta := h - FParagraphs[ParagraphIndex].PixelHeight;
    FParagraphs[ParagraphIndex].PixelHeight := h;
    FParagraphs[ParagraphIndex].Estimated := False;
    if Delta <> 0 then
    begin
      FDocumentHeight := FDocumentHeight + Delta;
      for i := ParagraphIndex + 1 to High(FParagraphs) do
        FParagraphs[i].YOffset := FParagraphs[i].YOffset + Delta;
      if (AScrollY <> nil) and (FParagraphs[ParagraphIndex].YOffset <= AScrollY^) then
        AScrollY^ := AScrollY^ + Delta;
    end;
  end;
end;

procedure TEngineText.GarbageCollectLayout(VisibleStart, VisibleEnd: Integer);
var
  i: Integer;
begin
  for i := 0 to High(FParagraphs) do
  begin
    if (i < VisibleStart - 50) or (i > VisibleEnd + 50) then
    begin
      if FParagraphs[i].Layout <> nil then
      begin
        g_object_unref(FParagraphs[i].Layout);
        FParagraphs[i].Layout := nil;
      end;
    end;
  end;
end;

procedure TEngineText.RecalculateLane(ForceReflow: Boolean = False);
var
  i, j, MaxLaneUsed, FoundLane: Integer;
  Lane: array of Integer;
  NewBracketsWidth, NewTextAreaWidth: Integer;
  HasAnchors: Boolean;
  MaxCharacterPerLine, SafetyBuffer: Integer;
begin
  if FViewWidth <= 0 then Exit;
  HasAnchors := (Length(FCoding) > 0) or (Length(FMemoMatch) > 0);
  if HasAnchors then
    FMarginLeft := FBenchmarkM * 2
  else
    FMarginLeft := FBenchmarkM;
  NewTextAreaWidth := Max(50, FViewWidth - FMarginLeft - FMarginRight);
  MaxCharacterPerLine := Max(10, NewTextAreaWidth div MulDiv(8, FDPI, 96));
  SafetyBuffer := MaxCharacterPerLine * 2;
  MaxLaneUsed := -1;
  SetLength(Lane, Length(FCoding));
  for i := 0 to High(Lane) do Lane[i] := -1;
  for i := 0 to High(FCoding) do
  begin
    FoundLane := 0;
    for j := 0 to High(Lane) do
    begin
      if (Lane[j] = -1) or ((Lane[j] + SafetyBuffer) < FBracketLayout[i].StartByte) then
      begin
        FoundLane := j;
        Lane[j] := FBracketLayout[i].EndByte;
        Break;
      end;
    end;
    FBracketLayout[i].LaneIndex := FoundLane;
    if FoundLane > MaxLaneUsed then MaxLaneUsed := FoundLane;
  end;
  if Length(FCoding) > 0 then
  begin
    NewBracketsWidth := (MaxLaneUsed + 1) * MulDiv(BRACKET_LANE_WIDTH, FDPI, 96);
    FMarginRight := FBenchmarkM + NewBracketsWidth + FBenchmarkM;
  end
  else
  begin
    NewBracketsWidth := 0;
    FMarginRight := FBenchmarkM;
  end;
  NewTextAreaWidth := Max(50, FViewWidth - FMarginLeft - FMarginRight);
  if ForceReflow or (NewTextAreaWidth <> FTextAreaWidth) then
  begin
    FBracketsAreaWidth := NewBracketsWidth;
    FTextAreaWidth := NewTextAreaWidth;
    for i := 0 to High(FParagraphs) do
    begin
      FParagraphs[i].Estimated := True;
    end;
    EstimateParagraphs;
  end;
end;

procedure TEngineText.Resize(AViewWidth: Integer);
begin
  if (FViewWidth <> AViewWidth) and (AViewWidth > 0) then
  begin
    FViewWidth := AViewWidth;
    RecalculateLane(True);
  end;
end;

function TEngineText.GetAbsoluteCaret: Integer;
begin
  if Length(FParagraphs) = 0 then Exit(0);
  if FCaretParagraph > High(FParagraphs) then Exit(GetDocumentLengthBytes);
  Result := FParagraphs[FCaretParagraph].StartByte + FCaretByte;
end;

procedure TEngineText.SetCaretToByte(AByte: Integer);
var
  TargetByte: Integer;
begin
  if Length(FParagraphs) = 0 then Exit;
  TargetByte := Math.EnsureRange(AByte, 0, GetDocumentLengthBytes);
  FCaretParagraph := GetParagraphAtByte(TargetByte);
  if FCaretParagraph < 0 then FCaretParagraph := 0;
  if FCaretParagraph > High(FParagraphs) then FCaretParagraph := High(FParagraphs);
  FCaretByte := TargetByte - FParagraphs[FCaretParagraph].StartByte;
  FCaretByte := Math.EnsureRange(FCaretByte, 0, FParagraphs[FCaretParagraph].LengthBytes);
  FIsEditing := True;
  FCaretVisible := True;
end;

procedure TEngineText.SetCaretFromXY(X, Y, ScrollY: Integer);
var
  AbsoluteByte: Integer;
begin
  if not FIsEditing then Exit;
  FCaretParagraph := GetParagraphAtY(Y + ScrollY);
  if FCaretParagraph > High(FParagraphs) then Exit;
  AbsoluteByte := ByteFromXY(X, Y + ScrollY);
  FCaretByte := AbsoluteByte - FParagraphs[FCaretParagraph].StartByte;
  if FCaretByte < 0 then FCaretByte := 0;
  if FCaretByte > FParagraphs[FCaretParagraph].LengthBytes then 
    FCaretByte := FParagraphs[FCaretParagraph].LengthBytes;
  FIsEditing := True;
  FCaretVisible := True;
end;

procedure TEngineText.MoveCaretVertical(DeltaLines, ScrollY: Integer);
var
  Extents: TPangoRectangle;
  TargetX, TargetY, AbsY, LineHeight: Integer;
begin
  if not FIsEditing or (FCaretParagraph < 0) or (FCaretParagraph > High(FParagraphs)) then Exit;
  if FParagraphs[FCaretParagraph].Layout <> nil then
  begin
    pango_layout_get_cursor_pos(FParagraphs[FCaretParagraph].Layout, FCaretByte, @Extents, nil);
    TargetX := FMarginLeft + (Extents.X div PANGO_SCALE);
    LineHeight := Extents.Height div PANGO_SCALE;
    if LineHeight = 0 then LineHeight := MulDiv(24, FDPI, 96);
    AbsY := FParagraphs[FCaretParagraph].YOffset + (Extents.Y div PANGO_SCALE);
    TargetY := AbsY + (DeltaLines * LineHeight) + (LineHeight div 2);
    SetCaretFromXY(TargetX, TargetY - ScrollY, ScrollY);
  end;
end;

procedure TEngineText.ToggleCaret;
begin
  FCaretVisible := not FCaretVisible;
end;

function TEngineText.GetNextCoding(CurrentScrollY, Direction: Integer): String;
var
  i, CodeY: Integer;
  BestY: Integer;
  BestID: String;
begin
  Result := '';
  if Length(FCoding) = 0 then Exit;
  BestID := '';
  if Direction = 1 then BestY := 9999999 else BestY := -1;
  for i := 0 to High(FCoding) do
  begin
    CodeY := GetYForByte(FBracketLayout[i].StartByte);
    if Direction = 1 then
    begin
      if (CodeY > CurrentScrollY + 10) and (CodeY < BestY) then
      begin
        BestY := CodeY;
        BestID := FCoding[i].ID;
      end;
    end
    else
    begin
      if (CodeY < CurrentScrollY - 10) and (CodeY > BestY) then
      begin
        BestY := CodeY;
        BestID := FCoding[i].ID;
      end;
    end;
  end;
  if BestID = '' then
  begin
    if Direction = 1 then BestY := 9999999 else BestY := -1;
    for i := 0 to High(FCoding) do
    begin
      CodeY := GetYForByte(FBracketLayout[i].StartByte);
      if Direction = 1 then
      begin
        if CodeY < BestY then
        begin
          BestY := CodeY;
          BestID := FCoding[i].ID;
        end;
      end
      else
      begin
        if CodeY > BestY then
        begin
          BestY := CodeY;
          BestID := FCoding[i].ID;
        end;
      end;
    end;
  end;
  Result := BestID;
end;

procedure TEngineText.ClearSelection;
begin
  FSelStartByte := -1;
  FSelEndByte := -1;
  FIsBracketSelection := False;
  FFocusedCodingID := '';
  FFocusedMemoID := '';
end;

function TEngineText.HasSelection: Boolean;
begin
  Result := (FSelStartByte >= 0) and (FSelEndByte >= 0) and (FSelStartByte <> FSelEndByte);
end;

function TEngineText.IsBracketSelection: Boolean;
begin
  Result := FIsBracketSelection;
end;

function TEngineText.SelectionStartCharacter: Integer;
begin
  Result := ByteToChar(Min(FSelStartByte, FSelEndByte));
end;

function TEngineText.SelectionLength: Integer;
begin
  Result := Abs(ByteToChar(FSelEndByte) - ByteToChar(FSelStartByte));
end;

function TEngineText.GetSelectedText: String;
var
  S, E: Integer;
begin
  Result := '';
  if not HasSelection then Exit;
  S := Min(FSelStartByte, FSelEndByte);
  E := Max(FSelStartByte, FSelEndByte);
  Result := Copy(FDocumentText, S + 1, E - S);
end;

procedure TEngineText.Paint(DC: HDC; ViewWidth, ViewHeight: Integer; var ScrollY: Integer);
var
  surface: Pcairo_surface_t;
  cr: Pcairo_t;
  Iter: Pointer;
  Line: Pointer;
  Extents: TPangoRectangle;
  Baseline, p: Integer;
  StartVisibleParagraph, EndVisibleParagraph: Integer;
  LocalScrollY, OldScrollY: Integer;
begin
  if (ViewWidth <= 1) or (DC = 0) then Exit;
  if FViewWidth <> ViewWidth then
  begin
    FViewWidth := ViewWidth;
    RecalculateLane(False);
  end;
  surface := cairo_win32_surface_create(DC);
  cr := cairo_create(surface);
  try
    cairo_set_source_rgb(cr, 1, 1, 1);
    cairo_paint(cr);
    LocalScrollY := ScrollY;
    repeat
      OldScrollY := LocalScrollY;
      StartVisibleParagraph := GetParagraphAtY(LocalScrollY);
      EndVisibleParagraph := GetParagraphAtY(LocalScrollY + ViewHeight);
      for p := StartVisibleParagraph to EndVisibleParagraph do
        EnsureLayout(p, cr, @LocalScrollY);
    until OldScrollY = LocalScrollY;
    ScrollY := LocalScrollY;
    DrawHighlights(cr, ScrollY, ViewHeight);
    DrawSearchHighlights(cr, ScrollY, ViewHeight);
    DrawMemoHighlights(cr, ScrollY, ViewHeight);
    DrawSelection(cr, ScrollY, ViewHeight);
    cairo_set_source_rgb(cr, 0.12, 0.12, 0.12);
    for p := StartVisibleParagraph to EndVisibleParagraph do
    begin
      if FParagraphs[p].Layout = nil then Continue;
      Iter := pango_layout_get_iter(FParagraphs[p].Layout);
      if Iter = nil then Continue;
      try
        repeat
          pango_layout_iter_get_line_extents(Iter, nil, @Extents);
          if FParagraphs[p].YOffset + (Extents.Y div PANGO_SCALE) > ScrollY + ViewHeight then Break;
          if FParagraphs[p].YOffset + (Extents.Y div PANGO_SCALE) + (Extents.Height div PANGO_SCALE) >= ScrollY then
          begin
            Line := pango_layout_iter_get_line_readonly(Iter);
            if Line <> nil then
            begin
              Baseline := pango_layout_iter_get_baseline(Iter);
              cairo_move_to(cr, FMarginLeft + (Extents.X div PANGO_SCALE),
                                FParagraphs[p].YOffset + (Baseline div PANGO_SCALE) - ScrollY);
              pango_cairo_show_layout_line(cr, Line);
            end;
          end;
        until not pango_layout_iter_next_line(Iter);
      finally
        pango_layout_iter_free(Iter);
      end;
    end;
    if FIsEditing and FCaretVisible and (FCaretParagraph >= StartVisibleParagraph) and (FCaretParagraph <= EndVisibleParagraph) then
    begin
      if FParagraphs[FCaretParagraph].Layout <> nil then
      begin
        pango_layout_get_cursor_pos(FParagraphs[FCaretParagraph].Layout, FCaretByte, @Extents, nil);
        cairo_set_source_rgb(cr, 0.05, 0.05, 0.05); 
        cairo_set_line_width(cr, Max(1.0, 1.0 * (FDPI / 96.0))); 
        cairo_move_to(cr, FMarginLeft + (Extents.X div PANGO_SCALE) + 0.5, 
                          FParagraphs[FCaretParagraph].YOffset + (Extents.Y div PANGO_SCALE) - ScrollY + 1.0);
        cairo_line_to(cr, FMarginLeft + (Extents.X div PANGO_SCALE) + 0.5, 
                          FParagraphs[FCaretParagraph].YOffset + ((Extents.Y + Extents.Height) div PANGO_SCALE) - ScrollY - 1.0);
        cairo_stroke(cr);
      end;
    end;
    DrawBrackets(cr, ScrollY, ViewHeight);
    DrawActionAnchors(cr, ViewHeight);
    GarbageCollectLayout(StartVisibleParagraph, EndVisibleParagraph);
  finally
    cairo_destroy(cr);
    cairo_surface_destroy(surface);
  end;
end;

procedure TEngineText.DrawBrackets(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
var
  i, StartParagraph, EndParagraph: Integer;
  BracketX, TopY, BottomY: Integer;
  BracketRectangle: TRect;
  R, G, B: Byte;
  LineW: Double;
  ScaledHitX, ScaledHitY, ScaledLineTick: Integer;
  StartRect, EndRect: TPangoRectangle;
  StartVisibleParagraph, EndVisibleParagraph: Integer;
  TargetByte: Integer;
begin
  if Length(FCoding) = 0 then Exit;
  SetLength(FBracketHit, 0);
  cairo_save(cr);
  cairo_set_antialias(cr, CAIRO_ANTIALIAS_BEST);
  ScaledHitX := MulDiv(8, FDPI, 96);
  ScaledHitY := MulDiv(2, FDPI, 96);
  ScaledLineTick := MulDiv(3, FDPI, 96);
  StartVisibleParagraph := GetParagraphAtY(ScrollY);
  EndVisibleParagraph := GetParagraphAtY(ScrollY + ViewHeight);
  for i := 0 to High(FCoding) do
  begin
    if (FBracketLayout[i].EndByte < FParagraphs[StartVisibleParagraph].StartByte) or
       (FBracketLayout[i].StartByte > FParagraphs[EndVisibleParagraph].StartByte + FParagraphs[EndVisibleParagraph].LengthBytes) then
      Continue;
    StartParagraph := GetParagraphAtByte(FBracketLayout[i].StartByte);
    if StartParagraph < StartVisibleParagraph then
      TopY := ScrollY - 100 
    else
    begin
      if FParagraphs[StartParagraph].Layout <> nil then
      begin
        pango_layout_index_to_pos(FParagraphs[StartParagraph].Layout, FBracketLayout[i].StartByte - FParagraphs[StartParagraph].StartByte, @StartRect);
        TopY := FParagraphs[StartParagraph].YOffset + (StartRect.Y div PANGO_SCALE);
      end
      else
        TopY := FParagraphs[StartParagraph].YOffset;
    end;
    TargetByte := Max(FBracketLayout[i].StartByte, FBracketLayout[i].EndByte - 1);
    EndParagraph := GetParagraphAtByte(TargetByte);
    if EndParagraph > EndVisibleParagraph then
      BottomY := ScrollY + ViewHeight + 100 
    else
    begin
      if FParagraphs[EndParagraph].Layout <> nil then
      begin
        pango_layout_index_to_pos(FParagraphs[EndParagraph].Layout, TargetByte - FParagraphs[EndParagraph].StartByte, @EndRect);
        BottomY := FParagraphs[EndParagraph].YOffset + (EndRect.Y div PANGO_SCALE) + (EndRect.Height div PANGO_SCALE);
      end
      else
        BottomY := FParagraphs[EndParagraph].YOffset + FParagraphs[EndParagraph].PixelHeight;
    end;
    BracketX := FViewWidth - FBenchmarkM - (FBracketLayout[i].LaneIndex * MulDiv(BRACKET_LANE_WIDTH, FDPI, 96));
    SetLength(FBracketHit, Length(FBracketHit) + 1);
    BracketRectangle := Rect(BracketX - ScaledHitX, TopY - ScaledHitY, BracketX + ScaledHitX, BottomY + ScaledHitY);
    if BracketRectangle.Height < ScaledLineTick then BracketRectangle.Bottom := BracketRectangle.Top + ScaledLineTick;
    FBracketHit[High(FBracketHit)].Rectangle := BracketRectangle;
    FBracketHit[High(FBracketHit)].CodingID := FCoding[i].ID;
    if (BottomY < ScrollY) or (TopY > ScrollY + ViewHeight) then Continue;
    RedGreenBlue(ColorToRGB(FCoding[i].Color), R, G, B);
    if FCoding[i].ID = FFocusedCodingID then
    begin
      LineW := 2.0 * (FDPI / 96.0);
      cairo_set_source_rgba(cr, R/255, G/255, B/255, 1.0);
    end
    else
    begin
      LineW := 1.0 * (FDPI / 96.0);
      cairo_set_source_rgba(cr, R/255, G/255, B/255, 0.7);
    end;
    cairo_set_line_width(cr, LineW);
    cairo_new_path(cr);
    if StartParagraph >= StartVisibleParagraph then
    begin
      cairo_move_to(cr, BracketX - ScaledLineTick, TopY - ScrollY);
      cairo_line_to(cr, BracketX, TopY - ScrollY);
    end
    else
      cairo_move_to(cr, BracketX, TopY - ScrollY);
    cairo_line_to(cr, BracketX, BottomY - ScrollY);
    if EndParagraph <= EndVisibleParagraph then
      cairo_line_to(cr, BracketX - ScaledLineTick, BottomY - ScrollY);
    cairo_stroke(cr);
  end;
  cairo_restore(cr);
end;

procedure TEngineText.DrawRange(cr: Pcairo_t; AStartByte, AEndByte: Integer; AColor: TColor; AAlpha: Double; ScrollY, ViewHeight: Integer);
var
  S, E, StartParagraph, EndParagraph, p, LocalS, LocalE, ActualLen: Integer;
  j: Integer;
  Line: Pointer;
  Extents, InkRectangle: TPangoRectangle;
  Range: PInteger;
  NRange: Integer;
  X1, X2, LY, LH, SafeLeft, SafeRight: Double;
  Iter: Pointer;
begin
  if (AStartByte < 0) or (AEndByte < 0) or (AStartByte = AEndByte) then Exit;
  S := Min(AStartByte, AEndByte);
  E := Max(AStartByte, AEndByte);
  StartParagraph := Max(GetParagraphAtByte(S), GetParagraphAtY(ScrollY));
  EndParagraph := Min(GetParagraphAtByte(E), GetParagraphAtY(ScrollY + ViewHeight));
  if StartParagraph > EndParagraph then Exit;
  cairo_save(cr);
  cairo_set_source_rgba(cr, Red(AColor)/255.0, Green(AColor)/255.0, Blue(AColor)/255.0, AAlpha);
  for p := StartParagraph to EndParagraph do
  begin
    if FParagraphs[p].Layout = nil then Continue;
    ActualLen := FParagraphs[p].LengthBytes;
    if (ActualLen > 0) and (FDocumentText[FParagraphs[p].StartByte + ActualLen] = #10) then
      Dec(ActualLen);
    LocalS := Max(0, S - FParagraphs[p].StartByte);
    LocalE := Min(ActualLen, E - FParagraphs[p].StartByte);
    if LocalS >= LocalE then Continue;
    Iter := pango_layout_get_iter(FParagraphs[p].Layout);
    if Iter = nil then Continue;
    try
      repeat
        pango_layout_iter_get_line_extents(Iter, @InkRectangle, @Extents);
        LY := FParagraphs[p].YOffset + (Extents.Y / PANGO_SCALE);
        LH := (Extents.Height / PANGO_SCALE);
        if LY > ScrollY + ViewHeight then Break;
        if LY + LH < ScrollY then Continue;
        SafeLeft := Min(Extents.X, InkRectangle.X) / PANGO_SCALE;
        SafeRight := Max(Extents.X + Extents.Width, InkRectangle.X + InkRectangle.Width) / PANGO_SCALE;
        Line := pango_layout_iter_get_line_readonly(Iter);
        NRange := 0;
        Range := nil;
        pango_layout_line_get_x_ranges(Line, LocalS, LocalE, @Range, @NRange);
        if (NRange > 0) and (Range <> nil) then
        begin
          cairo_new_path(cr);
          for j := 0 to NRange - 1 do
          begin
            X1 := Range[j*2] / PANGO_SCALE;
            X2 := Range[j*2+1] / PANGO_SCALE;
            X1 := EnsureRange(X1, SafeLeft, SafeRight);
            X2 := EnsureRange(X2, SafeLeft, SafeRight);
            if X2 > X1 then
              cairo_rectangle(cr, FMarginLeft + X1, LY - ScrollY, X2 - X1, LH);
          end;
          cairo_fill(cr);
          g_free(Range);
        end;
      until not pango_layout_iter_next_line(Iter);
    finally
      pango_layout_iter_free(Iter);
    end;
  end;
  cairo_restore(cr);
end;

procedure TEngineText.DrawSelection(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
var
  i: Integer;
  IsFocusedTarget: Boolean;
begin
  if not HasSelection then Exit;
  IsFocusedTarget := False;
  if FFocusedCodingID <> '' then
  begin
    for i := 0 to High(FCoding) do
    begin
      if FCoding[i].ID = FFocusedCodingID then
      begin
        if (Min(FSelStartByte, FSelEndByte) = FBracketLayout[i].StartByte) and
           (Max(FSelStartByte, FSelEndByte) = FBracketLayout[i].EndByte) then
        begin
          IsFocusedTarget := True;
        end;
        Break;
      end;
    end;
  end;
  if not IsFocusedTarget then
    DrawRange(cr, FSelStartByte, FSelEndByte, RGBToColor(51, 153, 255), 0.4, ScrollY, ViewHeight);
end;

procedure TEngineText.DrawSearchHighlights(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
var
  i, L, R, M, FirstMatch, VisibleStartByte, VisibleEndByte: Integer;
begin
  if Length(FSearchMatch) = 0 then Exit;
  VisibleStartByte := FParagraphs[GetParagraphAtY(ScrollY)].StartByte;
  VisibleEndByte := FParagraphs[GetParagraphAtY(ScrollY + ViewHeight)].StartByte + FParagraphs[GetParagraphAtY(ScrollY + ViewHeight)].LengthBytes;
  L := 0; 
  R := High(FSearchMatch); 
  FirstMatch := -1;
  while L <= R do
  begin
    M := L + (R - L) div 2;
    if FSearchMatch[M].StartByte + FSearchMatch[M].LengthBytes >= VisibleStartByte then
    begin
      FirstMatch := M;
      R := M - 1;
    end 
    else 
      L := M + 1;
  end;
  if FirstMatch <> -1 then
  begin
    for i := FirstMatch to High(FSearchMatch) do
    begin
      if FSearchMatch[i].StartByte > VisibleEndByte then Break;
      if i = FActiveMatchIndex then
        DrawRange(cr, FSearchMatch[i].StartByte, FSearchMatch[i].StartByte + FSearchMatch[i].LengthBytes, RGBToColor(255, 165, 0), 0.6, ScrollY, ViewHeight)
      else
        DrawRange(cr, FSearchMatch[i].StartByte, FSearchMatch[i].StartByte + FSearchMatch[i].LengthBytes, RGBToColor(255, 220, 0), 0.4, ScrollY, ViewHeight);
    end;
  end;
end;

procedure TEngineText.DrawHighlights(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
var
  i: Integer;
  VisibleStartByte, VisibleEndByte: Integer;
begin
  if Length(FCoding) = 0 then Exit;
  
  VisibleStartByte := FParagraphs[GetParagraphAtY(ScrollY)].StartByte;
  VisibleEndByte := FParagraphs[GetParagraphAtY(ScrollY + ViewHeight)].StartByte + FParagraphs[GetParagraphAtY(ScrollY + ViewHeight)].LengthBytes;
  for i := 0 to High(FCoding) do
  begin
    if (FBracketLayout[i].EndByte < VisibleStartByte) or
       (FBracketLayout[i].StartByte > VisibleEndByte) then Continue;
       
    if FCoding[i].ID = FFocusedCodingID then Continue;
    
    DrawRange(cr, FBracketLayout[i].StartByte,
              FBracketLayout[i].EndByte,
              FCoding[i].Color, 0.25, ScrollY, ViewHeight);
  end;
  if FFocusedCodingID <> '' then
  begin
    for i := 0 to High(FCoding) do
    begin
      if FCoding[i].ID = FFocusedCodingID then
      begin
        DrawRange(cr, FBracketLayout[i].StartByte,
                  FBracketLayout[i].EndByte,
                  FCoding[i].Color, 0.65, ScrollY, ViewHeight);
        Break;
      end;
    end;
  end;
end;

procedure TEngineText.DrawMemoHighlights(cr: Pcairo_t; ScrollY, ViewHeight: Integer);
var
  i, S, E, j, p, LocalS, LocalE, ActualLen: Integer;
  Line: Pointer;
  Extents, InkRectangle: TPangoRectangle;
  Range: PInteger;
  NRange: Integer;
  X1, X2, LY, LH, SafeLeft, SafeRight, YOffset, BaseY: Double;
  Iter: Pointer;
  StartParagraph, EndParagraph: Integer;
  VisibleStartByte, VisibleEndByte: Integer;
begin
  if Length(FMemoMatch) = 0 then Exit;
  VisibleStartByte := FParagraphs[GetParagraphAtY(ScrollY)].StartByte;
  VisibleEndByte := FParagraphs[GetParagraphAtY(ScrollY + ViewHeight)].StartByte + FParagraphs[GetParagraphAtY(ScrollY + ViewHeight)].LengthBytes;
  cairo_save(cr);
  for i := 0 to High(FMemoMatch) do
  begin
    if (FMemoMatch[i].StartByte + FMemoMatch[i].LengthBytes < VisibleStartByte) or
       (FMemoMatch[i].StartByte > VisibleEndByte) then
      Continue;
    cairo_set_line_width(cr, 1.0 * (FDPI / 96.0));
    if FMemoMatch[i].ID = FFocusedMemoID then
      cairo_set_source_rgb(cr, 0.0, 0.0, 0.0)
    else
      cairo_set_source_rgb(cr, 0.5, 0.5, 0.5);
    S := FMemoMatch[i].StartByte;
    E := FMemoMatch[i].StartByte + FMemoMatch[i].LengthBytes;
    YOffset := FMemoMatch[i].Lane * (2.0 * (FDPI / 96.0));
    StartParagraph := Max(GetParagraphAtByte(S), GetParagraphAtY(ScrollY));
    EndParagraph := Min(GetParagraphAtByte(E), GetParagraphAtY(ScrollY + ViewHeight));
    for p := StartParagraph to EndParagraph do
    begin
      if FParagraphs[p].Layout = nil then Continue;
      ActualLen := FParagraphs[p].LengthBytes;
      if (ActualLen > 0) and (FDocumentText[FParagraphs[p].StartByte + ActualLen] = #10) then
        Dec(ActualLen);
      LocalS := Max(0, S - FParagraphs[p].StartByte);
      LocalE := Min(ActualLen, E - FParagraphs[p].StartByte);
      if LocalS >= LocalE then Continue;
      Iter := pango_layout_get_iter(FParagraphs[p].Layout);
      if Iter = nil then Continue;
      try
        repeat
          pango_layout_iter_get_line_extents(Iter, @InkRectangle, @Extents);
          LY := FParagraphs[p].YOffset + (Extents.Y / PANGO_SCALE);
          LH := (Extents.Height / PANGO_SCALE);
          if LY > ScrollY + ViewHeight then Break;
          if LY + LH < ScrollY then Continue;
          SafeLeft := Min(Extents.X, InkRectangle.X) / PANGO_SCALE;
          SafeRight := Max(Extents.X + Extents.Width, InkRectangle.X + InkRectangle.Width) / PANGO_SCALE;
          Line := pango_layout_iter_get_line_readonly(Iter);
          NRange := 0;
          Range := nil;
          pango_layout_line_get_x_ranges(Line, LocalS, LocalE, @Range, @NRange);
          if (NRange > 0) and (Range <> nil) then
          begin
            cairo_new_path(cr);
            for j := 0 to NRange - 1 do
            begin
              X1 := Range[j*2] / PANGO_SCALE;
              X2 := Range[j*2+1] / PANGO_SCALE;
              X1 := EnsureRange(X1, SafeLeft, SafeRight);
              X2 := EnsureRange(X2, SafeLeft, SafeRight);
              if X2 > X1 then
              begin
                BaseY := LY - ScrollY + LH + YOffset;
                cairo_move_to(cr, FMarginLeft + X1, BaseY);
                cairo_line_to(cr, FMarginLeft + X2, BaseY);
              end;
            end;
            cairo_stroke(cr);
            g_free(Range);
          end;
        until not pango_layout_iter_next_line(Iter);
      finally
        pango_layout_iter_free(Iter);
      end;
    end;
  end;
  cairo_restore(cr);
end;

procedure TEngineText.DrawActionAnchors(cr: Pcairo_t; ViewHeight: Integer);
type
  TSortTick = record
    ID: String;
    TickType: TMapTickType;
    StartByte: Integer;
    LengthBytes: Integer;
    Color: TColor;
    Name: String;
  end;
var
  i, j, MapH, MapTop: Integer;
  MapW, MapX, SegW, StartX: Double;
  R, G, B: Byte;
  TotalBytes: Double;
  MinGap: Double;
  SortArr: array of TSortTick;
  ClusterIdx, ItemIdx: Integer;
  procedure QuickSortTicks(L, R: Integer);
  var
    I_, J_: Integer;
    Pivot, Temp: TSortTick;
    function CompareTicks(const A, B: TSortTick): Integer;
    begin
      if A.StartByte < B.StartByte then Exit(-1);
      if A.StartByte > B.StartByte then Exit(1);
      if A.LengthBytes > B.LengthBytes then Exit(-1);
      if A.LengthBytes < B.LengthBytes then Exit(1);
      if (A.TickType = mttCode) and (B.TickType = mttMemo) then Exit(-1);
      if (A.TickType = mttMemo) and (B.TickType = mttCode) then Exit(1);
      Result := CompareStr(A.ID, B.ID);
    end;
  begin
    if L >= R then Exit;
    I_ := L; J_ := R;
    Pivot := SortArr[L + (R - L) div 2];
    repeat
      while CompareTicks(SortArr[I_], Pivot) < 0 do Inc(I_);
      while CompareTicks(SortArr[J_], Pivot) > 0 do Dec(J_);
      if I_ <= J_ then
      begin
        Temp := SortArr[I_]; SortArr[I_] := SortArr[J_]; SortArr[J_] := Temp;
        Inc(I_); Dec(J_);
      end;
    until I_ > J_;
    if L < J_ then QuickSortTicks(L, J_);
    if I_ < R then QuickSortTicks(I_, R);
  end;
begin
  if (Length(FCoding) = 0) and (Length(FMemoMatch) = 0) then Exit;
  if Length(FParagraphs) = 0 then Exit;
  MapH := ViewHeight div 2;
  MapTop := (ViewHeight - MapH) div 2;
  MapW := 14.0;
  MapX := FBenchmarkM;
  if FMapClustersDirty or (ViewHeight <> FMapClustersViewHeight) then
  begin
    TotalBytes := FParagraphs[High(FParagraphs)].StartByte + FParagraphs[High(FParagraphs)].LengthBytes;
    MinGap := 5.0;
    SetLength(SortArr, Length(FMemoMatch) + Length(FCoding));
    for i := 0 to High(FMemoMatch) do
    begin
      SortArr[i].ID := FMemoMatch[i].ID;
      SortArr[i].TickType := mttMemo;
      SortArr[i].StartByte := FMemoMatch[i].StartByte;
      SortArr[i].LengthBytes := FMemoMatch[i].LengthBytes;
      SortArr[i].Color := clBlack;
      SortArr[i].Name := 'Segment Memo';
    end;
    for i := 0 to High(FCoding) do
    begin
      SortArr[Length(FMemoMatch) + i].ID := FCoding[i].ID;
      SortArr[Length(FMemoMatch) + i].TickType := mttCode;
      SortArr[Length(FMemoMatch) + i].StartByte := FBracketLayout[i].StartByte;
      SortArr[Length(FMemoMatch) + i].LengthBytes := FBracketLayout[i].EndByte - FBracketLayout[i].StartByte;
      SortArr[Length(FMemoMatch) + i].Color := FCoding[i].Color;
      SortArr[Length(FMemoMatch) + i].Name := FCoding[i].Name;
    end;
    if Length(SortArr) > 1 then QuickSortTicks(0, High(SortArr));
    SetLength(FMapClusters, 0);
    for i := 0 to High(SortArr) do
    begin
      if (i > 0) and (SortArr[i].StartByte = SortArr[i-1].StartByte) and (SortArr[i].LengthBytes = SortArr[i-1].LengthBytes) then
      begin
        ClusterIdx := High(FMapClusters);
        ItemIdx := Length(FMapClusters[ClusterIdx].Items);
        SetLength(FMapClusters[ClusterIdx].Items, ItemIdx + 1);
        FMapClusters[ClusterIdx].Items[ItemIdx].ID := SortArr[i].ID;
        FMapClusters[ClusterIdx].Items[ItemIdx].TickType := SortArr[i].TickType;
        FMapClusters[ClusterIdx].Items[ItemIdx].Color := SortArr[i].Color;
        FMapClusters[ClusterIdx].Items[ItemIdx].Name := SortArr[i].Name;
      end
      else
      begin
        SetLength(FMapClusters, Length(FMapClusters) + 1);
        ClusterIdx := High(FMapClusters);
        FMapClusters[ClusterIdx].StartByte := SortArr[i].StartByte;
        FMapClusters[ClusterIdx].LengthBytes := SortArr[i].LengthBytes;
        FMapClusters[ClusterIdx].MapY := MapTop + (SortArr[i].StartByte / Max(1.0, TotalBytes)) * MapH;
        SetLength(FMapClusters[ClusterIdx].Items, 1);
        FMapClusters[ClusterIdx].Items[0].ID := SortArr[i].ID;
        FMapClusters[ClusterIdx].Items[0].TickType := SortArr[i].TickType;
        FMapClusters[ClusterIdx].Items[0].Color := SortArr[i].Color;
        FMapClusters[ClusterIdx].Items[0].Name := SortArr[i].Name;
      end;
    end;
    for i := 1 to High(FMapClusters) do
    begin
      if FMapClusters[i].MapY < FMapClusters[i-1].MapY + MinGap then
        FMapClusters[i].MapY := FMapClusters[i-1].MapY + MinGap;
    end;
    if (Length(FMapClusters) > 0) and (FMapClusters[High(FMapClusters)].MapY > MapTop + MapH) then
    begin
      FMapClusters[High(FMapClusters)].MapY := MapTop + MapH;
      for i := High(FMapClusters) - 1 downto 0 do
      begin
        if FMapClusters[i].MapY > FMapClusters[i+1].MapY - MinGap then
          FMapClusters[i].MapY := FMapClusters[i+1].MapY - MinGap;
      end;
    end;
    FMapClustersDirty := False;
    FMapClustersViewHeight := ViewHeight;
  end;
  cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
  cairo_set_line_width(cr, 0.5);
  cairo_move_to(cr, MapX + 0.5, MapTop);
  cairo_line_to(cr, MapX + 0.5, MapTop + MapH);
  cairo_stroke(cr);
  for i := 0 to High(FMapClusters) do
  begin
    SegW := MapW / Length(FMapClusters[i].Items);
    StartX := (MapX + 0.5) - (MapW / 2.0);
    for j := 0 to High(FMapClusters[i].Items) do
    begin
      RedGreenBlue(ColorToRGB(FMapClusters[i].Items[j].Color), R, G, B);
      if i = FHoveredAnchorIndex then
      begin
        cairo_set_line_width(cr, 3.5);
        cairo_set_source_rgba(cr, R/255.0, G/255.0, B/255.0, 1.0);
      end
      else
      begin
        cairo_set_line_width(cr, 2.0);
        cairo_set_source_rgba(cr, R/255.0, G/255.0, B/255.0, 0.85);
      end;
      cairo_move_to(cr, StartX + (j * SegW), FMapClusters[i].MapY);
      cairo_line_to(cr, StartX + ((j + 1) * SegW), FMapClusters[i].MapY);
      cairo_stroke(cr);
    end;
  end;
end;

function TEngineText.GetBracketAt(X, Y, ScrollY: Integer): String;
var
  i: Integer;
  P: TPoint;
begin
  Result := '';
  P.X := X;
  P.Y := Y + ScrollY;
  for i := 0 to High(FBracketHit) do
  begin
    if PtInRect(FBracketHit[i].Rectangle, P) then
    begin
      Result := FBracketHit[i].CodingID;
      Exit;
    end;
  end;
end;

function TEngineText.GetCharAt(X, Y, ScrollY: Integer): Integer;
begin
  if (X < FMarginLeft) or (X > FViewWidth - FMarginRight) then Exit(-1);
  Result := ByteToChar(ByteFromXY(X, Y + ScrollY));
end;

function TEngineText.IsOverActionAnchors(X, Y, ViewHeight: Integer): Boolean;
var
  MapH, MapTop: Integer;
begin
  Result := False;
  if (Length(FCoding) = 0) and (Length(FMemoMatch) = 0) then Exit;
  MapH := ViewHeight div 2;
  MapTop := (ViewHeight - MapH) div 2;
  Result := (X >= FBenchmarkM - 4) and (X <= FBenchmarkM + 4) and (Y >= MapTop) and (Y <= MapTop + MapH);
end;

function TEngineText.UpdateAnchorHover(X, Y, ViewHeight: Integer): Boolean;
var
  i, BestIndex: Integer;
  Dist, MinDist: Double;
begin
  Result := False;
  BestIndex := -1;
  if IsOverActionAnchors(X, Y, ViewHeight) then
  begin
    MinDist := 9999.0;
    for i := 0 to High(FMapClusters) do
    begin
      Dist := Abs(Y - FMapClusters[i].MapY);
      if Dist < MinDist then
      begin
        MinDist := Dist;
        BestIndex := i;
      end;
    end;
    if MinDist > 4.0 then BestIndex := -1;
  end;
  if FHoveredAnchorIndex <> BestIndex then
  begin
    FHoveredAnchorIndex := BestIndex;
    Result := True;
  end;
end;

function TEngineText.ActionAnchorHitTest(X, Y, ViewHeight: Integer; out TargetCluster: TMapTickCluster; out TargetStartByte: Integer): Boolean;
begin
  Result := False;
  TargetStartByte := 0;
  TargetCluster := Default(TMapTickCluster);
  if (FHoveredAnchorIndex >= 0) and (FHoveredAnchorIndex <= High(FMapClusters)) then
  begin
    TargetCluster := FMapClusters[FHoveredAnchorIndex];
    TargetStartByte := FMapClusters[FHoveredAnchorIndex].StartByte;
    Result := True;
  end;
end;

procedure TEngineText.MouseDown(X, Y, ScrollY: Integer);
begin
  FSelecting := True;
  FIsBracketSelection := False;
  FSelStartByte := ByteFromXY(X, Y + ScrollY);
  FSelEndByte := FSelStartByte;
end;

procedure TEngineText.MouseMove(X, Y, ScrollY: Integer);
begin
  if not FSelecting then Exit;
  FSelEndByte := ByteFromXY(X, Y + ScrollY);
end;

procedure TEngineText.MouseUp;
begin
  FSelecting := False;
end;

procedure TEngineText.ExecuteSearch(const AQuery: String);
var
  TextLower, QueryLower: String;
  BytePos, SearchLen: Integer;
begin
  SetLength(FSearchMatch, 0);
  FActiveMatchIndex := -1;
  if Trim(AQuery) = '' then Exit;
  TextLower := UTF8LowerCase(FDocumentText);
  QueryLower := UTF8LowerCase(AQuery);
  SearchLen := Length(QueryLower);
  BytePos := PosEx(QueryLower, TextLower, 1);
  while BytePos > 0 do
  begin
    SetLength(FSearchMatch, Length(FSearchMatch) + 1);
    FSearchMatch[High(FSearchMatch)].StartByte := BytePos - 1;
    FSearchMatch[High(FSearchMatch)].LengthBytes := SearchLen;
    BytePos := PosEx(QueryLower, TextLower, BytePos + SearchLen);
  end;
  if Length(FSearchMatch) > 0 then FActiveMatchIndex := 0;
end;

procedure TEngineText.NavigateMatch(Direction: Integer);
begin
  if Length(FSearchMatch) = 0 then Exit;
  FActiveMatchIndex := FActiveMatchIndex + Direction;
  if FActiveMatchIndex < 0 then 
    FActiveMatchIndex := High(FSearchMatch)
  else if FActiveMatchIndex > High(FSearchMatch) then 
    FActiveMatchIndex := 0;
end;

function TEngineText.GetSearchStatus(out CurrentMatch, TotalMatch: Integer): Boolean;
begin
  TotalMatch := Length(FSearchMatch);
  if TotalMatch > 0 then
    CurrentMatch := FActiveMatchIndex + 1
  else
    CurrentMatch := 0;
  Result := TotalMatch > 0;
end;

function TEngineText.GetActiveMatchY: Integer;
var
  ParagraphIndex: Integer;
begin
  Result := -1;
  if (FActiveMatchIndex >= 0) and (FActiveMatchIndex <= High(FSearchMatch)) then
  begin
    ParagraphIndex := GetParagraphAtByte(FSearchMatch[FActiveMatchIndex].StartByte);
    Result := FParagraphs[ParagraphIndex].YOffset;
  end;
end;

end.

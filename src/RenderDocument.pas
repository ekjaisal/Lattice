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

unit RenderDocument;

{$mode objfpc}{$H+}

interface

uses
  Classes, Controls, ExtCtrls, Forms, Graphics, LCLIntf, LCLType, LMessages, Menus, SysUtils
  {$IFDEF WINDOWS}, Windows{$ENDIF}, EngineText;

type
  TBracketHoverEvent = procedure(Sender: TObject; const CodeID: String; CodingIndex: Integer) of object;
  TTextContextEvent = procedure(Sender: TObject; const BracketCodingID: String; ClickedCharacterPosition: Integer; P: TPoint) of object;
  TAnchorHoverEvent = procedure(Sender: TObject; const Cluster: TMapTickCluster) of object;
  TZoomPersistEvent = procedure(Sender: TObject; ZoomLevel: Integer) of object;

  TRenderDocument = class(TCustomControl)
  private
    FAutoScrollTimer: TTimer;
    FCaretTimer: TTimer;
    FEngineText: TEngineText;
    FLastHoverCodeID: String;
    FOnAnchorHover: TAnchorHoverEvent;
    FOnBracketHover: TBracketHoverEvent;
    FOnSaveRequest: TNotifyEvent;
    FOnTextContext: TTextContextEvent;
    FOnZoomPersist: TZoomPersistEvent;
    FResizeTimer: TTimer;
    FScrollY: Integer;
    FZoomSaveTimer: TTimer;
    procedure ChangeZoom(Delta: Integer);
    procedure OnAutoScrollTimer(Sender: TObject);
    procedure OnCaretTimer(Sender: TObject);
    procedure OnResizeTimer(Sender: TObject);
    procedure OnZoomSaveTimer(Sender: TObject);
    procedure ResetZoom;
    procedure SetScrollY(Value: Integer);
    procedure WMEraseBkgnd(var Message: TLMEraseBkgnd); message LM_ERASEBKGND;
    procedure WMVScroll(var Message: TLMScroll); message LM_VSCROLL;
  protected
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePosition: TPoint): Boolean; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure UTF8KeyPress(var UTF8Key: TUTF8Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetSelectedText: String;
    function GetTextSlice(StartCharacter, LengthCharacter: Integer): String;
    function HasSelection: Boolean;
    function IsBracketSelection: Boolean;
    function SelectionLength: Integer;
    function SelectionStartCharacter: Integer;
    procedure Clear;
    procedure ClearSelection;
    procedure ScrollToActiveSearchMatch;
    procedure ScrollToChar(AChar: Integer);
    procedure SetText(const AText: string);
    procedure UpdateCoding(const ACoding: TCodingArray);
    procedure UpdateScrollbar;
    property EngineText: TEngineText read FEngineText;
    property OnAnchorHover: TAnchorHoverEvent read FOnAnchorHover write FOnAnchorHover;
    property OnBracketHover: TBracketHoverEvent read FOnBracketHover write FOnBracketHover;
    property OnSaveRequest: TNotifyEvent read FOnSaveRequest write FOnSaveRequest;
    property OnTextContext: TTextContextEvent read FOnTextContext write FOnTextContext;
    property OnZoomPersist: TZoomPersistEvent read FOnZoomPersist write FOnZoomPersist;
    property ScrollY: Integer read FScrollY write SetScrollY;
  end;

implementation

uses
  Clipbrd, Math;

constructor TRenderDocument.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];
  DoubleBuffered := True;
  ShowHint := True;
  FEngineText := TEngineText.Create;
  FScrollY := 0;
  FLastHoverCodeID := '';
  FAutoScrollTimer := TTimer.Create(Self);
  FAutoScrollTimer.Interval := 50;
  FAutoScrollTimer.Enabled := False;
  FAutoScrollTimer.OnTimer := @OnAutoScrollTimer;
  FResizeTimer := TTimer.Create(Self);
  FResizeTimer.Interval := 150;
  FResizeTimer.Enabled := False;
  FResizeTimer.OnTimer := @OnResizeTimer;
  FZoomSaveTimer := TTimer.Create(Self);
  FZoomSaveTimer.Interval := 500;
  FZoomSaveTimer.Enabled := False;
  FZoomSaveTimer.OnTimer := @OnZoomSaveTimer;
  FCaretTimer := TTimer.Create(Self);
  FCaretTimer.Interval := 530;
  FCaretTimer.OnTimer := @OnCaretTimer;
  FCaretTimer.Enabled := True;
end;

destructor TRenderDocument.Destroy;
begin
  if Assigned(FAutoScrollTimer) then
    FAutoScrollTimer.Enabled := False;
  FAutoScrollTimer.Free;
  if Assigned(FResizeTimer) then
    FResizeTimer.Enabled := False;
  FResizeTimer.Free;
  if Assigned(FZoomSaveTimer) then
    FZoomSaveTimer.Enabled := False;
  FZoomSaveTimer.Free;
  FCaretTimer.Enabled := False;
  FCaretTimer.Free;
  FEngineText.Free;
  inherited Destroy;
end;

procedure TRenderDocument.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  {$IFDEF WINDOWS}
  Params.Style := Params.Style or WS_VSCROLL;
  {$ENDIF}
end;

procedure TRenderDocument.WMEraseBkgnd(var Message: TLMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TRenderDocument.UpdateScrollbar;
var
  DocumentHeight, PageHeight: Integer;
  {$IFDEF WINDOWS}
  si: TScrollInfo;
  {$ENDIF}
begin
  DocumentHeight := FEngineText.DocumentHeight;
  PageHeight := ClientHeight;
  {$IFDEF WINDOWS}
  si.cbSize := SizeOf(si);
  si.fMask := SIF_RANGE or SIF_PAGE or SIF_POS or SIF_DISABLENOSCROLL;
  si.nMin := 0;
  si.nMax := DocumentHeight;
  si.nPage := PageHeight;
  si.nPos := FScrollY;
  SetScrollInfo(Handle, SB_VERT, si, True);
  {$ELSE}
  SetScrollbarProp(SB_VERT, srpRange, DocumentHeight);
  SetScrollbarProp(SB_VERT, srpPage, PageHeight);
  SetScrollbarProp(SB_VERT, srpPos, FScrollY);
  {$ENDIF}
end;

procedure TRenderDocument.WMVScroll(var Message: TLMScroll);
var
  {$IFDEF WINDOWS}
  si: TScrollInfo;
  {$ENDIF}
  NewPos: Integer;
begin
  case Message.ScrollCode of
    SB_TOP: SetScrollY(0);
    SB_BOTTOM: SetScrollY(FEngineText.DocumentHeight);
    SB_LINEUP: SetScrollY(FScrollY - 30);
    SB_LINEDOWN: SetScrollY(FScrollY + 30);
    SB_PAGEUP: SetScrollY(FScrollY - ClientHeight);
    SB_PAGEDOWN: SetScrollY(FScrollY + ClientHeight);
    SB_THUMBPOSITION, SB_THUMBTRACK:
      begin
        {$IFDEF WINDOWS}
        si.cbSize := SizeOf(si);
        si.fMask := SIF_TRACKPOS;
        if GetScrollInfo(Handle, SB_VERT, si) then
          NewPos := si.nTrackPos
        else
          NewPos := Message.Pos;
        {$ELSE}
        NewPos := Message.Pos;
        {$ENDIF}
        SetScrollY(NewPos);
      end;
  end;
end;

procedure TRenderDocument.SetScrollY(Value: Integer);
var MaxScroll: Integer;
begin
  MaxScroll := Max(0, FEngineText.DocumentHeight - ClientHeight);
  Value := EnsureRange(Value, 0, MaxScroll);
  if FScrollY <> Value then
  begin
    FScrollY := Value;
    UpdateScrollbar;
    Invalidate;
  end;
end;

procedure TRenderDocument.ScrollToActiveSearchMatch;
var
  TargetY: Integer;
begin
  TargetY := FEngineText.GetActiveMatchY;
  if TargetY >= 0 then
  begin
    if (TargetY < FScrollY) or (TargetY > FScrollY + ClientHeight - 50) then
      SetScrollY(Max(0, TargetY - (ClientHeight div 2)));
  end;
  Invalidate;
end;

procedure TRenderDocument.OnAutoScrollTimer(Sender: TObject);
var
  P: TPoint;
begin
  P := ScreenToClient(Mouse.CursorPos);
  if P.Y < 0 then
    SetScrollY(FScrollY - 25)
  else if P.Y > ClientHeight then
    SetScrollY(FScrollY + 25);
  FEngineText.MouseMove(P.X, P.Y, FScrollY);
  Invalidate;
end;

procedure TRenderDocument.OnResizeTimer(Sender: TObject);
begin
  FResizeTimer.Enabled := False;
  if Assigned(FEngineText) then
  begin
    FEngineText.SetDPI(Font.PixelsPerInch);
    FEngineText.Resize(ClientWidth);
  end;
  UpdateScrollbar;
  Invalidate;
end;

procedure TRenderDocument.Paint;
var
  NewScrollY: Integer;
begin
  if Assigned(FEngineText) and (Width > 30) then
  begin
    NewScrollY := FScrollY;
    FEngineText.Paint(Canvas.Handle, ClientWidth, ClientHeight, NewScrollY);
    if NewScrollY <> FScrollY then
      FScrollY := NewScrollY;
    UpdateScrollbar;
  end
  else
  begin
    Canvas.Brush.Color := clWhite;
    Canvas.FillRect(ClientRect);
  end;
end;

procedure TRenderDocument.Resize;
begin
  inherited Resize;
  if Assigned(FEngineText) then
  begin
    FResizeTimer.Enabled := False;
    FResizeTimer.Enabled := True;
  end;
  UpdateScrollbar;
  Invalidate;
end;

procedure TRenderDocument.SetText(const AText: string);
begin
  FEngineText.SetDPI(Font.PixelsPerInch);
  FEngineText.SetText(AText);
  FScrollY := 0;
  FEngineText.Resize(ClientWidth);
  UpdateScrollbar;
  Invalidate;
end;

procedure TRenderDocument.OnCaretTimer(Sender: TObject);
begin
  if FEngineText.IsEditing then
  begin
    FEngineText.ToggleCaret;
    Invalidate;
  end;
end;

procedure TRenderDocument.UTF8KeyPress(var UTF8Key: TUTF8Char);
begin
  inherited UTF8KeyPress(UTF8Key);
  if FEngineText.IsEditing then
  begin
    if (Length(UTF8Key) > 1) or ((Length(UTF8Key) = 1) and (UTF8Key[1] >= #32)) then
    begin
      if HasSelection then
        FEngineText.ReplaceRange(FEngineText.SelStartByte, FEngineText.SelEndByte, UTF8Key)
      else
        FEngineText.ReplaceRange(FEngineText.GetAbsoluteCaret, FEngineText.GetAbsoluteCaret, UTF8Key);
      ScrollToChar(FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret));
      UpdateScrollbar;
      Invalidate;
      UTF8Key := '';
    end;
  end;
end;

procedure TRenderDocument.UpdateCoding(const ACoding: TCodingArray);
begin
  FEngineText.SetDPI(Font.PixelsPerInch);
  FEngineText.SetCodings(ACoding);
  FEngineText.Resize(ClientWidth);
  UpdateScrollbar;
  Invalidate;
end;

procedure TRenderDocument.ScrollToChar(AChar: Integer);
var
  TargetY: Integer;
begin
  TargetY := FEngineText.GetYForChar(AChar);
  if (TargetY < FScrollY) or (TargetY > FScrollY + ClientHeight - 50) then
    SetScrollY(Max(0, TargetY - (ClientHeight div 2)));
  Invalidate;
end;

procedure TRenderDocument.Clear;
begin
  SetText('');
end;

procedure TRenderDocument.ClearSelection;
begin
  FEngineText.ClearSelection;
  Invalidate;
end;

procedure TRenderDocument.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CodingID: String;
  ClickedChar, TargetStartByte: Integer;
  TargetCluster: TMapTickCluster;
  Pt: TPoint;
  BytePos: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbMiddle) and (ssCtrl in Shift) then
  begin
    ResetZoom;
    Exit;
  end;
  if Button = mbLeft then
  begin
    if FEngineText.ActionAnchorHitTest(X, Y, ClientHeight, TargetCluster, TargetStartByte) then
    begin
      if not FEngineText.IsEditing then
      begin
        if Length(TargetCluster.Items) > 0 then
        begin
          if TargetCluster.Items[0].TickType = mttCode then
          begin
            FEngineText.SetFocusedMemo('');
            FEngineText.SetFocusedCoding(TargetCluster.Items[0].ID);
            FEngineText.SelectCoding(TargetCluster.Items[0].ID);
          end
          else
          begin
            FEngineText.SetFocusedCoding('');
            FEngineText.SetFocusedMemo(TargetCluster.Items[0].ID);
          end;
        end
        else
        begin
          FEngineText.SetFocusedCoding('');
          FEngineText.SetFocusedMemo('');
        end;
      end;
      SetScrollY(Max(0, FEngineText.GetYForByte(TargetStartByte) - 20));
      Invalidate;
      Exit;
    end;
    CodingID := FEngineText.GetBracketAt(X, Y, FScrollY);
    if (CodingID <> '') and not FEngineText.IsEditing then
    begin
      FEngineText.SetFocusedCoding(CodingID);
      FEngineText.SelectCoding(CodingID);
      Invalidate;
    end
    else
    begin
      FEngineText.SetFocusedCoding('');
      FEngineText.SetFocusedMemo('');
      FEngineText.MouseDown(X, Y, FScrollY);
      FEngineText.SetCaretFromXY(X, Y, FScrollY);
      Invalidate;
    end;
  end
  else if Button = mbRight then
  begin
    if not FEngineText.IsEditing and FEngineText.IsOverActionAnchors(X, Y, ClientHeight) then
    begin
      if FEngineText.ActionAnchorHitTest(X, Y, ClientHeight, TargetCluster, TargetStartByte) then
      begin
        ClickedChar := FEngineText.ByteToChar(TargetStartByte);
        if Assigned(FOnTextContext) then
        begin
          Pt.X := X;
          Pt.Y := Y;
          Pt := ClientToScreen(Pt);
          FOnTextContext(Self, '', ClickedChar, Pt);
        end;
      end;
      Exit;
    end;
    CodingID := FEngineText.GetBracketAt(X, Y, FScrollY);
    if FEngineText.IsEditing then CodingID := '';
    if FEngineText.IsEditing then
    begin
      BytePos := FEngineText.ByteFromXY(X, Y + FScrollY);
      if not (FEngineText.HasSelection and 
             (BytePos >= Min(FEngineText.SelStartByte, FEngineText.SelEndByte)) and 
             (BytePos <= Max(FEngineText.SelStartByte, FEngineText.SelEndByte))) then
      begin
        FEngineText.ClearSelection;
        FEngineText.SetCaretFromXY(X, Y, FScrollY);
        Invalidate;
      end;
    end;
    ClickedChar := FEngineText.GetCharAt(X, Y, FScrollY);
    if (CodingID <> '') or (ClickedChar >= 0) or HasSelection then
    begin
      if CodingID <> '' then FEngineText.SetFocusedCoding(CodingID);
      Invalidate;
      if Assigned(FOnTextContext) then
      begin
        Pt.X := X;
        Pt.Y := Y;
        Pt := ClientToScreen(Pt);
        FOnTextContext(Self, CodingID, ClickedChar, Pt);
      end;
    end;
  end;
end;

procedure TRenderDocument.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  CodingID: String;
  TargetCluster: TMapTickCluster;
  TargetStartByte: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if Assigned(FEngineText) then
  begin
    if FEngineText.UpdateAnchorHover(X, Y, ClientHeight) then
    begin
      Invalidate;
      if FEngineText.ActionAnchorHitTest(X, Y, ClientHeight, TargetCluster, TargetStartByte) then
      begin
        if Assigned(FOnAnchorHover) then FOnAnchorHover(Self, TargetCluster);
      end
      else
      begin
        if Assigned(FOnAnchorHover) then FOnAnchorHover(Self, Default(TMapTickCluster));
      end;
    end;
    if FEngineText.IsOverActionAnchors(X, Y, ClientHeight) then
    begin
      if Hint <> 'Action Anchor' then Hint := 'Action Anchor';
    end
    else if Hint <> '' then Hint := '';
  end;
  if ssLeft in Shift then
  begin
    FEngineText.MouseMove(X, Y, FScrollY);
    FAutoScrollTimer.Enabled := (Y < 0) or (Y > ClientHeight);
    Invalidate;
  end
  else
  begin
    CodingID := FEngineText.GetBracketAt(X, Y, FScrollY);
    if CodingID <> '' then
    begin
      Cursor := crHandPoint;
      if (CodingID <> FLastHoverCodeID) then
      begin
        FLastHoverCodeID := CodingID;
        if Assigned(FOnBracketHover) then FOnBracketHover(Self, CodingID, -1);
      end;
    end
    else
    begin
      if FEngineText.GetCharAt(X, Y, FScrollY) >= 0 then
        Cursor := crIBeam
      else
        Cursor := crDefault;
      if FLastHoverCodeID <> '' then
      begin
        FLastHoverCodeID := '';
        if Assigned(FOnBracketHover) then FOnBracketHover(Self, '', -1);
      end;
    end;
  end;
end;

procedure TRenderDocument.MouseLeave;
begin
  inherited MouseLeave;
  if FLastHoverCodeID <> '' then
  begin
    FLastHoverCodeID := '';
    if Assigned(FOnBracketHover) then FOnBracketHover(Self, '', -1);
  end;
  if FEngineText.UpdateAnchorHover(-1000, -1000, ClientHeight) then
  begin
    Invalidate;
    if Assigned(FOnAnchorHover) then FOnAnchorHover(Self, Default(TMapTickCluster));
  end;
end;

procedure TRenderDocument.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  FAutoScrollTimer.Enabled := False;
  FEngineText.MouseUp;
  Invalidate;
end;

function TRenderDocument.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePosition: TPoint): Boolean;
begin
  if ssCtrl in Shift then
  begin
    if WheelDelta > 0 then ChangeZoom(1)
    else ChangeZoom(-1);
    Result := True;
  end
  else
  begin
    SetScrollY(FScrollY - WheelDelta);
    Result := True;
  end;
end;

procedure TRenderDocument.OnZoomSaveTimer(Sender: TObject);
begin
  FZoomSaveTimer.Enabled := False;
  if Assigned(FOnZoomPersist) then FOnZoomPersist(Self, FEngineText.ZoomOffset);
end;

procedure TRenderDocument.ResetZoom;
var
  TopByte: Integer;
begin
  if FEngineText.ZoomOffset <> 0 then
  begin
    TopByte := FEngineText.GetTopVisibleByte(FScrollY);
    FEngineText.ZoomOffset := 0;
    SetScrollY(FEngineText.GetYForByte(TopByte));
    Invalidate;
    FZoomSaveTimer.Enabled := False;
    FZoomSaveTimer.Enabled := True;
  end;
end;

procedure TRenderDocument.ChangeZoom(Delta: Integer);
var
  TopByte, NewZoom: Integer;
begin
  NewZoom := FEngineText.ZoomOffset + Delta;
  NewZoom := EnsureRange(NewZoom, -6, 24);
  if NewZoom <> FEngineText.ZoomOffset then
  begin
    TopByte := FEngineText.GetTopVisibleByte(FScrollY);
    FEngineText.ZoomOffset := NewZoom;
    SetScrollY(FEngineText.GetYForByte(TopByte));
    Invalidate;
    FZoomSaveTimer.Enabled := False;
    FZoomSaveTimer.Enabled := True;
  end;
end;

function TRenderDocument.HasSelection: Boolean;
begin
  Result := FEngineText.HasSelection;
end;

function TRenderDocument.IsBracketSelection: Boolean;
begin
  Result := FEngineText.IsBracketSelection;
end;

function TRenderDocument.SelectionStartCharacter: Integer;
begin
  Result := FEngineText.SelectionStartCharacter;
end;

function TRenderDocument.SelectionLength: Integer;
begin
  Result := FEngineText.SelectionLength;
end;

function TRenderDocument.GetTextSlice(StartCharacter, LengthCharacter: Integer): String;
begin
  Result := FEngineText.GetTextSlice(StartCharacter, LengthCharacter);
end;

procedure TRenderDocument.MouseEnter;
begin
  inherited MouseEnter;
  if CanFocus then SetFocus;
end;

function TRenderDocument.GetSelectedText: String;
begin
  Result := FEngineText.GetSelectedText;
end;

procedure TRenderDocument.KeyDown(var Key: Word; Shift: TShiftState);
var
  CharIdx: Integer;
begin
  inherited KeyDown(Key, Shift);
  if (ssCtrl in Shift) and ((Key = VK_0) or (Key = VK_NUMPAD0)) then
  begin
    ResetZoom;
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = VK_S) then
  begin
    if FEngineText.IsEditing then
    begin
      if Assigned(FOnSaveRequest) then FOnSaveRequest(Self);
      Key := 0;
    end;
  end
  else if (ssCtrl in Shift) and ((Key = VK_OEM_PLUS) or (Key = VK_ADD)) then
  begin
    ChangeZoom(1);
    Key := 0;
  end
  else if (ssCtrl in Shift) and ((Key = VK_OEM_MINUS) or (Key = VK_SUBTRACT)) then
  begin
    ChangeZoom(-1);
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = VK_C) then
  begin
    if HasSelection then
      Clipbrd.Clipboard.AsText := GetSelectedText;
    Key := 0;
  end
  else if (ssCtrl in Shift) and (Key = VK_Z) then
  begin
    if FEngineText.IsEditing then
    begin
      FEngineText.Undo;
      ScrollToChar(FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret));
      UpdateScrollbar;
      Invalidate;
      Key := 0;
    end;
  end
  else if (ssCtrl in Shift) and (Key = VK_Y) then
  begin
    if FEngineText.IsEditing then
    begin
      FEngineText.Redo;
      ScrollToChar(FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret));
      UpdateScrollbar;
      Invalidate;
      Key := 0;
    end;
  end
  else if (ssCtrl in Shift) and (Key = VK_V) then
  begin
    if FEngineText.IsEditing then
    begin
      if HasSelection then
        FEngineText.ReplaceRange(FEngineText.SelStartByte, FEngineText.SelEndByte, Clipbrd.Clipboard.AsText)
      else
        FEngineText.ReplaceRange(FEngineText.GetAbsoluteCaret, FEngineText.GetAbsoluteCaret, Clipbrd.Clipboard.AsText);
      ScrollToChar(FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret));
      UpdateScrollbar;
      Invalidate;
      Key := 0;
    end;
  end
  else if (ssCtrl in Shift) and (Key = VK_X) then
  begin
    if FEngineText.IsEditing and HasSelection then
    begin
      Clipbrd.Clipboard.AsText := GetSelectedText;
      FEngineText.ReplaceRange(FEngineText.SelStartByte, FEngineText.SelEndByte, '');
      UpdateScrollbar;
      Invalidate;
      Key := 0;
    end;
  end
  else if Key = VK_BACK then
  begin
    if FEngineText.IsEditing then
    begin
      if HasSelection then
        FEngineText.ReplaceRange(FEngineText.SelStartByte, FEngineText.SelEndByte, '')
      else
      begin
        CharIdx := FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret);
        FEngineText.ReplaceRange(FEngineText.CharToByte(Max(0, CharIdx - 1)), FEngineText.GetAbsoluteCaret, '');
      end;
      ScrollToChar(FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret));
      UpdateScrollbar;
      Invalidate;
      Key := 0;
    end;
  end
  else if Key = VK_DELETE then
  begin
    if FEngineText.IsEditing then
    begin
      if HasSelection then
        FEngineText.ReplaceRange(FEngineText.SelStartByte, FEngineText.SelEndByte, '')
      else
      begin
        CharIdx := FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret);
        FEngineText.ReplaceRange(FEngineText.GetAbsoluteCaret, FEngineText.CharToByte(CharIdx + 1), '');
      end;
      UpdateScrollbar;
      Invalidate;
      Key := 0;
    end;
  end
  else if Key = VK_RETURN then
  begin
    if FEngineText.IsEditing then
    begin
      if HasSelection then
        FEngineText.ReplaceRange(FEngineText.SelStartByte, FEngineText.SelEndByte, #10)
      else
        FEngineText.ReplaceRange(FEngineText.GetAbsoluteCaret, FEngineText.GetAbsoluteCaret, #10);
      ScrollToChar(FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret));
      UpdateScrollbar;
      Invalidate;
      Key := 0;
    end;
  end
  else if Key = VK_LEFT then
  begin
    if FEngineText.IsEditing then
    begin
      FEngineText.SetCaretToByte(Max(0, FEngineText.GetAbsoluteCaret - 1));
      FEngineText.ClearSelection;
      Invalidate;
      Key := 0;
    end;
  end
  else if Key = VK_RIGHT then
  begin
    if FEngineText.IsEditing then
    begin
      FEngineText.SetCaretToByte(Min(FEngineText.GetDocumentLengthBytes, FEngineText.GetAbsoluteCaret + 1));
      FEngineText.ClearSelection;
      Invalidate;
      Key := 0;
    end;
  end
  else if Key = VK_UP then
  begin
    if FEngineText.IsEditing then
    begin
      FEngineText.MoveCaretVertical(-1, FScrollY);
      FEngineText.ClearSelection;
      ScrollToChar(FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret));
    end
    else
      SetScrollY(FScrollY - 40);
    Invalidate;
    Key := 0;
  end
  else if Key = VK_DOWN then
  begin
    if FEngineText.IsEditing then
    begin
      FEngineText.MoveCaretVertical(1, FScrollY);
      FEngineText.ClearSelection;
      ScrollToChar(FEngineText.ByteToChar(FEngineText.GetAbsoluteCaret));
    end
    else
      SetScrollY(FScrollY + 40);
    Invalidate;
    Key := 0;
  end
  else if Key = VK_PRIOR then
  begin
    SetScrollY(FScrollY - ClientHeight + 40);
    Key := 0;
  end
  else if Key = VK_NEXT then
  begin
    SetScrollY(FScrollY + ClientHeight - 40);
    Key := 0;
  end;
end;

end.
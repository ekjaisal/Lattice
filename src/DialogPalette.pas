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

unit DialogPalette;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Controls, Dialogs, ExtCtrls, Forms, Graphics, Grids, StdCtrls;

type
  { TfrmDialogPalette }
  TfrmDialogPalette = class(TForm)
    btnMore: TButton;
    dlgPickColor: TColorDialog;
    grdPalette: TDrawGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure grdPaletteDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; {%H-}aState: TGridDrawState);
    procedure grdPaletteMouseDown(Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; X, Y: Integer);
    procedure btnMoreClick(Sender: TObject);
  private
    FSelectedColor: TColor;
  public
    class function Execute(out AColor: TColor): Boolean;
  end;

implementation

uses
  AppFont, AppIdentity;

{$R *.lfm}

procedure TfrmDialogPalette.FormCreate(Sender: TObject);
begin
  ApplyAppFont(Self);
  FSelectedColor := clNone;
end;

procedure TfrmDialogPalette.FormDeactivate(Sender: TObject);
begin
  Close;
end;

procedure TfrmDialogPalette.grdPaletteDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; {%H-}aState: TGridDrawState);
begin
  grdPalette.Canvas.Brush.Color := APP_PALETTE[aRow * 5 + aCol];
  grdPalette.Canvas.FillRect(aRect);
end;

procedure TfrmDialogPalette.grdPaletteMouseDown(Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; X, Y: Integer);
var
  aCol, aRow: Integer;
begin
  grdPalette.MouseToCell(X, Y, aCol, aRow);
  if (aCol >= 0) and (aRow >= 0) then
  begin
    FSelectedColor := APP_PALETTE[aRow * 5 + aCol];
    ModalResult := mrOk;
  end;
end;

procedure TfrmDialogPalette.btnMoreClick(Sender: TObject);
begin
  if dlgPickColor.Execute then
  begin
    FSelectedColor := dlgPickColor.Color;
    ModalResult := mrOk;
  end;
end;

class function TfrmDialogPalette.Execute(out AColor: TColor): Boolean;
var
  frm: TfrmDialogPalette;
begin
  frm := TfrmDialogPalette.Create(nil);
  try
    if frm.ShowModal = mrOk then
    begin
      AColor := frm.FSelectedColor;
      Result := True;
    end
    else
      Result := False;
  finally
    frm.Free;
  end;
end;

end.

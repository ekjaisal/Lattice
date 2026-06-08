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

unit DialogStartup;

{$mode ObjFPC}{$H+}

interface

uses
  Controls, ExtCtrls, Forms, Graphics, StdCtrls, AppFont, AppIdentity, BridgeLibrary;

type

  { TfrmDialogStartUp }
  TfrmDialogStartUp = class(TForm)
    btnCreateNew: TButton;
    btnOpenExisting: TButton;
    lblAppName: TLabel;
    lblVersion: TLabel;
    pnlAction: TPanel;
    pnlWelcome: TPanel;
    pbxLogo: TPaintBox;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pbxLogoPaint(Sender: TObject);
  private
    procedure ApplyLayout;
  public
  end;

var
  frmDialogStartUp: TfrmDialogStartUp;

implementation

{$R *.lfm}

procedure TfrmDialogStartUp.FormCreate(Sender: TObject);
begin
  ApplyAppFont(Self);
  Caption := APP_NAME;
  lblVersion.Caption := 'Version ' + APP_VERSION;
end;

procedure TfrmDialogStartUp.FormShow(Sender: TObject);
begin
  ApplyLayout;
end;

procedure TfrmDialogStartUp.ApplyLayout;
begin
  btnCreateNew.ModalResult := mrYes;
  btnOpenExisting.ModalResult := mrNo;
end;

procedure TfrmDialogStartUp.pbxLogoPaint(Sender: TObject);
var
  surface: Pcairo_surface_t;
  cr: Pcairo_t;
  LogoRatio, CanvasRatio: Double;
  DrawW, DrawH, DrawX, DrawY: Double;
  AvailableW, AvailableH: Integer;
const
  LOGO_W = 3515.0;
  LOGO_H = 2999.0;
  PADDING = 40; 
begin
  if (pbxLogo.Width <= 0) or (pbxLogo.Height <= 0) then Exit;
  surface := cairo_win32_surface_create(pbxLogo.Canvas.Handle);
  cr := cairo_create(surface);
  try
    cairo_set_source_rgb(cr, 1, 1, 1);
    cairo_paint(cr);
    AvailableW := pbxLogo.Width - (PADDING * 2);
    AvailableH := pbxLogo.Height - (PADDING * 2);
    if (AvailableW > 0) and (AvailableH > 0) then
    begin
      LogoRatio := LOGO_W / LOGO_H;
      CanvasRatio := AvailableW / AvailableH;
      if CanvasRatio > LogoRatio then
      begin
        DrawH := AvailableH;
        DrawW := DrawH * LogoRatio;
      end
      else
      begin
        DrawW := AvailableW;
        DrawH := DrawW / LogoRatio;
      end;
      DrawX := PADDING + (AvailableW - DrawW) / 2;
      DrawY := PADDING + ((AvailableH - DrawH) / 2) - (DrawH * 0.08);
      RenderAppLogo(cr, DrawX, DrawY, DrawH);
    end;
  finally
    cairo_destroy(cr);
    cairo_surface_destroy(surface);
  end;
end;

end.

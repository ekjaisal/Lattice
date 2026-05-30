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

unit DialogAbout;

{$mode ObjFPC}{$H+}

interface

uses
  Buttons, Classes, ComCtrls, Controls, Dialogs, ExtCtrls, Forms, Graphics, LCLIntf,
  LCLType, Menus, StdCtrls, SysUtils {$IFDEF WINDOWS}, Windows{$ENDIF}, BridgeLibrary;

type
  TfrmDialogAbout = class(TForm)
    btnClose: TButton;
    btnCopyright: TSpeedButton;
    btnRepository: TSpeedButton;
    btnSponsor: TSpeedButton;
    btnWebsite: TSpeedButton;
    ilDialogAboutIcon: TImageList;
    imgLogo: TPaintBox;
    lblAppName: TLabel;
    lblTagline: TLabel;
    lblVersion: TLabel;
    memLicense: TMemo;
    memThirdParty: TMemo;
    memUserGuide: TMemo;
    mniDialogAboutMemoCopy: TMenuItem;
    mniDialogAboutMemoSelectAll: TMenuItem;
    pcAbout: TPageControl;
    pmnDialogAboutMemo: TPopupMenu;
    pnlGuideBackground: TPanel;
    pnlIdentity: TPanel;
    pnlInfoBackground: TPanel;
    pnlLicenseBackground: TPanel;
    pnlNameVersionTag: TPanel;
    pnlThirdPartyBackground: TPanel;
    tsInfo: TTabSheet;
    tsLicense: TTabSheet;
    tsThirdParty: TTabSheet;
    tsUserGuide: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure LinkClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure imgLogoPaint(Sender: TObject);
    procedure memCaretHide(Sender: TObject);
    procedure mniDialogAboutMemoCopyClick(Sender: TObject);
    procedure mniDialogAboutMemoSelectAllClick(Sender: TObject);
    procedure pmnDialogAboutMemoPopup(Sender: TObject);
  private
    procedure LoadResourceText(const ResName: String; TargetMemo: TMemo);
  public
    class procedure Execute(ATabIndex: Integer = 0);
  end;

implementation

uses
  AppFont, AppIdentity;

{$R *.lfm}

var
  FAboutInstance: TfrmDialogAbout = nil;

procedure TfrmDialogAbout.FormCreate(Sender: TObject);
begin
  ApplyAppFont(Self);
  lblAppName.Caption := APP_NAME;
  lblVersion.Caption := 'Version ' + APP_VERSION;
  lblTagline.Caption := APP_TAGLINE;
  LoadResourceText('USERGUIDE', memUserGuide);
  LoadResourceText('LICENSE', memLicense);
  LoadResourceText('NOTICE', memThirdParty);
end;

procedure TfrmDialogAbout.LoadResourceText(const ResName: String; TargetMemo: TMemo);
var
  rs: TResourceStream;
begin
  try
    rs := TResourceStream.Create(HInstance, ResName, LCLType.RT_RCDATA);
    try
      TargetMemo.Lines.LoadFromStream(rs);
    finally
      rs.Free;
    end;
  except
    TargetMemo.Text := 'Resource not found: ' + ResName;
  end;
end;

procedure TfrmDialogAbout.imgLogoPaint(Sender: TObject);
var
  surface: Pcairo_surface_t;
  cr: Pcairo_t;
begin
  if (imgLogo.Width <= 0) or (imgLogo.Height <= 0) then Exit;
  imgLogo.Canvas.Brush.Color := clWindow;
  imgLogo.Canvas.FillRect(imgLogo.ClientRect);
  surface := cairo_win32_surface_create(imgLogo.Canvas.Handle);
  cr := cairo_create(surface);
  try
    RenderAppLogo(cr, 0, 0, imgLogo.Height);
  finally
    cairo_destroy(cr);
    cairo_surface_destroy(surface);
  end;
end;

procedure TfrmDialogAbout.LinkClick(Sender: TObject);
begin
  if Sender = btnCopyright then OpenURL(DEV_URL)
  else if Sender = btnWebsite then OpenURL(APP_URL)
  else if Sender = btnRepository then OpenURL(APP_REPOSITORY)
  else if Sender = btnSponsor then OpenURL(DEV_SPONSOR);
end;

procedure TfrmDialogAbout.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmDialogAbout.memCaretHide(Sender: TObject);
begin
  HideCaret(TMemo(Sender).Handle);
end;

procedure TfrmDialogAbout.pmnDialogAboutMemoPopup(Sender: TObject);
var
  TargetMemo: TMemo;
begin
  if (pmnDialogAboutMemo.PopupComponent is TMemo) then
  begin
    TargetMemo := TMemo(pmnDialogAboutMemo.PopupComponent);
    mniDialogAboutMemoCopy.Enabled := TargetMemo.SelLength > 0;
    mniDialogAboutMemoSelectAll.Enabled := Length(TargetMemo.Text) > 0;
  end;
end;

procedure TfrmDialogAbout.mniDialogAboutMemoCopyClick(Sender: TObject);
var
  TargetMemo: TMemo;
begin
  if (pmnDialogAboutMemo.PopupComponent is TMemo) then
  begin
    TargetMemo := TMemo(pmnDialogAboutMemo.PopupComponent);
    if TargetMemo.CanFocus then TargetMemo.SetFocus;
    TargetMemo.CopyToClipboard;
  end;
end;

procedure TfrmDialogAbout.mniDialogAboutMemoSelectAllClick(Sender: TObject);
var
  TargetMemo: TMemo;
begin
  if (pmnDialogAboutMemo.PopupComponent is TMemo) then
  begin
    TargetMemo := TMemo(pmnDialogAboutMemo.PopupComponent);
    if TargetMemo.CanFocus then TargetMemo.SetFocus;
    TargetMemo.SelectAll;
  end;
end;

class procedure TfrmDialogAbout.Execute(ATabIndex: Integer = 0);
begin
  if Assigned(FAboutInstance) then
  begin
    if (ATabIndex >= 0) and (ATabIndex < FAboutInstance.pcAbout.PageCount) then
      FAboutInstance.pcAbout.PageIndex := ATabIndex;
    FAboutInstance.BringToFront;
    {$IFDEF WINDOWS}
    SetForegroundWindow(FAboutInstance.Handle);
    {$ENDIF}
    Exit;
  end;
  FAboutInstance := TfrmDialogAbout.Create(nil);
  try
    if (ATabIndex >= 0) and (ATabIndex < FAboutInstance.pcAbout.PageCount) then
      FAboutInstance.pcAbout.PageIndex := ATabIndex;
    FAboutInstance.ActiveControl := FAboutInstance.btnClose;
    FAboutInstance.ShowModal;
  finally
    FAboutInstance.Free;
    FAboutInstance := nil;
  end;
end;

end.
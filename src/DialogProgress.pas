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

unit DialogProgress;

{$mode ObjFPC}{$H+}

interface

uses
  ComCtrls, ExtCtrls, Forms, StdCtrls;

type

  { TfrmDialogProgress }
  TfrmDialogProgress = class(TForm)
    lblStatus: TLabel;
    lblTitle: TLabel;
    pbMarquee: TProgressBar;
    pnlProgress: TPanel;
  public
    class procedure Prepare(const ATitle, AStatus: String);
    class procedure UpdateStatus(const AStatus: String);
  end;

var
  frmDialogProgress: TfrmDialogProgress;

implementation

{$R *.lfm}

class procedure TfrmDialogProgress.Prepare(const ATitle, AStatus: String);
begin
  if not Assigned(frmDialogProgress) then
    Application.CreateForm(TfrmDialogProgress, frmDialogProgress);
  frmDialogProgress.lblTitle.Caption := ATitle;
  frmDialogProgress.lblStatus.Caption := AStatus;
end;

class procedure TfrmDialogProgress.UpdateStatus(const AStatus: String);
begin
  if Assigned(frmDialogProgress) then
  begin
    frmDialogProgress.lblStatus.Caption := AStatus;
    frmDialogProgress.Update;
  end;
end;

end.

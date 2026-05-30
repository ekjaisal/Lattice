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

unit ServiceThread;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, sqldb, sqlite3conn;

type
  TBackgroundWorker = class(TThread)
  private
    FDBPath: String;
    FErrorMessage: String;
    FSuccess: Boolean;
  protected
    FConnection: TSQLite3Connection;
    FTransaction: TSQLTransaction;
    procedure Execute; override;
    procedure DoHeavyLifting; virtual; abstract;
    procedure CloseProgressDialog;
    procedure SyncUpdateStatus(const AStatus: String);
  public
    constructor Create(const ADBPath: String);
    property ErrorMessage: String read FErrorMessage;
    property Success: Boolean read FSuccess;
  end;

implementation

uses
  Controls, DialogProgress, ServiceDatabase;

constructor TBackgroundWorker.Create(const ADBPath: String);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FDBPath := ADBPath;
  FSuccess := False;
  FErrorMessage := '';
end;

procedure TBackgroundWorker.Execute;
begin
  FConnection := TSQLite3Connection.Create(nil);
  FTransaction := TSQLTransaction.Create(nil);
  try
    FConnection.Transaction := FTransaction;
    FConnection.DatabaseName := FDBPath;
    FConnection.Open;
    try
      DoHeavyLifting;
      FSuccess := True;
    except
      on E: Exception do
      begin
        FSuccess := False;
        FErrorMessage := E.Message;
      end;
    end;
  finally
    if FConnection.Connected then FConnection.Close;
    FTransaction.Free;
    FConnection.Free;
    Synchronize(@CloseProgressDialog);
  end;
end;

procedure TBackgroundWorker.CloseProgressDialog;
begin
  if Assigned(frmDialogProgress) and frmDialogProgress.Visible then
    frmDialogProgress.ModalResult := mrOk;
end;

procedure TBackgroundWorker.SyncUpdateStatus(const AStatus: String);
begin
  TfrmDialogProgress.UpdateStatus(AStatus);
end;

end.
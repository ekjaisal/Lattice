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

unit ServiceMemo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, SQLite3Conn;

type
  TServiceMemo = class
  public
    class function Execute(AConnection: TSQLite3Connection; const ATargetType: String; const ATargetID: String; const AReferenceName: String): Boolean;
  end;

implementation

uses
  Controls, Dialogs, Forms, StrUtils, DialogEditor, MonoLexID;

class function TServiceMemo.Execute(AConnection: TSQLite3Connection; const ATargetType: String; const ATargetID: String; const AReferenceName: String): Boolean;
var
  MemoTitle, MemoContent, NewLexID: String;
  IsExisting, IsAnalytical, DelReq: Boolean;
  Query: TSQLQuery;
begin
  Result := False;
  if not Assigned(AConnection) or not AConnection.Connected then Exit;
  IsExisting := False;
  MemoContent := '';
  IsAnalytical := SameText(ATargetType, 'Analytical');
  Query := TSQLQuery.Create(nil);
  try
    Query.Database := AConnection;
    Query.Transaction := AConnection.Transaction;
    if (ATargetID <> '') or (not IsAnalytical) then
    begin
      if IsAnalytical then
        Query.SQL.Text := 'SELECT content, title FROM memos WHERE id = :tid'
      else
        Query.SQL.Text := 'SELECT content, title FROM memos WHERE memo_type = :tt AND reference = :tid';
      Query.Params.ParamByName('tid').AsString := ATargetID;
      if not IsAnalytical then Query.Params.ParamByName('tt').AsString := ATargetType;
      Query.Open;
      if not Query.EOF then
      begin
        MemoContent := Query.FieldByName('content').AsString;
        MemoTitle := Query.FieldByName('title').AsString;
        IsExisting := True;
      end;
      Query.Close;
    end;
    if not IsExisting then
    begin
      case IndexStr(ATargetType, ['Project', 'Document', 'Code', 'Segment', 'Analytical']) of
        0: MemoTitle := 'Project-wide Memo';
        1: MemoTitle := 'Document Memo · ' + AReferenceName;
        2: MemoTitle := 'Code Memo · ' + AReferenceName;
        3: MemoTitle := 'Segment Memo · ' + AReferenceName;
        4: begin
             NewLexID := NewMonoLexID;
             MemoTitle := 'Analytical Memo · ' + Copy(StringReplace(NewLexID, '-', '', [rfReplaceAll]), 1, 16);
           end;
      else MemoTitle := 'New Memo';
      end;
    end;
    frmDialogEditor := TfrmDialogEditor.Create(nil);
    try
      if frmDialogEditor.ExecuteTextEditor('Memo Editor', MemoTitle, MemoContent, IsExisting, DelReq) then
      begin
        if not AConnection.Transaction.Active then AConnection.Transaction.StartTransaction;
        try
          if DelReq then
          begin
            if IsAnalytical then
              Query.SQL.Text := 'DELETE FROM memos WHERE id = :tid'
            else
              Query.SQL.Text := 'DELETE FROM memos WHERE memo_type = :tt AND reference = :tid';
            Query.Params.ParamByName('tid').AsString := ATargetID;
            if not IsAnalytical then Query.Params.ParamByName('tt').AsString := ATargetType;
            Query.ExecSQL;
          end
          else
          begin
            if not IsExisting then
            begin
              Query.SQL.Text := 'INSERT INTO memos (id, memo_type, reference, title, content) VALUES (:g, :tt, :tid, :title, :content)';
              if IsAnalytical then Query.Params.ParamByName('g').AsString := NewLexID
              else Query.Params.ParamByName('g').AsString := NewMonoLexID;
              Query.Params.ParamByName('tt').AsString := ATargetType;
              if ATargetID = '' then
                Query.Params.ParamByName('tid').AsString := ''
              else
                Query.Params.ParamByName('tid').AsString := ATargetID;
              Query.Params.ParamByName('title').AsString := MemoTitle;
              Query.Params.ParamByName('content').AsString := MemoContent;
            end
            else
            begin
              if IsAnalytical then
              begin
                Query.SQL.Text := 'UPDATE memos SET content = :content WHERE id = :tid';
                Query.Params.ParamByName('tid').AsString := ATargetID;
                Query.Params.ParamByName('content').AsString := MemoContent;
              end
              else
              begin
                Query.SQL.Text := 'UPDATE memos SET title = :title, content = :content WHERE memo_type = :tt AND reference = :tid';
                Query.Params.ParamByName('tt').AsString := ATargetType;
                Query.Params.ParamByName('tid').AsString := ATargetID;
                Query.Params.ParamByName('title').AsString := MemoTitle;
                Query.Params.ParamByName('content').AsString := MemoContent;
              end;
            end;
            Query.ExecSQL;
          end;
          AConnection.Transaction.Commit;
          Result := True;
        except
          on E: Exception do 
          begin
            if AConnection.Transaction.Active then AConnection.Transaction.Rollback;
            MessageDlg('Database Error', 'Operation failed: ' + E.Message, mtError, [mbOK], 0);
          end;
        end;
      end;
    finally 
      frmDialogEditor.Free; 
    end;
  finally
    Query.Free;
  end;
end;

end.
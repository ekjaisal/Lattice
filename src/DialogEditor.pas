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

unit DialogEditor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Controls, Dialogs, ExtCtrls, Forms, Graphics, StdCtrls, SysUtils;

type
  TEditorMode = (emReport, emText, emTree);

  { TfrmDialogEditor}
  TfrmDialogEditor = class(TForm)
    btnCancel: TButton;
    btnDelete: TButton;
    btnOK: TButton;
    edtTitle: TEdit;
    lblSubtitle: TLabel;
    lblTitle: TLabel;
    memContent: TMemo;
    pnlActions: TPanel;
    pnlClient: TPanel;
    pnlTop: TPanel;
    procedure btnDeleteClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FMode: TEditorMode;
    FDeleteRequested: Boolean;
    FOriginalTitle: String;
    procedure SetupUI;
    procedure UpdateTitleEllipsis;
  public
    function ExecuteReport(const ATitle, ASummary: String; AList: TStringArray): Boolean;
    function ExecuteTextEditor(const ATitle, APrompt: String; var AContent: String; CanDelete: Boolean; out DeleteRequested: Boolean): Boolean;
    function ExecuteTreeEditor(const ATitle: String; var AName, ADescription: String): Boolean;
  end;

var
  frmDialogEditor: TfrmDialogEditor;

implementation

uses
  LazUTF8, AppFont;

{$R *.lfm}

procedure TfrmDialogEditor.SetupUI;
begin
  lblTitle.Font.Style := [fsBold];
  case FMode of
    emReport: begin
      lblTitle.Font.Style := [];
      edtTitle.Visible := False;
      lblSubtitle.Visible := False;
      memContent.ReadOnly := True;
      btnCancel.Visible := False;
      btnDelete.Visible := False;
      btnOK.Caption := 'Close';
    end;
    emText: begin
      edtTitle.Visible := False;
      lblSubtitle.Visible := False;
      memContent.ReadOnly := False;
      btnCancel.Visible := True;
      btnOK.Caption := 'Save';
    end;
    emTree: begin
      lblTitle.Caption := 'Code Name';
      edtTitle.Visible := True;
      lblSubtitle.Visible := True;
      memContent.ReadOnly := False;
      btnCancel.Visible := True;
      btnDelete.Visible := False;
      btnOK.Caption := 'Save';
    end;
  end;
end;

procedure TfrmDialogEditor.UpdateTitleEllipsis;
const
  Ellipsis = '...';
var
  CalculatedText: String;
  MaxWidth: Integer;
begin
  if (FMode = emTree) or (FOriginalTitle = '') then Exit;
  lblTitle.Canvas.Font.Assign(lblTitle.Font);
  MaxWidth := lblTitle.ClientWidth - 10;
  CalculatedText := FOriginalTitle;
  if lblTitle.Canvas.TextWidth(CalculatedText) > MaxWidth then
  begin
    while (CalculatedText <> '') and
          (lblTitle.Canvas.TextWidth(CalculatedText + Ellipsis) > MaxWidth) do
    begin
      UTF8Delete(CalculatedText, UTF8Length(CalculatedText), 1);
    end;
    lblTitle.Caption := CalculatedText + Ellipsis;
  end
  else
  begin
    lblTitle.Caption := FOriginalTitle;
  end;
end;

procedure TfrmDialogEditor.FormShow(Sender: TObject);
begin
  ApplyAppFont(Self);
  SetupUI;
  UpdateTitleEllipsis;
  if (FMode = emTree) and edtTitle.CanFocus then edtTitle.SetFocus
  else if memContent.CanFocus then memContent.SetFocus;
end;

procedure TfrmDialogEditor.FormResize(Sender: TObject);
begin
  UpdateTitleEllipsis;
end;

procedure TfrmDialogEditor.btnOKClick(Sender: TObject);
begin
  if (FMode = emTree) and (Trim(edtTitle.Text) = '') then
  begin
    MessageDlg('Validation Error', 'The name cannot be empty.', mtWarning, [mbOK], 0);
    edtTitle.SetFocus;
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TfrmDialogEditor.btnDeleteClick(Sender: TObject);
begin
  if MessageDlg('Delete Item', 'Are you sure you want to permanently delete this item?', mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    FDeleteRequested := True;
    ModalResult := mrOk;
  end;
end;

function TfrmDialogEditor.ExecuteReport(const ATitle, ASummary: String; AList: TStringArray): Boolean;
var i: Integer;
begin
  FMode := emReport;
  Caption := ATitle;
  FOriginalTitle := ASummary;
  memContent.Lines.Clear;
  for i := Low(AList) to High(AList) do memContent.Lines.Add(AList[i]);
  Result := (ShowModal = mrOk);
end;

function TfrmDialogEditor.ExecuteTextEditor(const ATitle, APrompt: String; var AContent: String; CanDelete: Boolean; out DeleteRequested: Boolean): Boolean;
begin
  FMode := emText;
  FDeleteRequested := False;
  Caption := ATitle;
  FOriginalTitle := APrompt;
  memContent.Text := AContent;
  btnDelete.Visible := CanDelete;
  Result := (ShowModal = mrOk);
  if Result then
  begin
    AContent := memContent.Text;
    DeleteRequested := FDeleteRequested;
  end
  else
    DeleteRequested := False;
end;

function TfrmDialogEditor.ExecuteTreeEditor(const ATitle: String; var AName, ADescription: String): Boolean;
begin
  FMode := emTree;
  Caption := ATitle;
  edtTitle.Text := AName;
  memContent.Text := ADescription;
  Result := (ShowModal = mrOk);
  if Result then
  begin
    AName := Trim(edtTitle.Text);
    ADescription := Trim(memContent.Text);
  end;
end;

end.
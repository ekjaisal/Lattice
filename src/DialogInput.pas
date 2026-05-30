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

unit DialogInput;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Controls, Dialogs, ExtCtrls, Forms, Graphics, LCLType, Spin, StdCtrls, SysUtils,
  DateTimeCtrls, DateTimePicker;

type
  TDialogMode = (dmText, dmSelector, dmAttribute);

  TfrmDialogInput = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    cmbCategory: TComboBox;
    dtpDate: TDateTimePicker;
    edtFloat: TFloatSpinEdit;
    edtText: TEdit;
    lblPrompt: TLabel;
    pnlActions: TPanel;
    pnlInputContainer: TPanel;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FActiveMode: TDialogMode;
    FActiveType: String;
    function ValidateInput: Boolean;
  public
    function Execute(const ATitle, APrompt, ADefault: String; out AResult: String): Boolean; overload;
    function Execute(const ATitle, APrompt: String; AItems: TStrings; out SelectedIndex: Integer): Boolean; overload;
    function Execute(const ATitle, APrompt, AType, AOldValue: String; ACategoricalOptions: TStrings; out AResult: String): Boolean; overload;
  end;

var
  frmDialogInput: TfrmDialogInput;

implementation

uses
  AppFont;

{$R *.lfm}

procedure TfrmDialogInput.FormShow(Sender: TObject);
begin
  ApplyAppFont(Self);
  if edtText.Visible and edtText.CanFocus then edtText.SetFocus
  else if edtFloat.Visible and edtFloat.CanFocus then edtFloat.SetFocus
  else if dtpDate.Visible and dtpDate.CanFocus then dtpDate.SetFocus
  else if cmbCategory.Visible and cmbCategory.CanFocus then cmbCategory.SetFocus;
end;

procedure TfrmDialogInput.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    btnOKClick(Sender);
  end
  else if Key = VK_ESCAPE then
  begin
    Key := 0;
    ModalResult := mrCancel;
  end;
end;

function TfrmDialogInput.ValidateInput: Boolean;
var
  UrlVal: String;
  F: Double;
begin
  Result := True;
  if FActiveMode = dmText then
  begin
    if Trim(edtText.Text) = '' then
    begin
      MessageDlg('Validation', 'Value cannot be empty.', mtWarning, [mbOK], 0);
      if edtText.CanFocus then edtText.SetFocus;
      Exit(False);
    end;
  end
  else if FActiveMode = dmSelector then
  begin
    if cmbCategory.ItemIndex = -1 then
    begin
      MessageDlg('Validation', 'Please select an item.', mtWarning, [mbOK], 0);
      if cmbCategory.CanFocus then cmbCategory.SetFocus;
      Exit(False);
    end;
  end
  else if FActiveMode = dmAttribute then
  begin
    if FActiveType = 'Categorical' then
    begin
      if Trim(cmbCategory.Text) = '' then
      begin
        MessageDlg('Validation Error', 'Value cannot be empty.', mtWarning, [mbOK], 0);
        if cmbCategory.CanFocus then cmbCategory.SetFocus;
        Exit(False);
      end;
    end
    else if FActiveType = 'Numeric' then
    begin
      if not TryStrToFloat(Trim(edtFloat.Text), F) then
      begin
        MessageDlg('Validation Error', 'Please enter a valid numeric value.', mtError, [mbOK], 0);
        if edtFloat.CanFocus then edtFloat.SetFocus;
        Exit(False);
      end;
    end
    else if FActiveType = 'URL or Path' then
    begin
      UrlVal := Trim(edtText.Text);
      if UrlVal <> '' then
      begin
        if (Pos('://', UrlVal) = 0) and (Pos('\', UrlVal) = 0) and (Pos('/', UrlVal) = 0) and (Pos('www.', UrlVal) = 0) then
        begin
          if MessageDlg('Validation Warning', 'The value "' + UrlVal + '" does not appear to be a standard URL or File Path.' + sLineBreak + 'Do you want to save it anyway?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
          begin
            if edtText.CanFocus then edtText.SetFocus;
            Exit(False);
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmDialogInput.btnOKClick(Sender: TObject);
begin
  if ValidateInput then
    ModalResult := mrOk;
end;

function TfrmDialogInput.Execute(const ATitle, APrompt, ADefault: String; out AResult: String): Boolean;
begin
  FActiveMode := dmText;
  Caption := ATitle;
  lblPrompt.Caption := APrompt;
  AResult := '';
  edtText.Visible := True;
  edtFloat.Visible := False;
  dtpDate.Visible := False;
  cmbCategory.Visible := False;
  edtText.Text := ADefault;
  edtText.TextHint := 'Enter value';
  edtText.SelectAll;
  Result := (ShowModal = mrOk);
  if Result then AResult := Trim(edtText.Text);
end;

function TfrmDialogInput.Execute(const ATitle, APrompt: String; AItems: TStrings; out SelectedIndex: Integer): Boolean;
begin
  FActiveMode := dmSelector;
  Caption := ATitle;
  lblPrompt.Caption := APrompt;
  edtText.Visible := False;
  edtFloat.Visible := False;
  dtpDate.Visible := False;
  cmbCategory.Visible := True;
  cmbCategory.Style := csDropDownList;
  cmbCategory.Items.Assign(AItems);
  if cmbCategory.Items.Count > 0 then cmbCategory.ItemIndex := 0;
  Result := (ShowModal = mrOk) and (cmbCategory.ItemIndex > -1);
  if Result then SelectedIndex := cmbCategory.ItemIndex;
end;

function TfrmDialogInput.Execute(const ATitle, APrompt, AType, AOldValue: String; ACategoricalOptions: TStrings; out AResult: String): Boolean;
var
  D: TDateTime;
  Value: Double;
begin
  FActiveMode := dmAttribute;
  FActiveType := AType;
  Caption := ATitle;
  lblPrompt.Caption := APrompt;
  AResult := '';
  edtText.Visible := False;
  edtFloat.Visible := False;
  dtpDate.Visible := False;
  cmbCategory.Visible := False;
  if (AType = 'Numeric') then
  begin
    edtFloat.Visible := True;
    if TryStrToFloat(AOldValue, Value) then
      edtFloat.Value := Value
    else
      edtFloat.Value := 0;
  end
  else if (AType = 'Date-Time') then
  begin
    dtpDate.Visible := True;
    if (Trim(AOldValue) <> '') and TryStrToDate(AOldValue, D) then
    begin
      dtpDate.Date := D;
      dtpDate.Checked := True;
    end
    else
    begin
      dtpDate.Date := Date; 
      dtpDate.Checked := False;
    end;
  end
  else if (AType = 'Categorical') then
  begin
    cmbCategory.Visible := True;
    cmbCategory.Style := csDropDown;
    cmbCategory.Items.Assign(ACategoricalOptions);
    cmbCategory.Text := AOldValue;
  end
  else
  begin
    edtText.Visible := True;
    edtText.Text := AOldValue;
    if AType = 'URL or Path' then
      edtText.TextHint := 'Enter URL (https://...) or Path (C:\...)'
    else
      edtText.TextHint := 'Enter attribute value';
  end;
  Result := (ShowModal = mrOk);
  if Result then
  begin
    if edtText.Visible then AResult := Trim(edtText.Text)
    else if edtFloat.Visible then AResult := FloatToStr(edtFloat.Value)
    else if dtpDate.Visible then
    begin
       if dtpDate.Checked then
         AResult := FormatDateTime('yyyy-mm-dd', dtpDate.Date)
       else
         AResult := '';
    end
    else if cmbCategory.Visible then AResult := Trim(cmbCategory.Text);
  end;
end;

end.
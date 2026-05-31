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

unit DialogFilter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Controls, ExtCtrls, Forms, Spin, StdCtrls, EditBtn, SQLite3Conn;

type
  { TfrmDialogFilter }
  TfrmDialogFilter = class(TForm)
    btnApply: TButton;
    btnCancel: TButton;
    btnClear: TButton;
    cmbAttributeValueCat: TComboBox;
    cmbAttribute: TComboBox;
    cmbOperator: TComboBox;
    deValDate: TDateEdit;
    deValDateEnd: TDateEdit;
    edtAttributeValueText: TEdit;
    edtBodyText: TEdit;
    edtTitlePattern: TEdit;
    fseAttributeValueNum: TFloatSpinEdit;
    fseAttributeValueNumEnd: TFloatSpinEdit;
    lblAttributeValue: TLabel;
    lblAttribute: TLabel;
    lblBodyText: TLabel;
    lblFilterFeedback: TLabel;
    lblOperator: TLabel;
    lblTitlePattern: TLabel;
    pnlActions: TPanel;
    pnlAttributeInput: TPanel;
    pnlFeedback: TPanel;
    pnlOpVal: TPanel;
    pnlValCategorical: TPanel;
    pnlValDate: TPanel;
    pnlValNumeric: TPanel;
    pnlValText: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure InputChange(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure cmbAttributeChange(Sender: TObject);
  private
    FAttributeID: TStringList;
    FAttributeKey: TStringList;
    FAttributeTypes: TStringList;
    FConnection: TSQLite3Connection;
    FIsLoading: Boolean;
    function BuildAttributeSQL: String;
    procedure LoadAttributes;
    procedure LoadCategoricalValues(const AttributeID: String);
    procedure UpdateContextUI;
    procedure UpdateOperators;
  public
    class function Execute(AConnection: TSQLite3Connection; const VTitlePattern, VBodyQuery, VAttrID, VAttrOp, VAttrVal: String; out OutTitle, OutBody, OutAttributeID, OutAttributeOperator, OutAttributeValue, OutAttributeSQL: String; out ClearReq: Boolean): Boolean;
  end;

var
  frmDialogFilter: TfrmDialogFilter;

implementation

uses
  Math, SysUtils, SQLDB, AppFont;

{$R *.lfm}

procedure TfrmDialogFilter.FormCreate(Sender: TObject);
begin
  FAttributeID := TStringList.Create;
  FAttributeTypes := TStringList.Create;
  FAttributeKey := TStringList.Create;
end;

procedure TfrmDialogFilter.FormDestroy(Sender: TObject);
begin
  FAttributeID.Free;
  FAttributeTypes.Free;
  FAttributeKey.Free;
end;

procedure TfrmDialogFilter.FormShow(Sender: TObject);
begin
  ApplyAppFont(Self);
  UpdateContextUI;
  if edtTitlePattern.CanFocus then edtTitlePattern.SetFocus;
end;

procedure TfrmDialogFilter.LoadAttributes;
var
  Query: TSQLQuery;
begin
  FAttributeID.Clear;
  FAttributeTypes.Clear;
  FAttributeKey.Clear;
  cmbAttribute.Items.Clear;
  cmbAttribute.Items.Add('(None)');
  FAttributeID.Add('');
  FAttributeTypes.Add('');
  FAttributeKey.Add('');
  Query := TSQLQuery.Create(nil);
  try
    Query.Database := FConnection;
    Query.Transaction := FConnection.Transaction;
    Query.SQL.Text := 'SELECT id, name, attribute_key, attribute_type FROM attribute_registry ORDER BY name ASC';
    Query.Open;
    while not Query.EOF do
    begin
      FAttributeID.Add(Query.FieldByName('id').AsString);
      FAttributeTypes.Add(Query.FieldByName('attribute_type').AsString);
      FAttributeKey.Add(Query.FieldByName('attribute_key').AsString);
      cmbAttribute.Items.Add(Query.FieldByName('name').AsString);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

procedure TfrmDialogFilter.LoadCategoricalValues(const AttributeID: String);
var
  Query: TSQLQuery;
  ColumnName: String;
  Index: Integer;
begin
  cmbAttributeValueCat.Items.Clear;
  if AttributeID = '' then Exit;
  Index := FAttributeID.IndexOf(AttributeID);
  if Index < 0 then Exit;
  ColumnName := FAttributeKey[Index];
  Query := TSQLQuery.Create(nil);
  try
    Query.Database := FConnection;
    Query.Transaction := FConnection.Transaction;
    Query.SQL.Text := 'SELECT DISTINCT ' + ColumnName + ' FROM document_attributes WHERE ' + ColumnName + ' IS NOT NULL ORDER BY ' + ColumnName;
    Query.Open;
    while not Query.EOF do
    begin
      cmbAttributeValueCat.Items.Add(Query.Fields[0].AsString);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
  if cmbAttributeValueCat.Items.Count > 0 then cmbAttributeValueCat.ItemIndex := 0;
end;

procedure TfrmDialogFilter.UpdateOperators;
var
  AttributeType: String;
begin
  if cmbAttribute.ItemIndex < 1 then
  begin
    cmbOperator.Items.Clear;
    cmbOperator.Enabled := False;
    edtAttributeValueText.Visible := True;
    edtAttributeValueText.Enabled := False;
    pnlValNumeric.Visible := False;
    pnlValDate.Visible := False;
    cmbAttributeValueCat.Visible := False;
    Exit;
  end;
  cmbOperator.Enabled := True;
  AttributeType := FAttributeTypes[cmbAttribute.ItemIndex];
  cmbOperator.Items.BeginUpdate;
  try
    cmbOperator.Items.Clear;
    edtAttributeValueText.Visible := (AttributeType = 'Text') or (AttributeType = 'URL or Path');
    edtAttributeValueText.Enabled := edtAttributeValueText.Visible;
    pnlValNumeric.Visible := (AttributeType = 'Numeric');
    pnlValDate.Visible := (AttributeType = 'Date-Time');
    cmbAttributeValueCat.Visible := (AttributeType = 'Categorical');
    if pnlValDate.Visible then
    begin
      deValDate.Date := Date;
      deValDateEnd.Date := Date;
    end;
    if (AttributeType = 'Text') or (AttributeType = 'URL or Path') then
    begin
      cmbOperator.Items.Add('Equals');
      cmbOperator.Items.Add('Does Not Equal');
      cmbOperator.Items.Add('Contains');
      cmbOperator.Items.Add('Does Not Contain');
      cmbOperator.Items.Add('Starts With');
      cmbOperator.Items.Add('Ends With');
    end
    else if AttributeType = 'Numeric' then
    begin
      cmbOperator.Items.Add('Equals');
      cmbOperator.Items.Add('Does Not Equal');
      cmbOperator.Items.Add('Greater Than');
      cmbOperator.Items.Add('Less Than');
      cmbOperator.Items.Add('Greater or Equal');
      cmbOperator.Items.Add('Less or Equal');
      cmbOperator.Items.Add('Between');
    end
    else if AttributeType = 'Date-Time' then
    begin
      cmbOperator.Items.Add('On');
      cmbOperator.Items.Add('Not On');
      cmbOperator.Items.Add('After');
      cmbOperator.Items.Add('Before');
      cmbOperator.Items.Add('On or After');
      cmbOperator.Items.Add('On or Before');
      cmbOperator.Items.Add('Between');
    end
    else if AttributeType = 'Categorical' then
    begin
      cmbOperator.Items.Add('Equals');
      cmbOperator.Items.Add('Does Not Equal');
      LoadCategoricalValues(FAttributeID[cmbAttribute.ItemIndex]);
    end;
    cmbOperator.Items.Add('Is Empty');
    cmbOperator.Items.Add('Is Not Empty');
    cmbOperator.ItemIndex := 0;
  finally
    cmbOperator.Items.EndUpdate;
  end;
end;

procedure TfrmDialogFilter.UpdateContextUI;
var
  S, AttributeValue, Op: String;
  HasFilters, NeedsVal: Boolean;
begin
  pnlOpVal.Visible := cmbAttribute.ItemIndex > 0;
  Op := cmbOperator.Text;
  NeedsVal := (Op <> 'Is Empty') and (Op <> 'Is Not Empty');
  lblAttributeValue.Visible := NeedsVal;
  pnlAttributeInput.Visible := NeedsVal;
  if pnlValNumeric.Visible then
    fseAttributeValueNumEnd.Visible := (Op = 'Between');
  if pnlValDate.Visible then
    deValDateEnd.Visible := (Op = 'Between');
  S := '';
  HasFilters := False;
  if Trim(edtTitlePattern.Text) <> '' then
  begin
    S := S + '• Title matches "' + Trim(edtTitlePattern.Text) + '"' + sLineBreak;
    HasFilters := True;
  end;
  if Trim(edtBodyText.Text) <> '' then
  begin
    S := S + '• Body text matches FTS syntax "' + Trim(edtBodyText.Text) + '"' + sLineBreak;
    HasFilters := True;
  end;
  if cmbAttribute.ItemIndex > 0 then
  begin
    HasFilters := True;
    if not NeedsVal then
      S := S + '• Attribute [' + cmbAttribute.Text + '] ' + LowerCase(Op) + sLineBreak
    else
    begin
      if edtAttributeValueText.Visible then AttributeValue := edtAttributeValueText.Text
      else if pnlValNumeric.Visible then 
      begin
        AttributeValue := FloatToStr(fseAttributeValueNum.Value);
        if Op = 'Between' then AttributeValue := AttributeValue + ' to ' + FloatToStr(fseAttributeValueNumEnd.Value);
      end
      else if pnlValDate.Visible then 
      begin
        AttributeValue := FormatDateTime('yyyy"-"mm"-"dd', deValDate.Date);
        if Op = 'Between' then AttributeValue := AttributeValue + ' to ' + FormatDateTime('yyyy"-"mm"-"dd', deValDateEnd.Date);
      end
      else if cmbAttributeValueCat.Visible then AttributeValue := cmbAttributeValueCat.Text;
      if Trim(AttributeValue) <> '' then
        S := S + '• Attribute [' + cmbAttribute.Text + '] ' + LowerCase(Op) + ' "' + AttributeValue + '"' + sLineBreak;
    end;
  end;
  if S = '' then
    lblFilterFeedback.Caption := 'No active filters. Define and apply filter criteria to narrow the document list view.'
  else
    lblFilterFeedback.Caption := 'Active Filter Criteria:' + sLineBreak + TrimRight(S);
  btnClear.Enabled := HasFilters;
end;

function TfrmDialogFilter.BuildAttributeSQL: String;
var
  AttributeValue, OpStr, OpSelection, ColumnName: String;
  PipePos: Integer;
begin
  Result := '';
  if cmbAttribute.ItemIndex < 1 then Exit;
  ColumnName := FAttributeKey[cmbAttribute.ItemIndex];
  OpSelection := cmbOperator.Text;
  if OpSelection = 'Is Empty' then
  begin
    Result := ' AND (json_extract(da.attributes, ''$.' + ColumnName + ''') IS NULL OR CAST(json_extract(da.attributes, ''$.' + ColumnName + ''') AS TEXT) = '''')';
    Exit;
  end
  else if OpSelection = 'Is Not Empty' then
  begin
    Result := ' AND (json_extract(da.attributes, ''$.' + ColumnName + ''') IS NOT NULL AND CAST(json_extract(da.attributes, ''$.' + ColumnName + ''') AS TEXT) <> '''')';
    Exit;
  end;
  if edtAttributeValueText.Visible then AttributeValue := Trim(edtAttributeValueText.Text)
  else if pnlValNumeric.Visible then 
  begin
    AttributeValue := FloatToStr(fseAttributeValueNum.Value);
    if OpSelection = 'Between' then AttributeValue := AttributeValue + '|' + FloatToStr(fseAttributeValueNumEnd.Value);
  end
  else if pnlValDate.Visible then 
  begin
    AttributeValue := FormatDateTime('yyyy"-"mm"-"dd', deValDate.Date);
    if OpSelection = 'Between' then AttributeValue := AttributeValue + '|' + FormatDateTime('yyyy"-"mm"-"dd', deValDateEnd.Date);
  end
  else if cmbAttributeValueCat.Visible then AttributeValue := Trim(cmbAttributeValueCat.Text);
  if AttributeValue = '' then Exit;
  AttributeValue := StringReplace(AttributeValue, ',', '.', [rfReplaceAll]);
  if (OpSelection = 'Equals') or (OpSelection = 'On') then OpStr := '= ' + QuotedStr(AttributeValue)
  else if (OpSelection = 'Does Not Equal') or (OpSelection = 'Not On') then OpStr := '<> ' + QuotedStr(AttributeValue)
  else if OpSelection = 'Contains' then OpStr := 'LIKE ' + QuotedStr('%' + AttributeValue + '%')
  else if OpSelection = 'Does Not Contain' then OpStr := 'NOT LIKE ' + QuotedStr('%' + AttributeValue + '%')
  else if OpSelection = 'Starts With' then OpStr := 'LIKE ' + QuotedStr(AttributeValue + '%')
  else if OpSelection = 'Ends With' then OpStr := 'LIKE ' + QuotedStr('%' + AttributeValue)
  else if (OpSelection = 'Greater Than') or (OpSelection = 'After') then OpStr := '> ' + QuotedStr(AttributeValue)
  else if (OpSelection = 'Less Than') or (OpSelection = 'Before') then OpStr := '< ' + QuotedStr(AttributeValue)
  else if (OpSelection = 'Greater or Equal') or (OpSelection = 'On or After') then OpStr := '>= ' + QuotedStr(AttributeValue)
  else if (OpSelection = 'Less or Equal') or (OpSelection = 'On or Before') then OpStr := '<= ' + QuotedStr(AttributeValue)
  else if OpSelection = 'Between' then
  begin
    PipePos := Pos('|', AttributeValue);
    if PipePos > 0 then
      OpStr := 'BETWEEN ' + QuotedStr(Copy(AttributeValue, 1, PipePos - 1)) + ' AND ' + QuotedStr(Copy(AttributeValue, PipePos + 1, MaxInt))
    else
      OpStr := '= ' + QuotedStr(AttributeValue);
  end
  else OpStr := '= ' + QuotedStr(AttributeValue);
  if (OpSelection = 'Does Not Equal') or (OpSelection = 'Not On') or (OpSelection = 'Does Not Contain') then
    Result := ' AND (json_extract(da.attributes, ''$.' + ColumnName + ''') ' + OpStr + ' OR json_extract(da.attributes, ''$.' + ColumnName + ''') IS NULL)'
  else
    Result := ' AND json_extract(da.attributes, ''$.' + ColumnName + ''') ' + OpStr;
end;

procedure TfrmDialogFilter.cmbAttributeChange(Sender: TObject);
begin
  if FIsLoading then Exit;
  UpdateOperators;
  UpdateContextUI;
end;

procedure TfrmDialogFilter.InputChange(Sender: TObject);
begin
  if FIsLoading then Exit;
  UpdateContextUI;
end;

procedure TfrmDialogFilter.btnApplyClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmDialogFilter.btnClearClick(Sender: TObject);
begin
  ModalResult := mrRetry;
end;

class function TfrmDialogFilter.Execute(AConnection: TSQLite3Connection; const VTitlePattern, VBodyQuery, VAttrID, VAttrOp, VAttrVal: String; out OutTitle, OutBody, OutAttributeID, OutAttributeOperator, OutAttributeValue, OutAttributeSQL: String; out ClearReq: Boolean): Boolean;
var
  Dlg: TfrmDialogFilter;
  Index, PipePos: Integer;
  FmtSettings: TFormatSettings;
  DummyDate: TDateTime;
  SafeValueFirst, SafeValueSecond: String;
begin
  Result := False;
  ClearReq := False;
  OutTitle := ''; OutBody := ''; OutAttributeID := ''; OutAttributeOperator := ''; OutAttributeValue := ''; OutAttributeSQL := '';
  FmtSettings := DefaultFormatSettings;
  FmtSettings.DateSeparator := '-';
  FmtSettings.ShortDateFormat := 'yyyy-mm-dd';
  Dlg := TfrmDialogFilter.Create(nil);
  try
    Dlg.FConnection := AConnection;
    Dlg.FIsLoading := True;
    Dlg.LoadAttributes;
    Dlg.edtTitlePattern.Text := VTitlePattern;
    Dlg.edtBodyText.Text := VBodyQuery;
    if VAttrID <> '' then
    begin
      Index := Dlg.FAttributeID.IndexOf(VAttrID);
      if Index > -1 then
      begin
        Dlg.cmbAttribute.ItemIndex := Index;
        Dlg.UpdateOperators;
        Dlg.cmbOperator.ItemIndex := Max(0, Dlg.cmbOperator.Items.IndexOf(VAttrOp));
        if Dlg.edtAttributeValueText.Visible then Dlg.edtAttributeValueText.Text := VAttrVal
        else if Dlg.pnlValNumeric.Visible then 
        begin
          PipePos := Pos('|', VAttrVal);
          if PipePos > 0 then
          begin
            SafeValueFirst := StringReplace(Copy(VAttrVal, 1, PipePos - 1), '.', DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
            SafeValueSecond := StringReplace(Copy(VAttrVal, PipePos + 1, MaxInt), '.', DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
            Dlg.fseAttributeValueNum.Value := StrToFloatDef(SafeValueFirst, 0);
            Dlg.fseAttributeValueNumEnd.Value := StrToFloatDef(SafeValueSecond, 0);
          end else
          begin
            SafeValueFirst := StringReplace(VAttrVal, '.', DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
            Dlg.fseAttributeValueNum.Value := StrToFloatDef(SafeValueFirst, 0);
          end;
        end
        else if Dlg.pnlValDate.Visible then
        begin
          PipePos := Pos('|', VAttrVal);
          if PipePos > 0 then
          begin
            if TryStrToDate(Copy(VAttrVal, 1, PipePos - 1), DummyDate, FmtSettings) then Dlg.deValDate.Date := DummyDate else Dlg.deValDate.Date := Date;
            if TryStrToDate(Copy(VAttrVal, PipePos + 1, MaxInt), DummyDate, FmtSettings) then Dlg.deValDateEnd.Date := DummyDate else Dlg.deValDateEnd.Date := Date;
          end else
          begin
            if TryStrToDate(VAttrVal, DummyDate, FmtSettings) then Dlg.deValDate.Date := DummyDate else Dlg.deValDate.Date := Date;
            Dlg.deValDateEnd.Date := Date;
          end;
        end
        else if Dlg.cmbAttributeValueCat.Visible then Dlg.cmbAttributeValueCat.ItemIndex := Dlg.cmbAttributeValueCat.Items.IndexOf(VAttrVal);
      end;
    end;
    Dlg.FIsLoading := False;
    Dlg.UpdateContextUI;
    case Dlg.ShowModal of
      mrOk:
        begin
          OutTitle := Trim(Dlg.edtTitlePattern.Text);
          OutBody := Trim(Dlg.edtBodyText.Text);
          if Dlg.cmbAttribute.ItemIndex > 0 then
          begin
            OutAttributeID := Dlg.FAttributeID[Dlg.cmbAttribute.ItemIndex];
            OutAttributeOperator := Dlg.cmbOperator.Text;
            if Dlg.edtAttributeValueText.Visible then OutAttributeValue := Trim(Dlg.edtAttributeValueText.Text)
            else if Dlg.pnlValNumeric.Visible then 
            begin
              OutAttributeValue := FloatToStr(Dlg.fseAttributeValueNum.Value);
              if OutAttributeOperator = 'Between' then OutAttributeValue := OutAttributeValue + '|' + FloatToStr(Dlg.fseAttributeValueNumEnd.Value);
            end
            else if Dlg.pnlValDate.Visible then 
            begin
              OutAttributeValue := FormatDateTime('yyyy"-"mm"-"dd', Dlg.deValDate.Date);
              if OutAttributeOperator = 'Between' then OutAttributeValue := OutAttributeValue + '|' + FormatDateTime('yyyy"-"mm"-"dd', Dlg.deValDateEnd.Date);
            end
            else if Dlg.cmbAttributeValueCat.Visible then OutAttributeValue := Trim(Dlg.cmbAttributeValueCat.Text);
            OutAttributeSQL := Dlg.BuildAttributeSQL;
          end;
          Result := True;
        end;
      mrRetry:
        begin
          ClearReq := True;
          Result := True;
        end;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
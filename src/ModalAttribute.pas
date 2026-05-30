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

unit ModalAttribute;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, ComCtrls, Controls, Dialogs, ExtCtrls, Forms, Graphics, LCLIntf, LCLType, 
  StdCtrls, SysUtils, laz.VirtualTrees;

type
  TAttributeRecord = record
    ID: String;
    Name: String;
    AttributeType: String;
    Description: String;
  end;
  TAttributeArray = array of TAttributeRecord;

  { TfrmModalAttribute }
  TfrmModalAttribute = class(TForm)
    btnAdd: TButton;
    btnDelete: TButton;
    btnUpdate: TButton;
    cmbAttributeType: TComboBox;
    edtAttributeDescription: TEdit;
    edtAttributeName: TEdit;
    lblTitle: TLabel;
    pnlAttributeActions: TPanel;
    pnlEdit: TPanel;
    vstAttribute: TLazVirtualStringTree;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
    procedure vstAttributeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure vstAttributeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstAttributeHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
    procedure vstAttributePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
  private
    FAttributeData: TAttributeArray;
    FAttributeID: TStringList;
    FSelectedID: String;
    FSortColumn: Integer;
    FSortAscending: Boolean;
    function IsDuplicateName(AName: String; const ExcludeID: String): Boolean;
    function NormaliseString(AValue: String; Strict: Boolean = False): String;
    procedure AutoSizeColumns;
    procedure ClearEditControls;
    procedure RefreshAttributeList;
    procedure RestoreSelection;
    procedure SortAttribute;
    procedure UpdateActionUI;
  public
  end;

var
  frmModalAttribute: TfrmModalAttribute;

implementation

uses
  Math, SQLDB, AppBase, AppFont, DialogProgress, MonoLexID, ServiceParser, ServiceThread;

type
  TThreadLoadAttributes = class(TBackgroundWorker)
  public
    FResult: TAttributeArray;
    FSortColumn: Integer;
    FSortAsc: Boolean;
  protected
    procedure DoHeavyLifting; override;
  end;

  TAttributeModifyAction = (amaAdd, amaUpdate, amaDelete);

  TThreadModifyAttribute = class(TBackgroundWorker)
  public
    FAction: TAttributeModifyAction;
    FAttributeID: String;
    FColumnName: String;
    FNewName: String;
    FNewType: String;
    FNewDescription: String;
    FValidationError: String;
  protected
    procedure DoHeavyLifting; override;
  end;

{$R *.lfm}

function GetSafeColumnName(const AttributeID: String): String;
begin
  Result := 'attribute_' + Copy(StringReplace(AttributeID, '-', '', [rfReplaceAll]), 1, 16);
end;

procedure TThreadLoadAttributes.DoHeavyLifting;
  function CompareAttribute(const A, B: TAttributeRecord): Integer;
  begin
    case FSortColumn of
      0: Result := AnsiCompareText(A.Name, B.Name);
      1: Result := AnsiCompareText(A.AttributeType, B.AttributeType);
      2: Result := AnsiCompareText(A.Description, B.Description);
      else Result := 0;
    end;
    if not FSortAsc then Result := -Result;
  end;
  procedure QuickSort(L, R: Integer);
  var
    I, J: Integer;
    Pivot, Temp: TAttributeRecord;
  begin
    if L >= R then Exit;
    I := L;
    J := R;
    Pivot := FResult[L + (R - L) div 2];
    repeat
      while CompareAttribute(FResult[I], Pivot) < 0 do Inc(I);
      while CompareAttribute(FResult[J], Pivot) > 0 do Dec(J);
      if I <= J then
      begin
        Temp := FResult[I];
        FResult[I] := FResult[J];
        FResult[J] := Temp;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J);
    if I < R then QuickSort(I, R);
  end;
var
  Q: TSQLQuery;
  Count, Capacity: Integer;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    SyncUpdateStatus('Loading attributes...');
    Q.SQL.Text := 'SELECT id, name, attribute_type, description FROM attribute_registry';
    Q.Open;
    Count := 0; Capacity := Max(128, Q.RecordCount);
    SetLength(FResult, Capacity);
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FResult, Capacity);
      end;
      FResult[Count].ID := Q.FieldByName('id').AsString;
      FResult[Count].Name := Q.FieldByName('name').AsString;
      FResult[Count].AttributeType := Q.FieldByName('attribute_type').AsString;
      FResult[Count].Description := Q.FieldByName('description').AsString;
      Inc(Count);
      Q.Next;
    end;
    SetLength(FResult, Count);
    if (FSortColumn >= 0) and (Count > 1) then
    begin
      SyncUpdateStatus('Sorting attributes...');
      QuickSort(0, High(FResult));
    end;
  finally
    Q.Free;
  end;
end;

procedure TThreadModifyAttribute.DoHeavyLifting;
type
  TDocumentUpdateRecord = record
    DocumentID: String;
    SafeValue: String;
  end;
var
  TestVal, CleanValue: String;
  Q, QUpdate: TSQLQuery;
  UpdateArray: array of TDocumentUpdateRecord;
  Count, Capacity, I: Integer;
begin
  Q := TSQLQuery.Create(nil);
  QUpdate := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    QUpdate.Database := FConnection;
    QUpdate.Transaction := FTransaction;
    if FAction = amaAdd then
    begin
      SyncUpdateStatus('Registering new attribute...');
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO attribute_registry (id, name, attribute_key, attribute_type, description) VALUES (:g, :n, :c, :t, :d)';
      Q.Params.ParamByName('g').AsString := FAttributeID;
      Q.Params.ParamByName('n').AsString := FNewName;
      Q.Params.ParamByName('c').AsString := FColumnName;
      Q.Params.ParamByName('t').AsString := FNewType;
      Q.Params.ParamByName('d').AsString := FNewDescription;
      Q.ExecSQL;
      FTransaction.Commit;
    end
    else if FAction = amaUpdate then
    begin
      SyncUpdateStatus('Validating data compatibility...');
      Q.SQL.Text := 'SELECT document_id, json_extract(attributes, ''$.'' || :col) as val FROM document_attributes WHERE json_extract(attributes, ''$.'' || :col) IS NOT NULL AND CAST(json_extract(attributes, ''$.'' || :col) AS TEXT) <> ""';
      Q.Params.ParamByName('col').AsString := FColumnName;
      Q.Open;
      Count := 0; Capacity := Max(128, Q.RecordCount);
      SetLength(UpdateArray, Capacity);
      FValidationError := '';
      while not Q.EOF do
      begin
        TestVal := Trim(Q.FieldByName('val').AsString);
        if FNewType = 'Numeric' then
        begin
          if not TDataParser.TryParseNumeric(TestVal, CleanValue) then
          begin
            FValidationError := 'Migration Blocked: The data "' + TestVal + '" in a document is not a valid number.';
            Exit;
          end;
        end
        else if FNewType = 'Date-Time' then
        begin
          if not TDataParser.TryParseDate(TestVal, CleanValue) then
          begin
            FValidationError := 'Migration Blocked: The data "' + TestVal + '" in a document is not a valid date.';
            Exit;
          end;
        end
        else if FNewType = 'Categorical' then
          CleanValue := TDataParser.ParseCategorical(TestVal)
        else
          CleanValue := TestVal;
        if Count >= Capacity then
        begin
          Capacity := Capacity * 2;
          SetLength(UpdateArray, Capacity);
        end;
        UpdateArray[Count].DocumentID := Q.FieldByName('document_id').AsString;
        UpdateArray[Count].SafeValue := CleanValue;
        Inc(Count);
        Q.Next;
      end;
      Q.Close;
      SetLength(UpdateArray, Count);
      SyncUpdateStatus('Updating attribute registry...');
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'UPDATE attribute_registry SET name = :n, attribute_type = :t, description = :d WHERE id = :id';
      Q.Params.ParamByName('n').AsString := FNewName;
      Q.Params.ParamByName('t').AsString := FNewType;
      Q.Params.ParamByName('d').AsString := FNewDescription;
      Q.Params.ParamByName('id').AsString := FAttributeID;
      Q.ExecSQL;
      SyncUpdateStatus('Injecting strictly typed document data...');
      if FNewType = 'Numeric' then
        QUpdate.SQL.Text := 'UPDATE document_attributes SET attributes = json_set(attributes, ''$.' + FColumnName + ''', json(:val)) WHERE document_id = :did'
      else
        QUpdate.SQL.Text := 'UPDATE document_attributes SET attributes = json_set(attributes, ''$.' + FColumnName + ''', :val) WHERE document_id = :did';
      QUpdate.Prepare;
      for I := 0 to High(UpdateArray) do
      begin
        QUpdate.Params.ParamByName('did').AsString := UpdateArray[I].DocumentID;
        QUpdate.Params.ParamByName('val').AsString := UpdateArray[I].SafeValue;
        QUpdate.ExecSQL;
      end;
      FTransaction.Commit;
    end
    else if FAction = amaDelete then
    begin
      SyncUpdateStatus('Removing from attribute registry...');
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'DELETE FROM attribute_registry WHERE id = :id';
      Q.Params.ParamByName('id').AsString := FAttributeID;
      Q.ExecSQL;
      SyncUpdateStatus('Removing document association (this may take a moment)...');
      Q.SQL.Text := 'UPDATE document_attributes SET attributes = json_remove(attributes, ''$.' + FColumnName + ''')';
      Q.ExecSQL;
      FTransaction.Commit;
    end;
  finally
    Q.Free;
    QUpdate.Free;
    SetLength(UpdateArray, 0);
  end;
end;

procedure TfrmModalAttribute.FormCreate(Sender: TObject);
begin
  FAttributeID := TStringList.Create;
  vstAttribute.NodeDataSize := 0;
  FSortColumn := 0;
  FSortAscending := True;
end;

procedure TfrmModalAttribute.FormDestroy(Sender: TObject);
begin
  if Assigned(FAttributeID) then FAttributeID.Free;
  SetLength(FAttributeData, 0);
end;

procedure TfrmModalAttribute.FormShow(Sender: TObject);
begin
  ApplyAppFont(Self);
  ClearEditControls;
  RefreshAttributeList;
end;

procedure TfrmModalAttribute.FormResize(Sender: TObject);
begin
  AutoSizeColumns;
end;

procedure TfrmModalAttribute.UpdateActionUI;
begin
  btnUpdate.Enabled := FSelectedID <> '';
  btnDelete.Enabled := FSelectedID <> '';
end;

procedure TfrmModalAttribute.ClearEditControls;
begin
  FSelectedID := '';
  edtAttributeName.Clear;
  edtAttributeDescription.Clear;
  if cmbAttributeType.Items.Count > 0 then cmbAttributeType.ItemIndex := 0;
  UpdateActionUI;
end;

function TfrmModalAttribute.NormaliseString(AValue: String; Strict: Boolean = False): String;
begin
  Result := Trim(AValue);
  while Pos('  ', Result) > 0 do
    Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);
  if Strict then
    Result := StringReplace(LowerCase(Result), ' ', '', [rfReplaceAll]);
end;

procedure TfrmModalAttribute.AutoSizeColumns;
var
  TotalWidth, Remaining: Integer;
begin
  TotalWidth := vstAttribute.ClientWidth;
  vstAttribute.Header.Columns[0].Width := MulDiv(250, Self.PixelsPerInch, 96);
  vstAttribute.Header.Columns[1].Width := MulDiv(150, Self.PixelsPerInch, 96);
  Remaining := TotalWidth - (vstAttribute.Header.Columns[0].Width + vstAttribute.Header.Columns[1].Width);
  if Remaining > 100 then
    vstAttribute.Header.Columns[2].Width := Remaining
  else
    vstAttribute.Header.Columns[2].Width := 300;
end;

procedure TfrmModalAttribute.SortAttribute;
  function CompareAttribute(const A, B: TAttributeRecord): Integer;
  begin
    case FSortColumn of
      0: Result := AnsiCompareText(A.Name, B.Name);
      1: Result := AnsiCompareText(A.AttributeType, B.AttributeType);
      2: Result := AnsiCompareText(A.Description, B.Description);
      else Result := 0;
    end;
    if not FSortAscending then Result := -Result;
  end;
  procedure QuickSort(L, R: Integer);
  var
    I, J: Integer;
    Pivot, Temp: TAttributeRecord;
  begin
    if L >= R then Exit;
    I := L;
    J := R;
    Pivot := FAttributeData[L + (R - L) div 2];
    repeat
      while CompareAttribute(FAttributeData[I], Pivot) < 0 do Inc(I);
      while CompareAttribute(FAttributeData[J], Pivot) > 0 do Dec(J);
      if I <= J then
      begin
        Temp := FAttributeData[I];
        FAttributeData[I] := FAttributeData[J];
        FAttributeData[J] := Temp;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J);
    if I < R then QuickSort(I, R);
  end;
begin
  if (FSortColumn < 0) or (Length(FAttributeData) < 2) then Exit;
  QuickSort(0, High(FAttributeData));
end;

procedure TfrmModalAttribute.RestoreSelection;
var
  Node: PVirtualNode;
begin
  vstAttribute.ClearSelection;
  if FSelectedID = '' then Exit;
  Node := vstAttribute.GetFirst;
  while Assigned(Node) do
  begin
    if (Node^.Index < Cardinal(Length(FAttributeData))) then
    begin
      if FAttributeData[Node^.Index].ID = FSelectedID then
      begin
        vstAttribute.Selected[Node] := True;
        vstAttribute.FocusedNode := Node;
        vstAttribute.ScrollIntoView(Node, False);
        Break;
      end;
    end;
    Node := vstAttribute.GetNext(Node);
  end;
end;

function TfrmModalAttribute.IsDuplicateName(AName: String; const ExcludeID: String): Boolean;
var
  StrictInput: String;
begin
  Result := False;
  StrictInput := NormaliseString(AName, True);
  frmAppBase.qryCheck.Close;
  frmAppBase.qryCheck.SQL.Text := 'SELECT id, name FROM attribute_registry WHERE id <> :id';
  frmAppBase.qryCheck.Params.ParamByName('id').AsString := ExcludeID;
  frmAppBase.qryCheck.Open;
  while not frmAppBase.qryCheck.EOF do
  begin
    if StrictInput = NormaliseString(frmAppBase.qryCheck.Fields[1].AsString, True) then
    begin
      Result := True;
      Break;
    end;
    frmAppBase.qryCheck.Next;
  end;
  frmAppBase.qryCheck.Close;
end;

procedure TfrmModalAttribute.RefreshAttributeList;
var
  Worker: TThreadLoadAttributes;
begin
  if not frmAppBase.conMain.Connected then Exit;
  if frmAppBase.trnMain.Active then frmAppBase.trnMain.Commit;
  Worker := TThreadLoadAttributes.Create(frmAppBase.conMain.DatabaseName);
  try
    Worker.FSortColumn := FSortColumn;
    Worker.FSortAsc := FSortAscending;
    Worker.Start;
    TfrmDialogProgress.Prepare('Preparing Attribute Manager', 'Loading records...');
    frmDialogProgress.ShowModal;
    vstAttribute.BeginUpdate;
    try
      vstAttribute.Clear;
      if Worker.Success then
      begin
        FAttributeData := Worker.FResult;
        vstAttribute.RootNodeCount := Length(FAttributeData);
        RestoreSelection;
      end
      else
        SetLength(FAttributeData, 0);
    finally
      vstAttribute.EndUpdate;
    end;
  finally
    Worker.Free;
  end;
  AutoSizeColumns;
end;

procedure TfrmModalAttribute.vstAttributeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
begin
  if (Node^.Index < Cardinal(Length(FAttributeData))) then
  begin
    case Column of
      0: CellText := FAttributeData[Node^.Index].Name;
      1: CellText := FAttributeData[Node^.Index].AttributeType;
      2: CellText := FAttributeData[Node^.Index].Description;
    end;
  end;
end;

procedure TfrmModalAttribute.vstAttributeHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
begin
  if HitInfo.Column < 0 then Exit;
  if FSortColumn = HitInfo.Column then
    FSortAscending := not FSortAscending
  else
  begin
    FSortColumn := HitInfo.Column;
    FSortAscending := True;
  end;
  Sender.SortColumn := FSortColumn;
  if FSortAscending then Sender.SortDirection := sdAscending else Sender.SortDirection := sdDescending;
  SortAttribute;
  vstAttribute.Invalidate;
  RestoreSelection;
end;

procedure TfrmModalAttribute.vstAttributeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
begin
  if Assigned(Node) and (Node^.Index < Cardinal(Length(FAttributeData))) and (vsSelected in Node^.States) then
  begin
    FSelectedID := FAttributeData[Node^.Index].ID;
    edtAttributeName.Text := FAttributeData[Node^.Index].Name;
    cmbAttributeType.ItemIndex := cmbAttributeType.Items.IndexOf(FAttributeData[Node^.Index].AttributeType);
    edtAttributeDescription.Text := FAttributeData[Node^.Index].Description;
    UpdateActionUI;
  end
  else if Sender.SelectedCount = 0 then
    ClearEditControls;
end;

procedure TfrmModalAttribute.vstAttributePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
begin
  TargetCanvas.Font.Color := clWindowText;
end;

procedure TfrmModalAttribute.btnAddClick(Sender: TObject);
var
  NewID, ColumnName: String;
  Worker: TThreadModifyAttribute;
begin
  if Trim(edtAttributeName.Text) = '' then Exit;
  if IsDuplicateName(edtAttributeName.Text, '') then
  begin
    MessageDlg('Naming Conflict', 'A matching attribute already exists.', mtError, [mbOK], 0);
    Exit;
  end;
  NewID := NewMonoLexID;
  ColumnName := GetSafeColumnName(NewID);
  if frmAppBase.trnMain.Active then frmAppBase.trnMain.Commit;
  Worker := TThreadModifyAttribute.Create(frmAppBase.conMain.DatabaseName);
  try
    Worker.FAction := amaAdd;
    Worker.FAttributeID := NewID;
    Worker.FColumnName := ColumnName;
    Worker.FNewName := NormaliseString(edtAttributeName.Text);
    Worker.FNewType := cmbAttributeType.Text;
    Worker.FNewDescription := edtAttributeDescription.Text;
    Worker.Start;
    TfrmDialogProgress.Prepare('Adding Attribute', 'Initialising...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      SetLength(FAttributeData, Length(FAttributeData) + 1);
      FAttributeData[High(FAttributeData)].ID := NewID;
      FAttributeData[High(FAttributeData)].Name := Worker.FNewName;
      FAttributeData[High(FAttributeData)].AttributeType := Worker.FNewType;
      FAttributeData[High(FAttributeData)].Description := Worker.FNewDescription;
      if FSortColumn <> -1 then SortAttribute;
      vstAttribute.RootNodeCount := Length(FAttributeData);
      vstAttribute.Invalidate;
      FSelectedID := NewID;
      RestoreSelection;
      UpdateActionUI;
    end
    else
      MessageDlg('Database Error', Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

procedure TfrmModalAttribute.btnUpdateClick(Sender: TObject);
var
  ColumnName: String;
  Node: PVirtualNode;
  Worker: TThreadModifyAttribute;
begin
  if (FSelectedID = '') then Exit;
  if IsDuplicateName(edtAttributeName.Text, FSelectedID) then
  begin
    MessageDlg('Naming Conflict', 'Another attribute matches this name.', mtError, [mbOK], 0);
    Exit;
  end;
  ColumnName := GetSafeColumnName(FSelectedID);
  if frmAppBase.trnMain.Active then frmAppBase.trnMain.Commit;
  Worker := TThreadModifyAttribute.Create(frmAppBase.conMain.DatabaseName);
  try
    Worker.FAction := amaUpdate;
    Worker.FAttributeID := FSelectedID;
    Worker.FColumnName := ColumnName;
    Worker.FNewName := NormaliseString(edtAttributeName.Text);
    Worker.FNewType := cmbAttributeType.Text;
    Worker.FNewDescription := edtAttributeDescription.Text;
    Worker.Start;
    TfrmDialogProgress.Prepare('Updating Attribute', 'Initialising...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      if Worker.FValidationError <> '' then
      begin
        MessageDlg('Integrity Violation', Worker.FValidationError, mtError, [mbOK], 0);
      end
      else
      begin
        Node := vstAttribute.FocusedNode;
        if Assigned(Node) and (Node^.Index < Cardinal(Length(FAttributeData))) then
        begin
          FAttributeData[Node^.Index].Name := Worker.FNewName;
          FAttributeData[Node^.Index].AttributeType := Worker.FNewType;
          FAttributeData[Node^.Index].Description := Worker.FNewDescription;
        end;
        FSortColumn := -1;
        vstAttribute.Header.SortColumn := -1;
        vstAttribute.Invalidate;
        frmAppBase.RefreshDocumentList; 
      end;
    end
    else
    begin
      MessageDlg('Database Error', Worker.ErrorMessage, mtError, [mbOK], 0);
    end;
  finally
    Worker.Free;
  end;
end;

procedure TfrmModalAttribute.btnDeleteClick(Sender: TObject);
var
  ColumnName: String;
  Node: PVirtualNode;
  i, DelIndex: Integer;
  Worker: TThreadModifyAttribute;
begin
  if (FSelectedID = '') then Exit;
  if MessageDlg('Confirm Deletion', 'Delete attribute and all its document data? This may take some time for large projects.', mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    ColumnName := GetSafeColumnName(FSelectedID);
    if frmAppBase.trnMain.Active then frmAppBase.trnMain.Commit;
    Worker := TThreadModifyAttribute.Create(frmAppBase.conMain.DatabaseName);
    try
      Worker.FAction := amaDelete;
      Worker.FAttributeID := FSelectedID;
      Worker.FColumnName := ColumnName;
      Worker.Start;
      TfrmDialogProgress.Prepare('Deleting Attribute', 'Initialising...');
      frmDialogProgress.ShowModal;
      if Worker.Success then
      begin
        Node := vstAttribute.FocusedNode;
        if Assigned(Node) and (Node^.Index < Cardinal(Length(FAttributeData))) then
        begin
          DelIndex := Node^.Index;
          for i := DelIndex to High(FAttributeData) - 1 do
            FAttributeData[i] := FAttributeData[i + 1];
          SetLength(FAttributeData, Length(FAttributeData) - 1);
        end;
        vstAttribute.RootNodeCount := Length(FAttributeData);
        vstAttribute.Invalidate;
        ClearEditControls;
        frmAppBase.RefreshDocumentList;
      end
      else
        MessageDlg('Database Error', Worker.ErrorMessage, mtError, [mbOK], 0);
    finally
      Worker.Free;
    end;
  end;
end;

end.
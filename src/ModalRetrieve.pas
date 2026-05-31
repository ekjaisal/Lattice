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

unit ModalRetrieve;

{$mode ObjFPC}{$H+}

interface

uses
  Buttons, Classes, ComCtrls, Controls, Dialogs, EditBtn, ExtCtrls, Forms,
  Generics.Collections, Graphics, laz.VirtualTrees, Spin, StdCtrls, Types;

type
  PCodeTreeData = ^TCodeTreeData;
  TCodeTreeData = record
    ID: String;
    Name: String;
  end;

  TDocumentCache = record
    ID: String;
    Title: String;
  end;

  TAttributeCache = record
    ID: String;
    Name: String;
    Key: String;
    AttributeType: String;
    OperatorVal: String;
    FilterValue: String;
  end;

  TRetrievalResult = record
    DocumentID: String;
    Title: String;
    Code: String;
    SegmentPreview: String;
    StartPos: Integer;
    Length: Integer;
  end;

  TCodeNodeCache = record
    Name: String;
    ParentID: String;
  end;

  TCodeRecord = record
    ID: String;
    Name: String;
    ParentID: String;
  end;

  { TfrmModalRetrieve }
  TfrmModalRetrieve = class(TForm)
    btnAttributeFilterApply: TButton;
    btnAttributeClearAll: TButton;
    btnAttributeFilterClear: TButton;
    btnClose: TButton;
    btnCodeClearAll: TButton;
    btnCodeSelectAll: TButton;
    btnDocumentClearAll: TButton;
    btnDocumentSelectAll: TButton;
    btnExecute: TButton;
    btnExport: TButton;
    btnFieldAdd: TSpeedButton;
    btnFieldDown: TSpeedButton;
    btnFieldRemove: TSpeedButton;
    btnFieldUp: TSpeedButton;
    btnReset: TButton;
    cmbAttributeOperator: TComboBox;
    cmbOrder1: TComboBox;
    cmbOrder2: TComboBox;
    cmbOrder3: TComboBox;
    cmbSort1: TComboBox;
    cmbSort2: TComboBox;
    cmbSort3: TComboBox;
    cmbValueCategorical: TComboBox;
    deValueDate: TDateEdit;
    deValueDateEnd: TDateEdit;
    dlgExport: TSaveDialog;
    edtSearchAttribute: TEdit;
    edtSearchCode: TEdit;
    edtSearchDocument: TEdit;
    edtValueText: TEdit;
    fseValueNumeric: TFloatSpinEdit;
    fseValueNumericEnd: TFloatSpinEdit;
    lblExportFieldTitle: TLabel;
    lblExportSortTitle: TLabel;
    lblRetrievedSegmentTitle: TLabel;
    lblScopeFilterTitle: TLabel;
    lblSort1: TLabel;
    lblSort2: TLabel;
    lblSort3: TLabel;
    lblStatus: TLabel;
    lbxAvailable: TListBox;
    lbxSelected: TListBox;
    pcFilter: TPageControl;
    pnlAction: TPanel;
    pnlAttributeDefinition: TPanel;
    pnlAttributeFilterCondition: TPanel;
    pnlAttributeSearch: TPanel;
    pnlCodeTool: TPanel;
    pnlDocumentSearch: TPanel;
    pnlExportField: TPanel;
    pnlExportSort: TPanel;
    pnlFieldMove: TPanel;
    pnlFieldOrder: TPanel;
    pnlFilter: TPanel;
    pnlResult: TPanel;
    pnlValueCategorical: TPanel;
    pnlValueDate: TPanel;
    pnlValueInput: TPanel;
    pnlValueNumeric: TPanel;
    pnlValueText: TPanel;
    rgLogicMode: TRadioGroup;
    splExportOption: TSplitter;
    tmrAttributeSearch: TTimer;
    tmrCodeSearch: TTimer;
    tmrDocumentSearch: TTimer;
    tsAttribute: TTabSheet;
    tsCode: TTabSheet;
    tsDocument: TTabSheet;
    tsExportOption: TTabSheet;
    vstCode: TLazVirtualStringTree;
    vstFilterAttribute: TLazVirtualStringTree;
    vstFilterDocument: TLazVirtualStringTree;
    vstResult: TLazVirtualStringTree;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure SearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnAttributeFilterApplyClick(Sender: TObject);
    procedure btnAttributeClearAllClick(Sender: TObject);
    procedure btnAttributeFilterClearClick(Sender: TObject);
    procedure btnCodeClearAllClick(Sender: TObject);
    procedure btnCodeSelectAllClick(Sender: TObject);
    procedure btnDocumentClearAllClick(Sender: TObject);
    procedure btnDocumentSelectAllClick(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnFieldAddClick(Sender: TObject);
    procedure btnFieldDownClick(Sender: TObject);
    procedure btnFieldRemoveClick(Sender: TObject);
    procedure btnFieldUpClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure cmbAttributeOperatorChange(Sender: TObject);
    procedure edtSearchAttributeChange(Sender: TObject);
    procedure edtSearchCodeChange(Sender: TObject);
    procedure edtSearchDocumentChange(Sender: TObject);
    procedure tmrAttributeSearchTimer(Sender: TObject);
    procedure tmrCodeSearchTimer(Sender: TObject);
    procedure tmrDocumentSearchTimer(Sender: TObject);
    procedure vstCodeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstCodeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstCodeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
    procedure vstCodeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstCodeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure vstFilterAttributeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstFilterAttributeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
    procedure vstFilterAttributeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstFilterAttributePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
    procedure vstFilterAttributeHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
    procedure vstFilterDocumentChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstFilterDocumentGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
    procedure vstFilterDocumentGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstFilterDocumentInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure vstResultGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
    procedure vstResultGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstScopeNoFocusChanging(Sender: TBaseVirtualTree; OldNode, NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex; var Allowed: Boolean);
  private
    FAttributeCache: array of TAttributeCache;
    FAttributeSortAscending: Boolean;
    FAttributeSortColumn: Integer;
    FCheckedDocumentSet: specialize TDictionary<String, Boolean>;
    FCodeCache: specialize TDictionary<String, TCodeNodeCache>;
    FCurrentAttributeIndex: Integer;
    FDocumentCache: array of TDocumentCache;
    FLastCheckedDocNode: PVirtualNode;
    FLastCheckedNode: PVirtualNode;
    FResultCache: array of TRetrievalResult;
    function BuildSQL(CodeAll, DocumentAll: Boolean): String;
    function GetAttributeSQL: String;
    function GetFullCodePath(const CodeID: String): String;
    function GetSelectedCodeList(out IsAllSelected: Boolean): TStringDynArray;
    function GetSelectedDocumentList(out IsAllSelected: Boolean): TStringDynArray;
    procedure ApplyAttributeFilter(const Filter: String);
    procedure ApplyCodeFilter(const Filter: String);
    procedure LoadAttribute(const Filter: String);
    procedure LoadAttributeDefinitionPane(NodeIndex: Integer);
    procedure LoadCategoricalValue;
    procedure LoadDocument(const Filter: String);
    procedure UpdateAttributeOperator(const AttributeType: String);
    procedure UpdateSortDropdown;
  public
    function GetExportFieldList: TStringDynArray;
    function GetSortDescription: String;
    procedure GetSortConfig(out S1, O1, S2, O2, S3, O3: String);
  end;

var
  frmModalRetrieve: TfrmModalRetrieve;

implementation

uses
  DB, LazUTF8, LCLIntf, LCLType, Math, StrUtils, SysUtils, SQLDB, AppBase,
  AppFont, AppFormat, DataShared, DialogProgress, ServiceExport, ServiceThread;

type
  TThreadLoadRetrieveContext = class(TBackgroundWorker)
  public
    FAllCode: array of TCodeRecord;
    FDocumentCache: array of TDocumentCache;
    FAttributeCache: array of TAttributeCache;
    FCodeCacheDict: specialize TDictionary<String, TCodeNodeCache>;
    FExportAttributeName: TStringList;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadRetrieveExecution = class(TBackgroundWorker)
  public
    FSQL: String;
    FCodeArr, FDocumentArr: TStringDynArray;
    FCodeAll, FDocumentAll: Boolean;
    FResultCache: array of TRetrievalResult;
    FCodeCacheRef: specialize TDictionary<String, TCodeNodeCache>;
  protected
    procedure DoHeavyLifting; override;
    function GetPathSafe(const CodeID: String): String;
  end;

  TThreadRetrieveExport = class(TBackgroundWorker)
  public
    FSQL: String;
    FCodeArr, FDocumentArr: TStringDynArray;
    FCodeAll, FDocumentAll: Boolean;
    FFileName: String;
    FExportField: TStringDynArray;
    FSortDescription: String;
    FCodeCacheRef: specialize TDictionary<String, TCodeNodeCache>;
  protected
    procedure DoHeavyLifting; override;
    function GetPathSafe(const CodeID: String): String;
  end;

{$R *.lfm}

procedure TThreadLoadRetrieveContext.DoHeavyLifting;
var
  Q: TSQLQuery;
  Count, Capacity: Integer;
  NodeCache: TCodeNodeCache;
begin
  FCodeCacheDict := specialize TDictionary<String, TCodeNodeCache>.Create;
  FExportAttributeName := TStringList.Create;
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    SyncUpdateStatus('Loading code system...');
    Q.SQL.Text := 'SELECT id, name, parent_id FROM codes ORDER BY name ASC';
    Q.Open;
    Count := 0; Capacity := Max(128, Q.RecordCount);
    SetLength(FAllCode, Capacity);
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FAllCode, Capacity);
      end;
      FAllCode[Count].ID := Q.FieldByName('id').AsString;
      FAllCode[Count].Name := Q.FieldByName('name').AsString;
      FAllCode[Count].ParentID := Q.FieldByName('parent_id').AsString;
      NodeCache.Name := FAllCode[Count].Name;
      NodeCache.ParentID := FAllCode[Count].ParentID;
      FCodeCacheDict.AddOrSetValue(FAllCode[Count].ID, NodeCache);
      Inc(Count);
      Q.Next;
    end;
    SetLength(FAllCode, Count);
    Q.Close;
    SyncUpdateStatus('Loading document index...');
    Q.SQL.Text := 'SELECT id, title FROM documents ORDER BY title ASC';
    Q.Open;
    Count := 0; Capacity := Max(128, Q.RecordCount);
    SetLength(FDocumentCache, Capacity);
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FDocumentCache, Capacity);
      end;
      FDocumentCache[Count].ID := Q.FieldByName('id').AsString;
      FDocumentCache[Count].Title := Q.FieldByName('title').AsString;
      Inc(Count);
      Q.Next;
    end;
    SetLength(FDocumentCache, Count);
    Q.Close;
    SyncUpdateStatus('Loading attribute registry...');
    Q.SQL.Text := 'SELECT id, name, attribute_key, attribute_type FROM attribute_registry ORDER BY name ASC';
    Q.Open;
    Count := 0; Capacity := Max(128, Q.RecordCount);
    SetLength(FAttributeCache, Capacity);
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FAttributeCache, Capacity);
      end;
      FAttributeCache[Count].ID := Q.FieldByName('id').AsString;
      FAttributeCache[Count].Name := Q.FieldByName('name').AsString;
      FAttributeCache[Count].Key := Q.FieldByName('attribute_key').AsString;
      FAttributeCache[Count].AttributeType := Q.FieldByName('attribute_type').AsString;
      FAttributeCache[Count].OperatorVal := '';
      FAttributeCache[Count].FilterValue := '';
      FExportAttributeName.Add('Attribute: ' + FAttributeCache[Count].Name);
      Inc(Count);
      Q.Next;
    end;
    SetLength(FAttributeCache, Count);
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TThreadRetrieveExecution.GetPathSafe(const CodeID: String): String;
var
  CurrentID: String;
  NodeCache: TCodeNodeCache;
begin
  Result := '';
  if CodeID = '' then Exit;
  CurrentID := CodeID;
  while (CurrentID <> '') and FCodeCacheRef.TryGetValue(CurrentID, NodeCache) do
  begin
    if NodeCache.Name = '' then Break;
    if Result = '' then
      Result := NodeCache.Name
    else
      Result := NodeCache.Name + ' ' + #$E2#$86#$92 + ' ' + Result;
    CurrentID := NodeCache.ParentID;
  end;
end;

procedure TThreadRetrieveExecution.DoHeavyLifting;
var
  Q: TSQLQuery;
  FullText, SegmentSlice: String;
  StartPointer, LengthPosition, Count, Capacity: Integer;
  CodeID: String;
  fContent, fStartPos, fLength, fCodeID, fDocID, fTitle: TField;
  i: Integer;
begin
  if not FCodeAll then
  begin
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_codes');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_codes (id TEXT PRIMARY KEY)');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection; Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_codes (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FCodeArr) to High(FCodeArr) do
      begin
        Q.Params[0].AsString := FCodeArr[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
  end;
  if not FDocumentAll then
  begin
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_docs (id TEXT PRIMARY KEY)');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection; Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_docs (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FDocumentArr) to High(FDocumentArr) do
      begin
        Q.Params[0].AsString := FDocumentArr[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
  end;
  SyncUpdateStatus('Executing retrieval query...');
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    Q.ParseSQL := False;
    Q.UniDirectional := True;
    Q.SQL.Text := FSQL;
    Q.Open;
    Count := 0;
    Capacity := 4096;
    SetLength(FResultCache, Capacity);
    fContent := Q.FieldByName('content');
    fStartPos := Q.FieldByName('start_position');
    fLength := Q.FieldByName('length');
    fCodeID := Q.FieldByName('code_id');
    fDocID := Q.FieldByName('document_id');
    fTitle := Q.FieldByName('title');
    SyncUpdateStatus('Processing text segments...');
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FResultCache, Capacity);
      end;
      FullText := fContent.AsString;
      StartPointer := fStartPos.AsInteger;
      LengthPosition := fLength.AsInteger;
      CodeID := fCodeID.AsString;
      SegmentSlice := UTF8Copy(FullText, StartPointer + 1, LengthPosition);
      SegmentSlice := StringReplace(SegmentSlice, #10, ' ', [rfReplaceAll]);
      SegmentSlice := StringReplace(SegmentSlice, #13, ' ', [rfReplaceAll]);
      if UTF8Length(SegmentSlice) > 100 then
        SegmentSlice := UTF8Copy(SegmentSlice, 1, 100) + '...';
      FResultCache[Count].DocumentID := fDocID.AsString;
      FResultCache[Count].Title := fTitle.AsString;
      FResultCache[Count].Code := GetPathSafe(CodeID);
      FResultCache[Count].SegmentPreview := Trim(SegmentSlice);
      FResultCache[Count].StartPos := StartPointer;
      FResultCache[Count].Length := LengthPosition;
      Inc(Count);
      Q.Next;
    end;
    SetLength(FResultCache, Count);
  finally
    Q.Free;
  end;
end;

function TThreadRetrieveExport.GetPathSafe(const CodeID: String): String;
var
  CurrentID: String;
  NodeCache: TCodeNodeCache;
begin
  Result := '';
  if CodeID = '' then Exit;
  CurrentID := CodeID;
  while (CurrentID <> '') and FCodeCacheRef.TryGetValue(CurrentID, NodeCache) do
  begin
    if NodeCache.Name = '' then Break;
    if Result = '' then
      Result := NodeCache.Name
    else
      Result := NodeCache.Name + ' ' + #$E2#$86#$92 + ' ' + Result;
    CurrentID := NodeCache.ParentID;
  end;
end;

procedure TThreadRetrieveExport.DoHeavyLifting;
var
  Q: TSQLQuery;
  i: Integer;
begin
  if not FCodeAll then
  begin
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_codes');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_codes (id TEXT PRIMARY KEY)');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection; Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_codes (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FCodeArr) to High(FCodeArr) do
      begin
        Q.Params[0].AsString := FCodeArr[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
  end;
  if not FDocumentAll then
  begin
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_docs (id TEXT PRIMARY KEY)');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection; Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_docs (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FDocumentArr) to High(FDocumentArr) do
      begin
        Q.Params[0].AsString := FDocumentArr[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
  end;
  SyncUpdateStatus('Executing retrieval query for export...');
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    Q.ParseSQL := False;
    Q.UniDirectional := True;
    Q.SQL.Text := FSQL;
    Q.Open;
    SyncUpdateStatus('Writing file to disk...');
    if not TServiceExport.ExportRetrievedSegment(Q, FFileName, @GetPathSafe, FExportField, FSortDescription) then
      raise Exception.Create('Export failed or file is locked.');
  finally
    Q.Free;
  end;
end;

procedure TfrmModalRetrieve.FormCreate(Sender: TObject);
begin
  ApplyAppFont(Self);
  FCheckedDocumentSet := specialize TDictionary<String, Boolean>.Create;
  FCodeCache := specialize TDictionary<String, TCodeNodeCache>.Create;
  vstCode.NodeDataSize := SizeOf(TCodeTreeData);
  vstFilterDocument.NodeDataSize := 0;
  vstFilterAttribute.NodeDataSize := 0;
  vstResult.NodeDataSize := 0;
  FCurrentAttributeIndex := -1;
  FAttributeSortColumn := 0;
  FAttributeSortAscending := True;
  btnFieldAdd.Images := dmShared.imlMain;
  btnFieldRemove.Images := dmShared.imlMain;
  btnFieldUp.Images := dmShared.imlMain;
  btnFieldDown.Images := dmShared.imlMain;
end;

procedure TfrmModalRetrieve.FormDestroy(Sender: TObject);
begin
  Application.HintHidePause := 2500;
  FCheckedDocumentSet.Free;
  FCodeCache.Free;
  SetLength(FDocumentCache, 0);
  SetLength(FAttributeCache, 0);
  SetLength(FResultCache, 0);
end;

procedure TfrmModalRetrieve.FormShow(Sender: TObject);
var
  Worker: TThreadLoadRetrieveContext;
  procedure AddChildNode(ParentNode: PVirtualNode; const PID: String);
  var
    j: Integer;
    Node: PVirtualNode;
    Data: PCodeTreeData;
  begin
    for j := 0 to High(Worker.FAllCode) do
    begin
      if Worker.FAllCode[j].ParentID = PID then
      begin
        Node := vstCode.AddChild(ParentNode);
        Data := vstCode.GetNodeData(Node);
        Data^.ID := Worker.FAllCode[j].ID;
        Data^.Name := Worker.FAllCode[j].Name;
        vstCode.CheckState[Node] := csUncheckedNormal;
        vstCode.CheckType[Node] := ctCheckBox;
        AddChildNode(Node, Worker.FAllCode[j].ID);
      end;
    end;
  end;
begin
  ApplyAppFont(Self);
  pcFilter.ActivePageIndex := 0;
  edtSearchCode.Text := '';
  edtSearchDocument.Text := '';
  edtSearchAttribute.Text := '';
  Worker := TThreadLoadRetrieveContext.Create(frmAppBase.conMain.DatabaseName);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Preparing Retrieval Manager', 'Loading project data...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      FCodeCache.Free;
      FCodeCache := Worker.FCodeCacheDict;
      Worker.FCodeCacheDict := nil; 
      vstCode.BeginUpdate;
      vstCode.Clear;
      AddChildNode(nil, '');
      vstCode.EndUpdate;
      FDocumentCache := Worker.FDocumentCache;
      vstFilterDocument.BeginUpdate;
      vstFilterDocument.Clear;
      vstFilterDocument.RootNodeCount := Length(FDocumentCache);
      vstFilterDocument.EndUpdate;
      FAttributeCache := Worker.FAttributeCache;
      vstFilterAttribute.BeginUpdate;
      vstFilterAttribute.Clear;
      vstFilterAttribute.RootNodeCount := Length(FAttributeCache);
      vstFilterAttribute.EndUpdate;
      lbxAvailable.Clear;
      lbxSelected.Clear;
      lbxSelected.Items.Add('Document Name');
      lbxSelected.Items.Add('Code');
      lbxAvailable.Items.Assign(Worker.FExportAttributeName);
      UpdateSortDropdown;
    end
    else
    begin
      FCodeCache := specialize TDictionary<String, TCodeNodeCache>.Create;
      MessageDlg('Error', 'Failed to load project context: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
    end;
  finally
    if Assigned(Worker.FExportAttributeName) then Worker.FExportAttributeName.Free;
    if Assigned(Worker.FCodeCacheDict) then Worker.FCodeCacheDict.Free; 
    Worker.Free;
  end;
  btnCodeClearAllClick(nil);
  btnDocumentClearAllClick(nil);
  btnAttributeClearAllClick(nil);
  vstFilterAttribute.ClearSelection;
  FCurrentAttributeIndex := -1;
  pnlAttributeDefinition.Visible := False;
  SetLength(FResultCache, 0);
  vstResult.BeginUpdate;
  vstResult.Clear;
  vstResult.RootNodeCount := 0;
  vstResult.EndUpdate;
  FLastCheckedNode := nil;
  FLastCheckedDocNode := nil;
  btnExport.Enabled := False;
  lblStatus.Caption := 'Ready';
end;

function TfrmModalRetrieve.GetFullCodePath(const CodeID: String): String;
var
  CurrentID: String;
  NodeCache: TCodeNodeCache;
begin
  Result := '';
  if CodeID = '' then Exit;
  CurrentID := CodeID;
  while (CurrentID <> '') and FCodeCache.TryGetValue(CurrentID, NodeCache) do
  begin
    if NodeCache.Name = '' then Break;
    if Result = '' then
      Result := NodeCache.Name
    else
      Result := NodeCache.Name + ' ' + #$E2#$86#$92 + ' ' + Result;
    CurrentID := NodeCache.ParentID;
  end;
end;

procedure TfrmModalRetrieve.UpdateSortDropdown;
var
  i: Integer;
  Sel1, Sel2, Sel3: String;
begin
  Sel1 := cmbSort1.Text;
  Sel2 := cmbSort2.Text;
  Sel3 := cmbSort3.Text;
  cmbSort1.Items.BeginUpdate;
  cmbSort2.Items.BeginUpdate;
  cmbSort3.Items.BeginUpdate;
  try
    cmbSort1.Items.Clear;
    cmbSort2.Items.Clear;
    cmbSort3.Items.Clear;
    cmbSort1.Items.Add('(None)');
    cmbSort2.Items.Add('(None)');
    cmbSort3.Items.Add('(None)');
    for i := 0 to lbxSelected.Items.Count - 1 do
    begin
      cmbSort1.Items.Add(lbxSelected.Items[i]);
      cmbSort2.Items.Add(lbxSelected.Items[i]);
      cmbSort3.Items.Add(lbxSelected.Items[i]);
    end;
    cmbSort1.ItemIndex := cmbSort1.Items.IndexOf(Sel1);
    if cmbSort1.ItemIndex = -1 then cmbSort1.ItemIndex := 0;
    cmbSort2.ItemIndex := cmbSort2.Items.IndexOf(Sel2);
    if cmbSort2.ItemIndex = -1 then cmbSort2.ItemIndex := 0;
    cmbSort3.ItemIndex := cmbSort3.Items.IndexOf(Sel3);
    if cmbSort3.ItemIndex = -1 then cmbSort3.ItemIndex := 0;
  finally
    cmbSort1.Items.EndUpdate;
    cmbSort2.Items.EndUpdate;
    cmbSort3.Items.EndUpdate;
  end;
end;

procedure TfrmModalRetrieve.btnFieldAddClick(Sender: TObject);
var
  i: Integer;
begin
  for i := lbxAvailable.Items.Count - 1 downto 0 do
  begin
    if lbxAvailable.Selected[i] then
    begin
      lbxSelected.Items.Add(lbxAvailable.Items[i]);
      lbxAvailable.Items.Delete(i);
    end;
  end;
  UpdateSortDropdown;
end;

procedure TfrmModalRetrieve.btnFieldRemoveClick(Sender: TObject);
var
  i: Integer;
begin
  for i := lbxSelected.Items.Count - 1 downto 0 do
  begin
    if lbxSelected.Selected[i] then
    begin
      lbxAvailable.Items.Add(lbxSelected.Items[i]);
      lbxSelected.Items.Delete(i);
    end;
  end;
  UpdateSortDropdown;
end;

procedure TfrmModalRetrieve.btnFieldUpClick(Sender: TObject);
var
  i: Integer;
begin
  if lbxSelected.SelCount = 0 then Exit;
  lbxSelected.Items.BeginUpdate;
  try
    for i := 1 to lbxSelected.Items.Count - 1 do
    begin
      if lbxSelected.Selected[i] then
      begin
        lbxSelected.Items.Exchange(i, i - 1);
        lbxSelected.Selected[i] := False;
        lbxSelected.Selected[i - 1] := True;
      end;
    end;
  finally
    lbxSelected.Items.EndUpdate;
  end;
  UpdateSortDropdown;
end;

procedure TfrmModalRetrieve.btnFieldDownClick(Sender: TObject);
var
  i: Integer;
begin
  if lbxSelected.SelCount = 0 then Exit;
  lbxSelected.Items.BeginUpdate;
  try
    for i := lbxSelected.Items.Count - 2 downto 0 do
    begin
      if lbxSelected.Selected[i] then
      begin
        lbxSelected.Items.Exchange(i, i + 1);
        lbxSelected.Selected[i] := False;
        lbxSelected.Selected[i + 1] := True;
      end;
    end;
  finally
    lbxSelected.Items.EndUpdate;
  end;
  UpdateSortDropdown;
end;

procedure TfrmModalRetrieve.vstResultGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Index: Integer;
begin
  Index := Node^.Index;
  if (Index < 0) or (Index >= Length(FResultCache)) then Exit;
  case Column of
    0: CellText := FResultCache[Index].Title;
    1: CellText := FResultCache[Index].Code;
    2: CellText := FResultCache[Index].SegmentPreview;
  end;
end;

procedure TfrmModalRetrieve.vstResultGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
var
  Index: Integer;
  RawHint: String;
  Q: TSQLQuery;
begin
  Index := Node^.Index;
  if (Index >= 0) and (Index < Length(FResultCache)) then
  begin
    case Column of
      0: RawHint := FResultCache[Index].Title;
      1: RawHint := FResultCache[Index].Code;
      2: 
      begin
        Q := TSQLQuery.Create(nil);
        try
          Q.Database := frmAppBase.conMain;
          Q.SQL.Text := 'SELECT SUBSTR(content, :sp + 1, :len) FROM documents WHERE id = :did';
          Q.Params.ParamByName('did').AsString := FResultCache[Index].DocumentID;
          Q.Params.ParamByName('sp').AsInteger := FResultCache[Index].StartPos;
          Q.Params.ParamByName('len').AsInteger := Min(2000, FResultCache[Index].Length);
          Q.Open;
          if not Q.EOF then
          begin
            RawHint := Q.Fields[0].AsString;
            RawHint := StringReplace(RawHint, #10, ' ', [rfReplaceAll]);
            RawHint := StringReplace(RawHint, #13, ' ', [rfReplaceAll]);
          end
          else
            RawHint := '[Segment unavailable]';
        finally
          Q.Free;
        end;
      end;
    else
      Exit;
    end;
    HintText := TAppFormat.FormatUIHint(RawHint);
  end;
end;

procedure TfrmModalRetrieve.ApplyCodeFilter(const Filter: String);
var
  SearchTerm: String;
  function ProcessNode(ANode: PVirtualNode): Boolean;
  var
    AData: PCodeTreeData;
    Child: PVirtualNode;
    AnyChildMatch: Boolean;
    NodeMatches: Boolean;
  begin
    AData := vstCode.GetNodeData(ANode);
    AnyChildMatch := False;
    Child := ANode^.FirstChild;
    while Assigned(Child) do
    begin
      if ProcessNode(Child) then AnyChildMatch := True;
      Child := Child^.NextSibling;
    end;
    NodeMatches := (Filter = '') or (Pos(SearchTerm, LowerCase(AData^.Name)) > 0);
    vstCode.IsVisible[ANode] := NodeMatches or AnyChildMatch;
    if (Filter <> '') and (NodeMatches or AnyChildMatch) then
      vstCode.Expanded[ANode] := True;
    Result := vstCode.IsVisible[ANode];
  end;
var
  RootNode: PVirtualNode;
begin
  SearchTerm := LowerCase(Trim(Filter));
  vstCode.BeginUpdate;
  try
    RootNode := vstCode.GetFirst;
    while Assigned(RootNode) do
    begin
      ProcessNode(RootNode);
      RootNode := RootNode^.NextSibling;
    end;
  finally
    vstCode.EndUpdate;
  end;
end;

procedure TfrmModalRetrieve.vstCodeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var Data: PCodeTreeData;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then CellText := Data^.Name;
end;

procedure TfrmModalRetrieve.vstCodeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  Node^.CheckType := ctCheckBox;
end;

procedure TfrmModalRetrieve.vstCodeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PCodeTreeData;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then Finalize(Data^);
end;

procedure TfrmModalRetrieve.vstCodeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
const
  IsProcessing: Boolean = False;
var
  TargetState: TCheckState;
  StartNode, EndNode, CurrentNode: PVirtualNode;
  procedure ApplyCheck(ANode: PVirtualNode; AState: TCheckState);
  var Child: PVirtualNode;
  begin
    if Sender.CheckState[ANode] <> AState then
      Sender.CheckState[ANode] := AState;
    Child := ANode^.FirstChild;
    while Assigned(Child) do
    begin
      ApplyCheck(Child, AState);
      Child := Child^.NextSibling;
    end;
  end;
begin
  if IsProcessing then Exit;
  IsProcessing := True;
  try
    TargetState := Node^.CheckState;
    Sender.BeginUpdate;
    try
      if (GetKeyState(VK_SHIFT) < 0) and Assigned(FLastCheckedNode) then
      begin
        if Sender.AbsoluteIndex(FLastCheckedNode) < Sender.AbsoluteIndex(Node) then
        begin
          StartNode := FLastCheckedNode;
          EndNode := Node;
        end
        else
        begin
          StartNode := Node;
          EndNode := FLastCheckedNode;
        end;
        CurrentNode := StartNode;
        while Assigned(CurrentNode) do
        begin
          if Sender.IsVisible[CurrentNode] then
            ApplyCheck(CurrentNode, TargetState);
          if CurrentNode = EndNode then Break;
          CurrentNode := Sender.GetNextVisible(CurrentNode);
        end;
      end
      else
        ApplyCheck(Node, TargetState);
    finally
      Sender.EndUpdate;
      FLastCheckedNode := Node;
    end;
  finally
    IsProcessing := False;
  end;
end;

procedure TfrmModalRetrieve.vstCodeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
var
  Data: PCodeTreeData;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then
    HintText := TAppFormat.FormatUIHint(Data^.Name);
end;

procedure TfrmModalRetrieve.vstScopeNoFocusChanging(Sender: TBaseVirtualTree; OldNode, NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex; var Allowed: Boolean);
begin
  Allowed := False;
end;

function TfrmModalRetrieve.GetSelectedCodeList(out IsAllSelected: Boolean): TStringDynArray;
var
  Node: PVirtualNode;
  Data: PCodeTreeData;
  Count, TotalCount: Integer;
begin
  Result := nil;
  Count := 0;
  TotalCount := 0;
  Node := vstCode.GetFirst;
  while Assigned(Node) do
  begin
    Inc(TotalCount);
    if vstCode.CheckState[Node] = csCheckedNormal then Inc(Count);
    Node := vstCode.GetNext(Node);
  end;
  IsAllSelected := (TotalCount > 0) and (Count = TotalCount);
  SetLength(Result, Count);
  if IsAllSelected or (Count = 0) then Exit;
  Count := 0;
  Node := vstCode.GetFirst;
  while Assigned(Node) do
  begin
    if vstCode.CheckState[Node] = csCheckedNormal then
    begin
      Data := vstCode.GetNodeData(Node);
      Result[Count] := Data^.ID;
      Inc(Count);
    end;
    Node := vstCode.GetNext(Node);
  end;
end;

procedure TfrmModalRetrieve.btnCodeSelectAllClick(Sender: TObject);
var
  Node: PVirtualNode;
begin
  vstCode.BeginUpdate;
  try
    Node := vstCode.GetFirst;
    while Assigned(Node) do
    begin
      if vstCode.IsVisible[Node] then
        vstCode.CheckState[Node] := csCheckedNormal;
      Node := vstCode.GetNext(Node);
    end;
  finally
    vstCode.EndUpdate;
  end;
end;

procedure TfrmModalRetrieve.btnCodeClearAllClick(Sender: TObject);
var
  Node: PVirtualNode;
begin
  vstCode.BeginUpdate;
  try
    Node := vstCode.GetFirst;
    while Assigned(Node) do
    begin
      if vstCode.IsVisible[Node] then
        vstCode.CheckState[Node] := csUncheckedNormal;
      Node := vstCode.GetNext(Node);
    end;
  finally
    vstCode.EndUpdate;
  end;
end;

procedure TfrmModalRetrieve.edtSearchCodeChange(Sender: TObject);
begin
  tmrCodeSearch.Enabled := False;
  tmrCodeSearch.Enabled := True;
end;

procedure TfrmModalRetrieve.tmrCodeSearchTimer(Sender: TObject);
begin
  tmrCodeSearch.Enabled := False;
  if edtSearchCode.Text = '' then
  begin
    btnCodeSelectAll.Caption := 'Select All';
    btnCodeClearAll.Caption := 'Clear All';
  end
  else
  begin
    btnCodeSelectAll.Caption := 'Select Filtered';
    btnCodeClearAll.Caption := 'Clear Filtered';
  end;
  ApplyCodeFilter(edtSearchCode.Text);
end;

procedure TfrmModalRetrieve.LoadDocument(const Filter: String);
var
  Q: TSQLQuery;
  Count, Capacity: Integer;
  fId, fTitle: TField;
  WhereSQL: String;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := frmAppBase.conMain;
    Q.UniDirectional := True;
    WhereSQL := '';
    if Filter <> '' then
      WhereSQL := ' WHERE title LIKE ' + QuotedStr('%' + Filter + '%');
    Q.SQL.Text := 'SELECT COUNT(id) FROM documents' + WhereSQL;
    Q.Open;
    Capacity := Q.Fields[0].AsInteger;
    Q.Close;
    if Capacity < 128 then Capacity := 128;
    SetLength(FDocumentCache, Capacity);
    Q.SQL.Text := 'SELECT id, title FROM documents' + WhereSQL + ' ORDER BY title ASC';
    Q.Open;
    Count := 0;
    fId := Q.FieldByName('id');
    fTitle := Q.FieldByName('title');
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FDocumentCache, Capacity);
      end;
      FDocumentCache[Count].ID := fId.AsString;
      FDocumentCache[Count].Title := fTitle.AsString;
      Inc(Count);
      Q.Next;
    end;
    SetLength(FDocumentCache, Count);
    vstFilterDocument.BeginUpdate;
    try
      vstFilterDocument.Clear;
      vstFilterDocument.RootNodeCount := Count;
      vstFilterDocument.Invalidate;
    finally
      vstFilterDocument.EndUpdate;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmModalRetrieve.vstFilterDocumentInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  Node^.CheckType := ctCheckBox;
  if (Node^.Index < Cardinal(Length(FDocumentCache))) then
  begin
    if FCheckedDocumentSet.ContainsKey(FDocumentCache[Node^.Index].ID) then
      Sender.CheckState[Node] := csCheckedNormal
    else
      Sender.CheckState[Node] := csUncheckedNormal;
  end;
end;

procedure TfrmModalRetrieve.vstFilterDocumentGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
begin
  if (Node^.Index < Cardinal(Length(FDocumentCache))) then
    CellText := FDocumentCache[Node^.Index].Title;
end;

procedure TfrmModalRetrieve.vstFilterDocumentGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
begin
  if (Node^.Index < Cardinal(Length(FDocumentCache))) then
    HintText := TAppFormat.FormatUIHint(FDocumentCache[Node^.Index].Title);
end;

procedure TfrmModalRetrieve.vstFilterDocumentChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
const
  IsProcessing: Boolean = False;
var
  TargetState: TCheckState;
  StartNode, EndNode, CurrentNode: PVirtualNode;
  procedure ApplyDocCheck(ANode: PVirtualNode; AState: TCheckState);
  var DocumentID: String;
  begin
    if Sender.CheckState[ANode] <> AState then
      Sender.CheckState[ANode] := AState;
    if (ANode^.Index >= 0) and (ANode^.Index < Length(FDocumentCache)) then
    begin
      DocumentID := FDocumentCache[ANode^.Index].ID;
      if AState = csCheckedNormal then
        FCheckedDocumentSet.AddOrSetValue(DocumentID, True)
      else
        FCheckedDocumentSet.Remove(DocumentID);
    end;
  end;
begin
  if IsProcessing then Exit;
  IsProcessing := True;
  try
    TargetState := Node^.CheckState;
    Sender.BeginUpdate;
    try
      if (GetKeyState(VK_SHIFT) < 0) and Assigned(FLastCheckedDocNode) then
      begin
        if Sender.AbsoluteIndex(FLastCheckedDocNode) < Sender.AbsoluteIndex(Node) then
        begin
          StartNode := FLastCheckedDocNode;
          EndNode := Node;
        end
        else
        begin
          StartNode := Node;
          EndNode := FLastCheckedDocNode;
        end;
        CurrentNode := StartNode;
        while Assigned(CurrentNode) do
        begin
          if Sender.IsVisible[CurrentNode] then
            ApplyDocCheck(CurrentNode, TargetState);
          if CurrentNode = EndNode then Break;
          CurrentNode := Sender.GetNextVisible(CurrentNode);
        end;
      end
      else
        ApplyDocCheck(Node, TargetState);
    finally
      Sender.EndUpdate;
      FLastCheckedDocNode := Node;
    end;
  finally
    IsProcessing := False;
  end;
end;

function TfrmModalRetrieve.GetSelectedDocumentList(out IsAllSelected: Boolean): TStringDynArray;
var
  Key: String;
  Count: Integer;
begin
  Result := nil;
  Count := 0;
  IsAllSelected := (Length(FDocumentCache) > 0) and (FCheckedDocumentSet.Count = Length(FDocumentCache));
  SetLength(Result, FCheckedDocumentSet.Count);
  if IsAllSelected or (FCheckedDocumentSet.Count = 0) then Exit;
  for Key in FCheckedDocumentSet.Keys do
  begin
    Result[Count] := Key;
    Inc(Count);
  end;
end;

procedure TfrmModalRetrieve.btnDocumentSelectAllClick(Sender: TObject);
var
  i: Integer;
begin
  vstFilterDocument.BeginUpdate;
  try
    for i := 0 to High(FDocumentCache) do
      FCheckedDocumentSet.AddOrSetValue(FDocumentCache[i].ID, True);
    vstFilterDocument.ReinitChildren(nil, True);
  finally
    vstFilterDocument.EndUpdate;
  end;
end;

procedure TfrmModalRetrieve.btnDocumentClearAllClick(Sender: TObject);
var
  i: Integer;
begin
  vstFilterDocument.BeginUpdate;
  try
    for i := 0 to High(FDocumentCache) do
      FCheckedDocumentSet.Remove(FDocumentCache[i].ID);
    vstFilterDocument.ReinitChildren(nil, True);
  finally
    vstFilterDocument.EndUpdate;
  end;
end;

procedure TfrmModalRetrieve.edtSearchDocumentChange(Sender: TObject);
begin
  tmrDocumentSearch.Enabled := False;
  tmrDocumentSearch.Enabled := True;
end;

procedure TfrmModalRetrieve.tmrDocumentSearchTimer(Sender: TObject);
begin
  tmrDocumentSearch.Enabled := False;
  if edtSearchDocument.Text = '' then
  begin
    btnDocumentSelectAll.Caption := 'Select All';
    btnDocumentClearAll.Caption := 'Clear All';
  end
  else
  begin
    btnDocumentSelectAll.Caption := 'Select Filtered';
    btnDocumentClearAll.Caption := 'Clear Filtered';
  end;
  LoadDocument(edtSearchDocument.Text);
end;

procedure TfrmModalRetrieve.LoadAttribute(const Filter: String);
var
  Q: TSQLQuery;
  Count, Capacity: Integer;
begin
  Q := TSQLQuery.Create(nil);
  Q.Database := frmAppBase.conMain;
  try
    Q.SQL.Text := 'SELECT id, name, attribute_key, attribute_type FROM attribute_registry';
    if Filter <> '' then
      Q.SQL.Add(' WHERE name LIKE ' + QuotedStr('%' + Filter + '%'));
    Q.SQL.Add(' ORDER BY name');
    Q.Open;
    Count := 0;
    Capacity := Max(128, Q.RecordCount);
    SetLength(FAttributeCache, Capacity);
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FAttributeCache, Capacity);
      end;
      FAttributeCache[Count].ID := Q.FieldByName('id').AsString;
      FAttributeCache[Count].Name := Q.FieldByName('name').AsString;
      FAttributeCache[Count].Key := Q.FieldByName('attribute_key').AsString;
      FAttributeCache[Count].AttributeType := Q.FieldByName('attribute_type').AsString;
      FAttributeCache[Count].OperatorVal := '';
      FAttributeCache[Count].FilterValue := '';
      Inc(Count);
      Q.Next;
    end;
    SetLength(FAttributeCache, Count);
    vstFilterAttribute.BeginUpdate;
    try
      vstFilterAttribute.Clear;
      vstFilterAttribute.RootNodeCount := Count;
      vstFilterAttribute.Invalidate;
    finally
      vstFilterAttribute.EndUpdate;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmModalRetrieve.vstFilterAttributeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Index: Integer;
  Op: String;
begin
  Index := Node^.Index;
  if (Index < 0) or (Index >= Length(FAttributeCache)) then Exit;
  case Column of
    0: CellText := FAttributeCache[Index].Name;
    1: CellText := FAttributeCache[Index].OperatorVal;
    2: begin
         Op := FAttributeCache[Index].OperatorVal;
         if (Op = 'Is Empty') or (Op = 'Is Not Empty') then
           CellText := '-'
         else
           CellText := StringReplace(FAttributeCache[Index].FilterValue, '|', ' to ', []);
       end;
  end;
end;

procedure TfrmModalRetrieve.vstFilterAttributePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
begin
  TargetCanvas.Font.Color := clWindowText;
end;

procedure TfrmModalRetrieve.vstFilterAttributeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
var
  Index: Integer;
begin
  Index := Node^.Index;
  if (Index >= 0) and (Index < Length(FAttributeCache)) then
  begin
    case Column of
      0: HintText := TAppFormat.FormatUIHint(FAttributeCache[Index].Name);
      1: HintText := TAppFormat.FormatUIHint(FAttributeCache[Index].OperatorVal);
      2: HintText := TAppFormat.FormatUIHint(StringReplace(FAttributeCache[Index].FilterValue, '|', ' to ', []));
    end;
  end;
end;

procedure TfrmModalRetrieve.vstFilterAttributeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if Assigned(Node) and (Node^.Index < Cardinal(Length(FAttributeCache))) and (vsSelected in Node^.States) then
  begin
    FCurrentAttributeIndex := Node^.Index;
    LoadAttributeDefinitionPane(FCurrentAttributeIndex);
  end
  else if Sender.SelectedCount = 0 then
  begin
    FCurrentAttributeIndex := -1;
    pnlAttributeDefinition.Visible := False;
  end;
end;

procedure TfrmModalRetrieve.vstFilterAttributeHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
var
  i, j, Col: Integer;
  Temp: TAttributeCache;
  Swap, HasFilterI, HasFilterJ: Boolean;
begin
  if HitInfo.Column < 0 then Exit;
  Col := HitInfo.Column;
  if FAttributeSortColumn = Col then
    FAttributeSortAscending := not FAttributeSortAscending
  else
  begin
    FAttributeSortColumn := Col;
    FAttributeSortAscending := True;
  end;
  Sender.SortColumn := Col;
  if FAttributeSortAscending then Sender.SortDirection := sdAscending
  else Sender.SortDirection := sdDescending;
  for i := 0 to High(FAttributeCache) - 1 do
  begin
    for j := i + 1 to High(FAttributeCache) do
    begin
      Swap := False;
      if Col = 0 then
      begin
        if FAttributeSortAscending then Swap := AnsiCompareText(FAttributeCache[i].Name, FAttributeCache[j].Name) > 0
        else Swap := AnsiCompareText(FAttributeCache[i].Name, FAttributeCache[j].Name) < 0;
      end
      else
      begin
        HasFilterI := FAttributeCache[i].OperatorVal <> '';
        HasFilterJ := FAttributeCache[j].OperatorVal <> '';
        if HasFilterI <> HasFilterJ then
          Swap := HasFilterJ and not HasFilterI
        else if FAttributeSortAscending then Swap := AnsiCompareText(FAttributeCache[i].Name, FAttributeCache[j].Name) > 0
        else Swap := AnsiCompareText(FAttributeCache[i].Name, FAttributeCache[j].Name) < 0;
      end;
      if Swap then
      begin
        Temp := FAttributeCache[i];
        FAttributeCache[i] := FAttributeCache[j];
        FAttributeCache[j] := Temp;
      end;
    end;
  end;
  vstFilterAttribute.ClearSelection;
  FCurrentAttributeIndex := -1;
  pnlAttributeDefinition.Visible := False;
  vstFilterAttribute.Invalidate;
end;

procedure TfrmModalRetrieve.LoadAttributeDefinitionPane(NodeIndex: Integer);
var
  SavedValue, SafeValueFirst, SafeValueSecond: String;
  PipePos: Integer;
  FmtSettings: TFormatSettings;
  DummyDate: TDateTime;
begin
  FmtSettings := DefaultFormatSettings;
  FmtSettings.DateSeparator := '-';
  FmtSettings.ShortDateFormat := 'yyyy-mm-dd';
  pnlAttributeDefinition.Visible := True;
  UpdateAttributeOperator(FAttributeCache[NodeIndex].AttributeType);
  SavedValue := FAttributeCache[NodeIndex].FilterValue;
  if FAttributeCache[NodeIndex].OperatorVal <> '' then
    cmbAttributeOperator.ItemIndex := cmbAttributeOperator.Items.IndexOf(FAttributeCache[NodeIndex].OperatorVal);
  cmbAttributeOperatorChange(nil);
  if pnlValueText.Visible then
  begin
    edtValueText.Text := SavedValue;
    edtValueText.SetFocus;
  end
  else if pnlValueNumeric.Visible then
  begin
    PipePos := Pos('|', SavedValue);
    if (cmbAttributeOperator.Text = 'Between') and (PipePos > 0) then
    begin
      SafeValueFirst := StringReplace(Copy(SavedValue, 1, PipePos - 1), '.', DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
      SafeValueSecond := StringReplace(Copy(SavedValue, PipePos + 1, MaxInt), '.', DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
      fseValueNumeric.Value := StrToFloatDef(SafeValueFirst, 0);
      fseValueNumericEnd.Value := StrToFloatDef(SafeValueSecond, 0);
    end
    else
    begin
      SafeValueFirst := StringReplace(SavedValue, '.', DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
      fseValueNumeric.Value := StrToFloatDef(SafeValueFirst, 0);
      fseValueNumericEnd.Value := 0;
    end;
    fseValueNumeric.SetFocus;
  end
  else if pnlValueDate.Visible then
  begin
    PipePos := Pos('|', SavedValue);
    if (cmbAttributeOperator.Text = 'Between') and (PipePos > 0) then
    begin
      if TryStrToDate(Copy(SavedValue, 1, PipePos - 1), DummyDate, FmtSettings) then deValueDate.Date := DummyDate else deValueDate.Date := Date;
      if TryStrToDate(Copy(SavedValue, PipePos + 1, MaxInt), DummyDate, FmtSettings) then deValueDateEnd.Date := DummyDate else deValueDateEnd.Date := Date;
    end
    else
    begin
      if TryStrToDate(SavedValue, DummyDate, FmtSettings) then deValueDate.Date := DummyDate else deValueDate.Date := Date;
      deValueDateEnd.Date := Date;
    end;
    deValueDate.SetFocus;
  end
  else if pnlValueCategorical.Visible then
  begin
    cmbValueCategorical.Text := SavedValue;
    cmbValueCategorical.SetFocus;
  end;
end;

procedure TfrmModalRetrieve.UpdateAttributeOperator(const AttributeType: String);
var
  TypeIndex: Integer;
begin
  cmbAttributeOperator.Items.BeginUpdate;
  try
    cmbAttributeOperator.Items.Clear;
    TypeIndex := IndexStr(AttributeType, ['Text', 'Numeric', 'Date-Time', 'Categorical', 'URL or Path']);
    pnlValueText.Visible := (TypeIndex = 0) or (TypeIndex = 4);
    pnlValueNumeric.Visible := (TypeIndex = 1);
    pnlValueDate.Visible := (TypeIndex = 2);
    pnlValueCategorical.Visible := (TypeIndex = 3);
    fseValueNumericEnd.Visible := False;
    deValueDateEnd.Visible := False;
    if pnlValueDate.Visible then
    begin
      deValueDate.Date := Date;
      deValueDateEnd.Date := Date;
    end;
    case TypeIndex of
      0, 4:
        begin
          cmbAttributeOperator.Items.Add('Equals');
          cmbAttributeOperator.Items.Add('Does Not Equal');
          cmbAttributeOperator.Items.Add('Contains');
          cmbAttributeOperator.Items.Add('Does Not Contain');
          cmbAttributeOperator.Items.Add('Starts With');
          cmbAttributeOperator.Items.Add('Ends With');
        end;
      1:
        begin
          cmbAttributeOperator.Items.Add('Equals');
          cmbAttributeOperator.Items.Add('Does Not Equal');
          cmbAttributeOperator.Items.Add('Greater Than');
          cmbAttributeOperator.Items.Add('Less Than');
          cmbAttributeOperator.Items.Add('Greater or Equal');
          cmbAttributeOperator.Items.Add('Less or Equal');
          cmbAttributeOperator.Items.Add('Between');
        end;
      2:
        begin
          cmbAttributeOperator.Items.Add('On');
          cmbAttributeOperator.Items.Add('Not On');
          cmbAttributeOperator.Items.Add('After');
          cmbAttributeOperator.Items.Add('Before');
          cmbAttributeOperator.Items.Add('On or After');
          cmbAttributeOperator.Items.Add('On or Before');
          cmbAttributeOperator.Items.Add('Between');
        end;
      3:
        begin
          cmbAttributeOperator.Items.Add('Equals');
          cmbAttributeOperator.Items.Add('Does Not Equal');
          LoadCategoricalValue;
        end;
    end;
    cmbAttributeOperator.Items.Add('Is Empty');
    cmbAttributeOperator.Items.Add('Is Not Empty');
    cmbAttributeOperator.ItemIndex := 0;
  finally
    cmbAttributeOperator.Items.EndUpdate;
  end;
end;

procedure TfrmModalRetrieve.LoadCategoricalValue;
var
  Q: TSQLQuery;
  ColumnName: String;
begin
  if FCurrentAttributeIndex = -1 then Exit;
  cmbValueCategorical.Items.Clear;
  ColumnName := FAttributeCache[FCurrentAttributeIndex].Key;
  Q := TSQLQuery.Create(nil);
  Q.Database := frmAppBase.conMain;
  try
    Q.SQL.Text := 'SELECT DISTINCT ' + ColumnName + ' FROM document_attributes WHERE ' + ColumnName + ' IS NOT NULL ORDER BY ' + ColumnName;
    Q.Open;
    while not Q.EOF do
    begin
      cmbValueCategorical.Items.Add(Q.Fields[0].AsString);
      Q.Next;
    end;
    if cmbValueCategorical.Items.Count > 0 then cmbValueCategorical.ItemIndex := 0;
  finally
    Q.Free;
  end;
end;

procedure TfrmModalRetrieve.cmbAttributeOperatorChange(Sender: TObject);
var
  Op: String;
begin
  Op := cmbAttributeOperator.Text;
  pnlValueInput.Visible := (Op <> 'Is Empty') and (Op <> 'Is Not Empty');
  fseValueNumericEnd.Visible := (pnlValueNumeric.Visible) and (Op = 'Between');
  deValueDateEnd.Visible := (pnlValueDate.Visible) and (Op = 'Between');
end;

procedure TfrmModalRetrieve.btnAttributeFilterApplyClick(Sender: TObject);
var
  CurrentValue, Op: String;
begin
  if FCurrentAttributeIndex = -1 then Exit;
  Op := cmbAttributeOperator.Text;
  if (Op = 'Is Empty') or (Op = 'Is Not Empty') then
    CurrentValue := ''
  else if pnlValueText.Visible then
    CurrentValue := Trim(edtValueText.Text)
  else if pnlValueNumeric.Visible then
  begin
    CurrentValue := FloatToStr(fseValueNumeric.Value);
    if Op = 'Between' then
      CurrentValue := CurrentValue + '|' + FloatToStr(fseValueNumericEnd.Value);
  end
  else if pnlValueDate.Visible then
  begin
    CurrentValue := FormatDateTime('yyyy"-"mm"-"dd', deValueDate.Date);
    if Op = 'Between' then
      CurrentValue := CurrentValue + '|' + FormatDateTime('yyyy"-"mm"-"dd', deValueDateEnd.Date);
  end
  else if pnlValueCategorical.Visible then
    CurrentValue := Trim(cmbValueCategorical.Text);
  if ((Op <> 'Is Empty') and (Op <> 'Is Not Empty')) and (CurrentValue = '') then
  begin
    MessageDlg('Validation Error', 'Please provide a value for the filter, or select the "Is Empty"/"Is Not Empty" operator if you wish to find unassigned records.', mtWarning, [mbOK], 0);
    Exit;
  end;
  FAttributeCache[FCurrentAttributeIndex].OperatorVal := Op;
  FAttributeCache[FCurrentAttributeIndex].FilterValue := CurrentValue;
  vstFilterAttribute.InvalidateNode(vstFilterAttribute.FocusedNode);
  lblStatus.Caption := 'Filter applied for ' + FAttributeCache[FCurrentAttributeIndex].Name;
end;

procedure TfrmModalRetrieve.btnAttributeFilterClearClick(Sender: TObject);
begin
  if FCurrentAttributeIndex = -1 then Exit;
  FAttributeCache[FCurrentAttributeIndex].OperatorVal := '';
  FAttributeCache[FCurrentAttributeIndex].FilterValue := '';
  vstFilterAttribute.InvalidateNode(vstFilterAttribute.FocusedNode);
  edtValueText.Clear;
  fseValueNumeric.Value := 0;
  fseValueNumericEnd.Value := 0;
  fseValueNumericEnd.Visible := False;
  deValueDate.Date := Date;
  deValueDateEnd.Date := Date;
  deValueDateEnd.Visible := False;
  if cmbValueCategorical.Items.Count > 0 then
    cmbValueCategorical.ItemIndex := 0;
  cmbAttributeOperator.ItemIndex := 0;
  lblStatus.Caption := 'Filter removed.';
end;

procedure TfrmModalRetrieve.btnAttributeClearAllClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to High(FAttributeCache) do
  begin
    FAttributeCache[i].OperatorVal := '';
    FAttributeCache[i].FilterValue := '';
  end;
  vstFilterAttribute.Invalidate;
  edtValueText.Clear;
  fseValueNumeric.Value := 0;
  fseValueNumericEnd.Value := 0;
  fseValueNumericEnd.Visible := False;
  deValueDate.Date := Date;
  deValueDateEnd.Date := Date;
  deValueDateEnd.Visible := False;
  if cmbValueCategorical.Items.Count > 0 then
    cmbValueCategorical.ItemIndex := 0;
  if cmbAttributeOperator.Items.Count > 0 then
    cmbAttributeOperator.ItemIndex := 0;
  lblStatus.Caption := 'All attribute filters cleared.';
end;

function TfrmModalRetrieve.GetAttributeSQL: String;
var
  i, PipePos: Integer;
  AttributeString, Linker, Condition, ColumnName, OpSelection, AttributeValue, OpStr: String;
begin
  Result := '';
  if Length(FAttributeCache) = 0 then Exit;
  if rgLogicMode.ItemIndex = 0 then Linker := ' AND ' else Linker := ' OR ';
  AttributeString := '';
  for i := 0 to High(FAttributeCache) do
  begin
    if FAttributeCache[i].OperatorVal = '' then Continue;
    ColumnName := FAttributeCache[i].Key;
    OpSelection := FAttributeCache[i].OperatorVal;
    AttributeValue := FAttributeCache[i].FilterValue;
    AttributeValue := StringReplace(AttributeValue, ',', '.', [rfReplaceAll]);
    Condition := '';
    if OpSelection = 'Is Empty' then
      Condition := '(json_extract(da.attributes, ''$.' + ColumnName + ''') IS NULL OR CAST(json_extract(da.attributes, ''$.' + ColumnName + ''') AS TEXT) = '''')'
    else if OpSelection = 'Is Not Empty' then
      Condition := '(json_extract(da.attributes, ''$.' + ColumnName + ''') IS NOT NULL AND CAST(json_extract(da.attributes, ''$.' + ColumnName + ''') AS TEXT) <> '''')'
    else if AttributeValue <> '' then
    begin
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
        Condition := '(json_extract(da.attributes, ''$.' + ColumnName + ''') ' + OpStr + ' OR json_extract(da.attributes, ''$.' + ColumnName + ''') IS NULL)'
      else
        Condition := 'json_extract(da.attributes, ''$.' + ColumnName + ''') ' + OpStr;
    end;
    if Condition <> '' then
    begin
      if AttributeString <> '' then AttributeString := AttributeString + Linker;
      AttributeString := AttributeString + Condition;
    end;
  end;
  if AttributeString <> '' then
    Result := ' AND (' + AttributeString + ')';
end;

procedure TfrmModalRetrieve.ApplyAttributeFilter(const Filter: String);
var
  SearchTerm: String;
  Node: PVirtualNode;
  NodeMatches: Boolean;
begin
  SearchTerm := LowerCase(Trim(Filter));
  vstFilterAttribute.BeginUpdate;
  try
    Node := vstFilterAttribute.GetFirst;
    while Assigned(Node) do
    begin
      if (Node^.Index < Cardinal(Length(FAttributeCache))) then
      begin
        NodeMatches := (Filter = '') or (Pos(SearchTerm, LowerCase(FAttributeCache[Node^.Index].Name)) > 0);
        vstFilterAttribute.IsVisible[Node] := NodeMatches;
      end;
      Node := vstFilterAttribute.GetNext(Node);
    end;
  finally
    vstFilterAttribute.EndUpdate;
  end;
end;

procedure TfrmModalRetrieve.edtSearchAttributeChange(Sender: TObject);
begin
  tmrAttributeSearch.Enabled := False;
  tmrAttributeSearch.Enabled := True;
end;

procedure TfrmModalRetrieve.tmrAttributeSearchTimer(Sender: TObject);
begin
  tmrAttributeSearch.Enabled := False;
  ApplyAttributeFilter(edtSearchAttribute.Text);
end;

function TfrmModalRetrieve.BuildSQL(CodeAll, DocumentAll: Boolean): String;
var
  AttributeStr, ExtraSelect, OrderClause: String;
  FieldArr: TStringDynArray;
  i: Integer;
  S1, O1, S2, O2, S3, O3: String;
  JoinStr: String;
  function GetSortSQL(Field, Order: String): String;
  var 
    AttributeName, ColumnName: String;
  begin
    Result := '';
    if (Field = '') or (Field = '(None)') then Exit;
    if Field = 'Document Name' then Result := 'd.title ' + Order
    else if Field = 'Code' then Result := 'cd.name ' + Order
    else if Field = 'Segment' then Result := 'SUBSTR(d.content, co.start_position + 1, co.length) ' + Order
    else if StartsText('Attribute: ', Field) then
    begin
      AttributeName := Copy(Field, 12, MaxInt);
      frmAppBase.qryUtil.Close;
      frmAppBase.qryUtil.SQL.Text := 'SELECT attribute_key FROM attribute_registry WHERE name = :n';
      frmAppBase.qryUtil.Params.ParamByName('n').AsString := AttributeName;
      frmAppBase.qryUtil.Open;
      if not frmAppBase.qryUtil.EOF then
        ColumnName := frmAppBase.qryUtil.Fields[0].AsString
      else
        ColumnName := '';
      frmAppBase.qryUtil.Close;
      if ColumnName <> '' then
        Result := '(SELECT json_extract(attributes, ''$.' + ColumnName + ''') FROM document_attributes WHERE document_id = d.id) ' + Order;
    end;
  end;
  procedure AppendSort(var Clause: String; Field, Order: String);
  var Part: String;
  begin
    Part := GetSortSQL(Field, Order);
    if Part <> '' then
    begin
      if Clause <> '' then Clause := Clause + ', ';
      Clause := Clause + Part;
    end;
  end;
begin
  AttributeStr := GetAttributeSQL;
  JoinStr := '';
  if not CodeAll then
    JoinStr := JoinStr + ' JOIN temp_codes tc ON co.code_id = tc.id ';
  if not DocumentAll then
    JoinStr := JoinStr + ' JOIN temp_docs td ON co.document_id = td.id ';
  if AttributeStr <> '' then
    JoinStr := JoinStr + ' LEFT JOIN document_attributes da ON co.document_id = da.document_id ';
  ExtraSelect := '';
  FieldArr := GetExportFieldList;
  for i := 0 to High(FieldArr) do
  begin
    if StartsText('Attribute: ', FieldArr[i]) then
    begin
      frmAppBase.qryUtil.Close;
      frmAppBase.qryUtil.SQL.Text := 'SELECT attribute_key FROM attribute_registry WHERE name = :n';
      frmAppBase.qryUtil.Params.ParamByName('n').AsString := Copy(FieldArr[i], 12, MaxInt);
      frmAppBase.qryUtil.Open;
      if not frmAppBase.qryUtil.EOF then
        ExtraSelect := ExtraSelect + ', (SELECT json_extract(attributes, ''$.' + frmAppBase.qryUtil.Fields[0].AsString + ''') FROM document_attributes WHERE document_id = d.id) AS "' + StringReplace(FieldArr[i], '"', '""', [rfReplaceAll]) + '"';
      frmAppBase.qryUtil.Close;
    end;
  end;
  GetSortConfig(S1, O1, S2, O2, S3, O3);
  OrderClause := '';
  if S1 <> '(None)' then AppendSort(OrderClause, S1, IfThen(O1='Descending', 'DESC', 'ASC'));
  if S2 <> '(None)' then AppendSort(OrderClause, S2, IfThen(O2='Descending', 'DESC', 'ASC'));
  if S3 <> '(None)' then AppendSort(OrderClause, S3, IfThen(O3='Descending', 'DESC', 'ASC'));
  if OrderClause = '' then OrderClause := 'd.title ASC, co.start_position ASC';
  Result := 'SELECT d.id AS document_id, d.title, d.content, co.code_id, ' +
             'cd.color, co.start_position, co.length' + ExtraSelect + ' ' +
             'FROM codings co ' +
             'JOIN documents d ON co.document_id = d.id ' +
             'JOIN codes cd ON co.code_id = cd.id ' +
             JoinStr +
             'WHERE 1=1 ' + AttributeStr +
             ' ORDER BY ' + OrderClause;
end;

procedure TfrmModalRetrieve.GetSortConfig(out S1, O1, S2, O2, S3, O3: String);
begin
  S1 := ''; O1 := ''; S2 := ''; O2 := ''; S3 := ''; O3 := '';
  if cmbSort1.ItemIndex > 0 then begin S1 := cmbSort1.Text; O1 := cmbOrder1.Text; end;
  if cmbSort2.ItemIndex > 0 then begin S2 := cmbSort2.Text; O2 := cmbOrder2.Text; end;
  if cmbSort3.ItemIndex > 0 then begin S3 := cmbSort3.Text; O3 := cmbOrder3.Text; end;
end;

function TfrmModalRetrieve.GetSortDescription: String;
var
  S1, O1, S2, O2, S3, O3: String;
  function CleanFieldName(const FieldName: String): String;
  begin
    if Copy(FieldName, 1, 11) = 'Attribute: ' then
      Result := Copy(FieldName, 12, MaxInt)
    else
      Result := FieldName;
  end;
begin
  GetSortConfig(S1, O1, S2, O2, S3, O3);
  Result := '';
  if (S1 <> '') and (S1 <> '(None)') then 
    Result := CleanFieldName(S1) + ' (' + O1 + ')';
  if (S2 <> '') and (S2 <> '(None)') then 
    Result := Result + ', then by ' + CleanFieldName(S2) + ' (' + O2 + ')';
  if (S3 <> '') and (S3 <> '(None)') then 
    Result := Result + ', then by ' + CleanFieldName(S3) + ' (' + O3 + ')';
  if Result = '' then 
    Result := 'Default (Document Name, then Segment Position)';
end;

function TfrmModalRetrieve.GetExportFieldList: TStringDynArray;
var
  i: Integer;
begin
  Result := nil;
  SetLength(Result, lbxSelected.Items.Count);
  for i := 0 to lbxSelected.Items.Count - 1 do
    Result[i] := lbxSelected.Items[i];
end;

procedure TfrmModalRetrieve.btnResetClick(Sender: TObject);
begin
  edtSearchCode.Text := '';
  edtSearchDocument.Text := '';
  edtSearchAttribute.Text := '';
  ApplyCodeFilter('');
  ApplyAttributeFilter('');
  LoadDocument(''); 
  btnCodeClearAllClick(nil);
  btnDocumentClearAllClick(nil);
  btnAttributeClearAllClick(nil);
  vstFilterAttribute.ClearSelection;
  FCurrentAttributeIndex := -1;
  pnlAttributeDefinition.Visible := False;
  SetLength(FResultCache, 0);
  vstResult.BeginUpdate;
  try
    vstResult.Clear;
    vstResult.RootNodeCount := 0;
  finally
    vstResult.EndUpdate;
  end;
  FLastCheckedNode := nil;
  FLastCheckedDocNode := nil;
  btnExport.Enabled := False;
  lblStatus.Caption := 'Ready';
  pcFilter.ActivePageIndex := 0;
end;

procedure TfrmModalRetrieve.ListBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ListBox: TListBox;
  ItemIndex: Integer;
  NewHint: String;
begin
  ListBox := Sender as TListBox;
  ItemIndex := ListBox.ItemAtPos(Point(X, Y), True);
  if (ItemIndex >= 0) and (ItemIndex < ListBox.Items.Count) then
  begin
    NewHint := TAppFormat.FormatUIHint(ListBox.Items[ItemIndex]);
    if ListBox.Hint <> NewHint then
    begin
      ListBox.Hint := NewHint;
      Application.CancelHint;
    end;
  end
  else
    ListBox.Hint := '';
end;

procedure TfrmModalRetrieve.SearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    if Sender = edtSearchDocument then
    begin
      tmrDocumentSearch.Enabled := False;
      tmrDocumentSearchTimer(nil);
    end
    else if Sender = edtSearchCode then
    begin
      tmrCodeSearch.Enabled := False;
      tmrCodeSearchTimer(nil);
    end
    else if Sender = edtSearchAttribute then
    begin
      tmrAttributeSearch.Enabled := False;
      tmrAttributeSearchTimer(nil);
    end;
    Key := 0;
  end;
end;

procedure TfrmModalRetrieve.btnExecuteClick(Sender: TObject);
var
  Worker: TThreadRetrieveExecution;
  CodeArray, DocumentArray: TStringDynArray;
  CodeAll, DocumentAll: Boolean;
begin
  CodeArray := GetSelectedCodeList(CodeAll);
  DocumentArray := GetSelectedDocumentList(DocumentAll);
  if (not CodeAll and (Length(CodeArray) = 0)) or (not DocumentAll and (Length(DocumentArray) = 0)) then
  begin
    MessageDlg('Empty Scope', 'Please select at least one Code and one Document to retrieve segments.', mtWarning, [mbOK], 0);
    Exit;
  end;
  Worker := TThreadRetrieveExecution.Create(frmAppBase.conMain.DatabaseName);
  try
    Worker.FSQL := BuildSQL(CodeAll, DocumentAll);
    Worker.FCodeArr := CodeArray;
    Worker.FDocumentArr := DocumentArray;
    Worker.FCodeAll := CodeAll;
    Worker.FDocumentAll := DocumentAll;
    Worker.FCodeCacheRef := FCodeCache;
    Worker.Start;
    TfrmDialogProgress.Prepare('Retrieving Segments', 'Initialising...');
    frmDialogProgress.ShowModal;
    if not Worker.Success then
    begin
      MessageDlg('Retrieval Error', 'Failed to retrieve segments: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
      Exit;
    end;
    FResultCache := Worker.FResultCache;
    vstResult.BeginUpdate;
    try
      vstResult.Clear;
      vstResult.RootNodeCount := Length(FResultCache);
      vstResult.Invalidate;
    finally
      vstResult.EndUpdate;
    end;
    btnExport.Enabled := (Length(FResultCache) > 0);
    lblStatus.Caption := Format('Retrieved %d %s.', [Length(FResultCache), TAppFormat.Pluralize(Length(FResultCache), 'segment', 'segments')]);
  finally
    Worker.Free;
  end;
end;

procedure TfrmModalRetrieve.btnExportClick(Sender: TObject);
var
  Worker: TThreadRetrieveExport;
  ExportFieldArray, CodeArray, DocumentArray: TStringDynArray;
  SortDescription: String;
  CodeAll, DocumentAll: Boolean;
  i: Integer;
begin
  if vstResult.RootNodeCount = 0 then
  begin
    MessageDlg('No Data', 'Please perform a retrieval before exporting.', mtInformation, [mbOK], 0);
    Exit;
  end;
  if not dlgExport.Execute then Exit;
  ExportFieldArray := GetExportFieldList;
  SortDescription := GetSortDescription;
  CodeArray := GetSelectedCodeList(CodeAll);
  DocumentArray := GetSelectedDocumentList(DocumentAll);
  if (LowerCase(ExtractFileExt(dlgExport.FileName)) = '.xlsx') or 
     (LowerCase(ExtractFileExt(dlgExport.FileName)) = '.ods') then
  begin
    for i := 0 to High(FResultCache) do
      if FResultCache[i].Length > 32767 then
      begin
        MessageDlg('Data Limit Exceeded', 'Some segments exceed the 32,767 characters per cell limit for spreadsheets.' + sLineBreak + 'Please export as PDF, HTML, CSV, JSON, or XML instead.', mtWarning, [mbOK], 0);
        Exit;
      end;
  end;
  Worker := TThreadRetrieveExport.Create(frmAppBase.conMain.DatabaseName);
  try
    Worker.FSQL := BuildSQL(CodeAll, DocumentAll);
    Worker.FCodeArr := CodeArray;
    Worker.FDocumentArr := DocumentArray;
    Worker.FCodeAll := CodeAll;
    Worker.FDocumentAll := DocumentAll;
    Worker.FFileName := dlgExport.FileName;
    Worker.FExportField := ExportFieldArray;
    Worker.FSortDescription := SortDescription;
    Worker.FCodeCacheRef := FCodeCache;
    pnlFilter.Enabled := False;
    pnlAction.Enabled := False;
    Worker.Start;
    TfrmDialogProgress.Prepare('Exporting Data', 'Initialising...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      lblStatus.Caption := 'Export successful.';
      MessageDlg('Export Successful', 'The data has been exported to:' + sLineBreak + dlgExport.FileName, mtInformation, [mbOK], 0);
    end
    else
    begin
      lblStatus.Caption := 'Export failed.';
      MessageDlg('Export Error', 'Failed to export data: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
    end;
  finally
    pnlFilter.Enabled := True;
    pnlAction.Enabled := True;
    Worker.Free;
  end;
end;

end.

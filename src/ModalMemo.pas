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

unit ModalMemo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Controls, Dialogs, ExtCtrls, Forms, Graphics, StdCtrls, laz.VirtualTrees;

type
  TMemoRecord = record
    ID: String;
    MemoType: String;
    Title: String;
    UpdatedAtRaw: String;
    UpdatedAtLocal: String;
    ReferenceName: String;
    Reference: String;
  end;
  TMemoArray = array of TMemoRecord;

  { TfrmModalMemo }
  TfrmModalMemo = class(TForm)
    btnClearSelection: TButton;
    btnDelete: TButton;
    btnEdit: TButton;
    btnExport: TButton;
    cmbTypeFilter: TComboBox;
    dlgExport: TSaveDialog;
    edtMemoSearch: TEdit;
    lblPreviewTitle: TLabel;
    lblSegmentTitle: TLabel;
    memPreview: TMemo;
    memSegment: TMemo;
    pnlMemoActions: TPanel;
    pnlMemoFilter: TPanel;
    pnlPreviewContainer: TPanel;
    pnlPreviewContent: TPanel;
    pnlPreviewSegment: TPanel;
    pnlTopContainer: TPanel;
    splPreview: TSplitter;
    splPreviewInternal: TSplitter;
    tmrMemoSearch: TTimer;
    vstMemo: TLazVirtualStringTree;
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnClearSelectionClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure cmbTypeFilterChange(Sender: TObject);
    procedure edtMemoSearchChange(Sender: TObject);
    procedure tmrMemoSearchTimer(Sender: TObject);
    procedure vstMemoDblClick(Sender: TObject);
    procedure vstMemoFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure vstMemoGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstMemoHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
    procedure vstMemoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure vstMemoPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
  private
    FMemoData: TMemoArray;
    FSelectedID: String;
    FSelectedTargetID: String;
    FSelectedType: String;
    FSortAscending: Boolean;
    FSortColumn: Integer;
    procedure AutoSizeColumns;
    procedure RefreshMemoList;
    procedure RestoreSelection;
    procedure SortMemo;
    procedure UpdateActionUI;
    procedure UpdatePreviewPane;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmModalMemo: TfrmModalMemo;

implementation

uses
  DateUtils, LCLIntf, LCLType, Math, SysUtils, SQLDB, AppBase, AppFont, AppFormat,
  DialogProgress, ServiceExport, ServiceMemo, ServiceThread;

type
  TThreadLoadMemo = class(TBackgroundWorker)
  public
    FSQL: String;
    FResult: TMemoArray;
    FSortColumn: Integer;
    FSortAsc: Boolean;
  protected
    procedure DoHeavyLifting; override;
  end;

{$R *.lfm}

procedure TThreadLoadMemo.DoHeavyLifting;
  function CompareMemo(const A, B: TMemoRecord): Integer;
  begin
    case FSortColumn of
      0: Result := AnsiCompareText(A.MemoType, B.MemoType);
      1: Result := AnsiCompareText(A.Title, B.Title);
      2: Result := AnsiCompareText(A.UpdatedAtRaw, B.UpdatedAtRaw);
      3: Result := AnsiCompareText(A.ReferenceName, B.ReferenceName);
      else Result := 0;
    end;
    if not FSortAsc then Result := -Result;
  end;
  procedure QuickSort(L, R: Integer);
  var
    I, J: Integer;
    Pivot, Temp: TMemoRecord;
  begin
    if L >= R then Exit;
    I := L;
    J := R;
    Pivot := FResult[L + (R - L) div 2];
    repeat
      while CompareMemo(FResult[I], Pivot) < 0 do Inc(I);
      while CompareMemo(FResult[J], Pivot) > 0 do Dec(J);
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
  UTCDateTime, LocalDateTime: TDateTime;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    SyncUpdateStatus('Loading memos...');
    Q.SQL.Text := FSQL;
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
      FResult[Count].MemoType := Q.FieldByName('memo_type').AsString;
      FResult[Count].Title := Q.FieldByName('title').AsString;
      FResult[Count].UpdatedAtRaw := Q.FieldByName('updated_at').AsString;
      FResult[Count].ReferenceName := Q.FieldByName('ref_name').AsString;
      FResult[Count].Reference := Q.FieldByName('reference').AsString;
      try
        if TryStrToDateTime(FResult[Count].UpdatedAtRaw, UTCDateTime, DefaultFormatSettings) then
        begin
          LocalDateTime := UniversalTimeToLocal(UTCDateTime);
          FResult[Count].UpdatedAtLocal := FormatDateTime('yyyy-mm-dd hh:nn:ss AM/PM', LocalDateTime);
        end
        else
          FResult[Count].UpdatedAtLocal := FResult[Count].UpdatedAtRaw;
      except
        FResult[Count].UpdatedAtLocal := FResult[Count].UpdatedAtRaw;
      end;
      Inc(Count);
      Q.Next;
    end;
    SetLength(FResult, Count);
    if (FSortColumn >= 0) and (Count > 1) then
    begin
      SyncUpdateStatus('Sorting memos...');
      QuickSort(0, High(FResult));
    end;
  finally
    Q.Free;
  end;
end;

constructor TfrmModalMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  vstMemo.NodeDataSize := 0;
  FSortColumn := 2;
  FSortAscending := False;
end;

destructor TfrmModalMemo.Destroy;
begin
  SetLength(FMemoData, 0);
  inherited Destroy;
end;

procedure TfrmModalMemo.AutoSizeColumns;
var
  TotalWidth, FixedWidth: Integer;
begin
  if vstMemo.ClientWidth <= 0 then Exit;
  TotalWidth := vstMemo.ClientWidth;
  vstMemo.Header.Columns[0].Width := MulDiv(120, Self.PixelsPerInch, 96);
  vstMemo.Header.Columns[2].Width := MulDiv(200, Self.PixelsPerInch, 96);
  vstMemo.Header.Columns[3].Width := MulDiv(200, Self.PixelsPerInch, 96);
  FixedWidth := vstMemo.Header.Columns[0].Width + vstMemo.Header.Columns[2].Width + vstMemo.Header.Columns[3].Width;
  if TotalWidth - FixedWidth > 200 then
    vstMemo.Header.Columns[1].Width := TotalWidth - FixedWidth
  else
    vstMemo.Header.Columns[1].Width := 350;
end;

procedure TfrmModalMemo.UpdateActionUI;
var
  HasSelection, IsMulti, IsFiltered: Boolean;
  DelCap, ExpCap: String;
  function CalculateWidth(const S: String): Integer;
  var
    Bmp: TBitmap;
    W: Integer;
  begin
    Bmp := TBitmap.Create;
    try
      Bmp.Canvas.Font.Assign(Self.Font);
      W := Bmp.Canvas.TextWidth(S) + 40;
      Result := ((W - 1) div 50 + 1) * 50;
    finally
      Bmp.Free;
    end;
  end;
begin
  HasSelection := vstMemo.SelectedCount > 0;
  IsMulti := vstMemo.SelectedCount > 1;
  IsFiltered := (cmbTypeFilter.ItemIndex > 0) or (Trim(edtMemoSearch.Text) <> '');
  btnClearSelection.Visible := HasSelection;
  btnEdit.Enabled := HasSelection and not IsMulti;
  btnDelete.Enabled := HasSelection;
  btnExport.Enabled := (vstMemo.RootNodeCount > 0);
  if IsMulti then DelCap := 'Delete Selected Memos' else DelCap := 'Delete Memo';
  if HasSelection then
  begin
    if IsMulti then ExpCap := 'Export Selected Memos'
    else ExpCap := 'Export Selected Memo';
  end
  else if IsFiltered then
  begin
    if vstMemo.RootNodeCount = 1 then ExpCap := 'Export Filtered Memo'
    else ExpCap := 'Export Filtered Memos';
  end
  else
  begin
    if vstMemo.RootNodeCount = 1 then ExpCap := 'Export Memo'
    else ExpCap := 'Export Memos';
  end;
  btnDelete.Caption := DelCap;
  btnDelete.Width := CalculateWidth(DelCap);
  btnExport.Caption := ExpCap;
  btnExport.Width := CalculateWidth(ExpCap);
end;

procedure TfrmModalMemo.SortMemo;
  function CompareMemo(const A, B: TMemoRecord): Integer;
  begin
    case FSortColumn of
      0: Result := AnsiCompareText(A.MemoType, B.MemoType);
      1: Result := AnsiCompareText(A.Title, B.Title);
      2: Result := AnsiCompareText(A.UpdatedAtRaw, B.UpdatedAtRaw);
      3: Result := AnsiCompareText(A.ReferenceName, B.ReferenceName);
      else Result := 0;
    end;
    if not FSortAscending then Result := -Result;
  end;
  procedure QuickSort(L, R: Integer);
  var
    I, J: Integer;
    Pivot, Temp: TMemoRecord;
  begin
    if L >= R then Exit;
    I := L;
    J := R;
    Pivot := FMemoData[L + (R - L) div 2];
    repeat
      while CompareMemo(FMemoData[I], Pivot) < 0 do Inc(I);
      while CompareMemo(FMemoData[J], Pivot) > 0 do Dec(J);
      if I <= J then
      begin
        Temp := FMemoData[I];
        FMemoData[I] := FMemoData[J];
        FMemoData[J] := Temp;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J);
    if I < R then QuickSort(I, R);
  end;
begin
  if (FSortColumn < 0) or (Length(FMemoData) < 2) then Exit;
  QuickSort(0, High(FMemoData));
end;

procedure TfrmModalMemo.RestoreSelection;
var
  Node: PVirtualNode;
begin
  vstMemo.ClearSelection;
  if FSelectedID = '' then Exit;
  Node := vstMemo.GetFirst;
  while Assigned(Node) do
  begin
    if (Node^.Index < Cardinal(Length(FMemoData))) then
    begin
      if FMemoData[Node^.Index].ID = FSelectedID then
      begin
        vstMemo.Selected[Node] := True;
        vstMemo.FocusedNode := Node;
        vstMemo.ScrollIntoView(Node, False);
        Break;
      end;
    end;
    Node := vstMemo.GetNext(Node);
  end;
end;

procedure TfrmModalMemo.RefreshMemoList;
var
  SQL, Filter, TypeClause: String;
  Worker: TThreadLoadMemo;
begin
  if not frmAppBase.conMain.Connected then Exit;
  if frmAppBase.trnMain.Active then frmAppBase.trnMain.Commit;
  TypeClause := '';
  case cmbTypeFilter.ItemIndex of
    1: TypeClause := ' AND m.memo_type = ''Project''';
    2: TypeClause := ' AND m.memo_type = ''Document''';
    3: TypeClause := ' AND m.memo_type = ''Code''';
    4: TypeClause := ' AND m.memo_type = ''Segment''';
    5: TypeClause := ' AND m.memo_type = ''Analytical''';
  end;
  Filter := Trim(edtMemoSearch.Text);
  if Filter <> '' then
    Filter := ' AND (m.title LIKE ' + QuotedStr('%'+Filter+'%') + ' OR m.content LIKE ' + QuotedStr('%'+Filter+'%') + ')';
  SQL := 'SELECT m.id, m.memo_type, m.title, m.updated_at, m.reference, ' +
         'CASE ' +
         '  WHEN m.memo_type = ''Document'' THEN (SELECT title FROM documents WHERE id = m.reference) ' +
         '  WHEN m.memo_type = ''Code'' THEN (SELECT name FROM codes WHERE id = m.reference) ' +
         '  WHEN m.memo_type = ''Segment'' THEN (SELECT title FROM documents WHERE id = SUBSTR(m.reference, 1, INSTR(m.reference, '':'') - 1)) ' +
         '  ELSE ''N/A'' ' +
         'END as ref_name ' +
         'FROM memos m WHERE 1=1' + TypeClause + Filter;
  Worker := TThreadLoadMemo.Create(frmAppBase.conMain.DatabaseName);
  try
    Worker.FSQL := SQL;
    Worker.FSortColumn := FSortColumn;
    Worker.FSortAsc := FSortAscending;
    Worker.Start;
    TfrmDialogProgress.Prepare('Preparing Memo Manager', 'Loading records...');
    frmDialogProgress.ShowModal;
    vstMemo.BeginUpdate;
    try
      vstMemo.Clear;
      if Worker.Success then
      begin
        FMemoData := Worker.FResult;
        vstMemo.RootNodeCount := Length(FMemoData);
        RestoreSelection;
      end
      else
        SetLength(FMemoData, 0);
    finally
      vstMemo.EndUpdate;
    end;
  finally
    Worker.Free;
  end;
  AutoSizeColumns;
  UpdateActionUI;
end;

procedure TfrmModalMemo.UpdatePreviewPane;
var
  LocalQuery: TSQLQuery;
  PartArray: TStringArray;
  DocumentID: String;
  StartPos, LengthByte: Integer;
begin
  memPreview.Clear;
  memSegment.Clear;
  if FSelectedID = '' then
  begin
    pnlPreviewSegment.Visible := False;
    splPreviewInternal.Visible := False;
    lblPreviewTitle.Caption := 'Preview';
    Exit;
  end;
  LocalQuery := TSQLQuery.Create(nil);
  try
    LocalQuery.Database := frmAppBase.conMain;
    if SameText(FSelectedType, 'Segment') then
    begin
      PartArray := FSelectedTargetID.Split([':']);
      if Length(PartArray) = 3 then
      begin
        DocumentID := PartArray[0];
        StartPos := StrToIntDef(PartArray[1], 0);
        LengthByte := StrToIntDef(PartArray[2], 0);
        LocalQuery.SQL.Text := 'SELECT d.title, SUBSTR(d.content, :sp + 1, :len) as seg_text, m.content ' +
                               'FROM memos m JOIN documents d ON d.id = :did WHERE m.id = :mid';
        LocalQuery.Params.ParamByName('sp').AsInteger := StartPos;
        LocalQuery.Params.ParamByName('len').AsInteger := LengthByte;
        LocalQuery.Params.ParamByName('did').AsString := DocumentID;
        LocalQuery.Params.ParamByName('mid').AsString := FSelectedID;
        LocalQuery.Open;
        if not LocalQuery.EOF then
        begin
          lblPreviewTitle.Caption := 'Memo Content';
          lblSegmentTitle.Caption := 'Referenced Segment in: ' + LocalQuery.FieldByName('title').AsString;
          memPreview.Text := LocalQuery.FieldByName('content').AsString;
          memSegment.Text := LocalQuery.FieldByName('seg_text').AsString;
          pnlPreviewSegment.Visible := True;
          splPreviewInternal.Visible := True;
        end;
        LocalQuery.Close;
      end;
    end
    else
    begin
      pnlPreviewSegment.Visible := False;
      splPreviewInternal.Visible := False;
      lblPreviewTitle.Caption := 'Memo Content';
      LocalQuery.SQL.Text := 'SELECT content FROM memos WHERE id = :id';
      LocalQuery.Params.ParamByName('id').AsString := FSelectedID;
      LocalQuery.Open;
      if not LocalQuery.EOF then
        memPreview.Text := LocalQuery.FieldByName('content').AsString;
      LocalQuery.Close;
    end;
  finally
    LocalQuery.Free;
  end;
end;

procedure TfrmModalMemo.vstMemoGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
begin
  if (Node^.Index < Cardinal(Length(FMemoData))) then
  begin
    case Column of
      0: CellText := FMemoData[Node^.Index].MemoType;
      1: CellText := FMemoData[Node^.Index].Title;
      2: CellText := FMemoData[Node^.Index].UpdatedAtLocal;
      3: CellText := FMemoData[Node^.Index].ReferenceName;
    end;
  end;
end;

procedure TfrmModalMemo.vstMemoPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
begin
  TargetCanvas.Font.Color := clWindowText;
end;

procedure TfrmModalMemo.vstMemoHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
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
  SortMemo;
  vstMemo.Invalidate;
  RestoreSelection;
end;

procedure TfrmModalMemo.vstMemoDblClick(Sender: TObject);
var
  P: TPoint;
  HitInfo: THitInfo;
begin
  P := vstMemo.ScreenToClient(Mouse.CursorPos);
  vstMemo.GetHitTestInfoAt(P.X, P.Y, True, HitInfo);
  if Assigned(HitInfo.HitNode) then
    btnEditClick(nil);
end;

procedure TfrmModalMemo.vstMemoFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
begin
  if Assigned(Node) and (Node^.Index < Cardinal(Length(FMemoData))) and (vsSelected in Node^.States) then
  begin
    FSelectedID := FMemoData[Node^.Index].ID;
    FSelectedTargetID := FMemoData[Node^.Index].Reference;
    FSelectedType := FMemoData[Node^.Index].MemoType;
  end
  else if Sender.SelectedCount = 0 then
  begin
    FSelectedID := '';
    FSelectedTargetID := '';
    FSelectedType := '';
  end;
  UpdateActionUI;
  if vstMemo.SelectedCount <= 1 then UpdatePreviewPane;
end;

procedure TfrmModalMemo.vstMemoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  HitInfo: THitInfo;
begin
  if Button = mbLeft then
  begin
    vstMemo.GetHitTestInfoAt(X, Y, True, HitInfo);
    if not Assigned(HitInfo.HitNode) then
    begin
      vstMemo.ClearSelection;
      FSelectedID := '';
      FSelectedTargetID := '';
      FSelectedType := '';
      UpdateActionUI;
      UpdatePreviewPane;
    end;
  end;
end;

procedure TfrmModalMemo.FormShow(Sender: TObject);
begin
  ApplyAppFont(Self);
  FSelectedID := '';
  FSelectedTargetID := '';
  FSortColumn := 2;
  FSortAscending := False;
  cmbTypeFilter.ItemIndex := 0;
  RefreshMemoList;
  UpdatePreviewPane;
end;

procedure TfrmModalMemo.FormResize(Sender: TObject);
begin
  AutoSizeColumns;
end;

procedure TfrmModalMemo.tmrMemoSearchTimer(Sender: TObject);
begin
  tmrMemoSearch.Enabled := False;
  RefreshMemoList;
end;

procedure TfrmModalMemo.cmbTypeFilterChange(Sender: TObject);
begin
  RefreshMemoList;
end;

procedure TfrmModalMemo.edtMemoSearchChange(Sender: TObject);
begin
  tmrMemoSearch.Enabled := False;
  tmrMemoSearch.Enabled := True;
end;

procedure TfrmModalMemo.btnClearSelectionClick(Sender: TObject);
begin
  vstMemo.ClearSelection;
  FSelectedID := '';
  FSelectedTargetID := '';
  FSelectedType := '';
  UpdateActionUI;
  UpdatePreviewPane;
end;

procedure TfrmModalMemo.btnEditClick(Sender: TObject);
begin
  if (FSelectedID = '') or (vstMemo.SelectedCount > 1) then Exit;
  Self.Hide;
  if SameText(FSelectedType, 'Analytical') then
    TServiceMemo.Execute(frmAppBase.conMain, FSelectedType, FSelectedID, '')
  else
    TServiceMemo.Execute(frmAppBase.conMain, FSelectedType, FSelectedTargetID, '');
  Self.Show;
  RefreshMemoList;
  UpdatePreviewPane;
  frmAppBase.RefreshDocumentList;
  frmAppBase.RefreshCodeTree;
  frmAppBase.RefreshDocumentMemos;
end;

procedure TfrmModalMemo.btnDeleteClick(Sender: TObject);
var
  IDList: String;
  Node: PVirtualNode;
begin
  if vstMemo.SelectedCount = 0 then Exit;
  if MessageDlg('Confirm Deletion', Format('Permanently delete %d %s?', [vstMemo.SelectedCount, TAppFormat.Pluralize(vstMemo.SelectedCount, 'memo', 'memos')]), mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    IDList := '';
    Node := vstMemo.GetFirstSelected;
    while Assigned(Node) do
    begin
      if (Node^.Index < Cardinal(Length(FMemoData))) then
      begin
        if IDList <> '' then IDList := IDList + ',';
        IDList := IDList + QuotedStr(FMemoData[Node^.Index].ID);
      end;
      Node := vstMemo.GetNextSelected(Node);
    end;
    if IDList <> '' then
    begin
      if frmAppBase.trnMain.Active then frmAppBase.trnMain.Commit;
      frmAppBase.ExecuteSQLSafe('DELETE FROM memos WHERE id IN (' + IDList + ')');
      FSelectedID := '';
      RefreshMemoList;
      UpdatePreviewPane;
      frmAppBase.RefreshDocumentList;
      frmAppBase.RefreshCodeTree;
      frmAppBase.RefreshDocumentMemos;
    end;
  end;
end;

procedure TfrmModalMemo.btnExportClick(Sender: TObject);
var
  i: Integer;
  IDList: String;
  Node: PVirtualNode;
begin
  if vstMemo.RootNodeCount = 0 then Exit;
  if not dlgExport.Execute then Exit;
  IDList := '';
  if vstMemo.SelectedCount > 0 then
  begin
    Node := vstMemo.GetFirstSelected;
    while Assigned(Node) do
    begin
      if (Node^.Index < Cardinal(Length(FMemoData))) then
      begin
        if IDList <> '' then IDList := IDList + ',';
        IDList := IDList + QuotedStr(FMemoData[Node^.Index].ID);
      end;
      Node := vstMemo.GetNextSelected(Node);
    end;
  end
  else
  begin
    for i := 0 to High(FMemoData) do
    begin
      if IDList <> '' then IDList := IDList + ',';
      IDList := IDList + QuotedStr(FMemoData[i].ID);
    end;
  end;
  if IDList <> '' then
  begin
    if TServiceExport.ExportMemo(frmAppBase.conMain, dlgExport.FileName, IDList) then
      MessageDlg('Export Successful', 'The memos have been exported to:' + sLineBreak + dlgExport.FileName, mtInformation, [mbOK], 0);
  end;
end;

end.
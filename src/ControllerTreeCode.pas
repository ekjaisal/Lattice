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

unit ControllerTreeCode;

{$mode ObjFPC}{$H+}

interface

uses
  ActiveX, Classes, Controls, Dialogs, ExtCtrls, Forms, Generics.Collections, Graphics, LCLType, Math, SysUtils,
  Types, laz.VirtualTrees, ServiceDatabase;

type
  PCodeData = ^TCodeData;
  TCodeData = record
    ID: String;
    Name: String;
    Color: TColor;
    CodingCount: Integer;
    TotalCount: Integer;
    HasMemo: Boolean;
  end;

  TCodeHoverEvent = procedure(CodeName: String; CodeColor: TColor) of object;
  TCodeDoubleClickEvent = procedure(const CodeID: String; CodeColor: TColor) of object;

  TCodeTreeController = class
  private
    FDatabase: TServiceDatabase;
    FIsBatchOperation: Boolean;
    FLastClickedNode: PVirtualNode;
    FLastFilterText: String;
    FOnCodeDoubleClick: TCodeDoubleClickEvent;
    FOnCodeHover: TCodeHoverEvent;
    FOnCodeHoverClear: TNotifyEvent;
    FOnTreeChanged: TNotifyEvent;
    FRestoreFocusID: String;
    FRestoreFocusNode: PVirtualNode;
    FRestoreTopID: String;
    FRestoreTopNode: PVirtualNode;
    FSortField: String;
    FSortOrder: String;
    FTree: TLazVirtualStringTree;
    function GetSortDescription: String;
    function VerifySortLock: Boolean;
    procedure AsyncRefreshTree(Data: PtrInt);
    procedure DoCollapsed(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure DoDblClick(Sender: TObject);
    procedure DoDragAllowed(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean);
    procedure DoDragDrop(Sender: TBaseVirtualTree; Source: TObject; DataObject: IDataObject; Formats: TFormatArray; Shift: TShiftState; const Pt: TPoint; var Effect: DWORD; Mode: TDropMode);
    procedure DoDragOver(Sender: TBaseVirtualTree; Source: TObject; Shift: TShiftState; State: TDragState; const Pt: TPoint; Mode: TDropMode; var Effect: DWORD; var Accept: Boolean);
    procedure DoExpanded(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure DoFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure DoGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: Integer);
    procedure DoGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure DoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DoMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DoMouseLeave(Sender: TObject);
    procedure DoPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
  public
    constructor Create(ATree: TLazVirtualStringTree; ADatabase: TServiceDatabase);
    destructor Destroy; override;
    function GetFocusedNodeData(out CodeID: String; out CodeName: String): Boolean;
    function GetFocusedNodeParentID: String;
    function GetMergeData(out TargetID: String; out TargetName: String; out SourceID: TStringDynArray): Boolean;
    function GetSelectedID: TStringDynArray;
    function GetTargetNodeData(out CodeID: String; out CodeName: String): Boolean;
    function IsBranchFullyCollapsed(Node: PVirtualNode): Boolean;
    function IsBranchFullyExpanded(Node: PVirtualNode): Boolean;
    procedure ApplySort(const AField, AOrder: String);
    procedure FullCollapse(UseTarget: Boolean);
    procedure FullExpand(UseTarget: Boolean);
    procedure LoadData(const AFlatCode: TCodeFlatArray; const FilterText: String);
    procedure NudgeSelected(NudgeType: Integer);
    procedure RefreshTree(const FilterText: String);
    procedure SelectCodeNode(const CodeID: String);
    property OnCodeDoubleClick: TCodeDoubleClickEvent read FOnCodeDoubleClick write FOnCodeDoubleClick;
    property OnCodeHover: TCodeHoverEvent read FOnCodeHover write FOnCodeHover;
    property OnCodeHoverClear: TNotifyEvent read FOnCodeHoverClear write FOnCodeHoverClear;
    property OnTreeChanged: TNotifyEvent read FOnTreeChanged write FOnTreeChanged;
    property SortDescription: String read GetSortDescription;
    property SortField: String read FSortField;
    property SortOrder: String read FSortOrder;
  end;

implementation

function GetNodeHeight(ANode: PVirtualNode): Integer;
var
  Child: PVirtualNode;
  MaxChildHeight: Integer;
begin
  Result := 0;
  if (ANode = nil) or (ANode^.ChildCount = 0) then Exit;
  MaxChildHeight := 0;
  Child := ANode^.FirstChild;
  while Child <> nil do
  begin
    MaxChildHeight := Max(MaxChildHeight, 1 + GetNodeHeight(Child));
    Child := Child^.NextSibling;
  end;
  Result := MaxChildHeight;
end;

constructor TCodeTreeController.Create(ATree: TLazVirtualStringTree; ADatabase: TServiceDatabase);
begin
  inherited Create;
  FTree := ATree;
  FDatabase := ADatabase;
  FLastFilterText := '';
  FSortField := 'sort_order';
  FSortOrder := 'ASC';
  FIsBatchOperation := False;
  FTree.NodeDataSize := SizeOf(TCodeData);
  FTree.AutoExpandDelay := 1000;
  FTree.OnGetText := @DoGetText;
  FTree.OnFreeNode := @DoFreeNode;
  FTree.OnGetImageIndex := @DoGetImageIndex;
  FTree.OnPaintText := @DoPaintText;
  FTree.OnExpanded := @DoExpanded;
  FTree.OnCollapsed := @DoCollapsed;
  FTree.OnDragAllowed := @DoDragAllowed;
  FTree.OnDragOver := @DoDragOver;
  FTree.OnDragDrop := @DoDragDrop;
  FTree.OnDblClick := @DoDblClick;
  FTree.OnMouseDown := @DoMouseDown;
  FTree.OnMouseMove := @DoMouseMove;
  FTree.OnMouseLeave := @DoMouseLeave;
end;

destructor TCodeTreeController.Destroy;
begin
  inherited Destroy;
end;

procedure TCodeTreeController.LoadData(const AFlatCode: TCodeFlatArray; const FilterText: String);
var
  ChildMap: specialize TDictionary<String, specialize TList<Integer>>;
  RootCodeList: specialize TList<Integer>;
  i: Integer;
  ChildList: specialize TList<Integer>;
  function AddNodeRecursive(ParentNode: PVirtualNode; CodeIndex: Integer): Integer;
  var
    NewNode: PVirtualNode;
    NodeData: PCodeData;
    ChildTotal, c: Integer;
    ChildList: specialize TList<Integer>;
  begin
    NewNode := FTree.AddChild(ParentNode);
    NodeData := FTree.GetNodeData(NewNode);
    NodeData^.ID := AFlatCode[CodeIndex].ID;
    NodeData^.Name := AFlatCode[CodeIndex].Name;
    NodeData^.Color := TColor(AFlatCode[CodeIndex].Color);
    NodeData^.CodingCount := AFlatCode[CodeIndex].UsageCount;
    NodeData^.HasMemo := AFlatCode[CodeIndex].HasMemo;
    if NodeData^.ID = FRestoreFocusID then FRestoreFocusNode := NewNode;
    if NodeData^.ID = FRestoreTopID then FRestoreTopNode := NewNode;
    ChildTotal := 0;
    if ChildMap.TryGetValue(NodeData^.ID, ChildList) then
    begin
      for c := 0 to ChildList.Count - 1 do
        ChildTotal := ChildTotal + AddNodeRecursive(NewNode, ChildList[c]);
    end;
    NodeData^.TotalCount := NodeData^.CodingCount + ChildTotal;
    if FilterText = '' then FTree.Expanded[NewNode] := AFlatCode[CodeIndex].IsExpanded;
    Result := NodeData^.TotalCount;
  end;
begin
  FLastFilterText := FilterText;
  FRestoreFocusID := '';
  FRestoreTopID := '';
  FRestoreFocusNode := nil;
  FRestoreTopNode := nil;
  if Assigned(FTree.FocusedNode) then
  begin
    if Assigned(FTree.GetNodeData(FTree.FocusedNode)) then
      FRestoreFocusID := PCodeData(FTree.GetNodeData(FTree.FocusedNode))^.ID;
  end;
  if Assigned(FTree.TopNode) then
  begin
    if Assigned(FTree.GetNodeData(FTree.TopNode)) then
      FRestoreTopID := PCodeData(FTree.GetNodeData(FTree.TopNode))^.ID;
  end;
  FIsBatchOperation := True;
  FTree.BeginUpdate;
  ChildMap := specialize TDictionary<String, specialize TList<Integer>>.Create;
  RootCodeList := specialize TList<Integer>.Create;
  try
    for i := Low(AFlatCode) to High(AFlatCode) do
    begin
      if AFlatCode[i].ParentID = '' then
        RootCodeList.Add(i)
      else
      begin
        if not ChildMap.TryGetValue(AFlatCode[i].ParentID, ChildList) then
        begin
          ChildList := specialize TList<Integer>.Create;
          ChildMap.Add(AFlatCode[i].ParentID, ChildList);
        end;
        ChildList.Add(i);
      end;
    end;
    FTree.Clear;
    for i := 0 to RootCodeList.Count - 1 do
      AddNodeRecursive(nil, RootCodeList[i]);
    if FilterText <> '' then FTree.FullExpand(nil);
  finally
    for ChildList in ChildMap.Values do ChildList.Free;
    ChildMap.Free;
    RootCodeList.Free;
    FIsBatchOperation := False;
    FTree.EndUpdate;
  end;
  if Assigned(FRestoreFocusNode) then
  begin
    FTree.Selected[FRestoreFocusNode] := True;
    FTree.FocusedNode := FRestoreFocusNode;
  end;
  if Assigned(FRestoreTopNode) then
    FTree.TopNode := FRestoreTopNode
  else if Assigned(FRestoreFocusNode) then
    FTree.ScrollIntoView(FRestoreFocusNode, True);
end;

procedure TCodeTreeController.RefreshTree(const FilterText: String);
begin
  LoadData(FDatabase.GetAllCodeFlat(FilterText, FSortField, FSortOrder), FilterText);
end;

procedure TCodeTreeController.AsyncRefreshTree(Data: PtrInt);
begin
  if Assigned(FOnTreeChanged) then FOnTreeChanged(Self);
end;

function TCodeTreeController.VerifySortLock: Boolean;
begin
  Result := FSortField <> 'sort_order';
  if Result then
    MessageDlg('Action Locked', 'Structural changes to the code tree are not allowed when a custom sort is active.' + sLineBreak + sLineBreak + 'To release the lock, either reset the sort or make the current order permanent.', mtInformation, [mbOK], 0);
end;

procedure TCodeTreeController.ApplySort(const AField, AOrder: String);
begin
  FSortField := AField;
  FSortOrder := AOrder;
  RefreshTree(FLastFilterText);
end;

function TCodeTreeController.GetSortDescription: String;
begin
  if FSortField = 'sort_order' then Exit('Default Order');
  if FSortField = 'usage_cnt' then Result := 'Coding Count'
  else if FSortField = 'created_at' then Result := 'Creation Time'
  else Result := 'Code Name';
  if FSortOrder = 'ASC' then Result := Result + ' (Ascending)'
  else Result := Result + ' (Descending)';
end;

procedure TCodeTreeController.SelectCodeNode(const CodeID: String);
var
  Node: PVirtualNode;
  Data: PCodeData;
begin
  Node := FTree.GetFirst;
  while Assigned(Node) do
  begin
    Data := FTree.GetNodeData(Node);
    if (Assigned(Data)) and (Data^.ID = CodeID) then
    begin
      FTree.Selected[Node] := True;
      FTree.FocusedNode := Node;
      FTree.ScrollIntoView(Node, True);
      FTree.SetFocus;
      Break;
    end;
    Node := FTree.GetNext(Node);
  end;
end;

function TCodeTreeController.GetFocusedNodeData(out CodeID: String; out CodeName: String): Boolean;
var Data: PCodeData;
begin
  Result := False;
  if FTree.FocusedNode <> nil then
  begin
    Data := FTree.GetNodeData(FTree.FocusedNode);
    if Assigned(Data) then
    begin
      CodeID := Data^.ID;
      CodeName := Data^.Name;
      Result := True;
    end;
  end;
end;

function TCodeTreeController.GetTargetNodeData(out CodeID: String; out CodeName: String): Boolean;
var Data: PCodeData;
begin
  Result := False;
  if FLastClickedNode <> nil then
  begin
    Data := FTree.GetNodeData(FLastClickedNode);
    if Assigned(Data) then
    begin
      CodeID := Data^.ID;
      CodeName := Data^.Name;
      Result := True;
    end;
  end;
end;

function TCodeTreeController.GetFocusedNodeParentID: String;
begin
  Result := '';
  if (FTree.FocusedNode <> nil) and (FTree.FocusedNode^.Parent <> nil) and (FTree.FocusedNode^.Parent <> FTree.RootNode) then
    Result := PCodeData(FTree.GetNodeData(FTree.FocusedNode^.Parent))^.ID;
end;

function TCodeTreeController.GetSelectedID: TStringDynArray;
var
  i, Count: Integer;
  Node: PVirtualNode;
begin
  Result := nil;
  Count := FTree.SelectedCount;
  if Count = 0 then Exit;
  SetLength(Result, Count);
  i := 0;
  Node := FTree.GetFirstSelected;
  while Assigned(Node) and (i < Count) do
  begin
    Result[i] := PCodeData(FTree.GetNodeData(Node))^.ID;
    Inc(i);
    Node := FTree.GetNextSelected(Node);
  end;
  SetLength(Result, i);
end;

function TCodeTreeController.GetMergeData(out TargetID: String; out TargetName: String; out SourceID: TStringDynArray): Boolean;
var
  TargetNode: PVirtualNode;
  Data: PCodeData;
  NodeArray: TNodeArray;
  i: Integer;
begin
  Result := False;
  if FLastClickedNode <> nil then TargetNode := FLastClickedNode else TargetNode := FTree.FocusedNode;
  if TargetNode = nil then Exit;
  Data := FTree.GetNodeData(TargetNode);
  TargetID := Data^.ID;
  TargetName := Data^.Name;
  NodeArray := FTree.GetSortedSelection(False);
  if Length(NodeArray) < 2 then Exit;
  SetLength(SourceID, 0);
  for i := 0 to High(NodeArray) do
  begin
    if (NodeArray[i] = nil) or (NodeArray[i] = TargetNode) then Continue;
    if FTree.HasAsParent(TargetNode, NodeArray[i]) then
    begin
      MessageDlg('Invalid Action', 'Merging a parent code to its sub-code is not allowed.', mtInformation, [mbOK], 0);
      SetLength(SourceID, 0);
      Exit(False);
    end;
    SetLength(SourceID, Length(SourceID) + 1);
    SourceID[High(SourceID)] := PCodeData(FTree.GetNodeData(NodeArray[i]))^.ID;
  end;
  Result := True;
end;

procedure TCodeTreeController.NudgeSelected(NudgeType: Integer);
var
  NodeArray: TNodeArray;
  FirstNode, LastNode, TargetNode: PVirtualNode;
  SourceID: TStringDynArray;
  i: Integer;
  TargetID: String;
  TargetData, SourceData: PCodeData;
  DropModeInt: Integer;
begin
  if VerifySortLock then Exit;
  NodeArray := FTree.GetSortedSelection(False);
  if Length(NodeArray) = 0 then Exit;
  FirstNode := NodeArray[0];
  LastNode := NodeArray[High(NodeArray)];
  TargetNode := nil;
  DropModeInt := -1;
  case NudgeType of
    0:
      begin
        TargetNode := FirstNode^.PrevSibling;
        while (TargetNode <> nil) and (vsSelected in TargetNode^.States) do
          TargetNode := TargetNode^.PrevSibling;
        if TargetNode = nil then Exit;
        DropModeInt := 1;
      end;
    1:
      begin
        TargetNode := LastNode^.NextSibling;
        while (TargetNode <> nil) and (vsSelected in TargetNode^.States) do
          TargetNode := TargetNode^.NextSibling;
        if TargetNode = nil then Exit;
        DropModeInt := 2;
      end;
    2:
      begin
        TargetNode := FirstNode^.Parent;
        if (TargetNode = nil) or (TargetNode = FTree.RootNode) then Exit;
        DropModeInt := 2;
      end;
    3:
      begin
        TargetNode := FirstNode^.PrevSibling;
        while (TargetNode <> nil) and (vsSelected in TargetNode^.States) do
          TargetNode := TargetNode^.PrevSibling;
        if TargetNode = nil then Exit;
        DropModeInt := 0;
      end;
  end;
  if TargetNode = nil then Exit;
  TargetData := FTree.GetNodeData(TargetNode);
  TargetID := TargetData^.ID;
  SetLength(SourceID, Length(NodeArray));
  for i := 0 to High(NodeArray) do
  begin
    SourceData := FTree.GetNodeData(NodeArray[i]);
    SourceID[i] := SourceData^.ID;
    if (NudgeType = 3) and (FTree.GetNodeLevel(NodeArray[i]) + 1 + GetNodeHeight(NodeArray[i]) > 5) then
    begin
      MessageDlg('Code Hierarchy Overshoot', 'The code tree hierarchy is limited to six levels. This action is not allowed as it would overshoot the limit.', mtInformation, [mbOK], 0);
      Exit;
    end;
  end;
  try
    FDatabase.MoveCode(TargetID, SourceID, DropModeInt);
    if DropModeInt = 0 then FDatabase.SetCodeExpandedState(TargetID, True, False);
    if Assigned(FOnTreeChanged) then Application.QueueAsyncCall(@AsyncRefreshTree, 0);
  except
    on E: Exception do MessageDlg('Database Error', 'Move failed: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TCodeTreeController.FullExpand(UseTarget: Boolean);
var TargetID: String;
begin
  FIsBatchOperation := True;
  try
    if not UseTarget or (FLastClickedNode = nil) then
    begin
      FTree.FullExpand(nil);
      FDatabase.SetCodeExpandedState('', True, True);
    end
    else
    begin
      TargetID := PCodeData(FTree.GetNodeData(FLastClickedNode))^.ID;
      FTree.FullExpand(FLastClickedNode);
      FDatabase.SetCodeExpandedState(TargetID, True, True);
    end;
  finally
    FIsBatchOperation := False;
  end;
end;

procedure TCodeTreeController.FullCollapse(UseTarget: Boolean);
var TargetID: String;
begin
  FIsBatchOperation := True;
  try
    if not UseTarget or (FLastClickedNode = nil) then
    begin
      FTree.FullCollapse(nil);
      FDatabase.SetCodeExpandedState('', False, True);
    end
    else
    begin
      TargetID := PCodeData(FTree.GetNodeData(FLastClickedNode))^.ID;
      FTree.FullCollapse(FLastClickedNode);
      FDatabase.SetCodeExpandedState(TargetID, False, True);
    end;
  finally
    FIsBatchOperation := False;
  end;
end;

function TCodeTreeController.IsBranchFullyExpanded(Node: PVirtualNode): Boolean;
var Child: PVirtualNode;
begin
  Result := True;
  if not (vsExpanded in Node^.States) then Exit(False);
  Child := Node^.FirstChild;
  while Assigned(Child) do
  begin
    if (Child^.ChildCount > 0) and not IsBranchFullyExpanded(Child) then Exit(False);
    Child := Child^.NextSibling;
  end;
end;

function TCodeTreeController.IsBranchFullyCollapsed(Node: PVirtualNode): Boolean;
var
  Child: PVirtualNode;
begin
  Result := True;
  if (vsExpanded in Node^.States) and (Node^.ChildCount > 0) then Exit(False);
  Child := Node^.FirstChild;
  while Assigned(Child) do
  begin
    if (Child^.ChildCount > 0) and not IsBranchFullyCollapsed(Child) then Exit(False);
    Child := Child^.NextSibling;
  end;
end;

procedure TCodeTreeController.DoGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var Data: PCodeData;
begin
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) then Exit;
  case Column of
    0: CellText := Data^.Name;
    1: begin
         if Data^.TotalCount > Data^.CodingCount then
           CellText := Format('%d (%d)', [Data^.CodingCount, Data^.TotalCount])
         else
           CellText := IntToStr(Data^.CodingCount);
       end;
  end;
end;

procedure TCodeTreeController.DoGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: Integer);
begin
  if (Kind = ikNormal) or (Kind = ikSelected) then
  begin
    if Column = 0 then ImageIndex := 1 else ImageIndex := -1;
  end;
end;

procedure TCodeTreeController.DoPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
var Data: PCodeData;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) and (Column = 0) then 
  begin
    TargetCanvas.Font.Color := Data^.Color;
    if Data^.HasMemo then
      TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsUnderline]
    else
      TargetCanvas.Font.Style := TargetCanvas.Font.Style - [fsUnderline];
  end;
end;

procedure TCodeTreeController.DoFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var Data: PCodeData;
begin
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) then Finalize(Data^);
end;

procedure TCodeTreeController.DoExpanded(Sender: TBaseVirtualTree; Node: PVirtualNode);
var Data: PCodeData;
begin
  if FIsBatchOperation then Exit;
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) and (Data^.ID <> '') then FDatabase.SetCodeExpandedState(Data^.ID, True, False);
end;

procedure TCodeTreeController.DoCollapsed(Sender: TBaseVirtualTree; Node: PVirtualNode);
var Data: PCodeData;
begin
  if FIsBatchOperation then Exit;
  Data := Sender.GetNodeData(Node);
  if Assigned(Data) and (Data^.ID <> '') then FDatabase.SetCodeExpandedState(Data^.ID, False, False);
end;

procedure TCodeTreeController.DoDragAllowed(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var Allowed: Boolean);
begin
  Allowed := True;
end;

procedure TCodeTreeController.DoDragOver(Sender: TBaseVirtualTree; Source: TObject; Shift: TShiftState; State: TDragState; const Pt: TPoint; Mode: TDropMode; var Effect: DWORD; var Accept: Boolean);
begin
  Accept := False;
  if Source = FTree then 
    Accept := True;
end;

procedure TCodeTreeController.DoDragDrop(Sender: TBaseVirtualTree; Source: TObject; DataObject: IDataObject; Formats: TFormatArray; Shift: TShiftState; const Pt: TPoint; var Effect: DWORD; Mode: TDropMode);
var
  SourceNode, TargetNode: PVirtualNode;
  TargetData, SourceData: PCodeData;
  SourceNodeID, TargetID, ExistingID, TargetParentID: String;
  SourceName: String;
  NewParentLevel, i, DropModeInt: Integer;
  NodeArray: TNodeArray;
  SourceID: TStringDynArray;
  IsRealMove: Boolean;
begin
  TargetNode := Sender.DropTargetNode;
  NodeArray := Sender.GetSortedSelection(False);
  if Length(NodeArray) = 0 then Exit;
  IsRealMove := False;
  for i := 0 to High(NodeArray) do
  begin
    if (NodeArray[i] <> nil) and (NodeArray[i] <> TargetNode) then
    begin
      IsRealMove := True;
      Break;
    end;
  end;
  if not IsRealMove then 
  begin
    Effect := DROPEFFECT_NONE;
    Exit;
  end;
  if VerifySortLock then
  begin
    Effect := DROPEFFECT_NONE;
    Exit;
  end;
  TargetID := '';
  NewParentLevel := -1;
  DropModeInt := 0;
  if TargetNode <> nil then
  begin
    TargetData := Sender.GetNodeData(TargetNode);
    if Mode = dmOnNode then
    begin
      DropModeInt := 0;
      if Assigned(TargetData) then TargetID := TargetData^.ID;
      NewParentLevel := Sender.GetNodeLevel(TargetNode);
    end
    else
    begin
      if Mode = dmAbove then DropModeInt := 1 else DropModeInt := 2;
      if Assigned(TargetData) then TargetID := TargetData^.ID;
      if TargetNode^.Parent = Sender.RootNode then
      begin
        TargetParentID := '';
        NewParentLevel := -1;
      end
      else
      begin
        TargetData := Sender.GetNodeData(TargetNode^.Parent);
        if Assigned(TargetData) then TargetParentID := TargetData^.ID;
        NewParentLevel := Sender.GetNodeLevel(TargetNode^.Parent);
      end;
    end;
  end;
  SetLength(SourceID, 0);
  for i := 0 to High(NodeArray) do
  begin
    SourceNode := NodeArray[i];
    if (SourceNode = nil) or (SourceNode = TargetNode) then Continue;
    if (TargetNode <> nil) and Sender.HasAsParent(TargetNode, SourceNode) then
    begin
      MessageDlg('Invalid Action', 'You cannot move a parent code into its own sub-codes.', mtError, [mbOK], 0);
      Continue;
    end;
    if (NewParentLevel + 1 + GetNodeHeight(SourceNode) > 5) then
    begin
      MessageDlg('Code Hierarchy Overshoot', 'The code tree hierarchy is limited to six levels. This action is not allowed as it would overshoot the limit.', mtInformation, [mbOK], 0);
      Continue;
    end;
    SourceData := Sender.GetNodeData(SourceNode);
    SourceNodeID := SourceData^.ID;
    SourceName := FDatabase.GetCodeName(SourceNodeID);
    if DropModeInt = 0 then
    begin
      if FDatabase.CodeExists(SourceName, TargetID, ExistingID) then Continue;
    end
    else
    begin
      if FDatabase.CodeExists(SourceName, TargetParentID, ExistingID) then Continue;
    end;
    SetLength(SourceID, Length(SourceID) + 1);
    SourceID[High(SourceID)] := SourceNodeID;
  end;
  Effect := DROPEFFECT_NONE;
  if Length(SourceID) > 0 then
  begin
    try
      FDatabase.MoveCode(TargetID, SourceID, DropModeInt);
      if (DropModeInt = 0) and (TargetID <> '') then
        FDatabase.SetCodeExpandedState(TargetID, True, False);
      if Assigned(FOnTreeChanged) then
        Application.QueueAsyncCall(@AsyncRefreshTree, 0);
    except
      on E: Exception do MessageDlg('Database Error', 'The move operation failed: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TCodeTreeController.DoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var HitInfo: THitInfo;
begin
  FTree.GetHitTestInfoAt(X, Y, True, HitInfo);
  if (HitInfo.HitNode <> nil) and (not ([hiOnItemLabel, hiOnNormalIcon, hiOnStateIcon] * HitInfo.HitPositions <> [])) then
    HitInfo.HitNode := nil;
  if Button = mbRight then FLastClickedNode := HitInfo.HitNode;
  if (Button = mbLeft) and (HitInfo.HitNode = nil) then
  begin
    FTree.ClearSelection;
    FTree.FocusedNode := nil;
  end;
end;

procedure TCodeTreeController.DoMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var HoverNode: PVirtualNode; Data: PCodeData;
begin
  HoverNode := FTree.GetNodeAt(X, Y);
  if Assigned(HoverNode) then
  begin
    Data := FTree.GetNodeData(HoverNode);
    if Assigned(Data) and Assigned(FOnCodeHover) then
      FOnCodeHover(Data^.Name, Data^.Color);
  end
  else if Assigned(FOnCodeHoverClear) then
    FOnCodeHoverClear(Self);
end;

procedure TCodeTreeController.DoMouseLeave(Sender: TObject);
begin
  if Assigned(FOnCodeHoverClear) then
    FOnCodeHoverClear(Self);
end;

procedure TCodeTreeController.DoDblClick(Sender: TObject);
var Node: PVirtualNode; Data: PCodeData;
begin
  Node := FTree.FocusedNode;
  if not Assigned(Node) then Exit;
  Data := FTree.GetNodeData(Node);
  if Assigned(Data) and Assigned(FOnCodeDoubleClick) then
    FOnCodeDoubleClick(Data^.ID, Data^.Color);
end;

end.
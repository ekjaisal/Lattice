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

unit ControllerTreeDocument;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Controls, Graphics, LCLType, StrUtils, SysUtils, Types,
  laz.VirtualTrees, ServiceDatabase;

type
  TDocumentSelectEvent = procedure(const DocumentID: String) of object;

  TDocumentTreeController = class
  private
    FDatabase: TServiceDatabase;
    FDocumentCache: TDocumentCacheArray;
    FFilterDefinition: TDocumentFilterDefinition;
    FOnDocumentSelect: TDocumentSelectEvent;
    FOnUIStateChange: TNotifyEvent;
    FSortCriteria: String;
    FSortField: String;
    FSortIsAttribute: Boolean;
    FSortOrder: String;
    FTree: TLazVirtualStringTree;
    function GetDocumentCount: Integer;
    function GetSortDescription: String;
    procedure DoFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure DoGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: Integer);
    procedure DoGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure DoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DoPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
  public
    constructor Create(ATree: TLazVirtualStringTree; ADatabase: TServiceDatabase);
    destructor Destroy; override;
    function GetFallbackSelectionID: String;
    function GetSelectedID: TStringDynArray;
    function HasNextDocument: Boolean;
    function HasPreviousDocument: Boolean;
    procedure ApplyFilter(const ATitlePattern, ABodyTextQuery, AAttributeSQL, AAttributeID, AAttributeOperator, AAttributeValue: String);
    procedure ApplySearch(const AText: String);
    procedure ApplySort(const ACriteria, AField, AOrder: String; AIsAttribute: Boolean);
    procedure ClearFilter;
    procedure ClearSelection;
    procedure LoadData(const ACache: TDocumentCacheArray; const KeepSelectionID: String = ''; CenterSelection: Boolean = False);
    procedure LoadSortPreference;
    procedure RefreshTree(const KeepSelectionID: String = ''; CenterSelection: Boolean = False);
    procedure SaveSortPreference;
    procedure SelectDocumentByID(const DocumentID: String);
    procedure SelectNextDocument;
    procedure SelectPreviousDocument;
    procedure UpdateSelectedNodeTitle(const ANewTitle: String);
    property DocumentCount: Integer read GetDocumentCount;
    property FilterDefinition: TDocumentFilterDefinition read FFilterDefinition;
    property OnDocumentSelect: TDocumentSelectEvent read FOnDocumentSelect write FOnDocumentSelect;
    property OnUIStateChange: TNotifyEvent read FOnUIStateChange write FOnUIStateChange;
    property SortCriteria: String read FSortCriteria;
    property SortDescription: String read GetSortDescription;
    property SortField: String read FSortField;
    property SortOrder: String read FSortOrder;
  end;

implementation

constructor TDocumentTreeController.Create(ATree: TLazVirtualStringTree; ADatabase: TServiceDatabase);
begin
  inherited Create;
  FTree := ATree;
  FDatabase := ADatabase;
  FFilterDefinition.IsFilterActive := False;
  FFilterDefinition.QuickSearchText := '';
  FFilterDefinition.TitlePattern := '';
  FFilterDefinition.BodyTextQuery := '';
  FFilterDefinition.AttributeSQL := '';
  FSortField := 'id';
  FSortOrder := 'ASC';
  FSortCriteria := 'Default';
  FSortIsAttribute := False;
  FTree.NodeDataSize := 0;
  FTree.OnGetText := @DoGetText;
  FTree.OnGetImageIndex := @DoGetImageIndex;
  FTree.OnPaintText := @DoPaintText;
  FTree.OnFocusChanged := @DoFocusChanged;
  FTree.OnMouseDown := @DoMouseDown;
end;

destructor TDocumentTreeController.Destroy;
begin
  SetLength(FDocumentCache, 0);
  inherited Destroy;
end;

procedure TDocumentTreeController.LoadSortPreference;
begin
  FSortField := FDatabase.GetUserPreference('DocumentSortField', 'id');
  FSortOrder := FDatabase.GetUserPreference('DocumentSortOrder', 'ASC');
  FSortCriteria := FDatabase.GetUserPreference('DocumentSortCriteria', 'Default');
  FSortIsAttribute := StrToBoolDef(FDatabase.GetUserPreference('DocumentSortIsAttribute', 'False'), False);
end;

procedure TDocumentTreeController.SaveSortPreference;
begin
  FDatabase.SaveUserPreference('DocumentSortField', FSortField);
  FDatabase.SaveUserPreference('DocumentSortOrder', FSortOrder);
  FDatabase.SaveUserPreference('DocumentSortCriteria', FSortCriteria);
  FDatabase.SaveUserPreference('DocumentSortIsAttribute', BoolToStr(FSortIsAttribute, True));
end;

procedure TDocumentTreeController.RefreshTree(const KeepSelectionID: String = ''; CenterSelection: Boolean = False);
begin
  LoadData(FDatabase.GetDocumentData(FFilterDefinition, FSortField, FSortOrder, FSortIsAttribute), KeepSelectionID, CenterSelection);
end;

procedure TDocumentTreeController.LoadData(const ACache: TDocumentCacheArray; const KeepSelectionID: String = ''; CenterSelection: Boolean = False);
var
  FoundIndex, i: Integer;
  TargetNode: PVirtualNode;
  SavedOffsetY: Integer;
begin
  SavedOffsetY := FTree.OffsetY;
  FDocumentCache := ACache;
  FTree.BeginUpdate;
  try
    FTree.Clear;
    FTree.RootNodeCount := Length(FDocumentCache);
    FoundIndex := -1;
    if KeepSelectionID <> '' then
    begin
      for i := Low(FDocumentCache) to High(FDocumentCache) do
        if FDocumentCache[i].ID = KeepSelectionID then
        begin
          FoundIndex := i;
          Break;
        end;
    end;
    if FoundIndex >= 0 then
    begin
      TargetNode := FTree.GetFirst;
      for i := 1 to FoundIndex do
        if Assigned(TargetNode) then TargetNode := TargetNode^.NextSibling;
      if Assigned(TargetNode) then
      begin
        FTree.Selected[TargetNode] := True;
        FTree.FocusedNode := TargetNode;
        if CenterSelection then
          FTree.ScrollIntoView(TargetNode, True);
      end;
    end
    else
    begin
      FTree.ClearSelection;
      if Length(FDocumentCache) > 0 then
      begin
        TargetNode := FTree.GetFirst;
        if Assigned(TargetNode) then
        begin
          FTree.Selected[TargetNode] := True;
          FTree.FocusedNode := TargetNode;
          if Assigned(FOnDocumentSelect) then FOnDocumentSelect(FDocumentCache[0].ID);
        end;
      end
      else
        if Assigned(FOnDocumentSelect) then FOnDocumentSelect('');
    end;
  finally
    FTree.EndUpdate;
  end;
  if not CenterSelection then
    FTree.OffsetY := SavedOffsetY;
  if Assigned(FOnUIStateChange) then FOnUIStateChange(Self);
end;

function TDocumentTreeController.GetFallbackSelectionID: String;
var
  Node, FallbackNode: PVirtualNode;
begin
  Result := '';
  Node := FTree.GetFirstSelected;
  if not Assigned(Node) then Exit;
  FallbackNode := FTree.GetNextVisible(Node);
  while Assigned(FallbackNode) and (vsSelected in FallbackNode^.States) do
    FallbackNode := FTree.GetNextVisible(FallbackNode);
  if not Assigned(FallbackNode) then
  begin
    FallbackNode := FTree.GetPreviousVisible(Node);
    while Assigned(FallbackNode) and (vsSelected in FallbackNode^.States) do
      FallbackNode := FTree.GetPreviousVisible(FallbackNode);
  end;
  if Assigned(FallbackNode) and (FallbackNode^.Index >= 0) and (FallbackNode^.Index < Length(FDocumentCache)) then
    Result := FDocumentCache[FallbackNode^.Index].ID;
end;

procedure TDocumentTreeController.UpdateSelectedNodeTitle(const ANewTitle: String);
var
  Node: PVirtualNode;
begin
  Node := FTree.GetFirstSelected;
  if Assigned(Node) and (Node^.Index < Cardinal(Length(FDocumentCache))) then
  begin
    FDocumentCache[Node^.Index].Title := ANewTitle;
    FTree.InvalidateNode(Node);
  end;
end;

procedure TDocumentTreeController.DoGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
begin
  if (Node^.Index < Cardinal(Length(FDocumentCache))) then
  begin
    case Column of
      0: CellText := FDocumentCache[Node^.Index].Title;
      1: CellText := IntToStr(FDocumentCache[Node^.Index].CodingCount);
    end;
  end;
end;

procedure TDocumentTreeController.DoGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: Integer);
begin
  if (Kind = ikNormal) or (Kind = ikSelected) then
  begin
    if Column = 0 then ImageIndex := 0 else ImageIndex := -1;
  end;
end;

procedure TDocumentTreeController.DoPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
begin
  if (Node^.Index < Cardinal(Length(FDocumentCache))) then
  begin
    if (Column = 0) and FDocumentCache[Node^.Index].HasMemo then
      TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsUnderline]
    else
      TargetCanvas.Font.Style := TargetCanvas.Font.Style - [fsUnderline];
  end;
end;

procedure TDocumentTreeController.DoFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
begin
  if Assigned(Node) and Assigned(FOnDocumentSelect) then
  begin
    if (Node^.Index < Cardinal(Length(FDocumentCache))) then
      FOnDocumentSelect(FDocumentCache[Node^.Index].ID);
  end;
end;

procedure TDocumentTreeController.DoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  HitInfo: THitInfo;
begin
  FTree.GetHitTestInfoAt(X, Y, True, HitInfo);
  if (HitInfo.HitNode <> nil) and (not ([hiOnItemLabel, hiOnNormalIcon, hiOnStateIcon] * HitInfo.HitPositions <> [])) then
    HitInfo.HitNode := nil;
  if (Button = mbLeft) and (HitInfo.HitNode = nil) then
  begin
    FTree.ClearSelection;
    FTree.FocusedNode := nil;
  end;
end;

function TDocumentTreeController.GetSelectedID: TStringDynArray;
var
  i, Count: Integer;
  Node: PVirtualNode;
begin
  Count := FTree.SelectedCount;
  SetLength(Result, Count);
  if Count = 0 then Exit;
  i := 0;
  Node := FTree.GetFirstSelected;
  while Assigned(Node) and (i < Count) do
  begin
    if (Node^.Index < Cardinal(Length(FDocumentCache))) then
    begin
      Result[i] := FDocumentCache[Node^.Index].ID;
      Inc(i);
    end;
    Node := FTree.GetNextSelected(Node);
  end;
  SetLength(Result, i);
end;

procedure TDocumentTreeController.ClearSelection;
begin
  FTree.ClearSelection;
  FTree.FocusedNode := nil;
end;

procedure TDocumentTreeController.SelectDocumentByID(const DocumentID: String);
var
  Node: PVirtualNode;
begin
  Node := FTree.GetFirst;
  while Assigned(Node) do
  begin
    if (Node^.Index < Cardinal(Length(FDocumentCache))) then
    begin
      if FDocumentCache[Node^.Index].ID = DocumentID then
      begin
        FTree.Selected[Node] := True;
        FTree.FocusedNode := Node;
        FTree.ScrollIntoView(Node, False);
        Break;
      end;
    end;
    Node := FTree.GetNext(Node);
  end;
end;

procedure TDocumentTreeController.SelectNextDocument;
var
  NextNode: PVirtualNode;
begin
  if Assigned(FTree.FocusedNode) then
  begin
    NextNode := FTree.FocusedNode^.NextSibling;
    if Assigned(NextNode) then
    begin
      FTree.ClearSelection;
      FTree.Selected[NextNode] := True;
      FTree.FocusedNode := NextNode;
      FTree.ScrollIntoView(NextNode, False);
      FTree.SetFocus;
    end;
  end;
end;

procedure TDocumentTreeController.SelectPreviousDocument;
var
  PreviousNode: PVirtualNode;
begin
  if Assigned(FTree.FocusedNode) then
  begin
    PreviousNode := FTree.FocusedNode^.PrevSibling;
    if Assigned(PreviousNode) then
    begin
      FTree.ClearSelection;
      FTree.Selected[PreviousNode] := True;
      FTree.FocusedNode := PreviousNode;
      FTree.ScrollIntoView(PreviousNode, False);
      FTree.SetFocus;
    end;
  end;
end;

procedure TDocumentTreeController.ApplySearch(const AText: String);
begin
  FFilterDefinition.QuickSearchText := Trim(AText);
  RefreshTree;
end;

procedure TDocumentTreeController.ApplyFilter(const ATitlePattern, ABodyTextQuery, AAttributeSQL, AAttributeID, AAttributeOperator, AAttributeValue: String);
begin
  FFilterDefinition.IsFilterActive := True;
  FFilterDefinition.TitlePattern := Trim(ATitlePattern);
  FFilterDefinition.BodyTextQuery := Trim(ABodyTextQuery);
  FFilterDefinition.AttributeSQL := AAttributeSQL;
  FFilterDefinition.AttributeID := AAttributeID;
  FFilterDefinition.AttributeOperator := AAttributeOperator;
  FFilterDefinition.AttributeValue := AAttributeValue;
  RefreshTree;
end;

procedure TDocumentTreeController.ClearFilter;
begin
  FFilterDefinition.IsFilterActive := False;
  FFilterDefinition.TitlePattern := '';
  FFilterDefinition.BodyTextQuery := '';
  FFilterDefinition.AttributeSQL := '';
  FFilterDefinition.AttributeID := '';
  FFilterDefinition.AttributeOperator := '';
  FFilterDefinition.AttributeValue := '';
  RefreshTree;
end;

procedure TDocumentTreeController.ApplySort(const ACriteria, AField, AOrder: String; AIsAttribute: Boolean);
begin
  FSortCriteria := ACriteria;
  FSortField := AField;
  FSortOrder := AOrder;
  FSortIsAttribute := AIsAttribute;
  SaveSortPreference;
  RefreshTree;
end;

function TDocumentTreeController.GetSortDescription: String;
var DetailedOrder, SortTypeSuffix: String;
begin
  if SameText(FSortField, 'id') and SameText(FSortOrder, 'ASC') then Exit('Sorted by Default');
  if FSortCriteria = 'Coding Count' then
    DetailedOrder := IfThen(FSortOrder = 'ASC', 'Smallest to Largest', 'Largest to Smallest')
  else if FSortCriteria = 'Segment Memo Count' then
    DetailedOrder := IfThen(FSortOrder = 'ASC', 'Smallest to Largest', 'Largest to Smallest')
  else if FSortCriteria = 'Import Time' then
    DetailedOrder := IfThen(FSortOrder = 'ASC', 'Oldest to Newest', 'Newest to Oldest')
  else if FSortIsAttribute then
  begin
    SortTypeSuffix := FDatabase.GetAttributeType(FSortField);
    if SortTypeSuffix = 'Numeric' then DetailedOrder := IfThen(FSortOrder = 'ASC', 'Smallest to Largest', 'Largest to Smallest')
    else if SortTypeSuffix = 'Date-Time' then DetailedOrder := IfThen(FSortOrder = 'ASC', 'Oldest to Newest', 'Newest to Oldest')
    else DetailedOrder := IfThen(FSortOrder = 'ASC', 'A to Z', 'Z to A');
  end
  else DetailedOrder := IfThen(FSortOrder = 'ASC', 'A to Z', 'Z to A');
  Result := 'Sorted by ' + FSortCriteria + ' (' + DetailedOrder + ')';
end;

function TDocumentTreeController.GetDocumentCount: Integer;
begin
  Result := Length(FDocumentCache);
end;

function TDocumentTreeController.HasNextDocument: Boolean;
begin
  Result := False;
  if Assigned(FTree.FocusedNode) then
    Result := Assigned(FTree.FocusedNode^.NextSibling);
end;

function TDocumentTreeController.HasPreviousDocument: Boolean;
begin
  Result := False;
  if Assigned(FTree.FocusedNode) then
    Result := Assigned(FTree.FocusedNode^.PrevSibling);
end;

end.
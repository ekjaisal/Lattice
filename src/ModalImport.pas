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

unit ModalImport;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Controls, ExtCtrls, Forms, Graphics, StdCtrls, SQLite3Conn, laz.VirtualTrees;

type
  TMapTarget = (mtSkip, mtDocumentName, mtDocumentText, mtAttribute);

  TColumnMap = class
    SourceColumn: String;
    AttributeMode: Integer; 
    AttributeName: String;
    AttributeType: String;
    MapType: TMapTarget;
  end;

  TfrmModalImport = class(TForm)
    btnApply: TButton;
    btnCancel: TButton;
    btnImport: TButton;
    cmbAttributeMode: TComboBox;
    cmbExistingAttribute: TComboBox;
    cmbNewAttributeType: TComboBox;
    cmbTargetType: TComboBox;
    edtNewAttributeName: TEdit;
    lblAttributeMode: TLabel;
    lblExistingAttribute: TLabel;
    lblInstructions: TLabel;
    lblNewAttributeName: TLabel;
    lblNewAttributeType: TLabel;
    lblTargetType: TLabel;
    pnlActions: TPanel;
    pnlAttributeSettings: TPanel;
    pnlLeft: TPanel;
    pnlMap: TPanel;
    pnlRight: TPanel;
    splSplitter: TSplitter;
    vstMapping: TLazVirtualStringTree;
    procedure btnApplyClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure cmbAttributeModeChange(Sender: TObject);
    procedure cmbTargetTypeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure vstMappingFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure vstMappingGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstMappingPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
  private
    FConnection: TSQLite3Connection;
    FExistingAttribute: TStringList;
    FMapping: TList;
    FUpdating: Boolean;
    procedure LoadExistingAttributes;
    procedure UpdateRightPanel;
  public
    function Execute(AConnection: TSQLite3Connection; AColumn: TStrings): Boolean;
    function GetMapping(Index: Integer): TColumnMap;
  end;

var
  frmModalImport: TfrmModalImport;

implementation

uses
  Dialogs, SysUtils, SQLDB, AppFont;

{$R *.lfm}

procedure TfrmModalImport.FormCreate(Sender: TObject);
begin
  ApplyAppFont(Self);
  FMapping := TList.Create;
  FExistingAttribute := TStringList.Create;
  FUpdating := False;
end;

procedure TfrmModalImport.FormDestroy(Sender: TObject);
var i: Integer;
begin
  if Assigned(FMapping) then
  begin
    for i := 0 to FMapping.Count - 1 do
      if Assigned(FMapping[i]) then TColumnMap(FMapping[i]).Free;
    FMapping.Free;
  end;
  FExistingAttribute.Free;
end;

procedure TfrmModalImport.FormShow(Sender: TObject);
begin
  ApplyAppFont(Self);
  UpdateRightPanel;
end;

procedure TfrmModalImport.LoadExistingAttributes;
var
  Query: TSQLQuery;
begin
  FExistingAttribute.Clear;
  cmbExistingAttribute.Items.Clear;
  if not Assigned(FConnection) then Exit;
  Query := TSQLQuery.Create(nil);
  try
    Query.Database := FConnection;
    Query.Transaction := FConnection.Transaction;
    Query.SQL.Text := 'SELECT name, attribute_type FROM attribute_registry ORDER BY name ASC';
    Query.Open;
    while not Query.EOF do
    begin
      FExistingAttribute.Add(Query.FieldByName('name').AsString + '=' + Query.FieldByName('attribute_type').AsString);
      cmbExistingAttribute.Items.Add(Query.FieldByName('name').AsString);
      Query.Next;
    end;
    Query.Close;
  finally
    Query.Free;
  end;
end;

function TfrmModalImport.Execute(AConnection: TSQLite3Connection; AColumn: TStrings): Boolean;
var
  i: Integer;
  Map: TColumnMap;
begin
  FConnection := AConnection;
  LoadExistingAttributes;
  FUpdating := True;
  try
    for i := 0 to FMapping.Count - 1 do
      if Assigned(FMapping[i]) then TColumnMap(FMapping[i]).Free;
    FMapping.Clear;
    vstMapping.BeginUpdate;
    try
      vstMapping.Clear;
      for i := 0 to AColumn.Count - 1 do
      begin
        Map := TColumnMap.Create;
        Map.SourceColumn := AColumn[i];
        Map.MapType := mtSkip;
        Map.AttributeMode := 0;
        Map.AttributeName := '';
        Map.AttributeType := 'Text';
        FMapping.Add(Map);
      end;
      vstMapping.RootNodeCount := FMapping.Count;
    finally
      vstMapping.EndUpdate;
    end;
  finally
    FUpdating := False;
  end;
  if vstMapping.RootNodeCount > 0 then
  begin
    vstMapping.Selected[vstMapping.GetFirst] := True;
    vstMapping.FocusedNode := vstMapping.GetFirst;
  end;
  Result := (ShowModal = mrOk);
end;

function TfrmModalImport.GetMapping(Index: Integer): TColumnMap;
begin
  if (Index >= 0) and (Index < FMapping.Count) then
    Result := TColumnMap(FMapping[Index])
  else
    Result := nil;
end;

procedure TfrmModalImport.UpdateRightPanel;
var
  IsAttr, IsNew: Boolean;
begin
  IsAttr := (cmbTargetType.ItemIndex = 3);
  pnlAttributeSettings.Visible := IsAttr;
  if IsAttr then
  begin
    if cmbExistingAttribute.Items.Count = 0 then
    begin
      cmbAttributeMode.ItemIndex := 1;
      cmbAttributeMode.Enabled := False;
    end
    else
      cmbAttributeMode.Enabled := True;
    IsNew := (cmbAttributeMode.ItemIndex = 1);
    lblExistingAttribute.Visible := not IsNew;
    cmbExistingAttribute.Visible := not IsNew;
    lblNewAttributeName.Visible := IsNew;
    edtNewAttributeName.Visible := IsNew;
    lblNewAttributeType.Visible := IsNew;
    cmbNewAttributeType.Visible := IsNew;
  end;
end;

procedure TfrmModalImport.vstMappingFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
var
  Map: TColumnMap;
begin
  if FUpdating or not Assigned(Node) or (Node^.Index < 0) or (Node^.Index >= FMapping.Count) then Exit;
  FUpdating := True;
  try
    Map := TColumnMap(FMapping[Node^.Index]);
    if Assigned(Map) then
    begin
      cmbTargetType.ItemIndex := Ord(Map.MapType);
      cmbAttributeMode.ItemIndex := Map.AttributeMode;
      cmbExistingAttribute.ItemIndex := cmbExistingAttribute.Items.IndexOf(Map.AttributeName);
      edtNewAttributeName.Text := Map.AttributeName;
      cmbNewAttributeType.ItemIndex := cmbNewAttributeType.Items.IndexOf(Map.AttributeType);
      UpdateRightPanel;
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TfrmModalImport.vstMappingGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Map: TColumnMap;
begin
  if (Node^.Index >= 0) and (Node^.Index < FMapping.Count) then
  begin
    Map := TColumnMap(FMapping[Node^.Index]);
    case Column of
      0: CellText := Map.SourceColumn;
      1: case Map.MapType of
           mtSkip: CellText := 'Skip';
           mtDocumentName: CellText := 'Document Name';
           mtDocumentText: CellText := 'Document Content';
           mtAttribute: CellText := 'Attribute: ' + Map.AttributeName + ' (' + Map.AttributeType + ')';
         end;
    end;
  end;
end;

procedure TfrmModalImport.vstMappingPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
var
  Map: TColumnMap;
begin
  if (Node^.Index < 0) or (Node^.Index >= FMapping.Count) then Exit;
  Map := TColumnMap(FMapping[Node^.Index]);
  TargetCanvas.Font.Color := clWindowText;
  if Column = 1 then
  begin
    case Map.MapType of
      mtSkip: 
        if not (vsSelected in Node^.States) then
          TargetCanvas.Font.Color := clGrayText;
      mtDocumentName, mtDocumentText: 
        TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsBold];
    end;
  end;
end;

procedure TfrmModalImport.cmbTargetTypeChange(Sender: TObject);
begin
  if FUpdating then Exit;
  UpdateRightPanel;
end;

procedure TfrmModalImport.cmbAttributeModeChange(Sender: TObject);
begin
  if FUpdating then Exit;
  UpdateRightPanel;
end;

procedure TfrmModalImport.btnApplyClick(Sender: TObject);
var
  Map, OtherMap: TColumnMap;
  i: Integer;
  NewName, NewType: String;
  Node, NextNode: PVirtualNode;
begin
  Node := vstMapping.FocusedNode;
  if not Assigned(Node) or (Node^.Index < 0) or (Node^.Index >= FMapping.Count) then Exit;
  if cmbTargetType.ItemIndex in [1, 2] then
  begin
    for i := 0 to FMapping.Count - 1 do
    begin
      if i = Node^.Index then Continue;
      OtherMap := GetMapping(i);
      if Ord(OtherMap.MapType) = cmbTargetType.ItemIndex then
      begin
        MessageDlg('Duplicate Mapping', 'Another column is already mapped to this target. Only one column can map to Document Name or Text.', mtWarning, [mbOK], 0);
        Exit;
      end;
    end;
  end;
  Map := GetMapping(Node^.Index);
  if cmbTargetType.ItemIndex = 3 then
  begin
    if cmbAttributeMode.ItemIndex = 0 then
    begin
      if cmbExistingAttribute.ItemIndex = -1 then
      begin
        MessageDlg('Validation Error', 'Please select an existing attribute.', mtWarning, [mbOK], 0);
        Exit;
      end;
      NewName := cmbExistingAttribute.Text;
      NewType := FExistingAttribute.Values[NewName];
    end
    else
    begin
      NewName := Trim(edtNewAttributeName.Text);
      if NewName = '' then
      begin
        MessageDlg('Validation Error', 'Attribute name cannot be empty.', mtWarning, [mbOK], 0);
        Exit;
      end;
      for i := 0 to cmbExistingAttribute.Items.Count - 1 do
      begin
        if SameText(NewName, cmbExistingAttribute.Items[i]) then
        begin
          MessageDlg('Validation Error', 'An attribute with this name already exists. Please choose "Use Existing".', mtWarning, [mbOK], 0);
          Exit;
        end;
      end;
      if cmbNewAttributeType.ItemIndex = -1 then cmbNewAttributeType.ItemIndex := 0;
      NewType := cmbNewAttributeType.Text;
    end;
    for i := 0 to FMapping.Count - 1 do
    begin
      if i = Node^.Index then Continue;
      OtherMap := GetMapping(i);
      if (OtherMap.MapType = mtAttribute) and SameText(OtherMap.AttributeName, NewName) then
      begin
        MessageDlg('Validation Error', 'The attribute "' + NewName + '" is already mapped to another column.', mtWarning, [mbOK], 0);
        Exit;
      end;
    end;
    Map.AttributeName := NewName;
    Map.AttributeType := NewType;
    Map.AttributeMode := cmbAttributeMode.ItemIndex;
  end
  else
  begin
    Map.AttributeName := '';
    Map.AttributeType := '';
  end;
  Map.MapType := TMapTarget(cmbTargetType.ItemIndex);
  vstMapping.InvalidateNode(Node);
  NextNode := vstMapping.GetNext(Node);
  if Assigned(NextNode) then
  begin
    vstMapping.ClearSelection;
    vstMapping.Selected[NextNode] := True;
    vstMapping.FocusedNode := NextNode;
    vstMapping.ScrollIntoView(NextNode, False);
  end;
end;

procedure TfrmModalImport.btnImportClick(Sender: TObject);
var
  i: Integer;
  HasName, HasText: Boolean;
  Map: TColumnMap;
begin
  HasName := False;
  HasText := False;
  for i := 0 to FMapping.Count - 1 do
  begin
    Map := GetMapping(i);
    if Map.MapType = mtDocumentName then HasName := True;
    if Map.MapType = mtDocumentText then HasText := True;
  end;
  if not HasName or not HasText then
  begin
    MessageDlg('Mapping Incomplete', 'You must map exactly one column to "Document Name" and one column to "Document Content" to proceed.', mtWarning, [mbOK], 0);
    Exit;
  end;
  ModalResult := mrOk;
end;

end.
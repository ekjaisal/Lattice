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

unit ModalAnalyse;

{$mode ObjFPC}{$H+}

interface

uses
  Buttons, Classes, ComCtrls, Controls, DB, Dialogs, EditBtn, ExtCtrls, Forms, Generics.Collections,
  Graphics, Spin, StdCtrls, SysUtils, Types {$IFDEF WINDOWS}, Windows{$ENDIF}, SQLDB, laz.VirtualTrees,
  Cairo, BridgeLibrary, ServiceDatabase, ServiceVisualize;

type
  TAttributeCache = record
    ID: String;
    Name: String;
    Key: String;
    AttributeType: String;
    OperatorVal: String;
    FilterValue: String;
  end;

  TAnalysisState = (asReady, asRunning, asMissingAttribute, asNoSelection, asNoResults, asComplete);

  TCodeNodeCache = record
    Name: String;
    ParentID: String;
  end;

  { TfrmModalAnalyse }
  TfrmModalAnalyse = class(TForm)
    btnAnalyse: TButton;
    btnClose: TButton;
    btnCloudClearAll: TButton;
    btnCloudSelectAll: TButton;
    btnCoOccurrenceXClearAll: TButton;
    btnCoOccurrenceXSelectAll: TButton;
    btnCoOccurrenceYClearAll: TButton;
    btnCoOccurrenceYSelectAll: TButton;
    btnCrossClearAll: TButton;
    btnCrosstabSelectAll: TButton;
    btnExportData: TButton;
    btnFrequencyClearAll: TButton;
    btnFrequencySelectAll: TButton;
    btnReset: TButton;
    btnSaveVisualization: TButton;
    btnScopeAttributeApply: TButton;
    btnScopeAttributeClear: TButton;
    btnScopeAttributeClearAll: TButton;
    btnScopeDocumentClearAll: TButton;
    btnScopeDocumentSelectAll: TButton;
    btnStopwords: TButton;
    chkEnableLimit: TCheckBox;
    cmbCrossAttribute: TComboBox;
    cmbScopeAttributeOperator: TComboBox;
    cmbScopeAttributeValueCat: TComboBox;
    deScopeAttributeValueDate: TDateEdit;
    deScopeAttributeValueDateEnd: TDateEdit;
    dlgExportData: TSaveDialog;
    dlgSaveVisualization: TSaveDialog;
    edtVisualizationLimit: TSpinEdit;
    edtScopeAttributeValueText: TEdit;
    edtSearchCloud: TEdit;
    edtSearchCoOccurrenceX: TEdit;
    edtSearchCoOccurrenceY: TEdit;
    edtSearchCrosstab: TEdit;
    edtSearchFrequency: TEdit;
    edtSearchScopeAttribute: TEdit;
    edtSearchScopeDocument: TEdit;
    fseScopeAttributeValueNum: TFloatSpinEdit;
    fseScopeAttributeValueNumEnd: TFloatSpinEdit;
    lblVisualizationLimit: TLabel;
    lblCoverageInfo: TLabel;
    lblCrossAttribute: TLabel;
    lblParamsTitle: TLabel;
    lblResultsTitle: TLabel;
    lblScopeDocumentTitle: TLabel;
    lblScopeAttributeTitle: TLabel;
    pbxVisualization: TPaintBox;
    pcAnalysisType: TPageControl;
    pnlActions: TPanel;
    pnlAttributeFilterDef: TPanel;
    pnlVisualization: TPanel;
    pnlCloudTools: TPanel;
    pnlCoOccurrenceX: TPanel;
    pnlCoOccurrenceXTools: TPanel;
    pnlCoOccurrenceY: TPanel;
    pnlCoOccurrenceYTools: TPanel;
    pnlCrossX: TPanel;
    pnlCrosstabXTools: TPanel;
    pnlCrossY: TPanel;
    pnlDisplayOptions: TPanel;
    pnlFrequencyTools: TPanel;
    pnlGrid: TPanel;
    pnlLeft: TPanel;
    pnlLeftHeader: TPanel;
    pnlLimitControls: TPanel;
    pnlResults: TPanel;
    pnlRight: TPanel;
    pnlScope: TPanel;
    pnlScopeAttributeValue: TPanel;
    pnlScopeAttributeValueDate: TPanel;
    pnlScopeAttributeValueNumeric: TPanel;
    pnlScopeAttributes: TPanel;
    pnlScopeAttributesTools: TPanel;
    pnlScopeDocument: TPanel;
    pnlScopeDocumentTools: TPanel;
    pnlWordCloudTools: TPanel;
    rgLogicMode: TRadioGroup;
    splCoOccurrence: TSplitter;
    splCross: TSplitter;
    splMain: TSplitter;
    splResults: TSplitter;
    splScope: TSplitter;
    splScopeInternal: TSplitter;
    tmrCloudSearch: TTimer;
    tmrCoOccurrenceXSearch: TTimer;
    tmrCoOccurrenceYSearch: TTimer;
    tmrCrosstabSearch: TTimer;
    tmrFrequencySearch: TTimer;
    tmrScopeAttributeSearch: TTimer;
    tmrScopeDocumentSearch: TTimer;
    tsCoOccurrence: TTabSheet;
    tsCoverage: TTabSheet;
    tsCrosstab: TTabSheet;
    tsFrequency: TTabSheet;
    tsWordCloud: TTabSheet;
    vstCoOccurrenceX: TLazVirtualStringTree;
    vstCoOccurrenceY: TLazVirtualStringTree;
    vstCrosstabCode: TLazVirtualStringTree;
    vstFrequencyCode: TLazVirtualStringTree;
    vstResultGrid: TLazVirtualStringTree;
    vstScopeAttribute: TLazVirtualStringTree;
    vstScopeDocument: TLazVirtualStringTree;
    vstWordCloudCode: TLazVirtualStringTree;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnAnalyseClick(Sender: TObject);
    procedure btnCloudClearAllClick(Sender: TObject);
    procedure btnCloudSelectAllClick(Sender: TObject);
    procedure btnCoOccurrenceXClearAllClick(Sender: TObject);
    procedure btnCoOccurrenceXSelectAllClick(Sender: TObject);
    procedure btnCoOccurrenceYClearAllClick(Sender: TObject);
    procedure btnCoOccurrenceYSelectAllClick(Sender: TObject);
    procedure btnCrossClearAllClick(Sender: TObject);
    procedure btnCrosstabSelectAllClick(Sender: TObject);
    procedure btnExportDataClick(Sender: TObject);
    procedure btnFrequencyClearAllClick(Sender: TObject);
    procedure btnFrequencySelectAllClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnSaveVisualizationClick(Sender: TObject);
    procedure btnScopeAttributeApplyClick(Sender: TObject);
    procedure btnScopeAttributeClearAllClick(Sender: TObject);
    procedure btnScopeAttributeClearClick(Sender: TObject);
    procedure btnScopeDocumentClearAllClick(Sender: TObject);
    procedure btnScopeDocumentSelectAllClick(Sender: TObject);
    procedure btnStopwordsClick(Sender: TObject);
    procedure chkEnableLimitChange(Sender: TObject);
    procedure cmbScopeAttributeOperatorChange(Sender: TObject);
    procedure edtVisualizationLimitChange(Sender: TObject);
    procedure edtSearchCloudChange(Sender: TObject);
    procedure edtSearchCoOccurrenceXChange(Sender: TObject);
    procedure edtSearchCoOccurrenceYChange(Sender: TObject);
    procedure edtSearchCrosstabChange(Sender: TObject);
    procedure edtSearchFrequencyChange(Sender: TObject);
    procedure edtSearchScopeAttributeChange(Sender: TObject);
    procedure edtSearchScopeDocumentChange(Sender: TObject);
    procedure pbxVisualizationMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pbxVisualizationMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbxVisualizationMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pbxVisualizationMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePosition: TPoint; var Handled: Boolean);
    procedure pbxVisualizationPaint(Sender: TObject);
    procedure pcAnalysisTypeChange(Sender: TObject);
    procedure tmrCloudSearchTimer(Sender: TObject);
    procedure tmrCoOccurrenceXSearchTimer(Sender: TObject);
    procedure tmrCoOccurrenceYSearchTimer(Sender: TObject);
    procedure tmrCrosstabSearchTimer(Sender: TObject);
    procedure tmrFrequencySearchTimer(Sender: TObject);
    procedure tmrScopeAttributeSearchTimer(Sender: TObject);
    procedure tmrScopeDocumentSearchTimer(Sender: TObject);
    procedure vstChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstCodeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstCodeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
    procedure vstCodeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstCodeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure vstResultGridGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
    procedure vstResultGridGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstScopeAttributeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstScopeAttributeHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
    procedure vstScopeAttributeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
    procedure vstScopeAttributeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstScopeAttributePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
    procedure vstScopeDocumentChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstScopeDocumentFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstScopeDocumentGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
    procedure vstScopeDocumentGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstScopeDocumentInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure vstScopeNoFocusChanging(Sender: TBaseVirtualTree; OldNode, NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex; var Allowed: Boolean);
  private
    FActiveAnalysis: Integer;
    FAnalysisState: TAnalysisState;
    FAttributeCacheArray: array of TAttributeCache;
    FAttributeKey: TStringList;
    FAttributeSortAscending: Boolean;
    FAttributeSortColumn: Integer;
    FCheckedCloudCode: specialize TDictionary<String, Boolean>;
    FCheckedCoOccurrenceXCode: specialize TDictionary<String, Boolean>;
    FCheckedCoOccurrenceYCode: specialize TDictionary<String, Boolean>;
    FCheckedCrosstabCode: specialize TDictionary<String, Boolean>;
    FCheckedDocumentSet: specialize TDictionary<String, Boolean>;
    FCheckedFrequencyCode: specialize TDictionary<String, Boolean>;
    FCloudResult: TWordCloudArray;
    FCodeCacheArray: TCodeFlatArray;
    FCodeMap: specialize TDictionary<String, TCodeNodeCache>;
    FCoOccurrenceResult: TCoOccurrenceArray;
    FCoverageResult: TCoverageArray;
    FCrossResult: TCrosstabArray;
    FCurrentAttributeIndex: Integer;
    FDocumentCacheArray: TDocumentCacheArray;
    FFrequencyResult: TFrequencyArray;
    FIsBatchOperation: Boolean;
    FIsDragging: Boolean;
    FLastBarLimit: Integer;
    FLastCheckedDocNode: PVirtualNode;
    FLastCheckedNode: PVirtualNode;
    FLastCheckedTree: TBaseVirtualTree;
    FLastCloudLimit: Integer;
    FLastMouse: TPoint;
    FPanX, FPanY: Double;
    FServiceDatabase: TServiceDatabase;
    FVirtualHeight: Integer;
    FVirtualWidth: Integer;
    FVisualizer: TServiceVisualize;
    FZoom: Double;
    function GetAttributeSQL: String;
    function GetCheckedDocumentID(MaxLimit: Integer = 0): TStringDynArray;
    function GetCheckedTreeIDs(Tree: TLazVirtualStringTree; MaxLimit: Integer = 0): TStringDynArray;
    function GetDictionaryForTree(Tree: TLazVirtualStringTree): specialize TDictionary<String, Boolean>;
    function GetFullCodePath(const CodeID: String): String;
    function GetTruncatedCodePath(const CodeID: String; MaxNodeLen: Integer): String;
    function TruncateText(const S: String; MaxLen: Integer): String;
    procedure ApplyAttributeFilter(const Filter: String);
    procedure ExecuteCoOccurrence;
    procedure ExecuteCoverage;
    procedure ExecuteCrosstab;
    procedure ExecuteFrequency;
    procedure ExecuteWordCloud;
    procedure InternalApplyCodeFilter(Tree: TLazVirtualStringTree; const Filter: String);
    procedure LoadAttributeDefinitionPane(NodeIndex: Integer);
    procedure LoadAttributeTree(const FilterText: String);
    procedure LoadCategoricalValue;
    procedure LoadCodeTree(Tree: TLazVirtualStringTree);
    procedure LoadDocumentTree(const FilterText: String);
    procedure RenderActiveVisualisation(cr: Pcairo_t; AWidth, AHeight: Integer);
    procedure ResetResults;
    procedure ResetViewContext;
    procedure SetupGrid(const ColumnArray: array of String; const ColumnWidthArray: array of Integer; RowCount: Integer);
    procedure ToggleTreeNodes(Tree: TLazVirtualStringTree; Check: Boolean);
    procedure UpdateAttributeOperator(const AttributeType: String);
    procedure UpdateLimitControlsContext;
  end;

var
  frmModalAnalyse: TfrmModalAnalyse;

implementation

uses
  LazUTF8, Math, StrUtils, AppBase, AppFont, AppFormat, DialogEditor, DialogProgress,
  ServiceExport, ServiceThread;

type
  TThreadLoadAnalyseContext = class(TBackgroundWorker)
  public
    FCodeCacheArray: TCodeFlatArray;
    FDocumentCacheArray: TDocumentCacheArray;
    FAttributeCacheArray: array of TAttributeCache;
    FAttributeKey: TStringList;
    FCrosstabAttributeName: TStringList;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadExportTable = class(TThread)
  public
    FFileName: String;
    FHeader: TStringDynArray;
    FDataKeys: TStringDynArray;
    FGridData: T2DStringArray;
  private
    FSuccess: Boolean;
    FErrorMessage: String;
  protected
    procedure Execute; override;
    procedure CloseProgressDialog;
  public
    property Success: Boolean read FSuccess;
    property ErrorMessage: String read FErrorMessage;
  end;

  TThreadExportVisualization = class(TThread)
  public
    FFileName, FProjectTitle, FSubject: String;
    FWidth, FHeight, FActiveAnalysis: Integer;
    FMargin: Double;
    FFrequencyResult: TFrequencyArray;
    FCoOccurrenceResult: TCoOccurrenceArray;
    FCrossResult: TCrosstabArray;
    FCoverageResult: TCoverageArray;
    FCloudResult: TWordCloudArray;
    FLimit: Integer; // <-- Added parameter
  private
    FSuccess: Boolean;
    FErrorMessage: String;
    FLocalVisualization: TServiceVisualize;
  protected
    procedure Execute; override;
    procedure CloseProgressDialog;
    procedure ThreadRenderEvent(cr: Pcairo_t; AWidth, AHeight: Integer);
  public
    property Success: Boolean read FSuccess;
    property ErrorMessage: String read FErrorMessage;
  end;

  TThreadPrepareVisualization = class(TThread)
  public
    FActiveAnalysis: Integer;
    FFrequencyResult: TFrequencyArray;
    FCoOccurrenceResult: TCoOccurrenceArray;
    FCrossResult: TCrosstabArray;
    FCoverageResult: TCoverageArray;
    FCloudResult: TWordCloudArray;
    FLimit: Integer;
    PreparedVisualization: TServiceVisualize;
    VWidth, VHeight: Integer;
  private
    FSuccess: Boolean;
    FErrorMessage: String;
    FStatusMsg: String;
  protected
    procedure Execute; override;
    procedure CloseProgressDialog;
    procedure SyncStatus(const Message: String);
    procedure DoSyncStatus;
  public
    property Success: Boolean read FSuccess;
    property ErrorMessage: String read FErrorMessage;
  end;

procedure TThreadLoadAnalyseContext.DoHeavyLifting;
var
  LocalDB: TServiceDatabase;
  Q: TSQLQuery;
  Count, Capacity: Integer;
begin
  FAttributeKey := TStringList.Create;
  FCrosstabAttributeName := TStringList.Create;
  LocalDB := TServiceDatabase.Create(ServiceDatabase.TSQLite3Connection(FConnection));
  try
    SyncUpdateStatus('Loading code system...');
    FCodeCacheArray := LocalDB.GetAllCodeFlat('', 'sort_order', 'ASC');
    SyncUpdateStatus('Loading document index...');
    FDocumentCacheArray := LocalDB.GetDocumentData(Default(TDocumentFilterDefinition), 'title', 'ASC', False);
    SyncUpdateStatus('Loading attribute registry...');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.SQL.Text := 'SELECT id, name, attribute_key, attribute_type FROM attribute_registry ORDER BY name ASC';
      Q.Open;
      Count := 0; Capacity := Max(128, Q.RecordCount);
      SetLength(FAttributeCacheArray, Capacity);
      while not Q.EOF do
      begin
        if Count >= Capacity then
        begin
          Capacity := Capacity * 2;
          SetLength(FAttributeCacheArray, Capacity);
        end;
        FAttributeCacheArray[Count].ID := Q.FieldByName('id').AsString;
        FAttributeCacheArray[Count].Name := Q.FieldByName('name').AsString;
        FAttributeCacheArray[Count].Key := Q.FieldByName('attribute_key').AsString;
        FAttributeCacheArray[Count].AttributeType := Q.FieldByName('attribute_type').AsString;
        FAttributeCacheArray[Count].OperatorVal := '';
        FAttributeCacheArray[Count].FilterValue := '';
        FAttributeKey.Add(Q.FieldByName('attribute_key').AsString);
        FCrosstabAttributeName.Add(Q.FieldByName('name').AsString);
        Inc(Count);
        Q.Next;
      end;
      SetLength(FAttributeCacheArray, Count);
    finally
      Q.Free;
    end;
  finally
    LocalDB.Free;
  end;
end;

procedure TThreadExportTable.Execute;
begin
  FSuccess := False;
  FErrorMessage := '';
  try
    FSuccess := TServiceExport.ExportDataTable(FHeader, FDataKeys, FGridData, FFileName);
    if not FSuccess then FErrorMessage := 'Export failed or file is locked.';
  except
    on E: Exception do FErrorMessage := E.Message;
  end;
  Synchronize(@CloseProgressDialog);
end;

procedure TThreadExportTable.CloseProgressDialog;
begin
  if Assigned(frmDialogProgress) and frmDialogProgress.Visible then
    frmDialogProgress.ModalResult := mrOk;
end;

procedure TThreadExportVisualization.Execute;
var
  VW, VH, i, c, r, MaxVal, Limit: Integer;
  ChartData: TChartElementArray;
  CodeListX, CodeListY, CodeList, AttributeList: TStringList;
  Matrix: TMatrixData;
  XLabel, YLabel, LabelArray, LabelStr: array of String;
  TotalVal, SubVal: array of Double;
  Word: array of String;
  Frequency: array of Integer;
  AttributeString, DocumentName: String;
begin
  FSuccess := False;
  FErrorMessage := '';
  try
    FLocalVisualization := TServiceVisualize.Create;
    try
      case FActiveAnalysis of
        0: begin
             SetLength(ChartData, Length(FFrequencyResult));
             for i := 0 to High(FFrequencyResult) do
             begin
               ChartData[i].LabelText := frmModalAnalyse.GetTruncatedCodePath(FFrequencyResult[i].CodeID, 25);
               ChartData[i].Value := FFrequencyResult[i].SegmentCount;
               ChartData[i].ValueStr := IntToStr(FFrequencyResult[i].SegmentCount);
             end;
             FLocalVisualization.PrepareBarChart(ChartData, VW, VH);
           end;
        1: begin
             CodeListX := TStringList.Create;
             CodeListY := TStringList.Create;
             try
               CodeListX.Sorted := True; CodeListX.Duplicates := dupIgnore;
               CodeListY.Sorted := True; CodeListY.Duplicates := dupIgnore;
               MaxVal := 1;
               for i := 0 to High(FCoOccurrenceResult) do
               begin
                 CodeListX.Add(FCoOccurrenceResult[i].Code1ID);
                 CodeListY.Add(FCoOccurrenceResult[i].Code2ID);
                 if FCoOccurrenceResult[i].Overlap > MaxVal then MaxVal := FCoOccurrenceResult[i].Overlap;
               end;
               SetLength(Matrix, CodeListX.Count, CodeListY.Count);
               for i := 0 to High(FCoOccurrenceResult) do
               begin
                 c := CodeListX.IndexOf(FCoOccurrenceResult[i].Code1ID);
                 r := CodeListY.IndexOf(FCoOccurrenceResult[i].Code2ID);
                 if (c > -1) and (r > -1) then Matrix[c, r] := FCoOccurrenceResult[i].Overlap;
               end;
               SetLength(XLabel, CodeListX.Count);
               for c := 0 to CodeListX.Count - 1 do XLabel[c] := frmModalAnalyse.GetTruncatedCodePath(CodeListX[c], 25);
               SetLength(YLabel, CodeListY.Count);
               for r := 0 to CodeListY.Count - 1 do YLabel[r] := frmModalAnalyse.GetTruncatedCodePath(CodeListY[r], 25);
               FLocalVisualization.PrepareHeatmap(XLabel, YLabel, Matrix, MaxVal, False, VW, VH);
             finally
               CodeListX.Free; CodeListY.Free;
             end;
           end;
        2: begin
             CodeList := TStringList.Create;
             AttributeList := TStringList.Create;
             try
               CodeList.Sorted := True; CodeList.Duplicates := dupIgnore;
               AttributeList.Sorted := True; AttributeList.Duplicates := dupIgnore;
               MaxVal := 1;
               for i := 0 to High(FCrossResult) do
               begin
                 CodeList.Add(FCrossResult[i].CodeID);
                 AttributeList.Add(FCrossResult[i].AttributeValue);
                 if FCrossResult[i].Frequency > MaxVal then MaxVal := FCrossResult[i].Frequency;
               end;
               SetLength(Matrix, AttributeList.Count, CodeList.Count);
               for i := 0 to High(FCrossResult) do
               begin
                 c := AttributeList.IndexOf(FCrossResult[i].AttributeValue);
                 r := CodeList.IndexOf(FCrossResult[i].CodeID);
                 if (c > -1) and (r > -1) then Matrix[c, r] := FCrossResult[i].Frequency;
               end;
               SetLength(XLabel, AttributeList.Count);
               for c := 0 to AttributeList.Count - 1 do
               begin
                 AttributeString := AttributeList[c];
                 if UTF8Length(AttributeString) > 40 then AttributeString := UTF8Copy(AttributeString, 1, 40) + '...';
                 XLabel[c] := AttributeString;
               end;
               SetLength(YLabel, CodeList.Count);
               for r := 0 to CodeList.Count - 1 do YLabel[r] := frmModalAnalyse.GetTruncatedCodePath(CodeList[r], 25);
               FLocalVisualization.PrepareHeatmap(XLabel, YLabel, Matrix, MaxVal, True, VW, VH);
             finally
               CodeList.Free; AttributeList.Free;
             end;
           end;
        3: begin
             Limit := FLimit;
             if Limit <= 0 then Limit := Length(FCoverageResult);
             if Limit > Length(FCoverageResult) then Limit := Length(FCoverageResult);
             SetLength(LabelArray, Limit);
             SetLength(LabelStr, Limit);
             SetLength(TotalVal, Limit);
             SetLength(SubVal, Limit);
             for i := 0 to Limit - 1 do
             begin
               DocumentName := FCoverageResult[i].DocumentName;
               if UTF8Length(DocumentName) > 60 then DocumentName := UTF8Copy(DocumentName, 1, 60) + '...';
               LabelArray[i] := DocumentName;
               TotalVal[i] := FCoverageResult[i].TotalCharacters;
               SubVal[i] := FCoverageResult[i].CodedCharacters;
               if FCoverageResult[i].TotalCharacters > 0 then
                 LabelStr[i] := FormatFloat('0.00', (FCoverageResult[i].CodedCharacters / FCoverageResult[i].TotalCharacters) * 100) + '%'
               else
                 LabelStr[i] := '0.00%';
             end;
             FLocalVisualization.PrepareStackedBarChart(LabelArray, TotalVal, SubVal, LabelStr, VW, VH);
           end;
        4: begin
             Limit := Length(FCloudResult);
             SetLength(Word, Limit);
             SetLength(Frequency, Limit);
             for i := 0 to Limit - 1 do
             begin
               Word[i] := FCloudResult[i].Word;
               Frequency[i] := FCloudResult[i].Frequency;
             end;
             FLocalVisualization.PrepareWordCloud(Word, Frequency, VW, VH);
           end;
      end;
      FSuccess := TServiceExport.ExportVisualisation(FFileName, FProjectTitle, FSubject, FWidth, FHeight, @ThreadRenderEvent);
      if not FSuccess then FErrorMessage := 'Export failed or file is locked.';
    finally
      FLocalVisualization.Free;
    end;
  except
    on E: Exception do FErrorMessage := E.Message;
  end;
  Synchronize(@CloseProgressDialog);
end;

procedure TThreadExportVisualization.ThreadRenderEvent(cr: Pcairo_t; AWidth, AHeight: Integer);
begin
  cairo_save(cr);
  cairo_translate(cr, FMargin, FMargin);
  FLocalVisualization.Render(cr, AWidth - Round(FMargin * 2.0), AHeight - Round(FMargin * 2.0), 0, 0, 1.0);
  cairo_restore(cr);
end;

procedure TThreadExportVisualization.CloseProgressDialog;
begin
  if Assigned(frmDialogProgress) and frmDialogProgress.Visible then
    frmDialogProgress.ModalResult := mrOk;
end;

{$R *.lfm}

procedure TfrmModalAnalyse.FormCreate(Sender: TObject);
begin
  ApplyAppFont(Self);
  FServiceDatabase := TServiceDatabase.Create(ServiceDatabase.TSQLite3Connection(frmAppBase.conMain));
  FVisualizer := TServiceVisualize.Create;
  FLastCloudLimit := 50;
  FLastBarLimit := 10;
  FAnalysisState := asReady;
  FIsBatchOperation := False;
  FAttributeKey := TStringList.Create;
  FCheckedDocumentSet := specialize TDictionary<String, Boolean>.Create;
  FCheckedFrequencyCode := specialize TDictionary<String, Boolean>.Create;
  FCheckedCoOccurrenceXCode := specialize TDictionary<String, Boolean>.Create;
  FCheckedCoOccurrenceYCode := specialize TDictionary<String, Boolean>.Create;
  FCheckedCrosstabCode := specialize TDictionary<String, Boolean>.Create;
  FCheckedCloudCode := specialize TDictionary<String, Boolean>.Create;
  FCodeMap := specialize TDictionary<String, TCodeNodeCache>.Create;
  FCurrentAttributeIndex := -1;
  FAttributeSortColumn := 0;
  FAttributeSortAscending := True;
  vstFrequencyCode.NodeDataSize := SizeOf(Integer);
  vstCoOccurrenceX.NodeDataSize := SizeOf(Integer);
  vstCoOccurrenceY.NodeDataSize := SizeOf(Integer);
  vstCrosstabCode.NodeDataSize := SizeOf(Integer);
  vstWordCloudCode.NodeDataSize := SizeOf(Integer);
  vstScopeDocument.NodeDataSize := 0;
  vstScopeAttribute.NodeDataSize := 0;
  vstResultGrid.NodeDataSize := 0;
  Application.HintHidePause := 30000;
end;

procedure TfrmModalAnalyse.FormDestroy(Sender: TObject);
begin
  Application.HintHidePause := 2500;
  FServiceDatabase.Free;
  FVisualizer.Free;
  FAttributeKey.Free;
  FCheckedDocumentSet.Free;
  FCheckedFrequencyCode.Free;
  FCheckedCoOccurrenceXCode.Free;
  FCheckedCoOccurrenceYCode.Free;
  FCheckedCrosstabCode.Free;
  FCheckedCloudCode.Free;
  FCodeMap.Free;
  SetLength(FCodeCacheArray, 0);
  SetLength(FDocumentCacheArray, 0);
  SetLength(FAttributeCacheArray, 0);
  SetLength(FFrequencyResult, 0);
  SetLength(FCoOccurrenceResult, 0);
  SetLength(FCrossResult, 0);
  SetLength(FCoverageResult, 0);
  SetLength(FCloudResult, 0);
end;

procedure TfrmModalAnalyse.FormShow(Sender: TObject);
var
  Worker: TThreadLoadAnalyseContext;
  i: Integer;
  NodeCache: TCodeNodeCache;
begin
  pcAnalysisType.ActivePageIndex := 0;
  ResetResults;
  Worker := TThreadLoadAnalyseContext.Create(frmAppBase.conMain.DatabaseName);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Preparing Analysis Workspace', 'Loading project data...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      FCodeCacheArray := Worker.FCodeCacheArray;
      FDocumentCacheArray := Worker.FDocumentCacheArray;
      FAttributeCacheArray := Worker.FAttributeCacheArray;
      FAttributeKey.Clear;
      FAttributeKey.Assign(Worker.FAttributeKey);
      if Assigned(cmbCrossAttribute) then
      begin
        cmbCrossAttribute.Items.Clear;
        cmbCrossAttribute.Items.Assign(Worker.FCrosstabAttributeName);
      end;
      FCodeMap.Clear;
      for i := 0 to High(FCodeCacheArray) do
      begin
        NodeCache.Name := FCodeCacheArray[i].Name;
        NodeCache.ParentID := FCodeCacheArray[i].ParentID;
        FCodeMap.AddOrSetValue(FCodeCacheArray[i].ID, NodeCache);
      end;
      LoadCodeTree(vstFrequencyCode);
      LoadCodeTree(vstCoOccurrenceX);
      LoadCodeTree(vstCoOccurrenceY);
      LoadCodeTree(vstCrosstabCode);
      LoadCodeTree(vstWordCloudCode);
      vstScopeDocument.BeginUpdate;
      vstScopeDocument.Clear;
      vstScopeDocument.RootNodeCount := Length(FDocumentCacheArray);
      vstScopeDocument.EndUpdate;
      vstScopeAttribute.BeginUpdate;
      vstScopeAttribute.Clear;
      vstScopeAttribute.RootNodeCount := Length(FAttributeCacheArray);
      vstScopeAttribute.EndUpdate;
    end
    else
      MessageDlg('Error', 'Failed to load project context: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.FAttributeKey.Free;
    Worker.FCrosstabAttributeName.Free;
    Worker.Free;
  end;
  pcAnalysisTypeChange(nil);
end;

procedure TfrmModalAnalyse.pcAnalysisTypeChange(Sender: TObject);
begin
  UpdateLimitControlsContext;
  ResetResults;
end;

procedure TfrmModalAnalyse.UpdateLimitControlsContext;
begin
  if (csLoading in ComponentState) or not Assigned(pcAnalysisType) or not Assigned(chkEnableLimit) or not Assigned(lblVisualizationLimit) or not Assigned(edtVisualizationLimit) then Exit;
  if Assigned(btnStopwords) then
    btnStopwords.Visible := (pcAnalysisType.ActivePageIndex = 4);
  edtVisualizationLimit.OnChange := nil;
  case pcAnalysisType.ActivePageIndex of
    0, 3:
      begin
        pnlLimitControls.Visible := True;
        chkEnableLimit.Visible := True;
        lblVisualizationLimit.Caption := 'Limit Bars to:';
        edtVisualizationLimit.MaxValue := 1000000;
        edtVisualizationLimit.Value := FLastBarLimit;
        edtVisualizationLimit.Enabled := chkEnableLimit.Checked;
      end;
    1, 2:
      begin
        pnlLimitControls.Visible := False;
      end;
    4:
      begin
        pnlLimitControls.Visible := True;
        chkEnableLimit.Visible := False;
        lblVisualizationLimit.Caption := 'Limit Words in Cloud to (Max. 100):';
        edtVisualizationLimit.MaxValue := 100;
        edtVisualizationLimit.Value := FLastCloudLimit;
        edtVisualizationLimit.Enabled := True;
      end;
  end;
  edtVisualizationLimit.OnChange := @edtVisualizationLimitChange;
end;

function TfrmModalAnalyse.GetFullCodePath(const CodeID: String): String;
var
  CurrentID: String;
  NodeCache: TCodeNodeCache;
begin
  Result := '';
  if CodeID = '' then Exit;
  CurrentID := CodeID;
  while (CurrentID <> '') and FCodeMap.TryGetValue(CurrentID, NodeCache) do
  begin
    if NodeCache.Name = '' then Break;
    if Result = '' then
      Result := NodeCache.Name
    else
      Result := NodeCache.Name + ' ' + #$E2#$86#$92 + ' ' + Result;
    CurrentID := NodeCache.ParentID;
  end;
end;

function TfrmModalAnalyse.GetTruncatedCodePath(const CodeID: String; MaxNodeLen: Integer): String;
var
  CurrentID, NodeName: String;
  NodeCache: TCodeNodeCache;
begin
  Result := '';
  if CodeID = '' then Exit;
  CurrentID := CodeID;
  while (CurrentID <> '') and FCodeMap.TryGetValue(CurrentID, NodeCache) do
  begin
    if NodeCache.Name = '' then Break;
    NodeName := NodeCache.Name;
    if UTF8Length(NodeName) > MaxNodeLen then
      NodeName := UTF8Copy(NodeName, 1, MaxNodeLen) + '...';
    if Result = '' then
      Result := NodeName
    else
      Result := NodeName + ' ' + #$E2#$86#$92 + ' ' + Result;
    CurrentID := NodeCache.ParentID;
  end;
end;

function TfrmModalAnalyse.TruncateText(const S: String; MaxLen: Integer): String;
begin
  if UTF8Length(S) > MaxLen then
    Result := UTF8Copy(S, 1, MaxLen) + '...'
  else
    Result := S;
end;

procedure TfrmModalAnalyse.ResetResults;
begin
  FZoom := 1.0;
  FPanX := 0.0;
  FPanY := 0.0;
  FVirtualWidth := 0;
  FVirtualHeight := 0;
  FAnalysisState := asReady;
  FActiveAnalysis := -1;
  SetLength(FFrequencyResult, 0);
  SetLength(FCoOccurrenceResult, 0);
  SetLength(FCrossResult, 0);
  SetLength(FCoverageResult, 0);
  SetLength(FCloudResult, 0);
  if Assigned(pnlGrid) then pnlGrid.Visible := False;
  if Assigned(splResults) then splResults.Visible := False;
  if Assigned(vstResultGrid) then vstResultGrid.RootNodeCount := 0;
  btnExportData.Enabled := False;
  btnSaveVisualization.Enabled := False;
  if Assigned(pbxVisualization) then pbxVisualization.Invalidate;
end;

procedure TfrmModalAnalyse.LoadCodeTree(Tree: TLazVirtualStringTree);
var
  i: Integer;
  ChildMap: specialize TDictionary<String, specialize TList<Integer>>;
  RootCode: specialize TList<Integer>;
  ChildList: specialize TList<Integer>;
  procedure AddNodeRecursive(ParentNode: PVirtualNode; CodeIndex: Integer);
  var
    NewNode: PVirtualNode;
    Data: PInteger;
    c: Integer;
    ChildArray: specialize TList<Integer>;
  begin
    NewNode := Tree.AddChild(ParentNode);
    Data := Tree.GetNodeData(NewNode);
    Data^ := CodeIndex;
    if ChildMap.TryGetValue(FCodeCacheArray[CodeIndex].ID, ChildArray) then
    begin
      for c := 0 to ChildArray.Count - 1 do
        AddNodeRecursive(NewNode, ChildArray[c]);
    end;
  end;
begin
  ChildMap := specialize TDictionary<String, specialize TList<Integer>>.Create;
  RootCode := specialize TList<Integer>.Create;
  try
    for i := Low(FCodeCacheArray) to High(FCodeCacheArray) do
    begin
      if FCodeCacheArray[i].ParentID = '' then
        RootCode.Add(i)
      else
      begin
        if not ChildMap.TryGetValue(FCodeCacheArray[i].ParentID, ChildList) then
        begin
          ChildList := specialize TList<Integer>.Create;
          ChildMap.Add(FCodeCacheArray[i].ParentID, ChildList);
        end;
        ChildList.Add(i);
      end;
    end;
    Tree.BeginUpdate;
    try
      Tree.Clear;
      for i := 0 to RootCode.Count - 1 do
        AddNodeRecursive(nil, RootCode[i]);
    finally
      Tree.EndUpdate;
    end;
  finally
    for ChildList in ChildMap.Values do ChildList.Free;
    ChildMap.Free;
    RootCode.Free;
  end;
end;

procedure TfrmModalAnalyse.InternalApplyCodeFilter(Tree: TLazVirtualStringTree; const Filter: String);
var
  SearchTerm: String;
  function ProcessNode(ANode: PVirtualNode): Boolean;
  var
    AData: PInteger;
    Child: PVirtualNode;
    AnyChildMatch, NodeMatches: Boolean;
  begin
    AData := Tree.GetNodeData(ANode);
    AnyChildMatch := False;
    Child := ANode^.FirstChild;
    while Assigned(Child) do
    begin
      if ProcessNode(Child) then AnyChildMatch := True;
      Child := Child^.NextSibling;
    end;
    if Assigned(AData) then
      NodeMatches := (Filter = '') or (Pos(SearchTerm, LowerCase(FCodeCacheArray[AData^].Name)) > 0)
    else
      NodeMatches := False;
    Tree.IsVisible[ANode] := NodeMatches or AnyChildMatch;
    if (Filter <> '') and (NodeMatches or AnyChildMatch) then
      Tree.Expanded[ANode] := True;
    Result := Tree.IsVisible[ANode];
  end;
var
  RootNode: PVirtualNode;
begin
  SearchTerm := LowerCase(Trim(Filter));
  Tree.BeginUpdate;
  try
    RootNode := Tree.GetFirst;
    while Assigned(RootNode) do
    begin
      ProcessNode(RootNode);
      RootNode := RootNode^.NextSibling;
    end;
  finally
    Tree.EndUpdate;
  end;
end;

function TfrmModalAnalyse.GetDictionaryForTree(Tree: TLazVirtualStringTree): specialize TDictionary<String, Boolean>;
begin
  if Tree = vstFrequencyCode then Result := FCheckedFrequencyCode
  else if Tree = vstCoOccurrenceX then Result := FCheckedCoOccurrenceXCode
  else if Tree = vstCoOccurrenceY then Result := FCheckedCoOccurrenceYCode
  else if Tree = vstCrosstabCode then Result := FCheckedCrosstabCode
  else if Tree = vstWordCloudCode then Result := FCheckedCloudCode
  else Result := nil;
end;

procedure TfrmModalAnalyse.vstCodeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var
  DataPtr: PInteger;
  Dict: specialize TDictionary<String, Boolean>;
begin
  Node^.CheckType := ctCheckBox;
  Dict := GetDictionaryForTree(Sender as TLazVirtualStringTree);
  if Assigned(Dict) then
  begin
    DataPtr := Sender.GetNodeData(Node);
    if Assigned(DataPtr) and Dict.ContainsKey(FCodeCacheArray[DataPtr^].ID) then
      Sender.CheckState[Node] := csCheckedNormal
    else
      Sender.CheckState[Node] := csUncheckedNormal;
  end;
end;

procedure TfrmModalAnalyse.vstChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Dict: specialize TDictionary<String, Boolean>;
  TargetState: TCheckState;
  StartNode, EndNode, CurrentNode: PVirtualNode;
  procedure ApplyCheck(ANode: PVirtualNode; AState: TCheckState);
  var
    Child: PVirtualNode;
    DataPtr: PInteger;
  begin
    if Sender.CheckState[ANode] <> AState then
      Sender.CheckState[ANode] := AState;
    if Assigned(Dict) then
    begin
      DataPtr := Sender.GetNodeData(ANode);
      if Assigned(DataPtr) then
      begin
        if AState = csCheckedNormal then
          Dict.AddOrSetValue(FCodeCacheArray[DataPtr^].ID, True)
        else
          Dict.Remove(FCodeCacheArray[DataPtr^].ID);
      end;
    end;
    Child := ANode^.FirstChild;
    while Assigned(Child) do
    begin
      ApplyCheck(Child, AState);
      Child := Child^.NextSibling;
    end;
  end;
begin
  if FIsBatchOperation then Exit;
  Dict := GetDictionaryForTree(Sender as TLazVirtualStringTree);
  TargetState := Node^.CheckState;
  FIsBatchOperation := True;
  Sender.BeginUpdate;
  try
    if (GetKeyState(VK_SHIFT) < 0) and Assigned(FLastCheckedNode) and (FLastCheckedTree = Sender) then
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
    begin
      ApplyCheck(Node, TargetState);
    end;
  finally
    Sender.EndUpdate;
    FIsBatchOperation := False;
    FLastCheckedNode := Node;
    FLastCheckedTree := Sender;
  end;
end;

procedure TfrmModalAnalyse.vstCodeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var 
  DataPtr: PInteger;
begin
  DataPtr := Sender.GetNodeData(Node);
  if Assigned(DataPtr) and (DataPtr^ >= 0) and (DataPtr^ < Length(FCodeCacheArray)) then
    CellText := FCodeCacheArray[DataPtr^].Name;
end;

procedure TfrmModalAnalyse.vstCodeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
var 
  DataPtr: PInteger;
begin
  DataPtr := Sender.GetNodeData(Node);
  if Assigned(DataPtr) and (DataPtr^ >= 0) and (DataPtr^ < Length(FCodeCacheArray)) then
    HintText := TAppFormat.FormatUIHint(FCodeCacheArray[DataPtr^].Name);
end;

procedure TfrmModalAnalyse.vstCodeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var 
  DataPtr: PInteger;
begin
  DataPtr := Sender.GetNodeData(Node);
  if Assigned(DataPtr) then Finalize(DataPtr^);
end;

procedure TfrmModalAnalyse.LoadDocumentTree(const FilterText: String);
var
  FilterDefinition: TDocumentFilterDefinition;
begin
  FilterDefinition.IsFilterActive := False;
  FilterDefinition.QuickSearchText := FilterText;
  FilterDefinition.TitlePattern := '';
  FilterDefinition.BodyTextQuery := '';
  FilterDefinition.AttributeSQL := '';
  FDocumentCacheArray := FServiceDatabase.GetDocumentData(FilterDefinition, 'title', 'ASC', False);
  vstScopeDocument.BeginUpdate;
  try
    vstScopeDocument.Clear;
    vstScopeDocument.RootNodeCount := Length(FDocumentCacheArray);
    vstScopeDocument.Invalidate;
  finally
    vstScopeDocument.EndUpdate;
  end;
end;

procedure TfrmModalAnalyse.vstScopeDocumentInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  Node^.CheckType := ctCheckBox;
  if (Node^.Index < Cardinal(Length(FDocumentCacheArray))) then
  begin
    if FCheckedDocumentSet.ContainsKey(FDocumentCacheArray[Node^.Index].ID) then
      Sender.CheckState[Node] := csCheckedNormal
    else
      Sender.CheckState[Node] := csUncheckedNormal;
  end;
end;

procedure TfrmModalAnalyse.vstScopeDocumentChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  TargetState: TCheckState;
  StartNode, EndNode, CurrentNode: PVirtualNode;
  procedure ApplyDocCheck(ANode: PVirtualNode; AState: TCheckState);
  var DocumentID: String;
  begin
    if Sender.CheckState[ANode] <> AState then
      Sender.CheckState[ANode] := AState;
    if (ANode^.Index >= 0) and (ANode^.Index < Length(FDocumentCacheArray)) then
    begin
      DocumentID := FDocumentCacheArray[ANode^.Index].ID;
      if AState = csCheckedNormal then
        FCheckedDocumentSet.AddOrSetValue(DocumentID, True)
      else
        FCheckedDocumentSet.Remove(DocumentID);
    end;
  end;
begin
  if FIsBatchOperation then Exit;
  TargetState := Node^.CheckState;
  FIsBatchOperation := True;
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
    begin
      ApplyDocCheck(Node, TargetState);
    end;
  finally
    Sender.EndUpdate;
    FIsBatchOperation := False;
    FLastCheckedDocNode := Node;
  end;
end;

procedure TfrmModalAnalyse.vstScopeDocumentGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
begin
  if (Node^.Index < Cardinal(Length(FDocumentCacheArray))) then
    CellText := FDocumentCacheArray[Node^.Index].Title;
end;

procedure TfrmModalAnalyse.vstScopeDocumentGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
begin
  if (Node^.Index < Cardinal(Length(FDocumentCacheArray))) then
    HintText := TAppFormat.FormatUIHint(FDocumentCacheArray[Node^.Index].Title);
end;

procedure TfrmModalAnalyse.vstScopeDocumentFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
end;

procedure TfrmModalAnalyse.LoadAttributeTree(const FilterText: String);
var
  Q: TSQLQuery;
  Count, Capacity: Integer;
begin
  Q := TSQLQuery.Create(nil);
  Q.Database := frmAppBase.conMain;
  try
    Q.SQL.Text := 'SELECT id, name, attribute_key, attribute_type FROM attribute_registry';
    if FilterText <> '' then
      Q.SQL.Add(' WHERE name LIKE ' + QuotedStr('%' + FilterText + '%'));
    Q.SQL.Add(' ORDER BY name');
    Q.Open;
    Count := 0;
    Capacity := Max(128, Q.RecordCount);
    SetLength(FAttributeCacheArray, Capacity);
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FAttributeCacheArray, Capacity);
      end;
      FAttributeCacheArray[Count].ID := Q.FieldByName('id').AsString;
      FAttributeCacheArray[Count].Name := Q.FieldByName('name').AsString;
      FAttributeCacheArray[Count].Key := Q.FieldByName('attribute_key').AsString;
      FAttributeCacheArray[Count].AttributeType := Q.FieldByName('attribute_type').AsString;
      FAttributeCacheArray[Count].OperatorVal := '';
      FAttributeCacheArray[Count].FilterValue := '';
      Inc(Count);
      Q.Next;
    end;
    SetLength(FAttributeCacheArray, Count);
    vstScopeAttribute.BeginUpdate;
    try
      vstScopeAttribute.Clear;
      vstScopeAttribute.RootNodeCount := Count;
      vstScopeAttribute.Invalidate;
    finally
      vstScopeAttribute.EndUpdate;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmModalAnalyse.vstScopeAttributeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Index: Integer;
  Op: String;
begin
  Index := Node^.Index;
  if (Index < 0) or (Index >= Length(FAttributeCacheArray)) then Exit;
  case Column of
    0: CellText := FAttributeCacheArray[Index].Name;
    1: CellText := FAttributeCacheArray[Index].OperatorVal;
    2: begin
         Op := FAttributeCacheArray[Index].OperatorVal;
         if (Op = 'Is Empty') or (Op = 'Is Not Empty') then
           CellText := '-'
         else
           CellText := StringReplace(FAttributeCacheArray[Index].FilterValue, '|', ' to ', []);
       end;
  end;
end;

procedure TfrmModalAnalyse.vstScopeAttributePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
begin
  TargetCanvas.Font.Color := clWindowText;
end;

procedure TfrmModalAnalyse.vstScopeAttributeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
var
  Index: Integer;
begin
  Index := Node^.Index;
  if (Index >= 0) and (Index < Length(FAttributeCacheArray)) then
  begin
    case Column of
      0: HintText := TAppFormat.FormatUIHint(FAttributeCacheArray[Index].Name);
      1: HintText := TAppFormat.FormatUIHint(FAttributeCacheArray[Index].OperatorVal);
      2: HintText := TAppFormat.FormatUIHint(StringReplace(FAttributeCacheArray[Index].FilterValue, '|', ' to ', []));
    end;
  end;
end;

procedure TfrmModalAnalyse.vstScopeAttributeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if Assigned(Node) and (Node^.Index < Cardinal(Length(FAttributeCacheArray))) and (vsSelected in Node^.States) then
  begin
    FCurrentAttributeIndex := Node^.Index;
    LoadAttributeDefinitionPane(FCurrentAttributeIndex);
  end
  else if Sender.SelectedCount = 0 then
  begin
    FCurrentAttributeIndex := -1;
    pnlAttributeFilterDef.Visible := False;
  end;
end;

procedure TfrmModalAnalyse.vstScopeAttributeHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
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
  for i := 0 to High(FAttributeCacheArray) - 1 do
  begin
    for j := i + 1 to High(FAttributeCacheArray) do
    begin
      Swap := False;
      if Col = 0 then
      begin
        if FAttributeSortAscending then Swap := AnsiCompareText(FAttributeCacheArray[i].Name, FAttributeCacheArray[j].Name) > 0
        else Swap := AnsiCompareText(FAttributeCacheArray[i].Name, FAttributeCacheArray[j].Name) < 0;
      end
      else
      begin
        HasFilterI := FAttributeCacheArray[i].OperatorVal <> '';
        HasFilterJ := FAttributeCacheArray[j].OperatorVal <> '';
        if HasFilterI <> HasFilterJ then
          Swap := HasFilterJ and not HasFilterI
        else if FAttributeSortAscending then Swap := AnsiCompareText(FAttributeCacheArray[i].Name, FAttributeCacheArray[j].Name) > 0
        else Swap := AnsiCompareText(FAttributeCacheArray[i].Name, FAttributeCacheArray[j].Name) < 0;
      end;
      if Swap then
      begin
        Temp := FAttributeCacheArray[i];
        FAttributeCacheArray[i] := FAttributeCacheArray[j];
        FAttributeCacheArray[j] := Temp;
      end;
    end;
  end;
  vstScopeAttribute.ClearSelection;
  FCurrentAttributeIndex := -1;
  pnlAttributeFilterDef.Visible := False;
  vstScopeAttribute.Invalidate;
end;

procedure TfrmModalAnalyse.vstScopeNoFocusChanging(Sender: TBaseVirtualTree; OldNode, NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex; var Allowed: Boolean);
begin
  Allowed := False;
end;

procedure TfrmModalAnalyse.LoadAttributeDefinitionPane(NodeIndex: Integer);
var
  SavedValue, SafeValueFirst, SafeValueSecond: String;
  PipePos: Integer;
  FmtSettings: TFormatSettings;
  DummyDate: TDateTime;
begin
  FmtSettings := DefaultFormatSettings;
  FmtSettings.DateSeparator := '-';
  FmtSettings.ShortDateFormat := 'yyyy-mm-dd';
  pnlAttributeFilterDef.Visible := True;
  UpdateAttributeOperator(FAttributeCacheArray[NodeIndex].AttributeType);
  SavedValue := FAttributeCacheArray[NodeIndex].FilterValue;
  if FAttributeCacheArray[NodeIndex].OperatorVal <> '' then
    cmbScopeAttributeOperator.ItemIndex := cmbScopeAttributeOperator.Items.IndexOf(FAttributeCacheArray[NodeIndex].OperatorVal);
  cmbScopeAttributeOperatorChange(nil);
  if edtScopeAttributeValueText.Visible then
  begin
    edtScopeAttributeValueText.Text := SavedValue;
    edtScopeAttributeValueText.SetFocus;
  end
  else if pnlScopeAttributeValueNumeric.Visible then
  begin
    PipePos := Pos('|', SavedValue);
    if (cmbScopeAttributeOperator.Text = 'Between') and (PipePos > 0) then
    begin
      SafeValueFirst := StringReplace(Copy(SavedValue, 1, PipePos - 1), '.', DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
      SafeValueSecond := StringReplace(Copy(SavedValue, PipePos + 1, MaxInt), '.', DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
      fseScopeAttributeValueNum.Value := StrToFloatDef(SafeValueFirst, 0);
      fseScopeAttributeValueNumEnd.Value := StrToFloatDef(SafeValueSecond, 0);
    end
    else
    begin
      SafeValueFirst := StringReplace(SavedValue, '.', DefaultFormatSettings.DecimalSeparator, [rfReplaceAll]);
      fseScopeAttributeValueNum.Value := StrToFloatDef(SafeValueFirst, 0);
      fseScopeAttributeValueNumEnd.Value := 0;
    end;
    fseScopeAttributeValueNum.SetFocus;
  end
  else if pnlScopeAttributeValueDate.Visible then
  begin
    PipePos := Pos('|', SavedValue);
    if (cmbScopeAttributeOperator.Text = 'Between') and (PipePos > 0) then
    begin
      if TryStrToDate(Copy(SavedValue, 1, PipePos - 1), DummyDate, FmtSettings) then deScopeAttributeValueDate.Date := DummyDate else deScopeAttributeValueDate.Date := Date;
      if TryStrToDate(Copy(SavedValue, PipePos + 1, MaxInt), DummyDate, FmtSettings) then deScopeAttributeValueDateEnd.Date := DummyDate else deScopeAttributeValueDateEnd.Date := Date;
    end
    else
    begin
      if TryStrToDate(SavedValue, DummyDate, FmtSettings) then deScopeAttributeValueDate.Date := DummyDate else deScopeAttributeValueDate.Date := Date;
      deScopeAttributeValueDateEnd.Date := Date;
    end;
    deScopeAttributeValueDate.SetFocus;
  end
  else if cmbScopeAttributeValueCat.Visible then
  begin
    cmbScopeAttributeValueCat.Text := SavedValue;
    cmbScopeAttributeValueCat.SetFocus;
  end;
end;

procedure TfrmModalAnalyse.UpdateAttributeOperator(const AttributeType: String);
var
  TypeIndex: Integer;
begin
  cmbScopeAttributeOperator.Items.BeginUpdate;
  try
    cmbScopeAttributeOperator.Items.Clear;
    TypeIndex := IndexStr(AttributeType, ['Text', 'Numeric', 'Date-Time', 'Categorical', 'URL or Path']);
    edtScopeAttributeValueText.Visible := (TypeIndex = 0) or (TypeIndex = 4);
    pnlScopeAttributeValueNumeric.Visible := (TypeIndex = 1);
    pnlScopeAttributeValueDate.Visible := (TypeIndex = 2);
    cmbScopeAttributeValueCat.Visible := (TypeIndex = 3);
    fseScopeAttributeValueNumEnd.Visible := False;
    deScopeAttributeValueDateEnd.Visible := False;
    if pnlScopeAttributeValueDate.Visible then
    begin
      deScopeAttributeValueDate.Date := Date;
      deScopeAttributeValueDateEnd.Date := Date;
    end;
    case TypeIndex of
      0, 4:
        begin
          cmbScopeAttributeOperator.Items.Add('Equals');
          cmbScopeAttributeOperator.Items.Add('Does Not Equal');
          cmbScopeAttributeOperator.Items.Add('Contains');
          cmbScopeAttributeOperator.Items.Add('Does Not Contain');
          cmbScopeAttributeOperator.Items.Add('Starts With');
          cmbScopeAttributeOperator.Items.Add('Ends With');
        end;
      1:
        begin
          cmbScopeAttributeOperator.Items.Add('Equals');
          cmbScopeAttributeOperator.Items.Add('Does Not Equal');
          cmbScopeAttributeOperator.Items.Add('Greater Than');
          cmbScopeAttributeOperator.Items.Add('Less Than');
          cmbScopeAttributeOperator.Items.Add('Greater or Equal');
          cmbScopeAttributeOperator.Items.Add('Less or Equal');
          cmbScopeAttributeOperator.Items.Add('Between');
        end;
      2:
        begin
          cmbScopeAttributeOperator.Items.Add('On');
          cmbScopeAttributeOperator.Items.Add('Not On');
          cmbScopeAttributeOperator.Items.Add('After');
          cmbScopeAttributeOperator.Items.Add('Before');
          cmbScopeAttributeOperator.Items.Add('On or After');
          cmbScopeAttributeOperator.Items.Add('On or Before');
          cmbScopeAttributeOperator.Items.Add('Between');
        end;
      3:
        begin
          cmbScopeAttributeOperator.Items.Add('Equals');
          cmbScopeAttributeOperator.Items.Add('Does Not Equal');
          LoadCategoricalValue;
        end;
    end;
    cmbScopeAttributeOperator.Items.Add('Is Empty');
    cmbScopeAttributeOperator.Items.Add('Is Not Empty');
    cmbScopeAttributeOperator.ItemIndex := 0;
  finally
    cmbScopeAttributeOperator.Items.EndUpdate;
  end;
end;

procedure TfrmModalAnalyse.cmbScopeAttributeOperatorChange(Sender: TObject);
var
  Op: String;
begin
  Op := cmbScopeAttributeOperator.Text;
  pnlScopeAttributeValue.Visible := (Op <> 'Is Empty') and (Op <> 'Is Not Empty');
  fseScopeAttributeValueNumEnd.Visible := (pnlScopeAttributeValueNumeric.Visible) and (Op = 'Between');
  deScopeAttributeValueDateEnd.Visible := (pnlScopeAttributeValueDate.Visible) and (Op = 'Between');
end;

procedure TfrmModalAnalyse.LoadCategoricalValue;
var
  Q: TSQLQuery;
  ColumnName: String;
begin
  if FCurrentAttributeIndex = -1 then Exit;
  cmbScopeAttributeValueCat.Items.Clear;
  ColumnName := FAttributeCacheArray[FCurrentAttributeIndex].Key;
  Q := TSQLQuery.Create(nil);
  Q.Database := frmAppBase.conMain;
  try
    Q.SQL.Text := 'SELECT DISTINCT ' + ColumnName + ' FROM document_attributes WHERE ' + ColumnName + ' IS NOT NULL ORDER BY ' + ColumnName;
    Q.Open;
    while not Q.EOF do
    begin
      cmbScopeAttributeValueCat.Items.Add(Q.Fields[0].AsString);
      Q.Next;
    end;
    if cmbScopeAttributeValueCat.Items.Count > 0 then cmbScopeAttributeValueCat.ItemIndex := 0;
  finally
    Q.Free;
  end;
end;

procedure TfrmModalAnalyse.btnScopeAttributeApplyClick(Sender: TObject);
var
  CurrentValue, Op: String;
begin
  if FCurrentAttributeIndex = -1 then Exit;
  Op := cmbScopeAttributeOperator.Text;
  if (Op = 'Is Empty') or (Op = 'Is Not Empty') then
    CurrentValue := ''
  else if edtScopeAttributeValueText.Visible then
    CurrentValue := Trim(edtScopeAttributeValueText.Text)
  else if pnlScopeAttributeValueNumeric.Visible then
  begin
    CurrentValue := FloatToStr(fseScopeAttributeValueNum.Value);
    if Op = 'Between' then
      CurrentValue := CurrentValue + '|' + FloatToStr(fseScopeAttributeValueNumEnd.Value);
  end
  else if pnlScopeAttributeValueDate.Visible then
  begin
    CurrentValue := FormatDateTime('yyyy"-"mm"-"dd', deScopeAttributeValueDate.Date);
    if Op = 'Between' then
      CurrentValue := CurrentValue + '|' + FormatDateTime('yyyy"-"mm"-"dd', deScopeAttributeValueDateEnd.Date);
  end
  else if cmbScopeAttributeValueCat.Visible then
    CurrentValue := Trim(cmbScopeAttributeValueCat.Text);
  if ((Op <> 'Is Empty') and (Op <> 'Is Not Empty')) and (CurrentValue = '') then
  begin
    MessageDlg('Validation Error', 'Please provide a value for the filter, or select the "Is Empty"/"Is Not Empty" operator if you wish to find unassigned records.', mtWarning, [mbOK], 0);
    Exit;
  end;
  FAttributeCacheArray[FCurrentAttributeIndex].OperatorVal := Op;
  FAttributeCacheArray[FCurrentAttributeIndex].FilterValue := CurrentValue;
  vstScopeAttribute.InvalidateNode(vstScopeAttribute.FocusedNode);
end;

procedure TfrmModalAnalyse.btnScopeAttributeClearClick(Sender: TObject);
begin
  if FCurrentAttributeIndex = -1 then Exit;
  FAttributeCacheArray[FCurrentAttributeIndex].OperatorVal := '';
  FAttributeCacheArray[FCurrentAttributeIndex].FilterValue := '';
  vstScopeAttribute.InvalidateNode(vstScopeAttribute.FocusedNode);
  edtScopeAttributeValueText.Clear;
  fseScopeAttributeValueNum.Value := 0;
  fseScopeAttributeValueNumEnd.Value := 0;
  fseScopeAttributeValueNumEnd.Visible := False;
  deScopeAttributeValueDate.Date := Date;
  deScopeAttributeValueDateEnd.Date := Date;
  deScopeAttributeValueDateEnd.Visible := False;
  if cmbScopeAttributeValueCat.Items.Count > 0 then cmbScopeAttributeValueCat.ItemIndex := 0;
  cmbScopeAttributeOperator.ItemIndex := 0;
end;

procedure TfrmModalAnalyse.btnScopeAttributeClearAllClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to High(FAttributeCacheArray) do
  begin
    FAttributeCacheArray[i].OperatorVal := '';
    FAttributeCacheArray[i].FilterValue := '';
  end;
  vstScopeAttribute.Invalidate;
  edtScopeAttributeValueText.Clear;
  fseScopeAttributeValueNum.Value := 0;
  fseScopeAttributeValueNumEnd.Value := 0;
  fseScopeAttributeValueNumEnd.Visible := False;
  deScopeAttributeValueDate.Date := Date;
  deScopeAttributeValueDateEnd.Date := Date;
  deScopeAttributeValueDateEnd.Visible := False;
  if cmbScopeAttributeValueCat.Items.Count > 0 then cmbScopeAttributeValueCat.ItemIndex := 0;
  if cmbScopeAttributeOperator.Items.Count > 0 then cmbScopeAttributeOperator.ItemIndex := 0;
end;

procedure TfrmModalAnalyse.ToggleTreeNodes(Tree: TLazVirtualStringTree; Check: Boolean);
var
  Node: PVirtualNode;
  DataPtr: PInteger;
  CodeDict: specialize TDictionary<String, Boolean>;
  i: Integer;
begin
  if not Assigned(Tree) then Exit;
  FIsBatchOperation := True;
  Tree.BeginUpdate;
  try
    if Tree = vstScopeDocument then
    begin
      for i := 0 to High(FDocumentCacheArray) do
      begin
        if Check then
          FCheckedDocumentSet.AddOrSetValue(FDocumentCacheArray[i].ID, True)
        else
          FCheckedDocumentSet.Remove(FDocumentCacheArray[i].ID);
      end;
      Tree.ReinitChildren(nil, True);
    end
    else
    begin
      CodeDict := GetDictionaryForTree(Tree);
      if not Assigned(CodeDict) then Exit;
      Node := Tree.GetFirst;
      while Assigned(Node) do
      begin
        if Tree.IsVisible[Node] then
        begin
          DataPtr := Tree.GetNodeData(Node);
          if Assigned(DataPtr) then
          begin
            if Check then
              CodeDict.AddOrSetValue(FCodeCacheArray[DataPtr^].ID, True)
            else
              CodeDict.Remove(FCodeCacheArray[DataPtr^].ID);
          end;
          if Check then Tree.CheckState[Node] := csCheckedNormal
          else Tree.CheckState[Node] := csUncheckedNormal;
        end;
        Node := Tree.GetNext(Node);
      end;
    end;
  finally
    Tree.EndUpdate;
    FIsBatchOperation := False;
  end;
end;

procedure TfrmModalAnalyse.btnFrequencySelectAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstFrequencyCode, True);
end;

procedure TfrmModalAnalyse.btnFrequencyClearAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstFrequencyCode, False);
end;

procedure TfrmModalAnalyse.btnCoOccurrenceXSelectAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstCoOccurrenceX, True);
end;

procedure TfrmModalAnalyse.btnCoOccurrenceXClearAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstCoOccurrenceX, False);
end;

procedure TfrmModalAnalyse.btnCoOccurrenceYSelectAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstCoOccurrenceY, True);
end;

procedure TfrmModalAnalyse.btnCoOccurrenceYClearAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstCoOccurrenceY, False);
end;

procedure TfrmModalAnalyse.btnCrosstabSelectAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstCrosstabCode, True);
end;

procedure TfrmModalAnalyse.btnCrossClearAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstCrosstabCode, False);
end;

procedure TfrmModalAnalyse.btnCloudSelectAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstWordCloudCode, True);
end;

procedure TfrmModalAnalyse.btnCloudClearAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstWordCloudCode, False);
end;

procedure TfrmModalAnalyse.btnScopeDocumentSelectAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstScopeDocument, True);
end;

procedure TfrmModalAnalyse.btnScopeDocumentClearAllClick(Sender: TObject);
begin
  ToggleTreeNodes(vstScopeDocument, False);
end;

procedure TfrmModalAnalyse.edtSearchFrequencyChange(Sender: TObject);
begin
  tmrFrequencySearch.Enabled := False; tmrFrequencySearch.Enabled := True;
end;

procedure TfrmModalAnalyse.edtSearchCoOccurrenceXChange(Sender: TObject);
begin
  tmrCoOccurrenceXSearch.Enabled := False; tmrCoOccurrenceXSearch.Enabled := True;
end;

procedure TfrmModalAnalyse.edtSearchCoOccurrenceYChange(Sender: TObject);
begin
  tmrCoOccurrenceYSearch.Enabled := False; tmrCoOccurrenceYSearch.Enabled := True;
end;

procedure TfrmModalAnalyse.edtSearchCrosstabChange(Sender: TObject);
begin
  tmrCrosstabSearch.Enabled := False; tmrCrosstabSearch.Enabled := True;
end;

procedure TfrmModalAnalyse.edtSearchCloudChange(Sender: TObject);
begin
  tmrCloudSearch.Enabled := False; tmrCloudSearch.Enabled := True;
end;

procedure TfrmModalAnalyse.edtSearchScopeDocumentChange(Sender: TObject);
begin
  tmrScopeDocumentSearch.Enabled := False; tmrScopeDocumentSearch.Enabled := True;
end;

procedure TfrmModalAnalyse.edtSearchScopeAttributeChange(Sender: TObject);
begin
  tmrScopeAttributeSearch.Enabled := False; tmrScopeAttributeSearch.Enabled := True;
end;

procedure TfrmModalAnalyse.tmrFrequencySearchTimer(Sender: TObject);
begin
  tmrFrequencySearch.Enabled := False;
  if edtSearchFrequency.Text = '' then
  begin
    btnFrequencySelectAll.Caption := 'Select All';
    btnFrequencyClearAll.Caption := 'Clear All';
  end
  else
  begin
    btnFrequencySelectAll.Caption := 'Select Filtered';
    btnFrequencyClearAll.Caption := 'Clear Filtered';
  end;
  InternalApplyCodeFilter(vstFrequencyCode, edtSearchFrequency.Text);
end;

procedure TfrmModalAnalyse.tmrCoOccurrenceXSearchTimer(Sender: TObject);
begin
  tmrCoOccurrenceXSearch.Enabled := False;
  if edtSearchCoOccurrenceX.Text = '' then
  begin
    btnCoOccurrenceXSelectAll.Caption := 'Select All';
    btnCoOccurrenceXClearAll.Caption := 'Clear All';
  end
  else
  begin
    btnCoOccurrenceXSelectAll.Caption := 'Select Filtered';
    btnCoOccurrenceXClearAll.Caption := 'Clear Filtered';
  end;
  InternalApplyCodeFilter(vstCoOccurrenceX, edtSearchCoOccurrenceX.Text);
end;

procedure TfrmModalAnalyse.tmrCoOccurrenceYSearchTimer(Sender: TObject);
begin
  tmrCoOccurrenceYSearch.Enabled := False;
  if edtSearchCoOccurrenceY.Text = '' then
  begin
    btnCoOccurrenceYSelectAll.Caption := 'Select All';
    btnCoOccurrenceYClearAll.Caption := 'Clear All';
  end
  else
  begin
    btnCoOccurrenceYSelectAll.Caption := 'Select Filtered';
    btnCoOccurrenceYClearAll.Caption := 'Clear Filtered';
  end;
  InternalApplyCodeFilter(vstCoOccurrenceY, edtSearchCoOccurrenceY.Text);
end;

procedure TfrmModalAnalyse.tmrCrosstabSearchTimer(Sender: TObject);
begin
  tmrCrosstabSearch.Enabled := False;
  if edtSearchCrosstab.Text = '' then
  begin
    btnCrosstabSelectAll.Caption := 'Select All';
    btnCrossClearAll.Caption := 'Clear All';
  end
  else
  begin
    btnCrosstabSelectAll.Caption := 'Select Filtered';
    btnCrossClearAll.Caption := 'Clear Filtered';
  end;
  InternalApplyCodeFilter(vstCrosstabCode, edtSearchCrosstab.Text);
end;

procedure TfrmModalAnalyse.tmrCloudSearchTimer(Sender: TObject);
begin
  tmrCloudSearch.Enabled := False;
  if edtSearchCloud.Text = '' then
  begin
    btnCloudSelectAll.Caption := 'Select All';
    btnCloudClearAll.Caption := 'Clear All';
  end
  else
  begin
    btnCloudSelectAll.Caption := 'Select Filtered';
    btnCloudClearAll.Caption := 'Clear Filtered';
  end;
  InternalApplyCodeFilter(vstWordCloudCode, edtSearchCloud.Text);
end;

procedure TfrmModalAnalyse.tmrScopeDocumentSearchTimer(Sender: TObject);
begin
  tmrScopeDocumentSearch.Enabled := False;
  if edtSearchScopeDocument.Text = '' then
  begin
    btnScopeDocumentSelectAll.Caption := 'Select All';
    btnScopeDocumentClearAll.Caption := 'Clear All';
  end
  else
  begin
    btnScopeDocumentSelectAll.Caption := 'Select Filtered';
    btnScopeDocumentClearAll.Caption := 'Clear Filtered';
  end;
  LoadDocumentTree(edtSearchScopeDocument.Text);
end;

procedure TfrmModalAnalyse.tmrScopeAttributeSearchTimer(Sender: TObject);
begin
  tmrScopeAttributeSearch.Enabled := False;
  ApplyAttributeFilter(edtSearchScopeAttribute.Text);
end;

procedure TfrmModalAnalyse.SearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    if Sender = edtSearchFrequency then tmrFrequencySearchTimer(nil)
    else if Sender = edtSearchCoOccurrenceX then tmrCoOccurrenceXSearchTimer(nil)
    else if Sender = edtSearchCoOccurrenceY then tmrCoOccurrenceYSearchTimer(nil)
    else if Sender = edtSearchCrosstab then tmrCrosstabSearchTimer(nil)
    else if Sender = edtSearchCloud then tmrCloudSearchTimer(nil)
    else if Sender = edtSearchScopeDocument then tmrScopeDocumentSearchTimer(nil)
    else if Sender = edtSearchScopeAttribute then tmrScopeAttributeSearchTimer(nil);
    Key := 0;
  end;
end;

function TfrmModalAnalyse.GetCheckedTreeIDs(Tree: TLazVirtualStringTree; MaxLimit: Integer = 0): TStringDynArray;
var
  Dict: specialize TDictionary<String, Boolean>;
  Key: String;
  Count: Integer;
begin
  Result := nil;
  Dict := GetDictionaryForTree(Tree);
  if not Assigned(Dict) or (Dict.Count = 0) then Exit(nil);
  Count := 0;
  SetLength(Result, Dict.Count);
  for Key in Dict.Keys do
  begin
    Inc(Count);
    if (MaxLimit > 0) and (Count > MaxLimit) then
    begin
      MessageDlg('Selection Limit', Format('Please select a maximum of %d items for this analysis.', [MaxLimit]), mtWarning, [mbOK], 0);
      SetLength(Result, 0);
      Exit;
    end;
    Result[Count - 1] := Key;
  end;
  SetLength(Result, Count);
end;

function TfrmModalAnalyse.GetCheckedDocumentID(MaxLimit: Integer = 0): TStringDynArray;
var
  Key: String;
  Count: Integer;
begin
  Result := nil;
  Count := 0;
  SetLength(Result, FCheckedDocumentSet.Count);
  if FCheckedDocumentSet.Count = 0 then Exit;
  for Key in FCheckedDocumentSet.Keys do
  begin
    Inc(Count);
    if (MaxLimit > 0) and (Count > MaxLimit) then
    begin
      MessageDlg('Selection Limit', Format('Please select a maximum of %d items for this analysis.', [MaxLimit]), mtWarning, [mbOK], 0);
      SetLength(Result, 0);
      Exit;
    end;
    Result[Count - 1] := Key;
  end;
end;

procedure TfrmModalAnalyse.SetupGrid(const ColumnArray: array of String; const ColumnWidthArray: array of Integer; RowCount: Integer);
var
  i: Integer;
  Col: TVirtualTreeColumn;
begin
  if not Assigned(vstResultGrid) then Exit;
  vstResultGrid.Header.Options := vstResultGrid.Header.Options - [hoAutoResize];
  vstResultGrid.Header.AutoSizeIndex := -1;
  vstResultGrid.BeginUpdate;
  try
    vstResultGrid.Clear;
    vstResultGrid.Header.Columns.Clear;
    for i := 0 to High(ColumnArray) do
    begin
      Col := vstResultGrid.Header.Columns.Add;
      Col.Text := ColumnArray[i];
      if i <= High(ColumnWidthArray) then Col.Width := ColumnWidthArray[i] else Col.Width := 150;
      Col.Options := Col.Options - [coAutoSpring];
    end;
    vstResultGrid.RootNodeCount := RowCount;
  finally
    vstResultGrid.EndUpdate;
  end;
  vstResultGrid.Header.Options := [hoAutoResize, hoColumnResize, hoVisible];
  vstResultGrid.Header.AutoSizeIndex := High(ColumnArray);
  if Assigned(pnlGrid) then pnlGrid.Visible := (RowCount > 0);
  if Assigned(splResults) then splResults.Visible := pnlGrid.Visible;
end;

procedure TfrmModalAnalyse.vstResultGridGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Index: Integer;
begin
  Index := Node^.Index;
  CellText := '';
  case FActiveAnalysis of
    0: if (Index >= 0) and (Index < Length(FFrequencyResult)) then
       begin
         case Column of
           0: CellText := GetFullCodePath(FFrequencyResult[Index].CodeID);
           1: CellText := IntToStr(FFrequencyResult[Index].SegmentCount);
           2: CellText := IntToStr(FFrequencyResult[Index].DocumentCount);
         end;
       end;
    1: if (Index >= 0) and (Index < Length(FCoOccurrenceResult)) then
       begin
         case Column of
           0: CellText := GetFullCodePath(FCoOccurrenceResult[Index].Code1ID);
           1: CellText := GetFullCodePath(FCoOccurrenceResult[Index].Code2ID);
           2: CellText := IntToStr(FCoOccurrenceResult[Index].Overlap);
         end;
       end;
    2: if (Index >= 0) and (Index < Length(FCrossResult)) then
       begin
         case Column of
           0: CellText := GetFullCodePath(FCrossResult[Index].CodeID);
           1: CellText := FCrossResult[Index].AttributeValue;
           2: CellText := IntToStr(FCrossResult[Index].Frequency);
         end;
       end;
    3: if (Index >= 0) and (Index < Length(FCoverageResult)) then
       begin
         case Column of
           0: CellText := FCoverageResult[Index].DocumentName;
           1: CellText := IntToStr(FCoverageResult[Index].TotalCharacters);
           2: CellText := IntToStr(FCoverageResult[Index].CodedCharacters);
           3: if FCoverageResult[Index].TotalCharacters > 0 then
                CellText := FormatFloat('0.00', (FCoverageResult[Index].CodedCharacters / FCoverageResult[Index].TotalCharacters) * 100) + '%'
              else CellText := '0.00%';
         end;
       end;
    4: if (Index >= 0) and (Index < Length(FCloudResult)) then
       begin
         case Column of
           0: CellText := FCloudResult[Index].Word;
           1: CellText := IntToStr(FCloudResult[Index].Frequency);
         end;
       end;
  end;
end;

procedure TfrmModalAnalyse.vstResultGridGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: String);
var
  Index: Integer;
begin
  Index := Node^.Index;
  HintText := '';
  case FActiveAnalysis of
    0: if Column = 0 then HintText := GetFullCodePath(FFrequencyResult[Index].CodeID);
    1: if Column = 0 then HintText := GetFullCodePath(FCoOccurrenceResult[Index].Code1ID)
       else if Column = 1 then HintText := GetFullCodePath(FCoOccurrenceResult[Index].Code2ID);
    2: if Column = 0 then HintText := GetFullCodePath(FCrossResult[Index].CodeID);
    3: if Column = 0 then HintText := FCoverageResult[Index].DocumentName;
  end;
end;

procedure TfrmModalAnalyse.btnAnalyseClick(Sender: TObject);
var
  HasCodeSelection, HasDocSelection: Boolean;
  VisWorker: TThreadPrepareVisualization;
  CurrentLimit: Integer;
begin
  if csLoading in ComponentState then Exit;
  ResetResults;
  if Assigned(pcAnalysisType) then
    FActiveAnalysis := pcAnalysisType.ActivePageIndex
  else
    Exit;
  HasDocSelection := FCheckedDocumentSet.Count > 0;
  HasCodeSelection := True;
  case FActiveAnalysis of
    0: HasCodeSelection := FCheckedFrequencyCode.Count > 0;
    1: HasCodeSelection := (FCheckedCoOccurrenceXCode.Count > 0) or (FCheckedCoOccurrenceYCode.Count > 0);
    2: HasCodeSelection := FCheckedCrosstabCode.Count > 0;
    3: HasCodeSelection := True;
    4: HasCodeSelection := FCheckedCloudCode.Count > 0;
  end;
  if not HasDocSelection or not HasCodeSelection then
  begin
    FAnalysisState := asNoSelection;
    if Assigned(pbxVisualization) then pbxVisualization.Invalidate;
    Exit;
  end;
  if (FActiveAnalysis = 2) and Assigned(cmbCrossAttribute) and (cmbCrossAttribute.ItemIndex = -1) then
  begin
    FAnalysisState := asMissingAttribute;
    if Assigned(pbxVisualization) then pbxVisualization.Invalidate;
    Exit;
  end;
  FAnalysisState := asRunning;
  if Assigned(pbxVisualization) then pbxVisualization.Invalidate;
  Application.ProcessMessages;
  Screen.Cursor := crHourGlass;
  try
    case FActiveAnalysis of
      0: ExecuteFrequency;
      1: ExecuteCoOccurrence;
      2: ExecuteCrosstab;
      3: ExecuteCoverage;
      4: ExecuteWordCloud;
    end;
    if (Length(FFrequencyResult) > 0) or (Length(FCoOccurrenceResult) > 0) or
       (Length(FCrossResult) > 0)  or (Length(FCoverageResult) > 0) or
       (Length(FCloudResult) > 0) then
    begin
      CurrentLimit := 1000000;
      if Assigned(chkEnableLimit) and Assigned(edtVisualizationLimit) then
      begin
        if (FActiveAnalysis = 4) or chkEnableLimit.Checked then
          CurrentLimit := edtVisualizationLimit.Value;
      end;
      VisWorker := TThreadPrepareVisualization.Create(True);
      VisWorker.FreeOnTerminate := False;
      VisWorker.FActiveAnalysis := FActiveAnalysis;
      VisWorker.FFrequencyResult := FFrequencyResult;
      VisWorker.FCoOccurrenceResult := FCoOccurrenceResult;
      VisWorker.FCrossResult := FCrossResult;
      VisWorker.FCoverageResult := FCoverageResult;
      VisWorker.FCloudResult := FCloudResult;
      VisWorker.FLimit := CurrentLimit;
      VisWorker.Start;
      TfrmDialogProgress.Prepare('Composing Visualisation', 'Measuring layout dimensions...');
      frmDialogProgress.ShowModal;
      if VisWorker.Success and Assigned(VisWorker.PreparedVisualization) then
      begin
        FVisualizer.Free;
        FVisualizer := VisWorker.PreparedVisualization;
        FVirtualWidth := VisWorker.VWidth;
        FVirtualHeight := VisWorker.VHeight;
        VisWorker.PreparedVisualization := nil; 
        ResetViewContext;
        FAnalysisState := asComplete;
        btnExportData.Enabled := True;
        btnSaveVisualization.Enabled := True;
      end
      else
      begin
        FAnalysisState := asNoResults;
        MessageDlg('Visualisation Error', 'Failed to build the visualisation: ' + VisWorker.ErrorMessage, mtError, [mbOK], 0);
      end;
      VisWorker.Free;
    end
    else
    begin
      FAnalysisState := asNoResults;
      btnExportData.Enabled := False;
      btnSaveVisualization.Enabled := False;
    end;
    if Assigned(pbxVisualization) then pbxVisualization.Invalidate;
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TfrmModalAnalyse.GetAttributeSQL: String;
var
  i, PipePos: Integer;
  AttributeString, Linker, Condition, ColumnName, OpSelection, AttributeValue, OpStr: String;
begin
  Result := '';
  if Length(FAttributeCacheArray) = 0 then Exit;
  if rgLogicMode.ItemIndex = 0 then Linker := ' AND ' else Linker := ' OR ';
  AttributeString := '';
  for i := 0 to High(FAttributeCacheArray) do
  begin
    if FAttributeCacheArray[i].OperatorVal = '' then Continue;
    ColumnName := FAttributeCacheArray[i].Key;
    OpSelection := FAttributeCacheArray[i].OperatorVal;
    AttributeValue := FAttributeCacheArray[i].FilterValue;
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

procedure TfrmModalAnalyse.ApplyAttributeFilter(const Filter: String);
var
  SearchTerm: String;
  Node: PVirtualNode;
  NodeMatches: Boolean;
begin
  SearchTerm := LowerCase(Trim(Filter));
  vstScopeAttribute.BeginUpdate;
  try
    Node := vstScopeAttribute.GetFirst;
    while Assigned(Node) do
    begin
      if (Node^.Index < Cardinal(Length(FAttributeCacheArray))) then
      begin
        NodeMatches := (Filter = '') or (Pos(SearchTerm, LowerCase(FAttributeCacheArray[Node^.Index].Name)) > 0);
        vstScopeAttribute.IsVisible[Node] := NodeMatches;
      end;
      Node := vstScopeAttribute.GetNext(Node);
    end;
  finally
    vstScopeAttribute.EndUpdate;
  end;
end;

procedure TThreadPrepareVisualization.SyncStatus(const Message: String);
begin
  FStatusMsg := Message;
  Synchronize(@DoSyncStatus);
end;

procedure TThreadPrepareVisualization.DoSyncStatus;
begin
  if Assigned(frmDialogProgress) then
    TfrmDialogProgress.UpdateStatus(FStatusMsg);
end;

procedure TThreadPrepareVisualization.CloseProgressDialog;
begin
  if Assigned(frmDialogProgress) and frmDialogProgress.Visible then
    frmDialogProgress.ModalResult := mrOk;
end;

procedure TThreadPrepareVisualization.Execute;
var
  VW, VH, i, c, r, MaxVal, Limit: Integer;
  ChartData: TChartElementArray;
  CodeListX, CodeListY, CodeList, AttributeList: TStringList;
  Matrix: TMatrixData;
  XLabel, YLabel, LabelArray, LabelStr: array of String;
  TotalVal, SubVal: array of Double;
  Word: array of String;
  Frequency: array of Integer;
  AttributeString, DocumentName: String;
begin
  FSuccess := False;
  FErrorMessage := '';
  try
    PreparedVisualization := TServiceVisualize.Create;
    SyncStatus('Measuring spatial coordinates...');
    case FActiveAnalysis of
      0: begin
           SetLength(ChartData, Length(FFrequencyResult));
           for i := 0 to High(FFrequencyResult) do
           begin
             ChartData[i].LabelText := frmModalAnalyse.GetTruncatedCodePath(FFrequencyResult[i].CodeID, 25);
             ChartData[i].Value := FFrequencyResult[i].SegmentCount;
             ChartData[i].ValueStr := IntToStr(FFrequencyResult[i].SegmentCount);
           end;
           PreparedVisualization.PrepareBarChart(ChartData, VW, VH);
         end;
      1: begin
           CodeListX := TStringList.Create;
           CodeListY := TStringList.Create;
           try
             CodeListX.Sorted := True; CodeListX.Duplicates := dupIgnore;
             CodeListY.Sorted := True; CodeListY.Duplicates := dupIgnore;
             MaxVal := 1;
             for i := 0 to High(FCoOccurrenceResult) do
             begin
               CodeListX.Add(FCoOccurrenceResult[i].Code1ID);
               CodeListY.Add(FCoOccurrenceResult[i].Code2ID);
               if FCoOccurrenceResult[i].Overlap > MaxVal then MaxVal := FCoOccurrenceResult[i].Overlap;
             end;
             SetLength(Matrix, CodeListX.Count, CodeListY.Count);
             for i := 0 to High(FCoOccurrenceResult) do
             begin
               c := CodeListX.IndexOf(FCoOccurrenceResult[i].Code1ID);
               r := CodeListY.IndexOf(FCoOccurrenceResult[i].Code2ID);
               if (c > -1) and (r > -1) then Matrix[c, r] := FCoOccurrenceResult[i].Overlap;
             end;
             SetLength(XLabel, CodeListX.Count);
             for c := 0 to CodeListX.Count - 1 do XLabel[c] := frmModalAnalyse.GetTruncatedCodePath(CodeListX[c], 25);
             SetLength(YLabel, CodeListY.Count);
             for r := 0 to CodeListY.Count - 1 do YLabel[r] := frmModalAnalyse.GetTruncatedCodePath(CodeListY[r], 25);
             PreparedVisualization.PrepareHeatmap(XLabel, YLabel, Matrix, MaxVal, False, VW, VH);
           finally
             CodeListX.Free; CodeListY.Free;
           end;
         end;
      2: begin
           CodeList := TStringList.Create;
           AttributeList := TStringList.Create;
           try
             CodeList.Sorted := True; CodeList.Duplicates := dupIgnore;
             AttributeList.Sorted := True; AttributeList.Duplicates := dupIgnore;
             MaxVal := 1;
             for i := 0 to High(FCrossResult) do
             begin
               CodeList.Add(FCrossResult[i].CodeID);
               AttributeList.Add(FCrossResult[i].AttributeValue);
               if FCrossResult[i].Frequency > MaxVal then MaxVal := FCrossResult[i].Frequency;
             end;
             SetLength(Matrix, AttributeList.Count, CodeList.Count);
             for i := 0 to High(FCrossResult) do
             begin
               c := AttributeList.IndexOf(FCrossResult[i].AttributeValue);
               r := CodeList.IndexOf(FCrossResult[i].CodeID);
               if (c > -1) and (r > -1) then Matrix[c, r] := FCrossResult[i].Frequency;
             end;
             SetLength(XLabel, AttributeList.Count);
             for c := 0 to AttributeList.Count - 1 do
             begin
               AttributeString := AttributeList[c];
               if UTF8Length(AttributeString) > 40 then AttributeString := UTF8Copy(AttributeString, 1, 40) + '...';
               XLabel[c] := AttributeString;
             end;
             SetLength(YLabel, CodeList.Count);
             for r := 0 to CodeList.Count - 1 do YLabel[r] := frmModalAnalyse.GetTruncatedCodePath(CodeList[r], 25);
             PreparedVisualization.PrepareHeatmap(XLabel, YLabel, Matrix, MaxVal, True, VW, VH);
           finally
             CodeList.Free; AttributeList.Free;
           end;
         end;
      3: begin
           Limit := FLimit;
           if Limit <= 0 then Limit := Length(FCoverageResult);
           if Limit > Length(FCoverageResult) then Limit := Length(FCoverageResult);
           SetLength(LabelArray, Limit);
           SetLength(LabelStr, Limit);
           SetLength(TotalVal, Limit);
           SetLength(SubVal, Limit);
           for i := 0 to Limit - 1 do
           begin
             DocumentName := FCoverageResult[i].DocumentName;
             if UTF8Length(DocumentName) > 60 then DocumentName := UTF8Copy(DocumentName, 1, 60) + '...';
             LabelArray[i] := DocumentName;
             TotalVal[i] := FCoverageResult[i].TotalCharacters;
             SubVal[i] := FCoverageResult[i].CodedCharacters;
             if FCoverageResult[i].TotalCharacters > 0 then
               LabelStr[i] := FormatFloat('0.00', (FCoverageResult[i].CodedCharacters / FCoverageResult[i].TotalCharacters) * 100) + '%'
             else
               LabelStr[i] := '0.00%';
           end;
           PreparedVisualization.PrepareStackedBarChart(LabelArray, TotalVal, SubVal, LabelStr, VW, VH);
         end;
      4: begin
           Limit := Length(FCloudResult);
           SetLength(Word, Limit);
           SetLength(Frequency, Limit);
           for i := 0 to Limit - 1 do
           begin
             Word[i] := FCloudResult[i].Word;
             Frequency[i] := FCloudResult[i].Frequency;
           end;
           PreparedVisualization.PrepareWordCloud(Word, Frequency, VW, VH);
         end;
    end;
    VWidth := VW;
    VHeight := VH;
    FSuccess := True;
  except
    on E: Exception do
    begin
      FErrorMessage := E.Message;
      if Assigned(PreparedVisualization) then
      begin
        PreparedVisualization.Free;
        PreparedVisualization := nil;
      end;
    end;
  end;
  Synchronize(@CloseProgressDialog);
end;

procedure TfrmModalAnalyse.ExecuteFrequency;
var
  IDArray, DocumentID: TStringDynArray;
  Limit: Integer;
begin
  IDArray := GetCheckedTreeIDs(vstFrequencyCode);
  if Length(IDArray) = 0 then Exit;
  DocumentID := GetCheckedDocumentID();
  if Assigned(chkEnableLimit) and chkEnableLimit.Checked and Assigned(edtVisualizationLimit) then
    Limit := edtVisualizationLimit.Value
  else
    Limit := 1000000;
  FFrequencyResult := FServiceDatabase.RunFrequencyAnalysis(IDArray, DocumentID, GetAttributeSQL, Limit);
  SetupGrid(['Code', 'Segment Count', 'Document Count'], [500, 200, 200], Length(FFrequencyResult));
  if Length(FFrequencyResult) = 0 then FAnalysisState := asNoResults;
end;

procedure TfrmModalAnalyse.ExecuteCoOccurrence;
var
  IDXArray, IDYArray, DocumentID: TStringDynArray;
begin
  IDXArray := GetCheckedTreeIDs(vstCoOccurrenceX);
  IDYArray := GetCheckedTreeIDs(vstCoOccurrenceY);
  if (Length(IDXArray) = 0) and (Length(IDYArray) = 0) then Exit;
  DocumentID := GetCheckedDocumentID();
  FCoOccurrenceResult := FServiceDatabase.RunCoOccurrenceAnalysis(IDXArray, IDYArray, DocumentID, GetAttributeSQL, 0);
  SetupGrid(['Code X', 'Code Y', 'Overlap Count'], [350, 350, 200], Length(FCoOccurrenceResult));
  if Length(FCoOccurrenceResult) = 0 then FAnalysisState := asNoResults;
end;

procedure TfrmModalAnalyse.ExecuteCrosstab;
var
  IDArray, DocumentID: TStringDynArray;
begin
  if not Assigned(cmbCrossAttribute) or (cmbCrossAttribute.ItemIndex = -1) then Exit;
  IDArray := GetCheckedTreeIDs(vstCrosstabCode, 0);
  if Length(IDArray) = 0 then Exit;
  DocumentID := GetCheckedDocumentID();
  FCrossResult := FServiceDatabase.RunCrosstabAnalysis(IDArray, DocumentID, GetAttributeSQL, FAttributeKey[cmbCrossAttribute.ItemIndex]);
  SetupGrid(['Code', cmbCrossAttribute.Text, 'Segment Count'], [400, 300, 200], Length(FCrossResult));
  if Length(FCrossResult) = 0 then FAnalysisState := asNoResults;
end;

procedure TfrmModalAnalyse.ExecuteCoverage;
var
  DocumentID: TStringDynArray;
  i, ValidCount: Integer;
begin
  DocumentID := GetCheckedDocumentID();
  FCoverageResult := FServiceDatabase.RunCoverageAnalysis(DocumentID, GetAttributeSQL, 0);
  ValidCount := 0;
  for i := 0 to High(FCoverageResult) do if FCoverageResult[i].DocumentID <> '' then Inc(ValidCount);
  SetLength(FCoverageResult, ValidCount);
  SetupGrid(['Document Name', 'Total Characters', 'Coded Characters', 'Coverage %'], [300, 200, 200, 200], Length(FCoverageResult));
  if Length(FCoverageResult) = 0 then FAnalysisState := asNoResults;
end;

procedure TfrmModalAnalyse.ExecuteWordCloud;
var
  IDArray, DocumentID: TStringDynArray;
  StopStr: String;
  Limit: Integer;
begin
  IDArray := GetCheckedTreeIDs(vstWordCloudCode);
  if Length(IDArray) = 0 then Exit;
  DocumentID := GetCheckedDocumentID();
  StopStr := FServiceDatabase.GetUserPreference('StopWord', 'a,about,above,after,again,against,ain,all,am,an,and,any,are,aren,aren''t,as,at,be,because,been,before,being,below,between,both,but,by,can,couldn,couldn''t,d,did,didn,didn''t,do,does,doesn,doesn''t,doing,don,don''t,down,during,each,few,for,from,further,had,hadn,hadn''t,has,hasn,hasn''t,have,haven,haven''t,having,he,he''d,he''ll,her,here,hers,herself,he''s,him,himself,his,how,i,i''d,if,i''ll,i''m,in,into,is,isn,isn''t,it,it''d,it''ll,it''s,its,itself,i''ve,just,ll,m,ma,me,mightn,mightn''t,more,most,mustn,mustn''t,my,myself,needn,needn''t,no,nor,not,now,o,of,off,on,once,only,or,other,our,ours,ourselves,out,over,own,re,s,same,shan,shan''t,she,she''d,she''ll,she''s,should,shouldn,shouldn''t,should''ve,so,some,such,t,than,that,that''ll,the,their,theirs,them,themselves,then,there,these,they,they''d,they''ll,they''re,they''ve,this,those,through,to,too,under,until,up,ve,very,was,wasn,wasn''t,we,we''d,we''ll,we''re,were,weren,weren''t,we''ve,what,when,where,which,while,who,whom,why,will,with,won,won''t,wouldn,wouldn''t,y,you,you''d,you''ll,your,you''re,yours,yourself,yourselves,you''ve');
  if Assigned(edtVisualizationLimit) then Limit := edtVisualizationLimit.Value else Limit := 50;
  if Limit > 100 then Limit := 100;
  FCloudResult := FServiceDatabase.RunWordCloudAnalysis(IDArray, DocumentID, GetAttributeSQL, StopStr, Limit);
  SetupGrid(['Word', 'Frequency'], [500, 200], Length(FCloudResult));
  if Length(FCloudResult) = 0 then FAnalysisState := asNoResults;
end;

procedure TfrmModalAnalyse.pbxVisualizationPaint(Sender: TObject);
var
  Surface: Pcairo_surface_t;
  Context: Pcairo_t;
  TextExtents: cairo_text_extents_t;
  DisplayText: String;
begin
  if not Assigned(pbxVisualization) or (pbxVisualization.Width <= 0) or (pbxVisualization.Height <= 0) then Exit;
  pbxVisualization.Canvas.Brush.Color := clWhite;
  pbxVisualization.Canvas.FillRect(pbxVisualization.ClientRect);
  Surface := cairo_win32_surface_create(pbxVisualization.Canvas.Handle);
  Context := cairo_create(Surface);
  try
    cairo_set_source_rgb(Context, 1, 1, 1);
    cairo_paint(Context);
    if FAnalysisState <> asComplete then
    begin
      cairo_set_source_rgb(Context, 0.5, 0.5, 0.5);
      cairo_select_font_face(Context, PChar('Arial'), CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
      cairo_set_font_size(Context, 16.0 * (Font.PixelsPerInch / 96.0));
      case FAnalysisState of
        asReady: DisplayText := 'Run analysis to view results.';
        asRunning: DisplayText := 'Running analysis...';
        asMissingAttribute: DisplayText := 'Please select an attribute from the dropdown to run Crosstab Analysis.';
        asNoSelection: DisplayText := 'Please define the query scope to run the analysis.';
        asNoResults: DisplayText := 'No data found for the selected query.';
      end;
      cairo_text_extents(Context, PChar(DisplayText), @TextExtents);
      cairo_move_to(Context,
        (pbxVisualization.Width / 2.0) - (TextExtents.width / 2.0) - TextExtents.x_bearing,
        (pbxVisualization.Height / 2.0) - (TextExtents.height / 2.0) - TextExtents.y_bearing
      );
      cairo_show_text(Context, PChar(DisplayText));
      Exit;
    end;
    FVisualizer.Render(Context, pbxVisualization.Width, pbxVisualization.Height, FPanX, FPanY, FZoom);
  finally
    cairo_destroy(Context);
    cairo_surface_finish(Surface);
    cairo_surface_destroy(Surface);
  end;
end;

procedure TfrmModalAnalyse.pbxVisualizationMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FIsDragging := True;
    FLastMouse := Classes.Point(X, Y);
  end;
end;

procedure TfrmModalAnalyse.pbxVisualizationMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if FIsDragging then
  begin
    FPanX := FPanX + (X - FLastMouse.X);
    FPanY := FPanY + (Y - FLastMouse.Y);
    FLastMouse := Classes.Point(X, Y);
    if Assigned(pbxVisualization) then pbxVisualization.Invalidate;
  end;
end;

procedure TfrmModalAnalyse.pbxVisualizationMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then FIsDragging := False;
end;

procedure TfrmModalAnalyse.pbxVisualizationMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePosition: TPoint; var Handled: Boolean);
var
  ZoomDelta: Double;
begin
  if WheelDelta > 0 then ZoomDelta := 1.1 else ZoomDelta := 0.9;
  FPanX := MousePosition.X - (MousePosition.X - FPanX) * ZoomDelta;
  FPanY := MousePosition.Y - (MousePosition.Y - FPanY) * ZoomDelta;
  FZoom := FZoom * ZoomDelta;
  if Assigned(pbxVisualization) then pbxVisualization.Invalidate;
  Handled := True;
end;

procedure TfrmModalAnalyse.edtVisualizationLimitChange(Sender: TObject);
begin
  if (csLoading in ComponentState) or not Assigned(pbxVisualization) or not Assigned(edtVisualizationLimit) then Exit;
  if pcAnalysisType.ActivePageIndex = 4 then
  begin
    if edtVisualizationLimit.Value > 100 then edtVisualizationLimit.Value := 100;
    FLastCloudLimit := edtVisualizationLimit.Value;
  end
  else
    FLastBarLimit := edtVisualizationLimit.Value;
  pbxVisualization.Invalidate;
end;

procedure TfrmModalAnalyse.chkEnableLimitChange(Sender: TObject);
begin
  if (csLoading in ComponentState) or not Assigned(edtVisualizationLimit) or not Assigned(pbxVisualization) then Exit;
  edtVisualizationLimit.Enabled := chkEnableLimit.Checked;
  pbxVisualization.Invalidate;
end;

procedure TfrmModalAnalyse.btnStopwordsClick(Sender: TObject);
var
  Srv: TServiceDatabase;
  DefWord, CurrentWords: String;
  DummyDel: Boolean;
begin
  Srv := TServiceDatabase.Create(ServiceDatabase.TSQLite3Connection(frmAppBase.conMain));
  try
    DefWord := 'a,about,above,after,again,against,ain,all,am,an,and,any,are,aren,aren''t,as,at,be,because,been,before,being,below,between,both,but,by,can,couldn,couldn''t,d,did,didn,didn''t,do,does,doesn,doesn''t,doing,don,don''t,down,during,each,few,for,from,further,had,hadn,hadn''t,has,hasn,hasn''t,have,haven,haven''t,having,he,he''d,he''ll,her,here,hers,herself,he''s,him,himself,his,how,i,i''d,if,i''ll,i''m,in,into,is,isn,isn''t,it,it''d,it''ll,it''s,its,itself,i''ve,just,ll,m,ma,me,mightn,mightn''t,more,most,mustn,mustn''t,my,myself,needn,needn''t,no,nor,not,now,o,of,off,on,once,only,or,other,our,ours,ourselves,out,over,own,re,s,same,shan,shan''t,she,she''d,she''ll,she''s,should,shouldn,shouldn''t,should''ve,so,some,such,t,than,that,that''ll,the,their,theirs,them,themselves,then,there,these,they,they''d,they''ll,they''re,they''ve,this,those,through,to,too,under,until,up,ve,very,was,wasn,wasn''t,we,we''d,we''ll,we''re,were,weren,weren''t,we''ve,what,when,where,which,while,who,whom,why,will,with,won,won''t,wouldn,wouldn''t,y,you,you''d,you''ll,your,you''re,yours,yourself,yourselves,you''ve';
    CurrentWords := Srv.GetUserPreference('StopWord', DefWord);
    frmDialogEditor := TfrmDialogEditor.Create(Self);
    try
      if frmDialogEditor.ExecuteTextEditor('Manage Stopwords', 'Editable Comma-Separated Stopwords List', CurrentWords, False, DummyDel) then
      begin
        Srv.SaveUserPreference('StopWord', Trim(CurrentWords));
      end;
    finally
      frmDialogEditor.Free;
    end;
  finally
    Srv.Free;
  end;
end;

procedure TfrmModalAnalyse.btnExportDataClick(Sender: TObject);
var
  Worker: TThreadExportTable;
  Header, DataKeys: TStringDynArray;
  GridData: T2DStringArray;
  ColCount, RowCount, c, r: Integer;
  Node: PVirtualNode;
begin
  if not Assigned(vstResultGrid) or (vstResultGrid.RootNodeCount = 0) then Exit;
  if not Assigned(dlgExportData) or not dlgExportData.Execute then Exit;
  ColCount := vstResultGrid.Header.Columns.Count;
  RowCount := vstResultGrid.RootNodeCount;
  SetLength(Header, ColCount);
  SetLength(DataKeys, ColCount);
  for c := 0 to ColCount - 1 do Header[c] := vstResultGrid.Header.Columns[c].Text;
  case FActiveAnalysis of
    0: begin DataKeys[0] := 'Code'; DataKeys[1] := 'SegmentCount'; DataKeys[2] := 'DocumentCount'; end;
    1: begin DataKeys[0] := 'CodeX'; DataKeys[1] := 'CodeY'; DataKeys[2] := 'OverlapCount'; end;
    2: begin DataKeys[0] := 'Code'; DataKeys[1] := 'AttributeValue'; DataKeys[2] := 'SegmentCount'; end;
    3: begin DataKeys[0] := 'DocumentName'; DataKeys[1] := 'TotalCharacters'; DataKeys[2] := 'CodedCharacters'; DataKeys[3] := 'CoveragePercentage'; end;
    4: begin DataKeys[0] := 'Word'; DataKeys[1] := 'Frequency'; end;
  end;
  SetLength(GridData, RowCount, ColCount);
  r := 0;
  Node := vstResultGrid.GetFirst;
  while Assigned(Node) do
  begin
    for c := 0 to ColCount - 1 do GridData[r, c] := vstResultGrid.Text[Node, c];
    Inc(r);
    Node := vstResultGrid.GetNext(Node);
  end;
  if (LowerCase(ExtractFileExt(dlgExportData.FileName)) = '.xlsx') or 
     (LowerCase(ExtractFileExt(dlgExportData.FileName)) = '.ods') then
  begin
    for r := 0 to RowCount - 1 do
      for c := 0 to ColCount - 1 do
        if Length(GridData[r, c]) > 32767 then
        begin
          MessageDlg('Data Limit Exceeded', 'Some items exceed the 32,767 characters per cell limit for spreadsheets.' + sLineBreak + 'Please export as CSV, JSON, or XML instead.', mtWarning, [mbOK], 0);
          Exit;
        end;
  end;
  Worker := TThreadExportTable.Create(True);
  Worker.FreeOnTerminate := False;
  Worker.FFileName := dlgExportData.FileName;
  Worker.FHeader := Header;
  Worker.FDataKeys := DataKeys;
  Worker.FGridData := GridData;
  Worker.Start;
  TfrmDialogProgress.Prepare('Exporting Data Table', 'Writing file to disk...');
  frmDialogProgress.ShowModal;
  if not Worker.Success then
    MessageDlg('Error', 'Failed to export data: ' + Worker.ErrorMessage, mtError, [mbOK], 0)
  else
    MessageDlg('Success', 'Data table exported successfully.', mtInformation, [mbOK], 0);
  Worker.Free;
end;

procedure TfrmModalAnalyse.RenderActiveVisualisation(cr: Pcairo_t; AWidth, AHeight: Integer);
var
  Margin: Double;
begin
  Margin := MulDiv(38, Font.PixelsPerInch, 96);
  cairo_save(cr);
  cairo_translate(cr, Margin, Margin);
  FVisualizer.Render(cr, AWidth - Round(Margin * 2.0), AHeight - Round(Margin * 2.0), 0, 0, 1.0);
  cairo_restore(cr);
end;

procedure TfrmModalAnalyse.ResetViewContext;
var
  ActualViewW, ActualViewH: Double;
  VisibleViewW, VisibleViewH: Double;
  ScaleX, ScaleY, ContentW, ContentH: Double;
begin
  if not Assigned(pbxVisualization) or (pbxVisualization.Width <= 0) or (pbxVisualization.Height <= 0) then Exit;
  ActualViewW := pbxVisualization.Width;
  ActualViewH := pbxVisualization.Height;
  VisibleViewW := ActualViewW;
  VisibleViewH := ActualViewH;
  if Assigned(pnlGrid) and pnlGrid.Visible then
  begin
    VisibleViewH := VisibleViewH - pnlGrid.Height;
    if Assigned(splResults) and splResults.Visible then
      VisibleViewH := VisibleViewH - splResults.Height;
  end;
  if (FVirtualWidth <= 0) or (FVirtualHeight <= 0) then
  begin
    FZoom := 1.0;
    FPanX := 20.0;
    FPanY := 20.0;
    Exit;
  end;
  ScaleX := (VisibleViewW - 40.0) / FVirtualWidth;
  ScaleY := (VisibleViewH - 40.0) / FVirtualHeight;
  FZoom := Math.Min(1.0, Math.Min(ScaleX, ScaleY));
  if FZoom < 0.333 then FZoom := 0.333;
  ContentW := FVirtualWidth * FZoom;
  ContentH := FVirtualHeight * FZoom;
  if ContentW < VisibleViewW then
    FPanX := (VisibleViewW - ContentW) / 2.0
  else
    FPanX := 20.0;
  if ContentH < VisibleViewH then
    FPanY := (VisibleViewH - ContentH) / 2.0
  else
    FPanY := 20.0;
end;

procedure TfrmModalAnalyse.btnSaveVisualizationClick(Sender: TObject);
var
  RequestedWidth, RequestedHeight: Integer;
  Margin: Double;
  SubjectStr, ProjectTitle, Extension: String;
  Worker: TThreadExportVisualization;
  CurrentLimit: Integer;
begin
  if FAnalysisState <> asComplete then Exit;
  if not Assigned(dlgSaveVisualization) or not dlgSaveVisualization.Execute then Exit;
  RequestedWidth := FVirtualWidth;
  RequestedHeight := FVirtualHeight;
  Margin := MulDiv(38, Font.PixelsPerInch, 96);
  RequestedWidth := RequestedWidth + Round(Margin * 2.0);
  RequestedHeight := RequestedHeight + Round(Margin * 2.0);
  Extension := LowerCase(ExtractFileExt(dlgSaveVisualization.FileName));
  if ((Extension = '.png') or (Extension = '.jpg') or (Extension = '.jpeg')) and ((RequestedWidth > 32767) or (RequestedHeight > 32767)) then
  begin
    MessageDlg('Image Too Large', 'This visualisation is too large to be exported as a raster image (PNG/JPEG).' + sLineBreak + sLineBreak + 'Please choose PDF or SVG format instead.', mtWarning, [mbOK], 0);
    Exit;
  end;
  ProjectTitle := ChangeFileExt(ExtractFileName(frmAppBase.conMain.DatabaseName), '');
  case FActiveAnalysis of
    0: SubjectStr := 'Code Frequency';
    1: SubjectStr := 'Code Co-occurrence';
    2: SubjectStr := 'Attribute-Code Crosstab';
    3: SubjectStr := 'Coding Coverage';
    4: SubjectStr := 'Word Cloud';
  else
    SubjectStr := 'Visualisation';
  end;
  Worker := TThreadExportVisualization.Create(True);
  Worker.FreeOnTerminate := False;
  Worker.FFileName := dlgSaveVisualization.FileName;
  Worker.FProjectTitle := ProjectTitle;
  Worker.FSubject := SubjectStr;
  Worker.FWidth := RequestedWidth;
  Worker.FHeight := RequestedHeight;
  Worker.FActiveAnalysis := FActiveAnalysis;
  Worker.FMargin := Margin;
  Worker.FFrequencyResult := FFrequencyResult;
  Worker.FCoOccurrenceResult := FCoOccurrenceResult;
  Worker.FCrossResult := FCrossResult;
  Worker.FCoverageResult := FCoverageResult;
  Worker.FCloudResult := FCloudResult;
  CurrentLimit := 1000000;
  if Assigned(chkEnableLimit) and Assigned(edtVisualizationLimit) then
  begin
    if (FActiveAnalysis = 4) or chkEnableLimit.Checked then
      CurrentLimit := edtVisualizationLimit.Value;
  end;
  Worker.FLimit := CurrentLimit;
  Worker.Start;
  TfrmDialogProgress.Prepare('Exporting Visualisation', 'Rendering graphics...');
  frmDialogProgress.ShowModal;
  if not Worker.Success then
    MessageDlg('Error', 'Failed to save the visualisation: ' + Worker.ErrorMessage, mtError, [mbOK], 0)
  else
    MessageDlg('Success', 'Visualisation saved successfully.', mtInformation, [mbOK], 0);
  Worker.Free;
end;

procedure TfrmModalAnalyse.btnResetClick(Sender: TObject);
begin
  if Assigned(edtSearchFrequency) then edtSearchFrequency.Clear;
  if Assigned(edtSearchCoOccurrenceX) then edtSearchCoOccurrenceX.Clear;
  if Assigned(edtSearchCoOccurrenceY) then edtSearchCoOccurrenceY.Clear;
  if Assigned(edtSearchCrosstab) then edtSearchCrosstab.Clear;
  if Assigned(edtSearchCloud) then edtSearchCloud.Clear;
  if Assigned(edtSearchScopeDocument) then edtSearchScopeDocument.Clear;
  if Assigned(edtSearchScopeAttribute) then edtSearchScopeAttribute.Clear;
  btnFrequencyClearAllClick(nil);
  btnCoOccurrenceXClearAllClick(nil);
  btnCoOccurrenceYClearAllClick(nil);
  btnCrossClearAllClick(nil);
  btnCloudClearAllClick(nil);
  btnScopeDocumentClearAllClick(nil);
  btnScopeAttributeClearAllClick(nil);
  vstFrequencyCode.FullCollapse(nil);
  vstCoOccurrenceX.FullCollapse(nil);
  vstCoOccurrenceY.FullCollapse(nil);
  vstCrosstabCode.FullCollapse(nil);
  vstWordCloudCode.FullCollapse(nil);
  if Assigned(cmbCrossAttribute) and (cmbCrossAttribute.Items.Count > 0) then
    cmbCrossAttribute.ItemIndex := -1;
  vstScopeAttribute.ClearSelection;
  FCurrentAttributeIndex := -1;
  pnlAttributeFilterDef.Visible := False;
  FLastCloudLimit := 50;
  FLastBarLimit := 10;
  if Assigned(chkEnableLimit) then chkEnableLimit.Checked := True;
  pcAnalysisType.ActivePageIndex := 0;
  pcAnalysisTypeChange(nil);
  FLastCheckedNode := nil;
  FLastCheckedTree := nil;
  FLastCheckedDocNode := nil;
  ResetResults;
end;

end.

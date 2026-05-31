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

unit AppBase;

{$mode objfpc}{$H+}

interface

uses
  Buttons, Classes, ComCtrls, Controls, Dialogs, ExtCtrls, Forms, Generics.Collections,
  Graphics, LCLIntf, LCLType, Menus, StdCtrls, SysUtils, Types {$IFDEF WINDOWS}, Windows{$ENDIF},
  SQLDB, SQLite3Conn, laz.VirtualTrees, ControllerTreeCode, ControllerTreeDocument, EngineText,
  RenderDocument, ServiceDatabase;

type
  TDocumentAttributeItem = record
    Name: String;
    Value: String;
    AttributeType: String;
  end;
  TDocumentAttributeArray = array of TDocumentAttributeItem;

  { TfrmAppBase }
  TfrmAppBase = class(TForm)
    btnCodeAdd: TButton;
    btnCodeSort: TSpeedButton;
    btnDocumentFilter: TSpeedButton;
    btnDocumentSort: TSpeedButton;
    btnReadDocumentNext: TSpeedButton;
    btnReadDocumentPrevious: TSpeedButton;
    btnReadSearchNext: TSpeedButton;
    btnReadSearchPrevious: TSpeedButton;
    conImport: TSQLite3Connection;
    conMain: TSQLite3Connection;
    dlgExportSystem: TSaveDialog;
    dlgImport: TOpenDialog;
    dlgNewProject: TSaveDialog;
    dlgOpenProject: TOpenDialog;
    dlgPickColor: TColorDialog;
    edtCodeSearch: TEdit;
    edtDocumentSearch: TEdit;
    edtReadSearch: TEdit;
    lblAttributeTitle: TLabel;
    lblCodeTitle: TLabel;
    lblCurrentSort: TLabel;
    lblDocumentTitle: TLabel;
    lblEditStatus: TLabel;
    lblLegendTitle: TLabel;
    lblReadDocumentTitle: TLabel;
    lblReadSearchCount: TLabel;
    mniTreeDocumentSelectAll: TMenuItem;
    mniDocumentExportText: TMenuItem;
    mniDocumentExportSheet: TMenuItem;
    mniDocumentExportJSON: TMenuItem;
    mniDocumentExportXML: TMenuItem;
    mniDocumentExport: TMenuItem;
    mniCodebookExport: TMenuItem;
    mniDocumentImportPDF: TMenuItem;
    mniTreeCodeDemote: TMenuItem;
    mniTreeCodePromote: TMenuItem;
    mniTreeCodeMoveDown: TMenuItem;
    mniTreeCodeMoveUp: TMenuItem;
    mniTreeCodeSeparatorTwo: TMenuItem;
    mniAnalysis: TMenuItem;
    mniAttribute: TMenuItem;
    mniCode: TMenuItem;
    mniCodeSystem: TMenuItem;
    mniCodeSystemExport: TMenuItem;
    mniCodeSystemImport: TMenuItem;
    mniDocument: TMenuItem;
    mniDocumentImport: TMenuItem;
    mniDocumentImportJSON: TMenuItem;
    mniDocumentImportSQLite: TMenuItem;
    mniDocumentImportSheet: TMenuItem;
    mniDocumentImportText: TMenuItem;
    mniDocumentImportWord: TMenuItem;
    mniEdit: TMenuItem;
    mniHelp: TMenuItem;
    mniHelpAbout: TMenuItem;
    mniHelpGuide: TMenuItem;
    mniHelpLicense: TMenuItem;
    mniHelpSponsor: TMenuItem;
    mniHelpThirdParty: TMenuItem;
    mniHelpWebsite: TMenuItem;
    mniListAttributeValueCopy: TMenuItem;
    mniMemo: TMenuItem;
    mniMemoAnalytical: TMenuItem;
    mniMemoManage: TMenuItem;
    mniMemoProject: TMenuItem;
    mniProject: TMenuItem;
    mniProjectClose: TMenuItem;
    mniProjectOptimize: TMenuItem;
    mniProjectSnapshot: TMenuItem;
    mniRetrieval: TMenuItem;
    mniTreeCodeAddSubCode: TMenuItem;
    mniTreeCodeCollapseAll: TMenuItem;
    mniTreeCodeColorChange: TMenuItem;
    mniTreeCodeDelete: TMenuItem;
    mniTreeCodeExpandAll: TMenuItem;
    mniTreeCodeMemo: TMenuItem;
    mniTreeCodeMerge: TMenuItem;
    mniTreeCodeRename: TMenuItem;
    mniTreeCodeSeparatorOne: TMenuItem;
    mniTreeDocumentAttributeAdd: TMenuItem;
    mniTreeDocumentAttributeDelete: TMenuItem;
    mniTreeDocumentAttributeEdit: TMenuItem;
    mniTreeDocumentDelete: TMenuItem;
    mniTreeDocumentMemo: TMenuItem;
    mniTreeDocumentRename: TMenuItem;
    mniTreeDocumentSeparatorOne: TMenuItem;
    mniTreeDocumentSeparatorTwo: TMenuItem;
    mnuAppBase: TMainMenu;
    pbxLegendCodeName: TPaintBox;
    pmnListAttribute: TPopupMenu;
    pmnText: TPopupMenu;
    pmnTreeCode: TPopupMenu;
    pmnTreeDocument: TPopupMenu;
    pnlAttribute: TPanel;
    pnlCode: TPanel;
    pnlCodeAction: TPanel;
    pnlDocument: TPanel;
    pnlDocumentAction: TPanel;
    pnlDocumentList: TPanel;
    pnlLeft: TPanel;
    pnlLegend: TPanel;
    pnlRead: TPanel;
    pnlReadContainer: TPanel;
    pnlReadHeader: TPanel;
    pnlReadNavigation: TPanel;
    pnlReadSearch: TPanel;
    pnlRight: TPanel;
    qryCheck: TSQLQuery;
    qryDocumentData: TSQLQuery;
    qryImport: TSQLQuery;
    qryMain: TSQLQuery;
    qryUtil: TSQLQuery;
    dlgSnapshotSave: TSaveDialog;
    btnDocumentEditEnter: TSpeedButton;
    btnDocumentEditExit: TSpeedButton;
    mniDocumentImportSeparatorOne: TMenuItem;
    dlgExportCodebook: TSaveDialog;
    mniDocumentExportSeparatorOne: TMenuItem;
    dlgExportDirectory: TSelectDirectoryDialog;
    splCenterRight: TSplitter;
    splCode: TSplitter;
    splDocumentAttribute: TSplitter;
    splLeftCenter: TSplitter;
    stbMain: TStatusBar;
    tmrCodeSearch: TTimer;
    tmrDocumentSearch: TTimer;
    trnImport: TSQLTransaction;
    trnMain: TSQLTransaction;
    vstAttribute: TLazVirtualStringTree;
    vstCode: TLazVirtualStringTree;
    vstDocument: TLazVirtualStringTree;
    procedure AddSegmentMemoClick(Sender: TObject);
    procedure BracketCopySegmentClick(Sender: TObject);
    procedure BracketRecodeSegmentClick(Sender: TObject);
    procedure BracketRemoveCodingClick(Sender: TObject);
    procedure btnCloseDocumentClick(Sender: TObject);
    procedure btnCodeAddClick(Sender: TObject);
    procedure btnCodeSortClick(Sender: TObject);
    procedure btnDocumentEditExitClick(Sender: TObject);
    procedure btnDocumentFilterClick(Sender: TObject);
    procedure btnDocumentSearchClick(Sender: TObject);
    procedure btnDocumentSortClick(Sender: TObject);
    procedure btnDocumentEditEnterClick(Sender: TObject);
    procedure btnReadDocumentNextClick(Sender: TObject);
    procedure btnReadDocumentPreviousClick(Sender: TObject);
    procedure btnReadSearchNextClick(Sender: TObject);
    procedure btnReadSearchPreviousClick(Sender: TObject);
    procedure CopyTextClick(Sender: TObject);
    procedure EditSegmentMemoClick(Sender: TObject);
    procedure edtCodeSearchChange(Sender: TObject);
    procedure edtCodeSearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtDocumentSearchChange(Sender: TObject);
    procedure edtDocumentSearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtReadSearchChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure LoadCodingForCurrentDocument;
    procedure mniAnalysisClick(Sender: TObject);
    procedure mniAttributeClick(Sender: TObject);
    procedure mniCodebookExportClick(Sender: TObject);
    procedure mniCodeSystemExportClick(Sender: TObject);
    procedure mniCodeSystemImportClick(Sender: TObject);
    procedure mniDocumentClick(Sender: TObject);
    procedure mniDocumentExportJSONClick(Sender: TObject);
    procedure mniDocumentExportSheetClick(Sender: TObject);
    procedure mniDocumentExportTextClick(Sender: TObject);
    procedure mniDocumentExportXMLClick(Sender: TObject);
    procedure mniDocumentImportJSONClick(Sender: TObject);
    procedure mniDocumentImportPDFClick(Sender: TObject);
    procedure mniDocumentImportSheetClick(Sender: TObject);
    procedure mniDocumentImportSQLiteClick(Sender: TObject);
    procedure mniDocumentImportTextClick(Sender: TObject);
    procedure mniDocumentImportWordClick(Sender: TObject);
    procedure mniHelpAboutClick(Sender: TObject);
    procedure mniHelpGuideClick(Sender: TObject);
    procedure mniHelpLicenseClick(Sender: TObject);
    procedure mniHelpSponsorClick(Sender: TObject);
    procedure mniHelpThirdPartyClick(Sender: TObject);
    procedure mniHelpWebsiteClick(Sender: TObject);
    procedure mniListAttributeValueCopyClick(Sender: TObject);
    procedure mniMemoAnalyticalClick(Sender: TObject);
    procedure mniMemoManageClick(Sender: TObject);
    procedure mniMemoProjectClick(Sender: TObject);
    procedure mniProjectCloseClick(Sender: TObject);
    procedure mniProjectOptimizeClick(Sender: TObject);
    procedure mniProjectSnapshotClick(Sender: TObject);
    procedure mniRetrievalClick(Sender: TObject);
    procedure mniTreeCodeAddSubCodeClick(Sender: TObject);
    procedure mniTreeCodeCollapseAllClick(Sender: TObject);
    procedure mniTreeCodeColorChangeClick(Sender: TObject);
    procedure mniTreeCodeDeleteClick(Sender: TObject);
    procedure mniTreeCodeDemoteClick(Sender: TObject);
    procedure mniTreeCodeExpandAllClick(Sender: TObject);
    procedure mniTreeCodeMemoClick(Sender: TObject);
    procedure mniTreeCodeMergeClick(Sender: TObject);
    procedure mniTreeCodeMoveDownClick(Sender: TObject);
    procedure mniTreeCodeMoveUpClick(Sender: TObject);
    procedure mniTreeCodePromoteClick(Sender: TObject);
    procedure mniTreeCodeRenameClick(Sender: TObject);
    procedure mniTreeDocumentAttributeAddClick(Sender: TObject);
    procedure mniTreeDocumentAttributeDeleteClick(Sender: TObject);
    procedure mniTreeDocumentAttributeEditClick(Sender: TObject);
    procedure mniTreeDocumentDeleteClick(Sender: TObject);
    procedure mniTreeDocumentMemoClick(Sender: TObject);
    procedure mniTreeDocumentRenameClick(Sender: TObject);
    procedure mniTreeDocumentSelectAllClick(Sender: TObject);
    procedure pbxLegendCodeNamePaint(Sender: TObject);
    procedure pmnListAttributePopup(Sender: TObject);
    procedure pmnTextPopup(Sender: TObject);
    procedure pmnTreeCodePopup(Sender: TObject);
    procedure pmnTreeDocumentPopup(Sender: TObject);
    procedure tmrCodeSearchTimer(Sender: TObject);
    procedure tmrDocumentSearchTimer(Sender: TObject);
    procedure UpdateCodeSystemMenu;
    procedure vstAttributeDblClick(Sender: TObject);
    procedure vstAttributeExit(Sender: TObject);
    procedure vstAttributeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure vstAttributeHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
    procedure vstAttributePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
  private
    FActiveCodeList: TStringList;
    FActiveDocumentOriginalText: String;
    FBracketMenuMap: specialize TDictionary<TMenuItem, String>;
    FControllerTreeCode: TCodeTreeController;
    FControllerTreeDocument: TDocumentTreeController;
    FCurrentDocumentAttribute: TDocumentAttributeArray;
    FCurrentDocumentID: String;
    FRenderDocument: TRenderDocument;
    FServiceDatabase: TServiceDatabase;
    FSortAttributeAscending: Boolean;
    FSortAttributeColumn: Integer;
    function CheckUnsavedChangesBeforeAction(const ActionContext: String = ''): Boolean;
    function ExecuteLiveEditSave: Boolean;
    function ForceExitEditMode(const ActionContext: String = ''): Boolean;
    function GetNextColor: TColor;
    function GetSelectedDocumentID: TStringDynArray;
    function OpenProject(FilePath: String): Boolean;
    procedure ApplyCoding(const CodeID: String; CodeColor: TColor);
    procedure AsyncOpenProject(Data: PtrInt);
    procedure AttributeTypeChange(Sender: TObject);
    procedure ContextCutClick(Sender: TObject);
    procedure ContextPasteClick(Sender: TObject);
    procedure LoadMemoForCurrentDocument;
    procedure OnCodeTreeChanged(Sender: TObject);
    procedure OnDocumentSelect(const DocumentID: String);
    procedure OnDocumentUIStateChange(Sender: TObject);
    procedure OnTreeCodeDoubleClick(const CodeID: String; CodeColor: TColor);
    procedure OnTreeCodeHover(CodeName: String; CodeColor: TColor);
    procedure OnTreeCodeHoverClear(Sender: TObject);
    procedure RefreshAttribute;
    procedure ReloadCurrentDocument;
    procedure RenderDocumentAnchorHover(Sender: TObject; const Cluster: TMapTickCluster);
    procedure RenderDocumentBracketHover(Sender: TObject; const CodeID: String; CodingIndex: Integer);
    procedure RenderDocumentSaveRequest(Sender: TObject);
    procedure RenderDocumentTextChanged(Sender: TObject);
    procedure RenderDocumentTextContext(Sender: TObject; const BracketCodingID: String; ClickedCharacterPosition: Integer; P: TPoint);
    procedure RenderDocumentZoomPersist(Sender: TObject; ZoomLevel: Integer);
    procedure ShowStartupDialog(Data: PtrInt);
    procedure SortAttribute;
    procedure UpdateCodeSortUI;
    procedure UpdateDashboardStatistic;
    procedure UpdateDocumentStatus;
    procedure UpdateNavigationButton;
  public
    procedure ExecuteSQLSafe(SQL: String);
    procedure RefreshCodeTree;
    procedure RefreshDocumentList;
    procedure RefreshDocumentMemos;
  end;

var
  frmAppBase: TfrmAppBase;

implementation

uses
  Clipbrd, fpjson, fpsTypes, jsonparser, LazFileUtils, LazUTF8, AppFont, AppFormat,
  AppIdentity, DialogAbout, DialogEditor, DialogFilter, DialogInput, DialogProgress,
  DialogSort, DialogStartup, ModalAnalyse, ModalAttribute, ModalMemo, ModalRetrieve,
  ServiceExport, ServiceImport, ServiceMemo;

{$R *.lfm}

procedure TfrmAppBase.FormCreate(Sender: TObject);
begin
  ApplyAppFont(Self);
  TEngineText.WarmUpEngine;
  FActiveCodeList := TStringList.Create;
  FBracketMenuMap := specialize TDictionary<TMenuItem, String>.Create;
  FRenderDocument := TRenderDocument.Create(Self);
  FRenderDocument.Parent := pnlReadContainer;
  FRenderDocument.Align := alClient;
  FRenderDocument.OnBracketHover := @RenderDocumentBracketHover;
  FRenderDocument.OnTextContext := @RenderDocumentTextContext;
  FRenderDocument.OnAnchorHover := @RenderDocumentAnchorHover;
  FRenderDocument.OnZoomPersist := @RenderDocumentZoomPersist;
  FRenderDocument.EngineText.OnTextChanged := @RenderDocumentTextChanged;
  FRenderDocument.OnSaveRequest := @RenderDocumentSaveRequest;
  FServiceDatabase := TServiceDatabase.Create(conMain);
  FControllerTreeDocument := TDocumentTreeController.Create(vstDocument, FServiceDatabase);
  FControllerTreeDocument.OnDocumentSelect := @OnDocumentSelect;
  FControllerTreeDocument.OnUIStateChange := @OnDocumentUIStateChange;
  FControllerTreeCode := TCodeTreeController.Create(vstCode, FServiceDatabase);
  FControllerTreeCode.OnCodeHover := @OnTreeCodeHover;
  FControllerTreeCode.OnCodeHoverClear := @OnTreeCodeHoverClear;
  FControllerTreeCode.OnCodeDoubleClick := @OnTreeCodeDoubleClick;
  FControllerTreeCode.OnTreeChanged := @OnCodeTreeChanged;
  vstAttribute.NodeDataSize := 0;
  FSortAttributeColumn := 0;
  FSortAttributeAscending := True;
  if ParamCount > 0 then
    Application.QueueAsyncCall(@AsyncOpenProject, 0)
  else
    Application.QueueAsyncCall(@ShowStartupDialog, 0);
end;

procedure TfrmAppBase.FormDestroy(Sender: TObject);
begin
  if Assigned(FActiveCodeList) then
    FActiveCodeList.Free;
  if Assigned(FBracketMenuMap) then
    FBracketMenuMap.Free;
  if Assigned(FControllerTreeDocument) then
    FControllerTreeDocument.Free;
  if Assigned(FControllerTreeCode) then 
    FControllerTreeCode.Free;
  if Assigned(FServiceDatabase) then
  begin
    FServiceDatabase.CloseProject;
    FServiceDatabase.Free;
  end;
  SetLength(FCurrentDocumentAttribute, 0);
end;

procedure TfrmAppBase.FormResize(Sender: TObject);
var
  RightReqWidth: Integer;
begin
  if Assigned(stbMain) and (stbMain.Panels.Count > 1) then
  begin
    stbMain.Canvas.Font.Assign(stbMain.Font);
    RightReqWidth := stbMain.Canvas.TextWidth(stbMain.Panels[1].Text) + 30;
    if RightReqWidth < (stbMain.ClientWidth div 2) then
      RightReqWidth := stbMain.ClientWidth div 2;
    stbMain.Panels[1].Width := RightReqWidth;
    stbMain.Panels[0].Width := stbMain.ClientWidth - RightReqWidth;
    UpdateDocumentStatus;
  end;
end;

procedure TfrmAppBase.ShowStartupDialog(Data: PtrInt);
var
  Selection: Integer;
  IsFileClean: Boolean;
begin
  frmDialogStartUp := TfrmDialogStartUp.Create(Self);
  try
    Selection := frmDialogStartUp.ShowModal;
  finally
    frmDialogStartUp.Free;
  end;
  if Selection = mrYes then
  begin
    if dlgNewProject.Execute then
    begin
      IsFileClean := True;
      if FileExists(dlgNewProject.FileName) then
      begin
        if MessageDlg('Overwrite Project', 
           'The file "' + ExtractFileName(dlgNewProject.FileName) + '" already exists.' + sLineBreak + 
           'Do you want to overwrite it? All data in the existing project will be lost.', 
           mtWarning, [mbYes, mbNo], 0) = mrYes then
        begin
          try
            if conMain.Connected then FServiceDatabase.CloseProject;
            SysUtils.DeleteFile(dlgNewProject.FileName);
          except
            on E: Exception do
            begin
              MessageDlg('File Locked', 
                'Could not overwrite the file. It is likely open in another application.' + sLineBreak + 
                'Error: ' + E.Message, mtError, [mbOK], 0);
              IsFileClean := False;
              Application.QueueAsyncCall(@ShowStartupDialog, 0); 
              Exit; 
            end;
          end;
        end
        else
        begin
          Application.QueueAsyncCall(@ShowStartupDialog, 0); 
          Exit;
        end;
      end;
      if IsFileClean then
      begin
        conMain.DatabaseName := dlgNewProject.FileName;
        try
          conMain.Open;
          trnMain.Active := True;
          FServiceDatabase.InitializeProject;
          trnMain.Commit;
          FServiceDatabase.CloseProject;
          MessageDlg('Success', 'Project created successfully.' + sLineBreak + sLineBreak + 'To import documents, navigate to:' + sLineBreak + 'Menu → Documents → Import Documents', mtInformation, [mbOK], 0);
          OpenProject(dlgNewProject.FileName);
        except
          on E: Exception do
            ShowMessage('Error creating project: ' + E.Message);
        end;
      end;
    end
    else
    begin
      Application.QueueAsyncCall(@ShowStartupDialog, 0);
    end;
  end
  else if Selection = mrNo then
  begin
    if dlgOpenProject.Execute then
    begin
      if not OpenProject(dlgOpenProject.FileName) then
        Application.QueueAsyncCall(@ShowStartupDialog, 0);
    end
    else
    begin
      Application.QueueAsyncCall(@ShowStartupDialog, 0);
    end;
  end
  else
  begin
    Application.Terminate;
  end;
end;

procedure TfrmAppBase.AsyncOpenProject(Data: PtrInt);
begin
  if not OpenProject(ParamStr(1)) then
    Application.QueueAsyncCall(@ShowStartupDialog, 0);
end;

function TfrmAppBase.OpenProject(FilePath: String): Boolean;
var
  TotalDocument, CodedDocument, TotalCode, TotalCoding, TotalSegmentMemo: Integer;
  DocumentCache: TDocumentCacheArray;
  CodeCache: TCodeFlatArray;
begin
  Result := False;
  if not FileExists(FilePath) then
  begin
    MessageDlg('File Not Found', 'The file "' + ExtractFileName(FilePath) + '" does not exist.', mtError, [mbOK], 0);
    Exit;
  end;
  if conMain.Connected then FServiceDatabase.CloseProject;
  try
    FServiceDatabase.LoadProjectData(FilePath, DocumentCache, CodeCache, TotalDocument, CodedDocument, TotalCode, TotalCoding, TotalSegmentMemo);
    conMain.DatabaseName := FilePath;
    conMain.Open;
    FRenderDocument.EngineText.ZoomOffset := StrToIntDef(FServiceDatabase.GetUserPreference('DocumentZoom', '0'), 0);
    FControllerTreeDocument.LoadSortPreference;
    FControllerTreeDocument.LoadData(DocumentCache, '');
    FControllerTreeCode.LoadData(CodeCache, '');
    btnCodeSort.Down := FControllerTreeCode.SortField <> 'sort_order';
    UpdateCodeSortUI;
    if Assigned(stbMain) then
      stbMain.Panels[1].Text := Format(
        ' Project Statistics:  %s %s  ·  %s %s  ·  %s %s  ·  %s %s  ·  %s %s ',
        [FormatFloat('#,##0', TotalDocument), TAppFormat.Pluralize(TotalDocument, 'Total Document', 'Total Documents'),
         FormatFloat('#,##0', CodedDocument), TAppFormat.Pluralize(CodedDocument, 'Coded Document', 'Coded Documents'),
         FormatFloat('#,##0', TotalCode), TAppFormat.Pluralize(TotalCode, 'Code', 'Codes'),
         FormatFloat('#,##0', TotalCoding), TAppFormat.Pluralize(TotalCoding, 'Coding', 'Codings'),
         FormatFloat('#,##0', TotalSegmentMemo), TAppFormat.Pluralize(TotalSegmentMemo, 'Segment Memo', 'Segment Memos')]
      );
    Self.Caption := 'Lattice · ' + ExtractFileName(ExtractFileNameWithoutExt(FilePath));
    UpdateCodeSystemMenu;
    Result := True;
  except
    on E: Exception do
    begin
      if E.Message = 'InvalidProject' then
        MessageDlg('Invalid Project', 'The selected file is not a valid Lattice project database.', mtError, [mbOK], 0)
      else
        MessageDlg('Database Error', 'Could not access the database: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmAppBase.ExecuteSQLSafe(SQL: String);
begin
  if trnMain.Active then trnMain.Commit;
  qryMain.Close;
  qryMain.SQL.Text := SQL;
  try
    qryMain.ExecSQL;
    trnMain.Commit;
  except
    trnMain.Rollback;
    MessageDlg('Database Error', 'A database error occurred. The current transaction has been cancelled to prevent data corruption.', mtError, [mbOK], 0);
  end;
end;

function TfrmAppBase.GetNextColor: TColor;
const Palette: array[0..19] of TColor = (
  $00693A5C, $001E1C8B, $006E421D, $00155E1E, $004A248C,
  $00004FA6, $00095975, $00575C10, $00263A5E, $00323338,
  $00805B8E, $003F3CC4, $0091623B, $00378A41, $006F4AB8,
  $00146FD9, $001D7F9E, $007D822E, $003F5785, $0054555E
);
var Count: Integer;
begin
  qryCheck.Close;
  qryCheck.SQL.Text := 'SELECT count(*) FROM codes';
  try
    qryCheck.Open;
    Count := qryCheck.Fields[0].AsInteger;
    Result := Palette[Count mod 20];
  finally
    qryCheck.Close;
  end;
end;

procedure TfrmAppBase.UpdateDashboardStatistic;
var
  TotalDocument, CodedDocument, TotalCode, TotalCoding, TotalSegmentMemo: Integer;
  RightReqWidth: Integer;
begin
  if (stbMain = nil) or not conMain.Connected then Exit;
  FServiceDatabase.GetDashboardStatistic(TotalDocument, CodedDocument, TotalCode, TotalCoding, TotalSegmentMemo);
  stbMain.Panels[1].Text := Format(
    ' Project Statistics:  %s %s  ·  %s %s  ·  %s %s  ·  %s %s  ·  %s %s ',
    [FormatFloat('#,##0', TotalDocument), TAppFormat.Pluralize(TotalDocument, 'Total Document', 'Total Documents'),
     FormatFloat('#,##0', CodedDocument), TAppFormat.Pluralize(CodedDocument, 'Coded Document', 'Coded Documents'),
     FormatFloat('#,##0', TotalCode), TAppFormat.Pluralize(TotalCode, 'Code', 'Codes'),
     FormatFloat('#,##0', TotalCoding), TAppFormat.Pluralize(TotalCoding, 'Coding', 'Codings'),
     FormatFloat('#,##0', TotalSegmentMemo), TAppFormat.Pluralize(TotalSegmentMemo, 'Segment Memo', 'Segment Memos')]
  );
  stbMain.Canvas.Font.Assign(stbMain.Font);
  RightReqWidth := stbMain.Canvas.TextWidth(stbMain.Panels[1].Text) + 30;
  if RightReqWidth < (stbMain.ClientWidth div 2) then
    RightReqWidth := stbMain.ClientWidth div 2;
  stbMain.Panels[1].Width := RightReqWidth;
  stbMain.Panels[0].Width := stbMain.ClientWidth - RightReqWidth;
  UpdateDocumentStatus;
end;

procedure TfrmAppBase.UpdateDocumentStatus;
var
  TotalDocument, CurrentCount: Integer;
  MessageText, DocWord: String;
  HasSearch, HasAdvancedFilter: Boolean;
  Prefix, Suffix, CleanQuery: String;
  AvailableWidth: Integer;
begin
  if (stbMain = nil) or not conMain.Connected then Exit;
  TotalDocument := FServiceDatabase.GetDocumentCount(Default(TDocumentFilterDefinition));
  CurrentCount := FControllerTreeDocument.DocumentCount;
  HasSearch := Trim(FControllerTreeDocument.FilterDefinition.QuickSearchText) <> '';
  HasAdvancedFilter := FControllerTreeDocument.FilterDefinition.IsFilterActive;
  DocWord := TAppFormat.Pluralize(TotalDocument, 'Document', 'Documents');
  if HasSearch then
  begin
    CleanQuery := Trim(FControllerTreeDocument.FilterDefinition.QuickSearchText);
    Prefix := ' Search "';
    if HasAdvancedFilter then
      Suffix := Format('" within Filter: %s of %s %s Found ', [FormatFloat('#,##0', CurrentCount), FormatFloat('#,##0', TotalDocument), DocWord])
    else
      Suffix := Format('": %s of %s %s Found ', [FormatFloat('#,##0', CurrentCount), FormatFloat('#,##0', TotalDocument), DocWord]);
    stbMain.Canvas.Font.Assign(stbMain.Font);
    AvailableWidth := stbMain.Panels[0].Width - stbMain.Canvas.TextWidth(Prefix + Suffix) - 20;
    if AvailableWidth < 20 then AvailableWidth := 20;
    if stbMain.Canvas.TextWidth(CleanQuery) > AvailableWidth then
    begin
      while (UTF8Length(CleanQuery) > 1) and (stbMain.Canvas.TextWidth(CleanQuery + '...') > AvailableWidth) do
        UTF8Delete(CleanQuery, UTF8Length(CleanQuery), 1);
      CleanQuery := CleanQuery + '...';
    end;
    MessageText := Prefix + CleanQuery + Suffix;
  end
  else if HasAdvancedFilter then
    MessageText := Format(' Filter Active: Showing %s of %s %s ', [FormatFloat('#,##0', CurrentCount), FormatFloat('#,##0', TotalDocument), DocWord])
  else
  begin
    if TotalDocument = 1 then
      MessageText := ' Viewing 1 Document '
    else
      MessageText := Format(' Viewing all %s %s ', [FormatFloat('#,##0', TotalDocument), DocWord]);
  end;
  stbMain.Panels[0].Text := MessageText;
end;

procedure TfrmAppBase.UpdateNavigationButton;
var
  HasPrevious, HasNext: Boolean;
begin
  if FCurrentDocumentID = '' then
  begin
    btnReadDocumentPrevious.Visible := False;
    btnReadDocumentNext.Visible := False;
  end
  else
  begin
    HasPrevious := FControllerTreeDocument.HasPreviousDocument;
    HasNext := FControllerTreeDocument.HasNextDocument;
    btnReadDocumentPrevious.Visible := True;
    btnReadDocumentNext.Visible := True;
    btnReadDocumentPrevious.Enabled := HasPrevious;
    btnReadDocumentNext.Enabled := HasNext;
    if HasPrevious then
      btnReadDocumentPrevious.Hint := 'Previous Document'
    else
      btnReadDocumentPrevious.Hint := 'No Previous Document';
    if HasNext then
      btnReadDocumentNext.Hint := 'Next Document'
    else
      btnReadDocumentNext.Hint := 'No Next Document';
  end;
end;

procedure TfrmAppBase.RefreshDocumentList;
begin
  FControllerTreeDocument.RefreshTree(FCurrentDocumentID, False);
end;

procedure TfrmAppBase.OnDocumentSelect(const DocumentID: String);
var
  TargetID: String;
begin
  if FCurrentDocumentID = DocumentID then Exit;
  if not ForceExitEditMode('before switching') then
  begin
    TargetID := FCurrentDocumentID;
    FControllerTreeDocument.OnDocumentSelect := nil;
    try
      FControllerTreeDocument.ClearSelection;
      if TargetID <> '' then
        FControllerTreeDocument.SelectDocumentByID(TargetID);
    finally
      FControllerTreeDocument.OnDocumentSelect := @OnDocumentSelect;
    end;
    Exit;
  end;
  FCurrentDocumentID := DocumentID;
  ReloadCurrentDocument;
  RefreshAttribute;
  if FActiveCodeList.Count > 0 then
  begin
    FActiveCodeList.Clear;
    pbxLegendCodeName.Invalidate;
  end;
end;

procedure TfrmAppBase.OnDocumentUIStateChange(Sender: TObject);
var
  IsDefault: Boolean;
begin
  IsDefault := SameText(FControllerTreeDocument.SortField, 'id') and SameText(FControllerTreeDocument.SortOrder, 'ASC');
  btnDocumentSort.Down := not IsDefault;
  lblCurrentSort.Visible := not IsDefault;
  if not IsDefault then
  begin
    lblCurrentSort.Caption := FControllerTreeDocument.SortDescription;
    btnDocumentSort.Hint := 'Documents ' + lblCurrentSort.Caption;
  end else btnDocumentSort.Hint := 'Sort Documents';
  btnDocumentFilter.Down := FControllerTreeDocument.FilterDefinition.IsFilterActive;
  if FControllerTreeDocument.FilterDefinition.IsFilterActive then
  begin
    edtDocumentSearch.TextHint := 'Search within filtered';
    btnDocumentFilter.Hint := 'Documents Filtered by Active Criteria';
  end
  else
  begin
    edtDocumentSearch.TextHint := 'Search document name';
    btnDocumentFilter.Hint := 'Filter Documents';
  end;
  UpdateDashboardStatistic;
  UpdateDocumentStatus;
  UpdateNavigationButton;
end;

procedure TfrmAppBase.ReloadCurrentDocument;
var
  DocumentTitle, DisplayTitle: String;
  Query: TSQLQuery;
begin
  if FCurrentDocumentID = '' then
  begin
    FRenderDocument.SetText('');
    lblReadDocumentTitle.Caption := 'No Document Open';
    lblReadDocumentTitle.Hint := '';
    LoadCodingForCurrentDocument;
    if Assigned(edtReadSearch) then 
    begin
      edtReadSearch.Clear;
      btnReadSearchPrevious.Visible := False;
      btnReadSearchNext.Visible := False;
      lblReadSearchCount.Visible := False;
    end;
    btnDocumentEditEnter.Visible := False;
    btnDocumentEditExit.Visible := False;
    if Assigned(lblEditStatus) then lblEditStatus.Visible := False;
    UpdateNavigationButton;
    Exit;
  end;
  btnDocumentEditEnter.Visible := True;
  btnDocumentEditEnter.ImageIndex := 9;
  btnDocumentEditEnter.Hint := 'Enter Edit Mode';
  btnDocumentEditExit.Visible := False;
  FRenderDocument.EngineText.SetEditing(False);
  Query := TSQLQuery.Create(nil);
  try
    Query.Database := conMain;
    Query.UniDirectional := True;
    Query.SQL.Text := 'SELECT title, content FROM documents WHERE id = :id';
    Query.Params.ParamByName('id').AsString := FCurrentDocumentID;
    Query.Open;
    DocumentTitle := Query.FieldByName('title').AsString;
    if UTF8Length(DocumentTitle) > 25 then
      DisplayTitle := UTF8Copy(DocumentTitle, 1, 25) + '...'
    else
      DisplayTitle := DocumentTitle;
    lblReadDocumentTitle.Caption := DisplayTitle;
    lblReadDocumentTitle.Hint := TAppFormat.FormatUIHint(DocumentTitle);
    FRenderDocument.SetText(Query.FieldByName('content').AsString);
  finally
    Query.Free;
  end;
  LoadCodingForCurrentDocument;
  LoadMemoForCurrentDocument;
  if Assigned(edtReadSearch) then
  begin
    edtReadSearch.OnChange := nil;
    edtReadSearch.Clear;
    lblReadSearchCount.Caption := '';
    btnReadSearchPrevious.Visible := False;
    btnReadSearchNext.Visible := False;
    lblReadSearchCount.Visible := False;
    edtReadSearch.OnChange := @edtReadSearchChange;
  end;
  UpdateNavigationButton;
end;

procedure TfrmAppBase.LoadCodingForCurrentDocument;
var
  Coding: TCodingArray;
  i, Capacity: Integer;
  Query: TSQLQuery;
begin
  if FCurrentDocumentID = '' then
  begin
    SetLength(Coding, 0);
    FRenderDocument.UpdateCoding(Coding);
    Exit;
  end;
  Query := TSQLQuery.Create(nil);
  try
    Query.Database := conMain;
    Query.UniDirectional := True;
    Query.SQL.Text :=
      'SELECT c.id, c.start_position, c.length, co.color, co.name ' +
      'FROM codings c ' +
      'JOIN codes co ON c.code_id = co.id ' +
      'WHERE c.document_id = :doc ' +
      'ORDER BY c.start_position ASC, c.length DESC';
    Query.ParamByName('doc').AsString := FCurrentDocumentID;
    Query.Open;
    Capacity := 128;
    SetLength(Coding, Capacity);
    i := 0;
    while not Query.EOF do
    begin
      if i >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(Coding, Capacity);
      end;
      Coding[i].ID        := Query.FieldByName('id').AsString;
      Coding[i].StartCharacter := Query.FieldByName('start_position').AsInteger;
      Coding[i].Length    := Query.FieldByName('length').AsInteger;
      Coding[i].Color     := TColor(Query.FieldByName('color').AsInteger);
      Coding[i].Name      := Query.FieldByName('name').AsString;
      Inc(i);
      Query.Next;
    end;
    SetLength(Coding, i);
  finally
    Query.Free;
  end;
  FRenderDocument.UpdateCoding(Coding);
end;

procedure TfrmAppBase.LoadMemoForCurrentDocument;
var
  Memo: array of TMemoMatch;
  LocalQuery: TSQLQuery;
  TargetPrefix: String;
  PartArray: TStringArray;
  StartPosition, MatchLength: Integer;
begin
  if FCurrentDocumentID = '' then Exit;
  TargetPrefix := FCurrentDocumentID + ':%';
  SetLength(Memo, 0);
  LocalQuery := TSQLQuery.Create(nil);
  try
    LocalQuery.Database := conMain;
    LocalQuery.SQL.Text := 'SELECT reference FROM memos WHERE memo_type = ''Segment'' AND reference LIKE :t';
    LocalQuery.Params.ParamByName('t').AsString := TargetPrefix;
    LocalQuery.Open;
    while not LocalQuery.EOF do
    begin
      PartArray := LocalQuery.FieldByName('reference').AsString.Split([':']);
      if Length(PartArray) = 3 then
      begin
        StartPosition := StrToIntDef(PartArray[1], 0);
        MatchLength := StrToIntDef(PartArray[2], 0);
        SetLength(Memo, Length(Memo) + 1);
        Memo[High(Memo)].ID := LocalQuery.FieldByName('reference').AsString;
        Memo[High(Memo)].StartByte := FRenderDocument.EngineText.CharToByte(StartPosition);
        Memo[High(Memo)].LengthBytes := FRenderDocument.EngineText.CharToByte(StartPosition + MatchLength) - Memo[High(Memo)].StartByte;
      end;
      LocalQuery.Next;
    end;
    LocalQuery.Close;
  finally
    LocalQuery.Free;
  end;
  FRenderDocument.EngineText.SetMemoHighlights(Memo);
end;

procedure TfrmAppBase.RefreshDocumentMemos;
begin
  LoadMemoForCurrentDocument;
  if Assigned(FRenderDocument) then
    FRenderDocument.Invalidate;
end;

procedure TfrmAppBase.btnCloseDocumentClick(Sender: TObject);
begin
  FControllerTreeDocument.ClearSelection;
end;

procedure TfrmAppBase.btnReadDocumentNextClick(Sender: TObject);
begin
  FControllerTreeDocument.SelectNextDocument;
end;

procedure TfrmAppBase.btnReadDocumentPreviousClick(Sender: TObject);
begin
  FControllerTreeDocument.SelectPreviousDocument;
end;

procedure TfrmAppBase.btnDocumentFilterClick(Sender: TObject);
var
  NewTitle, NewBody, NewAttributeSQL, NewAttributeID, NewAttributeOperator, NewAttributeValue: String;
  ClearReq: Boolean;
begin
  if not conMain.Connected then Exit;
  if not ForceExitEditMode then Exit;
  if TfrmDialogFilter.Execute(conMain, 
    FControllerTreeDocument.FilterDefinition.TitlePattern, 
    FControllerTreeDocument.FilterDefinition.BodyTextQuery,
    FControllerTreeDocument.FilterDefinition.AttributeID,
    FControllerTreeDocument.FilterDefinition.AttributeOperator,
    FControllerTreeDocument.FilterDefinition.AttributeValue,
    NewTitle, NewBody, NewAttributeID, NewAttributeOperator, NewAttributeValue, NewAttributeSQL, ClearReq) then
  begin
    if ClearReq then
      FControllerTreeDocument.ClearFilter
    else
      FControllerTreeDocument.ApplyFilter(NewTitle, NewBody, NewAttributeSQL, NewAttributeID, NewAttributeOperator, NewAttributeValue);
  end;
  OnDocumentUIStateChange(Self);
end;

procedure TfrmAppBase.btnDocumentSortClick(Sender: TObject);
var
  AttributeList: TStringList;
  FullSpecification, CleanCriteria, SortField, SortOrder: String;
  PositionIndex: Integer;
  IsAttribute: Boolean;
begin
  if not ForceExitEditMode then Exit;
  AttributeList := TStringList.Create;
  try
    qryUtil.Close;
    qryUtil.SQL.Text := 'SELECT name, attribute_type FROM attribute_registry ORDER BY name ASC';
    qryUtil.Open;
    while not qryUtil.EOF do
    begin
      AttributeList.Add(qryUtil.FieldByName('name').AsString + ' · ' + qryUtil.FieldByName('attribute_type').AsString);
      qryUtil.Next;
    end;
    frmDialogSort := TfrmDialogSort.Create(Self);
    try
      frmDialogSort.InitializeOptions(AttributeList, FControllerTreeDocument.SortCriteria, FControllerTreeDocument.SortOrder = 'DESC', False, False);
      if frmDialogSort.ShowModal = mrOk then
      begin
        if frmDialogSort.Tag = 999 then
          FControllerTreeDocument.ApplySort('Import Time', 'id', 'ASC', False)
        else
        begin
          FullSpecification := frmDialogSort.cmbSortCriteria.Text;
          PositionIndex := Pos(' · ', FullSpecification);
          if PositionIndex > 0 then CleanCriteria := Copy(FullSpecification, 1, PositionIndex - 1)
          else CleanCriteria := FullSpecification;          
          SortOrder := 'ASC';
          if frmDialogSort.rgSortOrder.ItemIndex = 1 then SortOrder := 'DESC';
          if CleanCriteria = 'Document Name' then
          begin SortField := 'title'; IsAttribute := False; end
          else if CleanCriteria = 'Coding Count' then
          begin SortField := 'cc'; IsAttribute := False; end
          else if CleanCriteria = 'Segment Memo Count' then
          begin SortField := 'mc'; IsAttribute := False; end
          else if CleanCriteria = 'Import Time' then
          begin SortField := 'id'; IsAttribute := False; end
          else
          begin SortField := CleanCriteria; IsAttribute := True; end;
          FControllerTreeDocument.ApplySort(CleanCriteria, SortField, SortOrder, IsAttribute);
        end;
      end;
    finally
      frmDialogSort.Free;
    end;
  finally
    AttributeList.Free;
  end;
  OnDocumentUIStateChange(Self);
end;

procedure TfrmAppBase.tmrDocumentSearchTimer(Sender: TObject);
begin
  tmrDocumentSearch.Enabled := False;
  FControllerTreeDocument.ApplySearch(edtDocumentSearch.Text);
end;

procedure TfrmAppBase.edtDocumentSearchChange(Sender: TObject);
begin
  tmrDocumentSearch.Enabled := False;
  tmrDocumentSearch.Enabled := True;
end;

procedure TfrmAppBase.edtDocumentSearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    tmrDocumentSearch.Enabled := False;
    FControllerTreeDocument.ApplySearch(edtDocumentSearch.Text);
    Key := 0;
  end;
end;

procedure TfrmAppBase.btnDocumentSearchClick(Sender: TObject);
begin
  FControllerTreeDocument.ApplySearch(edtDocumentSearch.Text);
end;

procedure TfrmAppBase.pmnTreeDocumentPopup(Sender: TObject);
var
  IsSingle, HasAttributes: Boolean;
begin
  IsSingle := (vstDocument.SelectedCount = 1);
  HasAttributes := False;
  if vstDocument.SelectedCount > 0 then
  begin
    qryMain.Close;
    qryMain.SQL.Text := 'SELECT 1 FROM attribute_registry LIMIT 1';
    qryMain.Open;
    HasAttributes := not qryMain.EOF;
    qryMain.Close;
  end;
  mniTreeDocumentRename.Visible := IsSingle;
  mniTreeDocumentRename.Enabled := IsSingle;
  mniTreeDocumentMemo.Visible := IsSingle;
  mniTreeDocumentMemo.Enabled := IsSingle;
  if IsSingle then
  begin
    mniTreeDocumentAttributeAdd.Caption := 'Add Attribute';
    mniTreeDocumentAttributeEdit.Caption := 'Edit Attribute Value';
    mniTreeDocumentAttributeDelete.Caption := 'Delete Attribute';
    mniTreeDocumentDelete.Caption := 'Delete Document';
  end
  else
  begin
    mniTreeDocumentAttributeAdd.Caption := 'Batch Add Attribute';
    mniTreeDocumentAttributeEdit.Caption := 'Batch Edit Attribute Value';
    mniTreeDocumentAttributeDelete.Caption := 'Batch Delete Attribute';
    mniTreeDocumentDelete.Caption := 'Batch Delete Documents';
  end;
  mniTreeDocumentAttributeAdd.Enabled := (vstDocument.SelectedCount > 0) and HasAttributes;
  mniTreeDocumentAttributeEdit.Enabled := (vstDocument.SelectedCount > 0) and HasAttributes;
  mniTreeDocumentAttributeDelete.Enabled := (vstDocument.SelectedCount > 0) and HasAttributes;
  mniTreeDocumentDelete.Enabled := (vstDocument.SelectedCount > 0);
end;

function TfrmAppBase.GetSelectedDocumentID: TStringDynArray;
begin
  Result := FControllerTreeDocument.GetSelectedID;
end;

procedure TfrmAppBase.mniTreeDocumentSelectAllClick(Sender: TObject);
var
  Node: PVirtualNode;
begin
  vstDocument.BeginUpdate;
  try
    Node := vstDocument.GetFirstVisible;
    while Assigned(Node) do
    begin
      vstDocument.Selected[Node] := True;
      Node := vstDocument.GetNextVisible(Node);
    end;
  finally
    vstDocument.EndUpdate;
  end;
end;

procedure TfrmAppBase.mniTreeDocumentRenameClick(Sender: TObject);
var
  CurrentTitle, NewTitle, DisplayTitle: String;
  TargetDocumentID: String;
  Exists: Boolean;
  DocumentID: TStringDynArray;
  PartArray: TStringArray;
  StartCharacter, LengthCharacter, i: Integer;
  MemoData: TStringList;
begin
  if vstDocument.SelectedCount = 0 then Exit;
  if not ForceExitEditMode then Exit;
  DocumentID := FControllerTreeDocument.GetSelectedID;
  if Length(DocumentID) = 0 then Exit;
  TargetDocumentID := DocumentID[0];
  qryMain.Close;
  qryMain.SQL.Text := 'SELECT title FROM documents WHERE id = :id';
  qryMain.Params.ParamByName('id').AsString := TargetDocumentID;
  qryMain.Open;
  CurrentTitle := qryMain.FieldByName('title').AsString;
  qryMain.Close;
  frmDialogInput := TfrmDialogInput.Create(Self);
  try
    if not frmDialogInput.Execute('Rename Document', 'New Name', CurrentTitle, NewTitle) then Exit;
  finally
    frmDialogInput.Free;
  end;
  if (NewTitle = '') or (NewTitle = CurrentTitle) then Exit;
  qryCheck.Close;
  qryCheck.SQL.Text := 'SELECT 1 FROM documents WHERE LOWER(title) = LOWER(:t) AND id <> :id';
  qryCheck.Params.ParamByName('t').AsString := NewTitle;
  qryCheck.Params.ParamByName('id').AsString := TargetDocumentID;
  qryCheck.Open;
  Exists := not qryCheck.EOF;
  qryCheck.Close;
  if Exists then
  begin
    MessageDlg('Naming Conflict', 'A document with this name already exists.', mtError, [mbOK], 0);
    Exit;
  end;
  MemoData := TStringList.Create;
  try
    qryCheck.Close;
    qryCheck.SQL.Text := 'SELECT id, reference FROM memos WHERE memo_type = ''Segment'' AND reference LIKE :t';
    qryCheck.Params.ParamByName('t').AsString := TargetDocumentID + ':%';
    qryCheck.Open;
    while not qryCheck.EOF do
    begin
      MemoData.Add(qryCheck.FieldByName('id').AsString + '=' + qryCheck.FieldByName('reference').AsString);
      qryCheck.Next;
    end;
    qryCheck.Close;
    if not trnMain.Active then trnMain.StartTransaction;
    try
      qryMain.SQL.Text := 'UPDATE documents SET title = :t WHERE id = :id';
      qryMain.Params.ParamByName('t').AsString := NewTitle;
      qryMain.Params.ParamByName('id').AsString := TargetDocumentID;
      qryMain.ExecSQL;
      qryMain.SQL.Text := 'UPDATE memos SET title = :mt WHERE memo_type = ''Document'' AND reference = :tid';
      qryMain.Params.ParamByName('mt').AsString := 'Document Memo · ' + NewTitle;
      qryMain.Params.ParamByName('tid').AsString := TargetDocumentID;
      qryMain.ExecSQL;
      for i := 0 to MemoData.Count - 1 do
      begin
        PartArray := MemoData.ValueFromIndex[i].Split([':']);
        if Length(PartArray) = 3 then
        begin
          StartCharacter := StrToIntDef(PartArray[1], 0);
          LengthCharacter := StrToIntDef(PartArray[2], 0);
          qryMain.SQL.Text := 'UPDATE memos SET title = :mt WHERE id = :mid';
          qryMain.Params.ParamByName('mt').AsString := 'Segment Memo · ' + NewTitle + ' · ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter);
          qryMain.Params.ParamByName('mid').AsString := MemoData.Names[i];
          qryMain.ExecSQL;
        end;
      end;
      trnMain.Commit;
      FControllerTreeDocument.UpdateSelectedNodeTitle(NewTitle);
      if TargetDocumentID = FCurrentDocumentID then
      begin
        if UTF8Length(NewTitle) > 25 then
          DisplayTitle := UTF8Copy(NewTitle, 1, 25) + '...'
        else
          DisplayTitle := NewTitle;
        lblReadDocumentTitle.Caption := DisplayTitle;
        lblReadDocumentTitle.Hint := TAppFormat.FormatUIHint(NewTitle);
      end;
    except
      on E: Exception do
      begin
        trnMain.Rollback;
        MessageDlg('Database Error', 'Failed to rename document and update memos: ' + E.Message, mtError, [mbOK], 0);
      end;
    end;
  finally
    MemoData.Free;
  end;
end;

procedure TfrmAppBase.mniTreeDocumentDeleteClick(Sender: TObject);
var
  ConfirmMessage: String;
  DocumentID: TStringDynArray;
  TargetDocumentID: String;
  NeedsUIClear: Boolean;
  FallbackID: String;
  Worker: TThreadBatchDocumentDelete;
begin
  if vstDocument.SelectedCount = 0 then Exit;
  if not ForceExitEditMode then Exit;
  if vstDocument.SelectedCount = 1 then
    ConfirmMessage := 'Are you sure you want to delete the selected document and all associated data?'
  else
    ConfirmMessage := Format('Are you sure you want to delete the %d selected documents and all associated data?', [vstDocument.SelectedCount]);
  if MessageDlg('Confirm Deletion', ConfirmMessage, mtWarning, [mbYes, mbNo], 0) = mrNo then Exit;
  FallbackID := FControllerTreeDocument.GetFallbackSelectionID;
  DocumentID := FControllerTreeDocument.GetSelectedID;
  if Length(DocumentID) = 0 then Exit;
  NeedsUIClear := False;
  for TargetDocumentID in DocumentID do
  begin
    if TargetDocumentID = FCurrentDocumentID then
    begin
      NeedsUIClear := True;
      Break;
    end;
  end;
  Worker := TThreadBatchDocumentDelete.Create(conMain.DatabaseName);
  try
    Worker.FDocumentID := Copy(DocumentID);
    Worker.Start;
    if Length(DocumentID) = 1 then
      TfrmDialogProgress.Prepare('Deleting Document', 'Initialising...')
    else
      TfrmDialogProgress.Prepare('Deleting Documents', 'Initialising...');
    frmDialogProgress.ShowModal;
    if trnMain.Active then trnMain.Commit;
    if Worker.Success then
    begin
      FControllerTreeDocument.RefreshTree(FallbackID, False);
      RefreshCodeTree;
      UpdateDashboardStatistic;
      if NeedsUIClear then
      begin
        if FallbackID <> '' then
          OnDocumentSelect(FallbackID)
        else
        begin
          FCurrentDocumentID := '';
          FRenderDocument.SetText('');
          LoadCodingForCurrentDocument;
          vstAttribute.RootNodeCount := 0;
          SetLength(FCurrentDocumentAttribute, 0);
        end;
      end;
      MessageDlg('Success', Format('Successfully deleted %d %s.', [Worker.FDeletedCount, TAppFormat.Pluralize(Worker.FDeletedCount, 'document', 'documents')]), mtInformation, [mbOK], 0);
    end
    else
    begin
      MessageDlg('Database Error', 'Deletion failed: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
    end;
  finally
    Worker.Free;
  end;
end;

procedure TfrmAppBase.mniTreeDocumentMemoClick(Sender: TObject);
var
  DocumentID: TStringDynArray;
  TargetDocumentID, TargetTitle: String;
begin
  if vstDocument.SelectedCount = 0 then Exit;
  DocumentID := FControllerTreeDocument.GetSelectedID;
  if Length(DocumentID) = 0 then Exit;
  TargetDocumentID := DocumentID[0];
  qryCheck.Close;
  qryCheck.SQL.Text := 'SELECT title FROM documents WHERE id = :id';
  qryCheck.Params.ParamByName('id').AsString := TargetDocumentID;
  qryCheck.Open;
  TargetTitle := qryCheck.FieldByName('title').AsString;
  qryCheck.Close;
  TServiceMemo.Execute(conMain, 'Document', TargetDocumentID, TargetTitle);
  RefreshDocumentList;
end;

procedure TfrmAppBase.mniTreeDocumentAttributeAddClick(Sender: TObject);
var
  AttributeList, CategoryOption: TStringList;
  AttributeName, AttributeValue, DialogTitle, ConfirmMsg: String;
  DocumentID: TStringDynArray;
  AttributeID, AttributeType, ColumnName, DisplayName: String;
  SelectionIndex, DocsWithAttribute: Integer;
  Worker: TThreadBatchAttribute;
begin
  if vstDocument.SelectedCount = 0 then Exit;
  DocumentID := FControllerTreeDocument.GetSelectedID;
  if Length(DocumentID) = 0 then Exit;
  AttributeList := TStringList.Create;
  CategoryOption := TStringList.Create;
  try
    FServiceDatabase.GetAllAttributeName(AttributeList);
    if AttributeList.Count = 0 then
    begin
      MessageDlg('No Attributes', 'There are no attributes defined. Please create attributes in the Attribute Manager first.', mtInformation, [mbOK], 0);
      Exit;
    end;
    if Length(DocumentID) > 1 then
      DialogTitle := Format('Add Attribute (%d Documents)', [Length(DocumentID)])
    else
      DialogTitle := 'Add Attribute';
    frmDialogInput := TfrmDialogInput.Create(Self);
    try
      if not frmDialogInput.Execute(DialogTitle, 'Select Attribute to Add', AttributeList, SelectionIndex) then Exit;
    finally
      frmDialogInput.Free;
    end;
    AttributeName := AttributeList[SelectionIndex];
    FServiceDatabase.GetAttributeDetails(AttributeName, AttributeID, AttributeType);
    ColumnName := 'attribute_' + Copy(StringReplace(AttributeID, '-', '', [rfReplaceAll]), 1, 16);
    DocsWithAttribute := FServiceDatabase.CountDocumentsWithAttribute(DocumentID, ColumnName);
    if Length(DocumentID) = 1 then
    begin
      if DocsWithAttribute > 0 then
      begin
        MessageDlg('Attribute Exists', 'This document already possesses the "' + AttributeName + '" attribute. Please use "Edit Attribute Value" to modify it.', mtInformation, [mbOK], 0);
        Exit;
      end;
    end
    else
    begin
      if DocsWithAttribute = Length(DocumentID) then
      begin
        MessageDlg('Attribute Exists', 'All selected documents already possess the "' + AttributeName + '" attribute. Please use "Edit Attribute Value" to modify them.', mtInformation, [mbOK], 0);
        Exit;
      end;
    end;
    if AttributeType = 'Categorical' then
      FServiceDatabase.GetCategoricalValue(AttributeID, CategoryOption);
    DisplayName := AttributeName;
    if UTF8Length(DisplayName) > 25 then
      DisplayName := UTF8Copy(DisplayName, 1, 25) + '...';
    frmDialogInput := TfrmDialogInput.Create(Self);
    try
      if not frmDialogInput.Execute(DialogTitle, DisplayName + ' · ' + AttributeType + ' Attribute', AttributeType, '', CategoryOption, AttributeValue) then Exit;
    finally
      frmDialogInput.Free;
    end;
    if Length(DocumentID) = 1 then
    begin
      try
        qryCheck.Close;
        if AttributeType = 'Numeric' then
          qryCheck.SQL.Text := 'UPDATE document_attributes SET attributes = json_set(attributes, ''$.'' || :col, json(:val)) WHERE document_id = :did'
        else
          qryCheck.SQL.Text := 'UPDATE document_attributes SET attributes = json_set(attributes, ''$.'' || :col, :val) WHERE document_id = :did';
        qryCheck.Params.ParamByName('col').AsString := ColumnName;
        qryCheck.Params.ParamByName('val').AsString := Trim(AttributeValue);
        qryCheck.Params.ParamByName('did').AsString := DocumentID[0];
        qryCheck.ExecSQL;
        if trnMain.Active then trnMain.Commit;
        RefreshAttribute;
        MessageDlg('Success', 'Successfully added the attribute to the document.', mtInformation, [mbOK], 0);
      except
        on E: Exception do MessageDlg('Database Error', 'Failed to add attribute: ' + E.Message, mtError, [mbOK], 0);
      end;
    end
    else
    begin
      Worker := TThreadBatchAttribute.Create(conMain.DatabaseName);
      try
        Worker.FAction := baaAdd;
        Worker.FDocumentID := Copy(DocumentID);
        Worker.FAttributeID := AttributeID;
        Worker.FValue := Trim(AttributeValue);
        Worker.Start;
        TfrmDialogProgress.Prepare('Applying Attributes', 'Initialising...');
        frmDialogProgress.ShowModal;
        if trnMain.Active then trnMain.Commit;
        if Worker.Success then
        begin
          RefreshAttribute;
          if Worker.FSkippedCount > 0 then
            ConfirmMsg := Format('Added the attribute to %d %s. Skipped %d %s that already possessed it.', [Worker.FAddedCount, TAppFormat.Pluralize(Worker.FAddedCount, 'document', 'documents'), Worker.FSkippedCount, TAppFormat.Pluralize(Worker.FSkippedCount, 'document', 'documents')])
          else
            ConfirmMsg := Format('Successfully added the attribute to %d %s.', [Worker.FAddedCount, TAppFormat.Pluralize(Worker.FAddedCount, 'document', 'documents')]);
          MessageDlg('Success', ConfirmMsg, mtInformation, [mbOK], 0);
        end
        else
          MessageDlg('Error', 'Operation failed: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
      finally
        Worker.Free;
      end;
    end;
  finally
    AttributeList.Free;
    CategoryOption.Free;
  end;
end;

procedure TfrmAppBase.mniTreeDocumentAttributeEditClick(Sender: TObject);
var
  AttributeList, CategoryOption: TStringList;
  AttributeName, NewValue, DialogTitle, AttributeID, AttributeType, ColumnName, ExistingValue, DisplayName, MissingMsg: String;
  DocumentID: TStringDynArray;
  SelectedIndex, DocsWithAttribute, MissingCount, Res: Integer;
  UpdateMissing: Boolean;
  Worker: TThreadBatchAttribute;
begin
  if vstDocument.SelectedCount = 0 then Exit;
  DocumentID := FControllerTreeDocument.GetSelectedID;
  if Length(DocumentID) = 0 then Exit;
  AttributeList := TStringList.Create;
  CategoryOption := TStringList.Create;
  try
    FServiceDatabase.GetCommonAttributeName(DocumentID, AttributeList);
    if AttributeList.Count = 0 then
    begin
      if Length(DocumentID) = 1 then
        MessageDlg('No Attributes', 'This document does not possess any attributes to edit.', mtInformation, [mbOK], 0)
      else
        MessageDlg('No Shared Attributes', 'The selected documents do not possess any common attributes to edit.', mtInformation, [mbOK], 0);
      Exit;
    end;
    if Length(DocumentID) > 1 then
      DialogTitle := Format('Edit Attribute (%d Documents)', [Length(DocumentID)])
    else
      DialogTitle := 'Edit Attribute';
    frmDialogInput := TfrmDialogInput.Create(Self);
    try
      if not frmDialogInput.Execute(DialogTitle, 'Select the Attribute to Edit', AttributeList, SelectedIndex) then Exit;
    finally
      frmDialogInput.Free;
    end;
    AttributeName := AttributeList[SelectedIndex];
    FServiceDatabase.GetAttributeDetails(AttributeName, AttributeID, AttributeType);
    ColumnName := 'attribute_' + Copy(StringReplace(AttributeID, '-', '', [rfReplaceAll]), 1, 16);
    DocsWithAttribute := FServiceDatabase.CountDocumentsWithAttribute(DocumentID, ColumnName);
    UpdateMissing := True;
    ExistingValue := '';
    if Length(DocumentID) = 1 then
    begin
      if DocsWithAttribute = 0 then
      begin
        if MessageDlg('Attribute Missing', 'This document does not currently possess the "' + AttributeName + '" attribute. Do you wish to create it?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;
      end
      else
      begin
        qryCheck.Close;
        qryCheck.SQL.Text := 'SELECT json_extract(attributes, ''$.'' || :col) FROM document_attributes WHERE document_id = :did';
        qryCheck.Params.ParamByName('col').AsString := ColumnName;
        qryCheck.Params.ParamByName('did').AsString := DocumentID[0];
        qryCheck.Open;
        if not qryCheck.EOF and not qryCheck.Fields[0].IsNull then
          ExistingValue := qryCheck.Fields[0].AsString;
        qryCheck.Close;
      end;
    end
    else
    begin
      if DocsWithAttribute < Length(DocumentID) then
      begin
        MissingCount := Length(DocumentID) - DocsWithAttribute;
        if MissingCount = 1 then
          MissingMsg := '1 does not possess it'
        else
          MissingMsg := IntToStr(MissingCount) + ' do not possess it';
        Res := QuestionDlg('Attribute Missing', 
          Format('"%s" is currently applied to %d of the selected documents, but %s. Do you wish to create and apply the new value to the missing documents as well?', 
          [AttributeName, DocsWithAttribute, MissingMsg]), 
          mtConfirmation, [mrYes, Format('Update All %d', [Length(DocumentID)]), mrNo, Format('Only Update %d', [DocsWithAttribute]), mrCancel, 'Cancel'], 0);
        if Res = mrCancel then Exit;
        UpdateMissing := (Res = mrYes);
      end;
    end;
    if AttributeType = 'Categorical' then
      FServiceDatabase.GetCategoricalValue(AttributeID, CategoryOption);
    DisplayName := AttributeName;
    if UTF8Length(DisplayName) > 25 then
      DisplayName := UTF8Copy(DisplayName, 1, 25) + '...';
    frmDialogInput := TfrmDialogInput.Create(Self);
    try
      if not frmDialogInput.Execute(DialogTitle, DisplayName + ' · ' + AttributeType + ' Attribute', AttributeType, ExistingValue, CategoryOption, NewValue) then Exit;
    finally
      frmDialogInput.Free;
    end;
    if Length(DocumentID) = 1 then
    begin
      try
        qryCheck.Close;
        if AttributeType = 'Numeric' then
          qryCheck.SQL.Text := 'UPDATE document_attributes SET attributes = json_set(attributes, ''$.'' || :col, json(:val)) WHERE document_id = :did'
        else
          qryCheck.SQL.Text := 'UPDATE document_attributes SET attributes = json_set(attributes, ''$.'' || :col, :val) WHERE document_id = :did';
        qryCheck.Params.ParamByName('col').AsString := ColumnName;
        qryCheck.Params.ParamByName('val').AsString := Trim(NewValue);
        qryCheck.Params.ParamByName('did').AsString := DocumentID[0];
        qryCheck.ExecSQL;
        if trnMain.Active then trnMain.Commit;
        RefreshAttribute;
        if DocsWithAttribute = 0 then
          MessageDlg('Success', 'Successfully created and applied the attribute value.', mtInformation, [mbOK], 0)
        else
          MessageDlg('Success', 'Successfully updated the attribute value.', mtInformation, [mbOK], 0);
      except
        on E: Exception do MessageDlg('Database Error', 'Failed to update attribute: ' + E.Message, mtError, [mbOK], 0);
      end;
    end
    else
    begin
      Worker := TThreadBatchAttribute.Create(conMain.DatabaseName);
      try
        Worker.FAction := baaEdit;
        Worker.FDocumentID := Copy(DocumentID);
        Worker.FAttributeID := AttributeID;
        Worker.FValue := Trim(NewValue);
        Worker.FUpdateOnlyExisting := not UpdateMissing;
        Worker.Start;
        TfrmDialogProgress.Prepare('Modifying Attributes', 'Initialising...');
        frmDialogProgress.ShowModal;
        if trnMain.Active then trnMain.Commit;
        if Worker.Success then
        begin
          RefreshAttribute;
          MessageDlg('Success', Format('Successfully updated the attribute for %d %s.', [Worker.FAddedCount, TAppFormat.Pluralize(Worker.FAddedCount, 'document', 'documents')]), mtInformation, [mbOK], 0);
        end
        else
          MessageDlg('Error', 'Operation failed: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
      finally
        Worker.Free;
      end;
    end;
  finally
    AttributeList.Free;
    CategoryOption.Free;
  end;
end;

procedure TfrmAppBase.mniTreeDocumentAttributeDeleteClick(Sender: TObject);
var
  AttributeList: TStringList;
  AttributeName: String;
  DocumentID: TStringDynArray;
  SelectedIndex, DocsWithAttribute: Integer;
  AttributeID, AttributeType, ColumnName, DialogTitle, ConfirmMsg: String;
  Worker: TThreadBatchAttribute;
begin
  if vstDocument.SelectedCount = 0 then Exit;
  DocumentID := FControllerTreeDocument.GetSelectedID;
  if Length(DocumentID) = 0 then Exit;
  AttributeList := TStringList.Create;
  try
    FServiceDatabase.GetCommonAttributeName(DocumentID, AttributeList);
    if AttributeList.Count = 0 then
    begin
      if Length(DocumentID) = 1 then
        MessageDlg('No Attributes', 'This document does not possess any attributes to remove.', mtInformation, [mbOK], 0)
      else
        MessageDlg('No Shared Attributes', 'The selected documents do not possess any removable attributes.', mtInformation, [mbOK], 0);
      Exit;
    end;
    if Length(DocumentID) > 1 then
      DialogTitle := Format('Remove Attribute (%d Documents)', [Length(DocumentID)])
    else
      DialogTitle := 'Remove Attribute';
    frmDialogInput := TfrmDialogInput.Create(Self);
    try
      if not frmDialogInput.Execute(DialogTitle, 'Select the Attribute to Remove', AttributeList, SelectedIndex) then Exit;
    finally
      frmDialogInput.Free;
    end;
    AttributeName := AttributeList[SelectedIndex];
    FServiceDatabase.GetAttributeDetails(AttributeName, AttributeID, AttributeType);
    ColumnName := 'attribute_' + Copy(StringReplace(AttributeID, '-', '', [rfReplaceAll]), 1, 16);
    DocsWithAttribute := FServiceDatabase.CountDocumentsWithAttribute(DocumentID, ColumnName);
    if DocsWithAttribute = 0 then
    begin
      MessageDlg('No Attributes', 'None of the selected documents possess this attribute.', mtInformation, [mbOK], 0);
      Exit;
    end;
    if Length(DocumentID) = 1 then
      ConfirmMsg := 'Are you sure you want to remove the attribute "' + AttributeName + '" from this document?'
    else
    begin
      if DocsWithAttribute = 1 then
        ConfirmMsg := Format('Are you sure you want to remove the attribute "%s" from the 1 applicable document?', [AttributeName])
      else
        ConfirmMsg := Format('Are you sure you want to remove the attribute "%s" from the %d applicable documents?', [AttributeName, DocsWithAttribute]);
    end;
    if MessageDlg('Confirm Removal', ConfirmMsg, mtWarning, [mbYes, mbNo], 0) = mrNo then Exit;
    if Length(DocumentID) = 1 then
    begin
      try
        qryCheck.Close;
        qryCheck.SQL.Text := 'UPDATE document_attributes SET attributes = json_remove(attributes, ''$.'' || :col) WHERE document_id = :did';
        qryCheck.Params.ParamByName('col').AsString := ColumnName;
        qryCheck.Params.ParamByName('did').AsString := DocumentID[0];
        qryCheck.ExecSQL;
        if trnMain.Active then trnMain.Commit;
        RefreshAttribute;
        MessageDlg('Success', 'Successfully removed the attribute from the document.', mtInformation, [mbOK], 0);
      except
        on E: Exception do MessageDlg('Database Error', 'Failed to remove attribute: ' + E.Message, mtError, [mbOK], 0);
      end;
    end
    else
    begin
      Worker := TThreadBatchAttribute.Create(conMain.DatabaseName);
      try
        Worker.FAction := baaDelete;
        Worker.FDocumentID := Copy(DocumentID);
        Worker.FAttributeID := AttributeID;
        Worker.Start;
        TfrmDialogProgress.Prepare('Deleting Attributes', 'Initialising...');
        frmDialogProgress.ShowModal;
        if trnMain.Active then trnMain.Commit;
        if Worker.Success then
        begin
          RefreshAttribute;
          MessageDlg('Success', Format('Successfully removed the attribute from %d %s.', [Worker.FAddedCount, TAppFormat.Pluralize(Worker.FAddedCount, 'document', 'documents')]), mtInformation, [mbOK], 0);
        end
        else
          MessageDlg('Error', 'Operation failed: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
      finally
        Worker.Free;
      end;
    end;
  finally
    AttributeList.Free;
  end;
end;

procedure TfrmAppBase.AttributeTypeChange(Sender: TObject);
var
  rg: TRadioGroup;
  Dlg: TForm;
begin
  rg := Sender as TRadioGroup;
  Dlg := rg.Parent as TForm;
  TControl(Dlg.FindComponent('cbExisting')).Enabled := (rg.ItemIndex = 0);
  TControl(Dlg.FindComponent('edtNew')).Enabled := (rg.ItemIndex = 1);
  if rg.ItemIndex = 0 then
    TWinControl(Dlg.FindComponent('cbExisting')).SetFocus
  else
    TWinControl(Dlg.FindComponent('edtNew')).SetFocus;
end;

procedure TfrmAppBase.btnDocumentEditEnterClick(Sender: TObject);
begin
  if FCurrentDocumentID = '' then Exit;
  if not FRenderDocument.EngineText.IsEditing then
  begin
    FRenderDocument.EngineText.SetEditing(True);
    btnDocumentEditEnter.ImageIndex := 10;
    btnDocumentEditEnter.Hint := 'Save Changes';
    btnDocumentEditExit.Visible := True;
    btnDocumentEditExit.Hint := 'Exit Edit Mode';
    lblEditStatus.Caption := 'No changes to save';
    lblEditStatus.Font.Color := clGray;
    lblEditStatus.Visible := True;
    FActiveDocumentOriginalText := FRenderDocument.EngineText.GetDocumentText;
    FRenderDocument.Invalidate;
    MessageDlg('Editing Mode', 'Click on the document text to place the caret at the point where edits are to be made. The codings and segment memos will synchronise with the changes.', mtInformation, [mbOK], 0);
  end
  else
  begin
    RenderDocumentSaveRequest(Self);
  end;
end;

procedure TfrmAppBase.btnDocumentEditExitClick(Sender: TObject);
begin
  ForceExitEditMode;
end;

function TfrmAppBase.ExecuteLiveEditSave: Boolean;
var
  Worker: TThreadLiveEditSave;
begin
  Result := False;
  Worker := TThreadLiveEditSave.Create(conMain.DatabaseName);
  try
    Worker.FDocumentID := FCurrentDocumentID;
    Worker.FNewText := FRenderDocument.EngineText.GetDocumentText;
    Worker.FCodings := FRenderDocument.EngineText.GetCodingShifts;
    Worker.FMemos := FRenderDocument.EngineText.GetMemoShifts;
    Worker.Start;
    TfrmDialogProgress.Prepare('Saving Document', 'Saving changes...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      if trnMain.Active then trnMain.Commit; 
      FActiveDocumentOriginalText := FRenderDocument.EngineText.GetDocumentText;
      UpdateDashboardStatistic;
      Result := True;
    end
    else
      MessageDlg('Save Error', 'Failed to save document: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

function TfrmAppBase.CheckUnsavedChangesBeforeAction(const ActionContext: String = ''): Boolean;
var
  Res, SavedScrollY: Integer;
  PromptMsg: String;
begin
  Result := True;
  if Assigned(FRenderDocument) and FRenderDocument.EngineText.IsEditing and 
     (FRenderDocument.EngineText.GetDocumentText <> FActiveDocumentOriginalText) then
  begin
    if ActionContext <> '' then
      PromptMsg := 'There are unsaved changes in the document. Do you wish to save or discard them ' + ActionContext + '?'
    else
      PromptMsg := 'There are unsaved changes in the document. Do you wish to save or discard them?';
    Res := QuestionDlg('Unsaved Changes', PromptMsg, mtConfirmation, [mrYes, 'Save', mrNo, 'Discard', mrCancel, 'Cancel'], 0);
    case Res of
      mrYes: 
        begin
          Result := ExecuteLiveEditSave;
          if Result then 
            RefreshCodeTree;
        end;
      mrNo: 
        begin
          SavedScrollY := FRenderDocument.ScrollY;
          FRenderDocument.SetText(FActiveDocumentOriginalText);
          LoadCodingForCurrentDocument;
          LoadMemoForCurrentDocument;
          FRenderDocument.ScrollY := SavedScrollY;
          FRenderDocument.Invalidate;
          Result := True;
        end;
      mrCancel:
        Result := False;
    end;
  end;
end;

function TfrmAppBase.ForceExitEditMode(const ActionContext: String = ''): Boolean;
var
  SavedScrollY: Integer;
begin
  Result := True;
  if not Assigned(FRenderDocument) or not FRenderDocument.EngineText.IsEditing then Exit;
  SavedScrollY := FRenderDocument.ScrollY;
  if not CheckUnsavedChangesBeforeAction(ActionContext) then Exit(False);
  FRenderDocument.EngineText.SetEditing(False);
  btnDocumentEditEnter.ImageIndex := 9;
  btnDocumentEditEnter.Hint := 'Enter Edit Mode';
  btnDocumentEditExit.Visible := False;
  if Assigned(lblEditStatus) then lblEditStatus.Visible := False;
  FRenderDocument.ScrollY := SavedScrollY;
  FRenderDocument.Invalidate;
end;

procedure TfrmAppBase.RenderDocumentTextChanged(Sender: TObject);
begin
  if not Assigned(lblEditStatus) then Exit;
  if FRenderDocument.EngineText.GetDocumentText <> FActiveDocumentOriginalText then
  begin
    lblEditStatus.Caption := 'Unsaved changes';
    lblEditStatus.Font.Color := RGBToColor(200, 100, 0);
  end
  else
  begin
    lblEditStatus.Caption := 'No changes to save';
    lblEditStatus.Font.Color := clGray;
  end;
end;

procedure TfrmAppBase.RenderDocumentSaveRequest(Sender: TObject);
var
  SavedScrollY: Integer;
begin
  if not FRenderDocument.EngineText.IsEditing then Exit;
  if FRenderDocument.EngineText.GetDocumentText = FActiveDocumentOriginalText then
  begin
    lblEditStatus.Caption := 'Changes saved';
    lblEditStatus.Font.Color := RGBToColor(0, 128, 0);
    Exit;
  end;
  lblEditStatus.Caption := 'Saving...';
  lblEditStatus.Font.Color := clGray;
  Application.ProcessMessages;
  if ExecuteLiveEditSave then
  begin
    SavedScrollY := FRenderDocument.ScrollY;
    LoadCodingForCurrentDocument;
    LoadMemoForCurrentDocument;
    FRenderDocument.ScrollY := SavedScrollY;
    FRenderDocument.Invalidate;
    lblEditStatus.Caption := 'Changes saved';
    lblEditStatus.Font.Color := RGBToColor(0, 128, 0);
  end
  else
  begin
    lblEditStatus.Caption := 'Save failed';
    lblEditStatus.Font.Color := clRed;
  end;
end;

procedure TfrmAppBase.RenderDocumentZoomPersist(Sender: TObject; ZoomLevel: Integer);
begin
  if Assigned(FServiceDatabase) and conMain.Connected then
    FServiceDatabase.SaveUserPreference('DocumentZoom', IntToStr(ZoomLevel));
end;

procedure TfrmAppBase.RenderDocumentAnchorHover(Sender: TObject; const Cluster: TMapTickCluster);
var
  i: Integer;
begin
  FActiveCodeList.Clear;
  for i := 0 to High(Cluster.Items) do
  begin
    FActiveCodeList.AddObject(Cluster.Items[i].Name, TObject(PtrInt(Cluster.Items[i].Color)));
  end;
  pbxLegendCodeName.Invalidate;
end;

procedure TfrmAppBase.RenderDocumentBracketHover(Sender: TObject; const CodeID: String; CodingIndex: Integer);
var
  CodeName: String;
  CodeColor: TColor;
begin
  if CodeID = '' then
  begin
    if FActiveCodeList.Count > 0 then
    begin
      FActiveCodeList.Clear;
      pbxLegendCodeName.Invalidate;
    end;
    Exit;
  end;
  qryCheck.Close;
  qryCheck.SQL.Text := 'SELECT c.name, c.color ' +
                       'FROM codings co ' +
                       'JOIN codes c ON co.code_id = c.id ' +
                       'WHERE co.id = :id';
  qryCheck.Params.ParamByName('id').AsString := CodeID;
  try
    qryCheck.Open;
    if not qryCheck.EOF then
    begin
      CodeName := qryCheck.FieldByName('name').AsString;
      CodeColor := TColor(qryCheck.FieldByName('color').AsInteger);
      FActiveCodeList.Clear;
      FActiveCodeList.AddObject(CodeName, TObject(PtrInt(CodeColor)));
      pbxLegendCodeName.Invalidate;
    end;
  finally
    qryCheck.Close;
  end;
end;

procedure TfrmAppBase.RenderDocumentTextContext(Sender: TObject; const BracketCodingID: String; ClickedCharacterPosition: Integer; P: TPoint);
var
  Item, SubItem, SeparatorItem: TMenuItem;
  PartArray: TStringArray;
  StartCharacter, LengthCharacter, i: Integer;
  Snippet, CodeName, DisplayName, TargetString: String;
  MemoItemList, CodingItemList, RecodeItemList: TList;
  MemoExists, HasManualSelection: Boolean;
begin
  pmnText.Items.Clear;
  FBracketMenuMap.Clear;
  HasManualSelection := FRenderDocument.HasSelection and not FRenderDocument.IsBracketSelection;
  if FRenderDocument.EngineText.IsEditing then
  begin
    if HasManualSelection then
    begin
      Item := TMenuItem.Create(pmnText);
      Item.Caption := 'Cut';
      Item.ImageIndex := 50;
      Item.OnClick := @ContextCutClick;
      pmnText.Items.Add(Item);
      Item := TMenuItem.Create(pmnText);
      Item.Caption := 'Copy';
      Item.ImageIndex := 48;
      Item.OnClick := @CopyTextClick;
      pmnText.Items.Add(Item);
    end;
    Item := TMenuItem.Create(pmnText);
    Item.Caption := 'Paste';
    Item.ImageIndex := 49;
    Item.OnClick := @ContextPasteClick;
    pmnText.Items.Add(Item);
    if pmnText.Items.Count > 0 then pmnText.Popup(P.X, P.Y);
    Exit;
  end;
  if BracketCodingID <> '' then
  begin
    qryUtil.Close;
    qryUtil.SQL.Text := 'SELECT c.name, co.start_position, co.length FROM codings co JOIN codes c ON co.code_id = c.id WHERE co.id = :id';
    qryUtil.Params.ParamByName('id').AsString := BracketCodingID;
    qryUtil.Open;
    if not qryUtil.EOF then
    begin
      CodeName := qryUtil.FieldByName('name').AsString;
      StartCharacter := qryUtil.FieldByName('start_position').AsInteger;
      LengthCharacter := qryUtil.FieldByName('length').AsInteger;
    end
    else
    begin
      CodeName := 'Unknown';
      StartCharacter := 0;
      LengthCharacter := 0;
    end;
    qryUtil.Close;
    if UTF8Length(CodeName) > 25 then
      DisplayName := UTF8Copy(CodeName, 1, 25) + '...'
    else
      DisplayName := CodeName;
    if HasManualSelection then
    begin
      Item := TMenuItem.Create(pmnText);
      Item.Caption := 'Re-code: ''' + DisplayName + ''' · Position: ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter) + ' to Current Selection';
      Item.ImageIndex := 51;
      Item.OnClick := @BracketRecodeSegmentClick;
      FBracketMenuMap.Add(Item, BracketCodingID);
      pmnText.Items.Add(Item);
      SeparatorItem := TMenuItem.Create(pmnText);
      SeparatorItem.Caption := '-';
      pmnText.Items.Add(SeparatorItem);
    end;
    Item := TMenuItem.Create(pmnText);
    Item.Caption := 'Remove Coding: ''' + DisplayName + ''' · Position: ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter);
    Item.ImageIndex := 38;
    Item.OnClick := @BracketRemoveCodingClick;
    FBracketMenuMap.Add(Item, BracketCodingID);
    pmnText.Items.Add(Item);
    Item := TMenuItem.Create(pmnText);
    Item.Caption := 'Copy Coded Segment';
    Item.ImageIndex := 48;
    Item.OnClick := @BracketCopySegmentClick;
    FBracketMenuMap.Add(Item, BracketCodingID);
    pmnText.Items.Add(Item);
    TargetString := FCurrentDocumentID + ':' + IntToStr(StartCharacter) + ':' + IntToStr(LengthCharacter);
    qryCheck.Close;
    qryCheck.SQL.Text := 'SELECT 1 FROM memos WHERE memo_type = ''Segment'' AND reference = :ref LIMIT 1';
    qryCheck.Params.ParamByName('ref').AsString := TargetString;
    qryCheck.Open;
    MemoExists := not qryCheck.EOF;
    qryCheck.Close;
    Item := TMenuItem.Create(pmnText);
    if MemoExists then
    begin
      Item.Caption := 'View/Modify Memo for Coded Segment · Position: ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter);
      Item.ImageIndex := 8;
    end
    else
    begin
      Item.Caption := 'Create Memo for Coded Segment · Position: ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter);
      Item.ImageIndex := 36;
    end;
    Item.OnClick := @AddSegmentMemoClick;
    FBracketMenuMap.Add(Item, TargetString);
    pmnText.Items.Add(Item);
    pmnText.Popup(P.X, P.Y);
    Exit;
  end;
  if ClickedCharacterPosition >= 0 then
  begin
    MemoItemList := TList.Create;
    CodingItemList := TList.Create;
    RecodeItemList := TList.Create;
    try
      qryUtil.Close;
      qryUtil.SQL.Text := 'SELECT reference FROM memos WHERE memo_type = ''Segment'' AND reference LIKE :t';
      qryUtil.Params.ParamByName('t').AsString := FCurrentDocumentID + ':%';
      qryUtil.Open;
      while not qryUtil.EOF do
      begin
        PartArray := qryUtil.FieldByName('reference').AsString.Split([':']);
        if Length(PartArray) = 3 then
        begin
          StartCharacter := StrToIntDef(PartArray[1], 0);
          LengthCharacter := StrToIntDef(PartArray[2], 0);
          if (ClickedCharacterPosition >= StartCharacter) and (ClickedCharacterPosition < StartCharacter + LengthCharacter) then
          begin
            Snippet := FRenderDocument.GetTextSlice(StartCharacter, Min(LengthCharacter, 30));
            Snippet := StringReplace(Snippet, #10, ' ', [rfReplaceAll]);
            Snippet := StringReplace(Snippet, #13, '', [rfReplaceAll]);
            if LengthCharacter > 30 then Snippet := Snippet + '...';
            SubItem := TMenuItem.Create(pmnText);
            SubItem.Caption := 'View/Modify Memo: ''' + Snippet + ''' · Position: ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter);
            SubItem.ImageIndex := 8;
            SubItem.OnClick := @EditSegmentMemoClick;
            FBracketMenuMap.Add(SubItem, qryUtil.FieldByName('reference').AsString);
            MemoItemList.Add(SubItem);
          end;
        end;
        qryUtil.Next;
      end;
      qryUtil.Close;
      qryUtil.SQL.Text := 'SELECT co.id, c.name, co.start_position, co.length FROM codings co JOIN codes c ON co.code_id = c.id WHERE co.document_id = :d AND :p >= co.start_position AND :p < (co.start_position + co.length)';
      qryUtil.Params.ParamByName('d').AsString := FCurrentDocumentID;
      qryUtil.Params.ParamByName('p').AsInteger := ClickedCharacterPosition;
      qryUtil.Open;
      while not qryUtil.EOF do
      begin
        CodeName := qryUtil.FieldByName('name').AsString;
        StartCharacter := qryUtil.FieldByName('start_position').AsInteger;
        LengthCharacter := qryUtil.FieldByName('length').AsInteger;
        TargetString := qryUtil.FieldByName('id').AsString;
        if UTF8Length(CodeName) > 25 then
          DisplayName := UTF8Copy(CodeName, 1, 25) + '...'
        else
          DisplayName := CodeName;
        SubItem := TMenuItem.Create(pmnText);
        SubItem.Caption := 'Remove Coding: ''' + DisplayName + ''' · Position: ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter);
        SubItem.ImageIndex := 38;
        SubItem.OnClick := @BracketRemoveCodingClick;
        FBracketMenuMap.Add(SubItem, TargetString);
        CodingItemList.Add(SubItem);
        if HasManualSelection then
        begin
          SubItem := TMenuItem.Create(pmnText);
          SubItem.Caption := 'Re-code: ''' + DisplayName + ''' · Position: ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter) + ' to Current Selection';
          SubItem.ImageIndex := 51;
          SubItem.OnClick := @BracketRecodeSegmentClick;
          FBracketMenuMap.Add(SubItem, TargetString);
          RecodeItemList.Add(SubItem);
        end;
        qryUtil.Next;
      end;
      qryUtil.Close;
      if HasManualSelection then
      begin
        if RecodeItemList.Count = 1 then
          pmnText.Items.Add(TMenuItem(RecodeItemList[0]))
        else if RecodeItemList.Count > 1 then
        begin
          Item := TMenuItem.Create(pmnText);
          Item.Caption := 'Re-code to Current Selection';
          Item.ImageIndex := 51;
          for i := 0 to RecodeItemList.Count - 1 do
          begin
            TMenuItem(RecodeItemList[i]).ImageIndex := -1;
            Item.Add(TMenuItem(RecodeItemList[i]));
          end;
          pmnText.Items.Add(Item);
        end;
        if RecodeItemList.Count > 0 then
        begin
          SeparatorItem := TMenuItem.Create(pmnText);
          SeparatorItem.Caption := '-';
          pmnText.Items.Add(SeparatorItem);
        end;
        Item := TMenuItem.Create(pmnText);
        Item.Caption := 'Copy Selection';
        Item.ImageIndex := 48;
        Item.OnClick := @CopyTextClick;
        pmnText.Items.Add(Item);
        Item := TMenuItem.Create(pmnText);
        Item.Caption := 'Create Memo for Selection';
        Item.ImageIndex := 36;
        Item.OnClick := @AddSegmentMemoClick;
        pmnText.Items.Add(Item);
        if (MemoItemList.Count > 0) or (CodingItemList.Count > 0) then
        begin
          SeparatorItem := TMenuItem.Create(pmnText);
          SeparatorItem.Caption := '-';
          pmnText.Items.Add(SeparatorItem);
        end;
      end;
      if MemoItemList.Count = 1 then
        pmnText.Items.Add(TMenuItem(MemoItemList[0]))
      else if MemoItemList.Count > 1 then
      begin
        Item := TMenuItem.Create(pmnText);
        Item.Caption := 'View/Modify Memo';
        Item.ImageIndex := 8;
        for i := 0 to MemoItemList.Count - 1 do
        begin
          TMenuItem(MemoItemList[i]).ImageIndex := -1;
          Item.Add(TMenuItem(MemoItemList[i]));
        end;
        pmnText.Items.Add(Item);
      end;
      if (MemoItemList.Count > 0) and (CodingItemList.Count > 0) then
      begin
        SeparatorItem := TMenuItem.Create(pmnText);
        SeparatorItem.Caption := '-';
        pmnText.Items.Add(SeparatorItem);
      end;
      if CodingItemList.Count = 1 then
        pmnText.Items.Add(TMenuItem(CodingItemList[0]))
      else if CodingItemList.Count > 1 then
      begin
        Item := TMenuItem.Create(pmnText);
        Item.Caption := 'Remove Coding';
        Item.ImageIndex := 38;
        for i := 0 to CodingItemList.Count - 1 do
        begin
          TMenuItem(CodingItemList[i]).ImageIndex := -1;
          Item.Add(TMenuItem(CodingItemList[i]));
        end;
        pmnText.Items.Add(Item);
      end;
    finally
      MemoItemList.Free;
      CodingItemList.Free;
      RecodeItemList.Free;
    end;
    if pmnText.Items.Count > 0 then pmnText.Popup(P.X, P.Y);
    Exit;
  end;
  if HasManualSelection then
  begin
    Item := TMenuItem.Create(pmnText);
    Item.Caption := 'Copy Selection';
    Item.ImageIndex := 48;
    Item.OnClick := @CopyTextClick;
    pmnText.Items.Add(Item);
    Item := TMenuItem.Create(pmnText);
    Item.Caption := 'Create Memo for Selection';
    Item.ImageIndex := 36;
    Item.OnClick := @AddSegmentMemoClick;
    pmnText.Items.Add(Item);
    pmnText.Popup(P.X, P.Y);
  end;
end;

procedure TfrmAppBase.pmnTextPopup(Sender: TObject);
begin
  { Handled by RenderDocumentTextContext }
end;

procedure TfrmAppBase.ContextCutClick(Sender: TObject);
begin
  if Assigned(FRenderDocument) and FRenderDocument.EngineText.IsEditing and FRenderDocument.HasSelection and not FRenderDocument.IsBracketSelection then
  begin
    Clipbrd.Clipboard.AsText := FRenderDocument.GetSelectedText;
    FRenderDocument.EngineText.ReplaceRange(FRenderDocument.EngineText.SelStartByte, FRenderDocument.EngineText.SelEndByte, '');
    FRenderDocument.UpdateScrollbar;
    FRenderDocument.ScrollToChar(FRenderDocument.EngineText.ByteToChar(FRenderDocument.EngineText.GetAbsoluteCaret));
    FRenderDocument.Invalidate;
  end;
end;

procedure TfrmAppBase.ContextPasteClick(Sender: TObject);
begin
  if Assigned(FRenderDocument) and FRenderDocument.EngineText.IsEditing and (Clipbrd.Clipboard.AsText <> '') then
  begin
    if FRenderDocument.HasSelection and not FRenderDocument.IsBracketSelection then
      FRenderDocument.EngineText.ReplaceRange(FRenderDocument.EngineText.SelStartByte, FRenderDocument.EngineText.SelEndByte, Clipbrd.Clipboard.AsText)
    else
      FRenderDocument.EngineText.ReplaceRange(FRenderDocument.EngineText.GetAbsoluteCaret, FRenderDocument.EngineText.GetAbsoluteCaret, Clipbrd.Clipboard.AsText);
    FRenderDocument.UpdateScrollbar;
    FRenderDocument.ScrollToChar(FRenderDocument.EngineText.ByteToChar(FRenderDocument.EngineText.GetAbsoluteCaret));
    FRenderDocument.Invalidate;
  end;
end;

procedure TfrmAppBase.CopyTextClick(Sender: TObject);
begin
  if Assigned(FRenderDocument) and FRenderDocument.HasSelection then
    Clipbrd.Clipboard.AsText := FRenderDocument.GetSelectedText;
end;

procedure TfrmAppBase.ApplyCoding(const CodeID: String; CodeColor: TColor);
var
  StartCharacter, LengthCharacter: Integer;
  ErrorMessage: String;
begin
  if not Assigned(FRenderDocument) or not FRenderDocument.HasSelection then Exit;
  StartCharacter := FRenderDocument.SelectionStartCharacter;
  LengthCharacter := FRenderDocument.SelectionLength;
  if LengthCharacter <= 0 then Exit;
  if not FServiceDatabase.AddCoding(FCurrentDocumentID, CodeID, StartCharacter, LengthCharacter, ErrorMessage) then
  begin
    if ErrorMessage <> '' then MessageDlg('Database Error', 'Failed to apply coding: ' + ErrorMessage, mtError, [mbOK], 0)
    else MessageDlg('Duplicate Coding', 'This code is already applied to a segment which overlaps with the current selection. Verify and adjust/re-code segment boundaries.', mtInformation, [mbOK], 0);
    Exit;
  end;
  LoadCodingForCurrentDocument;
  RefreshCodeTree;
  RefreshDocumentList;
  FRenderDocument.ClearSelection;
end;

procedure TfrmAppBase.BracketRemoveCodingClick(Sender: TObject);
var
  CodingID: String;
begin
  if not (Sender is TMenuItem) then Exit;
  if not FBracketMenuMap.TryGetValue(Sender as TMenuItem, CodingID) then Exit;
  if MessageDlg('Confirm', 'Remove this coding?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;
  FServiceDatabase.DeleteCoding(CodingID);
  RefreshCodeTree;
  LoadCodingForCurrentDocument;
  RefreshDocumentList;
  FRenderDocument.ClearSelection;
end;

procedure TfrmAppBase.BracketRecodeSegmentClick(Sender: TObject);
var
  CodingID, TargetCodeID: String;
  StartCharacter, LengthCharacter, EndCharacter: Integer;
begin
  if not (Sender is TMenuItem) then Exit;
  if not FBracketMenuMap.TryGetValue(Sender as TMenuItem, CodingID) then Exit;
  if not Assigned(FRenderDocument) or not FRenderDocument.HasSelection or FRenderDocument.IsBracketSelection then Exit;
  StartCharacter := FRenderDocument.SelectionStartCharacter;
  LengthCharacter := FRenderDocument.SelectionLength;
  if LengthCharacter <= 0 then Exit;
  EndCharacter := StartCharacter + LengthCharacter;
  qryCheck.Close;
  qryCheck.SQL.Text := 'SELECT code_id FROM codings WHERE id = :id';
  qryCheck.Params.ParamByName('id').AsString := CodingID;
  qryCheck.Open;
  TargetCodeID := qryCheck.FieldByName('code_id').AsString;
  qryCheck.Close;
  qryCheck.SQL.Text := 'SELECT id FROM codings WHERE document_id = :d AND code_id = :c AND NOT (:e <= start_position OR :s >= (start_position + length)) AND id <> :id';
  qryCheck.Params.ParamByName('d').AsString := FCurrentDocumentID;
  qryCheck.Params.ParamByName('c').AsString := TargetCodeID;
  qryCheck.Params.ParamByName('s').AsInteger := StartCharacter;
  qryCheck.Params.ParamByName('e').AsInteger := EndCharacter;
  qryCheck.Params.ParamByName('id').AsString := CodingID;
  qryCheck.Open;
  if not qryCheck.EOF then
  begin
    MessageDlg('Duplicate Coding', 'This code is already applied to a segment which overlaps with the current selection. Verify and adjust/re-code segment boundaries.', mtInformation, [mbOK], 0);
    qryCheck.Close;
    Exit;
  end;
  qryCheck.Close;
  try
    ExecuteSQLSafe('UPDATE codings SET start_position = ' + IntToStr(StartCharacter) + ', length = ' + IntToStr(LengthCharacter) + ' WHERE id = ' + QuotedStr(CodingID));
    LoadCodingForCurrentDocument;
    RefreshCodeTree;
    RefreshDocumentList;
    FRenderDocument.ClearSelection;
    FRenderDocument.ScrollToChar(StartCharacter);
  except
    on E: Exception do
      MessageDlg('Database Error', 'Failed to re-code: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmAppBase.BracketCopySegmentClick(Sender: TObject);
var
  CodingID: String;
  StartCharacter, LengthCharacter: Integer;
begin
  if not (Sender is TMenuItem) then Exit;
  if not FBracketMenuMap.TryGetValue(Sender as TMenuItem, CodingID) then Exit;
  qryUtil.Close;
  qryUtil.SQL.Text := 'SELECT start_position, length FROM codings WHERE id = :id';
  qryUtil.Params.ParamByName('id').AsString := CodingID;
  qryUtil.Open;
  if not qryUtil.EOF then
  begin
    StartCharacter := qryUtil.FieldByName('start_position').AsInteger;
    LengthCharacter := qryUtil.FieldByName('length').AsInteger;
    Clipbrd.Clipboard.AsText := FRenderDocument.GetTextSlice(StartCharacter, LengthCharacter);
  end;
  qryUtil.Close;
end;

procedure TfrmAppBase.btnReadSearchNextClick(Sender: TObject);
var
  CurrentMatch, TotalMatch: Integer;
begin
  if FCurrentDocumentID = '' then Exit;
  FRenderDocument.EngineText.NavigateMatch(1);
  if FRenderDocument.EngineText.GetSearchStatus(CurrentMatch, TotalMatch) then
    lblReadSearchCount.Caption := IntToStr(CurrentMatch) + ' of ' + IntToStr(TotalMatch);
  FRenderDocument.ScrollToActiveSearchMatch;
end;

procedure TfrmAppBase.btnReadSearchPreviousClick(Sender: TObject);
var
  CurrentMatch, TotalMatch: Integer;
begin
  if FCurrentDocumentID = '' then Exit;
  FRenderDocument.EngineText.NavigateMatch(-1);
  if FRenderDocument.EngineText.GetSearchStatus(CurrentMatch, TotalMatch) then
    lblReadSearchCount.Caption := IntToStr(CurrentMatch) + ' of ' + IntToStr(TotalMatch);
  FRenderDocument.ScrollToActiveSearchMatch;
end;

procedure TfrmAppBase.edtReadSearchChange(Sender: TObject);
var
  CurrentMatch, TotalMatch: Integer;
  HasQuery: Boolean;
begin
  if FCurrentDocumentID = '' then Exit;
  HasQuery := Trim(edtReadSearch.Text) <> '';
  btnReadSearchPrevious.Visible := HasQuery;
  btnReadSearchNext.Visible := HasQuery;
  lblReadSearchCount.Visible := HasQuery;
  FRenderDocument.EngineText.ExecuteSearch(edtReadSearch.Text);
  if HasQuery then
  begin
    if FRenderDocument.EngineText.GetSearchStatus(CurrentMatch, TotalMatch) then
    begin
      lblReadSearchCount.Caption := IntToStr(CurrentMatch) + ' of ' + IntToStr(TotalMatch);
      FRenderDocument.ScrollToActiveSearchMatch;
    end
    else
      lblReadSearchCount.Caption := '0 of 0';
  end
  else
    lblReadSearchCount.Caption := '';
  FRenderDocument.Invalidate;
end;

procedure TfrmAppBase.AddSegmentMemoClick(Sender: TObject);
var
  StartCharacter, LengthCharacter: Integer;
  TargetString, DocumentTitle: String;
  TargetMenu: TMenuItem;
  PartArray: TStringArray;
begin
  if not (Sender is TMenuItem) then Exit;
  TargetMenu := Sender as TMenuItem;
  if FBracketMenuMap.TryGetValue(TargetMenu, TargetString) then
  begin
    PartArray := TargetString.Split([':']);
    if Length(PartArray) = 3 then
    begin
      StartCharacter := StrToIntDef(PartArray[1], 0);
      LengthCharacter := StrToIntDef(PartArray[2], 0);
      qryCheck.Close;
      qryCheck.SQL.Text := 'SELECT title FROM documents WHERE id = :id';
      qryCheck.Params.ParamByName('id').AsString := PartArray[0];
      qryCheck.Open;
      DocumentTitle := qryCheck.FieldByName('title').AsString;
      qryCheck.Close;
      TServiceMemo.Execute(conMain, 'Segment', TargetString, DocumentTitle + ' · ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter));
      LoadMemoForCurrentDocument;
      UpdateDashboardStatistic;
      FRenderDocument.ClearSelection;
      FRenderDocument.Invalidate;
    end;
    Exit;
  end;
  if (FCurrentDocumentID = '') or not FRenderDocument.HasSelection then Exit;
  StartCharacter := FRenderDocument.SelectionStartCharacter;
  LengthCharacter := FRenderDocument.SelectionLength;
  if LengthCharacter <= 0 then Exit;
  qryCheck.Close;
  qryCheck.SQL.Text := 'SELECT title FROM documents WHERE id = :id';
  qryCheck.Params.ParamByName('id').AsString := FCurrentDocumentID;
  qryCheck.Open;
  DocumentTitle := qryCheck.FieldByName('title').AsString;
  qryCheck.Close;
  TargetString := FCurrentDocumentID + ':' + IntToStr(StartCharacter) + ':' + IntToStr(LengthCharacter);
  TServiceMemo.Execute(conMain, 'Segment', TargetString, DocumentTitle + ' · ' + IntToStr(StartCharacter) + '–' + IntToStr(StartCharacter + LengthCharacter));
  LoadMemoForCurrentDocument;
  UpdateDashboardStatistic;
  FRenderDocument.ClearSelection;
  FRenderDocument.Invalidate;
end;

procedure TfrmAppBase.EditSegmentMemoClick(Sender: TObject);
var
  TargetString: String;
begin
  if not (Sender is TMenuItem) then Exit;
  if FBracketMenuMap.TryGetValue(Sender as TMenuItem, TargetString) then
  begin
    TServiceMemo.Execute(conMain, 'Segment', TargetString, '');
    LoadMemoForCurrentDocument;
    UpdateDashboardStatistic;
    FRenderDocument.Invalidate;
  end;
end;

procedure TfrmAppBase.RefreshCodeTree;
begin
  FControllerTreeCode.RefreshTree(Trim(edtCodeSearch.Text));
  UpdateDashboardStatistic;
  UpdateCodeSystemMenu;
end;

procedure TfrmAppBase.UpdateCodeSortUI;
var
  IsAnalytical: Boolean;
begin
  if not Assigned(FControllerTreeCode) then Exit;
  IsAnalytical := FControllerTreeCode.SortField <> 'sort_order';
  if not IsAnalytical then
    btnCodeSort.Hint := 'Sort Codes'
  else
    btnCodeSort.Hint := 'Sorted by: ' + FControllerTreeCode.SortDescription;
  btnCodeAdd.Enabled := not IsAnalytical;
end;

procedure TfrmAppBase.UpdateCodeSystemMenu;
var
  CodeCount: Integer;
begin
  if not conMain.Connected then
  begin
    mniCodeSystemImport.Enabled := False;
    mniCodeSystemExport.Enabled := False;
    mniCodebookExport.Enabled := False;
    Exit;
  end;
  qryMain.Close;
  qryMain.SQL.Text := 'SELECT COUNT(*) FROM codes';
  qryMain.Open;
  CodeCount := qryMain.Fields[0].AsInteger;
  qryMain.Close;
  mniCodeSystemImport.Enabled := (CodeCount = 0);
  mniCodeSystemExport.Enabled := (CodeCount > 0);
  mniCodebookExport.Enabled := (CodeCount > 0);
end;

procedure TfrmAppBase.pbxLegendCodeNamePaint(Sender: TObject);
var
  i, j, CharacterCount: Integer;
  CodeWordList: TStringList;
  CurrentWord, DisplayText, Chunk: String;
  DrawRectangle, ClearRectangle: TRect;
  TextStyle: TTextStyle;
  CurrentX, CurrentY, LastValidY: Integer;
  SpaceWidth, WordWidth, MaximumWidth: Integer;
  LineHeight: Integer;
  ItemColor: TColor;
  IsTruncated: Boolean;
begin
  pbxLegendCodeName.Canvas.Brush.Color := clWhite;
  pbxLegendCodeName.Canvas.FillRect(pbxLegendCodeName.ClientRect);
  DrawRectangle := pbxLegendCodeName.ClientRect;
  InflateRect(DrawRectangle, -8, -8);
  MaximumWidth := DrawRectangle.Right - DrawRectangle.Left;
  if FActiveCodeList.Count = 0 then
  begin
    pbxLegendCodeName.Canvas.Font.Color := clSilver;
    pbxLegendCodeName.Canvas.Font.Style := [];
    DisplayText := 'Hover over the in-document coding brackets, the action anchor ticks, or the code tree items to view legend.';
    TextStyle := pbxLegendCodeName.Canvas.TextStyle;
    TextStyle.Wordbreak := True;
    TextStyle.SingleLine := False;
    TextStyle.Alignment := taLeftJustify;    
    pbxLegendCodeName.Canvas.TextRect(DrawRectangle, DrawRectangle.Left, DrawRectangle.Top, DisplayText, TextStyle);
    Exit;
  end;
  CurrentX := DrawRectangle.Left;
  CurrentY := DrawRectangle.Top;
  LastValidY := CurrentY;
  SpaceWidth := pbxLegendCodeName.Canvas.TextWidth(' ');
  LineHeight := pbxLegendCodeName.Canvas.TextHeight('Wg') + 4;
  CodeWordList := TStringList.Create;
  IsTruncated := False;
  try
    for i := 0 to FActiveCodeList.Count - 1 do
    begin
      ItemColor := TColor(PtrInt(FActiveCodeList.Objects[i]));
      pbxLegendCodeName.Canvas.Font.Color := ItemColor;
      CodeWordList.Delimiter := ' ';
      CodeWordList.StrictDelimiter := True;
      CodeWordList.DelimitedText := FActiveCodeList[i];     
      for j := 0 to CodeWordList.Count - 1 do
      begin
        CurrentWord := CodeWordList[j];
        if CurrentWord = '' then Continue;
        while CurrentWord <> '' do
        begin
          WordWidth := pbxLegendCodeName.Canvas.TextWidth(CurrentWord);
          if CurrentX + WordWidth <= DrawRectangle.Right then
          begin
            if CurrentY + LineHeight > DrawRectangle.Bottom + 8 then
            begin
              IsTruncated := True;
              Break;
            end;
            pbxLegendCodeName.Canvas.TextOut(CurrentX, CurrentY, CurrentWord);
            LastValidY := CurrentY;
            CurrentX := CurrentX + WordWidth + SpaceWidth;
            CurrentWord := '';
            Break;
          end;
          if (CurrentX > DrawRectangle.Left) and (WordWidth <= MaximumWidth) then
          begin
            if CurrentY + (LineHeight * 2) > DrawRectangle.Bottom + 8 then
            begin
              IsTruncated := True;
              Break;
            end;
            CurrentX := DrawRectangle.Left;
            CurrentY := CurrentY + LineHeight;
            Continue;
          end;
          if CurrentX > DrawRectangle.Left then
          begin
            if CurrentY + (LineHeight * 2) > DrawRectangle.Bottom + 8 then
            begin
              IsTruncated := True;
              Break;
            end;
            CurrentX := DrawRectangle.Left;
            CurrentY := CurrentY + LineHeight;
          end;
          CharacterCount := 1;
          while (CharacterCount <= UTF8Length(CurrentWord)) do
          begin
            if pbxLegendCodeName.Canvas.TextWidth(UTF8Copy(CurrentWord, 1, CharacterCount) + '-') > MaximumWidth then
              Break;
            Inc(CharacterCount);
          end;
          Dec(CharacterCount);
          if CharacterCount <= 0 then CharacterCount := 1;
          Chunk := UTF8Copy(CurrentWord, 1, CharacterCount) + '-';
          if CurrentY + LineHeight > DrawRectangle.Bottom + 8 then
          begin
            IsTruncated := True;
            Break;
          end;
          pbxLegendCodeName.Canvas.TextOut(CurrentX, CurrentY, Chunk);
          LastValidY := CurrentY;
          UTF8Delete(CurrentWord, 1, CharacterCount);
          if (CurrentWord <> '') and (CurrentY + (LineHeight * 2) > DrawRectangle.Bottom + 8) then
          begin
            IsTruncated := True;
            Break;
          end;
          CurrentX := DrawRectangle.Left;
          CurrentY := CurrentY + LineHeight;
        end; 
        if IsTruncated then Break;
      end; 
      if IsTruncated then Break;
      CurrentX := CurrentX + SpaceWidth; 
    end; 
    if IsTruncated then
    begin
      DisplayText := '...';
      pbxLegendCodeName.Canvas.Font.Color := clGray;
      pbxLegendCodeName.Canvas.Font.Style := [fsBold];
      WordWidth := pbxLegendCodeName.Canvas.TextWidth(DisplayText);
      CurrentX := DrawRectangle.Right - WordWidth;
      ClearRectangle.Left := CurrentX - 4;
      ClearRectangle.Top := LastValidY;
      ClearRectangle.Right := DrawRectangle.Right + 8;
      ClearRectangle.Bottom := LastValidY + LineHeight;
      pbxLegendCodeName.Canvas.Brush.Color := clWhite;
      pbxLegendCodeName.Canvas.Brush.Style := bsSolid;
      pbxLegendCodeName.Canvas.FillRect(ClearRectangle);
      pbxLegendCodeName.Canvas.TextOut(CurrentX, LastValidY, DisplayText);
    end;
  finally
    CodeWordList.Free;
  end;
end;

procedure TfrmAppBase.OnTreeCodeHover(CodeName: String; CodeColor: TColor);
begin
  if (FActiveCodeList.Count <> 1) or (FActiveCodeList[0] <> CodeName) then
  begin
    FActiveCodeList.Clear;
    FActiveCodeList.AddObject(CodeName, TObject(PtrInt(CodeColor)));
    pbxLegendCodeName.Invalidate;
  end;
end;

procedure TfrmAppBase.OnTreeCodeHoverClear(Sender: TObject);
begin
  if FActiveCodeList.Count > 0 then
  begin
    FActiveCodeList.Clear;
    pbxLegendCodeName.Invalidate;
  end;
end;

procedure TfrmAppBase.OnTreeCodeDoubleClick(const CodeID: String; CodeColor: TColor);
begin
  if Assigned(FRenderDocument) and FRenderDocument.HasSelection then
    ApplyCoding(CodeID, CodeColor);
end;

procedure TfrmAppBase.OnCodeTreeChanged(Sender: TObject);
begin
  RefreshCodeTree;
end;

procedure TfrmAppBase.pmnTreeCodePopup(Sender: TObject);
var
  SelCount: Integer;
  IsAnalytical: Boolean;
  P: TPoint;
  HitInfo: THitInfo;
  TargetNode, Node: PVirtualNode;
  AllExpanded, AllCollapsed: Boolean;
begin
  SelCount := vstCode.SelectedCount;
  IsAnalytical := FControllerTreeCode.SortField <> 'sort_order';
  mniTreeCodeAddSubCode.Enabled := (SelCount = 1) and not IsAnalytical;
  mniTreeCodeRename.Enabled := (SelCount = 1);
  mniTreeCodeColorChange.Enabled := (SelCount > 0);
  mniTreeCodeMemo.Enabled := (SelCount = 1);
  mniTreeCodeDelete.Enabled := (SelCount > 0) and not IsAnalytical;
  mniTreeCodeMerge.Enabled := (SelCount >= 2) and not IsAnalytical;
  mniTreeCodeMoveUp.Enabled := (SelCount > 0) and not IsAnalytical;
  mniTreeCodeMoveDown.Enabled := (SelCount > 0) and not IsAnalytical;
  mniTreeCodePromote.Enabled := (SelCount > 0) and not IsAnalytical;
  mniTreeCodeDemote.Enabled := (SelCount > 0) and not IsAnalytical;
  P := vstCode.ScreenToClient(Mouse.CursorPos);
  vstCode.GetHitTestInfoAt(P.X, P.Y, True, HitInfo);
  if Assigned(HitInfo.HitNode) then
  begin
    mniTreeCodeExpandAll.Caption := 'Expand Branch';
    mniTreeCodeCollapseAll.Caption := 'Collapse Branch';
    TargetNode := HitInfo.HitNode;
    mniTreeCodeExpandAll.Enabled := (TargetNode^.ChildCount > 0) and not FControllerTreeCode.IsBranchFullyExpanded(TargetNode);
    mniTreeCodeCollapseAll.Enabled := (TargetNode^.ChildCount > 0) and not FControllerTreeCode.IsBranchFullyCollapsed(TargetNode);
  end
  else
  begin
    mniTreeCodeExpandAll.Caption := 'Expand All';
    mniTreeCodeCollapseAll.Caption := 'Collapse All';
    AllExpanded := True;
    AllCollapsed := True;
    Node := vstCode.GetFirst;
    while Assigned(Node) do
    begin
      if (Node^.ChildCount > 0) then
      begin
        if not FControllerTreeCode.IsBranchFullyExpanded(Node) then AllExpanded := False;
        if not FControllerTreeCode.IsBranchFullyCollapsed(Node) then AllCollapsed := False;
      end;
      Node := Node^.NextSibling;
    end;
    mniTreeCodeExpandAll.Enabled := (vstCode.RootNodeCount > 0) and not AllExpanded;
    mniTreeCodeCollapseAll.Enabled := (vstCode.RootNodeCount > 0) and not AllCollapsed;
  end;
  mniTreeCodeExpandAll.Visible := True;
  mniTreeCodeCollapseAll.Visible := True;
end;

procedure TfrmAppBase.tmrCodeSearchTimer(Sender: TObject);
begin
  tmrCodeSearch.Enabled := False;
  RefreshCodeTree;
end;

procedure TfrmAppBase.edtCodeSearchChange(Sender: TObject);
begin
  tmrCodeSearch.Enabled := False;
  tmrCodeSearch.Enabled := True;
end;

procedure TfrmAppBase.edtCodeSearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    tmrCodeSearch.Enabled := False;
    RefreshCodeTree;
    Key := 0;
  end;
end;

procedure TfrmAppBase.btnCodeAddClick(Sender: TObject);
var
  CodeName, CodeDescription: String;
  ExistingID: String;
begin
  CodeName := '';
  CodeDescription := '';
  frmDialogEditor := TfrmDialogEditor.Create(Self);
  try
    if not frmDialogEditor.ExecuteTreeEditor('New Code', CodeName, CodeDescription) then Exit;
  finally
    frmDialogEditor.Free;
  end;
  if CodeName = '' then Exit;
  if FServiceDatabase.CodeExists(CodeName, '', ExistingID) then
  begin
    MessageDlg('Duplicate Code', 'The code "' + CodeName + '" already exists in this hierarchy.', mtInformation, [mbOK], 0);
    FControllerTreeCode.SelectCodeNode(ExistingID);
    Exit;
  end;
  try
    FServiceDatabase.AddCode(CodeName, CodeDescription, GetNextColor, '');
    RefreshCodeTree;
  except
    on E: Exception do MessageDlg('Database Error', 'Failed to add code: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmAppBase.btnCodeSortClick(Sender: TObject);
var
  FullSpecification, SortField, SortOrder: String;
  AttributeList: TStringList;
  CurrentCriteria: String;
begin
  btnCodeSort.Down := FControllerTreeCode.SortField <> 'sort_order';
  AttributeList := TStringList.Create;
  frmDialogSort := TfrmDialogSort.Create(Self);
  try
    if FControllerTreeCode.SortField = 'usage_cnt' then CurrentCriteria := 'Coding Count'
    else if FControllerTreeCode.SortField = 'created_at' then CurrentCriteria := 'Creation Time'
    else if FControllerTreeCode.SortField = 'name' then CurrentCriteria := 'Code Name'
    else CurrentCriteria := 'Code Name'; 
    frmDialogSort.InitializeOptions(AttributeList, CurrentCriteria, FControllerTreeCode.SortOrder = 'DESC', btnCodeSort.Down, True);
    if frmDialogSort.ShowModal = mrOk then
    begin
      if frmDialogSort.Tag = 999 then
      begin
        btnCodeSort.Down := False;
        FControllerTreeCode.ApplySort('sort_order', 'ASC');
      end
      else
      begin
        FullSpecification := frmDialogSort.cmbSortCriteria.Text;
        SortOrder := 'ASC';
        if frmDialogSort.rgSortOrder.ItemIndex = 1 then SortOrder := 'DESC';
        if FullSpecification = 'Coding Count' then SortField := 'usage_cnt'
        else if FullSpecification = 'Creation Time' then SortField := 'created_at'
        else SortField := 'name';
        if frmDialogSort.Tag = 888 then
        begin
          btnCodeSort.Down := False;
          FServiceDatabase.PersistAnalyticalSort(SortField, SortOrder);
          FControllerTreeCode.ApplySort('sort_order', 'ASC');
        end
        else
        begin
          btnCodeSort.Down := True;
          FControllerTreeCode.ApplySort(SortField, SortOrder);
        end;
      end;
    end
    else
    begin
      btnCodeSort.Down := FControllerTreeCode.SortField <> 'sort_order';
    end;
  finally
    frmDialogSort.Free;
    AttributeList.Free;
  end;
  UpdateCodeSortUI;
  vstCode.SetFocus;
end;

procedure TfrmAppBase.mniTreeCodeAddSubCodeClick(Sender: TObject);
var
  ParentID, ExistingID: String;
  CodeName, CodeDescription, ParentName: String;
begin
  if not FControllerTreeCode.GetFocusedNodeData(ParentID, ParentName) then Exit;
  if Assigned(vstCode.FocusedNode) and (vstCode.GetNodeLevel(vstCode.FocusedNode) >= 5) then
  begin
    MessageDlg('Code Hierarchy Overshoot', 'The code tree hierarchy is limited to six levels. This action is not allowed as it would overshoot the limit.', mtInformation, [mbOK], 0);
    Exit;
  end;
  CodeName := '';
  CodeDescription := '';
  frmDialogEditor := TfrmDialogEditor.Create(Self);
  try
    if not frmDialogEditor.ExecuteTreeEditor('New Sub-Code', CodeName, CodeDescription) then Exit;
  finally
    frmDialogEditor.Free;
  end;
  if CodeName = '' then Exit;
  if SameText(CodeName, ParentName) then
  begin
    MessageDlg('Naming Conflict', 'A sub-code cannot have the exact same name as its parent code.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if FServiceDatabase.CodeExists(CodeName, ParentID, ExistingID) then
  begin
    MessageDlg('Duplicate Code', 'The code "' + CodeName + '" already exists in this hierarchy.', mtInformation, [mbOK], 0);
    FControllerTreeCode.SelectCodeNode(ExistingID);
    Exit;
  end;
  try
    FServiceDatabase.AddCode(CodeName, CodeDescription, GetNextColor, ParentID);
    RefreshCodeTree;
  except
    on E: Exception do MessageDlg('Error', 'Failed to add sub-code: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmAppBase.mniTreeCodeRenameClick(Sender: TObject);
var
  CodeID, ParentID, ExistingID: String;
  CurrentName, NewName, NewDescription: String;
begin
  if not FControllerTreeCode.GetFocusedNodeData(CodeID, CurrentName) then Exit;
  NewName := CurrentName;
  NewDescription := '';
  qryCheck.Close;
  qryCheck.SQL.Text := 'SELECT description FROM codes WHERE id = :id';
  qryCheck.Params.ParamByName('id').AsString := CodeID;
  qryCheck.Open;
  if not qryCheck.EOF then NewDescription := qryCheck.FieldByName('description').AsString;
  qryCheck.Close;
  frmDialogEditor := TfrmDialogEditor.Create(Self);
  try
    if not frmDialogEditor.ExecuteTreeEditor('View/Modify Code Details', NewName, NewDescription) then Exit;
  finally
    frmDialogEditor.Free;
  end;
  if (NewName = '') then Exit;
  if (NewName <> CurrentName) then
  begin
    ParentID := FControllerTreeCode.GetFocusedNodeParentID;
    if FServiceDatabase.CodeExists(NewName, ParentID, ExistingID) then
    begin
      MessageDlg('Naming Conflict', 'Another code matches this name.', mtError, [mbOK], 0);
      Exit;
    end;
  end;
  try
    FServiceDatabase.UpdateCodeDetails(CodeID, NewName, NewDescription);
    RefreshCodeTree;
  except
    on E: Exception do MessageDlg('Database Error', 'Failed to update code: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmAppBase.mniTreeCodeColorChangeClick(Sender: TObject);
var
  CodeIDs: TStringDynArray;
begin
  CodeIDs := FControllerTreeCode.GetSelectedID;
  if Length(CodeIDs) = 0 then Exit;
  if dlgPickColor.Execute then
  begin
    FServiceDatabase.UpdateCodeColorBatch(CodeIDs, dlgPickColor.Color);
    RefreshCodeTree; 
    LoadCodingForCurrentDocument;
    if Assigned(FRenderDocument) then FRenderDocument.Invalidate;
  end;
end;

procedure TfrmAppBase.mniTreeCodeMergeClick(Sender: TObject);
var
  TargetID: String;
  TargetName: String;
  SourceID: TStringDynArray;
  Worker: TThreadBatchMergeCode;
begin
  if not FControllerTreeCode.GetMergeData(TargetID, TargetName, SourceID) then Exit;
  if not ForceExitEditMode then Exit;
  if MessageDlg('Merge Codes', 'Are you sure you want to merge selected codes into "' + TargetName + '"? This action cannot be undone.', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;
  FRenderDocument.ClearSelection;
  Worker := TThreadBatchMergeCode.Create(conMain.DatabaseName);
  try
    Worker.FTargetID := TargetID;
    Worker.FSourceID := Copy(SourceID);
    Worker.Start;
    TfrmDialogProgress.Prepare('Merging Codes', 'Initialising...');
    frmDialogProgress.ShowModal;
    if trnMain.Active then trnMain.Commit;
    if Worker.Success then
    begin
      RefreshCodeTree;
      ReloadCurrentDocument;
      RefreshDocumentList;
    end
    else
      MessageDlg('Error', 'Merge failed: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

procedure TfrmAppBase.mniTreeCodeMoveUpClick(Sender: TObject);
begin
  FControllerTreeCode.NudgeSelected(0);
end;

procedure TfrmAppBase.mniTreeCodeMoveDownClick(Sender: TObject);
begin
  FControllerTreeCode.NudgeSelected(1);
end;

procedure TfrmAppBase.mniTreeCodePromoteClick(Sender: TObject);
begin
  FControllerTreeCode.NudgeSelected(2);
end;

procedure TfrmAppBase.mniTreeCodeDemoteClick(Sender: TObject);
begin
  FControllerTreeCode.NudgeSelected(3);
end;

procedure TfrmAppBase.mniTreeCodeExpandAllClick(Sender: TObject);
begin
  FControllerTreeCode.FullExpand(True);
end;

procedure TfrmAppBase.mniTreeCodeCollapseAllClick(Sender: TObject);
begin
  FControllerTreeCode.FullCollapse(True);
end;

procedure TfrmAppBase.mniTreeCodeDeleteClick(Sender: TObject);
var
  CodeID: String;
  TotalCode, TotalCoding, TotalMemo: Integer;
  CodeName, ConfirmMessage: String;
  Worker: TThreadBatchCodeDeleteRecursive;
begin
  if not FControllerTreeCode.GetFocusedNodeData(CodeID, CodeName) then Exit;
  if not ForceExitEditMode then Exit;
  FServiceDatabase.GetRecursiveCount(CodeID, TotalCode, TotalCoding, TotalMemo);
  ConfirmMessage := 'Are you sure you want to permanently delete "' + CodeName + '"?';
  if (TotalCode > 1) or (TotalCoding > 0) or (TotalMemo > 0) then
  begin
    ConfirmMessage := ConfirmMessage + sLineBreak + sLineBreak +
                  'The following associated data will also be deleted:' + sLineBreak;
    if TotalCode > 1 then
      ConfirmMessage := ConfirmMessage + ' • ' + IntToStr(TotalCode - 1) + ' ' + TAppFormat.Pluralize(TotalCode - 1, 'sub-code', 'sub-codes') + sLineBreak;
    if TotalCoding > 0 then
      ConfirmMessage := ConfirmMessage + ' • ' + IntToStr(TotalCoding) + ' ' + TAppFormat.Pluralize(TotalCoding, 'coding application', 'coding applications') + sLineBreak;
    if TotalMemo > 0 then
      ConfirmMessage := ConfirmMessage + ' • ' + IntToStr(TotalMemo) + ' attached ' + TAppFormat.Pluralize(TotalMemo, 'memo', 'memos') + sLineBreak;
  end;
  if MessageDlg('Confirm Deletion', Trim(ConfirmMessage), mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    FRenderDocument.ClearSelection;
    Worker := TThreadBatchCodeDeleteRecursive.Create(conMain.DatabaseName);
    try
      Worker.FCodeID := CodeID;
      Worker.Start;
      TfrmDialogProgress.Prepare('Deleting Code', 'Initialising...');
      frmDialogProgress.ShowModal;
      if trnMain.Active then trnMain.Commit;
      if Worker.Success then
      begin
        RefreshCodeTree;
        ReloadCurrentDocument;
        RefreshDocumentList;
      end
      else
        MessageDlg('Error', 'Deletion failed: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
    finally
      Worker.Free;
    end;
  end;
end;

procedure TfrmAppBase.mniTreeCodeMemoClick(Sender: TObject);
var
  CodeID: String;
  CodeName: String;
begin
  if FControllerTreeCode.GetFocusedNodeData(CodeID, CodeName) then
  begin
    TServiceMemo.Execute(conMain, 'Code', CodeID, CodeName);
    RefreshCodeTree;
  end;
end;

procedure TfrmAppBase.RefreshAttribute;
var
  ColumnName, AttributeType, JSONString: String;
  JSONData, ValueElement: TJSONData;
  JSONObject: TJSONObject;
  Count, Capacity: Integer;
  SavedAttributeName: String;
  Node: PVirtualNode;
begin
  SavedAttributeName := '';
  Node := vstAttribute.GetFirstSelected;
  if Assigned(Node) and (Node^.Index < Cardinal(Length(FCurrentDocumentAttribute))) then
    SavedAttributeName := FCurrentDocumentAttribute[Node^.Index].Name;
  vstAttribute.BeginUpdate;
  try
    vstAttribute.Clear;
    SetLength(FCurrentDocumentAttribute, 0);
    if FCurrentDocumentID = '' then Exit;
    qryCheck.Close;
    qryCheck.SQL.Text := 'SELECT attributes FROM document_attributes WHERE document_id = :id';
    qryCheck.Params.ParamByName('id').AsString := FCurrentDocumentID;
    qryCheck.Open;
    if qryCheck.EOF then
    begin
      qryCheck.Close;
      Exit;
    end;
    JSONString := qryCheck.FieldByName('attributes').AsString;
    qryCheck.Close;
    if Trim(JSONString) = '' then JSONString := '{}';
    JSONData := nil;
    try
      JSONData := GetJSON(JSONString);
      if (JSONData <> nil) and (JSONData.JSONType = jtObject) then
      begin
        JSONObject := TJSONObject(JSONData);
        qryMain.Close;
        qryMain.SQL.Text := 'SELECT name, attribute_key, attribute_type FROM attribute_registry ORDER BY name ASC';
        qryMain.Open;
        Count := 0;
        Capacity := 16;
        SetLength(FCurrentDocumentAttribute, Capacity);
        while not qryMain.EOF do
        begin
          ColumnName := qryMain.FieldByName('attribute_key').AsString;
          AttributeType := qryMain.FieldByName('attribute_type').AsString;
          ValueElement := JSONObject.Find(ColumnName);
          if Assigned(ValueElement) and (ValueElement.JSONType <> jtNull) then
          begin
            if Count >= Capacity then
            begin
              Capacity := Capacity * 2;
              SetLength(FCurrentDocumentAttribute, Capacity);
            end;
            FCurrentDocumentAttribute[Count].Name := qryMain.FieldByName('name').AsString;
            if AttributeType = 'Numeric' then
              FCurrentDocumentAttribute[Count].Value := FloatToStr(ValueElement.AsFloat)
            else
              FCurrentDocumentAttribute[Count].Value := ValueElement.AsString;
            FCurrentDocumentAttribute[Count].AttributeType := AttributeType;
            Inc(Count);
          end;
          qryMain.Next;
        end;
        qryMain.Close;
        SetLength(FCurrentDocumentAttribute, Count);
      end;
    finally
      if Assigned(JSONData) then JSONData.Free;
    end;
    if (FSortAttributeColumn >= 0) and (Length(FCurrentDocumentAttribute) > 1) then
      SortAttribute;
    vstAttribute.RootNodeCount := Length(FCurrentDocumentAttribute);
    if SavedAttributeName <> '' then
    begin
      Node := vstAttribute.GetFirst;
      while Assigned(Node) do
      begin
        if (Node^.Index < Cardinal(Length(FCurrentDocumentAttribute))) then
        begin
          if FCurrentDocumentAttribute[Node^.Index].Name = SavedAttributeName then
          begin
            vstAttribute.Selected[Node] := True;
            vstAttribute.FocusedNode := Node;
            Break;
          end;
        end;
        Node := vstAttribute.GetNext(Node);
      end;
    end;
  finally
    vstAttribute.EndUpdate;
  end;
end;

procedure TfrmAppBase.SortAttribute;
  function CompareAttribute(const A, B: TDocumentAttributeItem): Integer;
  begin
    if FSortAttributeColumn = 0 then
      Result := AnsiCompareText(A.Name, B.Name)
    else
      Result := AnsiCompareText(A.Value, B.Value);
    if not FSortAttributeAscending then Result := -Result;
  end;
  procedure QuickSort(LeftIndex, RightIndex: Integer);
  var
    I, J: Integer;
    Pivot, Temp: TDocumentAttributeItem;
  begin
    if LeftIndex >= RightIndex then Exit;
    I := LeftIndex;
    J := RightIndex;
    Pivot := FCurrentDocumentAttribute[LeftIndex + (RightIndex - LeftIndex) div 2];
    repeat
      while CompareAttribute(FCurrentDocumentAttribute[I], Pivot) < 0 do Inc(I);
      while CompareAttribute(FCurrentDocumentAttribute[J], Pivot) > 0 do Dec(J);
      if I <= J then
      begin
        Temp := FCurrentDocumentAttribute[I];
        FCurrentDocumentAttribute[I] := FCurrentDocumentAttribute[J];
        FCurrentDocumentAttribute[J] := Temp;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if LeftIndex < J then QuickSort(LeftIndex, J);
    if I < RightIndex then QuickSort(I, RightIndex);
  end;
begin
  if (FSortAttributeColumn < 0) or (Length(FCurrentDocumentAttribute) < 2) then Exit;
  QuickSort(0, High(FCurrentDocumentAttribute));
end;

procedure TfrmAppBase.vstAttributeHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
begin
  if HitInfo.Column < 0 then Exit;
  if FSortAttributeColumn = HitInfo.Column then
    FSortAttributeAscending := not FSortAttributeAscending
  else
  begin
    FSortAttributeColumn := HitInfo.Column;
    FSortAttributeAscending := True;
  end;
  Sender.SortColumn := FSortAttributeColumn;
  if FSortAttributeAscending then Sender.SortDirection := sdAscending else Sender.SortDirection := sdDescending;
  SortAttribute;
  vstAttribute.Invalidate;
end;

procedure TfrmAppBase.vstAttributeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
begin
  if (Node^.Index < Cardinal(Length(FCurrentDocumentAttribute))) then
  begin
    case Column of
      0: CellText := FCurrentDocumentAttribute[Node^.Index].Name;
      1: CellText := FCurrentDocumentAttribute[Node^.Index].Value;
    end;
  end;
end;

procedure TfrmAppBase.vstAttributePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
begin
  if (Column = 1) and (Node^.Index < Cardinal(Length(FCurrentDocumentAttribute))) and (FCurrentDocumentAttribute[Node^.Index].AttributeType = 'URL or Path') then
    TargetCanvas.Font.Color := $3C0266
  else
    TargetCanvas.Font.Color := clWindowText;
end;

procedure TfrmAppBase.vstAttributeDblClick(Sender: TObject);
var
  AttributeValue, AttributeType: String;
  Node: PVirtualNode;
begin
  Node := vstAttribute.FocusedNode;
  if not Assigned(Node) or (Node^.Index < 0) or (Node^.Index >= Length(FCurrentDocumentAttribute)) then Exit;
  AttributeType := FCurrentDocumentAttribute[Node^.Index].AttributeType;
  if AttributeType = 'URL or Path' then
  begin
    AttributeValue := FCurrentDocumentAttribute[Node^.Index].Value;
    if Trim(AttributeValue) <> '' then
    begin
      if not OpenURL(AttributeValue) then
        MessageDlg('Error', 'Could not open the link or path: ' + AttributeValue, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmAppBase.vstAttributeExit(Sender: TObject);
begin
  vstAttribute.ClearSelection;
end;

procedure TfrmAppBase.pmnListAttributePopup(Sender: TObject);
var
  P: TPoint;
  HitInfo: THitInfo;
begin
  P := vstAttribute.ScreenToClient(Mouse.CursorPos);
  vstAttribute.GetHitTestInfoAt(P.X, P.Y, True, HitInfo);
  if Assigned(HitInfo.HitNode) then
  begin
    vstAttribute.ClearSelection;
    vstAttribute.Selected[HitInfo.HitNode] := True;
    vstAttribute.FocusedNode := HitInfo.HitNode;
    mniListAttributeValueCopy.Visible := True;
  end
  else
    Abort;
end;

procedure TfrmAppBase.mniListAttributeValueCopyClick(Sender: TObject);
var
  Node: PVirtualNode;
begin
  Node := vstAttribute.FocusedNode;
  if Assigned(Node) and (Node^.Index < Cardinal(Length(FCurrentDocumentAttribute))) then
    Clipbrd.Clipboard.AsText := FCurrentDocumentAttribute[Node^.Index].Value;
end;

procedure TfrmAppBase.mniDocumentClick(Sender: TObject);
var
  VisibleCount, SelCount: Integer;
  HasFilters: Boolean;
  ScopeText: String;
begin
  VisibleCount := FControllerTreeDocument.DocumentCount;
  SelCount := vstDocument.SelectedCount;
  HasFilters := FControllerTreeDocument.FilterDefinition.IsFilterActive or 
                (Trim(FControllerTreeDocument.FilterDefinition.QuickSearchText) <> '');
  if VisibleCount = 0 then
  begin
    mniDocumentExport.Enabled := False;
    Exit;
  end;
  mniDocumentExport.Enabled := True;
  if (SelCount > 0) and (SelCount < VisibleCount) then
    ScopeText := 'Selected '
  else
  begin
    if HasFilters then 
      ScopeText := 'Filtered '
    else 
      ScopeText := 'All ';
  end;
  mniDocumentExportText.Caption := 'Export ' + ScopeText + 'as TXT with Metadata CSV';
  mniDocumentExportSheet.Caption := 'Export ' + ScopeText + 'as XLSX/ODS Spreadsheet';
  mniDocumentExportJSON.Caption := 'Export ' + ScopeText + 'as JSON Structured Data';
  mniDocumentExportXML.Caption := 'Export ' + ScopeText + 'as XML Structured Data';
end;

procedure TfrmAppBase.mniDocumentImportTextClick(Sender: TObject);
var
  Count: Integer;
begin
  if not ForceExitEditMode then Exit;
  dlgImport.Filter := 'Text Files (*.txt)|*.txt|All Files (*.*)|*.*';
  dlgImport.Title := 'Select Text Files to Import';
  if dlgImport.Execute then
  begin
    Count := TServiceImport.ImportTextFile(conMain, dlgImport.Files);
    if Count > 0 then
    begin
      RefreshDocumentList;
      UpdateDashboardStatistic;
    end;
  end;
end;

procedure TfrmAppBase.mniDocumentImportWordClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  dlgImport.Filter := 'Word Processor Files (*.docx;*.odt)|*.docx;*.odt';
  dlgImport.Title := 'Select Word Processor Files to Import';
  if dlgImport.Execute then
  begin
    TServiceImport.ImportWordProcessorFile(conMain, dlgImport.Files);
    RefreshDocumentList;
    UpdateDashboardStatistic;
  end;
end;

procedure TfrmAppBase.mniDocumentImportPDFClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  MessageDlg('Import PDF Files as Plain-Text', 'PDF imports are supported only for machine-readable or accurately OCR-processed text. Image-only pages and encrypted documents will be skipped. Please note that visual layout structures may vary in the extracted text.', mtInformation, [mbOK], 0);
  dlgImport.Filter := 'PDF Documents (*.pdf)|*.pdf';
  dlgImport.Title := 'Select PDF Files to Import';
  if dlgImport.Execute then
  begin
    TServiceImport.ImportPDFDocument(conMain, dlgImport.Files);
    RefreshDocumentList;
    UpdateDashboardStatistic;
  end;
end;

procedure TfrmAppBase.mniDocumentImportSheetClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  dlgImport.Filter := 'Spreadsheet Files (*.xlsx;*.ods)|*.xlsx;*.ods';
  if not dlgImport.Execute then Exit;
  if TServiceImport.ImportSpreadsheet(conMain, dlgImport.FileName) then
  begin
    RefreshDocumentList;
    UpdateDashboardStatistic;
  end;
end;

procedure TfrmAppBase.mniDocumentImportJSONClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  dlgImport.Filter := 'Structured Data (*.json)|*.json';
  if not dlgImport.Execute then Exit;
  if TServiceImport.ImportJSON(conMain, dlgImport.FileName) then
  begin
    RefreshDocumentList;
    UpdateDashboardStatistic;
  end;
end;

procedure TfrmAppBase.mniDocumentImportSQLiteClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  dlgImport.Filter := 'SQLite Database (*.sqlite;*.db;*.db3)|*.sqlite;*.db;*.db3';
  if not dlgImport.Execute then Exit;
  if TServiceImport.ImportSQLite(conMain, dlgImport.FileName) then
  begin
    RefreshDocumentList;
    UpdateDashboardStatistic;
  end;
end;

procedure TfrmAppBase.mniDocumentExportTextClick(Sender: TObject);
var
  DocumentID: TStringDynArray;
begin
  if not ForceExitEditMode then Exit;
  DocumentID := FServiceDatabase.GetDocumentScopeID(GetSelectedDocumentID, FControllerTreeDocument.FilterDefinition);
  if Length(DocumentID) = 0 then
  begin
    MessageDlg('No Documents', 'There are no documents to export in the current scope.', mtInformation, [mbOK], 0);
    Exit;
  end;
  if not dlgExportDirectory.Execute then Exit;
  if TServiceExport.ExportDocumentText(conMain, dlgExportDirectory.FileName, DocumentID) then
    MessageDlg('Success', 'Documents exported successfully.', mtInformation, [mbOK], 0);
end;

procedure TfrmAppBase.mniDocumentExportSheetClick(Sender: TObject);
var
  DocumentID: TStringDynArray;
  TargetFormat: TsSpreadsheetFormat;
begin
  if not ForceExitEditMode then Exit;
  DocumentID := FServiceDatabase.GetDocumentScopeID(GetSelectedDocumentID, FControllerTreeDocument.FilterDefinition);
  if Length(DocumentID) = 0 then
  begin
    MessageDlg('No Documents', 'There are no documents to export in the current scope.', mtInformation, [mbOK], 0);
    Exit;
  end;
  if FServiceDatabase.CheckSpreadsheetTruncationRisk(DocumentID) then
  begin
    if MessageDlg('Truncation Risk', 'Some documents exceed the 32,767 character limit for spreadsheet cells. Their content will be truncated if exported in this format. Proceed anyway?', mtWarning, [mbYes, mbNo], 0) = mrNo then Exit;
  end;
  dlgExportCodebook.Title := 'Export Documents';
  dlgExportCodebook.DefaultExt := '.xlsx';
  dlgExportCodebook.Filter := 'Excel Spreadsheet (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods';
  if not dlgExportCodebook.Execute then Exit;
  if LowerCase(ExtractFileExt(dlgExportCodebook.FileName)) = '.ods' then
    TargetFormat := sfOpenDocument
  else
    TargetFormat := sfOOXML;
  if TServiceExport.ExportDocumentSheet(conMain, dlgExportCodebook.FileName, DocumentID, TargetFormat) then
    MessageDlg('Success', 'Documents exported successfully.', mtInformation, [mbOK], 0);
end;

procedure TfrmAppBase.mniDocumentExportJSONClick(Sender: TObject);
var
  DocumentID: TStringDynArray;
begin
  if not ForceExitEditMode then Exit;
  DocumentID := FServiceDatabase.GetDocumentScopeID(GetSelectedDocumentID, FControllerTreeDocument.FilterDefinition);
  if Length(DocumentID) = 0 then
  begin
    MessageDlg('No Documents', 'There are no documents to export in the current scope.', mtInformation, [mbOK], 0);
    Exit;
  end;
  dlgExportCodebook.Title := 'Export Documents';
  dlgExportCodebook.DefaultExt := '.json';
  dlgExportCodebook.Filter := 'JSON Structured Data (*.json)|*.json';
  if not dlgExportCodebook.Execute then Exit;
  if TServiceExport.ExportDocumentJSON(conMain, dlgExportCodebook.FileName, DocumentID) then
    MessageDlg('Success', 'Documents exported successfully.', mtInformation, [mbOK], 0);
end;

procedure TfrmAppBase.mniDocumentExportXMLClick(Sender: TObject);
var
  DocumentID: TStringDynArray;
begin
  if not ForceExitEditMode then Exit;
  DocumentID := FServiceDatabase.GetDocumentScopeID(GetSelectedDocumentID, FControllerTreeDocument.FilterDefinition);
  if Length(DocumentID) = 0 then
  begin
    MessageDlg('No Documents', 'There are no documents to export in the current scope.', mtInformation, [mbOK], 0);
    Exit;
  end;
  dlgExportCodebook.Title := 'Export Documents';
  dlgExportCodebook.DefaultExt := '.xml';
  dlgExportCodebook.Filter := 'XML Structured Data (*.xml)|*.xml';
  if not dlgExportCodebook.Execute then Exit;
  if TServiceExport.ExportDocumentXML(conMain, dlgExportCodebook.FileName, DocumentID) then
    MessageDlg('Success', 'Documents exported successfully.', mtInformation, [mbOK], 0);
end;

procedure TfrmAppBase.mniCodeSystemImportClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  dlgImport.Filter := 'Code System (*.json)|*.json';
  if not dlgImport.Execute then Exit;
  if TServiceImport.ImportCodingScheme(conMain, dlgImport.FileName) then
  begin
    RefreshCodeTree;
    MessageDlg('Success', 'Code system imported successfully.', mtInformation, [mbOK], 0);
  end;
  UpdateCodeSystemMenu;
end;

procedure TfrmAppBase.mniCodeSystemExportClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  if not dlgExportSystem.Execute then Exit;
  try
    if TServiceExport.ExportCodeSystem(qryUtil, dlgExportSystem.FileName) then
      MessageDlg('Success', 'Code system exported successfully.', mtInformation, [mbOK], 0)
    else
      MessageDlg('Error', 'Failed to export code system.', mtError, [mbOK], 0);
  except
    on E: Exception do 
      MessageDlg('Export Error', E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmAppBase.mniCodebookExportClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  if not dlgExportCodebook.Execute then Exit;
  try
    if TServiceExport.ExportCodebook(conMain, dlgExportCodebook.FileName) then
      MessageDlg('Success', 'Codebook exported successfully.', mtInformation, [mbOK], 0)
    else
      MessageDlg('Error', 'Failed to export codebook.', mtError, [mbOK], 0);
  except
    on E: Exception do 
      MessageDlg('Export Error', E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmAppBase.mniProjectOptimizeClick(Sender: TObject);
var
  DBPath: String;
begin
  if not conMain.Connected then Exit;
  if not ForceExitEditMode then Exit;
  if MessageDlg('Optimise Project', 'This will rebuild search indices, defragment the database, and reclaim disk space. It may take a few moments, depending on the project size.' + sLineBreak + sLineBreak + 'Do you wish to proceed?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;
  Screen.Cursor := crHourGlass;
  try
    FServiceDatabase.OptimizeProject;
    DBPath := conMain.DatabaseName;
    if trnMain.Active then trnMain.Commit;
    conMain.Close;
    conMain.DatabaseName := DBPath;
    conMain.Open;
    trnMain.StartTransaction;
    MessageDlg('Success', 'Project optimisation complete. Search indices have been rebuilt, the database is fully defragmented, and unused disk space has been successfully reclaimed.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
    begin
      if not trnMain.Active then trnMain.StartTransaction;
      MessageDlg('Optimisation Error', 'An error occurred during maintenance: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
  Screen.Cursor := crDefault;
end;

procedure TfrmAppBase.mniProjectSnapshotClick(Sender: TObject);
var
  BaseName: String;
begin
  if not conMain.Connected then Exit;
  if not ForceExitEditMode then Exit;
  BaseName := ChangeFileExt(ExtractFileName(conMain.DatabaseName), '');
  dlgSnapshotSave.FileName := BaseName + '-Snapshot-' + FormatDateTime('yyyymmdd-hhnnss', Now) + '.lattice';
  if dlgSnapshotSave.Execute then
  begin
    if FileExists(dlgSnapshotSave.FileName) then SysUtils.DeleteFile(dlgSnapshotSave.FileName);
    try
      FServiceDatabase.SnapshotProject(dlgSnapshotSave.FileName);
      trnMain.StartTransaction;
      MessageDlg('Success', 'Project snapshot created successfully at:' + sLineBreak + dlgSnapshotSave.FileName, mtInformation, [mbOK], 0);
    except
      on E: Exception do
      begin
        if not trnMain.Active then trnMain.StartTransaction;
        MessageDlg('Snapshot Error', 'Failed to create snapshot: ' + E.Message, mtError, [mbOK], 0);
      end;
    end;
  end;
end;

procedure TfrmAppBase.mniProjectCloseClick(Sender: TObject);
begin
  if not conMain.Connected then Exit;
  if not ForceExitEditMode then Exit;
  if MessageDlg('Close Project', 'Are you sure you want to close the current project?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;
  FCurrentDocumentID := '';
  ReloadCurrentDocument;
  FControllerTreeDocument.LoadData(nil, '');
  FControllerTreeCode.LoadData(nil, '');
  vstAttribute.RootNodeCount := 0;
  SetLength(FCurrentDocumentAttribute, 0);
  FActiveCodeList.Clear;
  pbxLegendCodeName.Invalidate;
  if Assigned(stbMain) then
  begin
    stbMain.Panels[0].Text := '';
    if stbMain.Panels.Count > 1 then
      stbMain.Panels[1].Text := '';
  end;
  Self.Caption := 'Lattice';
  FServiceDatabase.CloseProject;
  UpdateCodeSystemMenu;
  Application.QueueAsyncCall(@ShowStartupDialog, 0);
end;

procedure TfrmAppBase.mniMemoProjectClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  TServiceMemo.Execute(conMain, 'Project', '', '');
end;

procedure TfrmAppBase.mniMemoAnalyticalClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  TServiceMemo.Execute(conMain, 'Analytical', '', '');
end;

procedure TfrmAppBase.mniMemoManageClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  frmModalMemo := TfrmModalMemo.Create(Self);
  try
    frmModalMemo.ShowModal;
  finally
    frmModalMemo.Free;
  end;
end;

procedure TfrmAppBase.mniRetrievalClick(Sender: TObject);
var
  SelectedDocumentID: String;
  SelectedTitle: String;
  SelectedNode: PVirtualNode;
begin
  if not conMain.Connected then Exit;
  if not ForceExitEditMode then Exit;
  frmModalRetrieve := TfrmModalRetrieve.Create(Self);
  try
    if frmModalRetrieve.ShowModal = mrOk then
    begin
      SelectedNode := frmModalRetrieve.vstResult.GetFirstSelected;
      if Assigned(SelectedNode) then
      begin
        SelectedTitle := frmModalRetrieve.vstResult.Text[SelectedNode, 0];
        qryCheck.Close;
        qryCheck.SQL.Text := 'SELECT id FROM documents WHERE title = :t';
        qryCheck.Params.ParamByName('t').AsString := SelectedTitle;
        qryCheck.Open;
        if not qryCheck.EOF then
        begin
          SelectedDocumentID := qryCheck.Fields[0].AsString;
          FControllerTreeDocument.RefreshTree(SelectedDocumentID, True);
          OnDocumentSelect(SelectedDocumentID);
        end;
        qryCheck.Close;
      end;
    end;
  finally
    frmModalRetrieve.Free;
  end;
end;

procedure TfrmAppBase.mniAnalysisClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  frmModalAnalyse := TfrmModalAnalyse.Create(Self);
  try
    frmModalAnalyse.ShowModal;
  finally
    frmModalAnalyse.Free;
  end;
end;

procedure TfrmAppBase.mniAttributeClick(Sender: TObject);
begin
  if not ForceExitEditMode then Exit;
  frmModalAttribute := TfrmModalAttribute.Create(Self);
  try
    frmModalAttribute.ShowModal;
  finally
    frmModalAttribute.Free;
  end;
  RefreshAttribute;
end;

procedure TfrmAppBase.mniHelpGuideClick(Sender: TObject);
begin
  TfrmDialogAbout.Execute(1);
end;

procedure TfrmAppBase.mniHelpWebsiteClick(Sender: TObject);
begin
  OpenURL(APP_URL);
end;

procedure TfrmAppBase.mniHelpSponsorClick(Sender: TObject);
begin
  OpenURL(DEV_SPONSOR);
end;

procedure TfrmAppBase.mniHelpLicenseClick(Sender: TObject);
begin
  TfrmDialogAbout.Execute(2);
end;

procedure TfrmAppBase.mniHelpThirdPartyClick(Sender: TObject);
begin
  TfrmDialogAbout.Execute(3);
end;

procedure TfrmAppBase.mniHelpAboutClick(Sender: TObject);
begin
  TfrmDialogAbout.Execute(0);
end;

end.

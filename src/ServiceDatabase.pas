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

unit ServiceDatabase;

{$mode objfpc}{$H+}

interface

uses
  Classes, Generics.Collections, Graphics, SysUtils, Types, SQLDB, SQLite3Conn,
  EngineText, ServiceThread;

type
  { Important: Database Configuration Interceptor }
  TSQLite3Connection = class(SQLite3Conn.TSQLite3Connection)
  protected
    procedure DoInternalConnect; override;
  public
    procedure ExecuteMaintenance;
  end;

  TDocumentCache = record
    ID: String;
    Title: String;
    CodingCount: Integer;
    HasMemo: Boolean;
  end;
  TDocumentCacheArray = array of TDocumentCache;

  TCodeFlatCache = record
    ID: String;
    Name: String;
    ParentID: String;
    Color: Integer;
    IsExpanded: Boolean;
    UsageCount: Integer;
    HasMemo: Boolean;
  end; 
  TCodeFlatArray = array of TCodeFlatCache;

  TDocumentFilterDefinition = record
    IsFilterActive: Boolean;
    QuickSearchText: String;
    TitlePattern: String;
    BodyTextQuery: String;
    AttributeSQL: String;
    AttributeID: String;
    AttributeOperator: String;
    AttributeValue: String;
  end;

  TFrequencyResult = record
    CodeID: String;
    CodeName: String;
    SegmentCount: Integer;
    DocumentCount: Integer;
  end;
  TFrequencyArray = array of TFrequencyResult;

  TCoOccurrenceResult = record
    Code1ID: String;
    Code2ID: String;
    Overlap: Integer;
  end;
  TCoOccurrenceArray = array of TCoOccurrenceResult;

  TCrosstabResult = record
    CodeID: String;
    CodeName: String;
    AttributeValue: String;
    Frequency: Integer;
  end;
  TCrosstabArray = array of TCrosstabResult;

  TCoverageResult = record
    DocumentID: String;
    DocumentName: String;
    TotalCharacters: Integer;
    CodedCharacters: Integer;
  end;
  TCoverageArray = array of TCoverageResult;

  TWordCloudResult = record
    Word: String;
    Frequency: Integer;
  end;
  TWordCloudArray = array of TWordCloudResult;

  TBatchAttrAction = (baaAdd, baaEdit, baaDelete);

  TThreadBatchDocumentDelete = class(TBackgroundWorker)
  public
    FDocumentID: TStringDynArray;
    FDeletedCount: Integer;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadBatchAttribute = class(TBackgroundWorker)
  public
    FAction: TBatchAttrAction;
    FDocumentID: TStringDynArray;
    FAttributeID: String;
    FValue: String;
    FUpdateOnlyExisting: Boolean;
    FAddedCount: Integer;
    FSkippedCount: Integer;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadBatchCodeDeleteRecursive = class(TBackgroundWorker)
  public
    FCodeID: String;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadBatchMergeCode = class(TBackgroundWorker)
  public
    FTargetID: String;
    FSourceID: TStringDynArray;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadLiveEditSave = class(TBackgroundWorker)
  public
    FDocumentID: String;
    FNewText: String;
    FCodings: TAnnotationShiftArray;
    FMemos: TAnnotationShiftArray;
  protected
    procedure DoHeavyLifting; override;
  end;

  TServiceDatabase = class
  private
    FConnection: TSQLite3Connection;
    FQuery: TSQLQuery;
    function BuildDocumentWhereClause(const Filter: TDocumentFilterDefinition): String;
    procedure EnsureSchema;
  public
    constructor Create(AConnection: TSQLite3Connection);
    destructor Destroy; override;
    function AddCoding(const DocumentID, CodeID: String; StartPos, Length: Integer; out ConflictMsg: String): Boolean;
    function CheckSpreadsheetTruncationRisk(const DocumentID: TStringDynArray): Boolean;
    function CodeExists(const AName: String; const ParentID: String; out ExistingID: String): Boolean;
    function CountDocumentsWithAttribute(const DocumentID: TStringDynArray; const ColumnName: String): Integer;
    function GetAllCodeFlat(const FilterText, SortField, SortOrder: String): TCodeFlatArray;
    function GetAttributeType(const AttributeName: String): String;
    function GetChronicleValue(const AKey, ADefault: String): String;
    function GetCodeName(const CodeID: String): String;
    function GetCodingAtPosition(const DocumentID: String; CharPos: Integer): String;
    function GetDocumentCount(const Filter: TDocumentFilterDefinition): Integer;
    function GetDocumentData(const Filter: TDocumentFilterDefinition; const SortField, SortOrder: String; SortIsAttr: Boolean): TDocumentCacheArray;
    function GetDocumentScopeID(const SelectedID: TStringDynArray; const Filter: TDocumentFilterDefinition): TStringDynArray;
    function GetUserPreference(const AKey, ADefault: String): String;
    function RunCoOccurrenceAnalysis(const CodeIDX, CodeIDY, DocumentID: TStringDynArray; const AttributeSQL: String; ALimit: Integer): TCoOccurrenceArray;
    function RunCoverageAnalysis(const DocumentID: TStringDynArray; const AttributeSQL: String; ALimit: Integer): TCoverageArray;
    function RunCrosstabAnalysis(const CodeID, DocumentID: TStringDynArray; const AttributeSQL: String; const AttributeKey: String): TCrosstabArray;
    function RunFrequencyAnalysis(const CodeID, DocumentID: TStringDynArray; const AttributeSQL: String; ALimit: Integer): TFrequencyArray;
    function RunWordCloudAnalysis(const CodeID, DocumentID: TStringDynArray; const AttributeSQL, StopWord: String; ALimit: Integer): TWordCloudArray;
    procedure AddCode(const AName, ADescription: String; AColor: TColor; const ParentID: String);
    procedure CloseProject;
    procedure DeleteCoding(const CodingID: String);
    procedure ExecuteSafe(const SQL: String);
    procedure GetAllAttributeName(List: TStrings);
    procedure GetAttributeDetails(const AttributeName: String; out AttributeID: String; out AttributeType: String);
    procedure GetCategoricalValue(const AttributeID: String; List: TStrings);
    procedure GetCommonAttributeName(const DocumentID: TStringDynArray; List: TStrings);
    procedure GetDashboardStatistic(out TotalDocument, CodedDocument, TotalCode, TotalCoding, TotalSegmentMemo: Integer);
    procedure GetRecursiveCount(const CodeID: String; out TotalCode, TotalCoding, TotalMemo: Integer);
    procedure InitializeProject;
    procedure LoadProjectData(const FilePath: String; out DocumentCache: TDocumentCacheArray; out CodeCache: TCodeFlatArray; out TotalDocument, CodedDocument, TotalCode, TotalCoding, TotalSegmentMemo: Integer);
    procedure MoveCode(const TargetID: String; const SourceID: TStringDynArray; DropMode: Integer);
    procedure OptimizeProject;
    procedure PersistAnalyticalSort(const SortField, SortOrder: String);
    procedure PopulateTempTable(const TableName: String; const IDArray: TStringDynArray);
    procedure SaveUserPreference(const AKey, AValue: String);
    procedure SetChronicleValue(const AKey, AValue: String);
    procedure SetCodeExpandedState(const CodeID: String; IsExpanded, Recursive: Boolean);
    procedure SnapshotProject(const TargetPath: String);
    procedure UpdateCodeColor(const CodeID: String; AColor: TColor);
    procedure UpdateCodeColorBatch(const CodeIDs: TStringDynArray; AColor: TColor);
    procedure UpdateCodeDetails(const CodeID: String; const AName, ADescription: String);
  end;

implementation

uses
  Character, DB, Dialogs, LazUTF8, Math, AppIdentity, DialogProgress, MonoLexID;

type
  TThreadOptimize = class(TBackgroundWorker)
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadSnapshot = class(TBackgroundWorker)
  private
    FTargetPath: String;
  protected
    procedure DoHeavyLifting; override;
  public
    constructor Create(const ADBPath, ATargetPath: String);
  end;

  TThreadLoadProject = class(TBackgroundWorker)
  public
    FDocumentCache: TDocumentCacheArray;
    FCodeCache: TCodeFlatArray;
    FTotalDocument, FCodedDocument, FTotalCode, FTotalCoding, FTotalSegmentMemo: Integer;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadFrequency = class(TBackgroundWorker)
  private
    FCodeID, FDocumentID: TStringDynArray;
    FAttributeSQL: String;
    FALimit: Integer;
    FResultArray: TFrequencyArray;
  protected
    procedure DoHeavyLifting; override;
  public
    constructor Create(const ADBPath: String; const ACodeID, ADocumentID: TStringDynArray; const AAttributeSQL: String; ALimit: Integer);
    property ResultArray: TFrequencyArray read FResultArray;
  end;

  TThreadCoOccurrence = class(TBackgroundWorker)
  private
    FCodeIDX, FCodeIDY, FDocumentID: TStringDynArray;
    FAttributeSQL: String;
    FALimit: Integer;
    FResultArray: TCoOccurrenceArray;
  protected
    procedure DoHeavyLifting; override;
  public
    constructor Create(const ADBPath: String; const ACodeIDX, ACodeIDY, ADocumentID: TStringDynArray; const AAttributeSQL: String; ALimit: Integer);
    property ResultArray: TCoOccurrenceArray read FResultArray;
  end;

  TThreadCrosstab = class(TBackgroundWorker)
  private
    FCodeID, FDocumentID: TStringDynArray;
    FAttributeSQL, FAttributeKey: String;
    FResultArray: TCrosstabArray;
  protected
    procedure DoHeavyLifting; override;
  public
    constructor Create(const ADBPath: String; const ACodeID, ADocumentID: TStringDynArray; const AAttributeSQL, AAttributeKey: String);
    property ResultArray: TCrosstabArray read FResultArray;
  end;

  TThreadCoverage = class(TBackgroundWorker)
  private
    FDocumentID: TStringDynArray;
    FAttributeSQL: String;
    FALimit: Integer;
    FResultArray: TCoverageArray;
  protected
    procedure DoHeavyLifting; override;
  public
    constructor Create(const ADBPath: String; const ADocumentID: TStringDynArray; const AAttributeSQL: String; ALimit: Integer);
    property ResultArray: TCoverageArray read FResultArray;
  end;

  TThreadWordCloud = class(TBackgroundWorker)
  private
    FCodeID, FDocumentID: TStringDynArray;
    FAttributeSQL, FStopWord: String;
    FALimit: Integer;
    FResultArray: TWordCloudArray;
  protected
    procedure DoHeavyLifting; override;
  public
    constructor Create(const ADBPath: String; const ACodeID, ADocumentID: TStringDynArray; const AAttributeSQL, AStopWord: String; ALimit: Integer);
    property ResultArray: TWordCloudArray read FResultArray;
  end;

procedure TSQLite3Connection.DoInternalConnect;
begin
  inherited DoInternalConnect;
  execsql('PRAGMA journal_mode=WAL;');
  execsql('PRAGMA foreign_keys=ON;');
  execsql('PRAGMA encoding = "UTF-8"');
end;

procedure TSQLite3Connection.ExecuteMaintenance;
begin
  execsql('PRAGMA wal_checkpoint(TRUNCATE);');
  execsql('INSERT INTO docs_fts(docs_fts) VALUES(''optimize'');');
  execsql('ANALYZE;');
  execsql('VACUUM;');
end;

constructor TServiceDatabase.Create(AConnection: TSQLite3Connection);
begin
  inherited Create;
  FConnection := AConnection;
  FQuery := TSQLQuery.Create(nil);
  FQuery.Database := FConnection;
end;

procedure TServiceDatabase.InitializeProject;
var
  CurrentSchema: Integer;
  IsNewProject: Boolean;
begin
  if not Assigned(FConnection) or not FConnection.Connected then Exit;
  FQuery.Transaction := FConnection.Transaction;
  FConnection.ExecuteDirect('CREATE TABLE IF NOT EXISTS chronicle (key TEXT PRIMARY KEY, value TEXT, updated_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')));');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS trg_chronicle_updated_at AFTER UPDATE OF value ON chronicle BEGIN UPDATE chronicle SET updated_at = STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'') WHERE key = OLD.key; END;');
  IsNewProject := GetChronicleValue('ProjectID', '') = '';
  if IsNewProject then
  begin
    EnsureSchema;
    SetChronicleValue('ProjectID', NewMonoLexID);
    SetChronicleValue('SchemaVersion', '1');
    SetChronicleValue('TriggerVersion', '1');
    SetChronicleValue('FTSVersion', '1');
    SetChronicleValue('CreatedByVersion', APP_VERSION);
  end
  else
  begin
    CurrentSchema := StrToIntDef(GetChronicleValue('SchemaVersion', '1'), 1);
    if CurrentSchema < 1 then
    begin
    end;
    EnsureSchema;
  end;
  SetChronicleValue('LastOpenedByVersion', APP_VERSION);
end;

procedure TServiceDatabase.EnsureSchema;
begin
  FConnection.ExecuteDirect('CREATE TABLE IF NOT EXISTS documents (id TEXT PRIMARY KEY, title TEXT, content TEXT, created_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')), updated_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')));');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS trg_documents_updated_at AFTER UPDATE OF title, content ON documents BEGIN UPDATE documents SET updated_at = STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'') WHERE id = OLD.id; END;');
  FConnection.ExecuteDirect('CREATE TABLE IF NOT EXISTS attribute_registry (id TEXT PRIMARY KEY, name TEXT UNIQUE, attribute_key TEXT UNIQUE, attribute_type TEXT, description TEXT, created_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')), updated_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')));');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS trg_attribute_registry_updated_at AFTER UPDATE OF name, attribute_type, description ON attribute_registry BEGIN UPDATE attribute_registry SET updated_at = STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'') WHERE id = OLD.id; END;');
  FConnection.ExecuteDirect('CREATE TABLE IF NOT EXISTS document_attributes (document_id TEXT PRIMARY KEY, attributes TEXT DEFAULT ''{}'', FOREIGN KEY(document_id) REFERENCES documents(id) ON DELETE CASCADE);');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS trg_doc_attr_auto_insert AFTER INSERT ON documents BEGIN INSERT INTO document_attributes (document_id, attributes) VALUES (NEW.id, ''{}''); END;');
  FConnection.ExecuteDirect('CREATE TABLE IF NOT EXISTS codes (id TEXT PRIMARY KEY, name TEXT, description TEXT, color INTEGER, parent_id TEXT DEFAULT '''', sort_order INTEGER DEFAULT 0, is_expanded BOOLEAN DEFAULT 0, created_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')), updated_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')));');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS trg_codes_updated_at AFTER UPDATE OF name, description, color, parent_id, sort_order, is_expanded ON codes BEGIN UPDATE codes SET updated_at = STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'') WHERE id = OLD.id; END;');
  FConnection.ExecuteDirect('CREATE TABLE IF NOT EXISTS codings (id TEXT PRIMARY KEY, document_id TEXT, code_id TEXT, start_position INTEGER, length INTEGER, created_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')), updated_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')), FOREIGN KEY(document_id) REFERENCES documents(id) ON DELETE CASCADE);');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS trg_codings_updated_at AFTER UPDATE OF code_id, start_position, length ON codings BEGIN UPDATE codings SET updated_at = STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'') WHERE id = OLD.id; END;');
  FConnection.ExecuteDirect('CREATE TABLE IF NOT EXISTS memos (id TEXT PRIMARY KEY, memo_type TEXT, reference TEXT DEFAULT '''', title TEXT, content TEXT, created_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')), updated_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')));');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS trg_memos_updated_at AFTER UPDATE OF title, content ON memos BEGIN UPDATE memos SET updated_at = STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'') WHERE id = OLD.id; END;');
  FConnection.ExecuteDirect('CREATE TABLE IF NOT EXISTS preferences (key TEXT PRIMARY KEY, value TEXT, created_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')), updated_at DATETIME NOT NULL DEFAULT (STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'')));');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS trg_preferences_updated_at AFTER UPDATE OF value ON preferences BEGIN UPDATE preferences SET updated_at = STRFTIME(''%Y-%m-%d %H:%M:%f'', ''now'') WHERE key = OLD.key; END;');
  FConnection.ExecuteDirect('CREATE INDEX IF NOT EXISTS idx_doc_titles ON documents(title);');
  FConnection.ExecuteDirect('CREATE INDEX IF NOT EXISTS idx_codings_doc_id ON codings(document_id);');
  FConnection.ExecuteDirect('CREATE INDEX IF NOT EXISTS idx_codes_parent_sort ON codes(parent_id, sort_order);');
  FConnection.ExecuteDirect('CREATE INDEX IF NOT EXISTS idx_memo_target ON memos(memo_type, reference);');
  FConnection.ExecuteDirect('CREATE VIRTUAL TABLE IF NOT EXISTS docs_fts USING fts5(title, content, content=''documents'', content_rowid=''rowid'');');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS docs_ai AFTER INSERT ON documents BEGIN INSERT INTO docs_fts(rowid, title, content) VALUES (new.rowid, new.title, new.content); END;');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS docs_ad AFTER DELETE ON documents BEGIN INSERT INTO docs_fts(docs_fts, rowid, title, content) VALUES(''delete'', old.rowid, old.title, old.content); END;');
  FConnection.ExecuteDirect('CREATE TRIGGER IF NOT EXISTS docs_au AFTER UPDATE OF title, content ON documents BEGIN INSERT INTO docs_fts(docs_fts, rowid, title, content) VALUES(''delete'', old.rowid, old.title, old.content); INSERT INTO docs_fts(rowid, title, content) VALUES (new.rowid, new.title, new.content); END;');
  FConnection.ExecuteDirect('INSERT OR IGNORE INTO preferences (key, value) VALUES (''DocumentSortField'', ''id'');');
  FConnection.ExecuteDirect('INSERT OR IGNORE INTO preferences (key, value) VALUES (''DocumentSortOrder'', ''ASC'');');
  FConnection.ExecuteDirect('INSERT OR IGNORE INTO preferences (key, value) VALUES (''DocumentSortCriteria'', ''Import Time'');');
end;

function TServiceDatabase.GetChronicleValue(const AKey, ADefault: String): String;
begin
  Result := ADefault;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT value FROM chronicle WHERE key = :k';
  FQuery.Params.ParamByName('k').AsString := AKey;
  FQuery.Open;
  if not FQuery.EOF then Result := FQuery.Fields[0].AsString;
  FQuery.Close;
end;

procedure TServiceDatabase.SetChronicleValue(const AKey, AValue: String);
begin
  ExecuteSafe('INSERT OR REPLACE INTO chronicle (key, value) VALUES (' + QuotedStr(AKey) + ', ' + QuotedStr(AValue) + ')');
end;

procedure TThreadLoadProject.DoHeavyLifting;
var
  LocalDB: TServiceDatabase;
  Q: TSQLQuery;
  SortField, SortOrder: String;
  SortIsAttr: Boolean;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    Q.SQL.Text := 'SELECT name FROM sqlite_master WHERE type=''table'' AND name=''documents''';
    Q.Open;
    if Q.EOF then raise Exception.Create('InvalidProject');
  finally
    Q.Free;
  end;
  LocalDB := TServiceDatabase.Create(TSQLite3Connection(FConnection));
  try
    SyncUpdateStatus('Verifying schema integrity...');
    LocalDB.InitializeProject;
    SyncUpdateStatus('Loading documents...');
    SortField := LocalDB.GetUserPreference('DocumentSortField', 'id');
    SortOrder := LocalDB.GetUserPreference('DocumentSortOrder', 'ASC');
    SortIsAttr := StrToBoolDef(LocalDB.GetUserPreference('DocumentSortIsAttribute', 'False'), False);
    FDocumentCache := LocalDB.GetDocumentData(Default(TDocumentFilterDefinition), SortField, SortOrder, SortIsAttr);
    SyncUpdateStatus('Loading code system...');
    FCodeCache := LocalDB.GetAllCodeFlat('', 'sort_order', 'ASC');
    SyncUpdateStatus('Calculating statistics...');
    LocalDB.GetDashboardStatistic(FTotalDocument, FCodedDocument, FTotalCode, FTotalCoding, FTotalSegmentMemo);
  finally
    LocalDB.Free;
  end;
end;

procedure TServiceDatabase.LoadProjectData(const FilePath: String; out DocumentCache: TDocumentCacheArray; out CodeCache: TCodeFlatArray; out TotalDocument, CodedDocument, TotalCode, TotalCoding, TotalSegmentMemo: Integer);
var
  Worker: TThreadLoadProject;
begin
  Worker := TThreadLoadProject.Create(FilePath);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Opening Project', 'Connecting to database...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      DocumentCache := Worker.FDocumentCache;
      CodeCache := Worker.FCodeCache;
      TotalDocument := Worker.FTotalDocument;
      CodedDocument := Worker.FCodedDocument;
      TotalCode := Worker.FTotalCode;
      TotalCoding := Worker.FTotalCoding;
      TotalSegmentMemo := Worker.FTotalSegmentMemo;
    end
    else
      raise Exception.Create(Worker.ErrorMessage);
  finally
    Worker.Free;
  end;
end;

procedure TServiceDatabase.GetDashboardStatistic(out TotalDocument, CodedDocument, TotalCode, TotalCoding, TotalSegmentMemo: Integer);
begin
  TotalDocument := 0; CodedDocument := 0; TotalCode := 0; TotalCoding := 0; TotalSegmentMemo := 0;
  if not FConnection.Connected then Exit;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT COUNT(*) FROM documents';
  FQuery.Open;
  TotalDocument := FQuery.Fields[0].AsInteger;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT COUNT(DISTINCT document_id) FROM codings';
  FQuery.Open;
  CodedDocument := FQuery.Fields[0].AsInteger;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT COUNT(*) FROM codes';
  FQuery.Open;
  TotalCode := FQuery.Fields[0].AsInteger;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT COUNT(*) FROM codings';
  FQuery.Open;
  TotalCoding := FQuery.Fields[0].AsInteger;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT COUNT(*) FROM memos WHERE memo_type = ''Segment''';
  FQuery.Open;
  TotalSegmentMemo := FQuery.Fields[0].AsInteger;
  FQuery.Close;
end;

procedure TServiceDatabase.CloseProject;
begin
  if not Assigned(FConnection) or not FConnection.Connected then Exit;
  if Assigned(FConnection.Transaction) and FConnection.Transaction.Active then
    FConnection.Transaction.Commit;
  try
    if not FConnection.Transaction.Active then
      FConnection.Transaction.StartTransaction;
    FConnection.ExecuteDirect('PRAGMA wal_checkpoint(TRUNCATE);');
    FConnection.Transaction.Commit;
  except
    if FConnection.Transaction.Active then
      FConnection.Transaction.Rollback;
  end;
  FConnection.Close;
end;

destructor TServiceDatabase.Destroy;
begin
  FQuery.Free;
  inherited Destroy;
end;

procedure TThreadOptimize.DoHeavyLifting;
begin
  SyncUpdateStatus('Rebuilding database indices...');
  if not FTransaction.Active then
    FTransaction.StartTransaction;
  FConnection.ExecuteDirect('COMMIT');
  FConnection.ExecuteDirect('VACUUM');
  FConnection.ExecuteDirect('BEGIN');
  SyncUpdateStatus('Optimising query planner...');
  FConnection.ExecuteDirect('PRAGMA optimize');
  FTransaction.Commit;
end;

procedure TServiceDatabase.OptimizeProject;
var
  Worker: TThreadOptimize;
begin
  if FConnection.Transaction.Active then FConnection.Transaction.Commit;
  Worker := TThreadOptimize.Create(FConnection.DatabaseName);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Optimising Project', 'Preparing database...');
    frmDialogProgress.ShowModal;
    if not Worker.Success then
      raise Exception.Create('Failed to optimise project: ' + Worker.ErrorMessage);
  finally
    Worker.Free;
  end;
end;

constructor TThreadSnapshot.Create(const ADBPath, ATargetPath: String);
begin
  inherited Create(ADBPath);
  FTargetPath := ATargetPath;
end;

procedure TThreadSnapshot.DoHeavyLifting;
begin
  SyncUpdateStatus('Creating project snapshot...');
  if not FTransaction.Active then
    FTransaction.StartTransaction;
  FConnection.ExecuteDirect('COMMIT');
  FConnection.ExecuteDirect('VACUUM INTO ' + QuotedStr(FTargetPath) + ';');
  FConnection.ExecuteDirect('BEGIN');
end;

procedure TServiceDatabase.SnapshotProject(const TargetPath: String);
var
  Worker: TThreadSnapshot;
begin
  if FConnection.Transaction.Active then FConnection.Transaction.Commit;
  Worker := TThreadSnapshot.Create(FConnection.DatabaseName, TargetPath);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Snapshotting Project', 'Initialising...');
    frmDialogProgress.ShowModal;
    if not Worker.Success then
      raise Exception.Create(Worker.ErrorMessage);
  finally
    Worker.Free;
  end;
end;

procedure TServiceDatabase.ExecuteSafe(const SQL: String);
begin
  if FConnection.Transaction.Active then FConnection.Transaction.Commit;
  FQuery.Close;
  FQuery.SQL.Text := SQL;
  try
    FQuery.ExecSQL;
    FConnection.Transaction.Commit;
  except
    FConnection.Transaction.Rollback;
    raise;
  end;
end;

procedure TServiceDatabase.PopulateTempTable(const TableName: String; const IDArray: TStringDynArray);
var
  i: Integer;
begin
  ExecuteSafe('DROP TABLE IF EXISTS ' + TableName);
  ExecuteSafe('CREATE TEMP TABLE ' + TableName + ' (id TEXT PRIMARY KEY)');
  if Length(IDArray) = 0 then Exit;
  if not FConnection.Transaction.Active then FConnection.Transaction.StartTransaction;
  try
    FQuery.Close;
    FQuery.SQL.Text := 'INSERT INTO ' + TableName + ' (id) VALUES (:id)';
    FQuery.Prepare;
    for i := Low(IDArray) to High(IDArray) do
    begin
      FQuery.Params[0].AsString := IDArray[i];
      FQuery.ExecSQL;
    end;
    FConnection.Transaction.Commit;
  except
    FConnection.Transaction.Rollback;
    raise;
  end;
end;

procedure TThreadBatchDocumentDelete.DoHeavyLifting;
var
  i: Integer;
  Q: TSQLQuery;
begin
  FDeletedCount := Length(FDocumentID);
  if FDeletedCount = 0 then Exit;
  SyncUpdateStatus('Preparing batch scope...');
  FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_batch_docs');
  FConnection.ExecuteDirect('CREATE TEMP TABLE temp_batch_docs (id TEXT PRIMARY KEY)');
  if not FTransaction.Active then FTransaction.StartTransaction;
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    Q.SQL.Text := 'INSERT INTO temp_batch_docs (id) VALUES (:id)';
    Q.Prepare;
    for i := Low(FDocumentID) to High(FDocumentID) do
    begin
      Q.Params[0].AsString := FDocumentID[i];
      Q.ExecSQL;
    end;
  finally
    Q.Free;
  end;
  SyncUpdateStatus('Removing associated segment memos...');
  FConnection.ExecuteDirect('DELETE FROM memos WHERE memo_type = ''Segment'' AND SUBSTR(reference, 1, INSTR(reference, '':'') - 1) IN (SELECT id FROM temp_batch_docs)');
  SyncUpdateStatus('Removing associated document memos...');
  FConnection.ExecuteDirect('DELETE FROM memos WHERE memo_type = ''Document'' AND reference IN (SELECT id FROM temp_batch_docs)');
  SyncUpdateStatus('Removing document attributes...');
  FConnection.ExecuteDirect('DELETE FROM document_attributes WHERE document_id IN (SELECT id FROM temp_batch_docs)');
  SyncUpdateStatus('Removing coding applications...');
  FConnection.ExecuteDirect('DELETE FROM codings WHERE document_id IN (SELECT id FROM temp_batch_docs)');
  SyncUpdateStatus('Deleting document records...');
  FConnection.ExecuteDirect('DELETE FROM documents WHERE id IN (SELECT id FROM temp_batch_docs)');
  SyncUpdateStatus('Finalising transaction...');
  FTransaction.Commit;
end;

function TServiceDatabase.BuildDocumentWhereClause(const Filter: TDocumentFilterDefinition): String;
var
  WhereStr, TitleSQL: String;
begin
  WhereStr := '';
  if Filter.QuickSearchText <> '' then
  begin
    WhereStr := WhereStr + ' AND d.title LIKE ' + QuotedStr('%' + Filter.QuickSearchText + '%');
  end;
  if Filter.IsFilterActive then
  begin
    if Filter.TitlePattern <> '' then
    begin
      TitleSQL := Filter.TitlePattern;
      TitleSQL := StringReplace(TitleSQL, '*', '%', [rfReplaceAll]);
      TitleSQL := StringReplace(TitleSQL, '?', '_', [rfReplaceAll]);
      if (Pos('%', TitleSQL) = 0) and (Pos('_', TitleSQL) = 0) then
        TitleSQL := '%' + TitleSQL + '%';
      WhereStr := WhereStr + ' AND d.title LIKE ' + QuotedStr(TitleSQL);
    end;
    if Filter.BodyTextQuery <> '' then
      WhereStr := WhereStr + ' AND d.rowid IN (SELECT rowid FROM docs_fts WHERE docs_fts MATCH ' + QuotedStr(Filter.BodyTextQuery) + ')';
    if Filter.AttributeSQL <> '' then
      WhereStr := WhereStr + Filter.AttributeSQL;
  end;
  if WhereStr <> '' then
  begin
    Delete(WhereStr, 1, 4);
    Result := ' WHERE ' + WhereStr;
  end
  else
    Result := '';
end;

function TServiceDatabase.GetDocumentCount(const Filter: TDocumentFilterDefinition): Integer;
var
  JoinSQL: String;
begin
  Result := 0;
  if Pos('da.', Filter.AttributeSQL) > 0 then
    JoinSQL := ' LEFT JOIN document_attributes da ON da.document_id = d.id'
  else
    JoinSQL := '';
  try
    FQuery.Close;
    FQuery.SQL.Text := 'SELECT COUNT(*) FROM documents d' + JoinSQL + BuildDocumentWhereClause(Filter);
    FQuery.Open;
    Result := FQuery.Fields[0].AsInteger;
    FQuery.Close;
  except
  end;
end;

function TServiceDatabase.GetDocumentData(const Filter: TDocumentFilterDefinition; const SortField, SortOrder: String; SortIsAttr: Boolean): TDocumentCacheArray;
var
  WhereSQL, OrderSQL, ColumnName, JoinSQL: String;
  Capacity, Count: Integer;
  fId, fTitle, fCC, fHasMemo: TField;
  Q: TSQLQuery;
begin
  Result := nil;
  WhereSQL := BuildDocumentWhereClause(Filter);
  if SortIsAttr then
  begin
    FQuery.Close;
    FQuery.SQL.Text := 'SELECT attribute_key FROM attribute_registry WHERE name = :n LIMIT 1';
    FQuery.Params.ParamByName('n').AsString := SortField;
    FQuery.Open;
    if not FQuery.EOF then ColumnName := FQuery.Fields[0].AsString else ColumnName := '';
    FQuery.Close;
    if ColumnName <> '' then
      OrderSQL := ' ORDER BY json_extract(da.attributes, ''$.' + ColumnName + ''') ' + SortOrder + ' NULLS LAST, d.id ASC'
    else
      OrderSQL := ' ORDER BY d.id ASC';
  end
  else if SortField = 'cc' then
    OrderSQL := ' ORDER BY cc ' + SortOrder + ', d.id ASC'
  else if SortField = 'mc' then
    OrderSQL := ' ORDER BY mc ' + SortOrder + ', d.id ASC'
  else if SameText(SortField, 'id') then
    OrderSQL := ' ORDER BY d.id ' + SortOrder
  else
    OrderSQL := ' ORDER BY d.' + SortField + ' ' + SortOrder + ', d.id ASC';
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FQuery.Database;
    Q.Transaction := FQuery.Transaction;
    Q.UniDirectional := True;
    JoinSQL := '';
    if Pos('da.', WhereSQL) > 0 then
      JoinSQL := ' LEFT JOIN document_attributes da ON da.document_id = d.id';
    try
      Q.SQL.Text := 'SELECT COUNT(d.id) FROM documents d' + JoinSQL + WhereSQL;
      Q.Open;
      Capacity := Q.Fields[0].AsInteger;
      Q.Close;
    except
      SetLength(Result, 0);
      Exit;
    end;
    if Capacity < 128 then Capacity := 128;
    SetLength(Result, Capacity);
    try
      Q.SQL.Text := 
        'WITH coding_counts AS (SELECT document_id, COUNT(id) as cc FROM codings GROUP BY document_id), ' +
        'doc_memos AS (SELECT reference as document_id, 1 as has_memo FROM memos WHERE memo_type = ''Document'' GROUP BY reference), ' +
        'seg_memos AS (SELECT SUBSTR(reference, 1, INSTR(reference, '':'') - 1) as document_id, COUNT(id) as mc FROM memos WHERE memo_type = ''Segment'' GROUP BY SUBSTR(reference, 1, INSTR(reference, '':'') - 1)) ' +
        'SELECT d.id, d.title, ' +
        'COALESCE(c.cc, 0) as cc, ' +
        'COALESCE(sm.mc, 0) as mc, ' +
        'COALESCE(dm.has_memo, 0) as has_memo ' +
        'FROM documents d ' +
        'LEFT JOIN document_attributes da ON da.document_id = d.id ' +
        'LEFT JOIN coding_counts c ON c.document_id = d.id ' +
        'LEFT JOIN doc_memos dm ON dm.document_id = d.id ' +
        'LEFT JOIN seg_memos sm ON sm.document_id = d.id' + 
        WhereSQL + OrderSQL;
      Q.Open;
      Count := 0;
      fId := Q.FieldByName('id');
      fTitle := Q.FieldByName('title');
      fCC := Q.FieldByName('cc');
      fHasMemo := Q.FieldByName('has_memo');
      while not Q.EOF do
      begin
        if Count >= Capacity then
        begin
          Capacity := Capacity * 2;
          SetLength(Result, Capacity);
        end;
        Result[Count].ID := fId.AsString;
        Result[Count].Title := fTitle.AsString;
        Result[Count].CodingCount := fCC.AsInteger;
        Result[Count].HasMemo := fHasMemo.AsInteger > 0;
        Inc(Count);
        Q.Next;
      end;
      SetLength(Result, Count);
    except
      SetLength(Result, 0);
      Exit;
    end;
  finally
    Q.Free;
  end;
end;

function TServiceDatabase.GetDocumentScopeID(const SelectedID: TStringDynArray; const Filter: TDocumentFilterDefinition): TStringDynArray;
var
  Count, Capacity: Integer;
  WhereSQL: String;
begin
  if Length(SelectedID) > 0 then Exit(SelectedID);
  Result := nil;
  WhereSQL := BuildDocumentWhereClause(Filter);
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT id FROM documents d ' + WhereSQL;
  FQuery.Open;
  Capacity := 1024;
  SetLength(Result, Capacity);
  Count := 0;
  while not FQuery.EOF do
  begin
    if Count >= Capacity then
    begin
      Capacity := Capacity * 2;
      SetLength(Result, Capacity);
    end;
    Result[Count] := FQuery.Fields[0].AsString;
    Inc(Count);
    FQuery.Next;
  end;
  SetLength(Result, Count);
  FQuery.Close;
end;

function TServiceDatabase.CheckSpreadsheetTruncationRisk(const DocumentID: TStringDynArray): Boolean;
var
  i: Integer;
begin
  Result := False;
  if Length(DocumentID) = 0 then Exit;
  PopulateTempTable('temp_truncation_check', DocumentID);
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT MAX(LENGTH(content)) FROM documents WHERE id IN (SELECT id FROM temp_truncation_check)';
  FQuery.Open;
  if not FQuery.EOF then
  begin
    if FQuery.Fields[0].AsInteger > 32700 then
      Result := True;
  end;
  FQuery.Close;
end;

function TServiceDatabase.GetAllCodeFlat(const FilterText, SortField, SortOrder: String): TCodeFlatArray;
var
  Capacity, Count: Integer;
  Q: TSQLQuery;
  fId, fName, fParent, fColor, fExpanded, fUsage, fMemo: TField;
  OrderClause: String;
begin
  Result := nil;
  if SortField = 'sort_order' then
    OrderClause := 'ORDER BY c.parent_id ASC, c.sort_order ASC, c.id ASC'
  else if SortField = 'usage_cnt' then
    OrderClause := 'ORDER BY COALESCE(cu.cum_cnt, 0) ' + SortOrder + ', c.name ASC'
  else
    OrderClause := 'ORDER BY c.name ' + SortOrder;
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FQuery.Database;
    Q.Transaction := FQuery.Transaction;
    Q.UniDirectional := True;
    if FilterText = '' then
    begin
      Q.SQL.Text :=
        'WITH RECURSIVE descendant_map(ancestor_id, descendant_id) AS ( ' +
        '  SELECT id, id FROM codes ' +
        '  UNION ALL ' +
        '  SELECT d.ancestor_id, ch.id FROM descendant_map d JOIN codes ch ON ch.parent_id = d.descendant_id ' +
        '), ' +
        'cumulative_usage AS ( ' +
        '  SELECT d.ancestor_id as code_id, COUNT(co.id) as cum_cnt ' +
        '  FROM descendant_map d JOIN codings co ON co.code_id = d.descendant_id ' +
        '  GROUP BY d.ancestor_id ' +
        '), ' +
        'code_usage AS (SELECT code_id, COUNT(id) as cnt FROM codings GROUP BY code_id), ' +
        'code_memos AS (SELECT reference, 1 as has_m FROM memos WHERE memo_type = ''Code'' GROUP BY reference) ' +
        'SELECT c.id, c.name, c.parent_id, c.color, COALESCE(c.is_expanded, 0) as is_expanded, ' +
        'COALESCE(u.cnt, 0) as usage_cnt, ' +
        'COALESCE(m.has_m, 0) as has_memo ' +
        'FROM codes c ' +
        'LEFT JOIN code_usage u ON u.code_id = c.id ' +
        'LEFT JOIN cumulative_usage cu ON cu.code_id = c.id ' +
        'LEFT JOIN code_memos m ON m.reference = c.id ' +
        OrderClause;
    end
    else
    begin
      Q.SQL.Text :=
        'WITH RECURSIVE search_matches AS (SELECT id FROM codes WHERE name LIKE :f), ' +
        'visible_nodes(id) AS (SELECT id FROM codes WHERE id IN search_matches UNION SELECT p.parent_id FROM codes p JOIN visible_nodes v ON p.id = v.id WHERE p.parent_id <> ''''), ' +
        'descendant_map(ancestor_id, descendant_id) AS ( ' +
        '  SELECT id, id FROM codes ' +
        '  UNION ALL ' +
        '  SELECT d.ancestor_id, ch.id FROM descendant_map d JOIN codes ch ON ch.parent_id = d.descendant_id ' +
        '), ' +
        'cumulative_usage AS ( ' +
        '  SELECT d.ancestor_id as code_id, COUNT(co.id) as cum_cnt ' +
        '  FROM descendant_map d JOIN codings co ON co.code_id = d.descendant_id ' +
        '  GROUP BY d.ancestor_id ' +
        '), ' +
        'code_usage AS (SELECT code_id, COUNT(id) as cnt FROM codings GROUP BY code_id), ' +
        'code_memos AS (SELECT reference, 1 as has_m FROM memos WHERE memo_type = ''Code'' GROUP BY reference) ' +
        'SELECT c.id, c.name, c.parent_id, c.color, COALESCE(c.is_expanded, 0) as is_expanded, ' +
        'COALESCE(u.cnt, 0) as usage_cnt, ' +
        'COALESCE(m.has_m, 0) as has_memo ' +
        'FROM codes c ' +
        'LEFT JOIN code_usage u ON u.code_id = c.id ' +
        'LEFT JOIN cumulative_usage cu ON cu.code_id = c.id ' +
        'LEFT JOIN code_memos m ON m.reference = c.id ' +
        'WHERE c.id IN visible_nodes ' + OrderClause;
      Q.Params.ParamByName('f').AsString := '%' + FilterText + '%';
    end;
    Q.Open;
    Capacity := 4096;
    SetLength(Result, Capacity);
    Count := 0;
    fId := Q.FieldByName('id');
    fName := Q.FieldByName('name');
    fParent := Q.FieldByName('parent_id');
    fColor := Q.FieldByName('color');
    fExpanded := Q.FieldByName('is_expanded');
    fUsage := Q.FieldByName('usage_cnt');
    fMemo := Q.FieldByName('has_memo');
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(Result, Capacity);
      end;
      Result[Count].ID := fId.AsString;
      Result[Count].Name := fName.AsString;
      Result[Count].ParentID := fParent.AsString;
      Result[Count].Color := fColor.AsInteger;
      Result[Count].IsExpanded := fExpanded.AsInteger > 0;
      Result[Count].UsageCount := fUsage.AsInteger;
      Result[Count].HasMemo := fMemo.AsInteger > 0;
      Inc(Count);
      Q.Next;
    end;
    SetLength(Result, Count);
  finally
    Q.Free;
  end;
end;

function TServiceDatabase.GetCodeName(const CodeID: String): String;
begin
  Result := '';
  if CodeID = '' then Exit;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT name FROM codes WHERE id = :id';
  FQuery.Params.ParamByName('id').AsString := CodeID;
  FQuery.Open;
  if not FQuery.EOF then Result := FQuery.FieldByName('name').AsString;
  FQuery.Close;
end;

function TServiceDatabase.CodeExists(const AName: String; const ParentID: String; out ExistingID: String): Boolean;
begin
  Result := False;
  ExistingID := '';
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT id FROM codes WHERE LOWER(name) = LOWER(:n) AND parent_id = :p';
  FQuery.Params.ParamByName('n').AsString := Trim(AName);
  FQuery.Params.ParamByName('p').AsString := ParentID;
  FQuery.Open;
  if not FQuery.EOF then
  begin
    ExistingID := FQuery.FieldByName('id').AsString;
    Result := True;
  end;
  FQuery.Close;
end;

procedure TServiceDatabase.AddCode(const AName, ADescription: String; AColor: TColor; const ParentID: String);
var
  MaxSort: Integer;
begin
  if not FConnection.Transaction.Active then FConnection.Transaction.StartTransaction;
  try
    FQuery.Close;
    FQuery.SQL.Text := 'SELECT COALESCE(MAX(sort_order), 0) FROM codes WHERE parent_id = :p';
    FQuery.Params.ParamByName('p').AsString := ParentID;
    FQuery.Open;
    MaxSort := FQuery.Fields[0].AsInteger + 10;
    FQuery.Close;
    FQuery.SQL.Text := 'INSERT INTO codes (id, name, description, color, parent_id, sort_order) VALUES (:g, :n, :d, :c, :p, :s)';
    FQuery.Params.ParamByName('g').AsString := NewMonoLexID;
    FQuery.Params.ParamByName('n').AsString := Trim(AName);
    FQuery.Params.ParamByName('d').AsString := Trim(ADescription);
    FQuery.Params.ParamByName('c').AsInteger := Integer(AColor);
    FQuery.Params.ParamByName('p').AsString := ParentID;
    FQuery.Params.ParamByName('s').AsInteger := MaxSort;
    FQuery.ExecSQL;
    FConnection.Transaction.Commit;
  except
    FConnection.Transaction.Rollback;
    raise;
  end;
end;

procedure TServiceDatabase.UpdateCodeColor(const CodeID: String; AColor: TColor);
begin
  ExecuteSafe('UPDATE codes SET color = ' + IntToStr(Integer(AColor)) + ' WHERE id = ' + QuotedStr(CodeID));
end;

procedure TServiceDatabase.UpdateCodeColorBatch(const CodeIDs: TStringDynArray; AColor: TColor);
begin
  if Length(CodeIDs) = 0 then Exit;
  PopulateTempTable('temp_color_update', CodeIDs);
  ExecuteSafe('UPDATE codes SET color = ' + IntToStr(Integer(AColor)) + ' WHERE id IN (SELECT id FROM temp_color_update)');
end;

procedure TServiceDatabase.UpdateCodeDetails(const CodeID: String; const AName, ADescription: String);
begin
  if not FConnection.Transaction.Active then FConnection.Transaction.StartTransaction;
  try
    FQuery.Close;
    FQuery.SQL.Text := 'UPDATE codes SET name = :n, description = :d WHERE id = :id';
    FQuery.Params.ParamByName('n').AsString := Trim(AName);
    FQuery.Params.ParamByName('d').AsString := Trim(ADescription);
    FQuery.Params.ParamByName('id').AsString := CodeID;
    FQuery.ExecSQL;
    FQuery.SQL.Text := 'UPDATE memos SET title = :mt WHERE memo_type = ''Code'' AND reference = :tid';
    FQuery.Params.ParamByName('mt').AsString := 'Code Memo · ' + Trim(AName);
    FQuery.Params.ParamByName('tid').AsString := CodeID;
    FQuery.ExecSQL;
    FConnection.Transaction.Commit;
  except
    FConnection.Transaction.Rollback;
    raise;
  end;
end;

procedure TServiceDatabase.GetRecursiveCount(const CodeID: String; out TotalCode, TotalCoding, TotalMemo: Integer);
begin
  TotalCode := 0; TotalCoding := 0; TotalMemo := 0;
  FQuery.Close;
  FQuery.SQL.Text :=
    'WITH RECURSIVE descendant_codes(id) AS ( ' +
    '  SELECT :root_id UNION ALL SELECT codes.id FROM codes ' +
    '  JOIN descendant_codes ON codes.parent_id = descendant_codes.id ' +
    ') SELECT ' +
    '  (SELECT COUNT(*) FROM descendant_codes) as code_count, ' +
    '  (SELECT COUNT(*) FROM codings WHERE code_id IN descendant_codes) as coding_count, ' +
    '  (SELECT COUNT(*) FROM memos WHERE memo_type = ''Code'' AND reference IN descendant_codes) as memo_count';
  FQuery.Params.ParamByName('root_id').AsString := CodeID;
  FQuery.Open;
  if not FQuery.EOF then
  begin
    TotalCode := FQuery.FieldByName('code_count').AsInteger;
    TotalCoding := FQuery.FieldByName('coding_count').AsInteger;
    TotalMemo := FQuery.FieldByName('memo_count').AsInteger;
  end;
  FQuery.Close;
end;

procedure TServiceDatabase.SetCodeExpandedState(const CodeID: String; IsExpanded, Recursive: Boolean);
var
  ExpVal: Integer;
begin
  if IsExpanded then ExpVal := 1 else ExpVal := 0;
  if Recursive then
  begin
    if not FConnection.Transaction.Active then FConnection.Transaction.StartTransaction;
    try
      if CodeID = '' then
        FQuery.SQL.Text := 'UPDATE codes SET is_expanded = ' + IntToStr(ExpVal)
      else
      begin
        FQuery.SQL.Text := 'WITH RECURSIVE descendants(id) AS ( SELECT :root UNION ALL ' +
                           'SELECT c.id FROM codes c JOIN descendants d ON c.parent_id = d.id ) ' +
                           'UPDATE codes SET is_expanded = ' + IntToStr(ExpVal) + ' WHERE id IN descendants';
        FQuery.Params.ParamByName('root').AsString := CodeID;
      end;
      FQuery.ExecSQL;
      FConnection.Transaction.Commit;
    except
      FConnection.Transaction.Rollback;
    end;
  end
  else
    ExecuteSafe('UPDATE codes SET is_expanded = ' + IntToStr(ExpVal) + ' WHERE id = ' + QuotedStr(CodeID));
end;

procedure TServiceDatabase.MoveCode(const TargetID: String; const SourceID: TStringDynArray; DropMode: Integer);
var
  i: Integer;
  TargetParent: String;
  TargetOrder, Counter: Integer;
begin
  if Length(SourceID) = 0 then Exit;
  if not FConnection.Transaction.Active then FConnection.Transaction.StartTransaction;
  try
    if DropMode = 0 then
    begin
      FQuery.Close;
      FQuery.SQL.Text := 'SELECT COALESCE(MAX(sort_order), 0) FROM codes WHERE parent_id = :p';
      FQuery.Params.ParamByName('p').AsString := TargetID;
      FQuery.Open;
      Counter := FQuery.Fields[0].AsInteger + 10;
      FQuery.Close;
      FQuery.SQL.Text := 'UPDATE codes SET parent_id = :tid, sort_order = :s WHERE id = :sid';
      for i := Low(SourceID) to High(SourceID) do
      begin
        FQuery.Params.ParamByName('tid').AsString := TargetID;
        FQuery.Params.ParamByName('sid').AsString := SourceID[i];
        FQuery.Params.ParamByName('s').AsInteger := Counter;
        FQuery.ExecSQL;
        Inc(Counter, 10);
      end;
    end
    else
    begin
      FQuery.Close;
      if TargetID = '' then
      begin
        TargetParent := '';
        TargetOrder := 0;
      end
      else
      begin
        FQuery.SQL.Text := 'SELECT parent_id, sort_order FROM codes WHERE id = :tid';
        FQuery.Params.ParamByName('tid').AsString := TargetID;
        FQuery.Open;
        TargetParent := FQuery.FieldByName('parent_id').AsString;
        TargetOrder := FQuery.FieldByName('sort_order').AsInteger;
        FQuery.Close;
      end;
      FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_source_codes');
      FConnection.ExecuteDirect('CREATE TEMP TABLE temp_source_codes (id TEXT PRIMARY KEY)');
      FQuery.SQL.Text := 'INSERT INTO temp_source_codes (id) VALUES (:id)';
      for i := Low(SourceID) to High(SourceID) do
      begin
        FQuery.Params.ParamByName('id').AsString := SourceID[i];
        FQuery.ExecSQL;
      end;
      FQuery.SQL.Text := 'UPDATE codes SET parent_id = :p WHERE id IN (SELECT id FROM temp_source_codes)';
      FQuery.Params.ParamByName('p').AsString := TargetParent;
      FQuery.ExecSQL;
      FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_ordered_siblings');
      FConnection.ExecuteDirect('CREATE TEMP TABLE temp_ordered_siblings (seq INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT)');
      if DropMode = 1 then
      begin
        FQuery.SQL.Text := 
          'INSERT INTO temp_ordered_siblings (id) ' +
          'SELECT id FROM codes WHERE parent_id = :p AND id NOT IN (SELECT id FROM temp_source_codes) AND (sort_order < :so OR (sort_order = :so AND id < :tid)) ORDER BY sort_order ASC, id ASC';
      end
      else
      begin
        FQuery.SQL.Text := 
          'INSERT INTO temp_ordered_siblings (id) ' +
          'SELECT id FROM codes WHERE parent_id = :p AND id NOT IN (SELECT id FROM temp_source_codes) AND (sort_order <= :so OR (sort_order = :so AND id <= :tid)) ORDER BY sort_order ASC, id ASC';
      end;
      FQuery.Params.ParamByName('p').AsString := TargetParent;
      FQuery.Params.ParamByName('so').AsInteger := TargetOrder;
      FQuery.Params.ParamByName('tid').AsString := TargetID;
      FQuery.ExecSQL;
      FConnection.ExecuteDirect('INSERT INTO temp_ordered_siblings (id) SELECT id FROM temp_source_codes');
      if DropMode = 1 then
      begin
        FQuery.SQL.Text := 
          'INSERT INTO temp_ordered_siblings (id) ' +
          'SELECT id FROM codes WHERE parent_id = :p AND id NOT IN (SELECT id FROM temp_source_codes) AND (sort_order > :so OR (sort_order = :so AND id >= :tid)) ORDER BY sort_order ASC, id ASC';
      end
      else
      begin
        FQuery.SQL.Text := 
          'INSERT INTO temp_ordered_siblings (id) ' +
          'SELECT id FROM codes WHERE parent_id = :p AND id NOT IN (SELECT id FROM temp_source_codes) AND (sort_order > :so OR (sort_order = :so AND id > :tid)) ORDER BY sort_order ASC, id ASC';
      end;
      FQuery.Params.ParamByName('p').AsString := TargetParent;
      FQuery.Params.ParamByName('so').AsInteger := TargetOrder;
      FQuery.Params.ParamByName('tid').AsString := TargetID;
      FQuery.ExecSQL;
      FConnection.ExecuteDirect('UPDATE codes SET sort_order = (SELECT seq * 10 FROM temp_ordered_siblings WHERE temp_ordered_siblings.id = codes.id) WHERE parent_id = ' + QuotedStr(TargetParent));
    end;
    FConnection.Transaction.Commit;
  except
    FConnection.Transaction.Rollback;
    raise;
  end;
end;

procedure TServiceDatabase.PersistAnalyticalSort(const SortField, SortOrder: String);
var
  OrderClause: String;
begin
  if not FConnection.Transaction.Active then FConnection.Transaction.StartTransaction;
  try
    if SortField = 'usage_cnt' then
      OrderClause := 'ORDER BY COALESCE(cu.cum_cnt, 0) ' + SortOrder + ', c.name ASC'
    else if SortField = 'created_at' then
      OrderClause := 'ORDER BY c.created_at ' + SortOrder + ', c.id ASC'
    else
      OrderClause := 'ORDER BY c.name ' + SortOrder;
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_sort_persist');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_sort_persist (id TEXT PRIMARY KEY, seq INTEGER)');
    FConnection.ExecuteDirect(
      'WITH RECURSIVE descendant_map(ancestor_id, descendant_id) AS ( ' +
      '  SELECT id, id FROM codes ' +
      '  UNION ALL ' +
      '  SELECT d.ancestor_id, ch.id FROM descendant_map d JOIN codes ch ON ch.parent_id = d.descendant_id ' +
      '), ' +
      'cumulative_usage AS ( ' +
      '  SELECT d.ancestor_id as code_id, COUNT(co.id) as cum_cnt ' +
      '  FROM descendant_map d JOIN codings co ON co.code_id = d.descendant_id ' +
      '  GROUP BY d.ancestor_id ' +
      ') ' +
      'INSERT INTO temp_sort_persist (id, seq) ' +
      'SELECT c.id, ROW_NUMBER() OVER (PARTITION BY c.parent_id ' + OrderClause + ') * 10 ' +
      'FROM codes c ' +
      'LEFT JOIN cumulative_usage cu ON cu.code_id = c.id'
    );
    FConnection.ExecuteDirect('UPDATE codes SET sort_order = (SELECT seq FROM temp_sort_persist WHERE temp_sort_persist.id = codes.id)');
    FConnection.Transaction.Commit;
  except
    FConnection.Transaction.Rollback;
    raise;
  end;
end;

procedure TThreadBatchCodeDeleteRecursive.DoHeavyLifting;
var
  Q: TSQLQuery;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    if not FTransaction.Active then FTransaction.StartTransaction;
    SyncUpdateStatus('Identifying code hierarchy...');
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_del_codes');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_del_codes (id TEXT PRIMARY KEY)');
    Q.SQL.Text := 
      'INSERT INTO temp_del_codes (id) ' +
      'WITH RECURSIVE descendants(id) AS ( SELECT :root_id UNION ALL ' +
      'SELECT codes.id FROM codes JOIN descendants ON codes.parent_id = descendants.id ) ' +
      'SELECT id FROM descendants';
    Q.Params.ParamByName('root_id').AsString := FCodeID;
    Q.ExecSQL;
    SyncUpdateStatus('Removing associated code memos...');
    FConnection.ExecuteDirect('DELETE FROM memos WHERE memo_type = ''Code'' AND reference IN (SELECT id FROM temp_del_codes)');
    SyncUpdateStatus('Removing coding applications...');
    FConnection.ExecuteDirect('DELETE FROM codings WHERE code_id IN (SELECT id FROM temp_del_codes)');
    SyncUpdateStatus('Deleting codes...');
    FConnection.ExecuteDirect('DELETE FROM codes WHERE id IN (SELECT id FROM temp_del_codes)');
    SyncUpdateStatus('Finalising transaction...');
    FTransaction.Commit;
  finally
    Q.Free;
  end;
end;

procedure TThreadBatchMergeCode.DoHeavyLifting;
var
  i: Integer;
  Q: TSQLQuery;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    if not FTransaction.Active then FTransaction.StartTransaction;
    for i := Low(FSourceID) to High(FSourceID) do
    begin
      SyncUpdateStatus('Merging code ' + IntToStr(i + 1) + ' of ' + IntToStr(Length(FSourceID)) + '...');
      Q.Close;
      Q.SQL.Text := 'UPDATE codings SET code_id = :tid WHERE code_id = :sid';
      Q.Params.ParamByName('tid').AsString := FTargetID;
      Q.Params.ParamByName('sid').AsString := FSourceID[i];
      Q.ExecSQL;
      Q.SQL.Text := 'UPDATE codes SET parent_id = :tid WHERE parent_id = :sid';
      Q.Params.ParamByName('tid').AsString := FTargetID;
      Q.Params.ParamByName('sid').AsString := FSourceID[i];
      Q.ExecSQL;
      Q.SQL.Text := 'UPDATE codes SET name = name || '' (Merged)'' ' +
                   'WHERE parent_id = :tid AND id IN ( SELECT c1.id FROM codes c1 ' +
                   'JOIN codes c2 ON c1.parent_id = c2.parent_id AND c1.name = c2.name AND c1.id > c2.id ' +
                   'WHERE c1.parent_id = :tid )';
      Q.Params.ParamByName('tid').AsString := FTargetID;
      Q.ExecSQL;
      Q.SQL.Text := 'DELETE FROM codes WHERE id = :sid';
      Q.Params.ParamByName('sid').AsString := FSourceID[i];
      Q.ExecSQL;
    end;
    SyncUpdateStatus('Cleaning up duplicate codings...');
    Q.SQL.Text := 'DELETE FROM codings WHERE id IN ( SELECT c2.id FROM codings c1 ' +
                  'JOIN codings c2 ON c1.document_id = c2.document_id AND c1.code_id = c2.code_id AND c1.id < c2.id ' +
                  'WHERE NOT (c1.start_position + c1.length <= c2.start_position OR c2.start_position + c2.length <= c1.start_position) )';
    Q.ExecSQL;
    SyncUpdateStatus('Finalising transaction...');
    FTransaction.Commit;
  finally
    Q.Free;
  end;
end;

function TServiceDatabase.AddCoding(const DocumentID, CodeID: String; StartPos, Length: Integer; out ConflictMsg: String): Boolean;
var
  EndPos: Integer;
begin
  Result := False;
  ConflictMsg := '';
  EndPos := StartPos + Length;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT id FROM codings WHERE document_id = :d AND code_id = :c AND NOT (:e <= start_position OR :s >= (start_position + length)) LIMIT 1';
  FQuery.Params.ParamByName('d').AsString := DocumentID;
  FQuery.Params.ParamByName('c').AsString := CodeID;
  FQuery.Params.ParamByName('s').AsInteger := StartPos;
  FQuery.Params.ParamByName('e').AsInteger := EndPos;
  FQuery.Open;
  if not FQuery.EOF then
  begin
    FQuery.Close;
    Exit;
  end;
  FQuery.Close;
  if not FConnection.Transaction.Active then FConnection.Transaction.StartTransaction;
  try
    FQuery.SQL.Text := 'INSERT INTO codings (id, document_id, code_id, start_position, length) VALUES (:g, :d, :c, :s, :l)';
    FQuery.Params.ParamByName('g').AsString := NewMonoLexID;
    FQuery.Params.ParamByName('d').AsString := DocumentID;
    FQuery.Params.ParamByName('c').AsString := CodeID;
    FQuery.Params.ParamByName('s').AsInteger := StartPos;
    FQuery.Params.ParamByName('l').AsInteger := Length;
    FQuery.ExecSQL;
    FConnection.Transaction.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      FConnection.Transaction.Rollback;
      ConflictMsg := E.Message;
    end;
  end;
end;

procedure TServiceDatabase.DeleteCoding(const CodingID: String);
begin
  ExecuteSafe('DELETE FROM codings WHERE id = ' + QuotedStr(CodingID));
end;

function TServiceDatabase.GetCodingAtPosition(const DocumentID: String; CharPos: Integer): String;
begin
  Result := '';
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT id FROM codings WHERE document_id = :d AND :p >= start_position AND :p < (start_position + length) LIMIT 1';
  FQuery.Params.ParamByName('d').AsString := DocumentID;
  FQuery.Params.ParamByName('p').AsInteger := CharPos;
  FQuery.Open;
  if not FQuery.EOF then Result := FQuery.Fields[0].AsString;
  FQuery.Close;
end;

procedure TThreadLiveEditSave.DoHeavyLifting;
var
  i: Integer;
  DocTitle: String;
  Q: TSQLQuery;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    if not FTransaction.Active then FTransaction.StartTransaction;
    SyncUpdateStatus('Preparing to save document...');
    Q.SQL.Text := 'SELECT title FROM documents WHERE id = :did';
    Q.Params.ParamByName('did').AsString := FDocumentID;
    Q.Open;
    if not Q.EOF then DocTitle := Q.Fields[0].AsString else DocTitle := 'Document';
    Q.Close;
    SyncUpdateStatus('Writing document text...');
    Q.SQL.Text := 'UPDATE documents SET content = :b WHERE id = :did';
    Q.Params.ParamByName('b').AsString := FNewText;
    Q.Params.ParamByName('did').AsString := FDocumentID;
    Q.ExecSQL;
    SyncUpdateStatus('Synchronising code brackets...');
    for i := 0 to High(FCodings) do
    begin
      if FCodings[i].NewLength <= 0 then
      begin
        Q.SQL.Text := 'DELETE FROM codings WHERE id = :id';
        Q.Params.ParamByName('id').AsString := FCodings[i].ID;
      end
      else
      begin
        Q.SQL.Text := 'UPDATE codings SET start_position = :s, length = :l WHERE id = :id';
        Q.Params.ParamByName('id').AsString := FCodings[i].ID;
        Q.Params.ParamByName('s').AsInteger := FCodings[i].NewStart;
        Q.Params.ParamByName('l').AsInteger := FCodings[i].NewLength;
      end;
      Q.ExecSQL;
    end;
    SyncUpdateStatus('Synchronising segment memos...');
    for i := 0 to High(FMemos) do
    begin
      if FMemos[i].NewLength <= 0 then
      begin
        Q.SQL.Text := 'DELETE FROM memos WHERE memo_type = ''Segment'' AND reference = :old_ref';
        Q.Params.ParamByName('old_ref').AsString := FMemos[i].ID; 
      end
      else
      begin
        Q.SQL.Text := 'UPDATE memos SET reference = :ref, title = :title WHERE memo_type = ''Segment'' AND reference = :old_ref';
        Q.Params.ParamByName('old_ref').AsString := FMemos[i].ID; 
        Q.Params.ParamByName('ref').AsString := FDocumentID + ':' + IntToStr(FMemos[i].NewStart) + ':' + IntToStr(FMemos[i].NewLength);
        Q.Params.ParamByName('title').AsString := 'Segment Memo · ' + DocTitle + ' · ' + IntToStr(FMemos[i].NewStart) + '–' + IntToStr(FMemos[i].NewStart + FMemos[i].NewLength);
      end;
      Q.ExecSQL;
    end;
    SyncUpdateStatus('Finalising transaction...');
    FTransaction.Commit;
  finally
    Q.Free;
  end;
end;

function TServiceDatabase.GetAttributeType(const AttributeName: String): String;
begin
  Result := 'Text';
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT attribute_type FROM attribute_registry WHERE name = :n';
  FQuery.Params.ParamByName('n').AsString := AttributeName;
  FQuery.Open;
  if not FQuery.EOF then Result := FQuery.Fields[0].AsString;
  FQuery.Close;
end;

procedure TServiceDatabase.GetAllAttributeName(List: TStrings);
begin
  List.Clear;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT name FROM attribute_registry ORDER BY name ASC';
  FQuery.Open;
  while not FQuery.EOF do
  begin
    List.Add(FQuery.FieldByName('name').AsString);
    FQuery.Next;
  end;
  FQuery.Close;
end;

procedure TServiceDatabase.GetCommonAttributeName(const DocumentID: TStringDynArray; List: TStrings);
begin
  List.Clear;
  if Length(DocumentID) = 0 then Exit;
  PopulateTempTable('temp_common_docs', DocumentID);
  FQuery.Close;
  FQuery.SQL.Text := 
    'SELECT DISTINCT ar.name ' +
    'FROM attribute_registry ar ' +
    'JOIN document_attributes da ON da.document_id IN (SELECT id FROM temp_common_docs) ' +
    'JOIN json_each(da.attributes) je ON je.key = ar.attribute_key ' +
    'WHERE je.value IS NOT NULL AND CAST(je.value AS TEXT) <> '''' ' +
    'ORDER BY ar.name ASC';
  FQuery.Open;
  while not FQuery.EOF do
  begin
    List.Add(FQuery.Fields[0].AsString);
    FQuery.Next;
  end;
  FQuery.Close;
end;

procedure TServiceDatabase.GetAttributeDetails(const AttributeName: String; out AttributeID: String; out AttributeType: String);
begin
  AttributeID := '';
  AttributeType := '';
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT id, attribute_type FROM attribute_registry WHERE name = :n';
  FQuery.Params.ParamByName('n').AsString := AttributeName;
  FQuery.Open;
  if not FQuery.EOF then
  begin
    AttributeID := FQuery.FieldByName('id').AsString;
    AttributeType := FQuery.FieldByName('attribute_type').AsString;
  end;
  FQuery.Close;
end;

procedure TServiceDatabase.GetCategoricalValue(const AttributeID: String; List: TStrings);
var
  ColumnName: String;
begin
  List.Clear;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT attribute_key FROM attribute_registry WHERE id = :id';
  FQuery.Params.ParamByName('id').AsString := AttributeID;
  FQuery.Open;
  if not FQuery.EOF then ColumnName := FQuery.Fields[0].AsString else ColumnName := '';
  FQuery.Close;
  if ColumnName = '' then Exit;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT DISTINCT json_extract(attributes, ''$.'' || :col) FROM document_attributes WHERE json_extract(attributes, ''$.'' || :col) IS NOT NULL AND CAST(json_extract(attributes, ''$.'' || :col) AS TEXT) <> "" ORDER BY json_extract(attributes, ''$.'' || :col)';
  FQuery.Params.ParamByName('col').AsString := ColumnName;
  FQuery.Open;
  while not FQuery.EOF do
  begin
    List.Add(FQuery.Fields[0].AsString);
    FQuery.Next;
  end;
  FQuery.Close;
end;

function TServiceDatabase.CountDocumentsWithAttribute(const DocumentID: TStringDynArray; const ColumnName: String): Integer;
begin
  Result := 0;
  if Length(DocumentID) = 0 then Exit;
  PopulateTempTable('temp_attr_count_docs', DocumentID);
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT COUNT(*) FROM document_attributes WHERE document_id IN (SELECT id FROM temp_attr_count_docs) AND json_extract(attributes, ''$.'' || :col) IS NOT NULL AND CAST(json_extract(attributes, ''$.'' || :col) AS TEXT) <> ''''';
  FQuery.Params.ParamByName('col').AsString := ColumnName;
  FQuery.Open;
  if not FQuery.EOF then Result := FQuery.Fields[0].AsInteger;
  FQuery.Close;
end;

procedure TThreadBatchAttribute.DoHeavyLifting;
var
  i: Integer;
  Q: TSQLQuery;
  ColumnName, AttributeType, JsonExpr: String;
begin
  FAddedCount := 0;
  FSkippedCount := 0;
  if Length(FDocumentID) = 0 then Exit;
  SyncUpdateStatus('Fetching attribute metadata...');
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    Q.SQL.Text := 'SELECT attribute_key, attribute_type FROM attribute_registry WHERE id = :id';
    Q.Params.ParamByName('id').AsString := FAttributeID;
    Q.Open;
    if not Q.EOF then
    begin
      ColumnName := Q.Fields[0].AsString;
      AttributeType := Q.Fields[1].AsString;
    end
    else
    begin
      ColumnName := '';
      AttributeType := '';
    end;
    Q.Close;
    if ColumnName = '' then Exit;
    SyncUpdateStatus('Preparing scope...');
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_batch_attr_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_batch_attr_docs (id TEXT PRIMARY KEY)');
    if not FTransaction.Active then FTransaction.StartTransaction;
    Q.SQL.Text := 'INSERT INTO temp_batch_attr_docs (id) VALUES (:id)';
    Q.Prepare;
    for i := Low(FDocumentID) to High(FDocumentID) do
    begin
      Q.Params[0].AsString := FDocumentID[i];
      Q.ExecSQL;
    end;
    if AttributeType = 'Numeric' then
      JsonExpr := 'CAST(:v AS REAL)'
    else
      JsonExpr := ':v';
    case FAction of
      baaAdd:
        begin
          SyncUpdateStatus('Applying attributes to documents...');
          Q.SQL.Text := 'UPDATE document_attributes SET attributes = json_set(attributes, ''$.'' || :col, ' + JsonExpr + ') ' +
                        'WHERE document_id IN (SELECT id FROM temp_batch_attr_docs) AND (json_extract(attributes, ''$.'' || :col) IS NULL OR CAST(json_extract(attributes, ''$.'' || :col) AS TEXT) = '''')';
          Q.Params.ParamByName('col').AsString := ColumnName;
          Q.Params.ParamByName('v').AsString := Trim(FValue);
          Q.ExecSQL;
          FAddedCount := Q.RowsAffected;
          FSkippedCount := Length(FDocumentID) - FAddedCount;
        end;
      baaEdit:
        begin
          SyncUpdateStatus('Modifying attribute values...');
          if FUpdateOnlyExisting then
          begin
            Q.SQL.Text := 'UPDATE document_attributes SET attributes = json_set(attributes, ''$.'' || :col, ' + JsonExpr + ') ' +
                          'WHERE document_id IN (SELECT id FROM temp_batch_attr_docs) AND json_extract(attributes, ''$.'' || :col) IS NOT NULL AND CAST(json_extract(attributes, ''$.'' || :col) AS TEXT) <> ''''';
          end
          else
          begin
            Q.SQL.Text := 'UPDATE document_attributes SET attributes = json_set(attributes, ''$.'' || :col, ' + JsonExpr + ') ' +
                          'WHERE document_id IN (SELECT id FROM temp_batch_attr_docs)';
          end;
          Q.Params.ParamByName('col').AsString := ColumnName;
          Q.Params.ParamByName('v').AsString := Trim(FValue);
          Q.ExecSQL;
          FAddedCount := Q.RowsAffected;
        end;
      baaDelete:
        begin
          SyncUpdateStatus('Removing attributes from documents...');
          Q.SQL.Text := 'UPDATE document_attributes SET attributes = json_remove(attributes, ''$.'' || :col) ' +
                        'WHERE document_id IN (SELECT id FROM temp_batch_attr_docs) AND json_extract(attributes, ''$.'' || :col) IS NOT NULL AND CAST(json_extract(attributes, ''$.'' || :col) AS TEXT) <> ''''';
          Q.Params.ParamByName('col').AsString := ColumnName;
          Q.ExecSQL;
          FAddedCount := Q.RowsAffected;
        end;
    end;
    SyncUpdateStatus('Finalising transaction...');
    FTransaction.Commit;
  finally
    Q.Free;
  end;
end;

constructor TThreadFrequency.Create(const ADBPath: String; const ACodeID, ADocumentID: TStringDynArray; const AAttributeSQL: String; ALimit: Integer);
begin
  inherited Create(ADBPath);
  FCodeID := ACodeID;
  FDocumentID := ADocumentID;
  FAttributeSQL := AAttributeSQL;
  FALimit := ALimit;
  SetLength(FResultArray, 0);
end;

procedure TThreadFrequency.DoHeavyLifting;
var
  Q: TSQLQuery;
  Count, Capacity, i: Integer;
  ScopeJoin: String;
begin
  SyncUpdateStatus('Preparing...');
  FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_codes');
  FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_codes (id TEXT PRIMARY KEY)');
  if Length(FCodeID) > 0 then
  begin
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_codes (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FCodeID) to High(FCodeID) do
      begin
        Q.Params[0].AsString := FCodeID[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
  end;
  ScopeJoin := '';
  if Length(FDocumentID) > 0 then
  begin
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_scope_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_scope_docs (id TEXT PRIMARY KEY)');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_scope_docs (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FDocumentID) to High(FDocumentID) do
      begin
        Q.Params[0].AsString := FDocumentID[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
    ScopeJoin := ' JOIN temp_analyse_scope_docs tsd ON co.document_id = tsd.id ';
  end;
  if FAttributeSQL <> '' then
    ScopeJoin := ScopeJoin + ' LEFT JOIN document_attributes da ON co.document_id = da.document_id ';
  SyncUpdateStatus('Processing frequencies...');
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    Q.SQL.Text :=
      'SELECT c.id, c.name, COUNT(co.id) as seg_count, COUNT(DISTINCT co.document_id) as doc_count ' +
      'FROM codes c JOIN temp_analyse_codes tc ON c.id = tc.id ' +
      'LEFT JOIN codings co ON c.id = co.code_id ' +
      ScopeJoin +
      'WHERE 1=1 ' + FAttributeSQL + ' ' +
      'GROUP BY c.id, c.name ORDER BY seg_count DESC, c.name ASC';
    if FALimit > 0 then
      Q.SQL.Text := Q.SQL.Text + ' LIMIT ' + IntToStr(FALimit);
    Q.Open;
    SyncUpdateStatus('Finalising visualisation...');
    Capacity := 1024;
    SetLength(FResultArray, Capacity);
    Count := 0;
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FResultArray, Capacity);
      end;
      FResultArray[Count].CodeID := Q.FieldByName('id').AsString;
      FResultArray[Count].CodeName := Q.FieldByName('name').AsString;
      FResultArray[Count].SegmentCount := Q.FieldByName('seg_count').AsInteger;
      FResultArray[Count].DocumentCount := Q.FieldByName('doc_count').AsInteger;
      Inc(Count);
      Q.Next;
    end;
    SetLength(FResultArray, Count);
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TServiceDatabase.RunFrequencyAnalysis(const CodeID, DocumentID: TStringDynArray; const AttributeSQL: String; ALimit: Integer): TFrequencyArray;
var
  Worker: TThreadFrequency;
begin
  SetLength(Result, 0);
  if FConnection.Transaction.Active then FConnection.Transaction.Commit;
  Worker := TThreadFrequency.Create(FConnection.DatabaseName, CodeID, DocumentID, AttributeSQL, ALimit);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Analysing Data', 'Initialising...');
    frmDialogProgress.ShowModal;
    if not Worker.Success then
      raise Exception.Create('Analysis failed: ' + Worker.ErrorMessage);
    Result := Worker.ResultArray;
  finally
    Worker.Free;
  end;
end;

constructor TThreadCoOccurrence.Create(const ADBPath: String; const ACodeIDX, ACodeIDY, ADocumentID: TStringDynArray; const AAttributeSQL: String; ALimit: Integer);
begin
  inherited Create(ADBPath);
  FCodeIDX := ACodeIDX;
  FCodeIDY := ACodeIDY;
  FDocumentID := ADocumentID;
  FAttributeSQL := AAttributeSQL;
  FALimit := ALimit;
  SetLength(FResultArray, 0);
end;

procedure TThreadCoOccurrence.DoHeavyLifting;
var
  Q: TSQLQuery;
  Count, Capacity, i: Integer;
  ScopeJoin, ScopeWhere: String;
begin
  SyncUpdateStatus('Preparing analyser...');
  FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_codes_x');
  FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_codes_x (id TEXT PRIMARY KEY)');
  FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_codes_y');
  FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_codes_y (id TEXT PRIMARY KEY)');
  if Length(FCodeIDX) > 0 then
  begin
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_codes_x (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FCodeIDX) to High(FCodeIDX) do
      begin
        Q.Params[0].AsString := FCodeIDX[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
  end;
  if Length(FCodeIDY) > 0 then
  begin
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_codes_y (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FCodeIDY) to High(FCodeIDY) do
      begin
        Q.Params[0].AsString := FCodeIDY[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
  end;
  ScopeJoin := '';
  if Length(FDocumentID) > 0 then
  begin
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_scope_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_scope_docs (id TEXT PRIMARY KEY)');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_scope_docs (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FDocumentID) to High(FDocumentID) do
      begin
        Q.Params[0].AsString := FDocumentID[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
    ScopeJoin := ' JOIN temp_analyse_scope_docs tsd ON c1.document_id = tsd.id ';
  end;
  if FAttributeSQL <> '' then
    ScopeJoin := ScopeJoin + ' LEFT JOIN document_attributes da ON c1.document_id = da.document_id ';
  ScopeWhere := FAttributeSQL;
  SyncUpdateStatus('Processing overlaps...');
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    if FALimit > 0 then
    begin
      Q.SQL.Text := 
        'WITH top_codes AS ( ' +
        '  SELECT c1.code_id, COUNT(*) as total_overlap ' +
        '  FROM codings c1 ' +
        '  JOIN codings c2 ON c1.document_id = c2.document_id AND c1.id <> c2.id ' +
        '  JOIN temp_analyse_codes_x tx ON c1.code_id = tx.id ' +
        '  JOIN temp_analyse_codes_y ty ON c2.code_id = ty.id ' +
        ScopeJoin +
        '  WHERE NOT (c1.start_position + c1.length <= c2.start_position OR c2.start_position + c2.length <= c1.start_position) ' + ScopeWhere +
        '  GROUP BY c1.code_id ' +
        '  ORDER BY total_overlap DESC ' +
        '  LIMIT :limit ' +
        ') ' +
        'SELECT c1.code_id AS code1, c2.code_id AS code2, COUNT(*) AS overlap ' +
        'FROM codings c1 ' +
        'JOIN codings c2 ON c1.document_id = c2.document_id AND c1.id <> c2.id ' +
        'JOIN top_codes t1 ON c1.code_id = t1.code_id ' +
        'JOIN temp_analyse_codes_y ty ON c2.code_id = ty.id ' +
        ScopeJoin +
        'WHERE NOT (c1.start_position + c1.length <= c2.start_position OR c2.start_position + c2.length <= c1.start_position) ' + ScopeWhere +
        'GROUP BY c1.code_id, c2.code_id';
      Q.Params.ParamByName('limit').AsInteger := FALimit;
    end
    else
    begin
      Q.SQL.Text := 
        'SELECT c1.code_id AS code1, c2.code_id AS code2, COUNT(*) AS overlap ' +
        'FROM codings c1 ' +
        'JOIN codings c2 ON c1.document_id = c2.document_id AND c1.id <> c2.id ' +
        'JOIN temp_analyse_codes_x tx ON c1.code_id = tx.id ' +
        'JOIN temp_analyse_codes_y ty ON c2.code_id = ty.id ' +
        ScopeJoin +
        'WHERE NOT (c1.start_position + c1.length <= c2.start_position OR c2.start_position + c2.length <= c1.start_position) ' + ScopeWhere +
        'GROUP BY c1.code_id, c2.code_id';
    end;
    Q.Open;
    SyncUpdateStatus('Finalising visualisation...');
    Capacity := 1024;
    SetLength(FResultArray, Capacity);
    Count := 0;
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FResultArray, Capacity);
      end;
      FResultArray[Count].Code1ID := Q.FieldByName('code1').AsString;
      FResultArray[Count].Code2ID := Q.FieldByName('code2').AsString;
      FResultArray[Count].Overlap := Q.FieldByName('overlap').AsInteger;
      Inc(Count);
      Q.Next;
    end;
    SetLength(FResultArray, Count);
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TServiceDatabase.RunCoOccurrenceAnalysis(const CodeIDX, CodeIDY, DocumentID: TStringDynArray; const AttributeSQL: String; ALimit: Integer): TCoOccurrenceArray;
var
  Worker: TThreadCoOccurrence;
begin
  SetLength(Result, 0);
  if FConnection.Transaction.Active then FConnection.Transaction.Commit;
  Worker := TThreadCoOccurrence.Create(FConnection.DatabaseName, CodeIDX, CodeIDY, DocumentID, AttributeSQL, ALimit);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Analysing Data', 'Initialising...');
    frmDialogProgress.ShowModal;
    if not Worker.Success then
      raise Exception.Create('Analysis failed: ' + Worker.ErrorMessage);
    Result := Worker.ResultArray;
  finally
    Worker.Free;
  end;
end;

constructor TThreadCrosstab.Create(const ADBPath: String; const ACodeID, ADocumentID: TStringDynArray; const AAttributeSQL, AAttributeKey: String);
begin
  inherited Create(ADBPath);
  FCodeID := ACodeID;
  FDocumentID := ADocumentID;
  FAttributeSQL := AAttributeSQL;
  FAttributeKey := AAttributeKey;
  SetLength(FResultArray, 0);
end;

procedure TThreadCrosstab.DoHeavyLifting;
var
  Q: TSQLQuery;
  Count, Capacity, i: Integer;
  ScopeJoin: String;
begin
  SyncUpdateStatus('Preparing...');
  FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_codes');
  FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_codes (id TEXT PRIMARY KEY)');
  if Length(FCodeID) > 0 then
  begin
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_codes (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FCodeID) to High(FCodeID) do
      begin
        Q.Params[0].AsString := FCodeID[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
  end;
  ScopeJoin := '';
  if Length(FDocumentID) > 0 then
  begin
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_scope_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_scope_docs (id TEXT PRIMARY KEY)');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_scope_docs (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FDocumentID) to High(FDocumentID) do
      begin
        Q.Params[0].AsString := FDocumentID[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
    ScopeJoin := ' JOIN temp_analyse_scope_docs tsd ON co.document_id = tsd.id ';
  end;
  ScopeJoin := ScopeJoin + ' LEFT JOIN document_attributes da ON co.document_id = da.document_id ';
  SyncUpdateStatus('Processing matrix variables...');
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    Q.SQL.Text := 
      'SELECT c.id, c.name, COALESCE(NULLIF(CAST(json_extract(da.attributes, ''$.' + FAttributeKey + ''') AS TEXT), ''''), ''(Unassigned)'') as attr_val, COUNT(co.id) as freq ' +
      'FROM codings co ' +
      'JOIN codes c ON co.code_id = c.id ' +
      'JOIN temp_analyse_codes tc ON c.id = tc.id ' +
      ScopeJoin +
      'WHERE 1=1 ' + FAttributeSQL + ' ' +
      'GROUP BY c.id, c.name, attr_val ORDER BY c.name ASC, attr_val ASC';
    Q.Open;
    SyncUpdateStatus('Finalising visualisation...');
    Capacity := 1024;
    SetLength(FResultArray, Capacity);
    Count := 0;
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FResultArray, Capacity);
      end;
      FResultArray[Count].CodeID := Q.FieldByName('id').AsString;
      FResultArray[Count].CodeName := Q.FieldByName('name').AsString;
      FResultArray[Count].AttributeValue := Q.FieldByName('attr_val').AsString;
      FResultArray[Count].Frequency := Q.FieldByName('freq').AsInteger;
      Inc(Count);
      Q.Next;
    end;
    SetLength(FResultArray, Count);
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TServiceDatabase.RunCrosstabAnalysis(const CodeID, DocumentID: TStringDynArray; const AttributeSQL: String; const AttributeKey: String): TCrosstabArray;
var
  Worker: TThreadCrosstab;
begin
  SetLength(Result, 0);
  if FConnection.Transaction.Active then FConnection.Transaction.Commit;
  Worker := TThreadCrosstab.Create(FConnection.DatabaseName, CodeID, DocumentID, AttributeSQL, AttributeKey);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Analysing Data', 'Initialising...');
    frmDialogProgress.ShowModal;
    if not Worker.Success then
      raise Exception.Create('Analysis failed: ' + Worker.ErrorMessage);
    Result := Worker.ResultArray;
  finally
    Worker.Free;
  end;
end;

constructor TThreadCoverage.Create(const ADBPath: String; const ADocumentID: TStringDynArray; const AAttributeSQL: String; ALimit: Integer);
begin
  inherited Create(ADBPath);
  FDocumentID := ADocumentID;
  FAttributeSQL := AAttributeSQL;
  FALimit := ALimit;
  SetLength(FResultArray, 0);
end;

procedure TThreadCoverage.DoHeavyLifting;
var
  DocumentIndexMap: specialize TDictionary<String, Integer>;
  Count, Capacity, i, j, CurStart, CurEnd, CodedLen: Integer;
  ScopeJoin, CurrentDocumentID, NextDocumentID: String;
  TempRes: TCoverageResult;
  HasActiveInterval: Boolean;
  PctI, PctJ: Double;
  Q: TSQLQuery;
begin
  SyncUpdateStatus('Preparing analyser...');
  ScopeJoin := '';
  if Length(FDocumentID) > 0 then
  begin
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_docs (id TEXT PRIMARY KEY)');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_docs (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FDocumentID) to High(FDocumentID) do
      begin
        Q.Params[0].AsString := FDocumentID[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
    ScopeJoin := ' JOIN temp_analyse_docs td ON d.id = td.id ';
  end;
  if FAttributeSQL <> '' then
    ScopeJoin := ScopeJoin + ' LEFT JOIN document_attributes da ON d.id = da.document_id ';
  SyncUpdateStatus('Processing document boundaries...');
  DocumentIndexMap := specialize TDictionary<String, Integer>.Create;
  Q := TSQLQuery.Create(nil);
  try
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    Q.SQL.Text := 'SELECT d.id, d.title, LENGTH(d.content) as doc_len FROM documents d ' + ScopeJoin + ' WHERE 1=1 ' + FAttributeSQL;
    Q.Open;
    Capacity := Max(128, Q.RecordCount);
    SetLength(FResultArray, Capacity);
    Count := 0;
    while not Q.EOF do
    begin
      if Count >= Capacity then
      begin
        Capacity := Capacity * 2;
        SetLength(FResultArray, Capacity);
      end;
      FResultArray[Count].DocumentID := Q.FieldByName('id').AsString;
      FResultArray[Count].DocumentName := Q.FieldByName('title').AsString;
      FResultArray[Count].TotalCharacters := Q.FieldByName('doc_len').AsInteger;
      FResultArray[Count].CodedCharacters := 0;
      DocumentIndexMap.Add(LowerCase(Trim(FResultArray[Count].DocumentID)), Count);
      Inc(Count);
      Q.Next;
    end;
    Q.Close;
    SetLength(FResultArray, Count);
    if Count = 0 then Exit;
    SyncUpdateStatus('Processing interval calculations...');
    if Length(FDocumentID) > 0 then
      Q.SQL.Text := 'SELECT document_id, start_position, length FROM codings WHERE document_id IN (SELECT id FROM temp_analyse_docs) ORDER BY document_id ASC, start_position ASC'
    else
      Q.SQL.Text := 'SELECT document_id, start_position, length FROM codings ORDER BY document_id ASC, start_position ASC';
    Q.Open;
    CurrentDocumentID := '';
    CodedLen := 0;
    HasActiveInterval := False;
    CurStart := 0;
    CurEnd := 0;
    while not Q.EOF do
    begin
      NextDocumentID := Q.FieldByName('document_id').AsString;
      if (CurrentDocumentID <> '') and (CurrentDocumentID <> NextDocumentID) then
      begin
        if HasActiveInterval then CodedLen := CodedLen + (CurEnd - CurStart);
        if DocumentIndexMap.TryGetValue(LowerCase(Trim(CurrentDocumentID)), i) then
          FResultArray[i].CodedCharacters := CodedLen;
        CodedLen := 0;
        HasActiveInterval := False;
      end;
      CurrentDocumentID := NextDocumentID;
      if not HasActiveInterval then
      begin
        CurStart := Q.FieldByName('start_position').AsInteger;
        CurEnd := CurStart + Q.FieldByName('length').AsInteger;
        HasActiveInterval := True;
      end
      else
      begin
        if Q.FieldByName('start_position').AsInteger <= CurEnd then
          CurEnd := Max(CurEnd, Q.FieldByName('start_position').AsInteger + Q.FieldByName('length').AsInteger)
        else
        begin
          CodedLen := CodedLen + (CurEnd - CurStart);
          CurStart := Q.FieldByName('start_position').AsInteger;
          CurEnd := CurStart + Q.FieldByName('length').AsInteger;
        end;
      end;
      Q.Next;
    end;
    if (CurrentDocumentID <> '') and HasActiveInterval then
    begin
      CodedLen := CodedLen + (CurEnd - CurStart);
      if DocumentIndexMap.TryGetValue(LowerCase(Trim(CurrentDocumentID)), i) then
        FResultArray[i].CodedCharacters := CodedLen;
    end;
    Q.Close;
    SyncUpdateStatus('Finalising visualisation...');
    for i := 0 to Count - 2 do
    begin
      for j := i + 1 to Count - 1 do
      begin
        if FResultArray[i].TotalCharacters > 0 then
          PctI := FResultArray[i].CodedCharacters / FResultArray[i].TotalCharacters
        else
          PctI := 0.0;
        if FResultArray[j].TotalCharacters > 0 then
          PctJ := FResultArray[j].CodedCharacters / FResultArray[j].TotalCharacters
        else
          PctJ := 0.0;
        if PctJ > PctI then
        begin
          TempRes := FResultArray[i];
          FResultArray[i] := FResultArray[j];
          FResultArray[j] := TempRes;
        end;
      end;
    end;
    if (FALimit > 0) and (FALimit < Count) then SetLength(FResultArray, FALimit);
  finally
    Q.Free;
    DocumentIndexMap.Free;
  end;
end;

function TServiceDatabase.RunCoverageAnalysis(const DocumentID: TStringDynArray; const AttributeSQL: String; ALimit: Integer): TCoverageArray;
var
  Worker: TThreadCoverage;
begin
  SetLength(Result, 0);
  if FConnection.Transaction.Active then FConnection.Transaction.Commit;
  Worker := TThreadCoverage.Create(FConnection.DatabaseName, DocumentID, AttributeSQL, ALimit);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Analysing Data', 'Initialising...');
    frmDialogProgress.ShowModal;
    if not Worker.Success then
      raise Exception.Create('Analysis failed: ' + Worker.ErrorMessage);
    Result := Worker.ResultArray;
  finally
    Worker.Free;
  end;
end;

constructor TThreadWordCloud.Create(const ADBPath: String; const ACodeID, ADocumentID: TStringDynArray; const AAttributeSQL, AStopWord: String; ALimit: Integer);
begin
  inherited Create(ADBPath);
  FCodeID := ACodeID;
  FDocumentID := ADocumentID;
  FAttributeSQL := AAttributeSQL;
  FStopWord := AStopWord;
  FALimit := ALimit;
  SetLength(FResultArray, 0);
end;

procedure TThreadWordCloud.DoHeavyLifting;
var
  WordDict: specialize TDictionary<String, Integer>;
  StopSet: specialize TDictionary<String, Boolean>;
  StopArray: TStringArray;
  i, j, Count, CharLen: Integer;
  RawText, TokenStr, LowerToken, ScopeJoin: String;
  Pair: specialize TPair<String, Integer>;
  TempRes: TWordCloudResult;
  P: PChar;
  CodePoint: Cardinal;
  Cat: TUnicodeCategory;
  IsValidChar: Boolean;
  Q: TSQLQuery;
begin
  SyncUpdateStatus('Preparing analyser...');
  FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_codes');
  FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_codes (id TEXT PRIMARY KEY)');
  if Length(FCodeID) > 0 then
  begin
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_codes (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FCodeID) to High(FCodeID) do
      begin
        Q.Params[0].AsString := FCodeID[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
  end;
  ScopeJoin := '';
  if Length(FDocumentID) > 0 then
  begin
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_analyse_scope_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_analyse_scope_docs (id TEXT PRIMARY KEY)');
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := FConnection;
      Q.Transaction := FTransaction;
      if not FTransaction.Active then FTransaction.StartTransaction;
      Q.SQL.Text := 'INSERT INTO temp_analyse_scope_docs (id) VALUES (:id)';
      Q.Prepare;
      for i := Low(FDocumentID) to High(FDocumentID) do
      begin
        Q.Params[0].AsString := FDocumentID[i];
        Q.ExecSQL;
      end;
      FTransaction.Commit;
    finally
      Q.Free;
    end;
    ScopeJoin := ' JOIN temp_analyse_scope_docs tsd ON co.document_id = tsd.id ';
  end;
  if FAttributeSQL <> '' then
    ScopeJoin := ScopeJoin + ' LEFT JOIN document_attributes da ON co.document_id = da.document_id ';
  StopSet := specialize TDictionary<String, Boolean>.Create;
  WordDict := specialize TDictionary<String, Integer>.Create;
  Q := TSQLQuery.Create(nil);
  try
    StopArray := UTF8LowerCase(FStopWord).Split([',', ' ', #13, #10], TStringSplitOptions.ExcludeEmpty);
    for i := 0 to High(StopArray) do StopSet.AddOrSetValue(Trim(StopArray[i]), True);
    Q.Database := FConnection;
    Q.Transaction := FTransaction;
    Q.SQL.Text := 'SELECT SUBSTR(d.content, co.start_position + 1, co.length) as segment_text FROM codings co JOIN documents d ON co.document_id = d.id JOIN temp_analyse_codes tc ON co.code_id = tc.id ' + ScopeJoin + 'WHERE 1=1 ' + FAttributeSQL;
    Q.Open;
    SyncUpdateStatus('Processing lexicographical tokens...');
    while not Q.EOF do
    begin
      RawText := Q.FieldByName('segment_text').AsString;
      P := PChar(RawText);
      TokenStr := '';
      while (P <> nil) and (P^ <> #0) do
      begin
        CodePoint := UTF8CodepointToUnicode(P, CharLen);
        if CharLen <= 0 then Break;
        IsValidChar := False;
        if (CharLen = 1) and (Ord(P^) >= $80) then
          IsValidChar := False
        else if CodePoint > $FFFF then
          IsValidChar := True
        else
        begin
          Cat := TCharacter.GetUnicodeCategory(WideChar(CodePoint));
          IsValidChar := (Cat = TUnicodeCategory.ucUppercaseLetter) or (Cat = TUnicodeCategory.ucLowercaseLetter) or (Cat = TUnicodeCategory.ucTitlecaseLetter) or (Cat = TUnicodeCategory.ucModifierLetter) or (Cat = TUnicodeCategory.ucOtherLetter) or (Cat = TUnicodeCategory.ucNonSpacingMark) or (Cat = TUnicodeCategory.ucCombiningMark) or (Cat = TUnicodeCategory.ucEnclosingMark) or (Cat = TUnicodeCategory.ucDecimalNumber) or (Cat = TUnicodeCategory.ucLetterNumber) or (Cat = TUnicodeCategory.ucOtherNumber) or (Cat = TUnicodeCategory.ucFormat) or (Cat = TUnicodeCategory.ucOtherSymbol) or (Cat = TUnicodeCategory.ucMathSymbol) or (Cat = TUnicodeCategory.ucCurrencySymbol);
        end;
        if IsValidChar then
          TokenStr := TokenStr + Copy(RawText, (P - PChar(RawText)) + 1, CharLen)
        else
        begin
          if TokenStr <> '' then
          begin
            LowerToken := UTF8LowerCase(TokenStr);
            if not StopSet.ContainsKey(LowerToken) then
            begin
              if WordDict.TryGetValue(LowerToken, j) then
                WordDict.AddOrSetValue(LowerToken, j + 1)
              else
                WordDict.Add(LowerToken, 1);
            end;
            TokenStr := '';
          end;
        end;
        Inc(P, CharLen);
      end;
      if TokenStr <> '' then
      begin
        LowerToken := UTF8LowerCase(TokenStr);
        if not StopSet.ContainsKey(LowerToken) then
        begin
          if WordDict.TryGetValue(LowerToken, j) then
            WordDict.AddOrSetValue(LowerToken, j + 1)
          else
            WordDict.Add(LowerToken, 1);
        end;
      end;
      Q.Next;
    end;
    Q.Close;
    SyncUpdateStatus('Finalising visualisation...');
    SetLength(FResultArray, WordDict.Count);
    Count := 0;
    for Pair in WordDict do
    begin
      FResultArray[Count].Word := Pair.Key;
      FResultArray[Count].Frequency := Pair.Value;
      Inc(Count);
    end;
    for i := 0 to Count - 2 do
    begin
      for j := i + 1 to Count - 1 do
      begin
        if FResultArray[j].Frequency > FResultArray[i].Frequency then
        begin
          TempRes := FResultArray[i];
          FResultArray[i] := FResultArray[j];
          FResultArray[j] := TempRes;
        end;
      end;
    end;
    if (FALimit > 0) and (FALimit < Count) then
      SetLength(FResultArray, FALimit);
  finally
    Q.Free;
    WordDict.Free;
    StopSet.Free;
  end;
end;

function TServiceDatabase.RunWordCloudAnalysis(const CodeID, DocumentID: TStringDynArray; const AttributeSQL, StopWord: String; ALimit: Integer): TWordCloudArray;
var
  Worker: TThreadWordCloud;
begin
  SetLength(Result, 0);
  if FConnection.Transaction.Active then FConnection.Transaction.Commit;
  Worker := TThreadWordCloud.Create(FConnection.DatabaseName, CodeID, DocumentID, AttributeSQL, StopWord, ALimit);
  try
    Worker.Start;
    TfrmDialogProgress.Prepare('Analysing Data', 'Initialising...');
    frmDialogProgress.ShowModal;
    if not Worker.Success then
      raise Exception.Create('Analysis failed: ' + Worker.ErrorMessage);
    Result := Worker.ResultArray;
  finally
    Worker.Free;
  end;
end;

function TServiceDatabase.GetUserPreference(const AKey, ADefault: String): String;
begin
  Result := ADefault;
  FQuery.Close;
  FQuery.SQL.Text := 'SELECT value FROM preferences WHERE key = :k';
  FQuery.Params.ParamByName('k').AsString := AKey;
  FQuery.Open;
  if not FQuery.EOF then Result := FQuery.Fields[0].AsString;
  FQuery.Close;
end;

procedure TServiceDatabase.SaveUserPreference(const AKey, AValue: String);
begin
  ExecuteSafe('INSERT OR REPLACE INTO preferences (key, value) VALUES (' +
              QuotedStr(AKey) + ', ' + QuotedStr(AValue) + ')');
end;

end.
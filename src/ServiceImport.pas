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

unit ServiceImport;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, fpspreadsheet, fpsTypes, SQLDB, SQLite3Conn;

type
  TImportColumnMap = record
    ColumnName: String;
    ColumnIndex: Integer;
    MapType: Integer;
    AttributeMode: Integer; 
    AttributeName: String;
    AttributeType: String;
  end;
  TImportColumnMapArray = array of TImportColumnMap;

  TServiceImport = class
  private
    class function CleanExtractedText(const RawText: String): String;
    class function ExtractTextFromPDF(const FilePath: String): String;
    class function GetSafeColumnName(const AttributeID: String): String;
    class function GetTextFromDOCX(const AFileName: String): String;
    class function GetTextFromODT(const AFileName: String): String;
    class function GetUniqueTitle(AQuery: TSQLQuery; const BaseTitle: String): String;
    class function SanitizeText(const AText: String): String;
    class procedure RecursiveImportCodingScheme(AQuery: TSQLQuery; JSONArray: TJSONArray; const ParentID: String);
  public
    class function ImportCodingScheme(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
    class function ImportJSON(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
    class function ImportSQLite(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
    class function ImportSpreadsheet(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
    class function ImportTextFile(AConnection: TSQLite3Connection; AFile: TStrings): Integer;
    class procedure ImportPDFDocument(AConnection: TSQLite3Connection; AFile: TStrings);
    class procedure ImportWordProcessorFile(AConnection: TSQLite3Connection; AFile: TStrings);
  end;

implementation

uses
  Controls, Dialogs, fpsopendocument, jsonparser, laz2_DOM, laz2_XMLRead, LazFileUtils, LazUTF8,
  zipper, xlsxOOXML, AppFormat, BridgeLibrary, DialogEditor, DialogInput, DialogProgress, ModalImport,
  MonoLexID, ServiceParser, ServiceThread;

type
  TThreadImportText = class(TBackgroundWorker)
  public
    FFile: TStringArray;
    FSuccessCount: Integer;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadImportWord = class(TBackgroundWorker)
  public
    FFile: TStringArray;
    FSkippedFile: TStringArray;
    FSuccessCount: Integer;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadImportPDF = class(TBackgroundWorker)
  public
    FFile: TStringArray;
    FSkippedFile: TStringArray;
    FSuccessCount: Integer;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadImportSpreadsheet = class(TBackgroundWorker)
  public
    FFileName: String;
    FSheetIndex: Integer;
    FMapping: TImportColumnMapArray;
    FTitleIndex, FTextIndex: Integer;
    FInvalidCount, FSuccessCount: Integer;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadImportJSON = class(TBackgroundWorker)
  public
    FFileName: String;
    FMapping: TImportColumnMapArray;
    FTitleIndex, FTextIndex: Integer;
    FInvalidCount, FSuccessCount: Integer;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadImportSQLite = class(TBackgroundWorker)
  public
    FFileName: String;
    FTableName: String;
    FMapping: TImportColumnMapArray;
    FTitleIndex, FTextIndex: Integer;
    FInvalidCount, FSuccessCount: Integer;
  protected
    procedure DoHeavyLifting; override;
  end;

class function TServiceImport.SanitizeText(const AText: String): String;
var
  i: Integer;
begin
  if AText = '' then Exit('');
  Result := StringReplace(AText, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
  for i := 1 to Length(Result) do
  begin
    if (Result[i] < #32) and not (Result[i] in [#10, #9]) then
      Result[i] := ' ';
  end;
  Result := StringReplace(Result, #0, '', [rfReplaceAll]);
end;

class function TServiceImport.GetUniqueTitle(AQuery: TSQLQuery; const BaseTitle: String): String;
var
  Counter: Integer;
begin
  Result := BaseTitle;
  Counter := 0;
  repeat
    AQuery.Close;
    AQuery.SQL.Text := 'SELECT 1 FROM documents WHERE title = :t LIMIT 1';
    AQuery.Params.ParamByName('t').AsString := Result;
    AQuery.Open;
    if not AQuery.EOF then
    begin
      Inc(Counter);
      Result := Format('%s (%d)', [BaseTitle, Counter]);
    end;
  until AQuery.EOF;
  AQuery.Close;
end;

class procedure TServiceImport.RecursiveImportCodingScheme(AQuery: TSQLQuery; JSONArray: TJSONArray; const ParentID: String);
var
  i: Integer;
  NewID: String;
  CodeObj: TJSONObject;
begin
  for i := 0 to JSONArray.Count - 1 do
  begin
    if JSONArray.Items[i].JSONType <> jtObject then Continue;
    CodeObj := TJSONObject(JSONArray.Items[i]);
    NewID := CodeObj.Get('ID', '');
    if (NewID = '') or (CodeObj.Get('Name', '') = '') then Continue;
    AQuery.Params.ParamByName('g').AsString := NewID;
    AQuery.Params.ParamByName('n').AsString := CodeObj.Get('Name', '');
    AQuery.Params.ParamByName('d').AsString := CodeObj.Get('Description', '');
    AQuery.Params.ParamByName('c').AsInteger := CodeObj.Get('Color', 8421504); 
    AQuery.Params.ParamByName('p').AsString := ParentID;
    AQuery.ExecSQL;
    if (CodeObj.Find('SubCodes') <> nil) and (CodeObj.Types['SubCodes'] = jtArray) then
      RecursiveImportCodingScheme(AQuery, CodeObj.Arrays['SubCodes'], NewID);
  end;
end;

class function TServiceImport.ImportCodingScheme(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
var
  JSONData: TJSONData;
  FileContent: TStringList;
  Query: TSQLQuery;
begin
  Result := False;
  JSONData := nil;
  FileContent := TStringList.Create;
  Query := TSQLQuery.Create(nil);
  try
    Query.Database := AConnection;
    Query.Transaction := AConnection.Transaction;
    try
      FileContent.LoadFromFile(AFileName);
    except
      on E: Exception do
      begin
        MessageDlg('File Error', 'Could not open the file: ' + E.Message, mtError, [mbOK], 0);
        Exit;
      end;
    end;
    try
      try
        JSONData := GetJSON(FileContent.Text);
      except
        on E: Exception do
        begin
          MessageDlg('Invalid JSON', 'The file could not be parsed as a valid JSON document: ' + E.Message, mtError, [mbOK], 0);
          Exit;
        end;
      end;
      if (JSONData = nil) or (JSONData.JSONType <> jtArray) then
      begin
        MessageDlg('Invalid Format', 'The selected file is not a valid coding scheme.', mtError, [mbOK], 0);
        Exit;
      end;
      if TJSONArray(JSONData).Count = 0 then
      begin
        MessageDlg('Empty Scheme', 'The selected coding scheme contains no codes.', mtInformation, [mbOK], 0);
        Exit;
      end;
      if not AConnection.Transaction.Active then AConnection.Transaction.StartTransaction;
      try
        Query.SQL.Text := 'INSERT INTO codes (id, name, description, color, parent_id) VALUES (:g, :n, :d, :c, :p)';
        Query.Prepare;
        RecursiveImportCodingScheme(Query, TJSONArray(JSONData), '');
        AConnection.Transaction.Commit;
        Result := True;
      except
        on E: Exception do
        begin
          if AConnection.Transaction.Active then AConnection.Transaction.Rollback;
          MessageDlg('Database Error', 'Failed to import codes: ' + E.Message, mtError, [mbOK], 0);
        end;
      end;
    finally
      if Assigned(JSONData) then JSONData.Free;
    end;
  finally
    FileContent.Free;
    Query.Free;
  end;
end;

procedure TThreadImportText.DoHeavyLifting;
var
  i: Integer;
  StringList: TStringList;
  BaseTitle, FinalTitle, SanitizedText: String;
  QueryMain, QueryCheck: TSQLQuery;
begin
  FSuccessCount := 0;
  StringList := TStringList.Create;
  QueryMain := TSQLQuery.Create(nil);
  QueryCheck := TSQLQuery.Create(nil);
  try
    QueryMain.Database := FConnection; QueryMain.Transaction := FTransaction;
    QueryCheck.Database := FConnection; QueryCheck.Transaction := FTransaction;
    if not FTransaction.Active then FTransaction.StartTransaction;
    QueryMain.SQL.Text := 'INSERT INTO documents (id, title, content) VALUES (:g, :t, :b)';
    QueryMain.Prepare;
    for i := Low(FFile) to High(FFile) do
    begin
      SyncUpdateStatus('Importing text file ' + IntToStr(i + 1) + ' of ' + IntToStr(Length(FFile)) + '...');
      try
        StringList.LoadFromFile(FFile[i]);
        SanitizedText := TServiceImport.SanitizeText(StringList.Text);
      except
        Continue;
      end;
      BaseTitle := ExtractFileNameWithoutExt(ExtractFileName(FFile[i]));
      FinalTitle := TServiceImport.GetUniqueTitle(QueryCheck, BaseTitle);
      QueryMain.Params.ParamByName('g').AsString := NewMonoLexID;
      QueryMain.Params.ParamByName('t').AsString := FinalTitle;
      QueryMain.Params.ParamByName('b').AsString := SanitizedText;
      QueryMain.ExecSQL;
      Inc(FSuccessCount);
    end;
    FTransaction.Commit;
  finally
    StringList.Free;
    QueryMain.Free;
    QueryCheck.Free;
  end;
end;

class function TServiceImport.ImportTextFile(AConnection: TSQLite3Connection; AFile: TStrings): Integer;
var
  Worker: TThreadImportText;
  FileArray: TStringArray;
  i: Integer;
begin
  Result := 0;
  if AFile.Count = 0 then Exit;
  SetLength(FileArray, AFile.Count);
  for i := 0 to AFile.Count - 1 do FileArray[i] := AFile[i];
  if AConnection.Transaction.Active then AConnection.Transaction.Commit;
  Worker := TThreadImportText.Create(AConnection.DatabaseName);
  try
    Worker.FFile := FileArray;
    Worker.Start;
    TfrmDialogProgress.Prepare('Importing Text Files', 'Connecting...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      Result := Worker.FSuccessCount;
      if Worker.FSuccessCount > 0 then
        MessageDlg('Success', Format('Successfully imported %d %s.', [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'text file', 'text files')]), mtInformation, [mbOK], 0);
    end
    else
      MessageDlg('Import Error', 'Failed to import text files: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

class function TServiceImport.GetTextFromDOCX(const AFileName: String): String;
var
  UnZipper: TUnZipper;
  XMLStream: TMemoryStream;
  Doc: TXMLDocument;
  DocumentPath: String;
  procedure ExtractTextWithFidelity(ANode: TDOMNode; var AText: string);
  var
    Child: TDOMNode;
  begin
    if ANode = nil then Exit;
    if ANode.NodeName = 'w:p' then
    begin
      Child := ANode.FirstChild;
      while Child <> nil do
      begin
        ExtractTextWithFidelity(Child, AText);
        Child := Child.NextSibling;
      end;
      AText := AText + sLineBreak;
    end
    else if (ANode.NodeName = 'w:br') or (ANode.NodeName = 'w:cr') or (ANode.NodeName = 'w:lastRenderedPageBreak') then
      AText := AText + sLineBreak
    else if ANode.NodeName = 'w:tab' then
      AText := AText + #9
    else if ANode.NodeName = 'w:t' then
      AText := AText + ANode.TextContent
    else if ANode.NodeName = 'w:softHyphen' then
      AText := AText + '-'
    else
    begin
      Child := ANode.FirstChild;
      while Child <> nil do
      begin
        ExtractTextWithFidelity(Child, AText);
        Child := Child.NextSibling;
      end;
    end;
  end;
begin
  Result := '';
  UnZipper := TUnZipper.Create;
  XMLStream := TMemoryStream.Create;
  DocumentPath := GetTempDir + 'word' + DirectorySeparator + 'document.xml';
  try
    try
      UnZipper.FileName := AFileName;
      try
        UnZipper.Examine;
        UnZipper.OutputPath := GetTempDir;
        UnZipper.Files.Add('word/document.xml');
        UnZipper.UnZipAllFiles;
      except
        on E: Exception do Exit;
      end;
      if FileExists(DocumentPath) then
      begin
        XMLStream.LoadFromFile(DocumentPath);
        XMLStream.Position := 0;
        ReadXMLFile(Doc, XMLStream);
        try
          ExtractTextWithFidelity(Doc.DocumentElement, Result);
        finally
          Doc.Free;
        end;
      end;
    except
      on E: Exception do ;
    end;
  finally
    if FileExists(DocumentPath) then DeleteFile(PChar(DocumentPath));
    XMLStream.Free;
    UnZipper.Free;
  end;
end;

class function TServiceImport.GetTextFromODT(const AFileName: String): String;
var
  UnZipper: TUnZipper;
  XMLStream: TMemoryStream;
  Doc: TXMLDocument;
  DocumentPath: String;
  procedure ExtractODTTextWithFidelity(ANode: TDOMNode; var AText: string);
  var
    Child: TDOMNode;
    i, SpaceCount: Integer;
    Attr: TDOMNode;
  begin
    if ANode = nil then Exit;
    if ANode.NodeName = 'text:p' then
    begin
      Child := ANode.FirstChild;
      while Child <> nil do
      begin
        ExtractODTTextWithFidelity(Child, AText);
        Child := Child.NextSibling;
      end;
      AText := AText + sLineBreak;
    end
    else if ANode.NodeName = 'text:line-break' then
      AText := AText + sLineBreak
    else if ANode.NodeName = 'text:tab' then
      AText := AText + #9
    else if ANode.NodeName = 'text:s' then
    begin
      SpaceCount := 1;
      Attr := ANode.Attributes.GetNamedItem('text:c');
      if Assigned(Attr) then
        SpaceCount := StrToIntDef(Attr.NodeValue, 1);
      for i := 1 to SpaceCount do AText := AText + ' ';
    end
    else if ANode.NodeType = TEXT_NODE then
      AText := AText + ANode.NodeValue
    else
    begin
      Child := ANode.FirstChild;
      while Child <> nil do
      begin
        ExtractODTTextWithFidelity(Child, AText);
        Child := Child.NextSibling;
      end;
    end;
  end;
begin
  Result := '';
  UnZipper := TUnZipper.Create;
  XMLStream := TMemoryStream.Create;
  DocumentPath := GetTempDir + 'content.xml';
  try
    try
      UnZipper.FileName := AFileName;
      try
        UnZipper.Examine;
        UnZipper.OutputPath := GetTempDir;
        UnZipper.Files.Add('content.xml');
        UnZipper.UnZipAllFiles;
      except
        on E: Exception do Exit;
      end;
      if FileExists(DocumentPath) then
      begin
        XMLStream.LoadFromFile(DocumentPath);
        XMLStream.Position := 0;
        ReadXMLFile(Doc, XMLStream);
        try
          ExtractODTTextWithFidelity(Doc.DocumentElement, Result);
        finally
          Doc.Free;
        end;
      end;
    except
      on E: Exception do ;
    end;
  finally
    if FileExists(DocumentPath) then DeleteFile(PChar(DocumentPath));
    XMLStream.Free;
    UnZipper.Free;
  end;
end;

procedure TThreadImportWord.DoHeavyLifting;
var
  i, SkipCount: Integer;
  Extension, BaseTitle, FinalTitle, FileText: String;
  QueryMain, QueryCheck: TSQLQuery;
begin
  FSuccessCount := 0;
  SkipCount := 0;
  SetLength(FSkippedFile, Length(FFile)); 
  QueryMain := TSQLQuery.Create(nil);
  QueryCheck := TSQLQuery.Create(nil);
  try
    QueryMain.Database := FConnection; QueryMain.Transaction := FTransaction;
    QueryCheck.Database := FConnection; QueryCheck.Transaction := FTransaction;
    if not FTransaction.Active then FTransaction.StartTransaction;
    QueryMain.SQL.Text := 'INSERT INTO documents (id, title, content) VALUES (:g, :t, :b)';
    QueryMain.Prepare;
    for i := Low(FFile) to High(FFile) do
    begin
      SyncUpdateStatus('Importing document ' + IntToStr(i + 1) + ' of ' + IntToStr(Length(FFile)) + '...');
      Extension := LowerCase(ExtractFileExt(FFile[i]));
      FileText := '';
      try
        if Extension = '.docx' then
          FileText := TServiceImport.GetTextFromDOCX(FFile[i])
        else if Extension = '.odt' then
          FileText := TServiceImport.GetTextFromODT(FFile[i]);
      except
      end;
      FileText := TServiceImport.SanitizeText(FileText);
      if Trim(FileText) = '' then
      begin
        FSkippedFile[SkipCount] := ExtractFileName(FFile[i]);
        Inc(SkipCount);
        Continue;
      end;
      BaseTitle := ExtractFileNameWithoutExt(ExtractFileName(FFile[i]));
      FinalTitle := TServiceImport.GetUniqueTitle(QueryCheck, BaseTitle);
      QueryMain.Params.ParamByName('g').AsString := NewMonoLexID;
      QueryMain.Params.ParamByName('t').AsString := FinalTitle;
      QueryMain.Params.ParamByName('b').AsString := FileText;
      QueryMain.ExecSQL;
      Inc(FSuccessCount);
    end;
    SetLength(FSkippedFile, SkipCount);
    FTransaction.Commit;
  finally
    QueryMain.Free;
    QueryCheck.Free;
  end;
end;

class procedure TServiceImport.ImportWordProcessorFile(AConnection: TSQLite3Connection; AFile: TStrings);
var
  Worker: TThreadImportWord;
  FileArray: TStringArray;
  i: Integer;
  ReportDlg: TfrmDialogEditor;
begin
  if AFile.Count = 0 then Exit;
  SetLength(FileArray, AFile.Count);
  for i := 0 to AFile.Count - 1 do FileArray[i] := AFile[i];
  if AConnection.Transaction.Active then AConnection.Transaction.Commit;
  Worker := TThreadImportWord.Create(AConnection.DatabaseName);
  try
    Worker.FFile := FileArray;
    Worker.Start;
    TfrmDialogProgress.Prepare('Importing Documents', 'Connecting...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      if Length(Worker.FSkippedFile) > 0 then
      begin
        ReportDlg := TfrmDialogEditor.Create(nil);
        try
          ReportDlg.ExecuteReport('Import Summary',
            Format('Successfully imported %d %s. Skipped %d corrupt or unreadable %s:',
                   [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'file', 'files'),
                    Length(Worker.FSkippedFile), TAppFormat.Pluralize(Length(Worker.FSkippedFile), 'file', 'files')]),
            Worker.FSkippedFile);
        finally
          ReportDlg.Free;
        end;
      end
      else if Worker.FSuccessCount > 0 then
        MessageDlg('Success', Format('Successfully imported %d %s.', [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'document', 'documents')]), mtInformation, [mbOK], 0);
    end
    else
      MessageDlg('Import Error', 'Failed to import documents: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

class function TServiceImport.CleanExtractedText(const RawText: String): String;
var
  Src, Dest: PChar;
  Len, DestLen: Integer;
  C1, C2, C3: Char;
  ConsecutiveLineBreaks: Integer;
begin
  Len := Length(RawText);
  if Len = 0 then Exit('');
  SetLength(Result, Len);
  Src := PChar(RawText);
  Dest := PChar(Result);
  DestLen := 0;
  ConsecutiveLineBreaks := 0;
  while Src^ <> #0 do
  begin
    C1 := Src^;
    if C1 = #13 then
    begin
      Inc(Src);
      Continue;
    end;
    C2 := (Src + 1)^;
    if C2 <> #0 then
    begin
      C3 := (Src + 2)^;
      if (C1 = #$EF) and (C2 = #$BF) and (C3 = #$BD) then
      begin
        Inc(Src, 3);
        Continue;
      end;
      if (C1 = #$EF) and (C2 = #$BF) and (C3 = #$BE) then
      begin
        Inc(Src, 3);
        Continue;
      end;
      if (C1 = #$C2) and (C2 = #$AD) then
      begin
        Inc(Src, 2);
        Continue;
      end;
    end;
    if C1 = #10 then
    begin
      Inc(ConsecutiveLineBreaks);
      if ConsecutiveLineBreaks > 2 then
      begin
        Inc(Src);
        Continue;
      end;
    end
    else
    begin
      ConsecutiveLineBreaks := 0;
    end;
    Dest^ := C1;
    Inc(Dest);
    Inc(DestLen);
    Inc(Src);
  end;
  SetLength(Result, DestLen);
  Result := Trim(Result);
end;

class function TServiceImport.ExtractTextFromPDF(const FilePath: String): String;
var
  MemStream: TMemoryStream;
  DocumentPointer: FPDF_DOCUMENT;
  PagePointer: FPDF_PAGE;
  TextPagePointer: FPDF_TEXTPAGE;
  PageCount, PageIndex, CharacterCount, BufferSize: Integer;
  WideBuffer: array of WideChar;
  TempWide: WideString;
  ExtractedText: String;
  Builder: TStringBuilder;
begin
  Result := '';
  if Trim(FilePath) = '' then Exit;
  MemStream := TMemoryStream.Create;
  Builder := TStringBuilder.Create;
  try
    try
      MemStream.LoadFromFile(FilePath);
    except
      Exit;
    end;
    if MemStream.Size = 0 then Exit;
    DocumentPointer := FPDF_LoadMemDocument(MemStream.Memory, MemStream.Size, nil);
    if not Assigned(DocumentPointer) then Exit;
    try
      PageCount := FPDF_GetPageCount(DocumentPointer);
      Builder.Capacity := PageCount * 2048;
      for PageIndex := 0 to PageCount - 1 do
      begin
        PagePointer := FPDF_LoadPage(DocumentPointer, PageIndex);
        if not Assigned(PagePointer) then Continue;
        try
          TextPagePointer := FPDFText_LoadPage(PagePointer);
          if not Assigned(TextPagePointer) then Continue;
          try
            CharacterCount := FPDFText_CountChars(TextPagePointer);
            if CharacterCount > 0 then
            begin
              if Length(WideBuffer) < CharacterCount + 2 then
                SetLength(WideBuffer, CharacterCount + 1024);
              BufferSize := FPDFText_GetText(TextPagePointer, 0, CharacterCount, @WideBuffer[0]);
              if BufferSize > 1 then
              begin
                SetString(TempWide, PWideChar(@WideBuffer[0]), BufferSize - 1);
                ExtractedText := CleanExtractedText(UTF8Encode(TempWide));
                if ExtractedText <> '' then
                begin
                  Builder.Append(ExtractedText);
                  Builder.Append(#10#10);
                end;
              end;
            end;
          finally
            FPDFText_ClosePage(TextPagePointer);
          end;
        finally
          FPDF_ClosePage(PagePointer);
        end;
      end;
    finally
      FPDF_CloseDocument(DocumentPointer);
    end;
    Result := Trim(Builder.ToString);
  finally
    Builder.Free;
    MemStream.Free;
  end;
end;

procedure TThreadImportPDF.DoHeavyLifting;
var
  i, SkipCount: Integer;
  BaseTitle, FinalTitle, FileText: String;
  QueryMain, QueryCheck: TSQLQuery;
begin
  FSuccessCount := 0;
  SkipCount := 0;
  SetLength(FSkippedFile, Length(FFile)); 
  QueryMain := TSQLQuery.Create(nil);
  QueryCheck := TSQLQuery.Create(nil);
  try
    QueryMain.Database := FConnection; QueryMain.Transaction := FTransaction;
    QueryCheck.Database := FConnection; QueryCheck.Transaction := FTransaction;
    if not FTransaction.Active then FTransaction.StartTransaction;
    QueryMain.SQL.Text := 'INSERT INTO documents (id, title, content) VALUES (:g, :t, :b)';
    QueryMain.Prepare;
    for i := Low(FFile) to High(FFile) do
    begin
      SyncUpdateStatus('Importing PDF ' + IntToStr(i + 1) + ' of ' + IntToStr(Length(FFile)) + '...');
      FileText := '';
      try
        FileText := TServiceImport.ExtractTextFromPDF(FFile[i]);
      except
      end;
      FileText := TServiceImport.SanitizeText(FileText);
      if Trim(FileText) = '' then
      begin
        FSkippedFile[SkipCount] := ExtractFileName(FFile[i]);
        Inc(SkipCount);
        Continue;
      end;
      BaseTitle := ExtractFileNameWithoutExt(ExtractFileName(FFile[i]));
      FinalTitle := TServiceImport.GetUniqueTitle(QueryCheck, BaseTitle);
      QueryMain.Params.ParamByName('g').AsString := NewMonoLexID;
      QueryMain.Params.ParamByName('t').AsString := FinalTitle;
      QueryMain.Params.ParamByName('b').AsString := FileText;
      QueryMain.ExecSQL;
      Inc(FSuccessCount);
    end;
    SetLength(FSkippedFile, SkipCount);
    FTransaction.Commit;
  finally
    QueryMain.Free;
    QueryCheck.Free;
  end;
end;

class procedure TServiceImport.ImportPDFDocument(AConnection: TSQLite3Connection; AFile: TStrings);
var
  Worker: TThreadImportPDF;
  FileArray: TStringArray;
  i: Integer;
  ReportDlg: TfrmDialogEditor;
begin
  if AFile.Count = 0 then Exit;
  SetLength(FileArray, AFile.Count);
  for i := 0 to AFile.Count - 1 do FileArray[i] := AFile[i];
  if AConnection.Transaction.Active then AConnection.Transaction.Commit;
  Worker := TThreadImportPDF.Create(AConnection.DatabaseName);
  try
    Worker.FFile := FileArray;
    Worker.Start;
    TfrmDialogProgress.Prepare('Importing PDF Documents', 'Connecting...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
    begin
      if Length(Worker.FSkippedFile) > 0 then
      begin
        ReportDlg := TfrmDialogEditor.Create(nil);
        try
          ReportDlg.ExecuteReport('Import Summary',
            Format('Successfully imported %d %s. Skipped %d encrypted, corrupt, or image-only %s:',
                   [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'PDF', 'PDFs'),
                    Length(Worker.FSkippedFile), TAppFormat.Pluralize(Length(Worker.FSkippedFile), 'file', 'files')]),
            Worker.FSkippedFile);
        finally
          ReportDlg.Free;
        end;
      end
      else if Worker.FSuccessCount > 0 then
        MessageDlg('Success', Format('Successfully imported %d PDF %s.', [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'document', 'documents')]), mtInformation, [mbOK], 0);
    end
    else
      MessageDlg('Import Error', 'Failed to import PDFs: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

class function TServiceImport.GetSafeColumnName(const AttributeID: String): String;
begin
  Result := 'attribute_' + Copy(StringReplace(AttributeID, '-', '', [rfReplaceAll]), 1, 16);
end;

procedure TThreadImportSpreadsheet.DoHeavyLifting;
var
  Workbook: TsWorkbook;
  Worksheet: TsWorksheet;
  Cell: PCell;
  r, i, UpdateFieldCount: Integer;
  TargetDocumentID, AttributeUpdateSQL, NewAttributeID, CurrentAttribute: String;
  BaseTitle, FinalTitle, CellValue, RowTextContent, CleanValue: String;
  QueryMain, QueryUtil, QueryCheck, QueryAttributeUpdate: TSQLQuery;
  CachedAttributeCols: array of String;
  InvariantFormat: TFormatSettings;
  DummyDate: TDateTime;
begin
  FInvalidCount := 0; FSuccessCount := 0;
  InvariantFormat := DefaultFormatSettings;
  InvariantFormat.DecimalSeparator := '.';
  InvariantFormat.ThousandSeparator := #0;
  QueryMain := TSQLQuery.Create(nil);
  QueryUtil := TSQLQuery.Create(nil);
  QueryCheck := TSQLQuery.Create(nil);
  QueryAttributeUpdate := TSQLQuery.Create(nil);
  Workbook := TsWorkbook.Create;
  try
    QueryMain.Database := FConnection; QueryMain.Transaction := FTransaction;
    QueryUtil.Database := FConnection; QueryUtil.Transaction := FTransaction;
    QueryCheck.Database := FConnection; QueryCheck.Transaction := FTransaction;
    QueryAttributeUpdate.Database := FConnection; QueryAttributeUpdate.Transaction := FTransaction;
    SyncUpdateStatus('Analysing workbook structure...');
    Workbook.ReadFromFile(FFileName);
    Worksheet := Workbook.GetWorksheetByIndex(FSheetIndex);
    if not FTransaction.Active then FTransaction.StartTransaction;
    SetLength(CachedAttributeCols, Length(FMapping));
    for i := 0 to High(FMapping) do
    begin
      CachedAttributeCols[i] := '';
      if (FMapping[i].MapType = 3) and (Trim(FMapping[i].AttributeName) <> '') then
      begin
        CurrentAttribute := Trim(FMapping[i].AttributeName);
        QueryUtil.Close;
        QueryUtil.SQL.Text := 'SELECT id, attribute_key FROM attribute_registry WHERE name = :n';
        QueryUtil.Params.ParamByName('n').AsString := CurrentAttribute;
        QueryUtil.Open;
        if not QueryUtil.EOF then
          CachedAttributeCols[i] := QueryUtil.FieldByName('attribute_key').AsString
        else
        begin
          NewAttributeID := NewMonoLexID;
          CachedAttributeCols[i] := TServiceImport.GetSafeColumnName(NewAttributeID);
          QueryUtil.Close;
          QueryUtil.SQL.Text := 'INSERT INTO attribute_registry (id, name, attribute_key, attribute_type) VALUES (:g, :n, :c, :tp)';
          QueryUtil.Params.ParamByName('g').AsString := NewAttributeID;
          QueryUtil.Params.ParamByName('n').AsString := CurrentAttribute;
          QueryUtil.Params.ParamByName('c').AsString := CachedAttributeCols[i];
          QueryUtil.Params.ParamByName('tp').AsString := FMapping[i].AttributeType;
          QueryUtil.ExecSQL;
        end;
        QueryUtil.Close;
      end;
    end;
    QueryMain.Close;
    QueryMain.SQL.Text := 'INSERT INTO documents (id, title, content) VALUES (:g, :t, :b)';
    QueryMain.Prepare;
    AttributeUpdateSQL := 'UPDATE document_attributes SET attributes = json_set(attributes';
    UpdateFieldCount := 0;
    for i := 0 to High(FMapping) do
    begin
      if CachedAttributeCols[i] <> '' then
      begin
        if FMapping[i].AttributeType = 'Numeric' then
          AttributeUpdateSQL := AttributeUpdateSQL + ', ''$.' + CachedAttributeCols[i] + ''', json(:' + CachedAttributeCols[i] + ')'
        else
          AttributeUpdateSQL := AttributeUpdateSQL + ', ''$.' + CachedAttributeCols[i] + ''', :' + CachedAttributeCols[i];
        Inc(UpdateFieldCount);
      end;
    end;
    AttributeUpdateSQL := AttributeUpdateSQL + ') WHERE document_id = :did';
    if UpdateFieldCount > 0 then
    begin
      QueryAttributeUpdate.SQL.Text := AttributeUpdateSQL;
      QueryAttributeUpdate.Prepare;
    end;
    SyncUpdateStatus('Importing typed records...');
    for r := 1 to Worksheet.GetLastRowIndex do
    begin
      BaseTitle := Trim(Worksheet.ReadAsText(r, FMapping[FTitleIndex].ColumnIndex));
      RowTextContent := TServiceImport.SanitizeText(Worksheet.ReadAsText(r, FMapping[FTextIndex].ColumnIndex));
      if (BaseTitle = '') and (RowTextContent = '') then Continue;
      TargetDocumentID := NewMonoLexID;
      FinalTitle := BaseTitle;
      if FinalTitle = '' then FinalTitle := 'Untitled-' + TargetDocumentID
      else FinalTitle := TServiceImport.GetUniqueTitle(QueryCheck, BaseTitle);
      QueryMain.Params.ParamByName('g').AsString := TargetDocumentID;
      QueryMain.Params.ParamByName('t').AsString := FinalTitle;
      QueryMain.Params.ParamByName('b').AsString := RowTextContent;
      QueryMain.ExecSQL;
      if UpdateFieldCount > 0 then
      begin
        QueryAttributeUpdate.Params.ParamByName('did').AsString := TargetDocumentID;
        for i := 0 to High(FMapping) do
        begin
          if CachedAttributeCols[i] <> '' then
          begin
            Cell := Worksheet.FindCell(r, FMapping[i].ColumnIndex);
            if Assigned(Cell) then
            begin
              if Cell^.ContentType = cctDateTime then
              begin
                if Worksheet.ReadAsDateTime(Cell, DummyDate) then
                  CellValue := FormatDateTime('yyyy-mm-dd', DummyDate)
                else
                  CellValue := '';
              end
              else if Cell^.ContentType = cctNumber then
                CellValue := FloatToStr(Worksheet.ReadAsNumber(Cell), InvariantFormat)
              else
                CellValue := Trim(Worksheet.ReadAsText(Cell));
            end
            else
              CellValue := '';
            if CellValue = '' then
              QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).Clear
            else
            begin
              if FMapping[i].AttributeType = 'Numeric' then
              begin
                if TDataParser.TryParseNumeric(CellValue, CleanValue) then
                  QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := CleanValue
                else begin QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).Clear; Inc(FInvalidCount); end;
              end
              else if FMapping[i].AttributeType = 'Date-Time' then
              begin
                if TDataParser.TryParseDate(CellValue, CleanValue) then
                  QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := CleanValue
                else begin QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).Clear; Inc(FInvalidCount); end;
              end
              else if FMapping[i].AttributeType = 'Categorical' then
              begin
                QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := TDataParser.ParseCategorical(CellValue);
              end
              else
                QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := CellValue;
            end;
          end;
        end;
        QueryAttributeUpdate.ExecSQL;
      end;
      Inc(FSuccessCount);
    end;
    FTransaction.Commit;
  finally
    Workbook.Free;
    QueryMain.Free; QueryUtil.Free; QueryCheck.Free; QueryAttributeUpdate.Free;
  end;
end;

class function TServiceImport.ImportSpreadsheet(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
var
  Workbook: TsWorkbook;
  Worksheet: TsWorksheet;
  SheetName, ColumnName: TStringList;
  SelectedSheetIndex, i, c, TitleIndex, TextIndex: Integer;
  CurrentMap: TColumnMap;
  frmSelector: TfrmDialogInput;
  frmModal: TfrmModalImport;
  MappingArray: TImportColumnMapArray;
  Worker: TThreadImportSpreadsheet;
begin
  Result := False;
  Workbook := TsWorkbook.Create;
  SheetName := TStringList.Create;
  ColumnName := TStringList.Create;
  try
    Workbook.ReadFromFile(AFileName);
    if Workbook.GetWorksheetCount = 0 then Exit;
    for i := 0 to Workbook.GetWorksheetCount - 1 do
      SheetName.Add(Workbook.GetWorksheetByIndex(i).Name);
    frmSelector := TfrmDialogInput.Create(nil);
    try
      if not frmSelector.Execute('Select Sheet', 'Select the worksheet to import', SheetName, SelectedSheetIndex) then Exit;
    finally
      frmSelector.Free;
    end;
    Worksheet := Workbook.GetWorksheetByIndex(SelectedSheetIndex);
    for c := 0 to Worksheet.GetLastColIndex do
    begin
      ColumnName.AddObject(Trim(Worksheet.ReadAsText(0, c)), TObject(PtrInt(c)));
    end;
    frmModal := TfrmModalImport.Create(nil);
    try
      if not frmModal.Execute(AConnection, ColumnName) then Exit;
      TitleIndex := -1; TextIndex := -1;
      SetLength(MappingArray, ColumnName.Count);
      for i := 0 to ColumnName.Count - 1 do
      begin
        CurrentMap := frmModal.GetMapping(i);
        MappingArray[i].ColumnName := ColumnName[i];
        MappingArray[i].ColumnIndex := PtrInt(ColumnName.Objects[i]);
        if Assigned(CurrentMap) then
        begin
          MappingArray[i].MapType := Ord(CurrentMap.MapType);
          MappingArray[i].AttributeMode := CurrentMap.AttributeMode;
          MappingArray[i].AttributeName := CurrentMap.AttributeName;
          MappingArray[i].AttributeType := CurrentMap.AttributeType;
          if CurrentMap.MapType = mtDocumentName then TitleIndex := i;
          if CurrentMap.MapType = mtDocumentText then TextIndex := i;
        end
        else MappingArray[i].MapType := 0;
      end;
      if AConnection.Transaction.Active then AConnection.Transaction.Commit;
      Worker := TThreadImportSpreadsheet.Create(AConnection.DatabaseName);
      try
        Worker.FFileName := AFileName;
        Worker.FSheetIndex := SelectedSheetIndex;
        Worker.FMapping := MappingArray;
        Worker.FTitleIndex := TitleIndex;
        Worker.FTextIndex := TextIndex;
        Worker.Start;
        TfrmDialogProgress.Prepare('Importing Data from Source', 'Connecting...');
        frmDialogProgress.ShowModal;
        if Worker.Success then
        begin
          if Worker.FInvalidCount > 0 then
            MessageDlg('Import Complete', Format('Successfully imported %d %s.' + sLineBreak + sLineBreak + 'Note: %d invalid %s encountered in Date-Time or Numeric target fields and excluded from import.', [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'document', 'documents'), Worker.FInvalidCount, TAppFormat.Pluralize(Worker.FInvalidCount, 'value was', 'values were')]), mtInformation, [mbOK], 0)
          else
            MessageDlg('Success', Format('Successfully imported %d %s.', [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'document', 'documents')]), mtInformation, [mbOK], 0);
          Result := True;
        end
        else
          MessageDlg('Import Error', 'Failed to import spreadsheet: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
      finally
        Worker.Free;
      end;
    finally
      frmModal.Free;
    end;
  finally
    ColumnName.Free;
    SheetName.Free;
    Workbook.Free;
  end;
end;

procedure TThreadImportJSON.DoHeavyLifting;
var
  JSONData: TJSONData;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  r, i, UpdateFieldCount: Integer;
  TargetDocumentID, AttributeUpdateSQL, NewAttributeID, CurrentAttribute: String;
  BaseTitle, FinalTitle, CellValue, RowTextContent, CleanValue: String;
  QueryMain, QueryUtil, QueryCheck, QueryAttributeUpdate: TSQLQuery;
  CachedAttributeCols: array of String;
begin
  FInvalidCount := 0; FSuccessCount := 0;
  QueryMain := TSQLQuery.Create(nil);
  QueryUtil := TSQLQuery.Create(nil);
  QueryCheck := TSQLQuery.Create(nil);
  QueryAttributeUpdate := TSQLQuery.Create(nil);
  try
    QueryMain.Database := FConnection; QueryMain.Transaction := FTransaction;
    QueryUtil.Database := FConnection; QueryUtil.Transaction := FTransaction;
    QueryCheck.Database := FConnection; QueryCheck.Transaction := FTransaction;
    QueryAttributeUpdate.Database := FConnection; QueryAttributeUpdate.Transaction := FTransaction;
    SyncUpdateStatus('Parsing JSON structures...');
    with TStringList.Create do
    try
      LoadFromFile(FFileName);
      JSONData := GetJSON(Text);
    finally
      Free;
    end;
    if (JSONData = nil) or (JSONData.JSONType <> jtArray) then Exit;
    JSONArray := TJSONArray(JSONData);
    if not FTransaction.Active then FTransaction.StartTransaction;
    SetLength(CachedAttributeCols, Length(FMapping));
    for i := 0 to High(FMapping) do
    begin
      CachedAttributeCols[i] := '';
      if (FMapping[i].MapType = 3) and (Trim(FMapping[i].AttributeName) <> '') then
      begin
        CurrentAttribute := Trim(FMapping[i].AttributeName);
        QueryUtil.Close;
        QueryUtil.SQL.Text := 'SELECT id, attribute_key FROM attribute_registry WHERE name = :n';
        QueryUtil.Params.ParamByName('n').AsString := CurrentAttribute;
        QueryUtil.Open;
        if not QueryUtil.EOF then
          CachedAttributeCols[i] := QueryUtil.FieldByName('attribute_key').AsString
        else
        begin
          NewAttributeID := NewMonoLexID;
          CachedAttributeCols[i] := TServiceImport.GetSafeColumnName(NewAttributeID);
          QueryUtil.Close;
          QueryUtil.SQL.Text := 'INSERT INTO attribute_registry (id, name, attribute_key, attribute_type) VALUES (:g, :n, :c, :tp)';
          QueryUtil.Params.ParamByName('g').AsString := NewAttributeID;
          QueryUtil.Params.ParamByName('n').AsString := CurrentAttribute;
          QueryUtil.Params.ParamByName('c').AsString := CachedAttributeCols[i];
          QueryUtil.Params.ParamByName('tp').AsString := FMapping[i].AttributeType;
          QueryUtil.ExecSQL;
        end;
        QueryUtil.Close;
      end;
    end;
    QueryMain.Close;
    QueryMain.SQL.Text := 'INSERT INTO documents (id, title, content) VALUES (:g, :t, :b)';
    QueryMain.Prepare;
    AttributeUpdateSQL := 'UPDATE document_attributes SET attributes = json_set(attributes';
    UpdateFieldCount := 0;
    for i := 0 to High(FMapping) do
    begin
      if CachedAttributeCols[i] <> '' then
      begin
        if FMapping[i].AttributeType = 'Numeric' then
          AttributeUpdateSQL := AttributeUpdateSQL + ', ''$.' + CachedAttributeCols[i] + ''', json(:' + CachedAttributeCols[i] + ')'
        else
          AttributeUpdateSQL := AttributeUpdateSQL + ', ''$.' + CachedAttributeCols[i] + ''', :' + CachedAttributeCols[i];
        Inc(UpdateFieldCount);
      end;
    end;
    AttributeUpdateSQL := AttributeUpdateSQL + ') WHERE document_id = :did';
    if UpdateFieldCount > 0 then
    begin
      QueryAttributeUpdate.SQL.Text := AttributeUpdateSQL;
      QueryAttributeUpdate.Prepare;
    end;
    SyncUpdateStatus('Importing strict typed JSON records...');
    for r := 0 to JSONArray.Count - 1 do
    begin
      if JSONArray.Items[r].JSONType <> jtObject then Continue;
      JSONObject := TJSONObject(JSONArray.Items[r]);
      BaseTitle := Trim(JSONObject.Get(FMapping[FTitleIndex].ColumnName, ''));
      RowTextContent := TServiceImport.SanitizeText(JSONObject.Get(FMapping[FTextIndex].ColumnName, ''));
      if (BaseTitle = '') and (RowTextContent = '') then Continue;
      TargetDocumentID := NewMonoLexID;
      FinalTitle := BaseTitle;
      if FinalTitle = '' then FinalTitle := 'Untitled-' + TargetDocumentID
      else FinalTitle := TServiceImport.GetUniqueTitle(QueryCheck, BaseTitle);
      QueryMain.Params.ParamByName('g').AsString := TargetDocumentID;
      QueryMain.Params.ParamByName('t').AsString := FinalTitle;
      QueryMain.Params.ParamByName('b').AsString := RowTextContent;
      QueryMain.ExecSQL;
      if UpdateFieldCount > 0 then
      begin
        QueryAttributeUpdate.Params.ParamByName('did').AsString := TargetDocumentID;
        for i := 0 to High(FMapping) do
        begin
          if CachedAttributeCols[i] <> '' then
          begin
            CellValue := Trim(JSONObject.Get(FMapping[i].ColumnName, ''));
            if CellValue = '' then
              QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).Clear
            else
            begin
              if FMapping[i].AttributeType = 'Numeric' then
              begin
                if TDataParser.TryParseNumeric(CellValue, CleanValue) then
                  QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := CleanValue
                else begin QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).Clear; Inc(FInvalidCount); end;
              end
              else if FMapping[i].AttributeType = 'Date-Time' then
              begin
                if TDataParser.TryParseDate(CellValue, CleanValue) then
                  QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := CleanValue
                else begin QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).Clear; Inc(FInvalidCount); end;
              end
              else if FMapping[i].AttributeType = 'Categorical' then
                QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := TDataParser.ParseCategorical(CellValue)
              else
                QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := CellValue;
            end;
          end;
        end;
        QueryAttributeUpdate.ExecSQL;
      end;
      Inc(FSuccessCount);
    end;
    FTransaction.Commit;
  finally
    if Assigned(JSONData) then JSONData.Free;
    QueryMain.Free; QueryUtil.Free; QueryCheck.Free; QueryAttributeUpdate.Free;
  end;
end;

class function TServiceImport.ImportJSON(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
var
  JSONData: TJSONData;
  JSONArray: TJSONArray;
  ColumnName: TStringList;
  i, r, TitleIndex, TextIndex: Integer;
  CurrentMap: TColumnMap;
  frmModal: TfrmModalImport;
  MappingArray: TImportColumnMapArray;
  Worker: TThreadImportJSON;
begin
  Result := False;
  JSONData := nil;
  ColumnName := TStringList.Create;
  try
    with TStringList.Create do
    try
      LoadFromFile(AFileName);
      JSONData := GetJSON(Text);
    finally
      Free;
    end;
    if (JSONData = nil) or (JSONData.JSONType <> jtArray) then
    begin
      MessageDlg('Error', 'JSON must contain an Array of records.', mtWarning, [mbOK], 0);
      Exit;
    end;
    JSONArray := TJSONArray(JSONData);
    ColumnName.Sorted := True;
    ColumnName.Duplicates := dupIgnore;
    for r := 0 to JSONArray.Count - 1 do
      if JSONArray.Items[r].JSONType = jtObject then
        for i := 0 to TJSONObject(JSONArray.Items[r]).Count - 1 do
          ColumnName.Add(TJSONObject(JSONArray.Items[r]).Names[i]);
    frmModal := TfrmModalImport.Create(nil);
    try
      if not frmModal.Execute(AConnection, ColumnName) then Exit;
      TitleIndex := -1; TextIndex := -1;
      SetLength(MappingArray, ColumnName.Count);
      for i := 0 to ColumnName.Count - 1 do
      begin
        CurrentMap := frmModal.GetMapping(i);
        MappingArray[i].ColumnName := ColumnName[i];
        if Assigned(CurrentMap) then
        begin
          MappingArray[i].MapType := Ord(CurrentMap.MapType);
          MappingArray[i].AttributeMode := CurrentMap.AttributeMode;
          MappingArray[i].AttributeName := CurrentMap.AttributeName;
          MappingArray[i].AttributeType := CurrentMap.AttributeType;
          if CurrentMap.MapType = mtDocumentName then TitleIndex := i;
          if CurrentMap.MapType = mtDocumentText then TextIndex := i;
        end
        else MappingArray[i].MapType := 0;
      end;
      if AConnection.Transaction.Active then AConnection.Transaction.Commit;
      Worker := TThreadImportJSON.Create(AConnection.DatabaseName);
      try
        Worker.FFileName := AFileName;
        Worker.FMapping := MappingArray;
        Worker.FTitleIndex := TitleIndex;
        Worker.FTextIndex := TextIndex;
        Worker.Start;
        TfrmDialogProgress.Prepare('Importing Data from Source', 'Connecting...');
        frmDialogProgress.ShowModal;
        if Worker.Success then
        begin
          if Worker.FInvalidCount > 0 then
            MessageDlg('Import Complete', Format('Successfully imported %d %s.' + sLineBreak + sLineBreak + 'Note: %d invalid %s encountered in Date-Time or Numeric target fields and excluded from import.', [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'document', 'documents'), Worker.FInvalidCount, TAppFormat.Pluralize(Worker.FInvalidCount, 'value was', 'values were')]), mtInformation, [mbOK], 0)
          else
            MessageDlg('Success', Format('Successfully imported %d %s.', [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'document', 'documents')]), mtInformation, [mbOK], 0);
          Result := True;
        end
        else
          MessageDlg('Import Error', 'Failed to import JSON: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
      finally
        Worker.Free;
      end;
    finally
      frmModal.Free;
    end;
  finally
    if Assigned(JSONData) then JSONData.Free;
    ColumnName.Free;
  end;
end;

procedure TThreadImportSQLite.DoHeavyLifting;
var
  ImportConn: TSQLite3Connection;
  ImportTrn: TSQLTransaction;
  QueryImport, QueryMain, QueryUtil, QueryCheck, QueryAttributeUpdate: TSQLQuery;
  r, i, UpdateFieldCount: Integer;
  TargetDocumentID, AttributeUpdateSQL, NewAttributeID, CurrentAttribute: String;
  BaseTitle, FinalTitle, CellValue, RowTextContent, CleanValue: String;
  CachedAttributeCols: array of String;
begin
  FInvalidCount := 0; FSuccessCount := 0;
  ImportConn := TSQLite3Connection.Create(nil);
  ImportTrn := TSQLTransaction.Create(nil);
  QueryImport := TSQLQuery.Create(nil);
  QueryMain := TSQLQuery.Create(nil);
  QueryUtil := TSQLQuery.Create(nil);
  QueryCheck := TSQLQuery.Create(nil);
  QueryAttributeUpdate := TSQLQuery.Create(nil);
  try
    ImportConn.Transaction := ImportTrn;
    QueryImport.Database := ImportConn; QueryImport.Transaction := ImportTrn;
    QueryMain.Database := FConnection; QueryMain.Transaction := FTransaction;
    QueryUtil.Database := FConnection; QueryUtil.Transaction := FTransaction;
    QueryCheck.Database := FConnection; QueryCheck.Transaction := FTransaction;
    QueryAttributeUpdate.Database := FConnection; QueryAttributeUpdate.Transaction := FTransaction;
    SyncUpdateStatus('Connecting to source database...');
    ImportConn.DatabaseName := FFileName;
    ImportConn.Open;
    if not FTransaction.Active then FTransaction.StartTransaction;
    SetLength(CachedAttributeCols, Length(FMapping));
    for i := 0 to High(FMapping) do
    begin
      CachedAttributeCols[i] := '';
      if (FMapping[i].MapType = 3) and (Trim(FMapping[i].AttributeName) <> '') then
      begin
        CurrentAttribute := Trim(FMapping[i].AttributeName);
        QueryUtil.Close;
        QueryUtil.SQL.Text := 'SELECT id, attribute_key FROM attribute_registry WHERE name = :n';
        QueryUtil.Params.ParamByName('n').AsString := CurrentAttribute;
        QueryUtil.Open;
        if not QueryUtil.EOF then
          CachedAttributeCols[i] := QueryUtil.FieldByName('attribute_key').AsString
        else
        begin
          NewAttributeID := NewMonoLexID;
          CachedAttributeCols[i] := TServiceImport.GetSafeColumnName(NewAttributeID);
          QueryUtil.Close;
          QueryUtil.SQL.Text := 'INSERT INTO attribute_registry (id, name, attribute_key, attribute_type) VALUES (:g, :n, :c, :tp)';
          QueryUtil.Params.ParamByName('g').AsString := NewAttributeID;
          QueryUtil.Params.ParamByName('n').AsString := CurrentAttribute;
          QueryUtil.Params.ParamByName('c').AsString := CachedAttributeCols[i];
          QueryUtil.Params.ParamByName('tp').AsString := FMapping[i].AttributeType;
          QueryUtil.ExecSQL;
        end;
        QueryUtil.Close;
      end;
    end;
    QueryMain.Close;
    QueryMain.SQL.Text := 'INSERT INTO documents (id, title, content) VALUES (:g, :t, :b)';
    QueryMain.Prepare;
    AttributeUpdateSQL := 'UPDATE document_attributes SET attributes = json_set(attributes';
    UpdateFieldCount := 0;
    for i := 0 to High(FMapping) do
    begin
      if CachedAttributeCols[i] <> '' then
      begin
        if FMapping[i].AttributeType = 'Numeric' then
          AttributeUpdateSQL := AttributeUpdateSQL + ', ''$.' + CachedAttributeCols[i] + ''', json(:' + CachedAttributeCols[i] + ')'
        else
          AttributeUpdateSQL := AttributeUpdateSQL + ', ''$.' + CachedAttributeCols[i] + ''', :' + CachedAttributeCols[i];
        Inc(UpdateFieldCount);
      end;
    end;
    AttributeUpdateSQL := AttributeUpdateSQL + ') WHERE document_id = :did';
    if UpdateFieldCount > 0 then
    begin
      QueryAttributeUpdate.SQL.Text := AttributeUpdateSQL;
      QueryAttributeUpdate.Prepare;
    end;
    SyncUpdateStatus('Importing typed records...');
    QueryImport.SQL.Text := 'SELECT * FROM ' + FTableName;
    QueryImport.Open;
    while not QueryImport.EOF do
    begin
      BaseTitle := Trim(QueryImport.Fields[FMapping[FTitleIndex].ColumnIndex].AsString);
      RowTextContent := TServiceImport.SanitizeText(QueryImport.Fields[FMapping[FTextIndex].ColumnIndex].AsString);
      if (BaseTitle = '') and (RowTextContent = '') then 
      begin
        QueryImport.Next;
        Continue;
      end;
      TargetDocumentID := NewMonoLexID;
      FinalTitle := BaseTitle;
      if FinalTitle = '' then FinalTitle := 'Untitled-' + TargetDocumentID
      else FinalTitle := TServiceImport.GetUniqueTitle(QueryCheck, BaseTitle);
      QueryMain.Params.ParamByName('g').AsString := TargetDocumentID;
      QueryMain.Params.ParamByName('t').AsString := FinalTitle;
      QueryMain.Params.ParamByName('b').AsString := RowTextContent;
      QueryMain.ExecSQL;
      if UpdateFieldCount > 0 then
      begin
        QueryAttributeUpdate.Params.ParamByName('did').AsString := TargetDocumentID;
        for i := 0 to High(FMapping) do
        begin
          if CachedAttributeCols[i] <> '' then
          begin
            CellValue := Trim(QueryImport.Fields[FMapping[i].ColumnIndex].AsString);
            if CellValue = '' then
              QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).Clear
            else
            begin
              if FMapping[i].AttributeType = 'Numeric' then
              begin
                if TDataParser.TryParseNumeric(CellValue, CleanValue) then
                  QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := CleanValue
                else begin QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).Clear; Inc(FInvalidCount); end;
              end
              else if FMapping[i].AttributeType = 'Date-Time' then
              begin
                if TDataParser.TryParseDate(CellValue, CleanValue) then
                  QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := CleanValue
                else begin QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).Clear; Inc(FInvalidCount); end;
              end
              else if FMapping[i].AttributeType = 'Categorical' then
                QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := TDataParser.ParseCategorical(CellValue)
              else
                QueryAttributeUpdate.Params.ParamByName(CachedAttributeCols[i]).AsString := CellValue;
            end;
          end;
        end;
        QueryAttributeUpdate.ExecSQL;
      end;
      Inc(FSuccessCount);
      QueryImport.Next;
    end;
    FTransaction.Commit;
  finally
    if ImportConn.Connected then ImportConn.Close;
    ImportConn.Free; ImportTrn.Free;
    QueryImport.Free; QueryMain.Free; QueryUtil.Free; QueryCheck.Free; QueryAttributeUpdate.Free;
  end;
end;

class function TServiceImport.ImportSQLite(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
var
  TableName, ColumnName: TStringList;
  SelectedTableIndex, i, TitleIndex, TextIndex: Integer;
  CurrentMap: TColumnMap;
  frmSelector: TfrmDialogInput;
  frmModal: TfrmModalImport;
  ImportConn: TSQLite3Connection;
  ImportTrn: TSQLTransaction;
  QueryImport: TSQLQuery;
  MappingArray: TImportColumnMapArray;
  Worker: TThreadImportSQLite;
begin
  Result := False;
  TableName := TStringList.Create;
  ColumnName := TStringList.Create;
  ImportConn := TSQLite3Connection.Create(nil);
  ImportTrn := TSQLTransaction.Create(nil);
  QueryImport := TSQLQuery.Create(nil);
  try
    ImportConn.Transaction := ImportTrn;
    QueryImport.Database := ImportConn;
    QueryImport.Transaction := ImportTrn;
    ImportConn.DatabaseName := AFileName;
    try
      ImportConn.Open;
      QueryImport.SQL.Text := 'SELECT name FROM sqlite_master WHERE type="table" AND name NOT LIKE "sqlite_%"';
      QueryImport.Open;
      while not QueryImport.EOF do
      begin
        TableName.Add(QueryImport.FieldByName('name').AsString);
        QueryImport.Next;
      end;
      QueryImport.Close;
      frmSelector := TfrmDialogInput.Create(nil);
      try
        if not frmSelector.Execute('Source Table', 'Select table to import', TableName, SelectedTableIndex) then Exit;
      finally
        frmSelector.Free;
      end;
      QueryImport.SQL.Text := 'SELECT * FROM ' + TableName[SelectedTableIndex] + ' LIMIT 1';
      QueryImport.Open;
      QueryImport.FieldDefs.GetItemNames(ColumnName);
      QueryImport.Close;
      ImportConn.Close;
    except
      on E: Exception do
      begin
        MessageDlg('Database Error', 'Could not read source database: ' + E.Message, mtError, [mbOK], 0);
        Exit;
      end;
    end;
    frmModal := TfrmModalImport.Create(nil);
    try
      if not frmModal.Execute(AConnection, ColumnName) then Exit;
      TitleIndex := -1; TextIndex := -1;
      SetLength(MappingArray, ColumnName.Count);
      for i := 0 to ColumnName.Count - 1 do
      begin
        CurrentMap := frmModal.GetMapping(i);
        MappingArray[i].ColumnName := ColumnName[i];
        MappingArray[i].ColumnIndex := i;
        if Assigned(CurrentMap) then
        begin
          MappingArray[i].MapType := Ord(CurrentMap.MapType);
          MappingArray[i].AttributeMode := CurrentMap.AttributeMode;
          MappingArray[i].AttributeName := CurrentMap.AttributeName;
          MappingArray[i].AttributeType := CurrentMap.AttributeType;
          if CurrentMap.MapType = mtDocumentName then TitleIndex := i;
          if CurrentMap.MapType = mtDocumentText then TextIndex := i;
        end
        else MappingArray[i].MapType := 0;
      end;
      if AConnection.Transaction.Active then AConnection.Transaction.Commit;
      Worker := TThreadImportSQLite.Create(AConnection.DatabaseName);
      try
        Worker.FFileName := AFileName;
        Worker.FTableName := TableName[SelectedTableIndex];
        Worker.FMapping := MappingArray;
        Worker.FTitleIndex := TitleIndex;
        Worker.FTextIndex := TextIndex;
        Worker.Start;
        TfrmDialogProgress.Prepare('Importing Data from Source', 'Connecting...');
        frmDialogProgress.ShowModal;
        if Worker.Success then
        begin
          if Worker.FInvalidCount > 0 then
            MessageDlg('Import Complete', Format('Successfully imported %d %s.' + sLineBreak + sLineBreak + 'Note: %d invalid %s encountered in Date-Time or Numeric target fields and excluded from import.', [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'document', 'documents'), Worker.FInvalidCount, TAppFormat.Pluralize(Worker.FInvalidCount, 'value was', 'values were')]), mtInformation, [mbOK], 0)
          else
            MessageDlg('Success', Format('Successfully imported %d %s.', [Worker.FSuccessCount, TAppFormat.Pluralize(Worker.FSuccessCount, 'document', 'documents')]), mtInformation, [mbOK], 0);
          Result := True;
        end
        else
          MessageDlg('Import Error', 'Failed to import database: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
      finally
        Worker.Free;
      end;
    finally
      frmModal.Free;
    end;
  finally
    if ImportConn.Connected then ImportConn.Close;
    ImportConn.Free;
    ImportTrn.Free;
    QueryImport.Free;
    TableName.Free;
    ColumnName.Free;
  end;
end;

initialization
  FPDF_InitLibrary;

finalization
  FPDF_DestroyLibrary;

end.
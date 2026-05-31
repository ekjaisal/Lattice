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

unit ServiceExport;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Graphics, SysUtils, Types, fpspreadsheet, fpsTypes, SQLDB, SQLite3Conn,
  Cairo, BridgeLibrary;

const
  PDF_METADATA_TITLE = 0;
  PDF_METADATA_AUTHOR = 1;
  PDF_METADATA_SUBJECT = 2;
  PDF_METADATA_KEYWORDS = 3;
  PDF_METADATA_CREATOR = 4;
  PDF_METADATA_CREATE_DATE = 5;
  PDF_METADATA_MOD_DATE = 6;

type
  EDataExportException = class(Exception);

  TPDFReportContext = record
    Surface: Pcairo_surface_t;
    Context: Pcairo_t;
    Layout: Ppango_layout_t;
    CurrentY: Double;
    PageNum: Integer;
    FontStack: String;
    ProjectTitle: String;
    SortDescription: String;
    FontH1: Ppango_font_description_t;
    FontSub: Ppango_font_description_t;
    FontFoot: Ppango_font_description_t;
    FontBody: Ppango_font_description_t;
    FontMeta: Ppango_font_description_t;
    FontCont: Ppango_font_description_t;
    CardBackground: Pcairo_pattern_t;
  end;

  TGetPathEvent = function(const CodeID: String): String of object;
  TVisualisationRenderEvent = procedure(cr: Pcairo_t; AWidth, AHeight: Integer) of object;
  T2DStringArray = array of TStringDynArray;

  TServiceExport = class
  private
    const
      SPREADSHEET_PER_CELL_LIMIT = 32767;
      A4_WIDTH = 595.28;
      A4_HEIGHT = 841.89;
      MARGIN = 50.0;
      CARD_WIDTH = 495.28;
      CARD_PADDING = 14.0;
      ACCENT_WIDTH = 4.0;
      GUTTER = 12.0;
      CORNER_RADIUS = 7.0;
      TARGET_LOGO_HEIGHT = 40;
    class function CleanFieldName(const FieldName: String): String;
    class function EscapeJSON(const AText: String): String;
    class function EscapeXML(const AText: String): String;
    class function FastExtractUTF8(const S: String; StartCharacter, LengthCharacter: Integer): String;
    class function FormatPascalCase(const AText: String): String;
    class function InitPDFContext(const AFileName, ASortDescription: String; out AContext: TPDFReportContext): Boolean;
    class function SanitizeCSVField(const AText: String): String;
    class function SaveMemoAsCSV(AConnection: TSQLite3Connection; const AFileName, IDList: String): Boolean;
    class function SaveMemoAsJSON(AConnection: TSQLite3Connection; const AFileName, IDList: String): Boolean;
    class function SaveMemoAsSpreadsheet(AConnection: TSQLite3Connection; const AFileName, IDList: String; AFormat: TsSpreadsheetFormat): Boolean;
    class function SaveMemoAsXML(AConnection: TSQLite3Connection; const AFileName, IDList: String): Boolean;
    class function SaveRetrievedSegmentAsCSV(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray): Boolean;
    class function SaveRetrievedSegmentAsHTML(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray; const ASortDescription: String): Boolean;
    class function SaveRetrievedSegmentAsJSON(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray): Boolean;
    class function SaveRetrievedSegmentAsPDF(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray; const ASortDescription: String): Boolean;
    class function SaveRetrievedSegmentAsSpreadsheet(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray; AFormat: TsSpreadsheetFormat): Boolean;
    class function SaveRetrievedSegmentAsXML(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray): Boolean;
    class procedure DrawFooter(var AContext: TPDFReportContext);
    class procedure FinalizePDFContext(var AContext: TPDFReportContext);
    class procedure NewPage(var AContext: TPDFReportContext; IsFirstPage: Boolean);
    class procedure PathRoundedRect(cr: Pcairo_t; x, y, w, h, r: Double);
    class procedure RenderSegmentCard(var AContext: TPDFReportContext; const ASegment, AMetaString: String; AColor: TColor);
    class procedure WriteToStream(AStream: TStream; const AText: String);
  public
    class function ExportCodebook(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
    class function ExportCodeSystem(AQuery: TSQLQuery; const AFileName: String): Boolean;
    class function ExportDataTable(const Header, DataKeys: TStringDynArray; const GridData: T2DStringArray; const AFileName: String): Boolean;
    class function ExportDocumentJSON(AConnection: TSQLite3Connection; const AFileName: String; const ADocumentID: TStringDynArray): Boolean;
    class function ExportDocumentSheet(AConnection: TSQLite3Connection; const AFileName: String; const ADocumentID: TStringDynArray; AFormat: TsSpreadsheetFormat): Boolean;
    class function ExportDocumentText(AConnection: TSQLite3Connection; const ADirectoryPath: String; const ADocumentID: TStringDynArray): Boolean;
    class function ExportDocumentXML(AConnection: TSQLite3Connection; const AFileName: String; const ADocumentID: TStringDynArray): Boolean;
    class function ExportMemo(AConnection: TSQLite3Connection; const AFileName, IDList: String): Boolean;
    class function ExportRetrievedSegment(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray; const ASortDescription: String): Boolean;
    class function ExportVisualisation(const AFileName, AProjectTitle, ASubject: String; AWidth, AHeight: Integer; ARenderEvent: TVisualisationRenderEvent): Boolean;
    class function ValidateAndFixUTF8(const AText: String): String;
  end;

implementation

uses
  Dialogs, fpjson, jsonparser, LazUTF8, Math, AppBase, AppFont, AppIdentity,
  DialogProgress, ServiceThread, {%H-}xlsxOOXML, {%H-}fpsopendocument;

type
  TThreadExportMemo = class(TBackgroundWorker)
  public
    FFileName: String;
    FIDList: String;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadExportDocumentText = class(TBackgroundWorker)
  public
    FDirectoryPath: String;
    FDocumentID: TStringDynArray;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadExportDocumentSheet = class(TBackgroundWorker)
  public
    FFileName: String;
    FDocumentID: TStringDynArray;
    FFormat: TsSpreadsheetFormat;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadExportDocumentJSON = class(TBackgroundWorker)
  public
    FFileName: String;
    FDocumentID: TStringDynArray;
  protected
    procedure DoHeavyLifting; override;
  end;

  TThreadExportDocumentXML = class(TBackgroundWorker)
  public
    FFileName: String;
    FDocumentID: TStringDynArray;
  protected
    procedure DoHeavyLifting; override;
  end;

class procedure TServiceExport.WriteToStream(AStream: TStream; const AText: String);
var
  UTF8Str: RawByteString;
begin
  if AText = '' then Exit;
  UTF8Str := UTF8Encode(AText);
  if Length(UTF8Str) > 0 then
    AStream.WriteBuffer(UTF8Str[1], Length(UTF8Str));
end;

class function TServiceExport.ValidateAndFixUTF8(const AText: String): String;
var
  Buffer: String;
begin
  if AText = '' then
  begin
    Result := '';
    Exit;
  end;
  Buffer := AText;
  UTF8FixBroken(Buffer);
  Result := Buffer;
end;

class function TServiceExport.FastExtractUTF8(const S: String; StartCharacter, LengthCharacter: Integer): String;
var
  P, StartPointer, EndPointer: PChar;
  C: Integer;
begin
  if (S = '') or (LengthCharacter <= 0) then Exit('');
  P := PChar(S);
  C := 0;
  while (C < StartCharacter) and (P^ <> #0) do
  begin
    Inc(P, UTF8CodepointSize(P));
    Inc(C);
  end;
  StartPointer := P;
  C := 0;
  while (C < LengthCharacter) and (P^ <> #0) do
  begin
    Inc(P, UTF8CodepointSize(P));
    Inc(C);
  end;
  EndPointer := P;
  SetString(Result, StartPointer, EndPointer - StartPointer);
end;

class function TServiceExport.CleanFieldName(const FieldName: String): String;
begin
  if Copy(FieldName, 1, 11) = 'Attribute: ' then
    Result := Copy(FieldName, 12, MaxInt)
  else
    Result := FieldName;
end;

class function TServiceExport.FormatPascalCase(const AText: String): String;
var
  i: Integer;
  C: Char;
  NextCap: Boolean;
  S: String;
begin
  S := StringReplace(AText, '%', 'Percentage', [rfReplaceAll]);
  Result := '';
  NextCap := True;
  for i := 1 to Length(S) do
  begin
    C := S[i];
    if (C in ['A'..'Z', 'a'..'z', '0'..'9']) then
    begin
      if NextCap then
      begin
        Result := Result + UpCase(C);
        NextCap := False;
      end
      else
        Result := Result + C;
    end
    else
    begin
      NextCap := True; 
    end;
  end;
end;

class function TServiceExport.SanitizeCSVField(const AText: String): String;
var
  S: String;
begin
  if AText = '' then Exit('""');
  S := StringReplace(AText, '"', '""', [rfReplaceAll]);
  S := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  S := StringReplace(S, #13, #10, [rfReplaceAll]);
  S := StringReplace(S, #10, #13#10, [rfReplaceAll]); 
  Result := '"' + S + '"';
end;

class function TServiceExport.EscapeXML(const AText: String): String;
begin
  Result := AText;
  Result := StringReplace(Result, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&#39;', [rfReplaceAll]);
end;

class function TServiceExport.EscapeJSON(const AText: String): String;
begin
  Result := AText;
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\r', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '\t', [rfReplaceAll]);
end;

class function TServiceExport.InitPDFContext(const AFileName, ASortDescription: String; out AContext: TPDFReportContext): Boolean;
var
  FontMap: Ppango_font_map_t;
  FontOptions: Pointer;
  SurfaceStatus: cairo_status_t;
  ContextStatus: cairo_status_t;
begin
  Result := False;
  {$IFDEF WINDOWS}
  FontMap := pango_win32_font_map_for_display;
  if Assigned(FontMap) then
    pango_cairo_font_map_set_default(FontMap);
  {$ENDIF}
  AContext.Surface := cairo_pdf_surface_create(PChar(AFileName), A4_WIDTH, A4_HEIGHT);
  SurfaceStatus := cairo_surface_status(AContext.Surface);
  if SurfaceStatus <> CAIRO_STATUS_SUCCESS then
    raise Exception.Create('Failed to create PDF surface: ' + String(cairo_status_to_string(SurfaceStatus)));
  cairo_surface_set_fallback_resolution(AContext.Surface, 720.0, 720.0);
  AContext.ProjectTitle := ChangeFileExt(ExtractFileName(frmAppBase.conMain.DatabaseName), '');
  AContext.SortDescription := ASortDescription;
  cairo_pdf_surface_set_metadata(AContext.Surface, PDF_METADATA_CREATOR, PChar(APP_ATTRIBUTION));
  cairo_pdf_surface_set_metadata(AContext.Surface, PDF_METADATA_TITLE, PChar('Coding Report'));
  cairo_pdf_surface_set_metadata(AContext.Surface, PDF_METADATA_SUBJECT, PChar(ValidateAndFixUTF8(AContext.ProjectTitle)));
  AContext.Context := cairo_create(AContext.Surface);
  ContextStatus := cairo_status(AContext.Context);
  if ContextStatus <> CAIRO_STATUS_SUCCESS then
  begin
    cairo_surface_destroy(AContext.Surface);
    raise Exception.Create('Failed to create Cairo context: ' + String(cairo_status_to_string(ContextStatus)));
  end;
  AContext.Layout := pango_cairo_create_layout(AContext.Context);
  FontOptions := cairo_font_options_create;
  cairo_font_options_set_antialias(FontOptions, CAIRO_ANTIALIAS_BEST);
  cairo_font_options_set_hint_style(FontOptions, CAIRO_HINT_STYLE_SLIGHT);
  pango_cairo_context_set_font_options(pango_layout_get_context(AContext.Layout), FontOptions);
  cairo_font_options_destroy(FontOptions);
  pango_cairo_context_set_resolution(pango_layout_get_context(AContext.Layout), 96.0);
  pango_layout_set_wrap(AContext.Layout, PANGO_WRAP_WORD_CHAR);
  AContext.FontStack := GetUniversalFontStack;
  AContext.PageNum := 1;
  AContext.CurrentY := MARGIN;
  AContext.FontH1 := pango_font_description_from_string(PChar(AContext.FontStack + ' Bold 18'));
  AContext.FontSub := pango_font_description_from_string(PChar(AContext.FontStack + ' 7'));
  AContext.FontFoot := pango_font_description_from_string(PChar(AContext.FontStack + ' 7'));
  AContext.FontBody := pango_font_description_from_string(PChar(AContext.FontStack + ' 9'));
  AContext.FontMeta := pango_font_description_from_string(PChar(AContext.FontStack + ' 7'));
  AContext.FontCont := pango_font_description_from_string(PChar(AContext.FontStack + ' Italic 7'));
  AContext.CardBackground := cairo_pattern_create_linear(0, 0, 0, 1.0);
  cairo_pattern_add_color_stop_rgba(AContext.CardBackground, 0.0, 0.98, 0.96, 0.98, 1.0);
  cairo_pattern_add_color_stop_rgba(AContext.CardBackground, 1.0, 1.0, 0.99, 0.97, 1.0);
  Result := True;
end;

class procedure TServiceExport.NewPage(var AContext: TPDFReportContext; IsFirstPage: Boolean);
var
  ScaledWidth, TitleY: Double;
  SafeProjectTitle: String;
  TextHeight: Integer;
begin
  SafeProjectTitle := ValidateAndFixUTF8(AContext.ProjectTitle);
  cairo_set_source_rgb(AContext.Context, 0, 0, 0);
  if IsFirstPage then
  begin
    ScaledWidth := (TARGET_LOGO_HEIGHT / 2999.0) * 3515.0;
    cairo_tag_begin(AContext.Context, PChar(CAIRO_TAG_LINK), PChar('uri=''' + APP_URL + ''''));
    RenderAppLogo(AContext.Context, A4_WIDTH - MARGIN - ScaledWidth, MARGIN - 3.0, TARGET_LOGO_HEIGHT);
    cairo_tag_end(AContext.Context, PChar(CAIRO_TAG_LINK));
    cairo_set_source_rgb(AContext.Context, 0, 0, 0);
    pango_layout_set_font_description(AContext.Layout, AContext.FontH1);
    pango_layout_set_text(AContext.Layout, 'Coding Report', -1);
    pango_layout_get_pixel_size(AContext.Layout, nil, @TextHeight);
    TitleY := (MARGIN - 3.0) + (TARGET_LOGO_HEIGHT / 2.0) - (TextHeight / 2.0);
    cairo_move_to(AContext.Context, MARGIN, TitleY);
    pango_cairo_show_layout(AContext.Context, AContext.Layout);
    pango_layout_set_font_description(AContext.Layout, AContext.FontSub);
    cairo_set_source_rgb(AContext.Context, 0.45, 0.45, 0.45);
    pango_layout_set_text(AContext.Layout, PChar('Sorted by: ' + AContext.SortDescription), -1);
    cairo_move_to(AContext.Context, MARGIN, TitleY + TextHeight + 12.0);
    pango_cairo_show_layout(AContext.Context, AContext.Layout);
    AContext.CurrentY := TitleY + TextHeight + 45.0;
  end
  else
  begin
    pango_layout_set_font_description(AContext.Layout, AContext.FontFoot);
    cairo_set_source_rgb(AContext.Context, 0.6, 0.6, 0.6);
    pango_layout_set_text(AContext.Layout, PChar(SafeProjectTitle), -1);
    cairo_move_to(AContext.Context, MARGIN, MARGIN - 20.0);
    pango_cairo_show_layout(AContext.Context, AContext.Layout);
    AContext.CurrentY := MARGIN + 10.0;
  end;
end;

class procedure TServiceExport.DrawFooter(var AContext: TPDFReportContext);
var
  TextWidth, TextHeight: Integer;
  FooterText: String;
begin
  FooterText := 'Page ' + IntToStr(AContext.PageNum);
  pango_layout_set_font_description(AContext.Layout, AContext.FontFoot);
  pango_layout_set_text(AContext.Layout, PChar(FooterText), -1);
  pango_layout_get_pixel_size(AContext.Layout, @TextWidth, @TextHeight);
  cairo_set_source_rgb(AContext.Context, 0.6, 0.6, 0.6);
  cairo_move_to(AContext.Context, (A4_WIDTH / 2) - (TextWidth / 2), A4_HEIGHT - MARGIN + 10);
  pango_cairo_show_layout(AContext.Context, AContext.Layout);
end;

class procedure TServiceExport.FinalizePDFContext(var AContext: TPDFReportContext);
begin
  DrawFooter(AContext);
  cairo_pattern_destroy(AContext.CardBackground);
  pango_font_description_free(AContext.FontH1);
  pango_font_description_free(AContext.FontSub);
  pango_font_description_free(AContext.FontFoot);
  pango_font_description_free(AContext.FontBody);
  pango_font_description_free(AContext.FontMeta);
  pango_font_description_free(AContext.FontCont);
  g_object_unref(AContext.Layout);
  cairo_destroy(AContext.Context);
  cairo_surface_finish(AContext.Surface);
  cairo_surface_destroy(AContext.Surface);
end;

class procedure TServiceExport.PathRoundedRect(cr: Pcairo_t; x, y, w, h, r: Double);
begin
  cairo_new_path(cr);
  cairo_move_to(cr, x + r, y);
  cairo_line_to(cr, x + w - r, y);
  cairo_arc(cr, x + w - r, y + r, r, -Pi/2, 0);
  cairo_line_to(cr, x + w, y + h - r);
  cairo_arc(cr, x + w - r, y + h - r, r, 0, Pi/2);
  cairo_line_to(cr, x + r, y + h);
  cairo_arc(cr, x + r, y + h - r, r, Pi/2, Pi);
  cairo_line_to(cr, x, y + r);
  cairo_arc(cr, x + r, y + r, r, Pi, 3*Pi/2);
  cairo_close_path(cr);
end;

class procedure TServiceExport.RenderSegmentCard(var AContext: TPDFReportContext; const ASegment, AMetaString: String; AColor: TColor);
var
  TextWidth, TextHeight, MetadataWidth, MetadataHeight, ContinuationWidth, ContinuationHeight: Integer;
  R, G, B: Byte;
  SafeSegment, MetaStr, RemainingText, ChunkText: String;
  AvailableHeight, MaxTextHeight, SplitByteIndex: Integer;
  CardHeight, HeaderH, FooterH, AccHeight, LineHeight: Integer;
  TextY: Double;
  IsSplit, IsContinuation: Boolean;
  Iter: Pointer;
  LogicalRectangle: TPangoRectangle;
begin
  SafeSegment := ValidateAndFixUTF8(ASegment);
  MetaStr := ValidateAndFixUTF8(AMetaString);
  if SafeSegment = '' then SafeSegment := '[Empty segment]';
  pango_layout_set_width(AContext.Layout, Round((CARD_WIDTH - (CARD_PADDING * 2.0) - ACCENT_WIDTH - 12.0) * PANGO_SCALE));
  pango_layout_set_font_description(AContext.Layout, AContext.FontMeta);
  pango_layout_set_text(AContext.Layout, PChar(MetaStr), -1);
  pango_layout_get_pixel_size(AContext.Layout, @MetadataWidth, @MetadataHeight);
  pango_layout_set_font_description(AContext.Layout, AContext.FontCont);
  pango_layout_set_text(AContext.Layout, 'Segment continued on next page...', -1);
  pango_layout_get_pixel_size(AContext.Layout, @ContinuationWidth, @ContinuationHeight);
  RemainingText := SafeSegment;
  IsContinuation := False;
  while RemainingText <> '' do
  begin
    AvailableHeight := Round(A4_HEIGHT - MARGIN - 30.0 - AContext.CurrentY);
    if AvailableHeight < 100 then
    begin
      DrawFooter(AContext);
      cairo_show_page(AContext.Context);
      Inc(AContext.PageNum);
      NewPage(AContext, False);
      AvailableHeight := Round(A4_HEIGHT - MARGIN - 30.0 - AContext.CurrentY);
    end;
    if IsContinuation then HeaderH := ContinuationHeight + 8 else HeaderH := 0;
    pango_layout_set_font_description(AContext.Layout, AContext.FontBody);
    pango_layout_set_text(AContext.Layout, PChar(RemainingText), Length(RemainingText));
    pango_layout_get_pixel_size(AContext.Layout, @TextWidth, @TextHeight);
    MaxTextHeight := AvailableHeight - Round(CARD_PADDING * 2.0) - HeaderH - 8 - Max(MetadataHeight, ContinuationHeight);
    IsSplit := False;
    if TextHeight > MaxTextHeight then
    begin
      Iter := pango_layout_get_iter(AContext.Layout);
      AccHeight := 0;
      SplitByteIndex := 0;
      if Assigned(Iter) then
      begin
        repeat
          pango_layout_iter_get_line_extents(Iter, nil, @LogicalRectangle);
          LineHeight := LogicalRectangle.Height div PANGO_SCALE;
          if AccHeight + LineHeight > MaxTextHeight then
          begin
            SplitByteIndex := pango_layout_iter_get_index(Iter);
            break;
          end;
          AccHeight := AccHeight + LineHeight;
        until not pango_layout_iter_next_line(Iter);
        pango_layout_iter_free(Iter);
      end;
      if SplitByteIndex = 0 then
      begin
        DrawFooter(AContext);
        cairo_show_page(AContext.Context);
        Inc(AContext.PageNum);
        NewPage(AContext, False);
        Continue;
      end;
      ChunkText := TrimRight(Copy(RemainingText, 1, SplitByteIndex));
      RemainingText := TrimLeft(Copy(RemainingText, SplitByteIndex + 1, MaxInt));
      IsSplit := True;
      pango_layout_set_text(AContext.Layout, PChar(ChunkText), Length(ChunkText));
      pango_layout_get_pixel_size(AContext.Layout, @TextWidth, @TextHeight);
    end
    else
    begin
      ChunkText := RemainingText;
      RemainingText := '';
    end;
    if IsSplit then FooterH := ContinuationHeight else FooterH := MetadataHeight;
    CardHeight := Round(CARD_PADDING * 2.0) + HeaderH + TextHeight + 8 + FooterH;
    cairo_save(AContext.Context);
    PathRoundedRect(AContext.Context, MARGIN, AContext.CurrentY, CARD_WIDTH, CardHeight, CORNER_RADIUS);
    cairo_clip(AContext.Context);
    cairo_translate(AContext.Context, MARGIN, AContext.CurrentY);
    cairo_scale(AContext.Context, 1.0, CardHeight);
    cairo_set_source(AContext.Context, AContext.CardBackground);
    cairo_paint(AContext.Context);
    cairo_restore(AContext.Context);
    cairo_set_source_rgba(AContext.Context, 0.2, 0.2, 0.2, 0.12);
    cairo_set_line_width(AContext.Context, 0.6);
    PathRoundedRect(AContext.Context, MARGIN, AContext.CurrentY, CARD_WIDTH, CardHeight, CORNER_RADIUS);
    cairo_stroke(AContext.Context);
    cairo_save(AContext.Context);
    PathRoundedRect(AContext.Context, MARGIN, AContext.CurrentY, CARD_WIDTH, CardHeight, CORNER_RADIUS);
    cairo_clip(AContext.Context);
    RedGreenBlue(ColorToRGB(AColor), R, G, B);
    cairo_set_source_rgb(AContext.Context, R/255.0, G/255.0, B/255.0);
    cairo_rectangle(AContext.Context, MARGIN, AContext.CurrentY, ACCENT_WIDTH, CardHeight);
    cairo_fill(AContext.Context);
    cairo_restore(AContext.Context);
    TextY := AContext.CurrentY + CARD_PADDING;
    if IsContinuation then
    begin
      cairo_set_source_rgb(AContext.Context, 0.5, 0.5, 0.5);
      pango_layout_set_font_description(AContext.Layout, AContext.FontCont);
      pango_layout_set_text(AContext.Layout, '...Continued', -1);
      cairo_move_to(AContext.Context, MARGIN + CARD_PADDING + ACCENT_WIDTH, TextY);
      pango_cairo_update_layout(AContext.Context, AContext.Layout);
      pango_cairo_show_layout(AContext.Context, AContext.Layout);
      TextY := TextY + ContinuationHeight + 8.0;
    end;
    cairo_set_source_rgb(AContext.Context, 0.08, 0.08, 0.08);
    pango_layout_set_font_description(AContext.Layout, AContext.FontBody);
    pango_layout_set_text(AContext.Layout, PChar(ChunkText), Length(ChunkText));
    cairo_move_to(AContext.Context, MARGIN + CARD_PADDING + ACCENT_WIDTH, TextY);
    pango_cairo_update_layout(AContext.Context, AContext.Layout);
    pango_cairo_show_layout(AContext.Context, AContext.Layout);
    if IsSplit then
    begin
      cairo_set_source_rgb(AContext.Context, 0.5, 0.5, 0.5);
      pango_layout_set_font_description(AContext.Layout, AContext.FontCont);
      pango_layout_set_text(AContext.Layout, 'Segment continued on next page...', -1);
      pango_layout_get_pixel_size(AContext.Layout, @ContinuationWidth, nil);
      cairo_move_to(AContext.Context, MARGIN + CARD_WIDTH - CARD_PADDING - ContinuationWidth, TextY + TextHeight + 8.0);
      pango_cairo_update_layout(AContext.Context, AContext.Layout);
      pango_cairo_show_layout(AContext.Context, AContext.Layout);
      IsContinuation := True;
    end
    else
    begin
      cairo_set_line_width(AContext.Context, 0.5);
      cairo_set_source_rgba(AContext.Context, 0.0, 0.0, 0.0, 0.1);
      cairo_move_to(AContext.Context, MARGIN + CARD_PADDING + ACCENT_WIDTH, TextY + TextHeight + 4.0);
      cairo_line_to(AContext.Context, MARGIN + CARD_WIDTH - CARD_PADDING, TextY + TextHeight + 4.0);
      cairo_stroke(AContext.Context);
      cairo_set_source_rgb(AContext.Context, 0.45, 0.45, 0.45);
      pango_layout_set_font_description(AContext.Layout, AContext.FontMeta);
      pango_layout_set_text(AContext.Layout, PChar(MetaStr), -1);
      cairo_move_to(AContext.Context, MARGIN + CARD_PADDING + ACCENT_WIDTH, TextY + TextHeight + 8.0);
      pango_cairo_update_layout(AContext.Context, AContext.Layout);
      pango_cairo_show_layout(AContext.Context, AContext.Layout);
      IsContinuation := False;
    end;
    AContext.CurrentY := AContext.CurrentY + CardHeight + GUTTER;
  end;
end;

class function TServiceExport.SaveRetrievedSegmentAsPDF(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray; const ASortDescription: String): Boolean;
var
  Report: TPDFReportContext;
  FullText, SegmentSlice, MetaString, Value: String;
  i: Integer;
  IndexContent, IndexStartPos, IndexLength, IndexColor, IndexCodeID, IndexTitle: Integer;
begin
  Result := False;
  if not InitPDFContext(AFileName, ASortDescription, Report) then Exit;
  try
    IndexContent := AQuery.FieldByName('content').Index;
    IndexStartPos := AQuery.FieldByName('start_position').Index;
    IndexLength := AQuery.FieldByName('length').Index;
    IndexColor := AQuery.FieldByName('color').Index;
    IndexCodeID := AQuery.FieldByName('code_id').Index;
    IndexTitle := AQuery.FieldByName('title').Index;
    NewPage(Report, True);
    AQuery.First;
    while not AQuery.EOF do
    begin
      FullText := AQuery.Fields[IndexContent].AsString;
      SegmentSlice := FastExtractUTF8(FullText, AQuery.Fields[IndexStartPos].AsInteger, AQuery.Fields[IndexLength].AsInteger);
      MetaString := '';
      for i := 0 to High(AField) do
      begin
        if AField[i] = 'Document Name' then Value := AQuery.Fields[IndexTitle].AsString
        else if AField[i] = 'Code' then Value := APathGetter(AQuery.Fields[IndexCodeID].AsString)
        else Value := AQuery.FieldByName(AField[i]).AsString;
        if Value = '' then Value := '-';
        if MetaString <> '' then MetaString := MetaString + '  ·  ';
        MetaString := MetaString + CleanFieldName(AField[i]) + ': ' + Value;
      end;
      RenderSegmentCard(
        Report,
        SegmentSlice,
        MetaString,
        TColor(AQuery.Fields[IndexColor].AsInteger)
      );
      AQuery.Next;
    end;
    Result := True;
  finally
    FinalizePDFContext(Report);
  end;
end;

class function TServiceExport.SaveRetrievedSegmentAsHTML(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray; const ASortDescription: String): Boolean;
var
  OutputList: TStringList;
  FullText, SegmentSlice, ProjectName, HexColor, Value, MetaString: String;
  CodeColor: TColor;
  i: Integer;
begin
  Result := False;
  ProjectName := ChangeFileExt(ExtractFileName(frmAppBase.conMain.DatabaseName), '');
  OutputList := TStringList.Create;
  try
    OutputList.Add('<!DOCTYPE html>');
    OutputList.Add('<html lang="en">');
    OutputList.Add('<head>');
    OutputList.Add('  <meta charset="UTF-8">');
    OutputList.Add('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    OutputList.Add('  <title>Coding Report · ' + EscapeXML(ProjectName) + '</title>');
    OutputList.Add('  <style>');
    OutputList.Add('    :root { --text-main: #141414; --text-muted: #737373; --border-color: rgba(51, 51, 51, 0.12); --bg-main: #ffffff; }');
    OutputList.Add('    body { font-family: system-ui, -apple-system, BlinkMacSystemFont, Arial, Helvetica, "Noto Sans", "Segoe UI", sans-serif; background: var(--bg-main); color: var(--text-main); margin: 0; padding: 40px 20px; line-height: 1.6; }');
    OutputList.Add('    .container { max-width: 800px; margin: 0 auto; }');
    OutputList.Add('    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; padding-bottom: 16px; border-bottom: 1px solid var(--border-color); }');
    OutputList.Add('    .header h1 { margin: 0; font-size: 32px; font-weight: bold; color: var(--text-main); }');
    OutputList.Add('    .sort-desc { font-size: 11px; color: var(--text-muted); margin-bottom: 30px; }');
    OutputList.Add('    .logo-svg { width: 56px; height: 56px; color: var(--text-main); transition: opacity 0.2s; display: block; }');
    OutputList.Add('    .logo-svg:hover { opacity: 0.8; }');
    OutputList.Add('    .segment-card { background: linear-gradient(180deg, #faf5fa 0%, #fffdf7 100%); border-radius: 7px; margin-bottom: 12px; border: 1px solid var(--border-color); overflow: hidden; display: flex; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }');
    OutputList.Add('    .accent-bar { width: 4px; flex-shrink: 0; }');
    OutputList.Add('    .card-content { padding: 14px 20px; flex-grow: 1; }');
    OutputList.Add('    .segment-text { font-size: 14px; white-space: pre-wrap; margin-bottom: 12px; color: var(--text-main); }');
    OutputList.Add('    .meta-data { font-size: 11px; color: var(--text-muted); border-top: 1px solid rgba(0,0,0,0.1); padding-top: 8px; }');
    OutputList.Add('    .meta-data b { color: #525252; font-weight: bold; }');
    OutputList.Add('    footer { text-align: center; margin-top: 40px; font-size: 11px; color: var(--text-muted); }');
    OutputList.Add('    footer a { color: inherit; text-decoration: none; transition: color 0.2s ease; }');
    OutputList.Add('    footer a:hover { color: #66023c; text-decoration: none; }');
    OutputList.Add('  </style>');
    OutputList.Add('</head>');
    OutputList.Add('<body>');
    OutputList.Add('  <div class="container">');
    OutputList.Add('    <div class="header">');
    OutputList.Add('      <h1>Coding Report</h1>');
    OutputList.Add('      <a href="' + EscapeXML(APP_URL) + '" target="_blank" class="logo-svg" title="Lattice">' + APP_LOGO_SVG + '</a>');
    OutputList.Add('    </div>');
    OutputList.Add('    <div class="sort-desc">Sorted by: ' + EscapeXML(ASortDescription) + '</div>');
    AQuery.First;
    while not AQuery.EOF do
    begin
      FullText := AQuery.FieldByName('content').AsString;
      SegmentSlice := UTF8Copy(FullText, AQuery.FieldByName('start_position').AsInteger + 1, AQuery.FieldByName('length').AsInteger);
      if SegmentSlice = '' then SegmentSlice := '[Empty segment]';
      MetaString := '';
      for i := 0 to High(AField) do
      begin
        if AField[i] = 'Document Name' then Value := AQuery.FieldByName('title').AsString
        else if AField[i] = 'Code' then Value := APathGetter(AQuery.FieldByName('code_id').AsString)
        else Value := AQuery.FieldByName(AField[i]).AsString;
        if Value = '' then Value := '-';
        if MetaString <> '' then MetaString := MetaString + ' &nbsp;&middot;&nbsp; ';
        MetaString := MetaString + '<b>' + EscapeXML(CleanFieldName(AField[i])) + ':</b> ' + EscapeXML(Value);
      end;
      CodeColor := TColor(AQuery.FieldByName('color').AsInteger);
      HexColor := '#' + IntToHex(Red(CodeColor), 2) + IntToHex(Green(CodeColor), 2) + IntToHex(Blue(CodeColor), 2);
      OutputList.Add('    <div class="segment-card">');
      OutputList.Add('      <div class="accent-bar" style="background-color: ' + HexColor + ';"></div>');
      OutputList.Add('      <div class="card-content">');
      OutputList.Add('        <div class="segment-text">' + EscapeXML(SegmentSlice) + '</div>');
      OutputList.Add('        <div class="meta-data">' + MetaString + '</div>');
      OutputList.Add('      </div>');
      OutputList.Add('    </div>');
      AQuery.Next;
    end;
    OutputList.Add('    <footer>Generated by <a href="' + EscapeXML(APP_URL) + '" target="_blank">' + EscapeXML(APP_NAME) + '</a> ' + EscapeXML(APP_VERSION_SHORT) + '</footer>');
    OutputList.Add('  </div>');
    OutputList.Add('</body>');
    OutputList.Add('</html>');
    OutputList.SaveToFile(AFileName, TEncoding.UTF8);
    Result := True;
  finally
    OutputList.Free;
  end;
end;

class function TServiceExport.SaveRetrievedSegmentAsXML(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray): Boolean;
var
  OutputList: TStringList;
  FullText, SegmentSlice, Value: String;
  i: Integer;
  HasAttributes: Boolean;
begin
  Result := False;
  OutputList := TStringList.Create;
  try
    OutputList.Add('<?xml version="1.0" encoding="UTF-8"?>');
    OutputList.Add('<Segments>');
    AQuery.First;
    while not AQuery.EOF do
    begin
      FullText := AQuery.FieldByName('content').AsString;
      SegmentSlice := UTF8Copy(FullText, AQuery.FieldByName('start_position').AsInteger + 1, AQuery.FieldByName('length').AsInteger);
      OutputList.Add('  <Segment>');
      OutputList.Add('    <SegmentText>' + EscapeXML(SegmentSlice) + '</SegmentText>');
      OutputList.Add('    <StartPosition>' + AQuery.FieldByName('start_position').AsString + '</StartPosition>');
      OutputList.Add('    <Length>' + AQuery.FieldByName('length').AsString + '</Length>');
      HasAttributes := False;
      for i := 0 to High(AField) do
      begin
        if AField[i] = 'Document Name' then
          OutputList.Add('    <DocumentName>' + EscapeXML(AQuery.FieldByName('title').AsString) + '</DocumentName>')
        else if AField[i] = 'Code' then
          OutputList.Add('    <Code>' + EscapeXML(APathGetter(AQuery.FieldByName('code_id').AsString)) + '</Code>')
        else
          HasAttributes := True;
      end;
      if HasAttributes then
      begin
        OutputList.Add('    <Attributes>');
        for i := 0 to High(AField) do
        begin
          if (AField[i] <> 'Document Name') and (AField[i] <> 'Code') then
          begin
            Value := AQuery.FieldByName(AField[i]).AsString;
            OutputList.Add('      <Attribute Name="' + EscapeXML(CleanFieldName(AField[i])) + '">' + EscapeXML(Value) + '</Attribute>');
          end;
        end;
        OutputList.Add('    </Attributes>');
      end;
      OutputList.Add('  </Segment>');
      AQuery.Next;
    end;
    OutputList.Add('</Segments>');
    OutputList.SaveToFile(AFileName, TEncoding.UTF8);
    Result := True;
  finally
    OutputList.Free;
  end;
end;

class function TServiceExport.SaveRetrievedSegmentAsJSON(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray): Boolean;
var
  RootArray: TJSONArray;
  ItemObj, MetaObj: TJSONObject;
  FullText, SegmentSlice, Value: String;
  OutputList: TStringList;
  i: Integer;
begin
  Result := False;
  RootArray := TJSONArray.Create;
  OutputList := TStringList.Create;
  try
    AQuery.First;
    while not AQuery.EOF do
    begin
      FullText := AQuery.FieldByName('content').AsString;
      SegmentSlice := UTF8Copy(FullText, AQuery.FieldByName('start_position').AsInteger + 1, AQuery.FieldByName('length').AsInteger);
      ItemObj := TJSONObject.Create;
      ItemObj.Add('SegmentText', SegmentSlice);
      ItemObj.Add('StartPosition', AQuery.FieldByName('start_position').AsInteger);
      ItemObj.Add('Length', AQuery.FieldByName('length').AsInteger);
      MetaObj := TJSONObject.Create;
      for i := 0 to High(AField) do
      begin
        if AField[i] = 'Document Name' then
          ItemObj.Add('DocumentName', AQuery.FieldByName('title').AsString)
        else if AField[i] = 'Code' then
          ItemObj.Add('Code', APathGetter(AQuery.FieldByName('code_id').AsString))
        else
        begin
          Value := AQuery.FieldByName(AField[i]).AsString;
          MetaObj.Add(CleanFieldName(AField[i]), Value);
        end;
      end;
      if MetaObj.Count > 0 then
        ItemObj.Add('Attributes', MetaObj)
      else
        MetaObj.Free;
      RootArray.Add(ItemObj);
      AQuery.Next;
    end;
    OutputList.Text := RootArray.FormatJSON;
    OutputList.SaveToFile(AFileName, TEncoding.UTF8);
    Result := True;
  finally
    RootArray.Free;
    OutputList.Free;
  end;
end;

class function TServiceExport.SaveRetrievedSegmentAsCSV(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray): Boolean;
var
  OutputList: TStringList;
  Line, FullText, SegmentSlice, Value: String;
  i: Integer;
begin
  Result := False;
  OutputList := TStringList.Create;
  try
    Line := SanitizeCSVField('Segment');
    for i := 0 to High(AField) do
    begin
      if AField[i] = 'Document Name' then Line := Line + ',' + SanitizeCSVField('Document Name')
      else if AField[i] = 'Code' then Line := Line + ',' + SanitizeCSVField('Code')
      else Line := Line + ',' + SanitizeCSVField(CleanFieldName(AField[i]));
    end;
    OutputList.Add(Line);
    AQuery.First;
    while not AQuery.EOF do
    begin
      FullText := AQuery.FieldByName('content').AsString;
      SegmentSlice := UTF8Copy(FullText, AQuery.FieldByName('start_position').AsInteger + 1, AQuery.FieldByName('length').AsInteger);
      Line := SanitizeCSVField(SegmentSlice);
      for i := 0 to High(AField) do
      begin
        if AField[i] = 'Document Name' then Value := AQuery.FieldByName('title').AsString
        else if AField[i] = 'Code' then Value := APathGetter(AQuery.FieldByName('code_id').AsString)
        else Value := AQuery.FieldByName(AField[i]).AsString;
        Line := Line + ',' + SanitizeCSVField(Value);
      end;
      OutputList.Add(Line);
      AQuery.Next;
    end;
    OutputList.WriteBOM := True;
    OutputList.SaveToFile(AFileName, TEncoding.UTF8);
    Result := True;
  finally
    OutputList.Free;
  end;
end;

class function TServiceExport.SaveRetrievedSegmentAsSpreadsheet(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray; AFormat: TsSpreadsheetFormat): Boolean;
var
  MyWorkbook: TsWorkbook;
  MyWorksheet: TsWorksheet;
  RowIndex, i: Integer;
  FullText, SegmentText, Value: String;
begin
  Result := False;
  MyWorkbook := TsWorkbook.Create;
  try
    MyWorksheet := MyWorkbook.AddWorksheet('Coding Report');
    MyWorksheet.WriteText(0, 0, 'Segment');
    for i := 0 to High(AField) do
    begin
      if AField[i] = 'Document Name' then MyWorksheet.WriteText(0, i + 1, 'Document Name')
      else if AField[i] = 'Code' then MyWorksheet.WriteText(0, i + 1, 'Code')
      else MyWorksheet.WriteText(0, i + 1, CleanFieldName(AField[i]));
    end;
    RowIndex := 1;
    AQuery.First;
    while not AQuery.EOF do
    begin
      FullText := AQuery.FieldByName('content').AsString;
      SegmentText := UTF8Copy(FullText, AQuery.FieldByName('start_position').AsInteger + 1, AQuery.FieldByName('length').AsInteger);
      MyWorksheet.WriteText(RowIndex, 0, SegmentText);
      for i := 0 to High(AField) do
      begin
        if AField[i] = 'Document Name' then Value := AQuery.FieldByName('title').AsString
        else if AField[i] = 'Code' then Value := APathGetter(AQuery.FieldByName('code_id').AsString)
        else Value := AQuery.FieldByName(AField[i]).AsString;
        MyWorksheet.WriteText(RowIndex, i + 1, Value);
      end;
      Inc(RowIndex);
      AQuery.Next;
    end;
    MyWorkbook.WriteToFile(AFileName, AFormat, True);
    Result := True;
  finally
    MyWorkbook.Free;
  end;
end;

class function TServiceExport.ExportRetrievedSegment(AQuery: TSQLQuery; const AFileName: String; APathGetter: TGetPathEvent; AField: TStringDynArray; const ASortDescription: String): Boolean;
var
  Extension: String;
begin
  Result := False;
  if not Assigned(AQuery) or (AFileName = '') or not Assigned(APathGetter) then Exit;
  Extension := LowerCase(ExtractFileExt(AFileName));
  if Extension = '.pdf' then
    Result := SaveRetrievedSegmentAsPDF(AQuery, AFileName, APathGetter, AField, ASortDescription)
  else if Extension = '.html' then
    Result := SaveRetrievedSegmentAsHTML(AQuery, AFileName, APathGetter, AField, ASortDescription)
  else if Extension = '.csv' then
    Result := SaveRetrievedSegmentAsCSV(AQuery, AFileName, APathGetter, AField)
  else if Extension = '.json' then
    Result := SaveRetrievedSegmentAsJSON(AQuery, AFileName, APathGetter, AField)
  else if Extension = '.xml' then
    Result := SaveRetrievedSegmentAsXML(AQuery, AFileName, APathGetter, AField)
  else if Extension = '.ods' then
    Result := SaveRetrievedSegmentAsSpreadsheet(AQuery, AFileName, APathGetter, AField, sfOpenDocument)
  else
    Result := SaveRetrievedSegmentAsSpreadsheet(AQuery, AFileName, APathGetter, AField, sfOOXML);
end;

class function TServiceExport.ExportVisualisation(const AFileName, AProjectTitle, ASubject: String; AWidth, AHeight: Integer; ARenderEvent: TVisualisationRenderEvent): Boolean;
var
  surface: Pcairo_surface_t;
  cr: Pcairo_t;
  Extension: String;
  bmp: Graphics.TBitmap;
  jpg: TJPEGImage;
begin
  Result := False;
  if not Assigned(ARenderEvent) or (AFileName = '') then Exit;
  Extension := LowerCase(ExtractFileExt(AFileName));
  if ((Extension = '.png') or (Extension = '.jpg') or (Extension = '.jpeg')) and ((AWidth > 32767) or (AHeight > 32767)) then
    raise EDataExportException.Create('This visualisation is too big to be exported as a raster image (PNG/JPEG).' + sLineBreak + 'Please export as PDF or SVG.');
  if Extension = '.pdf' then
  begin
    surface := cairo_pdf_surface_create(PChar(AFileName), AWidth, AHeight);
    cairo_pdf_surface_set_metadata(surface, PDF_METADATA_CREATOR, PChar(APP_ATTRIBUTION));
    cairo_pdf_surface_set_metadata(surface, PDF_METADATA_TITLE, PChar(ValidateAndFixUTF8(ASubject)));
    cairo_pdf_surface_set_metadata(surface, PDF_METADATA_SUBJECT, PChar(ValidateAndFixUTF8(AProjectTitle)));
  end
  else if Extension = '.svg' then
    surface := cairo_svg_surface_create(PChar(AFileName), AWidth, AHeight)
  else if Extension = '.png' then
    surface := cairo_image_surface_create(Cairo.CAIRO_FORMAT_ARGB32, AWidth, AHeight)
  else if (Extension = '.jpeg') or (Extension = '.jpg') then
  begin
    bmp := Graphics.TBitmap.Create;
    try
      bmp.SetSize(AWidth, AHeight);
      bmp.Canvas.Brush.Color := clWhite;
      bmp.Canvas.FillRect(0, 0, AWidth, AHeight);
      surface := cairo_win32_surface_create(bmp.Canvas.Handle);
      cr := cairo_create(surface);
      try
        cairo_set_source_rgb(cr, 1, 1, 1);
        cairo_paint(cr);
        ARenderEvent(cr, AWidth, AHeight);
      finally
        cairo_destroy(cr);
        cairo_surface_finish(surface);
        cairo_surface_destroy(surface);
      end;
      jpg := TJPEGImage.Create;
      try
        jpg.Assign(bmp);
        jpg.SaveToFile(AFileName);
      finally
        jpg.Free;
      end;
      Result := True;
    finally
      bmp.Free;
    end;
    Exit;
  end
  else
    Exit;
  cr := cairo_create(surface);
  try
    cairo_set_source_rgb(cr, 1, 1, 1);
    cairo_paint(cr);
    ARenderEvent(cr, AWidth, AHeight);
    if Extension = '.png' then
    begin
      if cairo_surface_write_to_png(surface, PChar(AFileName)) <> CAIRO_STATUS_SUCCESS then
        Exit(False);
    end;
    Result := True;
  finally
    cairo_destroy(cr);
    cairo_surface_finish(surface);
    cairo_surface_destroy(surface);
  end;
end;

class function TServiceExport.SaveMemoAsCSV(AConnection: TSQLite3Connection; const AFileName, IDList: String): Boolean;
var
  OutputList: TStringList;
  Query, QuerySegment: TSQLQuery;
  Line, SegmentText: String;
  PartArray: TStringArray;
begin
  Result := False;
  OutputList := TStringList.Create;
  Query := TSQLQuery.Create(nil);
  QuerySegment := TSQLQuery.Create(nil);
  try
    Query.Database := AConnection;
    Query.SQL.Text := 'SELECT m.memo_type, m.title, REPLACE(m.created_at, '' '', ''T'') || ''Z'' as created_at, REPLACE(m.updated_at, '' '', ''T'') || ''Z'' as updated_at, m.content, m.reference as raw_ref, ' +
                    'CASE WHEN m.memo_type = ''Document'' THEN (SELECT title FROM documents WHERE id = m.reference) ' +
                    'WHEN m.memo_type = ''Code'' THEN (SELECT name FROM codes WHERE id = m.reference) ' +
                    'WHEN m.memo_type = ''Segment'' THEN (SELECT title FROM documents WHERE id = SUBSTR(m.reference, 1, INSTR(m.reference, '':'') - 1)) ' +
                    'ELSE ''N/A'' END as ref_name FROM memos m WHERE m.id IN (' + IDList + ') ORDER BY m.memo_type ASC, m.title ASC';
    Query.Open;
    QuerySegment.Database := AConnection;
    QuerySegment.SQL.Text := 'SELECT SUBSTR(content, :sp + 1, :len) FROM documents WHERE id = :did';
    Line := SanitizeCSVField('Type') + ',' + SanitizeCSVField('Title') + ',' + SanitizeCSVField('Reference') + ',' +
            SanitizeCSVField('Content') + ',' + SanitizeCSVField('Segment') + ',' + SanitizeCSVField('Created At (UTC)') + ',' +
            SanitizeCSVField('Updated At (UTC)');
    OutputList.Add(Line);
    while not Query.EOF do
    begin
      SegmentText := 'N/A';
      if Query.FieldByName('memo_type').AsString = 'Segment' then
      begin
        PartArray := Query.FieldByName('raw_ref').AsString.Split([':']);
        if Length(PartArray) = 3 then
        begin
          QuerySegment.Close;
          QuerySegment.Params.ParamByName('did').AsString := PartArray[0];
          QuerySegment.Params.ParamByName('sp').AsInteger := StrToIntDef(PartArray[1], 0);
          QuerySegment.Params.ParamByName('len').AsInteger := StrToIntDef(PartArray[2], 0);
          QuerySegment.Open;
          if not QuerySegment.EOF then SegmentText := QuerySegment.Fields[0].AsString;
        end;
      end;
      Line := SanitizeCSVField(Query.FieldByName('memo_type').AsString) + ',';
      Line := Line + SanitizeCSVField(Query.FieldByName('title').AsString) + ',';
      Line := Line + SanitizeCSVField(Query.FieldByName('ref_name').AsString) + ',';
      Line := Line + SanitizeCSVField(Query.FieldByName('content').AsString) + ',';
      Line := Line + SanitizeCSVField(SegmentText) + ',';
      Line := Line + SanitizeCSVField(Query.FieldByName('created_at').AsString) + ',';
      Line := Line + SanitizeCSVField(Query.FieldByName('updated_at').AsString);
      OutputList.Add(Line);
      Query.Next;
    end;
    OutputList.WriteBOM := True;
    OutputList.SaveToFile(AFileName, TEncoding.UTF8);
    Result := True;
  finally
    QuerySegment.Free;
    Query.Free;
    OutputList.Free;
  end;
end;

class function TServiceExport.SaveMemoAsJSON(AConnection: TSQLite3Connection; const AFileName, IDList: String): Boolean;
var
  RootArray: TJSONArray;
  ItemObj: TJSONObject;
  OutputList: TStringList;
  Query, QuerySegment: TSQLQuery;
  PartArray: TStringArray;
  SegmentText: String;
begin
  Result := False;
  RootArray := TJSONArray.Create;
  OutputList := TStringList.Create;
  Query := TSQLQuery.Create(nil);
  QuerySegment := TSQLQuery.Create(nil);
  try
    Query.Database := AConnection;
    Query.SQL.Text := 'SELECT m.memo_type, m.title, REPLACE(m.created_at, '' '', ''T'') || ''Z'' as created_at, REPLACE(m.updated_at, '' '', ''T'') || ''Z'' as updated_at, m.content, m.reference as raw_ref, ' +
                    'CASE WHEN m.memo_type = ''Document'' THEN (SELECT title FROM documents WHERE id = m.reference) ' +
                    'WHEN m.memo_type = ''Code'' THEN (SELECT name FROM codes WHERE id = m.reference) ' +
                    'WHEN m.memo_type = ''Segment'' THEN (SELECT title FROM documents WHERE id = SUBSTR(m.reference, 1, INSTR(m.reference, '':'') - 1)) ' +
                    'ELSE ''N/A'' END as ref_name FROM memos m WHERE m.id IN (' + IDList + ') ORDER BY m.memo_type ASC, m.title ASC';
    Query.Open;
    QuerySegment.Database := AConnection;
    QuerySegment.SQL.Text := 'SELECT SUBSTR(content, :sp + 1, :len) FROM documents WHERE id = :did';
    while not Query.EOF do
    begin
      SegmentText := 'N/A';
      if Query.FieldByName('memo_type').AsString = 'Segment' then
      begin
        PartArray := Query.FieldByName('raw_ref').AsString.Split([':']);
        if Length(PartArray) = 3 then
        begin
          QuerySegment.Close;
          QuerySegment.Params.ParamByName('did').AsString := PartArray[0];
          QuerySegment.Params.ParamByName('sp').AsInteger := StrToIntDef(PartArray[1], 0);
          QuerySegment.Params.ParamByName('len').AsInteger := StrToIntDef(PartArray[2], 0);
          QuerySegment.Open;
          if not QuerySegment.EOF then SegmentText := QuerySegment.Fields[0].AsString;
        end;
      end;
      ItemObj := TJSONObject.Create;
      ItemObj.Add('Type', Query.FieldByName('memo_type').AsString);
      ItemObj.Add('Title', Query.FieldByName('title').AsString);
      ItemObj.Add('Reference', Query.FieldByName('ref_name').AsString);
      ItemObj.Add('Content', Query.FieldByName('content').AsString);
      ItemObj.Add('Segment', SegmentText);
      ItemObj.Add('CreatedAt', Query.FieldByName('created_at').AsString);
      ItemObj.Add('UpdatedAt', Query.FieldByName('updated_at').AsString);
      RootArray.Add(ItemObj);
      Query.Next;
    end;
    OutputList.Text := RootArray.FormatJSON;
    OutputList.SaveToFile(AFileName, TEncoding.UTF8);
    Result := True;
  finally
    QuerySegment.Free;
    Query.Free;
    OutputList.Free;
    RootArray.Free;
  end;
end;

class function TServiceExport.SaveMemoAsXML(AConnection: TSQLite3Connection; const AFileName, IDList: String): Boolean;
var
  OutputList: TStringList;
  Query, QuerySegment: TSQLQuery;
  PartArray: TStringArray;
  SegmentText: String;
begin
  Result := False;
  OutputList := TStringList.Create;
  Query := TSQLQuery.Create(nil);
  QuerySegment := TSQLQuery.Create(nil);
  try
    Query.Database := AConnection;
    Query.SQL.Text := 'SELECT m.memo_type, m.title, REPLACE(m.created_at, '' '', ''T'') || ''Z'' as created_at, REPLACE(m.updated_at, '' '', ''T'') || ''Z'' as updated_at, m.content, m.reference as raw_ref, ' +
                    'CASE WHEN m.memo_type = ''Document'' THEN (SELECT title FROM documents WHERE id = m.reference) ' +
                    'WHEN m.memo_type = ''Code'' THEN (SELECT name FROM codes WHERE id = m.reference) ' +
                    'WHEN m.memo_type = ''Segment'' THEN (SELECT title FROM documents WHERE id = SUBSTR(m.reference, 1, INSTR(m.reference, '':'') - 1)) ' +
                    'ELSE ''N/A'' END as ref_name FROM memos m WHERE m.id IN (' + IDList + ') ORDER BY m.memo_type ASC, m.title ASC';
    Query.Open;
    QuerySegment.Database := AConnection;
    QuerySegment.SQL.Text := 'SELECT SUBSTR(content, :sp + 1, :len) FROM documents WHERE id = :did';
    OutputList.Add('<?xml version="1.0" encoding="UTF-8"?>');
    OutputList.Add('<Memos>');
    while not Query.EOF do
    begin
      SegmentText := 'N/A';
      if Query.FieldByName('memo_type').AsString = 'Segment' then
      begin
        PartArray := Query.FieldByName('raw_ref').AsString.Split([':']);
        if Length(PartArray) = 3 then
        begin
          QuerySegment.Close;
          QuerySegment.Params.ParamByName('did').AsString := PartArray[0];
          QuerySegment.Params.ParamByName('sp').AsInteger := StrToIntDef(PartArray[1], 0);
          QuerySegment.Params.ParamByName('len').AsInteger := StrToIntDef(PartArray[2], 0);
          QuerySegment.Open;
          if not QuerySegment.EOF then SegmentText := QuerySegment.Fields[0].AsString;
        end;
      end;
      OutputList.Add('  <Memo>');
      OutputList.Add('    <Type>' + EscapeXML(Query.FieldByName('memo_type').AsString) + '</Type>');
      OutputList.Add('    <Title>' + EscapeXML(Query.FieldByName('title').AsString) + '</Title>');
      OutputList.Add('    <Reference>' + EscapeXML(Query.FieldByName('ref_name').AsString) + '</Reference>');
      OutputList.Add('    <Content>' + EscapeXML(Query.FieldByName('content').AsString) + '</Content>');
      OutputList.Add('    <Segment>' + EscapeXML(SegmentText) + '</Segment>');
      OutputList.Add('    <CreatedAt>' + EscapeXML(Query.FieldByName('created_at').AsString) + '</CreatedAt>');
      OutputList.Add('    <UpdatedAt>' + EscapeXML(Query.FieldByName('updated_at').AsString) + '</UpdatedAt>');
      OutputList.Add('  </Memo>');
      Query.Next;
    end;
    OutputList.Add('</Memos>');
    OutputList.SaveToFile(AFileName, TEncoding.UTF8);
    Result := True;
  finally
    QuerySegment.Free;
    Query.Free;
    OutputList.Free;
  end;
end;

class function TServiceExport.SaveMemoAsSpreadsheet(AConnection: TSQLite3Connection; const AFileName, IDList: String; AFormat: TsSpreadsheetFormat): Boolean;
var
  MyWorkbook: TsWorkbook;
  MyWorksheet: TsWorksheet;
  RowIndex: Integer;
  Query, QuerySegment: TSQLQuery;
  PartArray: TStringArray;
  SegmentText, MemoContent: String;
begin
  Result := False;
  MyWorkbook := TsWorkbook.Create;
  Query := TSQLQuery.Create(nil);
  QuerySegment := TSQLQuery.Create(nil);
  try
    Query.Database := AConnection;
    Query.SQL.Text := 'SELECT m.memo_type, m.title, REPLACE(m.created_at, '' '', ''T'') || ''Z'' as created_at, REPLACE(m.updated_at, '' '', ''T'') || ''Z'' as updated_at, m.content, m.reference as raw_ref, ' +
                    'CASE WHEN m.memo_type = ''Document'' THEN (SELECT title FROM documents WHERE id = m.reference) ' +
                    'WHEN m.memo_type = ''Code'' THEN (SELECT name FROM codes WHERE id = m.reference) ' +
                    'WHEN m.memo_type = ''Segment'' THEN (SELECT title FROM documents WHERE id = SUBSTR(m.reference, 1, INSTR(m.reference, '':'') - 1)) ' +
                    'ELSE ''N/A'' END as ref_name FROM memos m WHERE m.id IN (' + IDList + ') ORDER BY m.memo_type ASC, m.title ASC';
    Query.Open;
    QuerySegment.Database := AConnection;
    QuerySegment.SQL.Text := 'SELECT SUBSTR(content, :sp + 1, :len) FROM documents WHERE id = :did';
    MyWorksheet := MyWorkbook.AddWorksheet('Exported Memo');
    MyWorksheet.WriteText(0, 0, 'Type');
    MyWorksheet.WriteText(0, 1, 'Title');
    MyWorksheet.WriteText(0, 2, 'Reference');
    MyWorksheet.WriteText(0, 3, 'Content');
    MyWorksheet.WriteText(0, 4, 'Segment');
    MyWorksheet.WriteText(0, 5, 'Created At (UTC)');
    MyWorksheet.WriteText(0, 6, 'Updated At (UTC)');
    RowIndex := 1;
    while not Query.EOF do
    begin
      SegmentText := 'N/A';
      if Query.FieldByName('memo_type').AsString = 'Segment' then
      begin
        PartArray := Query.FieldByName('raw_ref').AsString.Split([':']);
        if Length(PartArray) = 3 then
        begin
          QuerySegment.Close;
          QuerySegment.Params.ParamByName('did').AsString := PartArray[0];
          QuerySegment.Params.ParamByName('sp').AsInteger := StrToIntDef(PartArray[1], 0);
          QuerySegment.Params.ParamByName('len').AsInteger := StrToIntDef(PartArray[2], 0);
          QuerySegment.Open;
          if not QuerySegment.EOF then SegmentText := QuerySegment.Fields[0].AsString;
        end;
      end;
      MemoContent := Query.FieldByName('content').AsString;
      MyWorksheet.WriteText(RowIndex, 0, Query.FieldByName('memo_type').AsString);
      MyWorksheet.WriteText(RowIndex, 1, Query.FieldByName('title').AsString);
      MyWorksheet.WriteText(RowIndex, 2, Query.FieldByName('ref_name').AsString);
      MyWorksheet.WriteText(RowIndex, 3, MemoContent);
      MyWorksheet.WriteText(RowIndex, 4, SegmentText);
      MyWorksheet.WriteText(RowIndex, 5, Query.FieldByName('created_at').AsString);
      MyWorksheet.WriteText(RowIndex, 6, Query.FieldByName('updated_at').AsString);
      Inc(RowIndex);
      Query.Next;
    end;
    MyWorkbook.WriteToFile(AFileName, AFormat, True);
    Result := True;
  finally
    QuerySegment.Free;
    Query.Free;
    MyWorkbook.Free;
  end;
end;

procedure TThreadExportMemo.DoHeavyLifting;
var
  Extension: String;
begin
  SyncUpdateStatus('Exporting memos...');
  Extension := LowerCase(ExtractFileExt(FFileName));
  if Extension = '.csv' then
  begin
    if not TServiceExport.SaveMemoAsCSV(FConnection, FFileName, FIDList) then
      raise Exception.Create('Failed to export as CSV.');
  end
  else if Extension = '.json' then
  begin
    if not TServiceExport.SaveMemoAsJSON(FConnection, FFileName, FIDList) then
      raise Exception.Create('Failed to export as JSON.');
  end
  else if Extension = '.xml' then
  begin
    if not TServiceExport.SaveMemoAsXML(FConnection, FFileName, FIDList) then
      raise Exception.Create('Failed to export as XML.');
  end
  else if Extension = '.ods' then
  begin
    if not TServiceExport.SaveMemoAsSpreadsheet(FConnection, FFileName, FIDList, sfOpenDocument) then
      raise Exception.Create('Failed to export as ODS.');
  end
  else
  begin
    if not TServiceExport.SaveMemoAsSpreadsheet(FConnection, FFileName, FIDList, sfOOXML) then
      raise Exception.Create('Failed to export as XLSX.');
  end;
end;

class function TServiceExport.ExportMemo(AConnection: TSQLite3Connection; const AFileName, IDList: String): Boolean;
var
  Worker: TThreadExportMemo;
  Q: TSQLQuery;
  Extension: String;
  PartArray: TStringArray;
begin
  Result := False;
  if not Assigned(AConnection) or (AFileName = '') or (IDList = '') then Exit;
  Extension := LowerCase(ExtractFileExt(AFileName));
  if (Extension = '.xlsx') or (Extension = '.ods') then
  begin
    Q := TSQLQuery.Create(nil);
    try
      Q.Database := AConnection;
      Q.SQL.Text := 'SELECT memo_type, content, reference FROM memos WHERE id IN (' + IDList + ')';
      Q.Open;
      while not Q.EOF do
      begin
        if Length(Q.FieldByName('content').AsString) > SPREADSHEET_PER_CELL_LIMIT then
        begin
          MessageDlg('Data Limit Exceeded', 'Some memos or segments exceed the 32,767 characters per cell limit for spreadsheets.' + sLineBreak + 'Please export as CSV, JSON, or XML instead.', mtWarning, [mbOK], 0);
          Exit(False);
        end;
        if Q.FieldByName('memo_type').AsString = 'Segment' then
        begin
          PartArray := Q.FieldByName('reference').AsString.Split([':']);
          if (Length(PartArray) = 3) and (StrToIntDef(PartArray[2], 0) > SPREADSHEET_PER_CELL_LIMIT) then
          begin
            MessageDlg('Data Limit Exceeded', 'Some memos or segments exceed the 32,767 characters per cell limit for spreadsheets.' + sLineBreak + 'Please export as CSV, JSON, or XML instead.', mtWarning, [mbOK], 0);
            Exit(False);
          end;
        end;
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  end;
  if AConnection.Transaction.Active then AConnection.Transaction.Commit;
  Worker := TThreadExportMemo.Create(AConnection.DatabaseName);
  try
    Worker.FFileName := AFileName;
    Worker.FIDList := IDList;
    Worker.Start;
    TfrmDialogProgress.Prepare('Exporting Memo', 'Connecting to database...');
    frmDialogProgress.ShowModal;
    if Worker.Success then
      Result := True
    else
      MessageDlg('Export Error', 'Failed to export memos: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

class function TServiceExport.ExportDataTable(const Header, DataKeys: TStringDynArray; const GridData: T2DStringArray; const AFileName: String): Boolean;
var
  Extension: String;
  ColCount, RowCount, c, r: Integer;
  Value, CleanHeader, Line: String;
  OutputList: TStringList;
  RootArray: TJSONArray;
  ItemObj: TJSONObject;
  Workbook: TsWorkbook;
  Worksheet: TsWorksheet;
  Format: TsSpreadsheetFormat;
begin
  Result := False;
  if (Length(Header) = 0) or (AFileName = '') then Exit;
  Extension := LowerCase(ExtractFileExt(AFileName));
  ColCount := Length(Header);
  RowCount := Length(GridData);
  if (Extension = '.xlsx') or (Extension = '.ods') then
  begin
    if Extension = '.ods' then Format := sfOpenDocument else Format := sfOOXML;
    Workbook := TsWorkbook.Create;
    try
      Worksheet := Workbook.AddWorksheet('Data Export');
      for c := 0 to ColCount - 1 do
        Worksheet.WriteText(0, c, Header[c]);
      for r := 0 to RowCount - 1 do
      begin
        for c := 0 to ColCount - 1 do
          Worksheet.WriteText(r + 1, c, GridData[r, c]);
      end;
      Workbook.WriteToFile(AFileName, Format, True);
      Result := True;
    finally
      Workbook.Free;
    end;
  end
  else if Extension = '.csv' then
  begin
    OutputList := TStringList.Create;
    try
      Line := '';
      for c := 0 to ColCount - 1 do
      begin
        if c > 0 then Line := Line + ',';
        Line := Line + SanitizeCSVField(Header[c]);
      end;
      OutputList.Add(Line);
      for r := 0 to RowCount - 1 do
      begin
        Line := '';
        for c := 0 to ColCount - 1 do
        begin
          if c > 0 then Line := Line + ',';
          Line := Line + SanitizeCSVField(GridData[r, c]);
        end;
        OutputList.Add(Line);
      end;
      OutputList.WriteBOM := True;
      OutputList.SaveToFile(AFileName, TEncoding.UTF8);
      Result := True;
    finally
      OutputList.Free;
    end;
  end
  else if Extension = '.json' then
  begin
    RootArray := TJSONArray.Create;
    OutputList := TStringList.Create;
    try
      for r := 0 to RowCount - 1 do
      begin
        ItemObj := TJSONObject.Create;
        for c := 0 to ColCount - 1 do
        begin
          CleanHeader := DataKeys[c];
          ItemObj.Add(CleanHeader, GridData[r, c]);
        end;
        RootArray.Add(ItemObj);
      end;
      OutputList.Text := RootArray.FormatJSON;
      OutputList.SaveToFile(AFileName, TEncoding.UTF8);
      Result := True;
    finally
      RootArray.Free;
      OutputList.Free;
    end;
  end
  else if Extension = '.xml' then
  begin
    OutputList := TStringList.Create;
    try
      OutputList.Add('<?xml version="1.0" encoding="UTF-8"?>');
      OutputList.Add('<Table>');
      for r := 0 to RowCount - 1 do
      begin
        OutputList.Add('  <Row>');
        for c := 0 to ColCount - 1 do
        begin
          CleanHeader := DataKeys[c];
          Value := EscapeXML(GridData[r, c]);
          OutputList.Add('    <' + CleanHeader + '>' + Value + '</' + CleanHeader + '>');
        end;
        OutputList.Add('  </Row>');
      end;
      OutputList.Add('</Table>');
      OutputList.SaveToFile(AFileName, TEncoding.UTF8);
      Result := True;
    finally
      OutputList.Free;
    end;
  end;
end;

class function TServiceExport.ExportCodeSystem(AQuery: TSQLQuery; const AFileName: String): Boolean;
var
  RootArray: TJSONArray;
  procedure InternalExport(const ParentID: String; CurrentArray: TJSONArray);
  var
    CodeObj: TJSONObject;
    ChildArray: TJSONArray;
    LocalList: TList;
    i: Integer;
  begin
    LocalList := TList.Create;
    try
      AQuery.Close;
      AQuery.SQL.Text := 'SELECT id, name, description, color FROM codes WHERE parent_id = :p';
      AQuery.Params.ParamByName('p').AsString := ParentID;
      AQuery.Open;
      while not AQuery.EOF do
      begin
        CodeObj := TJSONObject.Create;
        CodeObj.Add('ID', AQuery.FieldByName('id').AsString);
        CodeObj.Add('Name', AQuery.FieldByName('name').AsString);
        CodeObj.Add('Description', AQuery.FieldByName('description').AsString);
        CodeObj.Add('Color', AQuery.FieldByName('color').AsInteger);
        LocalList.Add(CodeObj);
        AQuery.Next;
      end;
      for i := 0 to LocalList.Count - 1 do
      begin
        CodeObj := TJSONObject(LocalList[i]);
        ChildArray := TJSONArray.Create;
        InternalExport(CodeObj.Strings['ID'], ChildArray);
        CodeObj.Add('SubCodes', ChildArray);
        CurrentArray.Add(CodeObj);
      end;
    finally
      LocalList.Free;
    end;
  end;
begin
  Result := False;
  RootArray := TJSONArray.Create;
  try
    InternalExport('', RootArray);
    with TStringList.Create do
    try
      Text := RootArray.FormatJSON;
      SaveToFile(AFileName);
      Result := True;
    finally
      Free;
    end;
  finally
    RootArray.Free;
  end;
end;

class function TServiceExport.ExportCodebook(AConnection: TSQLite3Connection; const AFileName: String): Boolean;
var
  Extension: String;
  Query: TSQLQuery;
  Workbook: TsWorkbook;
  Worksheet: TsWorksheet;
  Format: TsSpreadsheetFormat;
  OutputList: TStringList;
  RowIndex: Integer;
  Line, HexColor: String;
  CodeColor: TColor;
  R, G, B: Byte;
begin
  Result := False;
  if not Assigned(AConnection) or (AFileName = '') then Exit;
  Extension := LowerCase(ExtractFileExt(AFileName));
  Query := TSQLQuery.Create(nil);
  try
    Query.Database := AConnection;
    Query.SQL.Text :=
      'WITH RECURSIVE code_paths(id, name, description, color, created_at, full_path) AS ( ' +
      '  SELECT id, name, description, color, created_at, name as full_path ' +
      '  FROM codes WHERE parent_id = '''' ' +
      '  UNION ALL ' +
      '  SELECT c.id, c.name, c.description, c.color, c.created_at, cp.full_path || '' '#$E2#$86#$92' '' || c.name ' +
      '  FROM codes c JOIN code_paths cp ON c.parent_id = cp.id ' +
      '), ' +
      'code_usage AS ( ' +
      '  SELECT code_id, COUNT(id) as freq FROM codings GROUP BY code_id ' +
      ') ' +
      'SELECT cp.name, cp.full_path, cp.description, ' +
      '       COALESCE(m.content, '''') as code_memo, ' +
      '       cp.color, cp.created_at, COALESCE(u.freq, 0) as frequency ' +
      'FROM code_paths cp ' +
      'LEFT JOIN memos m ON m.reference = cp.id AND m.memo_type = ''Code'' ' +
      'LEFT JOIN code_usage u ON u.code_id = cp.id ' +
      'ORDER BY cp.full_path ASC';
    Query.Open;
    if (Extension = '.xlsx') or (Extension = '.ods') then
    begin
      if Extension = '.ods' then Format := sfOpenDocument else Format := sfOOXML;
      Workbook := TsWorkbook.Create;
      try
        Worksheet := Workbook.AddWorksheet('Codebook');
        Worksheet.WriteText(0, 0, 'Code Name');
        Worksheet.WriteText(0, 1, 'Hierarchy');
        Worksheet.WriteText(0, 2, 'Description');
        Worksheet.WriteText(0, 3, 'Code Memo');
        Worksheet.WriteText(0, 4, 'Color');
        Worksheet.WriteText(0, 5, 'Created At (UTC)');
        Worksheet.WriteText(0, 6, 'Usage Frequency');
        RowIndex := 1;
        while not Query.EOF do
        begin
          Worksheet.WriteText(RowIndex, 0, Query.FieldByName('name').AsString);
          Worksheet.WriteText(RowIndex, 1, Query.FieldByName('full_path').AsString);
          Worksheet.WriteText(RowIndex, 2, Query.FieldByName('description').AsString);
          Worksheet.WriteText(RowIndex, 3, Query.FieldByName('code_memo').AsString);
          CodeColor := ColorToRGB(TColor(Query.FieldByName('color').AsInteger));
          RedGreenBlue(CodeColor, R, G, B);
          HexColor := '#' + IntToHex(R, 2) + IntToHex(G, 2) + IntToHex(B, 2);
          Worksheet.WriteText(RowIndex, 4, HexColor);
          Worksheet.WriteText(RowIndex, 5, Query.FieldByName('created_at').AsString);
          Worksheet.WriteNumber(RowIndex, 6, Query.FieldByName('frequency').AsInteger);
          Inc(RowIndex);
          Query.Next;
        end;
        Workbook.WriteToFile(AFileName, Format, True);
        Result := True;
      finally
        Workbook.Free;
      end;
    end
    else if Extension = '.csv' then
    begin
      OutputList := TStringList.Create;
      try
        Line := SanitizeCSVField('Code Name') + ',' + SanitizeCSVField('Hierarchy') + ',' +
                SanitizeCSVField('Description') + ',' + SanitizeCSVField('Code Memo') + ',' +
                SanitizeCSVField('Color') + ',' + SanitizeCSVField('Created At (UTC)') + ',' +
                SanitizeCSVField('Usage Frequency');
        OutputList.Add(Line);
        while not Query.EOF do
        begin
          CodeColor := ColorToRGB(TColor(Query.FieldByName('color').AsInteger));
          RedGreenBlue(CodeColor, R, G, B);
          HexColor := '#' + IntToHex(R, 2) + IntToHex(G, 2) + IntToHex(B, 2);
          Line := SanitizeCSVField(Query.FieldByName('name').AsString) + ',' +
                  SanitizeCSVField(Query.FieldByName('full_path').AsString) + ',' +
                  SanitizeCSVField(Query.FieldByName('description').AsString) + ',' +
                  SanitizeCSVField(Query.FieldByName('code_memo').AsString) + ',' +
                  SanitizeCSVField(HexColor) + ',' +
                  SanitizeCSVField(Query.FieldByName('created_at').AsString) + ',' +
                  SanitizeCSVField(Query.FieldByName('frequency').AsString);
          OutputList.Add(Line);
          Query.Next;
        end;
        OutputList.WriteBOM := True;
        OutputList.SaveToFile(AFileName, TEncoding.UTF8);
        Result := True;
      finally
        OutputList.Free;
      end;
    end;
  finally
    Query.Free;
  end;
end;

procedure TThreadExportDocumentText.DoHeavyLifting;
var
  i, c, Counter: Integer;
  QueryMain, QueryAttribute: TSQLQuery;
  CSVList: TStringList;
  AttributeNameList, AttributeKeyList: TStringList;
  BaseTitle, SafeTitle, FinalFilename, TextContent, Line, Value: String;
  UsedFilename: TStringList;
  FileStream: TFileStream;
  UTF8Str: RawByteString;
begin
  if Length(FDocumentID) = 0 then Exit;
  QueryMain := TSQLQuery.Create(nil);
  QueryAttribute := TSQLQuery.Create(nil);
  CSVList := TStringList.Create;
  AttributeNameList := TStringList.Create;
  AttributeKeyList := TStringList.Create;
  UsedFilename := TStringList.Create;
  try
    UsedFilename.CaseSensitive := False;
    UsedFilename.Sorted := True;
    QueryMain.Database := FConnection;
    QueryAttribute.Database := FConnection;
    if not FTransaction.Active then FTransaction.StartTransaction;
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_export_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_export_docs (id TEXT PRIMARY KEY)');
    QueryMain.SQL.Text := 'INSERT INTO temp_export_docs (id) VALUES (:id)';
    QueryMain.Prepare;
    for i := Low(FDocumentID) to High(FDocumentID) do
    begin
      QueryMain.Params[0].AsString := FDocumentID[i];
      QueryMain.ExecSQL;
    end;
    QueryAttribute.SQL.Text := 'SELECT DISTINCT ar.name, ar.attribute_key FROM attribute_registry ar JOIN document_attributes da ON da.document_id IN (SELECT id FROM temp_export_docs) JOIN json_each(da.attributes) je ON je.key = ar.attribute_key WHERE je.value IS NOT NULL AND CAST(je.value AS TEXT) <> '''' ORDER BY ar.name ASC';
    QueryAttribute.Open;
    while not QueryAttribute.EOF do
    begin
      AttributeNameList.Add(QueryAttribute.Fields[0].AsString);
      AttributeKeyList.Add(QueryAttribute.Fields[1].AsString);
      QueryAttribute.Next;
    end;
    QueryAttribute.Close;
    Line := TServiceExport.SanitizeCSVField('Filename') + ',' + TServiceExport.SanitizeCSVField('Name');
    for c := 0 to AttributeNameList.Count - 1 do
      Line := Line + ',' + TServiceExport.SanitizeCSVField(AttributeNameList[c]);
    CSVList.Add(Line);
    QueryMain.SQL.Text := 'SELECT d.id, d.title, d.content, da.attributes FROM documents d LEFT JOIN document_attributes da ON d.id = da.document_id WHERE d.id IN (SELECT id FROM temp_export_docs) ORDER BY d.title ASC, d.id ASC';
    QueryMain.Open;
    i := 1;
    while not QueryMain.EOF do
    begin
      SyncUpdateStatus('Exporting document ' + IntToStr(i) + ' of ' + IntToStr(Length(FDocumentID)) + '...');
      BaseTitle := QueryMain.FieldByName('title').AsString;
      TextContent := QueryMain.FieldByName('content').AsString;
      SafeTitle := BaseTitle;
      for c := 1 to Length(SafeTitle) do
        if SafeTitle[c] in ['\', '/', ':', '*', '?', '"', '<', '>', '|'] then
          SafeTitle[c] := '-';
      SafeTitle := Trim(SafeTitle);
      if SafeTitle = '' then SafeTitle := 'Document';
      FinalFilename := SafeTitle;
      Counter := 1;
      while UsedFilename.Find(FinalFilename, c) do
      begin
        FinalFilename := SafeTitle + ' (' + IntToStr(Counter) + ')';
        Inc(Counter);
      end;
      UsedFilename.Add(FinalFilename);
      FinalFilename := FinalFilename + '.txt';
      FileStream := TFileStream.Create(IncludeTrailingPathDelimiter(FDirectoryPath) + FinalFilename, fmCreate);
      try
        if TextContent <> '' then
        begin
          UTF8Str := UTF8Encode(TextContent);
          FileStream.WriteBuffer(UTF8Str[1], Length(UTF8Str));
        end;
      finally
        FileStream.Free;
      end;
      Line := TServiceExport.SanitizeCSVField(FinalFilename) + ',' + TServiceExport.SanitizeCSVField(BaseTitle);
      if AttributeNameList.Count > 0 then
      begin
        QueryAttribute.SQL.Text := 'SELECT json_extract(:json, ''$.'' || :col)';
        QueryAttribute.Prepare;
        for c := 0 to AttributeKeyList.Count - 1 do
        begin
          QueryAttribute.Params.ParamByName('json').AsString := QueryMain.FieldByName('attributes').AsString;
          QueryAttribute.Params.ParamByName('col').AsString := AttributeKeyList[c];
          QueryAttribute.Open;
          if QueryAttribute.EOF or QueryAttribute.Fields[0].IsNull then
            Value := ''
          else
            Value := QueryAttribute.Fields[0].AsString;
          QueryAttribute.Close;
          Line := Line + ',' + TServiceExport.SanitizeCSVField(Value);
        end;
      end;
      CSVList.Add(Line);
      Inc(i);
      QueryMain.Next;
    end;
    QueryMain.Close;
    FTransaction.Commit;
    SyncUpdateStatus('Writing metadata file...');
    CSVList.WriteBOM := True;
    CSVList.SaveToFile(IncludeTrailingPathDelimiter(FDirectoryPath) + 'metadata.csv', TEncoding.UTF8);
  finally
    QueryMain.Free;
    QueryAttribute.Free;
    CSVList.Free;
    AttributeNameList.Free;
    AttributeKeyList.Free;
    UsedFilename.Free;
  end;
end;

class function TServiceExport.ExportDocumentText(AConnection: TSQLite3Connection; const ADirectoryPath: String; const ADocumentID: TStringDynArray): Boolean;
var
  Worker: TThreadExportDocumentText;
begin
  Result := False;
  if AConnection.Transaction.Active then AConnection.Transaction.Commit;
  Worker := TThreadExportDocumentText.Create(AConnection.DatabaseName);
  try
    Worker.FDirectoryPath := ADirectoryPath;
    Worker.FDocumentID := ADocumentID;
    Worker.Start;
    TfrmDialogProgress.Prepare('Exporting Documents', 'Initialising...');
    frmDialogProgress.ShowModal;
    if Worker.Success then Result := True
    else MessageDlg('Export Error', 'Failed to export documents: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

procedure TThreadExportDocumentSheet.DoHeavyLifting;
var
  i, c, RowIndex: Integer;
  QueryMain, QueryAttribute: TSQLQuery;
  AttributeNameList, AttributeKeyList: TStringList;
  Workbook: TsWorkbook;
  Worksheet: TsWorksheet;
  Value, TextContent: String;
begin
  if Length(FDocumentID) = 0 then Exit;
  QueryMain := TSQLQuery.Create(nil);
  QueryAttribute := TSQLQuery.Create(nil);
  AttributeNameList := TStringList.Create;
  AttributeKeyList := TStringList.Create;
  Workbook := TsWorkbook.Create;
  try
    QueryMain.Database := FConnection;
    QueryAttribute.Database := FConnection;
    if not FTransaction.Active then FTransaction.StartTransaction;
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_export_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_export_docs (id TEXT PRIMARY KEY)');
    QueryMain.SQL.Text := 'INSERT INTO temp_export_docs (id) VALUES (:id)';
    QueryMain.Prepare;
    for i := Low(FDocumentID) to High(FDocumentID) do
    begin
      QueryMain.Params[0].AsString := FDocumentID[i];
      QueryMain.ExecSQL;
    end;
    QueryAttribute.SQL.Text := 'SELECT DISTINCT ar.name, ar.attribute_key FROM attribute_registry ar JOIN document_attributes da ON da.document_id IN (SELECT id FROM temp_export_docs) JOIN json_each(da.attributes) je ON je.key = ar.attribute_key WHERE je.value IS NOT NULL AND CAST(je.value AS TEXT) <> '''' ORDER BY ar.name ASC';
    QueryAttribute.Open;
    while not QueryAttribute.EOF do
    begin
      AttributeNameList.Add(QueryAttribute.Fields[0].AsString);
      AttributeKeyList.Add(QueryAttribute.Fields[1].AsString);
      QueryAttribute.Next;
    end;
    QueryAttribute.Close;
    Worksheet := Workbook.AddWorksheet('Document Export');
    Worksheet.WriteText(0, 0, 'Name');
    Worksheet.WriteText(0, 1, 'Content');
    for c := 0 to AttributeNameList.Count - 1 do
      Worksheet.WriteText(0, c + 2, AttributeNameList[c]);
    QueryMain.SQL.Text := 'SELECT d.id, d.title, d.content, da.attributes FROM documents d LEFT JOIN document_attributes da ON d.id = da.document_id WHERE d.id IN (SELECT id FROM temp_export_docs) ORDER BY d.title ASC, d.id ASC';
    QueryMain.Open;
    RowIndex := 1;
    while not QueryMain.EOF do
    begin
      SyncUpdateStatus('Exporting document ' + IntToStr(RowIndex) + ' of ' + IntToStr(Length(FDocumentID)) + '...');
      Worksheet.WriteText(RowIndex, 0, QueryMain.FieldByName('title').AsString);
      TextContent := QueryMain.FieldByName('content').AsString;
      if Length(TextContent) > 32700 then
        TextContent := Copy(TextContent, 1, 32700) + '... [Truncated due to Spreadsheet Limits]';
      Worksheet.WriteText(RowIndex, 1, TextContent);
      if AttributeNameList.Count > 0 then
      begin
        QueryAttribute.SQL.Text := 'SELECT json_extract(:json, ''$.'' || :col)';
        QueryAttribute.Prepare;
        for c := 0 to AttributeKeyList.Count - 1 do
        begin
          QueryAttribute.Params.ParamByName('json').AsString := QueryMain.FieldByName('attributes').AsString;
          QueryAttribute.Params.ParamByName('col').AsString := AttributeKeyList[c];
          QueryAttribute.Open;
          if QueryAttribute.EOF or QueryAttribute.Fields[0].IsNull then
            Value := ''
          else
            Value := QueryAttribute.Fields[0].AsString;
          QueryAttribute.Close;
          Worksheet.WriteText(RowIndex, c + 2, Value);
        end;
      end;
      Inc(RowIndex);
      QueryMain.Next;
    end;
    QueryMain.Close;
    FTransaction.Commit;
    SyncUpdateStatus('Writing file to disk...');
    Workbook.WriteToFile(FFileName, FFormat, True);
  finally
    QueryMain.Free;
    QueryAttribute.Free;
    AttributeNameList.Free;
    AttributeKeyList.Free;
    Workbook.Free;
  end;
end;

class function TServiceExport.ExportDocumentSheet(AConnection: TSQLite3Connection; const AFileName: String; const ADocumentID: TStringDynArray; AFormat: TsSpreadsheetFormat): Boolean;
var
  Worker: TThreadExportDocumentSheet;
begin
  Result := False;
  if AConnection.Transaction.Active then AConnection.Transaction.Commit;
  Worker := TThreadExportDocumentSheet.Create(AConnection.DatabaseName);
  try
    Worker.FFileName := AFileName;
    Worker.FDocumentID := ADocumentID;
    Worker.FFormat := AFormat;
    Worker.Start;
    TfrmDialogProgress.Prepare('Exporting Documents', 'Initialising...');
    frmDialogProgress.ShowModal;
    if Worker.Success then Result := True
    else MessageDlg('Export Error', 'Failed to export documents: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

procedure TThreadExportDocumentJSON.DoHeavyLifting;
var
  i, c, Counter: Integer;
  QueryMain, QueryAttribute: TSQLQuery;
  AttributeNameList, AttributeKeyList: TStringList;
  RootArray: TJSONArray;
  ItemObj, MetaObj: TJSONObject;
  OutputList: TStringList;
  Value: String;
begin
  if Length(FDocumentID) = 0 then Exit;
  QueryMain := TSQLQuery.Create(nil);
  QueryAttribute := TSQLQuery.Create(nil);
  AttributeNameList := TStringList.Create;
  AttributeKeyList := TStringList.Create;
  RootArray := TJSONArray.Create;
  OutputList := TStringList.Create;
  try
    QueryMain.Database := FConnection;
    QueryAttribute.Database := FConnection;
    if not FTransaction.Active then FTransaction.StartTransaction;
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_export_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_export_docs (id TEXT PRIMARY KEY)');
    QueryMain.SQL.Text := 'INSERT INTO temp_export_docs (id) VALUES (:id)';
    QueryMain.Prepare;
    for i := Low(FDocumentID) to High(FDocumentID) do
    begin
      QueryMain.Params[0].AsString := FDocumentID[i];
      QueryMain.ExecSQL;
    end;
    QueryAttribute.SQL.Text := 'SELECT DISTINCT ar.name, ar.attribute_key FROM attribute_registry ar JOIN document_attributes da ON da.document_id IN (SELECT id FROM temp_export_docs) JOIN json_each(da.attributes) je ON je.key = ar.attribute_key WHERE je.value IS NOT NULL AND CAST(je.value AS TEXT) <> '''' ORDER BY ar.name ASC';
    QueryAttribute.Open;
    while not QueryAttribute.EOF do
    begin
      AttributeNameList.Add(QueryAttribute.Fields[0].AsString);
      AttributeKeyList.Add(QueryAttribute.Fields[1].AsString);
      QueryAttribute.Next;
    end;
    QueryAttribute.Close;
    QueryMain.SQL.Text := 'SELECT d.id, d.title, d.content, da.attributes FROM documents d LEFT JOIN document_attributes da ON d.id = da.document_id WHERE d.id IN (SELECT id FROM temp_export_docs) ORDER BY d.title ASC, d.id ASC';
    QueryMain.Open;
    Counter := 1;
    while not QueryMain.EOF do
    begin
      SyncUpdateStatus('Exporting document ' + IntToStr(Counter) + ' of ' + IntToStr(Length(FDocumentID)) + '...');
      ItemObj := TJSONObject.Create;
      ItemObj.Add('Name', QueryMain.FieldByName('title').AsString);
      ItemObj.Add('Content', QueryMain.FieldByName('content').AsString);
      if AttributeNameList.Count > 0 then
      begin
        MetaObj := TJSONObject.Create;
        QueryAttribute.SQL.Text := 'SELECT json_extract(:json, ''$.'' || :col)';
        QueryAttribute.Prepare;
        for c := 0 to AttributeKeyList.Count - 1 do
        begin
          QueryAttribute.Params.ParamByName('json').AsString := QueryMain.FieldByName('attributes').AsString;
          QueryAttribute.Params.ParamByName('col').AsString := AttributeKeyList[c];
          QueryAttribute.Open;
          if QueryAttribute.EOF or QueryAttribute.Fields[0].IsNull then
            Value := ''
          else
            Value := QueryAttribute.Fields[0].AsString;
          QueryAttribute.Close;
          MetaObj.Add(TServiceExport.CleanFieldName(AttributeNameList[c]), Value);
        end;
        ItemObj.Add('Attributes', MetaObj);
      end;
      RootArray.Add(ItemObj);
      Inc(Counter);
      QueryMain.Next;
    end;
    QueryMain.Close;
    FTransaction.Commit;
    SyncUpdateStatus('Writing file to disk...');
    OutputList.Text := RootArray.FormatJSON;
    OutputList.SaveToFile(FFileName, TEncoding.UTF8);
  finally
    QueryMain.Free;
    QueryAttribute.Free;
    AttributeNameList.Free;
    AttributeKeyList.Free;
    RootArray.Free;
    OutputList.Free;
  end;
end;

class function TServiceExport.ExportDocumentJSON(AConnection: TSQLite3Connection; const AFileName: String; const ADocumentID: TStringDynArray): Boolean;
var
  Worker: TThreadExportDocumentJSON;
begin
  Result := False;
  if AConnection.Transaction.Active then AConnection.Transaction.Commit;
  Worker := TThreadExportDocumentJSON.Create(AConnection.DatabaseName);
  try
    Worker.FFileName := AFileName;
    Worker.FDocumentID := ADocumentID;
    Worker.Start;
    TfrmDialogProgress.Prepare('Exporting Documents', 'Initialising...');
    frmDialogProgress.ShowModal;
    if Worker.Success then Result := True
    else MessageDlg('Export Error', 'Failed to export documents: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

procedure TThreadExportDocumentXML.DoHeavyLifting;
var
  i, c, Counter: Integer;
  QueryMain, QueryAttribute: TSQLQuery;
  AttributeNameList, AttributeKeyList: TStringList;
  OutputList: TStringList;
  Value: String;
begin
  if Length(FDocumentID) = 0 then Exit;
  QueryMain := TSQLQuery.Create(nil);
  QueryAttribute := TSQLQuery.Create(nil);
  AttributeNameList := TStringList.Create;
  AttributeKeyList := TStringList.Create;
  OutputList := TStringList.Create;
  try
    QueryMain.Database := FConnection;
    QueryAttribute.Database := FConnection;
    if not FTransaction.Active then FTransaction.StartTransaction;
    FConnection.ExecuteDirect('DROP TABLE IF EXISTS temp_export_docs');
    FConnection.ExecuteDirect('CREATE TEMP TABLE temp_export_docs (id TEXT PRIMARY KEY)');
    QueryMain.SQL.Text := 'INSERT INTO temp_export_docs (id) VALUES (:id)';
    QueryMain.Prepare;
    for i := Low(FDocumentID) to High(FDocumentID) do
    begin
      QueryMain.Params[0].AsString := FDocumentID[i];
      QueryMain.ExecSQL;
    end;
    QueryAttribute.SQL.Text := 'SELECT DISTINCT ar.name, ar.attribute_key FROM attribute_registry ar JOIN document_attributes da ON da.document_id IN (SELECT id FROM temp_export_docs) JOIN json_each(da.attributes) je ON je.key = ar.attribute_key WHERE je.value IS NOT NULL AND CAST(je.value AS TEXT) <> '''' ORDER BY ar.name ASC';
    QueryAttribute.Open;
    while not QueryAttribute.EOF do
    begin
      AttributeNameList.Add(QueryAttribute.Fields[0].AsString);
      AttributeKeyList.Add(QueryAttribute.Fields[1].AsString);
      QueryAttribute.Next;
    end;
    QueryAttribute.Close;
    OutputList.Add('<?xml version="1.0" encoding="UTF-8"?>');
    OutputList.Add('<Documents>');
    QueryMain.SQL.Text := 'SELECT d.id, d.title, d.content, da.attributes FROM documents d LEFT JOIN document_attributes da ON d.id = da.document_id WHERE d.id IN (SELECT id FROM temp_export_docs) ORDER BY d.title ASC, d.id ASC';
    QueryMain.Open;
    Counter := 1;
    while not QueryMain.EOF do
    begin
      SyncUpdateStatus('Exporting document ' + IntToStr(Counter) + ' of ' + IntToStr(Length(FDocumentID)) + '...');
      OutputList.Add('  <Document>');
      OutputList.Add('    <Name>' + TServiceExport.EscapeXML(QueryMain.FieldByName('title').AsString) + '</Name>');
      OutputList.Add('    <Content>' + TServiceExport.EscapeXML(QueryMain.FieldByName('content').AsString) + '</Content>');
      if AttributeNameList.Count > 0 then
      begin
        OutputList.Add('    <Attributes>');
        QueryAttribute.SQL.Text := 'SELECT json_extract(:json, ''$.'' || :col)';
        QueryAttribute.Prepare;
        for c := 0 to AttributeKeyList.Count - 1 do
        begin
          QueryAttribute.Params.ParamByName('json').AsString := QueryMain.FieldByName('attributes').AsString;
          QueryAttribute.Params.ParamByName('col').AsString := AttributeKeyList[c];
          QueryAttribute.Open;
          if QueryAttribute.EOF or QueryAttribute.Fields[0].IsNull then
            Value := ''
          else
            Value := QueryAttribute.Fields[0].AsString;
          QueryAttribute.Close;
          OutputList.Add('      <Attribute Name="' + TServiceExport.EscapeXML(TServiceExport.CleanFieldName(AttributeNameList[c])) + '">' + TServiceExport.EscapeXML(Value) + '</Attribute>');
        end;
        OutputList.Add('    </Attributes>');
      end;
      OutputList.Add('  </Document>');
      Inc(Counter);
      QueryMain.Next;
    end;
    QueryMain.Close;
    FTransaction.Commit;
    OutputList.Add('</Documents>');
    SyncUpdateStatus('Writing file to disk...');
    OutputList.SaveToFile(FFileName, TEncoding.UTF8);
  finally
    QueryMain.Free;
    QueryAttribute.Free;
    AttributeNameList.Free;
    AttributeKeyList.Free;
    OutputList.Free;
  end;
end;

class function TServiceExport.ExportDocumentXML(AConnection: TSQLite3Connection; const AFileName: String; const ADocumentID: TStringDynArray): Boolean;
var
  Worker: TThreadExportDocumentXML;
begin
  Result := False;
  if AConnection.Transaction.Active then AConnection.Transaction.Commit;
  Worker := TThreadExportDocumentXML.Create(AConnection.DatabaseName);
  try
    Worker.FFileName := AFileName;
    Worker.FDocumentID := ADocumentID;
    Worker.Start;
    TfrmDialogProgress.Prepare('Exporting Documents', 'Initialising...');
    frmDialogProgress.ShowModal;
    if Worker.Success then Result := True
    else MessageDlg('Export Error', 'Failed to export documents: ' + Worker.ErrorMessage, mtError, [mbOK], 0);
  finally
    Worker.Free;
  end;
end;

end.
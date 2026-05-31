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

unit ServiceVisualize;

{$mode ObjFPC}{$H+}

interface

uses
  Cairo, Graphics, BridgeLibrary;

type
  TChartElement = record
    LabelText: String;
    Value: Double;
    ValueStr: String;
  end;
  TChartElementArray = array of TChartElement;

  TMatrixData = array of array of Integer;

  TCloudItem = record
    WordText: String;
    PosX, PosY: Double;
    FontSize: Integer;
    BoundWidth, BoundHeight: Integer;
  end;
  TCloudItemArray = array of TCloudItem;

  TServiceVisualize = class
  private
    FActiveChart: Integer;
    FBarData: TChartElementArray;
    FCloudItem: TCloudItemArray;
    FColumnLabel: array of String;
    FColumnWidth: Double;
    FLayout: Ppango_layout_t;
    FMarginL: Double;
    FMarginT: Double;
    FMatrix: TMatrixData;
    FMaxMatrixVal: Integer;
    FMaxVal: Double;
    FMeasureContext: Pcairo_t;
    FMeasureSurface: Pcairo_surface_t;
    FRowHeight: Double;
    FRowLabel: array of String;
    FStackedSub: array of Double;
    FStackedTotal: array of Double;
    procedure ApplyThemeGradient(Context: Pcairo_t; X, Y, W, H: Double);
    procedure DrawBarChart(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double);
    procedure DrawHeatmap(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double; IsCrosstab: Boolean);
    procedure DrawStackedBarChart(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double);
    procedure DrawWordCloud(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double);
    procedure PathRoundedRect(Context: Pcairo_t; X, Y, W, H, R: Double);
  public
    constructor Create;
    destructor Destroy; override;
    procedure PrepareBarChart(const AData: TChartElementArray; out VWidth, VHeight: Integer);
    procedure PrepareHeatmap(const AColumn, ARowArray: array of String; const AMatrix: TMatrixData; MaxVal: Integer; IsCrosstab: Boolean; out VWidth, VHeight: Integer);
    procedure PrepareStackedBarChart(const ALabel: array of String; const ATotal, ASub: array of Double; const ALabelStr: array of String; out VWidth, VHeight: Integer);
    procedure PrepareWordCloud(const AWord: array of String; const AFrequency: array of Integer; out VWidth, VHeight: Integer);
    procedure Render(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double);
  end;

implementation

uses
  Math, SysUtils, Types, AppFont;

constructor TServiceVisualize.Create;
begin
  inherited Create;
  FMeasureSurface := cairo_image_surface_create(Cairo.CAIRO_FORMAT_ARGB32, 1, 1);
  FMeasureContext := cairo_create(FMeasureSurface);
  FLayout := pango_cairo_create_layout(FMeasureContext);
  pango_cairo_context_set_resolution(pango_layout_get_context(FLayout), 96.0);
  FActiveChart := -1;
end;

destructor TServiceVisualize.Destroy;
begin
  g_object_unref(FLayout);
  cairo_destroy(FMeasureContext);
  cairo_surface_destroy(FMeasureSurface);
  SetLength(FBarData, 0);
  SetLength(FColumnLabel, 0);
  SetLength(FRowLabel, 0);
  SetLength(FMatrix, 0);
  SetLength(FStackedTotal, 0);
  SetLength(FStackedSub, 0);
  SetLength(FCloudItem, 0);
  inherited Destroy;
end;

procedure TServiceVisualize.PathRoundedRect(Context: Pcairo_t; X, Y, W, H, R: Double);
begin
  cairo_new_path(Context);
  cairo_move_to(Context, X + R, Y);
  cairo_line_to(Context, X + W - R, Y);
  cairo_arc(Context, X + W - R, Y + R, R, -Pi/2, 0);
  cairo_line_to(Context, X + W, Y + H - R);
  cairo_arc(Context, X + W - R, Y + H - R, R, 0, Pi/2);
  cairo_line_to(Context, X + R, Y + H);
  cairo_arc(Context, X + R, Y + H - R, R, Pi/2, Pi);
  cairo_line_to(Context, X, Y + R);
  cairo_arc(Context, X + R, Y + R, R, Pi, 3*Pi/2);
  cairo_close_path(Context);
end;

procedure TServiceVisualize.ApplyThemeGradient(Context: Pcairo_t; X, Y, W, H: Double);
var
  Pattern: Pcairo_pattern_t;
begin
  Pattern := cairo_pattern_create_linear(X, Y, X + W, Y);
  cairo_pattern_add_color_stop_rgb(Pattern, 0.0, 106/255.0, 0, 69/255.0);
  cairo_pattern_add_color_stop_rgb(Pattern, 1.0, 255/255.0, 200/255.0, 140/255.0);
  cairo_set_source(Context, Pattern);
  cairo_fill(Context);
  cairo_pattern_destroy(Pattern);
end;

procedure TServiceVisualize.PrepareBarChart(const AData: TChartElementArray; out VWidth, VHeight: Integer);
var
  FontDescription: Ppango_font_description_t;
  TextWidth, TextHeight, MaxLeftWidth, MaxRightWidth, MaximumHeight, i: Integer;
begin
  FActiveChart := 0;
  FBarData := AData;
  FMaxVal := 0.001;
  MaxLeftWidth := 0; MaxRightWidth := 0; MaximumHeight := 0;
  FontDescription := pango_font_description_from_string(PChar(GetUniversalFontStack + ' 11'));
  pango_layout_set_font_description(FLayout, FontDescription);
  pango_font_description_free(FontDescription);
  pango_layout_set_wrap(FLayout, PANGO_WRAP_WORD_CHAR);
  for i := 0 to High(FBarData) do
  begin
    if FBarData[i].Value > FMaxVal then FMaxVal := FBarData[i].Value;
    pango_layout_set_width(FLayout, 250 * PANGO_SCALE);
    pango_layout_set_text(FLayout, PChar(FBarData[i].LabelText), -1);
    pango_layout_get_pixel_size(FLayout, @TextWidth, @TextHeight);
    if TextWidth > MaxLeftWidth then MaxLeftWidth := TextWidth;
    if TextHeight > MaximumHeight then MaximumHeight := TextHeight;
    pango_layout_set_width(FLayout, -1);
    pango_layout_set_text(FLayout, PChar(FBarData[i].ValueStr), -1);
    pango_layout_get_pixel_size(FLayout, @TextWidth, nil);
    if TextWidth > MaxRightWidth then MaxRightWidth := TextWidth;
  end;
  FRowHeight := Max(30, MaximumHeight + 4);
  FMarginL := 20.0 + Min(250, MaxLeftWidth) + 15.0; 
  VWidth := Round(FMarginL + 400.0 + 10.0 + MaxRightWidth + 20.0);
  if Length(FBarData) > 0 then
    VHeight := Round(20.0 + (Length(FBarData) * (FRowHeight + 15)) - 15.0 + 20.0)
  else
    VHeight := 40;
end;

procedure TServiceVisualize.PrepareHeatmap(const AColumn, ARowArray: array of String; const AMatrix: TMatrixData; MaxVal: Integer; IsCrosstab: Boolean; out VWidth, VHeight: Integer);
var
  FontDescription: Ppango_font_description_t;
  TextWidth, TextHeight, MaxRowWidth, MaxRowHeight, MaxColumnWidth, MaxColumnHeight, i: Integer;
begin
  if IsCrosstab then FActiveChart := 2 else FActiveChart := 1;
  SetLength(FColumnLabel, Length(AColumn));
  for i := 0 to High(AColumn) do FColumnLabel[i] := AColumn[i];
  SetLength(FRowLabel, Length(ARowArray));
  for i := 0 to High(ARowArray) do FRowLabel[i] := ARowArray[i];
  FMatrix := AMatrix;
  FMaxMatrixVal := MaxVal;
  MaxRowWidth := 0; MaxRowHeight := 0; MaxColumnWidth := 0; MaxColumnHeight := 0;
  FontDescription := pango_font_description_from_string(PChar(GetUniversalFontStack + ' 11'));
  pango_layout_set_font_description(FLayout, FontDescription);
  pango_font_description_free(FontDescription);
  pango_layout_set_wrap(FLayout, PANGO_WRAP_WORD_CHAR);
  for i := 0 to High(FRowLabel) do
  begin
    pango_layout_set_width(FLayout, 250 * PANGO_SCALE);
    pango_layout_set_text(FLayout, PChar(FRowLabel[i]), -1);
    pango_layout_get_pixel_size(FLayout, @TextWidth, @TextHeight);
    if TextWidth > MaxRowWidth then MaxRowWidth := TextWidth;
    if TextHeight > MaxRowHeight then MaxRowHeight := TextHeight;
  end;
  FMarginL := 20.0 + Min(250, MaxRowWidth) + 15.0;
  FRowHeight := Max(40, MaxRowHeight + 15);
  for i := 0 to High(FColumnLabel) do
  begin
    pango_layout_set_width(FLayout, 200 * PANGO_SCALE);
    pango_layout_set_text(FLayout, PChar(FColumnLabel[i]), -1);
    pango_layout_get_pixel_size(FLayout, @TextWidth, @TextHeight);
    if TextWidth > MaxColumnWidth then MaxColumnWidth := TextWidth;
    if TextHeight > MaxColumnHeight then MaxColumnHeight := TextHeight;
  end;
  FMarginT := 20.0 + Min(200, MaxColumnWidth) + 15.0;
  FColumnWidth := Max(40, MaxColumnHeight + 15);
  if FRowHeight > FColumnWidth then
    FColumnWidth := FRowHeight
  else
    FRowHeight := FColumnWidth;
  VWidth := Round(FMarginL + (Length(FColumnLabel) * FColumnWidth) + 20.0);
  VHeight := Round(FMarginT + (Length(FRowLabel) * FRowHeight) + 20.0);
end;

procedure TServiceVisualize.PrepareStackedBarChart(const ALabel: array of String; const ATotal, ASub: array of Double; const ALabelStr: array of String; out VWidth, VHeight: Integer);
var
  FontDescription: Ppango_font_description_t;
  TextWidth, TextHeight, MaxLeftWidth, MaxRightWidth, MaximumHeight, i: Integer;
begin
  FActiveChart := 3;
  SetLength(FRowLabel, Length(ALabel));
  SetLength(FStackedTotal, Length(ATotal));
  SetLength(FStackedSub, Length(ASub));
  SetLength(FColumnLabel, Length(ALabelStr));
  MaxLeftWidth := 0; MaxRightWidth := 0; MaximumHeight := 0;
  FontDescription := pango_font_description_from_string(PChar(GetUniversalFontStack + ' 11'));
  pango_layout_set_font_description(FLayout, FontDescription);
  pango_font_description_free(FontDescription);
  pango_layout_set_wrap(FLayout, PANGO_WRAP_WORD_CHAR);
  for i := 0 to High(ALabel) do
  begin
    FRowLabel[i] := ALabel[i];
    FStackedTotal[i] := ATotal[i];
    FStackedSub[i] := ASub[i];
    FColumnLabel[i] := ALabelStr[i];
    pango_layout_set_width(FLayout, 250 * PANGO_SCALE);
    pango_layout_set_text(FLayout, PChar(FRowLabel[i]), -1);
    pango_layout_get_pixel_size(FLayout, @TextWidth, @TextHeight);
    if TextWidth > MaxLeftWidth then MaxLeftWidth := TextWidth;
    if TextHeight > MaximumHeight then MaximumHeight := TextHeight;
    pango_layout_set_width(FLayout, -1);
    pango_layout_set_text(FLayout, PChar(FColumnLabel[i]), -1);
    pango_layout_get_pixel_size(FLayout, @TextWidth, nil);
    if TextWidth > MaxRightWidth then MaxRightWidth := TextWidth;
  end;
  FRowHeight := Max(30, MaximumHeight + 4);
  FMarginL := 20.0 + Min(250, MaxLeftWidth) + 15.0;
  VWidth := Round(FMarginL + 400.0 + 10.0 + MaxRightWidth + 20.0);
  if Length(FRowLabel) > 0 then
    VHeight := Round(20.0 + (Length(FRowLabel) * (FRowHeight + 15)) - 15.0 + 20.0)
  else
    VHeight := 40;
end;

procedure TServiceVisualize.PrepareWordCloud(const AWord: array of String; const AFrequency: array of Integer; out VWidth, VHeight: Integer);
var
  MaxFrequency, i, j, TextWidth, TextHeight, Limit: Integer;
  Radius, Theta, StepRadius, ScaleFactor, FontSize: Double;
  FontDescription: Ppango_font_description_t;
  FontStr: String;
  TemporaryRectangle: TRect;
  Intersects, PlacedSuccess: Boolean;
  MinX, MinY, MaxX, MaxY: Double;
begin
  FActiveChart := 4;
  Limit := Length(AWord);
  SetLength(FCloudItem, 0);
  VWidth := 40; VHeight := 40; 
  if Limit = 0 then Exit;
  MaxFrequency := 1;
  for i := 0 to Limit - 1 do
    if AFrequency[i] > MaxFrequency then MaxFrequency := AFrequency[i];
  for i := 0 to Limit - 1 do
  begin
    FontSize := 14.0 + (50.0 * (AFrequency[i] / MaxFrequency));
    ScaleFactor := 1.0;
    PlacedSuccess := False;
    while (ScaleFactor >= 0.25) and not PlacedSuccess do
    begin
      FontStr := GetUniversalFontStack + ' ' + IntToStr(Round(FontSize * ScaleFactor));
      FontDescription := pango_font_description_from_string(PChar(FontStr));
      pango_layout_set_font_description(FLayout, FontDescription);
      pango_layout_set_text(FLayout, PChar(AWord[i]), -1);
      pango_layout_get_pixel_size(FLayout, @TextWidth, @TextHeight);
      pango_font_description_free(FontDescription);
      Theta := 0.0;
      while True do
      begin
        Radius := 0.5 * Theta;
        if Radius > 8000.0 then Break; 
        TemporaryRectangle.Left := Round((Radius * Cos(Theta)) - (TextWidth / 2.0)) - 2;
        TemporaryRectangle.Top := Round((Radius * Sin(Theta)) - (TextHeight / 2.0)) - 2;
        TemporaryRectangle.Right := TemporaryRectangle.Left + TextWidth + 4;
        TemporaryRectangle.Bottom := TemporaryRectangle.Top + TextHeight + 4;
        Intersects := False;
        for j := 0 to High(FCloudItem) do
        begin
          if (TemporaryRectangle.Left <= FCloudItem[j].PosX + FCloudItem[j].BoundWidth) and (TemporaryRectangle.Right >= FCloudItem[j].PosX) and (TemporaryRectangle.Top <= FCloudItem[j].PosY + FCloudItem[j].BoundHeight) and (TemporaryRectangle.Bottom >= FCloudItem[j].PosY) then
          begin
            Intersects := True;
            Break;
          end;
        end;
        if not Intersects then
        begin
          SetLength(FCloudItem, Length(FCloudItem) + 1);
          FCloudItem[High(FCloudItem)].WordText := AWord[i];
          FCloudItem[High(FCloudItem)].PosX := TemporaryRectangle.Left + 2;
          FCloudItem[High(FCloudItem)].PosY := TemporaryRectangle.Top + 2;
          FCloudItem[High(FCloudItem)].FontSize := Round(FontSize * ScaleFactor);
          FCloudItem[High(FCloudItem)].BoundWidth := TextWidth;
          FCloudItem[High(FCloudItem)].BoundHeight := TextHeight;
          PlacedSuccess := True;
          Break;
        end;
        StepRadius := Max(1.0, Radius);
        Theta := Theta + (1.0 / StepRadius);
      end;
      if not PlacedSuccess then ScaleFactor := ScaleFactor - 0.15;
    end;
  end;
  if Length(FCloudItem) > 0 then
  begin
    MinX := FCloudItem[0].PosX; MinY := FCloudItem[0].PosY;
    MaxX := MinX + FCloudItem[0].BoundWidth; MaxY := MinY + FCloudItem[0].BoundHeight;
    for i := 1 to High(FCloudItem) do
    begin
      MinX := Min(MinX, FCloudItem[i].PosX);
      MinY := Min(MinY, FCloudItem[i].PosY);
      MaxX := Max(MaxX, FCloudItem[i].PosX + FCloudItem[i].BoundWidth);
      MaxY := Max(MaxY, FCloudItem[i].PosY + FCloudItem[i].BoundHeight);
    end;
    for i := 0 to High(FCloudItem) do
    begin
      FCloudItem[i].PosX := FCloudItem[i].PosX - MinX + 20.0;
      FCloudItem[i].PosY := FCloudItem[i].PosY - MinY + 20.0;
    end;
    VWidth := Round((MaxX - MinX) + 40.0);
    VHeight := Round((MaxY - MinY) + 40.0);
  end;
end;

procedure TServiceVisualize.DrawBarChart(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double);
var
  LogicalY, LogicalHeight, BaseY, CenterY, BarWidth: Double;
  StartIndex, EndIndex, i, TextHeight: Integer;
  FontDescription: Ppango_font_description_t;
begin
  LogicalY := -PanY / Zoom;
  LogicalHeight := ViewHeight / Zoom;
  StartIndex := Max(0, Floor((LogicalY - 20) / (FRowHeight + 15)));
  EndIndex := Min(High(FBarData), Ceil((LogicalY + LogicalHeight - 20) / (FRowHeight + 15)));
  if StartIndex > EndIndex then Exit;
  FontDescription := pango_font_description_from_string(PChar(GetUniversalFontStack + ' 11'));
  pango_layout_set_font_description(FLayout, FontDescription);
  pango_font_description_free(FontDescription);
  for i := StartIndex to EndIndex do
  begin
    BaseY := 20.0 + (i * (FRowHeight + 15.0));
    CenterY := BaseY + (FRowHeight / 2.0);
    BarWidth := (FBarData[i].Value / FMaxVal) * 400.0;
    if BarWidth < 5.0 then BarWidth := 5.0;
    PathRoundedRect(Context, FMarginL, CenterY - (FRowHeight / 2.0), BarWidth, FRowHeight, 4.0);
    ApplyThemeGradient(Context, FMarginL, CenterY - (FRowHeight / 2.0), BarWidth, FRowHeight);
    cairo_set_source_rgb(Context, 0, 0, 0);
    pango_layout_set_width(FLayout, Round((FMarginL - 20.0 - 15.0) * PANGO_SCALE));
    pango_layout_set_alignment(FLayout, PANGO_ALIGN_RIGHT);
    pango_layout_set_text(FLayout, PChar(FBarData[i].LabelText), -1);
    pango_layout_get_pixel_size(FLayout, nil, @TextHeight);
    cairo_move_to(Context, 20.0, CenterY - (TextHeight / 2.0));
    pango_cairo_show_layout(Context, FLayout);
    pango_layout_set_width(FLayout, -1);
    pango_layout_set_alignment(FLayout, PANGO_ALIGN_LEFT);
    pango_layout_set_text(FLayout, PChar(FBarData[i].ValueStr), -1);
    pango_layout_get_pixel_size(FLayout, nil, @TextHeight);
    cairo_move_to(Context, FMarginL + BarWidth + 10.0, CenterY - (TextHeight / 2.0));
    pango_cairo_show_layout(Context, FLayout);
  end;
end;

procedure TServiceVisualize.DrawHeatmap(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double; IsCrosstab: Boolean);
var
  LogicalX, LogicalY, LogicalWidth, LogicalHeight: Double;
  StartCol, EndCol, StartRow, EndRow, r, c, Value, TextWidth, TextHeight: Integer;
  Intensity, CellX, CellY: Double;
  FontDescription: Ppango_font_description_t;
begin
  LogicalX := -PanX / Zoom;
  LogicalY := -PanY / Zoom;
  LogicalWidth := ViewWidth / Zoom;
  LogicalHeight := ViewHeight / Zoom;
  StartCol := Max(0, Floor((LogicalX - FMarginL) / FColumnWidth));
  EndCol := Min(High(FColumnLabel), Ceil((LogicalX + LogicalWidth - FMarginL) / FColumnWidth));
  StartRow := Max(0, Floor((LogicalY - FMarginT) / FRowHeight));
  EndRow := Min(High(FRowLabel), Ceil((LogicalY + LogicalHeight - FMarginT) / FRowHeight));
  if (StartCol > EndCol) or (StartRow > EndRow) then Exit;
  FontDescription := pango_font_description_from_string(PChar(GetUniversalFontStack + ' 11'));
  pango_layout_set_font_description(FLayout, FontDescription);
  pango_font_description_free(FontDescription);
  cairo_set_line_width(Context, 1.0);
  for r := StartRow to EndRow do
  begin
    for c := StartCol to EndCol do
    begin
      Value := FMatrix[c, r];
      CellX := FMarginL + (c * FColumnWidth);
      CellY := FMarginT + (r * FRowHeight);
      if Value > 0 then
      begin
        Intensity := Value / FMaxMatrixVal;
        if IsCrosstab then cairo_set_source_rgba(Context, 255/255.0, 200/255.0, 140/255.0, Intensity)
        else cairo_set_source_rgba(Context, 106/255.0, 0, 69/255.0, Intensity);
        cairo_rectangle(Context, CellX, CellY, FColumnWidth, FRowHeight);
        cairo_fill_preserve(Context);
        cairo_set_source_rgba(Context, 0, 0, 0, 0.1);
        cairo_stroke(Context);
        pango_layout_set_width(FLayout, -1);
        pango_layout_set_alignment(FLayout, PANGO_ALIGN_CENTER);
        pango_layout_set_text(FLayout, PChar(IntToStr(Value)), -1);
        pango_layout_get_pixel_size(FLayout, @TextWidth, @TextHeight);
        if Intensity > 0.5 then cairo_set_source_rgb(Context, 1, 1, 1) else cairo_set_source_rgb(Context, 0, 0, 0);
        cairo_move_to(Context, CellX + (FColumnWidth / 2.0) - (TextWidth / 2.0), CellY + (FRowHeight / 2.0) - (TextHeight / 2.0));
        pango_cairo_show_layout(Context, FLayout);
      end
      else
      begin
        cairo_set_source_rgba(Context, 0.95, 0.95, 0.95, 1.0);
        cairo_rectangle(Context, CellX, CellY, FColumnWidth, FRowHeight);
        cairo_fill_preserve(Context);
        cairo_set_source_rgba(Context, 0, 0, 0, 0.05);
        cairo_stroke(Context);
      end;
    end;
  end;
  cairo_set_source_rgb(Context, 0, 0, 0);
  pango_layout_set_width(FLayout, Round((FMarginL - 20.0 - 15.0) * PANGO_SCALE));
  pango_layout_set_alignment(FLayout, PANGO_ALIGN_RIGHT);
  for r := StartRow to EndRow do
  begin
    pango_layout_set_text(FLayout, PChar(FRowLabel[r]), -1);
    pango_layout_get_pixel_size(FLayout, nil, @TextHeight);
    cairo_move_to(Context, 20.0, FMarginT + (r * FRowHeight) + (FRowHeight / 2.0) - (TextHeight / 2.0));
    pango_cairo_show_layout(Context, FLayout);
  end;
  pango_layout_set_width(FLayout, Round((FMarginT - 20.0 - 15.0) * PANGO_SCALE));
  pango_layout_set_alignment(FLayout, PANGO_ALIGN_LEFT);
  for c := StartCol to EndCol do
  begin
    pango_layout_set_text(FLayout, PChar(FColumnLabel[c]), -1);
    pango_layout_get_pixel_size(FLayout, nil, @TextHeight);
    cairo_save(Context);
    cairo_translate(Context, FMarginL + (c * FColumnWidth) + (FColumnWidth / 2.0) - (TextHeight / 2.0), FMarginT - 15.0);
    cairo_rotate(Context, -Pi / 2);
    cairo_move_to(Context, 0, 0);
    pango_cairo_show_layout(Context, FLayout);
    cairo_restore(Context);
  end;
end;

procedure TServiceVisualize.DrawStackedBarChart(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double);
var
  LogicalY, LogicalHeight, BaseY, CenterY, BarWidth, Percentage: Double;
  StartIndex, EndIndex, i, TextHeight: Integer;
  FontDescription: Ppango_font_description_t;
begin
  LogicalY := -PanY / Zoom;
  LogicalHeight := ViewHeight / Zoom;
  StartIndex := Max(0, Floor((LogicalY - 20) / (FRowHeight + 15)));
  EndIndex := Min(High(FRowLabel), Ceil((LogicalY + LogicalHeight - 20) / (FRowHeight + 15)));
  if StartIndex > EndIndex then Exit;
  FontDescription := pango_font_description_from_string(PChar(GetUniversalFontStack + ' 11'));
  pango_layout_set_font_description(FLayout, FontDescription);
  pango_font_description_free(FontDescription);
  for i := StartIndex to EndIndex do
  begin
    BaseY := 20.0 + (i * (FRowHeight + 15.0));
    CenterY := BaseY + (FRowHeight / 2.0);
    if FStackedTotal[i] > 0 then Percentage := FStackedSub[i] / FStackedTotal[i] else Percentage := 0.0;
    PathRoundedRect(Context, FMarginL, CenterY - (FRowHeight / 2.0), 400.0, FRowHeight, 4.0);
    cairo_set_source_rgb(Context, 0.9, 0.9, 0.9);
    cairo_fill(Context);
    if Percentage > 0 then
    begin
      BarWidth := 400.0 * Percentage;
      if BarWidth < 5.0 then BarWidth := 5.0;
      PathRoundedRect(Context, FMarginL, CenterY - (FRowHeight / 2.0), BarWidth, FRowHeight, 4.0);
      ApplyThemeGradient(Context, FMarginL, CenterY - (FRowHeight / 2.0), BarWidth, FRowHeight);
    end;
    cairo_set_source_rgb(Context, 0, 0, 0);
    pango_layout_set_width(FLayout, Round((FMarginL - 20.0 - 15.0) * PANGO_SCALE));
    pango_layout_set_alignment(FLayout, PANGO_ALIGN_RIGHT);
    pango_layout_set_text(FLayout, PChar(FRowLabel[i]), -1);
    pango_layout_get_pixel_size(FLayout, nil, @TextHeight);
    cairo_move_to(Context, 20.0, CenterY - (TextHeight / 2.0));
    pango_cairo_show_layout(Context, FLayout);
    pango_layout_set_width(FLayout, -1);
    pango_layout_set_alignment(FLayout, PANGO_ALIGN_LEFT);
    pango_layout_set_text(FLayout, PChar(FColumnLabel[i]), -1);
    pango_layout_get_pixel_size(FLayout, nil, @TextHeight);
    cairo_move_to(Context, FMarginL + 400.0 + 10.0, CenterY - (TextHeight / 2.0));
    pango_cairo_show_layout(Context, FLayout);
  end;
end;

procedure TServiceVisualize.DrawWordCloud(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double);
var
  LogicalX, LogicalY, LogicalWidth, LogicalHeight: Double;
  i: Integer;
  FontDescription: Ppango_font_description_t;
  FontStr: String;
begin
  LogicalX := -PanX / Zoom;
  LogicalY := -PanY / Zoom;
  LogicalWidth := ViewWidth / Zoom;
  LogicalHeight := ViewHeight / Zoom;
  cairo_set_source_rgb(Context, 106/255.0, 0, 69/255.0);
  pango_layout_set_width(FLayout, -1);
  for i := 0 to High(FCloudItem) do
  begin
    if (FCloudItem[i].PosX + FCloudItem[i].BoundWidth >= LogicalX) and (FCloudItem[i].PosX <= LogicalX + LogicalWidth) and
       (FCloudItem[i].PosY + FCloudItem[i].BoundHeight >= LogicalY) and (FCloudItem[i].PosY <= LogicalY + LogicalHeight) then
    begin
      FontStr := GetUniversalFontStack + ' ' + IntToStr(FCloudItem[i].FontSize);
      FontDescription := pango_font_description_from_string(PChar(FontStr));
      pango_layout_set_font_description(FLayout, FontDescription);
      pango_font_description_free(FontDescription);
      pango_layout_set_text(FLayout, PChar(FCloudItem[i].WordText), -1);
      cairo_move_to(Context, FCloudItem[i].PosX, FCloudItem[i].PosY);
      pango_cairo_show_layout(Context, FLayout);
    end;
  end;
end;

procedure TServiceVisualize.Render(Context: Pcairo_t; ViewWidth, ViewHeight: Integer; PanX, PanY, Zoom: Double);
begin
  if FActiveChart = -1 then Exit;
  cairo_save(Context);
  cairo_translate(Context, PanX, PanY);
  cairo_scale(Context, Zoom, Zoom);
  case FActiveChart of
    0: DrawBarChart(Context, ViewWidth, ViewHeight, PanX, PanY, Zoom);
    1: DrawHeatmap(Context, ViewWidth, ViewHeight, PanX, PanY, Zoom, False);
    2: DrawHeatmap(Context, ViewWidth, ViewHeight, PanX, PanY, Zoom, True);
    3: DrawStackedBarChart(Context, ViewWidth, ViewHeight, PanX, PanY, Zoom);
    4: DrawWordCloud(Context, ViewWidth, ViewHeight, PanX, PanY, Zoom);
  end;
  cairo_restore(Context);
end;

end.

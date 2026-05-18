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

unit BridgeLibrary;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Graphics, LCLIntf, LCLType, SysUtils;

const
  CairoLib = 'libcairo-2.dll';
  FontConfigLib = 'libfontconfig-1.dll';
  GLibLib = 'libglib-2.0-0.dll';
  GObjectLib = 'libgobject-2.0-0.dll';
  PangoCairoLib = 'libpangocairo-1.0-0.dll';
  PangoLib = 'libpango-1.0-0.dll';
  PangoWin32Lib = 'libpangowin32-1.0-0.dll';
  PdfiumLib = 'pdfium.dll';

  CAIRO_ANTIALIAS_BEST = 6;
  CAIRO_FORMAT_ARGB32 = 0;
  CAIRO_HINT_STYLE_SLIGHT = 1;
  CAIRO_STATUS_SUCCESS = 0;
  CAIRO_TAG_LINK = 'Link';
  PANGO_ALIGN_CENTER = 1;
  PANGO_ALIGN_LEFT = 0;
  PANGO_ALIGN_RIGHT = 2;
  PANGO_SCALE = 1024;
  PANGO_WRAP_WORD_CHAR = 2;

type
  cairo_status_t = Integer;
  Pcairo_pattern_t = Pointer;
  Pcairo_surface_t = Pointer;
  Pcairo_t = Pointer;
  Ppango_attr_list_t = Pointer;
  Ppango_attribute_t = ^TPangoAttribute;
  Ppango_font_description_t = Pointer;
  Ppango_font_map_t = Pointer;
  Ppango_layout_t = Pointer;
  PPangoContext = Pointer;
  PPangoFontMetrics = Pointer;
  FPDF_DOCUMENT = Pointer;
  FPDF_PAGE = Pointer;
  FPDF_TEXTPAGE = Pointer;

  TPangoAttribute = record
    klass: Pointer;
    start_index: Cardinal;
    end_index: Cardinal;
  end;

  TPangoRectangle = record
    X, Y, Width, Height: Integer;
  end;
  PPangoRectangle = ^TPangoRectangle;

  function cairo_create(target: Pcairo_surface_t): Pcairo_t; cdecl; external CairoLib;
  function cairo_font_options_create: Pointer; cdecl; external CairoLib;
  function cairo_pattern_create_linear(x0, y0, x1, y1: Double): Pcairo_pattern_t; cdecl; external CairoLib;
  function cairo_pdf_surface_create(filename: PChar; width_in_points, height_in_points: Double): Pcairo_surface_t; cdecl; external CairoLib;
  function cairo_status(cr: Pcairo_t): cairo_status_t; cdecl; external CairoLib;
  function cairo_status_to_string(status: cairo_status_t): PChar; cdecl; external CairoLib;
  function cairo_surface_status(surface: Pcairo_surface_t): cairo_status_t; cdecl; external CairoLib;
  function cairo_surface_write_to_png(surface: Pcairo_surface_t; filename: PChar): cairo_status_t; cdecl; external CairoLib;
  function cairo_svg_surface_create(filename: PChar; width_in_points, height_in_points: Double): Pcairo_surface_t; cdecl; external CairoLib;
  function cairo_win32_surface_create(hdc: HDC): Pcairo_surface_t; cdecl; external CairoLib;
  function FcConfigAppFontAddFile(config: Pointer; fileName: PChar): Integer; cdecl; external FontConfigLib;
  function FcConfigGetCurrent: Pointer; cdecl; external FontConfigLib;
  function FPDF_GetPageCount(document: FPDF_DOCUMENT): Integer; stdcall; external PdfiumLib;
  function FPDF_LoadDocument(file_path: PAnsiChar; password: PAnsiChar): FPDF_DOCUMENT; stdcall; external PdfiumLib;
  function FPDF_LoadMemDocument(data_buf: Pointer; size: Integer; password: PAnsiChar): FPDF_DOCUMENT; stdcall; external PdfiumLib;
  function FPDF_LoadPage(document: FPDF_DOCUMENT; page_index: Integer): FPDF_PAGE; stdcall; external PdfiumLib;
  function FPDFText_CountChars(text_page: FPDF_TEXTPAGE): Integer; stdcall; external PdfiumLib;
  function FPDFText_GetCharBox(text_page: FPDF_TEXTPAGE; index: Integer; out left, right, bottom, top: Double): Boolean; stdcall; external PdfiumLib;
  function FPDFText_GetText(text_page: FPDF_TEXTPAGE; start_index: Integer; count: Integer; result_buf: PWideChar): Integer; stdcall; external PdfiumLib;
  function FPDFText_GetUnicode(text_page: FPDF_TEXTPAGE; index: Integer): Cardinal; stdcall; external PdfiumLib;
  function FPDFText_LoadPage(page: FPDF_PAGE): FPDF_TEXTPAGE; stdcall; external PdfiumLib;
  function pango_attr_background_new(red, green, blue: Word): Ppango_attribute_t; cdecl; external PangoLib;
  function pango_attr_list_new: Ppango_attr_list_t; cdecl; external PangoLib;
  function pango_cairo_create_layout(cr: Pcairo_t): Ppango_layout_t; cdecl; external PangoCairoLib;
  function pango_cairo_font_map_get_default: Ppango_font_map_t; cdecl; external PangoCairoLib;
  function pango_context_get_metrics(context: PPangoContext; desc: Ppango_font_description_t; language: Pointer): PPangoFontMetrics; cdecl; external PangoLib;
  function pango_font_description_from_string(str: PChar): Ppango_font_description_t; cdecl; external PangoLib;
  function pango_font_metrics_get_ascent(metrics: PPangoFontMetrics): Integer; cdecl; external PangoLib;
  function pango_font_metrics_get_descent(metrics: PPangoFontMetrics): Integer; cdecl; external PangoLib;
  function pango_layout_get_context(layout: Ppango_layout_t): Pointer; cdecl; external PangoLib;
  function pango_layout_get_iter(layout: Ppango_layout_t): Pointer; cdecl; external PangoLib;
  function pango_layout_get_line_count(layout: Ppango_layout_t): Integer; cdecl; external PangoLib;
  function pango_layout_get_line_readonly(layout: Ppango_layout_t; line_index: Integer): Pointer; cdecl; external PangoLib;
  function pango_layout_get_unknown_glyphs_count(layout: Ppango_layout_t): Integer; cdecl; external PangoLib;
  function pango_layout_iter_get_baseline(iter: Pointer): Integer; cdecl; external PangoLib;
  function pango_layout_iter_get_index(iter: Pointer): Integer; cdecl; external PangoLib;
  function pango_layout_iter_get_line_readonly(iter: Pointer): Pointer; cdecl; external PangoLib;
  function pango_layout_iter_next_line(iter: Pointer): Boolean; cdecl; external PangoLib;
  function pango_win32_font_map_for_display: Ppango_font_map_t; cdecl; external PangoWin32Lib;
  procedure cairo_arc(cr: Pcairo_t; xc, yc, radius, angle1, angle2: Double); cdecl; external CairoLib;
  procedure cairo_clip(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_close_path(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_destroy(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_fill(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_fill_preserve(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_font_options_destroy(options: Pointer); cdecl; external CairoLib;
  procedure cairo_font_options_set_antialias(options: Pointer; antialias: Integer); cdecl; external CairoLib;
  procedure cairo_font_options_set_hint_style(options: Pointer; hint_style: Integer); cdecl; external CairoLib;
  procedure cairo_line_to(cr: Pcairo_t; x, y: Double); cdecl; external CairoLib;
  procedure cairo_move_to(cr: Pcairo_t; x, y: Double); cdecl; external CairoLib;
  procedure cairo_new_path(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_paint(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_pattern_add_color_stop_rgb(pat: Pcairo_pattern_t; offset, r, g, b: Double); cdecl; external CairoLib;
  procedure cairo_pattern_add_color_stop_rgba(pat: Pcairo_pattern_t; offset, r, g, b, a: Double); cdecl; external CairoLib;
  procedure cairo_pattern_destroy(pat: Pcairo_pattern_t); cdecl; external CairoLib;
  procedure cairo_pdf_surface_set_metadata(surface: Pcairo_surface_t; metadata: Integer; utf8: PChar); cdecl; external CairoLib;
  procedure cairo_rectangle(cr: Pcairo_t; x, y, width, height: Double); cdecl; external CairoLib;
  procedure cairo_restore(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_save(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_set_antialias(cr: Pcairo_t; antialias: Integer); cdecl; external CairoLib;
  procedure cairo_set_line_width(cr: Pcairo_t; width: Double); cdecl; external CairoLib;
  procedure cairo_set_source(cr: Pcairo_t; source: Pcairo_pattern_t); cdecl; external CairoLib;
  procedure cairo_set_source_rgb(cr: Pcairo_t; red, green, blue: Double); cdecl; external CairoLib;
  procedure cairo_set_source_rgba(cr: Pcairo_t; r, g, b, a: Double); cdecl; external CairoLib;
  procedure cairo_show_page(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_stroke(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_stroke_preserve(cr: Pcairo_t); cdecl; external CairoLib;
  procedure cairo_surface_destroy(surface: Pcairo_surface_t); cdecl; external CairoLib;
  procedure cairo_surface_finish(surface: Pcairo_surface_t); cdecl; external CairoLib;
  procedure cairo_surface_set_fallback_resolution(surface: Pcairo_surface_t; x_pixels_per_inch, y_pixels_per_inch: Double); cdecl; external CairoLib;
  procedure cairo_tag_begin(cr: Pcairo_t; tag_name: PChar; attributes: PChar); cdecl; external CairoLib;
  procedure cairo_tag_end(cr: Pcairo_t; tag_name: PChar); cdecl; external CairoLib;
  procedure cairo_translate(cr: Pcairo_t; tx, ty: Double); cdecl; external CairoLib;
  procedure FPDF_CloseDocument(document: FPDF_DOCUMENT); stdcall; external PdfiumLib;
  procedure FPDF_ClosePage(page: FPDF_PAGE); stdcall; external PdfiumLib;
  procedure FPDF_DestroyLibrary; stdcall; external PdfiumLib;
  procedure FPDF_InitLibrary; stdcall; external PdfiumLib;
  procedure FPDFText_ClosePage(text_page: FPDF_TEXTPAGE); stdcall; external PdfiumLib;
  procedure g_free(mem: Pointer); cdecl; external GLibLib;
  procedure g_object_unref(obj: Pointer); cdecl; external GObjectLib;
  procedure pango_attr_list_insert(list: Ppango_attr_list_t; attr: Ppango_attribute_t); cdecl; external PangoLib;
  procedure pango_attr_list_unref(list: Ppango_attr_list_t); cdecl; external PangoLib;
  procedure pango_cairo_context_set_font_options(context: Pointer; options: Pointer); cdecl; external PangoCairoLib;
  procedure pango_cairo_context_set_resolution(context: Pointer; dpi: Double); cdecl; external PangoCairoLib;
  procedure pango_cairo_font_map_set_default(font_map: Ppango_font_map_t); cdecl; external PangoCairoLib;
  procedure pango_cairo_show_layout(cr: Pcairo_t; layout: Ppango_layout_t); cdecl; external PangoCairoLib;
  procedure pango_cairo_show_layout_line(cr: Pcairo_t; line: Pointer); cdecl; external PangoCairoLib;
  procedure pango_cairo_update_layout(cr: Pcairo_t; layout: Ppango_layout_t); cdecl; external PangoCairoLib;
  procedure pango_font_description_free(desc: Ppango_font_description_t); cdecl; external PangoLib;
  procedure pango_font_description_set_family(desc: Ppango_font_description_t; family: PChar); cdecl; external PangoLib;
  procedure pango_font_description_set_size(desc: Ppango_font_description_t; size: Integer); cdecl; external PangoLib;
  procedure pango_font_metrics_unref(metrics: PPangoFontMetrics); cdecl; external PangoLib;
  procedure pango_layout_get_cursor_pos(layout: Ppango_layout_t; index: Integer; strong_pos, weak_pos: PPangoRectangle); cdecl; external PangoLib;
  procedure pango_layout_get_pixel_size(layout: Ppango_layout_t; width, height: PInteger); cdecl; external PangoLib;
  procedure pango_layout_index_to_pos(layout: Ppango_layout_t; index: Integer; pos: PPangoRectangle); cdecl; external PangoLib;
  procedure pango_layout_iter_free(iter: Pointer); cdecl; external PangoLib;
  procedure pango_layout_iter_get_line_extents(iter: Pointer; ink_rect, logical_rect: PPangoRectangle); cdecl; external PangoLib;
  procedure pango_layout_line_get_extents(line: Pointer; ink_rect, logical_rect: PPangoRectangle); cdecl; external PangoLib;
  procedure pango_layout_line_get_x_ranges(line: Pointer; start_index, end_index: Integer; ranges: PPointer; n_ranges: PInteger); cdecl; external PangoLib;
  procedure pango_layout_set_alignment(layout: Ppango_layout_t; alignment: Integer); cdecl; external PangoLib;
  procedure pango_layout_set_attributes(layout: Ppango_layout_t; attrs: Ppango_attr_list_t); cdecl; external PangoLib;
  procedure pango_layout_set_font_description(layout: Ppango_layout_t; desc: Ppango_font_description_t); cdecl; external PangoLib;
  procedure pango_layout_set_spacing(layout: Ppango_layout_t; spacing: Integer); cdecl; external PangoLib;
  procedure pango_layout_set_text(layout: Ppango_layout_t; text: PChar; length: Integer); cdecl; external PangoLib;
  procedure pango_layout_set_width(layout: Ppango_layout_t; width: Integer); cdecl; external PangoLib;
  procedure pango_layout_set_wrap(layout: Ppango_layout_t; wrap: Integer); cdecl; external PangoLib;
  procedure pango_layout_xy_to_index(layout: Ppango_layout_t; x, y: Integer; index, trailing: PInteger); cdecl; external PangoLib;

implementation

end.
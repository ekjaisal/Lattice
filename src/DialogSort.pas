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

unit DialogSort;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Controls, ExtCtrls, Forms, StdCtrls;

type
  { TfrmDialogSort }
  TfrmDialogSort = class(TForm)
    btnCancel: TButton;
    btnPersist: TButton;
    btnReset: TButton;
    btnSort: TButton;
    cmbSortCriteria: TComboBox;
    lblCriteria: TLabel;
    pnlActions: TPanel;
    rgSortOrder: TRadioGroup;
    procedure btnPersistClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure cmbSortCriteriaChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure UpdateOrderLabels;
  public
    procedure InitializeOptions(AAttribute: TStrings; SelectedCriteria: String; IsDescending: Boolean; AllowPersist: Boolean; IsCodeMode: Boolean);
  end;

var
  frmDialogSort: TfrmDialogSort;

implementation

uses
  SysUtils, AppFont;

{$R *.lfm}

procedure TfrmDialogSort.FormShow(Sender: TObject);
begin
  ApplyAppFont(Self);
end;

procedure TfrmDialogSort.InitializeOptions(AAttribute: TStrings; SelectedCriteria: String; IsDescending: Boolean; AllowPersist: Boolean; IsCodeMode: Boolean);
var
  i: Integer;
  CurrentItemName: String;
  p: Integer;
begin
  btnPersist.Visible := AllowPersist;
  cmbSortCriteria.Items.BeginUpdate;
  try
    cmbSortCriteria.Items.Clear;
    if IsCodeMode then
    begin
      cmbSortCriteria.Items.Add('Code Name');
      cmbSortCriteria.Items.Add('Coding Count');
      cmbSortCriteria.Items.Add('Creation Time');
      cmbSortCriteria.ItemIndex := 0;
    end
    else
    begin
      cmbSortCriteria.Items.Add('Document Name');
      cmbSortCriteria.Items.Add('Coding Count');
      cmbSortCriteria.Items.Add('Segment Memo Count');
      cmbSortCriteria.Items.Add('Import Time');
      if Assigned(AAttribute) then
        for i := 0 to AAttribute.Count - 1 do
          cmbSortCriteria.Items.Add(AAttribute[i]);
      cmbSortCriteria.ItemIndex := 3;
    end;
    for i := 0 to cmbSortCriteria.Items.Count - 1 do
    begin
      p := Pos(' · ', cmbSortCriteria.Items[i]);
      if p > 0 then
        CurrentItemName := Copy(cmbSortCriteria.Items[i], 1, p - 1)
      else
        CurrentItemName := cmbSortCriteria.Items[i];
      if SameText(CurrentItemName, SelectedCriteria) then
      begin
        cmbSortCriteria.ItemIndex := i;
        Break;
      end;
    end;
  finally
    cmbSortCriteria.Items.EndUpdate;
  end;
  if IsDescending then
    rgSortOrder.ItemIndex := 1
  else
    rgSortOrder.ItemIndex := 0;
  UpdateOrderLabels;
end;

procedure TfrmDialogSort.UpdateOrderLabels;
var
  FullSpec: String;
begin
  FullSpec := cmbSortCriteria.Text;
  if (FullSpec = 'Coding Count') or (FullSpec = 'Segment Memo Count') or (Pos(' · Numeric', FullSpec) > 0) then
  begin
    rgSortOrder.Items[0] := 'Smallest to Largest';
    rgSortOrder.Items[1] := 'Largest to Smallest';
  end
  else if (FullSpec = 'Import Time') or (FullSpec = 'Creation Time') or (Pos(' · Date-Time', FullSpec) > 0) then
  begin
    rgSortOrder.Items[0] := 'Oldest to Newest';
    rgSortOrder.Items[1] := 'Newest to Oldest';
    if (FullSpec = 'Import Time') or (FullSpec = 'Creation Time') then
      rgSortOrder.Items[0] := rgSortOrder.Items[0] + ' (Default)';
  end
  else
  begin
    rgSortOrder.Items[0] := 'A to Z';
    rgSortOrder.Items[1] := 'Z to A';
  end;
end;

procedure TfrmDialogSort.cmbSortCriteriaChange(Sender: TObject);
begin
  UpdateOrderLabels;
end;

procedure TfrmDialogSort.btnPersistClick(Sender: TObject);
begin
  Tag := 888;
  ModalResult := mrOk;
end;

procedure TfrmDialogSort.btnResetClick(Sender: TObject);
begin
  cmbSortCriteria.ItemIndex := 3;
  rgSortOrder.ItemIndex := 0;
  Tag := 999;
  ModalResult := mrOK;
end;

end.

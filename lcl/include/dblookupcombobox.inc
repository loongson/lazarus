{%MainUnit ../dbctrls.pp}

{******************************************************************************
                                     TDBLookupComboBox
                    data aware lookup Combo Box, base found in dbctrls.pp
 ******************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}

// included by dbctrls.pp

{ TDBLookupComboBox }

constructor TDBLookupComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLookup := TDBLookup.Create(Self);
  EmptyValue := '';
  DisplayEmpty := '';
  FDataLink.OnActiveChange := @ActiveChange;
  inherited DropDownCount := 7;
end;

procedure TDBLookupComboBox.UpdateData(Sender: TObject);
var
  i: Integer;
begin
  // combo that has edit control may have unreliable itemindex like bug 20950
  if Style.HasEditBox then
    ItemIndex := Items.IndexOf(Text);
  i := ItemIndex;
  if i <> -1 then
    FLookup.UpdateData(i)
  else
  if FDatalink.EditingSource then
    FDatalink.Dataset.Cancel
  else
    UpdateLookup;
end;

procedure TDBLookupComboBox.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('DropDownCount', @ReadDropDownCount, nil, false);
end;

function TDBLookupComboBox.DoEdit: boolean;
begin
  if IsUnbound then begin
    if FDetectedEvents and DBCBEVENT_CHANGE <> 0 then
      DoOnChange;
    if DetectedEvents and DBCBEVENT_SELECT <>0 then begin
      FLookup.UpdateData(ItemIndex);
      DoOnSelect;
    end;
    if DetectedEvents and DBCBEVENT_CLOSEUP <>0 then
      DoOnCloseUp;
  end
  else
    Result := inherited DoEdit;
end;

procedure TDBLookupComboBox.DoAutoCompleteSelect;
begin
  if IsUnbound then
    FLookup.UpdateData(ItemIndex)
  else
    UpdateData(Self);
end;

function TDBLookupComboBox.IsUnbound: boolean;
begin
  result := (FDataLink.DataSource=nil) or (DataField='');
end;

procedure TDBLookupComboBox.ActiveChange(Sender: TObject);
begin
  if FDataLink.Active then
    UpdateLookup;
end;

function TDBLookupComboBox.GetDisplayEmpty: String;
begin
  Result := FLookup.DisplayEmpty;
end;

function TDBLookupComboBox.GetDropDownRows: Integer;
begin
  result := inherited DropDownCount;
end;

function TDBLookupComboBox.GetEmptyValue: String;
begin
 Result := FLookup.EmptyValue;
end;

procedure TDBLookupComboBox.DataChange(Sender: TObject);
begin
  UpdateItemIndex;
end;

procedure TDBLookupComboBox.DoOnSelect;
begin
  if not Style.HasEditBox then
    UpdateRecord;
  inherited DoOnSelect;
end;

procedure TDBLookupComboBox.DestroyWnd;
begin
  inherited;
  //after handle destroy Items address changes
  FLookup.ControlItems := Items;
end;

procedure TDBLookupComboBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if FLookup.HandleNullKey(Key, Shift) then
  begin
    //clear selection
    ItemIndex := -1;
    //Text := '';
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TDBLookupComboBox.UTF8KeyPress(var UTF8Key: TUTF8Char);
begin
  if (not IsUnbound) and (not FDataLink.CanModify) then
    UTF8Key := '';
  inherited UTF8KeyPress(UTF8Key);
end;

procedure TDBLookupComboBox.Loaded;
begin
  inherited Loaded;
  UpdateLookup;
end;

procedure TDBLookupComboBox.InitializeWnd;
begin
  inherited InitializeWnd;
  //after handle allocation Items address changes
  FLookup.ControlItems := Items;
end;

function TDBLookupComboBox.GetKeyField: string;
begin
  Result := FLookup.KeyField;
end;

function TDBLookupComboBox.GetKeyValue: variant;
begin
  result := FLookup.GetKeyValue(ItemIndex);
end;

function TDBLookupComboBox.GetListField: string;
begin
  Result := FLookup.ListField;
end;

function TDBLookupComboBox.GetListFieldIndex: Integer;
begin
  Result := FLookup.ListFieldIndex;
end;

function TDBLookupComboBox.GetListSource: TDataSource;
begin
  Result := FLookup.ListSource;
end;

function TDBLookupComboBox.GetLookupCache: boolean;
begin
  Result := FLookup.LookupCache;
end;

function TDBLookupComboBox.GetNullValueKey: TShortCut;
begin
  result := FLookup.NullValueKey;
end;

procedure TDBLookupComboBox.SetDisplayEmpty(AValue: String);
begin
  FLookup.DisplayEmpty:=AValue;
  UpdateLookup;
end;

procedure TDBLookupComboBox.SetDropDownRows(AValue: Integer);
begin
  inherited DropDownCount := AValue;
end;

procedure TDBLookupComboBox.SetEmptyValue(AValue: String);
begin
  FLookup.EmptyValue:=AValue;
  UpdateLookup;
end;

function TDBLookupComboBox.GetScrollListDataset: Boolean;
begin
  Result := FLookup.ScrollListDataset;
end;

procedure TDBLookupComboBox.ReadDropDownCount(Reader: TReader);
begin
  inherited DropDownCount := Reader.ReadInteger;
end;

procedure TDBLookupComboBox.SetKeyField(const Value: string);
begin
  FLookup.KeyField := Value;
  UpdateLookup;
end;

procedure TDBLookupComboBox.SetKeyValue(const AValue: variant);
begin
  ItemIndex := FLookup.GetKeyIndex(AValue);
end;

procedure TDBLookupComboBox.SetListField(const Value: string);
begin
  FLookup.ListField := Value;
  UpdateLookup;
end;

procedure TDBLookupComboBox.SetListFieldIndex(const Value: Integer);
begin
  FLookup.ListFieldIndex := Value;
  UpdateLookup;
end;

procedure TDBLookupComboBox.SetListSource(const Value: TDataSource);
begin
  FLookup.ListSource := Value;
  UpdateLookup;
end;

procedure TDBLookupComboBox.SetLookupCache(const Value: boolean);
begin
  FLookup.LookupCache := Value;
  UpdateLookup;
end;

procedure TDBLookupComboBox.SetNullValueKey(const AValue: TShortCut);
begin
  FLookup.NullValueKey := AValue;
end;

procedure TDBLookupComboBox.SetScrollListDataset(AValue: Boolean);
begin
  FLookup.ScrollListDataset := AValue;
end;

procedure TDBLookupComboBox.UpdateLookup;
begin
  if ([csLoading, csDestroying] * ComponentState) = [] then
  begin
    FLookup.Initialize(FDataLink, Items);
    UpdateItemIndex;
  end;
end;

procedure TDBLookupComboBox.UpdateItemIndex;
var
  i: Integer;
begin
  i := FLookup.GetKeyIndex;
  ItemIndex := i;
  if i = -1 then
    Text := '';
end;


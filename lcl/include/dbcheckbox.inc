{%MainUnit ../dbctrls.pp}
{
 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}

{ TDBCheckBox }

function TDBCheckBox.GetDataField: string;
begin
  Result:=FDataLink.FieldName;
end;

function TDBCheckBox.GetDataSource: TDataSource;
begin
  Result:=FDataLink.DataSource;
end;

function TDBCheckBox.GetField: TField;
begin
  Result:=FDataLink.Field;
end;

function TDBCheckBox.GetReadOnly: Boolean;
begin
  Result:=FDataLink.ReadOnly;
end;

procedure TDBCheckBox.SetDataField(const AValue: string);
begin
  FDataLink.FieldName:=AValue;
end;

procedure TDBCheckBox.SetDataSource(const AValue: TDataSource);
begin
  if AValue=DataSource then exit;
  if not (FDataLink.DataSourceFixed and (csLoading in ComponentState)) then
    ChangeDataSource(Self,FDataLink,AValue);
end;

procedure TDBCheckBox.SetReadOnly(const AValue: Boolean);
begin
  FDataLink.ReadOnly:=AValue;
end;

procedure TDBCheckBox.SetValueChecked(const AValue: string);
begin
  if FValueChecked=AValue then exit;
  FValueChecked:=AValue;
  DataChange(Self);
end;

procedure TDBCheckBox.SetValueUnchecked(const AValue: string);
begin
  if FValueUnchecked=AValue then exit;
  FValueUnchecked:=AValue;
  DataChange(Self);
end;

//check if Word is equal to S or is one of the ; delimitted words in s
//whitespace between Word and delimiter is ignored (Delphi behavior)
function FindWord(const Word, S: String): Boolean;
var
  I, J, L: Integer;
  C: Char;
begin
  I := Pos(Word, S);
  Result := I > 0;
  if Result then
  begin
    //forward
    J := I + Length(Word);
    L := Length(S);
    while Result and (J < L) do
    begin
      C := S[J];
      if C = ';' then
        Break;
      Result := C = ' ';
      Inc(J);
    end;
    //backward
    Dec(I);
    while Result and (I > 0) do
    begin
      C := S[I];
      if C = ';' then
        Break;
      Result := C = ' ';
      Dec(I);
    end;
  end;
end;

function TDBCheckBox.GetFieldCheckState: TCheckBoxState;
var
  FieldText: string;
  DataLinkField: TField;
begin
  DataLinkField := FDataLink.Field;
  if DatalinkField=nil then begin
    Result:=cbUnchecked;
    exit;
  end;
  if DataLinkField.IsNull then
    Result:=cbGrayed
  else if DataLinkField.DataType = ftBoolean then begin
    if DataLinkField.AsBoolean then
      Result:=cbChecked
    else
      Result:=cbUnchecked;
  end else begin
    FieldText:=UpperCase(DatalinkField.AsString);
    if FindWord(FieldText,UpperCase(FValueChecked)) then
      Result:=cbChecked
    else if FindWord(FieldText,UpperCase(FValueUnchecked)) then
      Result:=cbUnchecked
    else
      Result:=cbGrayed;
  end;
end;

procedure TDBCheckBox.DataChange(Sender: TObject);
begin
  // avoid DoOnChange circle #33573
  FDataLink.OnDataChange := nil;
  try
    State := GetFieldCheckState;
  finally
    FDataLink.OnDataChange := @DataChange;
  end;
end;

procedure TDBCheckBox.DoOnChange;
begin
  // avoid DoOnChange circle #33573
  if FDataLink.OnDataChange <> nil then
  try
    //avoid reseting value when state changes
    FDataLink.OnDataChange := nil;
    if FDatalink.Edit then begin
      FDatalink.Modified;
      FDataLink.UpdateRecord;
    end else
      State := GetFieldCheckState;
  finally
    FDataLink.OnDataChange := @DataChange;
  end;

  inherited DoOnChange;
end;

procedure TDBCheckBox.UpdateData(Sender: TObject);
var
  NewFieldText: string;
begin
  if State = cbGrayed then
    FDataLink.Field.Clear
  else
    if FDataLink.Field.DataType = ftBoolean then
      FDataLink.Field.AsBoolean:=Checked
    else begin
      if Checked then
        NewFieldText:=FValueChecked
      else
        NewFieldText:=FValueUnchecked;
      // ToDo: use Field.Text
      FDataLink.Field.AsString:=Trim(NewFieldText);
    end;
end;

procedure TDBCheckBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation=opRemove) then begin
    if (FDataLink<>nil) and (AComponent=DataSource) then
      DataSource:=nil;
  end;
end;

procedure TDBCheckBox.CMGetDataLink(var Message: TLMessage);
begin
  Message.Result := PtrUInt(FDataLink);
end;

function TDBCheckBox.NonDefaultValueChecked: Boolean;
begin
  Result := not AnsiSameText(FValueChecked, BoolToStr(True));
end;

function TDBCheckBox.NonDefaultValueUnchecked: Boolean;
begin
  Result := not AnsiSameText(FValueChecked, BoolToStr(False));
end;

constructor TDBCheckBox.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FValueChecked := BoolToStr(True);
  FValueUnchecked := BoolToStr(False);

  ControlStyle:=ControlStyle+[csReplicatable];
  State:=cbUnchecked;
  FDataLink:=TFieldDataLink.Create;
  FDataLink.Control:=Self;
  FDataLink.OnDataChange:=@DataChange;
  FDataLink.OnUpdateData:=@UpdateData;
end;

destructor TDBCheckBox.Destroy;
begin
  FDataLink.Destroy;
  inherited Destroy;
end;

function TDBCheckBox.ExecuteAction(AAction: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(AAction) or
            (FDataLink <> nil) and FDataLink.ExecuteAction(AAction);
end;

function TDBCheckBox.UpdateAction(AAction: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(AAction) or
            (FDataLink <> nil) and FDataLink.UpdateAction(AAction);
end;

// included by dbctrls.pp

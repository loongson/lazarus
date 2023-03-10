{%MainUnit customdrawnint.pas}
{
 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
//---------------------------------------------------------------

procedure TCDWidgetSet.AccumulatingDebugOut(ASender: TObject; AStr: string; var AHandled: Boolean;
  Target: TLazLoggerWriteTarget; Data: Pointer);
begin
  AHandled := Target in [lwtStdOut, lwtStdErr];
  if not AHandled then exit;
  AccumulatedStr := AccumulatedStr + AStr;
end;

procedure TCDWidgetSet.CDSetFocusToControl(ALCLControl, AIntfControl: TWinControl);
var
  lForm, OldFocusedControl: TWinControl;
begin
  {$ifdef VerboseCDForms}
  if FocusedControl <> nil then DebugLn('[TCDWidgetSet.CDSetFocusToControl] OldFocusedControl=%s:%s', [FocusedControl.Name, FocusedControl.ClassName]);
  if FocusedIntfControl <> nil then DebugLn('[TCDWidgetSet.CDSetFocusToControl] OldIntfFocusedControl=%s:%s', [FocusedIntfControl.Name, FocusedIntfControl.ClassName]);
  if ALCLControl <> nil then DebugLn('[TCDWidgetSet.CDSetFocusToControl] ALCLControl=%s:%s', [ALCLControl.Name, ALCLControl.ClassName]);
  if AIntfControl <> nil then DebugLn('[TCDWidgetSet.CDSetFocusToControl] AIntfControl=%s:%s', [AIntfControl.Name, AIntfControl.ClassName]);
  {$endif}
  OldFocusedControl := FocusedControl;
  if ALCLControl = nil then Exit;
  lForm := GetParentForm(ALCLControl);
  if (FocusedControl <> ALCLControl) then
  begin
    // First kill focus in the previous control
    if FocusedControl <> nil then
      LCLSendKillFocusMsg(FocusedControl);
    FocusedControl := ALCLControl;
    LCLSendSetFocusMsg(ALCLControl);

    // The same for intf controls
    if FocusedIntfControl <> nil then
      LCLSendKillFocusMsg(FocusedIntfControl);
    FocusedIntfControl := AIntfControl;
    if AIntfControl <> nil then LCLSendSetFocusMsg(AIntfControl);

    // Also mark in the window information the focus change
    TCDForm(lForm.Handle).FocusedControl := ALCLControl;
    TCDForm(lForm.Handle).FocusedIntfControl := FocusedIntfControl;

    // Verify if the virtual keyboard needs to be shown/hidden
    // Only show if there is no hardware keyboard, but hide always in case
    // the user flopped the keyboard in the mean time
    if OldFocusedControl <> nil then
    begin
      if (csRequiresKeyboardInput in OldFocusedControl.ControlStyle)
       and (not (csRequiresKeyboardInput in ALCLControl.ControlStyle)) then
       HideVirtualKeyboard();

      if (not (csRequiresKeyboardInput in OldFocusedControl.ControlStyle))
       and (csRequiresKeyboardInput in ALCLControl.ControlStyle) then
       ShowVirtualKeyboard();
    end
    else if csRequiresKeyboardInput in ALCLControl.ControlStyle then
      ShowVirtualKeyboard();

    // Invalidate the entire window to reflect the focus change
    LCLIntf.InvalidateRect(lForm.Handle, nil, False);
  end;
end;

function TCDWidgetSet.CreateThemeServices: TThemeServices;
begin
  Result := TCDThemeServices.Create;
end;

procedure TCDWidgetSet.GenericAppInit;
begin
  {$ifndef CD_UseNativeText}
  // if it's the first time, we must create the list
  if FFontPaths.Count = 0 then BackendListFontPaths(FFontPaths, FFontList);
  {$endif}

  // Init stock objects
  FStockBlackBrush := TFPCustomBrush.Create;
  FStockBlackBrush.FPColor := colBlack;
  FStockDKGrayBrush := TFPCustomBrush.Create;
  FStockDKGrayBrush.FPColor := colDkGray;
  FStockGrayBrush := TFPCustomBrush.Create;
  FStockGrayBrush.FPColor := colGray;
  FStockLtGrayBrush := TFPCustomBrush.Create;
  FStockLtGrayBrush.FPColor := colLtGray;
  FStockNullBrush := TFPCustomBrush.Create;
  FStockNullBrush.Style := bsClear;
  FStockWhiteBrush := TFPCustomBrush.Create;
  FStockWhiteBrush.FPColor := colWhite;

  FStockBlackPen := TFPCustomPen.Create;
  FStockBlackPen.FPColor := colBlack;
  FStockNullPen := TFPCustomPen.Create;
  FStockNullPen.Style := psClear;
  FStockWhitePen := TFPCustomPen.Create;
  FStockWhitePen.FPColor := colWhite;

  FDefaultGUIFont := TFPCustomFont.Create;
end;

{------------------------------------------------------------------------------
  Method: TCDWidgetSet.Create
  Params:  None
  Returns: Nothing

  Constructor for the class.
 ------------------------------------------------------------------------------}
constructor TCDWidgetSet.Create;
begin
  inherited Create;

  CDWidgetSet := Self;
  FTerminating := False;
  DefaultFontSize := 10;

  ActivityClassName := 'com/pascal/lcltest/LCLActivity';

  FClipBoardFormats := TStringList.Create;
  FClipBoardFormats.Add('foo'); // 0 is reserved
  FClipBoardFormats.Add('text/plain'); // 1 - text/plain should always be supported

  // To be resistent against backend issues
  CDWidgetset.ScreenFormat := clfARGB32;

  {$ifndef CD_UseNativeText}
  FFontPaths:= TStringList.Create;
  FFontList := THashedStringList.Create;
  FFontList.CaseSensitive:= False;
  TT_Init_FreeType;
  {$endif}

  BackendCreate;
end;

{------------------------------------------------------------------------------
  Method: TQtWidgetSet.Destroy
  Params:  None
  Returns: Nothing

  Destructor for the class.
 ------------------------------------------------------------------------------}
destructor TCDWidgetSet.Destroy;
begin
  BackendDestroy;

  {$ifndef CD_UseNativeText}
  //TT_Done_FreeType; Causes crashes =( Uncomment when bug 21470 is fixed
  FFontPaths.Free;
  FFontList.Free;
  {$endif}

  FClipBoardFormats.Free;

  CDWidgetSet := nil;
  inherited Destroy;
end;

function TCDWidgetSet.LCLPlatform: TLCLPlatform;
begin
  Result:= lpCustomDrawn;
end;

function TCDWidgetSet.GetLCLCapability(ACapability: TLCLCapability): PtrUInt;
begin
  case ACapability of
    lcCanDrawOutsideOnPaint: Result := LCL_CAPABILITY_NO;
    {$ifdef CD_Cocoa}
    lcNeedMininimizeAppWithMainForm,
    lcApplicationTitle,
    lcFormIcon:
      Result := LCL_CAPABILITY_NO;
    {$endif}
    lcReceivesLMClearCutCopyPasteReliably: Result := LCL_CAPABILITY_NO;
    lcAntialiasingEnabledByDefault: Result := LCL_CAPABILITY_NO;
    lcAllowChildControlsInNativeControls: Result := LCL_CAPABILITY_YES
  else
    Result := inherited GetLCLCapability(ACapability);
  end;
end;

function TCDWidgetSet.DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor;
var
  LazCanvas: TLazCanvas;
begin
  Result := clNone;

  if not IsValidDC(CanvasHandle) then Exit;
  LazCanvas := TLazCanvas(CanvasHandle);
  
  Result := FPColorToTColor(LazCanvas.Colors[X, Y]);
end;

procedure TCDWidgetSet.DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor);
var
  LazCanvas: TLazCanvas;
begin
  if not IsValidDC(CanvasHandle) then Exit;
  LazCanvas := TLazCanvas(CanvasHandle);

  LazCanvas.Colors[X, Y] := TColorToFPColor(AColor);
end;

procedure TCDWidgetSet.DCRedraw(CanvasHandle: HDC);
begin
  // TODO: implement me
end;

procedure TCDWidgetSet.DCSetAntialiasing(CanvasHandle: HDC; AEnabled: Boolean);
{var
  DC: TQtDeviceContext;}
begin
{  if IsValidDC(CanvasHandle) then
  begin
    if CanvasHandle = 1 then
      DC := QtDefaultContext
    else
      DC := TQtDeviceContext(CanvasHandle);
    DC.setRenderHint(QPainterAntialiasing, AEnabled);
  end;}
end;

procedure TCDWidgetSet.SetDesigning(AComponent: TComponent);
begin

end;

function CDMessageBoxFunction(Text, Caption : PChar; Flags : Longint) : Integer;
begin
  Result := CDWidgetset.MessageBox(0, Text, Caption, Flags);
end;

//------------------------------------------------------------------------

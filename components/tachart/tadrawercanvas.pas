{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

Authors: Alexander Klenin

}

unit TADrawerCanvas;

{$H+}

interface

uses
  Classes, FPCanvas, FPImage, Graphics, SysUtils, TAChartUtils, TADrawUtils;

type
  IChartTCanvasDrawer = interface
  ['{6D8E5591-6788-4D2D-9FE6-596D5157C3C2}']
    function GetCanvas: TCanvas;
    property Canvas: TCanvas read GetCanvas;
  end;

  { TCanvasDrawer }

  TCanvasDrawer = class(
    TBasicDrawer, IChartDrawer, IChartTCanvasDrawer)
  strict private
    procedure SetBrush(ABrush: TFPCustomBrush);
    procedure SetFont(AFont: TFPCustomFont);
    procedure SetPen(APen: TFPCustomPen);
  strict protected
    FCanvas: TCanvas;
    function GetFontAngle: Double; override;
    function SimpleTextExtent(const AText: String): TPoint; override;
    procedure SimpleTextOut(AX, AY: Integer; const AText: String); override;
  public
    procedure AddToFontOrientation(ADelta: Integer);
    procedure ClippingStart;
    procedure ClippingStart(const AClipRect: TRect);
    procedure ClippingStop;
    constructor Create(ACanvas: TCanvas);
    procedure Ellipse(AX1, AY1, AX2, AY2: Integer);
    procedure FillRect(AX1, AY1, AX2, AY2: Integer);
    function GetBrushColor: TChartColor;
    function GetCanvas: TCanvas;
    procedure Line(AX1, AY1, AX2, AY2: Integer);
    procedure Line(const AP1, AP2: TPoint);
    procedure LineTo(AX, AY: Integer); override;
    procedure MoveTo(AX, AY: Integer); override;
    procedure Polygon(
      const APoints: array of TPoint; AStartIndex, ANumPts: Integer); override;
    procedure Polyline(
      const APoints: array of TPoint; AStartIndex, ANumPts: Integer);
    procedure PrepareSimplePen(AColor: TChartColor);
    procedure RadialPie(
      AX1, AY1, AX2, AY2: Integer;
      AStartAngle16Deg, AAngleLength16Deg: Integer);
    procedure Rectangle(const ARect: TRect);
    procedure Rectangle(AX1, AY1, AX2, AY2: Integer);
    procedure SetAntialiasingMode(AValue: TChartAntialiasingMode);
    procedure SetBrushColor(AColor: TChartColor);
    procedure SetBrushParams(AStyle: TFPBrushStyle; AColor: TChartColor);
    procedure SetPenParams(AStyle: TFPPenStyle; AColor: TChartColor);
  end;

  function CanvasGetFontOrientationFunc(AFont: TFPCustomFont): Integer;
  function ChartColorSysToFPColor(AChartColor: TChartColor): TFPColor;

implementation

uses
  LCLIntf, LCLType,
  TAGeometry;

function CanvasGetFontOrientationFunc(AFont: TFPCustomFont): Integer;
begin
  if AFont is TFont then
    Result := (AFont as TFont).Orientation
  else
    Result := 0;
end;

function ChartColorSysToFPColor(AChartColor: TChartColor): TFPColor;
begin
  Result := ChartColorToFPColor(ColorToRGB(AChartColor));
end;

{ TCanvasDrawer }

procedure TCanvasDrawer.AddToFontOrientation(ADelta: Integer);
begin
  with FCanvas.Font do
    Orientation := Orientation + ADelta;
end;

procedure TCanvasDrawer.ClippingStart(const AClipRect: TRect);
begin
  FCanvas.ClipRect := AClipRect;
  FCanvas.Clipping := true;
end;

procedure TCanvasDrawer.ClippingStart;
begin
  FCanvas.Clipping := true;
end;

procedure TCanvasDrawer.ClippingStop;
begin
  FCanvas.Clipping := false;
end;

constructor TCanvasDrawer.Create(ACanvas: TCanvas);
begin
  FCanvas := ACanvas;
end;

procedure TCanvasDrawer.Ellipse(AX1, AY1, AX2, AY2: Integer);
begin
  FCanvas.Ellipse(AX1, AY1, AX2, AY2);
end;

procedure TCanvasDrawer.FillRect(AX1, AY1, AX2, AY2: Integer);
begin
  FCanvas.FillRect(AX1, AY1, AX2, AY2);
end;

function TCanvasDrawer.GetBrushColor: TChartColor;
begin
  Result := FCanvas.Brush.Color;
end;

function TCanvasDrawer.GetCanvas: TCanvas;
begin
  Result := FCanvas;
end;

function TCanvasDrawer.GetFontAngle: Double;
begin
  Result := OrientToRad(FCanvas.Font.Orientation);
end;

procedure TCanvasDrawer.Line(AX1, AY1, AX2, AY2: Integer);
begin
  FCanvas.Line(AX1, AY1, AX2, AY2);
end;

procedure TCanvasDrawer.Line(const AP1, AP2: TPoint);
begin
  FCanvas.Line(AP1, AP2);
end;

procedure TCanvasDrawer.LineTo(AX, AY: Integer);
begin
  FCanvas.LineTo(AX, AY);
end;

procedure TCanvasDrawer.MoveTo(AX, AY: Integer);
begin
  FCanvas.MoveTo(AX, AY);
end;

procedure TCanvasDrawer.Polygon(
  const APoints: array of TPoint; AStartIndex, ANumPts: Integer);
begin
  FCanvas.Polygon(APoints, false, AStartIndex, ANumPts);
end;

procedure TCanvasDrawer.Polyline(
  const APoints: array of TPoint; AStartIndex, ANumPts: Integer);
begin
  if ANumPts <= 0 then exit;
  FCanvas.Polyline(APoints, AStartIndex, ANumPts);
  // TCanvas.Polyline does not draw the end point.
  with APoints[AStartIndex + ANumPts - 1] do
    FCanvas.Pixels[X, Y] := FCanvas.Pen.Color;
end;

procedure TCanvasDrawer.PrepareSimplePen(AColor: TChartColor);
begin
  with FCanvas.Pen do begin
    if FXor then
      Color := clWhite
    else
      Color := AColor;
    Style := psSolid;
    if FXor then
      Mode := pmXor
    else
      Mode := pmCopy;
    Width := 1;
  end;
end;

procedure TCanvasDrawer.RadialPie(
  AX1, AY1, AX2, AY2: Integer;
  AStartAngle16Deg, AAngleLength16Deg: Integer);
begin
  FCanvas.RadialPie(
    AX1, AY1, AX2, AY2, AStartAngle16Deg, AAngleLength16Deg);
end;

procedure TCanvasDrawer.Rectangle(AX1, AY1, AX2, AY2: Integer);
begin
  FCanvas.Rectangle(AX1, AY1, AX2, AY2);
end;

procedure TCanvasDrawer.Rectangle(const ARect: TRect);
begin
  FCanvas.Rectangle(ARect);
end;

procedure TCanvasDrawer.SetAntialiasingMode(AValue: TChartAntialiasingMode);
begin
  FCanvas.AntialiasingMode := TAntialiasingMode(AValue);
end;

procedure TCanvasDrawer.SetBrush(ABrush: TFPCustomBrush);
begin
  FCanvas.Brush.Assign(ABrush);
  if FXor then
    FCanvas.Brush.Style := bsClear;
end;

procedure TCanvasDrawer.SetBrushColor(AColor: TChartColor);
begin
  FCanvas.Brush.Color := AColor;
end;

procedure TCanvasDrawer.SetBrushParams(
  AStyle: TFPBrushStyle; AColor: TChartColor);
begin
  FCanvas.Brush.Color := AColor;
  FCanvas.Brush.Style := AStyle;
end;

procedure TCanvasDrawer.SetFont(AFont: TFPCustomFont);
begin
  FCanvas.Font.Assign(AFont);
end;

procedure TCanvasDrawer.SetPen(APen: TFPCustomPen);
begin
  if FXor then
    with FCanvas do begin
      Brush.Style := bsClear;
      if APen = nil then
        Pen.Style := psSolid
      else
        Pen.Style := APen.Style;
      Pen.Mode := pmXor;
      Pen.Color := clWhite;
      if APen = nil then
        Pen.Width := 1
      else
        Pen.Width := APen.Width;
    end
  else
    FCanvas.Pen.Assign(APen);
end;

procedure TCanvasDrawer.SetPenParams(AStyle: TFPPenStyle; AColor: TChartColor);
begin
  FCanvas.Pen.Style := AStyle;
  if not FXor then
    FCanvas.Pen.Color := AColor;
end;

function TCanvasDrawer.SimpleTextExtent(const AText: String): TPoint;
begin
  Result := FCanvas.TextExtent(AText);
end;

procedure TCanvasDrawer.SimpleTextOut(AX, AY: Integer; const AText: String);

  procedure DrawXorText;
  var
    bmp: TBitmap;
    p, ext, bmpSize: TPoint;
    a: Double;
  begin
    ext := FCanvas.TextExtent(AText);
    a := OrientToRad(FCanvas.Font.Orientation);
    bmpSize := MeasureRotatedRect(ext, a);
    p := bmpSize div 2 - RotatePoint(ext div 2, -a);

    bmp := TBitmap.Create;
    try
      bmp.SetSize(bmpSize.X, bmpSize.Y);
      bmp.Canvas.Brush.Style := bsClear;
      bmp.Canvas.Font := FCanvas.Font;
      bmp.Canvas.Font.Color := clWhite;
      bmp.Canvas.TextOut(p.X, p.Y, AText);
      bmp.Canvas.Pen.Color := clWhite;
      BitBlt(
        FCanvas.Handle, AX - p.X, AY - p.Y, bmpSize.X, bmpSize.Y,
        bmp.Canvas.Handle, 0, 0, SRCINVERT);
    finally
      bmp.Free;
    end;
  end;

begin
  if FXor then
    DrawXorText
  else
    FCanvas.TextOut(AX, AY, AText);
end;

initialization
  // Suppress incorrect "TAGeometry is unused" hint
  Unused(DoublePoint(0, 0));

end.


{
 *****************************************************************************
 *                              QtWidgets.pas                                *
 *                              --------------                               *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit qtwidgets;

{$mode objfpc}{$H+}

interface

{$I qtdefines.inc}

uses
  // Bindings
  qt4,
  qtobjects, qtint,
  // Free Pascal
  Classes, SysUtils, Types, Math,
  // LCL
  LCLType, LCLProc, LCLIntf, LMessages, Graphics, Forms, Controls,
  ComCtrls, ExtCtrls, StdCtrls, Menus, Dialogs;

type
  // forward declarations
  TQtListWidget = class;
  TQtViewPort = class;

  TByteSet = set of byte;

  {Used to know if our widget is part of some complex widget.
   Only for TQtWidgets created by CreateFrom & attach it's events.
   For now only combobox added for it's lineedit but not for droplist
   which doesn't attach it's event filter.
   We'll need it later for TQtScrollBar and probably TQtTabWidget}
  TChildOfComplexWidget = (ccwNone,
                          ccwComboBox,
                          ccwTreeWidget,
                          ccwAbstractScrollArea,
                          ccwScrollingWinControl,
                          ccwTabWidget);

  TQtGroupBoxType = (tgbtNormal,
                   tgbtCheckGroup,
                   tgbtRadioGroup);
  // records
  TPaintData = record
    PaintWidget: QWidgetH;
    ClipRect: Prect;
    ClipRegion: QRegionH;
  end;
  
  // interfaces

  { IQtTextEdit }

  { IQtEdit }

  IQtEdit = interface
    ['{035CA259-4442-4E82-9E70-96A114DD3BC6}']
    function getCursorPosition: Integer;
    function getMaxLength: Integer;
    function getSelectionStart: Integer;
    function getSelectionLength: Integer;
    function isUndoAvailable: Boolean;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setMaxLength(const ALength: Integer);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure setBorder(const ABorder: Boolean);
    procedure setCursorPosition(const ACursorPosition: Integer);
    procedure Cut;
    procedure Copy;
    procedure Paste;
    procedure Undo;
  end;

  // classes
  
  { TQtWidget }

  TQtWidget = class(TQtObject, IUnknown)
  private
    FChildOfComplexWidget: TChildOfComplexWidget;
    FOwnWidget: Boolean;
    FProps: TStringList;
    FPaintData: TPaintData;
    FCentralWidget: QWidgetH;
    FContext: HDC;
    FParams: TCreateParams;
    FDefaultCursor: QCursorH;
    FKeysToEat: TByteSet;
    FText: WideString;
    FHasCaret: Boolean;
    FLastCaretPos: TQtPoint;
    FHasPaint: Boolean;
    FOwner: TQtWidget;

    FWidgetColorRole: QPaletteColorRole;
    FTextColorRole: QPaletteColorRole;
    FPalette: TQtWidgetPalette;

    {TQtWidget.scroll() info}
    FScrollX: Integer;
    FScrollY: Integer;

    function GetPalette: TQtWidgetPalette;
    function GetProps(const AnIndex: String): pointer;
    function GetStyleSheet: WideString;
    function GetWidget: QWidgetH;
    function LCLKeyToQtKey(AKey: Word): Integer;
    function QtButtonsToLCLButtons(AButtons: QtMouseButton): PtrInt;
    function QtKeyModifiersToKeyState(AModifiers: QtKeyboardModifiers): PtrInt;
    function QtKeyToLCLKey(AKey: Integer; AText: WideString): Word;
    procedure SetLastCaretPos(const AValue: TQtPoint);
    procedure SetProps(const AnIndex: String; const AValue: pointer);
    procedure SetStyleSheet(const AValue: WideString);
    procedure SetWidget(const AValue: QWidgetH);
    function ShiftStateToQtModifiers(Shift: TShiftState): QtModifier;
  protected
    // IUnknown implementation
    {$IFDEF FPC_HAS_CONSTREF}
      function QueryInterface(constref iid: TGuid; out obj): LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
      function _AddRef: LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
      function _Release: LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    {$ELSE}
      function QueryInterface(const iid : tguid;out obj) : longint;stdcall;
      function _AddRef : longint;stdcall;
      function _Release : longint;stdcall;
    {$ENDIF}
    function GetContext: HDC; virtual;
    function CreateWidget(const Params: TCreateParams):QWidgetH; virtual;
    procedure DestroyWidget; virtual;
    procedure SetHasCaret(const AValue: Boolean);
    
    class procedure removeProperty(AObject: QObjectH; APropName: PAnsiChar);
    class procedure setProperty(AObject: QObjectH; APropName: PAnsiChar; APropValue: Int64);
  public
    LCLObject: TWinControl;
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); virtual; overload;
    constructor CreateFrom(const AWinControl: TWinControl; AWidget: QWidgetH); virtual;
    procedure InitializeWidget; virtual;
    procedure DeInitializeWidget;
    procedure RecreateWidget;
    procedure DestroyNotify(AWidget: TQtWidget); virtual;
    
    destructor Destroy; override;
    function GetContainerWidget: QWidgetH; virtual;
    procedure Release; override;
    procedure Destroyed; cdecl; override;
  public
    function CanSendLCLMessage: Boolean;
    function CanPaintBackground: Boolean; virtual;
    function DeliverMessage(var Msg): LRESULT; virtual;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    function getAcceptDropFiles: Boolean; virtual;
    procedure SetNoMousePropagation(Sender: QWidgetH; const ANoMousePropagation: Boolean); virtual;
    procedure SlotShow(vShow: Boolean); cdecl;
    function SlotClose: Boolean; cdecl; virtual;
    procedure SlotDestroy; cdecl;
    function slotDropFiles(Sender: QObjectH; Event: QEventH): Boolean;
    function SlotHover(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function SlotKey(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function SlotMouse(Sender: QObjectH; Event: QEventH): Boolean; virtual; cdecl;
    procedure SlotNCMouse(Sender: QObjectH; Event: QEventH); cdecl;
    function SlotMouseEnter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function SlotMouseMove(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    procedure SlotMouseWheel(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotMove(Event: QEventH); cdecl;
    procedure SlotPaintBg(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotPaint(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotResize(Event: QEventH); cdecl;
    function SlotContextMenu(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    procedure SlotWhatsThis(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotLCLMessage(Sender: QObjectH; Event: QEventH); cdecl;
  public
    procedure Activate; virtual;
    procedure BringToFront;
    procedure clearMask;
    procedure OffsetMousePos(APoint: PQtPoint); virtual;
    procedure Update(ARect: PRect = nil); virtual;
    procedure Repaint(ARect: PRect = nil); virtual;
    procedure setWindowTitle(Str: PWideString);
    procedure WindowTitle(Str: PWideString);
    procedure Hide;
    procedure Show;
    procedure ShowNormal;
    procedure ShowMinimized;
    procedure ShowMaximized;
    function getActionByIndex(AIndex: Integer): QActionH;
    function getAutoFillBackground: Boolean;
    function getClientBounds: TRect; virtual;
    function getClientOffset: TPoint; virtual;
    function getEnabled: Boolean;
    function getFont: QFontH;
    function getFocusPolicy: QtFocusPolicy;
    function getFrameGeometry: TRect;
    function getGeometry: TRect; virtual;
    function getLayoutDirection: QtLayoutDirection;
    function getVisible: Boolean; virtual;
    function getVisibleTo(AWidget: QWidgetH): Boolean; virtual;
    function getOwner: TQtWidget;
    function getParent: QWidgetH;
    function getPos: TQtPoint;
    function getFrameSize: TSize;
    function getSize: TSize;
    function getText: WideString; virtual;
    function getTextStatic: Boolean; virtual;
    function getHeight: Integer;
    function getUpdatesEnabled: Boolean;
    function getWidth: Integer;
    function getWindow: TQtWidget;
    function getWindowState: QtWindowStates;
    procedure grabMouse; virtual;
    function hasFocus: Boolean; virtual;
    function IsActiveWindow: Boolean;
    function isMinimized: Boolean;
    function isMaximized: Boolean;
    function IsWindow: Boolean;
    procedure lowerWidget; virtual;
    procedure move(ANewLeft, ANewTop: Integer); virtual;
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); virtual;
    procedure raiseWidget; virtual;
    procedure stackUnder(AWidget: QWidgetH); virtual;
    procedure frame_resize(ANewWidth, ANewHeight: Integer);
    procedure resize(ANewWidth, ANewHeight: Integer); virtual;
    procedure releaseMouse;
    procedure scroll(dx, dy: integer; ARect: PRect = nil); virtual;
    procedure setAutoFillBackground(const AValue: Boolean);
    procedure setAttribute(const Attr: QtWidgetAttribute; const TurnOn: Boolean = True);
    procedure setBackgroundRole(const ARole: QPaletteColorRole);
    procedure setDefaultColor(const DefaultColorType: TDefaultColorType);
    procedure setColor(const Value: PQColor); virtual;
    function getContextMenuPolicy: QtContextMenuPolicy; virtual;
    procedure setContextMenuPolicy(const AValue: QtContextMenuPolicy); virtual;
    procedure setCursor(const ACursor: QCursorH); virtual;
    procedure setDefaultColorRoles; virtual;
    procedure setEnabled(p1: Boolean);
    procedure setFocus;
    procedure setFocusPolicy(const APolicy: QtFocusPolicy); virtual;
    procedure setFocusProxy(const AWidget: QWidgetH);
    procedure setFont(AFont: QFontH);
    procedure setGeometry(ARect: TRect); virtual;
    procedure setLayoutDirection(ADirection: QtLayoutDirection);
    procedure setMaximumSize(AWidth, AHeight: Integer);
    procedure setMask(AMask: QBitmapH); overload;
    procedure setMask(AMask: QRegionH); overload;
    procedure setMinimumSize(AWidth, AHeight: Integer);
    procedure setParent(parent: QWidgetH); virtual;
    procedure setText(const W: WideString); virtual;
    procedure setTextColor(const Value: PQColor); virtual;
    procedure setVisible(AVisible: Boolean); virtual;
    procedure setWindowFlags(_type: QtWindowFlags);
    procedure setWindowIcon(AIcon: QIconH);
    procedure setWindowModality(windowModality: QtWindowModality);
    procedure setWindowOpacity(opacity: double);
    procedure setWidth(p1: Integer);
    procedure setHeight(p1: Integer);
    procedure setUpdatesEnabled(const AEnabled: Boolean);
    procedure setWindowState(AState: QtWindowStates);
    procedure sizeHint(size: PSize);
    function windowFlags: QtWindowFlags;
    function windowModality: QtWindowModality;
    property ChildOfComplexWidget: TChildOfComplexWidget read FChildOfComplexWidget write FChildOfComplexWidget;
    property Context: HDC read GetContext;
    property HasCaret: Boolean read FHasCaret write SetHasCaret;
    property HasPaint: Boolean read FHasPaint write FHasPaint;
    property KeysToEat: TByteSet read FKeysToEat write FKeysToEat;
    property LastCaretPos: TQtPoint read FLastCaretPos write SetLastCaretPos;
    property StyleSheet: WideString read GetStyleSheet write SetStyleSheet;
    property PaintData: TPaintData read FPaintData write FPaintData;
    property Palette: TQtWidgetPalette read GetPalette;
    property Props[AnIndex:String]:pointer read GetProps write SetProps;
    property TextColorRole: QPaletteColorRole read FTextColorRole write FTextColorRole;
    property Widget: QWidgetH read GetWidget write SetWidget;
    property WidgetColorRole: QPaletteColorRole read FWidgetColorRole write FWidgetColorRole;
  end;

  { TQtAbstractSlider , inherited by TQtScrollBar, TQtTrackBar }

  TQtAbstractSlider = class(TQtWidget)
  private
    FSliderPressed: Boolean;
    FSliderReleased: Boolean;
    FRangeChangedHook: QAbstractSlider_hookH;
    FSliderMovedHook:  QAbstractSlider_hookH;
    FSliderPressedHook: QAbstractSlider_hookH;
    FSliderReleasedHook: QAbstractSlider_hookH;
    FValueChangedHook: QAbstractSlider_hookH;
    FActionTriggeredHook: QAbstractSlider_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure SlotSliderMoved(p1: Integer); cdecl; virtual;
    procedure SlotValueChanged(p1: Integer); cdecl; virtual;
    procedure SlotActionTriggered(action: Integer); cdecl; virtual;
    procedure SlotRangeChanged(minimum: Integer; maximum: Integer); cdecl; virtual;
    procedure SlotSliderPressed; cdecl;
    procedure SlotSliderReleased; cdecl; virtual;
  public
    function getInvertedAppereance: Boolean;
    function getInvertedControls: Boolean;
    function getOrientation: QtOrientation;
    function getValue: Integer;
    function getPageStep: Integer;
    function getMin: Integer;
    function getMax: Integer;
    function getSingleStep: Integer;
    function getSliderDown: Boolean;
    function getSliderPosition: Integer;
    function getTracking: Boolean;

    procedure setInvertedAppereance(p1: Boolean); virtual;
    procedure setInvertedControls(p1: Boolean); virtual;

    procedure setMaximum(p1: Integer); virtual;
    procedure setMinimum(p1: Integer); virtual;

    procedure setOrientation(p1: QtOrientation); virtual;
    procedure setPageStep(p1: Integer); virtual;
    procedure setRange(minimum: Integer; maximum: Integer); virtual;
    procedure setSingleStep(p1: Integer); virtual;
    procedure setSliderDown(p1: Boolean); virtual;
    procedure setSliderPosition(p1: Integer); virtual;
    procedure setTracking(p1: Boolean); virtual;
    procedure setValue(p1: Integer); virtual;
    property SliderPressed: Boolean read FSliderPressed;
    property SliderReleased: Boolean read FSliderReleased;
  end;

  { TQtScrollBar }

  TQtScrollBar = class(TQtAbstractSlider)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
    procedure setFocusPolicy(const APolicy: QtFocusPolicy); override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure AttachEvents; override;
  end;

  { TQtFrame }

  TQtFrame = class(TQtWidget)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure setFocusPolicy(const APolicy: QtFocusPolicy); override;
    procedure setFrameStyle(p1: Integer);
    procedure setFrameShape(p1: QFrameShape);
    procedure setFrameShadow(p1: QFrameShadow);
  end;

  { TQtAbstractScrollArea }

  TQtAbstractScrollArea = class(TQtFrame)
  private
    function getScrollBarsPolicy(AIndex: Boolean): QtScrollBarPolicy;
    procedure setScrollBarPolicy(AIndex: Boolean;
      const AValue: QtScrollBarPolicy);
  protected
    FHScrollbar: TQtScrollBar;
    FVScrollbar: TQtScrollbar;
  public
    procedure grabMouse; override;
    function GetContainerWidget: QWidgetH; override;
    function getClientOffset: TPoint; override;
    function getClientBounds: TRect; override;
    function getViewOrigin: TPoint;
    function viewportWidget: QWidgetH;
    function horizontalScrollBar: TQtScrollBar;
    function verticalScrollBar: TQtScrollBar;
    procedure setFocusPolicy(const APolicy: QtFocusPolicy); override;
    procedure setHorizontalScrollBar(AScrollBar: TQtScrollBar);
    procedure setVerticalScrollBar(AScrollBar: TQtScrollBar);
    procedure setScrollStyle(AScrollStyle: TScrollStyle);
    procedure SetNoMousePropagation(Sender: QWidgetH; const ANoMousePropagation: Boolean); override;
    procedure DestroyNotify(AWidget: TQtWidget); override;
    destructor Destroy; override;
    procedure Update(ARect: PRect = nil); override;
    procedure Repaint(ARect: PRect = nil); override;
    property ScrollBarPolicy[AIndex: Boolean]: QtScrollBarPolicy read getScrollBarsPolicy write setScrollBarPolicy;
  end;

  { TQtCustomControl }

  TQtCustomControl = class(TQtAbstractScrollArea)
  private
    FCornerWidget: TQtWidget;
    FViewPortWidget: TQtViewPort;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure ViewPortEventFilter(event: QEventH; retval: PBoolean); cdecl;

    procedure DestroyNotify(AWidget: TQtWidget); override;
  public
    function cornerWidget: TQtWidget;
    function viewport: TQtViewPort;
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
    procedure setCornerWidget(AWidget: TQtWidget);
    procedure setCursor(const ACursor: QCursorH); override;
    procedure setViewport(const AViewPort: QWidgetH);
    procedure setVisible(AVisible: Boolean); override;
    procedure viewportNeeded; virtual;
    procedure viewportDelete; virtual;
  end;
  
  { TQtViewPort }
  
  TQtViewPort = class(TQtWidget)
  public
    function CanPaintBackground: Boolean; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure scroll(dx, dy: integer; ARect: PRect = nil); override;
    procedure stackUnder(AWidget: QWidgetH); override;
  end;
  
  { TQtGraphicView }

  TQtGraphicsView = class(TQtAbstractScrollArea)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;

  { TQtArrow }

  TQtArrow = class(TQtFrame)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    ArrowType: Integer;
  end;

  { TQtAbstractButton }

  TQtAbstractButton = class(TQtWidget)
  public
    function CanPaintBackground: Boolean; override;
    function getIconSize: TSize;
    function getText: WideString; override;
    procedure setIcon(AIcon: QIconH);
    procedure setIconSize(Size: PSize);
    procedure setShortcut(AShortcut: TShortcut);
    procedure setText(const W: WideString); override;
    procedure Toggle;
    function isChecked: Boolean;
    function isDown: Boolean;
    procedure setCheckable(p1: Boolean);
    procedure setChecked(p1: Boolean);
    procedure setDefaultColorRoles; override;
    procedure setDown(p1: Boolean);
    procedure SignalPressed; cdecl;
    procedure SignalReleased; cdecl;
    procedure SignalClicked(Checked: Boolean = False); cdecl;
    procedure SignalClicked2; cdecl;
  end;

  { TQtPushButton }

  TQtPushButton = class(TQtAbstractButton)
  private
    FClickedHook: QAbstractButton_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
  public
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
  public
    procedure SetDefault(const ADefault: Boolean);
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SlotClicked; cdecl;
  end;

  { TQtMainWindow }

  TQtMenuBar = class;
  TQtToolBar = class;
  TQtStatusBar = class;

  TQtMainWindow = class(TQtWidget)
  private
    FBlocked: Boolean;
    LayoutWidget: QBoxLayoutH;
    FCWEventHook: QObject_hookH;
    FShowOnTaskBar: Boolean;
    FPopupMode: TPopupMode;
    FPopupParent: QWidgetH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
    procedure ChangeParent(NewParent: QWidgetH);
    procedure UpdateParent;
  public
    QtFormBorderStyle: Integer;
    QtFormStyle: Integer;
    IsMainForm: Boolean;
    MDIAreaHandle: QMDIAreaH;
    MenuBar: TQtMenuBar;
    ToolBar: TQtToolBar;
    destructor Destroy; override;
    procedure Activate; override;
    function getAcceptDropFiles: Boolean; override;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    procedure setText(const W: WideString); override;
    procedure setMenuBar(AMenuBar: QMenuBarH);
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    function IsMdiChild: Boolean;
    function IsModal: Boolean;
    function MdiChildCount: integer;
    procedure OffsetMousePos(APoint: PQtPoint); override;
    procedure setAcceptDropFiles(AValue: Boolean);
    procedure SlotActivateWindow(vActivate: Boolean); cdecl;
    procedure slotWindowStateChange; cdecl;
    procedure setShowInTaskBar(AValue: Boolean);
    procedure setPopupParent(APopupMode: TPopupMode; NewParent: QWidgetH);
    property Blocked: Boolean read FBlocked write FBlocked;
    property ShowOnTaskBar: Boolean read FShowOnTaskBar;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function CWEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
  end;
  
  { TQtHintWindow }

  TQtHintWindow = class(TQtMainWindow)
  protected
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
  public
    procedure SetDefaultColorRoles; override;
    procedure setVisible(AVisible: Boolean); override;
  end;

  { TQtStaticText }

  TQtStaticText = class(TQtFrame)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function CanPaintBackground: Boolean; override;
    function getText: WideString; override;
    procedure setText(const W: WideString); override;
    procedure setAlignment(const AAlignment: QtAlignment);
  end;

  { TQtCheckBox }

  TQtCheckBox = class(TQtAbstractButton)
  private
    FStateChangedHook : QCheckBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function CheckState: QtCheckState;
    procedure setCheckState(state: QtCheckState);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure signalStateChanged(p1: Integer); cdecl;
  end;

  { TQtRadioButton }

  TQtRadioButton = class(TQtAbstractButton)
  private
    FToggledHook: QAbstractButton_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure SignalToggled(Checked: Boolean); cdecl;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
  end;

  { TQtGroupBox }

  TQtGroupBox = class(TQtWidget)
  private
    FGroupBoxType: TQtGroupBoxType;
    FCWEventHook: QObject_hookH;
    procedure setLayoutThemeMargins(ALayout: QLayoutH; AWidget: QWidgetH);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function CanPaintBackground: Boolean; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    function getText: WideString; override;
    procedure setText(const W: WideString); override;
    procedure setFocusPolicy(const APolicy: QtFocusPolicy); override;
    property GroupBoxType: TQtGroupBoxType read FGroupBoxType write FGroupBoxType;
  end;
  
  { TQtToolBar }
  
  TQtToolBar = class(TQtWidget)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;
  
  { TQtToolButton }

  TQtToolButton = class(TQtAbstractButton)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;
  
  { TQtTrackBar }
  
  TQtTrackBar = class(TQtAbstractSlider)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function getTickInterval: Integer;
    procedure setTickPosition(Value: QSliderTickPosition);
    procedure setTickInterval(Value: Integer);
  public
    procedure AttachEvents; override;
    
    procedure SlotSliderMoved(p1: Integer); cdecl; override;
    procedure SlotValueChanged(p1: Integer); cdecl; override;
  end;

  { TQtLineEdit }

  TQtLineEdit = class(TQtWidget, IQtEdit)
  private
    FTextChanged: QLineEdit_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function getAlignment: QtAlignment;
    function getCursorPosition: Integer;
    function getMaxLength: Integer;
    function getSelectedText: WideString;
    function getSelectionStart: Integer;
    function getSelectionLength: Integer;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    function isUndoAvailable: Boolean;
    function hasSelectedText: Boolean;
    procedure selectAll;
    procedure setAlignment(const AAlignment: QtAlignment);
    procedure setBorder(const ABorder: Boolean);
    procedure setCursorPosition(const ACursorPosition: Integer);
    procedure setDefaultColorRoles; override;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setInputMask(const AMask: WideString);
    procedure setMaxLength(const ALength: Integer);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure setText(const AText: WideString); override;
    procedure Cut;
    procedure Copy;
    procedure Paste;
    procedure Undo;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer;
      WithThemeSpace: Boolean); override;
    procedure SignalTextChanged(p1: PWideString); cdecl;
  end;

  { TQtTextEdit }

  TQtTextEdit = class(TQtAbstractScrollArea, IQtEdit)
  private
    FViewportEventHook: QObject_hookH;
    FUndoAvailableHook: QTextEdit_hookH;
    FUndoAvailable: Boolean;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    FList: TStrings;
    procedure append(AStr: WideString);
    function getAlignment: QtAlignment;
    function getBlockCount: Integer;
    function getCursorPosition: Integer;
    function getMaxLength: Integer;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    function getSelectionStart: Integer;
    function getSelectionEnd: Integer;
    function getSelectionLength: Integer;
    procedure insertLine(const AIndex: integer; AText: WideString);
    function isUndoAvailable: Boolean;
    procedure removeLine(const AIndex: integer);
    procedure setAlignment(const AAlignment: QtAlignment);
    procedure setBorder(const ABorder: Boolean);
    procedure setCursorPosition(const ACursorPosition: Integer);
    procedure setDefaultColorRoles; override;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setLineWrapMode(const AMode: QTextEditLineWrapMode);
    procedure setMaxLength(const ALength: Integer);
    procedure setLineText(const AIndex: integer; AText: WideString);
    procedure setText(const AText: WideString); override;
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure setTabChangesFocus(const AValue: Boolean);
    procedure Cut;
    procedure Copy;
    procedure Paste;
    procedure Undo;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function viewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function getContextMenuPolicy: QtContextMenuPolicy; override;
    procedure setContextMenuPolicy(const AValue: QtContextMenuPolicy); override;
    procedure SignalUndoAvailable(b: Boolean); cdecl;
  end;

  { TQtTabBar }
  TQtTabBar = class(TQtWidget)
  private
    FTabBarChangedHook: QTabBar_hookH;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function GetTabRect(const AIndex: integer): TRect;
    procedure SignalTabBarCurrentChanged(Index: Integer); cdecl;
    function SlotTabBarMouse(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
  end;

  { TQtTabWidget }

  TQtTabWidget = class(TQtWidget)
  private
    FCurrentChangedHook: QTabWidget_hookH;
    FCloseRequestedHook: QTabWidget_hookH;
    FStackedWidgetHook: QObject_hookH;
    FTabBar: TQtTabBar;
    FStackWidget: QWidgetH;
    function getShowTabs: Boolean;
    function getStackWidget: QWidgetH;
    function getTabBar: TQtTabBar;
    procedure setShowTabs(const AValue: Boolean);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    procedure DestroyNotify(AWidget: TQtWidget); override;
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure SignalCurrentChanged(Index: Integer); cdecl;
    procedure SignalCloseRequested(Index: Integer); cdecl;
  public
    function indexOf(const AWidget: QWidgetH): integer;
    function insertTab(index: Integer; page: QWidgetH; p2: WideString): Integer; overload;
    function insertTab(index: Integer; page: QWidgetH; icon: QIconH; p2: WideString): Integer; overload;
    function getClientBounds: TRect; override;
    function getCurrentIndex: Integer;
    function GetLCLPageIndex(AIndex: Integer): Integer;
    function getTabPosition: QTabWidgetTabPosition;
    procedure removeTab(AIndex: Integer);
    procedure setCurrentIndex(AIndex: Integer);
    procedure setCurrentWidget(APage: TQtWidget);
    procedure setTabPosition(ATabPosition: QTabWidgetTabPosition);
    procedure setTabIcon(index: Integer; icon: QIconH);
    procedure setTabText(index: Integer; p2: WideString);
    procedure setTabsClosable(AValue: Boolean);
    function tabAt(APoint: TPoint): Integer;

    property ShowTabs: Boolean read getShowTabs write setShowTabs;
    property TabBar: TQtTabBar read getTabBar;
    property StackWidget: QWidgetH read getStackWidget;
  end;

  { TQtComboBox }

  TQtComboBox = class(TQtWidget, IQtEdit)
  private
    // hooks
    FChangeHook: QComboBox_hookH;
    FActivateHook: QComboBox_hookH;
    FOwnerDrawn: Boolean;
    FSelectHook: QComboBox_hookH;
    FDropListEventHook: QObject_hookH;
    // parts
    FLineEdit: TQtLineEdit;
    FDropList: TQtListWidget;
    FDropListVisibleInternal: Boolean;
    function GetDropList: TQtListWidget;
    function GetLineEdit: TQtLineEdit;
    procedure SetOwnerDrawn(const AValue: Boolean);
    procedure slotPaintCombo(Sender: QObjectH; Event: QEventH); cdecl;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
    // IQtEdit implementation
    function getCursorPosition: Integer;
    function getMaxLength: Integer;
    function getSelectionStart: Integer;
    function getSelectionLength: Integer;
    function isUndoAvailable: Boolean;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setMaxLength(const ALength: Integer);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure setCursorPosition(const ACursorPosition: Integer);
    procedure Cut;
    procedure Copy;
    procedure Paste;
    procedure Undo;
  public
    FList: TStrings;
    destructor Destroy; override;
    procedure DestroyNotify(AWidget: TQtWidget); override;
    procedure ClearItems;
    procedure setBorder(const ABorder: Boolean);
    function currentIndex: Integer;
    function getDroppedDown: Boolean;
    function getEditable: Boolean;
    function getMaxVisibleItems: Integer;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    procedure insertItem(AIndex: Integer; AText: String); overload;
    procedure insertItem(AIndex: Integer; AText: PWideString); overload;
    procedure setCurrentIndex(index: Integer);
    procedure setDefaultColorRoles; override;
    procedure setDroppedDown(const ADroppedDown: Boolean);
    procedure setMaxVisibleItems(ACount: Integer);
    procedure setEditable(const AValue: Boolean);
    procedure setItemText(AIndex: Integer; AText: String);
    procedure setText(const W: WideString); override;
    procedure removeItem(AIndex: Integer);
    
    property DropList: TQtListWidget read GetDropList;
    property LineEdit: TQtLineEdit read GetLineEdit;
    property OwnerDrawn: Boolean read FOwnerDrawn write SetOwnerDrawn;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer;
      WithThemeSpace: Boolean); override;

    procedure SlotActivate(index: Integer); cdecl;
    procedure SlotChange(p1: PWideString); cdecl;
    procedure SlotSelect(index: Integer); cdecl;
    procedure SlotDropListVisibility(AVisible: Boolean); cdecl;
  end;

  { TQtAbstractSpinBox}
  
  TQtAbstractSpinBox = class(TQtWidget, IQtEdit)
  private
    {$ifdef CPU64 and not WIN64}
    FParentShowPassed: Integer;
    {$endif}
    FEditingFinishedHook: QAbstractSpinBox_hookH;
    // parts
    FLineEdit: QLineEditH;
    function GetLineEdit: QLineEditH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
    // IQtEdit implementation
    function getCursorPosition: Integer;
    function getMaxLength: Integer;
    function getSelectionStart: Integer;
    function getSelectionLength: Integer;
    function isUndoAvailable: Boolean;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setMaxLength(const ALength: Integer);
    procedure setSelection(const AStart, ALength: Integer);
    procedure setCursorPosition(const ACursorPosition: Integer);
    procedure Cut;
    procedure Copy;
    procedure Paste;
    procedure Undo;
  public
    function getValue: Double; virtual; abstract;
    function getReadOnly: Boolean;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    procedure setBorder(const ABorder: Boolean);
    procedure setDefaultColorRoles; override;
    procedure setFocusPolicy(const APolicy: QtFocusPolicy); override;
    procedure setMinimum(const v: Double); virtual; abstract;
    procedure setMaximum(const v: Double); virtual; abstract;
    procedure setSingleStep(const v: Double); virtual; abstract;
    procedure setReadOnly(const r: Boolean);
    procedure setValue(const v: Double); virtual; abstract;
    procedure setText(const W: WideString); override;

    property LineEdit: QLineEditH read GetLineEdit;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    
    procedure SignalEditingFinished; cdecl;
  end;

  { TQtFloatSpinBox }

  TQtFloatSpinBox = class(TQtAbstractSpinBox)
  private
    FValue: Double;
    FValueChangedHook: QDoubleSpinBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function getValue: Double; override;
    procedure setDecimals(const v: integer);
    procedure setMinimum(const v: Double); override;
    procedure setMaximum(const v: Double); override;
    procedure setSingleStep(const v: Double); override;
    procedure setValue(const v: Double); override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure SignalValueChanged(p1: Double); cdecl;
  end;
  
  { TQtSpinBox }

  TQtSpinBox = class(TQtAbstractSpinBox)
  private
    FValue: Integer;
    FValueChangedHook: QSpinBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function getValue: Double; override;
    procedure setMinimum(const v: Double); override;
    procedure setMaximum(const v: Double); override;
    procedure setSingleStep(const v: Double); override;
    procedure setValue(const v: Double); override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure SignalValueChanged(p1: Integer); cdecl;
  end;

  { TQtAbstractItemView }

  TQtAbstractItemView = class(TQtAbstractScrollArea)
  private
    FSavedEvent: QMouseEventH;
    FSavedEventTimer: QTimerH;
    FSavedEventTimerHook: QTimer_hookH;
    FCheckable: boolean;
    FHideSelection: Boolean;
    FOldDelegate: QAbstractItemDelegateH;
    FNewDelegate: QLCLItemDelegateH;
    FOwnerData: Boolean;
    FSignalActivated: QAbstractItemView_hookH;
    FSignalClicked: QAbstractItemView_hookH;
    FSignalDoubleClicked: QAbstractItemView_hookH;
    FSignalEntered: QAbstractItemView_hookH;
    FSignalPressed: QAbstractItemView_hookH;
    FSignalViewportEntered: QAbstractItemView_hookH;
    FAbstractItemViewportEventHook: QObject_hookH;
    FSyncingItems: Boolean;
    FViewStyle: Integer;
    function getIconSize: TSize;
    function GetOwnerDrawn: Boolean;
    procedure setIconSize(const AValue: TSize);
    procedure SetOwnerDrawn(const AValue: Boolean);
  protected
    procedure OwnerDataNeeded(ARect: TRect); virtual;
    procedure PostponedMouseRelease(AEvent: QEventH); virtual;
    procedure PostponedMouseReleaseTimerEvent(); cdecl; virtual;
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); override;
    procedure signalActivated(index: QModelIndexH); cdecl; virtual;
    procedure signalClicked(index: QModelIndexH); cdecl; virtual;
    procedure signalDoubleClicked(index: QModelIndexH); cdecl; virtual;
    procedure signalEntered(index: QModelIndexH); cdecl; virtual;
    procedure signalPressed(index: QModelIndexH); cdecl; virtual;
    procedure signalViewportEntered; cdecl; virtual;
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    function itemViewViewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; virtual;
    procedure setDefaultColorRoles; override;
  public
    procedure clearSelection;
    function getModel: QAbstractItemModelH;
    function getRowHeight(ARowIndex: integer): integer;
    function getSelectionMode: QAbstractItemViewSelectionMode;
    function getTopItem: integer; virtual;
    function getVisibleRowCount(const AFirstVisibleOnly: boolean = false): integer; virtual;

    procedure modelIndex(retval: QModelIndexH; row, column: Integer; parent: QModelIndexH = nil);
    function visualRect(Index: QModelIndexH): TRect;
    procedure setEditTriggers(ATriggers: QAbstractItemViewEditTriggers);
    procedure setSelectionMode(AMode: QAbstractItemViewSelectionMode);
    procedure setSelectionBehavior(ABehavior: QAbstractItemViewSelectionBehavior);
    procedure setWordWrap(const AValue: Boolean); virtual;
    property Checkable: boolean read FCheckable write FCheckable;
    property HideSelection: Boolean read FHideSelection write FHideSelection;
    property IconSize: TSize read getIconSize write setIconSize;
    property OwnerDrawn: Boolean read GetOwnerDrawn write SetOwnerDrawn;
    property OwnerData: Boolean read FOwnerData write FOwnerData;
    property SyncingItems: Boolean read FSyncingItems write FSyncingItems;
    property ViewStyle: Integer read FViewStyle write FViewStyle;
  public
    procedure ItemDelegateSizeHint(option: QStyleOptionViewItemH; index: QModelIndexH; Size: PSize); cdecl; virtual;
    procedure ItemDelegatePaint(painter: QPainterH; option: QStyleOptionViewItemH; index: QModelIndexH); cdecl; virtual;
  end;

  { TQtListView }

  TQtListView = class(TQtAbstractItemView)
  private
    function getBatchSize: integer;
    function getGridSize: TSize;
    function getSpacing: Integer;
    procedure setBatchSize(const AValue: integer);
    procedure setSpacing(const AValue: integer);
    procedure setGridSize(const AValue: TSize);
  public
    procedure setLayoutMode(const ALayoutMode: QListViewLayoutMode);
    procedure setMovement(const AMovement: QListViewMovement);
    procedure setResizeMode(const AResizeMode: QListViewResizeMode);
    procedure setUniformItemSizes(const AEnable: Boolean);
    procedure setViewFlow(const AFlow: QListViewFlow);
    procedure setViewMode(const AMode: QListViewViewMode);
    procedure setWordWrap(const AValue: Boolean); override;
    procedure setWrapping(const AWrapping: Boolean);
    procedure LayoutItems;
    property BatchSize: integer read getBatchSize write setBatchSize;
    property GridSize: TSize read getGridSize write setGridSize;
    property Spacing: Integer read getSpacing write setSpacing;
  end;

  { TQtListWidget }

  TQtListWidget = class(TQtListView)
  private
    FCurrentItemChangedHook: QListWidget_hookH;
    FSelectionChangeHook: QListWidget_hookH;
    FItemClickedHook: QListWidget_hookH;
    FItemTextChangedHook: QListWidget_hookH;
    FDontPassSelChange: Boolean;
    function getItemCount: Integer;
    procedure setItemCount(const AValue: Integer);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
    procedure OwnerDataNeeded(ARect: TRect); override;
  public
    FList: TStrings;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    function itemViewViewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;

    procedure signalCurrentItemChanged(current: QListWidgetItemH; previous: QListWidgetItemH); cdecl; virtual;
    procedure signalItemTextChanged(ANewText: PWideString); cdecl; virtual;
    procedure signalItemClicked(item: QListWidgetItemH); cdecl; virtual;
    procedure signalSelectionChanged(); cdecl; virtual;
    procedure ItemDelegatePaint(painter: QPainterH; option: QStyleOptionViewItemH; index: QModelIndexH); cdecl; override;
  public
    procedure ClearItems;
    function currentRow: Integer;
    function currentItem: QListWidgetItemH;
    function IndexAt(APoint: PQtPoint): Integer;
    procedure insertItem(AIndex: Integer; AText: String); overload;
    procedure insertItem(AIndex: Integer; AText: PWideString); overload;
    function itemAt(APoint: TPoint): QListWidgetItemH; overload;
    function itemAt(x: Integer; y: Integer): QListWidgetItemH; overload;
    function getItem(AIndex: Integer): QListWidgetItemH;
    function getItemSelected(AItem: QListWidgetItemH): Boolean;
    function getItemVisible(AItem: QListWidgetItemH): Boolean;
    function getRow(AItem: QListWidgetItemH): integer;
    function getSelCount: Integer;
    function getTopItem: integer; override;
    function getVisibleRowCount(const AFirstVisibleOnly: boolean = false): integer; override;
    function getVisualItemRect(AItem: QListWidgetItemH): TRect;
    function selectedItems: TPtrIntArray;
    procedure setCurrentRow(row: Integer);
    procedure setCurrentItem(AItem: QListWidgetItemH);
    procedure setItemText(AIndex: Integer; AText: String); overload;
    procedure setItemText(AIndex: Integer; AText: String; AAlignment: Integer); overload;
    procedure setItemSelected(AItem: QListWidgetItemH; const ASelect: Boolean);
    procedure setItemVisible(AItem: QListWidgetItemH; Const AVisible: Boolean);
    procedure scrollToItem(row: integer; hint: QAbstractItemViewScrollHint);
    procedure removeItem(AIndex: Integer);
    function rowCount: integer;
    procedure exchangeItems(AIndex1, AIndex2: Integer);
    property ItemCount: Integer read getItemCount write setItemCount;
  end;

  { TQtCheckListBox }

  TQtCheckListBox = class (TQtListWidget)
  private
    FItemChangedHook: QListWidget_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    function itemViewViewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;

    procedure signalCurrentItemChanged(current: QListWidgetItemH; previous: QListWidgetItemH); cdecl; override;
    procedure signalItemClicked(item: QListWidgetItemH); cdecl; override;
    procedure signalSelectionChanged(); cdecl; override;
    procedure signalItemChanged(item: QListWidgetItemH); cdecl;
  end;

  { TQtHeaderView }

  TQtHeaderView = class (TQtAbstractItemView)
  private
    FSelectionClicked: QHeaderView_hookH;
    function getClickable: Boolean;
    function getMinSectionSize: Integer;
    procedure setClickable(const AValue: Boolean);
    procedure setMinSectionSize(const AValue: Integer);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure SignalSectionClicked(logicalIndex: Integer) cdecl;
    function getResizeMode(AIndex: Integer): QHeaderViewResizeMode;
    procedure setResizeMode(AResizeMode: QHeaderViewResizeMode); overload;
    procedure setResizeMode(AIndex: Integer; AResizeMode: QHeaderViewResizeMode); overload;
    procedure moveSection(AFromIndex: Integer; AToIndex: Integer);
    procedure resizeSection(ASection: Integer; ASize: Integer);
    procedure setHighlightSections(AValue: Boolean);
    procedure setDefaultSectionSize(AValue: Integer);
    function SortIndicatorOrder: QtSortOrder;
    procedure SetSortIndicator(const AColumn: Integer; const AOrder: QtSortOrder);
    procedure SetSortIndicatorVisible(AVisible: Boolean);
    procedure setStretchLastSection(AValue: Boolean);
    property Clickable: Boolean read getClickable write setClickable;
    property MinSectionSize: Integer read getMinSectionSize write setMinSectionSize;
  end;

  { TQtTreeView }
  
  TQtTreeView = class (TQtAbstractItemView)
  private
    function getColVisible(AIndex: Integer): Boolean;
    function getColWidth(AIndex: Integer): Integer;
    function GetUniformRowHeights: Boolean;
    procedure setColVisible(AIndex: Integer; const AValue: Boolean);
    procedure setColWidth(AIndex: Integer; const AValue: Integer);
    procedure SetUniformRowHeights(const AValue: Boolean);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure setAllColumnsShowFocus(AValue: Boolean);
    procedure setWordWrap(const AValue: Boolean); override;
    procedure setRootIsDecorated(AValue: Boolean);
    property ColWidth[AIndex: Integer]: Integer read getColWidth write setColWidth;
    property ColVisible[AIndex: Integer]: Boolean read getColVisible write setColVisible;
    property UniformRowHeights: Boolean read GetUniformRowHeights write SetUniformRowHeights;
  end;
  
  { TQtTreeWidget }

  TQtTreeWidget = class(TQtTreeView)
  private
    FSorting: Boolean;
    FHeader: TQtHeaderView;
    FSectionClicked: QHeaderView_hookH;
    FSortChanged: QHeaderView_hookH;
    FCurrentItemChangedHook: QTreeWidget_hookH;
    FItemDoubleClickedHook: QTreeWidget_hookH;
    FItemClickedHook: QTreeWidget_hookH;
    FItemActivatedHook: QTreeWidget_hookH;
    FItemChangedHook: QTreeWidget_hookH;
    FItemEnteredHook: QTreeWidget_hookH;
    FSelectionChangedHook: QTreeWidget_hookH;
    FCurrentItem: QTreeWidgetItemH;
    FPreviousItem: QTreeWidgetItemH;
    FMousePressed: Boolean;
    function getColCount: Integer;
    function getHeader: TQtHeaderView;
    function getItemCount: Integer;
    function getMaxColSize(ACol: Integer): Integer;
    function getMinColSize(ACol: Integer): Integer;
    function getSortEnabled: Boolean;
    procedure setColCount(const AValue: Integer);
    procedure setItemCount(const AValue: Integer);
    procedure setMaxColSize(ACol: Integer; const AValue: Integer);
    procedure setMinColSize(ACol: Integer; const AValue: Integer);
    procedure setSortEnabled(const AValue: Boolean);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
    procedure OwnerDataNeeded(ARect: TRect); override;
  public
    destructor Destroy; override;
    procedure DestroyNotify(AWidget: TQtWidget); override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    function itemViewViewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure ClearItems;
    procedure DeleteItem(const AIndex: integer);
    function currentRow: Integer;
    procedure setCurrentRow(row: Integer);
    function currentItem: QTreeWidgetItemH;
    procedure setCurrentItem(AItem: QTreeWidgetItemH);
    function getRow(AItem: QTreeWidgetItemH): integer;
    function headerItem: QTreeWidgetItemH;
    function itemAt(APoint: TPoint): QTreeWidgetItemH; overload;
    function itemAt(x: Integer; y: Integer): QTreeWidgetItemH; overload;
    procedure insertTopLevelItem(AIndex: Integer; AItem: QTreeWidgetItemH);
    function takeTopLevelItem(AIndex: Integer): QTreeWidgetItemH;
    function topLevelItem(AIndex: Integer): QTreeWidgetItemH;
    function visualItemRect(AItem: QTreeWidgetItemH): TRect;
    function getHeaderHeight(out AOrientation: QtOrientation): Integer;
    function getItemVisible(AItem: QTreeWidgetItemH): Boolean;
    function getTopItem: integer; override;
    function getVisibleRowCount(const AFirstVisibleOnly: boolean = false): integer; override;
    procedure setItemVisible(AItem: QTreeWidgetItemH; Const AVisible: Boolean);
    procedure setItemText(AItem: QTreeWidgetItemH; const AColumn: Integer;
      const AText: WideString; const AAlignment: QtAlignment);
    function selCount: Integer;
    function selectedItems: TPtrIntArray;
    procedure setHeaderVisible(AVisible: Boolean);
    procedure setItemSelected(AItem: QTreeWidgetItemH; ASelect: Boolean);
    procedure setStretchLastSection(AValue: Boolean);
    procedure sortItems(Acolumn: Integer; AOrder: QtSortOrder);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function getClientBounds: TRect; override;
    function getClientOffset: TPoint; override;

    procedure SignalItemClicked(item: QTreeWidgetItemH; column: Integer); cdecl;
    procedure SignalItemDoubleClicked(item: QTreeWidgetItemH; column: Integer); cdecl;
    procedure SignalItemActivated(item: QTreeWidgetItemH; column: Integer); cdecl;
    procedure SignalItemEntered(item: QTreeWidgetItemH; column: Integer); cdecl;
    procedure SignalItemChanged(item: QTreeWidgetItemH; column: Integer); cdecl;
    procedure SignalCurrentItemChanged(current: QTreeWidgetItemH; previous: QTreeWidgetItemH); cdecl;
    procedure SignalSelectionChanged(); cdecl;
    procedure SignalSortIndicatorChanged(ALogicalIndex: Integer; AOrder: QtSortOrder); cdecl;

    property ColCount: Integer read getColCount write setColCount;
    property Header: TQtHeaderView read getHeader;
    property ItemCount: Integer read getItemCount write setItemCount;
    property MaxColSize[ACol: Integer]: Integer read getMaxColSize write setMaxColSize;
    property MinColSize[ACol: Integer]: Integer read getMinColSize write setMinColSize;
    property SortEnabled: Boolean read getSortEnabled write setSortEnabled;
  end;
  
  {TQtTableView}
  
  TQtTableView = class(TQtAbstractItemView)
  private
    FVerticalHeader: TQtHeaderView;
    FHorizontalHeader: TQtHeaderView;
  public
    function verticalHeader: TQtHeaderView;
    function horizontalHeader: TQtHeaderView;
    function CreateWidget(const Params: TCreateParams): QWidgetH; override;
    function getViewPort: QWidgetH;
    function getClientBounds: TRect; override;
    procedure grabMouse; override;
    procedure setVisible(AVisible: Boolean); override;
    function getGridStyle: QtPenStyle;
    procedure setGridStyle(ANewStyle: QtPenStyle);
  public
    destructor Destroy; override;
  end;

  { TQtMenu }

  TQtMenu = class(TQtWidget)
  private
    FActions: TFPList;
    FIcon: QIconH;
    FTriggeredHook: QAction_hookH;
    FHoveredHook: QAction_hookH;
    FAboutToHideHook: QMenu_hookH;
    FActionEventFilter: QObject_hookH;
    FActionHandle: QActionH;
    FMenuItem: TMenuItem;
    FTrackButton: QtMouseButtons;
    procedure setActionGroups(AItem: TMenuItem);
  protected
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
    procedure DoPopupClose;
  public
    constructor Create(const AMenuItem: TMenuItem); overload;
    destructor Destroy; override;
    procedure InitializeWidget; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SlotHovered; cdecl;
    procedure SlotAboutToHide; cdecl;
    procedure SlotDestroy; cdecl;
    procedure SlotTriggered(checked: Boolean = False); cdecl;
    function ActionEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
  public
    function actionHandle: QActionH;
    function addMenu(AMenu: QMenuH): QActionH;
    function insertMenu(AIndex: Integer; AMenu: QMenuH; AItem: TMenuItem): QActionH;
    function getHasSubMenu: boolean;
    function getText: WideString; override;
    function getVisible: Boolean; override;
    procedure PopUp(pos: PQtPoint; at: QActionH = nil);
    procedure removeActionGroup;
    procedure setChecked(p1: Boolean);
    procedure setCheckable(p1: Boolean);
    procedure setHasSubmenu(AValue: Boolean);
    procedure setIcon(AIcon: QIconH);
    procedure setImage(AImage: TQtImage);
    procedure setSeparator(AValue: Boolean);
    procedure setShortcut(AShortcut: TShortcut);
    procedure setText(const W: WideString); override;
    procedure setVisible(AVisible: Boolean); override;
    property trackButton: QtMouseButton read FTrackButton write FTrackButton;
  end;

  { TQtMenuBar }

  TQtMenuBar = class(TQtWidget)
  private
    FVisible: Boolean;
    FHeight: Integer;
  public
    constructor Create(const AParent: QWidgetH); overload;
  public
    function addMenu(AMenu: QMenuH): QActionH;
    function insertMenu(AIndex: Integer; AMenu: QMenuH): QActionH;
    function getGeometry: TRect; override;
  end;

  { TQtProgressBar }

  TQtProgressBar = class(TQtWidget)
  private
    FValueChangedHook: QProgressBar_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure SignalValueChanged(Value: Integer); cdecl;
  public
    procedure reset;
    procedure setRange(minimum: Integer; maximum: Integer);
    procedure setTextVisible(visible: Boolean);
    procedure setAlignment(const AAlignment: QtAlignment);
    procedure setTextDirection(textDirection: QProgressBarDirection);
    procedure setValue(value: Integer);
    procedure setOrientation(p1: QtOrientation);
    procedure setInvertedAppearance(invert: Boolean);
  end;

  { TQtStatusBarPanel }

  TQtStatusBarPanel = class(TQtFrame)
  private
    FId: Integer;
    procedure DrawItem(Sender: QObjectH; Event: QEventH);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    property ID: Integer read FId write FId;
  end;

  { TQtStatusBar }

  TQtStatusBar = class(TQtWidget)
  protected
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
  public
    Panels: array of TQtStatusBarPanel;
    procedure showMessage(text: PWideString; timeout: Integer = 0);
    procedure addWidget(AWidget: QWidgetH; AStretch: Integer = 0);
    procedure removeWidget(AWidget: QWidgetH);
    function isSizeGripEnabled: Boolean;
    procedure setSizeGripEnabled(const Value: Boolean);
    function SlotMouse(Sender: QObjectH; Event: QEventH): Boolean; override; cdecl;
  end;
  
  { TQtDialog }
  
  TQtDialog = class(TQtWidget)
  private
    FDialogEventHook: QObject_hookH;
  protected
    FDialog: TCommonDialog;
    function CreateWidget(parent: QWidgetH; f: QtWindowFlags):QWidgetH; virtual; overload;
  public
    constructor Create(ADialog: TCommonDialog; parent: QWidgetH = nil; f: QtWindowFlags = 0); overload;
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function DeliverMessage(var Msg): LRESULT; override;
    function SlotClose: Boolean; cdecl; override;
  public
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    function exec: Integer;
    procedure setSizeGripEnabled(const AEnabled: Boolean);
  end;
  
  { TQtFileDialog }

  TQtFileDialog = class(TQtDialog)
  private
    {$ifndef QT_NATIVE_DIALOGS}
    FBackBtn: QWidgetH;
    FForwardBtn: QWidgetH;
    FUpBtn: QWidgetH;
    FFileNameEdit: QWidgetH;
    FComboType: QWidgetH;
    FComboHistory: QWidgetH;
    FSideView: QWidgetH;
    FTreeView: QWidgetH;
    FListView: QWidgetH;
    FTreeViewEventFilter: QObject_hookH;
    FListViewEventFilter: QObject_hookH;
    FSideViewEventFilter: QObject_hookH;
    FFileNameEditEventFilter: QObject_hookH;
    FComboTypeEventFilter: QObject_hookH;
    FComboHistoryEventFilter: QObject_hookH;
    {$endif}
    FCurrentChangedHook: QFileDialog_hookH;
    FDirecotyEnteredHook: QFileDialog_hookH;
    FFilterSelectedHook: QFileDialog_hookH;
  protected
    function CreateWidget(parent: QWidgetH; f: QtWindowFlags):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    {$ifndef QT_NATIVE_DIALOGS}
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    {$endif}
    procedure CurrentChangedEvent(path: PWideString); cdecl;
    procedure FilterSelectedEvent(filter: PWideString); cdecl;
    procedure DirectoryEnteredEvent(directory: PWideString); cdecl;
  public
    procedure getFilters(const retval: QStringListH);
    function selectFile: WideString;
    procedure selectedFiles(retval: QStringListH);
    procedure setAcceptMode(const AMode: QFileDialogAcceptMode);
    procedure setConfirmOverwrite(const AValue: Boolean);
    procedure setDirectory(const ADirectory: WideString);
    procedure setHistory(AList: TStrings);
    procedure setFileMode(const AMode: QFileDialogFileMode);
    procedure setFilter(const AFilter: WideString);
    procedure setLabelText(const ALabel: QFileDialogDialogLabel; const AText: WideString);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelectedFilter(const ASelFilter: WideString);
    procedure setViewMode(const AMode: QFileDialogViewMode);
    {$ifndef QT_NATIVE_DIALOGS}
    procedure setShortcuts(const AIsOpenDialog: Boolean);
    {$endif}
  end;

  { TQtMessageBox }

  TQtMessageBox = class(TQtWidget)
  private
    FMBEventHook: QObject_hookH;
    FTitle: WideString;
    function getDetailText: WideString;
    function getMessageStr: WideString;
    function getMsgBoxType: QMessageBoxIcon;
    procedure setDetailText(const AValue: WideString);
    procedure setMessageStr(const AValue: WideString);
    procedure setMsgBoxType(const AValue: QMessageBoxIcon);
    procedure setTitle(const AValue: WideString);
  protected
    function CreateWidget(AParent: QWidgetH):QWidgetH; overload;
  public
    constructor Create(AParent: QWidgetH); overload;
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
  public
    function AddButton(ACaption: WideString; ABtnType: QMessageBoxStandardButton; AResult: Int64;
      const ADefaultBtn: Boolean; const AEscapeBtn: Boolean = False): QPushButtonH; overload;
    function AddButton(ACaption: WideString; AResult: Int64;
      const ADefaultBtn: Boolean; const AEscapeBtn: Boolean = False): QPushButtonH;
    procedure SetButtonProps(ABtn: QPushButtonH; AResult: Int64; const ADefaultBtn: Boolean;
      const AEscapeBtn: Boolean);
    function exec: Int64;
    property DetailText: WideString read getDetailText write setDetailText;
    property MessageStr: WideString read getMessageStr write setMessageStr;
    property MsgBoxType:QMessageBoxIcon read getMsgBoxType write setMsgBoxType;
    property Title: WideString read FTitle write setTitle;
  end;
  
  { TQtCalendar }

  TQtCalendar = class(TQtWidget)
  private
    FMouseDoubleClicked: Boolean;
    FCalViewportEventHook: QObject_hookH;
    FClickedHook: QCalendarWidget_hookH;
    FActivatedHook: QCalendarWidget_hookH;
    FSelectionChangedHook: QCalendarWidget_hookH;
    FCurrentPageChangedHook: QCalendarWidget_hookH;
    function GetDateTime: TDateTime;
    procedure SetDateTime(const AValue: TDateTime);
    procedure SetSelectedDate(const AValue: QDateH);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    AYear, AMonth, ADay: Word;
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function calViewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function HitTest(const APoint: TPoint): byte;
    procedure SetDisplaySettings(
      const AHHdrFmt: QCalendarWidgetHorizontalHeaderFormat;
      const AVHdrFmt: QCalendarWidgetVerticalHeaderFormat;
      const ASelMode: QCalendarWidgetSelectionMode;
      const ANavBarVisible: Boolean; const AGridVisible: Boolean;
      const AStartMonday: Boolean
      );
    procedure SignalActivated(ADate: QDateH); cdecl;
    procedure SignalClicked(ADate: QDateH); cdecl;
    procedure SignalSelectionChanged; cdecl;
    procedure SignalCurrentPageChanged(p1, p2: Integer); cdecl;
    property DateTime: TDateTime read GetDateTime write SetDateTime;
  end;
  
  // for page control / notebook

  { TQtPage }

  TQtPage = class(TQtWidget)
  protected
    FIcon: QIconH;
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    function getIcon: QIconH;
    function getIndex: Integer;
    function getTabWidget: QTabWidgetH;
    procedure setIcon(const AIcon: QIconH);
    procedure setText(const W: WideString); override;
  end;
  
  { TQtRubberBand }
  
  TQtRubberBand = class(TQtWidget)
  private
    FShape: QRubberBandShape;
  protected
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); override;

    // QRubberBand have it's own move,resize and setGeometry
    procedure move(ANewLeft, ANewTop: Integer); override;
    procedure resize(ANewWidth, ANewHeight: Integer); override;
    procedure setGeometry(ARect: TRect); override;

    function getShape: QRubberBandShape;
    procedure setShape(AShape: QRubberBandShape);
  end;
  
  { TQtDesignWidget }

  TQtDesignWidget = class(TQtMainWindow)
  protected
    FDesignControlEventHook: QObject_hookH;
    FDesignControl: QWidgetH;
    FDesignContext: HDC;
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
    procedure DestroyWidget; override;
    procedure SlotDesignControlPaint(Sender: QObjectH; Event: QEventH); cdecl;
    procedure BringDesignerToFront;
    procedure ResizeDesigner;
    function GetContext: HDC; override;
  public
    function DesignControlEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;

    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure lowerWidget; override;
    procedure raiseWidget; override;
  public
    property DesignContext: HDC read FDesignContext;
  end;

const
  AlignmentMap: array[TAlignment] of QtAlignment =
  (
{taLeftJustify } QtAlignLeft,
{taRightJustify} QtAlignRight,
{taCenter      } QtAlignHCenter
  );

implementation

uses
  LCLMessageGlue,
  qtCaret,
  qtproc,
  WSControls;

const
  DblClickThreshold = 3;// max Movement between two clicks of a DblClick

type
  TWinControlAccess = class(TWinControl)
  end;
  TLastMouseInfo = record
    Widget: QObjectH;
    MousePos: TQtPoint;
    TheTime: TDateTime;
    ClickCount: Integer;
  end;

var
{$IFDEF DARWIN}
  LastMouse: TLastMouseInfo = (Widget: nil; MousePos: (y:0; x:0); TheTime:0; ClickCount: 0);
{$ELSE}
  LastMouse: TLastMouseInfo = (Widget: nil; MousePos: (x:0; y:0); TheTime:0; ClickCount: 0);
{$ENDIF}

{ TQtWidget }

{------------------------------------------------------------------------------
  Function: TQtWidget.Create
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
constructor TQtWidget.Create(const AWinControl: TWinControl; const AParams: TCreateParams);
begin
  inherited Create;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;
  // Initializes the properties
  FProps := nil;
  LCLObject := AWinControl;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  FHasPaint := False;

  FParams := AParams;
  InitializeWidget;
end;

constructor TQtWidget.CreateFrom(const AWinControl: TWinControl;
  AWidget: QWidgetH);
begin
  inherited Create;

  FOwner := nil;
  FOwnWidget := False;
  FCentralWidget := nil;
  // Initializes the properties
  FProps := niL;
  LCLObject := AWinControl;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  
  // Creates the widget
  Widget := AWidget;
  
  FDefaultCursor := QCursor_create();
  QWidget_cursor(Widget, FDefaultCursor);

  // set Handle->QWidget map
  setProperty(Widget, 'lclwidget', Int64(PtrUInt(Self)));
  FillChar(FPaintData, sizeOf(FPaintData), 0);

  QtWidgetSet.AddHandle(Self);
  // set focus policy
  if (LCLObject <> nil) and not (Self is TQtMainWindow) then
    setFocusPolicy(QtClickFocus);

  // Set mouse move messages policy
  QWidget_setMouseTracking(Widget, True);
end;

procedure TQtWidget.InitializeWidget;
begin
  // default color roles
  SetDefaultColorRoles;
  FPalette := nil;
  FHasCaret := False;
  FLastCaretPos := QtPoint(-1, -1);
  ChildOfComplexWidget := ccwNone;
  // creates the widget
  Widget := CreateWidget(FParams);

  // retrieve default cursor on create
  FDefaultCursor := QCursor_create();
  QWidget_cursor(Widget, FDefaultCursor);
  
  // apply initial position and size
  move(FParams.X, FParams.Y);
  if GetContainerWidget <> Widget then
    QWidget_resize(GetContainerWidget, FParams.Width, FParams.Height);
  resize(FParams.Width, FParams.Height);

  FScrollX := 0;
  FScrollY := 0;

  {$ifdef VerboseQt}
  DebugLn('TQtWidget.InitializeWidget: Self:%x Widget:%x was created for control %s',
    [HWND(Self), PtrUInt(Widget), LCLObject.Name]);
  {$endif}

  // set Handle->QWidget map
  setProperty(Widget, 'lclwidget', Int64(PtrUInt(Self)));
  QtWidgetSet.AddHandle(Self);

  FillChar(FPaintData, sizeOf(FPaintData), 0);

  // Sets it's initial properties

  // set focus policy
  if (LCLObject <> nil) and not (Self is TQtMainWindow) then
    setFocusPolicy(QtClickFocus);

  if (csDesigning in LCLObject.ComponentState) and not
     (Self is TQtMainWindow) and
     HasPaint and
     getAutoFillBackground or
     ((csDesigning in LCLObject.ComponentState) and
      (ClassType = TQtTabWidget)) then
    setAutoFillBackground(False);

  // Set mouse move messages policy
  QWidget_setMouseTracking(Widget, True);
end;

procedure TQtWidget.DeInitializeWidget;
begin
  QtWidgetSet.RemoveHandle(Self);
  if Widget <> nil then
    DetachEvents;

  if Widget <> nil then
    removeProperty(Widget, 'lclwidget');

  QCursor_destroy(FDefaultCursor);
  
  if HasCaret then
    DestroyCaret;

  if FPalette <> nil then
  begin
    FPalette.Free;
    FPalette := nil;
  end;

  DestroyWidget;
end;

procedure TQtWidget.RecreateWidget;
var
  Parent: QWidgetH;
begin
  // update createparams
  with getPos do
  begin
    FParams.X := X;
    FParams.Y := Y;
  end;
  with getSize do
  begin
    FParams.Width := cx;
    FParams.Height := cy;
  end;

  if Widget <> nil then
    Parent := QWidget_parentWidget(Widget)
  else
    Parent := nil;
  FParams.WndParent := HwndFromWidgetH(Parent);
  DeinitializeWidget;
  InitializeWidget;
end;

procedure TQtWidget.DestroyNotify(AWidget: TQtWidget);
begin
  if AWidget = FOwner then
    FOwner := nil;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtWidget.Destroy;
begin
  DeinitializeWidget;

  if FProps <> nil then
  begin
    FProps.Free;
    FProps:=nil;
  end;

  if FPaintData.ClipRegion <> nil then
  begin
    QRegion_Destroy(FPaintData.ClipRegion);
    FPaintData.ClipRegion:=nil;
  end;
  
  if FOwner <> nil then
    FOwner.DestroyNotify(Self);

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.GetContainerWidget
  Params:  None
  Returns: The widget of the control on top of which other controls
           should be placed
 ------------------------------------------------------------------------------}
function TQtWidget.GetContainerWidget: QWidgetH;
begin
  if FCentralWidget <> nil then
    Result := FCentralWidget
  else
    Result := Widget;
end;

procedure TQtWidget.Release;
begin
  LCLObject := nil;
  inherited Release;
end;

procedure TQtWidget.Destroyed; cdecl;
begin
  Widget := nil;
  Release;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.CanSendLCLMessage
  Params:  None
  Returns: Boolean
  If returns FALSE then we should not send any message to LCL since our
  LCLObject is probably being destroyed or it has csDestroying flag on.
  This is very important to know before calling NotifyApplicationUserInput,
  which is often called from mouse & keyboard events.
 ------------------------------------------------------------------------------}
function TQtWidget.CanSendLCLMessage: Boolean;
begin
  Result := (LCLObject <> nil) and getVisible and
    not ((csDestroying in LCLObject.ComponentState) or
         (csDestroyingHandle in LCLObject.ControlState));
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.CanPaintBackground
  Params:  None
  Returns: Boolean
  Makes decision if control background need to be painted.
  Look at SlotPaintBg().
 ------------------------------------------------------------------------------}
function TQtWidget.CanPaintBackground: Boolean;
begin
  {TODO: we must override this function for some classes
   until clDefault is implemented in LCL.Then we can easy
   ask EqualTQColor() for diff between
   Palette.DefaultColor and current LCLObject.Color}
  Result := False;
end;

{$IF DEFINED(VerboseQt) OR DEFINED(VerboseQtEvents)}
function EventTypeToStr(Event:QEventH):string;
// Qt 3 events
const
  QEventChildInsertedRequest = 67;
  QEventChildInserted = 70;
  QEventLayoutHint = 72;
begin
  case QEvent_type(Event) of
    QEventNone: result:='QEventNone';
    QEventTimer: result:='QEventTimer';
    QEventMouseButtonPress: result:='QEventMouseButtonPress';
    QEventMouseButtonRelease: result:='QEventMouseButtonRelease';
    QEventMouseButtonDblClick: result:='QEventMouseButtonDblClick';
    QEventMouseMove: result:='QEventMouseMove';
    QEventKeyPress: result:='QEventKeyPress';
    QEventKeyRelease: result:='QEventKeyRelease';
    QEventFocusIn: result:='QEventFocusIn';
    QEventFocusOut: result:='QEventFocusOut';
    QEventEnter: result:='QEventEnter';
    QEventLeave: result:='QEventLeave';
    QEventPaint: result:='QEventPaint';
    QEventMove: result:='QEventMove';
    QEventResize: result:='QEventResize';
    QEventCreate: result:='QEventCreate';
    QEventDestroy: result:='QEventDestroy';
    QEventShow: result:='QEventShow';
    QEventHide: result:='QEventHide';
    QEventClose: result:='QEventClose';
    QEventQuit: result:='QEventQuit';
    QEventParentChange: result:='QEventParentChange';
    QEventThreadChange: result:='QEventThreadChange';
    QEventWindowActivate: result:='QEventWindowActivate';
    QEventWindowDeactivate: result:='QEventWindowDeactivate';
    QEventShowToParent: result:='QEventShowToParent';
    QEventHideToParent: result:='QEventHideToParent';
    QEventWheel: result:='QEventWheel';
    QEventWindowTitleChange: result:='QEventWindowTitleChange';
    QEventWindowIconChange: result:='QEventWindowIconChange';
    QEventApplicationWindowIconChange: result:='QEventApplicationWindowIconChange';
    QEventApplicationFontChange: result:='QEventApplicationFontChange';
    QEventApplicationLayoutDirectionChange: result:='QEventApplicationLayoutDirectionChange';
    QEventApplicationPaletteChange: result:='QEventApplicationPaletteChange';
    QEventPaletteChange: result:='QEventPaletteChange';
    QEventClipboard: result:='QEventClipboard';
    QEventSpeech: result:='QEventSpeech';
    QEventMetaCall: result:='QEventMetaCall';
    QEventSockAct: result:='QEventSockAct';
    QEventShortcutOverride: result:='QEventShortcutOverride';
    QEventDeferredDelete: result:='QEventDeferredDelete';
    QEventDragEnter: result:='QEventDragEnter';
    QEventDragMove: result:='QEventDragMove';
    QEventDragLeave: result:='QEventDragLeave';
    QEventDrop: result:='QEventDrop';
    QEventDragResponse: result:='QEventDragResponse';
    //    QEventChildInsertedRequest: result:='(Qt3) QEventChildAdded'; //qt3
    QEventChildAdded: result:='QEventChildAdded';
    QEventChildPolished: result:='QEventChildPolished';
    //    QEventChildInserted: result:='(Qt3) QEventChildAdded'; // qt3
    //    QEventLayoutHint: result:='(Qt3) QEventChildAdded'; // qt3
    QEventChildRemoved: result:='QEventChildRemoved';
    QEventShowWindowRequest: result:='QEventShowWindowRequest';
    QEventPolishRequest: result:='QEventPolishRequest';
    QEventPolish: result:='QEventPolish';
    QEventLayoutRequest: result:='QEventLayoutRequest';
    QEventUpdateRequest: result:='QEventUpdateRequest';
    QEventUpdateLater: result:='QEventUpdateLater';
    QEventEmbeddingControl: result:='QEventEmbeddingControl';
    QEventActivateControl: result:='QEventActivateControl';
    QEventDeactivateControl: result:='QEventDeactivateControl';
    QEventContextMenu: result:='QEventContextMenu';
    QEventInputMethod: result:='QEventInputMethod';
    QEventAccessibilityPrepare: result:='QEventAccessibilityPrepare';
    QEventTabletMove: result:='QEventTabletMove';
    QEventLocaleChange: result:='QEventLocaleChange';
    QEventLanguageChange: result:='QEventLanguageChange';
    QEventLayoutDirectionChange: result:='QEventLayoutDirectionChange';
    QEventStyle: result:='QEventStyle';
    QEventTabletPress: result:='QEventTabletPress';
    QEventTabletRelease: result:='QEventTabletRelease';
    QEventOkRequest: result:='QEventOkRequest';
    QEventHelpRequest: result:='QEventHelpRequest';
    QEventIconDrag: result:='QEventIconDrag';
    QEventFontChange: result:='QEventFontChange';
    QEventEnabledChange: result:='QEventEnabledChange';
    QEventActivationChange: result:='QEventActivationChange';
    QEventStyleChange: result:='QEventStyleChange';
    QEventIconTextChange: result:='QEventIconTextChange';
    QEventModifiedChange: result:='QEventModifiedChange';
    QEventWindowBlocked: result:='QEventWindowBlocked';
    QEventWindowUnblocked: result:='QEventWindowUnblocked';
    QEventWindowStateChange: result:='QEventWindowStateChange';
    QEventMouseTrackingChange: result:='QEventMouseTrackingChange';
    QEventToolTip: result:='QEventToolTip';
    QEventWhatsThis: result:='QEventWhatsThis';
    QEventStatusTip: result:='QEventStatusTip';
    QEventActionChanged: result:='QEventActionChanged';
    QEventActionAdded: result:='QEventActionAdded';
    QEventActionRemoved: result:='QEventActionRemoved';
    QEventFileOpen: result:='QEventFileOpen';
    QEventShortcut: result:='QEventShortcut';
    QEventWhatsThisClicked: result:='QEventWhatsThisClicked';
    QEventAccessibilityHelp: result:='QEventAccessibilityHelp';
    QEventToolBarChange: result:='QEventToolBarChange';
    QEventApplicationActivated: result:='QEventApplicationActivated';
    QEventApplicationDeactivated: result:='QEventApplicationDeactivated';
    QEventQueryWhatsThis: result:='QEventQueryWhatsThis';
    QEventEnterWhatsThisMode: result:='QEventEnterWhatsThisMode';
    QEventLeaveWhatsThisMode: result:='QEventLeaveWhatsThisMode';
    QEventZOrderChange: result:='QEventZOrderChange';
    QEventHoverEnter: result:='QEventHoverEnter';
    QEventHoverLeave: result:='QEventHoverLeave';
    QEventHoverMove: result:='QEventHoverMove';
    QEventAccessibilityDescription: result:='QEventAccessibilityDescription';
    QEventParentAboutToChange: result:='QEventParentAboutToChange';
    QEventWinEventAct: result:='QEventWinEventAct';
    QEventAcceptDropsChange: result:='QEventAcceptDropsChange';
    QEventMenubarUpdated: result:='QEventMenubarUpdated';
    QEventZeroTimerEvent: result:='QEventZeroTimerEvent';
    QEventNonClientAreaMouseMove: result:='QEventNonClientAreaMouseMove';
    QEventNonClientAreaMouseButtonPress: result:='QEventNonClientAreaMouseButtonPress';
    QEventNonClientAreaMouseButtonRelease: result:='QEventNonClientAreaMouseButtonRelease';
    QEventNonClientAreaMouseButtonDblClick: result:='QEventNonClientAreaMouseButtonDblClick';
    QEventMacSizeChange: result := 'QEventMacSizeChange';
    QEventContentsRectChange: result := 'QEventContentsRectChange';
    QEventMacGLWindowChange: result := 'QEventMacGLWindowChange';
    QEventFutureCallOut: result := 'QEventFutureCallOut';
    QEventGraphicsSceneResize: result := 'QEventGraphicsSceneResize';
    QEventGraphicsSceneMove: result := 'QEventGraphicsSceneMove';
    QEventCursorChange: result := 'QEventCursorChange';
    QEventToolTipChange: result := 'QEventToolTipChange';
    QEventNetworkReplyUpdated: result := 'QEventNetworkReplyUpdated';
    QEventGrabMouse: result := 'QEventGrabMouse';
    QEventUngrabMouse: result := 'QEventUngrabMouse';
    QEventGrabKeyboard: result := 'QEventGrabKeyboard';
    QEventUngrabKeyboard: result := 'QEventUngrabKeyboard';
    QEventCocoaRequestModal: result := 'QEventCocoaRequestModal';
    QEventUser: result:='QEventUser';
    QEventMaxUser: result:='QEventMaxUser';
  else
    Result := Format('Unknown event: %d', [QEvent_type(Event)]);
  end;
end;
{$ENDIF}

{------------------------------------------------------------------------------
  Function: TQtWidget.EventFilter
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  QColor, OldColor: TQColor;
  Color: TColor;
  QtEdit: IQtEdit;
  R: TRect;
  Pt: TQtPoint;
begin
  BeginEventProcessing;
  Result := False;

  QEvent_accept(Event);

  {$IF DEFINED(VerboseQt) OR DEFINED(VerboseQtEvents)}
  WriteLn('TQtWidget.EventFilter: Sender=', IntToHex(PtrUInt(Sender),8),
    ' LCLObject=', dbgsName(LCLObject),
    ' Event=', EventTypeToStr(Event),' inUpdate=',InUpdate);
  {$endif}

  if LCLObject <> nil then
  begin
    case QEvent_type(Event) of
      QEventEnabledChange:
        begin
          // if we are disabled, imediatelly invalidate widgetAt cache
          if QtWidgetSet.IsWidgetAtCache(HWND(Self)) then
            QtWidgetSet.InvalidateWidgetAtCache
          else
          if QtWidgetSet.IsValidWidgetAtCachePointer then
          begin
            Pt := QtPoint(0, 0);
            QWidget_mapToGlobal(Widget, @Pt, @Pt);
            QWidget_geometry(Widget, @R);
            R := Rect(Pt.X, Pt.Y, Pt.X + (R.Right - R.Left), Pt.Y + (R.Bottom - R.Top));
            if PtInRect(R, QtWidgetSet.GetWidgetAtCachePoint) then
              QtWidgetSet.InvalidateWidgetAtCache;
          end;
        end;
      QEventShow: SlotShow(True);
      QEventHide: SlotShow(False);
      QEventClose:
        if not SlotClose then
        begin
          QEvent_ignore(Event);
          Result := True;
        end;
      QEventDestroy: SlotDestroy;
      QEventEnter,
      QEventLeave: Result := SlotMouseEnter(Sender, Event);
      
      QEventHoverEnter,
      QEventHoverLeave,
      QEventHoverMove: Result := SlotHover(Sender, Event);

      QEventDrop,
      QEventDragMove,
      QEventDragEnter:
      begin
        Result := getAcceptDropFiles;
        if (Result) and (QEvent_type(Event) = QEventDrop) then
          Result := slotDropFiles(Sender, Event);
      end;

      QEventKeyPress,
      QEventKeyRelease:
        begin
          {non-spontaneous key events are garbage in Qt >= 4.4 for non edits}
          Result := QEvent_spontaneous(Event) or Supports(Self, IQtEdit, QtEdit);
          if Result then
            Result := SlotKey(Sender, Event) or (LCLObject is TCustomControl);
        end;

      QEventMouseButtonPress,
      QEventMouseButtonRelease,
      QEventMouseButtonDblClick: Result := SlotMouse(Sender, Event);
      QEventMouseMove: Result := SlotMouseMove(Sender, Event);
      QEventWheel:
        begin
          SlotMouseWheel(Sender, Event);
        end;
      QEventMove: SlotMove(Event);
      QEventResize: SlotResize(Event);
      QEventContentsRectChange: LCLObject.DoAdjustClientRectChange(False);
      QEventPaint:
        begin
          if canPaintBackground and (LCLObject.Color <> clDefault) then
            SlotPaintBg(Sender, Event);
          if FHasPaint then
            SlotPaint(Sender, Event);
        end;
      QEventContextMenu:
          Result := SlotContextMenu(Sender, Event);
      QEventNonClientAreaMouseButtonPress:
        begin
          SlotNCMouse(Sender, Event);
        end;
      QEventPaletteChange,
      QEventStyleChange:
        begin
          if (FPalette <> nil) and not InUpdate and not Palette.InReload then
          begin
            OldColor := Palette.CurrentColor;
            // now set our fpalette color from LCL
            if LCLObject.Color <> clDefault then
            begin
              Color := ColorToRGB(LCLObject.Color);
              QColor_fromRgb(@QColor,Red(Color),Green(Color),Blue(Color));
            end else
              QColor := Palette.DefaultColor;
            if not EqualTQColor(OldColor, QColor) then
            begin
              Palette.ReloadPaletteBegin;
              try
                SetColor(@QColor);
                Result := True;
                QEvent_accept(Event);
              finally
                Palette.ReloadPaletteEnd;
              end;
            end;
          end;
        end;
      QEventQueryWhatsThis: Result := True;
      QEventWhatsThis:
        begin
          SlotWhatsThis(Sender, Event);
          // TODO: we need to stop event by Result := True; but then we also need
          // to ask qt to leave Whats This mode. Currently we have no means to do so
        end;
      QEventLCLMessage:
        begin
          SlotLCLMessage(Sender, Event);
          Result := True;
        end;
    else
      QEvent_ignore(Event);
    end;
  end
  else
    QEvent_ignore(Event);

  {fixes #14544 and others when we loose our LCLObject
   after delivering message to LCL.}
  if (LCLObject = nil) and
     ((QEvent_type(Event) = QEventMouseButtonPress) or
     (QEvent_type(Event) = QEventMouseButtonRelease) or
     (QEvent_type(Event) = QEventMouseButtonDblClick) or
     (QEvent_type(Event) = QEventMouseMove) or
     (QEvent_type(Event) = QEventHoverEnter) or
     (QEvent_type(Event) = QEventHoverLeave) or
     (QEvent_type(Event) = QEventHoverMove) or
     (QEvent_type(Event) = QEventKeyPress) or
     (QEvent_type(Event) = QEventKeyRelease)) then
    Result := True;

  EndEventProcessing;
end;

function TQtWidget.getAcceptDropFiles: Boolean;
var
  Form: TCustomForm;
begin
  Result := False;
  Form := GetParentForm(LCLObject);
  if Assigned(Form) and (Form.HandleAllocated) then
    Result := TQtMainWindow(Form.Handle).getAcceptDropFiles;
end;

procedure TQtWidget.SetNoMousePropagation(Sender: QWidgetH;
  const ANoMousePropagation: Boolean);
begin
  QWidget_setAttribute(Sender, QtWA_NoMousePropagation, ANoMousePropagation);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotShow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotShow(vShow: Boolean); cdecl;
var
  Msg: TLMShowWindow;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotShow Name', LCLObject.Name, ' vShow: ', dbgs(vShow));
  {$endif}

  {do not pass message to LCL if LCL setted up control visibility}
  if inUpdate then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SHOWWINDOW;
  Msg.Show := vShow;

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Close
  Params:  None
  Returns: Nothing

  Note: LCL uses LM_CLOSEQUERY to set the form visibility and if we don�t send this
 message, you won�t be able to show a form twice.
 ------------------------------------------------------------------------------}
function TQtWidget.SlotClose: Boolean; cdecl;
var
  Msg : TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotClose');
  {$endif}
  FillChar(Msg, SizeOf(Msg), 0);

  Msg.Msg := LM_CLOSEQUERY;

  DeliverMessage(Msg);
  
  Result := False;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotDestroy
  Params:  None
  Returns: Nothing

  Currently commented because it was raising exception on software exit
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotDestroy; cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotDestroy');
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_DESTROY;
  DeliverMessage(Msg);
  Release;
end;

function TQtWidget.slotDropFiles(Sender: QObjectH; Event: QEventH): Boolean;
var
  MimeData: QMimeDataH;
  QStrList: QStringListH;
  ByteArr: QByteArrayH;
  i: Integer;
  WStr: WideString;
  GotFiles: Boolean;
  FilesList: TStrings;
  Files: Array of String;
  ParentForm: TCustomForm;
begin
  Result := False;
  GotFiles := False;
  MimeData := QDropEvent_mimeData(QDropEventH(Event));
  QStrList := QStringList_create();
  try
    QMimeData_formats(MimeData, QStrList);
    for i := 0 to QStringList_size(QStrList) - 1 do
    begin
      QStringList_at(QStrList, @WStr, i);
      GotFiles := WStr = 'text/uri-list';
      if GotFiles then
        break;
    end;
  finally
    QStringList_destroy(QStrList);
  end;
  if not GotFiles then
    exit;
  ByteArr := QByteArray_create();
  try
    QMimeData_data(MimeData, ByteArr, @WStr);
    if not QByteArray_isNull(ByteArr) then
    begin
      WStr := '';
      for i := 0 to QByteArray_size(ByteArr) - 1 do
        WStr := WStr + QByteArray_at(ByteArr, i);
      FilesList := TStringList.Create;
      try
        FilesList.Text := UTF16ToUTF8(WStr);
        if (FilesList.Count > 0) and
          ( (FilesList[FilesList.Count-1] = #0)
            or
            (FilesList[FilesList.Count-1] = '') ) then
          SetLength(Files, FilesList.Count - 1)
        else
          SetLength(Files, FilesList.Count);
        for i := 0 to High(Files) do
        begin
          Files[i] := FilesList.Strings[i];
          if UTF8Pos('file://', Files[i]) <> 0 then
            UTF8Delete(Files[i], 1, 7);
        end;
      finally
        FilesList.Free;
      end;
      QDropEvent_setDropAction(QDropEventH(Event), QtCopyAction);
      QDropEvent_acceptProposedAction(QDropEventH(Event));

      Application.IntfDropFiles(Files);
      if ClassType = TQtMainWindow then
        TCustomForm(LCLObject).IntfDropFiles(Files)
      else
      begin
        ParentForm := GetParentForm(LCLObject);
        if Assigned(ParentForm) then
          ParentForm.IntfDropFiles(Files);
      end;

      Result := True;
    end;
  finally
    QByteArray_destroy(ByteArr);
  end;
end;

function TQtWidget.SlotHover(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  Msg: TLMessage;
  MouseMsg: TLMMouseMove absolute Msg;
  MousePos: TQtPoint;
begin
  Result := False;
  if not CanSendLCLMessage then
    Exit;

  if (QApplication_mouseButtons() = 0) and
     not QWidget_hasMouseTracking(QWidgetH(Sender)) then // in other case MouseMove will be hooked
  begin
    FillChar(Msg, SizeOf(Msg), #0);

    MousePos := QHoverEvent_pos(QHoverEventH(Event))^;
    OffsetMousePos(@MousePos);

    case QEvent_type(Event) of
      QEventHoverEnter: Msg.Msg := LM_MOUSEENTER;
      QEventHoverLeave: Msg.Msg := LM_MOUSELEAVE;
      QEventHoverMove:
        begin
          MouseMsg.Msg := LM_MOUSEMOVE;
          MouseMsg.XPos := SmallInt(MousePos.X);
          MouseMsg.YPos := SmallInt(MousePos.Y);
        end;
    end;
    NotifyApplicationUserInput(Msg.Msg);
    DeliverMessage(Msg);
    SetNoMousePropagation(QWidgetH(Sender), True);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotKey
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.SlotKey(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
const
  CN_KeyDownMsgs: array[Boolean] of UINT = (CN_KEYDOWN, CN_SYSKEYDOWN);
  CN_KeyUpMsgs: array[Boolean] of UINT = (CN_KEYUP, CN_SYSKEYUP);
  LM_KeyDownMsgs: array[Boolean] of UINT = (LM_KEYDOWN, LM_SYSKEYDOWN);
  LM_KeyUpMsgs: array[Boolean] of UINT = (LM_KEYUP, LM_SYSKEYUP);
  CN_CharMsg: array[Boolean] of UINT = (CN_CHAR, CN_SYSCHAR);
  LM_CharMsg: array[Boolean] of UINT = (LM_CHAR, LM_SYSCHAR);
var
  KeyMsg: TLMKey;
  CharMsg: TLMChar;
  Modifiers: QtKeyboardModifiers;
  IsSysKey: Boolean;
  Text: WideString;
  UTF8Text: String; // use to prevent 3 time convertion from WideString to utf8 string
  UTF8Char: TUTF8Char;
  ACharCode: Word;
  TheKey: Integer;
  AChar: Char;
  AKeyEvent: QKeyEventH;
begin
  {$ifdef VerboseQt}
    DebugLn('TQtWidget.SlotKey ', dbgsname(LCLObject));
  {$endif}

  Result := True;

  if not CanSendLCLMessage then
    exit;

  FillChar(KeyMsg, SizeOf(KeyMsg), #0);
  FillChar(CharMsg, SizeOf(CharMsg), #0);
  UTF8Text := '';
  UTF8Char := '';
  AChar := #0;

  // Detects special keys (shift, alt, control, etc)
  Modifiers := QKeyEvent_modifiers(QKeyEventH(Event));
  IsSysKey := (QtAltModifier and Modifiers) <> $0;
  KeyMsg.KeyData := QtKeyModifiersToKeyState(Modifiers);

  {$ifdef windows}
    ACharCode := QKeyEvent_nativeVirtualKey(QKeyEventH(Event));
    KeyMsg.CharCode := ACharCode;
  // todo: VK to Win_VK for other os too
    //WriteLn(QKeyEvent_nativeVirtualKey(QKeyEventH(Event)));
    //WriteLn(QKeyEvent_nativeScanCode(QKeyEventH(Event)));
  {$endif}

  // Loads the UTF-8 character associated with the keypress, if any
  QKeyEvent_text(QKeyEventH(Event), @Text);

  {$note TQtWidget.SlotKey: this is workaround for Qt bug which reports
   wrong keys with Shift+Ctrl pressed. Fixes #13450.
   LAST REVISION: Qt-4.5.2 git snapshot 20090607. zeljko}
  if (Modifiers = QtShiftModifier or QtControlModifier) then
  begin
    TheKey := QKeyEvent_key(QKeyEventH(Event));
    if (length(Text) = 1) and (TheKey in [33..41,61]) then
    begin
      if TheKey = 61 then
        TheKey := 32;
      ACharCode := QtKeyToLCLKey( TheKey + 16, Text);
      KeyMsg.CharCode := ACharCode;
      Text := '';
    end;
  end;

  // Translates a Qt4 Key to a LCL VK_* key
  if KeyMsg.CharCode = 0 then
  begin
    ACharCode := QtKeyToLCLKey(QKeyEvent_key(QKeyEventH(Event)), Text);
    KeyMsg.CharCode := ACharCode;
  end;

  {------------------------------------------------------------------------------
   Sends the adequate key messages
   ------------------------------------------------------------------------------}
  case QEvent_type(Event) of
    QEventKeyPress: KeyMsg.Msg := CN_KeyDownMsgs[IsSysKey];
    QEventKeyRelease: KeyMsg.Msg := CN_KeyUpMsgs[IsSysKey];
  end;

  {$ifdef VerboseQt}
    WriteLn(' message: ', KeyMsg.Msg);
  {$endif}
  if KeyMsg.CharCode <> VK_UNKNOWN then
  begin
    NotifyApplicationUserInput(KeyMsg.Msg);
    if (DeliverMessage(KeyMsg) <> 0) or (KeyMsg.CharCode=VK_UNKNOWN) then
    begin
  {$ifdef VerboseQt}
      WriteLn('handled!');
  {$endif}
      Exit;
    end;

    // here we should let widgetset to handle key
    //...

    case QEvent_type(Event) of
      QEventKeyPress: KeyMsg.Msg := LM_KeyDownMsgs[IsSysKey];
      QEventKeyRelease: KeyMsg.Msg := LM_KeyUpMsgs[IsSysKey];
    end;
  {$ifdef VerboseQt}
    WriteLn(' message: ', KeyMsg.Msg);
  {$endif}
    NotifyApplicationUserInput(KeyMsg.Msg);
    if (DeliverMessage(KeyMsg) <> 0) or (KeyMsg.CharCode=VK_UNKNOWN) then
    begin
      // the LCL handled the key
  {$ifdef VerboseQt}
      WriteLn('handled!');
  {$endif}
      Result := KeyMsg.CharCode=VK_UNKNOWN;
      Exit;
    end;
  end;
  { Also sends a utf-8 key event for key down }

  if (QEvent_type(Event) = QEventKeyPress) and (Length(Text) <> 0) then
  begin
    UTF8Text := UTF16ToUTF8(Text);
    UTF8Char := UTF8Text;
  {$ifdef VerboseQt}
    WriteLn('sending char ', UTF8Char);
  {$endif}
    if LCLObject.IntfUTF8KeyPress(UTF8Char, 1, IsSysKey) then
    begin
      // the LCL has handled the key
  {$ifdef VerboseQt}
      WriteLn('handled!');
  {$endif}
      Exit;
    end;

    // create the CN_CHAR / CN_SYSCHAR message
    FillChar(CharMsg, SizeOf(CharMsg), 0);
    CharMsg.Msg := CN_CharMsg[IsSysKey];
    CharMsg.KeyData := KeyMsg.KeyData;
    AChar := Text[1];
    CharMsg.CharCode := Word(AChar);

    //Send message to LCL
  {$ifdef VerboseQt}
    WriteLn(' message: ', CharMsg.Msg);
  {$endif}
    NotifyApplicationUserInput(CharMsg.Msg);
    if (DeliverMessage(CharMsg) <> 0) or (CharMsg.CharCode = VK_UNKNOWN) then
    begin
      // the LCL has handled the key
  {$ifdef VerboseQt}
      WriteLn('handled!');
  {$endif}
      Exit;
    end;

    //Here is where we (interface) can do something with the key
    //...

    //Send a LM_(SYS)CHAR
    CharMsg.Msg := LM_CharMsg[IsSysKey];

  {$ifdef VerboseQt}
    WriteLn(' message: ', CharMsg.Msg);
  {$endif}
    NotifyApplicationUserInput(CharMsg.Msg);
    DeliverMessage(CharMsg);
  end;
  
  // check if data was changed during key handling
  if (KeyMsg.CharCode <> ACharCode) or (UTF8Char <> UTF8Text) or (Word(AChar) <> CharMsg.CharCode) then
  begin
    // data was changed
    if UTF8Char <> UTF8Text then
      Text := UTF8ToUTF16(Utf8Char)
    else
    if Word(AChar) <> CharMsg.CharCode then
      Text := Char(CharMsg.CharCode);
    AKeyEvent := QKeyEvent_createExtendedKeyEvent(
      QEvent_type(Event),
      LCLKeyToQtKey(KeyMsg.CharCode),
      Modifiers,
      0,
      KeyMsg.CharCode,
      0,
      @Text,
      QKeyEvent_isAutoRepeat(QKeyEventH(Event)),
      QKeyEvent_count(QKeyEventH(Event))
      );
    try
      QCoreApplication_sendEvent(Sender, AKeyEvent);
    finally
      QKeyEvent_destroy(AKeyEvent);
    end;
  end else
  begin
    Result := KeyMsg.CharCode in KeysToEat;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotMouse
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.SlotMouse(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
const
  // array of clickcount x buttontype
  MSGKIND: array[0..2, 1..4] of Integer =
  (
    (LM_LBUTTONDOWN, LM_LBUTTONDBLCLK, LM_LBUTTONTRIPLECLK, LM_LBUTTONQUADCLK),
    (LM_RBUTTONDOWN, LM_RBUTTONDBLCLK, LM_RBUTTONTRIPLECLK, LM_RBUTTONQUADCLK),
    (LM_MBUTTONDOWN, LM_MBUTTONDBLCLK, LM_MBUTTONTRIPLECLK, LM_MBUTTONQUADCLK)
  );
var
  Msg: TLMMouse;
  MousePos: TQtPoint;
  MButton: QTMouseButton;
  Modifiers: QtKeyboardModifiers;

  function CheckMouseButtonDown(AButton: Integer): Cardinal;

    function LastClickInSameWidget: boolean;
    begin
      Result := (LastMouse.Widget <> nil) and
                (LastMouse.Widget = Sender);
    end;

    function LastClickAtSamePosition: boolean;
    begin
      Result:= (Abs(MousePos.X-LastMouse.MousePos.X) <= DblClickThreshold) and
               (Abs(MousePos.Y-LastMouse.MousePos.Y) <= DblClickThreshold);
    end;

    function LastClickInTime: boolean;
    begin
      Result:=((now - LastMouse.TheTime) <= ((1/86400)*(QApplication_doubleClickInterval/1000)));
    end;

    function TestIfMultiClick: boolean;
    begin
      Result:= LastClickInSameWidget and
               LastClickAtSamePosition and
               LastClickInTime;
    end;

  var
    IsMultiClick: boolean;
  begin
    Result := LM_NULL;

    IsMultiClick := TestIfMultiClick;

    if QEvent_type(Event) = QEventMouseButtonDblClick then
    begin
      // the qt itself has detected a double click
      if (LastMouse.ClickCount >= 2) and IsMultiClick then
        // the double click was already detected and sent to the LCL
        // -> skip this message
        exit
      else
        LastMouse.ClickCount := 2;
    end
    else
    begin
      inc(LastMouse.ClickCount);

      if (LastMouse.ClickCount <= 4) and IsMultiClick then
      begin
        // multi click
      end else
      begin
        // normal click
        LastMouse.ClickCount:=1;
      end;
    end;

    LastMouse.TheTime := Now;
    LastMouse.MousePos := MousePos;
    LastMouse.Widget := Sender;

    Result := MSGKIND[AButton][LastMouse.ClickCount];
  end;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotMouse');
  {$endif}

  Result := False; // allow qt to handle message

  if not CanSendLCLMessage then
    exit;

  if (LCLObject <> nil) and
    (not (csDesigning in LCLObject.ComponentState) and not getEnabled) then
    Exit;

  // idea of multi click implementation is taken from gtk

  FillChar(Msg, SizeOf(Msg), #0);
  
  MousePos := QMouseEvent_pos(QMouseEventH(Event))^;
  OffsetMousePos(@MousePos);

  Modifiers := QInputEvent_modifiers(QInputEventH(Event));
  Msg.Keys := QtKeyModifiersToKeyState(Modifiers);

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);
  
  MButton := QMouseEvent_Button(QMouseEventH(Event));

  case QEvent_type(Event) of
    QEventMouseButtonPress, QEventMouseButtonDblClick:
    begin
      Msg.Keys := Msg.Keys or QtButtonsToLCLButtons(MButton);
      case MButton of
        QtLeftButton: Msg.Msg := CheckMouseButtonDown(0);
        QtRightButton: Msg.Msg := CheckMouseButtonDown(1);
        QtMidButton: Msg.Msg := CheckMouseButtonDown(2);
      end;
      NotifyApplicationUserInput(Msg.Msg);
      DeliverMessage(Msg);
      SetNoMousePropagation(QWidgetH(Sender), True);
    end;
    QEventMouseButtonRelease:
    begin
      LastMouse.Widget := Sender;
      LastMouse.MousePos := MousePos;
      Msg.Keys := Msg.Keys or QtButtonsToLCLButtons(MButton);
      case MButton of
        QtLeftButton: Msg.Msg := LM_LBUTTONUP;
        QtRightButton: Msg.Msg := LM_RBUTTONUP;
        QtMidButton: Msg.Msg := LM_MBUTTONUP;
      end;

      NotifyApplicationUserInput(Msg.Msg);
      DeliverMessage(Msg);
      SetNoMousePropagation(QWidgetH(Sender), True);

      { Clicking on buttons operates differently, because QEventMouseButtonRelease
        is sent if you click a control, drag the mouse out of it and release, but
        buttons should not be clicked on this case. }
      if not (LCLObject is TCustomButton) then
      begin
        Msg.Msg := LM_CLICKED;
        DeliverMessage(Msg);
      end;
    end;
  end;
end;

procedure TQtWidget.SlotNCMouse(Sender: QObjectH; Event: QEventH); cdecl;
var
  AHeader: TRect;
  APoint: TQtPoint;
begin
  //Drag&Dock support TCustomForm => Start BeginDrag()
  if (LCLObject is TCustomForm) and 
     not (csDesigning in LCLObject.ComponentState) and
     (TWinControlAccess(LCLObject).DragKind = dkDock) and
     (TWinControlAccess(LCLObject).DragMode = dmAutomatic) and
     (QMouseEvent_button(QMouseEventH(Event)) = QtLeftButton) then
  begin
    APoint := QMouseEvent_globalPos(QMouseEventH(Event))^;
    AHeader := getGeometry;
    with getFrameGeometry do
      AHeader.Top := Top;

    // remove various buttons from header (how to request their pos cross platform?):
    Inc(AHeader.Left, 20);  // system menu
    Dec(AHeader.Right, 80); // close, min, max buttons
    if AHeader.Right < AHeader.Left then
      AHeader.Right := AHeader.Left + 1;

    // we can skip translation of coords to global since we already working with window
    // check for title
    if PtInRect(AHeader, Point(APoint.x, APoint.y)) then
      LCLObject.BeginDrag(true);
  end;
end;

function TQtWidget.SlotMouseEnter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  Msg: TLMessage;
begin
  Result := False;
  FillChar(Msg, SizeOf(Msg), #0);
  case QEvent_type(Event) of
    QEventEnter: Msg.Msg := LM_MOUSEENTER;
    QEventLeave: Msg.Msg := LM_MOUSELEAVE;
  end;
  DeliverMessage(Msg);
end;

function TQtWidget.QtButtonsToLCLButtons(AButtons: QtMouseButton): PtrInt;
begin
  Result := 0;
  if (QtLeftButton and AButtons) <> 0 then
    Result := Result or MK_LBUTTON;

  if (QtRightButton and AButtons) <> 0 then
    Result := Result or MK_RBUTTON;

  if (QtMidButton and AButtons) <> 0 then
    Result := Result or MK_MBUTTON;

  if (QtXButton1 and AButtons) <> 0 then
    Result := Result or MK_XBUTTON1;
    
  if (QtXButton2 and AButtons) <> 0 then
    Result := Result or MK_XBUTTON2;
end;

function TQtWidget.QtKeyModifiersToKeyState(AModifiers: QtKeyboardModifiers): PtrInt;
begin
  Result := 0;
  if AModifiers and qtShiftModifier <> 0 then
    Result := Result or MK_SHIFT;
  if AModifiers and qtControlModifier <> 0 then
    Result := Result or MK_CONTROL;
  if AModifiers and qtAltModifier <> 0 then
    Result := Result or $20000000;
  { TODO: add support for ALT, META and NUMKEYPAD }
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotMouseMove
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.SlotMouseMove(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  Msg: TLMMouseMove;
  MousePos: TQtPoint;
  GlobPos: TQtPoint;
  R: TRect;
  P: TPoint;
  NewEvent: QEventH;
  W: QWidgetH;
  FrameBorder: Integer;
  TitleBarHeight: Integer;
begin
  Result := False;
  if not CanSendLCLMessage then
    Exit;

  if not (csCaptureMouse in LCLObject.ControlStyle) and
    not QWidget_isWindow(Widget) and
    not DragManager.IsDragging then
  begin
    MousePos := QMouseEvent_pos(QMouseEventH(Event))^;
    GlobPos := QMouseEvent_globalPos(QMouseEventH(Event))^;

    // get parent form, so check if mouse is out of parent form first.
    W := QWidget_window(Widget);

    if W <> nil then
    begin
      QWidget_frameGeometry(W, @R);

      // exclude borders from frame
      FrameBorder := QStyle_pixelMetric(QApplication_style(),
        QStylePM_DefaultFrameWidth, nil, W);
      TitleBarHeight := QStyle_pixelMetric(QApplication_style(),
        QStylePM_TitleBarHeight, nil, W);

      inc(R.Left, FrameBorder);
      inc(R.Top, TitleBarHeight);
      dec(R.Right, FrameBorder);
      dec(R.Bottom, FrameBorder);

      P := Point(GlobPos.X, GlobPos.Y);
      if not PtInRect(R, P) then
        MousePos := QtPoint(-1, -1);

      if not QWidget_underMouse(Widget) then
      begin
        if (MousePos.X >= 0) and (MousePos.Y >= 0) then
        begin
          QWidget_setAttribute(Widget, QtWA_UnderMouse, True);
          NewEvent := QEvent_create(QEventEnter);
          QCoreApplication_postEvent(Widget, NewEvent, 100);
        end;
      end;
    end;

    if not (csCaptureMouse in LCLObject.ControlStyle) and
      (QApplication_mouseButtons() <> QtNoButton) and
      ((MousePos.X < 0) or (MousePos.Y < 0)) then
    begin
      if not QWidget_underMouse(Widget) then
        exit;
      setCursor(FDefaultCursor);
      NewEvent := QEvent_create(QEventLeave);
      QCoreApplication_postEvent(Widget, NewEvent, 100);
      exit;
    end;
  end;

  FillChar(Msg, SizeOf(Msg), #0);
  
  MousePos := QMouseEvent_pos(QMouseEventH(Event))^;
  OffsetMousePos(@MousePos);

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);
  
  Msg.Keys := QtButtonsToLCLButtons(QmouseEvent_Buttons(QMouseEventH(Event)))
    or QtKeyModifiersToKeyState(QInputEvent_modifiers(QInputEventH(Event)));

  Msg.Msg := LM_MOUSEMOVE;

  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);
  SetNoMousePropagation(QWidgetH(Sender), True);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotMouseWheel
  Params:  None
  Returns: Nothing

  Qt stores the delta in 1/8 of a degree
  Most mouses scroll 15 degrees each time
 
  Msg.WheelData: -1 for up, 1 for down
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotMouseWheel(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMMouseEvent;
  MousePos: TQtPoint;
  Modifiers: QtKeyboardModifiers;
  ModifierState: PtrInt;
begin
  if not CanSendLCLMessage then
    exit;

  if (LCLObject <> nil) and
    (not (csDesigning in LCLObject.ComponentState) and not getEnabled) then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);

  MousePos := QWheelEvent_Pos(QWheelEventH(Event))^;
  OffsetMousePos(@MousePos);

  Modifiers := QInputEvent_modifiers(QInputEventH(Event));
  Msg.State := [];
  ModifierState := QtKeyModifiersToKeyState(Modifiers);
  if (ModifierState and MK_SHIFT) <> 0 then
    Msg.State := [ssShift];
  if (ModifierState and MK_CONTROL) <> 0 then
    Msg.State := [ssCtrl] + Msg.State;
  if (ModifierState and $20000000) <> 0 then
    Msg.State := [ssAlt] + Msg.State;

  LastMouse.Widget := Sender;
  LastMouse.MousePos := MousePos;
  
  Msg.Msg := LM_MOUSEWHEEL;

  Msg.X := SmallInt(MousePos.X);
  Msg.Y := SmallInt(MousePos.Y);

  Msg.WheelDelta := QWheelEvent_delta(QWheelEventH(Event));

  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);

  {propagate mousewheel to parent if our sender is TPanel,
   fixes problem with mousewheel scroll with lazreport}
  if not (csDesigning in LCLObject.ComponentState) and
    (LCLObject is TPanel) and
    Assigned(LCLObject.Parent) then
      TQtWidget(LCLObject.Parent.Handle).DeliverMessage(Msg);
end;

procedure TQtWidget.SlotMove(Event: QEventH); cdecl;
var
  Msg: TLMMove;
  Pos: TQtPoint;
  FrameRect, WindowRect: TRect;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotMove');
  {$endif}

  if QtWidgetSet.IsWidgetAtCache(HWND(Self)) then
    QtWidgetSet.InvalidateWidgetAtCache;
  // do not loop with LCL
  if InUpdate then
    exit;

  if not QEvent_spontaneous(Event) or
    (not QEvent_spontaneous(Event) and
    ((Self is TQtMainWindow) and not
    TQtMainWindow(Self).IsMdiChild)) then
    Exit;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_MOVE;

  Msg.MoveType := Msg.MoveType or Move_SourceIsInterface;

  Pos := QMoveEvent_pos(QMoveEventH(Event))^;
  FrameRect := getFrameGeometry;
  WindowRect := getGeometry;

  Msg.XPos := Pos.x - (WindowRect.Left - FrameRect.Left);
  Msg.YPos := Pos.y - (WindowRect.Top - FrameRect.Top);

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotPaintBg
  Params:  None
  Returns: Nothing.

  Paints widget background.
  Only for classes which have HasPaint=False and AutoFillBackground=False
  and solid color different to default one (eg. clBtnFace for buttons).
  Current allowed classes are: All TQtCheckBox,TQtRadioButton,
  TQtPushButton (X11 only), TQtStaticText and TQtGroupBox.
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotPaintBg(Sender: QObjectH; Event: QEventH); cdecl;
var
  Painter: QPainterH;
  Brush: QBrushH;
  Color: TQColor;
  R: TRect;
begin
  if LCLObject.Color = clDefault then
    Color := Palette.DefaultColor
  else
    ColorRefToTQColor(ColorToRGB(LCLObject.Color), Color);
  Painter := QPainter_create(QWidget_to_QPaintDevice(Widget));
  Brush := QBrush_create(@Color, QtSolidPattern);
  try
    QPaintEvent_rect(QPaintEventH(Event), @R);
    QPainter_fillRect(Painter, @R, Brush);
    QPainter_end(Painter);
  finally
    QBrush_destroy(Brush);
    QPainter_destroy(Painter);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotPaint
  Params:  None
  Returns: Nothing

  Sends a LM_PAINT message to the LCL. This is for windowed controls only
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotPaint(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMPaint;
  AStruct: PPaintStruct;
  P: TPoint;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotPaint ', dbgsName(LCLObject));
  {$endif}
  if CanSendLCLMessage and (LCLObject is TWinControl) then
  begin
    FillChar(Msg, SizeOf(Msg), #0);

    Msg.Msg := LM_PAINT;
    New(AStruct);
    FillChar(AStruct^, SizeOf(TPaintStruct), 0);
    Msg.PaintStruct := AStruct;

    with PaintData do
    begin
      PaintWidget := QWidgetH(Sender);
      ClipRegion := QPaintEvent_Region(QPaintEventH(Event));
      if ClipRect = nil then
        New(ClipRect);
      QPaintEvent_Rect(QPaintEventH(Event), ClipRect);
    end;

    Msg.DC := BeginPaint(THandle(Self), AStruct^);
    FContext := Msg.DC;
    
    Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
    Msg.PaintStruct^.hdc := FContext;

    P := getClientOffset;
    inc(P.X, FScrollX);
    inc(P.Y, FScrollY);
    TQtDeviceContext(Msg.DC).translate(P.X, P.Y);

    // send paint message
    try
      // Saving clip rect and clip region
      try
        LCLObject.WindowProc(TLMessage(Msg));
        if HasCaret then
        begin
          if GlobalCaretDirty then
            QtCaret.ShowCaret(Self);
          QtCaret.DrawCaret;
        end;
      finally
        Dispose(PaintData.ClipRect);
        Fillchar(FPaintData, SizeOf(FPaintData), 0);
        FContext := 0;
        EndPaint(THandle(Self), AStruct^);
        Dispose(AStruct);
      end;
    except
      Application.HandleException(nil);
    end;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotResize
  Params:  None
  Returns: Nothing

  Sends a LM_SIZE message to the LCL.
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotResize(Event: QEventH); cdecl;
var
  Msg: TLMSize;
  NewSize: TSize;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotResize');
  {$endif}

  if QtWidgetSet.IsWidgetAtCache(HWND(Self)) then
    QtWidgetSet.InvalidateWidgetAtCache;

  // return size w/o frame
  NewSize := QResizeEvent_size(QResizeEventH(Event))^;
{
  WriteLn('SlotResize: ', dbgsName(LCLObject),
    ' AOldWidth = ', LCLObject.Width, ' AOldHeight = ', LCLObject.Height,
    ' ANewWidth = ', NewSize.cx, ' ANewHeight = ', NewSize.cy
  );
}
  if not Assigned(LCLObject) then exit;

  // do not loop with LCL but do not apply it to TQtMainWindow !
  if not (csDesigning in LCLObject.ComponentState) then
    if not (ClassType = TQtMainWindow) and InUpdate then
      exit;
  
  if (NewSize.cx <> LCLObject.Width) or (NewSize.cy <> LCLObject.Height) or
     (LCLObject.ClientRectNeedsInterfaceUpdate) then
  begin
    LCLObject.DoAdjustClientRectChange;
  end;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SIZE;

  case getWindowState of
    QtWindowMinimized: Msg.SizeType := SIZEICONIC;
    QtWindowMaximized: Msg.SizeType := SIZEFULLSCREEN;
    QtWindowFullScreen: Msg.SizeType := SIZEFULLSCREEN;
  else
    Msg.SizeType := SIZENORMAL;
  end;

  Msg.SizeType := Msg.SizeType or Size_SourceIsInterface;

  Msg.Width := NewSize.cx;
  Msg.Height := NewSize.cy;

  DeliverMessage(Msg);
end;

function TQtWidget.SlotContextMenu(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  Msg: TLMContextMenu;
  MousePos: TQtPoint;

  procedure SendMouseReleaseEventToSelf;
  var
    AEvent: QEventH;
    Modifiers: QtKeyboardModifiers;
  begin
    Modifiers := QInputEvent_modifiers(QInputEventH(Event));
    AEvent := QMouseEvent_create(QEventMouseButtonRelease,
      QContextMenuEvent_pos(QContextMenuEventH(Event)),
      QContextMenuEvent_globalPos(QContextMenuEventH(Event)),
      QtRightButton,
      QtRightButton,
      Modifiers);
    QCoreApplication_postEvent(Widget, AEvent, 1);
  end;

begin
  if not CanSendLCLMessage then
    Exit(False);

  FillChar(Msg, SizeOf(Msg), #0);
  MousePos := QContextMenuEvent_globalPos(QContextMenuEventH(Event))^;

  Msg.Msg := LM_CONTEXTMENU;
  Msg.hWnd := HWND(Self);
  if QContextMenuEvent_reason(QContextMenuEventH(Event)) = QContextMenuEventKeyboard then
  begin
    Msg.XPos := -1;
    Msg.YPos := -1;
  end
  else
  begin
    Msg.XPos := SmallInt(MousePos.X);
    Msg.YPos := SmallInt(MousePos.Y);
  end;

  Result := DeliverMessage(Msg) <> 0;

  if Result then
    QEvent_accept(Event)
  else
  begin
    if Assigned(LCLObject.PopupMenu) then
      QEvent_ignore(Event);
    SetNoMousePropagation(QWidgetH(Sender), False);
  end;

  if Result and (csDesigning in LCLObject.ComponentState) then
    SendMouseReleaseEventToSelf;
end;

procedure TQtWidget.SlotWhatsThis(Sender: QObjectH; Event: QEventH); cdecl;
var
  Data: THelpInfo;
begin
  if not CanSendLCLMessage then
    exit;
  Data.cbSize := SizeOf(Data);
  Data.iContextType := HELPINFO_WINDOW;
  Data.iCtrlId := 0;
  Data.hItemHandle := THandle(Sender);
  Data.dwContextId := 0;
  with QHelpEvent_globalPos(QHelpEventH(Event))^ do
    Data.MousePos := Point(X, Y);
  Application.HelpCommand(0, PtrInt(@Data));
end;

procedure TQtWidget.SlotLCLMessage(Sender: QObjectH; Event: QEventH); cdecl;
var
  MessageEvent: QLCLMessageEventH absolute Event;
  Msg: TLMessage;
begin
  Msg.msg := QLCLMessageEvent_getMsg(MessageEvent);
  Msg.wParam := QLCLMessageEvent_getWParam(MessageEvent);
  Msg.lParam := QLCLMessageEvent_getLParam(MessageEvent);
  Msg.Result := 0;
  QLCLMessageEvent_setMsgResult(MessageEvent, DeliverMessage(Msg));
end;

procedure TQtWidget.Activate;
begin
  QWidget_activateWindow(Widget);
end;

procedure TQtWidget.BringToFront;
begin
  Activate;
  raiseWidget;
end;

procedure TQtWidget.clearMask;
begin
  QWidget_clearMask(Widget);
end;

procedure TQtWidget.OffsetMousePos(APoint: PQtPoint);
begin
  with getClientOffset do
  begin
    dec(APoint^.x, x);
    dec(APoint^.y, y);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SetColor
  Params:  QColorH
  Returns: Nothing

  Changes the color of a widget
 ------------------------------------------------------------------------------}
procedure TQtWidget.SetColor(const Value: PQColor);
begin
  Palette.setColor(Value);
end;

function TQtWidget.getContextMenuPolicy: QtContextMenuPolicy;
begin
  Result := QWidget_contextMenuPolicy(Widget);
end;

procedure TQtWidget.setContextMenuPolicy(const AValue: QtContextMenuPolicy);
begin
  QWidget_setContextMenuPolicy(Widget, AValue);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SetTextColor
  Params:  QColorH
  Returns: Nothing

  Changes the text color of a widget
 ------------------------------------------------------------------------------}
procedure TQtWidget.SetTextColor(const Value: PQColor);
begin
  Palette.setTextColor(Value);
end;

procedure TQtWidget.SetCursor(const ACursor: QCursorH);
begin
  {$IFDEF DARWIN}
  if not QWidget_isVisible(Widget) then
    exit;
  {$ENDIF}
  if ACursor <> nil then
    QWidget_setCursor(Widget, ACursor)
  else
    QWidget_setCursor(Widget, FDefaultCursor);
end;

procedure TQtWidget.setDefaultColorRoles;
begin
  FWidgetColorRole := QPaletteWindow;
  FTextColorRole := QPaletteWindowText;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Update
  Params:  None
  Returns: Nothing

  Schedules a paint event for processing when Qt returns to the main event loop
 ------------------------------------------------------------------------------}
procedure TQtWidget.Update(ARect: PRect = nil);
begin
  if ARect <> nil then
    QWidget_update(Widget, ARect)
  else
    QWidget_update(Widget);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Repaint
  Params:  None
  Returns: Nothing

  Repaints the control imediately
 ------------------------------------------------------------------------------}
procedure TQtWidget.Repaint(ARect: PRect = nil);
begin
  if ARect <> nil then
    QWidget_repaint(Widget, ARect)
  else
    QWidget_repaint(Widget);
end;

procedure TQtWidget.setWindowTitle(Str: PWideString);
begin
  QWidget_setWindowTitle(Widget, Str);
end;

procedure TQtWidget.WindowTitle(Str: PWideString);
begin
  QWidget_WindowTitle(Widget, Str);
end;

procedure TQtWidget.Hide;
begin
  QWidget_hide(Widget);
end;

procedure TQtWidget.Show;
begin
  QWidget_show(Widget);
end;

procedure TQtWidget.ShowNormal;
begin
  QWidget_showNormal(Widget);
end;

procedure TQtWidget.ShowMinimized;
begin
  QWidget_showMinimized(Widget);
end;

procedure TQtWidget.ShowMaximized;
begin
  QWidget_showMaximized(Widget);
end;

function TQtWidget.getActionByIndex(AIndex: Integer): QActionH;
var
  ActionList: TPtrIntArray;
begin
  QWidget_actions(Widget, @ActionList);
  if (AIndex > 0) and (AIndex < Length(ActionList)) then
    Result := QActionH(ActionList[AIndex])
  else
    Result := nil;
end;

function TQtWidget.getAutoFillBackground: Boolean;
begin
  Result := QWidget_autoFillBackground(Widget);
end;

function TQtWidget.getEnabled: Boolean;
begin
  if Widget = nil then
    exit(False);
  Result := QWidget_isEnabled(Widget);
end;

function TQtWidget.getFont: QFontH;
begin
  Result := QWidget_font(Widget);
end;

function TQtWidget.getFocusPolicy: QtFocusPolicy;
begin
  Result := QWidget_focusPolicy(Widget);
end;

function TQtWidget.getFrameGeometry: TRect;
begin
  QWidget_frameGeometry(Widget, @Result);
end;

function TQtWidget.getGeometry: TRect;
begin
  QWidget_geometry(Widget, @Result);
end;

function TQtWidget.getLayoutDirection: QtLayoutDirection;
begin
  Result := QWidget_layoutDirection(Widget);
end;

function TQtWidget.getVisible: boolean;
begin
  if Widget = nil then
    exit(False);
  Result := QWidget_isVisible(Widget);
end;

function TQtWidget.getVisibleTo(AWidget: QWidgetH): Boolean;
begin
  if Widget = nil then
    exit(False);
  Result := QWidget_isVisibleTo(Widget, AWidget);
end;

function TQtWidget.getOwner: TQtWidget;
begin
  Result := FOwner;
end;

function TQtWidget.getParent: QWidgetH;
begin
  Result := QWidget_parentWidget(Widget);
end;

function TQtWidget.getPos: TQtPoint;
begin
  QWidget_pos(Widget, @Result);
end;

function TQtWidget.getFrameSize: TSize;
begin
  QWidget_frameSize(Widget, @Result);
end;

function TQtWidget.getSize: TSize;
begin
  QWidget_size(Widget, @Result);
end;

function TQtWidget.getText: WideString;
begin
  Result := FText;
end;

function TQtWidget.getTextStatic: Boolean;
begin
  Result := True;
end;

function TQtWidget.getHeight: Integer;
begin
  Result := QWidget_height(Widget);
end;

function TQtWidget.getUpdatesEnabled: Boolean;
begin
  Result := QWidget_updatesEnabled(Widget);
end;

function TQtWidget.getWidth: Integer;
begin
  Result := QWidget_width(Widget);
end;

function TQtWidget.getWindow: TQtWidget;
var
  W: QWidgetH;
begin
  Result := nil;
  W := QWidget_window(Widget);
  if W <> nil then
    Result := TQtWidget(HwndFromWidgetH(W));
end;

function TQtWidget.getWindowState: QtWindowStates;
begin
  Result := QWidget_windowState(Widget);
end;

function TQtWidget.getClientBounds: TRect;
begin
  QWidget_contentsRect(getContainerWidget, @Result);
end;

function TQtWidget.getClientOffset: TPoint;
var
  P: TQtPoint;
  R: TRect;
begin
  // we need an offset of container inside widget, but if container = widget then
  // offset = 0
  if Widget <> GetContainerWidget then
    QWidget_pos(GetContainerWidget, @P)
  else
    P := QtPoint(0, 0);
  R := getClientBounds;
  Result := Point(P.x + R.Left, P.y + R.Top);
end;

procedure TQtWidget.grabMouse;
begin
  //DumpStack;
  //DebugLn(['current grab is: ', dbgs(QWidget_mouseGrabber())]);
  //DebugLn(['grab mouse for: ', dbgsName(LCLObject), ' : ', dbgs(Widget)]);
  QWidget_grabMouse(Widget);
end;

function TQtWidget.hasFocus: Boolean;
begin
  Result := QWidget_hasFocus(Widget);
end;

function TQtWidget.IsActiveWindow: Boolean;
begin
  Result := QWidget_isActiveWindow(Widget);
end;

function TQtWidget.isMinimized: Boolean;
begin
  Result := QWidget_isMinimized(Widget);
end;

function TQtWidget.isMaximized: Boolean;
begin
  Result := QWidget_isMaximized(Widget);
end;

function TQtWidget.IsWindow: Boolean;
begin
  Result := QWidget_isWindow(Widget);
end;

procedure TQtWidget.lowerWidget;
begin
  QWidget_lower(Widget);
end;

procedure TQtWidget.move(ANewLeft, ANewTop: Integer);
begin
  QWidget_move(Widget, ANewLeft, ANewTop);
end;

procedure TQtWidget.preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
var
  PrefSize: TSize;
begin
  sizeHint(@PrefSize);
  if (PrefSize.cx >= 0) and (PrefSize.cy >=0) then
  begin
    PreferredWidth := PrefSize.cx;
    PreferredHeight := PrefSize.cy;
  end;
end;

procedure TQtWidget.raiseWidget;
begin
  QWidget_raise(Widget);
end;

procedure TQtWidget.stackUnder(AWidget: QWidgetH);
begin
  QWidget_stackUnder(Widget, AWidget);
end;

procedure TQtWidget.frame_resize(ANewWidth, ANewHeight: Integer);
var
  R1, R2: TRect;
  dw, dh: integer;
begin
  R1 := getGeometry;
  R2 := getFrameGeometry;
  dw := (R1.Left - R2.Left) + (R2.Right - R1.Right);
  dh := (R1.Top - R2.Top) + (R2.Bottom - R1.Bottom);
  QWidget_resize(Widget, ANewWidth - dw, ANewHeight - dh);
end;

procedure TQtWidget.resize(ANewWidth, ANewHeight: Integer);
begin
{
  WriteLn('Resize: ', dbgsName(LCLObject),
    ' AOldWidth = ', LCLObject.Width, ' AOldHeight = ', LCLObject.Height,
    ' ANewWidth = ', ANewWidth, ' ANewHeight = ', ANewHeight);
}
  QWidget_resize(Widget, ANewWidth, ANewHeight);
end;

procedure TQtWidget.releaseMouse;
var
  AGrabWidget: QWidgetH;
begin
  // capture widget can be one of childs of Widget if Widget is complex control
  // so better to look for current Capture widget to release it
  // instead of pass Widget as argument
  AGrabWidget := QWidget_mouseGrabber();
  //DebugLn(['releasing current grab: ', dbgs(AGrabWidget)]);
  if AGrabWidget <> nil then
    QWidget_releaseMouse(AGrabWidget);
end;

procedure TQtWidget.scroll(dx, dy: integer; ARect: PRect = nil);
begin
  if ARect = nil then
    QWidget_scroll(getContainerWidget, dx, dy)
  else
    QWidget_scroll(getContainerWidget, dx, dy, ARect);
end;

procedure TQtWidget.setAutoFillBackground(const AValue: Boolean);
begin
  QWidget_setAutoFillBackground(Widget, AValue);
end;

procedure TQtWidget.setAttribute(const Attr: QtWidgetAttribute;
  const TurnOn: Boolean);
begin
  QWidget_setAttribute(Widget, Attr, TurnOn);
end;

procedure TQtWidget.setBackgroundRole(const ARole: QPaletteColorRole);
begin
  QWidget_setBackgroundRole(Widget, ARole);
end;

procedure TQtWidget.setDefaultColor(const DefaultColorType: TDefaultColorType);
begin
  case DefaultColorType of
    dctBrush: setColor(@Palette.DefaultColor);
    dctFont: setTextColor(@Palette.DefaultTextColor);
  end;
end;

procedure TQtWidget.setEnabled(p1: Boolean);
begin
  if not p1 and (HWND(Self) = GetCapture) then
    ReleaseCapture;
  QWidget_setEnabled(Widget, p1);
end;

procedure TQtWidget.setFocus;
begin
  QWidget_setFocus(Widget);
end;

procedure TQtWidget.setFocusPolicy(const APolicy: QtFocusPolicy);
begin
  QWidget_setFocusPolicy(Widget, APolicy);
end;

procedure TQtWidget.setFocusProxy(const AWidget: QWidgetH);
begin
  QWidget_setFocusProxy(Widget, AWidget);
end;

procedure TQtWidget.setFont(AFont: QFontH);
begin
  QWidget_setFont(Widget, AFont);
end;

procedure TQtWidget.setGeometry(ARect: TRect);
begin
  QWidget_setGeometry(Widget, @ARect);
end;

procedure TQtWidget.setLayoutDirection(ADirection: QtLayoutDirection);
begin
  QWidget_setLayoutDirection(Widget, ADirection);
end;

procedure TQtWidget.setMaximumSize(AWidth, AHeight: Integer);
begin
  QWidget_setMaximumSize(Widget, AWidth, AHeight);
end;

procedure TQtWidget.setMask(AMask: QBitmapH);
begin
  QWidget_setMask(Widget, AMask);
end;

procedure TQtWidget.setMask(AMask: QRegionH);
begin
  QWidget_setMask(Widget, AMask);
end;

procedure TQtWidget.setMinimumSize(AWidth, AHeight: Integer);
begin
  QWidget_setMinimumSize(Widget, AWidth, AHeight);
end;

procedure TQtWidget.setVisible(AVisible: Boolean);
begin
  QWidget_setVisible(Widget, AVisible);
end;

function TQtWidget.windowModality: QtWindowModality;
begin
  Result := QWidget_windowModality(Widget);
end;

procedure TQtWidget.setWindowModality(windowModality: QtWindowModality);
begin
  QWidget_setWindowModality(Widget, windowModality);
end;

procedure TQtWidget.setWindowOpacity(opacity: double);
begin
  QWidget_setWindowOpacity(Widget, opacity);
end;

procedure TQtWidget.setParent(parent: QWidgetH);
begin
  QWidget_setParent(Widget, parent);
end;

procedure TQtWidget.setText(const W: WideString);
begin
  FText := W;
end;

procedure TQtWidget.setWindowFlags(_type: QtWindowFlags);
begin
  QWidget_setWindowFlags(Widget, _type);
end;

procedure TQtWidget.setWindowIcon(AIcon: QIconH);
var
  DestroyIcon: Boolean;
begin
  DestroyIcon := AIcon = nil;
  if DestroyIcon then
    AIcon := QIcon_create();
  QWidget_setWindowIcon(Widget, AIcon);
  if DestroyIcon then
    QIcon_destroy(AIcon);
end;

function TQtWidget.windowFlags: QtWindowFlags;
begin
  Result := QWidget_windowFlags(Widget);
end;

procedure TQtWidget.setWidth(p1: Integer);
var
  R: TRect;
begin
  R := getGeometry;
  R.Right := R.Left + p1;
  setGeometry(R);
end;

procedure TQtWidget.setHeight(p1: Integer);
var
  R: TRect;
begin
  R := getGeometry;
  R.Bottom := R.Top + p1;
  setGeometry(R);
end;

procedure TQtWidget.setUpdatesEnabled(const AEnabled: Boolean);
begin
  QWidget_setUpdatesEnabled(Widget, AEnabled);
end;

procedure TQtWidget.setWindowState(AState: QtWindowStates);
begin
  QWidget_setWindowState(Widget, AState);
end;

procedure TQtWidget.sizeHint(size: PSize);
begin
  QWidget_sizeHint(Widget, size);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.QtKeyToLCLKey
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.QtKeyToLCLKey(AKey: Integer; AText: WideString): Word;
begin
  // The big problem here with unicode keys
  // Example: for Russian letter A qt returns AKey = $0410 and this is
  // absolutely correct: 0400 - 04FF - is russian unicode space and
  // 0410 is defined as "CYRILLIC CAPITAL LETTER A"

  Result := VK_UNKNOWN;
  case AKey of
    QtKey_0..QtKey_9: Result := VK_0 + (AKey - QtKey_0);
    QtKey_At: Result := VK_2; // some bug, but Ctrl + Shit + 2 produce QtKey_At
    QtKey_Escape: Result := VK_ESCAPE;
    QtKey_Tab: Result := VK_TAB;
    QtKey_Backtab: Result := VK_TAB; // ???
    QtKey_Backspace: Result := VK_BACK;
    QtKey_Return: Result := VK_RETURN;
    QtKey_Enter: Result := VK_RETURN;
    QtKey_Insert: Result := VK_INSERT;
    QtKey_Delete: Result := VK_DELETE;
    QtKey_Pause: Result := VK_PAUSE;
    QtKey_Print: Result := VK_PRINT;
    QtKey_SysReq: Result := VK_UNKNOWN; // ???
    QtKey_Clear: Result := VK_CLEAR;
    QtKey_Home: Result := VK_HOME;
    QtKey_End: Result := VK_END;
    QtKey_Left: Result := VK_LEFT;
    QtKey_Up: Result := VK_UP;
    QtKey_Right: Result := VK_RIGHT;
    QtKey_Down: Result := VK_DOWN;
    QtKey_PageUp: Result := VK_PRIOR;
    QtKey_PageDown: Result := VK_NEXT;
    QtKey_Shift: Result := VK_SHIFT;     // There is also RSHIFT
    QtKey_Control: Result := VK_CONTROL; // There is also RCONTROL
    QtKey_Meta: Result := VK_UNKNOWN; // ???
    QtKey_Alt: Result := VK_MENU;
    QtKey_CapsLock: Result := VK_CAPITAL;
    QtKey_NumLock: Result := VK_NUMLOCK;
    QtKey_ScrollLock: Result := VK_SCROLL;
    QtKey_F1..QtKey_F24: Result := VK_F1 + (AKey - QtKey_F1);
    QtKey_F25..
    QtKey_F35: Result := VK_UNKNOWN;
    QtKey_Super_L: Result := VK_LWIN;
    QtKey_Super_R: Result := VK_RWIN;
    QtKey_Menu: Result := VK_APPS;
    QtKey_Hyper_L,
    QtKey_Hyper_R: Result := VK_UNKNOWN;
    QtKey_Help: Result := VK_HELP;
    QtKey_Direction_L,
    QtKey_Direction_R,
    QtKey_Exclam,QtKey_NumberSign..
    QtKey_AmperSand,
    QtKey_ParenLeft,
    QtKey_ParenRight: Result := VK_UNKNOWN;
    QtKey_Asterisk: Result := VK_MULTIPLY;
    QtKey_Plus: Result := VK_ADD;
    QtKey_Comma: Result := VK_SEPARATOR;
    QtKey_Minus: Result := VK_SUBTRACT;
    QtKey_Period: Result := VK_DECIMAL;
    QtKey_Slash: Result := VK_DIVIDE;
    QtKey_Equal: Result := VK_OEM_PLUS;

    QtKey_Colon,
    QtKey_Semicolon: Result := VK_OEM_1;
    QtKey_AsciiTilde: Result := VK_OEM_3;
    QtKey_BraceLeft,
    QtKey_BracketLeft: Result := VK_OEM_4;
    QtKey_BackSlash: Result := VK_OEM_5;
    QtKey_BraceRight,
    QtKey_BracketRight: Result := VK_OEM_6;
    QtKey_QuoteDbl,
    QtKey_Apostrophe: Result := VK_OEM_7;
    QtKey_Less: Result := VK_OEM_COMMA;
    QtKey_Greater: Result := VK_OEM_PERIOD;

    QtKey_ydiaeresis,
    QtKey_Multi_key..
    QtKey_No: Result := VK_UNKNOWN;
    QtKey_Cancel: Result := VK_CANCEL;
    QtKey_Printer: Result := VK_PRINT;
    QtKey_Execute: Result := VK_EXECUTE;
    QtKey_Sleep: Result := VK_SLEEP;
    QtKey_Play: Result := VK_PLAY;
    QtKey_Zoom: Result := VK_ZOOM;
    QtKey_Context1..
    QtKey_Flip,
    QtKey_unknown: Result := VK_UNKNOWN;
  else
    if AKey <= $FF then // Qt:AKey = VK_KEY in many cases
      Result := AKey
    else
    if AText <> '' then
    begin
      // use QChar to understand whether we have unicode letter or number here or no
      // then try to map that char to VK_ code
    end;
  end;
end;

procedure TQtWidget.SetLastCaretPos(const AValue: TQtPoint);
begin
  FLastCaretPos := AValue;
end;

procedure TQtWidget.SetHasCaret(const AValue: Boolean);
begin
  FHasCaret := AValue;
end;

class procedure TQtWidget.removeProperty(AObject: QObjectH; APropName: PAnsiChar);
var
  AVariant: QVariantH;
begin
  AVariant := QVariant_create(QVariantInvalid);
  QObject_setProperty(AObject, APropName, AVariant);
  QVariant_destroy(AVariant);
end;

class procedure TQtWidget.setProperty(AObject: QObjectH; APropName: PAnsiChar; APropValue: Int64);
var
  AVariant: QVariantH;
begin
  AVariant := QVariant_create(APropValue);
  QObject_setProperty(AObject, APropName, AVariant);
  QVariant_destroy(AVariant);
end;

function TQtWidget.LCLKeyToQtKey(AKey: Word): Integer;
const
  VKKeyToQtKeyMap: array[0..255] of Integer = // Keyboard mapping table
   (
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Cancel,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Backspace,
    QtKey_Tab,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Clear,
    QtKey_Return,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Shift,
    QtKey_Control,
    QtKey_Alt,
    QtKey_Pause,
    QtKey_CapsLock,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Escape,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Mode_switch,
    QtKey_Space,
    QtKey_PageUp,
    QtKey_PageDown,
    QtKey_End,
    QtKey_Home,
    QtKey_Left,
    QtKey_Up,
    QtKey_Right,
    QtKey_Down,
    QtKey_Select,
    QtKey_Printer,
    QtKey_Execute,
    QtKey_Print,
    QtKey_Insert,
    QtKey_Delete,
    QtKey_Help,
    QtKey_0,
    QtKey_1,
    QtKey_2,
    QtKey_3,
    QtKey_4,
    QtKey_5,
    QtKey_6,
    QtKey_7,
    QtKey_8,
    QtKey_9,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_A,
    QtKey_B,
    QtKey_C,
    QtKey_D,
    QtKey_E,
    QtKey_F,
    QtKey_G,
    QtKey_H,
    QtKey_I,
    QtKey_J,
    QtKey_K,
    QtKey_L,
    QtKey_M,
    QtKey_N,
    QtKey_O,
    QtKey_P,
    QtKey_Q,
    QtKey_R,
    QtKey_S,
    QtKey_T,
    QtKey_U,
    QtKey_V,
    QtKey_W,
    QtKey_X,
    QtKey_Y,
    QtKey_Z,
    QtKey_Meta,
    QtKey_Meta,
    QtKey_Menu,
    QtKey_unknown,
    QtKey_Sleep,
    QtKey_0,
    QtKey_1,
    QtKey_2,
    QtKey_3,
    QtKey_4,
    QtKey_5,
    QtKey_6,
    QtKey_7,
    QtKey_8,
    QtKey_9,
    QtKey_Asterisk,
    QtKey_Plus,
    QtKey_Comma,
    QtKey_Minus,
    QtKey_Period,
    QtKey_Slash,
    QtKey_F1,
    QtKey_F2,
    QtKey_F3,
    QtKey_F4,
    QtKey_F5,
    QtKey_F6,
    QtKey_F7,
    QtKey_F8,
    QtKey_F9,
    QtKey_F10,
    QtKey_F11,
    QtKey_F12,
    QtKey_F13,
    QtKey_F14,
    QtKey_F15,
    QtKey_F16,
    QtKey_F17,
    QtKey_F18,
    QtKey_F19,
    QtKey_F20,
    QtKey_F21,
    QtKey_F22,
    QtKey_F23,
    QtKey_F24,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_NumLock,
    QtKey_ScrollLock,
    QtKey_unknown,
    QtKey_Massyo,
    QtKey_Touroku,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Shift,
    QtKey_Shift,
    QtKey_Control,
    QtKey_Control,
    QtKey_Alt,
    QtKey_Alt,
    QtKey_Back,
    QtKey_Forward,
    QtKey_Refresh,
    QtKey_Stop,
    QtKey_Search,
    QtKey_Favorites,
    QtKey_HomePage,
    QtKey_VolumeMute,
    QtKey_VolumeDown,
    QtKey_VolumeUp,
    QtKey_MediaNext,
    QtKey_MediaPrevious,
    QtKey_MediaStop,
    QtKey_MediaPlay,
    QtKey_LaunchMail,
    QtKey_LaunchMedia,
    QtKey_Launch0,
    QtKey_Launch1,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Plus,
    QtKey_Comma,
    QtKey_Minus,
    QtKey_Period,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Play,
    QtKey_Zoom,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Clear,
    QtKey_unknown
   );
begin
  if AKey > 255 then
    Result := QtKey_unknown
  else
    Result := VKKeyToQtKeyMap[AKey];
end;

function TQtWidget.ShiftStateToQtModifiers(Shift: TShiftState): QtModifier;
begin
  Result := 0;
  if ssCtrl  in Shift then inc(Result, QtCTRL);
  if ssShift in Shift then Inc(Result, QtSHIFT);
  if ssMeta  in Shift then Inc(Result, QtMETA);
  if ssAlt   in Shift then Inc(Result, QtALT);
end;

{$IFDEF FPC_HAS_CONSTREF}
function TQtWidget.QueryInterface(constref iid: TGuid; out obj): LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
{$ELSE}
function TQtWidget.QueryInterface(const iid: tguid; out obj): longint; stdcall;
{$ENDIF}
begin
  if GetInterface(iid, obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

{$IFDEF FPC_HAS_CONSTREF}
function TQtWidget._AddRef: longint; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
{$ELSE}
function TQtWidget._AddRef: longint; stdcall;
{$ENDIF}
begin
  Result := -1; // no ref counting
end;

{$IFDEF FPC_HAS_CONSTREF}
function TQtWidget._Release: longint; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
{$ELSE}
function TQtWidget._Release: longint; stdcall;
{$ENDIF}
begin
  Result := -1;
end;

function TQtWidget.GetProps(const AnIndex: String): pointer;
var
  i: Integer;
begin
  if (Fprops<>nil) then
  begin
    i:=Fprops.IndexOf(AnIndex);
    if i>=0 then
    begin
      result:=Fprops.Objects[i];
      exit;
    end;
  end;
  result := nil;
end;

function TQtWidget.GetStyleSheet: WideString;
var
  WStr: WideString;
begin
  QWidget_styleSheet(Widget, @WStr);
  Result := UTF16ToUTF8(WStr);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.GetPalette
  Params:  Nothing
  Returns: TQtWidgetPalette

  Assigns default widget palette, also takes care of widget colors changing.
 ------------------------------------------------------------------------------}
function TQtWidget.GetPalette: TQtWidgetPalette;
begin
  if not Assigned(FPalette) then
  begin
    if (ClassType = TQtCustomControl) then
      FPalette := TQtWidgetPalette.Create(WidgetColorRole, TextColorRole,
        TQtCustomControl(Self).viewport.Widget)
    else
      FPalette := TQtWidgetPalette.Create(WidgetColorRole, TextColorRole, Widget);
  end;
  Result := FPalette;
end;

function TQtWidget.GetContext: HDC;
begin
  Result := FContext;
end;

function TQtWidget.GetWidget: QWidgetH;
begin
  if TheObject <> nil then
    Result := QWidgetH(TheObject)
  else
    Result := nil;
end;

function TQtWidget.DeliverMessage(var Msg): LRESULT;
begin
  Result := 0;
  if LCLObject = nil then
    Exit;
  try
    if LCLObject.HandleAllocated then
    begin
      LCLObject.WindowProc(TLMessage(Msg));
      Result := TLMessage(Msg).Result;
    end;
  except
    Application.HandleException(nil);
  end;
end;

procedure TQtWidget.SetProps(const AnIndex: String; const AValue: pointer);
var
  i: Integer;
begin
  if FProps=nil then
  begin
    FProps:=TStringList.Create;
    //FProps.CaseSensitive:=false;
    FProps.Sorted:=true;
  end;
  i := Fprops.IndexOf(AnIndex);
  if i < 0 then
    i := FProps.Add(AnIndex);
  Fprops.Objects[i] := TObject(AValue);
end;

procedure TQtWidget.SetStyleSheet(const AValue: WideString);
var
  WStr: WideString;
begin
  WStr := GetUTF8String(AValue);
  QWidget_setStyleSheet(Widget, @WStr);
end;

procedure TQtWidget.SetWidget(const AValue: QWidgetH);
begin
  TheObject := AValue;
end;

function TQtWidget.CreateWidget(const Params: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  FHasPaint := True;

  if Params.WndParent <> 0 then
    Parent := TQtWidget(Params.WndParent).GetContainerWidget
  else
    Parent := nil;

  Widget := QWidget_create(Parent);
  Result := Widget;
end;

procedure TQtWidget.DestroyWidget;
begin
  if (Widget <> nil) and FOwnWidget then
  begin
    if not FDeleteLater then
      QWidget_destroy(Widget)
    else
      QObject_deleteLater(Widget);
  end;
  Widget := nil;
end;

{ TQtAbstractButton }

procedure TQtAbstractButton.setIcon(AIcon: QIconH);
begin
  QAbstractButton_setIcon(QAbstractButtonH(Widget), AIcon);
end;

procedure TQtAbstractButton.setIconSize(Size: PSize);
begin
  QAbstractButton_setIconSize(QAbstractButtonH(Widget), Size);
end;

procedure TQtAbstractButton.setShortcut(AShortcut: TShortcut);
var
  Key: Word;
  Shift: TShiftState;
  Modifiers: QtModifier;
  KeySequence: QKeySequenceH;
begin
  if AShortCut <> 0 then
  begin
    ShortCutToKey(AShortCut, Key, Shift);
    Modifiers := ShiftStateToQtModifiers(Shift);
    KeySequence := QKeySequence_create(LCLKeyToQtKey(Key) or Modifiers);
  end
  else
    KeySequence := QKeySequence_create();
  QAbstractButton_setShortcut(QAbstractButtonH(Widget), KeySequence);
  QKeySequence_destroy(KeySequence);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SetText(const W: WideString);
begin
  QAbstractButton_setText(QAbstractButtonH(Widget), @W);
end;

function TQtAbstractButton.CanPaintBackground: Boolean;
begin
  Result := CanSendLCLMessage and getEnabled and
    (LCLObject.Color <> clBtnFace) and (LCLObject.Color <> clBackground);
    // DO NOT REMOVE ! QCheckBox,QRadioButton default = clBackground  !
end;

function TQtAbstractButton.getIconSize: TSize;
begin
  QAbstractButton_iconSize(QAbstractButtonH(Widget), @Result);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.Text
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractButton.getText: WideString;
begin
  QAbstractButton_text(QAbstractButtonH(Widget), @Result);
end;

procedure TQtAbstractButton.Toggle;
begin
  QAbstractButton_toggle(QAbstractButtonH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.isChecked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractButton.isChecked: Boolean;
begin
  Result := QAbstractButton_isChecked(QAbstractButtonH(Widget));
end;

function TQtAbstractButton.isDown: Boolean;
begin
  Result := QAbstractButton_isDown(QAbstractButtonH(Widget));
end;

procedure TQtAbstractButton.setCheckable(p1: Boolean);
begin
  QAbstractButton_setCheckable(QAbstractButtonH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.setChecked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.setChecked(p1: Boolean);
begin
  QAbstractButton_setChecked(QAbstractButtonH(Widget), p1);
end;

procedure TQtAbstractButton.setDefaultColorRoles;
begin
  WidgetColorRole := QPaletteButton;
  TextColorRole := QPaletteButtonText;
end;

procedure TQtAbstractButton.setDown(p1: Boolean);
begin
  QAbstractButton_setDown(QAbstractButtonH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalPressed
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalPressed; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_KEYDOWN;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalReleased
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalReleased; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_KEYUP;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalClicked(Checked: Boolean = False); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalClicked2
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalClicked2; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CLICKED;
  DeliverMessage(Msg);
end;

{ TQtPushButton }

function TQtPushButton.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QPushButton_create(Parent);
end;

procedure TQtPushButton.preferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
var
  Size: TSize;
begin
  QPushButton_sizeHint(QPushButtonH(Widget), @Size);
  PreferredWidth := Size.cx;
  PreferredHeight := Size.cy;
end;

procedure TQtPushButton.SetDefault(const ADefault: Boolean);
begin
  QPushButton_setDefault(QPushButtonH(Widget), ADefault);
end;

procedure TQtPushButton.AttachEvents;
begin
  inherited AttachEvents;
  
  FClickedHook := QAbstractButton_hook_create(Widget);
  QAbstractButton_hook_hook_clicked2(FClickedHook, @SlotClicked);
end;

procedure TQtPushButton.DetachEvents;
begin
  QAbstractButton_hook_destroy(FClickedHook);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtPushButton.SlotClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtPushButton.SlotClicked; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_CLICKED;
  DeliverMessage(Msg);
end;

{ TQtMainWindow }

function TQtMainWindow.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  w: QWidgetH;
  p: QPaletteH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtMainWindow.CreateWidget Name: ', LCLObject.Name);
  {$endif}
  FBlocked := False;
  FShowOnTaskBar := False;
  QtFormBorderStyle := Ord(bsSizeable);
  QtFormStyle := Ord(fsNormal);
  FHasPaint := True;
  FPopupMode := pmNone;
  FPopupParent := nil;

  IsMainForm := False;

  w := QApplication_activeWindow;
  if not Assigned(w) and not ((Application.MainForm <> nil) and (Application.MainForm.Visible))
  and (TCustomForm(LCLObject).FormStyle <> fsSplash) then
  begin
  
    IsMainForm := True;
    Result := QMainWindow_create(nil, QtWindow);

    {$ifdef darwin}
      if csDesigning in LCLObject.ComponentState then
        MenuBar := TQtMenuBar.Create(nil)
      else
        MenuBar := TQtMenuBar.Create(Result);
    {$else}
      MenuBar := TQtMenuBar.Create(Result);
    {$endif}
    
    if (Application.MainForm <> nil) and
       (Application.MainForm.FormStyle = fsMDIForm) and
       not (csDesigning in LCLObject.ComponentState) then
    begin
      FCentralWidget := QWidget_create(Result);
      MDIAreaHandle := QMdiArea_create(Result);
      p := QWidget_palette(FCentralWidget);
      if p <> nil then
        QMdiArea_setBackground(MdiAreaHandle, QPalette_background(P));
      QWidget_setParent(MdiAreaHandle, FCentralWidget);
      QMdiArea_setActivationOrder(MdiAreaHandle, QMdiAreaActivationHistoryOrder);
      QMdiArea_setOption(MdiAreaHandle,
        QMdiAreaDontMaximizeSubWindowOnActivation, True);
    end
    else
    begin
      FCentralWidget := QWidget_create(Result);
      MDIAreaHandle := nil;
    end;
    
    if FCentralWidget <> nil then
    begin
      QMainWindow_setCentralWidget(QMainWindowH(Result), FCentralWidget);
      QWidget_setMouseTracking(FCentralWidget, True);
    end;

    if not (csDesigning in LCLObject.ComponentState) then
      QMainWindow_setDockOptions(QMainWindowH(Result), QMainWindowAnimatedDocks);
  end
  else
  begin
    if IsMdiChild then
    begin

      if TQtMainWindow(Application.MainForm.Handle).MDIAreaHandle = nil then
        raise Exception.Create('MDIChild can be added to MDIForm only !');

      Result := QMdiSubWindow_create(nil, QtWindow);

      // QMdiSubWindow already have an layout

      LayoutWidget := QBoxLayoutH(QWidget_layout(Result));
      if LayoutWidget <> nil then
        QBoxLayout_destroy(LayoutWidget);
    end
    else
    begin
      if (TCustomForm(LCLObject).FormStyle = fsSplash) and
        not (csDesigning in LCLObject.ComponentState) then
        Result := QWidget_create(nil, QtSplashScreen)
      else
        Result := QWidget_create(nil, QtWindow);

      QWidget_setAttribute(Result, QtWA_Hover);
      QWidget_setMouseTracking(Result, True);
    end;

    // Main menu bar
    {$ifdef darwin}
      MenuBar := TQtMenuBar.Create(nil);
    {$else}
      MenuBar := TQtMenuBar.Create(Result);
    {$endif}

    FCentralWidget := QWidget_create(Result);
    QWidget_setMouseTracking(FCentralWidget, True);

    LayoutWidget := QBoxLayout_create(QBoxLayoutTopToBottom, Result);

    QBoxLayout_setSpacing(LayoutWidget, 0);
    QLayout_setContentsMargins(LayoutWidget, 0, 0, 0, 0);

    // we must fix mouse events in QMDISubWindow by
    // adding FCentralWidget as it''s widget
    if IsMdiChild then
      QMdiSubWindow_setWidget(QMdiSubWindowH(Result), FCentralWidget);
      
    QLayout_addWidget(LayoutWidget, FCentralWidget);
    QWidget_setLayout(Result, QLayoutH(LayoutWidget));
    QWidget_setAttribute(Result, QtWA_DeleteOnClose);
  end;
end;

procedure TQtMainWindow.ChangeParent(NewParent: QWidgetH);
var
  Flags: QtWindowFlags;
  Visible: Boolean;
begin
  if NewParent <> Widget then
  begin
    Visible := getVisible;
    Flags := windowFlags;
    setParent(NewParent);
    setWindowFlags(Flags);
    setVisible(Visible);
  end;
end;

procedure TQtMainWindow.UpdateParent;
var
  NewParent: QWidgetH;
begin
  NewParent := nil;
  case FPopupMode of
    pmNone: ;// no popup parent
    pmAuto:
      // active form is parent
      if Screen.ActiveForm <> nil then
        NewParent := TQtWidget(Screen.ActiveForm.Handle).Widget;
    pmExplicit:
      // parent is FPopupParent
      if FPopupParent <> nil then
        NewParent := FPopupParent;
  end;
  if (NewParent = nil) and not FShowOnTaskBar and not IsMainForm then
    NewParent := TQtMainWindow(Application.MainForm.Handle).Widget;

  ChangeParent(NewParent);
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtMainWindow.Destroy;
begin
  // The main window takes care of the menubar handle
  if MenuBar <> nil then
  begin
    MenuBar.Widget := nil;
    MenuBar.Free;
  end;

  inherited Destroy;
end;

procedure TQtMainWindow.Activate;
begin
  if IsMDIChild then
    QMdiArea_setActiveSubWindow(QMdiSubWindow_mdiArea(QMdiSubWindowH(Widget)),
      QMdiSubWindowH(Widget))
  else
    inherited Activate;
  {$IFDEF HASX11}
  // qt X11 bug ?  activates window but it's not in
  // front of others.
  {$note TQtWidget.Activate: Check this with next qt version (>=4.7)}
  if not QWidget_isModal(Widget) then
    QWidget_raise(Widget);
  {$ENDIF}
end;

function TQtMainWindow.getAcceptDropFiles: Boolean;
begin
  Result := QWidget_acceptDrops(Widget);
end;

function TQtMainWindow.getText: WideString;
begin
  WindowTitle(@Result);
end;

function TQtMainWindow.getTextStatic: Boolean;
begin
  Result := False;
end;

procedure TQtMainWindow.setText(const W: WideString);
begin
  setWindowTitle(@W);
end;

procedure TQtMainWindow.setMenuBar(AMenuBar: QMenuBarH);
begin
  if IsMainForm then
    QMainWindow_setMenuBar(QMainWindowH(Widget), AMenuBar)
  else
    QLayout_setMenuBar(LayoutWidget, AMenuBar);
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.EventFilter
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtMainWindow.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
var
  AStateEvent: QWindowStateChangeEventH;
  AState: QtWindowStates;
  AOldState: QtWindowStates;
  CanSendEvent: Boolean;
  {$IFDEF HASX11}
  IsMinimizeEvent: Boolean;
  {$ENDIF}
begin
  Result := False;
  QEvent_accept(Event);
  if LCLObject = nil then
    exit;

  {$IF DEFINED(VerboseQt) OR DEFINED(VerboseQtEvents)}
  if (QEvent_type(Event)=QEventWindowActivate) or
    (QEvent_type(Event)=QEventWindowDeactivate) or
    (QEvent_type(Event)=QEventShowToParent) or
    (QEvent_type(Event)=QEventWindowStateChange) then
      WriteLn('TQtMainWindow.EventFilter: Sender=', IntToHex(PtrUInt(Sender),8),
      ' LCLObject=', dbgsName(LCLObject),
      ' Event=', EventTypeToStr(Event),' inUpdate=',inUpdate);
  {$endif}

  BeginEventProcessing;
  case QEvent_type(Event) of
    QEventWindowUnblocked: Blocked := False;
    QEventWindowBlocked: Blocked := True;
    QEventWindowActivate: SlotActivateWindow(True);
    QEventWindowDeactivate: SlotActivateWindow(False);
    QEventShowToParent:
    begin
      if IsMdiChild then
      begin
        if not TCustomForm(LCLObject).Active then
        begin
          SlotActivateWindow(True);
          Result := True;
          QEvent_ignore(Event);
        end;
      end;
    end;

    QEventWindowStateChange:
    begin
      CanSendEvent := True;
      {$IFDEF HASX11}
      // for X11 we must ask state of each modified window.
      AState := getWindowState;
      IsMinimizeEvent := AState and QtWindowMinimized <> 0;
      if IsMinimizeEvent then
        CanSendEvent := IsCurrentDesktop(Widget);
      {$ENDIF}
      if IsMainForm and CanSendEvent then
      begin
        {$IFNDEF HASX11}
        AState := getWindowState;
        {$ENDIF}
        AStateEvent := QWindowStateChangeEventH(Event);
        AOldState := QWindowStateChangeEvent_oldState(AStateEvent);
        if AState and QtWindowMinimized <> 0 then
          Application.IntfAppMinimize
        else
        if (AOldState and QtWindowMinimized <> 0) or
          (AOldState and QtWindowMaximized <> 0) or
          (AOldState and QtWindowFullScreen <> 0) then
          Application.IntfAppRestore;
      end;
      if CanSendEvent then
        SlotWindowStateChange;
    end;
    QEventDrop,
    QEventDragMove,
    QEventDragEnter:
    begin
      Result := getAcceptDropFiles;
      if (Result) and (QEvent_type(Event) = QEventDrop) then
        Result := slotDropFiles(Sender, Event);
    end;
  else
    Result := inherited EventFilter(Sender, Event);
  end;
  EndEventProcessing;
end;

function TQtMainWindow.IsMdiChild: Boolean;
begin
  Result := (LCLObject <> nil) and not
    (csDesigning in LCLObject.ComponentState) and
    (TCustomForm(LCLObject).FormStyle = fsMDIChild);
end;

function TQtMainWindow.IsModal: Boolean;
begin
  Result := QWidget_isModal(Widget);
end;

function TQtMainWindow.MdiChildCount: integer;
var
  Arr: TPtrIntArray;
  Area: QMdiAreaH;
begin
  Result := 0;
  if IsMdiChild then
    Area := QMdiSubWindow_mdiArea(QMdiSubWindowH(Widget))
  else
    Area := MDIAreaHandle;
  if Area <> nil then
  begin
    QMdiArea_subWindowList(Area, @Arr);
    Result := High(Arr);
  end;
end;

procedure TQtMainWindow.OffsetMousePos(APoint: PQtPoint);
begin
  if not IsMdiChild then
    inherited OffsetMousePos(APoint);
end;

procedure TQtMainWindow.setAcceptDropFiles(AValue: Boolean);
begin
  QWidget_setAcceptDrops(Widget, AValue);
end;

procedure TQtMainWindow.SlotActivateWindow(vActivate: Boolean); cdecl;
var
  Msg: TLMActivate;
  FIsActivated: Boolean;
begin
  {$ifdef VerboseQt}
  WriteLn('TQtWidget.SlotActivateWindow Name', LCLObject.Name, ' vActivate: ', dbgs(vActivate));
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);

  FIsActivated := TCustomForm(LCLObject).Active;
  {do not send activate if form is already activated,
   also do not send activate if TCustomForm.Parent is assigned
   since it's form embedded into another control or form}
  if (vActivate = FIsActivated) or (LCLObject.Parent <> nil) then
    exit;

  Msg.Active := vActivate;
  Msg.ActiveWindow := LCLObject.Handle;

  if vActivate then
    Msg.Msg := LM_ACTIVATE
  else
    Msg.Msg := LM_DEACTIVATE;

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.SlotWindowStateChange
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtMainWindow.SlotWindowStateChange; cdecl;
var
  Msg: TLMSize;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtMainWindow.SlotWindowStateChange');
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SIZE;
  Msg.SizeType := SIZENORMAL;

  if getWindowState and QtWindowMinimized <> 0 then
    Msg.SizeType := SIZEICONIC
  else
  if (getWindowState and QtWindowFullScreen <> 0) or
     (getWindowState and QtWindowMaximized <> 0) then
    Msg.SizeType := SIZEFULLSCREEN;

  Msg.SizeType := Msg.SizeType or Size_SourceIsInterface;

  Msg.Width := getWidth;
  Msg.Height := getHeight;
  
  DeliverMessage(Msg);
end;

procedure TQtMainWindow.setShowInTaskBar(AValue: Boolean);
begin
  FShowOnTaskBar := AValue;
  {$IFNDEF HASX11}
  if not QWidget_isModal(Widget) then
    UpdateParent;
  {$ENDIF}
end;

procedure TQtMainWindow.setPopupParent(APopupMode: TPopupMode; NewParent: QWidgetH);
begin
  FPopupMode := APopupMode;
  FPopupParent := NewParent;
  UpdateParent;
end;

procedure TQtMainWindow.AttachEvents;
begin
  inherited AttachEvents;

  if FCentralWidget <> nil then
  begin
    FCWEventHook := QObject_hook_create(FCentralWidget);
    QObject_hook_hook_events(FCWEventHook, @CWEventFilter);
  end;
end;

procedure TQtMainWindow.DetachEvents;
begin
  if FCWEventHook <> nil then
  begin
    QObject_hook_destroy(FCWEventHook);
    FCWEventHook := nil;
  end;

  inherited DetachEvents;
end;

function TQtMainWindow.CWEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  R: TRect;
  R2: TRect;
  i: Integer;
begin
  Result := False;
  
  if LCLObject <> nil then
  begin
    case QEvent_type(Event) of
      QEventResize:
        begin
          {mdi area part begins}
          if MdiAreaHandle <> nil then
          begin
            {first must get contents rect - all except main menu}
            QWidget_contentsRect(FCentralWidget, @R);
            
            {TODO: find better way to find out which controls are top,left,right & bottom aligned ...}
            for i := 0 to LCLObject.ComponentCount - 1 do
            begin
            
              {find statusbars}
              if LCLObject.Components[i] is TStatusBar then
              begin
                R2 := TWinControl(LCLObject.Components[i]).ClientRect;
                case TWinControl(LCLObject.Components[i]).Align of
                  alLeft: R.Left := R.Left + (R2.Right - R2.Left);
                  alTop: R.Top := R.Top + (R2.Bottom - R2.Top);
                  alRight: R.Right := R.Right - (R2.Right - R2.Left);
                  alBottom: R.Bottom := R.Bottom - (R2.Bottom - R2.Top);
                end;
              end;
              
              {find toolbars}
              if LCLObject.Components[i] is TToolBar then
              begin
                R2 := TWinControl(LCLObject.Components[i]).ClientRect;
                case TWinControl(LCLObject.Components[i]).Align of
                  alLeft: R.Left := R.Left + (R2.Right - R2.Left);
                  alTop: R.Top := R.Top + (R2.Bottom - R2.Top);
                  alRight: R.Right := R.Right - (R2.Right - R2.Left);
                  alBottom: R.Bottom := R.Bottom - (R2.Bottom - R2.Top);
                end;
              end;
              
            end; {components loop}
            
            QWidget_setGeometry(MDIAreaHandle, @R);
          end;
          {mdi area part end}
          
        end;
    end;
  end;
end;

{ TQtStaticText }

function TQtStaticText.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtStaticText.Create');
  {$endif}

  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QLabel_create(Parent);
end;

function TQtStaticText.CanPaintBackground: Boolean;
begin
  Result := CanSendLCLMessage and getEnabled and
    (LCLObject.Color <> clBtnFace) and (LCLObject.Color <> clBackground);
end;

{------------------------------------------------------------------------------
  Function: TQtStaticText.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtStaticText.SetText(const W: WideString);
var
  AmpersandPos: Integer;
  LocalW: WideString;
begin
  LocalW := W;
  if TCustomStaticText(LCLObject).ShowAccelChar then
  begin
    // replace '&' by underline
    AmpersandPos := Pos('&', W);
    if AmpersandPos > 0 then
    begin
      LocalW := Copy(W, 1, AmpersandPos - 1) + '<u>';
      if AmpersandPos < Length(W) then
        LocalW := LocalW + W[AmpersandPos + 1];
      LocalW := LocalW + '</u>' + Copy(W, AmpersandPos + 2, Length(W));
    end;
  end;
  QLabel_setText(QLabelH(Widget), @LocalW);
end;

procedure TQtStaticText.setAlignment(const AAlignment: QtAlignment);
begin
  QLabel_setAlignment(QLabelH(Widget), AAlignment);
end;

{------------------------------------------------------------------------------
  Function: TQtStaticText.Text
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtStaticText.getText: WideString;
begin
  QLabel_text(QLabelH(Widget), @Result);
end;

{ TQtCheckBox }

function TQtCheckBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtCheckBox.Create');
  {$endif}
  TextColorRole := QPaletteWindowText;

  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;

  Result := QCheckBox_create(Parent);
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.CheckState
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtCheckBox.CheckState: QtCheckState;
begin
  Result := QCheckBox_checkState(QCheckBoxH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.setCheckState
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtCheckBox.setCheckState(state: QtCheckState);
begin
  QCheckBox_setCheckState(QCheckBoxH(Widget), state);
end;

procedure TQtCheckBox.AttachEvents;
begin
  inherited AttachEvents;
  FStateChangedHook := QCheckBox_hook_create(Widget);
  QCheckBox_hook_hook_stateChanged(FStateChangedHook, @SignalStateChanged);
end;

procedure TQtCheckBox.DetachEvents;
begin
  QCheckBox_hook_destroy(FStateChangedHook);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.signalStateChanged
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtCheckBox.signalStateChanged(p1: Integer); cdecl;
var
  Msg: TLMessage;
begin
  if not InUpdate then
  begin
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    DeliverMessage(Msg);
  end;
end;

{ TQtRadioButton }

function TQtRadioButton.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtRadioButton.Create');
  {$endif}
  TextColorRole := QPaletteWindowText;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QRadioButton_create(Parent);
  // hide widget by default
  QWidget_hide(Result);
end;

procedure TQtRadioButton.AttachEvents;
begin
  inherited AttachEvents;
  FToggledHook := QAbstractButton_hook_create(Widget);
  QAbstractButton_hook_hook_toggled(FToggledHook, @SignalToggled);
end;

procedure TQtRadioButton.DetachEvents;
begin
  QAbstractButton_hook_destroy(FToggledHook);
  inherited DetachEvents;
end;

procedure TQtRadioButton.SignalToggled(Checked: Boolean); cdecl;
var
  Msg: TLMessage;
begin
  if not InUpdate then
  begin
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    DeliverMessage(Msg);
  end;
end;

function TQtRadioButton.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  Result := inherited EventFilter(Sender, Event);
  if (LCLObject <> nil) and
    ((QEvent_type(Event) in [QEventMouseButtonPress, QEventMouseButtonRelease])
    or
    ((QEvent_type(Event) in [QEventKeyPress, QEventKeyRelease]) and
     (QKeyEvent_key(QKeyEventH(Event)) = QtKey_Space) and
     isChecked))
  then
    Result := False;
end;

{ TQtGroupBox }

procedure TQtGroupBox.setLayoutThemeMargins(ALayout: QLayoutH; AWidget: QWidgetH);
var
  LeftMargin: Integer;
  TopMargin: Integer;
  RightMargin: Integer;
  BottomMargin: Integer;
  {$IFDEF HASX11}
  Font: QFontH;
  FontMetrics: QFontMetricsH;
  FontHeight: Integer;
  {$ENDIF}
begin
  if ALayout = nil then
    exit;

  QWidget_getContentsMargins(AWidget,@LeftMargin, @TopMargin, @RightMargin, @BottomMargin);

  {if contentsMargins TopMargin is huge then we must rethink about TopMargin
   size (eg.oxygen theme have 32 top margin while plastique have 19
   with same font height) }
  {$IFDEF HASX11}
  Font := QWidget_font(AWidget);
  FontMetrics := QFontMetrics_create(Font);
  try
    FontHeight := QFontMetrics_height(FontMetrics);
  finally
    QFontMetrics_destroy(FontMetrics);
  end;

  {currently applies only to wrong TopMargin calculation (eg.gtk style).}
  if (TopMargin - FontHeight < 2) then
    TopMargin := FontHeight + 2 // top & bottom +1px
  else {currently applies only to oxygen & nitrogen theme.}
  if ((TopMargin - BottomMargin - 2) > FontHeight) then
  begin
    TopMargin := TopMargin - BottomMargin - 3;
    BottomMargin := 0;
  end;
  {$ENDIF}

  QLayout_setContentsMargins(ALayout, LeftMargin, TopMargin, RightMargin, BottomMargin);
  QLayout_invalidate(ALayout);

  if LCLObject <> nil then
    LCLObject.DoAdjustClientRectChange(False);
end;

function TQtGroupBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Layout: QBoxLayoutH;
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtGroupBox.Create ');
  {$endif}
  FGroupBoxType := tgbtNormal;
  FHasPaint := True;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QGroupBox_create(Parent);
  FCentralWidget := QStackedWidget_create(Result);
  {we set QtNoFocus by default, since we don't want
  FCentralWidget grabs focus on mouse click}
  QWidget_setFocusPolicy(FCentralWidget, QtNoFocus);

  Layout := QVBoxLayout_create(Result);
  QLayout_addWidget(Layout, FCentralWidget);
  QWidget_setLayout(Result, QLayoutH(Layout));
  QWidget_setAttribute(Result, QtWA_LayoutOnEntireRect, True);
end;

procedure TQtGroupBox.AttachEvents;
begin
  inherited AttachEvents;
  if FCentralWidget <> nil then
  begin
    FCWEventHook := QObject_hook_create(FCentralWidget);
    QObject_hook_hook_events(FCWEventHook, @EventFilter);
  end;
end;

procedure TQtGroupBox.DetachEvents;
begin
  if FCWEventHook <> nil then
  begin
    QObject_hook_destroy(FCWEventHook);
    FCWEventHook := nil;
  end;
  inherited DetachEvents;
end;

function TQtGroupBox.CanPaintBackground: Boolean;
begin
  Result := CanSendLCLMessage and getEnabled and
    (LCLObject.Color <> clBtnFace) and (LCLObject.Color <> clBackground);
    // DO NOT REMOVE ! QGroupBox default = clBackground not clBtnFace !
end;

function TQtGroupBox.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
var
  ResizeEvent: QResizeEventH;
  NewSize, OldSize: TSize;
begin
  Result := False;
  QEvent_accept(Event);
  if LCLObject = nil then
    exit;

  if (Sender = FCentralWidget) then
  begin
    if (QEvent_type(Event) = QEventResize) and
      LCLObject.ClientRectNeedsInterfaceUpdate then
        LCLObject.InvalidateClientRectCache(False);
    exit;
  end;

  case QEvent_type(Event) of
    QEventFontChange,
    QEventStyleChange: setLayoutThemeMargins(QWidget_layout(Widget), Widget);
    QEventShow:
      begin
        LCLObject.DoAdjustClientRectChange(False);
        SlotShow(True);
        {send dummy LM_SIZE to LCL}
        if (FGroupBoxType <> tgbtNormal) and
          LCLObject.ClientRectNeedsInterfaceUpdate then
        begin
          OldSize.cx := LCLObject.Height;
          OldSize.cy := LCLObject.Width;
          NewSize := OldSize;
          inc(OldSize.cx);
          inc(OldSize.cy);
          ResizeEvent := QResizeEvent_create(@NewSize, @OldSize);
          QCoreApplication_postEvent(Widget, ResizeEvent, -1);
        end;
      end;
    else
      Result := inherited EventFilter(Sender, Event);
  end;
end;

function TQtGroupBox.getText: WideString;
begin
  QGroupBox_title(QGroupBoxH(Widget), @Result);
end;

procedure TQtGroupBox.setText(const W: WideString);
begin
  QGroupBox_setTitle(QGroupBoxH(Widget), @W);
  setLayoutThemeMargins(QWidget_Layout(Widget), Widget);
end;

procedure TQtGroupBox.setFocusPolicy(const APolicy: QtFocusPolicy);
begin
  if Assigned(LCLObject) and not LCLObject.TabStop then
    inherited setFocusPolicy(QtNoFocus)
  else
    inherited setFocusPolicy(APolicy);
end;

{ TQtFrame }

function TQtFrame.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtFrame.Create');
  {$endif}
  FHasPaint := True;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QFrame_create(Parent);
  if (QtVersionMajor = 4) and (QtVersionMinor < 6) then
    QWidget_setAutoFillBackground(Result, True);
end;

procedure TQtFrame.setFocusPolicy(const APolicy: QtFocusPolicy);
begin
  if Assigned(LCLObject) and not LCLObject.TabStop then
    inherited setFocusPolicy(QtNoFocus)
  else
    inherited setFocusPolicy(APolicy);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setFrameStyle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setFrameStyle(p1: Integer);
begin
  QFrame_setFrameStyle(QFrameH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setFrameShape
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setFrameShape(p1: QFrameShape);
begin
  QFrame_setFrameShape(QFrameH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setFrameShadow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setFrameShadow(p1: QFrameShadow);
begin
  QFrame_setFrameShadow(QFrameH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtArrow.CreateWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtArrow.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtArrow.Create');
  {$endif}
  FHasPaint := True;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QFrame_create(Parent);
end;

function TQtAbstractSlider.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSlider.Create');
  {$endif}

  FSliderPressed := False;
  FSliderReleased:= False;

  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QAbstractSlider_create(Parent);
end;

procedure TQtAbstractSlider.AttachEvents;
begin
  inherited AttachEvents;
  FRangeChangedHook := QAbstractSlider_hook_create(Widget);
  FSliderMovedHook :=  QAbstractSlider_hook_create(Widget);
  FSliderPressedHook := QAbstractSlider_hook_create(Widget);
  FSliderReleasedHook := QAbstractSlider_hook_create(Widget);
  FValueChangedHook := QAbstractSlider_hook_create(Widget);
  FActionTriggeredHook := QAbstractSlider_hook_create(Widget);
end;

procedure TQtAbstractSlider.DetachEvents;
begin
  QAbstractSlider_hook_destroy(FRangeChangedHook);
  QAbstractSlider_hook_destroy(FSliderMovedHook);
  QAbstractSlider_hook_destroy(FSliderPressedHook);
  QAbstractSlider_hook_destroy(FSliderReleasedHook);
  QAbstractSlider_hook_destroy(FValueChangedHook);
  QAbstractSlider_hook_destroy(FActionTriggeredHook);
  inherited DetachEvents;
end;

function TQtAbstractSlider.getValue: Integer;
begin
  Result := QAbstractSlider_value(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getPageStep: Integer;
begin
  Result := QAbstractSlider_pageStep(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getMin: Integer;
begin
  Result := QAbstractSlider_minimum(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getMax: Integer;
begin
  Result := QAbstractSlider_maximum(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getSingleStep: Integer;
begin
  Result := QAbstractSlider_singleStep(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getSliderDown: Boolean;
begin
  Result := QAbstractSlider_isSliderDown(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getSliderPosition: Integer;
begin
  Result := QAbstractSlider_sliderPosition(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getTracking: Boolean;
begin
  Result := QAbstractSlider_hasTracking(QAbstractSliderH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.rangeChanged
  Params:  minimum,maximum: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.SlotRangeChanged(minimum: Integer; maximum: Integer); cdecl;
begin
  { TODO: find out what needs to be done on rangeChanged event
    Possibilities: repaint or recount pageSize() }
 {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.rangeChanged() to min=',minimum,' max=',maximum);
 {$endif}
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setInvertedAppereance
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setInvertedAppereance(p1: Boolean);
begin
  QAbstractSlider_setInvertedAppearance(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setInvertedControls
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setInvertedControls(p1: Boolean);
begin
  QAbstractSlider_setInvertedControls(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setMaximum
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setMaximum(p1: Integer);
begin
  QAbstractSlider_setMaximum(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setMinimum
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setMinimum(p1: Integer);
begin
  QAbstractSlider_setMinimum(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setOrientation
  Params:  p1: QtOrientation (QtHorizontal or QtVertical)
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setOrientation(p1: QtOrientation);
begin
  QAbstractSlider_setOrientation(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setPageStep
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setPageStep(p1: Integer);
begin
  QAbstractSlider_setPageStep(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setRange
  Params:  minimum,maximum: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setRange(minimum: Integer; maximum: Integer);
begin
  QAbstractSlider_setRange(QAbstractSliderH(Widget), minimum, maximum);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setSingleStep
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setSingleStep(p1: Integer);
begin
  QAbstractSlider_setSingleStep(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setSliderDown
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setSliderDown(p1: Boolean);
begin
  QAbstractSlider_setSliderDown(QAbstractSliderH(Widget), p1);
end;


{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setSliderPosition
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setSliderPosition(p1: Integer);
begin
  QAbstractSlider_setSliderPosition(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setTracking
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setTracking(p1: Boolean);
begin
  QAbstractSlider_setTracking(QAbstractSliderH(Widget), p1);
end;

{-----------------------------------------------------------------------------
  Function: TQtAbstractSlider.setValue
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setValue(p1: Integer);
begin
  QAbstractSlider_setValue(QAbstractSliderH(Widget), p1);
end;

procedure TQtAbstractSlider.SlotSliderMoved(p1: Integer); cdecl;
begin
 {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.sliderMoved() to pos=',p1);
 {$endif}

 // there's no need to deliver this message
 // since ValueChanged does it's job correct, also for tracking on/off
 // this signal must stay empty because of ttrackbar !
end;

procedure TQtAbstractSlider.SlotSliderPressed; cdecl;
begin
  {$ifdef VerboseQt}
   writeln('TQtAbstractSlider.sliderPressed()');
  {$endif}
  FSliderPressed := True;
  FSliderReleased := False;
end;

procedure TQtAbstractSlider.SlotSliderReleased; cdecl;
begin
  {$ifdef VerboseQt}
   writeln('TQtAbstractSlider.sliderReleased()');
  {$endif}
  FSliderPressed := False;
  FSliderReleased := True;
end;

function TQtAbstractSlider.getInvertedAppereance: Boolean;
begin
  Result := QAbstractSlider_invertedAppearance(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getInvertedControls: Boolean;
begin
  Result := QAbstractSlider_invertedControls(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getOrientation: QtOrientation;
begin
  Result := QAbstractSlider_orientation(QAbstractSliderH(Widget));
end;

procedure TQtAbstractSlider.SlotValueChanged(p1: Integer); cdecl;
var
  LMScroll: TLMScroll;
  b: Boolean;
begin
  {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.SlotValueChanged() to value ',p1,' inUpdate ',inUpdate);
  {$endif}

  FillChar(LMScroll, SizeOf(LMScroll), #0);

  LMScroll.ScrollBar := PtrUInt(Self);

  if QAbstractSlider_orientation(QAbstractSliderH(Widget)) = QtHorizontal then
    LMScroll.Msg := LM_HSCROLL
  else
    LMScroll.Msg := LM_VSCROLL;
  
  LMScroll.Pos := p1;
  LMScroll.ScrollCode := SIF_POS;

  b := p1 = getMax;
  if not InUpdate or (getVisible and ((p1=getMin) or b)) then
  begin
    DeliverMessage(LMScroll);
    if b and (FChildOfComplexWidget = ccwAbstractScrollArea) then
    begin
      LCLObject.DoAdjustClientRectChange;
      if not InUpdate then
        QAbstractSlider_triggerAction(QAbstractSliderH(Widget),
          QAbstractSliderSliderToMaximum);
    end;
  end;
end;

procedure TQtAbstractSlider.SlotActionTriggered(action: Integer); cdecl;
const
  SliderActions: Array[0..7] of QAbstractSliderSliderAction = (
    QAbstractSliderSliderNoAction, QAbstractSliderSliderSingleStepAdd,
    QAbstractSliderSliderSingleStepSub, QAbstractSliderSliderPageStepAdd,
    QAbstractSliderSliderPageStepSub, QAbstractSliderSliderToMinimum,
    QAbstractSliderSliderToMaximum, QAbstractSliderSliderMove );
var
  LMScroll: TLMScroll;
  SliderAction: QAbstractSliderSliderAction;
begin
  {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.SlotActionTriggered() action = ',action,' inUpdate ',inUpdate);
  {$endif}

  FillChar(LMScroll, SizeOf(LMScroll), #0);

  LMScroll.ScrollBar := PtrUInt(Self);

  if QAbstractSlider_orientation(QAbstractSliderH(Widget)) = QtHorizontal then
    LMScroll.Msg := LM_HSCROLL
  else
    LMScroll.Msg := LM_VSCROLL;

  LMScroll.Pos := getSliderPosition;

  SliderAction := SliderActions[Action];

  case SliderAction of
    QAbstractSliderSliderNoAction: Exit;
    QAbstractSliderSliderSingleStepAdd:
      begin
        if LMScroll.Msg = LM_HSCROLL then
          LMScroll.ScrollCode := SB_LINERIGHT
        else
          LMScroll.ScrollCode := SB_LINEDOWN;
      end;
    QAbstractSliderSliderSingleStepSub:
      begin
        if LMScroll.Msg = LM_HSCROLL then
          LMScroll.ScrollCode := SB_LINELEFT
        else
          LMScroll.ScrollCode := SB_LINEUP;
      end;
    QAbstractSliderSliderPageStepAdd:
      begin
        if LMScroll.Msg = LM_HSCROLL then
          LMScroll.ScrollCode := SB_PAGERIGHT
        else
          LMScroll.ScrollCode := SB_PAGEDOWN;
      end;
    QAbstractSliderSliderPageStepSub:
      begin
        if LMScroll.Msg = LM_HSCROLL then
          LMScroll.ScrollCode := SB_PAGELEFT
        else
          LMScroll.ScrollCode := SB_PAGEUP;
      end;
    QAbstractSliderSliderToMinimum:
      begin
        if LMScroll.Msg = LM_HSCROLL then
          LMScroll.ScrollCode := SB_LEFT
        else
          LMScroll.ScrollCode := SB_TOP;
      end;
    QAbstractSliderSliderToMaximum:
      begin
        if LMScroll.Msg = LM_HSCROLL then
          LMScroll.ScrollCode := SB_RIGHT
        else
          LMScroll.ScrollCode := SB_BOTTOM;
      end;
    QAbstractSliderSliderMove:
      begin
        if getTracking and getSliderDown then
          LMScroll.ScrollCode := SB_THUMBTRACK
        else
          LMScroll.ScrollCode := SB_THUMBPOSITION;
      end;
  end;

  DeliverMessage(LMScroll);
end;

{ TQtScrollBar }

function TQtScrollBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtScrollBar.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QScrollBar_create(Parent);
  QWidget_setFocusPolicy(Result, QtNoFocus);
  if (QtVersionMajor = 4) and (QtVersionMinor < 6) then
    QWidget_setAutoFillBackground(Result, True);
  FHasPaint := True;
end;

procedure TQtScrollBar.preferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
var
  Size: TSize;
begin
  QScrollBar_sizeHint(QScrollBarH(Widget), @Size);
  PreferredWidth := Size.cx;
  PreferredHeight := Size.cy;
end;

procedure TQtScrollBar.setFocusPolicy(const APolicy: QtFocusPolicy);
begin
  if FOwnWidget and Assigned(LCLObject) and not LCLObject.TabStop then
    inherited setFocusPolicy(QtNoFocus)
  else
    inherited setFocusPolicy(APolicy);
end;

function TQtScrollBar.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  Result := False;
  QEvent_accept(Event);

  if LCLObject = nil then
    exit;

  case QEvent_type(Event) of
    {if any of those events returs TRUE our scrollbar becomes invisible.}
    QEventMouseMove,
    QEventWheel,
    QEventPaint,
    QEventKeyPress,
    QEventKeyRelease: Result := False;
  else
    if FOwnWidget then
      Result := inherited EventFilter(Sender, Event);
  end;
end;

procedure TQtScrollBar.AttachEvents;
begin
  inherited AttachEvents;
  QAbstractSlider_hook_hook_rangeChanged(FRangeChangedHook, @SlotRangeChanged);

  QAbstractSlider_hook_hook_sliderMoved(FSliderMovedHook, @SlotSliderMoved);

  QAbstractSlider_hook_hook_sliderPressed(FSliderPressedHook, @SlotSliderPressed);

  QAbstractSlider_hook_hook_sliderReleased(FSliderReleasedHook, @SlotSliderReleased);

  QAbstractSlider_hook_hook_valueChanged(FValueChangedHook, @SlotValueChanged);

  QAbstractSlider_hook_hook_actionTriggered(FActionTriggeredHook, @SlotActionTriggered);
end;

{ TQtToolBar }

function TQtToolBar.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtToolBar.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QToolBar_create(Parent);
end;

{ TQtToolButton }

function TQtToolButton.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtToolButton.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QToolButton_create(Parent);
end;

{ TQtTrackBar }

function TQtTrackBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTrackBar.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QSlider_create(Parent);
end;

function TQtTrackBar.getTickInterval: Integer;
begin
  Result := QSlider_tickInterval(QSliderH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtTrackBar.setTickPosition
  Params:  Value: QSliderTickPosition
  Returns: Nothing
 ------------------------------------------------------------------------------ }
procedure TQtTrackBar.setTickPosition(Value: QSliderTickPosition);
begin
  QSlider_setTickPosition(QSliderH(Widget), Value);
end;

{------------------------------------------------------------------------------
  Function: TQtTrackBar.setTickInterval
  Params:  Value: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------ }
procedure TQtTrackBar.SetTickInterval(Value: Integer);
begin
  QSlider_setTickInterval(QSliderH(Widget), Value);
end;

procedure TQtTrackBar.AttachEvents;
begin
  inherited AttachEvents;
  
  QAbstractSlider_hook_hook_sliderMoved(FSliderMovedHook, @SlotSliderMoved);

  QAbstractSlider_hook_hook_sliderPressed(FSliderPressedHook, @SlotSliderPressed);

  QAbstractSlider_hook_hook_sliderReleased(FSliderReleasedHook, @SlotSliderReleased);

  QAbstractSlider_hook_hook_valueChanged(FValueChangedHook, @SlotValueChanged);
end;

procedure TQtTrackBar.SlotSliderMoved(p1: Integer); cdecl;
var
  Msg: TLMessage;
begin
 {$ifdef VerboseQt}
  writeln('TQtTrackBar.SlotSliderMoved() p1=',p1);
 {$endif}
  if SliderPressed and not InUpdate then
  begin
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    DeliverMessage(Msg);
  end;
end;

procedure TQtTrackBar.SlotValueChanged(p1: Integer); cdecl;
var
  Msg: TLMessage;
begin
 {$ifdef VerboseQt}
  writeln('TQtTrackBar.SlotValueChanged() p1=',p1);
 {$endif}

  if not SliderPressed and not InUpdate then
  begin
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    DeliverMessage(Msg);
  end;
end;

{ TQtLineEdit }

function TQtLineEdit.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QLineEdit_create(Parent);
end;

function TQtLineEdit.getAlignment: QtAlignment;
begin
  Result := QLineEdit_alignment(QLineEditH(Widget));
end;

function TQtLineEdit.getCursorPosition: Integer;
begin
  Result := QLineEdit_cursorPosition(QLineEditH(Widget));
end;

function TQtLineEdit.getMaxLength: Integer;
begin
  Result := QLineEdit_maxLength(QLineEditH(Widget));
end;

function TQtLineEdit.getSelectedText: WideString;
begin
  QLineEdit_selectedText(QLineEditH(Widget), @Result);
end;

function TQtLineEdit.getSelectionStart: Integer;
begin
  if hasSelectedText then
    Result := QLineEdit_selectionStart(QLineEditH(Widget))
  else
    Result := getCursorPosition;
end;

function TQtLineEdit.getSelectionLength: Integer;
var
  W: WideString;
begin
  if hasSelectedText then
  begin
    W := getSelectedText;
    Result := Length(W);
  end
  else
    Result := 0;
end;

function TQtLineEdit.getText: WideString;
begin
  QLineEdit_text(QLineEditH(Widget), @Result);
end;

function TQtLineEdit.getTextStatic: Boolean;
begin
  Result := False;
end;

function TQtLineEdit.isUndoAvailable: Boolean;
begin
  Result := QLineEdit_isUndoAvailable(QLineEditH(Widget));
end;

function TQtLineEdit.hasSelectedText: Boolean;
begin
  Result := QLineEdit_hasSelectedText(QLineEditH(Widget));
end;

procedure TQtLineEdit.selectAll;
begin
  QLineEdit_selectAll(QLineEditH(Widget));
end;

procedure TQtLineEdit.setAlignment(const AAlignment: QtAlignment);
begin
  QLineEdit_setAlignment(QLineEditH(Widget), AAlignment);
end;

procedure TQtLineEdit.setBorder(const ABorder: Boolean);
begin
  QLineEdit_setFrame(QLineEditH(Widget), ABorder);
end;

procedure TQtLineEdit.AttachEvents;
begin
  inherited AttachEvents;

  FTextChanged := QLineEdit_hook_create(Widget);
  QLineEdit_hook_hook_textChanged(FTextChanged, @SignalTextChanged);
end;

procedure TQtLineEdit.DetachEvents;
begin
  QLineEdit_hook_destroy(FTextChanged);
  inherited DetachEvents;
end;

function TQtLineEdit.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  Result := False;
  QEvent_accept(Event);
  if LCLObject = nil then
    exit;
  if (ChildOfComplexWidget = ccwComboBox) and
    (QEvent_type(Event) = QEventPaint) and
    (LCLObject.HandleAllocated) then
  begin
    Result := TQtComboBox(LCLObject.Handle).InUpdate;
    if Result then
      QEvent_ignore(Event)
    else
      Result:=inherited EventFilter(Sender, Event);
  end else
    Result:=inherited EventFilter(Sender, Event);
end;

procedure TQtLineEdit.preferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
var
  Size: TSize;
begin
  QLineEdit_sizeHint(QLineEditH(Widget), @Size);
  PreferredHeight := Size.cy;
  PreferredWidth := Size.cx;
end;

procedure TQtLineEdit.setCursorPosition(const ACursorPosition: Integer);
begin
  QLineEdit_setCursorPosition(QLineEditH(Widget), ACursorPosition);
end;

procedure TQtLineEdit.setDefaultColorRoles;
begin
  WidgetColorRole := QPaletteBase;
  TextColorRole := QPaletteText;
end;

procedure TQtLineEdit.setEchoMode(const AMode: QLineEditEchoMode);
begin
  QLineEdit_setEchoMode(QLineEditH(Widget), AMode);
end;

procedure TQtLineEdit.setInputMask(const AMask: WideString);
begin
  QLineEdit_setInputMask(QLineEditH(Widget), @AMask);
end;

procedure TQtLineEdit.setMaxLength(const ALength: Integer);
begin
  QLineEdit_setMaxLength(QLineEditH(Widget), ALength);
end;

procedure TQtLineEdit.setReadOnly(const AReadOnly: Boolean);
begin
  QLineEdit_setReadOnly(QLineEditH(Widget), AReadOnly);
end;

procedure TQtLineEdit.setSelection(const AStart, ALength: Integer);
begin
  if AStart >= 0 then
  begin
    if ALength > 0 then
      QLineEdit_setSelection(QLineEditH(Widget), AStart, ALength)
    else
      setCursorPosition(AStart);
  end;
end;

procedure TQtLineEdit.setText(const AText: WideString);
begin
  QLineEdit_setText(QLineEditH(Widget), @AText);
end;

procedure TQtLineEdit.Cut;
begin
  QLineEdit_cut(QLineEditH(Widget));
end;

procedure TQtLineEdit.Copy;
begin
  QLineEdit_copy(QLineEditH(Widget));
end;

procedure TQtLineEdit.Paste;
begin
  QLineEdit_paste(QLineEditH(Widget));
end;

procedure TQtLineEdit.Undo;
begin
  QLineEdit_undo(QLineEditH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtLineEdit.SignalTextChanged
  Params:  PWideString
  Returns: Nothing

  Fires OnChange() event of TCustomEdit
 ------------------------------------------------------------------------------}
procedure TQtLineEdit.SignalTextChanged(p1: PWideString); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(Msg);
end;

{ TQtTextEdit }

function TQtTextEdit.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTextEdit.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QTextEdit_create(Parent);
  FKeysToEat := [];
  FUndoAvailable := False;
  {drops are handled by slotDropFiles()}
  QWidget_setAcceptDrops(Result, False);
end;

procedure TQtTextEdit.append(AStr: WideString);
begin
  QTextEdit_append(QTextEditH(Widget), @AStr);
end;

function TQtTextEdit.getAlignment: QtAlignment;
begin
  Result := QTextEdit_alignment(QTextEditH(Widget));
end;

function TQtTextEdit.getBlockCount: Integer;
begin
  Result := QTextDocument_blockCount(QTextEdit_document(QTextEditH(Widget)));
end;

function TQtTextEdit.getCursorPosition: Integer;
var
  TextCursor: QTextCursorH;
begin
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  if QTextCursor_isNull(TextCursor) then
    Result := 0
  else
    Result := QTextCursor_position(TextCursor);
  QTextCursor_destroy(TextCursor);
end;

function TQtTextEdit.getMaxLength: Integer;
begin
  {$note implement TQtTextEdit.getMaxLength}
  Result := 0;
end;

function TQtTextEdit.getText: WideString;
begin
  QTextEdit_toPlainText(QTextEditH(Widget), @Result);
end;

function TQtTextEdit.getTextStatic: Boolean;
begin
  Result := False;
end;

function TQtTextEdit.getSelectionStart: Integer;
var
  TextCursor: QTextCursorH;
begin
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  Result := QTextCursor_selectionStart(TextCursor);
  QTextCursor_destroy(TextCursor);
end;

function TQtTextEdit.getSelectionEnd: Integer;
var
  TextCursor: QTextCursorH;
begin
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  Result := QTextCursor_selectionEnd(TextCursor);
  QTextCursor_destroy(TextCursor);
end;

function TQtTextEdit.getSelectionLength: Integer;
begin
  Result := getSelectionEnd - getSelectionStart;
end;

function TQtTextEdit.isUndoAvailable: Boolean;
begin
  Result := QTextEdit_isUndoRedoEnabled(QTextEditH(Widget)) and FUndoAvailable;
end;

procedure TQtTextEdit.setEchoMode(const AMode: QLineEditEchoMode);
begin
  {$note implement TQtTextEdit.setEchoMode}
end;

procedure TQtTextEdit.setLineWrapMode(const AMode: QTextEditLineWrapMode);
begin
  QTextEdit_setLineWrapMode(QTextEditH(Widget), AMode);
end;

procedure TQtTextEdit.setMaxLength(const ALength: Integer);
begin
  {$note implement TQtTextEdit.setMaxLength}
end;

procedure TQtTextEdit.insertLine(const AIndex: integer; AText: WideString);
var
  QtCursor: QTextCursorH;
  WrapMode: QTextEditLineWrapMode;
begin
  WrapMode := QTextEdit_lineWrapMode(QTextEditH(Widget));
  {we must remove wrapping to get correct line !}
  setLineWrapMode(QTextEditNoWrap);
  QtCursor := QTextCursor_create();
  try
    QTextEdit_textCursor(QTextEditH(Widget), QtCursor);
    QTextCursor_beginEditBlock(QtCursor);
    QTextCursor_movePosition(QtCursor, QTextCursorStart,
      QTextCursorMoveAnchor, 1);
    QTextCursor_movePosition(QtCursor, QTextCursorStartOfLine,
      QTextCursorMoveAnchor, 1);
    QTextCursor_movePosition(QtCursor, QTextCursorDown,
      QTextCursorMoveAnchor, AIndex);
    QTextCursor_insertBlock(QtCursor);
    QTextCursor_movePosition(QtCursor, QTextCursorUp,
      QTextCursorMoveAnchor, 1);
    QTextCursor_insertText(QtCursor, @AText);
    QTextCursor_endEditBlock(QtCursor);
  finally
    QTextCursor_destroy(QtCursor);
    setLineWrapMode(WrapMode);
  end;
end;

procedure TQtTextEdit.removeLine(const AIndex: integer);
var
  QtCursor: QTextCursorH;
  B: Boolean;
  WrapMode: QTextEditLineWrapMode;
  Diff: Integer;
begin
  Diff := getBlockCount - AIndex;
  {we must remove wrapping to get correct line !}
  WrapMode := QTextEdit_lineWrapMode(QTextEditH(Widget));
  setLineWrapMode(QTextEditNoWrap);
  QtCursor := QTextCursor_create();
  try
    QTextEdit_textCursor(QTextEditH(Widget), QtCursor);
    QTextCursor_beginEditBlock(QtCursor);
    // small optimization if we delete from end of list
    if Diff <= 2 then
    begin
      QTextCursor_movePosition(QtCursor, QTextCursorEnd,
        QTextCursorMoveAnchor, 1);
      QTextCursor_movePosition(QtCursor, QTextCursorStartOfLine,
        QTextCursorMoveAnchor, 1);
      QTextCursor_movePosition(QtCursor, QTextCursorUp,
        QTextCursorMoveAnchor, Diff - 1);
    end else
    begin
      QTextCursor_movePosition(QtCursor, QTextCursorStart,
        QTextCursorMoveAnchor, 1);
      QTextCursor_movePosition(QtCursor, QTextCursorStartOfLine,
        QTextCursorMoveAnchor, 1);
      QTextCursor_movePosition(QtCursor, QTextCursorDown,
        QTextCursorMoveAnchor, AIndex);
      QTextCursor_movePosition(QtCursor, QTextCursorEndOfLine,
        QTextCursorMoveAnchor, 1);
    end;

    QTextCursor_select(QtCursor, QTextCursorLineUnderCursor);
    B := QTextCursor_hasSelection(QtCursor);
    if not B then
      QTextCursor_deleteChar(QtCursor)
    else
      QTextCursor_deletePreviousChar(QtCursor);

    if (AIndex = 0) then
    begin
      QTextCursor_movePosition(QtCursor, QTextCursorStart,
        QTextCursorMoveAnchor, 1);
      QTextCursor_movePosition(QtCursor, QTextCursorStartOfLine,
        QTextCursorMoveAnchor, 1);
      QTextCursor_movePosition(QtCursor, QTextCursorDown,
        QTextCursorMoveAnchor, 1);
    end;
    if B then
      QTextCursor_deletePreviousChar(QtCursor);
    QTextCursor_endEditBlock(QtCursor);
  finally
    QTextCursor_destroy(QtCursor);
    setLineWrapMode(WrapMode);
  end;
end;

procedure TQtTextEdit.setLineText(const AIndex: integer; AText: WideString);
var
  QtCursor: QTextCursorH;
  WrapMode: QTextEditLineWrapMode;
begin
  {we must remove wrapping to get correct line !}
  WrapMode := QTextEdit_lineWrapMode(QTextEditH(Widget));
  setLineWrapMode(QTextEditNoWrap);
  QtCursor := QTextCursor_create();
  try
    QTextEdit_textCursor(QTextEditH(Widget), QtCursor);
    QTextCursor_beginEditBlock(QtCursor);
    QTextCursor_movePosition(QtCursor, QTextCursorStart,
      QTextCursorMoveAnchor, 1);
    QTextCursor_movePosition(QtCursor, QTextCursorStartOfLine,
      QTextCursorMoveAnchor, 1);
    QTextCursor_movePosition(QtCursor, QTextCursorDown,
      QTextCursorMoveAnchor, AIndex);
    QTextCursor_select(QtCursor, QTextCursorLineUnderCursor);
    QTextCursor_removeSelectedText(QtCursor);
    QTextCursor_insertText(QtCursor, @AText);
    QTextCursor_movePosition(QtCursor, QTextCursorEndOfLine,
      QTextCursorMoveAnchor, 1);
    QTextCursor_endEditBlock(QtCursor);
  finally
    QTextCursor_destroy(QtCursor);
    setLineWrapMode(WrapMode);
  end;
end;

procedure TQtTextEdit.setText(const AText: WideString);
begin
  QTextEdit_setPlainText(QTextEditH(Widget), @AText);
end;

procedure TQtTextEdit.setReadOnly(const AReadOnly: Boolean);
begin
  QTextEdit_setReadOnly(QTextEditH(Widget), AReadOnly);
end;

procedure TQtTextEdit.setSelection(const AStart, ALength: Integer);
var
  TextCursor: QTextCursorH;
begin
  if AStart >= 0 then
  begin
    TextCursor := QTextCursor_create();
    QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
    QTextCursor_clearSelection(TextCursor);
    QTextCursor_setPosition(TextCursor, AStart);
    QTextCursor_setPosition(TextCursor, AStart + ALength, QTextCursorKeepAnchor);
    QTextEdit_setTextCursor(QTextEditH(Widget), TextCursor);
    QTextCursor_destroy(TextCursor);
  end;
end;

procedure TQtTextEdit.setTabChangesFocus(const AValue: Boolean);
begin
  QTextEdit_setTabChangesFocus(QTextEditH(Widget), AValue);
end;

procedure TQtTextEdit.Cut;
begin
  QTextEdit_cut(QTextEditH(Widget));
end;

procedure TQtTextEdit.Copy;
begin
  QTextEdit_copy(QTextEditH(Widget));
end;

procedure TQtTextEdit.Paste;
begin
  QTextEdit_paste(QTextEditH(Widget));
end;

procedure TQtTextEdit.Undo;
begin
  QTextEdit_undo(QTextEditH(Widget));
end;

procedure TQtTextEdit.SetAlignment(const AAlignment: QtAlignment);
var
  TextCursor: QTextCursorH;
begin
  // QTextEdit supports alignment for every paragraph. We need to align all text.
  // So, we should select all text, set format, and clear selection
  
  // 1. Select all text
  QTextEdit_selectAll(QTextEditH(Widget));
  
  // 2. Set format
  QTextEdit_setAlignment(QTextEditH(Widget), AAlignment);
  
  // 3. Clear selection. To unselect all document we must create new text cursor,
  // get format from Text Edit, clear selection in cursor and set it back to Text Edit
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  QTextCursor_clearSelection(TextCursor);
  QTextEdit_setTextCursor(QTextEditH(Widget), TextCursor);
  QTextCursor_destroy(TextCursor);
end;

procedure TQtTextEdit.setBorder(const ABorder: Boolean);
begin
  if ABorder then
    QFrame_setFrameShape(QFrameH(Widget), QFrameStyledPanel)
  else
    QFrame_setFrameShape(QFrameH(Widget), QFrameNoFrame);
end;

procedure TQtTextEdit.setCursorPosition(const ACursorPosition: Integer);
var
  TextCursor: QTextCursorH;
begin
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  if not QTextCursor_isNull(TextCursor) then
    QTextCursor_setPosition(TextCursor, ACursorPosition);
  QTextCursor_destroy(TextCursor);
end;

procedure TQtTextEdit.setDefaultColorRoles;
begin
  WidgetColorRole := QPaletteBase;
  TextColorRole := QPaletteText;
end;

procedure TQtTextEdit.AttachEvents;
begin
  inherited AttachEvents;

  FUndoAvailableHook := QTextEdit_hook_create(Widget);
  QTextEdit_hook_hook_undoAvailable(FUndoAvailableHook, @SignalUndoAvailable);

  FViewportEventHook := QObject_hook_create(viewportWidget);
  QObject_hook_hook_events(FViewportEventHook, @viewportEventFilter);

end;

procedure TQtTextEdit.DetachEvents;
begin
  QObject_hook_destroy(FViewportEventHook);
  inherited DetachEvents;
end;

function TQtTextEdit.viewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  Result := False;
  QEvent_accept(Event);
  case QEvent_type(Event) of
    QEventContextMenu: SlotContextMenu(Sender, Event);
    QEventMouseButtonPress,
    QEventMouseButtonRelease,
    QEventMouseButtonDblClick: Result := SlotMouse(Sender, Event);
    QEventMouseMove: Result := SlotMouseMove(Sender, Event);
  end;
end;

function TQtTextEdit.getContextMenuPolicy: QtContextMenuPolicy;
begin
  Result := QWidget_contextMenuPolicy(viewPortWidget);
end;

procedure TQtTextEdit.setContextMenuPolicy(const AValue: QtContextMenuPolicy);
begin
  QWidget_setContextMenuPolicy(viewportWidget, AValue);
end;

procedure TQtTextEdit.SignalUndoAvailable(b: Boolean); cdecl;
begin
  FUndoAvailable := b;
end;

{ TQtTabBar }

procedure TQtTabBar.AttachEvents;
begin
  inherited AttachEvents;
  FTabBarChangedHook := QTabBar_hook_create(QTabBarH(Widget));
  QTabBar_hook_hook_currentChanged(FTabBarChangedHook, @SignalTabBarCurrentChanged);
end;

procedure TQtTabBar.DetachEvents;
begin
  QTabBar_hook_destroy(FTabBarChangedHook);
  inherited DetachEvents;
end;

function TQtTabBar.GetTabRect(const AIndex: integer): TRect;
begin
  QTabBar_tabRect(QTabBarH(Widget), @Result, AIndex);
end;

procedure TQtTabBar.SignalTabBarCurrentChanged(Index: Integer); cdecl;
var
  Msg: TLMNotify;
  Hdr: TNmHdr;
begin
  if LCLObject = nil then
    Exit;

  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_NOTIFY;
  FillChar(Hdr, SizeOf(Hdr), 0);

  Hdr.hwndFrom := LCLObject.Handle;
  Hdr.Code := TCN_SELCHANGE;
  Hdr.idFrom := PtrUInt(TQtTabWidget(LCLObject.Handle).GetLCLPageIndex(Index));
  Msg.NMHdr := @Hdr;
  Msg.Result := 0;
  DeliverMessage(Msg);
end;

function TQtTabBar.SlotTabBarMouse(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
var
  MousePos: TQtPoint;
  NewIndex, CurIndex: Integer;
  Msg: TLMNotify;
  Hdr: TNmHdr;
  NewEvent: QMouseEventH;
  R: TRect;
  R1: TRect;
  BaseHeight: Integer;
begin
  Result := False;

  if not CanSendLCLMessage then
    exit;

  MousePos := QMouseEvent_pos(QMouseEventH(Event))^;
  NewIndex := QTabBar_tabAt(QTabBarH(Sender), @MousePos);
  CurIndex := QTabBar_currentIndex(QTabBarH(Sender));
  if (NewIndex <> CurIndex) and (NewIndex <> -1) and (CurIndex <> -1) then
  begin
    FillChar(Msg, SizeOf(Msg), 0);
    Msg.Msg := LM_NOTIFY;
    FillChar(Hdr, SizeOf(Hdr), 0);

    Hdr.hwndFrom := LCLObject.Handle;
    Hdr.Code := TCN_SELCHANGING;
    Hdr.idFrom := TQtTabWidget(LCLObject.Handle).GetLCLPageIndex(CurIndex);
    Msg.NMHdr := @Hdr;
    Msg.Result := 0;
    DeliverMessage(Msg);

    if Msg.Result <> 0 then
    begin
      QEvent_accept(Event);
      Result := True;
      Exit;
    end;
  end;

  if Assigned(FOwner) then
  begin
    R := TQtTabWidget(FOwner).getGeometry;
    R1 := getGeometry;
    BaseHeight := QStyle_pixelMetric(QApplication_style(),
      QStylePM_TabBarBaseHeight);

    case TQtTabWidget(FOwner).getTabPosition of
      QTabWidgetNorth:
        begin
          MousePos.Y := R.Top - (R1.Bottom - MousePos.Y);
          MousePos.X := MousePos.X - BaseHeight;
        end;
      QTabWidgetWest:
        begin
          MousePos.x := R.Left - (R1.Right - MousePos.X);
          MousePos.y := MousePos.Y - BaseHeight;
        end;
      QTabWidgetEast:
        begin
          MousePos.X := R1.Left + MousePos.X - BaseHeight;
          MousePos.y := MousePos.Y - BaseHeight;
        end;
      QTabWidgetSouth:
        begin
          MousePos.Y := R1.Top + MousePos.Y - BaseHeight;
          MousePos.X := MousePos.X - BaseHeight;
        end;
    end;
    NewEvent := QMouseEvent_create(QEvent_type(Event), @MousePos,
        QMouseEvent_globalPos(QMouseEventH(Event)),
        QMouseEvent_button(QMouseEventH(Event)),
        QMouseEvent_buttons(QMouseEventH(Event)),
        QInputEvent_modifiers(QInputEventH(Event))
      );
    SlotMouse(Sender, NewEvent);
    QMouseEvent_destroy(NewEvent);
  end else
    SlotMouse(Sender, Event);
end;

function TQtTabBar.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
{$IFDEF QT_ENABLE_LCL_PAINT_TABS}
var
  R: TRect;
{$ENDIF}
begin
  Result := False;
  QEvent_accept(Event);
  if LCLObject = nil then
    exit;
  {$IF DEFINED(VerboseQt) OR DEFINED(VerboseQtEvents)}
  WriteLn('TQtTabBar.EventFilter: Sender=', IntToHex(PtrUInt(Sender),8),
    ' LCLObject=', dbgsName(LCLObject),
    ' Event=', EventTypeToStr(Event),' inUpdate=',inUpdate);
  {$endif}

  BeginEventProcessing;
  case QEvent_type(Event) of
    {$IFDEF QT_ENABLE_LCL_PAINT_TABS}
    QEventPaint:
      begin
        QPaintEvent_rect(QPaintEventH(Event), @R);
        // qt paints tab
        QObject_event(Sender, Event);
        // LCL can do whatever now
        SlotPaint(Sender, Event);
        Result := True;
        QEvent_ignore(Event);
      end;
    {$ENDIF}
    QEventKeyPress,
    QEventKeyRelease: SlotKey(Sender, Event);
    QEventMouseButtonPress,
    QEventMouseButtonRelease,
    QEventMouseButtonDblClick:
      begin
        if QMouseEvent_button(QMouseEventH(Event)) = QtLeftButton then
        begin
          Result := SlotTabBarMouse(Sender, Event);
          SetNoMousePropagation(QWidgetH(Sender), False);
        end;
      end;
  else
    QEvent_ignore(Event);
  end;
  EndEventProcessing;
end;

{ TQtTabWidget }

function TQtTabWidget.getTabBar: TQtTabBar;
begin
  if FTabBar = nil then
  begin
    {$note TQtTabWidget.getTabBar: we can remove QLCLTabWidget, and get it like StackWidget,
     objectName is qt_tabwidget_tabbar.}
    FTabBar := TQtTabBar.CreateFrom(LCLObject, QLCLTabWidget_tabBarHandle(QTabWidgetH(Widget)));
    {$IFDEF QT_ENABLE_LCL_PAINT_TABS}
    FTabBar.HasPaint := True;
    {$ENDIF}
    FTabBar.FOwner := Self;
    FTabBar.AttachEvents;
  end;
  Result := FTabBar;
end;

function TQtTabWidget.getShowTabs: Boolean;
begin
  Result := TabBar.getVisible;
end;

function TQtTabWidget.getStackWidget: QWidgetH;
var
  List: TPtrIntArray;
  Obj: QObjectH;
  i: Integer;
  WStr: WideString;
begin
  if FStackWidget = nil then
  begin
    QObject_children(Widget, @List);
    for i := 0 to High(List) do
    begin
      Obj := QObjectH(List[i]);
      QObject_objectName(Obj, @WStr);
      {do not localize !}
      if WStr = 'qt_tabwidget_stackedwidget' then
      begin
        FStackWidget := QWidgetH(List[i]);
        break;
      end;
    end;
    FCentralWidget := FStackWidget;
  end;
  Result := FStackWidget;
end;

procedure TQtTabWidget.setShowTabs(const AValue: Boolean);
begin
  TabBar.setVisible(AValue);
end;

function TQtTabWidget.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTabWidget.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QTabWidget_create(Parent);
  
  {note: for some reason tabbar scroll buttons are not enabled as default option
  under mac - but under linux & win are. Qt docs says that this options is enabled
  as default ... possible qt bug}
  {$ifdef darwin}
  QTabWidget_setUsesScrollButtons(QTabWidgetH(Result), True);
  {$endif}
  if (QtVersionMajor = 4) and (QtVersionMinor < 6) then
    QWidget_setAutoFillBackground(Result, True);
end;

destructor TQtTabWidget.Destroy;
begin
  FTabBar.Free;
  inherited Destroy;
end;

procedure TQtTabWidget.DestroyNotify(AWidget: TQtWidget);
begin
  if AWidget = FTabBar then
    FTabBar := nil;
  inherited DestroyNotify(AWidget);
end;

function TQtTabWidget.GetLCLPageIndex(AIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := AIndex;
  if (LCLObject = nil) or
     (csDesigning in LCLObject.ComponentState) or
     not (LCLObject is TCustomNotebook) then
    Exit;
  I := 0;
  while (I < TCustomNotebook(LCLObject).PageCount) and (I <= Result) do
  begin
    if not TCustomNotebook(LCLObject).Page[I].TabVisible then
      Inc(Result);
    Inc(I);
  end;
end;

procedure TQtTabWidget.AttachEvents;
begin
  inherited AttachEvents;

  {initialize our tabbar}
  TabBar;

  FCurrentChangedHook := QTabWidget_hook_create(Widget);
  QTabWidget_hook_hook_currentChanged(FCurrentChangedHook, @SignalCurrentChanged);

  FCloseRequestedHook := QTabWidget_hook_create(Widget);
  QTabWidget_hook_hook_tabCloseRequested(FCloseRequestedHook, @SignalCloseRequested);

  FStackedWidgetHook := QObject_hook_create(StackWidget);
  QObject_hook_hook_events(FStackedWidgetHook, @EventFilter);

end;

procedure TQtTabWidget.DetachEvents;
begin

  if FStackedWidgetHook <> nil then
  begin
    QObject_hook_destroy(FStackedWidgetHook);
    FStackedWidgetHook := nil;
  end;

  QTabWidget_hook_destroy(FCurrentChangedHook);
  QTabWidget_hook_destroy(FCloseRequestedHook);
  inherited DetachEvents;
end;

function TQtTabWidget.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
{$IFDEF QT_ENABLE_LCL_PAINT_TABS}
var
  R: TRect;
  TabGeom: TRect;
  Pt: TPoint;
{$ENDIF}
begin

  Result := False;
  QEvent_accept(Event);
  if LCLObject = nil then
    exit;

  if (Sender = FStackWidget) then
  begin
    {$IF DEFINED(VerboseQt) OR DEFINED(VerboseQtEvents)}
    WriteLn('TQtTabWidget.EventFilter: STACKWIDGET Sender=', IntToHex(PtrUInt(Sender),8),
      ' LCLObject=', dbgsName(LCLObject),
      ' Event=', EventTypeToStr(Event),' inUpdate=',inUpdate);
    {$endif}
    case QEvent_type(Event) of
      QEventResize:
        if LCLObject.ClientRectNeedsInterfaceUpdate then
          LCLObject.InvalidateClientRectCache(False);
      // layoutRequest from stacked widget is very important !
      QEventLayoutRequest: LCLObject.DoAdjustClientRectChange(False);
    end;
    exit;
  end;

  BeginEventProcessing;
  case QEvent_type(Event) of
    {$IFDEF QT_ENABLE_LCL_PAINT_TABS}
    QEventPaint:
      begin
        {this paint event comes after tabbar paint event,
         so we have to exclude our tabs from painting}
        QPaintEvent_rect(QPaintEventH(Event), @R);
        QWidget_geometry(TabBar.Widget, @TabGeom);
        Pt.X := R.Left;
        Pt.Y := R.Top;
        Result := PtInRect(TabGeom, Pt) and
          (R.Bottom - R.Top = TabGeom.Bottom - TabGeom.Top) and
          (TabAt(Pt) >= 0);
        if Result then
          QEvent_ignore(Event);
      end;
    {$ENDIF}
    QEventKeyPress,
    QEventKeyRelease: QEvent_ignore(Event);
    else
      Result := inherited EventFilter(Sender, Event);
  end;

  EndEventProcessing;
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.insertTab
  Params:  index: Integer; page: QWidgetH; p2: PWideString
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtTabWidget.insertTab(index: Integer; page: QWidgetH; p2: WideString): Integer; overload;
begin
  Result := insertTab(index, page, nil, p2);
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.insertTab
  Params:  index: Integer; page: QWidgetH; icon: QIconH; p2: PWideString
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtTabWidget.insertTab(index: Integer; page: QWidgetH; icon: QIconH; p2: WideString): Integer; overload;
var
  UseAdd: Boolean;
begin
  UseAdd := Index > QTabWidget_count(QTabWidgetH(Widget)) - 1;
  if icon <> nil then
  begin
    if UseAdd then
      Result := QTabWidget_addTab(QTabWidgetH(Widget), page, icon, @p2)
    else
      Result := QTabWidget_insertTab(QTabWidgetH(Widget), index, page, icon, @p2)
  end else
  begin
    if UseAdd then
      Result := QTabWidget_addTab(QTabWidgetH(Widget), page, @p2)
    else
      Result := QTabWidget_insertTab(QTabWidgetH(Widget), index, page, @p2);
  end;
end;

function TQtTabWidget.getClientBounds: TRect;
begin
  QWidget_contentsRect(StackWidget, @Result)
end;

function TQtTabWidget.getCurrentIndex: Integer;
begin
  Result := QTabWidget_currentIndex(QTabWidgetH(Widget));
end;

function TQtTabWidget.getTabPosition: QTabWidgetTabPosition;
begin
  Result := QTabWidget_tabPosition(QTabWidgetH(Widget));
end;

procedure TQtTabWidget.removeTab(AIndex: Integer);
begin
  QTabWidget_removeTab(QTabWidgetH(Widget), AIndex);
end;

procedure TQtTabWidget.setCurrentIndex(AIndex: Integer);
begin
  QTabWidget_setCurrentIndex(QTabWidgetH(Widget), AIndex);
end;

procedure TQtTabWidget.setCurrentWidget(APage: TQtWidget);
begin
  QTabWidget_setCurrentWidget(QTabWidgetH(Widget), APage.Widget);
  APage.setFocus;
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.setTabPosition
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTabWidget.setTabPosition(ATabPosition: QTabWidgetTabPosition);
begin
  QTabWidget_setTabPosition(QTabWidgetH(Widget), ATabPosition);
end;

procedure TQtTabWidget.setTabIcon(index: Integer; icon: QIconH);
begin
  QTabWidget_setTabIcon(QTabWidgetH(Widget), index, icon);
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.SignalCurrentChanged
  Params:  None
  Returns: Nothing
           Changes ActivePage of TPageControl
 ------------------------------------------------------------------------------}
procedure TQtTabWidget.SignalCurrentChanged(Index: Integer); cdecl;
var
  Msg: TLMNotify;
  Hdr: TNmHdr;
begin
  if LCLObject = nil then
    Exit;

  if InUpdate then
    exit;

  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_NOTIFY;
  FillChar(Hdr, SizeOf(Hdr), 0);

  Hdr.hwndFrom := LCLObject.Handle;
  Hdr.Code := TCN_SELCHANGING;
  Hdr.idFrom := PtrUInt(GetLCLPageIndex(Index));
  Msg.NMHdr := @Hdr;
  Msg.Result := 0;
  DeliverMessage(Msg);
end;

procedure TQtTabWidget.SignalCloseRequested(Index: Integer); cdecl;
var
  APage: TCustomPage;
begin
  APage := TCustomNotebook(LCLObject).Page[GetLCLPageIndex(Index)];
  if not APage.HandleAllocated then
    Exit;
  TCustomNoteBook(LCLObject).DoCloseTabClicked(APage);
end;

function TQtTabWidget.indexOf(const AWidget: QWidgetH): integer;
begin
  Result := QTabWidget_indexOf(QTabWidgetH(Widget), AWidget);
end;

procedure TQtTabWidget.setTabText(index: Integer; p2: WideString);
begin
  QTabWidget_setTabText(QTabWidgetH(Widget), index, @p2);
end;

procedure TQtTabWidget.setTabsClosable(AValue: Boolean);
begin
  QTabWidget_setTabsClosable(QTabWidgetH(Widget), AValue);
end;

function TQtTabWidget.tabAt(APoint: TPoint): Integer;
var
  AQtPoint: TQtPoint;
  R: TRect;
begin
  if (APoint.Y < 0) or (APoint.X < 0) then
  begin
    {some themes (eg. MacOSX) moves tab buttons
     into the middle of parent, so we must
     take it's geometry into account.}
    R := TabBar.getGeometry;
    QWidget_pos(getStackWidget, @AQtPoint);
    AQtPoint.x := AQtPoint.x + APoint.x;
    AQtPoint.y := AQtPoint.y + APoint.y;

    if R.Left <> 0 then
      dec(AQtPoint.x, R.Left);
    if R.Top <> 0 then
      dec(AQtPoint.y, R.Top);
  end else
    AQtPoint := QtPoint(APoint.x, APoint.y);
  Result := QTabBar_tabAt(QTabBarH(TabBar.Widget), @AQtPoint);
end;

{ TQtComboBox }

function TQtComboBox.GetLineEdit: TQtLineEdit;
begin
  if not getEditable then
  begin
    FLineEdit := nil
  end
  else
  begin
    if FLineEdit = nil then
    begin
      FLineEdit := TQtLineEdit.CreateFrom(LCLObject, QComboBox_lineEdit(QComboBoxH(Widget)));
      FLineEdit.FOwner := Self;
      QObject_disconnect(FLineEdit.Widget, '2returnPressed()', Widget, '1_q_returnPressed()');
      FLineEdit.ChildOfComplexWidget := ccwComboBox;
      FLineEdit.AttachEvents;
    end;
  end;
  Result := FLineEdit;
end;

procedure TQtComboBox.SetOwnerDrawn(const AValue: Boolean);
begin
  FOwnerDrawn := AValue;
  if FDropList <> nil then
    FDropList.OwnerDrawn := FOwnerDrawn;
end;

function TQtComboBox.GetDropList: TQtListWidget;
begin
  if FDropList = nil then
  begin
    FDropList := TQtListWidget.CreateFrom(LCLObject, QListWidget_create());
    FDropList.FOwner := Self;
    FDropList.setAttribute(QtWA_NoMousePropagation, False);
    FDropList.OwnerDrawn := OwnerDrawn;
    FDropList.ChildOfComplexWidget := ccwComboBox;
    QComboBox_setModel(QComboBoxH(Widget), FDropList.getModel);
    QComboBox_setView(QComboBoxH(Widget), QListWidgetH(FDropList.Widget));
    FDropList.AttachEvents;
  end;
  Result := FDropList;
end;

function TQtComboBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtComboBox.Create');
  {$endif}
  FDropListVisibleInternal := False;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QComboBox_create(Parent);
  // disable AutoCompletion. LCL has its own
  QComboBox_setAutoCompletion(QComboboxH(Result), False);
  FLineEdit := nil;
  FOwnerDrawn := False;
end;

function TQtComboBox.getCursorPosition: Integer;
begin
  if LineEdit <> nil then
    Result := LineEdit.getCursorPosition
  else
    Result := 0;
end;

function TQtComboBox.getMaxLength: Integer;
begin
  if LineEdit <> nil then
    Result := LineEdit.getMaxLength
  else
    Result := 0;
end;

function TQtComboBox.getSelectionStart: Integer;
begin
  if (LineEdit <> nil) then
    Result := LineEdit.getSelectionStart
  else
    Result := 0;
end;

function TQtComboBox.getSelectionLength: Integer;
begin
  if (LineEdit <> nil) then
    Result := LineEdit.getSelectionLength
  else
    Result := 0;
end;

function TQtComboBox.isUndoAvailable: Boolean;
begin
  if LineEdit <> nil then
    Result := LineEdit.isUndoAvailable
  else
    Result := False;
end;

procedure TQtComboBox.setBorder(const ABorder: Boolean);
begin
  QComboBox_setFrame(QComboBoxH(Widget), ABorder);
end;

procedure TQtComboBox.setEchoMode(const AMode: QLineEditEchoMode);
begin
  if LineEdit <> nil then
    LineEdit.setEchoMode(AMode);
end;

procedure TQtComboBox.setMaxLength(const ALength: Integer);
begin
  if LineEdit <> nil then
    LineEdit.setMaxLength(ALength);
end;

procedure TQtComboBox.setReadOnly(const AReadOnly: Boolean);
begin
  setEditable(not AReadOnly);
end;

procedure TQtComboBox.setSelection(const AStart, ALength: Integer);
begin
  if LineEdit <> nil then
    LineEdit.setSelection(AStart, ALength);
end;

procedure TQtComboBox.setCursorPosition(const ACursorPosition: Integer);
begin
  if LineEdit <> nil then
    LineEdit.setCursorPosition(ACursorPosition);
end;

procedure TQtComboBox.Cut;
begin
  if LineEdit <> nil then
    LineEdit.Cut;
end;

procedure TQtComboBox.Copy;
begin
  if LineEdit <> nil then
    LineEdit.Copy;
end;

procedure TQtComboBox.Paste;
begin
  if LineEdit <> nil then
    LineEdit.Paste;
end;

procedure TQtComboBox.Undo;
begin
  if LineEdit <> nil then
    LineEdit.Undo;
end;

{------------------------------------------------------------------------------
  Function: TQtComboBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtComboBox.Destroy;
begin
  FDropList.Free;
  FLineEdit.Free;
  inherited Destroy;
end;

procedure TQtComboBox.DestroyNotify(AWidget: TQtWidget);
begin
  if AWidget = FLineEdit then
    FLineEdit := nil;
  if AWidget = FDropList then
    FDropList := nil;

  if Assigned(FList) then
    FList := nil;

  inherited DestroyNotify(AWidget);
end;

procedure TQtComboBox.ClearItems;
begin
  QComboBox_clear(QComboBoxH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtComboBox.currentIndex
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtComboBox.currentIndex: Integer;
begin
  Result := QComboBox_currentIndex(QComboBoxH(Widget));
end;

function TQtComboBox.getDroppedDown: Boolean;
begin
  Result := QWidget_isVisible(QComboBox_view(QComboBoxH(Widget)));
end;

function TQtComboBox.getEditable: Boolean;
begin
  Result := QComboBox_isEditable(QComboBoxH(Widget));
end;

function TQtComboBox.getMaxVisibleItems: Integer;
begin
  Result := QComboBox_maxVisibleItems(QComboboxH(Widget));
end;

function TQtComboBox.getText: WideString;
begin
  QComboBox_currentText(QComboBoxH(Widget), @Result);
  if FOwnerDrawn and (FLineEdit = nil) and
    (Result = '') and (Result <> FText) then
    Result := FText;
end;

function TQtComboBox.getTextStatic: Boolean;
begin
  Result := False;
end;

procedure TQtComboBox.insertItem(AIndex: Integer; AText: String);
var
  Str: WideString;
begin
  Str := GetUtf8String(AText);
  insertItem(AIndex, @Str);
end;

procedure TQtComboBox.insertItem(AIndex: Integer; AText: PWideString);
begin
  QComboBox_insertItem(QComboBoxH(WIdget), AIndex, AText, QVariant_create());
end;

{------------------------------------------------------------------------------
  Function: TQtComboBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtComboBox.setCurrentIndex(index: Integer);
begin
  // don't fire any events when we are changing it from the LCL side
  BeginUpdate;
  QComboBox_setCurrentIndex(QComboBoxH(Widget), index);
  EndUpdate;
end;

procedure TQtComboBox.setDefaultColorRoles;
begin
  WidgetColorRole := QPaletteBase;
  TextColorRole := QPaletteText;
end;

procedure TQtComboBox.setDroppedDown(const ADroppedDown: Boolean);
begin
  if ADroppedDown <> QWidget_isVisible(QComboBox_view(QComboBoxH(Widget))) then
  begin
    if ADroppedDown then
      QComboBox_showPopup(QComboBoxH(Widget))
    else
      QComboBox_hidePopup(QComboBoxH(Widget));
  end;
end;

procedure TQtComboBox.setMaxVisibleItems(ACount: Integer);
begin
  QComboBox_setMaxVisibleItems(QComboboxH(Widget), ACount);
end;

procedure TQtComboBox.setEditable(const AValue: Boolean);
begin
  QComboBox_setEditable(QComboBoxH(Widget), AValue);
  if not AValue then
    FreeAndNil(FLineEdit)
  else
  begin
    LineEdit.setFocusPolicy(getFocusPolicy);
    setText(FText);
  end;
end;

procedure TQtComboBox.setItemText(AIndex: Integer; AText: String);
var
  Str: WideString;
  item: QListWidgetItemH;
  R: TRect;
begin
  if (AIndex >= 0) and (AIndex < QComboBox_count(QComboBoxH(Widget))) then
  begin
    Str := GetUTF8String(AText);
    QComboBox_setItemText(QComboBoxH(Widget), AIndex, @Str);
    {we must update our custom delegate}
    if (FDropList <> nil) and
       (FDropList.getVisible) and
       (FDropList.OwnerDrawn) then
    begin
      Item := FDropList.getItem(AIndex);
      if Item <> nil then
      begin
        R := FDropList.getVisualItemRect(Item);
        FDropList.Update(@R);
      end;
    end;
  end else
    insertItem(AIndex, AText);
end;

procedure TQtComboBox.setText(const W: WideString);
begin
  if FLineEdit = nil then
    FText := W
  else
    QComboBox_setEditText(QComboBoxH(Widget), @W);
end;

procedure TQtComboBox.removeItem(AIndex: Integer);
begin
  QComboBox_removeItem(QComboBoxH(Widget), AIndex);
end;

procedure TQtComboBox.AttachEvents;
begin
  inherited AttachEvents;

  FActivateHook := QComboBox_hook_create(Widget);
  FChangeHook := QComboBox_hook_create(Widget);
  FSelectHook := QComboBox_hook_create(Widget);

  // OnChange event if itemindex changed by mouse or kbd
  QComboBox_hook_hook_activated(FActivateHook, @SlotActivate);
  
  // OnChange event -> fires only when text changed
  QComboBox_hook_hook_editTextChanged(FChangeHook, @SlotChange);
  // OnSelect event
  QComboBox_hook_hook_currentIndexChanged(FSelectHook, @SlotSelect);
  
  // DropList events
  FDropListEventHook := QObject_hook_create(DropList.Widget);
  QObject_hook_hook_events(FDropListEventHook, @EventFilter);
end;

procedure TQtComboBox.DetachEvents;
begin
  QObject_hook_destroy(FDropListEventHook);
  QComboBox_hook_destroy(FActivateHook);
  QComboBox_hook_destroy(FChangeHook);
  QComboBox_hook_destroy(FSelectHook);

  inherited DetachEvents;
end;

procedure TQtComboBox.slotPaintCombo(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMPaint;
  AStruct: PPaintStruct;
  MsgItem: TLMDrawListItem;
  DrawStruct: TDrawListItemStruct;
  P: TPoint;
  Opt: QStyleOptionComboBoxH;
  R: TRect;
  State: QStyleState;
  CurrIndex: Integer;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtComboBox.SlotPaintCombo ', dbgsName(LCLObject));
  {$endif}
  CurrIndex := currentIndex;
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_PAINT;
  New(AStruct);
  FillChar(AStruct^, SizeOf(TPaintStruct), 0);
  Msg.PaintStruct := AStruct;

  with PaintData do
  begin
    PaintWidget := Widget;
    ClipRegion := QPaintEvent_Region(QPaintEventH(Event));
    if ClipRect = nil then
      New(ClipRect);
    QPaintEvent_Rect(QPaintEventH(Event), ClipRect);
  end;

  Msg.DC := BeginPaint(THandle(Self), AStruct^);
  FContext := Msg.DC;

  Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
  Msg.PaintStruct^.hdc := FContext;

  P := getClientOffset;
  inc(P.X, FScrollX);
  inc(P.Y, FScrollY);
  TQtDeviceContext(Msg.DC).translate(P.X, P.Y);

  TQtDeviceContext(Msg.DC).save;
  try
    Opt := QStyleOptionComboBox_create();
    QStyleOption_initFrom(Opt, Widget);
    State := QStyleOption_state(opt);
    QStyleOption_rect(Opt, @R);
    QPainter_setClipRect(TQtDeviceContext(Msg.DC).Widget, @R);

    QStyle_drawComplexControl(QApplication_style(), QStyleCC_ComboBox, Opt,
      TQtDeviceContext(Msg.DC).Widget, Widget);
    QStyle_subControlRect(QApplication_style(), @R, QStyleCC_ComboBox, Opt,
      QStyleSC_ComboBoxEditField , Widget);
    if CurrIndex < 0 then
    begin
      QStyleOptionComboBox_setCurrentText(Opt, @FText);
      QStyle_drawControl(QApplication_style(), QStyleCE_ComboBoxLabel, opt,
        TQtDeviceContext(Msg.DC).Widget, Widget);
    end;

  finally
    QStyleOptionComboBox_destroy(Opt);
    TQtDeviceContext(Msg.DC).restore;
  end;

  inc(R.Top);
  dec(R.Bottom);
  QPainter_setClipRect(TQTDeviceContext(Msg.DC).Widget, @R);

  DrawStruct.ItemID := UINT(CurrIndex);
  DrawStruct.Area := R;
  DrawStruct.DC := Msg.DC;

  DrawStruct.ItemState := [];

  // selected
  if (State and QStyleState_Selected) <> 0 then
    Include(DrawStruct.ItemState, odSelected);
  // disabled
  if (State and QStyleState_Enabled) = 0 then
    Include(DrawStruct.ItemState, odDisabled);
  // focused (QStyleState_FocusAtBorder?)
  if ((State and QStyleState_HasFocus) <> 0) or
    ((State and QStyleState_FocusAtBorder) <> 0) then
    Include(DrawStruct.ItemState, odFocused);
  // hotlight
  if (State and QStyleState_MouseOver) <> 0 then
    Include(DrawStruct.ItemState, odHotLight);

  MsgItem.Msg := LM_DRAWLISTITEM;
  MsgItem.DrawListItemStruct := @DrawStruct;

  try
    if CurrIndex >= 0 then
      DeliverMessage(MsgItem);
  finally
    Dispose(PaintData.ClipRect);
    Fillchar(FPaintData, SizeOf(FPaintData), 0);
    FContext := 0;
    EndPaint(THandle(Self), AStruct^);
    Dispose(AStruct);
  end;
end;

function TQtComboBox.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  R, R1: TRect;
  ButtonRect: TRect;
  P: TQtPoint;
  Pt: TPoint;
  Opt: QStyleOptionComboBoxH;
begin

  Result := False;
  QEvent_accept(Event);

  if LCLObject = nil then
    exit;

  if (FDropList <> nil) and (Sender = FDropList.Widget) then
  begin
    QEvent_ignore(Event);
    exit;
  end;

  BeginEventProcessing;

  case QEvent_type(Event) of
    QEventHide:
    begin
      if getVisible then
        SlotShow(False);
    end;
    QEventPaint:
    begin
      if FOwnerDrawn and not getEditable then
      begin
        SlotPaintCombo(Widget, Event);
        Result := True;
        QEvent_accept(Event);
      end;
    end;
    QEventMouseButtonPress:
    begin
      if not FDropListVisibleInternal and
        (QMouseEvent_button(QMouseEventH(Event)) = QtLeftButton) then
      begin
        // some themes have empty space around combo button !

        P := QMouseEvent_pos(QMouseEventH(Event))^;

        // our combo geometry
        R := getGeometry;

        // our combo arrow position
        opt := QStyleOptionComboBox_create();
        QStyle_subControlRect(QApplication_style(), @R1, QStyleCC_ComboBox,
          opt, QStyleSC_ComboBoxArrow, QComboBoxH(Widget));
        QStyleOptionComboBox_destroy(opt);

        Pt := Point(P.X, P.Y);

        R := Rect(0, 0, R.Right - R.Left, R.Bottom - R.Top);
        ButtonRect := Rect(R.Right + R1.Left, R.Top,
          R.Right - R1.Right, R.Bottom);

        if PtInRect(ButtonRect, Pt) then
          TCustomComboBox(LCLObject).IntfGetItems;
      end;
      Result := inherited EventFilter(Sender, Event);
    end;
    QEventKeyPress:
    begin
      if (QKeyEvent_key(QKeyEventH(Event)) = QtKey_F4) or
        ((QKeyEvent_key(QKeyEventH(Event)) = QtKey_Space) and
          not getEditable) then
      begin
        if not FDropListVisibleInternal then
          TCustomComboBox(LCLObject).IntfGetItems
        else
          Result := inherited EventFilter(Sender, Event);
      end else
        Result := inherited EventFilter(Sender, Event);
    end;
    else
      Result := inherited EventFilter(Sender, Event);
  end;
  
  EndEventProcessing;
end;

procedure TQtComboBox.preferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
var
  Size: TSize;
begin
  QComboBox_sizeHint(QComboBoxH(Widget), @Size);
  PreferredWidth := Size.cx;
  PreferredHeight := Size.cy;
end;

procedure TQtComboBox.SlotActivate(index: Integer); cdecl;
var
  Msg: TLMessage;
begin
  if InUpdate then
    Exit;

  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_ACTIVATE;
  DeliverMessage(Msg);
end;

procedure TQtComboBox.SlotChange(p1: PWideString); cdecl;
var
  Msg: TLMessage;
begin
  if InUpdate then
    Exit;
    
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_CHANGED;

  DeliverMessage(Msg);
end;

procedure TQtComboBox.SlotSelect(index: Integer); cdecl;
var
  Msg: TLMessage;
begin
  if InUpdate then
    exit;

  {we must fire OnChange() if it isn''t editable
   since SlotChange() fires only for editable
   comboboxes }
  if not getEditable then
  begin
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    DeliverMessage(Msg);
  end;
  
  FillChar(Msg, SizeOf(Msg), #0);
  
  Msg.Msg := LM_SELCHANGE;

  DeliverMessage(Msg);
end;

procedure TQtComboBox.SlotDropListVisibility(AVisible: Boolean); cdecl;
const
  VisibilityToCodeMap: array[Boolean] of Word =
  (
    CBN_CLOSEUP,
    CBN_DROPDOWN
  );
var
  Msg : TLMCommand;
begin
  if InUpdate then
    Exit;

  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := CN_COMMAND;
  Msg.NotifyCode := VisibilityToCodeMap[AVisible];

  DeliverMessage(Msg);
  FDropListVisibleInternal := AVisible;
end;

{ TQtAbstractSpinBox }

function TQtAbstractSpinBox.GetLineEdit: QLineEditH;
begin
  if FLineEdit = nil then
    FLineEdit := QLCLAbstractSpinBox_lineEditHandle(QAbstractSpinBoxH(Widget));
  Result := FLineEdit;
end;

function TQtAbstractSpinBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QAbstractSpinBox_create(Parent);
end;

function TQtAbstractSpinBox.getMaxLength: Integer;
begin
  if LineEdit <> nil then
    Result := QLineEdit_maxLength(LineEdit);
end;

function TQtAbstractSpinBox.getSelectionStart: Integer;
begin
  if (LineEdit <> nil) then
  begin
    if QLineEdit_hasSelectedText(LineEdit) then
      Result := QLineEdit_selectionStart(LineEdit)
    else
      Result := QLineEdit_cursorPosition(LineEdit);
  end
  else
    Result := 0;
end;

function TQtAbstractSpinBox.getSelectionLength: Integer;
var
  W: WideString;
begin
  if (LineEdit <> nil) and QLineEdit_hasSelectedText(LineEdit) then
  begin
    QLineEdit_selectedText(LineEdit, @W);
    Result := Length(W);
  end
  else
    Result := 0;
end;

function TQtAbstractSpinBox.isUndoAvailable: Boolean;
begin
  if LineEdit <> nil then
    Result := QLineEdit_isUndoAvailable(LineEdit)
  else
    Result := False;
end;

procedure TQtAbstractSpinBox.setBorder(const ABorder: Boolean);
begin
  QAbstractSpinBox_setFrame(QAbstractSpinBoxH(Widget), ABorder);
end;

procedure TQtAbstractSpinBox.setCursorPosition(const ACursorPosition: Integer);
begin
  if LineEdit <> nil then
    QLineEdit_setCursorPosition(LineEdit, ACursorPosition);
end;

procedure TQtAbstractSpinBox.setDefaultColorRoles;
begin
  WidgetColorRole := QPaletteBase;
  TextColorRole := QPaletteText;
end;

procedure TQtAbstractSpinBox.setEchoMode(const AMode: QLineEditEchoMode);
begin
  if LineEdit <> nil then
    QLineEdit_setEchoMode(LineEdit, AMode);
end;

procedure TQtAbstractSpinBox.setMaxLength(const ALength: Integer);
begin
  if LineEdit <> nil then
    QLineEdit_setMaxLength(LineEdit, ALength);
end;

procedure TQtAbstractSpinBox.setSelection(const AStart, ALength: Integer);
begin
  if (LineEdit <> nil) and (AStart >= 0) then
  begin
    if ALength > 0 then
      QLineEdit_setSelection(LineEdit, AStart, ALength)
    else
      QLineEdit_setCursorPosition(LineEdit, AStart);
  end;
end;

procedure TQtAbstractSpinBox.Cut;
begin
  if LineEdit <> nil then
    QLineEdit_cut(LineEdit);
end;

procedure TQtAbstractSpinBox.Copy;
begin
  if LineEdit <> nil then
    QLineEdit_copy(LineEdit);
end;

procedure TQtAbstractSpinBox.Paste;
begin
  if LineEdit <> nil then
    QLineEdit_paste(LineEdit);
end;

procedure TQtAbstractSpinBox.Undo;
begin
  if LineEdit <> nil then
    QLineEdit_undo(LineEdit);
end;

function TQtAbstractSpinBox.getCursorPosition: Integer;
begin
  if LineEdit <> nil then
    Result := QLineEdit_cursorPosition(LineEdit)
  else
    Result := 0;
end;

function TQtAbstractSpinBox.getReadOnly: Boolean;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.IsReadOnly');
  {$endif}
  Result := QAbstractSpinBox_isReadOnly(QAbstractSpinBoxH(Widget));
end;

function TQtAbstractSpinBox.getText: WideString;
begin
  if LineEdit <> nil then
    QLineEdit_text(LineEdit, @Result)
  else
    Result := '';
  {$ifdef VerboseQt}
  WriteLn('TQtAbstractSpinBox.GetText Result=',Result);
  {$endif}
end;

function TQtAbstractSpinBox.getTextStatic: Boolean;
begin
  Result := False;
end;

procedure TQtAbstractSpinBox.setFocusPolicy(const APolicy: QtFocusPolicy);
begin
  inherited setFocusPolicy(APolicy);
  QWidget_setFocusPolicy(LineEdit, APolicy);
end;

procedure TQtAbstractSpinBox.setReadOnly(const r: Boolean);
begin
  QAbstractSpinBox_setReadOnly(QAbstractSpinBoxH(Widget), r);
end;

procedure TQtAbstractSpinBox.setText(const W: WideString);
begin
  {$ifdef VerboseQt}
  WriteLn('TQtAbstractSpinBox.SetText W=',w);
  {$endif}
  if (LineEdit <> nil) then
    QLineEdit_setText(LineEdit, @W)
end;

procedure TQtAbstractSpinBox.AttachEvents;
begin
  inherited AttachEvents;

  FEditingFinishedHook := QAbstractSpinBox_hook_create(Widget);
  {TODO: find out which TLMessage should be sended }
  QAbstractSpinBox_hook_hook_editingFinished(FEditingFinishedHook, @SignalEditingFinished);
end;

procedure TQtAbstractSpinBox.DetachEvents;
begin
  QAbstractSpinBox_hook_destroy(FEditingFinishedHook);
  
  inherited DetachEvents;
end;

function TQtAbstractSpinBox.EventFilter(Sender: QObjectH; Event: QEventH
  ): Boolean; cdecl;
var
  IsDeleteKey: Boolean;
begin
  if (QEvent_type(Event) = QEventKeyPress) or
     (QEvent_type(Event) = QEventKeyRelease) then
    IsDeleteKey := (QKeyEvent_key(QKeyEventH(Event)) = QtKey_Delete) and
      (QKeyEvent_modifiers(QKeyEventH(Event)) = QtNoModifier)
  else
    IsDeleteKey := False;
  Result := inherited EventFilter(Sender, Event);
  {we must pass delete key to qt, qabstractspinbox doesn't like what we do}
  if IsDeleteKey then
    Result := False;
  {$ifdef CPU64 and not WIN64}
  if (FParentShowPassed = 1) then
  begin
    if QEvent_type(Event) <> QEventPaint then
    begin
      inc(FParentShowPassed);
      setValue(getValue);
    end;
  end;

  if (QEvent_type(Event) = QEventShowToParent) and
    (FParentShowPassed = 0) then
    inc(FParentShowPassed);
  {$endif}

end;

procedure TQtAbstractSpinBox.SignalEditingFinished; cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.SignalEditingFinished');
  {$endif}
  FillChar(Msg, SizeOf(Msg), #0);
  { TODO: Find out which message should be sended here
    problem:
     everything is fine when we work with mouse, or
     press TabKey to select next control, but if we
     connect OnKeyDown and say eg. VK_RETURN: SelectNext(ActiveControl, true, true)
     then spinedit text is always selected, nothing important but looks ugly.}
  //  Msg.Msg := LM_EXIT;
  //  DeliverMessage(Msg);
end;

{ TQtFloatSpinBox }

function TQtFloatSpinBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtFloatSpinBox.Create');
  {$endif}
  {$ifdef CPU64 and not WIN64}
  FParentShowPassed := 0;
  {$endif}
  FValue := 0;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QDoubleSpinBox_create(Parent);
end;

function TQtFloatSpinBox.getValue: Double;
begin
  Result := FValue;
end;

procedure TQtFloatSpinBox.setDecimals(const v: integer);
begin
  QDoubleSpinBox_setDecimals(QDoubleSpinBoxH(Widget), v);
end;

procedure TQtFloatSpinBox.setMinimum(const v: Double);
begin
  QDoubleSpinBox_setMinimum(QDoubleSpinBoxH(Widget), v);
end;

procedure TQtFloatSpinBox.setMaximum(const v: Double);
begin
  QDoubleSpinBox_setMaximum(QDoubleSpinBoxH(Widget), v);
end;

procedure TQtFloatSpinBox.setSingleStep(const v: Double);
begin
  QDoubleSpinBox_setSingleStep(QDoubleSpinBoxH(Widget), v);
end;

procedure TQtFloatSpinBox.setValue(const v: Double);
begin
  FValue := v;
  QDoubleSpinBox_setValue(QDoubleSpinBoxH(Widget), FValue);
end;

procedure TQtFloatSpinBox.AttachEvents;
begin
  inherited AttachEvents;
  FValueChangedHook := QDoubleSpinBox_hook_create(Widget);
  QDoubleSpinBox_hook_hook_valueChanged(FValueChangedHook, @SignalValueChanged);
end;

procedure TQtFloatSpinBox.DetachEvents;
begin
  QDoubleSpinBox_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

procedure TQtFloatSpinBox.SignalValueChanged(p1: Double); cdecl;
var
   Msg: TLMessage;
begin
  FValue := p1;
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  if not InUpdate then
    DeliverMessage(Msg);
end;

{ TQtSpinBox }

function TQtSpinBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtSpinBox.Create');
  {$endif}
  {$ifdef CPU64 and not WIN64}
  FParentShowPassed := 0;
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QSpinBox_create(Parent);
end;

function TQtSpinBox.getValue: Double;
begin
  Result := FValue;
end;

procedure TQtSpinBox.setMinimum(const v: Double);
begin
  QSpinBox_setMinimum(QSpinBoxH(Widget), round(v));
end;

procedure TQtSpinBox.setMaximum(const v: Double);
begin
  QSpinBox_setMaximum(QSpinBoxH(Widget), round(v));
end;

procedure TQtSpinBox.setSingleStep(const v: Double);
begin
  QSpinBox_setSingleStep(QSpinBoxH(Widget), round(v));
end;

procedure TQtSpinBox.setValue(const v: Double);
begin
  FValue := Round(v);
  QSpinBox_setValue(QSpinBoxH(Widget), round(v));
end;

procedure TQtSpinBox.AttachEvents;
begin
  inherited AttachEvents;
  FValueChangedHook := QSpinBox_hook_create(Widget);
  QSpinBox_hook_hook_valueChanged(FValueChangedHook, @SignalValueChanged);
end;

procedure TQtSpinBox.DetachEvents;
begin
  QSpinBox_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

procedure TQtSpinBox.SignalValueChanged(p1: Integer); cdecl;
var
   Msg: TLMessage;
begin
  FValue := p1;
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  if not InUpdate then
    DeliverMessage(Msg);
end;

{ TQtListView }

function TQtListView.getBatchSize: integer;
begin
  Result := QListView_batchSize(QListViewH(Widget));
end;

function TQtListView.getGridSize: TSize;
begin
  QListView_gridSize(QListViewH(Widget), @Result);
end;

function TQtListView.getSpacing: Integer;
begin
  Result := QListView_spacing(QListViewH(Widget));
end;

procedure TQtListView.setBatchSize(const AValue: integer);
begin
  QListView_setBatchSize(QListViewH(Widget), AValue);
end;

procedure TQtListView.setGridSize(const AValue: TSize);
begin
  QListView_setGridSize(QListViewH(Widget), @AValue);
end;

procedure TQtListView.setLayoutMode(const ALayoutMode: QListViewLayoutMode);
begin
  QListView_setLayoutMode(QListViewH(Widget), ALayoutMode);
end;

procedure TQtListView.setMovement(const AMovement: QListViewMovement);
begin
  QListView_setMovement(QListViewH(Widget), AMovement);
end;

procedure TQtListView.setResizeMode(const AResizeMode: QListViewResizeMode);
begin
  QListView_setResizeMode(QListViewH(Widget), AResizeMode);
end;

procedure TQtListView.setSpacing(const AValue: integer);
begin
  QListView_setSpacing(QListViewH(Widget), AValue);
end;

procedure TQtListView.setUniformItemSizes(const AEnable: Boolean);
begin
  QListView_setUniformItemSizes(QListViewH(Widget), AEnable);
end;

procedure TQtListView.setViewFlow(const AFlow: QListViewFlow);
begin
  QListView_setFlow(QListViewH(Widget), AFlow);
end;

procedure TQtListView.setViewMode(const AMode: QListViewViewMode);
begin
  QListView_setViewMode(QListViewH(Widget), AMode);
end;

procedure TQtListView.setWordWrap(const AValue: Boolean);
begin
  QListView_setWordWrap(QListViewH(Widget), AValue);
end;

procedure TQtListView.setWrapping(const AWrapping: Boolean);
begin
  QListView_setWrapping(QListViewH(Widget), AWrapping);
end;

procedure TQtListView.LayoutItems;
begin
  QListView_doItemsLayout(QListViewH(Widget));
end;

{ TQtListWidget }

function TQtListWidget.getItemCount: Integer;
begin
  Result := QListWidget_count(QListWidgetH(Widget));
end;

procedure TQtListWidget.setItemCount(const AValue: Integer);
var
  i: Integer;
  AList: QStringListH;
  WStr: WideString;
begin
  if AValue = ItemCount then
    exit;
  BeginUpdate;
  try
    ClearItems;
    AList := QStringList_create();
    WStr := '';
    for i := 1 to AValue do
      QStringList_append(AList, @WStr);
    QListWidget_addItems(QListWidgetH(Widget), AList);
    QStringList_destroy(AList);
  finally
    EndUpdate;
  end;
end;

function TQtListWidget.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  FSavedEvent := nil;
  FSavedEventTimer := nil;
  FSavedEventTimerHook := nil;

  FViewStyle := -1;
  FSyncingItems := False;
  FCheckable := False;
  FDontPassSelChange := False;
  FOwnerData := False;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QListWidget_create(Parent);
end;

procedure TQtListWidget.OwnerDataNeeded(ARect: TRect);
var
  R: TRect;
  TopItem: Integer;
  i: Integer;
  VHeight: Integer; // viewport height
  RowHeight: Integer;
  item: QListWidgetItemH;
  v: QVariantH;
  WStr: WideString;
  DataStr: WideString;
begin

  {do not set items during design time}
  if (csDesigning in LCLObject.ComponentState) then
    exit;

  if ItemCount < 1 then
    exit;

  {TODO: add QtDecorationRole (icon) etc ... }
  QWidget_contentsRect(viewportWidget, @R);
  VHeight := R.Bottom - R.Top;

  item := itemAt(0, 1);
  if item <> nil then
  begin
    TopItem := getRow(Item);
    RowHeight := getRowHeight(TopItem);

    if (TopItem < 0) or (TopItem > TListView(LCLObject).Items.Count - 1) then
      exit;

    i := 0;

    while (i < (VHeight + RowHeight)) do
    begin
      item := itemAt(0, i + 1);
      if (item <> nil) then
      begin
        TopItem := getRow(Item);
        RowHeight := getRowHeight(TopItem);

        if (TopItem < 0) or (TopItem > TListView(LCLObject).Items.Count - 1) then
          break;

        if (TListView(LCLObject).Items[TopItem].ImageIndex <> -1) then
        begin
          // TODO: paint icons and reduce paint overhead by checking icon
        end;

        WStr := GetUTF8String(TListView(LCLObject).Items[TopItem].Caption);

        // reduce paint overhead by checking text
        v := QVariant_create();
        QListWidgetItem_data(item, v, Ord(QtDisplayRole));
        if QVariant_isValid(v) then
          QVariant_toString(v, @DataStr)
        else
          DataStr := '';
        QVariant_destroy(v);

        if (DataStr <> WStr) then
        begin
          v := QVariant_create(PWideString(@WStr));
          try
            QListWidgetItem_setData(item, Ord(QtDisplayRole), v);
          finally
            QVariant_destroy(v);
          end;
        end;
      end else
        break;

      inc(i, RowHeight);
    end;
  end;
end;

procedure TQtListWidget.AttachEvents;
begin
  inherited AttachEvents;

  FCurrentItemChangedHook := QListWidget_hook_create(Widget);
  FSelectionChangeHook := QListWidget_hook_create(Widget);
  FItemClickedHook := QListWidget_hook_create(Widget);
  FItemTextChangedHook := QListWidget_hook_create(Widget);

  // used only when we are handle of TListView
  QListWidget_hook_hook_currentItemChanged(FCurrentItemChangedHook,
    @signalCurrentItemChanged);

  // OnSelectionChange event (listbox)
  QListWidget_hook_hook_itemSelectionChanged(FSelectionChangeHook, @signalSelectionChanged);
  QListWidget_hook_hook_itemClicked(FItemClickedHook, @signalItemClicked);
  QListWidget_hook_hook_currentTextChanged(FItemTextChangedHook, @signalItemTextChanged);
end;

procedure TQtListWidget.DetachEvents;
begin
  QListWidget_hook_destroy(FCurrentItemChangedHook);
  QListWidget_hook_destroy(FSelectionChangeHook);
  QListWidget_hook_destroy(FItemClickedHook);
  QListWidget_hook_destroy(FItemTextChangedHook);

  inherited DetachEvents;
end;

function TQtListWidget.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
var
  ev: QEventH;
begin
  Result := False;
  QEvent_accept(Event);
  if LCLObject = nil then
    exit;
  if (FChildOfComplexWidget = ccwComboBox) and (FOwner <> nil) then
  begin
    case QEvent_type(Event) of
      QEventShow: TQtComboBox(FOwner).SlotDropListVisibility(True);
      QEventHide:
      begin
        {we must delay SlotDropDownVisiblity according to #9574
         so order is OnChange(if editable)->OnSelect->OnCloseUp }
        ev := QEvent_create(QEventHideToParent);
        QCoreApplication_postEvent(Sender, ev);
      end;
      QEventHideToParent: TQtComboBox(FOwner).SlotDropListVisibility(False);
    end;
  end else
  begin
    if (ViewStyle >= 0) and ((QEvent_type(Event) = QEventMouseButtonPress) or
    (QEvent_type(Event) = QEventMouseButtonRelease)) then
      {eat mouse button events when we are TListView class.
       Such events are handled by itemViewportEventFilter.}
    else
      Result:=inherited EventFilter(Sender, Event);
  end;
end;

function TQtListWidget.itemViewViewportEventFilter(Sender: QObjectH;
  Event: QEventH): Boolean; cdecl;
var
  Item: QListWidgetItemH;
  MousePos: TQtPoint;
  X: Integer;

  procedure SendEventToParent;
  var
    AEvent: QEventH;
  begin
    AEvent := QMouseEvent_create(QEvent_type(Event),
      QMouseEvent_pos(QMouseEventH(Event)),
      QMouseEvent_globalPos(QMouseEventH(Event)),
      QMouseEvent_button(QMouseEventH(Event)),
      QMouseEvent_buttons(QMouseEventH(Event)),
      QInputEvent_modifiers(QInputEventH(Event)));
    QCoreApplication_postEvent(Widget, AEvent, 1);
  end;

begin
  Result := False;
  QEvent_accept(Event);

  if (FChildOfComplexWidget = ccwComboBox) and (FOwner <> nil) then
    exit;

  if (LCLObject <> nil) then
  begin
    if ViewStyle >= 0 then
    begin
      if QEvent_type(Event) = QEventMouseButtonRelease then
        PostponedMouseRelease(Event)
      else
        Result := inherited itemViewViewportEventFilter(Sender, Event);
    end else
    case QEvent_type(Event) of
      QEventMouseButtonPress,
      QEventMouseButtonRelease,
      QEventMouseButtonDblClick:
      begin
        if (Checkable) and
          (QEvent_type(Event) <> QEventMouseButtonDblClick) and
          (QMouseEvent_button(QMouseEventH(Event)) = QtLeftButton) then
        begin
          MousePos := QMouseEvent_pos(QMouseEventH(Event))^;
          Item := itemAt(MousePos.x, MousePos.y);
          if (Item <> nil) and
            ((QListWidgetItem_flags(Item) and QtItemIsUserCheckable) <> 0) then
          begin
            x := QStyle_pixelMetric(QApplication_style(), QStylePM_IndicatorWidth,
              nil, Widget);
            if ((MousePos.X > 2) and (MousePos.X < (X + 2))) then
              {signalItemClicked() fires !}
            else
              SendEventToParent;
          end else
            SendEventToParent;
        end else
          SendEventToParent;
      end;
    else
      Result := inherited itemViewViewportEventFilter(Sender, Event);
    end;
  end;
end;

procedure TQtListWidget.signalCurrentItemChanged(current: QListWidgetItemH;
  previous: QListWidgetItemH); cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
  ASubIndex: Integer;
  AIndex: Integer;
begin
  // only when TQtListWidget is handle of TListView !
  if ViewStyle = -1 then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGING;

  AIndex := getRow(Current);

  ASubIndex := 0;

  NMLV.iItem := AIndex;
  NMLV.iSubItem := ASubIndex;
  NMLV.uNewState := LVIS_SELECTED;
  NMLV.uChanged := LVIF_STATE;

  Msg.NMHdr := @NMLV.hdr;
  DeliverMessage(Msg);

  FSyncingItems := True;
  try
    if Current <> nil then
    begin
      FillChar(Msg, SizeOf(Msg), #0);
      FillChar(NMLV, SizeOf(NMLV), #0);
      Msg.Msg := CN_NOTIFY;
      NMLV.hdr.hwndfrom := LCLObject.Handle;
      NMLV.hdr.code := LVN_ITEMCHANGED;
      NMLV.iItem := AIndex;
      NMLV.iSubItem := ASubIndex;
      if QListWidget_isItemSelected(QListWidgetH(Widget), Current) then
        NMLV.uNewState := LVIS_SELECTED
      else
        NMLV.uOldState := LVIS_SELECTED;
      NMLV.uChanged := LVIF_STATE;
      Msg.NMHdr := @NMLV.hdr;
      DeliverMessage(Msg);
    end;

    if Previous <> nil then
    begin
      FillChar(Msg, SizeOf(Msg), #0);
      FillChar(NMLV, SizeOf(NMLV), #0);
      Msg.Msg := CN_NOTIFY;
      NMLV.hdr.hwndfrom := LCLObject.Handle;
      NMLV.hdr.code := LVN_ITEMCHANGED;
      NMLV.iItem := getRow(Previous);
      ASubIndex := 0;
      NMLV.iSubItem := ASubIndex;
      if QListWidget_isItemSelected(QListWidgetH(Widget), Previous) then
        NMLV.uNewState := LVIS_SELECTED
      else
        NMLV.uOldState := LVIS_SELECTED;
      NMLV.uChanged := LVIF_STATE;
      Msg.NMHdr := @NMLV.hdr;
      DeliverMessage(Msg);
    end;
  finally
    FSyncingItems := False;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.SlotSelectionChange
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}

procedure TQtListWidget.signalSelectionChanged(); cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtListWidget.signalSelectionChange');
  {$endif}

  if FDontPassSelChange then
  begin
    FDontPassSelChange := False;
    Exit;
  end;

  if ViewStyle >= 0 then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_SELCHANGE;
  if (getSelCount > 0) and (FChildOfComplexWidget <> ccwComboBox) then
    DeliverMessage(Msg);
end;

procedure TQtListWidget.signalItemTextChanged(ANewText: PWideString); cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtListWidget.signalItemTextChanged');
  {$endif}
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(Msg);
end;

procedure TQtListWidget.signalItemClicked(item: QListWidgetItemH)cdecl;
var
  Msg: TLMessage;
  ItemRow: Integer;
  MsgN: TLMNotify;
  NMLV: TNMListView;
  R: TRect;
  Pt: TPoint;
  i: Integer;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtListWidget.signalItemClicked');
  {$endif}
  if (ViewStyle >= 0) and (FChildOfComplexWidget <> ccwComboBox) then
  begin
    FillChar(MsgN, SizeOf(MsgN), #0);
    FillChar(NMLV, SizeOf(NMLV), #0);

    MsgN.Msg := LM_CLICKED;

    NMLV.hdr.hwndfrom := LCLObject.Handle;
    NMLV.hdr.code := NM_CLICK;

    NMLV.iItem := getRow(Item);

    NMLV.iSubItem := 0;
    NMLV.uNewState := UINT(NM_CLICK);
    NMLV.uChanged :=  LVIS_SELECTED;

    QListWidget_visualItemRect(QListWidgetH(Widget), @R, Item);

    pt.X := R.Left;
    pt.Y := R.Top;

    NMLV.ptAction := pt;

    MsgN.NMHdr := @NMLV.hdr;

    DeliverMessage(MsgN);

    {sync LCL items for selected property}
    if (LCLObject <> nil) and (LCLObject is TListView) then
      for i := 0 to TListView(LCLObject).Items.Count - 1 do
        TListView(LCLObject).Items[i].Selected;

    {inform LCL about current change}
    MsgN.Msg := CN_NOTIFY;
    NMLV.hdr.code := LVN_ITEMCHANGED;
    NMLV.uNewState := 0;
    NMLV.uOldState := 0;
    if QListWidget_isItemSelected(QListWidgetH(Widget), Item) then
      NMLV.uNewState := LVIS_SELECTED
    else
      NMLV.uOldState := LVIS_SELECTED;
    NMLV.uChanged :=  LVIF_STATE;
    MsgN.NMHdr := @NMLV.hdr;
    DeliverMessage(Msgn);
  end;

  if Checkable then
  begin
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    ItemRow := QListWidget_row(QListWidgetH(Widget), Item);
    Msg.WParam := ItemRow;
    DeliverMessage(Msg);
  end;

end;

procedure TQtListWidget.ItemDelegatePaint(painter: QPainterH;
  option: QStyleOptionViewItemH; index: QModelIndexH); cdecl;
var
  Msg: TLMDrawListItem;
  DrawStruct: TDrawListItemStruct;
  State: QStyleState;
begin
  QPainter_save(painter);
  State := QStyleOption_state(option);
  DrawStruct.ItemID := UINT(QModelIndex_row(index));

  DrawStruct.Area := visualRect(index);
  DrawStruct.DC := HDC(TQtDeviceContext.CreateFromPainter(painter));

  DrawStruct.ItemState := [];
  // selected
  if (State and QStyleState_Selected) <> 0 then
    Include(DrawStruct.ItemState, odSelected);
  // disabled
  if (State and QStyleState_Enabled) = 0 then
    Include(DrawStruct.ItemState, odDisabled);
  // focused (QStyleState_FocusAtBorder?)
  if (State and QStyleState_HasFocus) <> 0 then
    Include(DrawStruct.ItemState, odFocused);
  // hotlight
  if (State and QStyleState_MouseOver) <> 0 then
    Include(DrawStruct.ItemState, odHotLight);

  { todo: over states:
  
    odGrayed, odChecked,
    odDefault, odInactive, odNoAccel,
    odNoFocusRect, odReserved1, odReserved2, odComboBoxEdit,
    odPainted
  }
  Msg.Msg := LM_DRAWLISTITEM;
  Msg.DrawListItemStruct := @DrawStruct;
  DeliverMessage(Msg);

  QPainter_restore(painter);
  
  TQtDeviceContext(DrawStruct.DC).Free;
end;

procedure TQtListWidget.ClearItems;
begin
  QListWidget_clear(QListWidgetH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.currentRow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtListWidget.currentRow: Integer;
begin
  Result := QListWidget_currentRow(QListWidgetH(Widget));
end;

function TQtListWidget.currentItem: QListWidgetItemH;
begin
  Result := QListWidget_currentItem(QListWidgetH(Widget));
end;

function TQtListWidget.IndexAt(APoint: PQtPoint): Integer;
var
  AModelIndex: QModelIndexH;
begin
  AModelIndex := QModelIndex_create();
  QListView_indexAt(QListWidgetH(Widget), AModelIndex, APoint);
  Result := QModelIndex_row(AModelIndex);
  QModelIndex_destroy(AModelIndex);
end;

procedure TQtListWidget.insertItem(AIndex: Integer; AText: String);
var
  Str: WideString;
begin
  Str := GetUtf8String(AText);
  insertItem(AIndex, @Str);
end;

procedure TQtListWidget.insertItem(AIndex: Integer; AText: PWideString);
var
  Item: QListWidgetItemH;
begin
  Item := QListWidgetItem_create(AText, nil, 0);
  if Checkable then
    QListWidgetItem_setCheckState(Item, QtUnChecked);
  QListWidget_insertItem(QListWidgetH(Widget), AIndex, Item);
end;

function TQtListWidget.itemAt(APoint: TPoint): QListWidgetItemH;
begin
  Result := ItemAt(APoint.X, APoint.Y);
end;

function TQtListWidget.itemAt(x: Integer; y: Integer): QListWidgetItemH;
begin
  Result := QListWidget_itemAt(QListWidgetH(Widget), x, y);
end;

function TQtListWidget.getItem(AIndex: Integer): QListWidgetItemH;
begin
  Result := QListWidget_item(QListWidgetH(Widget), AIndex);
end;

function TQtListWidget.getItemSelected(AItem: QListWidgetItemH): Boolean;
begin
  if AItem <> nil then
    Result := QListWidget_isItemSelected(QListWidgetH(Widget), AItem)
  else
    Result := False;
end;

function TQtListWidget.getItemVisible(AItem: QListWidgetItemH): Boolean;
begin
  if AItem = nil then
    Result := False
  else
    Result := not QListWidget_isItemHidden(QListWidgetH(Widget), AItem);
end;

function TQtListWidget.getRow(AItem: QListWidgetItemH): integer;
begin
  if AItem = nil then
    Result := -1
  else
    Result := QListWidget_row(QListWidgetH(Widget), AItem);
end;

function TQtListWidget.getSelCount: Integer;
begin
  Result := length(selectedItems);
end;

function TQtListWidget.getTopItem: integer;
begin
  Result := getVisibleRowCount(True);
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.getVisibleRowCount
  Params:  Boolean
  Returns: if AFirstVisibleOnly = False (default) then it returns number
  of visible rows, or 0 if there's no visible rows.
  When AFirstVisibleOnly = True then it returns index of first visible row,
  otherwise result is -1.
 ------------------------------------------------------------------------------}
function TQtListWidget.getVisibleRowCount(const AFirstVisibleOnly: boolean = false): integer;
var
  R: TRect;
  i: integer;
  item: QListWidgetItemH;
  RowIndex: integer;
  RowHeight: integer;
begin
  if AFirstVisibleOnly then
    Result := -1
  else
    Result := 0;
  QWidget_contentsRect(viewportWidget, @R);
  i := 0;
  repeat
    item := itemAt(0, i);
    if item <> nil then
    begin
      RowIndex := getRow(Item);
      if AFirstVisibleOnly then
      begin
        Result := RowIndex;
        break;
      end;
      RowHeight := getRowHeight(RowIndex);
      inc(Result);
      if RowHeight <= 0 then
        RowHeight := 1;
      inc(i, RowHeight);
    end else
      inc(i, 1);
  until i >= R.Bottom;
end;

function TQtListWidget.getVisualItemRect(AItem: QListWidgetItemH): TRect;
begin
  Result := Rect(0, 0, 0, 0);
  if AItem <> nil then
    QListWidget_visualItemRect(QListWidgetH(Widget), @Result, AItem);
end;

function TQtListWidget.selectedItems: TPtrIntArray;
begin
  QListWidget_selectedItems(QListWidgetH(Widget), @Result);
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.setCurrentRow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtListWidget.setCurrentRow(row: Integer);
begin
  if (getSelectionMode <> QAbstractItemViewSingleSelection) and (row < 0) then
    row := 0;

  if currentRow <> row then
  begin
    FDontPassSelChange := True;
    QListWidget_setCurrentRow(QListWidgetH(Widget), row);
  end;
end;

procedure TQtListWidget.setCurrentItem(AItem: QListWidgetItemH);
begin
  QListWidget_setCurrentItem(QListWidgetH(Widget), AItem);
end;

procedure TQtListWidget.setItemText(AIndex: Integer; AText: String);
var
  Item: QListWidgetItemH;
  Str: WideString;
  R: TRect;
begin
  Str := GetUTF8String(AText);
  if (AIndex >= 0) and (AIndex < rowCount) then
  begin
    Item := getItem(AIndex);
    QListWidgetItem_setText(Item, @Str);
    {we must update our custom delegate}
    if OwnerDrawn then
    begin
      R := getVisualItemRect(Item);
      Update(@R);
    end;
  end else
    insertItem(AIndex, @Str);
end;

procedure TQtListWidget.setItemText(AIndex: Integer; AText: String;
  AAlignment: Integer);
var
  Item: QListWidgetItemH;
  Str: WideString;
  R: TRect;
begin
  Str := GetUTF8String(AText);
  if (AIndex >= 0) and (AIndex < rowCount) then
  begin
    Item := getItem(AIndex);
    QListWidgetItem_setText(Item, @Str);
    QListWidgetItem_setTextAlignment(Item, AAlignment);
    {we must update our custom delegate}
    if OwnerDrawn then
    begin
      R := getVisualItemRect(Item);
      Update(@R);
    end;
  end else
    insertItem(AIndex, @Str);
end;

procedure TQtListWidget.setItemSelected(AItem: QListWidgetItemH;
  const ASelect: Boolean);
begin
  if AItem <> nil then
    QListWidget_setItemSelected(QListWidgetH(Widget), AItem, ASelect);
end;

procedure TQtListWidget.setItemVisible(AItem: QListWidgetItemH;
  const AVisible: Boolean);
begin
  if AItem <> nil then
    QListWidget_setItemHidden(QListWidgetH(Widget), AItem, not AVisible);
end;

procedure TQtListWidget.scrollToItem(row: integer;
  hint: QAbstractItemViewScrollHint);
var
  Item: QListWidgetItemH;
begin
  Item := getItem(Row);
  QListWidget_scrollToItem(QListWidgetH(Widget), Item, hint);
end;

procedure TQtListWidget.removeItem(AIndex: Integer);
var
  Item: QListWidgetItemH;
begin
  if (currentRow = AIndex) then
    if (getSelectionMode = QAbstractItemViewSingleSelection) then
      setCurrentRow(-1);
  Item := QListWidget_takeitem(QListWidgetH(Widget), AIndex);
  QListWidgetItem_destroy(Item);
end;

function TQtListWidget.rowCount: integer;
begin
  Result := QListWidget_count(QListWidgetH(Widget));
end;

procedure TQtListWidget.exchangeItems(AIndex1, AIndex2: Integer);
var
  Item1, Item2: QListWidgetItemH;
  R: TRect;
begin
  if AIndex1 = AIndex2 then
    exit;

  if (currentRow = AIndex1) or (currentRow = AIndex2) then
    if (getSelectionMode = QAbstractItemViewSingleSelection) then
      setCurrentRow(-1);

  if AIndex1 < AIndex2 then
  begin
    Item1 := QListWidget_takeItem(QListWidgetH(Widget), AIndex1);
    Item2 := QListWidget_takeItem(QListWidgetH(Widget), AIndex2 - 1);
    QListWidget_insertItem(QListWidgetH(Widget), AIndex1, Item2);
    QListWidget_insertItem(QListWidgetH(Widget), AIndex2, Item1);
  end else
  begin
    Item1 := QListWidget_takeItem(QListWidgetH(Widget), AIndex2);
    Item2 := QListWidget_takeItem(QListWidgetH(Widget), AIndex1 - 1);
    QListWidget_insertItem(QListWidgetH(Widget), AIndex2, Item2);
    QListWidget_insertItem(QListWidgetH(Widget), AIndex1, Item1);
  end;
  if OwnerDrawn then
  begin
    R := getVisualItemRect(Item1);
    Update(@R);
    R := getVisualItemRect(Item2);
    Update(@R);
  end;
end;

{ TQtCheckListBox }

function TQtCheckListBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  FSavedEvent := nil;
  FSavedEventTimer := nil;
  FSavedEventTimerHook := nil;

  FViewStyle := -1;
  FSyncingItems := False;
  FDontPassSelChange := False;
  FOwnerData := False;

  FCheckable := True;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QListWidget_create(Parent);
end;

procedure TQtCheckListBox.AttachEvents;
begin
  inherited AttachEvents;
  FItemChangedHook := QListWidget_hook_create(Widget);
  QListWidget_hook_hook_itemChanged(FItemChangedHook, @signalItemChanged);
end;

procedure TQtCheckListBox.DetachEvents;
begin
  QListWidget_hook_destroy(FItemChangedHook);
  inherited DetachEvents;
end;

function TQtCheckListBox.itemViewViewportEventFilter(Sender: QObjectH;
  Event: QEventH): Boolean; cdecl;
begin
  Result := False;
  QEvent_accept(Event);
  if (LCLObject <> nil) then
  begin
    case QEvent_type(Event) of
      QEventMouseButtonRelease,
      QEventMouseButtonPress,
      QEventMouseButtonDblClick:
        begin
          Result := inherited itemViewViewportEventFilter(Sender, Event);
        end;
      else
      begin
        {do not change selection if mousepressed and mouse moved}
        Result := (QEvent_type(Event) = QEventMouseMove) and
          hasFocus and (QApplication_mouseButtons() > 0);
         QEvent_ignore(Event);
      end;
    end;
  end;
end;

procedure TQtCheckListBox.signalCurrentItemChanged(current: QListWidgetItemH;
  previous: QListWidgetItemH); cdecl;
begin
  // Do nothing
  // inherited signalCurrentItemChanged(current, previous);
end;

procedure TQtCheckListBox.signalItemClicked(item: QListWidgetItemH); cdecl;
var
  AGlobalPos: TQtPoint;
  APos: TQtPoint;
  AMouseEvent: QMouseEventH;
begin
  // fires only when checkBox clicked.
  QCursor_pos(@AGlobalPos);
  QWidget_mapFromGlobal(Widget, @APos, @AGlobalPos);
  AMouseEvent := QMouseEvent_create(QEventMouseButtonPress, @APos,
    @AGlobalPos, QtLeftButton, QtLeftButton,
    QApplication_keyboardModifiers());
  SlotMouse(Widget, AMouseEvent);
  QMouseEvent_destroy(AMouseEvent);

  AMouseEvent := QMouseEvent_create(QEventMouseButtonRelease, @APos,
    @AGlobalPos, QtLeftButton, QtLeftButton,
    QApplication_keyboardModifiers());
  SlotMouse(Widget, AMouseEvent);
  QMouseEvent_destroy(AMouseEvent);
end;

procedure TQtCheckListBox.signalSelectionChanged(); cdecl;
begin
  // DO NOTHING
  // inherited signalSelectionChanged;
end;

procedure TQtCheckListBox.signalItemChanged(item: QListWidgetItemH); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  Msg.WParam := QListWidget_row(QListWidgetH(Widget), Item);
  if not InUpdate then
    DeliverMessage(Msg);
end;

{ TQtHeaderView }

function TQtHeaderView.getClickable: Boolean;
begin
  Result := QHeaderView_isClickable(QHeaderViewH(Widget));
end;

function TQtHeaderView.getMinSectionSize: Integer;
begin
  Result := QHeaderView_minimumSectionSize(QHeaderViewH(Widget));
end;

function TQtHeaderView.SortIndicatorOrder: QtSortOrder;
begin
  Result := QHeaderView_sortIndicatorOrder(QHeaderViewH(Widget));
end;

procedure TQtHeaderView.setClickable(const AValue: Boolean);
begin
  QHeaderView_setClickable(QHeaderViewH(Widget), AValue);
end;

procedure TQtHeaderView.setMinSectionSize(const AValue: Integer);
begin
  QHeaderView_setMinimumSectionSize(QHeaderViewH(Widget), AValue);
end;

procedure TQtHeaderView.SetSortIndicator(const AColumn: Integer;
  const AOrder: QtSortOrder);
begin
  QHeaderView_setSortIndicator(QHeaderViewH(Widget), AColumn, AOrder);
end;

procedure TQtHeaderView.SetSortIndicatorVisible(AVisible: Boolean);
begin
  QHeaderView_setSortIndicatorShown(QHeaderViewH(Widget), AVisible);
end;

{------------------------------------------------------------------------------
  Function: TQtHeaderView.CreateWidget
  Params:  None
  Returns: Widget (QHeaderViewH)
 ------------------------------------------------------------------------------}
function TQtHeaderView.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtHeaderView.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;

  Result := QHeaderView_create(QtHorizontal, Parent);
end;

procedure TQtHeaderView.AttachEvents;
begin
  inherited AttachEvents;
  FSelectionClicked := QHeaderView_hook_create(Widget);
  QHeaderView_hook_hook_sectionClicked(FSelectionClicked, @SignalSectionClicked);
end;

procedure TQtHeaderView.DetachEvents;
begin
  QHeaderView_hook_destroy(FSelectionClicked);
  inherited DetachEvents;
end;

function TQtHeaderView.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  Result := False;
  QEvent_accept(Event);
  if (FOwner <> nil) and (LCLObject <> nil) then
  begin
    if (FChildOfComplexWidget = ccwTreeWidget) and
      (QEvent_type(Event) = QEventFocusIn) then
    begin
      Result := True;
      QEvent_ignore(Event);
      QWidget_setFocus(FOwner.Widget);
    end;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtHeaderView.SignalSectionClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtHeaderView.SignalSectionClicked(logicalIndex: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  {$ifdef VerboseQt}
  writeln('TQtHeaderView.signalSectionClicked index ',logicalIndex);
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);
  
  Msg.Msg := CN_NOTIFY;
  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_COLUMNCLICK;
  NMLV.iItem := -1;
  NMLV.iSubItem := logicalIndex;
  
  Msg.NMHdr := @NMLV.hdr;
  
  DeliverMessage(Msg);
  
end;

function TQtHeaderView.getResizeMode(AIndex: Integer): QHeaderViewResizeMode;
begin
  Result := QHeaderView_resizeMode(QHeaderViewH(Widget), AIndex);
end;

procedure TQtHeaderView.setResizeMode(AResizeMode: QHeaderViewResizeMode);
begin
  QHeaderView_setResizeMode(QHeaderViewH(Widget), AResizeMode);
end;

procedure TQtHeaderView.setResizeMode(AIndex: Integer;
  AResizeMode: QHeaderViewResizeMode);
begin
  QHeaderView_setResizeMode(QHeaderViewH(Widget), AIndex, AResizeMode);
end;

procedure TQtHeaderView.moveSection(AFromIndex: Integer; AToIndex: Integer);
begin
  QHeaderView_moveSection(QHeaderViewH(Widget), AFromIndex, AToIndex);
end;

procedure TQtHeaderView.resizeSection(ASection: Integer; ASize: Integer);
begin
  QHeaderView_resizeSection(QHeaderViewH(Widget), ASection, ASize);
end;

procedure TQtHeaderView.setHighlightSections(AValue: Boolean);
begin
  QHeaderView_setHighlightSections(QHeaderViewH(Widget), AValue);
end;

procedure TQtHeaderView.setDefaultSectionSize(AValue: Integer);
begin
  QHeaderView_setDefaultSectionSize(QHeaderViewH(Widget), AValue);
end;

procedure TQtHeaderView.setStretchLastSection(AValue: Boolean);
begin
  QHeaderView_setStretchLastSection(QHeaderViewH(Widget), AValue);
end;

  { TQtTreeView }

function TQtTreeView.getColVisible(AIndex: Integer): Boolean;
begin
  Result := not QTreeView_isColumnHidden(QTreeViewH(Widget), AIndex);
end;

function TQtTreeView.getColWidth(AIndex: Integer): Integer;
begin
  Result := QTreeView_columnWidth(QTreeViewH(Widget), AIndex);
end;

function TQtTreeView.GetUniformRowHeights: Boolean;
begin
  Result := QTreeView_uniformRowHeights(QTreeViewH(Widget));
end;

procedure TQtTreeView.setColVisible(AIndex: Integer; const AValue: Boolean);
begin
  QTreeView_setColumnHidden(QTreeViewH(Widget), AIndex, not AValue);
end;

procedure TQtTreeView.setColWidth(AIndex: Integer; const AValue: Integer);
begin
  QTreeView_setColumnWidth(QTreeViewH(Widget), AIndex, AValue);
end;

procedure TQtTreeView.SetUniformRowHeights(const AValue: Boolean);
begin
  QTreeView_setUniformRowHeights(QTreeViewH(Widget), AValue);
end;

procedure TQtTreeView.setWordWrap(const AValue: Boolean);
begin
  QTreeView_setWordWrap(QTreeViewH(Widget), AValue);
end;

procedure TQtTreeView.setRootIsDecorated(AValue: Boolean);
begin
  QTreeView_setRootIsDecorated(QTreeViewH(Widget), AValue);
end;

procedure TQtTreeView.setAllColumnsShowFocus(AValue: Boolean);
begin
  QTreeView_setAllColumnsShowFocus(QTreeViewH(Widget), AValue);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeView.CreateWidget
  Params:  None
  Returns: Widget (QTreeViewH)
 ------------------------------------------------------------------------------}
function TQtTreeView.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTreeView.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QTreeView_create(Parent);
end;

  { TQtTreeWidget }

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.CreateWidget
  Params:  None
  Returns: Widget (QTreeWidgetH)
 ------------------------------------------------------------------------------}
function TQtTreeWidget.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTreeWidget.Create');
  {$endif}
  FCurrentItem := nil;
  FPreviousItem := nil;
  FMousePressed := False;

  FSavedEvent := nil;
  FSavedEventTimer := nil;
  FSavedEventTimerHook := nil;
  FViewStyle := -1;
  FCheckable := False;
  FHideSelection := False;
  FOwnerData := False;
  FSyncingItems := False;
  FSorting := False;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QTreeWidget_create(Parent);
  FHeader := nil;
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtTreeWidget.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTreeWidget.Destroy');
  {$endif}

  if Assigned(FHeader) then
    FHeader.Free;

  inherited Destroy;
end;

procedure TQtTreeWidget.DestroyNotify(AWidget: TQtWidget);
begin
  if AWidget = FHeader then
    FHeader := nil;
  inherited DestroyNotify(AWidget);
end;

function TQtTreeWidget.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
var
  item: QTreeWidgetItemH;
begin
  Result := False;
  QEvent_accept(Event);
  if LCLObject = nil then
    exit;
  if Checkable then
  begin
    if ( (QEvent_type(Event) = QEventKeyPress) or
     (QEvent_type(Event) = QEventKeyRelease) ) and
      (QKeyEvent_key(QKeyEventH(Event)) = QtKey_Space) then
    begin
      if QEvent_type(Event) = QEventKeyRelease then
      begin
        item := currentItem;
        if QTreeWidgetItem_checkState(Item, 0) = QtChecked then
          QTreeWidgetItem_setCheckState(Item, 0, QtUnChecked)
        else
          QTreeWidgetItem_setCheckState(Item, 0, QtChecked);
        // send click msg
        if item <> nil then
          SignalItemClicked(Item, 0);
      end;
      inherited EventFilter(Sender, Event);
      QEvent_ignore(Event);
      Result := True;
    end else
      Result:=inherited EventFilter(Sender, Event);
  end else
  if ((QEvent_type(Event) = QEventMouseButtonPress) or
    (QEvent_type(Event) = QEventMouseButtonRelease))
    and (QMouseEvent_button(QMouseEventH(Event)) = QtLeftButton) then
    {eat mouse button events -> signalItemClicked is fired}
  else
    Result:=inherited EventFilter(Sender, Event);
end;

function TQtTreeWidget.itemViewViewportEventFilter(Sender: QObjectH;
  Event: QEventH): Boolean; cdecl;
begin
  if (QEvent_type(Event) = QEventMouseButtonPress) and
    (QMouseEvent_button(QMouseEventH(Event)) = QtLeftButton) then
    FMousePressed := True;

  if (QEvent_type(Event) = QEventMouseButtonRelease) and
    (QMouseEvent_button(QMouseEventH(Event)) = QtLeftButton) then
    FMousePressed := False;

  Result := inherited itemViewViewportEventFilter(Sender, Event);
end;

procedure TQtTreeWidget.OwnerDataNeeded(ARect: TRect);
var
  R: TRect;
  TopItem: Integer;
  i: Integer;
  j: Integer;
  ChildCount: Integer;
  VHeight: Integer; // viewport height
  RowHeight: Integer;
  item: QTreeWidgetItemH;
  itemChild: QTreeWidgetItemH;
  v: QVariantH;
  WStr: WideString;
begin
  {do not set items during design time}
  if csDesigning in LCLObject.ComponentState then
    exit;

  if QTreeWidget_topLevelItemCount(QTreeWidgetH(Widget)) < 1 then
    exit;

  {TODO: add QtDecorationRole (icon) etc ... }
  QWidget_contentsRect(viewportWidget, @R);
  VHeight := R.Bottom - R.Top;

  item := QTreeWidget_itemAt(QTreeWidgetH(Widget), 0, 1);
  if item <> nil then
  begin

    TopItem := getRow(item);
    RowHeight := getRowHeight(TopItem);

    if (TopItem < 0) or (TopItem > TListView(LCLObject).Items.Count - 1) then
      exit;

    i := 0;

    while (i < (VHeight + RowHeight)) do
    begin
      item := QTreeWidget_itemAt(QTreeWidgetH(Widget), 0, i + 1);
      if item <> nil then
      begin

        TopItem := getRow(item);
        RowHeight := getRowHeight(TopItem);

        if (TopItem < 0) or (TopItem > TListView(LCLObject).Items.Count - 1) then
          continue;

        WStr := GetUTF8String(TListView(LCLObject).Items[TopItem].Caption);

        v := QVariant_create(PWideString(@WStr));
        try
          QTreeWidgetItem_setData(item, 0, Ord(QtDisplayRole), v);
        finally
          QVariant_destroy(v);
        end;

        ChildCount := QTreeWidgetItem_childCount(Item);
        if ChildCount = TListView(LCLObject).Items[TopItem].SubItems.Count then
        begin
          for j := 0 to ChildCount - 1 do
          begin
            itemChild := QTreeWidgetItem_child(item, j);
            if itemChild <> nil then
            begin
              WStr := GetUTF8String(TListView(LCLObject).Items[TopItem].SubItems[j]);
              v := QVariant_create(PWideString(@WStr));
              QTreeWidgetItem_setData(itemChild, 0, Ord(QtDisplayRole), v);
              QVariant_destroy(v);
            end;
          end;
        end else
        begin
          for j := 0 to TListView(LCLObject).Items[TopItem].SubItems.Count - 1 do
          begin
            WStr := GetUTF8String(TListView(LCLObject).Items[TopItem].SubItems[j]);
            v := QVariant_create(PWideString(@WStr));
            QTreeWidgetItem_setData(item, j + 1, Ord(QtDisplayRole), v);
            QVariant_destroy(v);
          end;
        end;
      end;

      inc(i, RowHeight);
    end;
  end;
end;

procedure TQtTreeWidget.ClearItems;
begin
  QTreeWidget_clear(QTreeWidgetH(Widget));
end;

procedure TQtTreeWidget.DeleteItem(const AIndex: integer);
var
  Item: QTreeWidgetItemH;
begin
  Item := takeTopLevelItem(AIndex);
  if (Item = FCurrentItem) then
    FCurrentItem := nil
  else
  if (Item = FPreviousItem) then
    FPreviousItem := nil;
  if Item <> nil then
    QTreeWidgetItem_destroy(Item);
end;

function TQtTreeWidget.getHeader: TQtHeaderView;
begin
  {while designing TQtHeaderView is a no-no}
  if not (csDesigning in LCLObject.ComponentState) and (FHeader = nil) then
  begin
    FHeader := TQtHeaderView.CreateFrom(LCLObject, QTreeView_header(QTreeViewH(Widget)));
    FHeader.FOwner := Self;
    FHeader.FChildOfComplexWidget := ccwTreeWidget;
    FSectionClicked := QHeaderView_hook_create(FHeader.Widget);
    QHeaderView_hook_hook_sectionClicked(FSectionClicked,
      @FHeader.SignalSectionClicked);
    FSortChanged := QHeaderView_hook_create(FHeader.Widget);
    QHeaderView_hook_hook_sortIndicatorChanged(FSortChanged,
      @SignalSortIndicatorChanged);
    FHeader.AttachEvents;
  end;
  Result := FHeader;
end;

function TQtTreeWidget.getItemCount: Integer;
begin
  Result := QTreeWidget_topLevelItemCount(QTreeWidgetH(Widget));
end;

function TQtTreeWidget.getMaxColSize(ACol: Integer): Integer;
begin
  {$note QSizeH implementation missing for TQtTreeWidget.getMaxColSize}
  Result := MAXINT -1;
end;

function TQtTreeWidget.getMinColSize(ACol: Integer): Integer;
begin
  {$note QSizeH implementation missing for TQtTreeWidget.getMinColSize}
  Result := 0;
end;

function TQtTreeWidget.getSortEnabled: Boolean;
begin
  Result := QTreeWidget_isSortingEnabled(QTreeWidgetH(Widget));
end;

function TQtTreeWidget.getColCount: Integer;
begin
  Result := QTreeWidget_columnCount(QTreeWidgetH(Widget));
end;

procedure TQtTreeWidget.setColCount(const AValue: Integer);
begin
  QTreeWidget_setColumnCount(QTreeWidgetH(Widget), AValue);
end;

procedure TQtTreeWidget.setItemCount(const AValue: Integer);
var
  i: Integer;
  j: Integer;
  Items: TPtrIntArray;
  Item: QTreeWidgetItemH;
  ItemChild: QTreeWidgetItemH;
begin
  if AValue = ItemCount then
    exit;
  BeginUpdate;
  try
    ClearItems;
    SetLength(Items, AValue);
    for i := 0 to High(Items) do
    begin
      Item := QTreeWidgetItem_create(QTreeWidgetH(Widget), 0);
      for j := 0 to ColCount - 1 do
      begin
        ItemChild := QTreeWidgetItem_create(item, 0);
        QTreeWidgetItem_addChild(item, ItemChild);
      end;
      Items[i] := PtrUInt(Item);
    end;
    if length(Items) > 0 then
      QTreeWidget_addTopLevelItems(QTreeWidgetH(Widget), @Items);
  finally
    EndUpdate;
  end;
end;

procedure TQtTreeWidget.setMaxColSize(ACol: Integer; const AValue: Integer);
begin
  {$note QSizeH implementation missing for TQtTreeWidget.setMaxColSize}
end;

procedure TQtTreeWidget.setMinColSize(ACol: Integer; const AValue: Integer);
begin
  // QTreeWidgetItem_setSizeHint(headerItem, @Size, ACol);
  {$note QSizeH implementation missing for TQtTreeWidget.setMinColSize}
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.setSortEnabled
  Params:  Boolean
  Returns: Nothing
  Enables sorting of items.
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.setSortEnabled(const AValue: Boolean);
begin
  QTreeWidget_setSortingEnabled(QTreeWidgetH(Widget), AValue);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.CurrentRow
  Params:  None
  Returns: Integer
 ------------------------------------------------------------------------------}
function TQtTreeWidget.currentRow: Integer;
var
  TWI: QTreeWidgetItemH;
begin
  TWI := QTreeWidget_currentItem(QTreeWidgetH(Widget));
  Result := getRow(TWI);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.setCurrentRow
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.setCurrentRow(row: Integer);
var
  TWI: QTreeWidgetItemH;
begin
  TWI := QTreeWidget_topLevelItem(QTreeWidgetH(Widget), Row);
  QTreeWidget_setCurrentItem(QTreeWidgetH(Widget), TWI);
end;

function TQtTreeWidget.currentItem: QTreeWidgetItemH;
begin
  Result := QTreeWidget_currentItem(QTreeWidgetH(Widget));
end;

procedure TQtTreeWidget.setCurrentItem(AItem: QTreeWidgetItemH);
begin
  QTreeWidget_setCurrentItem(QTreeWidgetH(Widget), AItem);
end;

function TQtTreeWidget.getRow(AItem: QTreeWidgetItemH): integer;
begin
  Result := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), AItem);
end;

function TQtTreeWidget.headerItem: QTreeWidgetItemH;
begin
  Result := QTreeWidget_headerItem(QTreeWidgetH(Widget));
end;

function TQtTreeWidget.itemAt(APoint: TPoint): QTreeWidgetItemH;
begin
  Result := itemAt(APoint.X, APoint.Y);
end;

function TQtTreeWidget.itemAt(x: Integer; y: Integer): QTreeWidgetItemH;
begin
  Result := QTreeWidget_itemAt(QTreeWidgetH(Widget), x, y);
end;

procedure TQtTreeWidget.insertTopLevelItem(AIndex: Integer;
  AItem: QTreeWidgetItemH);
begin
  QTreeWidget_insertTopLevelItem(QTreeWidgetH(Widget), AIndex, AItem);
end;

function TQtTreeWidget.takeTopLevelItem(AIndex: Integer): QTreeWidgetItemH;
begin
  Result := QTreeWidget_takeTopLevelItem(QTreeWidgetH(Widget), AIndex);
end;

function TQtTreeWidget.topLevelItem(AIndex: Integer): QTreeWidgetItemH;
begin
  Result := QTreeWidget_topLevelItem(QTreeWidgetH(Widget), AIndex);
end;

function TQtTreeWidget.visualItemRect(AItem: QTreeWidgetItemH): TRect;
var
  ItemRect: TRect;
begin
  QTreeWidget_visualItemRect(QTreeWidgetH(Widget), @ItemRect, AItem);
  Result := ItemRect;
end;

function TQtTreeWidget.getHeaderHeight(out AOrientation: QtOrientation): Integer;
var
  W: QHeaderViewH;
begin
  Result := 0;
  AOrientation := QtHorizontal;
  W := QTreeView_header(QTreeViewH(Widget));
  if QWidget_isVisible(W) and QWidget_isVisibleTo(W, Widget) then
  begin
    AOrientation := QHeaderView_orientation(W);
    if AOrientation = QtHorizontal then
      Result := QWidget_height(W)
    else
      Result := QWidget_width(W);
  end;
end;

function TQtTreeWidget.getItemVisible(AItem: QTreeWidgetItemH): Boolean;
begin
  Result := not QTreeWidget_isItemHidden(QTreeWidgetH(Widget), AItem);
end;

function TQtTreeWidget.getTopItem: integer;
begin
  Result := getVisibleRowCount(True);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.getVisibleRowCount
  Params:  Boolean
  Returns: if AFirstVisibleOnly = False (default) then it returns number
  of visible rows, or 0 if there's no visible rows.
  When AFirstVisibleOnly = True then it returns index of first visible row,
  otherwise result is -1.
 ------------------------------------------------------------------------------}
function TQtTreeWidget.getVisibleRowCount(const AFirstVisibleOnly: boolean = false): integer;
var
  R: TRect;
  i: integer;
  item: QTreeWidgetItemH;
  RowIndex: integer;
  RowHeight: integer;
begin
  if AFirstVisibleOnly then
    Result := -1
  else
    Result := 0;
  QWidget_contentsRect(viewportWidget, @R);
  i := 0;
  repeat
    item := itemAt(0, i);
    if item <> nil then
    begin
      RowIndex := getRow(Item);
      if AFirstVisibleOnly then
      begin
        Result := RowIndex;
        break;
      end;
      RowHeight := getRowHeight(RowIndex);
      if RowHeight <= 0 then
        RowHeight := 1;
      inc(Result);
      inc(i, RowHeight);
    end else
      inc(i, 1);
  until i >= R.Bottom;
end;

procedure TQtTreeWidget.setItemVisible(AItem: QTreeWidgetItemH;
  const AVisible: Boolean);
begin
  QTreeWidget_setItemHidden(QTreeWidgetH(Widget), AItem, not AVisible);
end;

procedure TQtTreeWidget.setItemText(AItem: QTreeWidgetItemH;
  const AColumn: Integer; const AText: WideString; const AAlignment: QtAlignment
  );
begin
  QTreeWidgetItem_setText(AItem, AColumn, @AText);
  QTreeWidgetItem_setTextAlignment(AItem, AColumn, AAlignment);
end;

function TQtTreeWidget.selCount: Integer;
begin
  Result := length(selectedItems);
end;

function TQtTreeWidget.selectedItems: TPtrIntArray;
begin
  QTreeWidget_selectedItems(QTreeWidgetH(Widget), @Result);
end;

procedure TQtTreeWidget.setHeaderVisible(AVisible: Boolean);
begin
  if (csDesigning in LCLObject.ComponentState) then
    QTreeView_setHeaderHidden(QTreeViewH(Widget), not AVisible)
  else
    Header.setVisible(AVisible);
end;

procedure TQtTreeWidget.setItemSelected(AItem: QTreeWidgetItemH;
  ASelect: Boolean);
var
  Msg: TLMNotify;
  NMLV: TNMListView;
  AParent: QTreeWidgetItemH;
  AIndex: Integer;
  ASubIndex: Integer;
begin
  if QTreeWidget_isItemSelected(QTreeWidgetH(Widget), AItem) = ASelect then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);
  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;

  AIndex := getRow(AItem);

  if AIndex = -1 then
    exit;

  AParent := QTreeWidgetItem_parent(AItem);

  if AParent <> nil then
    ASubIndex := QTreeWidgetItem_indexOfChild(AParent, AItem)
  else
    ASubIndex := 0;


  NMLV.iItem := AIndex;
  NMLV.iSubItem := ASubIndex;
  if not ASelect then
    NMLV.uOldState := LVIS_SELECTED
  else
    NMLV.uNewState := LVIS_SELECTED;
  NMLV.uChanged := LVIF_STATE;
  Msg.NMHdr := @NMLV.hdr;

  QTreeWidget_setItemSelected(QTreeWidgetH(Widget), AItem, ASelect);

  if not FSyncingItems then
    DeliverMessage(Msg);
end;

procedure TQtTreeWidget.setStretchLastSection(AValue: Boolean);
begin
  if (csDesigning in LCLObject.ComponentState) then
    QHeaderView_setStretchLastSection(QTreeView_header(QTreeViewH(Widget)),
      AValue)
  else
    Header.setStretchLastSection(AValue);
end;

procedure TQtTreeWidget.sortItems(Acolumn: Integer; AOrder: QtSortOrder);
begin
  QTreeWidget_sortItems(QTreeWidgetH(Widget), AColumn, AOrder);
end;

procedure TQtTreeWidget.AttachEvents;
begin
  inherited AttachEvents;

  FCurrentItemChangedHook := QTreeWidget_hook_create(Widget);
  FItemDoubleClickedHook := QTreeWidget_hook_create(Widget);
  FItemClickedHook := QTreeWidget_hook_create(Widget);
  FItemActivatedHook := QTreeWidget_hook_create(Widget);
  FItemChangedHook := QTreeWidget_hook_create(Widget);
  FItemEnteredHook := QTreeWidget_hook_create(Widget);
  FSelectionChangedHook := QTreeWidget_hook_create(Widget);
  
  QTreeWidget_hook_hook_currentItemChanged(FCurrentItemChangedHook, @SignalCurrentItemChanged);

  QTreeWidget_hook_hook_ItemDoubleClicked(FItemDoubleClickedHook, @SignalItemDoubleClicked);

  QTreeWidget_hook_hook_ItemClicked(FItemClickedHook, @SignalItemClicked);

  QTreeWidget_hook_hook_ItemActivated(FItemActivatedHook, @SignalItemActivated);

  QTreeWidget_hook_hook_ItemChanged(FItemChangedHook, @SignalItemChanged);

  QTreeWidget_hook_hook_ItemEntered(FItemEnteredHook, @SignalItemEntered);

  QTreeWidget_hook_hook_itemSelectionChanged(FSelectionChangedHook, @SignalSelectionChanged);

end;

procedure TQtTreeWidget.DetachEvents;
begin
  QTreeWidget_hook_destroy(FCurrentItemChangedHook);
  QTreeWidget_hook_destroy(FItemDoubleClickedHook);
  QTreeWidget_hook_destroy(FItemClickedHook);
  QTreeWidget_hook_destroy(FItemActivatedHook);
  QTreeWidget_hook_destroy(FItemChangedHook);
  QTreeWidget_hook_destroy(FItemEnteredHook);
  QTreeWidget_hook_destroy(FSelectionChangedHook);

  if FSectionClicked <> nil then
    QHeaderView_hook_destroy(FSectionClicked);
  if FSortChanged <> nil then
    QHeaderView_hook_destroy(FSortChanged);

  inherited DetachEvents;
end;

function TQtTreeWidget.getClientBounds: TRect;
var
  Offset: Integer;
  AOrientation: QtOrientation;
begin
  Result := inherited getClientBounds;
  Offset := getHeaderHeight(AOrientation);
  if Offset > 0 then
  begin
    if AOrientation = QtHorizontal then
      Inc(Result.Top, Offset)
    else
      Inc(Result.Left, Offset);
  end;
end;

function TQtTreeWidget.getClientOffset: TPoint;
var
  Offset: Integer;
  AOrientation: QtOrientation;
begin
  Offset := getHeaderHeight(AOrientation);
  if Offset > 0 then
    Result := Point(0, 0)
  else
    Result := inherited getClientOffset;
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemClicked
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  MsgN: TLMNotify;
  NMLV: TNMListView;
  R: TRect;
  Pt: TPoint;
  i: Integer;
begin
  // we'll send also which item is clicked ... probably future
  // lcl implementation of OnItemClick.
  if not Checkable then
    exit;
  FillChar(MsgN, SizeOf(MsgN), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  MsgN.Msg := LM_CLICKED;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := NM_CLICK;

  NMLV.iItem := getRow(Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := UINT(NM_CLICK);
  NMLV.uChanged :=  LVIS_SELECTED;

  QTreeWidget_visualItemRect(QTreeWidgetH(Widget), @R, Item);

  pt.X := R.Left;
  pt.Y := R.Top;

  NMLV.ptAction := pt;

  MsgN.NMHdr := @NMLV.hdr;

  DeliverMessage(MsgN);

  {sync LCL items for selected property}
  if (LCLObject <> nil) and (LCLObject is TListView) then
    for i := 0 to TListView(LCLObject).Items.Count - 1 do
      TListView(LCLObject).Items[i].Selected;

  {inform LCL about current change}
  MsgN.Msg := CN_NOTIFY;
  NMLV.hdr.code := LVN_ITEMCHANGED;
  NMLV.uNewState := 0;
  NMLV.uOldState := 0;
  if QTreeWidget_isItemSelected(QTreeWidgetH(Widget), Item) then
    NMLV.uNewState := LVIS_SELECTED
  else
    NMLV.uOldState := LVIS_SELECTED;
  NMLV.uChanged :=  LVIF_STATE;
  MsgN.NMHdr := @NMLV.hdr;
  DeliverMessage(Msgn);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemDoubleClicked
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemDoubleClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := LM_LBUTTONDBLCLK;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := NM_DBLCLK;

  NMLV.iItem := getRow(Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := UINT(NM_DBLCLK);
  NMLV.uChanged := LVIS_SELECTED;
  // LVIF_STATE;
  
  Msg.NMHdr := @NMLV.hdr;
  {we send dblclick over TQtAbstractItemView.itemViewViewportEventFilter }
 // DeliverMessage( Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemActivated
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemActivated(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;

  NMLV.iItem := getRow(Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := LVIS_FOCUSED;
  NMLV.uChanged := LVIF_STATE;

  Msg.NMHdr := @NMLV.hdr;

  DeliverMessage( Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemEntered
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemEntered(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_ENTER;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemChanged
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemChanged(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMessage;
begin
  if InUpdate then exit;
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalCurrentItemChanged
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalCurrentItemChanged(current: QTreeWidgetItemH; previous: QTreeWidgetItemH) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
  AParent: QTreeWidgetItemH;
  ASubIndex: Integer;
  AIndex: Integer;
begin
  FCurrentItem := Current;
  FPreviousItem := Previous;

  if FMousePressed then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGING;

  AIndex := getRow(Current);

  AParent := nil;
  if Current <> nil then
    AParent := QTreeWidgetItem_parent(Current);

  if AParent <> nil then
    ASubIndex := QTreeWidgetItem_indexOfChild(AParent, Current)
  else
    ASubIndex := 0;

  NMLV.iItem := AIndex;
  NMLV.iSubItem := ASubIndex;
  NMLV.uNewState := LVIS_SELECTED;
  NMLV.uChanged := LVIF_STATE;

  Msg.NMHdr := @NMLV.hdr;
  DeliverMessage(Msg);

  FSyncingItems := True;
  try
    if Current <> nil then
    begin
      FillChar(Msg, SizeOf(Msg), #0);
      FillChar(NMLV, SizeOf(NMLV), #0);
      Msg.Msg := CN_NOTIFY;
      NMLV.hdr.hwndfrom := LCLObject.Handle;
      NMLV.hdr.code := LVN_ITEMCHANGED;
      NMLV.iItem := AIndex;
      NMLV.iSubItem := ASubIndex;
      if QTreeWidget_isItemSelected(QTreeWidgetH(Widget), Current) then
        NMLV.uNewState := LVIS_SELECTED
      else
        NMLV.uOldState := LVIS_SELECTED;
      NMLV.uChanged := LVIF_STATE;
      Msg.NMHdr := @NMLV.hdr;
      DeliverMessage(Msg);
    end;

    if Previous <> nil then
    begin
      FillChar(Msg, SizeOf(Msg), #0);
      FillChar(NMLV, SizeOf(NMLV), #0);
      Msg.Msg := CN_NOTIFY;
      NMLV.hdr.hwndfrom := LCLObject.Handle;
      NMLV.hdr.code := LVN_ITEMCHANGED;
      NMLV.iItem := getRow(Previous);
      AParent := QTreeWidgetItem_parent(Previous);
      if AParent <> nil then
        ASubIndex := QTreeWidgetItem_indexOfChild(AParent, Previous)
      else
        ASubIndex := 0;
      NMLV.iSubItem := ASubIndex;
      if QTreeWidget_isItemSelected(QTreeWidgetH(Widget), Previous) then
        NMLV.uNewState := LVIS_SELECTED
      else
        NMLV.uOldState := LVIS_SELECTED;
      NMLV.uChanged := LVIF_STATE;
      Msg.NMHdr := @NMLV.hdr;
      DeliverMessage(Msg);
    end;
  finally
    FSyncingItems := False;
  end;
end;

procedure TQtTreeWidget.SignalSelectionChanged(); cdecl;
begin
  if FMousePressed then
  begin
    FMousePressed := False;
    if FCurrentItem <> nil then
      SignalCurrentItemChanged(FCurrentItem, FPreviousItem);
  end;
end;

procedure TQtTreeWidget.SignalSortIndicatorChanged(ALogicalIndex: Integer;
  AOrder: QtSortOrder)cdecl;
begin
  if FSorting or not Assigned(LCLObject) or not
    QHeaderView_isSortIndicatorShown(QHeaderViewH(Header.Widget)) then
    exit;
  FSorting := True;
  try
    if ALogicalIndex >= 0 then
      sortItems(ALogicalIndex, AOrder);
  finally
    FSorting := False;
  end;
end;

{TQtTableView}

function TQtTableView.CreateWidget(const Params: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTableView.CreateWidget');
  {$endif}
  HasPaint := False;
  if Params.WndParent <> 0 then
    Parent := TQtWidget(Params.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QTableView_create(Parent);
  if (QtVersionMajor = 4) and (QtVersionMinor < 6) then
    QWidget_setAutoFillBackground(Result, True);
end;

function TQtTableView.verticalHeader: TQtHeaderView;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTableView.verticalHeader');
  {$endif}
  if FVerticalHeader = nil then
    FVerticalHeader := TQtHeaderView.CreateFrom(LCLObject, QTableView_verticalHeader(QTableViewH(Widget)));
  Result := FVerticalHeader;
end;

function TQtTableView.horizontalHeader: TQtHeaderView;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTableView.horizontalHeader');
  {$endif}
  if FHorizontalHeader = nil then
    FHorizontalHeader := TQtHeaderView.CreateFrom(LCLObject, QTableView_horizontalHeader(QTableViewH(Widget)));
  Result := FHorizontalHeader;
end;

procedure TQtTableView.setVisible(AVisible: Boolean);
begin
  QWidget_setVisible(Widget, AVisible);
end;

function TQtTableView.getGridStyle: QtPenStyle;
begin
  Result := QTableView_gridStyle(QTableViewH(Widget));
end;

procedure TQtTableView.setGridStyle(ANewStyle: QtPenStyle);
begin
  QTableView_setGridStyle(QTableViewH(Widget), ANewStyle);
end;

destructor TQtTableView.Destroy;
begin
  if FVerticalHeader <> nil then
    FVerticalHeader.Free;
  if FHorizontalHeader <> nil then
    FHorizontalHeader.Free;
  inherited Destroy;
end;

function TQtTableView.getViewPort: QWidgetH;
begin
  Result := viewportWidget;
end;

function TQtTableView.getClientBounds: TRect;
begin
  QWidget_contentsRect(Widget, @Result);
end;

procedure TQtTableView.grabMouse;
begin
  QWidget_grabMouse(Widget);
end;

{ TQtMenu }

function TQtMenu.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  AGroup: TQtActionGroup;
  Parent: QWidgetH;
begin
  FTrackButton := QtNoButton;
  FIcon := nil;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QMenu_create(Parent);
  FDeleteLater := True;
  FActionHandle := nil;
  FActions := TFPList.Create;
  AGroup := TQtActionGroup.Create(Result);
  if FMenuItem <> nil then
    AGroup.GroupIndex := FMenuItem.GroupIndex
  else
    AGroup.GroupIndex := -1;
  AGroup.Exclusive := False;
  FActions.Add(AGroup);
end;

procedure TQtMenu.InitializeWidget;
begin
  ChildOfComplexWidget := ccwNone;
  WidgetColorRole := QPaletteWindow;
  TextColorRole := QPaletteText;
  Widget := CreateWidget(FParams);
  setProperty(Widget, 'lclwidget', Int64(PtrUInt(Self)));
  QtWidgetSet.AddHandle(Self);
end;

constructor TQtMenu.Create(const AMenuItem: TMenuItem);
var
  AParams: TCreateParams;
begin
  FillChar(AParams, SizeOf(AParams), #0);
  FMenuItem := AMenuItem;
  inherited Create(nil, AParams);
end;

destructor TQtMenu.Destroy;
var
  i: integer;
begin
  if FIcon <> nil then
    QIcon_destroy(FIcon);

  if Assigned(FActions) then
  begin
    for i := 0 to FActions.Count - 1 do
      TQtActionGroup(FActions.Items[i]).Free;

    FActions.Free;
  end;

  inherited Destroy;
end;

procedure TQtMenu.AttachEvents;
begin
  FTriggeredHook := QAction_hook_create(ActionHandle);
  FHoveredHook := QAction_hook_create(ActionHandle);
  FAboutToHideHook := QMenu_hook_create(Widget);
  FEventHook := QObject_hook_create(Widget);

  QAction_hook_hook_triggered(FTriggeredHook, @SlotTriggered);

  QAction_hook_hook_hovered(FHoveredHook, @SlotHovered);
  
  QMenu_hook_hook_aboutToHide(FAboutToHideHook, @SlotAboutToHide);

  QObject_hook_hook_events(FEventHook, @EventFilter);
end;

procedure TQtMenu.DetachEvents;
begin
  if FActionEventFilter <> nil then
  begin
    QObject_hook_destroy(FActionEventFilter);
    FActionEventFilter := nil;
  end;

  if FTriggeredHook <> nil then
  begin
    QAction_hook_destroy(FTriggeredHook);
    FTriggeredHook := nil;
  end;

  if FHoveredHook <> nil then
  begin
    QAction_hook_destroy(FHoveredHook);
    FHoveredHook := nil;
  end;
  
  if FAboutToHideHook <> nil then
  begin
    QMenu_hook_destroy(FAboutToHideHook);
    FAboutToHideHook := nil;
  end;
  inherited DetachEvents;
end;

procedure TQtMenu.SlotHovered; cdecl;
begin
  FMenuItem.IntfDoSelect;
end;

procedure TQtMenu.SlotAboutToHide; cdecl;
var
  Event: QLCLMessageEventH;
begin
  if FMenuItem.Menu is TPopupMenu then
  begin
    Event := QLCLMessageEvent_create(LCLQt_PopupMenuClose);
    QCoreApplication_postEvent(Widget, Event);
  end;
end;

procedure TQtMenu.DoPopupClose;
begin
  if FMenuItem.Menu is TPopupMenu then
    TPopupMenu(FMenuItem.Menu).Close;
end;

procedure TQtMenu.SlotDestroy; cdecl;
begin
  Widget := nil;
end;

procedure TQtMenu.PopUp(pos: PQtPoint; at: QActionH);
begin
  QMenu_Popup(QMenuH(Widget), pos, at);
end;

function TQtMenu.actionHandle: QActionH;
begin
  if FActionHandle = nil then
  begin
    if FActionEventFilter <> nil then
    begin
      QObject_hook_destroy(FActionEventFilter);
      FActionEventFilter := nil;
    end;
    FActionHandle := QMenu_menuAction(QMenuH(Widget));
    FActionEventFilter := QObject_hook_create(FActionHandle);
    QObject_hook_hook_events(FActionEventFilter, @ActionEventFilter);
  end;
  Result := FActionHandle;
end;

function TQtMenu.addMenu(AMenu: QMenuH): QActionH;
begin
  setHasSubmenu(True);
  Result := QMenu_addMenu(QMenuH(Widget), AMenu);
end;

procedure TQtMenu.removeActionGroup;
var
  Action: QActionGroupH;
begin
  Action := QAction_actionGroup(ActionHandle);
  if Action <> nil then
    QActionGroup_removeAction(Action, ActionHandle);
end;

procedure TQtMenu.setActionGroups(AItem: TMenuItem);
var
  i: integer;
  b: Boolean = True;
  Group: TQtActionGroup;
begin
  for i := 0 to FActions.Count - 1 do
  begin
    Group := TQtActionGroup(FActions.Items[i]);
    if Group.GroupIndex = AItem.GroupIndex then
    begin
      QAction_setEnabled(TQtMenu(AItem.Handle).actionHandle, True);
      QAction_setVisible(TQtMenu(AItem.Handle).actionHandle, True);
      Group.addAction(TQtMenu(AItem.Handle).actionHandle);
      Group.Exclusive := AItem.RadioItem;
      Group.Visible := True;
      Group.Enabled := True;
      b := False;
      break;
    end;
  end;
  if b then
  begin
    Group := TQtActionGroup.Create(Widget);
    Group.Exclusive := AItem.RadioItem;
    Group.GroupIndex := AItem.GroupIndex;
    QAction_setEnabled(TQtMenu(AItem.Handle).actionHandle, True);
    QAction_setVisible(TQtMenu(AItem.Handle).actionHandle, True);
    Group.addAction(TQtMenu(AItem.Handle).actionHandle);
    Group.Visible := True;
    Group.Enabled := True;
    FActions.Add(Group);
  end;
end;

function TQtMenu.insertMenu(AIndex: Integer; AMenu: QMenuH; AItem: TMenuItem): QActionH;
var
  actionBefore: QActionH;
begin

  setHasSubmenu(True);

  if (AItem <> nil) and not AItem.IsLine then
    setActionGroups(AItem);

  actionBefore := getActionByIndex(AIndex);

  if actionBefore <> nil then
    Result := QMenu_insertMenu(QMenuH(Widget), actionBefore, AMenu)
  else
    Result := QMenu_addMenu(QMenuH(Widget), AMenu);
end;

function TQtMenu.getHasSubMenu: boolean;
begin
  Result := QAction_menu(ActionHandle) <> nil;
end;

function TQtMenu.getVisible: Boolean;
begin
  if ActionHandle = nil then
    exit(False);
  Result := QAction_isVisible(ActionHandle);
end;

function TQtMenu.getText: WideString;
begin
  QAction_text(ActionHandle, @Result);
end;

procedure TQtMenu.setText(const W: WideString);
begin
  QAction_setText(ActionHandle, @W);
end;

procedure TQtMenu.setVisible(AVisible: Boolean);
begin
  QAction_setVisible(ActionHandle, AVisible);
end;

procedure TQtMenu.setChecked(p1: Boolean);
begin
  setCheckable(p1);
  QAction_setChecked(ActionHandle, p1);
end;

procedure TQtMenu.setCheckable(p1: Boolean);
begin
  if FMenuItem.RadioItem or FMenuItem.ShowAlwaysCheckable then
    QAction_setCheckable(ActionHandle, True)
  else
    QAction_setCheckable(ActionHandle, p1);
end;

procedure TQtMenu.setHasSubmenu(AValue: Boolean);
begin
  if AValue then
    QAction_setMenu(ActionHandle, QMenuH(Widget))
  else
    QAction_setMenu(ActionHandle, nil);
end;

procedure TQtMenu.setIcon(AIcon: QIconH);
begin
  QMenu_setIcon(QMenuH(Widget), AIcon);
end;

procedure TQtMenu.setImage(AImage: TQtImage);
begin
  if FIcon <> nil then
  begin
    QIcon_destroy(FIcon);
    FIcon := nil;
  end;

  if AImage <> nil then
    FIcon := AImage.AsIcon()
  else
    FIcon := QIcon_create();
    
  setIcon(FIcon);
end;

procedure TQtMenu.setSeparator(AValue: Boolean);
begin
  QAction_setSeparator(ActionHandle, AValue);
end;

procedure TQtMenu.setShortcut(AShortcut: TShortcut);
var
  Key: Word;
  KeySequence: QKeySequenceH;
  Shift: TShiftState;
  Modifiers: QtModifier;
begin
  if AShortCut <> 0 then
  begin
    ShortCutToKey(AShortCut, Key, Shift);
    Modifiers := ShiftStateToQtModifiers(Shift);
    // there is no need in destroying QKeySequnce
    KeySequence := QKeySequence_create(LCLKeyToQtKey(Key) or Modifiers);
  end
  else
    KeySequence := QKeySequence_create();
  QAction_setShortcut(ActionHandle, KeySequence);
  QKeySequence_destroy(KeySequence);
end;

{------------------------------------------------------------------------------
  Method: TQtMenu.SlotTriggered

  Callback for menu item click
 ------------------------------------------------------------------------------}
procedure TQtMenu.SlotTriggered(checked: Boolean); cdecl;
var
  Event: QLCLMessageEventH;
begin
  Event := QLCLMessageEvent_create(LCLQt_PopupMenuTriggered);
  QCoreApplication_postEvent(Widget, Event, 1 {high priority});
end;

function TQtMenu.ActionEventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
var
  TempAction: QActionH;
  Group: QActionGroupH;
begin
  Result := False;
  QEvent_accept(Event);
  if Assigned(FMenuItem) and (QEvent_type(Event) = QEventActionChanged) then
  begin
    {qt shouldn't change checkables in any case, LCL should do that !}
    TempAction := QActionEvent_action(QActionEventH(Event));
    if (TempAction <> nil) and
      QAction_isCheckable(TempAction) and
      (QAction_isChecked(TempAction) <> FMenuItem.Checked) then
    begin
      Group := QAction_actionGroup(TempAction);
      if Group <> nil then
      begin
        if QActionGroup_isExclusive(Group) then
          QObject_blockSignals(Group, True)
        else
          QObject_blockSignals(TempAction, True);
      end else
        QObject_blockSignals(TempAction, True);

      QAction_setChecked(TempAction, FMenuItem.Checked);

      if QObject_signalsBlocked(TempAction) then
      begin
        QObject_blockSignals(TempAction, False);
        Result := True;
        QEvent_ignore(Event);
      end;
    end;
  end;
end;

function TQtMenu.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  Msg: TLMessage;
  TempAction: QActionH;
begin
  Result := False;
  QEvent_accept(Event);

  case QEvent_type(Event) of
    LCLQt_PopupMenuTriggered:
      begin
        FillChar(Msg, SizeOf(Msg), 0);
        Msg.msg := LM_ACTIVATE;
        if Assigned(FMenuItem) then
          FMenuItem.Dispatch(Msg);
        Result := True;
      end;
    LCLQt_PopupMenuClose:
      begin
        DoPopupClose;
        Result := True;
      end;
    QEventDestroy: SlotDestroy;
    QEventMouseButtonPress,
    QEventMouseButtonRelease:
      begin
        Result := (FTrackButton = QtLeftButton) and
          (QMouseEvent_button(QMouseEventH(Event)) <> FTrackButton);
        if Assigned(FMenuItem) and not (FMenuItem.Menu is TPopupMenu) then
        begin
          TempAction := QMenu_actionAt(QMenuH(Widget),
            QMouseEvent_pos(QMouseEventH(Event)));
          {trigger LCL if root of menu have OnClick() connected,
           since qt won't do that for us.}
          if (QMouseEvent_button(QMouseEventH(Event)) = QtLeftButton) and
            Assigned(FMenuItem.OnClick) and
            (TempAction = nil) then
            SlotTriggered();
        end;
      end;
  end;
end;

{ TQtMenuBar }

constructor TQtMenuBar.Create(const AParent: QWidgetH);
begin
  Create;
  Widget := QMenuBar_create(AParent);
  FHeight := getHeight;
  FVisible := False;
  setVisible(FVisible);
end;

function TQtMenuBar.addMenu(AMenu: QMenuH): QActionH;
begin
  if not FVisible then
  begin
    FVisible := True;
    setVisible(FVisible);
  end;
  Result := QMenuBar_addMenu(QMenuBarH(Widget), AMenu);
end;

function TQtMenuBar.insertMenu(AIndex: Integer; AMenu: QMenuH): QActionH;
var
  actionBefore: QActionH;
begin
  if not FVisible then
  begin
    FVisible := True;
    setVisible(FVisible);
  end;
  actionBefore := getActionByIndex(AIndex);
  if actionBefore <> nil then
    Result := QMenuBar_insertMenu(QMenuBarH(Widget), actionBefore, AMenu)
  else
    Result := QMenuBar_addMenu(QMenuBarH(Widget), AMenu);
end;

function TQtMenuBar.getGeometry: TRect;
begin
  Result := inherited getGeometry;

  // workaround since after attaching menu it takes 0 height
  if Result.Bottom = 0 then
    Result.Bottom := FHeight;
end;

{ TQtProgressBar }

function TQtProgressBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQProgressBar.Create');
  {$endif}
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QProgressBar_create(Parent);
end;

procedure TQtProgressBar.AttachEvents;
begin
  inherited AttachEvents;

  FValueChangedHook := QProgressBar_hook_create(Widget);
  QProgressBar_hook_hook_valueChanged(FValueChangedHook, @SignalValueChanged);
end;

procedure TQtProgressBar.DetachEvents;
begin
  QProgressBar_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

procedure TQtProgressBar.setRange(minimum: Integer; maximum: Integer);
begin
  QProgressBar_setRange(QProgressBarH(Widget), minimum, maximum);
end;

procedure TQtProgressBar.setTextVisible(visible: Boolean);
begin
  QProgressBar_setTextVisible(QProgressBarH(Widget), visible);
end;

procedure TQtProgressBar.setAlignment(const AAlignment: QtAlignment);
begin
  QProgressBar_setAlignment(QProgressBarH(Widget), AAlignment);
end;

procedure TQtProgressBar.setTextDirection(textDirection: QProgressBarDirection);
begin
  QProgressBar_setTextDirection(QProgressBarH(Widget), textDirection);
end;

procedure TQtProgressBar.setValue(value: Integer);
begin
  QProgressBar_setValue(QProgressBarH(Widget), value);
end;

procedure TQtProgressBar.setOrientation(p1: QtOrientation);
begin
  QProgressBar_setOrientation(QProgressBarH(Widget), p1);
end;

procedure TQtProgressBar.setInvertedAppearance(invert: Boolean);
begin
  QProgressBar_setInvertedAppearance(QProgressBarH(Widget), invert);
end;

procedure TQtProgressBar.SignalValueChanged(Value: Integer); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  if not InUpdate then
    DeliverMessage(Msg);
end;

procedure TQtProgressBar.reset;
begin
  QProgressBar_reset(QProgressBarH(Widget));
end;

{ TQtStatusBarPanel }

function TQtStatusBarPanel.CreateWidget(const AParams: TCreateParams
  ): QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtStatusBarPanel.Create');
  {$endif}

  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QLabel_create(Parent);
end;

procedure TQtStatusBarPanel.DrawItem(Sender: QObjectH; Event: QEventH);
var
  Msg: TLMDrawItems;
  AStruct: TPaintStruct;
  ItemStruct: PDrawItemStruct;
  P: TPoint;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.DrawItem ', dbgsName(LCLObject));
  {$endif}
  if CanSendLCLMessage and (LCLObject is TWinControl) then
  begin
    FillChar(Msg, SizeOf(Msg), #0);

    Msg.Msg := LM_DRAWITEM;
    FillChar(AStruct, SizeOf(TPaintStruct), 0);
    FillChar(ItemStruct, SizeOf(TDrawItemStruct), 0);
    New(ItemStruct);

    with PaintData do
    begin
      PaintWidget := QWidgetH(Sender);
      ClipRegion := QPaintEvent_Region(QPaintEventH(Event));
      if ClipRect = nil then
        New(ClipRect);
      QPaintEvent_Rect(QPaintEventH(Event), ClipRect);
    end;

    ItemStruct^.itemID := UINT(ID);
    ItemStruct^._hDC := BeginPaint(THandle(Self), AStruct);
    FContext := ItemStruct^._hDC;
    ItemStruct^.rcItem := PaintData.ClipRect^;
    ItemStruct^.hwndItem := HWND(Self);
    Msg.Ctl := LCLObject.Handle;
    Msg.DrawItemStruct := ItemStruct;

    P := getClientOffset;
    inc(P.X, FScrollX);
    inc(P.Y, FScrollY);
    TQtDeviceContext(FContext).translate(P.X, P.Y);

    // send paint message
    try
      try
        LCLObject.WindowProc(TLMessage(Msg));
      finally
        Dispose(PaintData.ClipRect);
        Fillchar(FPaintData, SizeOf(FPaintData), 0);
        FContext := 0;
        EndPaint(THandle(Self), AStruct);
        Dispose(ItemStruct);
      end;
    except
      Application.HandleException(nil);
    end;
  end;
end;

function TQtStatusBarPanel.EventFilter(Sender: QObjectH; Event: QEventH
  ): Boolean; cdecl;
begin
  Result := False;
  QEvent_accept(Event);
  if LCLObject = nil then
    exit;
  if HasPaint and (QEvent_type(Event) = QEventPaint) then
  begin
    DrawItem(Sender, Event);
    Result := True;
  end;
end;

{ TQtStatusBar }

function TQtStatusBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  SetLength(Panels, 0);
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QStatusBar_create(Parent);
  if (QtVersionMajor = 4) and (QtVersionMinor < 6) then
    QWidget_setAutoFillBackground(Result, True);
  Widget := Result;
end;

procedure TQtStatusBar.showMessage(text: PWideString; timeout: Integer);
begin
  QStatusBar_showMessage(QStatusBarH(Widget), text, timeout);
end;

procedure TQtStatusBar.addWidget(AWidget: QWidgetH; AStretch: Integer = 0);
begin
  QStatusBar_addWidget(QStatusBarH(Widget), AWidget, AStretch);
end;

procedure TQtStatusBar.removeWidget(AWidget: QWidgetH);
begin
  QStatusBar_removeWidget(QStatusBarH(Widget), AWidget);
end;

function TQtStatusBar.isSizeGripEnabled: Boolean;
begin
  Result := QStatusBar_isSizeGripEnabled(QStatusBarH(Widget));
end;

procedure TQtStatusBar.setSizeGripEnabled(const Value: Boolean);
begin
  QStatusBar_setSizeGripEnabled(QStatusBarH(Widget), Value);
end;

function TQtStatusBar.SlotMouse(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  inherited SlotMouse(Sender, Event);
  Result := True; // cancel event propagation
end;

{ TQtDialog }

function TQtDialog.CreateWidget(parent: QWidgetH; f: QtWindowFlags): QWidgetH;
begin
  Result := QDialog_create(parent, f);
end;

constructor TQtDialog.Create(ADialog: TCommonDialog; parent: QWidgetH; f: QtWindowFlags);
begin
  WidgetColorRole := QPaletteWindow;
  TextColorRole := QPaletteWindowText;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;
  FProps := nil;
  LCLObject := nil;
  FKeysToEat := [];
  FHasPaint := False;
  FDialog := ADialog;
  Widget := CreateWidget(parent, f);
end;

procedure TQtDialog.AttachEvents;
begin
  inherited AttachEvents;
  FDialogEventHook := QObject_hook_create(Widget);
  QObject_hook_hook_events(FDialogEventHook, @EventFilter);
end;

procedure TQtDialog.DetachEvents;
begin
  QObject_hook_destroy(FDialogEventHook);
  inherited DetachEvents;
end;

function TQtDialog.DeliverMessage(var Msg): LRESULT;
begin
  try
    if FDialog.HandleAllocated then
    begin
      FDialog.Dispatch(TLMessage(Msg));
      Result := TLMessage(Msg).Result;
    end else
      Result := 0;
  except
    Application.HandleException(nil);
  end;
end;

function TQtDialog.SlotClose: Boolean; cdecl;
begin
  Result := True;
  FDialog.DoCanClose(Result);
end;

function TQtDialog.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  {we'll need it later. QDialog uses it's own eventLoop !}
  Result := False;
  QEvent_accept(Event);
  if LCLObject <> nil then
    Result := inherited EventFilter(Sender, Event);
end;

function TQtDialog.exec: Integer;
begin
  {$IF DEFINED(DARWIN) OR DEFINED(QT_DIALOGS_USE_QT_LOOP)}
  Result := QDialog_exec(QDialogH(Widget));
  {$ELSE}
  if QWidget_testAttribute(Widget, QtWA_DeleteOnClose) then
    Result := QDialog_exec(QDialogH(Widget))
  else
  begin
    QWidget_setWindowModality(Widget ,QtApplicationModal);
    QWidget_show(Widget);
    repeat
      QCoreApplication_processEvents();
      Application.Idle(true);
    until not QWidget_isVisible(Widget) or Application.Terminated;
    Result := QDialog_result(QDialogH(Widget));
  end;
  {$ENDIF}
end;

procedure TQtDialog.setSizeGripEnabled(const AEnabled: Boolean);
begin
  QDialog_setSizeGripEnabled(QDialogH(Widget), AEnabled);
end;

{ TQtViewPort }

function TQtViewPort.CanPaintBackground: Boolean;
begin
  Result := CanSendLCLMessage and getEnabled and
    (FChildOfComplexWidget = ccwScrollingWinControl) and
    (LCLObject.Color <> clBtnFace) and (LCLObject.Color <> clBackground);
end;

function TQtViewPort.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  HaveVertBar: Boolean;
  HaveHorzBar: Boolean;
begin
  Result := False;
  {$IF DEFINED(VerboseQt) OR DEFINED(VerboseQtEvents)}
  if (QEvent_type(Event) = QEventResize) or
    (QEvent_type(Event) = QEventLayoutRequest) or
    (QEvent_type(Event) = QEventWheel) then
    WriteLn('TQtViewPort.EventFilter: Sender=', IntToHex(PtrUInt(Sender),8),
      ' LCLObject=', dbgsName(LCLObject),
      ' Event=', EventTypeToStr(Event),' inUpdate=',inUpdate);
  {$endif}
  case QEvent_type(Event) of
    QEventResize:
    begin
      // immediate update clientRect !
      if FOwner <> nil then
      begin
        HaveVertBar := Assigned(TQtCustomControl(FOwner).FVScrollbar);
        HaveHorzBar := Assigned(TQtCustomControl(FOwner).FHScrollbar);
        LCLObject.DoAdjustClientRectChange(HaveVertBar or HaveHorzBar);
      end else
        LCLObject.DoAdjustClientRectChange;
    end;
    QEventLayoutRequest: ; // nothing to do here
    QEventWheel:
    begin
      inherited EventFilter(Sender, Event);
      Result := True;
      QEvent_ignore(Event);
    end;
  else
    Result := inherited EventFilter(Sender, Event);
  end;
end;

procedure TQtViewPort.scroll(dx, dy: integer; ARect: PRect = nil);
begin
  inherited scroll(dx, dy, ARect);
  FScrollX := FScrollX + dx;
  FScrollY := FScrollY + dy;
end;

procedure TQtViewPort.stackUnder(AWidget: QWidgetH);
begin
  // do nothing for TQtViewPort
  // inherited stackUnder(AWidget);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.horizontalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}

procedure TQtAbstractScrollArea.setScrollBarPolicy(AIndex: Boolean;
  const AValue: QtScrollBarPolicy);
var
  Area: QAbstractScrollAreaH;
begin
  Area := QAbstractScrollAreaH(Widget);
  if getScrollBarsPolicy(AIndex) <> AValue then
  begin
    if AIndex then
      QAbstractScrollArea_setVerticalScrollBarPolicy(Area, AValue)
    else
      QAbstractScrollArea_setHorizontalScrollBarPolicy(Area, AValue);
  end;
end;

procedure TQtAbstractScrollArea.grabMouse;
var
  W: QWidgetH;
begin
  W := viewportWidget;
  if (W <> nil) and QWidget_isVisible(W) and QWidget_isEnabled(W) then
    QWidget_grabMouse(W)
  else
    inherited grabMouse;
end;

function TQtAbstractScrollArea.GetContainerWidget: QWidgetH;
begin
  Result := viewportWidget;
end;

function TQtAbstractScrollArea.getClientOffset: TPoint;
begin
  with getClientBounds do
    Result := Point(Left, Top);
end;

function TQtAbstractScrollArea.getClientBounds: TRect;
var
  HaveBar: Boolean;
begin
  if not getVisible or
    QWidget_testAttribute(viewportWidget, QtWA_PendingResizeEvent) then
  begin
    QWidget_contentsRect(Widget, @Result);
    if (QStyle_styleHint(QApplication_style(),
          QStyleSH_ScrollView_FrameOnlyAroundContents) <= 0) then
    begin
      HaveBar := Assigned(FVScrollbar);
      if HaveBar and (verticalScrollBar.getVisibleTo(Widget)) then
        dec(Result.Right, verticalScrollBar.getWidth);

      HaveBar := Assigned(FHScrollbar);
      if HaveBar and (horizontalScrollBar.getVisibleTo(Widget)) then
        dec(Result.Bottom, horizontalScrollBar.getHeight);
    end;
  end else
    QWidget_rect(viewportWidget, @Result);
end;

function TQtAbstractScrollArea.getViewOrigin: TPoint;
var
  R: TRect;
begin
  QWidget_rect(viewportWidget, @R);
  // current bindings (2.1) does not assign TopLeft so it's always 0,0
  Result := R.TopLeft;
end;

function TQtAbstractScrollArea.viewportWidget: QWidgetH;
begin
  Result := QAbstractScrollArea_viewport(QAbstractScrollAreaH(Widget));
end;

function TQtAbstractScrollArea.getScrollBarsPolicy(AIndex: Boolean
  ): QtScrollBarPolicy;
var
  Area: QAbstractScrollAreaH;
begin
  Area := QAbstractScrollAreaH(Widget);
  if AIndex then
    Result := QAbstractScrollArea_verticalScrollBarPolicy(Area)
  else
    Result := QAbstractScrollArea_horizontalScrollBarPolicy(Area);
end;

function TQtAbstractScrollArea.horizontalScrollBar: TQtScrollBar;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.horizontalScrollBar');
  {$endif}
  if FHScrollBar = nil then
  begin
    FHScrollBar := TQtScrollBar.CreateFrom(LCLObject,
      QAbstractScrollArea_horizontalScrollBar(QAbstractScrollAreaH(Widget)));
    FHScrollBar.ChildOfComplexWidget := ccwAbstractScrollArea;
    FHScrollBar.FOwner := Self;
    FHScrollBar.setFocusPolicy(QtNoFocus);
    FHScrollBar.AttachEvents;
  end;
  Result := FHScrollBar;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.verticalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.verticalScrollBar: TQtScrollBar;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.verticalScrollBar');
  {$endif}
  if FVScrollBar = nil then
  begin
    FVScrollbar := TQtScrollBar.CreateFrom(LCLObject,
      QAbstractScrollArea_verticalScrollBar(QAbstractScrollAreaH(Widget)));;
    FVScrollBar.ChildOfComplexWidget := ccwAbstractScrollArea;
    FVScrollBar.FOwner := Self;
    FVScrollBar.setFocusPolicy(QtNoFocus);
    FVScrollbar.AttachEvents;
  end;
  Result := FVScrollBar;
end;

procedure TQtAbstractScrollArea.setFocusPolicy(const APolicy: QtFocusPolicy);
begin
  QWidget_setFocusPolicy(Widget, APolicy);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setHorizontalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setHorizontalScrollBar(AScrollBar: TQtScrollBar);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setHorizontalScrollBar');
  {$endif}
  FHScrollbar := AScrollBar;
  if Assigned(FHScrollBar) then
    QAbstractScrollArea_setHorizontalScrollBar(QAbstractScrollAreaH(Widget), QScrollBarH(FHScrollBar.Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setVerticalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setVerticalScrollBar(AScrollBar: TQtScrollBar);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setVerticalScrollBar');
  {$endif}
  FVScrollBar := AScrollBar;
  if Assigned(FVScrollBar) then
    QAbstractScrollArea_setVerticalScrollBar(QAbstractScrollAreaH(Widget), QScrollBarH(FVScrollBar.Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setScrollStyle
  Params:  None
  Returns: Nothing
           Setting scrollbar''s policy (LCL TScrollStyle)
 -----------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setScrollStyle(AScrollStyle: TScrollStyle);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setScrollStyle');
  {$endif}
  case AScrollStyle of
    ssNone:
    begin
      ScrollBarPolicy[True] := QtScrollBarAlwaysOff;
      ScrollBarPolicy[False] := QtScrollBarAlwaysOff;
    end;
    ssHorizontal, ssVertical:
    begin
      ScrollBarPolicy[AScrollStyle = ssVertical] := QtScrollBarAlwaysOn;
    end;
    ssBoth:
    begin
      ScrollBarPolicy[True] := QtScrollBarAlwaysOn;
      ScrollBarPolicy[False] := QtScrollBarAlwaysOn;
    end;
    ssAutoHorizontal, ssAutoVertical:
    begin
      ScrollBarPolicy[AScrollStyle = ssAutoVertical] := QtScrollBarAsNeeded;
    end;
    ssAutoBoth:
    begin
      ScrollBarPolicy[True] := QtScrollBarAsNeeded;
      ScrollBarPolicy[False] := QtScrollBarAsNeeded;
    end;
  end;

end;

procedure TQtAbstractScrollArea.SetNoMousePropagation(Sender: QWidgetH;
  const ANoMousePropagation: Boolean);
begin
  if Sender = viewportWidget then
    inherited SetNoMousePropagation(Sender, False)
  else
    inherited SetNoMousePropagation(Sender, ANoMousePropagation);
end;

procedure TQtAbstractScrollArea.DestroyNotify(AWidget: TQtWidget);
begin
  if AWidget = FHScrollbar then
    FHScrollbar := nil;

  if AWidget = FVScrollbar then
    FVScrollbar := nil;

  inherited DestroyNotify(AWidget);
end;

destructor TQtAbstractScrollArea.Destroy;
begin
  FreeAndNil(FHScrollBar);
  FreeAndNil(FVScrollBar);
  inherited Destroy;
end;

procedure TQtAbstractScrollArea.Update(ARect: PRect);
var
  P: TPoint;
begin
  if ARect <> nil then
  begin
    P := getClientOffset;
    OffsetRect(ARect^, -P.X , -P.Y);
    QWidget_update(viewportWidget, ARect);
  end else
    QWidget_update(viewportWidget);
end;

procedure TQtAbstractScrollArea.Repaint(ARect: PRect);
var
  P: TPoint;
begin
  if ARect <> nil then
  begin
    P := getClientOffset;
    OffsetRect(ARect^, -P.X , -P.Y);
    QWidget_repaint(viewportWidget, ARect);
  end else
    QWidget_repaint(viewportWidget);
end;

{ TQtCustomControl }

{------------------------------------------------------------------------------
  Function: TQtCustomControl.CreateWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtCustomControl.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtCustomControl.CreateWidget');
  {$endif}
  FHasPaint := True;
  FViewPortWidget := nil;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QLCLAbstractScrollArea_create(Parent);

  if (LCLObject is TScrollingWinControl) then
  begin
    if (QtVersionMajor = 4) and (QtVersionMinor < 6) and
      not (csDesigning in LCLObject.ComponentState) then
      QWidget_setAutoFillBackground(Result, True);
    FChildOfComplexWidget := ccwScrollingWinControl;
  end else
    QWidget_setAutoFillBackground(Result, False);

  QWidget_setAttribute(Result, QtWA_InputMethodEnabled);
end;

{------------------------------------------------------------------------------
  Function: TQtCustomControl.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtCustomControl.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtCustomControl.Destroy');
  {$endif}
  viewportDelete;
  inherited Destroy;
end;

function TQtCustomControl.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  Result := False;
  QEvent_accept(Event);
  if (LCLObject = nil) then
    exit;

  if (QEvent_type(Event) in [
                            QEventPaint,
                            QEventMouseButtonPress,
                            QEventMouseButtonRelease,
                            QEventMouseButtonDblClick,
                            QEventContextMenu
                           ]) and
     (ClassType = TQtCustomControl) then
    Result := False
  else
  if QEvent_type(Event) = QEventWheel then
  begin
    if not horizontalScrollBar.getVisible and not verticalScrollBar.getVisible then
      Result := inherited EventFilter(Sender, Event)
    else
      Result := False;  
  end else
  {$IFDEF MSWINDOWS}
  {sometimes our IDE completely freezes, after screensaver activated
   or OS sleep state / hibernation under Win32 (if cursor stays
   inside SourceEditor), so if application is deactivated by OS
   we must release mouse grab. }
  if QEvent_type(Event) = QEventApplicationDeactivate then
  begin
    if HWND(Self) = GetCapture then
      ReleaseCapture;
    Result := inherited EventFilter(Sender, Event);
  end else
  {$ENDIF}
    Result := inherited EventFilter(Sender, Event);
end;

procedure TQtCustomControl.ViewPortEventFilter(event: QEventH; retval: PBoolean); cdecl;
var
  MouseEventTyp: Boolean;
  AForm: TCustomForm;
begin
  {$ifdef VerboseViewPortEventFilter}
    WriteLn('ViewPortEventFilter ',QEvent_type(Event));
  {$endif}
  
  QEvent_accept(Event);

  case QEvent_type(Event) of
    QEventResize,
    QEventMouseButtonPress,
    QEventMouseButtonRelease,
    QEventMouseButtonDblClick,
    QEventMouseMove,
    QEventWheel,
    QEventContextMenu,
    QEventPaint:
    begin
      MouseEventTyp := (QEvent_type(Event) = QEventMouseButtonPress) or
        (QEvent_type(Event) = QEventMouseButtonRelease) or
        (QEvent_type(Event) = QEventMouseButtonDblClick) or
        (QEvent_type(Event) = QEventWheel);

      if QEvent_type(Event) = QEventWheel then
        QLCLAbstractScrollArea_InheritedViewportEvent(QLCLAbstractScrollAreaH(Widget), event);

      retval^ := True;

      {$note this is workaround for infinite loop with some
       applications since qt doesn't have scrollbars on forms yet.
       example of problem: #16413.
       After implementing TQtMainWindow.Widget from QAbstractScrollArea
       remove this workaround.}
      if (QEvent_type(Event) = QEventResize) and
        (FChildOfComplexWidget = ccwScrollingWinControl) and
        Assigned(LCLObject.Parent) then
      begin
        AForm := GetParentForm(LCLObject);
        LCLObject.DoAdjustClientRectChange(not AForm.AutoScroll);
      end else
        Viewport.EventFilter(ViewPort.Widget, Event);
      // do not allow qt to call notifications on user input events (mouse)
      // otherwise we can crash since our object maybe does not exist
      // after mouse clicks
      if not MouseEventTyp then
        QEvent_ignore(Event);
    end;
  else
    retval^ := QLCLAbstractScrollArea_InheritedViewportEvent(QLCLAbstractScrollAreaH(Widget), event);
  end;
end;

procedure TQtCustomControl.DestroyNotify(AWidget: TQtWidget);
begin
  if AWidget = FCornerWidget then
    FCornerWidget := nil;

  if AWidget = FViewPortWidget then
    FViewPortWidget := nil;

  inherited DestroyNotify(AWidget);
end;

{------------------------------------------------------------------------------
  Function: TQtCustomControl.cornerWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtCustomControl.cornerWidget: TQtWidget;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.cornerWidget');
  {$endif}
  Result := FCornerWidget;
end;

{------------------------------------------------------------------------------
  Function: TQtCustomControl.setCornerWidget
  Params:  TQtWidget
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtCustomControl.setCornerWidget(AWidget: TQtWidget);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setCornerWidget');
  {$endif}
  FCornerWidget := AWidget;
  if Assigned(FCornerWidget) then
    QAbstractScrollArea_setCornerWidget(QAbstractScrollAreaH(Widget), FCornerWidget.Widget)
  else
    QAbstractScrollArea_setCornerWidget(QAbstractScrollAreaH(Widget), NiL);
end;

procedure TQtCustomControl.setCursor(const ACursor: QCursorH);
begin
  if (LCLObject is TCustomControl) and HasPaint then
    viewport.setCursor(ACursor)
  else
    inherited setCursor(ACursor);
end;

procedure TQtCustomControl.setViewport(const AViewPort: QWidgetH);
begin
  QAbstractScrollArea_setViewport(QAbstractScrollAreaH(Widget), AViewPort);
end;

procedure TQtCustomControl.setVisible(AVisible: Boolean);
begin
  inherited setVisible(AVisible);
  if FViewPortWidget <> nil then
    FViewPortWidget.setVisible(AVisible);
end;

{------------------------------------------------------------------------------
  Function: TQtCustomControl.viewport
  Params:  None
  Returns: viewport widget of QAbstractScrollArea
 ------------------------------------------------------------------------------}
function TQtCustomControl.viewport: TQtViewport;
begin
  viewportNeeded;
  Result := FViewPortWidget;
end;

procedure TQtCustomControl.preferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  if LCLObject is TCustomControl then
  begin
    PreferredWidth := 0;
    PreferredHeight := 0;
  end else
    inherited preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

{------------------------------------------------------------------------------
  Function: TQtCustomControl.viewportNeeded
  Params:  None
  Returns: Nothing
           Creates viewport widget for QAbstractScrollArea
 ------------------------------------------------------------------------------}
procedure TQtCustomControl.viewportNeeded;
var
  AParams: TCreateParams;
begin
  if FViewPortWidget <> niL then
    exit;
  FillChar(AParams, SizeOf(AParams), #0);
  FViewPortWidget := TQtViewPort.Create(LCLObject, AParams);
  FViewPortWidget.setFocusProxy(Widget);
  FViewPortWidget.setBackgroundRole(QPaletteNoRole);
  FViewPortWidget.setAutoFillBackground(False);
  FViewPortWidget.FOwner := Self;
  FViewPortWidget.FChildOfComplexWidget := FChildOfComplexWidget;

  // some events will be redirected to scroll area
  FViewPortWidget.AttachEvents;

  QLCLAbstractScrollArea_override_viewportEvent(QLCLAbstractScrollAreaH(Widget),
    @ViewPortEventFilter);

  setViewport(FViewPortWidget.Widget);
end;

procedure TQtCustomControl.viewportDelete;
begin
  if Assigned(FViewPortWidget) then
  begin
    QLCLAbstractScrollArea_override_viewportEvent(QLCLAbstractScrollAreaH(Widget),
      QLCLAbstractScrollArea_viewportEvent_Override(NilMethod));
    FreeAndNil(FViewPortWidget);
  end;
end;

  { TQtCalendar }

function TQtCalendar.GetDateTime: TDateTime;
var
  Date: QDateH;
begin
  Date := QDate_create();
  QCalendarWidget_selectedDate(QCalendarWidgetH(Widget), Date);
  AYear := QDate_year(Date);
  AMonth := QDate_month(Date);
  ADay := QDate_day(Date);
  QDate_destroy(Date);
  Result := EncodeDate(AYear, AMonth, ADay);
end;

procedure TQtCalendar.SetDateTime(const AValue: TDateTime);
var
  Date: QDateH;
begin
  DecodeDate(AValue, AYear, AMonth, ADay);
  Date := QDate_create(AYear, AMonth, ADay);
  QCalendarWidget_setCurrentPage(QCalendarWidgetH(Widget),
    AYear, AMonth);
  SetSelectedDate(Date);
  QDate_destroy(Date);
end;

procedure TQtCalendar.SetSelectedDate(const AValue: QDateH);
begin
  QCalendarWidget_setSelectedDate(QCalendarWidgetH(Widget), AValue);
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.CreateWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtCalendar.CreateWidget(const AParams: TCreateParams):QWidgetH;
var
  Parent: QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtCalendar.Create');
  {$endif}
  FMouseDoubleClicked := False;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QCalendarWidget_create(Parent);
end;

procedure TQtCalendar.AttachEvents;
var
  i: integer;
  Children: TPtrIntArray;
  AnObject: QObjectH;
begin
  inherited AttachEvents;
  
  FClickedHook := QCalendarWidget_hook_create(Widget);
  FActivatedHook := QCalendarWidget_hook_create(Widget);
  FSelectionChangedHook := QCalendarWidget_hook_create(Widget);
  FCurrentPageChangedHook := QCalendarWidget_hook_create(Widget);
  
  QCalendarWidget_hook_hook_clicked(FClickedHook, @SignalClicked);

  QCalendarWidget_hook_hook_activated(FActivatedHook, @SignalActivated);

  QCalendarWidget_hook_hook_selectionChanged(FSelectionChangedHook, @SignalSelectionChanged);

  QCalendarWidget_hook_hook_currentPageChanged(FCurrentPageChangedHook, @SignalCurrentPageChanged);

  QObject_children(Widget, @Children);
  for i := 0 to High(Children) do
  begin
    AnObject := QObjectH(Children[i]);
    if QObject_isWidgetType(AnObject) then
    begin
      {do not localize !!}
      if QObject_inherits(AnObject,'QAbstractScrollArea') then
      begin
        FCalViewportEventHook := QObject_hook_create(QAbstractScrollArea_viewport(QAbstractScrollAreaH(AnObject)));
        QObject_hook_hook_events(FCalViewportEventHook, @calViewportEventFilter);
      end;
    end;
  end;

end;

procedure TQtCalendar.DetachEvents;
begin
  QObject_hook_destroy(FCalViewportEventHook);
  QCalendarWidget_hook_destroy(FClickedHook);
  QCalendarWidget_hook_destroy(FActivatedHook);
  QCalendarWidget_hook_destroy(FSelectionChangedHook);
  QCalendarWidget_hook_destroy(FCurrentPageChangedHook);
  inherited DetachEvents;
end;

function TQtCalendar.calViewportEventFilter(Sender: QObjectH; Event: QEventH
  ): Boolean; cdecl;
begin
  {we install only mouse dblclick event on QCalendar viewport,
   since inside signalActivated we don't know is it signalled from
   dblclick or by pressing return key.}
  Result := False;
  QEvent_accept(Event);
  if (LCLObject <> nil) then
  begin
    case QEvent_type(Event) of
      QEventMouseButtonDblClick: FMouseDoubleClicked := True;
    end;
  end;
end;

function TQtCalendar.HitTest(const APoint: TPoint): byte;
var
  Layout: QLayoutH;
  CalendarBody: QWidgetH;
  HeaderRect, BodyRect: TRect;
  AQtPoint: TQtPoint;
  Index: QModelIndexH;
begin
  Result := 0;
  Layout := QWidget_layout(Widget);
  // layout must have 2 items:
  // 1 - navigation bar
  // 2 - calendar model
  if QLayout_count(Layout) <> 2 then
    Exit;
  QLayoutItem_geometry(QLayout_itemAt(Layout, 0), @HeaderRect);
  QLayoutItem_geometry(QLayout_itemAt(Layout, 1), @BodyRect);
  if PtInRect(HeaderRect, APoint) then
  begin
    // we are in the header
    Result := 3;
    // todo: detail result more - button / month / year
  end
  else
  if PtInRect(BodyRect, APoint) then
  begin
    CalendarBody := QLayoutItem_widget(QLayout_itemAt(Layout, 1));
    AQtPoint := QtPoint(APoint.X, APoint.Y);
    QWidget_mapFrom(CalendarBody, @AQtPoint, Widget, @AQtPoint);
    Index := QModelIndex_create();
    try
      QTableView_indexAt(QTableWidgetH(CalendarBody), Index, @AQtPoint);
      if (QCalendarWidget_horizontalHeaderFormat(QCalendarWidgetH(Widget)) = QCalendarWidgetNoHorizontalHeader) or
         (QModelIndex_row(Index) > 0) then
      begin
        if (QCalendarWidget_verticalHeaderFormat(QCalendarWidgetH(Widget)) = QCalendarWidgetNoVerticalHeader) or
           (QModelIndex_column(Index) > 0) then
          Result := 1
        else
          Result := 2;
      end;
    finally
      QModelIndex_destroy(Index);
    end;
  end;
end;

procedure TQtCalendar.SetDisplaySettings(
      const AHHdrFmt: QCalendarWidgetHorizontalHeaderFormat;
      const AVHdrFmt: QCalendarWidgetVerticalHeaderFormat;
      const ASelMode: QCalendarWidgetSelectionMode;
      const ANavBarVisible: Boolean; const AGridVisible: Boolean;
      const AStartMonday: Boolean);
begin
  QCalendarWidget_setHorizontalHeaderFormat(QCalendarWidgetH(Widget), AHHdrFmt);
  QCalendarWidget_setNavigationBarVisible(QCalendarWidgetH(Widget), ANavBarVisible);
  QCalendarWidget_setVerticalHeaderFormat(QCalendarWidgetH(Widget), AVHdrFmt);
  QCalendarWidget_setGridVisible(QCalendarWidgetH(Widget), AGridVisible);
  if AStartMonday then
    QCalendarWidget_setFirstDayOfWeek(QCalendarWidgetH(Widget), QtMonday)
  else
    QCalendarWidget_setFirstDayOfWeek(QCalendarWidgetH(Widget), QtSunday);
  QCalendarWidget_setSelectionMode(QCalendarWidgetH(Widget), ASelMode);
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalActivated
  Params:  None
  Returns: Nothing
           Sends signal when RETURN pressed on selected date.
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalActivated(ADate: QDateH); cdecl;
var
  y,m,d: Integer;
  Msg: TLMMouse;
  AKeyEvent: QKeyEventH;
  AMouseEvent: QMouseEventH;
  APos: TQtPoint;
  AGlobalPos: TQtPoint;
begin
  {$IFDEF VerboseQt}
  writeln('TQtCalendar.signalActivated ');
  {$ENDIF}

  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_DAYCHANGED;
  y := QDate_year(ADate);
  m := QDate_month(ADate);
  d := QDate_day(ADate);
  if (y <> aYear) or (m <> aMonth) or (d <> aDay) then
    DeliverMessage(Msg);
  aYear := y;
  aMonth := m;
  aDay := d;

  {avoid OnAcceptDate() to trigger twice if doubleclicked
   via FMouseDoubleClicked, also send dummy Key events to LCL when item
   activated (only QtKey_Return activates)}
  if not FMouseDoubleClicked then
  begin
    AKeyEvent := QKeyEvent_create(QEventKeyPress, QtKey_Return, QtNoModifier);
    SlotKey(Widget, AKeyEvent);
    QEvent_destroy(AKeyEvent);
    AKeyEvent := QKeyEvent_create(QEventKeyRelease, QtKey_Return, QtNoModifier);
    SlotKey(Widget, AKeyEvent);
    QEvent_destroy(AKeyEvent);
  end else
  begin
    FMouseDoubleClicked := False;
    if QWidget_underMouse(Widget) then
    begin
      QCursor_pos(@AGlobalPos);
      QWidget_mapFromGlobal(Widget, @APos, @AGlobalPos);
      AMouseEvent := QMouseEvent_create(QEventMouseButtonDblClick, @APos,
        @AGlobalPos, QtLeftButton, QtLeftButton,
        QApplication_keyboardModifiers());
      SlotMouse(Widget, AMouseEvent);
      QMouseEvent_destroy(AMouseEvent);
    end;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalClicked
  Params:  None
  Returns: Nothing
           Sends msg LM_DAYCHANGED when OldDate<>NewDate
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalClicked(ADate: QDateH); cdecl;
var
  Msg: TLMessage;
  y, m, d: Integer;
  AEvent: QMouseEventH;
  APos: TQtPoint;
  AGlobalPos: TQtPoint;
begin
  {$IFDEF VerboseQt}
  writeln('TQtCalendar.signalClicked');
  {$ENDIF}
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_DAYCHANGED;
  y := QDate_year(ADate);
  m := QDate_month(ADate);
  d := QDate_day(ADate);
  if (y <> aYear) or (m <> aMonth) or (d <> aDay) then
    DeliverMessage(Msg);

  aYear := y;
  aMonth := m;
  aDay := d;

  if QWidget_underMouse(Widget) then
  begin
    {we create dummy event for LCL, and call directly SlotMouse() - no need
    to send it via event loop}
    QCursor_pos(@AGlobalPos);
    QWidget_mapFromGlobal(Widget, @APos, @AGlobalPos);
    AEvent := QMouseEvent_create(QEventMouseButtonPress, @APos, @AGlobalPos,
      QtLeftButton, QtLeftButton, QApplication_keyboardModifiers());
    SlotMouse(Widget, AEvent);
    QMouseEvent_destroy(AEvent);
    AEvent := QMouseEvent_create(QEventMouseButtonRelease, @APos, @AGlobalPos,
      QtLeftButton, QtLeftButton, QApplication_keyboardModifiers());
    SlotMouse(Widget, AEvent);
    QMouseEvent_destroy(AEvent);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalSelectionChanged
  Params:  None
  Returns: Nothing

  Notes: no event for date changed by keyboard ?!?
   always triggers even if selection isn't changed ...
   this is not Qt4 bug ... tested with pure Qt C++ app
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalSelectionChanged; cdecl;
var
  Msg: TLMessage;
begin
  {$IFDEF VerboseQt}
  writeln('TQtCalendar.SignalSelectionChanged');
  {$ENDIF}
  if InUpdate then
    exit;
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_SELCHANGE;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalCurrentPageChanged
  Params:  None
  Returns: Nothing

  Notes: fixme what's wrong with those values ?!?
   with pure Qt C++ app this works ok, but via bindings get
   impossible year & month values ...
 ------------------------------------------------------------------------------}
procedure TQtCalendar.signalCurrentPageChanged(p1, p2: Integer); cdecl;
var
  Msg: TLMessage;
begin
  {$IFDEF VerboseQt}
  writeln('TQtCalendar.SignalCurrentPageChanged p1=',p1,' p2=',p2);
  {$ENDIF}
  if InUpdate then
    exit;
  FillChar(Msg, SizeOf(Msg), #0);
  if AYear <> p1 then
  begin
    Msg.Msg := LM_YEARCHANGED;
    DeliverMessage(Msg);
  end;

  if AMonth <> p2 then
  begin
    Msg.Msg := LM_MONTHCHANGED;
    DeliverMessage(Msg);
  end;
end;

{ TQtHintWindow }

function TQtHintWindow.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  FHasPaint := True;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QWidget_create(Parent, QtToolTip);
  FDeleteLater := True;
  MenuBar := nil;
end;

procedure TQtHintWindow.SetDefaultColorRoles;
begin
  WidgetColorRole := QPaletteToolTipBase;
  TextColorRole := QPaletteToolTipText;
end;

procedure TQtHintWindow.setVisible(AVisible: Boolean);
const
  ToolTipOffset = 4;
var
  D: TRect;
  R: TRect;
  P: TPoint;
  Pt: TQtPoint;
  ScreenNumber: integer;
  W,H: integer;
begin
  // must use ClassType comparision here since qt is buggy about hints.#16551
  if AVisible and (LCLObject.ClassType = THintWindow) then
  begin
    R := getGeometry;
    W := R.Right - R.Left;
    H := R.Bottom - R.Top;
    LCLIntf.GetCursorPos(P);

    {we must make proper positioning of our hint if
     hint geometry intersects current cursor pos - issue #15882}
    if PtInRect(R, P) then
    begin
      if QDesktopWidget_isVirtualDesktop(QApplication_desktop()) then
        ScreenNumber := QDesktopWidget_screenNumber(QApplication_desktop(), @P)
      else
        ScreenNumber := QDesktopWidget_screenNumber(QApplication_desktop(), Widget);

      {$IFDEF DARWIN}
      QDesktopWidget_availableGeometry(QApplication_desktop() ,@D, ScreenNumber);
      {$ELSE}
      QDesktopWidget_screenGeometry(QApplication_desktop() ,@D, ScreenNumber);
      {$ENDIF}


      if (P.X + W > D.Right - D.Left) then
        P.X := P.X - ((ToolTipOffset) + W);

      if (P.Y + H > D.Bottom - D.Top) then
        P.Y := P.Y - ((ToolTipOffset * 6) + H);

      if P.Y < D.Top then
        P.Y := D.Top;

      if (P.X + W > D.Right - D.Left) then
        P.X := D.Right - D.Left - W;

      if P.X < D.Left then
        P.X := D.Left;

      if P.Y + H > D.Bottom - D.Top then
        P.Y := D.Bottom - D.Top - H;

      Pt := getPos;

      if (P.X >= Pt.X) and (P.X <= Pt.X + W) then
        move(P.X + ToolTipOffset, P.Y)
      else
        move(P.X , P.Y);
    end;
  end;
  inherited setVisible(AVisible);
end;

{ TQtPage }

function TQtPage.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  FHasPaint := True;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QWidget_create(Parent);
  if (QtVersionMajor = 4) and (QtVersionMinor < 6) then
    QWidget_setAutoFillBackground(Result, True);
end;

function TQtPage.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  if (QEvent_type(Event) = QEventResize) and
    LCLObject.Parent.ClientRectNeedsInterfaceUpdate  then
      LCLObject.Parent.InvalidateClientRectCache(False);
  Result:=inherited EventFilter(Sender, Event);
end;

function TQtPage.getIcon: QIconH;
begin
  Result := FIcon;
end;

function TQtPage.getIndex: Integer;
var
  AParent: QTabWidgetH;

  function CanReturnIndex: Boolean;
  begin
    Result := AParent <> nil;
    if Result then
      Result := QWidget_isVisible(AParent) or
        ( (QtVersionMajor >= 4) and (QtVersionMinor >= 6)
         and LCLObject.HandleObjectShouldBeVisible );
  end;

begin
  AParent := getTabWidget;
  if CanReturnIndex then
    Result := QTabWidget_indexOf(AParent, Widget)
  else
    Result := -1;
end;

function TQtPage.getTabWidget: QTabWidgetH;
var
  AParent: QWidgetH;
begin
  // it is placed to the stack widget and stack widget into tab widget
  AParent := QWidget_parentWidget(Widget);
  if AParent <> nil then
    Result := QTabWidgetH(QWidget_parentWidget(AParent))
  else
    Result := nil;
end;

procedure TQtPage.setIcon(const AIcon: QIconH);
var
  AParent: QTabWidgetH;
  TabWidget: TQtTabWidget;
begin
  FIcon := AIcon;
  AParent := getTabWidget;
  if AParent <> nil then
  begin
    if ChildOfComplexWidget = ccwTabWidget then
    begin
      TabWidget := TQtTabWidget(LCLObject.Parent.Handle);
      TabWidget.setTabIcon(TabWidget.indexOf(Widget), AIcon);
    end else
      QTabWidget_setTabIcon(AParent, getIndex, AIcon);
  end;
end;

procedure TQtPage.setText(const W: WideString);
var
  AParent: QTabWidgetH;
  Index: integer;
begin
  inherited setText(W);
  AParent := getTabWidget;
  if (AParent <> nil) then
  begin
    Index := getIndex;
    if Index <> -1 then
      QTabWidget_setTabText(AParent, Index, @W);
  end;
end;

{ TQtAbstractItemView }

function TQtAbstractItemView.GetOwnerDrawn: Boolean;
begin
  Result := FNewDelegate <> nil;
end;

function TQtAbstractItemView.getIconSize: TSize;
begin
  QAbstractItemView_iconSize(QAbstractItemViewH(Widget), @Result);
end;

procedure TQtAbstractItemView.setIconSize(const AValue: TSize);
begin
  QAbstractItemView_setIconSize(QAbstractItemViewH(Widget), @AValue);
end;

procedure TQtAbstractItemView.SetOwnerDrawn(const AValue: Boolean);
begin
  if AValue and (FNewDelegate = nil) then
  begin
    FNewDelegate := QLCLItemDelegate_create(Widget);

    QLCLItemDelegate_override_sizeHint(FNewDelegate, @ItemDelegateSizeHint);

    QLCLItemDelegate_override_Paint(FNewDelegate, @ItemDelegatePaint);

    FOldDelegate := QAbstractItemView_itemDelegate(QAbstractItemViewH(Widget));
    QAbstractItemView_setItemDelegate(QAbstractItemViewH(Widget), FNewDelegate);
  end
  else
  if ((not AValue) and (FNewDelegate <> nil)) then
  begin
    {$note TQtAbstractItemView.SetOwnerDrawn: this call avoid sporadic AVs with QLCLItemDelegate_destroy(FNewDelegate).}
    {howto reproduce: comment next code line, recompile laz, and then in oi click
     in first field eg. Action (TForm), now push kbd down arrow let it pass all properties,
     you'll have crash at Constraints property.}
    FNewDelegate := QLCLItemDelegateH(QAbstractItemView_itemDelegate(QAbstractItemViewH(Widget)));
    QAbstractItemView_setItemDelegate(QAbstractItemViewH(Widget), FOldDelegate);
    QLCLItemDelegate_destroy(FNewDelegate);
    FNewDelegate := nil;
  end;
end;

procedure TQtAbstractItemView.OwnerDataNeeded(ARect: TRect);
begin
  // override
end;

procedure TQtAbstractItemView.PostponedMouseRelease(AEvent: QEventH);
 // postpone mouse release for LCL
var
  ev: QMouseEventH;
begin
  if QEvent_type(AEvent) = QEventMouseButtonRelease then
  begin
    ev := QMouseEventH(AEvent);
    FSavedEvent := QMouseEvent_create(QEventMouseButtonRelease,
      QMouseEvent_pos(ev), QMouseEvent_globalPos(ev),
      QMouseEvent_button(ev), QMouseEvent_buttons(ev),
      QInputEvent_modifiers(QInputEventH(AEvent)));
    FSavedEventTimer := QTimer_create(Widget);
    FSavedEventTimerHook := QTimer_hook_create(FSavedEventTimer);
    QTimer_hook_hook_timeout(FSavedEventTimerHook,
      @PostponedMouseReleaseTimerEvent);
    QTimer_setInterval(FSavedEventTimer, 5);
    QTimer_setSingleShot(FSavedEventTimer, True);
    QTimer_start(FSavedEventTimer);
  end;
end;

procedure TQtAbstractItemView.PostponedMouseReleaseTimerEvent(); cdecl;
begin
  if FSavedEvent <> nil then
  begin
    SlotMouse(Widget, FSavedEvent);
    QMouseEvent_destroy(FSavedEvent);
    FSavedEvent := nil;
    QTimer_hook_destroy(FSavedEventTimerHook);
    QTimer_destroy(FSavedEventTimer);
    FSavedEventTimer := nil;
    FSavedEventTimerHook := nil;
  end;
end;

constructor TQtAbstractItemView.Create(const AWinControl: TWinControl;
  const AParams: TCreateParams);
begin
  inherited Create(AWinControl, AParams);
  FOldDelegate := nil;
  FNewDelegate := nil;
end;

procedure TQtAbstractItemView.signalActivated(index: QModelIndexH); cdecl;
var
  Msg: TLMessage;
begin
  // writeln('SIGNAL: TQtAbstractItemView.signalActivated');
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_ACTIVATE;
  DeliverMessage( Msg );
end;

procedure TQtAbstractItemView.signalClicked(index: QModelIndexH); cdecl;
begin
  {use to be overriden by descedants, don''t implement it here,
   or U get in trouble with TQtListView && TQtListWidget items.}
end;

procedure TQtAbstractItemView.signalDoubleClicked(index: QModelIndexH); cdecl;
begin
  {use to be overriden by descedants, don''t implement it here,
   or U get in trouble with TQtListView && TQtListWidget items.}
end;

procedure TQtAbstractItemView.signalEntered(index: QModelIndexH); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_ENTER;
  DeliverMessage( Msg );
end;

procedure TQtAbstractItemView.signalPressed(index: QModelIndexH); cdecl;
begin
  {should be overriden by descedants}
end;

procedure TQtAbstractItemView.SignalViewportEntered; cdecl;
begin
  {should be overriden by descedants}
end;

procedure TQtAbstractItemView.AttachEvents;
begin
  inherited AttachEvents;
  FSignalActivated := QAbstractItemView_hook_create(Widget);
  FSignalClicked := QAbstractItemView_hook_create(Widget);
  FSignalDoubleClicked := QAbstractItemView_hook_create(Widget);
  FSignalEntered := QAbstractItemView_hook_create(Widget);
  FSignalPressed := QAbstractItemView_hook_create(Widget);
  FSignalViewportEntered := QAbstractItemView_hook_create(Widget);
  
  QAbstractItemView_hook_hook_activated(FSignalActivated, @SignalActivated);

  QAbstractItemView_hook_hook_clicked(FSignalClicked, @SignalClicked);
  
  QAbstractItemView_hook_hook_doubleClicked(FSignalDoubleClicked, @SignalDoubleClicked);
  
  QAbstractItemView_hook_hook_entered(FSignalEntered, @SignalEntered);

  QAbstractItemView_hook_hook_pressed(FSignalPressed, @SignalPressed);

  QAbstractItemView_hook_hook_viewportEntered(FSignalViewportEntered, @SignalViewportEntered);

  FAbstractItemViewportEventHook := QObject_hook_create(viewportWidget);
  QObject_hook_hook_events(FAbstractItemViewportEventHook, @itemViewViewportEventFilter);
end;

procedure TQtAbstractItemView.DetachEvents;
begin
  QAbstractItemView_hook_destroy(FSignalActivated);
  QAbstractItemView_hook_destroy(FSignalClicked);
  QAbstractItemView_hook_destroy(FSignalDoubleClicked);
  QAbstractItemView_hook_destroy(FSignalEntered);
  QAbstractItemView_hook_destroy(FSignalPressed);
  QAbstractItemView_hook_destroy(FSignalViewportEntered);
  QObject_hook_destroy(FAbstractItemViewportEventHook);
  inherited DetachEvents;
end;

function TQtAbstractItemView.itemViewViewportEventFilter(Sender: QObjectH;
  Event: QEventH): Boolean; cdecl;
var
  R: TRect;
begin
  {we install only mouse events on QAbstractItemView viewport}
  Result := False;
  QEvent_accept(Event);
  if (LCLObject <> nil) then
  begin
    BeginEventProcessing;

    {ownerdata is needed only before qt paint's data}
    if (ViewStyle >= 0) and FOwnerData and
      (QEvent_type(Event) = QEventPaint) then
    begin
      QPaintEvent_rect(QPaintEventH(Event), @R);
      OwnerDataNeeded(R);
    end;

    case QEvent_type(Event) of
      QEventMouseButtonPress,
      QEventMouseButtonRelease,
      QEventMouseButtonDblClick: Result := SlotMouse(Sender, Event);
      QEventContextMenu: Result := SlotContextMenu(Sender, Event);
      else
      begin
        if not (ViewStyle in [Ord(vsIcon), Ord(vsSmallIcon)]) then
        begin
          {do not change selection if mousepressed and mouse moved}
          Result := (QEvent_type(Event) = QEventMouseMove) and
            hasFocus and (QApplication_mouseButtons() > 0);
          QEvent_ignore(Event);
        end;
      end;
    end;
    EndEventProcessing;
  end;
end;

procedure TQtAbstractItemView.setDefaultColorRoles;
begin
  WidgetColorRole := QPaletteBase;
  TextColorRole := QPaletteText;
end;

procedure TQtAbstractItemView.clearSelection;
begin
  QAbstractItemView_clearSelection(QAbstractItemViewH(Widget));
end;

function TQtAbstractItemView.getModel: QAbstractItemModelH;
begin
  Result := QAbstractItemView_model(QAbstractItemViewH(Widget));
end;

function TQtAbstractItemView.getRowHeight(ARowIndex: integer): integer;
begin
  Result := QAbstractItemView_sizeHintForRow(QAbstractItemViewH(Widget),
    ARowIndex);
end;

function TQtAbstractItemView.getSelectionMode: QAbstractItemViewSelectionMode;
begin
  Result := QAbstractItemView_SelectionMode(QAbstractItemViewH(Widget));
end;

function TQtAbstractItemView.getTopItem: integer;
begin
  Result := -1;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractItemView.getVisibleRowCount
  Params:  Boolean
  Returns: if AFirstVisibleOnly = False (default) then it returns number
  of visible rows, or 0 if there's no visible rows.
  When AFirstVisibleOnly = True then it returns index of first visible row,
  otherwise result is -1.
  This function is used by TQtTreeWidget and TQtListWidget.
 ------------------------------------------------------------------------------}
function TQtAbstractItemView.getVisibleRowCount(const AFirstVisibleOnly: boolean = false): integer;
begin
  Result := 0;
end;

procedure TQtAbstractItemView.modelIndex(retval: QModelIndexH; row, column: Integer; parent: QModelIndexH = nil);
begin
  QAbstractItemModel_index(getModel, retval, row, column, parent);
end;

function TQtAbstractItemView.visualRect(Index: QModelIndexH): TRect;
begin
  QAbstractItemView_visualRect(QAbstractItemViewH(Widget), @Result, Index);
end;

procedure TQtAbstractItemView.setEditTriggers(
  ATriggers: QAbstractItemViewEditTriggers);
begin
  QAbstractItemView_setEditTriggers(QAbstractItemViewH(Widget), ATriggers);
end;

procedure TQtAbstractItemView.setSelectionMode(
  AMode: QAbstractItemViewSelectionMode);
begin
  QAbstractItemView_setSelectionMode(QAbstractItemViewH(Widget), AMode);
end;

procedure TQtAbstractItemView.setSelectionBehavior(
  ABehavior: QAbstractItemViewSelectionBehavior);
begin
  QAbstractItemView_setSelectionBehavior(QAbstractItemViewH(Widget), ABehavior);
end;

procedure TQtAbstractItemView.setWordWrap(const AValue: Boolean);
begin
  // override
end;

procedure TQtAbstractItemView.ItemDelegateSizeHint(
  option: QStyleOptionViewItemH; index: QModelIndexH; Size: PSize); cdecl;
var
  Msg: TLMMeasureItem;
  MeasureItemStruct: TMeasureItemStruct;
begin
  MeasureItemStruct.itemID := UINT(QModelIndex_row(index));
  MeasureItemStruct.itemWidth := UINT(Size^.cx);
  MeasureItemStruct.itemHeight := UINT(Size^.cy);
  Msg.Msg := LM_MEASUREITEM;
  Msg.MeasureItemStruct := @MeasureItemStruct;
  DeliverMessage(Msg);
  Size^.cx := Longint(MeasureItemStruct.itemWidth);
  Size^.cy := Longint(MeasureItemStruct.itemHeight);
end;

procedure TQtAbstractItemView.ItemDelegatePaint(painter: QPainterH;
  option: QStyleOptionViewItemH; index: QModelIndexH); cdecl;
begin
  // should be overrided
end;

{ TQtRubberBand }

function TQtRubberBand.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QRubberBand_create(FShape, Parent);
end;

constructor TQtRubberBand.Create(const AWinControl: TWinControl;
  const AParams: TCreateParams);
begin
  FShape := QRubberBandLine;
  inherited Create(AWinControl, AParams);
end;

procedure TQtRubberBand.move(ANewLeft, ANewTop: Integer);
begin
  QRubberBand_move(QRubberBandH(Widget), ANewLeft, ANewTop);
end;

procedure TQtRubberBand.resize(ANewWidth, ANewHeight: Integer);
begin
  QRubberBand_resize(QRubberBandH(Widget), ANewWidth, ANewHeight);
end;

procedure TQtRubberBand.setGeometry(ARect: TRect);
begin
  QRubberBand_setGeometry(QRubberBandH(Widget), @ARect);
end;

function TQtRubberBand.getShape: QRubberBandShape;
begin
  Result := QRubberBand_shape(QRubberBandH(Widget));
end;

procedure TQtRubberBand.setShape(AShape: QRubberBandShape);
begin
  if getShape <> AShape then
  begin
    // recreate widget
    FShape := AShape;
    RecreateWidget;
    AttachEvents;
  end;
end;

{ TQtFileDialog }

function TQtFileDialog.CreateWidget(parent: QWidgetH; f: QtWindowFlags): QWidgetH;
begin
  Result := QFileDialog_create(parent, f);
  {$ifndef QT_NATIVE_DIALOGS}
  FBackBtn := nil;
  FForwardBtn := nil;
  FUpBtn := nil;
  FFileNameEdit := nil;
  FComboType := nil;
  FComboHistory := nil;
  FSideView := nil;;
  FTreeView := nil;
  FListView := nil;

  FTreeViewEventFilter := nil; // detailed view
  FListViewEventFilter := nil; // small icons
  FSideViewEventFilter := nil; // sidebar
  FFileNameEditEventFilter := nil; // filename editor
  FComboTypeEventFilter := nil;
  FComboHistoryEventFilter := nil;
  {$endif}
end;

procedure TQtFileDialog.AttachEvents;
begin
  inherited AttachEvents;

  FCurrentChangedHook := QFileDialog_hook_create(Widget);
  FDirecotyEnteredHook := QFileDialog_hook_create(Widget);
  FFilterSelectedHook := QFileDialog_hook_create(Widget);

  QFileDialog_hook_hook_filterSelected(FFilterSelectedHook, @FilterSelectedEvent);

  QFileDialog_hook_hook_currentChanged(FCurrentChangedHook, @CurrentChangedEvent);

  QFileDialog_hook_hook_directoryEntered(FDirecotyEnteredHook, @DirectoryEnteredEvent);
end;

procedure TQtFileDialog.DetachEvents;
begin
  QFileDialog_hook_destroy(FCurrentChangedHook);
  QFileDialog_hook_destroy(FFilterSelectedHook);
  QFileDialog_hook_destroy(FDirecotyEnteredHook);
  {$ifndef QT_NATIVE_DIALOGS}
  if FTreeViewEventFilter <> nil then
  begin
    QObject_hook_destroy(FTreeViewEventFilter);
    FTreeViewEventFilter := nil;
  end;
  if FListViewEventFilter <> nil then
  begin
    QObject_hook_destroy(FListViewEventFilter);
    FListViewEventFilter := nil;
  end;
  if FSideViewEventFilter <> nil then
  begin
    QObject_hook_destroy(FSideViewEventFilter);
    FSideViewEventFilter := nil;
  end;
  if FFileNameEditEventFilter <> nil then
  begin
    QObject_hook_destroy(FFileNameEditEventFilter);
    FFileNameEditEventFilter := nil;
  end;
  if FComboTypeEventFilter <> nil then
  begin
    QObject_hook_destroy(FComboTypeEventFilter);
    FComboTypeEventFilter := nil;
  end;
  if FComboHistoryEventFilter <> nil then
  begin
    QObject_hook_destroy(FComboHistoryEventFilter);
    FComboHistoryEventFilter := nil;
  end;
  {$endif}
  inherited DetachEvents;
end;

{$ifndef QT_NATIVE_DIALOGS}
function TQtFileDialog.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  Result := False;
  if Sender <> Widget then
  begin
    // TODO: Ctrl + Letter for Open/Save button trigger
    // ALT + Left, Up, Right to navigate (Backward, Up parent, Forward) in list.
    // ALT + E to focus fileedit
    // ALT + H to focus lookInCombo (history combo)
    // ALT + L to focus view
    // ALT + N to create new folder (TODO)
    // ALT + S to select sidebar
    // ALT + T to focus file type combo
    // ALT + V to change view style (TODO)
    case QEvent_type(Event) of
      QEventKeyPress:
        begin
          if (QKeyEvent_modifiers(QKeyEventH(Event)) and QtAltModifier <> 0) then
          begin
            case QKeyEvent_key(QKeyEventH(Event)) of
              QtKey_Left:
                begin
                  if Assigned(FBackBtn) and QWidget_isVisible(FBackBtn) and
                    QWidget_isEnabled(FBackBtn) then
                    QAbstractButton_click(QAbstractButtonH(FBackBtn));
                  Result := True;
                end;
              QtKey_Right:
                begin
                  if Assigned(FForwardBtn) and QWidget_isVisible(FForwardBtn) and
                    QWidget_isEnabled(FForwardBtn) then
                    QAbstractButton_click(QAbstractButtonH(FForwardBtn));
                  Result := True;
                end;
              QtKey_Up:
                begin
                  if Assigned(FUpBtn) and QWidget_isVisible(FUpBtn) and
                    QWidget_isEnabled(FUpBtn) then
                    QAbstractButton_click(QAbstractButtonH(FUpBtn));
                  Result := True;
                end;
              QtKey_E:
                begin
                  if Assigned(FFileNameEdit) and
                    QWidget_isVisible(FFileNameEdit) and
                    QWidget_isEnabled(FFileNameEdit) and
                    not QWidget_hasFocus(FFileNameEdit) then
                    QWidget_setFocus(FFileNameEdit);
                  Result := True;
                end;
              QtKey_H:
                begin
                  if Assigned(FComboHistory) and
                    QWidget_isVisible(FComboHistory) and
                    QWidget_isEnabled(FComboHistory) and
                    not QWidget_hasFocus(FComboHistory) then
                      QWidget_setFocus(FComboHistory);
                  Result := True;
                end;
              QtKey_L:
                begin
                  if Assigned(FTreeView) and
                    QWidget_isVisible(FTreeView) and
                    QWidget_isEnabled(FTreeView) and
                    not QWidget_hasFocus(FTreeView) then
                    QWidget_setFocus(FTreeView)
                  else
                  if Assigned(FListView) and
                    QWidget_isVisible(FListView) and
                    QWidget_isEnabled(FListView) and
                    not QWidget_hasFocus(FListView) then
                    QWidget_setFocus(FListView);
                  Result := True;
                end;
              QtKey_N:
                begin
                  //TODO: create newfolder
                  Result := True;
                end;
              QtKey_S:
                begin
                  // select sidebar
                  if Assigned(FSideView) and
                    QWidget_isVisible(FSideView) and
                    QWidget_isEnabled(FSideView) and
                    not QWidget_hasFocus(FSideView) then
                    QWidget_setFocus(FSideView);
                  Result := True;
                end;
              QtKey_T:
                begin
                  // focus combo filetype
                  if Assigned(FComboType) and
                    QWidget_isVisible(FComboType) and
                    QWidget_isEnabled(FComboType) and
                    not QWidget_hasFocus(FComboType) then
                      QWidget_setFocus(FComboType);
                  Result := True;
                end;
              QtKey_V:
                begin
                  //TODO: change viewStyle
                  Result := True;
                end;
            end;
          end;
        end;
    end;
  end else
    Result := inherited EventFilter(Sender, Event);
end;
{$endif}

function TQtFileDialog.selectFile: WideString;
begin
  QFileDialog_selectFile(QFileDialogH(Widget), @Result);
end;

procedure TQtFileDialog.selectedFiles(retval: QStringListH);
begin
  QFileDialog_selectedFiles(QFileDialogH(Widget), retval);
end;

procedure TQtFileDialog.setAcceptMode(const AMode: QFileDialogAcceptMode);
begin
  QFileDialog_setAcceptMode(QFileDialogH(Widget), AMode)
end;

procedure TQtFileDialog.setConfirmOverwrite(const AValue: Boolean);
begin
  QFileDialog_setConfirmOverwrite(QFileDialogH(Widget), AValue);
end;

procedure TQtFileDialog.setDirectory(const ADirectory: WideString);
begin
  QFileDialog_setDirectory(QFileDialogH(Widget), @ADirectory);
end;

procedure TQtFileDialog.setHistory(AList: TStrings);
var
  List: QStringListH;
  i: Integer;
  WStr: WideString;
begin
  List := QStringList_create();
  try
    for i := 0 to AList.Count - 1 do
    begin
      WStr := GetUTF8String(AList.Strings[i]);
      QStringList_append(List, @WStr);
    end;
    QFileDialog_setHistory(QFileDialogH(Widget), List);
  finally
    QStringList_destroy(List);
  end;
end;

procedure TQtFileDialog.setFileMode(const AMode: QFileDialogFileMode);
begin
  QFileDialog_setFileMode(QFileDialogH(Widget), AMode);
end;

procedure TQtFileDialog.setFilter(const AFilter: WideString);
begin
  QFileDialog_setNameFilter(QFileDialogH(Widget), @AFilter);
end;

procedure TQtFileDialog.setLabelText(const ALabel: QFileDialogDialogLabel;
  const AText: WideString);
begin
  QFileDialog_setLabelText(QFileDialogH(Widget), ALabel, @AText);
end;

procedure TQtFileDialog.setReadOnly(const AReadOnly: Boolean);
begin
  QFileDialog_setReadOnly(QFileDialogH(Widget), AReadOnly);
end;

procedure TQtFileDialog.setSelectedFilter(const ASelFilter: WideString);
begin
  QFileDialog_selectNameFilter(QFileDialogH(Widget), @ASelFilter);
end;

procedure TQtFileDialog.setViewMode(const AMode: QFileDialogViewMode);
begin
  QFileDialog_setViewMode(QFileDialogH(Widget), AMode);
end;

{------------------------------------------------------------------------------
  Function: TQtFileDialog.setShortcuts
  Params:  None
  Returns: Nothing
  Qt non-native dialogs doesn't set keyboard shortcuts, so we must do that.
  This functions hooks eventFilter of all widgets on QFileDialog.
 ------------------------------------------------------------------------------}
{$ifndef QT_NATIVE_DIALOGS}
procedure TQtFileDialog.setShortcuts(const AIsOpenDialog: Boolean);
var
  AnIter: TQtObjectDump;
  i: Integer;
  Obj: QObjectH;
  WStr: WideString;
  ToolTip: WideString;
begin
  // if there's auto recognition enabled then don''t set shortcuts
  // cause we are maybe native dialog and then boomer.
  if not QFileDialog_testOption(QFileDialogH(Widget),
    QFileDialogDontUseNativeDialog) then
    exit;
  FForwardBtn := nil;
  FBackBtn := nil;
  FUpBtn := nil;

  AnIter := TQtObjectDump.Create(Widget);
  try
    AnIter.DumpObject;

    for i := 0 to AnIter.ObjList.Count - 1 do
    begin
      Obj := QObjectH(AnIter.Objlist.Items[i]);
      if AnIter.IsWidget(Obj) then
      begin
        WStr := AnIter.GetObjectName(Obj);
        if (WStr = 'treeView') or (WStr = 'listView') or (WStr = 'sidebar') then
        begin
          if FForwardBtn = nil then
          begin
            FForwardBtn := AnIter.FindWidgetByName('forwardButton');
            if FForwardBtn <> nil then
            begin
              ToolTip := 'Forward (Alt + Right)';
              QWidget_setToolTip(FForwardBtn, @ToolTip);
            end;
          end;
          if FBackBtn = nil then
          begin
            FBackBtn := AnIter.FindWidgetByName('backButton');
            if FBackBtn <> nil then
            begin
              ToolTip := 'Back (Alt + Left)';
              QWidget_setToolTip(FBackBtn, @ToolTip);
            end;
          end;
          if FUpBtn = nil then
          begin
            FUpBtn := AnIter.FindWidgetByName('toParentButton');
            if FUpBtn <> nil then
            begin
              ToolTip := 'To parent directory (Alt + Up)';
              QWidget_setToolTip(FUpBtn, @ToolTip);
            end;
          end;

          if FForwardBtn <> nil then
          begin
            if WStr = 'treeView' then
            begin
              FTreeView := QWidgetH(Obj);
              FTreeViewEventFilter := QObject_hook_create(Obj);
              QObject_hook_hook_events(FTreeViewEventFilter, @EventFilter);
              ToolTip := 'Alt + L to focus this widget';
              QWidget_setToolTip(FTreeView, @ToolTip);
            end else
            if WStr = 'listView' then
            begin
              FListView := QWidgetH(Obj);
              FListViewEventFilter := QObject_hook_create(Obj);
              QObject_hook_hook_events(FListViewEventFilter, @EventFilter);
              ToolTip := 'Alt + L to focus this widget';
              QWidget_setToolTip(FListView, @ToolTip);
            end else
            if WStr = 'sidebar' then
            begin
              FSideView := QWidgetH(Obj);
              FSideViewEventFilter := QObject_hook_create(Obj);
              QObject_hook_hook_events(FSideViewEventFilter, @EventFilter);
              ToolTip := 'Alt + S to focus this widget';
              QWidget_setToolTip(FSideView, @ToolTip);
            end;

          end;
        end else
        if WStr = 'fileNameEdit' then
        begin
          FFileNameEdit := QWidgetH(Obj);
          FFileNameEditEventFilter := QObject_hook_create(Obj);
          QObject_hook_hook_events(FFileNameEditEventFilter, @EventFilter);
          ToolTip := 'Alt + E to focus this widget';
          QWidget_setToolTip(FFileNameEdit, @ToolTip);
        end else
        if WStr = 'fileTypeCombo' then
        begin
          FComboType := QWidgetH(Obj);
          FComboTypeEventFilter := QObject_hook_create(Obj);
          QObject_hook_hook_events(FComboTypeEventFilter, @EventFilter);
          ToolTip := 'Alt + T to focus this widget';
          QWidget_setToolTip(FComboType, @ToolTip);
        end else
        if WStr = 'lookInCombo' then
        begin
          FComboHistory := QWidgetH(Obj);
          FComboHistoryEventFilter := QObject_hook_create(Obj);
          QObject_hook_hook_events(FComboHistoryEventFilter, @EventFilter);
          ToolTip := 'Alt + H to focus this widget';
          QWidget_setToolTip(FComboHistory, @ToolTip);
        end;
      end;
    end;

  finally
    AnIter.Free;
  end;
end;
{$endif}

procedure TQtFileDialog.FilterSelectedEvent(filter: PWideString); cdecl;
var
  List: TQtStringList;
  index: Integer;
begin
  if filter <> nil then
  begin
    List := TQtStringList.Create;
    getFilters(List.Handle);
    index := List.IndexOf(UTF16ToUTF8(filter^));
    if index <> -1 then
      TFileDialog(FDialog).IntfFileTypeChanged(index + 1);
    List.Free;
  end;
end;

procedure TQtFileDialog.CurrentChangedEvent(path: PWideString); cdecl;
begin
  if FDialog is TOpenDialog then
  begin
    TOpenDialog(FDialog).FileName := UTF16ToUTF8(path^);
    TOpenDialog(FDialog).DoSelectionChange;
  end;
end;

procedure TQtFileDialog.DirectoryEnteredEvent(directory: PWideString); cdecl;
begin
  if FDialog is TOpenDialog then
    TOpenDialog(FDialog).DoFolderChange;
end;

procedure TQtFileDialog.getFilters(const retval: QStringListH);
begin
  QFileDialog_nameFilters(QFileDialogH(Widget), retval);
end;

{ TQtGraphicView }

function TQtGraphicsView.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Parent: QWidgetH;
begin
  FHasPaint := True;
  if AParams.WndParent <> 0 then
    Parent := TQtWidget(AParams.WndParent).GetContainerWidget
  else
    Parent := nil;
  Result := QGraphicsView_create(Parent);
end;

{ TQtDesignWidget }

function TQtDesignWidget.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  Result := inherited CreateWidget(AParams);
  FDesignControl := QWidget_create(Result);
  QWidget_setMouseTracking(FDesignControl, True);
  setProperty(FDesignControl, 'lclwidget', Int64(PtrUInt(Self)));
  QtWidgetSet.AddHandle(Self);
  BringDesignerToFront;
end;

procedure TQtDesignWidget.DestroyWidget;
begin
  inherited DestroyWidget;
  FDesignControl := nil;
end;

procedure TQtDesignWidget.SlotDesignControlPaint(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMPaint;
  AStruct: PPaintStruct;
  P: TPoint;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotPaint ', dbgsName(LCLObject));
  {$endif}

  if (LCLObject is TWinControl) then
  begin
    FillChar(Msg, SizeOf(Msg), #0);

    Msg.Msg := LM_PAINT;
    New(AStruct);
    FillChar(AStruct^, SizeOf(TPaintStruct), 0);
    Msg.PaintStruct := AStruct;

    with PaintData do
    begin
      PaintWidget := FDesignControl;
      ClipRegion := QPaintEvent_Region(QPaintEventH(Event));
      if ClipRect = nil then
        New(ClipRect);
      QPaintEvent_Rect(QPaintEventH(Event), ClipRect);
    end;

    Msg.DC := BeginPaint(THandle(Self), AStruct^);
    FDesignContext := Msg.DC;

    Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
    Msg.PaintStruct^.hdc := FDesignContext;

    P := getClientOffset;
    inc(P.X, FScrollX);
    inc(P.Y, FScrollY);
    TQtDeviceContext(Msg.DC).translate(P.X, P.Y);

    // send paint message
    try
      // Saving clip rect and clip region
      try
        LCLObject.WindowProc(TLMessage(Msg));
      finally
        Dispose(PaintData.ClipRect);
        Fillchar(FPaintData, SizeOf(FPaintData), 0);
        FDesignContext := 0;
        EndPaint(THandle(Self), AStruct^);
        Dispose(AStruct);
      end;
    except
      Application.HandleException(nil);
    end;
  end;
end;

procedure TQtDesignWidget.BringDesignerToFront;
begin
  if FDesignControl <> nil then
    QWidget_raise(FDesignControl);
end;

procedure TQtDesignWidget.ResizeDesigner;
var
  R: TRect;
begin
  if FDesignControl = nil then
    Exit;
  // FDesignControl must be same as form area,
  // since we use QWidget, not QMainWindow in design time.
  QWidget_contentsRect(Widget, @R);
  with R do
  begin
    QWidget_move(FDesignControl, Left, Top);
    QWidget_resize(FDesignControl, Right - Left, Bottom - Top);
  end;
end;

function TQtDesignWidget.GetContext: HDC;
begin
  if FDesignContext <> 0 then
    Result := FDesignContext
  else
    Result := FContext;
end;

function TQtDesignWidget.DesignControlEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  p: TQtPoint;
  pt: TPoint;
  R: TRect;
  Control: TControl;
  MouseEvent: QMouseEventH;
  WidgetToNotify: QWidgetH;
  WSQtWidget: TWSWinControlClass;
  Action: QActionH;
begin
  Result := False;
  QEvent_Accept(Event);
  if LCLObject = nil then
    exit;
  if QEvent_type(Event) = QEventDestroy then
  begin
    {FDesignControl is always destroyed by it's parent,
     only thing we need is to remove dynamic property.}
    RemoveProperty(FDesignControl,'lclwidget');
    exit;
  end;
  BeginEventProcessing;
  case QEvent_type(Event) of
    QEventMouseButtonPress,
    QEventMouseButtonRelease:
    begin
      p := QMouseEvent_pos(QMouseEventH(Event))^;
      OffsetMousePos(@p);
      pt := Point(p.x, p.y);
      Control := LCLObject.ControlAtPos(pt, [capfRecursive, capfAllowWinControls]);

      if Assigned(Control) and (Control is TWinControl) then
      begin
        if Control is TCustomNotebook then
          WidgetToNotify := TQtTabWidget(TWinControl(Control).Handle).TabBar.Widget
        else
          WidgetToNotify := TQtWidget(TWinControl(Control).Handle).Widget;

        p := QMouseEvent_pos(QMouseEventH(Event))^;
        QWidget_mapFrom(WidgetToNotify, @p, Widget, @p);
        Pt := Point(p.x, p.y);

        WSQtWidget := TWSWinControlClass(TWinControl(Control).WidgetSetClass);

        if WSQtWidget.GetDesignInteractive(TWinControl(Control), Pt) then
        begin
          MouseEvent := QMouseEvent_create(QEvent_type(Event), @p,
            QMouseEvent_globalpos(QMouseEventH(Event)),
            QMouseEvent_button(QMouseEventH(Event)),
            QMouseEvent_buttons(QMouseEventH(Event)),
            QInputEvent_modifiers(QInputEventH(Event))
            );
          QCoreApplication_postEvent(WidgetToNotify, MouseEvent, 1);
        end;
      end else
      begin
        p := QMouseEvent_globalPos(QMouseEventH(Event))^;
        WidgetToNotify := QApplication_widgetAt(@p);
        if (WidgetToNotify <> nil) then
        begin
          if TQtMainWindow(Self).MenuBar.Widget <> nil then
          begin
            p := QMouseEvent_Pos(QMouseEventH(Event))^;
            QWidget_geometry(TQtMainWindow(Self).MenuBar.Widget, @R);
            pt := Point(P.X, P.Y);
            if LCLIntf.PtInRect(R, pt) then
            begin
              Action := QMenuBar_actionAt(QMenuBarH(TQtMainWindow(Self).MenuBar.Widget), @p);
              if Action <> nil then
              begin
                QCoreApplication_notify(QCoreApplication_instance(), TQtMainWindow(Self).MenuBar.Widget, Event);
                QEvent_accept(Event);
                Result := True;
              end;
            end;
          end;
        end;
      end;
    end;
    QEventPaint: SlotDesignControlPaint(Sender, Event);
  end;
  EndEventProcessing;
end;

function TQtDesignWidget.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  Result := False;
  QEvent_accept(Event);
  if LCLObject = nil then
    exit;

  BeginEventProcessing;
  case QEvent_type(Event) of
    QEventChildAdded,
    QEventChildRemoved: BringDesignerToFront;
    QEventResize:
      begin
        Result := inherited EventFilter(Sender, Event);
        ResizeDesigner;
      end;
    else
      Result := inherited EventFilter(Sender, Event);
  end;
  EndEventProcessing;
end;

procedure TQtDesignWidget.AttachEvents;
begin
  inherited AttachEvents;
  if FDesignControl <> nil then
  begin
    FDesignControlEventHook := QObject_hook_create(FDesignControl);
    QObject_hook_hook_events(FDesignControlEventHook, @DesignControlEventFilter);
  end;
end;

procedure TQtDesignWidget.DetachEvents;
begin
  if FDesignControlEventHook <> nil then
    QObject_hook_destroy(FDesignControlEventHook);
  inherited DetachEvents;
end;

procedure TQtDesignWidget.lowerWidget;
begin
  inherited lowerWidget;
  BringDesignerToFront;
end;

procedure TQtDesignWidget.raiseWidget;
begin
  inherited raiseWidget;
  BringDesignerToFront;
end;

{ TQtMessageBox }

function TQtMessageBox.getMsgBoxType: QMessageBoxIcon;
begin
  Result := QMessageBox_icon(QMessageBoxH(Widget));
end;

procedure TQtMessageBox.setDetailText(const AValue: WideString);
var
  Str: WideString;
begin
  Str := GetUTF8String(AValue);
  QMessageBox_setDetailedText(QMessageBoxH(Widget), @Str);
end;

function TQtMessageBox.getMessageStr: WideString;
var
  Str: WideString;
begin
  QMessageBox_text(QMessageBoxH(Widget), @Str);
  Result := UTF16ToUTF8(Str);
end;

function TQtMessageBox.getDetailText: WideString;
var
  Str: WideString;
begin
  QMessageBox_detailedText(QMessageBoxH(Widget), @Str);
  Result := UTF16ToUTF8(Str);
end;

procedure TQtMessageBox.setMessageStr(const AValue: WideString);
var
  Str: WideString;
begin
  Str := GetUTF8String(AValue);
  QMessageBox_setText(QMessageBoxH(Widget), @Str);
end;

procedure TQtMessageBox.setMsgBoxType(const AValue: QMessageBoxIcon);
begin
  QMessageBox_setIcon(QMessageBoxH(Widget), AValue);
end;

procedure TQtMessageBox.setTitle(const AValue: WideString);
begin
  if AValue <> FTitle then
  begin
    FTitle := GetUTF8String(AValue);
    QMessageBox_setWindowTitle(QMessageBoxH(Widget), @FTitle);
  end;
end;

function TQtMessageBox.CreateWidget(AParent: QWidgetH): QWidgetH;
begin
  FHasPaint := False;
  Result := QMessageBox_create(AParent);
  QMessageBox_setWindowModality(QMessageBoxH(Result), QtApplicationModal);
end;

constructor TQtMessageBox.Create(AParent: QWidgetH);
begin
  WidgetColorRole := QPaletteWindow;
  TextColorRole := QPaletteWindowText;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;
  FProps := nil;
  LCLObject := nil;
  FKeysToEat := [];
  FHasPaint := False;
  Widget := CreateWidget(AParent);
end;

procedure TQtMessageBox.AttachEvents;
begin
  inherited AttachEvents;
  FMBEventHook := QObject_hook_create(Widget);
  QObject_hook_hook_events(FMBEventHook, @EventFilter);
end;

procedure TQtMessageBox.DetachEvents;
begin
  QObject_hook_destroy(FMBEventHook);
  inherited DetachEvents;
end;

function TQtMessageBox.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  {we'll need it later. QMessageBox uses it's own eventLoop !}
  Result := False;
  QEvent_accept(Event);
  if LCLObject <> nil then
    Result := inherited EventFilter(Sender, Event);
end;

procedure TQtMessageBox.SetButtonProps(ABtn: QPushButtonH; AResult: Int64; const ADefaultBtn: Boolean; const AEscapeBtn: Boolean);
var
  v: QVariantH;
begin
  if ADefaultBtn then
    QMessageBox_setDefaultButton(QMessageBoxH(Widget), ABtn);

  if AEscapeBtn then
    QMessageBox_setEscapeButton(QMessageBoxH(Widget), ABtn);

  v := QVariant_create(AResult);
  try
    QObject_setProperty(ABtn, 'lclmsgboxbutton', v);
  finally
    QVariant_destroy(v);
  end;
end;

function TQtMessageBox.AddButton(ACaption: WideString; ABtnType: QMessageBoxStandardButton;
   AResult: Int64; const ADefaultBtn: Boolean; const AEscapeBtn: Boolean): QPushButtonH;
var
  Str: WideString;
begin
  Result := QMessageBox_addButton(QMessageBoxH(Widget), ABtnType);
  Str := GetUTF8String(ACaption);
  QAbstractButton_setText(Result, @Str);
  SetButtonProps(Result, AResult, ADefaultBtn, AEscapeBtn);
end;

function TQtMessageBox.AddButton(ACaption: WideString; AResult: Int64; const ADefaultBtn: Boolean;
  const AEscapeBtn: Boolean): QPushButtonH;
var
  Str: WideString;
begin
  Str := GetUTF8String(ACaption);
  Result := QMessageBox_addButton(QMessageBoxH(Widget), @Str, QMessageBoxActionRole);
  SetButtonProps(Result, AResult, ADefaultBtn, AEscapeBtn);
end;

function TQtMessageBox.exec: Int64;
var
  ABtn: QPushButtonH;
  v: QVariantH;
  ok: Boolean;
  QResult: Int64;
begin
  Result := QMessageBoxNoButton;
  {$IFDEF QTDIALOGS_USES_QT_LOOP}
  QDialog_exec(QMessageBoxH(Widget));
  {$ELSE}
  QMessageBox_setWindowModality(QMessageBoxH(Widget), QtApplicationModal);
  QWidget_show(Widget);
  repeat
    QCoreApplication_processEvents();
    Application.Idle(true);
  until not QWidget_isVisible(Widget) or Application.Terminated;
  {$ENDIF}
  ABtn := QPushButtonH(QMessageBox_clickedButton(QMessageBoxH(Widget)));
  if ABtn <> nil then
  begin
    v := QVariant_create();
    try
      QObject_property(ABtn, v, 'lclmsgboxbutton');
      if QVariant_isValid(v) then
      begin
        QResult := QVariant_toLongLong(v, @Ok);
        if Ok then
          Result := QResult;
      end;
    finally
      QVariant_destroy(v);
    end;
  end;
end;

end.

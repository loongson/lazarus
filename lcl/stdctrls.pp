{ 
 /*************************************************************************** 
                               StdCtrls.pp  - 
                             ------------------- 
 
                   Initial Revision  : Tue Oct 19 CST 1999 
 
 ***************************************************************************/ 
 
/*************************************************************************** 
 *                                                                         * 
 *   This program is free software; you can redistribute it and/or modify  * 
 *   it under the terms of the GNU General Public License as published by  * 
 *   the Free Software Foundation; either version 2 of the License, or     * 
 *   (at your option) any later version.                                   * 
 *                                                                         * 
 ***************************************************************************/ 
} 
 
{
@author()
@created()
@lastmod()

Detailed description of the Unit.
}

unit stdctrls;

{$mode objfpc}
{$H+}
interface

uses  vclglobals, classes, sysutils, Graphics, LMessages, Controls, forms;


type
   TEditCharCase = (ecNormal, ecUppercase, ecLowerCase);
   TScrollStyle = (ssNone, ssHorizontal, ssVertical, ssBoth);
   TScrollBar = class(TWinControl)
   private
      fOwner: TControl;

   public
      constructor Create(AOwner: TComponent); override;
   end;

   TCustomGroupBox = class (TWinControl) {class(TCustomControl) }
   public                                                                                      
     constructor Create(AOwner : TComponent); Override;                                         
   end;                                                                                        
                                                                                                   
   TGroupBox = class(TCustomGroupBox)                                                         
   published
     property Caption;
     property Visible;
   end;                                                                                        

  TComboBoxStyle = (csDropDown, csSimple, csDropDownList, csOwnerDrawFixed, csOwnerDrawVariable);      

  TCustomComboBox = class(TWinControl)
    private
      FItems: TStrings;
      FStyle : TComboBoxStyle;
      FOnChange : TNotifyEvent;
      FSorted : boolean;
      procedure SetItems(Value : TStrings);
      procedure CNDrawItems(var Message : TLMDrawItems) ; message CN_DrawItem;
    protected
      procedure CreateHandle; override;
      procedure DestroyHandle; override;
      procedure DoChange(var msg); message LM_CHANGED;
      procedure AttachSignals; override;
      function GetSelLength : integer;
      function GetSelStart : integer;
      function GetSelText : string;
      function GetItemIndex : integer; virtual;
      function GetMaxLength : integer; virtual;
      procedure SetItemIndex(Val : integer); virtual;
      procedure SetMaxLength(Val : integer); virtual;
      procedure SetSelLength(Val : integer);
      procedure SetSelStart(Val : integer);
      procedure SetSelText(Val : string);
      procedure SetSorted(Val : boolean); virtual;
      procedure SetStyle(Val : TComboBoxStyle); virtual;
      property Items : TStrings read FItems write SetItems;
      property ItemIndex : integer read GetItemIndex write SetItemIndex;
      property MaxLength : integer read GetMaxLength write SetMaxLength;
      property Sorted : boolean read FSorted write SetSorted;
      property Style : TComboBoxStyle read FStyle write SetStyle;
      property OnChange : TNotifyEvent read FOnChange write FOnChange;
    public
          constructor Create(AOwner : TComponent); Override;
          destructor Destroy; override;
          property SelLength : integer read GetSelLength write SetSelLength;
          property SelStart : integer read GetSelStart write SetSelStart;
          property SelText : String read GetSelText write SetSelText;
    end;

    TComboBox = class(TCustomComboBox)
    public
      property ItemIndex;
    published
      property Enabled;
      property Items;
      property MaxLength;
      property Sorted;
      property Style;
      property Text;
      property Visible;
      property OnChange;
      property OnClick;
    end;
    
  TListBoxStyle = (lbStandard, lbOwnerDrawFixed, lbOwnerDrawVariable);


  TCustomListBox = class(TWinControl)
  private
    FBorderStyle : TBorderStyle;
    FExtendedSelect, FMultiSelect : boolean;
    FItems : TStrings;
    FSorted : boolean;
    FStyle : TListBoxStyle;
    procedure UpdateSelectionMode;
  protected
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
    function GetItemIndex : integer; virtual;
    function GetSelCount : integer;
    function GetSelected(Index : integer) : boolean;
    procedure SetBorderStyle(Val : TBorderStyle); virtual;
    procedure SetExtendedSelect(Val : boolean); virtual;
    procedure SetItemIndex(Val : integer); virtual;
    procedure SetItems(Value : TStrings); virtual;
    procedure SetMultiSelect(Val : boolean); virtual;
    procedure SetSelected(Index : integer; Val : boolean);
    procedure SetSorted(Val : boolean); virtual;
    procedure SetStyle(Val : TListBoxStyle); virtual;
    property BorderStyle : TBorderStyle read FBorderStyle write SetBorderStyle;
    property ExtendedSelect : boolean read FExtendedSelect write SetExtendedSelect;
    property Sorted : boolean read FSorted write SetSorted;
    property Style : TListBoxStyle read FStyle write SetStyle;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    property ItemIndex : integer read GetItemIndex write SetItemIndex;
    property Items : TStrings read FItems write SetItems;
    property MultiSelect : boolean read FMultiSelect write SetMultiSelect;
    property SelCount : integer read GetSelCount;
    property Selected[Index : integer] : boolean read GetSelected write SetSelected;
  end;
    
  TListBox = class(TCustomListBox)
  public
    property ItemIndex;
  published
    property Align;
    property BorderStyle;
    property ExtendedSelect;
    property Items;
    property MultiSelect;
    property OnClick;
    property OnDblClick;
    property Sorted;
    property Style;
    property Visible;
  end;    

  TCustomEdit = class(TWinControl)
  private
    FMaxLength : Integer;
    FModified : Boolean;
    FReadOnly : Boolean;
    FCharCase : TEditCharCase;
    FOnChange : TNotifyEvent;
    Function GetModified : Boolean;
    Procedure SetCharCase(Value : TEditCharCase);
    Procedure SetMaxLength(Value : Integer);
    Procedure SetModified(Value : Boolean);
    Procedure SetReadOnly(Value : Boolean);
//    Procedure CMTextChanged(Var Message : TLMessage); message CM_TextChanged;
  protected
    Procedure CMTextChanged(Var Message : TLMessage); message CM_TextChanged;
    Procedure Change; dynamic;
    procedure AttachSignals; override;

    property OnChange : TNotifyEvent read FOnChange write FOnChange;
  public
    property CharCase : TEditCharCase read FCharCase write SetCharCase default ecNormal;
    property MaxLength : Integer read FMaxLength write SetMaxLength default 0;
    property ReadOnly : Boolean read FReadOnly write SetReadOnly default false;

    constructor Create(AOwner: TComponent); override;
    property Modified : Boolean read GetModified write SetModified;
    property Text;
  published
    property TabStop default true;
  end;


   TCustomMemo = class(TCustomEdit)
   private
      FFont : TFont;
      FLines: TStrings;
      FScrollBars: TScrollStyle;
      FWordWrap: Boolean;
   protected
//      procedure AttachSignals; override;

      procedure SetLines(Value : TStrings);
      procedure SetWordWrap(Value : Boolean);
   public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure Append(Value : String);
      property Lines: TStrings read FLines write SetLines;
      property ScrollBars: TScrollStyle read FScrollBars write FScrollBars;
      property WordWrap: Boolean read FWordWrap write SetWordWrap;
      property Font : TFont read FFont write FFont;
   end;

   TEdit = class(TCustomEdit)
   published
      property OnChange;
      property OnClick;
      property CharCase;
      property DragMode;
      property MaxLength;
      property ReadOnly;
      property Text;
      property Visible;
   end;


   TMemo = class(TCustomMemo)
   private
   public
   published
      property Align;
      property Color;
      property Font;

      property Lines;
      property ReadOnly;
      property Tabstop;
      property Visible;
      property OnChange;
   end;

  TTextLayout = (tlTop, tlCenter, tlBottom);

  TCustomLabel = class(TWinControl)
  private
    FAlignment : TAlignment;
    FWordWrap : Boolean;
    FLayout : TTextLayout;
    procedure SetAlignment(Value : TAlignment);
    procedure SetLayout(Value : TTextLayout);
    procedure SetWordWrap(Value : Boolean);
  protected
    function GetLabelText: String ; virtual;
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;
    property Layout: TTextLayout read FLayout write SetLayout default tlBottom;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default false;
  public
    constructor Create(AOwner : TComponent); override;
  end;


  TLabel = class(TCustomLabel)
  published
    property Alignment;
    property Caption;
    property Color;
    property Font;
    property Visible;
    property Layout;
    property WordWrap;
  end;


   TButtonControl = class(TWinControl)
   private
     FClicksDisabled: Boolean;
   protected
     function GetChecked: Boolean; virtual;
     procedure SetChecked(Value: Boolean); virtual;
     property Checked: Boolean read GetChecked write SetChecked;// stored IsCheckedStored default False;
     property ClicksDisabled: Boolean read FClicksDisabled write FClicksDisabled;
   public
     constructor Create(AOwner: TComponent); override;
   end;



                        {TCHECKBOX}

   TCheckBoxState = (cbUnchecked, cbChecked, cbGrayed);

   TCustomCheckBox = class(TButtonControl)
   private
      FAllowGrayed: Boolean;
      FState: TCheckBoxState;
      procedure SetState(Value: TCheckBoxState);
      function GetState : TCheckBoxState;
   protected
      procedure InitializeWnd; override;
//      procedure Click; override;
      procedure Toggle; virtual;
      function GetChecked: Boolean; override;
      procedure SetChecked(Value: Boolean); override;
      procedure ApplyChanges; virtual;
      property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed;
      property State: TCheckBoxState read GetState write SetState;

   public
      constructor Create(AOwner: TComponent); override;

   end;

   TCheckBox = class(TCustomCheckBox)
   private
   public
      constructor Create(AOwner: TComponent); override;
   published
      property AllowGrayed;
      property Caption;
      property Checked;
      property State;
      property Visible;
      property Enabled;
      property OnEnter;
      property OnExit;
      property DragCursor;
      property DragKind;
      property DragMode;
      property Hint;
      property ParentShowHint;
      property PopupMenu;
      property ShowHint;
      property TabOrder;
      property TabStop;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
      property OnStartDrag;
   end;



   TToggleBox = class(TCustomCheckBox)
   private
   public
      constructor Create(AOwner: TComponent); override;

   published
      property AllowGrayed;
      property Caption;
      property Checked;
      property State;
      property Visible;
      property Enabled;
      property OnEnter;
      property OnExit;
      property DragCursor;
      property DragKind;
      property DragMode;
      property Hint;
      property ParentShowHint;
      property PopupMenu;
      property ShowHint;
      property TabOrder;
      property TabStop;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
      property OnStartDrag;
   end;

               {TRadioButton}
   TRadioButton = Class; //Forward Declaration

   TRadioButton = class(TCustomCheckBox)
   private
      fGroup : THandle;                      // handle to the previous button in the group this button belongs to
      procedure SetGroup (Value : THandle); 
      function GetGroup : THandle;
   protected
      procedure CreateWnd; override;
   public
      constructor Create (AOwner: TComponent); override;
      property group : THandle read GetGroup write SetGroup;
   published
      property AllowGrayed;
      property Caption;
      property Checked;
      property State;
      property Visible;
      property Enabled;
      property OnEnter;
      property OnExit;
      property DragCursor;
      property DragKind;
      property DragMode;
      property Hint;
      property ParentShowHint;
      property PopupMenu;
      property ShowHint;
      property TabOrder;
      property TabStop;
      property OnDragDrop;
      property OnDragOver;
      property OnEndDrag;
      property OnMouseDown;
      property OnMouseMove;
      property OnMouseUp;
      property OnStartDrag;
   end;




implementation {*******}


type
   TSelection = record
      Startpos, EndPos: Integer;
   end;

   TMemoStrings = class(TStrings)
   private
      FMemo: TCustomMemo;
   protected
      function Get(Index : Integer): String; override;
      function GetCount: Integer; override;
   public
      constructor Create(AMemo: TCustomMemo);
      procedure Clear; override;
      procedure Delete(index : Integer); override;
      procedure Insert(index: Integer; const S: String); override;
   end;

 { TComboBoxStrings = class(TStrings)
  private
    ComboBox: TCustomComboBox;
  protected
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
    function GetObject(Index: Integer): TObject; override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
    procedure SetUpdateState(Updating: Boolean); override;
  public
    function Add(const S: string): Integer; override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    function IndexOf(const S: string): Integer; override;
    procedure Insert(Index: Integer; const S: string); override;
  end;
    }
var
   aColors : Array[1..10] of TColor;
   ColorNum : Integer;

{$I customgroupbox.inc}
{$I customcombobox.inc}                                                                                            
{$I customlistbox.inc}
{$I custommemo.inc}
{$I customedit.inc}
{$I customlabel.inc}
{$I customcheckbox.inc}

{$I scrollbar.inc} 
{$I memo.inc}
{$I memostrings.inc}

{$I edit.inc}
{$I buttoncontrol.inc}
{$I checkbox.inc}
{$I radiobutton.inc}
{$I togglebox.inc}

end.

{ =============================================================================

  $Log$
  Revision 1.9  2001/01/10 20:12:29  lazarus
  Added the Nudge feature to the IDE.
  Shane

  Revision 1.8  2001/01/05 17:44:37  lazarus
  ViewUnits1, ViewForms1 and MessageDlg are all loaded from their resources and all controls are auto-created on them.
  There are still a few problems with some controls so I haven't converted all forms.
  Shane

  Revision 1.7  2001/01/04 15:09:05  lazarus
  Tested TCustomEdit.Readonly, MaxLength and CharCase.
  Shane

  Revision 1.6  2001/01/04 13:52:00  lazarus
  Minor changes to TEdit.
  Not tested.
  Shane

  Revision 1.5  2000/12/29 15:04:07  lazarus
  Added more images to the resource.
  Shane

  Revision 1.4  2000/12/01 15:50:39  lazarus
  changed the TCOmponentInterface SetPropByName.  It works for a few properties, but not all.
  Shane

  Revision 1.3  2000/11/29 21:22:35  lazarus
  New Object Inspector code
  Shane

  Revision 1.2  2000/07/16 12:45:01  lazarus
  Added procedure ListBox.Clear (changes by chris, added by stoppok)

  Revision 1.1  2000/07/13 10:28:24  michael
  + Initial import

  Revision 1.28  2000/07/09 20:41:20  lazarus
  Added Attachsignals method to custombobobox, stoppok

  Revision 1.27  2000/06/29 21:07:08  lazarus
  some more published properties for combobox, stoppok

  Revision 1.26  2000/06/24 21:30:19  lazarus
  *** empty log message ***

  Revision 1.25  2000/06/16 13:33:21  lazarus
  Created a new method for adding controls to the toolbar to be dropped onto the form!
  Shane

  Revision 1.24  2000/05/30 22:28:41  lazarus
  MWE:
    Applied patches from Vincent Snijders:
    + Added GetWindowRect
    * Fixed horz label alignment
    + Added vert label alignment

  Revision 1.23  2000/05/08 12:54:19  lazarus
  Removed some writeln's
  Added alignment for the TLabel.  Isn't working quite right.
  Added the shell code for WindowFromPoint and GetParent.
  Added FindLCLWindow
  Shane

  Revision 1.22  2000/04/18 20:06:39  lazarus
  Added some functions to Compiler.pp

  Revision 1.21  2000/04/13 21:25:16  lazarus
  MWE:
    ~ Added some docu and did some cleanup.
  Hans-Joachim Ott <hjott@compuserve.com>:
    * TMemo.Lines works now.
    + TMemo has now a property Scrollbar.
    = TControl.GetTextBuf revised :-)
    + Implementation for CListBox columns added
    * Bug in TGtkCListStringList.Assign corrected.

  Revision 1.20  2000/04/10 14:03:06  lazarus
  Added SetProp and GetProp winapi calls.
  Added ONChange to the TEdit's published property list.
  Shane

  Revision 1.19  2000/03/30 21:57:45  lazarus
  MWE:
    + Added some general functions to Get/Set the Main/Fixed/CoreChild
      widget
    + Started with graphic scalig/depth stuff. This is way from finished

  Hans-Joachim Ott <hjott@compuserve.com>:
    + Added some improvements for TMEMO

  Revision 1.18  2000/03/30 18:07:54  lazarus
  Added some drag and drop code
  Added code to change the unit name when it's saved as a different name.  Not perfect yet because if you are in a comment it fails.

  Shane

  Revision 1.17  2000/02/28 19:16:04  lazarus
  Added code to the FILE CLOSE to check if the file was modified.  HAven't gotten the application.messagebox working yet though.  It won't stay visible.
  Shane

  Revision 1.16  2000/02/24 21:15:30  lazarus
  Added TCustomForm.GetClientRect and RequestAlign to try and get the controls to align correctly when a MENU is present.  Not Complete yet.

  Fixed the bug in TEdit that caused it not to update it's text property.  I will have to
  look at TMemo to see if anything there was affected.

  Added SetRect to WinAPI calls
  Added AdjustWindowRectEx to WINAPI calls.
  Shane

  Revision 1.15  2000/02/22 22:19:50  lazarus
  TCustomDialog is a descendant of TComponent.
  Initial cuts a form's proper Close behaviour.

  Revision 1.14  2000/02/22 21:51:40  lazarus
  MWE: Removed some double (or triple) event declarations.
       The latest compiler doesn't like it

  Revision 1.13  2000/02/21 17:38:04  lazarus
  Added modalresult to TCustomForm
  Added a View Units dialog box
  Added a View Forms dialog box
  Added a New Unit menu selection
  Added a New Form menu selection
  Shane

  Revision 1.12  2000/02/18 19:38:53  lazarus
  Implemented TCustomForm.Position
  Better implemented border styles. Still needs some tweaks.
  Changed TComboBox and TListBox to work again, at least partially.
  Minor cleanups.

  Revision 1.11  2000/01/04 19:16:09  lazarus
  Stoppok:
     - new messages LM_GETVALUE, LM_SETVALUE, LM_SETPROPERTIES
     - changed trackbar, progressbar, checkbox to use above messages
     - some more published properties for above components
       (all properties derived from TWinControl)
     - new functions SetValue, GetValue, SetProperties in gtk-interface

  Revision 1.10  1999/12/30 19:04:13  lazarus
   - Made TRadiobutton work again
   - Some more cleanups to checkbox code
           stoppok

  Revision 1.9  1999/12/30 10:38:59  lazarus

    Some changes to Checkbox code.
      stoppok

  Revision 1.8  1999/12/29 01:30:02  lazarus

    Made groupbox working again.
      stoppok

  Revision 1.7  1999/12/18 18:27:32  lazarus
  MWE:
    Rearranged some events to get a LM_SIZE, LM_MOVE and LM_WINDOWPOSCHANGED
    Initialized the TextMetricstruct to zeros to clear unset values
    Get mwEdit to show more than one line
    Fixed some errors in earlier commits

  Revision 1.6  1999/12/07 01:19:26  lazarus
  MWE:
    Removed some double events
    Changed location of SetCallBack
    Added call to remove signals
    Restructured somethings
    Started to add default handlers in TWinControl
    Made some parts of TControl and TWinControl more delphi compatible
    ... and lots more ...

  Revision 1.5  1999/11/01 01:28:30  lazarus
  MWE: Implemented HandleNeeded/CreateHandle/CreateWND
       Now controls are created on demand. A call to CreateComponent shouldn't
       be needed. It is now part of CreateWnd

  Revision 1.4  1999/10/27 17:27:07  lazarus
  Added alot of changes and TODO: statements
  shane

  Revision 1.3  1999/10/25 17:38:52  lazarus
  More stuff added for compatability.  Most stuff added was put in the windows.pp file.  CONST scroll bar messages and such.  2 functions were also added to that unit that needs to be completed.
  Shane

  Revision 1.2  1999/10/22 21:01:51  lazarus

        Removed calls to InterfaceObjects except for controls.pp. Commented
        out any gtk depend lines of code.     MAH

  Revision 1.1  1999/10/19 19:16:51  lazarus
  renamed stdcontrols.pp stdctrls.pp
  Shane

  Revision 1.9  1999/08/21 13:57:41  lazarus
  Implemented TListBox.BorderStyle. The listbox is scrollable now.

  Revision 1.8  1999/08/14 10:05:56  lazarus
  Added TListBox ItemIndex property. Made ItemIndex public for TComboBox and TListBox.

  Revision 1.7  1999/08/11 20:41:34  lazarus

  Minor changes and additions made.  Lazarus may not compile due to these changes

  Revision 1.6  1999/08/07 17:59:23  lazarus

        buttons.pp   the DoLeave and DoEnter were connected to the wrong
                     event.

        The rest were modified to use the new SendMessage function.   MAH

 }



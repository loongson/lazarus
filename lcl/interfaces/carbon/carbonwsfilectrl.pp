{ $Id: Carbonwsfilectrl.pp 5319 2004-03-17 20:11:29Z marc $}
{
 *****************************************************************************
 *                              CarbonWSFileCtrl.pp                          * 
 *                              ---------------                              * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.LCL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit CarbonWSFileCtrl;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
//  FileCtrl,
////////////////////////////////////////////////////
  WSFileCtrl, WSLCLClasses;

type

  { TCarbonWSCustomFileListBox }

  TCarbonWSCustomFileListBox = class(TWSCustomFileListBox)
  private
  protected
  public
  end;

  { TCarbonWSFileListBox }

  TCarbonWSFileListBox = class(TWSFileListBox)
  private
  protected
  public
  end;


implementation

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TCustomFileListBox, TCarbonWSCustomFileListBox);
//  RegisterWSComponent(TFileListBox, TCarbonWSFileListBox);
////////////////////////////////////////////////////
end.

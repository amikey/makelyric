//***************************************************************************
//
//       名称：uMain.pas
//       工具：RAD Studio XE6
//       日期：2015/11/2 19:30:29
//       作者：ying32
//       QQ  ：1444386932
//       E-mail：yuanfen3287@vip.qq.com
//       版权所有 (C) 2015-2015 ying32 All Rights Reserved
//
//
//***************************************************************************
unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  Tfrm_Main = class(TForm)
    grp_in: TGroupBox;
    grp_out: TGroupBox;
    btn_Convert: TButton;
    chk_in_krc: TCheckBox;
    chk_in_qrc: TCheckBox;
    chk_in_nrc: TCheckBox;
    chk_in_trc: TCheckBox;
    chk_out_trc: TCheckBox;
    chk_out_lrc: TCheckBox;
    chk_out_qrc: TCheckBox;
    chk_out_krc: TCheckBox;
    chk_out_nrc: TCheckBox;
    chk_out_ksc: TCheckBox;
    procedure btn_ConvertClick(Sender: TObject);
  private
    FInKrc, FInNrc, FInQrc, FInTrc: Boolean;
    FOutTrc, FOutLrc, FOutQrc, FOutKrc, FOutNrc, FOutKsc: Boolean;
    procedure InitCheck;
  public
    { Public declarations }
  end;

var
  frm_Main: Tfrm_Main;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  System.Types, uLyricList;

procedure Tfrm_Main.btn_ConvertClick(Sender: TObject);
var
  LFiles: TStringDynArray;
  LExt: string;
  S: string;
  LList: TLyricList;
begin
  InitCheck;
  LFiles := TDirectory.GetFiles(ExtractFilePath(ParamStr(0)),
    function(const Path: string; const SearchRec: TSearchRec): Boolean
    begin
      LExt := ExtractFileExt(SearchRec.Name);
      Result := (SameText(LExt, '.qrc') and FInQrc) or
                (SameText(LExt, '.krc') and FInKrc) or
                (SameText(LExt, '.nrc') and FInNrc) or
                (SameText(LExt, '.trc') and FInTrc);
    end);
  LList := TLyricList.Create;
  try
    for S in LFiles do
    begin
      LExt := ExtractFileExt(S);
      if SameText(LExt, '.qrc') then
        TLyricConvert.LoadQrc(S, LList)
      else if SameText(LExt, '.krc') then
        TLyricConvert.LoadKrc(S, LList)
      else if SameText(LExt, '.nrc') then
        TLyricConvert.LoadNrc(S, LList)
      else if SameText(LExt, '.trc') then
        TLyricConvert.LoadTrc(S, LList);
      if FOutTrc then
        TLyricConvert.ToTrc(LList, TPath.ChangeExtension(S, '.trc'));
      if FOutLrc then
        TLyricConvert.ToLrc(LList, TPath.ChangeExtension(S, '.lrc'));
      if FOutQrc then
        TLyricConvert.ToQrc(LList, TPath.ChangeExtension(S, '.qrc'));
      if FOutKrc then
        TLyricConvert.ToKrc(LList, TPath.ChangeExtension(S, '.krc'));
      if FOutNrc then
        TLyricConvert.ToNrc(LList, TPath.ChangeExtension(S, '.nrc'));
      if FOutKsc then
        TLyricConvert.ToKsc(LList, TPath.ChangeExtension(S, '.ksc'));
      LList.Clear;
    end;
  finally
    LList.Free;
  end;
end;

procedure Tfrm_Main.InitCheck;
begin
  FInKrc := chk_in_krc.Checked;
  FInNrc := chk_in_nrc.Checked;
  FInQrc := chk_in_qrc.Checked;
  FInTrc := chk_in_trc.Checked;

  FOutTrc := chk_out_trc.Checked;
  FOutLrc := chk_out_lrc.Checked;
  FOutQrc := chk_out_qrc.Checked;
  FOutKrc := chk_out_krc.Checked;
  FOutNrc := chk_out_nrc.Checked;
  FOutKsc := chk_out_ksc.Checked;
end;

end.

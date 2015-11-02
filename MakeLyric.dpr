//***************************************************************************
//
//       名称：MakeLyric.dpr
//       工具：RAD Studio XE6
//       日期：2015/11/2 19:30:42
//       作者：ying32
//       QQ  ：1444386932
//       E-mail：yuanfen3287@vip.qq.com
//       版权所有 (C) 2015-2015 ying32 All Rights Reserved
//
//
//***************************************************************************
program MakeLyric;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frm_Main},
  uLyricList in 'uLyricList.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(Tfrm_Main, frm_Main);
  Application.Run;
end.

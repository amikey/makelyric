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

program CVLyric;

{$R *.dres}

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frm_Main},
  uLyricList in '..\uLyricList.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(Tfrm_Main, frm_Main);
  Application.Run;
end.

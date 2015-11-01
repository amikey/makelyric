unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList, Vcl.Menus,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, uLyricList, Vcl.Buttons, Vcl.MPlayer;

type
  Tfrm_Main = class(TForm)
    actlst1: TActionList;
    pnl_Client: TPanel;
    pgc_Main: TPageControl;
    ts_Lrc: TTabSheet;
    ts_Make: TTabSheet;
    pnl3: TPanel;
    mmo_Lrc: TMemo;
    act_open: TAction;
    TrackBar1: TTrackBar;
    mp_Play: TMediaPlayer;
    dlgOpen1: TOpenDialog;
    tmr1: TTimer;
    pnl2: TPanel;
    btn_Next: TSpeedButton;
    btn_Prev: TSpeedButton;
    act_Next: TAction;
    act_Prev: TAction;
    pb_DrawLyric: TPaintBox;
    pnl_DrawBk: TPanel;
    btn_loadmp3: TSpeedButton;
    ts_Info: TTabSheet;
    grp1: TGroupBox;
    edt_Singer: TEdit;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    edt_SongName: TEdit;
    edt_EditBy: TEdit;
    grp2: TGroupBox;
    chk_krc: TCheckBox;
    chk_qrc: TCheckBox;
    chk_nrc: TCheckBox;
    chk_trc: TCheckBox;
    chk_ksc: TCheckBox;
    btn_output: TSpeedButton;
    stat1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure act_PrevExecute(Sender: TObject);
    procedure act_NextExecute(Sender: TObject);
    procedure act_NextUpdate(Sender: TObject);
    procedure act_PrevUpdate(Sender: TObject);
    procedure pb_DrawLyricPaint(Sender: TObject);
    procedure btn_outputClick(Sender: TObject);
    procedure btn_loadmp3Click(Sender: TObject);
  private
    FColNumber: Integer;
    FLyricList: TLyricList;
    FTabIndex: Integer;
    FPlaying: Boolean;
    procedure SetTabHide;
    procedure ShowTabByIndex(AIndex: Integer);
    function GetMpPos: Integer; inline;
    procedure ResetState;
  public
    { Public declarations }
  end;



var
  frm_Main: Tfrm_Main;

implementation

{$R *.dfm}

function GetWordCount(const AStr: string): Integer;
var
  s: string;
  I: Integer;
begin
  Result := 0;
  for I := 1 to AStr.Length do
  begin
    s := AStr[I];
    if Ord(s[1]) > 127 then
      Result := Result + 1
    else
    begin
      if (s[1] = #32) and (Ord(AStr[I-1]) > 127) then // 空格
        Result := Result + 1
      else if s[1] = #32 then Result := Result + 1;

    end;
  end;
end;

procedure Tfrm_Main.act_NextExecute(Sender: TObject);
begin
  if FTabIndex = 0 then
  begin
    if mmo_Lrc.Text = '' then
    begin
      ShowMessage('请输入歌词!');
      Exit;
    end;
  end else if FTabIndex = 1 then
  begin
    if (edt_SongName.Text = '') or (edt_Singer.Text = '') then
    begin
      ShowMessage('歌曲名和歌手不能为空!');
      Exit;
    end;
  end;
  Inc(FTabIndex);
  ShowTabByIndex(FTabIndex);
end;

procedure Tfrm_Main.act_NextUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := FTabIndex < pgc_Main.PageCount - 1;
end;

procedure Tfrm_Main.act_PrevExecute(Sender: TObject);
begin
  Dec(FTabIndex);
  ShowTabByIndex(FTabIndex);
end;

procedure Tfrm_Main.act_PrevUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := FTabIndex > 0;
end;

procedure Tfrm_Main.btn_loadmp3Click(Sender: TObject);
begin
  if dlgOpen1.Execute then
  begin
    try
      mp_Play.Stop;
    except
    end;
    mp_Play.FileName := dlgOpen1.FileName;
    mp_Play.Open;
    TrackBar1.Max := 0;
    FPlaying := False;
    TrackBar1.Position := 0;
    ResetState;
  end;
end;

procedure Tfrm_Main.btn_outputClick(Sender: TObject);

var
  LPath: string;

  function GetSaveFileName(const AExt: string): string;
  begin
    Result := LPath + edt_SongName.Text + ' - ' + edt_Singer.Text + AExt;
  end;

begin
  if FLyricList.Count = 0 then Exit;
  LPath := ExtractFilePath(ParamStr(0));
  FLyricList.Actor := edt_Singer.Text;
  FLyricList.Title := edt_SongName.Text;
  FLyricList.EditBy := edt_EditBy.Text;
  FLyricList.Total := mp_Play.Length.ToString;
  if chk_krc.Checked then
    TLyricConvert.ToKrc(FLyricList, GetSaveFileName('.krc'));
  if chk_qrc.Checked then
    TLyricConvert.ToQrc(FLyricList, GetSaveFileName('.qrc'));
  if chk_nrc.Checked then
    TLyricConvert.ToNrc(FLyricList, GetSaveFileName(''));
  if chk_trc.Checked then
    TLyricConvert.ToTrc(FLyricList, GetSaveFileName('.trc'));
  if chk_ksc.Checked then
    TLyricConvert.ToKsc(FLyricList, GetSaveFileName('.ksc'));
end;

procedure Tfrm_Main.FormCreate(Sender: TObject);
begin
//  OutputDebugString(PChar(IntToStr(GetWordCount('L''amore resta un mistero'))));
  SetTabHide;
  FColNumber := 0;
  FLyricList := TLyricList.Create;
  chk_qrc.Enabled := QQMusicCommonIsLoaded;
end;

procedure Tfrm_Main.FormDestroy(Sender: TObject);
begin
  FLyricList.Free;
end;

procedure Tfrm_Main.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

  function GetLineTime(const ALine: TLineItem): Integer;
  var
    I: Integer;
  begin
    Result := ALine.StartTime;
    for I := 0 to ALine.Count - 1 do
      Result := Result + ALine.Items[I].Time;
  end;

  procedure SetLineCountTime(ALine: TLineItem);
  var
    I, LTime: Integer;
  begin
    LTime := 0;
    for I := 0 to ALine.Count - 1 do
      LTime := LTime + ALine.Items[I].Time;
    ALine.TimeCount := LTime;
  end;

var
  LLine: TLineItem;
  LWord: TWordItem;
  LLineNumber: Integer;
begin
  if FTabIndex <> 2 then Exit;

  if Key = VK_RIGHT then
  begin
    Inc(FColNumber);
    if FLyricList.Count = 0 then
      LLineNumber := 0
    else LLineNumber := FLyricList.Count - 1;

    if FColNumber = 1 then
    begin
      // 行已经完成, 不能再添加新行了
      if FLyricList.Count >= mmo_Lrc.Lines.Count then Exit;
      if FLyricList.Count > 0 then
      begin
        // 换了新行, 上一行的最后一个字的时间添加
        LLine := FLyricList.Lines[FLyricList.Count - 1];
        if LLine.Count > 0 then
          if LLine.Items[LLine.Count - 1].Time = 0 then
            LLine.Items[LLine.Count - 1].Time := GetMpPos - GetLineTime(LLine);
        SetLineCountTime(LLine);
      end;
      LLine := FLyricList.Add;
      LLine.Text := mmo_Lrc.Lines[LLineNumber];
      LLine.StartTime := GetMpPos;
      // 总是显示部分
      if (FLyricList.Count > 5) and (FLyricList.Count < mmo_Lrc.Lines.Count - 3) then
      begin
        pb_DrawLyric.Top := pb_DrawLyric.Top - 30;
        pb_DrawLyric.Height := pb_DrawLyric.Height + 30;
      end;
    end
    else
      LLine := FLyricList.Lines[LLineNumber];
    LLineNumber := FLyricList.Count - 1;

    if Assigned(LLine) then
    begin
      // 判断所有字已经完成
      if (LLineNumber = mmo_Lrc.Lines.Count - 1) and (LLine.Count = Length(mmo_Lrc.Lines[LLineNumber])) then
      begin
        // 将最后一个字的时间添加进去
        LLine := FLyricList.Lines[LLineNumber];
        if LLine.Count > 0 then
          if LLine.Items[LLine.Count - 1].Time = 0 then
            LLine.Items[LLine.Count - 1].Time := mp_Play.Position - GetLineTime(LLine);
        SetLineCountTime(LLine);
        Exit;
      end;
      // 上一个字的总时间,等于 当前时间 - (当前行起始时间 + 已经添加字时间)
      if LLine.Count > 0 then
      begin
        LWord := LLine.Items[LLine.Count - 1];
        LWord.Time := GetMpPos - GetLineTime(LLine);
        SetLineCountTime(LLine);
      end;
      LWord := LLine.Add;
      LWord.Time := 0;
      LWord.Text := mmo_Lrc.Lines[LLineNumber][FColNumber];
    end;
    // 当前行字已经最后一个了, 初始下行起始
    if FColNumber >= Length(mmo_Lrc.Lines[LLineNumber]) then
      FColNumber := 0;
    pb_DrawLyric.Refresh;
  end else if Key = VK_DOWN then
  begin
    if FLyricList.Count > 0 then
    begin
      LLine := FLyricList.Lines[FLyricList.Count - 1];
      if LLine.Count > 0 then
        LLine.Items[LLine.Count - 1].Time := GetMpPos - GetLineTime(LLine);
      SetLineCountTime(LLine);
      OutputDebugString(PChar('停顿:' + LLine.TimeCount.ToString));
    end;
  end else if Key = VK_SPACE then
  begin
    if FPlaying then
    begin
      FPlaying := False;
      mp_Play.PauseOnly;
    end else
    begin
      FPlaying := True;
      mp_Play.Play;
    end;
  end;
end;


function Tfrm_Main.GetMpPos: Integer;
begin
  Result := mp_Play.Position;
end;

procedure Tfrm_Main.pb_DrawLyricPaint(Sender: TObject);
var
  I, J: Integer;
  R: TRect;
  LLine: TLineItem;
  LBuffer: TBitmap;
begin
  LBuffer := TBitmap.Create;
  try
    with LBuffer do
    begin
      SetSize(pb_DrawLyric.Width, pb_DrawLyric.Height);
      Canvas.Font.Size := 14;
      Canvas.Font.Name := '微软雅黑';

      for I := 0 to mmo_Lrc.Lines.Count - 1 do
      begin
        for J := 1 to Length(mmo_Lrc.Lines[I]) do
        begin
          R.Left := (J - 1) * 25;
          R.Top := I * 30;
          R.Width := 25;
          R.Height := 25;
          Canvas.Brush.Style := bsClear;
          Canvas.Font.Color := clBlack;
          Canvas.TextRect(R, R.Left,R.Top, mmo_Lrc.Lines[I][J]);
        end;
      end;

      if FLyricList.Count > 0 then
      begin
        for I := 0 to FLyricList.Count - 1 do
        begin
          LLine := FLyricList.Lines[I];
          for J := 0 to LLine.Count - 1 do
          begin
            R.Left := J * 25;
            R.Top := I * 30;
            R.Width := 25;
            R.Height := 25;

            Canvas.Font.Color := clSkyBlue;
            Canvas.TextRect(R, R.Left,R.Top, LLine.Items[J].Text);
            Canvas.Pen.Color := clSkyBlue;
            Canvas.Rectangle(R);
          end;
        end;
//          Canvas.MoveTo(I * 30, I * 30);
//          Canvas.LineTo(I * 30 + Width, I * 30);
      end;
    end;
    pb_DrawLyric.Canvas.Draw(0, 0, LBuffer);
  finally
    LBuffer.Free;
  end;
end;

procedure Tfrm_Main.ResetState;
begin
  pb_DrawLyric.SetBounds(2, 0, 656, 308);
  FLyricList.Clear;
  FColNumber := 0;
end;

procedure Tfrm_Main.SetTabHide;
var
  I: Integer;
begin
  FTabIndex := 0;
  for I := pgc_Main.PageCount - 1 downto 0 do
    pgc_Main.Pages[I].TabVisible := False;
  pgc_Main.TabIndex := FTabIndex;
  pgc_Main.Pages[FTabIndex].Visible := True;
end;

procedure Tfrm_Main.ShowTabByIndex(AIndex: Integer);
var
  I: Integer;
begin
  for I := 0 to pgc_Main.PageCount - 1 do
    pgc_Main.Pages[I].Visible := False;
  if (AIndex >= 0) and (AIndex < pgc_Main.PageCount) then
  begin
    pgc_Main.TabIndex := AIndex;
    pgc_Main.Pages[AIndex].Visible := True;
  end;
end;

procedure Tfrm_Main.tmr1Timer(Sender: TObject);
begin
  if FPlaying then
    if GetMpPos > 0 then
    begin
      TrackBar1.Max := mp_Play.Length;
      TrackBar1.Position := GetMpPos;
    end;
end;

end.

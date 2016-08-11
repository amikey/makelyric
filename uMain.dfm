object frm_Main: Tfrm_Main
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = #21160#24863#27468#35789#21046#20316#24037#20855' 1.0 '#27979#35797#29256#26412
  ClientHeight = 497
  ClientWidth = 688
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object pnl_Client: TPanel
    Left = 0
    Top = 53
    Width = 688
    Height = 384
    Align = alClient
    DoubleBuffered = True
    ParentDoubleBuffered = False
    ShowCaption = False
    TabOrder = 1
    object pgc_Main: TPageControl
      Left = 1
      Top = 1
      Width = 686
      Height = 382
      ActivePage = ts_Info
      Align = alClient
      DoubleBuffered = True
      MultiLine = True
      ParentDoubleBuffered = False
      Style = tsFlatButtons
      TabOrder = 0
      object ts_Lrc: TTabSheet
        Caption = #27468#35789#32534#36753
        object mmo_Lrc: TMemo
          Left = 0
          Top = 0
          Width = 678
          Height = 351
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = #24494#36719#38597#40657
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
        end
      end
      object ts_Info: TTabSheet
        Caption = #27468#35789#20449#24687
        ImageIndex = 2
        object grp1: TGroupBox
          Left = 16
          Top = 19
          Width = 265
          Height = 126
          Caption = #27468#35789#20449#24687
          TabOrder = 0
          object lbl1: TLabel
            Left = 32
            Top = 25
            Width = 47
            Height = 13
            AutoSize = False
            Caption = #27468#25163#21517':'
          end
          object lbl2: TLabel
            Left = 32
            Top = 60
            Width = 47
            Height = 13
            AutoSize = False
            Caption = #27468#26354#21517':'
          end
          object lbl3: TLabel
            Left = 32
            Top = 94
            Width = 47
            Height = 13
            AutoSize = False
            Caption = #21046#20316#20154':'
          end
          object edt_Singer: TEdit
            Left = 88
            Top = 21
            Width = 144
            Height = 21
            TabOrder = 0
          end
          object edt_SongName: TEdit
            Left = 88
            Top = 56
            Width = 144
            Height = 21
            TabOrder = 1
          end
          object edt_EditBy: TEdit
            Left = 88
            Top = 90
            Width = 144
            Height = 21
            TabOrder = 2
          end
        end
        object grp2: TGroupBox
          Left = 310
          Top = 19
          Width = 265
          Height = 164
          Caption = #36755#20986#26684#24335#36873#39033
          TabOrder = 1
          object chk_krc: TCheckBox
            Left = 16
            Top = 24
            Width = 97
            Height = 17
            Caption = #37239#29399#38899#20048
            TabOrder = 0
          end
          object chk_qrc: TCheckBox
            Left = 16
            Top = 51
            Width = 97
            Height = 17
            Caption = 'QQ'#38899#20048
            TabOrder = 1
          end
          object chk_nrc: TCheckBox
            Left = 16
            Top = 78
            Width = 97
            Height = 17
            Caption = #32593#26131#20113#38899#20048
            TabOrder = 2
          end
          object chk_trc: TCheckBox
            Left = 16
            Top = 107
            Width = 97
            Height = 17
            Caption = #22825#22825#21160#21548
            TabOrder = 3
          end
          object chk_ksc: TCheckBox
            Left = 16
            Top = 136
            Width = 97
            Height = 17
            Caption = #23567#28784#29066#23383#24149
            TabOrder = 4
          end
        end
      end
      object ts_Make: TTabSheet
        Caption = #21046#20316#21160#24863#27468#35789
        DoubleBuffered = True
        ImageIndex = 1
        ParentDoubleBuffered = False
        object TrackBar1: TTrackBar
          Left = 3
          Top = 7
          Width = 305
          Height = 26
          ParentShowHint = False
          ShowHint = False
          ShowSelRange = False
          TabOrder = 1
          TabStop = False
          TickMarks = tmBoth
          TickStyle = tsNone
        end
        object mp_Play: TMediaPlayer
          Left = 450
          Top = 3
          Width = 85
          Height = 30
          EnabledButtons = [btPlay, btPause, btStop]
          VisibleButtons = [btPlay, btPause, btStop]
          AutoRewind = False
          Visible = False
          TabOrder = 0
          TabStop = False
        end
        object pnl_DrawBk: TPanel
          Left = 2
          Top = 39
          Width = 665
          Height = 313
          BevelKind = bkTile
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          ShowCaption = False
          TabOrder = 2
          object pb_DrawLyric: TPaintBox
            Left = 2
            Top = 0
            Width = 656
            Height = 308
            OnPaint = pb_DrawLyricPaint
          end
        end
      end
    end
  end
  object pnl3: TPanel
    Left = 0
    Top = 0
    Width = 688
    Height = 53
    Align = alTop
    TabOrder = 0
    object btn_loadmp3: TSpeedButton
      Left = 493
      Top = 10
      Width = 87
      Height = 28
      Caption = #21152#36733#38899#39057#25991#20214
      OnClick = btn_loadmp3Click
    end
    object btn_output: TSpeedButton
      Left = 586
      Top = 10
      Width = 87
      Height = 28
      Caption = #36755#20986
      OnClick = btn_OutputClick
    end
  end
  object pnl2: TPanel
    Left = 0
    Top = 437
    Width = 688
    Height = 41
    Align = alBottom
    TabOrder = 2
    object btn_Next: TSpeedButton
      Left = 586
      Top = 6
      Width = 65
      Height = 25
      Action = act_Next
    end
    object btn_Prev: TSpeedButton
      Left = 515
      Top = 6
      Width = 65
      Height = 25
      Action = act_Prev
    end
  end
  object stat1: TStatusBar
    Left = 0
    Top = 478
    Width = 688
    Height = 19
    Panels = <
      item
        Text = #20316#32773':ying32, qq:1444386932'
        Width = 50
      end>
  end
  object actlst1: TActionList
    Left = 352
    Top = 80
    object act_open: TAction
      Caption = #25171#24320'(&O)'
    end
    object act_Next: TAction
      Caption = #19979#19968#27493
      OnExecute = act_NextExecute
      OnUpdate = act_NextUpdate
    end
    object act_Prev: TAction
      Caption = #19978#19968#27493
      OnExecute = act_PrevExecute
      OnUpdate = act_PrevUpdate
    end
  end
  object dlgOpen1: TOpenDialog
    Filter = 'MP3'#25991#20214'|*.mp3'
    Left = 416
    Top = 80
  end
  object tmr1: TTimer
    Interval = 900
    OnTimer = tmr1Timer
    Left = 384
    Top = 80
  end
end

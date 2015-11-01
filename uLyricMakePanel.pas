unit uLyricMakePanel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,  System.Classes,
  Vcl.Graphics, Vcl.Controls, uLyricList;

type
  TLyricMakePanel = class(TCustomControl)
  private
    FLines: TStrings;
    FLyricList: TLyricList;
    procedure SetLines(const Value: TStrings);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
    procedure WMKeyDown(var Message: TWMKeyDown); message WM_KEYDOWN;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    property Lines: TStrings read FLines write SetLines;
    property LyricList: TLyricList read FLyricList;
  end;


implementation

{ TLyricMakePanel }

constructor TLyricMakePanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLines := TStringList.Create;
  FLyricList := TLyricList.Create;
  Canvas.Font.Size := 14;
  Canvas.Font.Name := 'Î¢ÈíÑÅºÚ';
  DoubleBuffered := True;
end;

destructor TLyricMakePanel.Destroy;
begin
  FLyricList.Free;
  FLines.Free;
  inherited;
end;

procedure TLyricMakePanel.Paint;
var
  I, J: Integer;
  R: TRect;
  LLine: TLineItem;
  LBuffer: TBitmap;
begin
  LBuffer := TBitmap.Create;
  try
    LBuffer.SetSize(Width, Height);
    for I := 0 to FLines.Count - 1 do
    begin
      for J := 1 to Length(FLines[I]) do
      begin
        R.Left := (J - 1) * 25;
        R.Top := I * 30;
        R.Width := 25;
        R.Height := 25;
        LBuffer.Canvas.Brush.Style := bsClear;
        LBuffer.Canvas.Font.Color := clBlack;
        LBuffer.Canvas.TextRect(R, R.Left,R.Top, FLines[I][J]);
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
          LBuffer.Canvas.Font.Color := clSkyBlue;
          LBuffer.Canvas.TextRect(R, R.Left,R.Top, LLine.Items[J].Text);
          LBuffer.Canvas.Pen.Color := clSkyBlue;
          LBuffer.Canvas.Rectangle(R);
        end;
      end;
    end;
    Canvas.Draw(0, 0, LBuffer);
  finally
    LBuffer.Free;
  end;
end;

procedure TLyricMakePanel.Resize;
begin
  inherited;
end;

procedure TLyricMakePanel.SetLines(const Value: TStrings);
begin
  FLines.Assign(Value);
end;

procedure TLyricMakePanel.WMEraseBkgnd(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TLyricMakePanel.WMKeyDown(var Message: TWMKeyDown);
begin
  inherited;

end;

end.

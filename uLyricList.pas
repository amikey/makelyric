unit uLyricList;

{$DEFINE DynLoadDLL}

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.DateUtils,
  System.Classes,
  System.JSON,
  System.Zlib,
  System.RegularExpressions,
  System.Generics.Collections,
  System.Types;

type
  TWordItem = class
  private
    FTime: Integer;
    FText: string;
  public
    property Time: Integer read FTime write FTime;
    property Text: string read FText write FText;
  end;

  TLineItem = class
  private
    FStartTime: Integer;
    FTimeCount: Integer;
    FItems: TObjectList<TWordItem>;
    FText: string;
    function GetCount: Integer;
    function GetItem(Index: Integer): TWordItem;
    procedure SetItem(Index: Integer; const Value: TWordItem);
  public
    constructor Create;
    destructor Destroy; override;
    function Add: TWordItem;
    procedure Clear;
  public
    property StartTime: Integer read FStartTime write FStartTime;
    property TimeCount: Integer read FTimeCount write FTimeCount;
    property Text: string read FText write FText;
    property Items[Index: Integer]: TWordItem read GetItem write SetItem;
    property Count: Integer read GetCount;
  end;

  TLyricList = class(TObject)
  private
    FLines: TObjectList<TLineItem>;
    FActor: string;
    FTotal: string;
    FTitle: string;
    FEditBy: string;
    FOffset: Integer;
    function GetCount: Integer;
    function GetLine(Index: Integer): TLineItem;
    procedure SetLine(Index: Integer; const Value: TLineItem);
  public
    constructor Create;
    destructor Destroy; override;
    function Add: TLineItem;
    procedure Clear;
  public
    property Count: Integer read GetCount;
    property Lines[Index: Integer]: TLineItem read GetLine write SetLine;
    property Actor: string read FActor write FActor; // 演员
    property Title: string read FTitle write FTitle; // 歌名
    property EditBy: string read FEditBy write FEditBy; // 歌词编辑者
    property Total: string read FTotal write FTotal; // 歌曲总时长
    property Offset: Integer read FOffset write FOffset; // 歌词偏移时间
  end;

  TLyricConvert = class(TObject)
  private
    class procedure ParseLabel(AStrs: TStrings; AList: TLyricList);
    class procedure WriteHead(AStream: TStringStream; AList: TLyricList; const ABreakLine: string);

    class procedure KRCXorStream(AStream: TMemoryStream);
    class procedure KRCDecryptStream(AStream: TMemoryStream);
    class procedure KRCEncryptStream(AStream: TMemoryStream);

    class procedure QRCDecryptStream(AStream: TMemoryStream);
    class procedure QRCEncryptStream(AStream: TMemoryStream);
  public
    class procedure ToKrc(const AList: TLyricList; const AFileName: string);
    class procedure ToQrc(const AList: TLyricList; const AFileName: string);
    class procedure ToNrc(const AList: TLyricList; const AFileName: string);
    class procedure ToTrc(const AList: TLyricList; const AFileName: string);
    class function ToLrc(const AList: TLyricList; const AFileName: string;
       ALen: Integer = 2; AIsJson: Boolean = False; AAddHead: Boolean = True): string;
    class procedure ToKsc(const AList: TLyricList; const AFileName: string);

    class procedure LoadKrc(const AFileName: string; out AList: TLyricList);
    class procedure LoadQrc(const AFileName: string; out AList: TLyricList);
    class procedure LoadNrc(const AFileName: string; out AList: TLyricList);
    class procedure LoadTrc(const AFileName: string; out AList: TLyricList);
  end;



  function MyUnixToDateTime(const AValue: Int64): TDateTime; inline;
  function MyDateTimeToUnix(const AValue: TDateTime): Int64; inline;
  function TimeToStrLable(N, Len: Integer): string; inline;

{$IFNDEF DynLoadDLL}
  procedure QQ_des(ABuffer, AKey: Pointer; ABufLen: Integer); cdecl; external 'QQMusicCommon.dll' name '?des@qqmusic@@YAHPAE0H@Z';
  procedure QQ_Ddes(ABuffer, AKey: Pointer; ABufLen: Integer); cdecl; external 'QQMusicCommon.dll' name '?Ddes@qqmusic@@YAHPAE0H@Z';
{$ENDIF}

//  function QQ_UncompressCommon(outputbuffer: Pointer; var outLen: Integer; inBuffer:Pointer; inBufLen: Integer): Integer; cdecl; external 'Common.dll' name '?UncompressCommon@qqmusic@@YAHPAEPAKPBEK@Z';
//  function QQ_CompressCommon(outputbuffer: Pointer; var outLen: Integer; inBuffer:Pointer; inBufLen: Integer): Integer; cdecl; external 'Common.dll' name '?CompressCommon@qqmusic@@YAHPAEPAKPBEK@Z';


  function QQMusicCommonIsLoaded: Boolean;

implementation

const
  //QRCMatch = 'SaveTime\=\"(?<SaveTime>[\d+]*)\"([\s\S]*?)Version\=\"(?<version>[\d+]*)\"([\s\S]*?)LyricCount\=\"(?<LyricCount>[\d+]*)\"([\s\S]*?)LyricType\=\"(?<LyricType>[\d+]*)\"([\s\S]*?)LyricContent\=\"(?<LyricContent>([\s\S]*))\"';
  QRCMatch = 'LyricContent\=\"(?<LyricContent>([\s\S]*))\"';
  UTF8Header: array[0..2] of Byte = ($EF, $BB, $BF);
  QQ_Key1: array[0..15] of Byte = ($21, $40, $23, $29, $28, $4E, $48, $4C, $69, $75, $79, $2A, $24, $25, $5E, $26);
  QQ_Key2: array[0..15] of Byte = ($31, $32, $33, $5A, $58, $43, $21, $40, $23, $29, $28, $2A, $24, $25, $5E, $26);
  QQ_Key3: array[0..15] of Byte = ($21, $40, $23, $29, $28, $2A, $24, $25, $5E, $26, $61, $62, $63, $44, $45, $46);

{$IFDEF DynLoadDLL}
type
  TQQ_des = procedure(ABuffer, AKey: Pointer; ABufLen: Integer); cdecl;
  TQQ_Ddes = procedure(ABuffer, AKey: Pointer; ABufLen: Integer); cdecl;
//  TQQ_UncompressCommon = function(outputbuffer: Pointer; var outLen: Integer; inBuffer:Pointer; inBufLen: Integer): Integer; cdecl;
//  TQQ_CompressCommon = function(outputbuffer: Pointer; var outLen: Integer; inBuffer:Pointer; inBufLen: Integer): Integer; cdecl;
var
  QQMusicDLLHandle: HMODULE = 0;
  QQ_des: TQQ_des = nil;
  QQ_Ddes: TQQ_Ddes = nil;
//  QQ_UncompressCommon: TQQ_UncompressCommon = nil;
//  QQ_CompressCommon: TQQ_CompressCommon = nil;
{$ENDIF}

function QQMusicCommonIsLoaded: Boolean;
begin
{$IFNDEF DynLoadDLL}
  Result := True;
{$ELSE}
  Result := QQMusicDLLHandle > 0;
{$ENDIF}
end;



// ckey1 = '!@#)(NHLiuy*$%^&';
// ckey2 = '123ZXC!@#)(*$%^&';
// ckey3 = '!@#)(*$%^&abcDEF';
// 加密
// des(buffer, key1, 0)
// Ddes(buffer, key2, 0)
// des(buffer, key3, 0)

// 解密
// Ddes(buffer, key3, 0)
// des(buffer, key2, 0)
// Ddes(buffer, key1, 0)


function BetweenOf(const AStr, ASubStr1, ASubStr2: string):string;
var
  P1, P2:Integer;
begin
  Result := '';
  P1 := Pos(ASubStr1, AStr);
  if P1 > 0 then
  begin
    P2 := Pos(ASubStr2, AStr, P1 + Length(ASubStr1) + 1);
    if P2 > 0 then
      Result := Copy(AStr, P1 + Length(ASubStr1), P2 - P1 - Length(ASubStr1));
  end;
end;

function StringToTime(const ATimeStr: string): Integer; //文本到毫秒
var
  LStrArr: TArray<string>;
  Int1, Int2, Int3: Integer;
begin
  Result := 0;
  LStrArr := ATimeStr.Replace('.', ':').Replace('[', '').Replace(']', '').Split([':']);
  if Length(LStrArr) = 3 then
  begin
    Int1 := StrToIntDef(LStrArr[0], 0);
    Int2 := StrToIntDef(LStrArr[1], 0);
    Int3 := StrToIntDef(LStrArr[2], 0);
    Result := ((Int1 * 60) + Int2) * 1000 + (Int3 * 10);
  end;
end;

function TimeToStrLable(N, Len: Integer): string;
begin
  Result := Format('%.2d:%.2d.%s', [N div 1000 div 60, N div 1000 mod 60, Copy(IntToStr(N mod 1000) + '00', 1, Len)]);
end;

function MyUnixToDateTime(const AValue: Int64): TDateTime;
begin
  Result := IncHour(System.DateUtils.UnixToDateTime(AValue), 8);
end;

function MyDateTimeToUnix(const AValue: TDateTime): Int64;
begin
  Result := System.DateUtils.DateTimeToUnix(AValue) - 28800;
end;

procedure ParseQRCLine(const ALineStr: string; AList: TLyricList);
var
  P1, PStart, PEnd: Integer;
  LineStr, TimeLabel: string;
  LLine  : TLineItem;
  LWord: TWordItem;
begin
  LineStr := ALineStr;
  P1 := Pos(']', LineStr);
  TimeLabel := Copy(LineStr, 1, P1);

  LLine := AList.Add;
  LLine.StartTime := StrToIntDef(BetweenOf(TimeLabel, '[', ','), 0);
  LLine.TimeCount   := StrToIntDef(BetweenOf(TimeLabel, ',', ']'), 0);
  LLine.Text := '';

  PEnd := 1;
  PStart := 1;
  LineStr := Copy(LineStr, P1 + 1, Length(LineStr) - 1);
  while PEnd <= Length(LineStr) do
  begin
    if LineStr[PEnd] = '(' then
    begin
      LWord := LLine.Add;
      LWord.Text := Copy(LineStr, PStart, PEnd - PStart);
      LLine.Text := LLine.Text + LWord.Text;
      PStart := Pos(')', LineStr, PEnd + 1) + 1;
      TimeLabel := Copy(LineStr, PEnd, PStart - PEnd); // 包含 ( )
      // 解析时间标签
      LWord.Time := StrToIntDef(BetweenOf(TimeLabel, ',', ')'), 0);
      PEnd := PStart;
    end;
    Inc(PEnd);
  end;

end;

procedure ParseNRCLine(const ALineStr: string; AList: TLyricList);
var
  P1, PStart, PEnd, J: Integer;
  LineStr, TimeLabel: string;
  LLine  : TLineItem;
  LWord: TWordItem;
begin
  LineStr := ALineStr;
  P1 := Pos(']', LineStr);
  TimeLabel := Copy(LineStr, 1, P1);

  LLine := AList.Add;
  LLine.StartTime := StrToIntDef(BetweenOf(TimeLabel, '[', ','), 0);
  LLine.TimeCount := StrToIntDef(BetweenOf(TimeLabel, ',', ']'), 0);
  LLine.Text := '';

  J := 1;
  LineStr := Copy(LineStr, P1 + 1, Length(LineStr) - 1);
  while J <= Length(LineStr) do
  begin
    if LineStr[J] = '(' then
    begin
      PStart := Pos(')', LineStr, J + 1) + 1;
      TimeLabel := Copy(LineStr, J, PStart - J); // 包含 < >
      LWord := LLine.Add;
      // 解析时间标签
      LWord.Time := StrToIntDef(BetweenOf(TimeLabel, ',', ')'), 0);
      PEnd := Pos('(', LineStr , PStart + 1);
      if (PEnd = 0) and (PStart <> 0) then
        LWord.Text := Copy(LineStr, PStart, Length(LineStr) - PStart + 1)
      else
        LWord.Text := Copy(LineStr, PStart, PEnd - PStart);
      LLine.Text := LLine.Text + LWord.Text;
      J := PStart;
    end;
    Inc(J);
  end;
end;

procedure ParseTRCLine(const ALineStr: string; AList: TLyricList);
var
  P1, PStart, PEnd, J: Integer;
  LineStr, TimeLabel: string;
  LLine  : TLineItem;
  LWord: TWordItem;
begin
  if ALineStr.Contains('[00:00.001]') or ALineStr.Contains('[00:00.009]') or
     ALineStr.Contains('[99:00.000]') or ALineStr.Contains('[99:00.100]') then
    Exit;
  LineStr := ALineStr;

  P1 := Pos(']', LineStr); // #93 = ]
  TimeLabel := Copy(LineStr, 1, P1);

  LLine := AList.Add;
  LLine.StartTime := StringToTime(TimeLabel);
  LLine.TimeCount := 0;
  LLine.Text := '';

  J := 1;
  LineStr := Copy(LineStr, P1 + 1, Length(LineStr) - 1);
  while J <= Length(LineStr) do
  begin
    // Parser Faild. Clear List;
    if AList.Count > 300 then
    begin
      AList.Clear;
      Exit;
    end;
    if LineStr[J] = '<' then
    begin
      PStart := Pos('>', LineStr, J + 1) + 1;
      TimeLabel := Copy(LineStr, J, PStart - J); // 包含 < >
      LWord := LLine.Add;
      // 解析时间标签
      LWord.Time := StrToIntDef(BetweenOf(TimeLabel, '<', '>'), 0);
      LLine.TimeCount := LLine.TimeCount + LWord.Time;
      // 行长度
      PEnd := Pos('<', LineStr , PStart + 1);
      if (PEnd = 0) and (PStart <> 0) then
        LWord.Text := Copy(LineStr, PStart, Length(LineStr) - PStart + 1)
      else
        LWord.Text := Copy(LineStr, PStart, PEnd - PStart);
      LLine.Text := LLine.Text + LWord.Text;
      J := PStart;
    end;
    Inc(J);
  end;
end;

procedure ParseKRCLine(const ALineStr: string; AList: TLyricList);
var
  P1, PStart, PEnd, J: Integer;
  LineStr, TimeLabel: string;
  LLine  : TLineItem;
  LWord: TWordItem;
begin
  LineStr := ALineStr;
  P1 := Pos(']', LineStr);
  TimeLabel := Copy(LineStr, 1, P1);

  LLine := AList.Add;
  LLine.StartTime := StrToIntDef(BetweenOf(TimeLabel, '[', ','), 0);
  LLine.TimeCount := StrToIntDef(BetweenOf(TimeLabel, ',', ']'), 0);
  LLine.Text := '';

  J := 1;
  LineStr := Copy(LineStr, P1 + 1, Length(LineStr) - 1);
  while J <= Length(LineStr) do
  begin
    if LineStr[J] = '<' then
    begin
      PStart := Pos('>', LineStr, J + 1) + 1;
      TimeLabel := Copy(LineStr, J, PStart - J); // 包含 < >
      LWord := LLine.Add;
      // 解析时间标签
      LWord.Time := StrToIntDef(BetweenOf(TimeLabel, ',', ','), 0);
      PEnd := Pos('<', LineStr , PStart + 1);
      if (PEnd = 0) and (PStart <> 0) then
        LWord.Text := Copy(LineStr, PStart, Length(LineStr) - PStart + 1)
      else
        LWord.Text := Copy(LineStr, PStart, PEnd - PStart);
      LLine.Text := LLine.Text + LWord.Text;
      J := PStart;
    end;
    Inc(J);
  end;
end;





{ TLineItem }

function TLineItem.Add: TWordItem;
begin
  Result := TWordItem.Create;
  FItems.Add(Result);
end;

procedure TLineItem.Clear;
begin
  FItems.Clear;
end;

constructor TLineItem.Create;
begin
  inherited Create;
  FItems := TObjectList<TWordItem>.Create;
end;

destructor TLineItem.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TLineItem.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TLineItem.GetItem(Index: Integer): TWordItem;
begin
  Result := FItems[Index];
end;

procedure TLineItem.SetItem(Index: Integer; const Value: TWordItem);
begin
  FItems[Index] := Value;
end;

{ TLyricList }

function TLyricList.Add: TLineItem;
begin
  Result := TLineItem.Create;
  FLines.Add(Result);
end;

procedure TLyricList.Clear;
begin
  FLines.Clear;
end;

constructor TLyricList.Create;
begin
  inherited Create;
  FLines := TObjectList<TLineItem>.Create;
end;

destructor TLyricList.Destroy;
begin
  FLines.Free;
  inherited;
end;

function TLyricList.GetCount: Integer;
begin
  Result := FLines.Count;
end;

function TLyricList.GetLine(Index: Integer): TLineItem;
begin
  Result := FLines[Index];
end;

procedure TLyricList.SetLine(Index: Integer; const Value: TLineItem);
begin
  FLines[Index] := Value;
end;


{ TLyricConvert }

class procedure TLyricConvert.KRCDecryptStream(AStream: TMemoryStream);
const
   KrcHead: array[0..3] of byte = ($6B, $72, $63, $31);
var
 XorStream: TMemoryStream;
 Utf8Header: array[0..2] of Byte;
 KRCFlags: array[0..3] of Byte;
 XorBytes: array of Byte;
begin
  AStream.Position := 0;
  FillChar(KRCFlags, SizeOf(KRCFlags), #0);
  AStream.Read(KRCFlags[0], Length(KRCFlags));
  if CompareMem(@KRCFlags[0], @KrcHead[0], Length(KRCFlags)) then
  begin
    SetLength(XorBytes, AStream.Size - 4);
    // 减4为了减去头部的 krc1 标识
    AStream.Read(XorBytes[0],  Length(XorBytes));
    XorStream := TMemoryStream.Create;
    try
      XorStream.Write(XorBytes[0], Length(XorBytes));
      KRCXorStream(XorStream);
      AStream.Clear;
      ZDecompressStream(XorStream, AStream);
      FillChar(Utf8Header, SizeOf(Utf8Header), 0);
      AStream.Position := 0;
    finally
      XorStream.Free;
    end;
  end;
end;

class procedure TLyricConvert.KRCEncryptStream(AStream: TMemoryStream);
var
  XorStream, ZipStream: TMemoryStream;
const
  KrcHead: array[0..3] of byte = ($6B, $72, $63, $31);
begin
  XorStream := TMemoryStream.Create;
  try
    //Writeln(Format('%.2x, %.2x, %.2x', [PByte(AStream.Memory)^, PByte(Cardinal(AStream.Memory) + 1)^, PByte(Cardinal(AStream.Memory) + 2)^]));
    XorStream.Write(UTF8Header[0], Length(UTF8Header));
    XorStream.Write(AStream.Memory^, AStream.Size);
    ZipStream := TMemoryStream.Create;
    try
      XorStream.Position := 0;
      ZCompressStream(XorStream, ZipStream, zcMax);
      KRCXorStream(ZipStream);
      AStream.Clear;
      AStream.Write(KrcHead[0], Length(KrcHead));
      AStream.Write(ZipStream.Memory^, ZipStream.Size);
      AStream.Position := 0;
    finally
      ZipStream.Free;
    end;
  finally
    XorStream.Free;
  end;
end;

class procedure TLyricConvert.KRCXorStream(AStream: TMemoryStream);
var
  EncodedBytes, ZipBytes:array of Byte; //编码字节
  BytesLength: Integer;
  I, L:integer;
const
  EncKey: array[0..15] of byte = ($40, $47, $61, $77, $5E, $32, $74, $47,
                                  $51, $36, $31, $2D, $CE, $D2, $6E, $69);
begin
  AStream.Position := 0;
  BytesLength := AStream.Size;
  SetLength(EncodedBytes, BytesLength);
  SetLength(ZipBytes, BytesLength);
  AStream.Read(EncodedBytes[0], BytesLength);
  for I := 0 to BytesLength - 1 do
  begin
    L := I mod 16;
    ZipBytes[i] := EncodedBytes[i] xor EncKey[L];
  end;
  AStream.Clear; //清除以前的流
  AStream.Write(ZipBytes[0], BytesLength); //将异或后的字节集写入原流中
  AStream.Position := 0;
end;

class procedure TLyricConvert.LoadKrc(const AFileName: string;
  out AList: TLyricList);
var
  LStream: TStringStream;
  LStrs: TStringList;
  S: string;
begin
  LStream := TStringStream.Create('', TEncoding.UTF8);
  try
    LStream.LoadFromFile(AFileName);
    KRCDecryptStream(LStream);
    LStrs := TStringList.Create;
    try
      LStrs.Text := LStream.DataString;
      ParseLabel(LStrs, AList);
      for S in LStrs do
      begin
        if (S[1] = '[') and CharInSet(S[2], ['0'..'9']) then
          ParseKRCLine(S, AList);
      end;
    finally
      LStrs.Free;
    end;
  finally
    LStream.Free;
  end;
end;

class procedure TLyricConvert.LoadNrc(const AFileName: string;
  out AList: TLyricList);
var
  LJSON: TJSONValue;
  LStrs: TStringList;
  LStream: TStringStream;
  LString: string;
begin
  LStream := TStringStream.Create('', TEncoding.UTF8);
  try
    LStream.LoadFromFile(AFileName);
    LJSON := TJSONObject.ParseJSONValue(LStream.DataString);
    if Assigned(LJSON) then
    begin
      try
        LStrs := TStringList.Create;
        try
          if LJSON.TryGetValue<string>('klyric.lyric', LString) then
          begin
            LStrs.Text := LString;
            ParseLabel(LStrs, AList);
            for LString in LStrs do
            begin
              if (LString[1] = '[') and CharInSet(LString[2], ['0'..'9']) then
                ParseNRCLine(LString, AList);
            end;
            //Writeln(LStrs.Count);
          end;
        finally
          LStrs.Free;
        end;
      finally
        LJSON.Free;
      end;
    end;
  finally
    LStream.Free;
  end;
end;

class procedure TLyricConvert.LoadQrc(const AFileName: string;
  out AList: TLyricList);
var
  LStream: TStringStream;
  LStrs: TStringList;
  LMatch: TMatch;
  S: string;
begin
  if not QQMusicCommonIsLoaded then Exit;
  LStream := TStringStream.Create('', TEncoding.UTF8);
  try
    LStream.LoadFromFile(AFileName);
    QRCDecryptStream(LStream);
    LStrs := TStringList.Create;
    try
      LStrs.Text := LStream.DataString;
      LMatch := TRegEx.Match(LStrs.Text, QRCMatch, [roIgnoreCase, roMultiLine]);
      if LMatch.Success then
      begin
        LStrs.Text := LMatch.Groups.Item['LyricContent'].Value;
        ParseLabel(LStrs, AList);
        for S in LStrs do
        begin
          if (S[1] = '[') and CharInSet(S[2], ['0'..'9']) then
            ParseQRCLine(S, AList);
        end;
      end;
    finally
      LStrs.Free;
    end;
  finally
    LStream.Free;
  end;
end;

class procedure TLyricConvert.LoadTrc(const AFileName: string;
  out AList: TLyricList);
var
  LStrs: TStringList;
  S: string;
begin
  LStrs := TStringList.Create;
  try
    LStrs.LoadFromFile(AFileName);
    ParseLabel(LStrs, AList);
    for S in LStrs do
    begin
      if (S[1] = '[') and CharInSet(S[2], ['0'..'9']) then
        ParseTRCLine(S, AList);
    end;
  finally
    LStrs.Free;
  end;
end;

class procedure TLyricConvert.ParseLabel(AStrs: TStrings; AList: TLyricList);
var
  S: string;
  I: Integer;
begin
  I := 0;
  for S in AStrs do
  begin
    if S.Length < 2 then Continue;
    if S.Contains('[ar:') then
      AList.Actor := BetweenOf(S, 'ar:', ']')
    else if S.Contains('[ti:') then
      AList.Title := BetweenOf(S, 'ti:', ']')
    else if S.Contains('[by:') then
      AList.EditBy := BetweenOf(S, '[by:', ']')
    else if S.Contains('[offset:') then
      AList.Offset := StrToIntDef(BetweenOf(S, 'offset:', ']'), 0)
    else if S.Contains('[total:') then
      AList.Total := BetweenOf(S, 'total:', ']');
    if (S[1] = '[') and CharInSet(S[2], ['0'..'9']) then
      Break;
    Inc(I);
  end;
  while I > 0 do
  begin
    AStrs.Delete(0);
    Dec(I);
  end;
end;

class procedure TLyricConvert.QRCDecryptStream(AStream: TMemoryStream);
const
  NewQRCHead : array[0..7] of Byte = ($5B, $6F, $66, $66, $73, $65, $74, $3A);
var
//  TEMP: Pointer;
  Bytes, OutBytes: TBytes;
//  I, OutLen, LRet: Integer;
begin
  if CompareMem(AStream.Memory, @NewQRCHead[0], Length(NewQRCHead)) then
  begin
    // 头10个? 第11个是 $10 暂不清楚为何物
    AStream.Position := 11;
    SetLength(Bytes, AStream.Size - 11);
    AStream.Read(Bytes[0], Length(Bytes));
    QQ_Ddes(@Bytes[0], @QQ_Key1[0], Length(Bytes));
    QQ_des (@Bytes[0], @QQ_Key2[0], Length(Bytes));
    QQ_Ddes(@Bytes[0], @QQ_Key3[0], Length(Bytes));
//    OutLen := Length(Bytes) * $10;
    ZDecompress(Bytes, OutBytes);
    AStream.Clear;
    AStream.Write(OutBytes, 0, Length(OutBytes));
    AStream.Position := 0;
//    Writeln('OutBytes Len = ', Length(OutBytes));
{$REGION '使用QQ库解压'}
(*
    GetMem(TEMP, 1);
    try
      I := 1;
      LRet := 0;
      repeat
        if I > 5 then Break;
        ReallocMem(TEMP, OutLen);
        LRet := QQ_UncompressCommon(TEMP, OutLen, @Bytes[0], Length(Bytes));
        Inc(I);
      until LRet <> -5;
      AStream.Clear;
      AStream.Write(TEMP^, OutLen);
      AStream.Write(OutBytes, 0, Length(OutBytes));
      AStream.Position := 0;
    finally
      if TEMP <> nil then FreeMem(TEMP);
    end;
*)
{$ENDREGION '使用QQ库解压'}
  end;
end;

class procedure TLyricConvert.QRCEncryptStream(AStream: TMemoryStream);
const
 NewQRCHead: array[0..10] of Byte = ($5B, $6F, $66, $66, $73, $65, $74, $3A, $30, $5D, $0A);
var
//  TEMP: Pointer;
//  OutLen, LRet: Integer;
//  I: Integer;
  inBytes, outBytes: TBytes;
begin
  SetLength(inBytes, AStream.Size);
  Move(AStream.Memory^, inBytes[0], Length(inBytes));
  ZCompress(inBytes, outBytes);
//  Writeln('OutBytes Len = ', Length(outBytes));
  QQ_des (@outBytes[0], @QQ_Key3[0], Length(outBytes));
  QQ_Ddes(@outBytes[0], @QQ_Key2[0], Length(outBytes));
  QQ_des (@outBytes[0], @QQ_Key1[0], Length(outBytes));
  AStream.Clear;
  AStream.Write(NewQRCHead[0], Length(NewQRCHead));
  AStream.Write(outBytes[0], Length(outBytes) + 4);
  AStream.Position := 0;
{$REGION 'QQ压缩'}
//  OutLen := $BB00;
//  GetMem(TEMP, OutLen);
//  if TEMP <> nil then
//  begin
//    I := 1;
//    try
//      LRet := 0;
//      repeat
//        if I > 5 then Break;
//        LRet := QQ_CompressCommon(TEMP, OutLen, AStream.Memory, AStream.Size);
//        if OutLen <> $BB00 then
//          ReallocMem(TEMP, OutLen);
//        Inc(I);
//      until LRet <> -5;
//      Writeln('write=', lret, '  outlen=', outlen);
//      QQ_des (TEMP, @QQ_Key3[0], OutLen);
//      QQ_Ddes(TEMP, @QQ_Key2[0], OutLen);
//      QQ_des (TEMP, @QQ_Key1[0], OutLen);
//      AStream.Clear;
//      AStream.Write(NewQRCHead[0], Length(NewQRCHead));
//      AStream.Write(TEMP^, OutLen + 4); //? 原何要加8
//      AStream.Position := 0;
//    finally
//      FreeMem(TEMP);
//    end;
//  end;
{$ENDREGION}
end;

class procedure TLyricConvert.ToKrc(const AList: TLyricList;
  const AFileName: string);
var
  LLine: TLineItem;
  LWord: TWordItem;
  I, J, M: Integer;
  StrStream: TStringStream;
begin
  StrStream := TStringStream.Create('', TEncoding.UTF8);
  try
    //StrStream.WriteString(Format('[id:$%.8x]'#13#10'[ti:%s]'#13#10'[ar:%s]'#13#10'[by:%s]'#13#10'[total:%s]'#13#10'[offset:%d]'#13#10,
    //    [0, AList.Title, AList.Actor, AList.EditBy, AList.Total, AList.Offset]));
    StrStream.WriteString('[id:$00000000'#13#10);
    WriteHead(StrStream, AList, #13#10);
    for I := 0 to AList.Count - 1 do
    begin
      LLine := AList.Lines[I];
      StrStream.WriteString(Format('[%d,%d]', [LLine.StartTime, LLine.TimeCount]));
      M := 0;
      for J := 0 to LLine.Count - 1 do
      begin
        LWord := LLine.Items[J];
        StrStream.WriteString(Format('<%d,%d,0>%s', [M, LWord.Time, LWord.Text]));
        M := M + LWord.Time;
        // krc = <time<首行为0>, time, 0>str
      end;
      StrStream.WriteString(sLineBreak);
    end;
    KRCEncryptStream(StrStream);
    StrStream.SaveToFile(AFileName);
  finally
    StrStream.Free;
  end;
end;

class procedure TLyricConvert.ToKsc(const AList: TLyricList;
  const AFileName: string);
var
  LLine: TLineItem;
  LWord: TWordItem;
  I, J: Integer;
  StrStream: TStringStream;
  S: string;

  procedure WriteStr(const AStr: string);
  begin
    StrStream.WriteString(AStr + #13#10);
  end;
begin
  StrStream := TStringStream.Create('', TEncoding.UTF8);
  try
    WriteStr('karaoke := CreateKaraokeObject;');
    WriteStr('karaoke.rows := 2;');
    WriteStr('karaoke.clear;');
    WriteStr('karaoke.transparentcolor := rgb(0, 255, 0);');
    WriteStr(Format('karaoke.TimeOffset := %d;', [AList.Offset]));
    WriteStr(Format('karaoke.singer := ''%s'';', [AList.Actor]));
    WriteStr(Format('karaoke.songname := ''%s'';', [AList.Title]));
    for I := 0 to AList.Count - 1 do
    begin
      LLine := AList.Lines[I];
      S := '';
      for J := 0 to LLine.Count - 1 do
      begin
        LWord := LLine.Items[J];
        S := S + LWord.Time.ToString + ',';
      end;
      Delete(S, Length(S), 1);
      WriteStr(Format('karaoke.add(''%s'',''%s'',''%s'', ''%s'');', [
                TimeToStrLable(LLine.StartTime, 3),
                TimeToStrLable(LLine.StartTime + LLine.TimeCount, 3),
                StringReplace(LLine.Text, #39, #39#39, [rfReplaceAll]),
                S]));
    end;
    StrStream.SaveToFile(AFileName);
  finally
    StrStream.Free;
  end;
end;

class procedure TLyricConvert.ToNrc(const AList: TLyricList;
  const AFileName: string);
var
  LLine: TLineItem;
  LWord: TWordItem;
  I, J: Integer;
  StrStream: TStringStream;
begin
  StrStream := TStringStream.Create('', TEncoding.UTF8);
  try
    StrStream.WriteString('{"lrc":{"version":13,"lyric":"');
    StrStream.WriteString(ToLrc(AList, '', 3, True, False));
    StrStream.WriteString('"},"klyric":{"version":2,"lyric":"'); // 8056827@网易云音乐 [#:http://music.163.com/#/song?id=103879]
    //StrStream.WriteString(Format('[ti:%s]\n[ar:%s]\n[by:%s]\n', [AList.Title, AList.Actor, AList.EditBy]));
    WriteHead(StrStream, AList, '\n');
    for I := 0 to AList.Count - 1 do
    begin
      LLine := AList.Lines[I];
      StrStream.WriteString(Format('[%d,%d]', [LLine.StartTime, LLine.TimeCount]));
      for J := 0 to LLine.Count - 1 do
      begin
        LWord := LLine.Items[J];
        StrStream.WriteString(Format('(0,%d)%s', [LWord.Time, LWord.Text]));
        // nrc = (0, time)str
      end;
      StrStream.WriteString('\n');
    end;
    StrStream.WriteString('"},"tlyric":{"version":0,"lyric":null},"sgc":false,"qfy":false,"sfy":false,"code":200}');
    StrStream.SaveToFile(AFileName);
  finally
    StrStream.Free;
  end;
end;

class procedure TLyricConvert.ToQrc(const AList: TLyricList;
  const AFileName: string);
var
  LLine: TLineItem;
  LWord: TWordItem;
  I, J, M: Integer;
  StrStream: TStringStream;
begin
  if not QQMusicCommonIsLoaded then Exit;
  StrStream := TStringStream.Create('', TEncoding.UTF8);
  try
    StrStream.WriteString('<?xml version="1.0" encoding="utf-8"?>'#13#10);
    StrStream.WriteString('<QrcInfos>'#13#10);
    StrStream.WriteString(Format('<QrcHeadInfo SaveTime="%d" Version="100"/>'#13#10, [MyDateTimeToUnix(Now)]));
    StrStream.WriteString('<LyricInfo LyricCount="1">'#13#10);
    StrStream.WriteString('<Lyric_1 LyricType="1" LyricContent="');
    WriteHead(StrStream, AList, #13#10);
    //StrStream.WriteString(Format('[ti:%s]'#13#10'[ar:%s]'#13#10'[by:%s]'#13#10'[offset:%d]'#13#10,
    //    [AList.Title, AList.Actor, AList.EditBy, AList.Offset]));
    for I := 0 to AList.Count - 1 do
    begin
      LLine := AList.Lines[I];
      StrStream.WriteString(Format('[%d,%d]', [LLine.StartTime, LLine.TimeCount]));
      M := LLine.StartTime;
      for J := 0 to LLine.Count - 1 do
      begin
        LWord := LLine.Items[J];
        StrStream.WriteString(Format('%s(%d,%d)', [LWord.Text, M, LWord.Time]));
        M := M + LWord.Time;
        // qrc = str(LineStart + Lasttime<首行为0>, time)
      end;
      StrStream.WriteString(sLineBreak);
    end;
    StrStream.WriteString('"/>'#13#10);
    StrStream.WriteString('</LyricInfo>'#13#10);
    StrStream.WriteString('</QrcInfos>'#13#10);
    QRCEncryptStream(StrStream);
    StrStream.SaveToFile(AFileName);
  finally
    StrStream.Free;
  end;
end;

class procedure TLyricConvert.ToTrc(const AList: TLyricList;
  const AFileName: string);
var
  LLine: TLineItem;
  LWord: TWordItem;
  I, J: Integer;
  StrStream: TStringStream;
begin
  StrStream := TStringStream.Create('', TEncoding.UTF8);
  try
    WriteHead(StrStream, AList, #10);
    //StrStream.WriteString(Format('[ti:%s]'#10'[ar:%s]'#10'[by:%s]'#10'[total:%s]'#10,
    //    [AList.Title, AList.Actor, AList.EditBy, AList.Total]));
    for I := 0 to AList.Count - 1 do
    begin
      LLine := AList.Lines[I];
      StrStream.WriteString(Format('[%s]', [TimeToStrLable(LLine.StartTime, 2)]));
      for J := 0 to LLine.Count - 1 do
      begin
        LWord := LLine.Items[J];
        StrStream.WriteString(Format('<%d>%s', [LWord.Time, LWord.Text]));
        // trc = <time>str
      end;
      StrStream.WriteString(#10);
    end;
    StrStream.WriteString('[00:00.001]好音质,天天动听!'#10'[00:00.009]'#10'[99:00.000]'#10'[99:00.100]好音质,天天动听!');
    StrStream.SaveToFile(AFileName);
  finally
    StrStream.Free;
  end;
end;

class procedure TLyricConvert.WriteHead(AStream: TStringStream; AList: TLyricList; const ABreakLine: string);
begin
  if not AList.Title.IsEmpty then
    AStream.WriteString(Format('[ti:%s]%s', [AList.Title, ABreakLine]));
  if not AList.Actor.IsEmpty then
    AStream.WriteString(Format('[ar:%s]%s', [AList.Actor, ABreakLine]));
  if not AList.EditBy.IsEmpty then
    AStream.WriteString(Format('[by:%s]%s', [AList.EditBy, ABreakLine]));
  if not AList.Total.IsEmpty then
    AStream.WriteString(Format('[total:%s]%s', [AList.Total, ABreakLine]));
  if AList.Offset <> 0 then
    AStream.WriteString(Format('[offset:%d]%s', [AList.Offset, ABreakLine]));
end;

class function TLyricConvert.ToLrc(const AList: TLyricList;
  const AFileName: string; ALen: Integer; AIsJson: Boolean; AAddHead: Boolean): string;
var
  LLine: TLineItem;
  I: Integer;
  StrStream: TStringStream;
begin
  Result := '';
  StrStream := TStringStream.Create('', TEncoding.UTF8);
  try
    if AAddHead then
    begin
      //StrStream.WriteString(Format('[ti:%s]'#13#10'[ar:%s]'#13#10'[by:%s]'#13#10'[total:%s]'#13#10,
      //  [AList.Title, AList.Actor, AList.EditBy, AList.Total]));
      WriteHead(StrStream, AList, #13#10);
    end;
    for I := 0 to AList.Count - 1 do
    begin
      LLine := AList.Lines[I];
      StrStream.WriteString(Format('[%s]%s', [TimeToStrLable(LLine.StartTime, ALen), LLine.Text]));
      if AIsJson then
        StrStream.WriteString('\n')
      else
        StrStream.WriteString(sLineBreak);
    end;
    if StrStream.Size <> 0 then
    begin
      if AFileName.IsEmpty then
        Result := StrStream.DataString
      else
        StrStream.SaveToFile(AFileName);
    end;
  finally
    StrStream.Free;
  end;
end;

{$IFDEF DynLoadDLL}
procedure LoadQQMusicDLL;
begin
  QQMusicDLLHandle := SafeLoadLibrary('QQMusicCommon.dll');
  if QQMusicDLLHandle <> 0 then
  begin
    @QQ_des := GetProcAddress(QQMusicDLLHandle, LPCWSTR('?des@qqmusic@@YAHPAE0H@Z'));
    @QQ_Ddes := GetProcAddress(QQMusicDLLHandle, LPCWSTR('?Ddes@qqmusic@@YAHPAE0H@Z'));
//    @QQ_UncompressCommon := GetProcAddress(MemoryDLLHandle, LPCWSTR('?UncompressCommon@qqmusic@@YAHPAEPAKPBEK@Z'));
//    @QQ_CompressCommon := GetProcAddress(MemoryDLLHandle, LPCWSTR('?CompressCommon@qqmusic@@YAHPAEPAKPBEK@Z'));
  end;
end;

initialization
  LoadQQMusicDLL;

finalization
  if QQMusicDLLHandle <> 0 then
    FreeLibrary(QQMusicDLLHandle);
{$ENDIF}


end.

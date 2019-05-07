unit StrLib;
(*
  DESCRIPTION: Strings processing
  AUTHOR:      Alexander Shostak (aka Berserker aka EtherniDee aka BerSoft)
*)

(***)  interface  (***)
uses Windows, Math, SysUtils, Classes, StrUtils, Utils;

const
  (* ExplodeEx *)
  INCLUDE_DELIM = TRUE;
  LIMIT_TOKENS  = TRUE;

  BINARY_CHARACTERS: set of char = [#0..#8, #11..#12, #14..#31];

  PATH_DELIMS = ['\', '/'];

  (* Windows 7+ *)
  // Translate any Unicode characters that do not translate directly to multibyte equivalents to the default character specified by lpDefaultChar
  WC_NO_BEST_FIT_CHARS = $00000400;

  // Raise error on invalid character for ansi page
  WC_ERR_INVALID_CHARS = $80;

  FAIL_ON_ERROR = true;

type
  (* IMPORT *)
  TArrayOfStr  = Utils.TArrayOfStr;

  TTrimSide  = (LEFT_SIDE, RIGHT_SIDE);
  TTrimSides = set of LEFT_SIDE..RIGHT_SIDE;

  PListItem = ^TListItem;
  TListItem = record
          Data:     array of char;
          DataSize: integer;
    {On}  NextItem: PListItem;
  end; // .record TListItem
  
  IStrBuilder = interface
    procedure Append (const Str: string);
    procedure AppendBuf (BufSize: integer; {n} Buf: pointer);
    procedure WriteByte (Value: byte);
    procedure WriteWord (Value: word);
    procedure WriteInt (Value: integer);
    function  BuildStr: string;
    function  BuildBuf: TArrayOfByte;
    procedure Clear;
  end; // .interface IStrBuilder

  TStrBuilder = class (TInterfacedObject, IStrBuilder)
   protected
    const
      MIN_BLOCK_SIZE = 65536;

    var
      {On} fRootItem: PListItem;
      {Un} fCurrItem: PListItem;
           fSize:     integer;

   public
    destructor  Destroy; override;
    procedure Append (const Str: string);
    procedure AppendBuf (BufSize: integer; {n} Buf: pointer);
    procedure WriteByte (Value: byte);
    procedure WriteWord (Value: word);
    procedure WriteInt (Value: integer);
    function  BuildStr: string;
    function  BuildBuf: TArrayOfByte;
    procedure Clear;

    property  Size: integer read fSize;
  end; // .class TStrBuilder

  IByteSource = interface
    (* Reads up to specified number of bytes to buffer. Returns number of actually read bytes *)
    function Read (Count: integer; {Un} Buf: pointer): integer;
  end;

  TStrByteSource = class (TInterfacedObject, IByteSource)
   protected
    fData:    string;
    fDataLen: integer;
    fPos:     integer;

   public
    constructor Create (const Data: string);
    
    function Read (Count: integer; {Un} Buf: pointer): integer;
  end; // .TStrByteSource

  TBufByteSource = class (TInterfacedObject, IByteSource)
   protected
    {Un} fBuf:     pointer;
         fBufSize: integer;
         fPos:     integer;

   public
    constructor Create ({Un} Buf: pointer; BufSize: integer);
    
    function Read (Count: integer; {Un} Buf: pointer): integer;
  end; // .TBufByteSource

  IByteMapper = interface
    function GetSource: IByteSource;
    function ReadInt: integer;
    function ReadStr (StrLen: integer): string;
    function ReadStrWithLenField (StrLenFieldSize: integer): string;
  end;

  (* All methods assert reading success *)
  TByteMapper = class (TInterfacedObject, IByteMapper)
   protected
    fByteSource: IByteSource;

   public
    constructor Create (ByteSource: IByteSource);

    function GetSource: IByteSource;
    function ReadInt: integer;
    function ReadStr (StrLen: integer): string;
    function ReadStrWithLenField (StrLenFieldSize: integer): string;
  end; // .TByteMapper

function  MakeStr: IStrBuilder;
function  StrAsByteSource (const Str: string): IByteSource;
function  BufAsByteSource ({Un} Buf: pointer; BufSize: integer): IByteSource;
function  MapBytes (ByteSource: IByteSource): IByteMapper;
function  InStrBounds (Pos: integer; const Str: string): boolean;
function  BytesToAnsiString (PBytes: PBYTE; NumBytes: integer): AnsiString;
function  BytesToWideString (PBytes: PBYTE; NumBytes: integer): WideString;
function  FindChar (Ch: char; const Str: string; out CharPos: integer): boolean;
function  FindCharEx (Ch: char; const Str: string; StartPos: integer; out CharPos: integer): boolean;
function  ReverseFindCharEx (Ch: char; const Str: string; StartPos: integer; out CharPos: integer): boolean;
function  ReverseFindChar (Ch: char; const Str: string; out CharPos: integer): boolean;
function  FindCharW (Ch: WideChar; const Str: WideString; out CharPos: integer): boolean;
function  FindCharExW (Ch: WideChar; const Str: WideString; StartPos: integer; out CharPos: integer): boolean;
function  FindCharsetEx (Charset:  Utils.TCharSet; const Str: string; StartPos: integer; out CharPos: integer): boolean;
function  FindCharset (Charset: Utils.TCharSet; const Str: string; out CharPos: integer): boolean;

(* Both FindSubstr routines are wrappers around Delphi Pos function *)
function  FindSubstrEx (const Substr, Str: string; StartPos: integer; out SubstrPos: integer): boolean;

function  FindSubstr (const Substr, Str: string; out SubstrPos: integer): boolean;

(*
  Knuth-Morris-Pratt stable speed fast search algorithm.
  F('', Haystack, StartPos in range of Haystack) => true, StartPos
  F('', Haystack, StartPos out of range of Haystack) => false
*)
function  FindStr (const Needle, Haystack: string; out FoundPos: integer): boolean;

function  FindStrEx (const Needle, Haystack: string; Pos: integer; out FoundPos: integer): boolean;

(*
  f('') => NIL
  f(Str, '') => [Str]
*)
function  ExplodeEx (const Str, Delim: string; InclDelim: boolean; LimitTokens: boolean; MaxTokens: integer): TArrayOfStr;
function  Explode (const Str: string; const Delim: string): TArrayOfStr;
function  Join (const Arr: TArrayOfStr; const Glue: string): string;

(*
  TemplArgs - pairs of (ArgName, ArgValue).
  Example: f('Hello, ~UserName~. You are ~Years~ years old.', ['Years', '20', 'UserName', 'Bob'], '~') =>
  => 'Hello, Bob. You are 20 years old'.
*)
function  BuildStr (const Template: string; TemplArgs: array of string; TemplChar: char): string;
function  CharsetToStr (const Charset: Utils.TCharSet): string;
function  IntToRoman (Value: integer): string;
function  CharToLower (c: char): char;
function  CharToUpper (c: char): char;
function  Capitalize (const Str: string): string;
function  HexCharToByte (HexChar: char): byte;
function  ByteToHexChar (ByteValue: byte): char;
function  Concat (const Strings: array of string): string;

(* Base file name does not include extension. *)
function  TrimEx (const Str: string; const TrimCharSet: Utils.TCharSet; TrimSides: TTrimSides = [LEFT_SIDE, RIGHT_SIDE]): string;

function  ExtractBaseFileName (const FilePath: string): string;
function  SubstrBeforeChar (const Str: string; Ch: char): string;
function  Match (const Str, Pattern: string): boolean;
function  MatchW (const Str, Pattern: WideString): boolean;
function  ExtractFromPchar (Str: pchar; Count: integer): string;
function  BufToStr ({n} Buf: pointer; BufSize: integer): string;

(*) Detects characters in the BINARY_CHARACTERS set *)
function  IsBinaryStr (const Str: string): boolean;

function  Utf8ToAnsi (const Str: string): string;
function  PWideCharToAnsi (const Str: PWideChar; out Res: string; FailOnError: boolean = false): boolean;

(* Converts null-terminated WideString to AnsiString, substituting invalid characters with special character *)
function  WideToAnsiSubstitute (const Str: WideString): string;

function  WideStringFromBuf ({n} Buf: PWideChar; NumChars: integer = -1): WideString;
function  WideStringToBuf (const Str: WideString; Buf: PWideChar): PWideChar;
function  WideLowerCase (const Str: WideString): WideString;
function  ExcludeTrailingDelimW (const Str: WideString; {n} HadTrailingDelim: pboolean = nil): WideString;
function  ExtractDirPathW (const Path: WideString): WideString;
function  ExtractFileNameW (const Path: WideString): WideString;
function  CompareWideChars (Str1Ptr, Str2Ptr: PWideChar; Len: integer = -1): integer;
function  CompareBinStringsW (const Str1, Str2: WideString): integer;


(***) implementation (***)


destructor TStrBuilder.Destroy;
begin
  Self.Clear;
end; // .destructor TStrBuilder.Destroy

procedure TStrBuilder.Append (const Str: string);
begin
  Self.AppendBuf(Length(Str), pointer(Str));
end;

procedure TStrBuilder.AppendBuf (BufSize: integer; {n} Buf: pointer);
var
  LeftPartSize:  integer;
  RightPartSize: integer;
  
begin
  {!} Assert(Utils.IsValidBuf(Buf, BufSize));
  if BufSize > 0 then begin
    if Self.fRootItem = nil then begin
      New(Self.fRootItem);
      Self.fCurrItem := Self.fRootItem;
      SetLength(Self.fCurrItem.Data, Math.Max(BufSize, Self.MIN_BLOCK_SIZE));
      Self.fCurrItem.DataSize := 0;
      Self.fCurrItem.NextItem := nil;
    end;
    
    LeftPartSize  := Math.Min(BufSize, Length(Self.fCurrItem.Data) - Self.fCurrItem.DataSize);
    RightPartSize := BufSize - LeftPartSize;
    
    if LeftPartSize > 0 then begin
      Utils.CopyMem(LeftPartSize, Buf, @Self.fCurrItem.Data[Self.fCurrItem.DataSize]);
    end;
    
    Self.fCurrItem.DataSize := Self.fCurrItem.DataSize + LeftPartSize;
    
    if RightPartSize > 0 then begin
      New(Self.fCurrItem.NextItem);
      Self.fCurrItem := Self.fCurrItem.NextItem;
      SetLength(Self.fCurrItem.Data, Math.Max(RightPartSize, Self.MIN_BLOCK_SIZE));
      Self.fCurrItem.DataSize := RightPartSize;
      Self.fCurrItem.NextItem := nil;
      Utils.CopyMem(RightPartSize, Utils.PtrOfs(Buf, LeftPartSize), @Self.fCurrItem.Data[0]);
    end;
    
    Self.fSize := Self.fSize + BufSize;
  end; // .if
end; // .procedure TStrBuilder.AppendBuf

procedure TStrBuilder.WriteByte (Value: byte);
begin
  Self.AppendBuf(sizeof(Value), @Value);
end;

procedure TStrBuilder.WriteWord (Value: word);
begin
  Self.AppendBuf(sizeof(Value), @Value);
end;

procedure TStrBuilder.WriteInt (Value: integer);
begin
  Self.AppendBuf(sizeof(Value), @Value);
end;

function TStrBuilder.BuildStr: string;
var
{U} CurrItem: PListItem;
    Pos:      integer;

begin
  CurrItem := Self.fRootItem;
  // * * * * * //
  SetLength(result, Self.fSize);
  Pos := 0;
  
  while CurrItem <> nil do begin
    Utils.CopyMem(CurrItem.DataSize, @CurrItem.Data[0], Utils.PtrOfs(pointer(result), Pos));
    Pos      := Pos + CurrItem.DataSize;
    CurrItem := CurrItem.NextItem;
  end;
end; // .function TStrBuilder.BuildStr

function TStrBuilder.BuildBuf: TArrayOfByte;
var
{U} CurrItem: PListItem;
    Pos:      integer;

begin
  CurrItem := Self.fRootItem;
  // * * * * * //
  SetLength(result, Self.fSize);
  Pos := 0;
  
  while CurrItem <> nil do begin
    Utils.CopyMem(CurrItem.DataSize, @CurrItem.Data[0], Utils.PtrOfs(pointer(result), Pos));
    Pos      := Pos + CurrItem.DataSize;
    CurrItem := CurrItem.NextItem;
  end;
end; // .function TStrBuilder.BuildBuf

procedure TStrBuilder.Clear;
var
{Un}  CurrItem: PListItem;
{Un}  NextItem: PListItem;
  
begin
  CurrItem := Self.fRootItem;
  NextItem := nil;
  // * * * * * //
  while CurrItem <> nil do begin
    NextItem := CurrItem.NextItem;
    Dispose(CurrItem);
    CurrItem := NextItem;
  end;
  
  Self.fRootItem := nil;
  Self.fCurrItem := nil;
  Self.fSize     := 0;
end; // .procedure TStrBuilder.Clear

constructor TStrByteSource.Create (const Data: string);
begin
  inherited Create;
  fData    := Data;
  fDataLen := length(Data);
  fPos     := 0;
end;

function TStrByteSource.Read (Count: integer; {Un} Buf: pointer): integer;
begin
  {!} Assert(Utils.IsValidBuf(Buf, Count));

  if Count = 0 then begin
    result := 0;
  end else begin
    result := Min(Count, fDataLen - fPos);

    if result > 0 then begin
      Utils.CopyMem(Count, @fData[fPos + 1], Buf);
      inc(fPos, result);
    end;
  end;
end; // .function TStrByteSource.Read

constructor TBufByteSource.Create ({Un} Buf: pointer; BufSize: integer);
begin
  {!} Assert(Utils.IsValidBuf(Buf, BufSize));
  
  inherited Create;
  
  fBuf     := Buf;
  fBufSize := BufSize;
  fPos     := 0;
end;

function TBufByteSource.Read (Count: integer; {Un} Buf: pointer): integer;
begin
  {!} Assert(Utils.IsValidBuf(Buf, Count));

  if Count = 0 then begin
    result := 0;
  end else begin
    result := Min(Count, fBufSize - fPos);

    if result > 0 then begin
      Utils.CopyMem(Count, Utils.PtrOfs(fBuf, fPos), Buf);
      inc(fPos, result);
    end;
  end;
end; // .function TBufByteSource.Read

constructor TByteMapper.Create (ByteSource: IByteSource);
begin
  inherited Create;
  fByteSource := ByteSource;
end;

function TByteMapper.GetSource: IByteSource;
begin
  result := fByteSource;
end;

function TByteMapper.ReadInt: integer;
begin
  {!} Assert(fByteSource.Read(sizeof(integer), @result) = sizeof(integer));
end;

function TByteMapper.ReadStr (StrLen: integer): string;
begin
  {!} Assert(StrLen >= 0);
  SetLength(result, StrLen);

  if StrLen > 0 then begin
    {!} Assert(fByteSource.Read(StrLen, @result[1]) = StrLen);
  end;
end;

function TByteMapper.ReadStrWithLenField (StrLenFieldSize: integer): string;
var
  StrLen: integer;

begin
  {!} Assert(StrLenFieldSize in [1, 2, 4, sizeof(integer)]);
  StrLen := 0;
  result := '';
  {!} Assert(fByteSource.Read(StrLenFieldSize, @StrLen) = StrLenFieldSize);
  {!} Assert(StrLen >= 0);

  if StrLen > 0 then begin
    SetLength(result, StrLen);
    {!} Assert(fByteSource.Read(StrLen, @result[1]) = StrLen);
  end;
end; // .function TByteMapper.ReadStrWithLenField

function MakeStr: IStrBuilder;
begin
  result := TStrBuilder.Create;
end;

function StrAsByteSource (const Str: string): IByteSource;
begin
  result := TStrByteSource.Create(Str);
end;

function BufAsByteSource ({Un} Buf: pointer; BufSize: integer): IByteSource;
begin
  result := TBufByteSource.Create(Buf, BufSize);
end;

function MapBytes (ByteSource: IByteSource): IByteMapper;
begin
  result := TByteMapper.Create(ByteSource);
end;

function InStrBounds (Pos: integer; const Str: string): boolean;
begin
  result := Math.InRange(Pos, 1, Length(Str));
end;

function BytesToAnsiString (PBytes: PBYTE; NumBytes: integer): AnsiString;
begin
  {!} Assert(PBytes <> nil);
  {!} Assert(NumBytes >= 0);
  SetLength(result, NumBytes);
  Utils.CopyMem(NumBytes, PBytes, pointer(result));
end;

function BytesToWideString (PBytes: PBYTE; NumBytes: integer): WideString;
begin
  {!} Assert(PBytes <> nil);
  {!} Assert(NumBytes >= 0);
  {!} Assert(Utils.EVEN(NumBytes));
  SetLength(result, NumBytes shr 1);
  Utils.CopyMem(NumBytes, PBytes, pointer(result));
end;

function FindCharEx (Ch: char; const Str: string; StartPos: integer; out CharPos: integer): boolean;
var
  StrLen: integer;
  i:      integer;

begin
  StrLen := Length(Str);
  result := Math.InRange(StartPos, 1, StrLen);
  
  if result then begin
    i :=  StartPos;
    
    while (i <= StrLen) and (Str[i] <> Ch) do begin
      Inc(i);
    end;
    
    result := i <= StrLen;
    
    if result then begin
      CharPos :=  i;
    end;
  end;
end; // .function FindCharEx

function ReverseFindCharEx
(
        Ch:       char;
  const Str:      string;
        StartPos: integer;
  out   CharPos:  integer
): boolean;

var
  StrLen: integer;
  i:      integer;

begin
  StrLen := Length(Str);
  result := Math.InRange(StartPos, 1, StrLen);
  
  if result then begin
    i :=  StartPos;
    
    while (i >= 1) and (Str[i] <> Ch) do begin
      Dec(i);
    end;
    
    result := i >= 1;
    
    if result then begin
      CharPos :=  i;
    end;
  end;
end; // .function ReverseFindCharEx

function FindChar (Ch: char; const Str: string; out CharPos: integer): boolean;
begin
  result := FindCharEx(Ch, Str, 1, CharPos);
end;

function ReverseFindChar (Ch: char; const Str: string; out CharPos: integer): boolean;
begin
  result := ReverseFindCharEx(Ch, Str, Length(Str), CharPos);
end;

function FindCharExW (Ch: WideChar; const Str: WideString; StartPos: integer; out CharPos: integer): boolean;
var
  CharPtr: PWideChar;
  StrLen:  integer;

begin
  CharPtr := nil;
  // * * * * * //
  StrLen := Length(Str);
  result := Math.InRange(StartPos, 1, StrLen);
  
  if result then begin
    CharPtr := PWideChar(Str) + (StartPos - 1);

    while (CharPtr^ <> #0) and (CharPtr^ <> Ch) do begin
      Inc(CharPtr);
    end;
    
    result := CharPtr^ <> #0;

    if result then begin
      CharPos := (CharPtr - PWideChar(Str)) + 1;
    end;
  end; // .if
end; // .function FindCharExW

function FindCharW (Ch: WideChar; const Str: WideString; out CharPos: integer): boolean;
begin
  result := FindCharExW(Ch, Str, 1, CharPos);
end;

function FindCharsetEx (Charset: Utils.TCharSet; const Str: string; StartPos: integer; out CharPos: integer): boolean;
var
  StrLen: integer;
  i:      integer;

begin
  {!} Assert(StartPos >= 1);
  StrLen := Length(Str);
  result := StartPos <= StrLen;
  if result then begin
    i :=  StartPos;
    while (i <= StrLen) and not (Str[i] in Charset) do begin
      Inc(i);
    end;
    result := i <= StrLen;
    if result then begin
      CharPos :=  i;
    end;
  end;
end; // .function FindCharsetEx

function FindCharset (Charset: Utils.TCharSet; const Str: string; out CharPos: integer): boolean;
begin
  result := FindCharsetEx(Charset, Str, 1, CharPos);
end;

function FindSubstrEx (const Substr, Str: string; StartPos: integer; out SubstrPos: integer): boolean;
var
  Pos: integer;

begin
  Pos := StrUtils.PosEx(Substr, Str, StartPos);

  if Pos <> 0 then begin
    SubstrPos := Pos;
    result    := true;
  end else begin
    result    := false;
  end;
end; // .function FindSubstrEx

function FindSubstr (const Substr, Str: string; out SubstrPos: integer): boolean;
begin
  result := FindSubstrEx(Substr, Str, 1, SubstrPos);
end;

function FindStrEx (const Needle, Haystack: string; Pos: integer; out FoundPos: integer): boolean;
const
  MAX_STATIC_FALLBACK_TABLE_LEN = 255;
  START_STRING_POS              = 1;

var
{O} FallbackTableBuf:          PEndlessIntArr;
    FallbackTableStackStorage: array [0..MAX_STATIC_FALLBACK_TABLE_LEN] of integer;
{U} FallbackTable:             PEndlessIntArr;
  
    NeedleLen:               integer;
    HaystackLen:             integer;
    FirstNeedleChar:         char;
    FirstFourNeedleChars:    integer;
    FarthestStartPos:        integer; // Last pos where there is any sense to start searching
    FallbackPos:             integer;
    HaystackPtr:             pinteger;
    HaystackEndMinusFourPtr: pinteger;
    i:                       integer;

  procedure GenerateFallbackTable;
  var
    k: integer;

  begin
    // Initialize fallback table pointer to either stack storage or memory buffer
    if NeedleLen <= MAX_STATIC_FALLBACK_TABLE_LEN then begin
      FallbackTable := @FallbackTableStackStorage[0];
    end else begin
      GetMem(FallbackTableBuf, (NeedleLen + 1) * sizeof(integer));
      FallbackTable := FallbackTableBuf;
    end;

    // First not matched char always redirect to start, starting analysis from the the second one
    FallbackTable[START_STRING_POS] := START_STRING_POS;
    k                               := START_STRING_POS + 1;

    while k <= NeedleLen do begin
      // Search for the next occurense of needle prefix in the needle itself
      repeat
        FallbackTable[k] := START_STRING_POS;
        Inc(k);
      until (k > NeedleLen) or (Needle[k - 1] = FirstNeedleChar);

      // First char is already checked, starting from the second one
      i := START_STRING_POS + 1;

      if k <= NeedleLen then begin
        // While characters match needle prefix, fallback offsets grow
        // ab[abababab]c[ab]d
        // 11[12345678]1[12]1
        repeat
          FallbackTable[k] := i;
          Inc(i);
          Inc(k);
        until (k > NeedleLen) or (Needle[i] <> Needle[k]);
      end;
    end; // .while
  end; // .procedure GenerateFallbackTable

  procedure FindFirstNeedleChars;
  begin
    if Pos <= FarthestStartPos then begin
      HaystackPtr := @Haystack[Pos];

      while (cardinal(HaystackPtr) <= cardinal(HaystackEndMinusFourPtr)) and
            (HaystackPtr^ <> FirstFourNeedleChars)
      do begin
        Inc(pbyte(HaystackPtr));
      end;

      i := START_STRING_POS + sizeof(integer);

      if cardinal(HaystackPtr) <= cardinal(HaystackEndMinusFourPtr) then begin
        Pos := Pos + (integer(HaystackPtr) - integer(@Haystack[Pos])) + sizeof(integer);
      end else begin
        Pos := MAXINT;
      end;
    end; // .if
  end; // .procedure FindFirstNeedleChars

begin
  FallbackTableBuf := nil;
  FallbackTable    := nil;
  // * * * * * //
  if Pos < START_STRING_POS then begin
    Pos := START_STRING_POS;
  end;

  NeedleLen        := Length(Needle);
  HaystackLen      := Length(Haystack);
  FarthestStartPos := HaystackLen - NeedleLen + 1;
  result           := (Pos <= FarthestStartPos) and (HaystackLen > 0);
  
  if result then begin
    if NeedleLen = 0 then begin
      FoundPos := START_STRING_POS;
    end else if NeedleLen <= sizeof(integer) then begin
      result := FindSubstrEx(Needle, Haystack, Pos, FoundPos);
    end else begin
      FirstNeedleChar         := Needle[START_STRING_POS];
      FirstFourNeedleChars    := pinteger(@Needle[START_STRING_POS])^;
      HaystackEndMinusFourPtr := @Haystack[HaystackLen - sizeof(integer) + 1];
      GenerateFallbackTable;

      i := START_STRING_POS;
      FindFirstNeedleChars;

      while (Pos <= HaystackLen) and (i <= NeedleLen) do begin
        if Haystack[Pos] = Needle[i] then begin
          Inc(Pos);
          Inc(i);
        end else begin
          FallbackPos := FallbackTable[i];

          if FallbackPos = START_STRING_POS then begin
            FindFirstNeedleChars;
          end else begin
            i := FallbackPos;
          end;
        end; // .else
      end; // .while

      result := i > NeedleLen;

      if result then begin
        FoundPos := Pos - NeedleLen;
      end;
    end; // .else
  end; // .if
  // * * * * * //
  FreeMem(FallbackTableBuf);
end; // .function FindStrEx

function FindStr (const Needle, Haystack: string; out FoundPos: integer): boolean;
begin
  result := FindStrEx(Needle, Haystack, 1, FoundPos);
end;

function ExplodeEx (const Str, Delim: string; InclDelim: boolean; LimitTokens: boolean; MaxTokens: integer): TArrayOfStr;
var
(* O *) DelimPosList:   Classes.TList {OF INTEGER};
        StrLen:         integer;
        DelimLen:       integer;
        DelimPos:       integer;
        DelimsLimit:    integer;
        NumDelims:      integer;
        TokenStartPos:  integer;
        TokenEndPos:    integer;
        TokenLen:       integer;
        i:              integer;

begin
  {!} Assert(not LimitTokens or (MaxTokens > 0));
  DelimPosList := Classes.TList.Create;
  result       := nil;
  // * * * * * //
  StrLen   := Length(Str);
  DelimLen := Length(Delim);
  
  if StrLen > 0 then begin
    if not LimitTokens then begin
      MaxTokens := MAXLONGINT;
    end;

    if DelimLen = 0 then begin
      SetLength(result, 1);
      result[0] := Str;
    end else begin
      DelimsLimit := MaxTokens - 1;
      NumDelims   := 0;
      DelimPos    := 1;
      
      while (NumDelims < DelimsLimit) and FindSubstrEx(Delim, Str, DelimPos, DelimPos) do begin
        DelimPosList.Add(pointer(DelimPos));
        Inc(DelimPos);
        Inc(NumDelims);
      end;
      
      DelimPosList.Add(pointer(StrLen + 1));
      SetLength(result, NumDelims + 1);
      TokenStartPos := 1;
      
      for i := 0 to NumDelims do begin
        TokenEndPos := integer(DelimPosList[i]);
        TokenLen    := TokenEndPos - TokenStartPos;
        
        if InclDelim and (i < NumDelims) then begin
          TokenLen := TokenLen + DelimLen;
        end;
        
        result[i]     := Copy(Str, TokenStartPos, TokenLen);
        TokenStartPos := TokenStartPos + DelimLen + TokenLen - ord(InclDelim);
      end; // .for
    end; // .else
  end; // .if
  // * * * * * //
  SysUtils.FreeAndNil(DelimPosList);
end; // .function ExplodeEx

function Explode (const Str: string; const Delim: string): TArrayOfStr;
begin
  result := ExplodeEx(Str, Delim, not INCLUDE_DELIM, not LIMIT_TOKENS, 0);
end;

function Join (const Arr: TArrayOfStr; const Glue: string): string;
var
(* U *) Mem:        pointer;
        ArrLen:     integer;
        GlueLen:    integer;
        NumPairs:   integer;
        ResultSize: integer;
        i:          integer;

begin
  Mem    := nil;
  result := '';
  // * * * * * //
  ArrLen  := Length(Arr);
  GlueLen := Length(Glue);
  
  if ArrLen > 0 then begin
    NumPairs   := ArrLen - 1;
    ResultSize := 0;
    
    for i := 0 to ArrLen - 1 do begin
      ResultSize := ResultSize + Length(Arr[i]);
    end;
    
    ResultSize := ResultSize + NumPairs * GlueLen;
    SetLength(result, ResultSize);
    Mem := pointer(result);
    
    if GlueLen = 0 then begin
      for i := 0 to NumPairs - 1 do begin
        Utils.CopyMem(Length(Arr[i]), pointer(Arr[i]), Mem);
        Mem :=  Utils.PtrOfs(Mem, Length(Arr[i]));
      end;
    end else begin
      for i := 0 to NumPairs - 1 do begin
        Utils.CopyMem(Length(Arr[i]), pointer(Arr[i]), Mem);
        Mem :=  Utils.PtrOfs(Mem, Length(Arr[i]));
        Utils.CopyMem(Length(Glue), pointer(Glue), Mem);
        Mem :=  Utils.PtrOfs(Mem, Length(Glue));
      end;
    end; // .else
    
    Utils.CopyMem(Length(Arr[NumPairs]), pointer(Arr[NumPairs]), Mem);
  end; // .if
end; // .function Join

function BuildStr (const Template: string; TemplArgs: array of string; TemplChar: char): string;
var
  TemplTokens:    TArrayOfStr;
  NumTemplTokens: integer;
  NumTemplSlots:  integer;
  NumTemplArgs:   integer;
  i:              integer;

  function GetParam (const ParamName: string): string;
  var
    j: integer;

  begin
    j := 0;

    while (j < NumTemplArgs) do begin
      if TemplArgs[j] = ParamName then begin
        result := TemplArgs[j + 1];
        exit;
      end;

      inc(j, 2);
    end;
    
    result := TemplChar + ParamName + TemplChar;
  end; // .function GetParam

begin
  NumTemplArgs := Length(TemplArgs);
  {!} Assert(Utils.Even(NumTemplArgs));
  result := '';
  // * * * * * //
  if NumTemplArgs = 0 then begin
    result := Template;
  end else begin
    TemplTokens    := Explode(Template, TemplChar);
    NumTemplTokens := Length(TemplTokens);
    NumTemplSlots  := (NumTemplTokens - 1) div 2;

    if NumTemplSlots = 0 then begin
      result := Template;
    end else begin
      i := 1;

      while (i < NumTemplTokens) do begin
        TemplTokens[i] := GetParam(TemplTokens[i]);
        inc(i, 2);
      end;
      
      result := StrLib.Join(TemplTokens, '');
    end; // .else
  end; // .else
end; // .function BuildStr

function CharsetToStr (const Charset: Utils.TCharSet): string;
const
  CHARSET_CAPACITY  = 256;
  SPACE_PER_ITEM    = 3;
  DELIMETER         = ', ';
  DELIM_LEN         = Length(DELIMETER);

var
(* U *) BufPos:       ^char;
        Buffer:       array [0..(SPACE_PER_ITEM * CHARSET_CAPACITY + DELIM_LEN * (CHARSET_CAPACITY - 1)) - 1] of char;
        BufSize:      integer;
        StartItemInd: integer;
        FinitItemInd: integer;
        RangeLen:     integer;
        
  procedure WriteItem (c: char);
  begin
    if ORD(c) < ORD(' ') then begin
      BufPos^ :=  '#';                            Inc(BufPos);
      BufPos^ :=  CHR(ORD(c) div 10 + ORD('0'));  Inc(BufPos);
      BufPos^ :=  CHR(ORD(c) mod 10 + ORD('0'));  Inc(BufPos);
    end else begin
      BufPos^ :=  '"';  Inc(BufPos);
      BufPos^ :=  c;    Inc(BufPos);
      BufPos^ :=  '"';  Inc(BufPos);
    end;
    Inc(BufSize, SPACE_PER_ITEM);
  end; // .procedure WriteItem

begin
  BufPos := @Buffer[0];
  // * * * * * //
  BufSize      := 0;
  StartItemInd := 0;
  
  while StartItemInd < CHARSET_CAPACITY do begin
    if chr(StartItemInd) in Charset then begin
      if BufSize > 0 then begin
        BufPos^ :=  DELIMETER[1]; Inc(BufPos);
        BufPos^ :=  DELIMETER[2]; Inc(BufPos);
        Inc(BufSize, DELIM_LEN);
      end;
      
      FinitItemInd := StartItemInd + 1;
      
      while (FinitItemInd < CHARSET_CAPACITY) and (chr(FinitItemInd) in Charset) do begin
        Inc(FinitItemInd);
      end;
      
      RangeLen := FinitItemInd - StartItemInd;
      WriteItem(chr(StartItemInd));
      
      if RangeLen > 1 then begin
        if RangeLen > 2 then begin
          BufPos^ :=  '-';
          Inc(BufPos);
          Inc(BufSize);
        end;
        
        WriteItem(chr(FinitItemInd - 1));
      end;
      
      StartItemInd := FinitItemInd;
    end else begin
      Inc(StartItemInd);
    end; // .else
  end; // .while
  
  SetLength(result, BufSize);
  Utils.CopyMem(BufSize, @Buffer[0], pointer(result));
end; // .function CharsetToStr

function IntToRoman (Value: integer): string;
const
  Arabics:  array [0..12] of integer  = (1, 4, 5, 9, 10, 40, 50, 90, 100, 400, 500, 900, 1000);
  Romans:   array [0..12] of string   = ('I', 'IV', 'V', 'IX', 'X', 'XL', 'L', 'XC', 'C', 'CD', 'D', 'CM', 'M');

var
  i:  integer;

begin
  {!} Assert(Value > 0);
  result := '';
  
  for i := 12 downto 0 do begin
    while Value >= Arabics[i] do begin
      Value  := Value - Arabics[i];
      result := result + Romans[i];
    end;
  end;
end; // .function IntToRoman

function CharToLower (c: char): char;
begin
  result := chr(integer(Windows.CharLower(Ptr(ORD(c)))));
end;

function CharToUpper (c: char): char;
begin
  result := chr(integer(Windows.CharUpper(Ptr(ORD(c)))));
end;

function Capitalize (const Str: string): string;
begin
  result := Str;

  if result <> '' then begin
    result[1] := CharToUpper(result[1]);
  end;
end;

function HexCharToByte (HexChar: char): byte;
begin
  HexChar :=  CharToLower(HexChar);
  
  if HexChar in ['0'..'9'] then begin
    result := ORD(HexChar) - ORD('0');
  end else if HexChar in ['a'..'f'] then begin
    result := ORD(HexChar) - ORD('a') + 10;
  end else begin
    result := 0;
    {!} Assert(FALSE);
  end;
end; // .function HexCharToByte

function ByteToHexChar (ByteValue: byte): char;
begin
  {!} Assert(Math.InRange(ByteValue, $00, $0F));
  
  if ByteValue < 10 then begin
    result := CHR(ByteValue + ORD('0'));
  end else begin
    result := CHR(ByteValue - 10 + ORD('A'));
  end;
end;

function Concat (const Strings: array of string): string;
var
  ResLen: integer;
  Offset: integer;
  StrLen: integer;
  i:      integer;

begin
  ResLen := 0;
  
  for i := 0 to High(Strings) do begin
    ResLen := ResLen + Length(Strings[i]);
  end;
  
  SetLength(result, ResLen);
  
  Offset := 0;
  
  for i := 0 to High(Strings) do begin
    StrLen := Length(Strings[i]);
    
    if StrLen > 0 then begin
      Utils.CopyMem(StrLen, pointer(Strings[i]), Utils.PtrOfs(pointer(result), Offset));
      Offset := Offset + StrLen;
    end;
  end;
end; // .function Concat

function TrimEx (const Str: string; const TrimCharSet: Utils.TCharSet; TrimSides: TTrimSides = [LEFT_SIDE, RIGHT_SIDE]): string;
var
  StrLen: integer;
  Left:   integer;
  Right:  integer;

begin
  result := '';

  if Str <> '' then begin
    StrLen := length(Str);
    Left   := 1;
    Right  := StrLen;

    if LEFT_SIDE in TrimSides then begin
      while (Left <= Right) and (Str[Left] in TrimCharSet) do begin
        inc(Left);
      end;
    end;

    if (RIGHT_SIDE in TrimSides) and (Left <= Right) then begin
      while (Right >= 1) and (Str[Right] in TrimCharSet) do begin
        dec(Right);
      end;
    end;

    if Left <= Right then begin
      result := Copy(Str, Left, Right - Left + 1);
    end;
  end; // .if
end; // .function TrimEx

function ExtractBaseFileName (const FilePath: string): string;
var
  DotPos: integer;

begin
  result := SysUtils.ExtractFileName(FilePath);
  
  if ReverseFindChar('.', result, DotPos) then begin
    SetLength(result, DotPos - 1);
  end;
end; // .function ExtractBaseFileName

function SubstrBeforeChar (const Str: string; Ch: char): string;
var
  CharPos:  integer;

begin
  if FindChar(Ch, Str, CharPos) then begin
    result := COPY(Str, 1, CharPos - 1);
  end else begin
    result := Str;
  end;
end; // .function SubstrBeforeChar

function Match (const Str, Pattern: string): boolean;
const
  ONE_SYM_WILDCARD  = '?';
  ANY_SYMS_WILDCARD = '*';
  WILDCARDS         = [ONE_SYM_WILDCARD, ANY_SYMS_WILDCARD];

type
  TState  =
  (
    STATE_STRICT_COMPARE,       // [abc]*?*?**cde?x*
    STATE_SKIP_WILDCARDS,       // abc[*?*?**]cde?x*
    STATE_FIRST_LETTER_SEARCH,  // abc*?*?**[c]de?x*
    STATE_MATCH_SUBSTR_TAIL,    // abc*?*?**c[de?x]*
    STATE_EXIT
  );

(*
  Non-greedy algorithm tries to treat ANY_SYMS_WILLCARD as the shortest possible string.
  Token is a substring between Base position and ANY_SYMS_WILLCARD or end of string in the template
  and corresponding matching substring in the string.
  
  Match "abcecd78e" against "a*cd*e": (Token is wrapped in parenthesis)
  
  (abcecd78e)
  (a*cd*e)
  
  => STRICT_COMPARE until * (success)
  
  (a  )(bcecd78e)
  (a* )(cd*e)
  
  => FIRST_LETTER_SEARCH "c" (success)
  
  (ab )(cecd78e)
  (a* )(cd*e)
  
  => MATCH_SUBSTR_TAIL "d" (fail)
  
  (abc)(ecd78e)
  (a* )(cd*e)
  
  => FIND_FIRST_LETTER "c" (success)
  
  (abce)(cd78e)
  (a*  )(cd*e)
  
  => MATCH_SUBSTR_TAIL "d" (success)
  
  (abce)(cd  )(78e)
  (a*  )(cd* )(e)
  
  => FIND_FIRST_LETTER "e" (success)
  
  (abce)(cd78)(e)
  (a*  )(cd* )(e)
  
  => exit
*)

(*
  Contracts for states:
    STATE_STRICT_COMPARE:
      - Entry state, not-reenterable
      - Matches character-to-character, including ONE_SYM_WILLCARD
      - Exits on mismatch
      - => STATE_SKIP_WILDCARDS
    STATE_SKIP_WILDCARDS:
      - Skips sequence of WILDCARDS
      - Increases position in the string for each ONE_SYM_WILDCARD
      - Exits on end of pattern
      - Initializes character "c" to current pattern character
      - => STATE_FIRST_LETTER_SEARCH
    STATE_FIRST_LETTER_SEARCH
      - Character [c] must be initialized before entering
      - Searches for character [c] in the string
      - Exits on end of string
      - Sets New token positions for string and token to current positions
      - => STATE_MATCH_SUBSTR_TAIL
    STATE_MATCH_SUBSTR_TAIL:
      - Matches character-to-character, including ONE_SYM_WILLCARD
      - Exits on end of string
      - Increases current token position in string by 1 and roll-backs to tokens positions in
        string and template on end of template or last character mismatch
      - => STATE_SKIP_WILDCARDS
*)
  
var
  State:          TState;
  StrLen:         integer;
  PatternLen:     integer;
  StrBasePos:     integer;  // Start position of current token
  PatternBasePos: integer;  // Start position of current token
  s:              integer;  // Pos in Pattern
  p:              integer;  // Pos in Str
  c:              char;     // First letter to search for

  procedure SkipMatchingSubstr;
  begin
    while
      (p <= PatternLen)                 and
      (s <= StrLen)                     and
      (Pattern[p] <> ANY_SYMS_WILDCARD) and
      (
        (Str[s]     = Pattern[p]) or
        (Pattern[p] = ONE_SYM_WILDCARD)
      )
    do begin
      Inc(p);
      Inc(s);
    end; // .while
  end; // .procedure SkipMatchingSubstr

begin
  StrLen         := Length(Str);
  PatternLen     := Length(Pattern);
  StrBasePos     := 1;
  PatternBasePos := 1;
  s              := 1;
  p              := 1;
  c              := #0;
  State          := STATE_STRICT_COMPARE;
  result         := FALSE;
  
  while State <> STATE_EXIT do begin
    case State of 
      STATE_STRICT_COMPARE:
        begin
          SkipMatchingSubstr;
          
          if (p > PatternLen) or (Pattern[p] <> ANY_SYMS_WILDCARD) then begin
            State :=  STATE_EXIT;
          end else begin
            STATE :=  STATE_SKIP_WILDCARDS;
          end;
        end; // .case STATE_STRICT_COMPARE
        
      STATE_SKIP_WILDCARDS:
        begin
          while (p <= PatternLen) and (Pattern[p] in WILDCARDS) do begin
            if Pattern[p] = ONE_SYM_WILDCARD then begin
              Inc(s);
            end;
            
            Inc(p);
          end;
          
          if p <= PatternLen then begin
            c     := Pattern[p];
            State := STATE_FIRST_LETTER_SEARCH;
          end else begin
            if s <= StrLen then begin
              s := StrLen + 1;
            end;
          
            State := STATE_EXIT;
          end;
        end; // .case STATE_SKIP_WILDCARDS
        
      STATE_FIRST_LETTER_SEARCH:
        begin
          while (s <= StrLen) and (Str[s] <> c) do begin
            Inc(s);
          end;
          
          if s > StrLen then begin
            State := STATE_EXIT;
          end else begin
            StrBasePos     := s;
            PatternBasePos := p;
            Inc(p);
            Inc(s);
            State          := STATE_MATCH_SUBSTR_TAIL;
          end;
        end; // .case STATE_FIRST_LETTER_SEARCH
        
      STATE_MATCH_SUBSTR_TAIL:
        begin
          SkipMatchingSubstr;
          
          if (p > PatternLen) or (Pattern[p] = ANY_SYMS_WILDCARD) then begin
            State := STATE_STRICT_COMPARE;
          end else if ((PAttern[p]) = ONE_SYM_WILDCARD) or (s > StrLen) then begin
            STATE := STATE_EXIT;
          end else begin
            Inc(StrBasePos);
            p     := PatternBasePos;
            s     := StrBasePos;
            State := STATE_FIRST_LETTER_SEARCH;
          end;
        end; // .case STATE_MATCH_SUBSTR_TAIL
    end; // .switch State
  end; // .while
  
  result := (s = (StrLen + 1)) and (p = (PatternLen + 1));
end; // .function Match

function MatchW (const Str, Pattern: WideString): boolean;
var
{n} StrAnchor:      PWideChar;
{n} PatternAnchor:  PWideChar;
    StrCharPtr:     PWideChar;
    PatternCharPtr: PWideChar;

begin
  StrAnchor      := nil;
  PatternAnchor  := nil;
  StrCharPtr     := PWideChar(Str);
  PatternCharPtr := PWideChar(Pattern);
  // * * * * * //
  while (StrCharPtr^ <> #0) and (PatternCharPtr^ <> '*') do begin
    if (PatternCharPtr^ <> StrCharPtr^) and (PatternCharPtr^ <> '?') then begin
      result := false;
      exit;
    end;

    Inc(StrCharPtr);
    Inc(PatternCharPtr);
  end;

  while StrCharPtr^ <> #0 do begin
    if PatternCharPtr^ = '*' then begin
      Inc(PatternCharPtr);

      if PatternCharPtr^ = #0 then begin
        result := true;
        exit;
      end;

      PatternAnchor := PatternCharPtr;
      StrAnchor     := StrCharPtr + 1;
    end else if (StrCharPtr^ = PatternCharPtr^) or (PatternCharPtr^ = '?') then begin
      Inc(StrCharPtr);
      Inc(PatternCharPtr);
    end else begin
      PatternCharPtr := PatternAnchor;
      StrCharPtr     := StrAnchor;
      Inc(StrAnchor);
    end;
  end; // .while

  while PatternCharPtr^ = '*' do begin
    Inc(PatternCharPtr);
  end;

  result := PatternCharPtr^ = #0;
end; // .function MatchW

function ExtractFromPchar (Str: pchar; Count: integer): string;
var
  Buf:    pchar;
  StrLen: integer;

begin
  {!} Assert(Str <> nil);
  {!} Assert(Count >= 0);
  Buf := Str;
  // * * * * * //
  if Count > 0 then begin
    while (Count > 0) and (Str^ <> #0) do begin
      Dec(Count);
      Inc(Str);
    end;
    
    StrLen := Str - Buf;
    SetLength(result, StrLen);
    Utils.CopyMem(StrLen, Buf, pointer(result));
  end;
end; // .function ExtractFromPchar

function BufToStr ({n} Buf: pointer; BufSize: integer): string;
begin
  {!} Assert(Utils.IsValidBuf(Buf, BufSize));
  SetLength(result, BufSize);

  if BufSize > 0 then begin
    Utils.CopyMem(BufSize, Buf, @result[1]);
  end;
end;

function IsBinaryStr (const Str: string): boolean;
var
  i: integer;

begin
  i := 1;
  
  while (i <= Length(Str)) and not (Str[i] in BINARY_CHARACTERS) do begin
    Inc(i);
  end;

  result := i <= Length(Str);
end; // .function IsBinaryStr

function Utf8ToAnsi (const Str: string): string;
var
  TempBuf:    string;
  TempBufLen: integer;
  ResBufLen:  integer;

begin
  result := '';

  if Str <> '' then begin
    TempBufLen := Windows.MultiByteToWideChar(Windows.CP_UTF8, 0, pointer(Str), length(Str), nil, 0);

    if TempBufLen <> 0 then begin
      SetLength(TempBuf, TempBufLen * sizeof(WideChar));
      TempBufLen := Windows.MultiByteToWideChar(Windows.CP_UTF8, 0, pointer(Str), length(Str), @TempBuf[1], TempBufLen);
      ResBufLen  := Windows.WideCharToMultiByte(Windows.CP_ACP, WC_NO_BEST_FIT_CHARS, pointer(TempBuf), TempBufLen, nil, 0, nil, nil);
      SetLength(result, ResBufLen * sizeof(char));
      ResBufLen  := Windows.WideCharToMultiByte(Windows.CP_ACP, WC_NO_BEST_FIT_CHARS, pointer(TempBuf), TempBufLen, @result[1], ResBufLen, nil, nil);

      if length(result) <> ResBufLen then begin
        SetLength(result, ResBufLen);
      end;
    end;
  end; // .if
end; // .function Utf8ToAnsi

function PWideCharToAnsi (const Str: PWideChar; out Res: string; FailOnError: boolean = false): boolean;
const
  AUTO_LEN      = -1;
  NULL_CHAR_LEN = sizeof(char);

var
  Flags:     integer;
  ResBufLen: integer;

begin
  result := true;
  Res    := '';

  if (Str <> nil) and (Str^ <> #0) then begin
    Flags := WC_NO_BEST_FIT_CHARS;

    if FailOnError then begin
      Flags := Flags or WC_ERR_INVALID_CHARS;
    end;

    ResBufLen := Windows.WideCharToMultiByte(Windows.CP_ACP, Flags, Str, AUTO_LEN, nil, 0, nil, nil);
    result    := ResBufLen > NULL_CHAR_LEN;

    if result then begin
      SetLength(Res, ResBufLen * sizeof(char) - NULL_CHAR_LEN);
      ResBufLen := Windows.WideCharToMultiByte(Windows.CP_ACP, Flags, Str, AUTO_LEN, @Res[1], ResBufLen, nil, nil);
      result    := ResBufLen = length(Res) + NULL_CHAR_LEN;
    end;

    if not result then begin
      Res := '';      
    end;
  end; // .if
end; // .function PWideCharToAnsi

function WideToAnsiSubstitute (const Str: WideString): string;
begin
  PWideCharToAnsi(PWideChar(Str), result, not FAIL_ON_ERROR);
end;

function WideStringFromBuf ({n} Buf: PWideChar; NumChars: integer = -1): WideString;
begin
  if NumChars < 0 then begin
    result := Buf;
  end else begin
    {!} Assert(Utils.IsValidBuf(Buf, NumChars));
    result := '';

    if NumChars > 0 then begin    
      SetLength(result, NumChars);

      if NumChars > 0 then begin
        Utils.CopyMem(NumChars * sizeof(WideChar), Buf, @result[1]);
      end;
    end;
  end; // .else
end; // .function WideStringFromBuf

function WideStringToBuf (const Str: WideString; Buf: PWideChar): PWideChar;
begin
  {!} Assert(Buf <> nil);
  result := Buf;
  // * * * * * //
  if Str <> '' then begin
    Utils.CopyMem(length(Str) * sizeof(WideChar) + sizeof(WideChar), pointer(Str), Buf);
  end else begin
    Buf^ := #0;
  end;
end; // .function WideStringToBuf

function WideLowerCase (const Str: WideString): WideString;
begin
  result := Str;

  if result <> '' then begin
    UniqueString(result);
    Windows.CharLowerW(PWideChar(result));
  end;  
end;

function ExcludeTrailingDelimW (const Str: WideString; {n} HadTrailingDelim: pboolean = nil): WideString;
var
  StrLen: integer;
  Pos:    integer;

begin
  result := Str;
  
  if result <> '' then begin
    StrLen := Length(result);
    Pos    := StrLen;

    while (Pos >= 1) and (result[Pos] in PATH_DELIMS) do begin
      Dec(Pos);
    end;

    if Pos <> StrLen then begin
      SetLength(result, Pos);
    end;
  end;

  if HadTrailingDelim <> nil then begin
    HadTrailingDelim^ := Length(result) <> Length(Str);
  end;
end; // .function ExcludeTrailingDelimW

function ExtractDirPathW (const Path: WideString): WideString;
var
  StartPtr: PWideChar;
  CharPtr:  PWideChar;

begin
  StartPtr := PWideChar(Path);
  CharPtr  := StartPtr + Length(Path);
  // * * * * * //
  result := '';

  while (CharPtr >= StartPtr) and not (CharPtr^ in PATH_DELIMS) do begin
    Dec(CharPtr);
  end;

  if CharPtr > StartPtr then begin
    while (CharPtr >= StartPtr) and (CharPtr^ in PATH_DELIMS) do begin
      Dec(CharPtr);
    end;

    Inc(CharPtr);
  end;

  if CharPtr > StartPtr then begin
    SetLength(result, CharPtr - StartPtr);
    Utils.CopyMem((CharPtr - StartPtr) * sizeof(CharPtr^), StartPtr, @result[1]);
  end;

  if result = '' then begin
    result := '.';
  end;
end; // .function ExtractDirPathW

function ExtractFileNameW (const Path: WideString): WideString;
var
  StartPtr: PWideChar;
  EndPtr:   PWideChar;
  CharPtr:  PWideChar;

begin
  StartPtr := PWideChar(Path);
  EndPtr   := StartPtr + Length(Path);
  CharPtr  := EndPtr;
  // * * * * * //
  result := '';

  while (CharPtr >= StartPtr) and not (CharPtr^ in PATH_DELIMS) do begin
    Dec(CharPtr);
  end;

  Inc(CharPtr);

  if CharPtr < EndPtr then begin
    SetLength(result, EndPtr - CharPtr);
    Utils.CopyMem((EndPtr - CharPtr) * sizeof(CharPtr^), CharPtr, @result[1]);
  end;
end; // .function ExtractFileNameW

function CompareWideChars (Str1Ptr, Str2Ptr: PWideChar; Len: integer = -1): integer;
var
  Char1: WideChar;
  Char2: WideChar;
  Pos:   integer;

begin
  {!} Assert(Str1Ptr <> nil);
  {!} Assert(Str2Ptr <> nil);
  // * * * * * //
  Char1  := #0;
  Char2  := #0;
  Pos    := 0;
  result := 0;

  if Len < 0 then begin
    Len := high(integer);
  end;

  while Pos < Len do begin
    Char1 := Str1Ptr^;
    Char2 := Str2Ptr^;

    if Char1 = Char2 then begin
      if Char1 = #0 then begin
        exit;
      end;

      Inc(Str1Ptr);
      Inc(Str2Ptr);
    end else begin
      break;
    end;

    Inc(Pos);
  end; // .while

  // Characters differ, fix up each one if they're both in or above the surrogate range, then compare them
  if (ord(Char1) >= $D800) and (ord(Char2) >= $D800) then begin
    if ord(Char1) >= $E000 then begin
      Char1 := WideChar(ord(Char1) - $800);
    end else begin
      Char1 := WideChar(ord(Char1) + $2000);
    end;

    if ord(Char2) >= $E000 then begin
      Char2 := WideChar(ord(Char2) - $800);
    end else begin
      Char2 := WideChar(ord(Char2) + $2000);
    end;
  end;

  // Now both characters are in code point order
  result := ord(Char1) - ord(Char2);
end; // .function CompareWideChars

function CompareBinStringsW (const Str1, Str2: WideString): integer;
begin
  result := CompareWideChars(PWideChar(Str1), PWideChar(Str2));
end;

end.

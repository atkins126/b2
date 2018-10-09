unit DataFlows;
(*
  Byte stream interfaces, helpers, abstract classes.
*)


(***)  interface  (***)

uses
  SysUtils, Utils;

type
  IReadable = interface
    (* Reads up to specified number of bytes to buffer. Returns number of actually read bytes *)
    function ReadUpTo (Count: integer; {n} Buf: pointer): integer;

    (* Returns true if end of data is reached. EOF may be not detectable before data reading attempt is made. Thus
       reading 0 bytes without EOF two times one after another can be considered an IO error *)
    function IsEof: boolean;
  end;

  IWritable = interface
    (* Writes up to specified number of bytes to buffer. Returns number of actually written bytes *)
    function WriteUpTo (Count: integer; {n} Buf: pointer): integer;
  end;

  ISeekable = interface
    (* Set new caret position in data stream, if possible. NOTE: Position becomes undefined on failure *)
    function Seek (Pos: integer): boolean;
  end;

  IIndentedOutput

  (*
    Provides means for formatted output to external storage.
    It's recommended to internally use StrBuilder for file output.
    Default indentation must be '  ', line end marker - #13#10.
  *)
  IFormattedOutput = interface (IWritable)
    (* Sets new string to use as single level indentation. Real indentation string will be multiplied by indentation level *)
    procedure SetIndentationTemplate (const IndentationTmpl: string);
    
    (* Assigns new string to use as line end marker. Markers are used to detecting, where indentation should be applied *)
    procedure SetLineEndMarker (const LineEndMarker: string);

    (* Increase indentation level by one *)
    procedure Indent;
    
    (* Decreases indentation level by one *)
    procedure Outdent;
    
    (* Sets new indentation level (>= 0) *)
    procedure SetIndentationLevel (Level: integer);

    (* Returns current indentation level (>= 0) *)
    function GetIndentationLevel: integer;

    function GetIndentationTemplate: string;
    
    procedure Write (const Str: string);
    
    // Same as Write + Write([line end marker])
    procedure WriteIndentation;

    (* Same as: set indent level to 0 + Write + restore indent level + [line end marker] *)
    procedure RawLine (const Str: string);
    
    // Same as Write([indentation]) * [indent level] + RawLine(Str)
    procedure Line (const Str: string);
    
    (* Same as Write([line end marker]) *)
    procedure EmptyLine;
  end; // .interface IFormattedOutput


(***)  implementation  (***)


TBytesWriter

with TFormattedOutput.Create(TBufferedOutput(TFile.Create(Path), 1000000)) do begin

end;

with StrLib.FormatOutput(DataFlows.BufOutput(TFile.Create(Path), 1000000)) do begin

end;

DataFlows.Reader.ReadBytes();

procedure ReadBytes (Count: integer; {n} Buf: pointer; Source: IReadable);
var
  NumBytesRead:   integer;
  TotalBytesRead: integer;

begin
  {!} Assert(Utils.IsValidBuf(Buf, Count));
  {!} Assert(Source <> nil);
  TotalBytesRead := 0;

  while TotalBytesRead < Count do begin
    NumBytesRead := Source.ReadUpTo(Count, Utils.PtrOfs(Buf, TotalBytesRead));

    if NumBytesRead <= 0 then begin
      raise EInOutError.Create(Format('Failed to read %d bytes from IReadable. Bytes read: %d', [Count, TotalBytesRead]));
    end;

    Inc(TotalBytesRead, NumBytesRead);
  end;
end; // .procedure ReadBytes

procedure WriteBytes (Count: integer; {n} Buf: pointer; Destination: IWritable);
var
  NumBytesWritten:   integer;
  TotalBytesWritten: integer;

begin
  {!} Assert(Utils.IsValidBuf(Buf, Count));
  {!} Assert(Destination <> nil);
  TotalBytesWritten := 0;

  while TotalBytesWritten < Count do begin
    NumBytesWritten := Destination.WriteUpTo(Count, Utils.PtrOfs(Buf, TotalBytesWritten));

    if NumBytesWritten <= 0 then begin
      raise EInOutError.Create(Format('Failed to write %d bytes from IWritable. Bytes written: %d', [Count, TotalBytesWritten]));
    end;

    Inc(TotalBytesWritten, NumBytesWritten);
  end;
end; // .procedure WriteBytes

end.
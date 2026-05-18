{
 BSD 3-Clause License
 ____________________
 
 Copyright © 2026, Jaisal E. K.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}

{ 
 ==================================================================================
 MonoLexID (https://github.com/ekjaisal/MonoLexID)
 ==================================================================================
 
 A time-ordered and sortable Universally Unique Identifier (UUID) generator for 
 Object Pascal (Lazarus/Free Pascal), producing identifiers structurally compatible 
 with the RFC 9562 UUIDv7 layout while privileging intra-millisecond monotonicity.

 Generation Policy
 _________________
 
 1. Lexicographic Monotonicity: Identifiers are time-ordered at millisecond 
    precision, ensuring natural sequential sorting, preventing index fragmentation 
    and optimising database insertion performance.
 
 2. Time Integrity: The generator privileges chronological truth (clock-dependent). 
    Should the system exhaust the sequence counter (4,096 allocations per millisecond) 
    or detect a retrograde clock shift, generation is suspended via a CPU spin-wait 
    loop. It yields (pauses) until physical time advances, so that identifiers are not 
    generated with a fictitious-future time.
 
 3. Cryptographic Uniqueness: To preclude collisions in distributed environments, the 
    remainder of the string payload is populated using OS-native, cryptographically 
    secure pseudorandom number generators to minimise collision risk.

 36 Character String Layout (UUIDv7 Compatible Encoding)
 _______________________________________________________
 
 • Chars 1-8:   UNIX Timestamp in Milliseconds (Part 1)
 • Char 9:      Hyphen
 • Chars 10-13: UNIX Timestamp in Milliseconds (Part 2)
 • Char 14:     Hyphen
 • Chars 15-18: Version Identifier ('7') + Sequence Counter
 • Char 19:     Hyphen
 • Chars 20-23: Variant Identifier + Random Data
 • Char 24:     Hyphen
 • Chars 25-36: Secure Random Data
}

unit MonoLexID;

(* The default mode uses threadvar state (monotonic per thread).
   For switching to global locking instead:
   (1) Pass a -dMONOLEXID_GLOBAL_MONOTONIC flag in the project/compiler options,
       or alternatively,
   (2) Add a {$DEFINE MONOLEXID_GLOBAL_MONOTONIC} directive after this comment.
*)

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils
  {$IFDEF WINDOWS}
  , Windows
  {$ELSE}
  , BaseUnix, Unix
  {$ENDIF};

const
  MonoLexIDVersionMajor = 1;
  MonoLexIDVersionMinor = 0;
  MonoLexIDVersionPatch = 0;

type
  TMonoLexIDBytes = array[0..15] of Byte;
  TGetTimeMSFunc = function: Int64;
  TYieldThreadFunc = procedure;

  TSaveStateFunc = procedure(const SessionNonce: QWord; const ThreadNodeID: QWord; const LastTS: Int64; const LastMonoLexID: TMonoLexIDBytes);
  TLoadStateFunc = function(const SessionNonce: QWord; const ThreadNodeID: QWord; out LastTS: Int64; out LastMonoLexID: TMonoLexIDBytes): Boolean;

function NewMonoLexID: String;
function TryNewMonoLexID(out ID: String): Boolean;
function NewMonoLexIDBytes: TMonoLexIDBytes;
function TryNewMonoLexIDBytes(out IDBytes: TMonoLexIDBytes): Boolean;
procedure MonoLexIDFlushState;

var
  MonoLexIDGetTimeMS: TGetTimeMSFunc;
  MonoLexIDYieldThread: TYieldThreadFunc;
  MonoLexIDSaveState: TSaveStateFunc;
  MonoLexIDLoadState: TLoadStateFunc;

implementation

const
  HexMap: array[0..15] of AnsiChar = '0123456789abcdef';
  SEQ_MASK_MAX  = $FFF;
  SEQ_MASK_SEED = $FFF;
  PERSIST_FREQUENCY = 1024;
  MAX_SPIN_YIELDS = 100000;
  SPIN_SLEEP_THRESHOLD = 100;

type
  TGeneratorState = record
    IsInit: Boolean;
    LastTS: Int64;
    Seq: LongWord;
    LastMonoLexID: TMonoLexIDBytes;
    ThreadNodeID: QWord;
    RndBuf: array[0..1023] of Byte;
    RndIdx: Integer;
    UnpersistedCount: Integer;
    {$IFNDEF WINDOWS}
    PID: TPid;
    {$ENDIF}
  end;

var
  GSessionNonce: QWord;

{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
var
  GState: TGeneratorState;
  GMonoLexIDLock: TRTLCriticalSection;
{$ELSE}
threadvar
  GState: TGeneratorState;
{$ENDIF}

{$IFNDEF WINDOWS}
var
  GURandomFD: THandle = THandle(-1);
{$ENDIF}

{$IFDEF WINDOWS}
type
  TGetSystemTimePreciseAsFileTime = procedure(var lpSystemTimeAsFileTime: TFileTime); stdcall;

var
  _GetSystemTimePreciseAsFileTime: TGetSystemTimePreciseAsFileTime = nil;

function RtlGenRandom(RandomBuffer: Pointer; RandomBufferLength: LongWord): Boolean; stdcall; external 'advapi32.dll' name 'SystemFunction036';
function SwitchToThread: BOOL; stdcall; external 'kernel32.dll';

procedure InitWindowsPreciseTime;
var
  Kernel: HMODULE;
begin
  Kernel := GetModuleHandle('kernel32.dll');
  if Kernel <> 0 then
    Pointer(_GetSystemTimePreciseAsFileTime) := GetProcAddress(Kernel, 'GetSystemTimePreciseAsFileTime');
end;

procedure SecureRandom(var Buffer; Count: SizeInt);
begin
  if not RtlGenRandom(@Buffer, Count) then
    raise Exception.Create('MonoLexID Generation Failed: Windows CSPRNG is unavailable.');
end;

procedure DefaultYieldThread;
begin
  SwitchToThread;
end;
{$ELSE}
procedure SecureRandom(var Buffer; Count: SizeInt);
var
  P: PByte;
  ReadNow, Total: SizeInt;
begin
  if GURandomFD = THandle(-1) then
    raise Exception.Create('MonoLexID Generation Failed: /dev/urandom is not open.');

  P := @Buffer;
  Total := 0;
  while Total < Count do
  begin
    ReadNow := FileRead(GURandomFD, P[Total], Count - Total);
    if ReadNow <= 0 then
      raise Exception.Create('MonoLexID Generation Failed: OS I/O error reading from entropy source.');
    Inc(Total, ReadNow);
  end;
end;

procedure DefaultYieldThread;
begin
  Sleep(0);
end;
{$ENDIF}

procedure GetBufferedRandom(var Buffer; Count: Integer);
var
  Dst: PByte;
  I: Integer;
begin
  {$IFNDEF WINDOWS}
  if GState.PID <> fpGetpid then
  begin
    GState.IsInit := False;
    GState.PID := fpGetpid;
  end;
  {$ENDIF}

  if GState.RndIdx + Count > SizeOf(GState.RndBuf) then
  begin
    SecureRandom(GState.RndBuf, SizeOf(GState.RndBuf));
    GState.RndIdx := 0;
  end;
  
  Dst := @Buffer;
  for I := 0 to Count - 1 do
    Dst[I] := GState.RndBuf[GState.RndIdx + I];
    
  Inc(GState.RndIdx, Count);
end;

function DefaultGetUnixTimeMS: Int64;
{$IFDEF WINDOWS}
var
  FileTime: TFileTime;
  LL: QWord;
begin
  FileTime := Default(TFileTime);
  if Assigned(_GetSystemTimePreciseAsFileTime) then
    _GetSystemTimePreciseAsFileTime(FileTime)
  else
    GetSystemTimeAsFileTime(FileTime);
  LL := (QWord(FileTime.dwHighDateTime) shl 32) or FileTime.dwLowDateTime;
  Result := (LL div 10000) - 11644473600000;
end;
{$ELSE}
var
  TV: BaseUnix.timeval;
begin
  Unix.fpgettimeofday(@TV, nil);
  Result := Int64(TV.tv_sec) * 1000 + (TV.tv_usec div 1000);
end;
{$ENDIF}

function CompareMonoLexID(const A, B: TMonoLexIDBytes): Integer; inline;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 15 do
  begin
    if A[I] > B[I] then Exit(1);
    if A[I] < B[I] then Exit(-1);
  end;
end;

procedure InitGeneratorState;
var
  RandWord: LongWord;
  LoadedTS: Int64;
  LoadedMonoLexID: TMonoLexIDBytes;
begin
  RandWord := 0;

  {$IFNDEF WINDOWS}
  GState.PID := fpGetpid;
  {$ENDIF}

  GState.RndIdx := SizeOf(GState.RndBuf);
  GetBufferedRandom(GState.ThreadNodeID, SizeOf(GState.ThreadNodeID));

  if Assigned(MonoLexIDLoadState) and MonoLexIDLoadState(GSessionNonce, GState.ThreadNodeID, LoadedTS, LoadedMonoLexID) then
  begin
    GState.LastTS := LoadedTS;
    GState.LastMonoLexID := LoadedMonoLexID;
  end
  else
  begin
    GState.LastTS := 0;
    GState.LastMonoLexID := Default(TMonoLexIDBytes);
  end;

  GState.Seq := 0;
  GState.UnpersistedCount := 0;
  GetBufferedRandom(RandWord, SizeOf(RandWord));
  GState.Seq := RandWord and SEQ_MASK_SEED;
  GState.IsInit := True;
end;

procedure PersistGeneratorState(const TS: Int64; const MonoLexID: TMonoLexIDBytes);
begin
  if Assigned(MonoLexIDSaveState) then
    MonoLexIDSaveState(GSessionNonce, GState.ThreadNodeID, TS, MonoLexID);
  GState.UnpersistedCount := 0;
end;

procedure MonoLexIDFlushState;
begin
  if GState.IsInit then PersistGeneratorState(GState.LastTS, GState.LastMonoLexID);
end;

function NewMonoLexIDBytes: TMonoLexIDBytes;
var
  CurrentMS: Int64;
  Seq, RandStep: LongWord;
  RandWord: LongWord;
  RandBytes: array[0..7] of Byte;
  IsValid, RequiresPersistence: Boolean;
  SpinCount: Integer;
begin
  RandWord := 0;
  RandBytes[0] := 0;

  {$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  EnterCriticalSection(GMonoLexIDLock);
  try
  {$ENDIF}

  if not GState.IsInit then InitGeneratorState;

  repeat
    IsValid := True;
    RequiresPersistence := False;
    GetBufferedRandom(RandBytes, SizeOf(RandBytes));

    RandStep := 1 + (RandBytes[7] and $01);

    CurrentMS := MonoLexIDGetTimeMS();

    SpinCount := 0;
    while CurrentMS < GState.LastTS do
    begin
      if SpinCount > SPIN_SLEEP_THRESHOLD then Sleep(1) else MonoLexIDYieldThread();
      CurrentMS := MonoLexIDGetTimeMS();
      Inc(SpinCount);
      if SpinCount > MAX_SPIN_YIELDS then
        raise Exception.Create('MonoLexID Generation Failed: Clock retrograde timeout.');
    end;

    if CurrentMS > GState.LastTS then
    begin
      GState.LastTS := CurrentMS;
      GetBufferedRandom(RandWord, SizeOf(RandWord));
      GState.Seq := RandWord and SEQ_MASK_SEED;
      RequiresPersistence := True;
    end
    else
    begin
      Inc(GState.Seq, RandStep);
      if GState.Seq > SEQ_MASK_MAX then
      begin
        SpinCount := 0;
        repeat
          if SpinCount > SPIN_SLEEP_THRESHOLD then Sleep(1) else MonoLexIDYieldThread();
          CurrentMS := MonoLexIDGetTimeMS();
          Inc(SpinCount);
          if SpinCount > MAX_SPIN_YIELDS then
            raise Exception.Create('MonoLexID Generation Failed: Sequence overflow timeout.');
        until CurrentMS > GState.LastTS;

        GState.LastTS := CurrentMS;
        GetBufferedRandom(RandWord, SizeOf(RandWord));
        GState.Seq := RandWord and SEQ_MASK_SEED;
        RequiresPersistence := True;
      end;
    end;
    
    CurrentMS := GState.LastTS;
    Seq := GState.Seq;

    Result[0] := (CurrentMS shr 40) and $FF;
    Result[1] := (CurrentMS shr 32) and $FF;
    Result[2] := (CurrentMS shr 24) and $FF;
    Result[3] := (CurrentMS shr 16) and $FF;
    Result[4] := (CurrentMS shr 8) and $FF;
    Result[5] := CurrentMS and $FF;

    Result[6] := $70 or ((Seq shr 8) and $0F);
    Result[7] := Seq and $FF;

    Result[8] := $80 or (RandBytes[7] and $3F);
    Result[9] := RandBytes[6];
    Result[10] := RandBytes[5];
    Result[11] := RandBytes[4];
    Result[12] := RandBytes[3];
    Result[13] := RandBytes[2];
    Result[14] := RandBytes[1];
    Result[15] := RandBytes[0];

    if GState.LastTS > 0 then
    begin
      if CompareMonoLexID(Result, GState.LastMonoLexID) <= 0 then
      begin
        SpinCount := 0;
        repeat
          if SpinCount > SPIN_SLEEP_THRESHOLD then Sleep(1) else MonoLexIDYieldThread();
          CurrentMS := MonoLexIDGetTimeMS();
          Inc(SpinCount);
          if SpinCount > MAX_SPIN_YIELDS then
            raise Exception.Create('MonoLexID Generation Failed: Collision mitigation timeout.');
        until CurrentMS > GState.LastTS;

        GState.LastTS := CurrentMS;
        GetBufferedRandom(RandWord, SizeOf(RandWord));
        GState.Seq := RandWord and SEQ_MASK_SEED;
        IsValid := False;
        RequiresPersistence := True;
      end;
    end;
  until IsValid;

  GState.LastMonoLexID := Result;
  Inc(GState.UnpersistedCount);

  if RequiresPersistence or (GState.UnpersistedCount >= PERSIST_FREQUENCY) then
    PersistGeneratorState(GState.LastTS, Result);

  {$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  finally
    LeaveCriticalSection(GMonoLexIDLock);
  end;
  {$ENDIF}
end;

function TryNewMonoLexIDBytes(out IDBytes: TMonoLexIDBytes): Boolean;
begin
  try
    IDBytes := NewMonoLexIDBytes;
    Result := True;
  except
    on E: Exception do
    begin
      IDBytes := Default(TMonoLexIDBytes);
      Result := False;
    end;
  end;
end;

function NewMonoLexID: String;
var
  Bytes: TMonoLexIDBytes;
  I, P: Integer;
begin
  Result := ''; 
  Bytes := NewMonoLexIDBytes;
  SetLength(Result, 36);
  P := 1;
  for I := 0 to 15 do
  begin
    if (I = 4) or (I = 6) or (I = 8) or (I = 10) then
    begin
      Result[P] := '-';
      Inc(P);
    end;
    Result[P] := HexMap[Bytes[I] shr 4];
    Result[P + 1] := HexMap[Bytes[I] and $0F];
    Inc(P, 2);
  end;
end;

function TryNewMonoLexID(out ID: String): Boolean;
begin
  try
    ID := NewMonoLexID;
    Result := True;
  except
    on E: Exception do
    begin
      ID := '';
      Result := False;
    end;
  end;
end;

initialization
  MonoLexIDGetTimeMS := @DefaultGetUnixTimeMS;
  MonoLexIDYieldThread := @DefaultYieldThread;
  MonoLexIDSaveState := nil;
  MonoLexIDLoadState := nil;

  {$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  InitCriticalSection(GMonoLexIDLock);
  {$ENDIF}
  
  {$IFDEF WINDOWS}
  InitWindowsPreciseTime;
  {$ELSE}
  GURandomFD := FileOpen('/dev/urandom', fmOpenRead or fmShareDenyNone);
  if GURandomFD = THandle(-1) then
    raise Exception.Create('MonoLexID Initialization Failed: Cannot open /dev/urandom.');
  {$ENDIF}

  GSessionNonce := 0;
  SecureRandom(GSessionNonce, SizeOf(GSessionNonce));

finalization
  {$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  DoneCriticalSection(GMonoLexIDLock);
  {$ENDIF}
  {$IFNDEF WINDOWS}
  if GURandomFD <> THandle(-1) then FileClose(GURandomFD);
  {$ENDIF}

end.
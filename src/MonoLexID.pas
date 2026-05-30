{
 Copyright © 2026, Jaisal E. K.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

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

 A time-ordered and sortable Universally Unique Identifier (UUID) generator
 for Object Pascal (Lazarus/Free Pascal), producing identifiers structurally
 compatible with the RFC 9562 UUIDv7 layout while privileging intra-millisecond
 monotonicity.

 Generation Policy
 __________________________________________________________________________________

 1. Lexicographic Monotonicity: Identifiers are time-ordered at millisecond
    precision, ensuring natural sequential sorting, preventing index fragmentation,
    and optimising database insertion performance.

 2. Time Integrity: The generator privileges clock-dependent chronological truth.
    Should the system exhaust the sequence counter (4,096 allocations per
    millisecond) or detect a retrograde clock shift, generation is suspended via
    an adaptive spin/yield loop. It yields (pauses) until physical time advances,
    so that identifiers are not generated with a fictitious-future time.

 3. Cryptographic Uniqueness: To preclude collisions in distributed environments,
    the remainder of the string payload is populated using OS-native,
    cryptographically secure pseudorandom number generators to minimise collision
    risk.

 4. Fail-Closed Under Clock Rollback: If the system clock is stepped backwards and
    remains so, generation will suspend until physical time catches up or the
    configurable spin timeout (MonoLexIDSpinTimeoutMS, default 5000 ms) is
    exceeded. Applications that require fail-open UUID generation under clock
    instability should not rely on MonoLexID’s time integrity guarantees.

 36 Character String Layout (UUIDv7 Compatible Encoding)
 __________________________________________________________________________________

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

const
  MonoLexIDVersionMajor = 1;
  MonoLexIDVersionMinor = 1;
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
function MonoLexIDReinitialize: Boolean;
function MonoLexIDGetLastError: String;

var
  MonoLexIDGetTimeMS: TGetTimeMSFunc;
  MonoLexIDYieldThread: TYieldThreadFunc;
  MonoLexIDSaveState: TSaveStateFunc;
  MonoLexIDLoadState: TLoadStateFunc;
  MonoLexIDInitError: String;
  MonoLexIDSpinTimeoutMS: Int64;

implementation

uses
  SysUtils
  {$IFDEF WINDOWS}
  , Windows
  {$ELSE}
  , BaseUnix, Unix
  {$ENDIF};

const
  HexMap: array[0..15] of AnsiChar = '0123456789abcdef';
  SEQ_MASK_MAX         = $FFF;
  SEQ_MASK_SEED        = $FFF;
  PERSIST_FREQUENCY    = 1024;
  MAX_SPIN_YIELDS      = 100000;
  SPIN_SLEEP_THRESHOLD = 100;
  DEFAULT_SPIN_TIMEOUT = 5000;

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
    {$IFDEF UNIX}
    PID: TPid;
    {$ENDIF}
  end;

var
  GInitFailed: Boolean;
  GSessionNonce: QWord;
  GInitLock: TRTLCriticalSection;
  GErrorLock: TRTLCriticalSection;
  GForkErrorStatus: Integer = 0;

{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
var
  GState: TGeneratorState;
  GMonoLexIDLock: TRTLCriticalSection;
  GLastError: String;
  GLockInitialized: Boolean;
{$ELSE}
threadvar
  GState: TGeneratorState;
  GLastError: String;
{$ENDIF}

{$IFDEF UNIX}
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
    raise Exception.Create('MonoLexID: Windows CSPRNG (RtlGenRandom) is unavailable.');
end;

procedure DefaultYieldThread;
begin
  SwitchToThread;
end;

function DefaultGetUnixTimeMS: Int64;
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

procedure SecureRandom(var Buffer; Count: SizeInt);
var
  P: PByte;
  ReadNow, Total: SizeInt;
begin
  if GURandomFD = THandle(-1) then
    raise Exception.Create('MonoLexID: /dev/urandom is not open.');
  P := @Buffer;
  Total := 0;
  while Total < Count do
  begin
    ReadNow := FileRead(GURandomFD, P[Total], Count - Total);
    if ReadNow <= 0 then
      raise Exception.Create('MonoLexID: OS I/O error reading from /dev/urandom.');
    Inc(Total, ReadNow);
  end;
end;

procedure DefaultYieldThread;
begin
  Sleep(0);
end;

function DefaultGetUnixTimeMS: Int64;
var
  TV: BaseUnix.timeval;
begin
  Unix.fpgettimeofday(@TV, nil);
  Result := Int64(TV.tv_sec) * 1000 + (TV.tv_usec div 1000);
end;
{$ENDIF}

procedure SetLastError(const Msg: String);
begin
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  EnterCriticalSection(GErrorLock);
  try
    GLastError := Msg;
  finally
    LeaveCriticalSection(GErrorLock);
  end;
{$ELSE}
  GLastError := Msg;
{$ENDIF}
end;

function MonoLexIDGetLastError: String;
begin
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  EnterCriticalSection(GErrorLock);
  try
    Result := GLastError;
  finally
    LeaveCriticalSection(GErrorLock);
  end;
{$ELSE}
  Result := GLastError;
{$ENDIF}
end;

procedure GetBufferedRandom(var Buffer; Count: Integer);
begin
  if (GState.RndIdx < 0) or (GState.RndIdx > SizeOf(GState.RndBuf)) then
    raise Exception.Create('MonoLexID: RndBuf index invariant violated.');
{$IFDEF UNIX}
  if GState.PID <> fpGetpid then
  begin
    GState.IsInit := False;
    GState.PID := fpGetpid;
    GState.RndIdx := SizeOf(GState.RndBuf);
  end;
{$ENDIF}
  if GState.RndIdx + Count > SizeOf(GState.RndBuf) then
  begin
    SecureRandom(GState.RndBuf, SizeOf(GState.RndBuf));
    GState.RndIdx := 0;
  end;
  Move(GState.RndBuf[GState.RndIdx], Buffer, Count);
  Inc(GState.RndIdx, Count);
end;

procedure InitGeneratorState;
var
  RandWord: LongWord;
  LoadedTS: Int64;
  LoadedMonoLexID: TMonoLexIDBytes;
begin
  RandWord := 0;
{$IFDEF UNIX}
  GState.PID := fpGetpid;
{$ENDIF}
  GState.RndIdx := SizeOf(GState.RndBuf);
  GetBufferedRandom(GState.ThreadNodeID, SizeOf(GState.ThreadNodeID));
  if Assigned(MonoLexIDLoadState) and
     MonoLexIDLoadState(GSessionNonce, GState.ThreadNodeID, LoadedTS, LoadedMonoLexID) then
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

procedure PersistGeneratorState(const TS: Int64; const ID: TMonoLexIDBytes);
begin
  if Assigned(MonoLexIDSaveState) then
  begin
    try
      MonoLexIDSaveState(GSessionNonce, GState.ThreadNodeID, TS, ID);
    except
      on E: Exception do
        SetLastError('MonoLexID: State persistence failed: ' + E.Message);
    end;
  end;
end;

procedure MonoLexIDFlushState;
var
  DoPersist: Boolean;
  PersistTS: Int64;
  PersistID: TMonoLexIDBytes;
begin
  if GInitFailed then Exit;
  DoPersist := False;
  PersistTS := 0;
  PersistID := Default(TMonoLexIDBytes);
  if GState.IsInit then
  begin
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
    EnterCriticalSection(GMonoLexIDLock);
    try
      if GState.IsInit then
      begin
        DoPersist := True;
        PersistTS := GState.LastTS;
        PersistID := GState.LastMonoLexID;
        GState.UnpersistedCount := 0;
      end;
    finally
      LeaveCriticalSection(GMonoLexIDLock);
    end;
{$ELSE}
    DoPersist := True;
    PersistTS := GState.LastTS;
    PersistID := GState.LastMonoLexID;
    GState.UnpersistedCount := 0;
{$ENDIF}
  end;
  if DoPersist then
    PersistGeneratorState(PersistTS, PersistID);
end;

function MonoLexIDReinitialize: Boolean;
begin
  Result := False;
  EnterCriticalSection(GInitLock);
  try
    try
{$IFDEF WINDOWS}
      InitWindowsPreciseTime;
{$ELSE}
      if GURandomFD = THandle(-1) then
      begin
        GURandomFD := FileOpen('/dev/urandom', fmOpenRead or fmShareDenyNone);
        if GURandomFD = THandle(-1) then
        begin
          MonoLexIDInitError := 'MonoLexID: Cannot open /dev/urandom.';
          Exit;
        end;
      end;
{$ENDIF}
      GSessionNonce := 0;
      SecureRandom(GSessionNonce, SizeOf(GSessionNonce));
      MonoLexIDInitError := '';
      Result := True;
    except
      on E: Exception do
        MonoLexIDInitError := 'MonoLexID: Initialization failed: ' + E.Message;
    end;
  finally
    LeaveCriticalSection(GInitLock);
  end;
  if Result then
  begin
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
    EnterCriticalSection(GMonoLexIDLock);
    try
      if GLockInitialized then
      begin
        GState.IsInit := False;
        GState := Default(TGeneratorState);
      end;
    finally
      LeaveCriticalSection(GMonoLexIDLock);
    end;
{$ELSE}
    GState.IsInit := False;
    GState := Default(TGeneratorState);
    GState.RndIdx := SizeOf(GState.RndBuf);
{$ENDIF}
  end;
  GInitFailed := not Result;
end;

{$IFDEF UNIX}
procedure MonoLexIDForkPrepare; cdecl;
begin
  EnterCriticalSection(GInitLock);
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  EnterCriticalSection(GMonoLexIDLock);
  EnterCriticalSection(GErrorLock);
{$ENDIF}
end;

procedure MonoLexIDForkParent; cdecl;
begin
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  LeaveCriticalSection(GErrorLock);
  LeaveCriticalSection(GMonoLexIDLock);
{$ENDIF}
  LeaveCriticalSection(GInitLock);
end;

procedure MonoLexIDForkChild; cdecl;
var
  ReadNow: SizeInt;
begin
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  LeaveCriticalSection(GErrorLock);
  LeaveCriticalSection(GMonoLexIDLock);
{$ENDIF}
  GState.IsInit := False;
  GState := Default(TGeneratorState);
  GState.RndIdx := SizeOf(GState.RndBuf);
  GState.PID := fpGetpid;
  if GURandomFD <> THandle(-1) then
  begin
    FileClose(GURandomFD);
    GURandomFD := THandle(-1);
  end;
  GURandomFD := FileOpen('/dev/urandom', fmOpenRead or fmShareDenyNone);
  if GURandomFD = THandle(-1) then
  begin
    GInitFailed := True;
    GForkErrorStatus := 1;
  end
  else
  begin
    ReadNow := FileRead(GURandomFD, GSessionNonce, SizeOf(GSessionNonce));
    if ReadNow <> SizeOf(GSessionNonce) then
    begin
      GInitFailed := True;
      GForkErrorStatus := 2;
    end
    else
    begin
      GInitFailed := False;
      GForkErrorStatus := 0;
    end;
  end;
  LeaveCriticalSection(GInitLock);
end;

function pthread_atfork(prepare: Pointer; parent: Pointer; child: Pointer): Integer;
  cdecl; external {$IFDEF DARWIN}'libc'{$ELSE}'libpthread'{$ENDIF};
{$ENDIF}

function IsNewIDCollidingWithLast(const NewID, LastID: TMonoLexIDBytes): Boolean; inline;
var
  I: Integer;
begin
  for I := 0 to 15 do
  begin
    if NewID[I] > LastID[I] then Exit(False);
    if NewID[I] < LastID[I] then Exit(True);
  end;
  Result := True;
end;

function NewMonoLexIDBytes: TMonoLexIDBytes;
var
  CurrentMS, SpinDeadline: Int64;
  Seq, RandStep: LongWord;
  RandWord: LongWord;
  RandBytes: array[0..7] of Byte;
  IsValid, RequiresPersistence, NeedsSpin: Boolean;
  SpinReason: Byte;
  SpinCount: Integer;
  TimeoutMS: Int64;
  PersistTS: Int64;
  PersistID: TMonoLexIDBytes;
  LocalTargetTS: Int64;
begin
  if GForkErrorStatus <> 0 then
  begin
    EnterCriticalSection(GInitLock);
    try
      if GForkErrorStatus = 1 then
        MonoLexIDInitError := 'MonoLexID: Post-fork /dev/urandom failure.'
      else if GForkErrorStatus = 2 then
        MonoLexIDInitError := 'MonoLexID: Post-fork entropy read failure.';
      GInitFailed := True;
      GForkErrorStatus := 0;
    finally
      LeaveCriticalSection(GInitLock);
    end;
  end;
  if GInitFailed then
  begin
    EnterCriticalSection(GInitLock);
    try
      raise Exception.Create('MonoLexID: Subsystem failed to initialize. Reason: ' + MonoLexIDInitError);
    finally
      LeaveCriticalSection(GInitLock);
    end;
  end;
  if not Assigned(MonoLexIDGetTimeMS) then
    raise Exception.Create('MonoLexID: MonoLexIDGetTimeMS is nil. Assign a valid time function before use.');
  if not Assigned(MonoLexIDYieldThread) then
    raise Exception.Create('MonoLexID: MonoLexIDYieldThread is nil. Assign a valid yield function before use.');
  TimeoutMS := MonoLexIDSpinTimeoutMS;
  if TimeoutMS <= 0 then
    TimeoutMS := DEFAULT_SPIN_TIMEOUT;
  RandWord := 0;
  RandBytes[0] := 0;
  RequiresPersistence := False;
  PersistTS := 0;
  PersistID := Default(TMonoLexIDBytes);
  LocalTargetTS := 0;
  repeat
    IsValid := False;
    NeedsSpin := False;
    SpinReason := 0;
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
    EnterCriticalSection(GMonoLexIDLock);
    try
{$ENDIF}
      if not GState.IsInit then InitGeneratorState;
      GetBufferedRandom(RandBytes, SizeOf(RandBytes));
      RandStep := 1 + (RandBytes[7] and $01);
      CurrentMS := MonoLexIDGetTimeMS();
      if CurrentMS < GState.LastTS then
      begin
        NeedsSpin := True;
        SpinReason := 1;
        LocalTargetTS := GState.LastTS;
      end
      else
      begin
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
            NeedsSpin := True;
            SpinReason := 2;
            LocalTargetTS := GState.LastTS;
          end;
        end;
        if not NeedsSpin then
        begin
          CurrentMS := GState.LastTS;
          Seq := GState.Seq;
          Result[0]  := (CurrentMS shr 40) and $FF;
          Result[1]  := (CurrentMS shr 32) and $FF;
          Result[2]  := (CurrentMS shr 24) and $FF;
          Result[3]  := (CurrentMS shr 16) and $FF;
          Result[4]  := (CurrentMS shr 8)  and $FF;
          Result[5]  :=  CurrentMS         and $FF;
          Result[6]  := $70 or ((Seq shr 8) and $0F);
          Result[7]  :=  Seq and $FF;
          Result[8]  := $80 or (RandBytes[7] and $3F);
          Result[9]  := RandBytes[6];
          Result[10] := RandBytes[5];
          Result[11] := RandBytes[4];
          Result[12] := RandBytes[3];
          Result[13] := RandBytes[2];
          Result[14] := RandBytes[1];
          Result[15] := RandBytes[0];
          if (GState.LastTS > 0) and IsNewIDCollidingWithLast(Result, GState.LastMonoLexID) then
          begin
            NeedsSpin := True;
            SpinReason := 3;
            LocalTargetTS := GState.LastTS;
          end
          else
          begin
            GState.LastMonoLexID := Result;
            Inc(GState.UnpersistedCount);
            if RequiresPersistence or (GState.UnpersistedCount >= PERSIST_FREQUENCY) then
            begin
              RequiresPersistence := True;
              PersistTS := GState.LastTS;
              PersistID := Result;
              GState.UnpersistedCount := 0;
            end;
            IsValid := True;
          end;
        end;
      end;
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
    finally
      LeaveCriticalSection(GMonoLexIDLock);
    end;
{$ENDIF}
    if NeedsSpin then
    begin
      SpinDeadline := MonoLexIDGetTimeMS() + TimeoutMS;
      SpinCount := 0;
      case SpinReason of
        1:
          begin
            while MonoLexIDGetTimeMS() < LocalTargetTS do
            begin
              if MonoLexIDGetTimeMS() > SpinDeadline then
                raise Exception.Create('MonoLexID: Clock retrograde spin timeout exceeded.');
              if SpinCount > SPIN_SLEEP_THRESHOLD then Sleep(1) else MonoLexIDYieldThread();
              Inc(SpinCount);
              if SpinCount > MAX_SPIN_YIELDS then
                raise Exception.Create('MonoLexID: Clock retrograde yield count exceeded.');
            end;
          end;
        2:
          begin
            while MonoLexIDGetTimeMS() <= LocalTargetTS do
            begin
              if MonoLexIDGetTimeMS() > SpinDeadline then
                raise Exception.Create('MonoLexID: Sequence overflow spin timeout exceeded.');
              if SpinCount > SPIN_SLEEP_THRESHOLD then Sleep(1) else MonoLexIDYieldThread();
              Inc(SpinCount);
              if SpinCount > MAX_SPIN_YIELDS then
                raise Exception.Create('MonoLexID: Sequence overflow yield count exceeded.');
            end;
          end;
        3:
          begin
            while MonoLexIDGetTimeMS() <= LocalTargetTS do
            begin
              if MonoLexIDGetTimeMS() > SpinDeadline then
                raise Exception.Create('MonoLexID: Collision mitigation spin timeout exceeded.');
              if SpinCount > SPIN_SLEEP_THRESHOLD then Sleep(1) else MonoLexIDYieldThread();
              Inc(SpinCount);
              if SpinCount > MAX_SPIN_YIELDS then
                raise Exception.Create('MonoLexID: Collision mitigation yield count exceeded.');
            end;
          end;
      end;
    end;
  until IsValid;
  if RequiresPersistence then
    PersistGeneratorState(PersistTS, PersistID);
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
      SetLastError(E.Message);
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
    Result[P]     := HexMap[Bytes[I] shr 4];
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
      SetLastError(E.Message);
      Result := False;
    end;
  end;
end;

initialization
  MonoLexIDGetTimeMS    := @DefaultGetUnixTimeMS;
  MonoLexIDYieldThread  := @DefaultYieldThread;
  MonoLexIDSaveState    := nil;
  MonoLexIDLoadState    := nil;
  MonoLexIDInitError    := '';
  MonoLexIDSpinTimeoutMS := DEFAULT_SPIN_TIMEOUT;
  InitCriticalSection(GInitLock);
  InitCriticalSection(GErrorLock);
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  InitCriticalSection(GMonoLexIDLock);
  GLockInitialized := True;
{$ENDIF}
{$IFDEF UNIX}
  pthread_atfork(@MonoLexIDForkPrepare, @MonoLexIDForkParent, @MonoLexIDForkChild);
{$ENDIF}
  MonoLexIDReinitialize;

finalization
  MonoLexIDFlushState;
{$IFDEF MONOLEXID_GLOBAL_MONOTONIC}
  if GLockInitialized then
  begin
    DoneCriticalSection(GMonoLexIDLock);
    GLockInitialized := False;
  end;
{$ENDIF}
  DoneCriticalSection(GErrorLock);
  DoneCriticalSection(GInitLock);
{$IFDEF UNIX}
  if GURandomFD <> THandle(-1) then
  begin
    FileClose(GURandomFD);
    GURandomFD := THandle(-1);
  end;
{$ENDIF}

end.
program main;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  SysUtils,
  Windows;

const
  FieldLen = 10;
  CoordLetters = 'АБВГДЕЖЗИК';
  CoordDigits = '123456789';

type
  TUserCoord = string[4];
  TStates = (Sea, Ship, Missed, Hurt, Sunk);
  TField = array [1 .. FieldLen, 1 .. FieldLen] of TStates;

procedure ClearScreen;
var
  stdout: THandle;
  csbi: TConsoleScreenBufferInfo;
  ConsoleSize: DWORD;
  NumWritten: DWORD;
  Origin: TCoord;
begin
  stdout := GetStdHandle(STD_OUTPUT_HANDLE);
  Win32Check(stdout <> INVALID_HANDLE_VALUE);
  Win32Check(GetConsoleScreenBufferInfo(stdout, csbi));
  ConsoleSize := csbi.dwSize.X * csbi.dwSize.Y;
  Origin.X := 0;
  Origin.Y := 0;
  Win32Check(FillConsoleOutputCharacter(stdout, ' ', ConsoleSize, Origin,
    NumWritten));
  Win32Check(FillConsoleOutputAttribute(stdout, csbi.wAttributes, ConsoleSize,
    Origin, NumWritten));
  Win32Check(SetConsoleCursorPosition(stdout, Origin));
end;

procedure ReadFile(var arr: TField; fname: string; var isCorrect: boolean);
var
  f: textfile;
  s: string[200];
  k: integer;
begin
  k := 1;
  if FileExists(fname) then
  begin
    AssignFile(f, fname);
    Reset(f);
    while (not EOF(f)) do
    begin
      Readln(f, s);
      s := utf8ToAnsi(s);
      for var I := 1 to Length(s) do
      begin
        if s[I] = 'М' then
          arr[k, I] := Sea
        else if s[I] = 'К' then
          arr[k, I] := Ship
        else if s[I] <> #10 then
        begin
          isCorrect := false;
        end;
      end;
      Inc(k);
    end;
    CloseFile(f);
  end
  else
    isCorrect := false;
end;

procedure DrawFields(const Player1Field, Player2Field: TField);
begin
  ClearScreen;
  writeln('                  Игрок 1                                         Игрок 2                   ');
  writeln('   | А | Б | В | Г | Д | Е | Ж | З | И | К |       | А | Б | В | Г | Д | Е | Ж | З | И | К |');
  for var I := 1 to FieldLen do
  begin
    write(I:2, ' |');
    for var j := 1 to FieldLen do
    begin
      if (Player1Field[I, j] = Ship) or (Player1Field[I, j] = Sea) then
        write(' * |')
      else if Player1Field[I, j] = Missed then
        write(' П |')
      else if Player1Field[I, j] = Hurt then
        write(' P |')
      else if Player1Field[I, j] = Sunk then
        write(' У |');
    end;
    write('    ');
    write(I:2, ' |');
    for var j := 1 to FieldLen do
    begin
      if (Player2Field[I, j] = Ship) or (Player2Field[I, j] = Sea) then
        write(' * |')
      else if Player2Field[I, j] = Missed then
        write(' П |')
      else if Player2Field[I, j] = Hurt then
        write(' P |')
      else if Player2Field[I, j] = Sunk then
        write(' У |');
    end;
    writeln;
  end;

end;

procedure ConvertCoord(const coord: TUserCoord; var X, Y: integer;
  const field: TField);
begin
  Y := Pos(coord[1], CoordLetters);
  if Length(coord) = 3 then
    X := 10
  else
    X := Pos(coord[2], CoordDigits);
end;

function CheckCoord(const coord: TUserCoord; const field: TField;
  var X, Y: integer): boolean;
var
  len: integer;
begin
  len := Length(coord);
  if (len > 3) or (len < 2) then
    Exit(false)
  else if Pos(coord[1], CoordLetters) = 0 then
    Exit(false)
  else if Pos(coord[2], CoordDigits) = 0 then
    Exit(false)
  else if (len = 3) and (Copy(coord, 2, 2) <> '10') then
    Exit(false)
  else
  begin
    ConvertCoord(coord, X, Y, field);
    if (field[X, Y] <> Sea) and (field[X, Y] <> Ship) then
      Exit(false);
    Exit(True);
  end;
end;

procedure Fire(var field: TField; const X, Y: integer; var move: boolean);
begin
  if field[X, Y] = Sea then
  begin
    field[X, Y] := Missed;
    move := not move;
  end
  else if field[X, Y] = Ship then
  begin
    field[X, Y] := Hurt;
  end;

  Readln;
end;

procedure PlayerMove(const user: integer; var field: TField;
  var coord: TUserCoord; var move: boolean);
var
  X, Y: integer;
begin
  while True do
  begin
    writeln;
    writeln('Ход игрока номер ', user);
    write('Введите координату: ');
    Readln(coord);
    if not CheckCoord(coord, field, X, Y) then
    begin
      writeln('Невалидная координата, повторите попытку');
      continue;
    end;
    break;
  end;

  Fire(field, X, Y, move);
end;

var
  Player1Field, Player2Field: TField;
  isCorrect, isGameOver: boolean;
  move: boolean;
  coord: TUserCoord;

begin
  move := True;
  isCorrect := True;
  isGameOver := false;
  ReadFile(Player1Field, '../../player1ships.txt', isCorrect);
  ReadFile(Player2Field, '../../player2ships.txt', isCorrect);

  if isCorrect then
  begin
    while not isGameOver do
    begin

      DrawFields(Player1Field, Player2Field);
      if move then
      begin
        PlayerMove(1, Player2Field, coord, move);
      end
      else
      begin
        PlayerMove(2, Player1Field, coord, move);
      end;
    end;
  end
  else
    writeln('Неверный формат файла или файл не найден');
  Readln;

end.

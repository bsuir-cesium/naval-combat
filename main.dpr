program main;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  SysUtils,
  Windows,
  mmsystem;

const
  FieldLen = 10;
  CoordLetters = 'АБВГДЕЖЗИК';
  CoordSmallLetters = 'абвгдежзик';
  CoordDigits = '123456789';

type
  TUserCoord = string[7];
  TStates = (Sea, Ship, Missed, Hurt, Sunk);
  TField = array [1 .. FieldLen, 1 .. FieldLen] of TStates;
  TShipsCount = array [1 .. 4] of Integer;

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
  k: Integer;
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
        if Length(s) <> FieldLen then
          isCorrect := false
        else if s[I] = 'М' then
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

procedure ConvertCoord(const coord: TUserCoord; var X, Y: Integer;
  const field: TField);
begin
  if Pos(coord[1], CoordLetters) = 0 then
    Y := Pos(coord[1], CoordSmallLetters)
  else
    Y := Pos(coord[1], CoordLetters);
  if Length(coord) = 3 then
    X := 10
  else
    X := Pos(coord[2], CoordDigits);
end;

function CheckCoord(const coord: TUserCoord; const field: TField;
  var X, Y: Integer): boolean;
var
  len: Integer;
begin
  len := Length(coord);
  if (len > 3) or (len < 2) then
    CheckCoord := false
  else if (Pos(coord[1], CoordLetters) = 0) and
    (Pos(coord[1], CoordSmallLetters) = 0) then
    CheckCoord := false
  else if Pos(coord[2], CoordDigits) = 0 then
    CheckCoord := false
  else if (len = 3) and (Copy(coord, 2, 2) <> '10') then
    CheckCoord := false
  else
  begin
    ConvertCoord(coord, X, Y, field);
    if (field[X, Y] <> Sea) and (field[X, Y] <> Ship) then
      CheckCoord := false
    else
      CheckCoord := True;
  end;
end;

procedure DrawMissedAfterShipDeath(var field: TField; const X, Y: Integer);
var
  I, j: Integer;
begin
  if (X = 10) and (Y = 1) then
  begin
    if field[X - 1, Y] = Sea then
      field[X - 1, Y] := Missed;
    if field[X, Y + 1] = Sea then
      field[X, Y + 1] := Missed;
    if field[X - 1, Y + 1] = Sea then
      field[X - 1, Y + 1] := Missed;
  end
  else if (X = 10) and (Y = 10) then
  begin
    if field[X - 1, Y] = Sea then
      field[X - 1, Y] := Missed;
    if field[X, Y - 1] = Sea then
      field[X, Y - 1] := Missed;
    if field[X - 1, Y - 1] = Sea then
      field[X - 1, Y - 1] := Missed;
  end
  else if (X = 1) and (Y = 1) then
  begin
    if field[X + 1, Y] = Sea then
      field[X + 1, Y] := Missed;
    if field[X, Y + 1] = Sea then
      field[X, Y + 1] := Missed;
    if field[X + 1, Y + 1] = Sea then
      field[X + 1, Y + 1] := Missed;
  end
  else if (X = 1) and (Y = 10) then
  begin
    if field[X + 1, Y] = Sea then
      field[X + 1, Y] := Missed;
    if field[X, Y - 1] = Sea then
      field[X, Y - 1] := Missed;
    if field[X + 1, Y - 1] = Sea then
      field[X + 1, Y - 1] := Missed;
  end

  else if (X = 10) then
  begin
    if field[X - 1, Y] = Sea then
      field[X - 1, Y] := Missed;
    if field[X, Y + 1] = Sea then
      field[X, Y + 1] := Missed;
    if field[X - 1, Y + 1] = Sea then
      field[X - 1, Y + 1] := Missed;
    if field[X, Y - 1] = Sea then
      field[X, Y - 1] := Missed;
    if field[X - 1, Y - 1] = Sea then
      field[X - 1, Y - 1] := Missed;
  end
  else if (Y = 10) then
  begin
    if field[X - 1, Y] = Sea then
      field[X - 1, Y] := Missed;
    if field[X, Y - 1] = Sea then
      field[X, Y - 1] := Missed;
    if field[X - 1, Y - 1] = Sea then
      field[X - 1, Y - 1] := Missed;
    if field[X + 1, Y] = Sea then
      field[X + 1, Y] := Missed;
    if field[X + 1, Y - 1] = Sea then
      field[X + 1, Y - 1] := Missed;
  end
  else if (X = 1) then
  begin
    if field[X + 1, Y] = Sea then
      field[X + 1, Y] := Missed;
    if field[X, Y + 1] = Sea then
      field[X, Y + 1] := Missed;
    if field[X + 1, Y + 1] = Sea then
      field[X + 1, Y + 1] := Missed;
    if field[X, Y - 1] = Sea then
      field[X, Y - 1] := Missed;
    if field[X + 1, Y - 1] = Sea then
      field[X + 1, Y - 1] := Missed;
  end
  else if (Y = 1) then
  begin
    if field[X + 1, Y] = Sea then
      field[X + 1, Y] := Missed;
    if field[X, Y + 1] = Sea then
      field[X, Y + 1] := Missed;
    if field[X + 1, Y + 1] = Sea then
      field[X + 1, Y + 1] := Missed;
    if field[X - 1, Y] = Sea then
      field[X - 1, Y] := Missed;
    if field[X - 1, Y + 1] = Sea then
      field[X - 1, Y + 1] := Missed;
  end
  else
  begin
    if field[X + 1, Y] = Sea then
      field[X + 1, Y] := Missed;
    if field[X - 1, Y] = Sea then
      field[X - 1, Y] := Missed;

    if field[X, Y + 1] = Sea then
      field[X, Y + 1] := Missed;
    if field[X, Y - 1] = Sea then
      field[X, Y - 1] := Missed;

    if field[X + 1, Y - 1] = Sea then
      field[X + 1, Y - 1] := Missed;
    if field[X - 1, Y + 1] = Sea then
      field[X - 1, Y + 1] := Missed;

    if field[X + 1, Y + 1] = Sea then
      field[X + 1, Y + 1] := Missed;
    if field[X - 1, Y - 1] = Sea then
      field[X - 1, Y - 1] := Missed;
  end;
end;

procedure CheckDeath(var field: TField; const X, Y: Integer; print: Boolean);
var
  h, w, oneVert, oneHor: Integer;
  flagShipH, flagShipW, flagSea, isDead: boolean;
begin
  flagShipW := True;
  flagShipH := True;
  flagSea := false;
  isDead := false;
  h := X;
  w := Y;
  while (h > 0) and not(flagSea) do
  begin
    if (field[h, Y] = Sea) or (field[h, Y] = Missed) then
    begin
      flagSea := True;
    end
    else if field[h, Y] = Ship then
      flagShipH := false;
    if not flagSea then
      h := h - 1;

  end;
  oneVert := X - h;
  h := X;
  flagSea := false;
  while (h < 11) and not(flagSea) do
  begin
    if (field[h, Y] = Sea) or (field[h, Y] = Missed) then
    begin
      flagSea := True;
    end
    else if field[h, Y] = Ship then
      flagShipH := false;
    if not flagSea then
      h := h + 1;
  end;
  if h - X > oneVert then
    oneVert := h - X;

  flagSea := false;
  while (w > 0) and not(flagSea) do
  begin
    if (field[X, w] = Sea) or (field[X, w] = Missed) then
    begin
      flagSea := True;
    end
    else if field[X, w] = Ship then
      flagShipW := false;
    if not flagSea then
      w := w - 1;
  end;
  oneHor := Y - w;
  w := Y;
  flagSea := false;
  while (w < 11) and not(flagSea) do
  begin
    if (field[X, w] = Sea) or (field[X, w] = Missed) then
    begin
      flagSea := True;
    end
    else if field[X, w] = Ship then
      flagShipW := false;
    if not flagSea then
      w := w + 1;
  end;
  if w - Y > oneHor then
    oneHor := w - Y;
  h := X;
  w := Y;
  flagSea := false;
  if (flagShipH) and (oneHor = 1) then
  begin
    while (h > 0) and not(flagSea) do
    begin
      if (field[h, Y] = Sea) or (field[h, Y] = Missed) then
        flagSea := True
      else
      begin
        DrawMissedAfterShipDeath(field, h, Y);
        field[h, Y] := Sunk;
        isDead := True;
      end;
      h := h - 1;
    end;
    h := X;
    flagSea := false;
    while (h < 11) and not(flagSea) do
    begin
      if (field[h, Y] = Sea) or (field[h, Y] = Missed) then
        flagSea := True
      else
      begin
        DrawMissedAfterShipDeath(field, h, Y);
        field[h, Y] := Sunk;
        isDead := True;
      end;
      h := h + 1;
    end;
  end
  else if flagShipW and (oneVert = 1) then
  begin
    flagSea := false;
    while (w > 0) and not(flagSea) do
    begin
      if (field[X, w] = Sea) or (field[X, w] = Missed) then
        flagSea := True
      else
      begin
        DrawMissedAfterShipDeath(field, X, w);
        field[X, w] := Sunk;
        isDead := True;
      end;
      w := w - 1;
    end;
    w := Y;
    flagSea := false;
    while (w < 11) and not(flagSea) do
    begin
      if (field[X, w] = Sea) or (field[X, w] = Missed) then
        flagSea := True
      else
      begin
        DrawMissedAfterShipDeath(field, X, w);
        field[X, w] := Sunk;
        isDead := True;
      end;
      w := w + 1;
    end;
  end;

  if print then
  begin
    if isDead then
      writeln('Убил')
    else
      writeln('Ранил');
    PlaySound('../../zvuk-vzryva.wav', 0, SND_SYNC);
    PlaySound('../../sea.wav', 0, SND_ASYNC or SND_LOOP);
  end;
end;

procedure Fire(var field: TField; const X, Y: Integer; var move: boolean);
begin
  if field[X, Y] = Sea then
  begin
    field[X, Y] := Missed;

    writeln('Промах!');
    PlaySound('../../bulck.wav', 0, SND_SYNC);
    PlaySound('../../sea.wav', 0, SND_ASYNC or SND_LOOP);
    move := not move;
  end
  else if field[X, Y] = Ship then
  begin
    field[X, Y] := Hurt;
    CheckDeath(field, X, Y, True);
  end;
  writeln('Нажмите Enter для продолжения...');
  Readln;
end;

procedure FireBomb(var field: TField; var coord: TUserCoord; var move: boolean);
var
  X, Y, I, j: Integer;
  CoordFlag, isValidCoord, hit: boolean;
begin
  CoordFlag := True;
  while CoordFlag do
  begin
    write('Введите координату для сброса бомбы: ');
    Readln(coord);
    isValidCoord := CheckCoord(coord, field, X, Y);
    if not isValidCoord or (X < 2) or (X > 9) or (Y < 2) or (Y > 9) then
    begin
      writeln('Невалидная координата, повторите попытку');
    end
    else
    begin
      CoordFlag := false;
    end;
  end;

  hit := False;
  for I := X - 1 to X + 1 do
  begin
    for j := Y - 1 to Y + 1 do
    begin
      if field[i, j] = Sea then
      begin
        field[i, j] := Missed;
      end
      else if field[i, j] = Ship then
      begin
        hit := True;
        field[i, j] := Hurt;
        CheckDeath(field, i, j, False);
      end;
    end;
  end;

  if not hit then
  begin
    writeln('Ох, какой промах!');
    move := not move;
    PlaySound('../../bulck.wav', 0, SND_SYNC);
  end
  else
  begin
    writeln('Есть попадание!');
    PlaySound('../../zvuk-vzryva.wav', 0, SND_SYNC);
  end;
  PlaySound('../../sea.wav', 0, SND_ASYNC or SND_LOOP);
  writeln('Нажмите Enter для продолжения...');
  Readln;
end;

procedure FireCluster(var field: TField; var move: boolean);
begin

end;

procedure PlayerMove(const user: Integer; var field: TField;
  var coord: TUserCoord; var move, extra: boolean);
var
  X, Y: Integer;
  CoordFlag: boolean;
begin
  CoordFlag := True;
  while CoordFlag do
  begin
    writeln;
    writeln('Ход игрока номер ', user);
    write('Введите координату: ');
    Readln(coord);
    if (coord = 'бомба') and extra then
    begin
      CoordFlag := false;
      extra := False;
      FireBomb(field, coord, move);
    end
    else if (coord = 'кассета') and extra then
    begin
      CoordFlag := false;
      extra := False;
      FireCluster(field, move);
    end
    else if ((coord = 'бомба') or (coord = 'кассета')) and not extra then
      writeln('Лимит исчерпан, повторите попытку')
    else if not CheckCoord(coord, field, X, Y) then
      writeln('Невалидная координата, повторите попытку')
    else
    begin
      CoordFlag := false;
      Fire(field, X, Y, move);
    end;
  end;

end;

function IsVictory(const field: TField): boolean;
var
  I, j: Integer;
begin
  IsVictory := True;
  for I := 1 to FieldLen do
  begin
    for j := 1 to FieldLen do
    begin
      if (field[I, j] = Ship) or (field[I, j] = Hurt) then
        IsVictory := false;
    end;
  end;
end;

procedure CheckField(var isCorrect: boolean; const field: TField);
var
  I, j, count: Integer;
  countsList: TShipsCount;
begin
  for I := 2 to FieldLen - 1 do
  begin
    for j := 2 to FieldLen - 1 do
    begin
      if ((field[I, j] = Ship) and (field[I - 1, j - 1] = Ship)) or
        ((field[I, j] = Ship) and (field[I + 1, j - 1] = Ship)) or
        ((field[I, j] = Ship) and (field[I - 1, j + 1] = Ship)) or
        ((field[I, j] = Ship) and (field[I + 1, j + 1] = Ship)) or
        ((field[I, j - 1] = Ship) and (field[I - 1, j] = Ship)) or
        ((field[I, j + 1] = Ship) and (field[I - 1, j] = Ship)) or
        ((field[I, j + 1] = Ship) and (field[I + 1, j] = Ship)) or
        ((field[I, j - 1] = Ship) and (field[I + 1, j] = Ship)) then
      begin
        isCorrect := false;
      end;
    end;
  end;

  for I := 1 to 4 do
    countsList[I] := 0;

  count := 0;
  for I := 1 to FieldLen do
  begin
    j := 1;
    while j <= FieldLen do
    begin
      if field[I, j] = Sea then
      begin
        if (count > 0) and (count < 5) then
          countsList[count] := countsList[count] + 1
        else if count > 4 then
          isCorrect := false;
        count := 0;
      end
      else if (I = 1) and (field[I, j] = Ship) and (field[I + 1, j] <> Ship)
      then
        Inc(count)
      else if (I = FieldLen) and (field[I, j] = Ship) and
        (field[I - 1, j] <> Ship) then
        Inc(count)
      else if (I <> FieldLen) and (field[I, j] = Ship) and
        (field[I + 1, j] <> Ship) and (field[I - 1, j] <> Ship) then
        Inc(count);
      Inc(j);
    end;
    if count > 0 then
    begin
      if (count > 0) and (count < 5) then
        countsList[count] := countsList[count] + 1
      else if count > 4 then
        isCorrect := false;
      count := 0;
    end;
  end;

  count := 0;
  for j := 1 to FieldLen do
  begin
    I := 1;
    while I <= FieldLen do
    begin
      if field[I, j] = Sea then
      begin
        if (count > 1) and (count < 5) then
          countsList[count] := countsList[count] + 1
        else if count > 4 then
          isCorrect := false;
        count := 0;
      end
      else if (j = 1) and (field[I, j] = Ship) and (field[I, j + 1] <> Ship)
      then
        Inc(count)
      else if (j = FieldLen) and (field[I, j] = Ship) and
        (field[I, j - 1] <> Ship) then
      begin
        Inc(count)
      end
      else if (j <> FieldLen) and (field[I, j] = Ship) and
        (field[I, j + 1] <> Ship) and (field[I, j - 1] <> Ship) then
        Inc(count);
      Inc(I);
    end;
    if count > 0 then
    begin
      if (count > 1) and (count < 5) then
        countsList[count] := countsList[count] + 1
      else if count > 4 then
        isCorrect := false;
      count := 0;
    end;
  end;

  for I := 1 to 4 do
    if countsList[I] <> 5 - I then
      isCorrect := false;

end;

var
  Player1Field, Player2Field: TField;
  isCorrect, isGameOver, extraPlayer1, extraPlayer2: boolean;
  move, gameMode: boolean;
  coord: TUserCoord;

begin
  move := True;
  extraPlayer1 := True;
  extraPlayer2 := True;
  isCorrect := True;
  isGameOver := false;
  ReadFile(Player1Field, '../../player1ships.txt', isCorrect);
  ReadFile(Player2Field, '../../player2ships.txt', isCorrect);
  CheckField(isCorrect, Player1Field);
  CheckField(isCorrect, Player2Field);
  PlaySound('../../sea.wav', 0, SND_ASYNC or SND_LOOP);
  if isCorrect then
  begin
    while not isGameOver do
    begin
      DrawFields(Player1Field, Player2Field);
      if move then
      begin
        PlayerMove(1, Player2Field, coord, move, extraPlayer1);
        if IsVictory(Player2Field) then
        begin
          DrawFields(Player1Field, Player2Field);
          writeln('Игрок 1 победил!');
          isGameOver := True;
        end;
      end
      else
      begin
        PlayerMove(2, Player1Field, coord, move, extraPlayer2);
        if IsVictory(Player1Field) then
        begin
          DrawFields(Player1Field, Player2Field);
          writeln('Игрок 2 победил!');
          isGameOver := True;
        end;
      end;
    end;
    writeln('Игра окончена, нажмите Enter для выхода...');
  end
  else
    writeln('Неверный формат файла или файл не найден');
  Readln;

end.

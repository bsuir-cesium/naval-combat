program main;

uses
  SysUtils;

const
  FieldLen = 10;
  CoordLetters = 'АБВГДЕЖЗИК';
  CoordDigits = '123456789';

type
  TCoord = string[4];
  TStates = (Sea, Ship, Missed, Hurt, Sunk);
  TField = array [1 .. FieldLen, 1 .. FieldLen] of TStates;

procedure ReadFile(var arr: TField; fname: string; var isCorrect: boolean);
var
  f: textfile;
  s: string[200];
  k: integer;
  I: integer;
begin
  k := 1;
    Assign(f, fname);
    Reset(f);
    while (not EOF(f)) do
    begin
      Readln(f, s);
      s := utf8ToAnsi(s);
      for I := 1 to Length(s) do
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
    Close(f);
end;

procedure DrawFields(const Player1Field, Player2Field: TField);
var
  I, j: integer;
begin
  writeln('   | А | Б | В | Г | Д | Е | Ж | З | И | К |       | А | Б | В | Г | Д | Е | Ж | З | И | К |');
  for I := 1 to FieldLen do
  begin
    write(I:2, ' |');
    for j := 1 to FieldLen do
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
    for j := 1 to FieldLen do
    begin
      if (Player2Field[I, j] = Ship) or (Player1Field[I, j] = Sea) then
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

function CheckCoord(const coord: TCoord): boolean;
var
  len: integer;
begin
  // Добавить проверку на уже заюзаную корду
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
    Exit(True);
end;

procedure PlayerMove(const hod: integer; var move: boolean; var coord: TCoord);
begin
  while True do
  begin
    writeln;
    writeln('Ход игрока номер ', hod);
    write('Введите координату: ');
    Readln(coord);
    if not CheckCoord(coord) then
    begin
      writeln('Ошибка ввода, повторите попытку');
      continue;
    end;

    break;
  end;
  move := not move;
end;

var
  Player1Field, Player2Field: TField;
  isCorrect, isGameOver: boolean;
  move: boolean;
  coord: TCoord;

begin
  move := True;
  isCorrect := True;
  isGameOver := false;
  ReadFile(Player1Field, './player1ships.txt', isCorrect);
  ReadFile(Player2Field, './player2ships.txt', isCorrect);

  if isCorrect then
  begin
    while not isGameOver do
    begin
      DrawFields(Player1Field, Player2Field);
      if move then
      begin
        PlayerMove(1, move, coord);
      end
      else
      begin
        PlayerMove(2, move, coord);
      end;

      Readln;
    end;
  end
  else
    writeln('Неверный формат файла или файл не найден');
  Readln;

end.

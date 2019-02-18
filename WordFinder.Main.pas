unit WordFinder.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections,
  Vcl.ComCtrls;

type
  //Матрица символов из полей
  TChars = array[1..5, 1..5] of Char;
  //Состояние символа соответственно матрице символов. Занят или нет и порядковый номер
  TCharState = record
   State:Boolean;
   Ord:Integer;
  end;
  //Матрица состояния символов
  TCharsState = array[1..5, 1..5] of TCharState;
  //Данные слова
  TWordData = record
   Text:string;     //Слово
   Gifts:Integer;
   Mask:TCharsState;//Матрица состояний, чтоб отобразить при выборе
  end;
  //Список найденных слов
  TWords = class(TList<TWordData>)
   //Поиск слова в списке
   function IndexOf(Text:string):Integer;
  end;

  TFormMain = class(TForm)
    Panel1: TPanel;
    ButtonFind: TButton;
    PanelPad: TPanel;
    EditLet1: TEdit;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    Edit14: TEdit;
    Edit15: TEdit;
    Edit16: TEdit;
    Edit17: TEdit;
    Edit18: TEdit;
    Edit19: TEdit;
    Edit20: TEdit;
    Edit21: TEdit;
    Edit22: TEdit;
    Edit23: TEdit;
    Edit24: TEdit;
    ListViewWords: TListView;
    Label1: TLabel;
    LabelWrdCount: TLabel;
    ButtonRandom: TButton;
    ButtonClose: TButton;
    ButtonAbout: TButton;
    ButtonClear: TButton;
    procedure EditLet1Click(Sender: TObject);
    procedure EditLet1KeyPress(Sender: TObject; var Key: Char);
    procedure ButtonFindClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListViewWordsClick(Sender: TObject);
    procedure ListViewWordsDblClick(Sender: TObject);
    procedure ListViewWordsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure EditFieldChange(Sender: TObject);
    procedure ButtonRandomClick(Sender: TObject);
    procedure ButtonCloseClick(Sender: TObject);
    procedure ButtonAboutClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
  private
    FChars:TChars;
    FCharsState:TCharsState;
    Dict:TStringList;
    FWords:TWords;
    FFieldGifts:TCharsState;
    procedure UpdateGifts;
    function CalcGifts(States:TCharsState):Integer;
  public
    destructor Destroy; override;
  end;

var
  FormMain: TFormMain;

implementation
 uses Math, HGM.Common.Utils, ShellApi;

{$R *.dfm}

function CharState(AState:Boolean; AOrd:Integer):TCharState;
begin
 Result.State:=AState;
 Result.Ord:=AOrd;
end;

//Очистка состояния символов
procedure ClearState(var States:TCharsState);
var x, y:Integer;
begin
 for x:= 1 to 5 do
  for y:= 1 to 5 do
   States[x, y]:=CharState(False, 0);
end;

procedure TFormMain.ButtonAboutClick(Sender: TObject);
begin
 MessageBox(Handle,
  'Разработчик: Геннадий Малинин aka HemulGM'+#13+#10+
  'Delphi, 2019 год'+#13+#10+
  'Программа для поиска слов в матрице символов 5х5'+#13+#10+
  'Сайт: www.hemulgm.ru',
  '', MB_ICONINFORMATION or MB_OK);
end;

procedure TFormMain.ButtonClearClick(Sender: TObject);
begin
 ClearState(FFieldGifts);
 UpdateGifts;
end;

procedure TFormMain.ButtonCloseClick(Sender: TObject);
begin
 Application.Terminate;
end;

procedure TFormMain.ButtonFindClick(Sender: TObject);
var i, y, x: Integer;
    Wrd:string;
    Item:TWordData;

//Проверка координаты на корректность и доступность
function CheckCoord(xv, yv:Integer):Boolean;
begin
 Result:=False;
 //Проверка границ
 if (xv < 1) or (yv < 1) then Exit;
 if (xv > 5) or (yv > 5) then Exit;
 //Проверка на доступность
 Result:=not FCharsState[xv, yv].State;
end;

//Поиск следующего символа относительно текущей позиции
function FindNext(x1, y1, c:Integer):Boolean;
var nx, ny, vr:Integer;
begin
 //Если длина слова равна текущему символу, то слово собрано, выходим
 if Wrd.Length = c then Exit(True);

 Result:=False;
 nx:=0;
 ny:=0;
 //8 вариантов направления   //5 2 8
 for vr:= 1 to 8 do          //3 x 6
  begin                      //4 1 7
   case vr of
    1: begin nx:=x1;   ny:=y1+1; end;
    2: begin nx:=x1;   ny:=y1-1; end;

    3: begin nx:=x1-1; ny:=y1;   end;
    4: begin nx:=x1-1; ny:=y1-1; end;
    5: begin nx:=x1-1; ny:=y1+1; end;

    6: begin nx:=x1+1; ny:=y1;   end;
    7: begin nx:=x1+1; ny:=y1+1; end;
    8: begin nx:=x1+1; ny:=y1-1; end;
   end;
   //Проверяем полученное смещение на границы массива и на не занятость
   if CheckCoord(nx, ny) then
    begin
     //Если наш символ как раз совпадает со следующим символом в слове,
     if FChars[nx, ny] = Wrd[c+1] then
      begin
       FCharsState[nx, ny]:=CharState(True, c); //То устанавливаем состояние - занят и его порядок в слове
       Result:=FindNext(nx, ny, c+1);           //И передаем далее рекурсивно
       if not Result then                       //Если дальше не нашли ничего
        FCharsState[nx, ny]:=CharState(False, 0)//То текущий символ освобождаем
       else Exit;                               //А если всё нашли, то далее можно не продолжать
      end;
    end;
  end;
end;

begin
 //Собираем данные из полей в массив
 for i:= 0 to PanelPad.ControlCount-1 do
  begin
   if PanelPad.Controls[i] is TEdit then
    begin
     x:=(PanelPad.Controls[i] as TEdit).Tag;
     FChars[(x-1) mod 5+1, (x-1) div 5+1]:=AnsiLowerCase((PanelPad.Controls[i] as TEdit).Text)[1];
    end;
  end;
 //Основной цикл поиска слов
 FWords.Clear;                                  //Очистим список слов
 if Dict.Count > 0 then
  begin
   for i:= 0 to Dict.Count-1 do
    begin
     Wrd:=Dict[i];                                //Берём слово из словаря
     if Wrd.Length < 3 then Continue;             //Если оно менее 3, то пропускаем
     ClearState(FCharsState);                     //Очищаем состояние матрицы отмеченных символов
     for y:= 1 to 5 do                            //Идём по матрице символов
      for x := 1 to 5 do
       begin                                      //Если символ в матрице является началом слова
        if Dict[i][1] = AnsiLowerCase(FChars[x, y])[1] then
         begin
          FCharsState[x, y]:=CharState(True, 1);  //То, устанвляиваем состояние текущего символа - занят
          if FindNext(x, y, 1) then               //Передаем на поиск следующих символов слова
           begin                                  //Если нашли всё слово
            if FWords.IndexOf(Wrd) < 0 then       //И его уже нет в списке
             begin                                //То добавляем его в список
              Item.Text:=Wrd;                     //Слово
              Item.Mask:=FCharsState;             //Состояние символов
              FWords.Add(Item);                   //
             end;
           end;
          ClearState(FCharsState);                //Каждый раз очищаем состояние, чтоб ничего не осталось
         end;
       end;
    end;
   for x:=0 to FWords.Count-1 do
    begin
     Item:=FWords[x];
     Item.Gifts:=CalcGifts(Item.Mask);
     FWords[x]:=Item;
    end;
   //Процесс поиска закончен, отображаем результат
   //Сортируем по количеству символов в слове
   for x:=0 to FWords.Count-1 do
    begin
     Item:=FWords[x];
     Item.Gifts:=CalcGifts(Item.Mask);
     FWords[x]:=Item;
     for i:=0 to FWords.Count-2 do
      if FWords[i].Text.Length < FWords[i+1].Text.Length then
       begin
        Item:=FWords[i];
        FWords[i]:=FWords[i+1];
        FWords[i+1]:=Item;
       end;
    end;
   //Процесс поиска закончен, отображаем результат
   //Сортируем по количеству символов в слове
   for x:=0 to FWords.Count-1 do
    for i:=0 to FWords.Count-2 do
     if (FWords[i].Gifts < FWords[i+1].Gifts) and (FWords[i+1].Text.Length > 4) then
      begin
       Item:=FWords[i];
       FWords[i]:=FWords[i+1];
       FWords[i+1]:=Item;
      end;
  end
 else
  MessageBox(Handle, 'Необходим файл словаря dict.txt в каталоге с программой!', 'Внимание', MB_ICONWARNING or MB_OK);
 //Добавляем в список слова
 ListViewWords.Items.BeginUpdate;
 ListViewWords.Items.Clear;
 for i:= 0 to FWords.Count-1 do
  ListViewWords.Items.Add.Caption:=FWords[i].Text;
 ListViewWords.Items.EndUpdate;
 //Если хоть одно слово нашли,
 if ListViewWords.Items.Count > 0 then
  begin
   ListViewWords.ItemIndex:=0; //то выбираем первое
  end;
 //Покажем, сколько слов нашли
 LabelWrdCount.Caption:=IntToStr(ListViewWords.Items.Count);
 ListViewWordsClick(nil);    //И выделяем его в полях
end;

procedure TFormMain.ButtonRandomClick(Sender: TObject);
var i:Integer;
begin
 for i:= 0 to PanelPad.ControlCount-1 do
  if PanelPad.Controls[i] is TEdit then
   (PanelPad.Controls[i] as TEdit).Text:=AnsiChar(RandomRange(Ord('А'), Ord('Я')+1));
 ClearState(FFieldGifts);
 UpdateGifts;
 ButtonFindClick(nil);
end;

function TFormMain.CalcGifts(States: TCharsState): Integer;
var y, x: Integer;
begin
 Result:=0;
 for y:= 1 to 5 do
  for x:= 1 to 5 do
   if States[x, y].State and FFieldGifts[x, y].State then Inc(Result);
end;

destructor TFormMain.Destroy;
begin
 Dict.Free;
 FWords.Free;
 inherited;
end;

procedure TFormMain.EditFieldChange(Sender: TObject);
begin
 //Если наша ячейка последняя, то выполним поиск автоматически
 if (Sender as TEdit).Tag = 25 then ButtonFindClick(nil);
end;

procedure TFormMain.EditLet1Click(Sender: TObject);
begin
 (Sender as TEdit).SelectAll;
end;

procedure TFormMain.EditLet1KeyPress(Sender: TObject; var Key: Char);
var x:Integer;
    Item:TCharState;
begin
 case Key of
  #13: Key:=#0;
  ' ':
   begin
    Key:=#0;
    x:=(Sender as TEdit).Tag;
    Item:=FFieldGifts[(x-1) mod 5+1, (x-1) div 5+1];
    Item.State:=not Item.State;
    FFieldGifts[(x-1) mod 5+1, (x-1) div 5+1]:=Item;
    UpdateGifts;
   end;
 end;
 //Следующее поле по TabOrder
 SelectNext((Sender as TEdit), True, True);
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
 ClientHeight:=480;
 ClientWidth:=530;
 //Создаем и загружаем словарь
 Dict:=TStringList.Create;
 if FileExists('dict.txt') then
  try
   Dict.LoadFromFile('dict.txt')
  except
   MessageBox(Handle, 'Необходим файл словаря dict.txt в каталоге с программой!', 'Внимание', MB_ICONWARNING or MB_OK);
  end
 else
  MessageBox(Handle, 'Необходим файл словаря dict.txt в каталоге с программой!', 'Внимание', MB_ICONWARNING or MB_OK);
 //Список найденных слов
 FWords:=TWords.Create;
end;

procedure TFormMain.ListViewWordsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
 ListViewWordsClick(nil);
end;

procedure TFormMain.ListViewWordsClick(Sender: TObject);
var x, y, t: Integer;
    Item:TWordData;
begin
 //Очищаем цвет полей
 for x:= 0 to PanelPad.ControlCount-1 do
  if PanelPad.Controls[x] is TEdit then
    (PanelPad.Controls[x] as TEdit).Color:=clWhite;
 //Если выбран элемент
 if ListViewWords.ItemIndex >= 0 then
  begin
   //Выбранный элемент
   Item:=FWords[ListViewWords.ItemIndex];
   //Идём по матрице символов
   for y:= 1 to 5 do
    for x:= 1 to 5 do
     begin
      //Если символ использовался, то ищем нужное поле
      //и указываем цвет выделения и степень его насыщенности в зависимости от порядкового номера в слове
      if Item.Mask[x, y].State then
       for t:= 0 to PanelPad.ControlCount-1 do
        if PanelPad.Controls[t] is TEdit then   //Координаты в номер
         if (PanelPad.Controls[t] as TEdit).Tag = (y-1) * 5 + 1 + (x-1) then
          begin
           (PanelPad.Controls[t] as TEdit).Color:=ColorLighter($00A85400, Item.Mask[x, y].Ord * 8);
          end;
     end;
  end;
end;

procedure TFormMain.ListViewWordsDblClick(Sender: TObject);
begin
 if ListViewWords.ItemIndex >= 0 then
  begin
   ShellExecute(Handle, 'open', PWideChar('http://gramota.ru/slovari/dic/?word='+ListViewWords.Items[ListViewWords.ItemIndex].Caption+'&all=x'), nil, nil, SW_NORMAL);
  end;
end;

procedure TFormMain.UpdateGifts;
var x, y, t: Integer;
begin
 //Очищаем цвет полей
 for x:= 0 to PanelPad.ControlCount-1 do
  if PanelPad.Controls[x] is TEdit then
    (PanelPad.Controls[x] as TEdit).Font.Color:=clBlack;
 for y:= 1 to 5 do
  for x:= 1 to 5 do
   begin
    if FFieldGifts[x, y].State then
     for t:= 0 to PanelPad.ControlCount-1 do
      if PanelPad.Controls[t] is TEdit then   //Координаты в номер
       if (PanelPad.Controls[t] as TEdit).Tag = (y-1) * 5 + 1 + (x-1) then
        begin
         (PanelPad.Controls[t] as TEdit).Font.Color:=$00007DFA;
        end;
   end;
end;

{ TWords }

function TWords.IndexOf(Text: string): Integer;
var i: Integer;
begin
 Result:=-1;
 for i:= 0 to Count-1 do
  if Items[i].Text = Text then Exit(i);
end;

end.

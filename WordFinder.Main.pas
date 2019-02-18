unit WordFinder.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections,
  Vcl.ComCtrls;

type
  //������� �������� �� �����
  TChars = array[1..5, 1..5] of Char;
  //��������� ������� �������������� ������� ��������. ����� ��� ��� � ���������� �����
  TCharState = record
   State:Boolean;
   Ord:Integer;
  end;
  //������� ��������� ��������
  TCharsState = array[1..5, 1..5] of TCharState;
  //������ �����
  TWordData = record
   Text:string;     //�����
   Gifts:Integer;
   Mask:TCharsState;//������� ���������, ���� ���������� ��� ������
  end;
  //������ ��������� ����
  TWords = class(TList<TWordData>)
   //����� ����� � ������
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

//������� ��������� ��������
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
  '�����������: �������� ������� aka HemulGM'+#13+#10+
  'Delphi, 2019 ���'+#13+#10+
  '��������� ��� ������ ���� � ������� �������� 5�5'+#13+#10+
  '����: www.hemulgm.ru',
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

//�������� ���������� �� ������������ � �����������
function CheckCoord(xv, yv:Integer):Boolean;
begin
 Result:=False;
 //�������� ������
 if (xv < 1) or (yv < 1) then Exit;
 if (xv > 5) or (yv > 5) then Exit;
 //�������� �� �����������
 Result:=not FCharsState[xv, yv].State;
end;

//����� ���������� ������� ������������ ������� �������
function FindNext(x1, y1, c:Integer):Boolean;
var nx, ny, vr:Integer;
begin
 //���� ����� ����� ����� �������� �������, �� ����� �������, �������
 if Wrd.Length = c then Exit(True);

 Result:=False;
 nx:=0;
 ny:=0;
 //8 ��������� �����������   //5 2 8
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
   //��������� ���������� �������� �� ������� ������� � �� �� ���������
   if CheckCoord(nx, ny) then
    begin
     //���� ��� ������ ��� ��� ��������� �� ��������� �������� � �����,
     if FChars[nx, ny] = Wrd[c+1] then
      begin
       FCharsState[nx, ny]:=CharState(True, c); //�� ������������� ��������� - ����� � ��� ������� � �����
       Result:=FindNext(nx, ny, c+1);           //� �������� ����� ����������
       if not Result then                       //���� ������ �� ����� ������
        FCharsState[nx, ny]:=CharState(False, 0)//�� ������� ������ �����������
       else Exit;                               //� ���� �� �����, �� ����� ����� �� ����������
      end;
    end;
  end;
end;

begin
 //�������� ������ �� ����� � ������
 for i:= 0 to PanelPad.ControlCount-1 do
  begin
   if PanelPad.Controls[i] is TEdit then
    begin
     x:=(PanelPad.Controls[i] as TEdit).Tag;
     FChars[(x-1) mod 5+1, (x-1) div 5+1]:=AnsiLowerCase((PanelPad.Controls[i] as TEdit).Text)[1];
    end;
  end;
 //�������� ���� ������ ����
 FWords.Clear;                                  //������� ������ ����
 if Dict.Count > 0 then
  begin
   for i:= 0 to Dict.Count-1 do
    begin
     Wrd:=Dict[i];                                //���� ����� �� �������
     if Wrd.Length < 3 then Continue;             //���� ��� ����� 3, �� ����������
     ClearState(FCharsState);                     //������� ��������� ������� ���������� ��������
     for y:= 1 to 5 do                            //��� �� ������� ��������
      for x := 1 to 5 do
       begin                                      //���� ������ � ������� �������� ������� �����
        if Dict[i][1] = AnsiLowerCase(FChars[x, y])[1] then
         begin
          FCharsState[x, y]:=CharState(True, 1);  //��, ������������� ��������� �������� ������� - �����
          if FindNext(x, y, 1) then               //�������� �� ����� ��������� �������� �����
           begin                                  //���� ����� �� �����
            if FWords.IndexOf(Wrd) < 0 then       //� ��� ��� ��� � ������
             begin                                //�� ��������� ��� � ������
              Item.Text:=Wrd;                     //�����
              Item.Mask:=FCharsState;             //��������� ��������
              FWords.Add(Item);                   //
             end;
           end;
          ClearState(FCharsState);                //������ ��� ������� ���������, ���� ������ �� ��������
         end;
       end;
    end;
   for x:=0 to FWords.Count-1 do
    begin
     Item:=FWords[x];
     Item.Gifts:=CalcGifts(Item.Mask);
     FWords[x]:=Item;
    end;
   //������� ������ ��������, ���������� ���������
   //��������� �� ���������� �������� � �����
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
   //������� ������ ��������, ���������� ���������
   //��������� �� ���������� �������� � �����
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
  MessageBox(Handle, '��������� ���� ������� dict.txt � �������� � ����������!', '��������', MB_ICONWARNING or MB_OK);
 //��������� � ������ �����
 ListViewWords.Items.BeginUpdate;
 ListViewWords.Items.Clear;
 for i:= 0 to FWords.Count-1 do
  ListViewWords.Items.Add.Caption:=FWords[i].Text;
 ListViewWords.Items.EndUpdate;
 //���� ���� ���� ����� �����,
 if ListViewWords.Items.Count > 0 then
  begin
   ListViewWords.ItemIndex:=0; //�� �������� ������
  end;
 //�������, ������� ���� �����
 LabelWrdCount.Caption:=IntToStr(ListViewWords.Items.Count);
 ListViewWordsClick(nil);    //� �������� ��� � �����
end;

procedure TFormMain.ButtonRandomClick(Sender: TObject);
var i:Integer;
begin
 for i:= 0 to PanelPad.ControlCount-1 do
  if PanelPad.Controls[i] is TEdit then
   (PanelPad.Controls[i] as TEdit).Text:=AnsiChar(RandomRange(Ord('�'), Ord('�')+1));
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
 //���� ���� ������ ���������, �� �������� ����� �������������
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
 //��������� ���� �� TabOrder
 SelectNext((Sender as TEdit), True, True);
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
 ClientHeight:=480;
 ClientWidth:=530;
 //������� � ��������� �������
 Dict:=TStringList.Create;
 if FileExists('dict.txt') then
  try
   Dict.LoadFromFile('dict.txt')
  except
   MessageBox(Handle, '��������� ���� ������� dict.txt � �������� � ����������!', '��������', MB_ICONWARNING or MB_OK);
  end
 else
  MessageBox(Handle, '��������� ���� ������� dict.txt � �������� � ����������!', '��������', MB_ICONWARNING or MB_OK);
 //������ ��������� ����
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
 //������� ���� �����
 for x:= 0 to PanelPad.ControlCount-1 do
  if PanelPad.Controls[x] is TEdit then
    (PanelPad.Controls[x] as TEdit).Color:=clWhite;
 //���� ������ �������
 if ListViewWords.ItemIndex >= 0 then
  begin
   //��������� �������
   Item:=FWords[ListViewWords.ItemIndex];
   //��� �� ������� ��������
   for y:= 1 to 5 do
    for x:= 1 to 5 do
     begin
      //���� ������ �������������, �� ���� ������ ����
      //� ��������� ���� ��������� � ������� ��� ������������ � ����������� �� ����������� ������ � �����
      if Item.Mask[x, y].State then
       for t:= 0 to PanelPad.ControlCount-1 do
        if PanelPad.Controls[t] is TEdit then   //���������� � �����
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
 //������� ���� �����
 for x:= 0 to PanelPad.ControlCount-1 do
  if PanelPad.Controls[x] is TEdit then
    (PanelPad.Controls[x] as TEdit).Font.Color:=clBlack;
 for y:= 1 to 5 do
  for x:= 1 to 5 do
   begin
    if FFieldGifts[x, y].State then
     for t:= 0 to PanelPad.ControlCount-1 do
      if PanelPad.Controls[t] is TEdit then   //���������� � �����
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

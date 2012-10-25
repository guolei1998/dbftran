unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DirectDBF, ExtCtrls,DateUtils;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    Button1: TButton;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    dbf:TDirectDBF;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
uses
  UnicodeConv;
{$R *.dfm}




procedure TForm1.FormCreate(Sender: TObject);
begin
  dbf:=TDirectDBF.Create(Self);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  dbf.Free;
end;

function trans: Integer; stdcall;
var
  i:Integer;
  a,b:string;
  c,d:Integer;
  tmp:string;
  tmp2:WideString;
begin
  with Form1 do begin
    dbf.DbfFileName := OpenDialog1.FileName;
    dbf.Open;
    if dbf.RecordCount > 0 then begin
      dbf.first;

      while not dbf.Eof do begin
        dbf.Edit;
        for i := 0 to dbf.FieldCount -1 do begin
          dbf.GetFieldAttributes(i,a,b,c,d);
          if b = 'C' then begin
            dbf.GetStringValue(a,tmp);
            try
              tmp2:=UTF8ToUTF16BEStr(tmp);
            except
              tmp2:='';
            end;
            //Memo1.Lines.Add(tmp2);

            dbf.SetStringValue(a,tmp2);
           // Application.ProcessMessages;
          end;

        end;
        dbf.post;
        dbf.next;
        
      end;
      
    end;
     dbf.close;
  end;


  //  Form1.Button1.Enabled := True;
    Form1.Button1.Caption := '转换完毕！';

end;


procedure TForm1.Button1Click(Sender: TObject);

var
  tmphndl:THandle;
  tmpint:Cardinal;
begin
  if not OpenDialog1.Execute then Exit;
  Button1.Enabled := False;
  Form1.Button1.Caption := '正在转换...';
 // Timer1.Enabled := True;
    tmphndl:=CreateThread(nil, 0, @trans, nil, 0, tmpint);

  //  WaitForSingleObject(tmphndl,INFINITE) ;
    //
    CloseHandle(tmphndl);


end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  a:integer;
begin
  a:= SecondOfTheYear(now);
  if a mod 3= 0 then begin
    Button1.Caption := '转换.';
  end;
  if a mod 3= 1 then begin
    Button1.Caption := '转换..';
  end;
  if a mod 3= 2 then begin
    Button1.Caption := '转换...';
  end;
  if a mod 3= 3 then begin
    Button1.Caption := '转换....';
  end;
  if  Button1.Caption = '转换' then begin
    Timer1.Enabled := False;
    ShowMessage('转换成功');
  end;
end;

end.

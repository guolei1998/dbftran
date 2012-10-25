object Form1: TForm1
  Left = 215
  Top = 134
  BorderStyle = bsDialog
  Caption = 'UTF8'#36716'MBCS'
  ClientHeight = 106
  ClientWidth = 211
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 64
    Top = 32
    Width = 97
    Height = 33
    Caption = #36716#25442
    TabOrder = 0
    OnClick = Button1Click
  end
  object OpenDialog1: TOpenDialog
    Left = 40
    Top = 32
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 168
    Top = 32
  end
end

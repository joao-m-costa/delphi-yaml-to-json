object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'YAML vs JSON'
  ClientHeight = 446
  ClientWidth = 848
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 848
    Height = 446
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'JSON to YAML'
      ExplicitWidth = 281
      ExplicitHeight = 165
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 840
        Height = 41
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object Label1: TLabel
          Left = 15
          Top = 12
          Width = 20
          Height = 13
          Caption = 'File:'
        end
        object ComboBox1: TComboBox
          Left = 56
          Top = 9
          Width = 137
          Height = 21
          TabOrder = 0
          OnChange = ComboBox1Change
          Items.Strings = (
            '1.json'
            '2.json'
            '3.json'
            '4.json'
            '5.json'
            '6.json')
        end
        object Button1: TButton
          Left = 208
          Top = 7
          Width = 129
          Height = 25
          Caption = 'Convert to YAML'
          TabOrder = 1
          OnClick = Button1Click
        end
      end
      object Memo1: TMemo
        Left = 0
        Top = 41
        Width = 840
        Height = 377
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Lucida Console'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 1
        ExplicitTop = 39
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'YAML to JSON'
      ImageIndex = 1
      ExplicitWidth = 281
      ExplicitHeight = 165
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 840
        Height = 41
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitLeft = 368
        ExplicitTop = 72
        ExplicitWidth = 185
        object Label2: TLabel
          Left = 15
          Top = 12
          Width = 20
          Height = 13
          Caption = 'File:'
        end
        object ComboBox2: TComboBox
          Left = 56
          Top = 9
          Width = 137
          Height = 21
          TabOrder = 0
          OnChange = ComboBox2Change
          Items.Strings = (
            '1.yaml'
            '2.yaml'
            '3.yaml'
            '4.yaml'
            '5.yaml'
            '6.yaml')
        end
        object Button2: TButton
          Left = 208
          Top = 7
          Width = 129
          Height = 25
          Caption = 'Convert to JSON'
          TabOrder = 1
          OnClick = Button2Click
        end
      end
      object Memo2: TMemo
        Left = 0
        Top = 41
        Width = 840
        Height = 377
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Lucida Console'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 1
        ExplicitLeft = 288
        ExplicitTop = 168
        ExplicitWidth = 185
        ExplicitHeight = 89
      end
    end
  end
end

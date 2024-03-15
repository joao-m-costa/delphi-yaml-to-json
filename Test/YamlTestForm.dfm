object YamlVsJsonForm: TYamlVsJsonForm
  Left = 0
  Top = 0
  Caption = 'YAML vs JSON'
  ClientHeight = 647
  ClientWidth = 933
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 15
  object Pages: TPageControl
    Left = 0
    Top = 0
    Width = 933
    Height = 647
    ActivePage = TabYamlToJson
    Align = alClient
    TabHeight = 30
    TabOrder = 0
    ExplicitWidth = 929
    ExplicitHeight = 646
    object TabYamlToJson: TTabSheet
      Caption = 'YAML to JSON'
      object PanelYaml: TPanel
        Left = 0
        Top = 0
        Width = 925
        Height = 41
        Align = alTop
        BevelEdges = [beBottom]
        BevelKind = bkFlat
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitWidth = 921
        object LabelToJson: TLabel
          Left = 15
          Top = 12
          Width = 21
          Height = 15
          Caption = 'File:'
        end
        object YamlFile: TComboBox
          Left = 56
          Top = 9
          Width = 137
          Height = 23
          TabOrder = 0
          OnChange = YamlFileChange
        end
        object BtnToJson: TButton
          Left = 208
          Top = 7
          Width = 129
          Height = 25
          Caption = 'Convert to JSON'
          TabOrder = 1
          OnClick = BtnToJsonClick
        end
      end
      object DataYaml: TMemo
        Left = 0
        Top = 41
        Width = 925
        Height = 566
        Align = alClient
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Lucida Console'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 1
        ExplicitWidth = 921
        ExplicitHeight = 565
      end
    end
    object TabJsonToYaml: TTabSheet
      Caption = 'JSON to YAML'
      ImageIndex = 1
      object PaneljSON: TPanel
        Left = 0
        Top = 0
        Width = 925
        Height = 41
        Align = alTop
        BevelEdges = [beBottom]
        BevelKind = bkFlat
        BevelOuter = bvNone
        TabOrder = 0
        object LabelToYaml: TLabel
          Left = 15
          Top = 12
          Width = 21
          Height = 15
          Caption = 'File:'
        end
        object JsonFile: TComboBox
          Left = 56
          Top = 9
          Width = 137
          Height = 23
          TabOrder = 0
          OnChange = JsonFileChange
        end
        object BtnToYaml: TButton
          Left = 208
          Top = 7
          Width = 129
          Height = 25
          Caption = 'Convert to YAML'
          TabOrder = 1
          OnClick = BtnToYamlClick
        end
      end
      object DataJson: TMemo
        Left = 0
        Top = 41
        Width = 925
        Height = 566
        Align = alClient
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Lucida Console'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 1
      end
    end
  end
end

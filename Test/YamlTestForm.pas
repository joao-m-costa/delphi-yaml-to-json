unit YamlTestForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Types,
  Vcl.Graphics,  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TYamlVsJsonForm = class(TForm)
    Pages: TPageControl;
    TabYamlToJson: TTabSheet;
    TabJsonToYaml: TTabSheet;
    PanelYaml: TPanel;
    DataYaml: TMemo;
    LabelToJson: TLabel;
    YamlFile: TComboBox;
    BtnToJson: TButton;
    PaneljSON: TPanel;
    LabelToYaml: TLabel;
    JsonFile: TComboBox;
    BtnToYaml: TButton;
    DataJson: TMemo;
    procedure YamlFileChange(Sender: TObject);
    procedure BtnToJsonClick(Sender: TObject);
    procedure JsonFileChange(Sender: TObject);
    procedure BtnToYamlClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  YamlVsJsonForm: TYamlVsJsonForm;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.JSON, System.JSON.Types, Costate.Utils.Yaml;



procedure TYamlVsJsonForm.BtnToJsonClick(Sender: TObject);
var
  LData: string;
  LJSONVal: TJSONValue;
begin
  if DataYaml.Lines.Count <= 0 then
    raise Exception.Create('Please select a YAML source first.');
  LData := DataYaml.Lines.Text;
  DataYaml.Lines.Clear;
  DataYaml.Lines.Text := Costate.Utils.Yaml.TYamlUtils.YamlToJson( LData, 2 );
  // Check the JSON is valid
  try
    LJSONVal := TJSONObject.ParseJSONValue(DataYaml.Lines.Text, False, True);
  finally
    FreeAndNil( LJSONVal );
  end;
end;

procedure TYamlVsJsonForm.BtnToYamlClick(Sender: TObject);
var
  LJSONVal: TJSONValue;
begin
  if DataJson.Lines.Count <= 0 then
    raise Exception.Create('Please select a JSON source first.');
  LJSONVal := TJSONObject.ParseJSONValue(DataJson.Lines.Text, False, True);
  DataJson.Lines.Clear;
  Costate.Utils.Yaml.TYamlUtils.JsonToYaml( LJSONVal, DataJson.Lines, 2 );
end;


procedure TYamlVsJsonForm.FormShow(Sender: TObject);
var
  LCurrDir: string;
  LFiles: TStringDynArray;
  I: Integer;
begin
  // Read file names ...
  LCurrDir := System.SysUtils.ExtractFilePath(Application.ExeName);
  // Yaml
  LFiles := System.IOUtils.TDirectory.GetFiles( LCurrDir, '*.yaml' );
  for I := 0 to Length(LFiles) - 1 do
    YamlFile.Items.Add( System.SysUtils.ExtractFileName(LFiles[I]) );
  // Json
  LFiles := System.IOUtils.TDirectory.GetFiles( LCurrDir, '*.json' );
  for I := 0 to Length(LFiles) - 1 do
    JsonFile.Items.Add( System.SysUtils.ExtractFileName(LFiles[I]) );
  Pages.ActivePageIndex := 0;
end;

procedure TYamlVsJsonForm.JsonFileChange(Sender: TObject);
var
  LFile: string;
  LData: string;
  LJSONVal: TJSONValue;
begin
  LJSONVal := nil;
  DataJson.Lines.Clear;
  if JsonFile.ItemIndex >= 0 then
    begin
      LFile := ExtractFilePath( Application.ExeName ) + JsonFile.Items[ JsonFile.ItemIndex ];
      LData := TFile.ReadAllText( LFile );
      // Check source is a valid JSON
      try
        LJSONVal := TJSONObject.ParseJSONValue(LData, False, True);
      finally
        FreeAndNil( LJSONVal );
      end;
      // Show it
      DataJson.Lines.Text := LData;
    end;
end;

procedure TYamlVsJsonForm.YamlFileChange(Sender: TObject);
var
  LFile: string;
begin
  DataYaml.Lines.Clear;
  if YamlFile.ItemIndex >= 0 then
    begin
      LFile := ExtractFilePath( Application.ExeName ) + YamlFile.Items[ YamlFile.ItemIndex ];
      DataYaml.Lines.LoadFromFile( LFile );
    end;
end;

end.

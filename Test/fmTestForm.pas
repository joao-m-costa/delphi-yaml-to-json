unit fmTestForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Panel1: TPanel;
    Panel2: TPanel;
    ComboBox1: TComboBox;
    Button1: TButton;
    Label1: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    Label2: TLabel;
    ComboBox2: TComboBox;
    Button2: TButton;
    procedure ComboBox1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.JSON, System.JSON.Types, Costate.Utils.Yaml;


procedure TForm1.Button1Click(Sender: TObject);
var
  LJSONVal: TJSONValue;
begin
  if Memo1.Lines.Count <= 0 then
    raise Exception.Create('Please select a JSON source first.');
  LJSONVal := TJSONObject.ParseJSONValue(Memo1.Lines.Text, False, True);
  Memo1.Lines.Clear;
  TYamlUtils.JsonToYaml( LJSONVal, Memo1.Lines, 2 );
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  LData: string;
  LJSONVal: TJSONValue;
begin
  LData := Memo2.Lines.Text;
  Memo2.Lines.Clear;
  Memo2.Lines.Text := TYamlUtils.YamlToJson( LData, 2 );
  // Check the JSON is valid
  try
    LJSONVal := TJSONObject.ParseJSONValue(Memo2.Lines.Text, False, True);
  finally
    FreeAndNil( LJSONVal );
  end;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
var
  LFile: string;
  LData: string;
  LJSONVal: TJSONValue;
begin
  LJSONVal := nil;
  if ComboBox1.ItemIndex >= 0 then
    begin
      LFile := ExtractFilePath( Application.ExeName ) + ComboBox1.Items[ ComboBox1.ItemIndex ];
      LData := TFile.ReadAllText( LFile );
      // Check source is a valid JSON
      try
        LJSONVal := TJSONObject.ParseJSONValue(LData, False, True);
      finally
        FreeAndNil( LJSONVal );
      end;
      // Show it
      Memo1.Lines.Clear;
      Memo1.Lines.Text := LData;
    end;
end;

procedure TForm1.ComboBox2Change(Sender: TObject);
var
  LFile: string;
begin
  if ComboBox2.ItemIndex >= 0 then
    begin
      LFile := ExtractFilePath( Application.ExeName ) + ComboBox2.Items[ ComboBox2.ItemIndex ];
      Memo2.Lines.Clear;
      Memo2.Lines.LoadFromFile( LFile );
    end;
end;

end.

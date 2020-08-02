program YamlJson;

uses
  Vcl.Forms,
  fmTestForm in 'fmTestForm.pas' {Form1},
  Costate.Utils.Yaml in '..\Unit\Costate.Utils.Yaml.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

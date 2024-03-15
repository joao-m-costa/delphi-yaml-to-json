program YamlTest;



uses
  Vcl.Forms,
  YamlTestForm in 'YamlTestForm.pas' {YamlVsJsonForm},
  Costate.Utils.Yaml in '..\Unit\Costate.Utils.Yaml.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TYamlVsJsonForm, YamlVsJsonForm);
  Application.Run;
end.

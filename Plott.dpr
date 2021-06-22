program Plott;

uses
  System.StartUpCopy,
  FMX.Forms,
  Plott.Main in 'src\Plott.Main.pas' {FrmPlottMain},
  Plott.Graph.Calculations in 'src\Plott.Graph.Calculations.pas',
  Plott.CPU in 'src\Plott.CPU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmPlottMain, FrmPlottMain);
  Application.Run;
end.

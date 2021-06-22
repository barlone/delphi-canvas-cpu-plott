unit Plott.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.Colors, FMX.Controls.Presentation, FMX.StdCtrls,
  Plott.Graph.Calculations, Math, FMX.Utils, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView;

type
  TFrmPlottMain = class(TForm)
    lytGraph: TLayout;
    PlottSales: TPaintBox;
    lytControls: TFlowLayout;
    lytColor: TLayout;
    cbColorGraph: TComboColorBox;
    lbColorGraph: TText;
    Timer: TTimer;
    lytRulerHorz: TLayout;
    trkHorzLines: TTrackBar;
    lbHorzLines: TText;
    lytRulerVert: TLayout;
    trkVertLines: TTrackBar;
    lbVertLines: TText;
    lytGridOpacity: TLayout;
    trkOpacity: TTrackBar;
    lbGridOpacity: TText;
    Style: TStyleBook;
    trkHudHue: TTrackBar;
    lyPercent: TLayout;
    lbPercent: TText;
    lytTime: TLayout;
    lbTime: TText;
    lbCPU: TText;
    lyTimeSpan: TLayout;
    trkTimeSpan: TTrackBar;
    lbTimeSpan: TText;
    lytMenu: TLayout;
    btnSettings: TButton;
    procedure TimerTimer(Sender: TObject);
    procedure PlottSalesPainting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure PlottSalesPaint(Sender: TObject; Canvas: TCanvas);
    procedure FormCreate(Sender: TObject);
    procedure trkHorzLinesTracking(Sender: TObject);
    procedure trkVertLinesTracking(Sender: TObject);
    procedure trkOpacityTracking(Sender: TObject);
    procedure trkTimeSpanTracking(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    private
      IsCalc: Boolean;
      procedure DrawEverything;
      procedure Init;
      procedure ProcessGrid;
  end;

var
  FrmPlottMain: TFrmPlottMain;


implementation

{$R *.fmx}

uses Plott.CPU;

procedure TFrmPlottMain.btnSettingsClick(Sender: TObject);
const WIDTH = 160;
begin
  lytControls.AnimateFloat(
    'Opacity', -1 * (lytControls.Opacity - 1),
    0.4,
    TAnimationType.InOut,
    TInterpolationType.Exponential
  );

  lytControls.AnimateFloat('Width',
    WIDTH - WIDTH * lytControls.Opacity,
    0.4,
    TAnimationType.InOut,
    TInterpolationType.Exponential
  );
end;

procedure TFrmPlottMain.DrawEverything;
begin
  if IsCalc then Exit;
  IsCalc := True;
  try
    with Grid do
    begin
      if Assigned(Grid) then
      begin
        Grid.BackGroundColor := cbColorGraph.Color;
        lbCPU.Text := Format('CPU Usage:  %3.2f', [Grid.CpuPercnt]);
        Grid.GridOpacity := trkOpacity.Value;
        Grid.HudColor := InterpolateColor(TAlphaColors.Whitesmoke, TAlphaColors.Red, trkHudHue.Value);
      end else begin
        Grid := TGraphGrid.Create;
      end;
    end;
  finally
     IsCalc := False;
  end;
end;


procedure TFrmPlottMain.FormCreate(Sender: TObject);
begin
  Init;
end;

procedure TFrmPlottMain.Init;
begin
  DrawEverything;
  trkHorzLinesTracking(nil);
  trkVertLinesTracking(nil);
  trkOpacityTracking(nil);
end;

procedure TFrmPlottMain.PlottSalesPaint(Sender: TObject; Canvas: TCanvas);
begin
  PlottSales.Paint(Sender, Canvas);
end;

procedure TFrmPlottMain.PlottSalesPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  PlottSales.Painting(Sender, Canvas, ARect);
end;

procedure TFrmPlottMain.ProcessGrid;
var Count: Integer; Opacity: Single;
begin

  Count := Format('%0.0f', [trkHorzLines.Value]).ToInteger ;
  lbHorzLines.Text := 'Horizontal Lines: ' + (Count - 1).ToString;
  Grid.HorizontalCount := Count;

  Count := Format('%0.0f', [trkVertLines.Value]).ToInteger;
  lbVertLines.Text := 'Vertical Lines: ' + (Count - 1).ToString;
  Grid.VerticalCount := Count;

  lbTimeSpan.Text := Format('Time: %.0f min', [trkTimeSpan.Value / 60]);
  Grid.TimeSpan :=  StrToFloat(trkTimeSpan.Value.ToString);

end;

procedure TFrmPlottMain.TimerTimer(Sender: TObject);
begin
  DrawEverything;
  if not IsCalc
  then PlottSales.Repaint;
end;
procedure TFrmPlottMain.trkHorzLinesTracking(Sender: TObject);
begin
  ProcessGrid;
end;

procedure TFrmPlottMain.trkOpacityTracking(Sender: TObject);
begin
  lbGridOpacity.Text := Format('HUD Brightness: %0.3f', [trkOpacity.Value]);
end;

procedure TFrmPlottMain.trkTimeSpanTracking(Sender: TObject);
begin
  ProcessGrid;
end;

procedure TFrmPlottMain.trkVertLinesTracking(Sender: TObject);
begin
  ProcessGrid;
end;

end.

unit Plott.Graph.Calculations;

interface

uses
  System.Types, FMX.Graphics, FMX.Objects, FMX.Colors, System.UITypes, Math,
  System.Classes;
type
  TLine = record
    P1, P2: TPointF;
    Opacity: Single;
    Stroke : TStrokeBrush;
    Avaible: Boolean;
    Tick, Num: Single;
    PerctX, PerctY: Single;
    Cpu: Single;
  end;

type
  TLegend = record
    Stroke: TStrokeBrush;
    Opacity: Single;
    LabelX, LabelY: array of string;
  end;

type
  TGraphGrid = class
    Avaible: Boolean;
    TVertLineList: array of TLine;
    THorzLineList: array of TLine;

  private
    FVerticalCount: Integer;
    FHorizontalCount: Integer;
    FBackGroundColor: TAlphaColor;
    FGridOpacity: Single;
    FHudColor: TAlphaColor;
    FTimeSpan: Double;
    procedure SetVerticalCount(const Value: Integer);
    procedure SetHorizontalCount(const Value: Integer);
    procedure SetBackGroundColor(const Value: TAlphaColor);
    procedure SetGridOpacity(const Value: Single);
  private
    FCpuPercnt: Double;
    procedure DrawGridLines(Canvas: TCanvas);
    procedure DrawLegend(Canvas:TCanvas);
    procedure DrawGraphic(Canvas: TCanvas; ARect: TRectF);
    procedure SetHudColor(const Value: TAlphaColor);
    procedure SetTimeSpan(const Value: Double);
    procedure SetCpuPercnt(const Value: Double);
  public
    function Calculate(const aRect: TRectF): TRectF;
    property VerticalCount: Integer read FVerticalCount write SetVerticalCount;
    property HorizontalCount: Integer read FHorizontalCount write SetHorizontalCount;
    property BackGroundColor: TAlphaColor read FBackGroundColor write SetBackGroundColor;
    property GridOpacity: Single read FGridOpacity write SetGridOpacity;
    property HudColor: TAlphaColor read FHudColor write SetHudColor;
    property TimeSpan: Double read FTimeSpan write SetTimeSpan;
    property CpuPercnt: Double read FCpuPercnt write SetCpuPercnt;
    constructor Create;
  end;

type
  TPaintBoxHelper = class helper for TPaintBox
    procedure Painting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Paint(Sender: TObject; Canvas: TCanvas);
  end;
var
  Grid: TGraphGrid;
  Legend: TLegend;
  Tick: Integer = 0;
  Curve : array of TLine;
  Wait: Boolean = False;
  GRect: TRectF;
  DispX, DispY: Single;
  MaxX, MaxY: Single;

implementation

uses
  FMX.Types, System.SysUtils, Plott.CPU;

function TGraphGrid.Calculate(const aRect: TRectF): TRectF;
var
  iVert,          //For each vertical line
  iHorz: Integer; //For each horizontal line
  MaxLenght,      //For both max lenght on height and width
  Space: Single;  //For storing the "slices" size  (i.e.: Width/iVert) so it can be used for some offset
  Line: TLine;    //Line object
begin

  //Calculate how many vertical lines would be
  SetLength(TVertLineList, VerticalCount);
  MaxLenght := aRect.Width;
  for iVert := 0 to High(TVertLineList) do
  begin
    Line := TVertLineList[iVert];
    with Line do
    begin
      Space := aRect.Height / VerticalCount ;
      Opacity := GridOpacity;
      Stroke := TStrokeBrush.Create(TBrushKind.Solid, HudColor);
      Stroke.Thickness := 0.4;

      P1.X := 0;
      P1.Y := TVertLineList[iVert-1].P1.Y + TPointF.Create(0, Space).Y;
      P2.X := MaxLenght;
      P2.Y := TVertLineList[iVert-1].P2.Y + TPointF.Create(MaxLenght, Space).Y;

      Num := (1 - (iVert /(VerticalCount-2))) * 100;
      Avaible := True;
      TVertLineList[iVert] := Line;
    end;
  end;

  //Calculate how many horizontal lines would be
  SetLength(THorzLineList, HorizontalCount);
  MaxLenght := aRect.Height;
  for iHorz := 0 to High(THorzLineList) do
  begin
    Line := THorzLineList[iHorz];
    with Line do
    begin
      Space := aRect.Width / HorizontalCount;
      Opacity := GridOpacity;
      Stroke := TStrokeBrush.Create(TBrushKind.Solid, HudColor);
      Stroke.Thickness := 0.4;

      P1.X := THorzLineList[iHorz-1].P1.X + TPointF.Create(Space, MaxLenght).X;
      P1.Y := MaxLenght;
      P2.X := THorzLineList[iHorz-1].P2.X + TPointF.Create(Space, 0).X;
      P2.Y := 0;

      Num := TimeSpan - ((TimeSpan /(HorizontalCount)) * iHorz) - (TimeSpan /(HorizontalCount));
      Avaible := True;
      THorzLineList[iHorz] := Line;
    end;
  end;

end;

{ TPaintBoxHelper }

procedure TPaintBoxHelper.Paint(Sender: TObject; Canvas: TCanvas);
var  Save: TCanvasSaveState;
begin

  //This is kind of the main process along the steps of drawing
  if Assigned(Grid) then
  begin
    Save := Canvas.SaveState;
    Grid.DrawGridLines(Canvas);
    Grid.DrawGraphic(Canvas, GRect);
    Grid.DrawLegend(Canvas);
    Canvas.RestoreState(Save);
  end;

end;

procedure TPaintBoxHelper.Painting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  GRect := ARect;                                   // Used for painting legends
  Grid.Calculate(GRect);                            // Calculate everything
  Canvas.ClearRect(ARect, Grid.BackGroundColor);    // Clear it for a new painting
end;

constructor TGraphGrid.Create;
begin
  inherited Create;
end;

procedure TGraphGrid.DrawGraphic(Canvas: TCanvas; ARect: TRectF);
var
  //Graph
  i,
  Steps,          // How many points on X axis?
  T: Integer;     // 'Clock's Tick' each 'Tick' is a frame on time
  P: TPointF;
  Point: TLine;   // Line Object. It mainly stores points location
  D,              // CPU percentage
  X, Y: Single;
begin
  inherited;

  //This routine calculate the exact locaction for each point on the plott

  Steps := Trunc((TimeSpan / 60) * 1000 * VerticalCount);
  MaxX := ARect.Width;
  MaxY := ARect.Height;
  DispX :=  MaxX / Steps;
  DispY :=  MaxY / VerticalCount ;

  D := GetTotalCpuUsagePct;
  P := TPointF.Create(
    {X} MaxX + DispX * Tick,
    {Y} (MaxY - ((MaxY - 2 *DispY) * D / 100)) - DispY
  );

  Point.P1 := P;
  Point.Stroke := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColors.Red);
  Point.Opacity := 1;
  Point.Stroke.Thickness := 3;
  Point.PerctX := 1 + (DispX * Tick)/MaxX;
  Point.PerctY := P.Y/MaxY;
  Point.Tick := Tick;
  Point.Cpu := D;

  if Tick mod 12 = 0 then
  begin
    T := Tick div 12;
    //SetLength(Curve, T + 1);
    //Curve[T] := Point;
    SetLength(Curve, T + 1);
    Curve[T] := Point;
  end;

  Tick := Tick + 1;

  //After calculating above, there comes the painting
  //Notice the curve moves along with time
  for i := 0 to High(Curve) do
  begin

    X := MaxX * Curve[i].PerctX;
    Y := MaxY * Curve[i].PerctY;

    Curve[i].P1 := PointF(X, Y);
    Curve[i].P1 := Curve[i].P1 - PointF(DispX, 0);
    Curve[i].PerctX := 1 - (MaxX - Curve[i].P1.X )/MaxX;
    Curve[i].PerctY := Curve[i].P1.Y/MaxY;

    if i = 0 then Continue;

    if  (Curve[i].P1.X > 0)
    and (Curve[i].P1.X < ARect.Right)
    and (Curve[i].P1.Y < ARect.Bottom)
    and (Curve[i].P1.Y > 0)
    then
    begin
      CpuPercnt := Curve[i].Cpu;
      Canvas.DrawLine(
        Curve[i].P1,
        Curve[i-1].P1,
        Curve[i].Opacity,
        Curve[i].Stroke
      );
    end;

  end;


end;

procedure TGraphGrid.DrawGridLines(Canvas: TCanvas);
var
  iVert, iHorz: Integer;
  L : TLine;
begin
  //Draw the vertical lines
  for iVert := Low(Grid.TVertLineList) to High(Grid.TVertLineList) do
  begin
    L := Grid.TVertLineList[iVert];
    Canvas.DrawLine(L.P1, L.P2, L.Opacity, L.Stroke);
  end;

  //Draw the horizontal lines
  for iHorz := Low(Grid.THorzLineList) to High(Grid.THorzLineList) do
  begin
    L := Grid.THorzLineList[iHorz];
    Canvas.DrawLine(L.P1, L.P2, L.Opacity, L.Stroke);
  end;
end;

procedure TGraphGrid.DrawLegend(Canvas: TCanvas);
var
  iVert, iHorz: Integer;
  TextH, TextW, N,
   Margin: Single;
  LRect:TRectF;
  P: TPointF;
begin

  //Set legend sizes and arrays
  Legend.Opacity := Grid.GridOpacity * 2;
  SetLength(Legend.LabelX, VerticalCount);
  SetLength(Legend.LabelY, HorizontalCount);

  //Draw legend borders
  Canvas.Stroke.Color := HudColor;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.DrawRect(
    GRect, 0, 0, [],
    Legend.Opacity,
    TCornerType.InnerLine
  );

  Margin := 10;

  //Draw vertical legend
  for iVert := Low(Grid.TVertLineList) to High(Grid.TVertLineList) do
  begin

    //Ignores first label
    if (iVert = High(Grid.TVertLineList))
    then Continue;

    //Every label must have a local rect with respective coordinates so that it
    //can be drawn in the screen
    P := Grid.TVertLineList[iVert].P1;
    N := Grid.TVertLineList[iVert].Num;
    Legend.LabelX[iVert] :=  FloatToStrF(N, TFloatFormat.ffFixed, 7, 2) + ' (%)';
    TextW := Canvas.TextWidth(Legend.LabelX[iVert]);
    TextH := Canvas.TextHeight(Legend.LabelX[iVert]);
    LRect := RectF(
      P.X + Margin,
      P.Y - TextH / 2,
      P.X + TextW + Margin,
      P.Y + TextH - TextH / 2
    );

    //After stablishing the coordinates we can start drawing it
    Canvas.Fill.Color := HudColor;
    Canvas.FillText(
      LRect,
      Legend.LabelX[iVert],
      False,
      Legend.Opacity,
      [],
      TTextAlign.Leading
    );

  end;

  //Draw horizontal legend
  for iHorz := Low(Grid.THorzLineList) to High(Grid.THorzLineList) do
  begin

    //Ignores first label
    if (iHorz = High(Grid.THorzLineList))
    then Continue;

    //Every label must have a local rect with respective coordinates so that it
    //can be drawn in the screen
    P := Grid.THorzLineList[iHorz].P1;
    N := Grid.THorzLineList[iHorz].Num;
    Legend.LabelY[iHorz] :=  FormatDateTime('nn:ss', N/(24*60*60));

    // FloatToStrF(N, TFloatFormat.ffGeneral, 7, 2);  //Format('%.0f min', [N / 60000]);
    TextW := Canvas.TextWidth(Legend.LabelY[iHorz]);
    TextH := Canvas.TextHeight(Legend.LabelY[iHorz]);
    LRect := RectF(
      P.X - TextW / 2,
      P.Y - 2 * Margin,
      P.X + TextW - TextW / 2,
      P.Y + TextH - 2 * Margin
    );

    //After stablishing the coordinates we can start drawing it
    Canvas.Fill.Color := HudColor;
    Canvas.FillText(
      LRect,
      Legend.LabelY[iHorz],
      False,
      Legend.Opacity,
      [],
      TTextAlign.Leading
    );

  end;
end;

procedure TGraphGrid.SetBackGroundColor(const Value: TAlphaColor);
begin
  FBackGroundColor := Value;
end;

procedure TGraphGrid.SetCpuPercnt(const Value: Double);
begin
  FCpuPercnt := Value;
end;

procedure TGraphGrid.SetGridOpacity(const Value: Single);
begin
  FGridOpacity := Value;
end;

procedure TGraphGrid.SetHorizontalCount(const Value: Integer);
begin
  FHorizontalCount := Value;
end;

procedure TGraphGrid.SetHudColor(const Value: TAlphaColor);
begin
  FHudColor := Value;
end;

procedure TGraphGrid.SetTimeSpan(const Value: Double);
begin
  SetLength(Curve, 0);
  Tick := 0;
  FTimeSpan := Value;
end;

procedure TGraphGrid.SetVerticalCount(const Value: Integer);
begin
  FVerticalCount := Value;
end;



end.

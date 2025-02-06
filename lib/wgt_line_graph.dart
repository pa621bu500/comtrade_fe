import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class WgtLineChart extends StatefulWidget {
  final List<Map<String, dynamic>> channelList;
  final String xKey;
  final String yKey;
  final String? xAxisName;
  final String? yAxisName;
  final List<Color>? seriesColors;
  final String? graphTitle;
  // final TextStyle? xTitleStyle;
  // final TextStyle? yTitleStyle;
  // final bool showBottomAxisName;
  // final bool showLeftAxisName;
  // final int yDecimal;
  // final String valUnit;

  const WgtLineChart({
    super.key,
    required this.channelList,
    required this.xKey,
    required this.yKey,
    this.xAxisName,
    this.yAxisName,
    this.seriesColors,
    this.graphTitle,
    // this.showBottomAxisName = true,
    // this.showLeftAxisName = true,
    // this.xTitleStyle,
    // this.yTitleStyle,
    // this.yDecimal = 0,
    // this.valUnit = '',
  });

  @override
  _WgtLineChartState createState() => _WgtLineChartState();
}

class _WgtLineChartState extends State<WgtLineChart> {
  double _maxY = double.infinity;
  double _minY = double.infinity;
  double _maxX = -double.infinity;
  double _minX = double.infinity;

  @override
  void initState() {
    super.initState();

    _loadChartData();
  }

  @override
  void didUpdateWidget(WgtLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if dataSets has changed
    if (oldWidget.channelList != widget.channelList) {
      _loadChartData(); // Reload data if dataSets has changed
    }
  }

  void _loadChartData() {
    // Reset min and max values before recalculating
    _minX = double.infinity;
    _maxX = -double.infinity;
    _minY = double.infinity;
    _maxY = -double.infinity;
    List<List<ChartData>> chartDataList = [];
    setState(() {
      if (widget.channelList.isEmpty) return;

      for (var channelMap in widget.channelList) {
        // Ensure channelMap has a "data" field and it's a List
        if (channelMap.containsKey("data") && channelMap["data"] is List) {
          for (var dataItem in channelMap["data"]) {
            if (dataItem is Map<String, dynamic>) {
              try {
                double x = (dataItem[widget.xKey] is num)
                    ? (dataItem[widget.xKey] as num).toDouble()
                    : double.parse(dataItem[widget.xKey].toString());

                double y = (dataItem[widget.yKey] is num)
                    ? (dataItem[widget.yKey] as num).toDouble()
                    : double.parse(dataItem[widget.yKey].toString());

                _maxY = _maxY > y ? _maxY : y;
                _minY = _minY < y ? _minY : y;
                _maxX = _maxX > x ? _maxX : x;
                _minX = _minX < x ? _minX : x;

                // seriesData.add(ChartData(x, y));
              } catch (e) {
                print("Error parsing data: $e");
              }
            }
          }
        }

        // chartDataList.add(seriesData); // Add the processed data
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_minX == double.infinity) _minX = 0;
    if (_maxX == -double.infinity) _maxX = 1;
    if (_minY == double.infinity) _minY = 0;
    if (_maxY == double.infinity) _maxY = 1;

    List<ChartSeries> seriesList = [];

    for (int i = 0; i < widget.channelList.length; i++) {
      seriesList.add(LineSeries<ChartData, double>(
        dataSource:
            (widget.channelList[i]["data"] as List<Map<String, dynamic>>)
                .map<ChartData>((dataItem) {
          return ChartData(
            dataItem["x"]?.toDouble() ?? 0.0, // Ensure x is a double
            dataItem["y"]?.toDouble() ?? 0.0, // Ensure y is a double
          );
        }).toList(), // Convert to List<ChartData>
        xValueMapper: (ChartData data, _) => data.x,
        yValueMapper: (ChartData data, _) => data.y,
        dataLabelSettings: const DataLabelSettings(isVisible: false),
        color: widget.seriesColors != null && i < widget.seriesColors!.length
            ? widget.seriesColors![i]
            : Colors.blue,
        name: widget.channelList[i]["phase"], // Set phase as the legend name
      ));
    }

    return SfCartesianChart(
      title: ChartTitle(text: widget.graphTitle ?? ""),
      primaryXAxis: NumericAxis(
        minimum: _minX,
        maximum: _maxX,
        interactiveTooltip: InteractiveTooltip(enable: false),
      ),
      primaryYAxis: NumericAxis(
        minimum: _minY - (_maxY - _minY) * 0.1,
        maximum: _maxY + (_maxY - _minY) * 0.1,
        interactiveTooltip: InteractiveTooltip(enable: false),
      ),
      series: seriesList,
      legend: Legend(
        isVisible: true, // Enable legend
        position: LegendPosition
            .top, // You can change the position of the legend (top, bottom, left, right)
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
        enableSelectionZooming: true,
        enableMouseWheelZooming: true,
        enableDoubleTapZooming: true,
        zoomMode: ZoomMode.xy,
        maximumZoomLevel: 0.5,
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        duration: 2000,
        decimalPlaces: 3,
      ),
      annotations: <CartesianChartAnnotation>[
        CartesianChartAnnotation(
          widget: Container(
            padding: EdgeInsets.all(8),
            color: Colors.yellow
                .withOpacity(0.7), // Optional: Add background color
            child: Text(
              'Graph Type: Voltage vs Time', // Example text
              style: TextStyle(
                color: Colors.black, // Use black for visibility
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          coordinateUnit: CoordinateUnit.point,
          x: 0.5, // X position (relative to chart size)
          y: 0.5, // Set Y to 0.5 for center positioning
        ),
      ],
    );
  }
}

class ChartData {
  final double x;
  final double y;

  ChartData(this.x, this.y);
}

// import 'dart:math';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';

// class WgtLineChart extends StatefulWidget {
//   const WgtLineChart({
//     super.key,
//     required this.xKey,
//     required this.yKey,
//     required this.dataSets,
//     this.width,
//     this.height,
//     this.xAxisName,
//     this.yAxisName,
//     this.legend,
//     this.chartRatio = 1.5,
//     this.isCurved = false,
//     this.fitInsideBottomTitle = false,
//     this.fitInsideTopTitle = false,
//     this.fitInsideLeftTitle = false,
//     this.fitInsideRightTitle = false,
//     this.showLeftTitle = true,
//     this.showRightTitle = true,
//     this.showTopTitle = true,
//     this.showBottomTitle = true,
//     this.reservedSizeLeft,
//     this.reservedSizeRight,
//     this.reservedSizeTop,
//     this.reservedSizeBottom,
//     this.xColor,
//     this.yColor,
//     this.xTitleStyle,
//     this.yTitleStyle,
//     this.showBottomAxisName = true,
//     this.showLeftAxisName = true,
//     this.yDecimal = 0,
//     this.valUnit = '',
//     this.getTooltipText,
//     Color? tooltipTextColor,
//   }) : tooltipTextColor = tooltipTextColor ?? Colors.black;

//   final String xKey;
//   final String yKey;
//   final String? xAxisName;
//   final String? yAxisName;
//   final List<Map<String, List<Map<String, dynamic>>>> dataSets;
//   final List<Map<String, dynamic>>? legend;
//   final double chartRatio;
//   final double? width;
//   final double? height;
//   final bool isCurved;
//   final bool fitInsideBottomTitle;
//   final bool fitInsideTopTitle;
//   final bool fitInsideLeftTitle;
//   final bool fitInsideRightTitle;
//   final bool showLeftTitle;
//   final bool showRightTitle;
//   final bool showTopTitle;
//   final bool showBottomTitle;
//   final double? reservedSizeLeft;
//   final double? reservedSizeRight;
//   final double? reservedSizeTop;
//   final double? reservedSizeBottom;
//   final Color? xColor;
//   final Color? yColor;
//   final TextStyle? xTitleStyle;
//   final TextStyle? yTitleStyle;
//   final bool showBottomAxisName;
//   final bool showLeftAxisName;
//   final int yDecimal;
//   final String valUnit;
//   final String Function(double, String)? getTooltipText;
//   final Color tooltipTextColor;

//   @override
//   State<WgtLineChart> createState() => _WgtLineChartState();
// }

// class _WgtLineChartState extends State<WgtLineChart> {
//   double _maxY = 0;
//   double _minY = double.infinity;
//   double _range = 0;
//   double _minX = double.infinity;
//   double _maxX = -double.infinity;
//   List<LineChartBarData> _chartDataSets = [];
//   List<Map<String, int>> _xTitles = [];

//   // Generates a list of FlSpot objects
//   List<FlSpot> convertToFlSpotData(
//       List<Map<String, dynamic>> data, String xKey, String yKey,
//       {List<Map<String, dynamic>>? errorData}) {
//     List<FlSpot> chartData = [];
//     for (var dataItem in data) {
//       double xVal = dataItem[xKey] is double
//           ? dataItem[xKey]
//           : dataItem[xKey] is int
//               ? dataItem[xKey].toDouble()
//               : double.parse(dataItem[xKey]);
//       double value = dataItem[yKey] is double
//           ? dataItem[yKey]
//           : dataItem[yKey] is int
//               ? dataItem[yKey].toDouble()
//               : double.parse(dataItem[yKey]);
//       if (value > _maxY) {
//         _maxY = value;
//       }
//       if (value < _minY) {
//         _minY = value;
//       }
//       if (xVal > _maxX) {
//         _maxX = xVal;
//       }
//       if (xVal < _minX) {
//         _minX = xVal;
//       }
//       chartData.add(FlSpot(xVal, value));
//       if (errorData != null) {
//         if (dataItem['error_data'] != null) {
//           errorData.add({
//             'x': xVal.toInt(),
//             'y': value.toInt(),
//             'error': dataItem['error_data']
//           });
//         }
//       }
//     }
//     return chartData;
//   }

//   void updateChart(List<Map<String, List<Map<String, dynamic>>>> newDataSets) {
//     setState(() {
//       widget.dataSets.clear();
//       widget.dataSets.addAll(newDataSets);
//       _loadChartData();
//     });
//   }

//   void _loadChartData() {
//     setState(() {
//       _chartDataSets = [];
//       _maxY = 0;
//       _minY = double.infinity;
//       _maxX = -double.infinity;
//       _minX = double.infinity;

//       for (var historyDataInfo in widget.dataSets) {
//         Color? lineColor;
//         if (widget.legend != null) {
//           for (var legendItem in widget.legend!) {
//             if (legendItem['name'] == historyDataInfo.keys.first) {
//               lineColor = legendItem['color'];
//             }
//           }
//         }

//         for (List<Map<String, dynamic>> data
//             in historyDataInfo.values.toList()) {
//           Color color = lineColor ?? Colors.yellow;

//           List<FlSpot> chartData = convertToFlSpotData(
//               data, widget.xKey, widget.yKey,
//               errorData: []);

//           _chartDataSets.add(LineChartBarData(
//             isCurved: widget.isCurved,
//             color: color,
//             barWidth: 1.5,
//             isStrokeCapRound: true,
//             dotData: FlDotData(
//                 show: false,
//                 getDotPainter: (spot, percent, barData, index) {
//                   return FlDotCirclePainter(
//                     radius: 2,
//                     color: color,
//                     strokeWidth: 2,
//                     strokeColor: color,
//                   );
//                 }),
//             belowBarData: BarAreaData(show: false),
//             spots: chartData,
//           ));
//         }
//       }
//       _range = _maxY - _minY;
//       if (_range == 0) {
//         _range = 0.1 * _minY;
//       }
//     });
//   }

//   List<LineTooltipItem?> getToolTipItems(List<LineBarSpot> touchedBarSpots) {
//     List<double> yValues = [];
//     for (var tbs in touchedBarSpots) {
//       yValues.add(tbs.y);
//     }
//     double yMin = yValues.reduce(min);
//     return touchedBarSpots.map((barSpot) {
//       final flSpot = barSpot;

//       TextAlign textAlign;
//       switch (flSpot.x.toInt()) {
//         case 1:
//           textAlign = TextAlign.left;
//           break;
//         case 5:
//           textAlign = TextAlign.right;
//           break;
//         default:
//           textAlign = TextAlign.center;
//       }

//       Color? textColor;
//       if (widget.legend != null) {
//         textColor = widget.legend![barSpot.barIndex]['color'];
//       }

//       String text =
//           '${flSpot.y.toStringAsFixed(widget.yDecimal)}${widget.valUnit}';
//       if (widget.getTooltipText != null) {
//         text = widget.getTooltipText!(flSpot.y, '');
//       }
//       return LineTooltipItem(
//         text,
//         TextStyle(
//           color: textColor ?? widget.tooltipTextColor,
//           fontWeight: FontWeight.bold,
//         ),
//         children: [],
//         textAlign: textAlign,
//       );
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     _loadChartData();
//     return AspectRatio(
//       aspectRatio: widget.chartRatio,
//       child: InteractiveViewer(
//         boundaryMargin: const EdgeInsets.all(10),
//         minScale: 0.5, // Minimum zoom-out scale
//         maxScale: 2.0, // Maximum zoom-in scale
//         panEnabled: true, // Enable panning
//         scaleEnabled: true, // Enable zooming
//         child: LineChart(
//           LineChartData(
//             minX: _minX,
//             maxX: _maxX,
//             minY: widget.dataSets.isEmpty
//                 ? 0
//                 : _minY < 0
//                     ? _minY - 0.5 * _range
//                     : _minY - 0.5 * _range > 0
//                         ? _minY - (0.5 * _range)
//                         : 0,
//             maxY: widget.dataSets.isEmpty ? 0 : _maxY + (0.34 * _range),
//             lineBarsData: _chartDataSets,
//             lineTouchData: LineTouchData(
//               touchTooltipData: LineTouchTooltipData(
//                 getTooltipItems: getToolTipItems,
//               ),
//             ),
//             titlesData: FlTitlesData(
//               show: true,
//               topTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: widget.showTopTitle,
//                   reservedSize: widget.reservedSizeTop ?? 40,
//                 ),
//               ),
//               bottomTitles: AxisTitles(
//                 axisNameSize: 20,
//                 axisNameWidget: widget.showBottomAxisName
//                     ? Text(
//                         widget.xAxisName ?? widget.xKey,
//                         style: widget.xTitleStyle ??
//                             TextStyle(color: widget.xColor ?? Colors.blue),
//                       )
//                     : null,
//                 sideTitles: SideTitles(
//                   showTitles: widget.showBottomTitle,
//                   reservedSize: widget.reservedSizeBottom ?? 40,
//                 ),
//               ),
//               leftTitles: AxisTitles(
//                 axisNameSize: 20,
//                 axisNameWidget: widget.showLeftAxisName
//                     ? Text(
//                         widget.yAxisName ?? widget.yKey,
//                         style: widget.yTitleStyle ??
//                             TextStyle(color: widget.yColor ?? Colors.blue),
//                       )
//                     : null,
//                 sideTitles: SideTitles(
//                   showTitles: widget.showLeftTitle,
//                   reservedSize: widget.reservedSizeLeft ?? 40,
//                   getTitlesWidget: (value, meta) {
//                     return Text(
//                       value.toStringAsFixed(widget.yDecimal),
//                       style: widget.yTitleStyle ??
//                           const TextStyle(color: Colors.blue, fontSize: 13.5),
//                     );
//                   },
//                 ),
//               ),
//               rightTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: widget.showRightTitle,
//                   reservedSize: widget.reservedSizeRight ?? 40,
//                   getTitlesWidget: (value, meta) {
//                     return Text(
//                       value.toStringAsFixed(widget.yDecimal),
//                       style: widget.yTitleStyle ??
//                           const TextStyle(color: Colors.blue, fontSize: 13.5),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

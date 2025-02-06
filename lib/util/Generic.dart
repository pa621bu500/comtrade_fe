import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class GenericWidgets {
  static Widget button(
      {required String text,
      required VoidCallback onPressed,
      double fontsize = 12,
      Color textColor = Colors.black,
      double? width,
      double borderRadius = 4.0,
      Color? backgroundcolor,
      bool isProcessing = false}) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundcolor ?? Colors.white, // Background color
          foregroundColor: textColor, // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius), // Border radius
          ),
        ),
        onPressed: onPressed,
        child: isProcessing
            ? const CircularProgressIndicator()
            : Text(text,
                style: TextStyle(fontSize: fontsize, color: textColor)),
      ),
    );
  }

  static Widget textField({
    String? text,
    double? width,
    double? height,
    double? fontSize,
    Color? backgroundColor,
  }) {
    return Container(
      width: width ?? 200,
      height: height ?? 30,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        border: Border.all(
          width: 1,
          color: const Color.fromARGB(255, 192, 194, 197),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          text ?? "",
          style: TextStyle(fontSize: fontSize ?? 12),
        ),
      ),
    );
  }

  static Widget inputField({
    required TextEditingController controller,
    required TextInputType keyboardType,
    double? width,
    double? height,
    String? defaultText,
  }) {
    if (defaultText != null) {
      controller.text = defaultText;
    }
    return SizedBox(
      height: height ?? 30,
      width: width ?? 100,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 192, 194, 197)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 192, 194, 197)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.only(top: 0, bottom: 0, left: 10),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  static Widget basicLineGraphWidget({
    required String yTitle,
    required String xTitle,
    double? width,
    double? height,
    double? minX,
    double? minY,
    double? maxX,
    double? maxY,
    bool? showGridLine,
    List<Map<String, double>>? spots,
    List<FlSpot>? polynomialFitSpots,
  }) {
    List<FlSpot> flSpots = spots?.map((spot) {
          double x = spot['x'] ?? 0.0;
          double y = spot['y'] ?? 0.0;
          return FlSpot(x, y);
        }).toList() ??
        [];

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: RotatedBox(
            quarterTurns: -1,
            child: Text(
              yTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SizedBox(
            width: width ?? 400,
            height: height ?? 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: LineChart(
                      LineChartData(
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: flSpots.isNotEmpty
                                ? flSpots
                                : [const FlSpot(0, 1)],
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 2,
                            belowBarData: BarAreaData(show: false),
                          ),
                          if (polynomialFitSpots != null &&
                              polynomialFitSpots.isNotEmpty)
                            LineChartBarData(
                              spots: polynomialFitSpots,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 2,
                              belowBarData: BarAreaData(show: false),
                            ),
                        ],
                        minX: minX ?? 0,
                        maxX: maxX ?? 1,
                        minY: minY ?? 0,
                        maxY: maxY ?? 1,
                        gridData: FlGridData(show: showGridLine ?? false),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    xTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  // Function to convert a list of lists to a list of maps
  static List<Map<String, dynamic>> convertToListOfMap(
      List<List<dynamic>> entityList) {
    List<Map<String, dynamic>> graphCoordinates = [];
    List<dynamic> headers = entityList[0];

    for (int i = 1; i < entityList.length; i++) {
      Map<String, dynamic> rowMap = {};
      List<dynamic> row = entityList[i];

      for (int j = 0; j < headers.length; j++) {
        rowMap[headers[j]] = row[j];
      }

      graphCoordinates.add(rowMap);
    }
    return graphCoordinates;
  }
}

List<FlSpot> calculatePolynomialFit(
    List<Map<String, double>> data, int degree) {
  List<double> x = data.map((e) => e['x']!).toList();
  List<double> y = data.map((e) => e['y']!).toList();

  int n = x.length;
  List<List<double>> A =
      List.generate(degree + 1, (i) => List.generate(degree + 1, (j) => 0.0));
  List<double> B = List.generate(degree + 1, (i) => 0.0);

  for (int i = 0; i < n; i++) {
    double xi = x[i];
    double yi = y[i];
    for (int j = 0; j <= degree; j++) {
      for (int k = 0; k <= degree; k++) {
        A[j][k] += pow(xi, j + k).toDouble();
      }
      B[j] += yi * pow(xi, j).toDouble();
    }
  }

  List<double> coefficients = List.generate(degree + 1, (i) => 0.0);
  solveLinearSystem(A, B, coefficients);

  List<FlSpot> fitPoints = [];
  double step = (x.last - x.first) / 100;
  for (double i = x.first; i <= x.last; i += step) {
    double yFit = coefficients.asMap().entries.fold(
          0.0,
          (prev, entry) => prev + entry.value * pow(i, entry.key).toDouble(),
        );
    fitPoints.add(FlSpot(i, yFit));
  }

  return fitPoints;
}

void solveLinearSystem(List<List<double>> A, List<double> B, List<double> X) {
  // Implement Gaussian Elimination or another method to solve the system
  // This is a placeholder; you need a proper implementation
  // Here's a simple Gaussian Elimination implementation
  int n = A.length;

  for (int i = 0; i < n; i++) {
    // Search for maximum in this column
    double maxEl = A[i][i];
    int maxRow = i;
    for (int k = i + 1; k < n; k++) {
      if (A[k][i] > maxEl) {
        maxEl = A[k][i];
        maxRow = k;
      }
    }

    // Swap maximum row with current row
    for (int k = i; k < n; k++) {
      double tmp = A[maxRow][k];
      A[maxRow][k] = A[i][k];
      A[i][k] = tmp;
    }
    double tmp = B[maxRow];
    B[maxRow] = B[i];
    B[i] = tmp;

    // Make all rows below this one 0 in current column
    for (int k = i + 1; k < n; k++) {
      double c = -A[k][i] / A[i][i];
      for (int j = i; j < n; j++) {
        A[k][j] += c * A[i][j];
      }
      B[k] += c * B[i];
    }
  }

  // Solve equation for an upper triangular matrix
  for (int i = n - 1; i >= 0; i--) {
    X[i] = B[i] / A[i][i];
    for (int k = i - 1; k >= 0; k--) {
      B[k] -= A[k][i] * X[i];
    }
  }
}

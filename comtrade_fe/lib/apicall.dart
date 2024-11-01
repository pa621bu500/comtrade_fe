import 'dart:convert';
import 'package:archive/archive.dart';

import 'package:comtrade_fe/wgt_line_graph.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Import html for web file handling
import 'package:universal_platform/universal_platform.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

enum RequestOperations { plotGraph, downloadJsonZip, downloadCsvZip }

class _MainScreenState extends State<MainScreen> {
  Map<String, dynamic> _result = {};
  final List<int> _stepOptions = [1, 10, 100, 200];
  int? _selectedStepValue = 1; // Currently selected value
  List<double> _v1 = [];
  List<double> _v2 = [];
  List<double> _v3 = [];
  List<double> _a1 = [];
  List<double> _a2 = [];
  List<double> _a3 = [];
  List<Map<String, List<Map<String, dynamic>>>> _voltageWaveformLineSelected =
      [];
  List<Map<String, List<Map<String, dynamic>>>> _currentWaveformLineSelected =
      [];

  // ignore: prefer_final_fields
  Map<String, dynamic> _tableMap = {
    'Substation_name': '',
    'device_id': '',
    'year': '',
    'channel_count': '',
    'analog_channel_count': '',
    'digital_channel_count': '',
    'line_frequency': '',
    'start_timestamp': '',
    'end_timestamp': '',
    'file_type': '',
    'time_multiplier': '',
    'sample_rate': '',
    'number_of_samples': '',
  };

  PlatformFile? cfgFile;
  PlatformFile? datFile;
  String cfgFilename = '';

  Future<void> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['cfg', 'dat'],
      );

      if (result != null) {
        setState(() {
          cfgFile = result.files.firstWhere((file) => file.extension == 'cfg',
              orElse: () => throw Exception("No .cfg file selected"));
          datFile = result.files.firstWhere((file) => file.extension == 'dat',
              orElse: () => throw Exception("No .dat file selected"));
        });
        cfgFilename = cfgFile!.name.split('.').first; // Store .cfg filename
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking files: $e');
      }
    }
  }

  void setTableData(var responseData) {
    final Map<String, dynamic> responseJson = jsonDecode(responseData.body);
    final Map<String, dynamic> result = responseJson['result'];
    setState(() {
      _result = result;
      _tableMap['Substation_name'] = result['stationName'] ?? '';
      _tableMap['device_id'] = result['deviceId'] ?? '';
      _tableMap['year'] = result['revYear'] ?? '';
      _tableMap['channel_count'] = result['numOfChannels'] ?? '';
      _tableMap['analog_channel_count'] = result['numOfAnalogChannels'] ?? '';
      _tableMap['digital_channel_count'] = result['numOfDigitalChannels'] ?? '';
      _tableMap['line_frequency'] = result['lineFrequency'] ?? '';
      _tableMap['start_timestamp'] = result['startTimestamp'] ?? '';
      _tableMap['end_timestamp'] = result['endTimestamp'] ?? '';
      _tableMap['file_type'] = result['fileType'] ?? '';
      _tableMap['time_multiplier'] = result['timeMultiplier'] ?? '';
      _tableMap['sample_rate'] = result['sampleRates'] ?? '';
      _tableMap['number_of_samples'] = result['numOfSamples'] ?? '';
    });
  }

  Future<void> _fetchData(Enum requestOperation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            cfgFile != null ? '.cfg file uploaded' : 'No .cfg file selected'),
        duration: const Duration(
            seconds: 2), // Duration for which the snackbar is displayed
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            datFile != null ? '.dat file uploaded' : 'No .dat file selected'),
        duration: const Duration(
            seconds: 2), // Duration for which the snackbar is displayed
      ),
    );
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://localhost:8111/process_pqd'), // Replace with your API URL
      );

      if (cfgFile!.bytes != null && datFile!.bytes != null) {
        // Create form data using html for web
        request.files.add(http.MultipartFile.fromBytes(
          'cfgFile', // The name of the field in the form data
          cfgFile!.bytes!,
          filename: cfgFile!.name,
        ));
      } else {
        if (kDebugMode) {
          print('Error: File bytes are empty.');
        }
      }
      if (datFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'datFile', // The name of the field in the form data
          datFile!.bytes!,
          filename: datFile!.name,
        ));
      }
      request.fields['sample_step'] = _selectedStepValue.toString();
      request.fields['operation'] = requestOperation.name;
      request.fields['filename'] = cfgFilename;
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);

        switch (requestOperation) {
          case RequestOperations.plotGraph:
            setTableData(responseData);
            if (_result['analogChannels'] != null) {
              _handlePlotGraph(_result);
            }
          case RequestOperations.downloadJsonZip:
            setTableData(responseData);
            _downloadJsonZip();
          case RequestOperations.downloadCsvZip:
            if (kDebugMode) {
              print(
                  "Size of response body bytes: ${responseData.bodyBytes.length}");
            }
            final blob = html.Blob([responseData.bodyBytes], 'application/zip');
            final url = html.Url.createObjectUrlFromBlob(blob);
            // ignore: unused_local_variable
            final anchor = html.AnchorElement(href: url)
              ..setAttribute(
                  'download', '$cfgFilename.zip') // Set the download filename
              ..click(); // Trigger the download

            // Clean up the URL object
            html.Url.revokeObjectUrl(url);
            break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  void _handlePlotGraph(Map<String, dynamic> result) {
    // List<double> valuesList = [];
    // List<double> valuesList2 = [];
    // List<double> valuesList3 = [];
    // List<double> currentList1 = [];
    // List<double> currentList2 = [];
    // List<double> currentList3 = [];
    if (result['analogChannels'] != null) {
      // Extract and convert values for plotting
      // List<double> valuesList =
      //     result['analogChannels']?[0]['values'] as List<double>;
      // List<double> valuesList2 =
      //     result['analogChannels'][1]['values'] as List<double>;
      // List<double> valuesList3 =
      //     result['analogChannels'][2]['values'] as List<double>;

      // List<double> currentList1 =
      //     result['analogChannels'][4]['values'] as List<double>;
      // List<double> currentList2 =
      //     result['analogChannels'][5]['values'] as List<double>;
      // List<double> currentList3 =
      //     result['analogChannels'][6]['values'] as List<double>;

      if (result['analogChannels'].length > 0) {
        _v1 = List<double>.from(result['analogChannels'][0]['values']
                ?.map((item) => item.toDouble()) ??
            []);
      }
      if (result['analogChannels'].length > 1) {
        _v2 = List<double>.from(result['analogChannels'][1]['values']
                ?.map((item) => item.toDouble()) ??
            []);
      }
      if (result['analogChannels'].length > 2) {
        _v3 = List<double>.from(result['analogChannels'][2]['values']
                ?.map((item) => item.toDouble()) ??
            []);
      }
      if (result['analogChannels'].length > 4) {
        _a1 = List<double>.from(result['analogChannels'][4]['values']
                ?.map((item) => item.toDouble()) ??
            []);
      }
      if (result['analogChannels'].length > 5) {
        _a2 = List<double>.from(result['analogChannels'][5]['values']
                ?.map((item) => item.toDouble()) ??
            []);
      }
      if (result['analogChannels'].length > 6) {
        _a3 = List<double>.from(result['analogChannels'][6]['values']
                ?.map((item) => item.toDouble()) ??
            []);
      }

      _voltageWaveformLineSelected = [
        {
          'v1': List.generate(
            _v1.length,
            (index) => {'x': (index + 1).toDouble(), 'y': _v1[index]},
          )
        },
        {
          'v2': List.generate(
            _v2.length,
            (index) => {'x': (index + 1).toDouble(), 'y': _v2[index]},
          )
        },
        {
          'v3': List.generate(
            _v3.length,
            (index) => {'x': (index + 1).toDouble(), 'y': _v3[index]},
          )
        },
      ];

      _currentWaveformLineSelected = [
        {
          'a1': List.generate(
            _a1.length,
            (index) => {'x': (index + 1).toDouble(), 'y': _a1[index]},
          )
        },
        {
          'a2': List.generate(
            _a2.length,
            (index) => {'x': (index + 1).toDouble(), 'y': _a2[index]},
          )
        },
        {
          'a3': List.generate(
            _a3.length,
            (index) => {'x': (index + 1).toDouble(), 'y': _a3[index]},
          )
        },
      ];
    }
  }

  void _downloadJsonZip() {
    String jsonString = json.encode(_result);

    // Create a Zip file
    final Archive archive = Archive();

    // Create a new file in the zip with the JSON content
    archive.addFile(ArchiveFile(
        '$cfgFilename.json', jsonString.length, utf8.encode(jsonString)));

    // Encode the archive to a List<int>
    final List<int> bytes =
        ZipEncoder().encode(archive) ?? []; // Handle potential null

    if (bytes.isNotEmpty) {
      // Create a Blob from the zip bytes
      final blob = html.Blob([bytes], 'application/zip');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create an anchor element and trigger a download
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', cfgFilename)
        ..click();

      // Revoke the object URL after download
      html.Url.revokeObjectUrl(url);
    } else {
      if (kDebugMode) {
        print('Failed to create zip file.');
      }
    }
  }

  Widget getWaveformChart(
      double width,
      double height,
      List<Map<String, List<Map<String, dynamic>>>> _waveformLineSelected,
      double scale) {
    if (_waveformLineSelected.isEmpty) {
      return Container();
    }
    List<Color> colors = [Colors.blue, Colors.red, Colors.green];
    List<Map<String, dynamic>> legend = [];
    int i = 0;
    for (Map<String, dynamic> siteMap in _waveformLineSelected) {
      String label = siteMap.keys.first;
      Color color = colors[i % colors.length];
      i++;
      legend.add({
        'name': label,
        'color': color,
      });
    }
    List<Map<String, List<Map<String, dynamic>>>> scaledDataSets =
        _waveformLineSelected.map((siteMap) {
      String key = siteMap.keys.first;
      List<Map<String, dynamic>> scaledPoints = siteMap[key]!.map((point) {
        return {
          'x': point['x'], // Scale the X values
          'y': point['y'], // Scale the Y values
        };
      }).toList();

      return {key: scaledPoints};
    }).toList();
    return SizedBox(
      // height: height,
      child: WgtLineChart(
        xKey: 'x',
        yKey: 'y',
        xTitleStyle: TextStyle(
          fontSize: 13.5,
          color: Theme.of(context).hintColor,
        ),
        yTitleStyle: TextStyle(
          fontSize: 13.5,
          color: Theme.of(context).hintColor,
        ),
        showTopTitle: false,
        showBottomTitle: true,
        showLeftAxisName: false,
        showRightTitle: false,
        showBottomAxisName: false,
        reservedSizeLeft: 55,
        reservedSizeRight: 55,
        isCurved: true,
        chartRatio: 2.8,
        width: width,
        dataSets: scaledDataSets,
        legend: legend,
      ),
    );
  }

  Future<void> _downloadCsvZip() async {
    try {
      final response = await http.get(Uri.parse(
          'http://localhost:8111/downloadCsvZip')); // Adjust URL as necessary

      if (response.statusCode == 200) {
        // Create a blob and trigger a download
        final blob = html.Blob([response.bodyBytes], 'application/zip');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'data.zip') // Set the download filename
          ..click(); // Trigger the download

        // Clean up the URL object
        html.Url.revokeObjectUrl(url);
      } else {
        print(
            'Failed to download ZIP file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading ZIP file: $e');
    }
  }

  double getMinY(List<double> v1, List<double> v2, List<double> v3) {
    List<double> allValues = [...v1, ...v2, ...v3];
    return allValues.isNotEmpty ? allValues.reduce((a, b) => a < b ? a : b) : 0;
  }

  double getMaxY(List<double> v1, List<double> v2, List<double> v3) {
    List<double> allValues = [...v1, ...v2, ...v3];
    return allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 1;
  }

// Function to get buffered min and max Y values
  double getBufferedMinY(List<double> v1, List<double> v2, List<double> v3) {
    double minY = getMinY(v1, v2, v3);
    double maxY = getMaxY(v1, v2, v3);
    double yBuffer = (maxY - minY) * 0.1; // 10% buffer
    return minY - yBuffer;
  }

  double getBufferedMaxY(List<double> v1, List<double> v2, List<double> v3) {
    double maxY = getMaxY(v1, v2, v3);
    double minY = getMinY(v1, v2, v3);
    double yBuffer = (maxY - minY) * 0.1; // 10% buffer
    return maxY + yBuffer;
  }

  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    // double minYValueVoltage = getBufferedMinY(_v1, _v2, _v3);
    // double maxYValueVoltage = getBufferedMaxY(_v1, _v2, _v3);
    // double minYValueCurrent = getBufferedMinY(_a1, _a2, _a3);
    // double maxYValueCurrent = getBufferedMaxY(_a1, _a2, _a3);
    return Scaffold(
      appBar: AppBar(
        title: const Text('comtrade example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: pickFiles,
                  child: const Text('Select .cfg and .dat Files'),
                ),
              ),
              const SizedBox(width: 20),
              Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: DropdownButton<int>(
                  hint: const Text('Select a value'), // Placeholder text
                  value: _selectedStepValue, // Current selected value
                  items: _stepOptions.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedStepValue =
                          newValue; // Update the selected value
                    });

                    // Call your function with the selected value
                    if (_selectedStepValue != null) {
                      if (kDebugMode) {
                        print('Selected: $_selectedStepValue');
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => _fetchData(RequestOperations.plotGraph),
                child: const Text('generate result'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => _fetchData(RequestOperations.downloadJsonZip),
                child: const Text('download JSON zip'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => _fetchData(RequestOperations.downloadCsvZip),
                child: const Text('download CSV zip'),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Expanded(
            child: Row(
              children: [
                // Expanded widget for the Table
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Table(
                    border: TableBorder.all(),
                    columnWidths: const {
                      0: FixedColumnWidth(160.0),
                      1: FixedColumnWidth(160.0),
                    },
                    children: [
                      ..._tableMap.entries.map((entry) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(entry.value.toString()),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                // Expanded widget for the graphs
                Expanded(
                  flex: 2, // Adjust this for the desired width ratio
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Expanded(
                          child: getWaveformChart(
                              800, 200, _voltageWaveformLineSelected, _scale),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Expanded(
                          child: InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(
                                10), // Space around the chart
                            minScale: 0.5, // Minimum zoom-out scale
                            maxScale: 5.0, // Maximum zoom-in scale
                            panEnabled: true, // Enable panning
                            scaleEnabled: true,
                            child: getWaveformChart(
                                800, 200, _currentWaveformLineSelected, _scale),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // const SizedBox(
          //   height: 20,
          // ),
          // InteractiveViewer(
          //     boundaryMargin:
          //         const EdgeInsets.all(50), // Space around the chart
          //     minScale: 0.5, // Minimum zoom-out scale
          //     maxScale: 5.0, // Maximum zoom-in scale
          //     panEnabled: true, // Enable panning
          //     scaleEnabled: true,
          //     child: getWaveformChart(1200, _voltageWaveformLineSelected)),
          // InteractiveViewer(
          //     boundaryMargin:
          //         const EdgeInsets.all(50), // Space around the chart
          //     minScale: 0.5, // Minimum zoom-out scale
          //     maxScale: 5.0, // Maximum zoom-in scale
          //     panEnabled: true, // Enable panning
          //     scaleEnabled: true,
          //     child: getWaveformChart(1200, _currentWaveformLineSelected)),
        ],
      ),
    );
  }
}

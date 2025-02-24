import 'dart:convert';
import 'package:comtrade_fe/util/generic.dart';
import 'package:comtrade_fe/util/theme_provider.dart';
import 'package:comtrade_fe/wgt_line_graph.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:provider/provider.dart'; // Import html for web file handling

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

enum RequestOperations { plotGraph, downloadJsonZip, downloadCsvZip }

class _MainScreenState extends State<MainScreen> {
  Map<String, dynamic> _result = {};
  final List<int> _stepOptions = [1, 5, 10, 25, 50, 100];
  int? _selectedStepValueComtrade = 1; // Currently selected value
  int? _selectedStepValuePQD = 1; // Currently selected value

  // Process for both comtrade file (analogChannels) and pqd file (channel_info)

  List<Map<String, dynamic>> _voltageWaveformLineSelected = [];
  List<Map<String, dynamic>> _currentWaveformLineSelected = [];

  // ignore: prefer_final_fields
  Map<String, dynamic> _comtradeTableMap = {
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

  Map<String, dynamic> _pqdTableMap = {
    'file_name': '',
    'timestamp': '',
  };

  PlatformFile? cfgFile;
  PlatformFile? datFile;
  PlatformFile? pqdFile;
  String cfgFilename = '';
  String datFilename = '';
  String pqdFilename = '';

  Future<void> uploadCFGandDatFiles() async {
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

  Future<void> uploadPQDFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pqd'],
      );

      if (result != null) {
        setState(() {
          pqdFile = result.files.firstWhere((file) => file.extension == 'pqd',
              orElse: () => throw Exception("No .pqd file selected"));
        });
        pqdFilename = pqdFile!.name.split('.').first; // Store .cfg filename
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking files: $e');
      }
    }
  }

  void setTableDataForComtrade(var responseData) {
    final Map<String, dynamic> responseJson = jsonDecode(responseData.body);
    final Map<String, dynamic> result = responseJson['result'];
    setState(() {
      _result = result;
      _comtradeTableMap['Substation_name'] = result['stationName'] ?? '';
      _comtradeTableMap['device_id'] = result['deviceId'] ?? '';
      _comtradeTableMap['year'] = result['revYear'] ?? '';
      _comtradeTableMap['channel_count'] = result['numOfChannels'] ?? '';
      _comtradeTableMap['analog_channel_count'] =
          result['numOfAnalogChannels'] ?? '';
      _comtradeTableMap['digital_channel_count'] =
          result['numOfDigitalChannels'] ?? '';
      _comtradeTableMap['line_frequency'] = result['lineFrequency'] ?? '';
      _comtradeTableMap['start_timestamp'] = result['startTimestamp'] ?? '';
      _comtradeTableMap['end_timestamp'] = result['endTimestamp'] ?? '';
      _comtradeTableMap['file_type'] = result['fileType'] ?? '';
      _comtradeTableMap['time_multiplier'] = result['timeMultiplier'] ?? '';
      _comtradeTableMap['sample_rate'] = result['sampleRates'] ?? '';
      _comtradeTableMap['number_of_samples'] = result['numOfSamples'] ?? '';
    });
  }

  void setTableDataForPqdFile(var responseData) {
    final Map<String, dynamic> responseJson = jsonDecode(responseData.body);
    final Map<String, dynamic> result = responseJson['data'];
    final Map<String, dynamic> pqdData = result['pqd_data'];
    final Map<String, dynamic> logicalParserData = pqdData['logical_parser'][0];

    setState(() {
      _result = logicalParserData;
      _pqdTableMap['file_name'] = _result['file_name'] ?? '';
      _pqdTableMap['timestamp'] = _result['timestamp'] ?? '';
    });
  }

  Future<void> _processComtradeData(Enum requestOperation) async {
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
            'https://dev-pq-decoder.evs.com.sg/process_comtrade_file'), // Replace with your API URL
      );

      if (cfgFile!.bytes != null && datFile!.bytes != null) {
        // Create form data using html for web
        request.files.add(http.MultipartFile.fromBytes(
          'cfg_file', // The name of the field in the form data
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
          'dat_file', // The name of the field in the form data
          datFile!.bytes!,
          filename: datFile!.name,
        ));
      }
      request.fields['sample_step'] = _selectedStepValueComtrade.toString();
      request.fields['operation'] = requestOperation.name;
      request.fields['filename'] = cfgFilename;
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);

        switch (requestOperation) {
          case RequestOperations.plotGraph:
            setTableDataForComtrade(responseData);
            if (_result['analogChannels'] != null) {
              _handlePlotGraph(_result);
            }

          case RequestOperations.downloadJsonZip:
          case RequestOperations.downloadCsvZip:
            String contentType;

            // Set the content type for the zip file itself
            contentType =
                'application/zip'; // This is the content type for the zip file itself

            // Create the blob for the zip file content
            final blob = html.Blob([responseData.bodyBytes], contentType);

            // Create the URL from the Blob
            final url = html.Url.createObjectUrlFromBlob(blob);

            // Create the download anchor element
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

  Future<void> _processPQDData(Enum requestOperation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            pqdFile != null ? '.pqd file uploaded' : 'No .pqd file selected'),
        duration: const Duration(
            seconds: 2), // Duration for which the snackbar is displayed
      ),
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://dev-pq-decoder.evs.com.sg/process_pqd_file'), // Replace with your API URL
      );

      if (pqdFile!.bytes != null) {
        // Create form data using html for web
        request.files.add(http.MultipartFile.fromBytes(
          'pqd_file', // The name of the field in the form data
          pqdFile!.bytes!,
          filename: pqdFile!.name,
        ));
      } else {
        if (kDebugMode) {
          print('Error: File bytes are empty.');
        }
      }

      request.fields['sample_step'] = _selectedStepValuePQD.toString();
      request.fields['operation'] = requestOperation.name;
      request.fields['filename'] = pqdFilename;
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);

        switch (requestOperation) {
          case RequestOperations.plotGraph:
            setTableDataForPqdFile(responseData);
            if (_result['channel_info'] != null) {
              _handlePlotGraph(_result);
            }

          case RequestOperations.downloadJsonZip:
          case RequestOperations.downloadCsvZip:
            String contentType;

            // Set the content type for the zip file itself
            contentType =
                'application/zip'; // This is the content type for the zip file itself

            // Create the blob for the zip file content
            final blob = html.Blob([responseData.bodyBytes], contentType);

            // Create the URL from the Blob
            final url = html.Url.createObjectUrlFromBlob(blob);

            // Create the download anchor element
            final anchor = html.AnchorElement(href: url)
              ..setAttribute(
                  'download', '$pqdFilename.zip') // Set the download filename
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
    List<dynamic> dataSource =
        result['analogChannels'] ?? result['channel_info'] ?? [];
    List<Map<String, dynamic>> channels = [];

    for (int i = 0; i < dataSource.length; i++) {
      var channel = dataSource[i];

      channels.add({
        'channel_name': channel['channel_name'] ?? 'Channel $i',
        'phase': channel['phase'] ?? channel['phase_id'] ?? '',
        'measurement_unit':
            channel['measurement_unit'] ?? channel['unit'] ?? '',
        "data": List.generate(
            channel['values'].length,
            (index) => {
                  "x": (index + 1).toDouble(),
                  "y": channel['values'][index],
                }),
      });
    }

    // Now you have all channel data stored in the 'channels' list, and you can access them like:
    // channels[0] - first channel data
    // channels[1] - second channel data
    // channels[n] - nth channel data

    // Example: Access the first channel's name and values

    //convert to x,y format for both current and voltage

    setState(() {
      _voltageWaveformLineSelected = channels.where((channel) {
        return (channel['measurement_unit'] == "Voltage" ||
                channel['measurement_unit'] == "V") &&
            (channel['phase'] != 'NG' &&
                channel['phase'] != 'P3'); // Filter out non-voltage channels
      }).map((channel) {
        // Check if 'values' exists and is not null or empty
        if (channel['data'] != null && channel['data'].isNotEmpty) {
          return {
            "channel_name": channel['channel_name'], // Channel name
            "phase": channel['phase'], // Channel phase
            "measurement_unit":
                channel['measurement_unit'], // Measurement unit (Voltage)
            "data": List.generate(
              channel['data'].length, // Use the length of each channel's values
              (index) => {
                "x": channel['data'][index]["x"], // Keep original x value
                "y": channel['data'][index]["y"], // Fix: Access only y value
              },
            ),
          };
        } else {
          // Handle the case where 'values' is null or empty
          return {
            "channel_name": channel['channel_name'],
            "phase": channel['phase'],
            "measurement_unit": channel['measurement_unit'],
            "data": [], // Return an empty list for this channel
          };
        }
      }).toList();
      _currentWaveformLineSelected = channels.where((channel) {
        return (channel['measurement_unit'] == "Current" ||
                channel['measurement_unit'] == "A") &&
            (channel['phase'] != 'NG' &&
                channel['phase'] != 'P3'); // Filter out non-voltage channels
      }).map((channel) {
        // Check if 'values' exists and is not null or empty
        if (channel['data'] != null && channel['data'].isNotEmpty) {
          return {
            "channel_name": channel['channel_name'], // Channel name
            "phase": channel['phase'], // Channel phase
            "measurement_unit":
                channel['measurement_unit'], // Measurement unit (Voltage)
            "data": List.generate(
              channel['data'].length, // Use the length of each channel's values
              (index) => {
                "x": channel['data'][index]["x"], // Keep original x value
                "y": channel['data'][index]["y"], // Fix: Access only y value
              },
            ),
          };
        } else {
          // Handle the case where 'values' is null or empty
          return {
            "channel_name": channel['channel_name'],
            "phase": channel['phase'],
            "measurement_unit": channel['measurement_unit'],
            "data": [], // Return an empty list for this channel
          };
        }
      }).toList();
    });

    // if (result['analogChannels'] != null &&
    //     result['analogChannels'].isNotEmpty) {
    //   setState(() {
    //     _voltageWaveformLineSelected = channels.where((channel) {
    //       return channel['measurement_unit'] == "V" &&
    //           channel['phase'] != 'P3'; // Filter out non-voltage channels
    //     }).map((channel) {
    //       // Check if 'values' exists and is not null or empty
    //       if (channel['data'] != null && channel['data'].isNotEmpty) {
    //         return {
    //           "channel_name": channel['channel_name'], // Channel name
    //           "phase": channel['phase'], // Channel phase
    //           "measurement_unit":
    //               channel['measurement_unit'], // Measurement unit (Voltage)
    //           "data": List.generate(
    //             channel['data']
    //                 .length, // Use the length of each channel's values
    //             (index) => {
    //               "x": channel['data'][index]["x"], // Keep original x value
    //               "y": channel['data'][index]["y"], // Fix: Access only y value
    //             },
    //           ),
    //         };
    //       } else {
    //         // Handle the case where 'values' is null or empty
    //         return {
    //           "channel_name": channel['channel_name'],
    //           "phase": channel['phase'],
    //           "measurement_unit": channel['measurement_unit'],
    //           "data": [], // Return an empty list for this channel
    //         };
    //       }
    //     }).toList();
    //     _currentWaveformLineSelected = channels.where((channel) {
    //       return channel['measurement_unit'] == "A" &&
    //           channel['phase'] != 'P3'; // Filter out non-voltage channels
    //     }).map((channel) {
    //       // Check if 'values' exists and is not null or empty
    //       if (channel['data'] != null && channel['data'].isNotEmpty) {
    //         return {
    //           "channel_name": channel['channel_name'], // Channel name
    //           "phase": channel['phase'], // Channel phase
    //           "measurement_unit":
    //               channel['measurement_unit'], // Measurement unit (Voltage)
    //           "data": List.generate(
    //             channel['data']
    //                 .length, // Use the length of each channel's values
    //             (index) => {
    //               "x": channel['data'][index]["x"], // Keep original x value
    //               "y": channel['data'][index]["y"], // Fix: Access only y value
    //             },
    //           ),
    //         };
    //       } else {
    //         // Handle the case where 'values' is null or empty
    //         return {
    //           "channel_name": channel['channel_name'],
    //           "phase": channel['phase'],
    //           "measurement_unit": channel['measurement_unit'],
    //           "data": [], // Return an empty list for this channel
    //         };
    //       }
    //     }).toList();
    //   });
    // }
  }

  Widget getWaveformChart({
    required List<Map<String, dynamic>>
        waveformLineSelected, // Required parameter

    double? height, // Required parameter
    double? width, // Optional parameter
    String? title, // Optional parameter
  }) {
    if (waveformLineSelected.isEmpty) {
      return Container();
    }
    width ??= MediaQuery.of(context).size.width;

    List<Map<String, dynamic>> legend = [];

    List<Color> generateColors(int count) {
      const List<Color> baseColors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.pink,
        Colors.indigo,
        Colors.amber,
        Colors.cyan,
      ];
      List<Color> colors = [];
      for (int i = 0; i < count; i++) {
        colors.add(baseColors[i % baseColors.length]);
      }
      return colors;
    }

    List<Color> colors = generateColors(waveformLineSelected.length);

    // for (Map<String, dynamic> siteMap in waveformLineSelected) {
    //   String label = siteMap.keys.first;
    //   Color color = colors[i % colors.length];
    //   i++;
    //   legend.add({
    //     'name': label,
    //     'color': color,
    //   });
    // }

    return Flexible(
      fit: FlexFit.tight,
      child: SizedBox(
        height: height,
        // child: WgtLineChart(
        //   xKey: 'x',
        //   yKey: 'y',
        //   xTitleStyle: TextStyle(
        //     fontSize: 13.5,
        //     color: Theme.of(context).hintColor,
        //   ),
        //   yTitleStyle: TextStyle(
        //     fontSize: 13.5,
        //     color: Theme.of(context).hintColor,
        //   ),
        //   showTopTitle: false,
        //   showBottomTitle: true,
        //   showLeftAxisName: false,
        //   showRightTitle: false,
        //   showBottomAxisName: false,
        //   reservedSizeLeft: 55,
        //   reservedSizeRight: 55,
        //   isCurved: true,
        //   chartRatio: 2.8,
        //   // width: width,
        //   // height: height,
        //   dataSets: scaledDataSets,
        //   legend: legend,
        // ),
        child: WgtLineChart(
          channelList: waveformLineSelected,
          seriesColors: colors, // Pass the list of colors here
          graphTitle: title,
          xKey: 'x',
          yKey: 'y',
          // xTitleStyle: TextStyle(
          //   fontSize: 13.5,
          //   color: Theme.of(context).hintColor,
          // ),
          // yTitleStyle: TextStyle(
          //   fontSize: 13.5,
          //   color: Theme.of(context).hintColor,
          // ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              // child: ElevatedButton(
              //   onPressed: uploadCFGandDatFiles,
              //   child: const Text('upload cfg and dat File'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor:
              //         Color.fromARGB(255, 33, 132, 161), // Background color
              //     foregroundColor: Colors.white, // Text color
              //   ),
              // ),
              child: GenericWidgets.button(
                onPressed: uploadCFGandDatFiles,
                text: 'upload cfg and dat File',
                backgroundcolor: Color.fromARGB(255, 33, 132, 161),
                textColor: Colors.white,
                width: 180,
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
                value: _selectedStepValueComtrade, // Current selected value
                items: _stepOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      value.toString(),
                      style: const TextStyle(
                          color: Colors.white), // Foreground color for items
                    ),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedStepValueComtrade =
                        newValue; // Update the selected value
                  });

                  // Call your function with the selected value
                  if (_selectedStepValueComtrade != null) {
                    if (kDebugMode) {
                      print('Selected: $_selectedStepValueComtrade');
                    }
                  }
                },
                dropdownColor:
                    Colors.black, // Background color for the dropdown menu
              ),
            ),
            const SizedBox(width: 20),
            GenericWidgets.button(
                onPressed: () =>
                    _processComtradeData(RequestOperations.plotGraph),
                text: 'generate result',
                backgroundcolor: Color.fromARGB(255, 33, 132, 161),
                width: 180,
                textColor: Colors.white),
            const SizedBox(width: 20),
            GenericWidgets.button(
                onPressed: () =>
                    _processComtradeData(RequestOperations.downloadJsonZip),
                text: 'download JSON zip',
                backgroundcolor: Color.fromARGB(255, 33, 132, 161),
                width: 180,
                textColor: Colors.white),
            const SizedBox(width: 20),
            GenericWidgets.button(
                onPressed: () =>
                    _processComtradeData(RequestOperations.downloadCsvZip),
                text: 'download CSV zip',
                backgroundcolor: Color.fromARGB(255, 33, 132, 161),
                width: 180,
                textColor: Colors.white),
            const SizedBox(width: 20),
            GenericWidgets.button(
                onPressed: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
                text: "Toggle Theme",
                backgroundcolor: Color.fromARGB(255, 33, 132, 161),
                width: 180,
                textColor: Colors.white),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GenericWidgets.button(
                  onPressed: uploadPQDFiles,
                  text: 'upload pqd file',
                  backgroundcolor: Color.fromARGB(255, 33, 132, 161),
                  width: 180,
                  textColor: Colors.white),
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
                value: _selectedStepValuePQD, // Current selected value
                items: _stepOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      value.toString(),
                      style: const TextStyle(
                          color: Colors.white), // Foreground color for items
                    ),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedStepValuePQD =
                        newValue; // Update the selected value
                  });

                  // Call your function with the selected value
                  if (_selectedStepValuePQD != null) {
                    if (kDebugMode) {
                      print('Selected: $_selectedStepValuePQD');
                    }
                  }
                },
                dropdownColor:
                    Colors.black, // Background color for the dropdown menu
              ),
            ),
            const SizedBox(width: 20),
            GenericWidgets.button(
                onPressed: () => _processPQDData(RequestOperations.plotGraph),
                text: 'generate result',
                backgroundcolor: Color.fromARGB(255, 33, 132, 161),
                width: 180,
                textColor: Colors.white),
            const SizedBox(width: 20),
            GenericWidgets.button(
                onPressed: () =>
                    _processPQDData(RequestOperations.downloadJsonZip),
                text: 'download JSON zip',
                backgroundcolor: Color.fromARGB(255, 33, 132, 161),
                width: 180,
                textColor: Colors.white),
            const SizedBox(width: 20),
            GenericWidgets.button(
                onPressed: () =>
                    _processPQDData(RequestOperations.downloadCsvZip),
                text: 'download CSV zip',
                backgroundcolor: Color.fromARGB(255, 33, 132, 161),
                width: 180,
                textColor: Colors.white),
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
                    ..._comtradeTableMap.entries.map((entry) {
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
                    }),
                  ],
                ),
              ),
              SizedBox(
                width: 20,
              ),
              // Expanded widget for the graphs
              Expanded(
                child: Column(
                  children: [
                    Text(_pqdTableMap['file_name']),
                    Text(_pqdTableMap['timestamp']),
                    SizedBox(
                      height: 5,
                    ),
                    _voltageWaveformLineSelected.isNotEmpty
                        ? getWaveformChart(
                            height: 320,
                            waveformLineSelected: _voltageWaveformLineSelected,
                            title: "Voltage")
                        : const Text("No data available",
                            style: TextStyle(fontSize: 16)),
                    SizedBox(
                      height: 20,
                    ),
                    _currentWaveformLineSelected.isNotEmpty
                        ? getWaveformChart(
                            height: 320,
                            waveformLineSelected: _currentWaveformLineSelected,
                            title: "Current")
                        : const Text("No data available",
                            style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

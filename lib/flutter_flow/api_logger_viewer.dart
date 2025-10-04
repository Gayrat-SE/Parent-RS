import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// API Request Logger Viewer Widget
/// WebView ichidagi barcha API requestlarni ko'rsatadi
class APILoggerViewer extends StatefulWidget {
  final InAppWebViewController? controller;

  const APILoggerViewer({
    super.key,
    required this.controller,
  });

  @override
  State<APILoggerViewer> createState() => _APILoggerViewerState();
}

class _APILoggerViewerState extends State<APILoggerViewer> {
  List<Map<String, dynamic>> _logs = [];
  Set<String> _endpoints = {};
  Map<String, int> _methodStats = {};
  Map<String, int> _endpointStats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (widget.controller == null) {
      debugPrint('Controller is null');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Log'larni olish
      final logsResult = await widget.controller!.evaluateJavascript(
        source:
            'window.getAPIRequestLogs ? JSON.stringify(window.getAPIRequestLogs()) : "[]"',
      );

      // Endpoint'larni olish
      final endpointsResult = await widget.controller!.evaluateJavascript(
        source:
            'window.getUniqueEndpoints ? JSON.stringify(window.getUniqueEndpoints()) : "[]"',
      );

      // Statistikani olish
      final statsResult = await widget.controller!.evaluateJavascript(
        source:
            'window.getAPIRequestStats ? JSON.stringify(window.getAPIRequestStats()) : "{}"',
      );

      if (mounted) {
        setState(() {
          // Log'larni parse qilish
          if (logsResult != null) {
            try {
              final logsJson = jsonDecode(logsResult.toString());
              if (logsJson is List) {
                _logs = logsJson.cast<Map<String, dynamic>>();
              }
            } catch (e) {
              debugPrint('Error parsing logs: $e');
              _logs = [];
            }
          }

          // Endpoint'larni parse qilish
          if (endpointsResult != null) {
            try {
              final endpointsJson = jsonDecode(endpointsResult.toString());
              if (endpointsJson is List) {
                _endpoints = endpointsJson.cast<String>().toSet();
              }
            } catch (e) {
              debugPrint('Error parsing endpoints: $e');
              _endpoints = {};
            }
          }

          // Statistikani parse qilish
          if (statsResult != null) {
            try {
              final statsJson = jsonDecode(statsResult.toString());
              if (statsJson is Map) {
                final stats = statsJson.cast<String, dynamic>();
                _methodStats = (stats['methods'] as Map<String, dynamic>?)
                        ?.cast<String, int>() ??
                    {};
                _endpointStats = (stats['endpoints'] as Map<String, dynamic>?)
                        ?.cast<String, int>() ??
                    {};
              }
            } catch (e) {
              debugPrint('Error parsing stats: $e');
              _methodStats = {};
              _endpointStats = {};
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading logs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearLogs() async {
    if (widget.controller == null) return;

    try {
      await widget.controller!.evaluateJavascript(
        source: 'window.clearAPIRequestLogs && window.clearAPIRequestLogs();',
      );

      setState(() {
        _logs.clear();
        _endpoints.clear();
        _methodStats.clear();
        _endpointStats.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }

  void _copyLogToClipboard(Map<String, dynamic> log) {
    final logText = const JsonEncoder.withIndent('  ').convert(log);
    Clipboard.setData(ClipboardData(text: logText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log copied to clipboard')),
      );
    }
  }

  void _copyAllLogsToClipboard() {
    final allLogsText = const JsonEncoder.withIndent('  ').convert(_logs);
    Clipboard.setData(ClipboardData(text: allLogsText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All logs copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Request Logger (${_logs.length})'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _logs.isNotEmpty ? _copyAllLogsToClipboard : null,
            tooltip: 'Copy All',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _logs.isNotEmpty ? _clearLogs : null,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No API requests logged yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Make some API calls to see them here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Statistics Panel
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistics',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Requests',
                                  _logs.length.toString(),
                                  Icons.api,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  'Unique Endpoints',
                                  _endpoints.length.toString(),
                                  Icons.link,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_methodStats.isNotEmpty) ...[
                            Text(
                                'Methods: ${_methodStats.entries.map((e) => '${e.key}(${e.value})').join(', ')}'),
                          ],
                        ],
                      ),
                    ),
                    // Logs List
                    Expanded(
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log =
                              _logs[_logs.length - 1 - index]; // Reverse order
                          return _buildLogItem(log, index);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log, int index) {
    final method = log['method']?.toString() ?? 'UNKNOWN';
    final url = log['url']?.toString() ?? 'No URL';
    final type = log['type']?.toString() ?? 'UNKNOWN';
    final timestamp = log['timestamp'];
    final headers = log['headers'] as Map<String, dynamic>?;
    final body = log['body'];

    // Extract endpoint from URL
    String endpoint = url;
    try {
      final uri = Uri.parse(url);
      endpoint = uri.path;
    } catch (e) {
      // Keep original URL if parsing fails
    }

    // Method color
    Color methodColor = Colors.grey;
    switch (method.toUpperCase()) {
      case 'GET':
        methodColor = Colors.green;
        break;
      case 'POST':
        methodColor = Colors.blue;
        break;
      case 'PUT':
        methodColor = Colors.orange;
        break;
      case 'DELETE':
        methodColor = Colors.red;
        break;
      case 'PATCH':
        methodColor = Colors.purple;
        break;
    }

    // Format timestamp
    String timeStr = 'Unknown time';
    if (timestamp != null) {
      try {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        timeStr =
            '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
      } catch (e) {
        timeStr = timestamp.toString();
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: methodColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            method,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          endpoint,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                type,
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () => _copyLogToClipboard(log),
          tooltip: 'Copy Log',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full URL
                _buildDetailRow('URL', url),
                const SizedBox(height: 8),

                // Headers
                if (headers != null && headers.isNotEmpty) ...[
                  const Text(
                    'Headers:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: headers.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontFamily: 'monospace',
                              ),
                              children: [
                                TextSpan(
                                  text: '${entry.key}: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: entry.value.toString()),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Body
                if (body != null) ...[
                  const Text(
                    'Body:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      body.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

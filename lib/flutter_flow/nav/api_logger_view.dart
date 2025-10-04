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
        source: 'window.getAPIRequestLogs ? JSON.stringify(window.getAPIRequestLogs()) : "[]"',
      );

      // Endpoint'larni olish
      final endpointsResult = await widget.controller!.evaluateJavascript(
        source: 'window.getUniqueEndpoints ? JSON.stringify(window.getUniqueEndpoints()) : "[]"',
      );

      // Method statistikasini olish
      final methodStatsResult = await widget.controller!.evaluateJavascript(
        source: 'window.getRequestStatsByMethod ? JSON.stringify(window.getRequestStatsByMethod()) : "{}"',
      );

      // Endpoint statistikasini olish
      final endpointStatsResult = await widget.controller!.evaluateJavascript(
        source: 'window.getRequestStatsByEndpoint ? JSON.stringify(window.getRequestStatsByEndpoint()) : "{}"',
      );

      setState(() {
        if (logsResult != null && logsResult.toString().isNotEmpty) {
          final decoded = jsonDecode(logsResult.toString());
          _logs = List<Map<String, dynamic>>.from(decoded);
        }

        if (endpointsResult != null && endpointsResult.toString().isNotEmpty) {
          final decoded = jsonDecode(endpointsResult.toString());
          _endpoints = Set<String>.from(decoded);
        }

        if (methodStatsResult != null && methodStatsResult.toString().isNotEmpty) {
          final decoded = jsonDecode(methodStatsResult.toString());
          _methodStats = Map<String, int>.from(decoded);
        }

        if (endpointStatsResult != null && endpointStatsResult.toString().isNotEmpty) {
          final decoded = jsonDecode(endpointStatsResult.toString());
          _endpointStats = Map<String, int>.from(decoded);
        }

        _isLoading = false;
      });

      debugPrint('Loaded ${_logs.length} API requests');
      debugPrint('Found ${_endpoints.length} unique endpoints');
    } catch (e) {
      debugPrint('Error loading logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    if (widget.controller == null) return;

    try {
      await widget.controller!.evaluateJavascript(
        source: 'window.clearAPIRequestLogs ? window.clearAPIRequestLogs() : null',
      );

      setState(() {
        _logs.clear();
        _endpoints.clear();
        _methodStats.clear();
        _endpointStats.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared')),
        );
      }
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }

  Future<void> _exportLogs() async {
    if (widget.controller == null) return;

    try {
      final result = await widget.controller!.evaluateJavascript(
        source: 'window.exportAPIRequestLogs ? window.exportAPIRequestLogs() : "[]"',
      );

      if (result != null) {
        await Clipboard.setData(ClipboardData(text: result.toString()));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logs copied to clipboard')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error exporting logs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Request Logger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _exportLogs,
            tooltip: 'Export to Clipboard',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Logs', icon: Icon(Icons.list)),
                      Tab(text: 'Endpoints', icon: Icon(Icons.link)),
                      Tab(text: 'Methods', icon: Icon(Icons.bar_chart)),
                      Tab(text: 'Stats', icon: Icon(Icons.analytics)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildLogsTab(),
                        _buildEndpointsTab(),
                        _buildMethodsTab(),
                        _buildStatsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLogsTab() {
    if (_logs.isEmpty) {
      return const Center(
        child: Text('No API requests logged yet'),
      );
    }

    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            leading: _getMethodIcon(log['method']),
            title: Text(
              '${log['method']} ${_getShortUrl(log['url'])}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(log['datetime'] ?? ''),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Type', log['type']),
                    _buildInfoRow('URL', log['url']),
                    _buildInfoRow('Time', log['datetime']),
                    const SizedBox(height: 8),
                    const Text(
                      'Headers:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatJson(log['headers']),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    if (log['body'] != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Body:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatJson(log['body']),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEndpointsTab() {
    if (_endpoints.isEmpty) {
      return const Center(
        child: Text('No endpoints found'),
      );
    }

    final sortedEndpoints = _endpoints.toList()..sort();

    return ListView.builder(
      itemCount: sortedEndpoints.length,
      itemBuilder: (context, index) {
        final endpoint = sortedEndpoints[index];
        final count = _endpointStats[endpoint] ?? 0;

        return ListTile(
          leading: const Icon(Icons.link),
          title: Text(endpoint),
          trailing: Chip(
            label: Text('$count'),
            backgroundColor: Colors.blue.shade100,
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: endpoint));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied: $endpoint')),
            );
          },
        );
      },
    );
  }

  Widget _buildMethodsTab() {
    if (_methodStats.isEmpty) {
      return const Center(
        child: Text('No method statistics available'),
      );
    }

    return ListView(
      children: _methodStats.entries.map((entry) {
        return ListTile(
          leading: _getMethodIcon(entry.key),
          title: Text(entry.key),
          trailing: Chip(
            label: Text('${entry.value}'),
            backgroundColor: _getMethodColor(entry.key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard('Total Requests', _logs.length.toString(), Icons.all_inbox),
        _buildStatCard('Unique Endpoints', _endpoints.length.toString(), Icons.link),
        _buildStatCard('HTTP Methods', _methodStats.length.toString(), Icons.http),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Icon _getMethodIcon(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Icon(Icons.download, color: Colors.green);
      case 'POST':
        return const Icon(Icons.upload, color: Colors.blue);
      case 'PUT':
        return const Icon(Icons.edit, color: Colors.orange);
      case 'DELETE':
        return const Icon(Icons.delete, color: Colors.red);
      case 'PATCH':
        return const Icon(Icons.update, color: Colors.purple);
      default:
        return const Icon(Icons.http, color: Colors.grey);
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green.shade100;
      case 'POST':
        return Colors.blue.shade100;
      case 'PUT':
        return Colors.orange.shade100;
      case 'DELETE':
        return Colors.red.shade100;
      case 'PATCH':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  String _getShortUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path;
    } catch (e) {
      return url;
    }
  }

  String _formatJson(dynamic data) {
    try {
      if (data == null) return 'null';
      if (data is String) return data;
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}


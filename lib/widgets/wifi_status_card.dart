import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/wifi_connection_model.dart';
import '../services/wifi_connection_service.dart';

class WifiStatusCard extends StatefulWidget {
  final WifiConnectionService? service;

  const WifiStatusCard({super.key, this.service});

  @override
  State<WifiStatusCard> createState() => _WifiStatusCardState();
}

class _WifiStatusCardState extends State<WifiStatusCard> {
  late final WifiConnectionService _service;
  WifiConnectionInfo? _connection;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? WifiConnectionService();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  Future<void> _refresh() async {
    WifiConnectionInfo? connection;
    try {
      connection = await _service.currentConnection();
    } catch (_) {
      connection = const WifiConnectionInfo(isWifi: false);
    }
    if (!mounted) return;
    setState(() => _connection = connection);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connection = _connection;
    final isWifi = connection?.isWifi == true;
    final color = isWifi ? AppColors.healthIdeal : AppColors.offlineRed;
    final status = connection == null
        ? 'Verificando Wi-Fi...'
        : isWifi
        ? 'Wi-Fi conectado'
        : 'Wi-Fi desconectado';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isWifi ? CupertinoIcons.wifi : CupertinoIcons.wifi_slash,
            color: color,
            size: 23,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  connection?.ssid == null || connection!.ssid!.isEmpty
                      ? 'SSID não disponível. O teste pelo IP continuará.'
                      : 'Rede: ${connection.ssid}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
                if (connection?.ipAddress != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'IP do celular: ${connection!.ipAddress}',
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
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
}

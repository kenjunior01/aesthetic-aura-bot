/// aura_lembretes.dart — o app toca campainha por ti: ritual diário e o
/// check-in semanal da Jornada do Auge, como notificações locais.
///
/// Agendamento INEXATO (inexactLocalTime): sem pedir SCHEDULE_EXACT_ALARM
/// (janelas de bateria e permissões raras no Android 14+). O atraso máximo
/// de minutos não muda nada num lembrete de autocuidado.
///
/// Todo o motor falha em silêncio: sem permissão → o toggle volta ao
/// estado anterior; sem canal de notificação (testes) → nada explode.
library;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class AuraLembretes {
  AuraLembretes._();
  static final AuraLembretes I = AuraLembretes._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _iniciado = false;

  static const _canal = 'aurastyle-lembretes';
  static const _idRitual = 1001;
  static const _idCheckin = 1002;

  /// Inicializa plugin + timezone local. Idempotente; nunca lança.
  Future<void> _init() async {
    if (_iniciado) return;
    _iniciado = true;
    try {
      tzdata.initializeTimeZones();
      // Location de OFFSET FIXO derivada do sistema — evita o plugin
      // flutter_timezone (Kotlin desalinhado que partia o build). Sem
      // fuso IANA não há ajuste de hora-de-verão: o lembrete pode ficar
      // 1 h deslocado em regiões com DST — aceitável para autocuidado.
      final deslocamento = DateTime.now().timeZoneOffset;
      final zona = tz.TimeZone(
        deslocamento.inMilliseconds,
        isDst: false,
        abbreviation: 'aura',
      );
      tz.setLocalLocation(
        tz.Location('aura-local-fixed', [tz.minTime], const [0], [zona]),
      );
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      );
      await _plugin.initialize(settings);
    } catch (_) {
      // ambiente sem canais (testes/web) → silêncio
    }
  }

  static const NotificationDetails _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      _canal,
      'Lembretes AuraStyle',
      channelDescription: 'Ritual de hoje e check-in da jornada',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: Color(0xFFB8D9F3),
    ),
  );

  /// Liga/desliga os lembretes e reagenda com a hora escolhida.
  /// [minutosDoDia] = hora*60+minuto do ritual diário.
  Future<void> agendar({required bool ligado, required int minutosDoDia}) async {
    await _init();
    try {
      await cancelar();
      if (!ligado) return;

      // Android 13+ pede a permissão em runtime na primeira vez.
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final ok = await android.requestNotificationsPermission();
        if (ok == false) return; // recusada → respeita e sai
      }

      final agora = DateTime.now();
      final h = minutosDoDia ~/ 60;
      final m = minutosDoDia % 60;
      var alvo = DateTime(agora.year, agora.month, agora.day, h, m);
      if (!alvo.isAfter(agora)) alvo = alvo.add(const Duration(days: 1));
      final tzAlvo = tz.TZDateTime.from(alvo, tz.local);

      // 1) RITUAL DIÁRIO — repete todos os dias à mesma hora.
      await _plugin.zonedSchedule(
        _idRitual,
        'Hora do ritual',
        'Cinco passos, cinco minutos — a tua aura agradece.',
        tzAlvo,
        _detalhes,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 2) CHECK-IN SEMANAL — segunda-feira às 10:00 (a semana decide-se
      // agora; a foto de hoje vira o "antes" da próxima).
      final seg = _proximaSegunda(agora);
      await _plugin.zonedSchedule(
        _idCheckin,
        'Check-in da jornada',
        'Uma foto nova, uma comparação real — vê o quanto evoluíste.',
        tz.TZDateTime.from(seg, tz.local),
        _detalhes,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint('AuraLembretes: agendado $tzAlvo + $seg');
    } catch (_) {
      // dispositivo sem suporte → silêncio
    }
  }

  DateTime _proximaSegunda(DateTime agora) {
    var d = DateTime(agora.year, agora.month, agora.day, 10, 0);
    do {
      d = d.add(const Duration(days: 1));
    } while (d.weekday != DateTime.monday);
    return d;
  }

  /// Cancela todos os lembretes agendados.
  Future<void> cancelar() async {
    try {
      await _plugin.cancel(_idRitual);
      await _plugin.cancel(_idCheckin);
    } catch (_) {}
  }
}

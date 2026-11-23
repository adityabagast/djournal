enum FeedbackKind { bug, feature }

enum FeedbackArea { journal, money, report, reminders, backup, other }

enum FeedbackSeverity { low, medium, high }

const feedbackTitleMax = 80;
const feedbackBodyMax = 1000;

bool validFeedbackTitle(String text) => text.trim().length >= 5;

bool validFeedbackBody(String text) => text.trim().length >= 10;

/// Isi email masukan. Hanya memuat tulisan user dan (opsional) info
/// perangkat; tidak pernah membaca jurnal atau data keuangan.
class FeedbackMail {
  const FeedbackMail({required this.subject, required this.body});

  factory FeedbackMail.compose({
    required String kindLabel,
    required String title,
    required String areaLine,
    String? severityLine,
    required String body,
    List<String> deviceLines = const [],
  }) => FeedbackMail(
    subject: 'Nyawtat · $kindLabel: ${title.trim()}',
    body: [
      areaLine,
      ?severityLine,
      '',
      body.trim(),
      if (deviceLines.isNotEmpty) ...['', ...deviceLines],
    ].join('\n'),
  );

  final String subject;
  final String body;

  /// Tautan `mailto:`. Di-encode sendiri karena `queryParameters` mengubah
  /// spasi jadi "+", yang tampil apa adanya di aplikasi email.
  Uri uri(String to) {
    final text = body.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n');
    return Uri(
      scheme: 'mailto',
      path: to,
      query:
          'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(text)}',
    );
  }
}

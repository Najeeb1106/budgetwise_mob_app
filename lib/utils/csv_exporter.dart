import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class CsvExporter {
  /// Generates a valid RFC-4180 CSV string from a list of transactions.
  static String generateCsv(List<TransactionWithCategory> transactions) {
    final buffer = StringBuffer();
    // CSV Header row
    buffer.writeln('Date,Category,Amount,Type,Notes');

    final dateFormatter = DateFormat('yyyy-MM-dd');

    // Iterate and write transaction records
    for (final item in transactions) {
      final tx = item.transaction;
      final cat = item.category;

      final dateStr = dateFormatter.format(tx.date);
      final categoryStr = _escapeCsvValue(cat.name);
      final amountStr = tx.amount.toStringAsFixed(2);
      final typeStr = tx.type; // 'income' | 'expense'
      final notesStr = _escapeCsvValue(tx.note ?? '');

      buffer.writeln('$dateStr,$categoryStr,$amountStr,$typeStr,$notesStr');
    }

    return buffer.toString();
  }

  /// Escapes CSV field values according to RFC-4180 specs.
  /// If the field contains a comma, double-quote, or newline,
  /// it is wrapped in double quotes and inner quotes are doubled.
  static String _escapeCsvValue(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}

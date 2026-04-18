import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/inventory_models.dart';

class ReportPdfHelper {
  static final _fmt = NumberFormat('#,##0', 'en_US');

  static Future<void> generateRecentMovementsPdf(List<RecentMovement> movements, String filter) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader('Recent Movements Report', 'Filter: ${filter.toUpperCase()}'),
          pw.SizedBox(height: 20),
          _buildRecentMovementsTable(movements),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Recent_Movements_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> generateItemMovementsPdf(
      List<StockMovementReport> movements, String itemName, DateTime startDate, DateTime endDate) async {
    final pdf = pw.Document();
    final dateRange = '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader('Item Movements Report', 'Item: $itemName\nPeriod: $dateRange'),
          pw.SizedBox(height: 20),
          _buildItemMovementsTable(movements),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Item_Movements_${itemName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> generateDailySummaryPdf(List<DailyStockSummary> summaries, String itemName, int daysBack) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader('Daily Summary Report', 'Item: $itemName\nHistory: Last $daysBack Days'),
          pw.SizedBox(height: 20),
          _buildDailySummaryTable(summaries),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Daily_Summary_${itemName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> generateMonthlyReportPdf(List<MonthlyStockReport> reports, int year) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader('Monthly Stock Report', 'Year: $year'),
          pw.SizedBox(height: 20),
          _buildMonthlyReportTable(reports),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Monthly_Report_$year.pdf',
    );
  }

  static pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(subtitle, style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 10),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildRecentMovementsTable(List<RecentMovement> movements) {
    final headers = ['Date', 'Item Name', 'Type', 'Qty', 'Value (Rs)'];
    final data = movements.map((m) {
      final isDeficit = m.movementType == 'sale' || m.movementType == 'damage';
      return [
        DateFormat('MMM dd, yyyy').format(m.createdAt),
        m.itemName,
        m.movementType.toUpperCase(),
        '${isDeficit ? '-' : '+'}${m.quantity % 1 == 0 ? m.quantity.toInt() : m.quantity}',
        _fmt.format(m.transactionValue),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildItemMovementsTable(List<StockMovementReport> movements) {
    final headers = ['Date', 'Type', 'Quantity', 'Notes'];
    final data = movements.map((m) {
      final isDeficit = m.type == 'sale' || m.type == 'damage';
      return [
        DateFormat('MMM dd, yyyy').format(m.createdAt),
        m.type.toUpperCase(),
        '${isDeficit ? '-' : '+'}${m.quantity % 1 == 0 ? m.quantity.toInt() : m.quantity}',
        m.notes ?? '-',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
      },
    );
  }

  static pw.Widget _buildDailySummaryTable(List<DailyStockSummary> summaries) {
    final headers = ['Date', 'IN', 'OUT', 'Sales (Rs)', 'Profit (Rs)', 'Closing Qty'];
    final data = summaries.map((s) {
      return [
        DateFormat('MMM dd, yyyy').format(s.date),
        s.totalPurchasedQty.toString(),
        s.totalSoldQty.toString(),
        _fmt.format(s.salesValue),
        _fmt.format(s.grossProfit),
        s.closingStockQty.toString(),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildMonthlyReportTable(List<MonthlyStockReport> reports) {
    final headers = ['Month', 'Sold Qty', 'Sales Value (Rs)', 'Profit (Rs)', 'Margin (%)'];
    final data = reports.map((r) {
      return [
        r.monthName,
        r.totalSalesQty.toString(),
        _fmt.format(r.totalSalesValue),
        _fmt.format(r.grossProfit),
        '${r.grossMarginPercentage.toStringAsFixed(2)}%',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }
}

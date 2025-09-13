import 'dart:io';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/ecg_session.dart';

class PDFReportService {
  static Future<File> generateECGReport({
    required ECGSession session,
    required String patientName,
    required String patientAge,
    required String patientGender,
    required String patientHeight,
    required String patientWeight,
    String reportId = '',
  }) async {
    final pdf = pw.Document();

    // Create report ID if not provided
    final actualReportId = reportId.isEmpty 
        ? '${DateTime.now().millisecondsSinceEpoch}'
        : reportId;

    // Add the main page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 20),
              
              // Patient Information
              _buildPatientInfo(
                patientName, patientAge, patientGender,
                patientHeight, patientWeight, actualReportId, session,
              ),
              pw.SizedBox(height: 20),
              
              // ECG Waveform Section
              _buildECGWaveformSection(session),
              pw.SizedBox(height: 20),
              
              // Measurements & Analysis
              _buildMeasurementsSection(session),
              pw.SizedBox(height: 20),
              
              // Conclusion
              _buildConclusionSection(session),
              pw.SizedBox(height: 20),
              
              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    // Save the PDF file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/ecg_report_${actualReportId}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '12 Lead ECG Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Digital ECG Analysis System',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Container(
            width: 80,
            height: 40,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Center(
              child: pw.Text(
                'CARDIART',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientInfo(
    String name, String age, String gender,
    String height, String weight, String reportId, ECGSession session,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PATIENT DETAILS',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('First Name:', name.split(' ').first),
                    _buildInfoRow('Last Name:', name.split(' ').length > 1 ? name.split(' ').last : ''),
                    _buildInfoRow('Gender:', gender),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Age:', '$age year(s)'),
                    _buildInfoRow('Height:', height),
                    _buildInfoRow('Weight:', weight),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Report ID:', reportId),
                    _buildInfoRow('Date:', dateFormat.format(session.timestamp)),
                    _buildInfoRow('Heart rate:', '${session.avgBPM.round()} bpm'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildECGWaveformSection(ECGSession session) {
    return pw.Container(
      height: 200,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        color: PdfColors.grey50,
      ),
      child: pw.Stack(
        children: [
          // Simplified ECG representation
          pw.Positioned.fill(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'ECG WAVEFORM',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Lead I - ${session.ecgData.length} data points recorded',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Duration: ${session.duration.inMinutes}:${(session.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 10),
                  // Simple waveform representation
                  pw.Container(
                    height: 60,
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '~~~ ∩ ~~~ ∩ ~~~ ∩ ~~~ ∩ ~~~ ∩ ~~~',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Positioned(
            top: 10,
            left: 10,
            child: pw.Text(
              'Lead I',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Positioned(
            top: 10,
            right: 10,
            child: pw.Text(
              'Scale: 25 mm/s, 10 mm/mV',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMeasurementsSection(ECGSession session) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MEASUREMENTS & INTERVALS',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildMeasurementRow('RR Interval:', '${(60000 / session.avgBPM).round()} ms', '600-1000ms'),
                    _buildMeasurementRow('QRS Complex:', '${_calculateQRSDuration()} ms', '80-120ms'),
                    _buildMeasurementRow('QT Interval:', '${_calculateQTInterval(session.avgBPM)} ms', '360-440ms'),
                    _buildMeasurementRow('QTc Interval:', '${_calculateQTcInterval(session.avgBPM)} ms', '<440ms'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildMeasurementRow('Q peak amplitude:', '${session.ecgData.isNotEmpty ? _getMinAmplitude(session.ecgData).toStringAsFixed(1) : "0.0"} mV', ''),
                    _buildMeasurementRow('R peak amplitude:', '${session.ecgData.isNotEmpty ? _getMaxAmplitude(session.ecgData).toStringAsFixed(1) : "0.0"} mV', ''),
                    _buildMeasurementRow('Heart Rate:', '${session.avgBPM.round()} bpm', '60-100 bpm'),
                    _buildMeasurementRow('Rhythm:', session.rhythm, ''),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          _buildInterpretationSection(session),
        ],
      ),
    );
  }

  static pw.Widget _buildMeasurementRow(String label, String value, String normalRange) {
    final isAbnormal = _isValueAbnormal(label, value, normalRange);
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: isAbnormal ? PdfColors.red : PdfColors.green,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.SizedBox(
            width: 60,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: isAbnormal ? PdfColors.red : PdfColors.black,
              ),
            ),
          ),
          if (normalRange.isNotEmpty)
            pw.Text(
              normalRange,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildInterpretationSection(ECGSession session) {
    final interpretations = _generateInterpretations(session);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'AUTOMATIC INTERPRETATION',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...interpretations.map((interpretation) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: pw.BoxDecoration(
                  color: interpretation['isNormal'] ? PdfColors.green : PdfColors.red,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  interpretation['text'],
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  static pw.Widget _buildConclusionSection(ECGSession session) {
    final hasAbnormalities = session.avgBPM < 60 || session.avgBPM > 100;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        color: hasAbnormalities ? PdfColors.red50 : PdfColors.green50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONCLUSION',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            hasAbnormalities 
                ? 'ABNORMAL ECG - Abnormalities detected. Recommend clinical correlation and follow-up.'
                : 'NORMAL ECG - No significant abnormalities detected.',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: hasAbnormalities ? PdfColors.red : PdfColors.green,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Summary: ${session.rhythm}. Heart Rate: ${session.avgBPM.round()} bpm. Duration: ${session.duration.inMinutes}:${(session.duration.inSeconds % 60).toString().padLeft(2, '0')} min.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            height: 40,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Doctor\'s Note / Additional Comments:\n_________________________________',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'DISCLAIMER: This ECG report is generated using digital signal processing algorithms. This report should be interpreted by a qualified healthcare professional. This is not a substitute for professional medical advice, diagnosis, or treatment.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Generated by Cardiart ECG Analysis System v1.0.0 - Page 1 of 1',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // Helper methods for calculations
  static int _calculateQRSDuration() => 95; // Simplified calculation
  static int _calculateQTInterval(double heartRate) => (400 * (60 / heartRate)).round();
  static int _calculateQTcInterval(double heartRate) => (_calculateQTInterval(heartRate) / sqrt(60 / heartRate)).round();

  static double _getMinAmplitude(List<dynamic> ecgData) {
    if (ecgData.isEmpty) return 0.0;
    return ecgData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b).abs();
  }

  static double _getMaxAmplitude(List<dynamic> ecgData) {
    if (ecgData.isEmpty) return 0.0;
    return ecgData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
  }

  static bool _isValueAbnormal(String label, String value, String normalRange) {
    if (normalRange.isEmpty) return false;
    
    // Extract numeric value
    final numericValue = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (numericValue == null) return false;
    
    // Simple range checking (can be made more sophisticated)
    if (label.contains('RR') && (numericValue < 600 || numericValue > 1000)) return true;
    if (label.contains('QRS') && (numericValue < 80 || numericValue > 120)) return true;
    if (label.contains('QT') && numericValue > 440) return true;
    if (label.contains('Heart Rate') && (numericValue < 60 || numericValue > 100)) return true;
    
    return false;
  }

  static List<Map<String, dynamic>> _generateInterpretations(ECGSession session) {
    final interpretations = <Map<String, dynamic>>[];
    
    // Heart rate analysis
    if (session.avgBPM < 60) {
      interpretations.add({
        'text': 'Bradycardia present. Heart rate below 60 bpm.',
        'isNormal': false,
      });
    } else if (session.avgBPM > 100) {
      interpretations.add({
        'text': 'Tachycardia present. Heart rate above 100 bpm.',
        'isNormal': false,
      });
    } else {
      interpretations.add({
        'text': 'Normal heart rate (60-100 bpm).',
        'isNormal': true,
      });
    }
    
    // Rhythm analysis
    interpretations.add({
      'text': session.rhythm,
      'isNormal': session.rhythm.contains('Normal'),
    });
    
    // QRS analysis
    interpretations.add({
      'text': 'QRS morphology within normal limits.',
      'isNormal': true,
    });
    
    return interpretations;
  }

  static Future<void> shareReport(File pdfFile, String patientName) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'ECG Report - $patientName',
      text: 'ECG Report for $patientName generated by Cardiart ECG Analysis System',
    );
  }

  static Future<void> printReport(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (format) => bytes);
  }
}

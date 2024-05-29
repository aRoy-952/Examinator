import 'package:flutter/material.dart';
import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PdfViewerDrawer extends StatefulWidget {
  final String pdfUrl;

  const PdfViewerDrawer({Key? key, required this.pdfUrl,}) : super(key: key);

  @override
  State<PdfViewerDrawer> createState() => _PdfViewerDrawerState();
}

class _PdfViewerDrawerState extends State<PdfViewerDrawer> {
  late PDFDocument document;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializePdf();
  }

  Future<void> initializePdf() async {
    try {
      FileInfo? fileInfo = await DefaultCacheManager().getFileFromCache(widget.pdfUrl);

      if (fileInfo != null && fileInfo.file != null) {
        document = await PDFDocument.fromFile(fileInfo.file!);
      } else {
        var file = await DefaultCacheManager().getSingleFile(widget.pdfUrl);
        document = await PDFDocument.fromFile(file!);
      }
    } catch (e) {
      errorMessage = 'Failed to load PDF: $e';
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      child: Container(
        color: Colors.white,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text(errorMessage!))
            : PDFViewer(
          document: document,
          lazyLoad: false,
          zoomSteps: 3,
          scrollDirection: Axis.vertical,
          enableSwipeNavigation: true,
          backgroundColor: Colors.transparent,
          indicatorPosition: IndicatorPosition.bottomLeft,
        ),
      ),
    );
  }
}

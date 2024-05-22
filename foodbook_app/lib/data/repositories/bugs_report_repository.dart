import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodbook_app/data/data_sources/database_provider.dart';
import 'package:foodbook_app/data/dtos/bug_report_dto.dart';
import 'package:foodbook_app/data/models/bug_report.dart';

class BugReportRepository {
  final DatabaseProvider dbProvider;
  final _fireCloud = FirebaseFirestore.instance.collection("bugReports");

  BugReportRepository(this.dbProvider);

  Future<String> reportBug({ required BugReport bugReport }) async {
    try {
      print('BUG REPORT: ${BugReportDTO.fromModel(bugReport).toJson(false)}');
      DocumentReference bugReportRef = await _fireCloud.add(BugReportDTO.fromModel(bugReport).toJson(false));
      return bugReportRef.id;
    } on FirebaseException catch (e) {
      print("Failed with error '${e.code}': ${e.message}");
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: "Failed to add bug report: '${e.code}': ${e.message}"
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> reportBugDraft(BugReport bugReport) async {
    print('BUG REPORT DRAFT: ${BugReportDTO.fromModel(bugReport).toJson(true)}');
    final db = await dbProvider.getDatabase();
    await db.insert('BugsReports', BugReportDTO.fromModel(bugReport).toJson(true));
    print('DRAFT SAVED: ${BugReportDTO.fromModel(bugReport).toJson(true)}');
  }

  Future<BugReport?> getBugReportDraft() async {
    final db = await dbProvider.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query("BugsReports");
    if (maps.isNotEmpty) {
      print('DRAFT: ${BugReportDTO.fromJson(maps.first).toJson(true)}');
      return BugReportDTO.fromJson(maps.first).toModel();
    }
    return null;
  }

  Future<void> deleteBugReportDraft() async {
    await dbProvider.clearTable('BugsReports');
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbook_app/bloc/bug_report_bloc/bug_report_bloc.dart';
import 'package:foodbook_app/bloc/bug_report_bloc/bug_report_event.dart';
import 'package:foodbook_app/bloc/settings_bloc/settings_bloc.dart';
import 'package:foodbook_app/data/models/bug_report.dart';
import 'package:foodbook_app/presentation/views/settings_view/settings_view.dart';

class BugReportView extends StatefulWidget {
  final BugReport? initialBugReport;

  const BugReportView({
    super.key,
    this.initialBugReport
  });

  @override
  _BugReportViewState createState() => _BugReportViewState();
}

class _BugReportViewState extends State<BugReportView> {
  final TextEditingController bugDetailsController = TextEditingController();
  final TextEditingController stepsToReproduceController = TextEditingController();
  String bugType = 'Unexpected Behavior';
  String severityLevel = 'Minor';

  @override
  void initState() {
    super.initState();
    if (widget.initialBugReport != null) {
      bugDetailsController.text = widget.initialBugReport!.description;
      bugType = widget.initialBugReport!.bugType;
      severityLevel = widget.initialBugReport!.severityLevel;
      stepsToReproduceController.text = widget.initialBugReport!.stepsToReproduce;
    }
  }

  Future<void> _createBugReportDraft(BuildContext context) async {
    final bugReportBloc = BlocProvider.of<BugReportBloc>(context);

    final saveDraft = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Would you like to save this bug as a draft?"),
          content: const Text('This will delete your latest draft'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop('No');
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop('Yes');
              },
            ),
          ],
        );
      },
    );

    if (saveDraft == 'Yes') {
      bugReportBloc.add(DeleteBugReportDraft());
      BugReport newReport = BugReport(
        description: bugDetailsController.text,
        bugType: bugType,
        severityLevel: severityLevel,
        stepsToReproduce: stepsToReproduceController.text,
      );
      BlocProvider.of<BugReportBloc>(context).add(SaveBugReportDraft(newReport));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: BlocProvider.of<SettingsBloc>(context),
            child: const SettingsPage(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<SettingsBloc>(context),
              child: const SettingsPage(),
            ),
          ),
        );
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text("Report a Bug"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              _createBugReportDraft(context);
            },
            child: const Text(
              'Save as draft',
              style: TextStyle(
                fontSize: 20,
                color: Color.fromRGBO(0, 122, 255, 100),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              controller: bugDetailsController,
              decoration: const InputDecoration(
                labelText: 'Bug Details',
                hintText: 'Describe the issue...',
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: bugType,
              onChanged: (String? newValue) {
                setState(() {
                  bugType = newValue!;
                });
              },
              items: <String>['Unexpected Behavior', 'Crash', 'Other']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Bug Type',
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: severityLevel,
              onChanged: (String? newValue) {
                setState(() {
                  severityLevel = newValue!;
                });
              },
              items: <String>['Minor', 'Major']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Severity Level',
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: stepsToReproduceController,
              decoration: const InputDecoration(
                labelText: 'Steps to Reproduce',
                hintText: 'For example: Open the app > navigate to the ForYou page > tap on the logout button',
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  BugReport newReport = BugReport(
                    date: Timestamp.fromDate(DateTime.now()),
                    description: bugDetailsController.text,
                    bugType: bugType,
                    severityLevel: severityLevel,
                    stepsToReproduce: stepsToReproduceController.text,
                  );
                  BlocProvider.of<BugReportBloc>(context).add(ReportBug(newReport));
                },
                child: const Text('Send Bug Report'),
              ),
            )
          ],
        ),
      ),
    ));
  }
}

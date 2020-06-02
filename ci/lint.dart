/// Runs clang-tidy on files with changes.
///
/// usage:
/// dart lint.dart <path to compile_commands.json> <path to git repository> [clang-tidy checks]
///
/// User environment variable FLUTTER_LINT_ALL to run on all files.
import 'dart:async' show Completer;
import 'dart:convert' show jsonDecode, utf8;
import 'dart:io'
    show
        File,
        Process,
        ProcessResult,
        exit,
        Directory,
        FileSystemEntity,
        Platform;

class Command {
  String directory;
  String command;
  String file;
}

Command parseCommand(Map<String, dynamic> map) {
  return Command()
    ..directory = map['directory'] as String
    ..command = map['command'] as String
    ..file = map['file'] as String;
}

String calcTidyArgs(Command command) {
  String result = command.command;
  result = result.replaceAll(RegExp(r'\S*clang/bin/clang'), '');
  result = result.replaceAll(RegExp(r'-MF \S*'), '');
  return result;
}

String calcTidyPath(Command command) {
  final RegExp regex = RegExp(r'\S*clang/bin/clang');
  return regex
      .stringMatch(command.command)
      .replaceAll('clang/bin/clang', 'clang/bin/clang-tidy');
}

bool isNonEmptyString(String str) => str.isNotEmpty;

bool containsAny(String str, List<String> queries) {
  for (String query in queries) {
    if (str.contains(query)) {
      return true;
    }
  }
  return false;
}

/// Returns a list of all files with current changes or differ from `master`.
List<String> getListOfChangedFiles(String repoPath) {
  final Set<String> result = <String>{};
  final ProcessResult diffResult = Process.runSync(
      'git', <String>['diff', '--name-only'],
      workingDirectory: repoPath);
  final ProcessResult diffCachedResult = Process.runSync(
      'git', <String>['diff', '--cached', '--name-only'],
      workingDirectory: repoPath);

  final ProcessResult mergeBaseResult = Process.runSync(
      'git',<String>['merge-base', 'master', 'HEAD'],
      workingDirectory: repoPath);
  final String mergeBase = (mergeBaseResult.stdout as String).trim();
  final ProcessResult masterResult = Process.runSync(
      'git', <String>['diff', '--name-only', mergeBase],
      workingDirectory: repoPath);
  result.addAll((diffResult.stdout as String).split('\n').where(isNonEmptyString));
  result.addAll((diffCachedResult.stdout as String).split('\n').where(isNonEmptyString));
  result.addAll((masterResult.stdout as String).split('\n').where(isNonEmptyString));
  return result.toList();
}

Future<List<String>> dirContents(String repoPath) {
  final Directory dir = Directory(repoPath);
  final List<String> files = <String>[];
  final Completer<List<String>> completer = Completer<List<String>>();
  final Stream<FileSystemEntity> lister = dir.list(recursive: true);
  lister.listen((FileSystemEntity file) => files.add(file.path),
      // should also register onError
      onDone: () => completer.complete(files));
  return completer.future;
}

void main(List<String> arguments) async {
  final String buildCommandsPath = arguments[0];
  final String repoPath = arguments[1];
  final String checks =
      arguments.length >= 3 ? '--checks=${arguments[2]}' : '--config=';
  final List<String> changedFiles =
      Platform.environment['FLUTTER_LINT_ALL'] != null
          ? await dirContents(repoPath)
          : getListOfChangedFiles(repoPath);

  final List<dynamic> buildCommandMaps =
      jsonDecode(await File(buildCommandsPath).readAsString()) as List<dynamic>;
  final List<Command> buildCommands =
      buildCommandMaps.map((dynamic x) => parseCommand(x as Map<String, dynamic>)).toList();
  final Command firstCommand = buildCommands[0];
  final String tidyPath = calcTidyPath(firstCommand);
  final List<Command> changedFileBuildCommands =
      buildCommands.where((Command x) => containsAny(x.file, changedFiles)).toList();

  int exitCode = 0;
  //TODO(aaclarke): Coalesce this into one call using the `-p` argument.
  for (Command command in changedFileBuildCommands) {
    final String tidyArgs = calcTidyArgs(command);
    final List<String> args = <String>[command.file, checks, '--'];
    args.addAll(tidyArgs.split(' '));
    print('# linting ${command.file}');
    final Process process = await Process.start(tidyPath, args,
        workingDirectory: command.directory, runInShell: false);
    process.stdout.transform(utf8.decoder).listen((String data) {
      print(data);
      exitCode = 1;
    });
    await process.exitCode;
  }
  exit(exitCode);
}

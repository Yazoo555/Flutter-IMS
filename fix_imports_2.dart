import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    String content = file.readAsStringSync();
    String updated = content;

    List<String> pathParts = file.path.split('/');
    // Check if the file is at least 3 levels deep (e.g., lib/screens/auth/login_screen.dart -> length 4)
    if (pathParts.length >= 4) { 
      updated = updated.replaceAllMapped(RegExp(r"import\s+['""]([^'""]+)['""];"), (match) {
        String importPath = match.group(1)!;

        // Skip absolute imports
        if (importPath.startsWith('package:') || importPath.startsWith('dart:')) {
          return match.group(0)!;
        }

        // If the import path starts with `../` but NOT `../../`
        // We know we must fix any `../` that points to a root folder of `lib` (theme, widgets, utils, main.dart, models).
        if (importPath.startsWith('../') && !importPath.startsWith('../../')) {
          List<String> rootLibFolders = ['theme', 'models', 'widgets', 'utils', 'main.dart'];
          for (var root in rootLibFolders) {
            if (importPath.startsWith('../$root')) {
              // It needs one more `../` because the file was moved deeper
              // Example: '../theme/app_theme.dart' -> '../../theme/app_theme.dart'
              return "import '../$importPath';";
            }
          }
        }
        return match.group(0)!;
      });
    }

    if (content != updated) {
      file.writeAsStringSync(updated);
      print('Fixed relative roots in ${file.path}');
    }
  }
}

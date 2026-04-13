import 'dart:io';

void main() {
  var dir = Directory('lib');
  var files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  Map<String, String> moves = {
    'login_screen.dart': 'auth',
    'signup_screen.dart': 'auth',
    'forgot_password_screen.dart': 'auth',
    'otp_screen.dart': 'auth',
    'inventory_screen.dart': 'inventory',
    'item_detail_screen.dart': 'inventory',
    'add_edit_item_screen.dart': 'inventory',
    'stock_adjust_screen.dart': 'inventory',
    'inventory_widgets.dart': 'inventory',
    'inventory_models.dart': 'inventory',
    'categories_screen.dart': 'setup',
    'add_edit_category_screen.dart': 'setup',
    'units_screen.dart': 'setup',
    'add_unit_screen.dart': 'setup',
    'dashboard_screen.dart': 'dashboard',
    'home_screen.dart': 'dashboard',
    'logistics_screen.dart': 'logistics',
    'reports_screen.dart': 'reports',
  };

  for (var file in files) {
    String content = file.readAsStringSync();
    String updated = content;
    
    // Quick replace for main.dart imports
    for (var entry in moves.entries) {
      updated = updated.replaceAll("'screens/${entry.key}'", "'screens/${entry.value}/${entry.key}'");
      updated = updated.replaceAll('"screens/${entry.key}"', '"screens/${entry.value}/${entry.key}"');
    }
    
    // Replace relative imports across the app
    updated = updated.replaceAllMapped(RegExp(r"import\s+['""]([^'""]+)['""];"), (match) {
      String importPath = match.group(1)!;
      if (importPath.startsWith('package:') || importPath.startsWith('dart:')) {
        return match.group(0)!; 
      }
      
      String basename = importPath.split('/').last;
      if (moves.containsKey(basename)) {
        String targetFolder = moves[basename]!; 
        
        List<String> currentParts = file.path.split('/');
        int currentDepth = currentParts.length - 1; 
        
        String newImportPath;
        if (currentDepth == 1) { 
           newImportPath = 'screens/$targetFolder/$basename';
        } else if (currentDepth == 2) { 
           if (currentParts[1] == 'screens') {
             newImportPath = '$targetFolder/$basename';
           } else {
             newImportPath = '../screens/$targetFolder/$basename';
           }
        } else if (currentDepth == 3) { 
           String thisFolder = currentParts[2];
           if (thisFolder == targetFolder) {
             newImportPath = basename; 
           } else {
             newImportPath = '../$targetFolder/$basename';
           }
        } else if (currentDepth == 4) { 
           newImportPath = '../../$targetFolder/$basename';
        } else {
           newImportPath = importPath; 
        }
        return "import '$newImportPath';";
      }
      return match.group(0)!;
    });

    if (content != updated) {
      file.writeAsStringSync(updated);
      print('Updated imports in ${file.path}');
    }
  }
}

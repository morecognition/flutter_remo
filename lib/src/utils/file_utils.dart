import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileUtils {
  static const String androidDownloadPath = '/storage/emulated/0/Downloads/';
  static const String androidAlternativeDownloadPath = '/storage/emulated/0/Download/';
  static const String remorderFolderName = 'remorder';

  static Future<Directory?> getDownloadDirectory() async{
    Directory? result;

    if (Platform.isAndroid) {
      if(await Directory(androidDownloadPath).exists()) {
        result = Directory('$androidDownloadPath/$remorderFolderName');
      } else {
        result = Directory('$androidAlternativeDownloadPath/$remorderFolderName');
      }
        
      if(!await result.exists()) {
        await result.create();
      }
    } else if (Platform.isIOS) {
      result = await getApplicationDocumentsDirectory();
    }

    return result;
  }
}

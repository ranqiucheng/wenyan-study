import "dart:io";

class SaveDialog {
  SaveDialog._();

  static Future<String?> pickSavePath({
    required String suggestedName,
    String filter = "内容包 (*.wyc)|*.wyc|所有文件 (*.*)|*.*",
    String title = "保存内容包",
  }) async {
    if (!Platform.isWindows) {
      return null;
    }
    final script = """
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.SaveFileDialog
\$dialog.Filter = '$filter'
\$dialog.FileName = '$suggestedName'
\$dialog.Title = '$title'
\$dialog.OverwritePrompt = \$true
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dialog.FileName
}
""";
    try {
      final result = await Process.run(
        "powershell.exe",
        ["-NoProfile", "-STA", "-WindowStyle", "Hidden", "-Command", script],
      );
      final path = (result.stdout as String).trim();
      return path.isEmpty ? null : path;
    } catch (_) {
      return null;
    }
  }
}

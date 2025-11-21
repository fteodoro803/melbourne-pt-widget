import 'dart:io';

void main() {
  print('Local Development Environment Setup');
  print('Creates a .env file, and modifies secrets.properties and AppDelegate.swift');
  print('-' * 35);

  final envVars = {
    'PTV_USER_ID': {
      'description': 'PTV User ID',
      'required': true,
    },
    'PTV_API_KEY': {
      'description': 'PTV API Key',
      'required': true,
    },
    'GOOGLE_API_KEY': {
      'description': 'Google API Key',
      'required': true,
    },
    'GTFS_API_KEY': {
      'description': 'GTFS API Key',
      'required': true,
    },
  };

  final buffer = StringBuffer();
  buffer.writeln('# Generated .env file for local development');
  buffer.writeln('# Never commit this file to Git');
  buffer.writeln('# Created by setup_env.dart\n');

  for (var entry in envVars.entries) {
    final name = entry.key;
    final description = entry.value['description'] as String;
    final required = entry.value['required'] as bool? ?? false;

    stdout.write('$description: ');
    final value = stdin.readLineSync()?.trim();

    if (required && (value == null || value.isEmpty)) {
      print('$description is required! Run setup_env again');
      return;
    }

    if (value != null && value.isNotEmpty) {
      buffer.writeln('$name=$value');

      if (name == "GOOGLE_API_KEY") {
        addGoogleApiKey(value);
      }
    }
  }

  final envFile = File('.env');

  if (envFile.existsSync()) {
    stdout.write('\n.env already exists. Overwrite? (y/N): ');
    final response = stdin.readLineSync()?.toLowerCase();
    if (response != 'y') {
      print('Aborted.');
      return;
    }
  }

  envFile.writeAsStringSync(buffer.toString());
  print('\nCreated .env');
  print('Remember: Never commit this file to Git!');
}

void addGoogleApiKey(String value) {
  // 1. Open the files and check if they exist
  final secretsFile = File("android/secrets.properties");
  final appDelegatesFile = File("ios/Runner/AppDelegate.swift");

  if (!secretsFile.existsSync() || !appDelegatesFile.existsSync()) {
    print("$secretsFile or $appDelegatesFile doesn't exist");
    return;
  }

  // 2. Read the file contents
  var secretsContent = secretsFile.readAsStringSync();
  var appDelegatesContent = appDelegatesFile.readAsStringSync();

  // 3. Regex patterns
  final secretsRegex = RegExp(r'MAPS_API_KEY="[^"]*"');
  final appDelegateRegex = RegExp(r'GMSServices\.provideAPIKey\("([^"]*)"\)');

  // 4. Replace values
  secretsContent = secretsContent.replaceAll(
    secretsRegex,
    'MAPS_API_KEY="$value"',
  );

  appDelegatesContent = appDelegatesContent.replaceAll(
    appDelegateRegex,
    'GMSServices.provideAPIKey("$value")',
  );

  // 5. Save files
  secretsFile.writeAsStringSync(secretsContent);
  appDelegatesFile.writeAsStringSync(appDelegatesContent);

  print("Updated secrets.properties and AppDelegate.swift with Google API key.");
}
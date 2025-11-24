import 'dart:io';

Future<void> main() async {
  print('Local Development Environment Setup');
  print('Creates a .env file, and modifies secrets.properties and AppDelegate.swift');
  print('----------------------------------------------------------------------');

  stdout.write(
      '1. Run full setup'
      '\n2. Add environment variables (ex. API Keys)'
      '\n3. Modify Git tracking of sensitive files (ie. where API Keys are stored)'
      '\n4. Exit'
      '\nEnter number of what you want to do: ');

  final response = stdin.readLineSync()?.toLowerCase();
  stdout.write('\n');   // empty line
  if (response == '1') {
    await setup();
  }
  else if (response == '2') {
    createEnvPrompts();
  }
  else if (response == '3') {
    trackingPrompts();
  }
  else if (response == '4') {
    return;
  }

  return;
}

Future<void> setup() async {
  createEnvPrompts();
  stdout.write('----------------------------------------------------------------------\n');   // empty line
  await trackingPrompts();
}

Future<void> trackingPrompts() async {
  // 1. Prompt to ignore git tracking for local development
  stdout.write('Ignore git tracking to files containing inputted sensitive data? (Default is yes) (y/n): ');
  final response = stdin.readLineSync()?.toLowerCase();
  if (response == 'n') {
    await ignoreLocalChanges(enabled: false);
  }
  else {
    await ignoreLocalChanges(enabled: true);
  }
}

void createEnvPrompts() {
  // 1. List of variables that can be added to .env
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

  // 2. Prompt the addition of each variable
  String googleApiKey = "";
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
        googleApiKey = value;
      }
    }
  }

  final envFile = File('.env');

  // 3. Overwrite prompt if a previous .env file exists
  if (envFile.existsSync()) {
    stdout.write('\n.env already exists. Overwrite? (Default is yes) (y/n): ');
    final response = stdin.readLineSync()?.toLowerCase();
    if (response == 'n') {
      print('\tAborted.');
      return;
    }

    // Add Google API Key if it exists
    if (googleApiKey.isNotEmpty) {
      addGoogleApiKey(googleApiKey);
    }
  }

  envFile.writeAsStringSync(buffer.toString());
  print('Created .env');
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

  // print("\tUpdated secrets.properties and AppDelegate.swift with Google API key.");
}

/// Ignores git tracking of files containing details like API keys to prevent them from being committed.
Future<void> ignoreLocalChanges({required bool enabled}) async {
  List<String> args;
  if (enabled == true) {
    args = [
      'update-index',
      '--assume-unchanged',
      'assets/cfg/config.json',
      'android/secrets.properties',
      'ios/Runner/AppDelegate.swift',
    ];
  }
  else {
    args = [
      'update-index',
      '--no-assume-unchanged',
      'assets/cfg/config.json',
      'android/secrets.properties',
      'ios/Runner/AppDelegate.swift',
    ];
  }

  String changed = enabled == true ? "" : "no-";
  print('Running "git update-index --${changed}assume-unchanged" on\n'
      '\t1. assets/cfg/config.json'
      '\t2. android/secrets.properties'
      '\t3. ios/Runner/AppDelegate.swift');

  final result = await Process.run('git', args);

  if (result.exitCode != 0) {
    print('\tGit error: ${result.stderr}');
  }
}
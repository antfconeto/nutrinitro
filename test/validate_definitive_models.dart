import 'dart:convert';
import 'dart:io';
import 'package:nutrinitro/src/data/models/analysis/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/model_runners.dart';

void main() async {
  print('================================================================');
  print('VALIDATING DART SPAD PREDICTION PARITY AGAINST PYTHON RESEARCH');
  print('================================================================');

  final recipeFile = File('assets/recipes/marandu_nutrients_v1.json');
  if (!await recipeFile.exists()) {
    print('Erro: receita marandu_nutrients_v1.json não encontrada.');
    return;
  }
  final recipeJson = json.decode(await recipeFile.readAsString()) as Map<String, dynamic>;
  final recipe = AnalysisRecipe.fromJson(recipeJson);
  final chlorophyllModel = recipe.predictions.firstWhere((p) => p.target == 'chlorophyll');
  const mlpRunner = MlpModelRunner();

  // Load extracted_indices_10x10.csv
  final File featuresFile = File('tcc/data/output/images-infos/extracted_indices_10x10.csv');
  if (!await featuresFile.exists()) {
    print('Erro: arquivo extracted_indices_10x10.csv não encontrado.');
    return;
  }

  // Load global_model_predictions.csv
  final File predictionsFile = File('tcc/data/output/images-infos/global_model_predictions.csv');
  if (!await predictionsFile.exists()) {
    print('Erro: arquivo global_model_predictions.csv não encontrado.');
    return;
  }

  final List<String> featuresLines = await featuresFile.readAsLines();
  final List<String> predictionsLines = await predictionsFile.readAsLines();

  // Parse predictions file into a lookup map by Date and Ponto
  // Key: "date_ponto" -> Map with 'mlp' and 'si'
  final Map<String, Map<String, double>> predLookup = {};
  for (int i = 1; i < predictionsLines.length; i++) {
    final String line = predictionsLines[i].trim();
    if (line.isEmpty) continue;
    final List<String> parts = line.split(',');
    if (parts.length < 4) continue;

    final String date = parts[0];
    final double ponto = double.parse(parts[1]);
    final double mlpPred = double.parse(parts[2]);
    final double siPred = double.parse(parts[3]);

    final String key = '${date}_${ponto.toInt()}';
    predLookup[key] = {
      'mlp': mlpPred,
      'si': siPred,
    };
  }

  print('Loaded ${predLookup.length} prediction rows from Python outputs.');

  int totalTested = 0;
  double mlpMaxDiff = 0.0;

  print('\n-------------------------------------------------------------------------------------');
  print('Data       | Pt | Python MLP | Dart MLP  | Diff MLP  | Status');
  print('-------------------------------------------------------------------------------------');

  for (int i = 1; i < featuresLines.length; i++) {
    final String line = featuresLines[i].trim();
    if (line.isEmpty) continue;
    final List<String> parts = line.split(',');

    final double pontoVal = double.parse(parts[0]);
    final int ponto = pontoVal.toInt();
    final String date = parts[4];
    
    final String lookupKey = '${date}_$ponto';
    final Map<String, double>? pyPreds = predLookup[lookupKey];
    if (pyPreds == null) {
      print('Aviso: predição Python não encontrada para $lookupKey');
      continue;
    }

    // Extract the 28 features in the correct order for the MLP model
    // 7 coordinates: r, g, b, rg, rb, gb, rgb
    final List<double> medians = [
      double.parse(parts[10]), // r
      double.parse(parts[14]), // g
      double.parse(parts[18]), // b
      double.parse(parts[22]), // rg
      double.parse(parts[26]), // rb
      double.parse(parts[30]), // gb
      double.parse(parts[34]), // rgb
    ];

    final List<double> means = [
      double.parse(parts[11]), // r
      double.parse(parts[15]), // g
      double.parse(parts[19]), // b
      double.parse(parts[23]), // rg
      double.parse(parts[27]), // rb
      double.parse(parts[31]), // gb
      double.parse(parts[35]), // rgb
    ];

    final List<double> p75s = [
      double.parse(parts[12]), // r
      double.parse(parts[16]), // g
      double.parse(parts[20]), // b
      double.parse(parts[24]), // rg
      double.parse(parts[28]), // rb
      double.parse(parts[32]), // gb
      double.parse(parts[36]), // rgb
    ];

    final List<double> p90s = [
      double.parse(parts[13]), // r
      double.parse(parts[17]), // g
      double.parse(parts[21]), // b
      double.parse(parts[25]), // rg
      double.parse(parts[29]), // rb
      double.parse(parts[33]), // gb
      double.parse(parts[37]), // rgb
    ];

    final List<double> mlpInputs = [
      ...medians,
      ...means,
      ...p75s,
      ...p90s,
    ];

    // Compute predictions using Dart implementation
    final double dartMlp = mlpRunner.predict(mlpInputs, chlorophyllModel.parameters);

    final double pyMlp = pyPreds['mlp']!;

    final double mlpDiff = (dartMlp - pyMlp).abs();

    if (mlpDiff > mlpMaxDiff) mlpMaxDiff = mlpDiff;

    final bool success = mlpDiff < 1e-4;

    print(
      '${date.padRight(10)} | '
      '${ponto.toString().padRight(2)} | '
      '${pyMlp.toStringAsFixed(4).padRight(10)} | '
      '${dartMlp.toStringAsFixed(4).padRight(9)} | '
      '${mlpDiff.toStringAsExponential(2).padRight(9)} | '
      '${success ? 'OK' : 'FALHA'}'
    );

    totalTested++;
  }

  print('-------------------------------------------------------------------------------------');
  print('Total de amostras validadas: $totalTested');
  print('Diferença máxima MLP: ${mlpMaxDiff.toStringAsExponential(4)}');

  if (mlpMaxDiff < 1e-4) {
    print('\n🎉 SUCESSO! A paridade de predição Dart-Python é absoluta (tolerância < 0.0001 SPAD).');
  } else {
    print('\n❌ FALHA! Algumas predições divergiram além do limite aceitável.');
    exit(1);
  }
}

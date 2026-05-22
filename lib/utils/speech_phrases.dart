import 'package:momento_booth/models/app_action_example.dart';

const List<String> cancelPhrases = [
  "cancel",
  "stop",
  "abort",
  "never mind",
  "forget it",
  "close",
  "dismiss",
  "exit",
];

List<AppActionExample> get cancelPhrasesExamples => cancelPhrases.map((phrase) => AppActionExample(phrase: phrase)).toList();

const List<String> continuePhrases = [
  "continue",
  "next",
  "go on",
  "proceed",
  "keep going",
  "done",
  "finished"
];

List<AppActionExample> get continuePhrasesExamples => continuePhrases.map((phrase) => AppActionExample(phrase: phrase)).toList();

const List<String> backPhrases = [
  "back",
  "previous",
  "go back",
  "return",
  "previous screen"
];

List<AppActionExample> get backPhrasesExamples => backPhrases.map((phrase) => AppActionExample(phrase: phrase)).toList();

const List<String> confirmPhrases = [
  "yes",
  "confirm",
  "that's right",
  "correct",
  "yep",
  "do it",
];

List<AppActionExample> get confirmPhrasesExamples => confirmPhrases.map((phrase) => AppActionExample(phrase: phrase)).toList();

const List<String> getQRPhrases = [
  "get qr code",
  "show qr code",
  "generate qr code",
  "share photo"
];

List<AppActionExample> get getQRPhrasesExamples => getQRPhrases.map((phrase) => AppActionExample(phrase: phrase)).toList();

const List<String> printPhrases = [
  "print",
  "print it",
  "print photo",
  "print picture",
  "i want a print",
  "i want to print",
  "let's print"
];

List<AppActionExample> get printPhrasesExamples => printPhrases.map((phrase) => AppActionExample(phrase: phrase)).toList();

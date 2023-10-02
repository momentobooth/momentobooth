import 'dart:math';

String getRandomString({int length = 6, String possibleChars = 'abcdefghijklmnopqrstuvwxyz0123456789'}) {
  var random = Random();
  return List.generate(length, (index) => possibleChars[random.nextInt(possibleChars.length)]).join();
}

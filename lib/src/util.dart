import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<String> readLine() async {
  final c = Completer<String>(); // completer
  final l = stdin // stdin
      .transform(utf8.decoder) // decode
      .transform(const LineSplitter()) // split line
      .asBroadcastStream() // make it stream
      .listen((line) => !c.isCompleted ? c.complete(line) : 0); // listen

  final o = await c.future; // get output from future
  l.cancel(); // cancel stream after future is completed
  return o;
}

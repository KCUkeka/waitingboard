import 'package:mysql1/mysql1.dart';

class Mysql {
  static String host = 'roxb-ecwtest',
      user = 'DBKCUkeka',
      password = 'Welcome5875!',
      db = 'mobiledoc';
  static int port = 4928;

  Future<MySqlConnection> getConnection() async {
    var settings = new ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: db,
    );
    return await MySqlConnection.connect(settings);
  }
}

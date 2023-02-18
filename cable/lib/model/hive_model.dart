import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';


@HiveType()
class UserData extends HiveObject{
  @HiveField(0)
  var users;
}
class UserDataAdapter extends TypeAdapter<UserData>{
  @override
  UserData read(BinaryReader reader) {
    return UserData()..users;
  }

  @override
  final typeId= 0;

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer.write(obj.users);
  }

}

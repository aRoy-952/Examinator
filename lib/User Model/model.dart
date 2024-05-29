class UserModel {
  String? email;
  String? roleOfUser;
  String? uid;
  String? name;
  String? regNo;

  // receiving data
  UserModel({this.uid, this.email, this.roleOfUser, this.name, this.regNo});
  factory UserModel.fromMap(map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
      roleOfUser: map['roleOfUser'],
      regNo: map['regNo'],
    );
  }
  // sending data
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'roleOfUser': roleOfUser,
      'name': name,
      'regNo': regNo,
    };
  }
}

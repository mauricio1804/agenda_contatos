String idColumn = 'idColumn';
String nameColumn = 'nameColumn';
String emailColumn = 'emailColumn';
String phoneColumn = 'phoneColumn';
String imgColumn = 'imgColumn';
String contactTable = 'contactTable';

class Contact{
  int? id;
  String? name;
  String? email;
  String? phone;
  String? img;

  Contact({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.img
  });

  Contact.fromMap(Map <String, dynamic> map) : 
    id = map[idColumn],
    name = map[nameColumn],
    email = map[emailColumn],
    phone = map[phoneColumn],
    img = map[imgColumn];

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      nameColumn: name,
      emailColumn: email,
      phoneColumn: phone,
      imgColumn: img
    };
    if (id != null) {
      map[idColumn] = id;
    }
    return map;
  }

  @override
  String toString() {
    return "Contact(id: $id, name: $name, email: $email, phone: $phone, img: $img)";
  }
}
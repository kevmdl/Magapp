class ClientModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final int chatId;

  ClientModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.chatId,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['idusuarios'],
      name: json['nome'],
      email: json['email'],
      phone: json['telefone'],
      chatId: json['chat_id'],
    );
  }
}
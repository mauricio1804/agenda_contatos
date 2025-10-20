import 'dart:io';
import 'dart:convert';

import 'package:appcontatos/database/helper/contact_helper.dart';
import 'package:appcontatos/database/model/contact_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;

class ContactPage extends StatefulWidget {
  final Contact? contact;

  const ContactPage({Key? key, this.contact}) : super(key: key);

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  Contact? _editContact;
  bool _userEdited = false;
  bool _isValidatingEmail = false;
  String? _emailError;
  String? _phoneError;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imgController = TextEditingController();
  final ContactHelper _helper = ContactHelper();
  final ImagePicker _picker = ImagePicker();
  final phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final String _token = "21595|k9M1AWXJht19PRy9xPwJmOQqhh24KYCi";

  Future<void> Function()? _debounce;

  Future<void> _validateEmail(String email) async {
    if (email.isEmpty) {
      setState(() {
        _emailError = null;
        _isValidatingEmail = false;
      });
      return;
    }
    _debounce?.call();
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isValidatingEmail = true;
      _emailError = null;
    });

    try {
      print('Validando email: $email');
      final response = await http.get(
        Uri.parse(
          'https://api.invertexto.com/v1/email-validator/$email?token=$_token',
        ),
      );

      print('Status code: ${response.statusCode}');
      print('Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('Resultado da API: $result');
        setState(() {
          _isValidatingEmail = false;

          bool validFormat = result['valid_format'] == true;
          bool validMx = result['valid_mx'] == true;
          bool isDisposable = result['disposable'] == true;

          if (!validFormat) {
            _emailError = 'Formato de email inválido';
          } else if (!validMx) {
            _emailError = 'Domínio do email inválido';
          } else if (isDisposable) {
            _emailError = 'Email temporário não permitido';
          } else {
            _emailError = null;
          }
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isValidatingEmail = false;
          _emailError = 'Erro de autenticação com a API';
        });
      } else {
        setState(() {
          _isValidatingEmail = false;
          _emailError = 'Erro ao validar email: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Erro na validação: $e');
      setState(() {
        _isValidatingEmail = false;
        _emailError = 'Erro ao validar email: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.contact == null) {
      _editContact = Contact(name: "", email: "", phone: "", img: "");
    } else {
      _editContact = widget.contact;
      _nameController.text = _editContact?.name ?? "";
      _emailController.text = _editContact?.email ?? "";
      _phoneController.text = _editContact?.phone ?? "";
      _imgController.text = _editContact?.img ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(_editContact?.name ?? "Novo Contato"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveContact();
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.save),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: () => _selectImage(),
              child: Container(
                width: 140.0,
                height: 140.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image:
                        _editContact?.img != null &&
                            _editContact!.img!.isNotEmpty
                        ? FileImage(File(_editContact!.img!))
                        : AssetImage("assets/imgs/avatar.png") as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nome"),
              onChanged: (text) {
                _userEdited = true;
                setState(() {
                  _editContact?.name = text;
                });
              },
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                errorText: _emailError,
                helperText: _isValidatingEmail ? "Validando..." : null,
                suffixIcon: _isValidatingEmail
                    ? Container(
                        width: 20,
                        height: 20,
                        margin: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _emailError == null && _emailController.text.isNotEmpty
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (text) {
                _userEdited = true;
                setState(() {
                  _editContact?.email = text;
                });
                if (text.isNotEmpty) {
                  _validateEmail(text);
                }
              },
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Telefone",
                errorText: _phoneError,
                helperText: "(##) #####-####",
                suffixIcon: _phoneController.text.isNotEmpty
                    ? Icon(
                        _phoneError == null ? Icons.check_circle : Icons.error,
                        color: _phoneError == null ? Colors.green : Colors.red,
                      )
                    : null,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneMask],
              onChanged: (text) {
                _userEdited = true;
                setState(() {
                  _editContact?.phone = text;
                  String digitsOnly = text.replaceAll(RegExp(r'\D'), '');
                  if (text.isEmpty) {
                    _phoneError = null;
                  } else if (digitsOnly.length < 11) {
                    _phoneError = 'Número incompleto';
                  } else if (digitsOnly.length > 11) {
                    _phoneError = 'Número muito longo';
                  } else {
                    _phoneError = null;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _editContact?.img = image.path;
      });
    }
  }

  void _saveContact() async {
    if (_editContact?.img == "") {
      _editContact?.img = null;
    }

    if (_emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, corrija o email antes de salvar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor, corrija o número de telefone antes de salvar',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_editContact?.name != null && _editContact!.name!.isNotEmpty) {
      if (_editContact?.id != null) {
        await _helper.updateContact(_editContact!);
      } else {
        await _helper.saveContact(_editContact!);
      }

      Navigator.pop(context, _editContact);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Nome é Obrigatório")));
    }
  }
}

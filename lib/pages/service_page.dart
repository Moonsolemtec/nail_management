import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nail_management/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const double _radius = 12;
  static const double _gap = 12;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addOrEditService({DocumentSnapshot? service}) async {
    final formKey = GlobalKey<FormState>();
    String? name = service?["name"];
    String? price = service?["price"]?.toString();
    String? duration = service?["duration"]?.toString();
    String? selectedAgent = service?["agentId"];

    final agentsSnapshot = await _db.collection("agents").get();
    final agents = agentsSnapshot.docs;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service == null ? "Novo Serviço" : "Editar Serviço",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: _gap),
                    _buildFilledTextField(
                      initialText: name,
                      label: "Nome",
                      icon: Icons.content_cut,
                      onSaved: (v) => name = v,
                      validator: (v) => v == null || v.isEmpty ? "Informe o nome" : null,
                    ),
                    const SizedBox(height: _gap),
                    _buildFilledTextField(
                      initialText: price,
                      label: "Preço (R\$)",
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      onSaved: (v) => price = v,
                      validator: (v) => v == null || v.isEmpty ? "Informe o preço" : null,
                    ),
                    const SizedBox(height: _gap),
                    _buildFilledTextField(
                      initialText: duration,
                      label: "Tempo (min)",
                      icon: Icons.timer,
                      keyboardType: TextInputType.number,
                      onSaved: (v) => duration = v,
                      validator: (v) => v == null || v.isEmpty ? "Informe o tempo" : null,
                    ),
                    const SizedBox(height: _gap),
                    DropdownButtonFormField<String>(
                      value: agents.any((a) => a.id == selectedAgent) ? selectedAgent : null,
                      decoration: InputDecoration(
                        labelText: "Agente",
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_radius),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: agents
                          .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a["name"] ?? ""),
                              ))
                          .toList(),
                      onChanged: (v) => selectedAgent = v,
                      validator: (v) => v == null ? "Selecione um agente" : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text("Cancelar"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_radius),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              final data = {
                                "name": name,
                                "price": double.tryParse(price ?? "0"),
                                "duration": int.tryParse(duration ?? "0"),
                                "agentId": selectedAgent,
                                "updatedAt": FieldValue.serverTimestamp(),
                              };
                              if (service == null) {
                                await _db.collection("services").add(data);
                              } else {
                                await _db.collection("services").doc(service.id).update(data);
                              }
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text("Salvar"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_radius),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addOrEditAgent({DocumentSnapshot? agent}) async {
    final formKey = GlobalKey<FormState>();
    String? name = agent?["name"];
    String? surname = agent?["surname"];
    String? phone = agent?["phone"];
    String? email = agent?["email"];
    String? imagePath = agent?["imagePath"];

    File? agentImage = imagePath != null ? File(imagePath) : null;

    Future<void> _pickImage(StateSetter setModalState) async {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        final File imageFile = File(pickedImage.path);
        final directory = await getApplicationDocumentsDirectory();
        final String path =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
        final File localImage = await imageFile.copy(path);
        agentImage = localImage;
        setModalState(() {});
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          agent == null ? "Novo Agente" : "Editar Agente",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: _gap),
                        GestureDetector(
                          onTap: () => _pickImage(setModalState),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_radius),
                              color: Colors.grey[100],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: agentImage != null
                                ? Image.file(agentImage!, fit: BoxFit.cover)
                                : (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync())
                                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                                    : Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.camera_alt, size: 32, color: Colors.grey[600]),
                                            const SizedBox(height: 8),
                                            Text("Adicionar foto do agente", style: TextStyle(color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: _gap),
                        _buildFilledTextField(
                          initialText: name,
                          label: "Nome",
                          icon: Icons.person,
                          onSaved: (v) => name = v,
                          validator: (v) => v == null || v.isEmpty ? "Informe o nome" : null,
                        ),
                        const SizedBox(height: _gap),
                        _buildFilledTextField(
                          initialText: surname,
                          label: "Sobrenome",
                          icon: Icons.person_outline,
                          onSaved: (v) => surname = v,
                        ),
                        const SizedBox(height: _gap),
                        _buildFilledTextField(
                          initialText: phone,
                          label: "Telefone",
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          onSaved: (v) => phone = v,
                        ),
                        const SizedBox(height: _gap),
                        _buildFilledTextField(
                          initialText: email,
                          label: "Email",
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (v) => email = v,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text("Cancelar"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(_radius),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  final data = {
                                    "name": name,
                                    "surname": surname,
                                    "phone": phone,
                                    "email": email,
                                    "imagePath": agentImage?.path ?? imagePath,
                                    "updatedAt": FieldValue.serverTimestamp(),
                                  };
                                  if (agent == null) {
                                    await _db.collection("agents").add(data);
                                  } else {
                                    await _db.collection("agents").doc(agent.id).update(data);
                                  }
                                  await _reloadAgents();
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.save),
                              label: const Text("Salvar"),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(_radius),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showListDialog(String title, String collection, VoidCallback onAdd, Function(DocumentSnapshot) onEdit) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return StreamBuilder<QuerySnapshot>(
              stream: _db.collection(collection).orderBy("name").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Erro ao carregar dados."));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: docs.isEmpty
                            ? const Center(child: Text("Nenhum item cadastrado."))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => const Divider(height: 8),
                                itemBuilder: (_, i) {
                                  final item = docs[i];
                                  final titleText = (item.data() as Map<String, dynamic>)["name"] ?? "";
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            onEdit(item);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteItem(collection, item.id),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text("Fechar"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(_radius),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onAdd();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Novo"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(_radius),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _setInterval() async {
    final doc = await _db.collection("settings").doc("schedule").get();
    int? minutes = doc.exists ? doc["interval"] : null;
    final controller = TextEditingController(text: minutes?.toString() ?? "");

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Intervalo Entre Agendamentos",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Minutos",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.timer),
                    ),
                    onChanged: (v) => minutes = int.tryParse(v),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text("Cancelar"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (minutes != null && minutes! > 0) {
                            await _db.collection("settings").doc("schedule").set({"interval": minutes});
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text("Salvar"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteItem(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
    if (collection == "agents") await _reloadAgents();
  }

  Widget _buildMenuItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildFilledTextField({
    String? initialText,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      initialValue: initialText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Future<void> _reloadAgents() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          StreamBuilder<DocumentSnapshot>(
            stream: _db.collection("salons").doc("my_salon").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                );
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final imagePath = data["imagePath"] as String?;
              final nomeSalao = data["name"] ?? "Meu Salão";
              ImageProvider? imageProvider;
              if (imagePath != null && imagePath.isNotEmpty) {
                final file = File(imagePath);
                if (file.existsSync()) imageProvider = FileImage(file);
              }
              return Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: imageProvider,
                    backgroundColor: AppTheme.primary,
                    child: imageProvider == null ? const Icon(Icons.store, size: 40, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 10),
                  Text(nomeSalao, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.content_cut,
                  text: "Serviços",
                  onTap: () => _showListDialog("Serviços", "services", () => _addOrEditService(), (doc) => _addOrEditService(service: doc)),
                ),
                const Divider(height: 5),
                _buildMenuItem(
                  icon: Icons.star_border,
                  text: "Agentes",
                  onTap: () => _showListDialog("Agentes", "agents", () => _addOrEditAgent(), (doc) => _addOrEditAgent(agent: doc)),
                ),
                const Divider(height: 5),
                _buildMenuItem(
                  icon: Icons.schedule,
                  text: "Horários",
                  onTap: _setInterval,
                ),
                const Divider(height: 5),
                _buildMenuItem(
                  icon: Icons.home_work,
                  text: "Salão",
                  onTap: () => _registerSalon(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerSalon(BuildContext context) async {
    final doc = await _db.collection("salons").doc("my_salon").get();
    String? address = doc.exists ? doc["address"] : null;
    String? cnpj = doc.exists ? doc["cnpj"] : null;
    String? hours = doc.exists ? doc["hours"] : null;
    String? name = doc.exists ? doc["name"] : null;
    String? phone = doc.exists ? doc["phone"] : null;
    final TextEditingController nameController = TextEditingController(text: name ?? "");
    final TextEditingController cnpjController = TextEditingController(text: cnpj ?? "");
    final TextEditingController addressController = TextEditingController(text: address ?? "");
    final TextEditingController phoneController = TextEditingController(text: phone ?? "");
    final TextEditingController hoursController = TextEditingController(text: hours ?? "");

    File? salonImage;
    String? existingImage = doc.exists ? doc["imagePath"] : null;

    Future<void> _pickImage(StateSetter setModalState) async {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        final File imageFile = File(pickedImage.path);
        final directory = await getApplicationDocumentsDirectory();
        final String path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
        final File localImage = await imageFile.copy(path);
        salonImage = localImage;
        setModalState(() {});
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Cadastro de Salão", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(labelText: "Nome do salão", prefixIcon: const Icon(Icons.store), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: cnpjController,
                          decoration: InputDecoration(labelText: "CNPJ", prefixIcon: const Icon(Icons.badge), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: addressController,
                          decoration: InputDecoration(labelText: "Endereço", prefixIcon: const Icon(Icons.location_on), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: "Telefone", prefixIcon: const Icon(Icons.phone), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: hoursController,
                          decoration: InputDecoration(labelText: "Horário de funcionamento", prefixIcon: const Icon(Icons.access_time), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(_radius), borderSide: BorderSide.none)),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _pickImage(setModalState),
                          child: Stack(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: salonImage != null
                                    ? ClipRRect(key: ValueKey(salonImage!.path), borderRadius: BorderRadius.circular(16), child: Image.file(salonImage!, fit: BoxFit.cover, height: 200, width: double.infinity))
                                    : (existingImage != null && existingImage.isNotEmpty && File(existingImage).existsSync())
                                        ? ClipRRect(key: ValueKey(existingImage), borderRadius: BorderRadius.circular(16), child: Image.file(File(existingImage), fit: BoxFit.cover, height: 200, width: double.infinity))
                                        : Container(key: const ValueKey("placeholder"), height: 200, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[200]), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.camera_alt, size: 28, color: Colors.grey[600]), const SizedBox(height: 8), Text("Clique para adicionar uma imagem", style: TextStyle(color: Colors.grey[600]))]))),
                              ),
                              Positioned(bottom: 10, right: 10, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.85), borderRadius: BorderRadius.circular(50)), child: const Icon(Icons.edit, color: Colors.white, size: 20))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), label: const Text("Cancelar"), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)))),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final salonData = {
                                  "name": nameController.text,
                                  "cnpj": cnpjController.text,
                                  "address": addressController.text,
                                  "phone": phoneController.text,
                                  "hours": hoursController.text,
                                  "imagePath": salonImage?.path ?? existingImage,
                                  "updatedAt": FieldValue.serverTimestamp(),
                                };
                                await _db.collection("salons").doc("my_salon").set(salonData);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.save),
                              label: const Text("Salvar"),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
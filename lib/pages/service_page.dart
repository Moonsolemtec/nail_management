import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ------------------------------
  // FORM DE SERVIÇOS
  // ------------------------------
  Future<void> _addOrEditService({DocumentSnapshot? service}) async {
    final formKey = GlobalKey<FormState>();
    String? name = service?["name"];
    String? price = service?["price"].toString();
    String? duration = service?["duration"].toString();
    String? selectedAgent = service?["agentId"];

    final agentsSnapshot = await _db.collection("agents").get();
    final agents = agentsSnapshot.docs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(service == null ? "Novo Serviço" : "Editar Serviço",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(labelText: "Nome"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Informe o nome" : null,
                      onSaved: (v) => name = v,
                    ),
                    TextFormField(
                      initialValue: price,
                      decoration: const InputDecoration(labelText: "Preço (R\$)"),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Informe o preço" : null,
                      onSaved: (v) => price = v,
                    ),
                    TextFormField(
                      initialValue: duration,
                      decoration: const InputDecoration(labelText: "Tempo (min)"),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Informe o tempo" : null,
                      onSaved: (v) => duration = v,
                    ),
                    DropdownButtonFormField<String>(
                      value: agents.any((a) => a.id == selectedAgent)
                          ? selectedAgent
                          : null,
                      decoration: const InputDecoration(labelText: "Agente"),
                      items: agents
                          .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a["name"]),
                              ))
                          .toList(),
                      onChanged: (v) => selectedAgent = v,
                      validator: (v) =>
                          v == null ? "Selecione um agente" : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              final data = {
                                "name": name,
                                "price": double.tryParse(price ?? "0"),
                                "duration": int.tryParse(duration ?? "0"),
                                "agentId": selectedAgent,
                              };
                              if (service == null) {
                                await _db.collection("services").add(data);
                              } else {
                                await _db
                                    .collection("services")
                                    .doc(service.id)
                                    .update(data);
                              }
                              Navigator.pop(context);
                              _showListDialog("Serviços", "services",
                                  () => _addOrEditService(),
                                  (doc) => _addOrEditService(service: doc));
                            }
                          },
                          child: const Text("Salvar"),
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

  // ------------------------------
  // FORM DE AGENTES
  // ------------------------------
  Future<void> _addOrEditAgent({DocumentSnapshot? agent}) async {
    final formKey = GlobalKey<FormState>();
    String? name = agent?["name"];
    List<String> shifts = List<String>.from(agent?["shifts"] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(agent == null ? "Novo Agente" : "Editar Agente",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(labelText: "Nome"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Informe o nome" : null,
                      onSaved: (v) => name = v,
                    ),
                    CheckboxListTile(
                      title: const Text("Matutino"),
                      value: shifts.contains("Matutino"),
                      onChanged: (v) {
                        v == true
                            ? shifts.add("Matutino")
                            : shifts.remove("Matutino");
                        setState(() {});
                      },
                    ),
                    CheckboxListTile(
                      title: const Text("Noturno"),
                      value: shifts.contains("Noturno"),
                      onChanged: (v) {
                        v == true
                            ? shifts.add("Noturno")
                            : shifts.remove("Noturno");
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              final data = {"name": name, "shifts": shifts};
                              if (agent == null) {
                                await _db.collection("agents").add(data);
                              } else {
                                await _db
                                    .collection("agents")
                                    .doc(agent.id)
                                    .update(data);
                              }
                              Navigator.pop(context);
                              _showListDialog("Agentes", "agents",
                                  () => _addOrEditAgent(),
                                  (doc) => _addOrEditAgent(agent: doc));
                            }
                          },
                          child: const Text("Salvar"),
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

  // ------------------------------
  // LISTAGEM
  // ------------------------------
  void _showListDialog(String title, String collection, VoidCallback onAdd,
      Function(DocumentSnapshot) onEdit) {
    showModalBottomSheet(
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
              stream: _db.collection(collection).snapshots(),
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
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Expanded(
                        child: docs.isEmpty
                            ? const Center(
                                child: Text("Nenhum item cadastrado."))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: docs.length,
                                itemBuilder: (_, i) {
                                  final item = docs[i];
                                  return ListTile(
                                    title: Text(item["name"] ?? ""),
                                    subtitle: collection == "services"
                                        ? Text(
                                            "Preço: R\$ ${(item["price"] as num?)?.toStringAsFixed(2) ?? "--"}\n"
                                            "Duração: ${item["duration"]?.toString() ?? "--"} min",
                                          )
                                        : Text(
                                            "Turnos: ${(item["shifts"] as List?)?.join(", ") ?? "--"}"),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            onEdit(item);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteItem(
                                              collection, item.id),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Fechar")),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onAdd();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Novo"),
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

  // ------------------------------
  // INTERVALO
  // ------------------------------
  Future<void> _setInterval() async {
    final doc = await _db.collection("settings").doc("schedule").get();
    int? minutes = doc.exists ? doc["interval"] : null;
    final controller = TextEditingController(text: minutes?.toString() ?? "");

    showModalBottomSheet(
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
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Definir intervalo entre agendamentos",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Minutos"),
                    onChanged: (v) => minutes = int.tryParse(v),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar")),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (minutes != null && minutes! > 0) {
                            await _db
                                .collection("settings")
                                .doc("schedule")
                                .set({"interval": minutes});
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Salvar"),
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

  // ------------------------------
  // DELETE ITEM
  // ------------------------------
  Future<void> _deleteItem(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  // ------------------------------
  // UI PRINCIPAL
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text("Meu Salão",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.content_cut,
                  text: "Serviços",
                  onTap: () => _showListDialog(
                    "Serviços",
                    "services",
                    () => _addOrEditService(),
                    (doc) => _addOrEditService(service: doc),
                  ),
                ),
                const Divider(height: 5),
                _buildMenuItem(
                  icon: Icons.star_border,
                  text: "Agentes",
                  onTap: () => _showListDialog(
                    "Agentes",
                    "agents",
                    () => _addOrEditAgent(),
                    (doc) => _addOrEditAgent(agent: doc),
                  ),
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
  
  // ------------------------------
  // Salon Registration
  // ------------------------------
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

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        final File imageFile = File(pickedImage.path);
        final directory = await getApplicationDocumentsDirectory();
        final String path =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
        final File localImage = await imageFile.copy(path);

        setState(() {
          salonImage = localImage;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Cadastro de Salão",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: "Nome do salão"),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: cnpjController,
                        decoration: const InputDecoration(labelText: "CNPJ"),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: "Endereço"),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: "Telefone"),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: hoursController,
                        decoration: const InputDecoration(
                            labelText: "Horário de funcionamento"),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          await _pickImage();
                          setModalState(() {}); // Atualiza a imagem no modal
                        },
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: salonImage != null
                              ? Image.file(salonImage!, fit: BoxFit.cover)
                              : const Center(
                                  child: Text("Clique para adicionar uma imagem")),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancelar")),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              // Salva os dados no Firebase (exceto a imagem)
                              final salonData = {
                                "name": nameController.text,
                                "cnpj": cnpjController.text,
                                "address": addressController.text,
                                "phone": phoneController.text,
                                "hours": hoursController.text,
                                "updatedAt": FieldValue.serverTimestamp(),
                              };

                              // Você pode usar um doc fixo ou gerar aleatório
                              await _db.collection("salons").doc("my_salon").set(salonData);

                              // Opcional: print no console
                              print("Salão salvo no Firebase!");
                              print("Imagem local: ${salonImage?.path}");

                              Navigator.pop(context);
                            },
                            child: const Text("Salvar"),
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
      },
    );
  }


  Widget _buildMenuItem(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

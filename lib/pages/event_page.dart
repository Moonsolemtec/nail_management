import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nail_management/theme/app_theme.dart';

class EventPage extends StatelessWidget {
  final DateTime selectedDate;
  final String agentId;

  const EventPage({
    super.key,
    required this.selectedDate,
    required this.agentId,
  });

  Query<Map<String, dynamic>> _getEventsQuery() {
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection("events")
        .where("agentId", isEqualTo: agentId)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("date", isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy("date");
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("dd 'de' MMMM", "pt_BR").format(selectedDate);

    void showAddEventDialog(BuildContext context) {
      final notesController = TextEditingController();
      final clientController = TextEditingController();
      TimeOfDay selectedTime = TimeOfDay.now();
      bool isLoading = false;

      String? selectedServiceId;
      List<Map<String, dynamic>> services = [];

      Future<void> loadServices() async {
        final query = await FirebaseFirestore.instance.collection('services').get();
        services = query.docs.map((d) => {
              "id": d.id,
              "name": d['name'] ?? 'Sem nome',
              "agentId": d['agentId'],
        }).toList();
      }

      Future<void> showAddClientDialog() async {
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        final emailController = TextEditingController();
        final addressController = TextEditingController();
        bool isClientLoading = false;

        await showDialog(
          context: context,
          builder: (clientCtx) => StatefulBuilder(
            builder: (context, setClientState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Novo Cliente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(clientCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isClientLoading
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty ||
                              phoneController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Nome e telefone são obrigatórios.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setClientState(() => isClientLoading = true);

                          await FirebaseFirestore.instance
                              .collection('clients')
                              .add({
                            'name': nameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'email': emailController.text.trim(),
                            'address': addressController.text.trim(),
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          setClientState(() => isClientLoading = false);
                          Navigator.pop(clientCtx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Cliente cadastrado!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  child: isClientLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            ),
          ),
        );
      }

      showDialog(
        context: context,
        builder: (dialogContext) => FutureBuilder(
          future: loadServices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Novo Agendamento'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedServiceId,
                        items: services
                            .where((service) => service['agentId'] == agentId)
                            .map((service) => DropdownMenuItem<String>(
                                  value: service['id'],
                                  child: Text(service['name']),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          selectedServiceId = value;
                        }),
                        decoration: const InputDecoration(
                          labelText: 'Serviço *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.design_services),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: clientController,
                              decoration: const InputDecoration(
                                labelText: 'Cliente *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                            tooltip: 'Cadastrar novo cliente',
                            onPressed: showAddClientDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context)
                                    .copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Horário *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.edit, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (selectedServiceId == null ||
                                clientController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Selecione um serviço e informe o cliente.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            setState(() => isLoading = true);

                            final eventDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );

                            await FirebaseFirestore.instance.collection('events').add({
                              'serviceId': selectedServiceId,
                              'clientName': clientController.text.trim(),
                              'notes': notesController.text.trim().isNotEmpty
                                  ? notesController.text.trim()
                                  : null,
                              'date': Timestamp.fromDate(eventDateTime),
                              'agentId': agentId,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Agendamento criado com sucesso!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    void showEditEventDialog(BuildContext context, DocumentSnapshot eventDoc) {
      final event = eventDoc.data() as Map<String, dynamic>;
      final notesController = TextEditingController(text: event['notes'] ?? '');
      final clientController =
          TextEditingController(text: event['clientName'] ?? '');
      TimeOfDay selectedTime = TimeOfDay(
        hour: (event['date'] as Timestamp).toDate().hour,
        minute: (event['date'] as Timestamp).toDate().minute,
      );

      bool isLoading = false;
      String? selectedServiceId = event['serviceId'];
      List<Map<String, dynamic>> services = [];

      Future<void> loadServices() async {
        final query = await FirebaseFirestore.instance
            .collection('services')
            .where('agentId', isEqualTo: agentId)
            .get();

        services = query.docs.map((d) => {
              "id": d.id,
              "name": d['name'] ?? 'Sem nome',
            }).toList();
      }

      Future<void> showAddClientDialog() async {
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        final emailController = TextEditingController();
        final addressController = TextEditingController();
        bool isClientLoading = false;

        await showDialog(
          context: context,
          builder: (clientCtx) => StatefulBuilder(
            builder: (context, setClientState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Novo Cliente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(clientCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isClientLoading
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty ||
                              phoneController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Nome e telefone são obrigatórios.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setClientState(() => isClientLoading = true);

                          await FirebaseFirestore.instance
                              .collection('clients')
                              .add({
                            'name': nameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'email': emailController.text.trim(),
                            'address': addressController.text.trim(),
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          setClientState(() => isClientLoading = false);
                          Navigator.pop(clientCtx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Cliente cadastrado!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  child: isClientLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            ),
          ),
        );
      }

      showDialog(
        context: context,
        builder: (dialogContext) => FutureBuilder(
          future: loadServices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Editar Agendamento'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedServiceId,
                        items: services
                            .map((service) => DropdownMenuItem<String>(
                                  value: service['id'],
                                  child: Text(service['name']),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          selectedServiceId = value;
                        }),
                        decoration: const InputDecoration(
                          labelText: 'Serviço *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.design_services),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: clientController,
                              decoration: const InputDecoration(
                                labelText: 'Cliente *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_1,
                                color: Colors.blue),
                            tooltip: 'Cadastrar novo cliente',
                            onPressed: showAddClientDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  alwaysUse24HourFormat: true,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Horário *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.edit, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (selectedServiceId == null ||
                                clientController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Selecione um serviço e informe o cliente.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            setState(() => isLoading = true);

                            final updatedDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );

                            await eventDoc.reference.update({
                              'serviceId': selectedServiceId,
                              'clientName': clientController.text.trim(),
                              'notes': notesController.text.trim().isNotEmpty
                                  ? notesController.text.trim()
                                  : null,
                              'date': Timestamp.fromDate(updatedDateTime),
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Agendamento atualizado!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.deselected,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getEventsQuery().snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      final errorMessage = snapshot.error.toString();
                      final isIndexError = errorMessage.contains('index') || 
                                          errorMessage.contains('FAILED_PRECONDITION');
                      
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isIndexError ? Icons.settings : Icons.error_outline, 
                                size: 48, 
                                color: isIndexError ? Colors.orange[300] : Colors.red[300]
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isIndexError 
                                  ? "Configurando banco de dados..." 
                                  : "Erro ao carregar eventos",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isIndexError ? Colors.orange[700] : Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isIndexError
                                  ? "É necessário criar um índice no Firebase.\n\nClique no link que apareceu no console (log) e aguarde alguns minutos após criar o índice."
                                  : "Verifique sua conexão e tente novamente.",
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              if (isIndexError) ...[
                                const SizedBox(height: 16),
                                const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text(
                                  "O índice leva de 2 a 5 minutos para ficar pronto.",
                                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Nenhum evento para este dia.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Toque no + para adicionar",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final events = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final eventDoc = events[index];
                        final event = eventDoc.data() as Map<String, dynamic>;

                        final serviceId = event['serviceId'];
                        final clientName = event['clientName'] ?? 'Cliente não informado';
                        final date = (event['date'] as Timestamp).toDate();

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('services')
                              .doc(serviceId)
                              .get(),
                          builder: (context, snapshot) {
                            String serviceName = 'Serviço não definido';
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>;
                              serviceName = data['name'] ?? 'Serviço sem nome';
                            }

                            return Card(
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              elevation: 2,
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                leading: const Icon(Icons.event, color: Colors.blueAccent),
                                title: Text(
                                  "$serviceName - $clientName",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat("dd/MM/yyyy HH:mm").format(date),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      showEditEventDialog(context, eventDoc);
                                    } else if (value == 'delete') {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text('Confirmar exclusão'),
                                            ],
                                          ),
                                          content: const Text(
                                            'Tem certeza que deseja excluir este agendamento?',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Excluir'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        await eventDoc.reference.delete();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('✓ Agendamento excluído'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
                                    const PopupMenuItem<String>(value: 'delete', child: Text('Excluir')),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () => showAddEventDialog(context),
                  child: const Icon(Icons.add),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
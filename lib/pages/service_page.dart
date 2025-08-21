import 'package:flutter/material.dart';
import 'package:nail_management/pages/event_page.dart';
import 'package:nail_management/theme/app_theme.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});
  
  get selected => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Foto de perfil
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            "Meu Salão",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Caixa com opções
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.content_cut,
                    text: "Serviços",
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, // ocupa mais espaço
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) {
                          return EventPage(selectedDate: selected);
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.menu_book,
                    text: "Preços",
                    onTap: () {
                      // TODO: navegar para a página de preços
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.star_border,
                    text: "Agente",
                    onTap: () {
                      // TODO: navegar para a página de agente
                    },
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.add_box_outlined,
                    text: "Horários",
                    onTap: () {
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Função para criar os itens de menu
  Widget _buildMenuItem(BuildContext context,
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

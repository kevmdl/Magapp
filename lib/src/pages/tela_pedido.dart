import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class TelaPedido extends StatefulWidget { // Nome da classe corrigido
  const TelaPedido({super.key});

  @override
  State<TelaPedido> createState() => _TelaPedidoState();
}

class _TelaPedidoState extends State<TelaPedido> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now(); // Inicializar com o dia atual

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F59F7), Color(0xFF020e26)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
          
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/img/logo_maga_app.png',
                            height: 60,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      _buildCalendar(),
                      _buildPedidos(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função para construir o calendário
  Widget _buildCalendar() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: TableCalendar(
          focusedDay: _focusedDay,
          firstDay: DateTime(2000),
          lastDay: DateTime(2050),
          currentDay: DateTime.now(),
          calendarFormat: CalendarFormat.month,
          locale: 'pt_BR',
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF063FBA),
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF063FBA)),
            rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF063FBA)),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: const Color(0xFF063FBA).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF063FBA),
              shape: BoxShape.circle,
            ),
            defaultTextStyle: const TextStyle(color: Colors.black87),
            weekendTextStyle: const TextStyle(color: Colors.red),
            outsideTextStyle: const TextStyle(color: Colors.grey),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Color(0xFF063FBA)),
            weekendStyle: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  // Função para construir a seção Meus Pedidos
  Widget _buildPedidos() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Meus Pedidos", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildPedidoItem("01/01", "Placa: ******", "Renavam: *******", 
                           "Veículo/modelo: *****", "Cor: *****"),
            _buildPedidoItem("02/01", "Placa: ******", "Renavam: *******", 
                           "Veículo/modelo: *****", "Cor: *****"),
          ],
        ),
      ),
    );
  }

  Widget _buildPedidoItem(String data, String placa, String renavam, 
                         String modelo, String cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(placa),
                Text(renavam),
                Text(modelo),
                Text(cor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

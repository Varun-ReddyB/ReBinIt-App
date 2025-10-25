import 'package:flutter/material.dart';

class EcoTipsScreen extends StatelessWidget {
  const EcoTipsScreen({super.key});

  final List<Map<String, String>> ecoTips = const [
    {
      'icon': 'lightbulb_outline',
      'title': "Reduce Energy Consumption",
      'description': "Turn off lights when you leave a room and unplug electronics when not in use. Switch to energy-efficient LED bulbs."
    },
    {
      'icon': 'water',
      'title': "Conserve Water",
      'description': "Take shorter showers, fix leaky faucets, and only run your dishwasher and washing machine when they are full."
    },
    {
      'icon': 'shopping_basket',
      'title': "Reuse and Reduce",
      'description': "Choose reusable shopping bags, water bottles, and coffee cups. Buy products with minimal packaging to reduce waste."
    },
    {
      'icon': 'recycling',
      'title': "Recycle Properly",
      'description': "Know your local recycling rules. Rinse containers and break down cardboard boxes before placing them in the bin."
    },
    {
      'icon': 'eco',
      'title': "Compost Organic Waste",
      'description': "Start a compost pile for food scraps and yard waste. It reduces landfill waste and creates nutrient-rich soil."
    },
    {
      'icon': 'commute',
      'title': "Choose Sustainable Transportation",
      'description': "Walk, bike, or use public transport whenever possible. This significantly reduces your carbon emissions."
    },
    {
      'icon': 'book',
      'title': "Go Paperless",
      'description': "Opt for digital bills and statements. Use tablets and computers instead of notebooks for notes and documents."
    },
    {
      'icon': 'fastfood',
      'title': "Eat Mindfully",
      'description': "Reduce food waste by planning meals and buying only what you need. Consider a vegetarian meal once a week to lessen your environmental impact."
    },
    {
      'icon': 'local_florist',
      'title': "Plant a Tree",
      'description': "Trees absorb carbon dioxide and provide oxygen. Planting a tree is a simple yet powerful way to help the environment."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eco Tips", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Learn How to Reduce Your Carbon Footprint",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Map over the list of tips to build the tip cards
              ...ecoTips.map((tip) => _buildTipCard(
                icon: _getIconForString(tip['icon']!),
                title: tip['title']!,
                description: tip['description']!,
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForString(String iconName) {
    switch (iconName) {
      case 'lightbulb_outline': return Icons.lightbulb_outline;
      case 'water': return Icons.water;
      case 'shopping_basket': return Icons.shopping_basket;
      case 'recycling': return Icons.recycling;
      case 'eco': return Icons.eco;
      case 'commute': return Icons.commute;
      case 'book': return Icons.book;
      case 'fastfood': return Icons.fastfood;
      case 'local_florist': return Icons.local_florist;
      default: return Icons.help_outline;
    }
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
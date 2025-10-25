import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "About Us",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // ✅ Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/dec.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ✅ Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.withOpacity(0.85),
                  Colors.green.withOpacity(0.5),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Our Story"),
                  _buildSection(
                    "Our Mission",
                    "To empower communities with smart waste tracking and recycling solutions, promoting eco-friendly habits and sustainability.",
                    Icons.track_changes,
                  ),
                  _buildSection(
                    "Our Vision",
                    "A cleaner, greener future where technology and awareness solve waste problems together.",
                    Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Meet the Team"),

                  // ✅ Team Members (ImgBB links)
                  _buildTeamMember(
                    context,
                    "Bongaram Varun Reddy",
                    "Chief Executive Officer (CEO)",
                    "https://i.ibb.co/LDtTLR4j/varun.jpg",
                    "Visionary leader behind ReBinIt, driving innovation and sustainability through technology.",
                  ),
                  _buildTeamMember(
                    context,
                    "V Hanirvesh Reddy",
                    "Chief Technology Officer (CTO)",
                    "https://i.ibb.co/0j90KqCD/hanirvesh.jpg",
                    "Leads technical strategy, ensuring scalable, secure, and high-performance solutions.",
                  ),
                  _buildTeamMember(
                    context,
                    "Gonela Rohith Kumar",
                    "Chief Operating Officer (COO)",
                    "https://i.ibb.co/YBjdbSPM/rohit.jpg",
                    "Manages operations, ensuring seamless execution and high customer satisfaction.",
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Hero Header
  Widget _buildHeroHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.recycling, size: 80, color: Colors.white),
          SizedBox(height: 15),
          Text(
            "ReBinIt: Our Story",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3.0,
                    color: Colors.black26),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            "Smart waste management & recycling for a cleaner tomorrow.",
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 25),
        ],
      ),
    );
  }

  // ✅ Section Title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Container(
            height: 2,
            width: 50,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  // ✅ Story Section
  Widget _buildSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Text(content,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ✅ Team Member (Tap to open dialog)
  Widget _buildTeamMember(BuildContext context, String name, String role,
      String imageUrl, String bio) {
    return GestureDetector(
      onTap: () {
        _showMemberDialog(context, name, role, imageUrl, bio);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: NetworkImage(imageUrl),
          ),
          title: Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Text(role,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          trailing: const Icon(Icons.info_outline, color: Colors.green),
        ),
      ),
    );
  }

  // ✅ Popup Dialog for Team Member
  void _showMemberDialog(BuildContext context, String name, String role,
      String imageUrl, String bio) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: NetworkImage(imageUrl),
              ),
              const SizedBox(height: 15),
              Text(name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(role,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 10),
              Text(
                bio,
                style: const TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text("Close",
                    style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

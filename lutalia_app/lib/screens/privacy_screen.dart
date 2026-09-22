import 'package:flutter/material.dart';
import '../theme/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: LutaliaTheme.latte),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Datenschutz",
          style: TextStyle(
            fontFamily: "NewFirst",
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: LutaliaTheme.espresso,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            const Text(
              "Datenschutzvereinbarung",
              style: TextStyle(
                fontFamily: "NewFirst",
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: LutaliaTheme.espresso,
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle("1. Verantwortliche Stelle"),
            _sectionText(
              "Lutalia\n"
              "Luisa Großmann\n"
              "Nürnberg / Zirndorf, Deutschland\n"
              "E-Mail: deine@email.de",
            ),

            _sectionTitle("2. Welche Daten wir verarbeiten"),
            _sectionText(
              "Im Rahmen der Registrierung verarbeiten wir folgende personenbezogene Daten:\n"
              "• Vorname, Nachname\n"
              "• Nickname\n"
              "• Geburtsdatum\n"
              "• E-Mail-Adresse\n"
              "• Passwort (verschlüsselt)\n"
              "• Optional: Profilbild\n"
              "• Nutzungsdaten innerhalb der App",
            ),

            _sectionTitle("3. Zweck der Verarbeitung"),
            _sectionText(
              "Wir verarbeiten deine Daten zu folgenden Zwecken:\n"
              "• Erstellung und Verwaltung deines Nutzerkontos\n"
              "• Bereitstellung der App-Funktionen\n"
              "• Personalisierung deines Nutzererlebnisses\n"
              "• Kommunikation mit dir (z. B. E-Mail-Verifizierung)\n"
              "• Sicherheit und Missbrauchsprävention",
            ),

            _sectionTitle("4. Rechtsgrundlagen"),
            _sectionText(
              "Die Verarbeitung erfolgt auf Basis von:\n"
              "• Art. 6 Abs. 1 lit. b DSGVO – Vertragserfüllung\n"
              "• Art. 6 Abs. 1 lit. a DSGVO – Einwilligung\n"
              "• Art. 6 Abs. 1 lit. f DSGVO – berechtigtes Interesse",
            ),

            _sectionTitle("5. Speicherung & Löschung"),
            _sectionText(
              "Wir speichern deine Daten nur so lange, wie es für die Nutzung der App erforderlich ist "
              "oder gesetzliche Aufbewahrungsfristen bestehen. "
              "Du kannst dein Konto jederzeit löschen.",
            ),

            _sectionTitle("6. Weitergabe an Dritte"),
            _sectionText(
              "Wir geben deine Daten nicht an Dritte weiter, außer:\n"
              "• an technische Dienstleister (z. B. Firebase),\n"
              "• wenn dies zur Vertragserfüllung notwendig ist,\n"
              "• oder wenn eine gesetzliche Verpflichtung besteht.",
            ),

            _sectionTitle("7. Deine Rechte"),
            _sectionText(
              "Du hast jederzeit das Recht auf:\n"
              "• Auskunft\n"
              "• Berichtigung\n"
              "• Löschung\n"
              "• Einschränkung der Verarbeitung\n"
              "• Datenübertragbarkeit\n"
              "• Widerruf deiner Einwilligung",
            ),

            _sectionTitle("8. Widerruf der Einwilligung"),
            _sectionText(
              "Du kannst deine Einwilligung jederzeit mit Wirkung für die Zukunft widerrufen. "
              "Die Rechtmäßigkeit der bis zum Widerruf erfolgten Verarbeitung bleibt unberührt.",
            ),

            _sectionTitle("9. Kontakt"),
            _sectionText(
              "Bei Fragen zum Datenschutz kannst du dich jederzeit an uns wenden.",
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ⭐ Hilfs-Widgets für einheitlichen Stil

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: "Cinzel",
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: LutaliaTheme.espresso,
        ),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: "Cinzel",
        fontSize: 15,
        height: 1.45,
        color: LutaliaTheme.espresso,
      ),
    );
  }
}
